"""Collect only completed runs. Never promote generated fixtures to RTL evidence."""
import csv
import hashlib
import json
from pathlib import Path
from datetime import datetime, timezone, timedelta

root = Path(__file__).resolve().parents[1]
result = root / "results/week9_implementation"
result.mkdir(parents=True, exist_ok=True)
components = {}
for name, path in {
    "frontend": "week9_frontend/windows",
    "arithmetic": "week9_arithmetic/windows",
    "paper": "week9_paper/windows",
    "core": "week9_core/windows",
    "multiplier_pilot": "week9_multiplier/final_pilot",
}.items():
    components[name] = json.loads((root / "results" / path / "summary.json").read_text(encoding="utf-8-sig"))
    if components[name]["status"] != "PASS":
        raise RuntimeError(f"unfinished component: {name}")
for name, run in (("multiplier_uniform", "acceptance_parallel"),
                  ("multiplier_stratified_pilot", "stratified_final_pilot_rtl"),
                  ("multiplier_stratified", "stratified_acceptance")):
    extra = root / "results/week9_multiplier" / run / "summary.json"
    if extra.exists():
        components[name] = json.loads(extra.read_text(encoding="utf-8-sig"))
        if components[name]["status"] != "PASS":
            raise RuntimeError(f"unfinished component: {name}")
acceptance = root / "results/week9_multiplier/stratified_acceptance/summary.json"
if not acceptance.exists():
    acceptance = root / "results/week9_multiplier/acceptance_parallel/summary.json"
if acceptance.exists():
    components["multiplier_acceptance"] = json.loads(acceptance.read_text(encoding="utf-8-sig"))
    if components["multiplier_acceptance"]["status"] != "PASS":
        raise RuntimeError("acceptance has not passed")

cross_platform = {}
for suite in ("arithmetic", "paper", "core"):
    path = root / "results" / f"week9_{suite}"
    for vector in sorted((path / "windows").glob("*.txt")):
        gold = vector.read_text().splitlines()
        for platform in ("linux", "ubsan"):
            other = path / platform / vector.name
            if not other.exists():
                cross_platform[f"{suite}/{platform}"] = "NOT RUN"
            elif gold != other.read_text().splitlines():
                raise RuntimeError(f"fixture differs: {other}")
            else:
                cross_platform.setdefault(f"{suite}/{platform}", "MATCH after newline normalization")
pilot = root / "results/week9_multiplier/final_pilot"
for platform in ("linux", "ubsan"):
    for vector in pilot.glob("mul_*.txt"):
        if vector.read_text().splitlines() != (root / "results/week9_multiplier" / platform / vector.name).read_text().splitlines():
            raise RuntimeError("multiplier pilot differs across platforms")
    cross_platform[f"multiplier/{platform}"] = "MATCH after newline normalization"

coverage = []
for file in sorted((root / "results/week9_multiplier/acceptance_corpus").glob("coverage_*.csv")):
    cells = list(csv.DictReader(file.open()))
    if len(cells) != 36 or any(int(row["transactions"]) == 0 for row in cells):
        raise RuntimeError("incomplete generated coverage")
    coverage.append({"profile": file.stem, "cells": 36,
                     "rows": sum(int(row["transactions"]) for row in cells)})
if len(coverage) != 16:
    raise RuntimeError("missing generated profile")

files = []
for directory in ("rtl", "tb", "scripts", "l1/test"):
    files.extend(path for path in (root / directory).glob("*") if path.is_file()
                 and path.suffix in (".sv", ".vh", ".cpp", ".py", ".ps1", ".sh"))
files.extend(root / path for path in ("SPEC_Posit_MAC_IP.md", "l1/PLAN.md", "l1/Makefile", "Makefile"))
source_hashes = {str(path.relative_to(root)).replace("\\", "/"):
                 hashlib.sha256(path.read_bytes()).hexdigest() for path in files}
fixture_hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                  for path in (root / "results/week9_multiplier/acceptance_corpus").glob("mul_*.txt")}
git_status_path = result / "git_backup_status.json"
git_status = json.loads(git_status_path.read_text(encoding="utf-8")) if git_status_path.exists() else {
    "status": "BLOCKED", "repository": "https://github.com/huytruong2k5t/Project",
    "reason": "source tree has no Git checkout", "commit": None, "branch": None}
