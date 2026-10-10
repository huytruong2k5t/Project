"""Accept the Week9 multiplier milestone only from completed, linked evidence."""
import hashlib
import itertools
import json
import re
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
base = root / "results/week9_multiplier"
run = base / "verilator/gate2_stratified"
read = lambda path: json.loads(path.read_text(encoding="utf-8-sig"))
summary = read(run / "summary.json")
functional = read(run / "functional_coverage.json")
structure = read(run / "structural_coverage.json")
assert summary["status"] == "PASS" and summary["completed"] >= 10_000_000
assert summary["mismatches"] == 0 and summary["l1_checks"] == summary["fixture_rows"]
assert functional["status"] == "OBSERVED RTL PASS"
assert len(summary["profiles"]) == len(functional["profiles"]) == 16
for profile in functional["profiles"]:
    assert not profile["bins_below_4000"] and not profile["finite_runs_below_10000"]
    assert profile["hit_regime_cross_bins"] == profile["valid_regime_cross_bins"]
    assert len(profile["config_cells"]) == 36 and min(profile["config_cells"].values()) > 0
lint = root / "results/week9_implementation/lint_gate2"
logs = list(lint.glob("*.log"))
logs = [path for path in logs if path.name != "version.log"]
assert len(logs) == 16
for line in (lint / "source.sha256").read_text().splitlines():
    digest, relative = line.split(maxsplit=1)
    source = root / relative.strip()
    assert source.resolve().is_relative_to(root.resolve())
    assert hashlib.sha256(source.read_bytes()).hexdigest() == digest, "stale lint source"
for path in logs:
    assert "%Warning" not in path.read_text() and "%Error" not in path.read_text()
assert len(structure["profiles"]) == 16
assert all(set(p["metrics"]) >= {"line", "branch", "toggle"} for p in structure["profiles"])
modelsim = read(base / "gate2_corners_modelsim/summary.json")
assert modelsim["status"] == "PASS" and modelsim["mismatches"] == 0
corners = []
pattern = re.compile(r"PASS rows=(\d+) completed=(\d+) reset_aborts=(\d+) "
                     r"long_stalls=(\d+) mismatches=0 L1_checks=(\d+) "
                     r"L0_checks=(\d+) ES3_checks=(\d+)")
for observed in modelsim["profiles"]:
    name = observed["profile"]
    nb = int(name.split("_")[1])
    fixture = base / "gate2_cornercorpus" / (name + ".txt")
    assert hashlib.sha256(fixture.read_bytes()).hexdigest() == observed["fixtureSHA256"]
    folder = run / name.removeprefix("mul_")
    match = pattern.search((folder / "corner_run.log").read_text())
    assert match
    rows, completed, aborts, stalls, l1_checks, l0_checks, es3_checks = map(int, match.groups())
    assert (rows, completed, aborts) == (observed["rows"], observed["completed"], observed["resetAborts"])
    assert rows == l1_checks
    nar, mask = 1 << (nb - 1), (1 << nb) - 1
    values = (0, 1, 2, nar-1, nar, nar+1, mask, nar//2, nar//2+1, nar+nar//2)
    required = set(itertools.product(values, values, range(2), range(9), range(2)))
    observed_cells = set()
    for row, line in enumerate(fixture.read_text().splitlines()):
        if row % 211 == 100:
            continue
        a, b, mode, n, ops, *_ = [int(value, 16) for value in line.split()]
        observed_cells.add((a, b, mode, n, ops))
    assert required <= observed_cells
    corners.append(dict(profile=name, rows=rows, completed=completed, reset_aborts=aborts,
                        long_stalls=stalls, observed_corner_config_cells=len(required)))
evidence_paths = [run / "summary.json", run / "functional_coverage.json",
                  run / "structural_coverage.json", base / "gate2_corners_modelsim/summary.json",
                  lint / "source.sha256"]
report = dict(
    status="PASS", Gate2="ACCEPTED: Week9 normative multiplier milestone",
    date=datetime.now(timezone.utc).isoformat(),
    scope="PLAN section7 W9-01..06 / SPEC week9 threshold; not full final regression "
          "matrix section6.7, MAC RTL, PPA or recovered paper baseline",
    compared_transactions=summary["completed"], mismatches=0,
    direct_l1_checks=summary["l1_checks"], direct_l0_checks=summary["l0_checks"],
    direct_es3_checks=summary["es3_checks"], corners=corners,
    strict_lint_profiles=16,
    structural_coverage="Measured raw line/branch/toggle; no percentage threshold "
                        "is specified for this milestone; unhit points retained",
    evidence_sha256={str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in evidence_paths},
    remaining=["Gate3 MAC RTL integration", "Final section6.7 large matrix",
               "STA/PPA and CDC signoff", "Original paper provenance/TableI"])
(root / "results/week9_implementation/gate2_acceptance.json").write_text(
    json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(report["Gate2"], report["compared_transactions"], "mismatches=0")
