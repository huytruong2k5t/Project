#!/usr/bin/env python3
"""Measure MAC-F's pre-Packer multiplier on the report's fixed A/B corpus."""

import argparse
import csv
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from functools import lru_cache
import gzip
import hashlib
import importlib.util
import io
from itertools import product
import json
import os
from pathlib import Path
import random
import re
import shutil
import subprocess
import sys
import time


SOURCE = Path(__file__).resolve().parents[1]
RECEIPT = "results/shared_parser_mul_20261107/build_f.json"
FILELIST = "rtl/mac_active.f"
GOLDEN = "scripts/gen_refactored_mac_vectors.py"
BENCH = "tb/tb_multiplier_prepack.sv"
SEED = 20261112
NAR = 0x80000000
MASK = 0xFFFFFFFF
REGIME_RUNS = ((1, 3), (4, 7), (8, 11), (12, 15),
               (16, 17), (18, 22), (23, 27), (28, 31))
GROUPS = ("uniform_raw", "stratified_regime", "directed_finite", "directed_zero", "directed_nar")
METRICS = ("total_rel", "input_rel", "iteration_rel")
CAPTURE_FIELDS = ("pair_id", "m_q24", "sf_base", "sign", "iterations",
                  "input_cut", "iteration_cut", "d_hex", "flags_hex")


@dataclass(frozen=True)
class Baselines:
    full_q52: int
    trunc_q24: int
    sign: int
    sf_base: int
    x_bits: tuple[int, ...]
    y_q12: int
    input_cut: bool


@dataclass(frozen=True)
class Pair:
    group: str
    label: str
    a: int
    b: int
    baseline: Baselines | None


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def check_hashes(root, hashes):
    for rel, expected in hashes.items():
        if sha(root / rel) != expected:
            raise ValueError(f"SHA-256 mismatch: {root / rel}")


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def snapshot(run):
    rtl = (SOURCE / FILELIST).read_text(encoding="ascii").split()
    receipt = json.loads((SOURCE / RECEIPT).read_text(encoding="utf-8"))
    locked = {p: receipt["source_sha256"][p] for p in [*rtl, FILELIST, "rtl/posit_mac.vh"]}
    check_hashes(SOURCE, locked)
    hashes = dict(locked)
    for rel in (RECEIPT, GOLDEN, BENCH, "scripts/measure_multiplier_prepack.py"):
        hashes[rel] = sha(SOURCE / rel)
    for rel in hashes:
        target = run / "source" / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(SOURCE / rel, target)
    check_hashes(run / "source", hashes)
    return rtl, hashes


def raw_finite(rng):
    while True:
        raw = rng.getrandbits(32)
        if raw not in (0, NAR):
            return raw


def regime_raw(rng, group, sign):
    lo, hi = REGIME_RUNS[group]
    run, polarity = rng.choice([(r, p) for r in range(lo, hi + 1)
                                for p in (0, 1) if r != 31 or p == 1])
    magnitude = ((1 << run) - 1) << (31 - run) if polarity else 1 << (30 - run)
    if run < 31:
        magnitude |= rng.getrandbits(30 - run)
    return (-magnitude) & MASK if sign else magnitude


def exact_baselines(a, b, decode):
    sign_a, coeff_a, sf_a = decode(a)
    sign_b, coeff_b, sf_b = decode(b)
    sig_a, sig_b = coeff_a >> 14, coeff_b >> 14
    frac_a, frac_b = sig_a & 4095, sig_b & 4095
    # OPS=1. Ties keep A in the X role.
    if frac_b.bit_count() < frac_a.bit_count():
        x, y = frac_b, sig_a
    else:
        x, y = frac_a, sig_b
    bits = tuple(1 << bit for bit in range(11, -1, -1) if x & (1 << bit))
    return Baselines(coeff_a * coeff_b, sig_a * sig_b, int(sign_a != sign_b),
                     sf_a + sf_b, bits, y, bool((coeff_a | coeff_b) & 16383))


