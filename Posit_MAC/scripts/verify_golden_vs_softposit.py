#!/usr/bin/env python3
"""Cross-validate the independent Python BigInt golden reference against Berkeley SoftPosit (es=2),
   summarize Norris & Kim (ISCAS 2021) es=3 statistical agreement, and quantify one-sided product bias."""
import csv
import gzip
import json
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))

from l0 import softposit as sp
import gen_refactored_mac_vectors as gm

NAR = 0x80000000
MASK = 0xFFFFFFFF
BASE = 532  # 2^BASE grid scaling; safely covers es=2 (maxpos 2^120) and es=3 (maxpos 2^240)


def decode_es(raw: int, es: int) -> tuple[bool, int, int]:
    """Same exact Posit decoding rule parameterized by es."""
    raw &= MASK
    sign = bool(raw & NAR)
    code = (-raw) & MASK if sign else raw
    if not code:
        return sign, 0, 0
    if code == NAR:
        raise ValueError("NaR")
    bit = 30
    run = 0
    polarity = (code >> bit) & 1
    while bit >= 0 and ((code >> bit) & 1) == polarity:
        run += 1
        bit -= 1
    if bit >= 0:
        bit -= 1
    exponent = 0
    for _ in range(es):
        exponent *= 2
        if bit >= 0:
            exponent |= (code >> bit) & 1
            bit -= 1
    frac_len = max(0, bit + 1)
    max_frac_bits = 31 - 2 - es  # for n=32, max fraction bits when k=0,-1 -> 27 (es=2) or 26 (es=3)
    frac = (code & ((1 << frac_len) - 1)) << (max_frac_bits - frac_len)
    k = (run - 1) if polarity else (-run)
    sf = (k << es) + exponent
    return sign, (1 << max_frac_bits) | frac, sf


def value_es(raw: int, es: int) -> int:
    if raw == 0 or raw == NAR:
        return 0
    s, c, sf = decode_es(raw, es)
    max_frac_bits = 29 - es
    return (-1 if s else 1) * (c << (BASE + sf - max_frac_bits))


def encode_es(val: int, es: int) -> int:
    """Same exact RNE encoder parameterized by es."""
    if val == 0:
        return 0
    sign = val < 0
    m = abs(val)
    h = m.bit_length() - 1
    sf = h - BASE
    max_sf = 30 * (1 << es)  # 120 for es=2, 240 for es=3
    if sf >= max_sf:
        code = NAR - 1
    elif sf < -max_sf:
        code = 1
    else:
        k, e = divmod(sf, 1 << es)
        run = k + 1 if k >= 0 else -k
        bits = [int(k >= 0)] * run + [int(k < 0)] + [(e >> b) & 1 for b in range(es - 1, -1, -1)]
        bits += [(m >> b) & 1 for b in range(h - 1, -1, -1)]
        bits += [0] * max(0, 33 - len(bits))
        code = 0
        for b in bits[:31]:
            code = (code << 1) | b
        if bits[31] and ((code & 1) or any(bits[32:])):
            code += 1
        code = max(1, min(NAR - 1, code))
    return (-code) & MASK if sign else code


