"""Fail closed on incomplete comparisons; retain measured timing and scope."""
from pathlib import Path
from rtl_paths import rtl_source, resolve_source
import csv
import hashlib
import json
import re
from statistics import median

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/primitive_xilinx_20261015"


def sha(path):
    return hashlib.sha256(resolve_source(path).read_bytes()).hexdigest()


def extract(pattern, content, cast=float):
    match = re.search(pattern, content, re.M)
    if not match:
        raise ValueError(f"Missing report field: {pattern}")
    return cast(match.group(1))


def main():
    manifest = json.loads((OUT / "manifest.json").read_text(encoding="utf-8-sig"))
    for name, expected in manifest["sources"].items():
        assert sha(ROOT / name) == expected, f"Source changed: {name}"
    for variant, directory in (("baseline", "rtl/common"), ("candidate", "rtl/candidates/primitives")):
        for module in ("dyn_left_shifter", "dyn_right_shifter", "lod_lzd_core"):
            assert (OUT/"source"/variant/f"{module}.sv").read_bytes() == (ROOT/directory/f"{module}.sv").read_bytes()
        for file in ("primitive_ppa_top.sv", "primitive_ppa_boundary.sv", "posit_mac.vh"):
            assert (OUT/"source"/variant/file).read_bytes() == (rtl_source(file)).read_bytes()
    for module in ("dyn_left_shifter", "dyn_right_shifter", "lod_lzd_core"):
        expected = (rtl_source(f"{module}.sv")).read_text().replace(
            f"module {module} #(", f"module {module}_reference #(")
        assert (OUT/"reference"/f"{module}_reference.sv").read_text() == expected
    freeze = json.loads((ROOT / "results/week12/nf_ppa/summary.json").read_text(encoding="utf-8-sig"))
    production = {p: sha(ROOT/p) == h for p, h in freeze["source_sha256"].items() if p.startswith("rtl/")}
    assert all(production.values()), "Frozen NF RTL changed"
    interfaces = {}
    for module in ("dyn_left_shifter", "dyn_right_shifter", "lod_lzd_core"):
        headers = []
        for directory in ("rtl/common", "rtl/candidates/primitives"):
            content = (ROOT/directory/f"{module}.sv").read_text()
            header = re.search(r"module\s+\w+\s*#\((.*?)\);", content, re.S).group(1)
            headers.append(re.sub(r"\s+", "", re.sub(r"//[^\n]*", "", header)))
        interfaces[module] = headers[0] == headers[1]
        assert interfaces[module], f"Public interface changed: {module}"
    lint = (OUT / "lint/lint.log").read_text()
    assert "STRICT_LINT_PASS invocations=197" in lint and "%Warning" not in lint and "%Error" not in lint
    verification = json.loads((OUT / "verification.json").read_text(encoding="utf-8-sig"))
    assert verification["status"] == "PASS" and verification["mismatch"] == 0
    rows = []
    report_hashes = {}
    for part in manifest["parts"]:
        with (OUT / part / "measurements.csv").open() as fp:
            entries = list(csv.DictReader(fp))
        expected_keys = {(v, c["n"], c["kind"], s) for v in ("baseline", "candidate")
                         for c in manifest["cases"] for s in manifest["strategies"]}
        keys = {(r["variant"], int(r["n"]), int(r["kind"]), r["strategy"]) for r in entries}
        assert keys == expected_keys and len(entries) == len(expected_keys), f"Incomplete PPA: {part}"
        for entry in entries:
            row = {k: (v if k in ("part", "variant", "strategy") else float(v)) for k, v in entry.items()}
            n, kind = int(row["n"]), int(row["kind"])
            run = OUT / part / f"{row['variant']}_n{n}_k{kind}" / row["strategy"]
            timing = (run / "timing.rpt").read_text()
            util = (run / "utilization.rpt").read_text()
            route = (run / "route.rpt").read_text()
            drc = (run / "drc.rpt").read_text()
            setup = (run / "r2r_setup.rpt").read_text()
            hold = (run / "r2r_hold.rpt").read_text()
            assert "Design State : Routed" in timing
            assert extract(r"\| Device\s*:\s*(\S+)", util, str) == part
            assert "period=5.000ns" in setup and "period=5.000ns" in hold
            assert abs(extract(r"Slack \((?:MET|VIOLATED)\)\s*:\s*([-\d.]+)ns", setup)
                       -row["r2r_setup_slack_ns"]) < 0.0011
            assert abs(extract(r"Slack \((?:MET|VIOLATED)\)\s*:\s*([-\d.]+)ns", hold)
                       -row["r2r_hold_slack_ns"]) < 0.0011
            for check in ("no_clock", "unconstrained_internal_endpoints", "loops", "latch_loops",
                          "no_input_delay", "no_output_delay", "partial_input_delay", "partial_output_delay"):
                count = extract(rf"^\d+\. checking {check} \((\d+)\)", timing, int)
                assert count == 0, (part, run, check, count)
            summary = re.search(r"^\s+([-\d.]+)\s+([-\d.]+)\s+(\d+)\s+(\d+)\s+([-\d.]+)\s+([-\d.]+)\s+(\d+)\s+(\d+)\s+([-\d.]+)\s+([-\d.]+)\s+(\d+)\s+(\d+)\s*$", timing, re.M)
            assert summary, "Timing summary missing"
            for key, idx in (("whole_setup_wns_ns", 1), ("whole_setup_tns_ns", 2),
                             ("whole_hold_whs_ns", 5), ("whole_hold_ths_ns", 6), ("pulse_width_slack_ns", 9)):
                row[key] = float(summary.group(idx))
            row["slice_luts"] = extract(r"^\| Slice LUTs\*?\s*\|\s*(\d+)", util, int)
            row["slice_registers"] = extract(r"^\| Slice Registers\s*\|\s*(\d+)", util, int)
            row["latches"] = extract(r"^\|\s+Register as Latch\s*\|\s*(\d+)", util, int)
            assert row["latches"] == 0
            assert row["ff"] == row["slice_registers"]
            assert row["dsp"] == row["bram"] == 0
            assert not re.search(r"^\|[^\n]*\|\s*(?:Error|Critical Warning)\s*\|", drc, re.M)
            row["r2r_startpoint"] = extract(r"^\s*Source:\s+(.+)", setup, str).strip()
            row["r2r_endpoint"] = extract(r"^\s*Destination:\s+(.+)", setup, str).strip()
            assert "u_boundary/" in row["r2r_startpoint"] and "u_boundary/result_reg" in row["r2r_endpoint"]
            row["r2r_delay_ns"] = row["r2r_logic_ns"] + row["r2r_route_ns"]
            row["r2r_fmax_sta_estimate_mhz"] = 1000.0 / (row["period_ns"] - row["r2r_setup_slack_ns"])
            row["r2r_pass_200mhz"] = row["r2r_setup_slack_ns"] >= 0 and row["r2r_hold_slack_ns"] >= 0
            row["synthetic_benchmark_all_timing_pass"] = all(row[k] >= 0 for k in (
                "whole_setup_wns_ns", "whole_hold_whs_ns", "pulse_width_slack_ns"))
            row["reported_violations"] = [{"slack_ns": float(s), "source": a.strip(), "destination": b.strip()}
                for s, a, b in re.findall(r"Slack \(VIOLATED\)\s*:\s*([-\d.]+)ns[^\n]*\n"
                    r"\s*Source:\s*([^\n]+)[\s\S]*?Destination:\s*([^\n]+)", timing)]
            row["reported_violations_only_io"] = all(
                not (v["source"].startswith("u_boundary/") and v["destination"].startswith("u_boundary/"))
                for v in row["reported_violations"])
            # Route report is also retained even though OOC port routes are incomplete.
            row["route_errors"] = extract(r"# of nets with routing errors\.+\s*:\s*(\d+)", route, int)
            assert row["route_errors"] == 0
            for name in ("timing.rpt", "utilization.rpt", "hierarchy.rpt", "route.rpt", "drc.rpt", "r2r_setup.rpt", "r2r_hold.rpt"):
                path = run/name
                report_hashes[path.relative_to(ROOT).as_posix()] = sha(path)
            rows.append(row)
    comparisons = []
    for part in manifest["parts"]:
        for case in manifest["cases"]:
            item = {"part": part, **case, "block": manifest["kind"][str(case["kind"])], "variants": {}}
            for variant in ("baseline", "candidate"):
                group = [r for r in rows if r["part"] == part and r["variant"] == variant
                         and r["n"] == case["n"] and r["kind"] == case["kind"]]
                assert len(group) == 3
                item["variants"][variant] = {k: {"min": min(r[k] for r in group), "median": median(r[k] for r in group),
                    "max": max(r[k] for r in group)} for k in (
                        "slice_luts", "ff", "r2r_delay_ns", "r2r_fmax_sta_estimate_mhz")}
                item["variants"][variant]["all_r2r_pass_200mhz"] = all(r["r2r_pass_200mhz"] for r in group)
                frequencies = [r["r2r_fmax_sta_estimate_mhz"] for r in group]
                spread = 100*(max(frequencies)/min(frequencies)-1)
                item["variants"][variant]["sta_spread_percent"] = spread
                item["variants"][variant]["sta_spread_over10percent"] = spread > 10
            a, b = item["variants"]["baseline"], item["variants"]["candidate"]
            item["lut_change_percent"] = 100*(b["slice_luts"]["median"]/a["slice_luts"]["median"]-1)
            item["sta_estimate_change_percent"] = 100*(b["r2r_fmax_sta_estimate_mhz"]["median"]/a["r2r_fmax_sta_estimate_mhz"]["median"]-1)
            comparisons.append(item)
    result = {"status": "MEASURED_POST_ROUTE", "tool": "Vivado 2026.1 build 6511674", "runs": len(rows),
        "verification": verification, "strict_lint_invocations": 197, "production_rtl_unchanged": production,
        "public_parameter_and_port_contract_unchanged": interfaces,
        "contract": manifest, "rows": rows, "comparisons": comparisons,
        "all_r2r_pass_200mhz": all(r["r2r_pass_200mhz"] for r in rows),
        "all_synthetic_benchmark_timing_pass": all(r["synthetic_benchmark_all_timing_pass"] for r in rows),
        "limitations": ["Fmax STA estimates from routed paths at 5ns, not a frequency sweep or board test",
            "No MAC/SAC/parser integration, no production replacement; MODE1/ARITH1 PPA not measured",
            "OOC ports have no HD.PARTPIN_LOCS; external I/O routes/timing are not board signoff",
            "The banks have no owned valid/control state and need no reset; primitive DUTs remain combinational",
            "Both devices are Artix-7 speed grade -1; no Zynq support installed; no cross-family claim",
            "Binary functional equivalence tested; universal X/Z/formal equivalence not claimed"],
        "report_sha256": report_hashes, "collector_sha256": sha(Path(__file__)),
        "replay_entry_sha256": sha(ROOT/"scripts/replay_primitive_xilinx.ps1"),
        "commands": ["powershell -NoProfile -File scripts/verify_primitive_xilinx.ps1",
            'wsl.exe --exec bash --noprofile --norc -c \'cd "/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC" && bash scripts/lint_primitive_xilinx.sh\'',
            "powershell -NoProfile -File scripts/run_primitive_xilinx_ppa.ps1 -Part xc7a35tcpg236-1",
            "powershell -NoProfile -File scripts/run_primitive_xilinx_ppa.ps1 -Part xc7a100tcsg324-1",
            "python scripts/collect_primitive_xilinx.py"]}
    (OUT/"summary.json").write_text(json.dumps(result, indent=2)+"\n")
    with (OUT/"comparison.csv").open("w", newline="") as fp:
        writer = csv.writer(fp)
        writer.writerow(["part", "n", "block", "baseline_lut_median", "candidate_lut_median", "lut_change_pct",
            "baseline_sta_mhz_min", "baseline_sta_mhz_median", "baseline_sta_mhz_max",
            "candidate_sta_mhz_min", "candidate_sta_mhz_median", "candidate_sta_mhz_max", "sta_change_pct",
            "baseline_spread_pct", "candidate_spread_pct"])
        for c in comparisons:
            a, b = c["variants"]["baseline"], c["variants"]["candidate"]
            writer.writerow([c["part"], c["n"], c["block"], a["slice_luts"]["median"], b["slice_luts"]["median"],
                c["lut_change_percent"], *[a["r2r_fmax_sta_estimate_mhz"][x] for x in ("min", "median", "max")],
                *[b["r2r_fmax_sta_estimate_mhz"][x] for x in ("min", "median", "max")],
                c["sta_estimate_change_percent"], a["sta_spread_percent"], b["sta_spread_percent"]])
    print(json.dumps({k: result[k] for k in ("status", "runs", "all_r2r_pass_200mhz", "all_synthetic_benchmark_timing_pass")}))


if __name__ == "__main__":
    main()