def corpus(decode, uniform_count, per_regime):
    rng = random.Random(SEED)
    pairs = []

    def add(group, label, a, b):
        baseline = None
        if NAR in (a, b):
            group = "directed_nar"
        elif 0 in (a, b):
            group = "directed_zero"
        else:
            baseline = exact_baselines(a, b, decode)
        pairs.append(Pair(group, label, a, b, baseline))

    for _ in range(uniform_count):
        add("uniform_raw", "", raw_finite(rng), raw_finite(rng))

    for ga, gb, sa, sb in product(range(8), range(8), range(2), range(2)):
        for _ in range(per_regime):
            add("stratified_regime", f"g{ga}_g{gb}_s{sa}_s{sb}",
                regime_raw(rng, ga, sa), regime_raw(rng, gb, sb))

    special = (0, NAR, 1, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000001, 0x40000000, 0xC0000000)
    for a, b in product(special, repeat=2):
        add("directed_finite", "extremes", a, b)

    one, dense_q12 = 0x40000000, 0x43FFC000
    for count in range(13):
        sparse = one | (((1 << count) - 1) << 14)
        add("directed_finite", f"ops_popcount_{count}_a", sparse, dense_q12)
        add("directed_finite", f"ops_popcount_{count}_b", dense_q12, (-sparse) & MASK)

    for label, a, b in (
        ("ft05", 0x1C900000, 0x3C820000),
        ("same_popcount_different_bits", 0x42000000, 0x40004000),
        ("alternating_fraction", one | (0xAAA << 14), one | (0x555 << 14)),
        ("only_input_cut", one + 1, one + 1),
        ("full_fraction", 0x43FFFFFF, 0x43FFFFFF),
        ("regime_transition", 0x3FFFFFFF, 0x60000000),
    ):
        add("directed_finite", label, a, b)
    return pairs


def csv_writer(stream):
    return csv.writer(stream, lineterminator="\n")


def write_pairs(run, pairs):
    with (run / "pairs.csv").open("w", encoding="ascii", newline="") as table, \
         (run / "tmp/pairs.vec").open("w", encoding="ascii", newline="\n") as fixture:
        writer = csv_writer(table)
        writer.writerow(("pair_id", "group", "case", "a_hex", "b_hex",
                         "full_q52", "trunc_q24", "sf_base", "sign", "ops_popcount_x"))
        for index, pair in enumerate(pairs, 1):
            ref = pair.baseline
            a, b = f"{pair.a:08x}", f"{pair.b:08x}"
            values = (ref.full_q52, ref.trunc_q24, ref.sf_base, ref.sign, len(ref.x_bits)) if ref else ("",) * 5
            writer.writerow((index, pair.group, pair.label, a, b, *values))
            fixture.write(f"{index} {a} {b}\n")


def execute(args, cwd, env, logfile):
    with logfile.open("wb") as log:
        code = subprocess.run(args, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT).returncode
    if code:
        raise RuntimeError(f"{Path(args[0]).name} exited {code}. See {logfile}")


def capture(run, rtl, count, jobs):
    simulator = shutil.which("vsim.exe")
    if not simulator:
        raise RuntimeError("ModelSim vsim.exe must be on PATH")
    bin_dir = Path(simulator).parent
    verify = run / "verify"
    verify.mkdir()
    env = os.environ.copy()
    env["TEMP"] = env["TMP"] = str(run / "tmp")
    version = subprocess.check_output([simulator, "-version"], cwd=verify, env=env, text=True).strip()
    (verify / "run.do").write_text(
        "onerror {quit -code 1}\nonbreak {quit -code 1}\nrun -all\nquit -code 0\n", encoding="ascii"
    )
    library = [str(bin_dir / "vlib.exe"), "work"]
    compile_cmd = [str(bin_dir / "vlog.exe"), "-sv", "-timescale", "1ns/1ps", "+incdir+../source/rtl",
                   "-work", "work", *(f"../source/{name}" for name in [*rtl, BENCH]), "-l", "compile.log"]
    execute(library, verify, env, verify / "library.log")
    execute(compile_cmd, verify, env, verify / "compile_console.log")

    def simulate(n):
        stem = f"n{n:02d}"
        command = [simulator, "-c", "work.tb_multiplier_prepack", f"+N={n}", "+PAIRS=../tmp/pairs.vec",
                   f"+OBSERVED=../tmp/{stem}.csv", "-do", "run.do", "-l", f"{stem}.log",
                   "-wlf", f"../tmp/{stem}.wlf"]
        start = time.monotonic()
        execute(command, verify, env, verify / f"{stem}_console.log")
        log = (verify / f"{stem}.log").read_text(encoding="utf-8", errors="replace")
        marker = f"MULTIPLIER_PREPACK_CAPTURED n={n} rows={count}"
        if not re.search(rf"^# {marker}\s*$", log, re.MULTILINE) or re.search(r"\*\*\s+(Error|Fatal):", log):
            raise RuntimeError(f"Capture did not complete: {verify / (stem + '.log')}")
        elapsed = round(time.monotonic() - start, 2)
        print(f"{marker} elapsed_s={elapsed}", flush=True)
        return {"n": n, "captured": count, "elapsed_s": elapsed, "command": command}

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        runs = list(pool.map(simulate, range(13)))
    return {"version": version, "library": library, "compile": compile_cmd, "runs": runs}


