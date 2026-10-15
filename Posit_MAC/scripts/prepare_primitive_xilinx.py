"""Freeze input snapshots and generate parameterized, independent RTL checks."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/primitive_xilinx_20261015"
NAMES = ("dyn_left_shifter", "dyn_right_shifter", "lod_lzd_core")


def main():
    (OUT / "reference").mkdir(parents=True, exist_ok=True)
    manifest = {"seed": 20261015, "sources": {}, "parts": [
        "xc7a35tcpg236-1", "xc7a100tcsg324-1"],
        "unavailable_part": "xc7z020clg400-1",
        "period_ns": 5.0, "uncertainty_ns": 0.1,
        "synthetic_io_delays_ns": {"input_min": 2.5, "input_max": 2.5,
                                  "output_min": 0.0, "output_max": 0.5},
        "strategies": ["default", "explore", "runtime"],
        "strategy_commands": {"default": ["Default", "Default"],
                              "explore": ["Explore", "Explore"],
                              "runtime": ["RuntimeOptimized", "Default"]},
        "measurement": "OOC input/output banks, R2R; not on-board measurement",
        "cases": [{"kind": k, "n": n} for n in (12, 26, 32) for k in (0, 1, 2)],
        "kind": {"0": "left", "1": "right_custom_fill", "2": "lod_mode0"}}
    for name in NAMES:
        for directory in ("rtl", "rtl/candidates/primitives"):
            path = ROOT / directory / f"{name}.sv"
            manifest["sources"][path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
        original = (ROOT / "rtl" / f"{name}.sv").read_text()
        reference = original.replace(f"module {name} #(", f"module {name}_reference #(")
        (OUT / "reference" / f"{name}_reference.sv").write_text(reference, newline="\n")
    for path in [ROOT / "scripts" / p for p in (
        "prepare_primitive_xilinx.py", "verify_primitive_xilinx.ps1", "primitive_xilinx_ppa.tcl",
        "run_primitive_xilinx_ppa.ps1", "lint_primitive_xilinx.sh")]+[
            ROOT / "tb/primitive_lod_check.sv", ROOT / "tb/primitive_shift_check.sv"]:
        manifest["sources"][path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    for variant, directory in (("baseline", "rtl"), ("candidate", "rtl/candidates/primitives")):
        snapshot = OUT / "source" / variant
        snapshot.mkdir(parents=True, exist_ok=True)
        for name in NAMES:
            shutil.copyfile(ROOT / directory / f"{name}.sv", snapshot / f"{name}.sv")
        for name in ("primitive_ppa_top.sv", "primitive_ppa_boundary.sv", "posit_mac.vh"):
            source = ROOT / "rtl" / name
            shutil.copyfile(source, snapshot / name)
            manifest["sources"][source.relative_to(ROOT).as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
    widths = (1, 2, 3, 5, 8, 12, 26, 27, 29, 31, 32, 33, 64)
    lod_widths = (*range(2, 13), 26, 27, 29, 31, 32, 33, 53, 54, 64)
    instances = []
    for n in widths:
        s = max(1, (n-1).bit_length())
        for w in sorted({max(1, s-1), s, s+1}):
            i = len(instances)
            instances.append(f"    primitive_shift_check #(.N({n}), .W({w})) u_s{i} (.done(done[{i}]));")
    shift_configs = len(instances)
    for n in lod_widths:
        for s in ((n-1).bit_length(), (n-1).bit_length()+1):
            for mode in (0, 1):
                i = len(instances)
                instances.append(f"    primitive_lod_check #(.N({n}), .S({s}), .MODE({mode})) u_l{i} (.done(done[{i}]));")
    tb = """`timescale 1ns/1ps
module tb_primitive_xilinx;
    wire [COUNT-1:0] done;
INSTANCES
    initial begin
        wait (&done);
        $display("PRIMITIVE_ALL_PASS seed=20261015 configurations=COUNT");
        $finish;
    end
    initial begin
        #2000000;
        $fatal(1, "primitive regression timeout");
    end
endmodule
""".replace("COUNT", str(len(instances))).replace("INSTANCES", "\n".join(instances))
    (OUT / "tb_primitive_xilinx.sv").write_text(tb, newline="\n")
    manifest["test_configs"] = {"shifter": shift_configs, "lod": len(instances)-shift_configs}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", newline="\n")
    print(json.dumps({"prepared": str(OUT), "configurations": manifest["test_configs"]}))


if __name__ == "__main__":
    main()
