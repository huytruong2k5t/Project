import json
import os
import subprocess
import time
from pathlib import Path

MSIM_BIN = Path(r"C:\altera\13.0sp1\modelsim_ase\win32aloem")
OUT_DIR = Path(__file__).resolve().parent
REPO_ROOT = OUT_DIR.parents[1]
MAC_ACTIVE = REPO_ROOT / "rtl" / "mac_active.f"
TB_PATH = REPO_ROOT / "tb" / "tb_refactored_mac.sv"
INC_DIR = REPO_ROOT / "rtl"
VEC_NF = OUT_DIR / "subset_1500.vec" / "nf.txt"
VEC_F = OUT_DIR / "subset_1500.vec" / "f.txt"


def run_cmd(cmd, cwd, log_path):
    t0 = time.perf_counter()
    p = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, timeout=120)
    dt = time.perf_counter() - t0
    txt = f"CMD: {cmd}\nRC: {p.returncode}\nELAPSED_S: {dt:.3f}\n--- STDOUT ---\n{p.stdout}\n--- STDERR ---\n{p.stderr}\n"
    log_path.write_text(txt, encoding="utf-8")
    return {"cmd": cmd, "rc": p.returncode, "elapsed_s": round(dt, 3), "stdout": p.stdout, "stderr": p.stderr}


def main():
    rtl_files = [str(REPO_ROOT / ln.strip()) for ln in MAC_ACTIVE.read_text(encoding="utf-8").splitlines() if ln.strip() and not ln.strip().startswith("#")]
    all_srcs = rtl_files + [str(TB_PATH)]
    logs_dir = OUT_DIR / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    report = {}

    # 1) Baseline subset run (NF and F)
    report["vlib_base"] = run_cmd([str(MSIM_BIN / "vlib.exe"), "work_base"], OUT_DIR, logs_dir / "vlib_base.log")
    report["vlog_base"] = run_cmd(
        [str(MSIM_BIN / "vlog.exe"), "-sv", "-timescale", "1ns/1ps", f"+incdir+{INC_DIR}", "-work", "work_base"] + all_srcs,
        OUT_DIR, logs_dir / "vlog_base.log"
    )
    report["vsim_base_nf"] = run_cmd(
        [str(MSIM_BIN / "vsim.exe"), "-c", "-lib", "work_base", "work_base.tb_refactored_mac", "-GFUSED=0",
         f"+VECTORS={VEC_NF}", "-do", "run -all; quit -f"],
        OUT_DIR, logs_dir / "vsim_base_nf.log"
    )
    report["vsim_base_f"] = run_cmd(
        [str(MSIM_BIN / "vsim.exe"), "-c", "-lib", "work_base", "work_base.tb_refactored_mac", "-GFUSED=1",
         f"+VECTORS={VEC_F}", "-do", "run -all; quit -f"],
        OUT_DIR, logs_dir / "vsim_base_f.log"
    )

    # 2) Coverage flags probe (vlog +cover=bcesft, vsim -coverage, coverage save/report)
    report["vlib_cov"] = run_cmd([str(MSIM_BIN / "vlib.exe"), "work_cov"], OUT_DIR, logs_dir / "vlib_cov.log")
    report["vlog_cov"] = run_cmd(
        [str(MSIM_BIN / "vlog.exe"), "+cover=bcesft", "-sv", "-timescale", "1ns/1ps", f"+incdir+{INC_DIR}", "-work", "work_cov"] + all_srcs,
        OUT_DIR, logs_dir / "vlog_cov.log"
    )
    report["vsim_cov_nf"] = run_cmd(
        [str(MSIM_BIN / "vsim.exe"), "-c", "-coverage", "-lib", "work_cov", "work_cov.tb_refactored_mac", "-GFUSED=0",
         f"+VECTORS={VEC_NF}", "-do", "run -all; coverage save cov_nf.ucdb; coverage report -detail -file cov_nf_report.txt; quit -f"],
        OUT_DIR, logs_dir / "vsim_cov_nf.log"
    )
    report["vsim_cov_f"] = run_cmd(
        [str(MSIM_BIN / "vsim.exe"), "-c", "-coverage", "-lib", "work_cov", "work_cov.tb_refactored_mac", "-GFUSED=1",
         f"+VECTORS={VEC_F}", "-do", "run -all; coverage save cov_f.ucdb; coverage report -detail -file cov_f_report.txt; quit -f"],
        OUT_DIR, logs_dir / "vsim_cov_f.log"
    )

    # Check produced files
    produced = {}
    for fname in ["cov_nf.ucdb", "cov_nf_report.txt", "cov_f.ucdb", "cov_f_report.txt"]:
        fp = OUT_DIR / fname
        produced[fname] = {"exists": fp.exists(), "size": fp.stat().st_size if fp.exists() else 0}
    report["coverage_files"] = produced

    # Save concise summary + full report
    (OUT_DIR / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    for k in ["vlog_base", "vsim_base_nf", "vsim_base_f", "vlog_cov", "vsim_cov_nf", "vsim_cov_f"]:
        r = report[k]
        tail = "\n".join(r["stdout"].splitlines()[-8:])
        print(f"=== {k} rc={r['rc']} ({r['elapsed_s']}s) ===")
        print(tail)
        if r["stderr"].strip():
            print("STDERR:", r["stderr"].strip())
    print("coverage_files:", produced)


if __name__ == "__main__":
    main()