def percentile95(count):
    """Zero-based nearest-rank index for an ascending nonempty sample."""
    return (95 * count + 99) // 100 - 1


def format_pct(value):
    return f"{value:.12g}"


def analyze(run, pairs, golden):
    @lru_cache(maxsize=160_000)
    def packed(magnitude, sf_base, sign):
        scaled = magnitude << (golden.BASE + sf_base - 24)
        return golden.encode(-scaled if sign else scaled)

    fields = ("ops", "n", "group", "samples", "relative_samples", "mismatches",
              "rounds_min", "rounds_mean", "rounds_p95", "rounds_max", "early_stop",
              "input_cut_count", "iteration_cut_count",
              *(f"{metric}_{suffix}" for metric in METRICS for suffix in ("p95_pct", "max_pct", "max_pair_id")))
    counts = {group: sum(pair.group == group for pair in pairs) for group in GROUPS}
    with (run / "summary.csv").open("w", encoding="ascii", newline="") as summary, \
         (run / "rounds_hist.csv").open("w", encoding="ascii", newline="") as histogram, \
         (run / "samples.csv.gz").open("wb") as compressed, \
         gzip.GzipFile(filename="", mode="wb", fileobj=compressed, compresslevel=1, mtime=0) as gzip_stream, \
         io.TextIOWrapper(gzip_stream, encoding="ascii", newline="") as detail:
        summary_writer, hist_writer, detail_writer = map(csv_writer, (summary, histogram, detail))
        summary_writer.writerow(fields)
        hist_writer.writerow(("ops", "n", "group", *(f"t{t}" for t in range(13))))
        detail_writer.writerow(("n", *CAPTURE_FIELDS, *(f"{metric}_pct" for metric in METRICS)))
        for n in range(13):
            rounds = {group: [0] * 13 for group in GROUPS}
            cuts = {group: [0, 0] for group in GROUPS}
            errors = {group: [[], [], []] for group in GROUPS}
            with (run / "tmp" / f"n{n:02d}.csv").open(encoding="ascii", newline="") as stream:
                rows = csv.reader(stream)
                if tuple(next(rows)) != CAPTURE_FIELDS:
                    raise ValueError(f"Unexpected observation columns for n={n}")
                for (index, pair), row in zip(enumerate(pairs, 1), rows, strict=True):
                    read_id, *observed = map(int, row[:-2])
                    observed.extend(int(field, 16) for field in row[-2:])
                    ref = pair.baseline
                    if ref:
                        t = min(n, len(ref.x_bits))
                        magnitude = (4096 + sum(ref.x_bits[:t])) * ref.y_q12
                        iteration_cut = t != len(ref.x_bits)
                        d, flags = packed(magnitude, ref.sf_base, ref.sign)
                        flags |= (2 if ref.input_cut or iteration_cut else 0) | int(iteration_cut)
                        expected = (magnitude, ref.sf_base, ref.sign, t, ref.input_cut, iteration_cut, d, flags)
                    else:
                        nar = pair.group == "directed_nar"
                        expected = (0, 0, 0, 0, 0, 0, NAR if nar else 0, 16 if nar else 0)

                    if read_id != index or tuple(observed) != expected:
                        raise ValueError(
                            f"n={n} pair_id={index} A={pair.a:08x} B={pair.b:08x}: "
                            f"observed pair={read_id} {tuple(observed)}, expected {expected}"
                        )
                    m, _, _, t, cut_in, cut_iter, _, _ = observed
                    rounds[pair.group][t] += 1
                    cuts[pair.group][0] += cut_in
                    cuts[pair.group][1] += cut_iter
                    relative = ()
                    if ref:
                        # Align Q24 coefficients to Q52. The power of two and
                        # sign cancel, so relative errors stay well scaled.
                        trunc_q52 = ref.trunc_q24 << 28
                        measured_q52 = m << 28
                        if not measured_q52 <= trunc_q52 <= ref.full_q52 or (n == 12 and m != ref.trunc_q24):
                            raise ValueError(f"Unexpected magnitude ordering at n={n}, pair_id={index}")
                        relative = (100 * (ref.full_q52 - measured_q52) / ref.full_q52,
                                    100 * (ref.full_q52 - trunc_q52) / ref.full_q52,
                                    100 * (ref.trunc_q24 - m) / ref.trunc_q24)
                        for population, error in zip(errors[pair.group], relative, strict=True):
                            population.append((error, index))
                    error_cells = tuple(map(format_pct, relative)) if relative else ("",) * 3
                    detail_writer.writerow((n, *row, *error_cells))

            for group in GROUPS:
                hist = rounds[group]
                count = counts[group]
                t_values = [t for t, freq in enumerate(hist) for _ in range(freq)]
                stats = []
                for population in errors[group]:
                    if population:
                        population.sort()
                        p95, _ = population[percentile95(len(population))]
                        maximum, index = population[-1]
                        stats.extend((format_pct(p95), format_pct(maximum), index))
                    else:
                        stats.extend(("", "", ""))
                summary_writer.writerow(
                    (1, n, group, count, len(errors[group][0]), 0, t_values[0],
                     format_pct(sum(t_values) / count), t_values[percentile95(count)], t_values[-1],
                     sum(hist[:n]) if group in GROUPS[:3] else "", *cuts[group], *stats)
                )
                hist_writer.writerow((1, n, group, *hist))
            print(f"MULTIPLIER_PREPACK_MATCH n={n} rows={len(pairs)} mismatches=0", flush=True)
    return counts


