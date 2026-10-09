"""Report checked-row lower bounds from the existing ModelSim markers."""
import json
import re
from datetime import datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]
report = {}
for run in ("acceptance_parallel", "stratified_acceptance"):
    directory = root / "results/week9_multiplier" / run
    profiles = []
    for log in sorted(directory.glob("mul_*/simulate.log")):
        text = log.read_text(encoding="utf-8", errors="replace")
        passed = re.search(r"MULTIPLIER PASS .*rows=(\d+) completed=(\d+) reset_aborts=(\d+)", text)
        markers = re.findall(r"MUL PROGRESS .*rows=(\d+)", text)
        rows = int(passed[1]) if passed else (int(markers[-1]) if markers else 0)
        aborts = (rows - 101) // 211 + 1 if rows >= 101 else 0
        checked = int(passed[2]) if passed else rows - aborts
        profiles.append({"profile": log.parent.name, "status": "PASS" if passed else "RUNNING",
                         "checked_lower_bound": checked, "row_marker": rows})
    report[run] = {"completed_profiles": sum(p["status"] == "PASS" for p in profiles),
                   "checked_lower_bound": sum(p["checked_lower_bound"] for p in profiles),
                   "profiles": profiles}
    print(run, "PASS profiles", report[run]["completed_profiles"], "/16",
          "checked lower bound", report[run]["checked_lower_bound"])
output = root / "results/week9_implementation/runtime_progress.json"
output.write_text(json.dumps({"date_local": datetime.now().isoformat(), "runs": report,
    "scope": "progress only; does not replace all-profile PASS, coverage or Gate2 acceptance"},
    indent=2)+"\n", encoding="utf-8")