coverage_reports = {}
for run in ("final_pilot", "stratified_final_pilot_rtl", "acceptance_parallel", "stratified_acceptance"):
    path = root / "results/week9_multiplier" / run / "functional_coverage.json"
    if path.exists():
        data = json.loads(path.read_text(encoding="utf-8"))
        coverage_reports[run] = {"status": data["status"], "report": path.relative_to(root).as_posix(),
            "scope": data["scope"], "profiles": [{key: p[key] for key in (
                "profile", "surviving_rows", "valid_regime_cross_bins", "hit_regime_cross_bins",
                "minimum_regime_cross_count", "finite_run_minimum_operands")}
                for p in data["profiles"]]}
summary = {
    "date": datetime.now(timezone(timedelta(hours=7))).isoformat(),
    "milestones": {"W9-03": "PASS", "W9-R1": "frozen reconstruction assumptions",
                   "W9-R2": "PASS functional corpus only", "W9-04": "PASS",
                   "W9-05": "PASS baseline enabled features, four formats",
                   "W9-06": "processing: official Verilator run/lint unavailable"},
    "Gate2": "NOT ACCEPTED", "week9": "processing",
    "components": components, "cross_platform": cross_platform,
    "seed": 20261009,
    "generated_acceptance_rows": sum(row["rows"] for row in coverage),
    "generated_coverage": coverage,
    "acceptance_RTL_run": components.get("multiplier_acceptance", "RUNNING in separate ModelSim profile processes: fixture generation is not RTL verification"),
    "functional_coverage": coverage_reports,
    "coverage_limit": "Only PASS summaries make fixture bins observed comparisons. Uniform-bit coverage alone is insufficient under SPEC6.3. Line/branch/toggle coverage not measured by these runs.",
    "superseded_run": "acceptance sixteen-DUT process stopped deliberately; partial run has zero accepted comparison credit; see run_status.json",
    "Verilator": "command -v returned no installed executable; no tool installed by this task",
    "static_analysis": "Quartus13 Analysis & Synthesis NB32/ES2 RNE/FLOOR, 0 errors/14 reviewed warnings; not strict Verilator lint, STA, CDC or PPA",
    "static_warning_review": "parallel license unavailable; ASYNC_REG is a Xilinx attribute not recognized by Quartus13; bounded parameter constants resized to declared vector widths. No latch warning.",
    "paper_original_baseline": "not confirmed; Table I not rerun because RTL matches existing reconstruction without new source evidence",
    "git_push": git_status,
    "source_sha256": source_hashes, "acceptance_fixture_sha256": fixture_hashes,
    "compilers": {name: (result / f"compiler_{name}.log").read_text().splitlines()[0]
                  for name in ("linux", "windows")},
    "SoftPosit": {"version": "vendored source snapshot; exact/RNE ES0/1/2; ES3 uses independent integer/bit-list reference",
                  "linux_library_sha256": hashlib.sha256((root / "l0/libsoftposit.so").read_bytes()).hexdigest(),
                  "windows_library_sha256": hashlib.sha256((root / "l0/softposit.dll").read_bytes()).hexdigest()},
    "commands": ["make -C l1 gen_week9_arithmetic gen_week9_arithmetic.exe gen_week9_arithmetic_ubsan",
                 "make -C l1 gen_week9_paper gen_week9_paper.exe gen_week9_paper_ubsan gen_week9_core gen_week9_core.exe gen_week9_core_ubsan",
                 "make -C l1 gen_week9_multiplier gen_week9_multiplier.exe gen_week9_multiplier_ubsan",
                 "scripts/verify_week9_arithmetic_modelsim.ps1", "scripts/verify_week9_paper_modelsim.ps1",
                 "scripts/verify_week9_core_modelsim.ps1", "scripts/verify_week9_frontend_modelsim.ps1",
                 "scripts/verify_week9_multiplier_modelsim.ps1 -PerProfile 2000 -RunName final_pilot",
                 "./l1/gen_week9_multiplier results/week9_multiplier/acceptance_corpus 630000",
                 "quartus_map multiplier --analysis_and_elaboration", "quartus_map multiplier",
                 "make lint (BLOCKED)", "bash scripts/verify_week9_verilator.sh (BLOCKED before build)"]
}
(result / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
print("WEEK9 IMPLEMENTATION SUMMARY: W9-03/R1/R2/04/05 PASS; Gate2 NOT ACCEPTED")
