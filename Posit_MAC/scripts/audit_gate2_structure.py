"""Record raw Verilator coverage points, including all unhit points (no waivers)."""
import collections
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
run = root / "results/week9_multiplier/verilator/gate2_stratified"
summary = json.loads((run / "summary.json").read_text())
assert summary["status"] == "PASS" and len(summary["profiles"]) == 16
profiles = []
for profile in summary["profiles"]:
    folder = run / profile["profile"].removeprefix("mul_")
    path = folder / "coverage.dat"
    corner_path = folder / "corner_coverage.dat"
    assert corner_path.is_file(), "Corner replay and coverage are required"
    merged = collections.Counter()
    for raw_path in (path, corner_path):
        for line in raw_path.read_text().splitlines():
            if line.startswith("C '"):
                key, count = line[3:].rsplit("' ", 1)
                merged[key] += int(count)
    totals, hit, missing = collections.Counter(), collections.Counter(), []
    for key, count in merged.items():
        fields = dict(part.split("\x02", 1) for part in key.split("\x01")
                      if "\x02" in part)
        kind = fields["page"].split("/", 1)[0].removeprefix("v_")
        totals[kind] += 1
        if int(count) > 0:
            hit[kind] += 1
        else:
            missing.append(dict(kind=kind, file=fields.get("f"), line=fields.get("l"),
                                object=fields.get("o"), hierarchy=fields.get("h")))
    assert all(kind in totals for kind in ("line", "branch", "toggle"))
    metrics = {kind: dict(hit=hit[kind], total=totals[kind],
                         percent=100 * hit[kind] / totals[kind]) for kind in totals}
    profiles.append(dict(profile=profile["profile"], metrics=metrics,
                         coverage_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                         corner_coverage_sha256=hashlib.sha256(corner_path.read_bytes()).hexdigest(),
                         unhit_points=missing))
report = dict(status="MEASURED; no coverage points excluded", profiles=profiles,
              scope="Raw line/branch/toggle point coverage, count>0. This is not "
                    "the functional input-bin acceptance criterion. Static padding, "
                    "parameter constants and impossible state paths remain included.",
              Gate2="Review functional thresholds and lint separately")
(run / "structural_coverage.json").write_text(json.dumps(report, indent=2) + "\n")
for profile in profiles:
    print(profile["profile"], profile["metrics"])
