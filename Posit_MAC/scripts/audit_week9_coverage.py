"""Audit the frozen multiplier fixtures; never equate generated rows with RTL pass.

Reset-aborted row indices follow multiplier_checker.sv. Only a PASS summary
makes the surviving rows observed RTL comparisons. The operand decoder below
is independent of L1 and is used solely for functional coverage.
"""
import argparse
import collections
import hashlib
import json
from pathlib import Path

GROUPS = ((1, 3), (4, 7), (8, 11), (12, 15), (16, 17),
          (18, 22), (23, 27), (28, 31))
ROOT = Path(__file__).resolve().parents[1]


def decode(raw, nb, es, width):
    mask, nar = (1 << nb) - 1, 1 << (nb - 1)
    if raw in (0, nar):
        return None
    sign = int(bool(raw & nar))
    magnitude = (-raw & mask) if sign else raw
    bit, run = nb - 2, 0
    polarity = (magnitude >> bit) & 1
    while bit >= 0 and ((magnitude >> bit) & 1) == polarity:
        run += 1
        bit -= 1
    if bit >= 0:
        bit -= 1
    bit = max(-1, bit - es)
    fraction_bits = bit + 1
    fraction = magnitude & ((1 << fraction_bits) - 1)
    fraction = (fraction << (width - fraction_bits)) if width >= fraction_bits else (
        fraction >> (fraction_bits - width))
    group = next(i for i, (lo, hi) in enumerate(GROUPS) if lo <= run <= hi)
    return group, sign, polarity, run, fraction.bit_count()


def count_bin(count):
    return str(count) if count <= 2 else ("3-4" if count <= 4 else (
        "5-8" if count <= 8 else ">8"))


def audit(directory, summary_path=None, output=None):
    summary_path = summary_path or directory / "summary.json"
    passed = summary_path.exists() and json.loads(summary_path.read_text(
        encoding="utf-8-sig")).get("status") == "PASS"
    reported = json.loads(summary_path.read_text(encoding="utf-8-sig")) if passed else {}
    reported_profiles = {p["profile"]: p for p in reported.get("profiles", [])}
    profiles = []
    for fixture in sorted(directory.glob("mul_*.txt")):
        nb, es, scheme, rounding = map(int, fixture.stem.split("_")[1:])
        digest = hashlib.sha256(fixture.read_bytes()).hexdigest()
        if fixture.stem in reported_profiles and digest != reported_profiles[fixture.stem]["fixtureSHA256"]:
            raise RuntimeError("frozen fixture hash differs from the RTL PASS record")
        grid, runs, config, population, iterations = [collections.Counter() for _ in range(5)]
        rows = aborts = special = 0
        for row, line in enumerate(fixture.open(encoding="ascii")):
            a, b, mode, n, ops, _, _, actual = [int(field, 16) for field in line.split()]
            rows += 1
            if row % 211 == 100:
                aborts += 1
                continue
            config[f"{mode}/{ops}/{n}"] += 1
            iteration_bin=str(actual) if actual <= 4 else ("5-8" if actual <= 8 else ">8")
            iterations[f"{mode}/{iteration_bin}"] += 1
            width = min(nb - 3 - es, 12) if mode else nb - 3 - es
            da, db = decode(a, nb, es, width), decode(b, nb, es, width)
            for operand in (da, db):
                if operand:
                    runs[f"{operand[2]}/{operand[3]}"] += 1
            if not da or not db:
                special += 1
                continue
            grid[f"{da[0]}/{db[0]}/{2*da[1]+db[1]}"] += 1
            selected = min(da[4], db[4]) if ops else da[4]
            population[f"{mode}/{count_bin(selected)}"] += 1
        groups = [i for i, (lo, _) in enumerate(GROUPS) if lo <= nb - 1]
        valid_grid = [f"{ga}/{gb}/{sign}" for ga in groups for gb in groups for sign in range(4)]
        valid_runs = [f"{pol}/{run}" for pol in range(2) for run in range(1, nb)
                      if not (pol == 0 and run == nb - 1)]
        excluded = [f"polarity=0/run={nb-1} is Zero, not finite",
                    "empty regime groups: "+str([i for i in range(8) if i not in groups]),
                    "approx iteration >8 is impossible with N_MAX=8"]
        if nb - 3 - es <= 8:
            excluded.extend(["exact iteration >8 exceeds FRAC_MAX",
                             "selected fraction popcount >8 exceeds active width in both modes"])
        profiles.append({
            "profile": fixture.stem, "fixture_sha256": digest,
            "rows": rows, "reset_aborts": aborts,
            "surviving_rows": rows - aborts, "special_pairs": special,
            "valid_regime_cross_bins": len(valid_grid),
            "hit_regime_cross_bins": sum(bool(grid[k]) for k in valid_grid),
            "minimum_regime_cross_count": min(grid[k] for k in valid_grid),
            "bins_below_4000": [k for k in valid_grid if grid[k] < 4000],
            "finite_run_minimum_operands": min(runs[k] for k in valid_runs),
            "finite_runs_below_10000": [k for k in valid_runs if runs[k] < 10000],
            "regime_cross": dict(sorted(grid.items())),
            "finite_runs": dict(sorted(runs.items())),
            "config_cells": dict(sorted(config.items())),
            "selected_fraction_popcount": dict(sorted(population.items())),
            "actual_iteration_bins": dict(sorted(iterations.items())),
            "excluded_bins": excluded,
        })
    if len(profiles) != 16:
        raise RuntimeError("expected all sixteen frozen profile fixtures")
    if passed:
        if sum(p["surviving_rows"] for p in profiles) != reported["comparedTransactions"]:
            raise RuntimeError("surviving coverage rows disagree with RTL PASS summary")
    result = {
        "status": "OBSERVED RTL PASS" if passed else "PLANNED FIXTURE COVERAGE; RTL RUN NOT COMPLETE",
        "scope": "functional input/iteration coverage; no line/branch/toggle measurement",
        "reset_abort_rule": "zero-based row % 211 == 100; excluded from all comparison bins",
        "profiles": profiles,
        "Gate2": "NOT ACCEPTED: strict lint, official engine and structural coverage review required",
    }
    output = output or directory / "functional_coverage.json"
    output.write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(result["status"])
    for profile in profiles:
        print(profile["profile"], "regime bins", profile["hit_regime_cross_bins"],
              "/", profile["valid_regime_cross_bins"], "minimum", profile["minimum_regime_cross_count"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", help="existing fixture directory inside Posit_MAC")
    parser.add_argument("--rtl-summary", help="PASS summary from a separate runner directory")
    parser.add_argument("--output", help="report destination inside Posit_MAC")
    args = parser.parse_args()
    directory = Path(args.directory).resolve()
    if not directory.is_dir() or not directory.is_relative_to(ROOT):
        raise RuntimeError("fixture directory must stay inside Posit_MAC")
    summary_path = Path(args.rtl_summary).resolve() if args.rtl_summary else None
    output = Path(args.output).resolve() if args.output else None
    for path in (summary_path, output):
        if path and not path.is_relative_to(ROOT):
            raise RuntimeError("all report paths must stay inside Posit_MAC")
    audit(directory, summary_path, output)
