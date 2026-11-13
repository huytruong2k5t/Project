"""Paired standalone MAC-NF/F measurement for report section 4.3.2."""

import argparse
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from contextlib import ExitStack
import csv
import gzip
import importlib.util
import io
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess

from measure_multiplier_prepack import (
    FILELIST, GOLDEN, NAR, check_hashes, csv_writer, execute,
    format_pct, percentile95, sha, write_json,
)

ROOT = Path(__file__).resolve().parents[1]
CORPUS = Path("results/mul_prepack_20261112")
BENCH = "tb/tb_paired_mac_accuracy.sv"
BUILD = "results/shared_parser_mul_20261107/build_{}.json"
FIXTURE_FIELDS = ("id", "pair_id", "ab_group", "a_hex", "b_hex", "c_hex",
                  "c_case", "c_clamp", "sum_class")


def freeze(run):
    rtl = (ROOT / FILELIST).read_text(encoding="ascii").split()
    rtl_files = [*rtl, FILELIST, "rtl/posit_mac.vh"]
    for variant in ("nf", "f"):
        receipt = json.loads((ROOT / BUILD.format(variant)).read_text(encoding="utf-8"))
        check_hashes(ROOT, {p: receipt["source_sha256"][p] for p in rtl_files})
    parent = ROOT / CORPUS
    prepack = json.loads((parent / "manifest.json").read_text(encoding="utf-8"))
    check_hashes(parent, {"pairs.csv": prepack["evidence_sha256"]["pairs.csv"]})
    check_hashes(ROOT, {GOLDEN: prepack["source_sha256"][GOLDEN]})
    sources = [*rtl_files, BENCH, GOLDEN, BUILD.format("nf"), BUILD.format("f"),
               "scripts/measure_multiplier_prepack.py", "scripts/measure_paired_mac_accuracy.py",
               (CORPUS / "manifest.json").as_posix(), (CORPUS / "pairs.csv").as_posix()]
    hashes = {p: sha(ROOT / p) for p in sources}
    for p in sources:
        dst = run / "source" / p
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / p, dst)
    check_hashes(run / "source", hashes)
    return rtl, hashes


def classify(product_q, total_q):
    if total_q == 0:
        return "zero"
    if product_q and abs(total_q) << 12 <= abs(product_q):
        return "near_zero"
    return "regular"


def variants(pair, golden):
    a, b = (int(pair[k], 16) for k in ("a_hex", "b_hex"))
    if NAR in (a, b):
        yield a, b, 0, "special", "", "nar"
    elif not a or not b:
        yield a, b, 0, "special", "", "zero"
    else:
        magnitude = int(pair["full_q52"]) << (golden.BASE + int(pair["sf_base"]) - 52)
        exact_p = -magnitude if pair["sign"] == "1" else magnitude
        half = (-1 if exact_p < 0 else 1) * (magnitude >> 1)
        for label, target in (("same_sign", half), ("opposite_sign", -half), ("cancel_target", -exact_p)):
            c, flags = golden.encode(target)
            clamp = "max" if flags & 8 else "min" if flags & 4 else ""
            yield a, b, c, label, clamp, classify(exact_p, exact_p + golden.value(c))


def fixtures(run, golden, jobs, smoke):
    counts = [0] * jobs
    covered = Counter()
    tmp = run / "tmp"
    source_pairs = run / "source" / CORPUS / "pairs.csv"
    with ExitStack() as stack:
        pairs = csv.DictReader(stack.enter_context(source_pairs.open(encoding="ascii", newline="")))
        vectors = [stack.enter_context((tmp / f"s{i}.vec").open("w", encoding="ascii", newline="\n"))
                   for i in range(jobs)]
        tables = [csv_writer(stack.enter_context((tmp / f"s{i}_inputs.csv").open(
            "w", encoding="ascii", newline=""))) for i in range(jobs)]
        for writer in tables:
            writer.writerow(FIXTURE_FIELDS)
        for pair in pairs:
            group = pair["group"]
            if smoke and covered[group] >= 128:
                continue
            covered[group] += 1
            for a, b, c, label, clamp, sum_class in variants(pair, golden):
                idx = sum(counts)
                shard = idx % jobs
                dn, fn = golden.golden(a, b, c, 12, 1, False)
                df, ff = golden.golden(a, b, c, 12, 1, True)
                vectors[shard].write(f"{idx+1} {a:08x} {b:08x} {c:08x} {dn:08x} {fn:02x} {df:08x} {ff:02x}\n")
                tables[shard].writerow((idx+1, pair["pair_id"], group, f"{a:08x}", f"{b:08x}", f"{c:08x}",
                                       label, clamp, sum_class))
                counts[shard] += 1
    return counts


