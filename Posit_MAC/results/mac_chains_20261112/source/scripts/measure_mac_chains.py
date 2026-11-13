"""Measure NF/F external feedback and current quire with matched command streams."""

import argparse
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from contextlib import ExitStack
import csv
import importlib.util
import json
import math
import os
from pathlib import Path
import random
import re
import shutil
import statistics
import subprocess

from measure_multiplier_prepack import FILELIST, GOLDEN, check_hashes, csv_writer, execute, sha, write_json
from measure_paired_mac_accuracy import ideal

SOURCE = Path(__file__).resolve().parents[1]
Q_LIST = "rtl/quire_active.f"
Q_ORACLE = "scripts/gen_quire_vectors.py"
BENCH = "tb/tb_mac_chain_benchmark.sv"
BUILD = "results/shared_parser_mul_20261107/build_{}.json"
VARIANTS = ("nf", "f", "quire")
GROUPS = ("same_sign", "alternating", "near_cancel")
SEED = 20261112


def freeze(run):
    mac = (SOURCE / FILELIST).read_text(encoding="ascii").split()
    quire = (SOURCE / Q_LIST).read_text(encoding="ascii").split()
    receipts = [BUILD.format(v) for v in VARIANTS[:2]]
    for rel in receipts:
        reference = json.loads((SOURCE / rel).read_text())["source_sha256"]
        check_hashes(SOURCE, {p: reference[p] for p in [*mac, FILELIST, "rtl/posit_mac.vh"]})
    rtl = list(dict.fromkeys([*mac, *quire]))
    inputs = [*rtl, FILELIST, Q_LIST, "rtl/posit_mac.vh", *receipts, BENCH, GOLDEN, Q_ORACLE,
              "scripts/measure_multiplier_prepack.py", "scripts/measure_paired_mac_accuracy.py",
              "scripts/measure_mac_chains.py"]
    hashes = {name: sha(SOURCE / name) for name in inputs}
    for name in inputs:
        dst = run / "source" / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(SOURCE / name, dst)
    check_hashes(run / "source", hashes)
    return rtl, hashes