def run_benchmark(run, smoke, jobs):
    run.mkdir()
    (run / "tmp").mkdir()
    rtl, source_hashes = snapshot(run)
    spec = importlib.util.spec_from_file_location("prepack_golden", run / "source" / GOLDEN)
    golden = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(golden)
    uniform_count, per_regime = (256, 1) if smoke else (100_000, 100)
    pairs = corpus(golden.decode, uniform_count, per_regime)
    write_pairs(run, pairs)
    fixture_hash = sha(run / "tmp/pairs.vec")
    simulator = capture(run, rtl, len(pairs), jobs)
    counts = analyze(run, pairs, golden)
    check_hashes(run / "source", source_hashes)
    check_hashes(SOURCE, source_hashes)
    check_hashes(run, {"tmp/pairs.vec": fixture_hash})
    evidence = ["pairs.csv", "tmp/pairs.vec", "summary.csv", "rounds_hist.csv", "samples.csv.gz",
                "verify/run.do", "verify/library.log", "verify/compile.log", "verify/compile_console.log",
                *(f"verify/n{n:02d}{suffix}.log" for n in range(13) for suffix in ("", "_console"))]
    manifest = {
        "status": "SMOKE_PASS" if smoke else "PASS",
        "scope": "Posit(32,3) MAC-F, C=0, FULL_TERM26/Q24 product at core_done before normalization and packing",
        "source_receipt": RECEIPT,
        "source_sha256": source_hashes,
        "seed": SEED,
        "rng": "Python random.Random (MT19937)",
        "python": sys.version,
        "ops": 1,
        "n": list(range(13)),
        "uniform_count": uniform_count,
        "regime_pairs_per_cell": per_regime,
        "regime_run_bins": REGIME_RUNS,
        "pair_counts": counts,
        "comparisons": len(pairs) * 13,
        "mismatches": 0,
        "p95": "nearest rank, ceil(0.95 * count), on finite nonzero products within each group",
        "simulator": simulator,
        "evidence_sha256": {rel: sha(run / rel) for rel in evidence},
    }
    write_json(run / "manifest.json", manifest)
    audit(run)


def audit(run):
    manifest = json.loads((run / "manifest.json").read_text(encoding="utf-8"))
    check_hashes(run / "source", manifest["source_sha256"])
    check_hashes(run, manifest["evidence_sha256"])
    print(f"MULTIPLIER_PREPACK_{manifest['status']} comparisons={manifest['comparisons']} mismatches=0", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("run", "audit"))
    parser.add_argument("tag", help="Directory name under Posit_MAC/results")
    parser.add_argument("--jobs", type=int, choices=range(1, 9), default=4)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9_]+", args.tag):
        parser.error("tag must contain only letters, digits and underscores")
    project = Path.cwd()
    if not (project / FILELIST).is_file():
        parser.error("run from the Posit_MAC project root")
    run = project / "results" / args.tag
    if args.action == "audit":
        audit(run)
    else:
        run_benchmark(run, args.smoke, args.jobs)


if __name__ == "__main__":
    main()
