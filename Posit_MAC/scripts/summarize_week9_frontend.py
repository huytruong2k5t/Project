"""Validate frontend fixtures and preserve the limited week9 acceptance scope."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/week9_frontend"
windows = OUT / "windows"
summary = json.loads((windows / "summary.json").read_text(encoding="utf-8-sig"))
assert summary["status"] == "PASS"
assert summary["opsChecks"] == 159820 and summary["sacChecks"] == 167620
assert summary["mismatches"] == 0
canonical = {}
rows = {"ops": 0, "sac": 0}
for kind in rows:
    for width in (1, 5, 12, 26, 27):
        name = f"{kind}_{width}.txt"
        reference = (windows / name).read_text(encoding="utf-8-sig").splitlines()
        assert reference == (OUT / "linux" / name).read_text().splitlines(), name
        assert reference == (OUT / "ubsan" / name).read_text().splitlines(), name
        rows[kind] += len(reference)
        canonical[name] = hashlib.sha256(("\n".join(reference) + "\n").encode()).hexdigest()
assert rows == {"ops": 159820, "sac": 167620}
for log in (windows / "generator.log", OUT / "generator_linux.log", OUT / "generator_ubsan.log"):
    assert "WEEK9 GENERATOR PASS ops=159820 sac=167620 seed=20261008" in log.read_text(encoding="utf-8-sig")
for name in ("compile.log", "simulate.log"):
    text = (windows / name).read_text(encoding="utf-8-sig")
    assert not re.search(r"\*\*\s+(Warning|Error|Fatal):", text), name
assert "WEEK9 FRONTEND ALL PASS" in (windows / "simulate.log").read_text(encoding="utf-8-sig")
summary.update(
    milestone="W9-01 interface and W9-02 combinational OPS/SAC PASS",
    week9_status="processing", Gate2="not yet accepted", paper_original_baseline="not accepted by this test",
    fixture_rows=rows, generator_platforms=["Windows", "Linux", "Linux UBSan"],
    cross_platform="MATCH all ten fixture files after newline normalization",
    canonical_fixture_sha256=canonical,
    fraction_widths=[1, 5, 12, 26, 27], cfg_ops=[0, 1, 2, 3], cfg_mode=[0, 1],
    coverage="OPS widths1/5 exhaustive pairs; SAC widths1/5/12 exhaustive fx and scale; larger widths directed plus50k random",
    compilers={p: (OUT / f"compiler_{p}.log").read_text(encoding="utf-8-sig").splitlines()[0] for p in ("linux", "windows")},
    softposit="Not linked for combinational OPS/SAC; accepted L1 plus independent scalar references",
    commands=["make -C l1 gen_week9_frontend gen_week9_frontend.exe gen_week9_frontend_ubsan",
              "./l1/gen_week9_frontend results/week9_frontend/linux",
              "./l1/gen_week9_frontend_ubsan results/week9_frontend/ubsan",
              "./scripts/verify_week9_frontend_modelsim.ps1", "python scripts/summarize_week9_frontend.py"],
    unverified=["SBM/normalize RTL", "Sequential core/reset/drain", "Integrated multiplier/handshake/Gate2", "Verilator lint/STA/PPA", "Original paper RTL"])
source_names = ["rtl/ops_sel_comb.sv", "rtl/sac_step_comb.sv", "rtl/lod_lzd_core.sv", "rtl/dyn_left_shifter.sv",
                "tb/ops_frontend_checker.sv", "tb/sac_frontend_checker.sv", "tb/tb_week9_frontend.sv",
                "l1/test/gen_week9_frontend.cpp", "l1/include/ops_sel.hpp", "l1/include/sac.hpp", "l1/Makefile",
                "l1/gen_week9_frontend", "l1/gen_week9_frontend.exe", "l1/gen_week9_frontend_ubsan",
                "scripts/verify_week9_frontend_modelsim.ps1", "scripts/summarize_week9_frontend.py"]
paths = [ROOT / name for name in source_names]
paths += [p for p in OUT.rglob("*.log") if p.is_file()]
summary["sha256"] = {str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
(OUT / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("WEEK9 SUMMARY PASS ops=159820 sac=167620 cross_platform=MATCH week9=processing")
