"""Run the same source-bound A35T implementation recipe for MAC-NF and MAC-F."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil

from measure_multiplier_prepack import FILELIST, check_hashes, execute, sha, write_json


SOURCE = Path(__file__).resolve().parents[1]
RECIPE = "syn/route_mac_100mhz.tcl"
RECEIPTS = [f"results/shared_parser_mul_20261107/build_{v}.json" for v in ("nf", "f")]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("--vivado", required=True, type=Path)
    args = parser.parse_args()
    project = Path.cwd()
    if not (project / FILELIST).is_file() or not re.fullmatch(r"[a-zA-Z0-9_]+", args.tag):
        parser.error("run from Posit_MAC with a simple new tag")
    vivado = args.vivado.resolve(strict=True)
    run = project / "results" / args.tag
    run.mkdir()
    rtl = (SOURCE / FILELIST).read_text(encoding="ascii").split()
    guarded = [*rtl, FILELIST, "rtl/posit_mac.vh"]
    for receipt in RECEIPTS:
        build = json.loads((SOURCE / receipt).read_text(encoding="utf-8"))["source_sha256"]
        check_hashes(SOURCE, {p: build[p] for p in guarded})
    files = [*guarded, *RECEIPTS, RECIPE, "scripts/route_mac_100mhz.py",
             "scripts/measure_multiplier_prepack.py", "tb/prepack_nf_ppa_top.sv",
             "tb/week13_fused_ppa_top.sv", "syn/constraints/a35t_clock.xdc",
             "syn/constraints/a35t_benchmark_100mhz.xdc"]
    hashes = {p: sha(SOURCE / p) for p in files}
    snapshot = run / "source"
    for p in files:
        dst = snapshot / p
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(SOURCE / p, dst)
    check_hashes(snapshot, hashes)
    write_json(run / "source_sha256.json", hashes)
    evidence = {}
    for variant in ("nf", "f"):
        target = run / variant
        target.mkdir()
        for name in ("tmp", "appdata", "localappdata"):
            (target / name).mkdir()
        env = dict(os.environ, TEMP=str(target / "tmp"), TMP=str(target / "tmp"),
                   APPDATA=str(target / "appdata"), LOCALAPPDATA=str(target / "localappdata"),
                   XILINX_LOCAL_USER_DATA="no")
        command = [str(vivado), "-mode", "batch", "-notrace", "-source", f"../source/{RECIPE}",
                   "-log", "vivado.log", "-journal", "vivado.jou", "-tclargs", variant]
        write_json(target / "execution.json", {"command": command, "cwd": variant,
                   "source_index_sha256": sha(run / "source_sha256.json")})
        execute(command, target, env, target / "console.log")
        console = (target / "console.log").read_text(encoding="utf-8", errors="replace")
        if f"MAC_ROUTE_COMPLETE variant={variant}" not in console:
            raise RuntimeError(f"Missing completion marker in {target / 'console.log'}")
        for name in ("execution.json", "console.log", "vivado.log", "vivado.jou",
                     "synthesis_timing.rpt", "synthesis_utilization.rpt", "synthesis.dcp",
                     "routed.dcp", "effective_constraints_routed.xdc", "route_timing.rpt",
                     "route_paths.rpt", "route_status.rpt", "route_utilization.rpt", "route_drc.rpt"):
            evidence[f"{variant}/{name}"] = sha(target / name)
        print(f"MAC_ROUTE_COMPLETE {variant}", flush=True)
    check_hashes(snapshot, hashes)
    check_hashes(SOURCE, hashes)
    check_hashes(run, evidence)
    write_json(run / "manifest.json", {"status": "ROUTED", "part": "xc7a35tcpg236-1",
               "period_ns": 10, "source_index_sha256": sha(run / "source_sha256.json"),
               "evidence_sha256": evidence})


if __name__ == "__main__":
    main()
