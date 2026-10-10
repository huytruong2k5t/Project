"""Audit frozen-fixture replay against recorded ModelSim pilot evidence."""
import hashlib
import csv
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
run = sys.argv[1] if len(sys.argv) >= 2 else "final_pilot"
result_name = sys.argv[2] if len(sys.argv) >= 3 else run
if run not in {"final_pilot", "stratified_corpus"}:
    raise SystemExit("No reviewed ModelSim comparator for this fixture")
result = root / "results/week9_multiplier/verilator" / result_name
reference_path = root / ("results/week9_multiplier/gate2_final_pilot/summary.json" if run == "final_pilot" else "results/week9_multiplier/stratified_acceptance/summary.json")
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
    for source in (folder / "src").rglob("*"):
        if not source.is_file(): continue
        if source.parent.name == "l1": live = root / "l1/include" / source.name
        elif source.name in {"softposit_api.h", "libsoftposit.so"}: live = root / "l0" / source.name
        else: live = root / ("tb" if source.suffix in {".cpp", ".hpp"} else "rtl") / source.name
        assert source.read_bytes() == live.read_bytes(), (profile, "source changed")
        snapshots[str(source.relative_to(folder / "src"))] = hashlib.sha256(source.read_bytes()).hexdigest()
    build = (folder / "build.log").read_text()
    assert "%Error:" not in build and "***" not in build, (profile, "build failed")
    direct = re.search(r"L1_checks=(\d+) L0_checks=(\d+) ES3_checks=(\d+)", log)
    assert direct, (profile, "missing direct oracle counts")
    l1_checks, l0_checks, es3_checks = map(int, direct.groups())
    assert l1_checks == rows
    warnings = {}
    for warning in re.findall(r"%Warning-([A-Z0-9_]+):", build):
        warnings[warning] = warnings.get(warning, 0) + 1
    profiles.append(dict(profile=profile, rows=rows, completed=completed,
                         reset_aborts=aborts, long_stalls=stalls, mismatches=0,
                         fixture_sha256=digest, fixtureSHA256=digest, resetAborts=aborts, source_sha256=snapshots,
                         build_warnings=warnings, l1_checks=l1_checks, l0_checks=l0_checks, es3_checks=es3_checks))
summary = dict(
    status="PASS",
    date=datetime.now(timezone.utc).isoformat(),
    version=(result / "version.log").read_text().strip(),
    command=f"bash --noprofile --norc scripts/verify_week9_verilator.sh {run} {result_name}",
    fixtureRun=run,
    seed=reference["seed"], profiles=profiles,
    fixture_rows=sum(p["rows"] for p in profiles),
    completed=sum(p["completed"] for p in profiles),
    reset_aborts=sum(p["reset_aborts"] for p in profiles),
    long_stalls=sum(p["long_stalls"] for p in profiles), mismatches=0,
    l1_checks=sum(p["l1_checks"] for p in profiles),
    l0_checks=sum(p["l0_checks"] for p in profiles),
    es3_checks=sum(p["es3_checks"] for p in profiles),
    comparedTransactions=sum(p["completed"] for p in profiles),
    comparator=str(reference_path.relative_to(root)),
    scope="Four formats, two schemes, two round modes; reset/startup, invalid "
          "config, latency, context isolation, output stability and ordering. "
          "--no-timing cycle simulation ignores CK2Q delay; warnings retained.",
    limitations=["Pilot only" if run=="final_pilot" else "Structural coverage assessed separately"], Gate2="Pending integrated evidence review")
(result / "summary.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
with (result / "comparisons.csv").open("w", newline="", encoding="utf-8") as stream:
    fields = ["profile", "rows", "completed", "reset_aborts", "long_stalls",
              "mismatches", "l1_checks", "l0_checks", "es3_checks", "fixture_sha256"]
    writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
    writer.writeheader()
    writer.writerows(profiles)
print(f"AUDIT PASS: {summary['completed']} comparisons, 0 mismatches; Gate2 pending")