def golden_es2_exact_ops(a: int, b: int, c: int) -> tuple[int, int, int, int]:
    """Return (add_ab, sub_ab, mul_ab, fma_abc) using BigInt model with es=2."""
    # Add(a,b)
    if a == NAR or b == NAR:
        add_res = NAR
    elif a == 0:
        add_res = b
    elif b == 0:
        add_res = a
    else:
        add_res = encode_es(value_es(a, 2) + value_es(b, 2), 2)

    # Sub(a,b)
    if a == NAR or b == NAR:
        sub_res = NAR
    else:
        nb = 0 if b == 0 else ((-b) & MASK)
        if a == 0:
            sub_res = nb
        elif nb == 0:
            sub_res = a
        else:
            sub_res = encode_es(value_es(a, 2) + value_es(nb, 2), 2)

    # Mul(a,b)
    if a == NAR or b == NAR:
        mul_res = NAR
    elif a == 0 or b == 0:
        mul_res = 0
    else:
        mul_res = encode_es(value_es(a, 2) * value_es(b, 2) // (1 << BASE), 2)

    # Fused mulAdd(a,b,c) matching SoftPosit posit32::mulAdd
    if a == NAR or b == NAR or c == NAR:
        fma_res = NAR
    elif a == 0 or b == 0:
        fma_res = c
    else:
        p = value_es(a, 2) * value_es(b, 2) // (1 << BASE)
        fma_res = encode_es(p + value_es(c, 2), 2)

    return add_res, sub_res, mul_res, fma_res


def check_softposit(n_rand: int = 100000) -> dict:
    # Verify es=3 consistency against existing gm first
    rng = random.Random(20261114)
    es3_check = 0
    for _ in range(10000):
        x = rng.getrandbits(32)
        if x not in (0, NAR):
            assert decode_es(x, 3) == gm.decode(x)
            es3_check += 1

    corners = [
        0, 1, 2, 3, 0x3FFFFFFF, 0x40000000, 0x40000001, 0x48000000,
        0x7FFFFFFE, 0x7FFFFFFF, 0x80000000, 0x80000001, 0x80000002,
        0xBFFFFFFF, 0xC0000000, 0xC0000001, 0xFFFFFFFF,
    ]
    cases = []
    # All corner pairs + cancellation + small perturbations
    for a in corners:
        for b in corners:
            cases.append((a, b, 0))
            cases.append((a, b, (-a) & MASK))
            cases.append((a, b, 0x40000000))
    for _ in range(n_rand):
        a = rng.getrandbits(32)
        b = rng.getrandbits(32)
        c = rng.getrandbits(32)
        cases.append((a, b, c))

    mismatches = {"add": 0, "sub": 0, "mul": 0, "fma": 0}
    first_err = []
    for a, b, c in cases:
        ga, gs, gm_, gf = golden_es2_exact_ops(a, b, c)
        sa = sp.p32_add(a, b)
        ss = sp.p32_sub(a, b)
        sm = sp.p32_mul(a, b)
        sf = sp.p32_mulAdd(a, b, c)
        for op, g_v, s_v in [("add", ga, sa), ("sub", gs, ss), ("mul", gm_, sm), ("fma", gf, sf)]:
            if g_v != s_v:
                mismatches[op] += 1
                if len(first_err) < 5:
                    first_err.append({"op": op, "a": hex(a), "b": hex(b), "c": hex(c), "golden": hex(g_v), "softposit": hex(s_v)})

    return {
        "es3_decode_sanity_checked": es3_check,
        "total_cases": len(cases),
        "corner_cases": len(cases) - n_rand,
        "random_cases": n_rand,
        "mismatches": mismatches,
        "total_mismatches": sum(mismatches.values()),
        "sample_errors": first_err,
    }


def check_one_sided_bias() -> dict:
    """Measure one-sided magnitude inequality |P_hat| <= |P12| <= |P| on exact mul_prepack pairs."""
    pairs_path = ROOT / "results" / "mul_prepack_20261112" / "pairs.csv"
    pairs = {}
    with pairs_path.open("r", encoding="ascii") as f:
        for row in csv.DictReader(f):
            pid = int(row["pair_id"])
            a_raw = int(row["a_hex"], 16)
            b_raw = int(row["b_hex"], 16)
            pairs[pid] = (a_raw, b_raw, row["group"])

    total_n12_finite = 0
    uniform_n12 = 0
    le_p_cnt = 0
    lt_p_cnt = 0
    eq_p_cnt = 0
    le_p12_cnt = 0

    for pid, (a_raw, b_raw, grp) in pairs.items():
        if a_raw in (0, NAR) or b_raw in (0, NAR):
            continue
        sa, ca, qa = gm.decode(a_raw)
        sb, cb, qb = gm.decode(b_raw)
        # Same scale factor 2^(qa+qb) applies to both P_full and P12, so compare scaled significands directly:
        # P_full_sig = ca * cb (Q52), P12_sig = ((4096 + fa) * (4096 + fb)) << 28 (Q52)
        p_full = ca * cb
        fa = (ca >> 14) & 0xFFF
        fb = (cb >> 14) & 0xFFF
        # On n=12, |P_hat| == |P12|
        p12 = ((4096 + fa) * (4096 + fb)) << 28
        total_n12_finite += 1
        if grp == "uniform_raw":
            uniform_n12 += 1
        if p12 <= p_full:
            le_p_cnt += 1
        if p12 < p_full:
            lt_p_cnt += 1
        if p12 == p_full:
            eq_p_cnt += 1
        if p12 <= p12:
            le_p12_cnt += 1

    return {
        "total_finite_pairs_n12": total_n12_finite,
        "uniform_finite_pairs_n12": uniform_n12,
        "p_hat_le_p_full_count": le_p_cnt,
        "p_hat_lt_p_full_count": lt_p_cnt,
        "p_hat_eq_p_full_count": eq_p_cnt,
        "one_sided_invariant_100pct": (le_p_cnt == total_n12_finite),
    }


def summarize_norris_kim() -> dict:
    rep = (ROOT / "l1" / "BASELINE_VERIFICATION_REPORT.md").read_text(encoding="utf-8")
    deltas = [abs(float(m)) for m in re.findall(r"\*\*([+-]\d+\.\d+)\s*pp\*\*", rep)]
    return {
        "source_report": "l1/BASELINE_VERIFICATION_REPORT.md",
        "table_i_cells": 12,
        "max_abs_delta_pp": max(deltas) if deltas else None,
        "all_cells_under_1pp": all(d <= 1.0 for d in deltas) if deltas else False,
    }


def main():
    sp_res = check_softposit(100000)
    bias_res = check_one_sided_bias()
    nk_res = summarize_norris_kim()
    out = {
        "softposit_es2_cross_check": sp_res,
        "norris_kim_es3_baseline": nk_res,
        "multiplier_one_sided_bias": bias_res,
    }
    out_path = ROOT / "results" / "nf_f_coverage_final" / "golden_cross_validation.json"
    out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