def oracle(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def pairs_for(rng, length, group):
    count = length // 2 if group == "near_cancel" else length
    pairs = [(rng.randrange(0x3C000000, 0x44000000), rng.randrange(0x3C000000, 0x44000000))
             for _ in range(count)]
    if group == "alternating":
        return [(((-a) & 0xFFFFFFFF) if i % 2 else a, b) for i, (a, b) in enumerate(pairs)]
    if group == "near_cancel":
        mirrored = [((-a) & 0xFFFFFFFF, b) for a, b in pairs]
        a, b = pairs[-1]
        mirrored[-1] = ((-(a ^ 1)) & 0xFFFFFFFF, b)
        return pairs + mirrored
    return pairs


def make_fixtures(run, golden, quire, smoke):
    rng = random.Random(SEED)
    metadata = {}
    counts = defaultdict(int)
    with ExitStack() as stack:
        vectors = {v: stack.enter_context((run / "tmp" / f"{v}.vec").open(
            "w", encoding="ascii", newline="\n")) for v in VARIANTS}
        stream = stack.enter_context((run / "chains.csv").open("w", encoding="ascii", newline=""))
        table = csv_writer(stream)
        table.writerow(("sequence_id", "group", "length", "replicate", "step", "a_hex", "b_hex"))
        for group in GROUPS:
            for length in ((16,) if smoke else (16, 64, 256, 1024)):
                for replicate in range(1 if smoke else 4):
                    idx = len(metadata) + 1
                    states = {"nf": 0, "f": 0}
                    q = quire.State()
                    reference = 0
                    vectors["quire"].write(f"{idx} 0 0 0 0 0 0 0 0\n")
                    for i, (a, b) in enumerate(pairs_for(rng, length, group), 1):
                        table.writerow((idx, group, length, replicate + 1, i, f"{a:08x}", f"{b:08x}"))
                        reference += ideal(a, b, 0, golden)
                        for v in VARIANTS[:2]:
                            d, flags = golden.golden(a, b, states[v], 12, 1, v == "f")
                            states[v] = d
                            vectors[v].write(f"{idx} 1 {a:08x} {b:08x} {d:08x} {flags:02x} 0 {i} {int(i==length)}\n")
                        q.mac(a, b)
                        d, flags = q.response(1)
                        vectors["quire"].write(f"{idx} 1 {a:08x} {b:08x} {d:08x} {flags:02x} {q.q & quire.MASK:0243x} {i} 0\n")
                    d, flags = q.response(2)
                    vectors["quire"].write(f"{idx} 2 0 0 {d:08x} {flags:02x} {q.q & quire.MASK:0243x} {length} 1\n")
                    metadata[idx] = (group, length, replicate + 1, reference)
                    for v in VARIANTS:
                        counts[v] += length + (2 if v == "quire" else 0)
    return metadata, counts


def simulate(run, rtl, counts, sequences):
    vsim = shutil.which("vsim.exe")
    if not vsim:
        raise RuntimeError("ModelSim is required on PATH")
    bin_dir = Path(vsim).parent
    work = run / "verify"
    env = dict(os.environ, TEMP=str(run / "tmp"), TMP=str(run / "tmp"))
    version = subprocess.check_output([vsim, "-version"], cwd=work, env=env, text=True).strip()
    (work / "run.do").write_text(
        "onerror {quit -code 1}\nonbreak {quit -code 1}\nrun -all\nquit -code 0\n", encoding="ascii")
    library = [str(bin_dir / "vlib.exe"), "work"]
    compile_cmd = [str(bin_dir / "vlog.exe"), "-sv", "-timescale", "1ns/1ps", "+incdir+../source/rtl",
                   "-work", "work", *(f"../source/{name}" for name in [*rtl, BENCH]), "-l", "compile.log"]
    execute(library, work, env, work / "library.log")
    execute(compile_cmd, work, env, work / "compile_console.log")

    def variant(item):
        i, v = item
        args = [vsim, "-c", "work.tb_mac_chain_benchmark", f"-gCORE={i}",
                f"+FIXTURE=../tmp/{v}.vec", f"+RESULTS=../tmp/{v}.csv",
                "-do", "run.do", "-l", f"{v}.log", "-wlf", f"../tmp/{v}.wlf"]
        execute(args, work, env, work / f"{v}_console.log")
        marker = f"MAC_CHAIN_PASS core={i} commands={counts[v]} sequences={sequences}"
        log = (work / f"{v}.log").read_text(encoding="utf-8", errors="replace")
        if not re.search(rf"^# {marker}\s*$", log, re.M) or re.search(r"\*\*\s+(Error|Fatal):", log):
            raise RuntimeError(f"Check {work / (v + '.log')}")
        print(marker, flush=True)
        return args

    with ThreadPoolExecutor(max_workers=3) as pool:
        commands = list(pool.map(variant, enumerate(VARIANTS)))
    return {"version": version, "library": library, "compile": compile_cmd, "commands": commands}


def summarize(run, meta, golden):
    groups = defaultdict(list)
    with (run / "results.csv").open("w", encoding="ascii", newline="") as f:
        table = csv_writer(f)
        table.writerow(("sequence_id", "group", "length", "replicate", "core", "cycles",
                        "d_hex", "flags_hex", "ideal_q532", "abs_error_q532", "abs_error", "rel_error_pct"))
        for v in VARIANTS:
            with (run / "tmp" / f"{v}.csv").open(encoding="ascii", newline="") as output:
                for idx, row in zip(meta, csv.DictReader(output), strict=True):
                    if int(row["sequence_id"]) != idx:
                        raise ValueError(f"Wrong sequence order for {v}")
                    group, length, replicate, reference = meta[idx]
                    error = abs(golden.value(int(row["d_hex"], 16)) - reference)
                    cycles = int(row["cycles"])
                    absolute = math.ldexp(float(error), -golden.BASE)
                    relative = f"{100 * error / abs(reference):.12g}" if reference else ""
                    groups[group, length, v].append((cycles, absolute))
                    table.writerow((idx, group, length, replicate, v, cycles, row["d_hex"],
                                    row["flags_hex"], reference, error, f"{absolute:.12g}", relative))
    with (run / "summary.csv").open("w", encoding="ascii", newline="") as f:
        table = csv_writer(f)
        table.writerow(("group", "length", "core", "sequences", "cycles_min", "cycles_median",
                        "cycles_max", "abs_error_median", "abs_error_max"))
        for key, values in sorted(groups.items()):
            cycles, errors = zip(*values)
            table.writerow((*key, len(cycles), min(cycles), statistics.median(cycles), max(cycles),
                            f"{statistics.median(errors):.12g}", f"{max(errors):.12g}"))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=("run", "audit"))
    p.add_argument("tag")
    p.add_argument("--smoke", action="store_true")
    args = p.parse_args()
    project = Path.cwd()
    if not (project / FILELIST).is_file() or not re.fullmatch(r"[a-zA-Z0-9_]+", args.tag):
        p.error("run from Posit_MAC with a simple tag")
    run = project / "results" / args.tag
    if args.action == "run":
        run.mkdir()
        (run / "tmp").mkdir()
        (run / "verify").mkdir()
        rtl, hashes = freeze(run)
        golden = oracle(run / "source" / GOLDEN, "chain_mac_oracle")
        quire = oracle(run / "source" / Q_ORACLE, "chain_quire_oracle")
        meta, counts = make_fixtures(run, golden, quire, args.smoke)
        tool = simulate(run, rtl, counts, len(meta))
        summarize(run, meta, golden)
        check_hashes(SOURCE, hashes)
        evidence = [run / n for n in ("chains.csv", "results.csv", "summary.csv")]
        evidence.extend(p for p in (run / "verify").iterdir() if p.suffix in (".log", ".do"))
        evidence.extend(p for p in (run / "tmp").iterdir() if p.suffix in (".vec", ".csv"))
        write_json(run / "manifest.json", {
            "status": "SMOKE_PASS" if args.smoke else "PASS", "ops": 1, "n": 12, "seed": SEED,
            "sequences": len(meta), "commands": counts, "mismatches": 0,
            "cycles": "inclusive, from first input handshake to last output handshake; quire includes CLEAR and READ",
            "source_sha256": hashes, "simulator": tool,
            "evidence_sha256": {p.relative_to(run).as_posix(): sha(p) for p in sorted(evidence)},
        })
    manifest = json.loads((run / "manifest.json").read_text())
    check_hashes(run / "source", manifest["source_sha256"])
    check_hashes(run, manifest["evidence_sha256"])
    print(f"MAC_CHAINS_{manifest['status']} sequences={manifest['sequences']} mismatches=0", flush=True)


if __name__ == "__main__":
    main()
