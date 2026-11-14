#!/usr/bin/env python3
"""Real-world application benchmarks: 32-tap FIR filter and 128-dim NN/wide-dynamic-range dot products."""
import json
import math
import random
import struct
import sys
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 120

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "app_benchmarks"
OUT.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(ROOT / "scripts"))
import gen_refactored_mac_vectors as gm


def float_to_fp32(x: float) -> float:
    try:
        return struct.unpack("!f", struct.pack("!f", x))[0]
    except OverflowError:
        return math.copysign(math.inf, x)


def float_to_fp16(x: float) -> float:
    if not math.isfinite(x):
        return x
    try:
        return struct.unpack("!e", struct.pack("!e", x))[0]
    except OverflowError:
        return math.copysign(math.inf, x)


def float_to_bf16(x: float) -> float:
    if not math.isfinite(x):
        return x
    try:
        u32 = struct.unpack("!I", struct.pack("!f", x))[0]
    except OverflowError:
        return math.copysign(math.inf, x)
    # Flush binary32 subnormals/underflow consistently with normal 8-bit exp BF16 range; keep finite RNE
    lsb = (u32 >> 16) & 1
    guard = (u32 >> 15) & 1
    sticky = (u32 & 0x7FFF) != 0
    if guard and (lsb or sticky):
        u32_hi = (u32 & 0xFFFF0000) + 0x00010000
    else:
        u32_hi = u32 & 0xFFFF0000
    # Check overflow into exponent 0xFF (Inf)
    if (u32_hi & 0x7F800000) == 0x7F800000:
        u32_hi = (u32 & 0x80000000) | 0x7F800000
    return struct.unpack("!f", struct.pack("!I", u32_hi))[0]


def fp_mac_step(a: float, b: float, c: float, quant_fn) -> float:
    # Unfused IEEE-754 MAC step: round(round(a*b) + c) matching separate mul+add pipeline
    qa = quant_fn(a)
    qb = quant_fn(b)
    qc = quant_fn(c)
    prod = quant_fn(qa * qb)
    res = quant_fn(prod + qc)
    return res


def real_to_posit32(val: float) -> int:
    if val == 0.0:
        return 0
    if not math.isfinite(val):
        return gm.NAR
    d = Decimal(str(val)) if abs(val) > 1e300 or abs(val) < 1e-300 else Decimal(val)
    if d == 0:
        return 0
    sign = d < 0
    ad = abs(d)
    exp2 = int(math.floor(ad.ln() / Decimal(2).ln()))
    scale2 = Decimal(2) ** exp2
    while scale2 > ad:
        exp2 -= 1
        scale2 /= 2
    while scale2 * 2 <= ad:
        exp2 += 1
        scale2 *= 2
    frac_bits = 60
    scaled = int((ad * (Decimal(2) ** (frac_bits - exp2))).to_integral_value())
    shift = gm.BASE + exp2 - frac_bits
    if shift >= 0:
        grid = scaled << shift
    else:
        grid = scaled >> (-shift)
    if grid == 0:
        code = 1
        return (-code) & gm.MASK if sign else code
    signed_grid = -grid if sign else grid
    raw, _ = gm.encode(signed_grid)
    return raw


def posit_to_decimal(raw: int) -> Decimal:
    if raw == 0:
        return Decimal(0)
    if raw == gm.NAR:
        return Decimal("NaN")
    s, c, q = gm.decode(raw)
    v = Decimal(c) * (Decimal(2) ** (q - 26))
    return -v if s else v


def posit_mac_step(a_raw: int, b_raw: int, c_raw: int, n: int, ops: int, fused: bool) -> tuple[int, int]:
    d, _ = gm.golden(a_raw, b_raw, c_raw, n, ops, fused)
    if a_raw in (0, gm.NAR) or b_raw in (0, gm.NAR) or c_raw == gm.NAR:
        t = 0
    else:
        _, ca, _ = gm.decode(a_raw)
        _, cb, _ = gm.decode(b_raw)
        fa = (ca >> 14) & 0xFFF
        fb = (cb >> 14) & 0xFFF
        if ops and fb.bit_count() < fa.bit_count():
            fa = fb
        t = min(n, fa.bit_count())
    return d, t