def simulate(run, rtl, counts):
    vsim = shutil.which("vsim.exe")
    if not vsim:
        raise RuntimeError("ModelSim vsim.exe is required on PATH")
    bin_dir = Path(vsim).parent
    verify = run / "verify"
    env = dict(os.environ, TEMP=str(run / "tmp"), TMP=str(run / "tmp"))
    version = subprocess.check_output([vsim, "-version"], cwd=verify, env=env, text=True).strip()
    (verify / "run.do").write_text(
        "onerror {quit -code 1}\nonbreak {quit -code 1}\nrun -all\nquit -code 0\n", encoding="ascii")
    library = [str(bin_dir / "vlib.exe"), "work"]
    compile_cmd = [str(bin_dir / "vlog.exe"), "-sv", "-timescale", "1ns/1ps", "+incdir+../source/rtl",
                   "-work", "work", *(f"../source/{name}" for name in [*rtl, BENCH]), "-l", "compile.log"]
    execute(library, verify, env, verify / "library.log")
    execute(compile_cmd, verify, env, verify / "compile_console.log")

    def shard(i):
        stem = f"s{i}"
        args = [vsim, "-c", "work.tb_paired_mac_accuracy", f"+FIXTURE=../tmp/{stem}.vec",
                f"+OBSERVED=../tmp/{stem}_outputs.csv", "-do", "run.do", "-l", f"{stem}.log",
                "-wlf", f"../tmp/{stem}.wlf"]
        execute(args, verify, env, verify / f"{stem}_console.log")
        log = (verify / f"{stem}.log").read_text(encoding="utf-8", errors="replace")
        if not re.search(rf"^# PAIRED_MAC_PASS completed={counts[i]}\s*$", log, re.M) or re.search(
                r"\*\*\s+(Error|Fatal):", log):
            raise RuntimeError(f"Check simulation transcript {verify / (stem + '.log')}")
        print(f"PAIRED_MAC_SHARD_PASS shard={i} completed={counts[i]}", flush=True)
        return args

    with ThreadPoolExecutor(max_workers=len(counts)) as pool:
        commands = list(pool.map(shard, range(len(counts))))
    return {"version": version, "library": library, "compile": compile_cmd, "shards": commands}


def ideal(a, b, c, golden):
    sa, ma, ea = golden.decode(a)
    sb, mb, eb = golden.decode(b)
    prod = (ma * mb) << (golden.BASE + ea + eb - 52)
    return (-prod if sa != sb else prod) + golden.value(c)


