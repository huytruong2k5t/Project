#!/usr/bin/env python3
"""Run standalone back-to-back II=1 elastic test on posit_parser_mul -> posit_add -> posit_pack."""
import json
import random
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path("/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC")
ELASTIC_DIR = ROOT / "results" / "nf_f_coverage_final" / "elastic_test"
OUT = ROOT / "results" / "nf_f_coverage_final"
sys.path.insert(0, str(ROOT / "scripts"))

import gen_refactored_mac_vectors as gm
import report_nf_f_coverage as rnfc


def gen_vectors(path: Path, count: int = 20000):
    rng = random.Random(20261114)
    corners = [
        0, gm.NAR, 1, 2, gm.MASK, gm.MASK - 1,
        0x7FFFFFFF, 0x7FFFFFFE, 0x80000001, 0x80000002,
        0x40000000, 0xC0000000, 0x7FFFFF00, 0x000000FF,
        0x3FFFFFFF, 0x40000001,
    ]
    lines = []
    idx = 0
    for a in corners:
        for b in corners:
            if a == gm.NAR or b == gm.NAR:
                ed, ef = gm.NAR, 16
            else:
                ed, ef = gm.encode(gm.value(a) + gm.value(b))
            lines.append(f"{a:08x} {b:08x} {ed:08x} {ef:02x}\n")
            idx += 1
    while idx < count:
        a = rng.getrandbits(32)
        if idx % 7 == 0 and a not in (0, gm.NAR):
            # Opposite near-cancellation triggering deep LZC shifts K=29,30
            b = ((-a) & gm.MASK) ^ (rng.getrandbits(3))
        else:
            b = rng.getrandbits(32)
        if a == gm.NAR or b == gm.NAR:
            ed, ef = gm.NAR, 16
        else:
            ed, ef = gm.encode(gm.value(a) + gm.value(b))
        lines.append(f"{a:08x} {b:08x} {ed:08x} {ef:02x}\n")
        idx += 1
    path.write_text("".join(lines), encoding="ascii")


def main():
    vec_file = ELASTIC_DIR / "vecs.txt"
    gen_vectors(vec_file, 20000)

    obj_dir = ELASTIC_DIR / "obj"
    obj_dir.mkdir(exist_ok=True)
    rtl_files = [
        "rtl/parser/posit_parser_mul.sv",
        "rtl/parser/posit_parser_f_regime_lod.sv",
        "rtl/common/dyn_left_shifter.sv",
        "rtl/common/dyn_left_shifter_fixed5.sv",
        "rtl/common/dyn_left_shifter_fixed6.sv",
        "rtl/common/dyn_right_shifter_fixed2.sv",
        "rtl/common/dyn_right_shifter_fixed4.sv",
        "rtl/common/lod_lzd_core_fixed2.sv",
        "rtl/common/lod_lzd_core_fixed4.sv",
        "rtl/adder/posit_add.sv",
        "rtl/adder/posit_add_prepare_comb.sv",
        "rtl/adder/posit_add_align_comb.sv",
        "rtl/adder/posit_add_arith_comb.sv",
        "rtl/adder/posit_add_lod_comb.sv",
        "rtl/adder/posit_add_norm_comb.sv",
        "rtl/packer/posit_pack.sv",
        "rtl/packer/posit_pack_prepare.sv",
        "rtl/packer/posit_pack_finish.sv",
    ]
    sources_f = obj_dir / "sources.f"
    rel_root = "../../../.."
    sources_f.write_text(
        "\n".join(f"{rel_root}/{p}" for p in rtl_files) + "\n../elastic_adder_top.sv\n",
        encoding="ascii",
    )

    cmd = [
        "verilator", "--cc", "--exe", "--no-timing", "-DCK2Q=",
        "--assert", "--coverage", "-Wall", "-Wno-DECLFILENAME",
        "-I" + f"{rel_root}/rtl",
        "--top-module", "elastic_adder_top",
        "-f", "sources.f",
        "../elastic_adder_harness.cpp",
        "--Mdir", ".",
        "-CFLAGS", "-O3 -std=c++17",
    ]
    subprocess.run(cmd, cwd=obj_dir, check=True)
    subprocess.run(["make", "-f", "Velastic_adder_top.mk", "-j4", "CURDIR=."], cwd=obj_dir, check=True)

    run_json = ELASTIC_DIR / "elastic_run.json"
    cov_dat = ELASTIC_DIR / "elastic_cov.dat"
    subprocess.run([str(obj_dir / "Velastic_adder_top"), str(vec_file), str(run_json), str(cov_dat)], check=True)

    counters = rnfc.read_counters(cov_dat)
    by_file = defaultdict(lambda: defaultdict(lambda: [0, 0]))
    unhit_branches = []
    for key, (fields, count) in counters.items():
        src = fields["source"]
        if src.startswith(rel_root + "/"):
            src = src[len(rel_root) + 1:]
        cat = fields["page"].split("/")[0]
        if any(src.endswith(t) for t in ("posit_parser_mul.sv", "posit_add.sv", "posit_pack.sv")):
            by_file[src][cat][0] += int(bool(count))
            by_file[src][cat][1] += 1
            if cat == "v_branch" and not count:
                unhit_branches.append((src, fields.get("l"), fields.get("h")))

    run_data = json.loads(run_json.read_text())
    summary = {
        "run": run_data,
        "by_file": {
            f: {
                c: {"hit": h, "total": t, "pct": (100.0 * h / t if t else 100.0)}
                for c, (h, t) in cats.items()
            }
            for f, cats in sorted(by_file.items())
        },
        "unhit_branches": unhit_branches,
    }
    (OUT / "elastic_cov_summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