def run_fir_benchmark():
    M = 32
    fc = 0.2
    coeffs = []
    for k in range(M):
        n_idx = k - (M - 1) / 2.0
        sinc = 2.0 * fc if n_idx == 0 else math.sin(2.0 * math.pi * fc * n_idx) / (math.pi * n_idx)
        win = 0.54 - 0.46 * math.cos(2.0 * math.pi * k / (M - 1))
        coeffs.append(sinc * win)
    csum = sum(coeffs)
    coeffs = [c / csum for c in coeffs]

    N_SIG = 288
    x = [0.75 * math.sin(2.0 * math.pi * 0.05 * i) + 0.35 * math.cos(2.0 * math.pi * 0.38 * i + 0.4) for i in range(N_SIG)]

    x_p = [real_to_posit32(v) for v in x]
    h_p = [real_to_posit32(v) for v in coeffs]
    x_dec = [Decimal.from_float(v) for v in x]
    h_dec = [Decimal.from_float(v) for v in coeffs]

    ref_y = []
    res_data = {k: [] for k in ["fp32", "bf16", "fp16", "mac_f_n12", "mac_f_n8", "mac_nf_n12", "mac_quire"]}
    cycles = {"mac_f_n12": 0, "mac_f_n8": 0, "mac_nf_n12": 0, "mac_quire": 0}

    for idx in range(M - 1, N_SIG):
        exact = sum(h_dec[k] * x_dec[idx - k] for k in range(M))
        ref_y.append(exact)

        for fp_name, qfn in [("fp32", float_to_fp32), ("bf16", float_to_bf16), ("fp16", float_to_fp16)]:
            acc_fp = 0.0
            for k in range(M):
                acc_fp = fp_mac_step(coeffs[k], x[idx - k], acc_fp, qfn)
            res_data[fp_name].append(Decimal.from_float(acc_fp))

        for name, n_lim, fused in [("mac_f_n12", 12, True), ("mac_f_n8", 8, True), ("mac_nf_n12", 12, False)]:
            acc_p = 0
            for k in range(M):
                acc_p, t = posit_mac_step(h_p[k], x_p[idx - k], acc_p, n_lim, 1, fused)
                cycles[name] += (13 if fused else 16) + max(1, t)
            res_data[name].append(posit_to_decimal(acc_p))

        q_sum = 0
        cycles["mac_quire"] += 62
        for k in range(M):
            a_raw, b_raw = h_p[k], x_p[idx - k]
            if a_raw != 0 and b_raw != 0:
                sa, ca, qa = gm.decode(a_raw)
                sb, cb, qb = gm.decode(b_raw)
                fa = (ca >> 14) & 0xFFF
                fb = (cb >> 14) & 0xFFF
                if fb.bit_count() < fa.bit_count():
                    fa, fb = fb, fa
                t = fa.bit_count()
                m = (4096 + fa) * (4096 + fb)
                p = (-1 if sa != sb else 1) * (m << (gm.BASE + qa + qb - 24))
                q_sum += p
                cycles["mac_quire"] += 36 + max(1, t)
            else:
                cycles["mac_quire"] += 37
        q_raw, _ = gm.encode(q_sum)
        res_data["mac_quire"].append(posit_to_decimal(q_raw))

    n_samples = len(ref_y)
    sig_pow = float(sum(v * v for v in ref_y)) / n_samples
    out = {}
    freqs_mhz = {"mac_f_n12": 154.42, "mac_f_n8": 154.42, "mac_nf_n12": 135.85, "mac_quire": 98.16}
    for name, vals in res_data.items():
        errs = [float(abs(v - r)) for v, r in zip(vals, ref_y)]
        mse = sum(e * e for e in errs) / n_samples
        rmse = math.sqrt(mse)
        max_e = max(errs)
        snr = 10.0 * math.log10(sig_pow / mse) if mse > 0 else float("inf")
        entry = {"samples": n_samples, "snr_db": snr, "rmse": rmse, "max_abs_err": max_e}
        if name in cycles:
            avg_cyc = cycles[name] / n_samples
            entry["avg_cycles_per_sample"] = avg_cyc
            entry["time_us_per_sample"] = avg_cyc / freqs_mhz[name]
        out[name] = entry
    return out