def summarize(run, counts, golden):
    bins = defaultdict(Counter)
    errors = defaultdict(lambda: [[], [], [], []])
    result_fields = ("d_nf", "flags_nf", "d_f", "flags_f", "abs_nf", "abs_f",
                     "rel_nf_pct", "rel_f_pct", "accuracy")
    with (run / "samples.csv.gz").open("wb") as raw, \
         gzip.GzipFile(filename="", fileobj=raw, mode="wb", compresslevel=1, mtime=0) as compressed, \
         io.TextIOWrapper(compressed, encoding="ascii", newline="") as stream, \
         (run / "f_worse_examples.csv").open("w", encoding="ascii", newline="") as examples:
        detail = csv_writer(stream)
        sample_examples = csv_writer(examples)
        for writer in (detail, sample_examples):
            writer.writerow((*FIXTURE_FIELDS, *result_fields))
        example_counts = Counter()
        for i, expected in enumerate(counts):
            tmp = run / "tmp"
            with (tmp / f"s{i}_inputs.csv").open(encoding="ascii", newline="") as src, \
                 (tmp / f"s{i}_outputs.csv").open(encoding="ascii", newline="") as dst:
                checked = 0
                for row, output in zip(csv.DictReader(src), csv.reader(dst), strict=True):
                    if row["id"] != output[0]:
                        raise ValueError(f"Pairing mismatch: shard {i}, id {row['id']}")
                    a, b, c = (int(row[field], 16) for field in ("a_hex", "b_hex", "c_hex"))
                    dn, fn, df, ff = (int(word, 16) for word in output[1:])
                    group, case, category = (row[k] for k in ("ab_group", "c_case", "sum_class"))
                    keys = [(group, case, category), ("all", case, category)]
                    error_values = ("", "", "", "")
                    accuracy = "nar"
                    if category != "nar":
                        reference = ideal(a, b, c, golden)
                        nf = abs(golden.value(dn) - reference)
                        f = abs(golden.value(df) - reference)
                        accuracy = "f_better" if f < nf else "f_worse" if f > nf else "tie"
                        abs_values = (math.ldexp(float(nf), -golden.BASE), math.ldexp(float(f), -golden.BASE))
                        rel_values = (100 * nf / abs(reference), 100 * f / abs(reference)) if category == "regular" else ()
                        for key in keys:
                            for bucket, value in zip(errors[key], (*abs_values, *rel_values)):
                                bucket.append(value)
                        error_values = (*map(format_pct, abs_values),
                                        *(tuple(map(format_pct, rel_values)) if rel_values else ("", "")))
                    for key in keys:
                        bins[key].update(["samples", accuracy])
                        if row["c_clamp"]:
                            bins[key][f"c_clamp_{row['c_clamp']}"] += 1
                        bins[key]["nf_flags"] += bool(fn)
                        bins[key]["f_flags"] += bool(ff)
                    detail_row = (*row.values(), *output[1:], *error_values, accuracy)
                    detail.writerow(detail_row)
                    ex_key = (case, category)
                    if accuracy == "f_worse" and example_counts[ex_key] < 5:
                        sample_examples.writerow(detail_row)
                        example_counts[ex_key] += 1
                    checked += 1
                if checked != expected:
                    raise ValueError(f"Shard {i}: {checked} rows, expected {expected}")

    counters = ("samples", "f_better", "tie", "f_worse", "nar", "c_clamp_min", "c_clamp_max",
                "nf_flags", "f_flags")
    with (run / "summary.csv").open("w", encoding="ascii", newline="") as summary:
        writer = csv_writer(summary)
        writer.writerow(("ab_group", "c_case", "sum_class", *counters,
                         *(f"{x}_{stat}" for x in ("abs_nf", "abs_f", "rel_nf_pct", "rel_f_pct")
                           for stat in ("p95", "max"))))
        for key, counter in sorted(bins.items()):
            stats = []
            for bucket in errors[key]:
                bucket.sort()
                stats.extend((format_pct(bucket[percentile95(len(bucket))]), format_pct(bucket[-1]))
                             if bucket else ("", ""))
            writer.writerow((*key, *(counter[k] for k in counters), *stats))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("run", "audit"))
    parser.add_argument("tag")
    parser.add_argument("--jobs", type=int, choices=range(1, 9), default=6)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9_]+", args.tag):
        parser.error("tag must contain only letters, digits and underscores")
    project = Path.cwd()
    if not (project / FILELIST).is_file():
        parser.error("run from the Posit_MAC project root")
    run = project / "results" / args.tag
    manifest_path = run / "manifest.json"
    if args.action == "run":
        run.mkdir()
        (run / "tmp").mkdir()
        (run / "verify").mkdir()
        rtl, hashes = freeze(run)
        spec = importlib.util.spec_from_file_location("paired_golden", run / "source" / GOLDEN)
        golden = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(golden)
        counts = fixtures(run, golden, args.jobs, args.smoke)
        print(f"PAIRED_MAC_FIXTURES triples={sum(counts)} shards={len(counts)}", flush=True)
        tool = simulate(run, rtl, counts)
        summarize(run, counts, golden)
        check_hashes(ROOT, hashes)
        evidence = [run / n for n in ("samples.csv.gz", "summary.csv", "f_worse_examples.csv")]
        evidence.extend(p for p in (run / "verify").iterdir() if p.suffix in (".log", ".do"))
        evidence.extend(p for p in (run / "tmp").iterdir() if p.suffix in (".vec", ".csv"))
        write_json(manifest_path, {
            "status": "SMOKE_PASS" if args.smoke else "PASS", "ops": 1, "n": 12,
            "seed_ab": 20261112, "c": ["R(P/2)", "R(-P/2)", "R(-P)", "C=0 for special A/B"],
            "near_zero": "0 < abs(P+C) <= abs(P) / 4096",
            "triples": sum(counts), "counts": counts, "mismatches_per_core": 0,
            "source_sha256": hashes, "simulator": tool,
            "evidence_sha256": {p.relative_to(run).as_posix(): sha(p) for p in sorted(evidence)},
        })
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    check_hashes(run / "source", manifest["source_sha256"])
    check_hashes(run, manifest["evidence_sha256"])
    print(f"PAIRED_MAC_{manifest['status']} triples={manifest['triples']} mismatches=0", flush=True)


if __name__ == "__main__":
    main()
