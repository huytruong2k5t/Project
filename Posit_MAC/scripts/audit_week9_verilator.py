"""Audit frozen-fixture replay against recorded ModelSim pilot evidence."""
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
run = sys.argv[1] if len(sys.argv) == 2 else "final_pilot"
if run != "final_pilot":
    raise SystemExit("Only final_pilot has a mapped, reviewed ModelSim comparator")
result = root / "results/week9_multiplier/verilator" / run
reference_path = root / "results/week9_multiplier/parallel_pilot/summary.json"
reference = json.loads(reference_path.read_text(encoding="utf-8-sig"))
assert reference["fixtureRun"] == run and len(reference["profiles"]) == 16
profiles = []
pattern = re.compile(r"VERILATOR MULTIPLIER PASS rows=(\d+) completed=(\d+) "
                     r"reset_aborts=(\d+) long_stalls=(\d+) mismatches=0")
for model in reference["profiles"]:
    profile = model["profile"]
    folder = result / profile.removeprefix("mul_")
    fixture = root / "results/week9_multiplier" / run / (profile + ".txt")
    digest = hashlib.sha256(fixture.read_bytes()).hexdigest()
    assert digest == model["fixtureSHA256"], (profile, "fixture changed")
    assert (folder / "fixture.sha256").read_text().split()[0] == digest
    log = (folder / "run.log").read_text()
    matches = list(pattern.finditer(log))
    assert len(matches) == 1, (profile, "missing or duplicate PASS")
    rows, completed, aborts, stalls = map(int, matches[0].groups())
    assert (rows, completed, aborts) == (
        model["rows"], model["completed"], model["resetAborts"])
    snapshots = {}
    for source in (folder / "src").iterdir():
        live = root / ("tb" if source.suffix == ".cpp" else "rtl") / source.name
        assert source.read_bytes() == live.read_bytes(), (profile, "source changed")
        snapshots[source.name] = hashlib.sha256(source.read_bytes()).hexdigest()
    build = (folder / "build.log").read_text()
    assert "%Error:" not in build and "***" not in build, (profile, "build failed")
    warnings = {}
    for warning in re.findall(r"%Warning-([A-Z0-9_]+):", build):
        warnings[warning] = warnings.get(warning, 0) + 1
    profiles.append(dict(profile=profile, rows=rows, completed=completed,
                         reset_aborts=aborts, long_stalls=stalls, mismatches=0,
                         fixture_sha256=digest, source_sha256=snapshots,
                         build_warnings=warnings))
summary = dict(
    status="PASS: fixture replay and ModelSim count/hash cross-check",
    date=datetime.now(timezone.utc).isoformat(),
    version=(result / "version.log").read_text().strip(),
    command="bash --noprofile --norc scripts/verify_week9_verilator.sh final_pilot",
    seed=reference["seed"], profiles=profiles,
    fixture_rows=sum(p["rows"] for p in profiles),
    completed=sum(p["completed"] for p in profiles),
    reset_aborts=sum(p["reset_aborts"] for p in profiles),
    long_stalls=sum(p["long_stalls"] for p in profiles), mismatches=0,
    comparator=str(reference_path.relative_to(root)),
    scope="Four formats, two schemes, two round modes; reset/startup, invalid "
          "config, latency, context isolation, output stability and ordering. "
          "--no-timing cycle simulation ignores CK2Q delay; warnings retained.",
    limitations=["Pilot only, below 10^7 vectors", "Strict lint not passed",
                 "Fixtures, not direct calls to L0/L1 in C++ scoreboard",
                 "No line/branch/toggle coverage"], Gate2="NOT ACCEPTED")
(result / "summary.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"AUDIT PASS: {summary['completed']} comparisons, 0 mismatches; Gate2 pending")
