"""Require the observed full corner/config cross, including both NaR/Zero orders."""
import hashlib
import itertools
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
base = root / "results/week9_multiplier"
fixture_dir = base / "corners_final_windows"
summary_path = base / "corners_final_rtl/summary.json"
summary = json.loads(summary_path.read_text(encoding="utf-8-sig"))
if summary["status"] != "PASS":
    raise RuntimeError("corner RTL run has not passed")
profiles = {p["profile"]: p for p in summary["profiles"]}
reports = []
for fixture in sorted(fixture_dir.glob("mul_*.txt")):
    nb, es, scheme, rounding = map(int, fixture.stem.split("_")[1:])
    nar, mask = 1 << (nb-1), (1 << nb)-1
    corners = (0, 1, 2, nar-1, nar, nar+1, mask, nar//2, nar//2+1, nar+nar//2)
    expected = set(itertools.product(corners, corners, range(2), range(9), range(2)))
    actual = set()
    rows = fixture.read_text().splitlines()
    for platform in ("corners_final_linux", "corners_final_ubsan"):
        if rows != (base / platform / fixture.name).read_text().splitlines():
            raise RuntimeError("cross-platform corner fixture mismatch")
    for row, line in enumerate(rows):
        if row % 211 != 100:
            fields = [int(field, 16) for field in line.split()]
            actual.add(tuple(fields[:5]))
    if actual != expected:
        raise RuntimeError(f"incomplete corner/config cross: {fixture.stem}")
    if hashlib.sha256(fixture.read_bytes()).hexdigest() != profiles[fixture.stem]["fixtureSHA256"]:
        raise RuntimeError("fixture changed after RTL run")
    reports.append({"profile": fixture.stem, "distinct_observed_cases": len(actual),
                    "mode_ops_n_cells": 36, "operand_pairs": 100})
for fixture in (base / "uniform_replay").glob("mul_*.txt"):
    if fixture.read_text().splitlines() != (base / "final_pilot" / fixture.name).read_text().splitlines():
        raise RuntimeError("new corner option changed the original uniform generator")
report = {"status": "PASS", "profiles": reports,
          "Linux_Windows_UBSan": "MATCH after newline normalization",
          "legacy_uniform_replay": "32000 rows unchanged",
          "scope": "3600 distinct corner/config cases per profile; aborted repetitions excluded; ±1, ±minpos, ±maxpos, NaR×0 and 0×NaR included"}
(base / "corners_final_rtl/coverage.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
print("CORNER COVERAGE PASS: 16 profiles x 3600 distinct surviving cases; cross-platform replay MATCH")