def run_nn_and_dynamic_range_benchmark():
    rng = random.Random(20261113)
    dim = 128
    n_vecs = 200

    scenarios = {}
    for scen_name, mode in [("nn_norm_dim128", "norm"), ("wide_dyn_scale_dim128", "scale"), ("wide_dyn_cancel_dim128", "cancel")]:
        errs = {k: [] for k in ["fp32", "bf16", "fp16", "mac_f_n12", "mac_f_n8", "mac_nf_n12", "mac_quire"]}
        fp_fail_cnt = {"fp32": 0, "bf16": 0, "fp16": 0}
        posit_valid = 0

        for v_idx in range(n_vecs):
            if mode == "norm":
                a_vals = [rng.gauss(0.0, 1.0 / math.sqrt(dim)) for _ in range(dim)]
                b_vals = [rng.gauss(0.0, 1.0) for _ in range(dim)]
            elif mode == "scale":
                a_vals, b_vals = [], []
                large_mode = (v_idx % 2 == 0)
                for j in range(dim):
                    if large_mode:
                        ea, eb = rng.uniform(20.0, 22.0), rng.uniform(19.0, 21.0)
                    else:
                        ea, eb = rng.uniform(-24.0, -21.0), rng.uniform(-24.0, -21.0)
                    sgn = 1.0 if (j % 3 != 0) else -0.35
                    a_vals.append(sgn * (1.0 + rng.random()) * (10.0 ** ea))
                    b_vals.append((1.0 + rng.random()) * (10.0 ** eb))
            else:
                a_vals, b_vals = [], []
                big_pairs = 16
                for j in range(big_pairs):
                    ea = rng.uniform(22, 26)
                    eb = rng.uniform(18, 22)
                    va = (1.0 + rng.random()) * (10.0 ** ea)
                    vb = (1.0 + rng.random()) * (10.0 ** eb)
                    a_vals.extend([va, -va])
                    b_vals.extend([vb, vb])
                for j in range(dim - 2 * big_pairs):
                    ea = rng.uniform(-24, -19)
                    eb = rng.uniform(-24, -19)
                    a_vals.append(rng.choice([-1.0, 1.0]) * (1.0 + rng.random()) * (10.0 ** ea))
                    b_vals.append((1.0 + rng.random()) * (10.0 ** eb))
                combined = list(zip(a_vals, b_vals))
                rng.shuffle(combined)
                a_vals, b_vals = zip(*combined)
                a_vals, b_vals = list(a_vals), list(b_vals)

            exact = sum(Decimal(str(x)) * Decimal(str(y)) for x, y in zip(a_vals, b_vals))

            for fp_name, qfn in [("fp32", float_to_fp32), ("bf16", float_to_bf16), ("fp16", float_to_fp16)]:
                acc_fp = 0.0
                for x, y in zip(a_vals, b_vals):
                    acc_fp = fp_mac_step(x, y, acc_fp, qfn)
                if not math.isfinite(acc_fp) or (mode != "norm" and acc_fp == 0.0 and exact != 0):
                    fp_fail_cnt[fp_name] += 1
                if math.isfinite(acc_fp) and exact != 0:
                    errs[fp_name].append(float(abs(Decimal.from_float(acc_fp) - exact) / abs(exact)))
                else:
                    errs[fp_name].append(float("inf"))

            ap = [real_to_posit32(x) for x in a_vals]
            bp = [real_to_posit32(y) for y in b_vals]

            for name, n_lim, fused in [("mac_f_n12", 12, True), ("mac_f_n8", 8, True), ("mac_nf_n12", 12, False)]:
                acc_p = 0
                for x_p, y_p in zip(ap, bp):
                    acc_p, _ = posit_mac_step(x_p, y_p, acc_p, n_lim, 1, fused)
                dv = posit_to_decimal(acc_p)
                if name == "mac_f_n12" and acc_p not in (0, gm.NAR):
                    posit_valid += 1
                errs[name].append(float(abs(dv - exact) / abs(exact)) if exact != 0 else 0.0)

            q_sum = 0
            for x_p, y_p in zip(ap, bp):
                if x_p != 0 and y_p != 0:
                    sa, ca, qa = gm.decode(x_p)
                    sb, cb, qb = gm.decode(y_p)
                    fa = (ca >> 14) & 0xFFF
                    fb = (cb >> 14) & 0xFFF
                    if fb.bit_count() < fa.bit_count():
                        fa, fb = fb, fa
                    m = (4096 + fa) * (4096 + fb)
                    q_sum += (-1 if sa != sb else 1) * (m << (gm.BASE + qa + qb - 24))
            q_raw, _ = gm.encode(q_sum)
            dq = posit_to_decimal(q_raw)
            errs["mac_quire"].append(float(abs(dq - exact) / abs(exact)) if exact != 0 else 0.0)

        stat = {}
        for k, lst in errs.items():
            s = sorted(lst)
            p50 = s[len(s) // 2]
            p95 = s[int(0.95 * len(s)) - 1]
            mx = s[-1]
            inf_cnt = sum(1 for v in s if not math.isfinite(v))
            stat[k] = {"p50_rel": p50, "p95_rel": p95, "max_rel": mx, "fail_inf_cnt": inf_cnt}
        stat["fp32_fail_or_underflow_cnt"] = fp_fail_cnt["fp32"]
        stat["bf16_fail_or_underflow_cnt"] = fp_fail_cnt["bf16"]
        stat["fp16_fail_or_underflow_cnt"] = fp_fail_cnt["fp16"]
        stat["mac_f_valid_nonzero_cnt"] = posit_valid
        scenarios[scen_name] = stat
    return scenarios


def main():
    fir = run_fir_benchmark()
    nn = run_nn_and_dynamic_range_benchmark()
    result = {"fir_32tap_256samples": fir, "dot_product_128d": nn}
    (OUT / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
    print("APP_BENCHMARKS_DONE")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
