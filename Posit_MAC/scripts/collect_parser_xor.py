"""Audit parser-XOR results; fail closed on incomplete evidence."""
from pathlib import Path
import csv
import hashlib
import json
import re
import statistics

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/parser_xor_20261016"


def read(path):
    raw = (OUT / path).read_bytes()
    return raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig", errors="replace")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    for name, digest in json.loads(read("study_inputs.json")).items():
        assert sha(ROOT / name) == digest, f"Measured input changed: {name}"
    for module in ("posit_parser", "posit_parser_comb"):
        before = read(f"source/baseline/{module}.sv")
        after = (ROOT / f"rtl/parser/{module}.sv").read_text()
        header = lambda s: s[s.index(f"module {module} #("):].split(");", 1)[0]
        assert header(before) == header(after), "Public interface/parameters changed"
        assert after.count("lod_lzd_core #(") == 1
        if module == "posit_parser":
            assert before.split("// Empty slots", 1)[1] == after.split("// Empty slots", 1)[1], "Elastic banks/control changed"
            sync = lambda s: s[s.index("    always_ff"):s.index("    assign reset_b_sync_clk")]
            assert sync(before) == sync(after), "Reset synchronizer changed"
    assert "GENERATOR PASS total=2465812" in read("generator.log")
    comb_log = read("parser_comb/simulate.log")
    pipe_log = read("parser_pipeline/simulate.log")
    assert "PARSER_COMB ALL PASS" in comb_log
    assert "PARSER_PIPELINE ALL PASS" in pipe_log
    comb = [list(map(int, m)) for m in re.findall(
        r"PARSER PASS NB=(\d+) ES=(\d+) checks=(\d+)", comb_log)]
    pipeline = [list(map(int, m)) for m in re.findall(
        r"PIPE PASS NB=(\d+) ES=(\d+) checks=(\d+) reset=(\d+) discarded=(\d+) stalls=(\d+) full=(\d+) simultaneous=(\d+) bubbles=(\d+) latency=(\d+)", pipe_log)]
    assert len(comb) == len(pipeline) == 4
    assert sum(m[2] for m in comb) == sum(m[2] for m in pipeline) == 2465812
    assert all(m[3] == 3 and m[4] == 3 and min(m[5:]) > 0 for m in pipeline)
    params_log = read("params/simulate.log")
    assert "PARSER_XOR_PARAMS ALL PASS" in params_log
    params = [list(map(int, m)) for m in re.findall(
        r"PARAM PASS NB=(\d+) ES=(\d+) SW=(\d+) checks=(\d+) accepted=(\d+) retired=(\d+) stalled=(\d+)", params_log)]
    assert len(params) == 9 and all(min(m[4:]) > 0 for m in params)
    lint = list((OUT / "lint").glob("*.log"))
    assert len(lint) == 16
    assert all(not re.search(r"%Warning|%Error", f.read_text()) for f in lint)
    integration = {}
    for name in ("nf_es2", "nf_es3"):
        log = read(f"integration/{name}/smoke.log")
        m = re.search(r"W11 HARNESS PASS NB=32 ES=(\d+) completed=(\d+) reset_aborts=(\d+) mismatches=0", log)
        assert m and int(m[2]) == 10000
        integration[name] = dict(es=int(m[1]), completed=int(m[2]), reset_aborts=int(m[3]), mismatch=0)
    log = read("integration/fused/verilator/smoke.log")
    assert "W13 PASS completed=10000 mismatch=0 stages=59340" in log
    integration["fused"] = dict(nb=32, es=3, completed=10000, mismatch=0, stage_checks=59340)
    integration_lint = list((OUT / "integration/lint").glob("*.log")) + [OUT / "integration/fused/lint.log"]
    assert len(integration_lint) == 17
    assert all(not re.search(r"%Warning|%Error", f.read_text()) for f in integration_lint)
    for folder in (OUT / "source").iterdir():
        for path in folder.iterdir():
            if folder.name == "xor":
                current = ROOT / ("rtl/parser/" if path.name.startswith("posit_parser") else "rtl/" if path.suffix == ".vh" else "rtl/common/") / path.name
                assert sha(path) == sha(current), f"Production differs: {current}"
    rows = []
    for part in ("xc7a35tcpg236-1", "xc7a100tcsg324-1"):
        with (OUT / "ppa" / part / "metrics.csv").open() as f:
            part_rows = list(csv.DictReader(f))
        assert len(part_rows) == 12
        assert "PARSER_XOR_PPA_COMPLETE" in read(f"ppa/{part}/console.log")
        for r in part_rows:
            for field in ("lut", "ff", "es", "latches", "unrouted"):
                r[field] = int(r[field])
            for field in ("slack", "hold", "logic_ns", "route_ns"):
                r[field] = float(r[field])
            id_ = f'{r["variant"]}_es{r["es"]}_{r["strategy"]}'
            # Driver's historical filename p2_slack actually contains ALL R2R.
            r["global_r2r_slack"] = float(read(f"ppa/{part}/{id_}/p2_slack.txt"))
            assert r["latches"] == r["unrouted"] == 0
        rows.extend(part_rows)
    comparison = []
    for part in sorted({r["part"] for r in rows}):
        for es in (2, 3):
            before = [r for r in rows if r["part"] == part and r["es"] == es and r["variant"] == "baseline"]
            after = [r for r in rows if r["part"] == part and r["es"] == es and r["variant"] == "xor"]
            entry = dict(part=part, es=es, strategies=3)
            for key, group in (("baseline", before), ("xor", after)):
                entry[key] = dict(lut=statistics.median(r["lut"] for r in group), ff=statistics.median(r["ff"] for r in group),
                    p1_sta_mhz=statistics.median(1000 / (5-r["slack"]) for r in group),
                    global_r2r_sta_mhz=statistics.median(1000 / (5-r["global_r2r_slack"]) for r in group),
                    p1_delay_ns=statistics.median(r["logic_ns"]+r["route_ns"] for r in group))
            entry["lut_change_pct"] = 100 * (entry["xor"]["lut"]/entry["baseline"]["lut"] - 1)
            assert entry["lut_change_pct"] < 0 and entry["xor"]["ff"] == entry["baseline"]["ff"]
            entry["p1_sta_change_pct"] = 100 * (entry["xor"]["p1_sta_mhz"]/entry["baseline"]["p1_sta_mhz"] - 1)
            paired = []
            for a in after:
                b = next(r for r in before if r["strategy"] == a["strategy"])
                paired.append(dict(strategy=a["strategy"], lut_change_pct=100*(a["lut"]/b["lut"]-1),
                                   p1_sta_change_pct=100*((5-b["slack"])/(5-a["slack"])-1)))
            entry["paired_strategies"] = paired
            comparison.append(entry)
    result = dict(status="PASS", date="2026-10-16", mismatch=0,
        comb_checks=2465812, pipeline_checks=2465812, comb_suites=comb, pipeline_suites=pipeline,
        param_checks=sum(m[3] for m in params), param_suites=params,
        strict_lint_profiles=16, integration_strict_lint_profiles=17,
        integration=integration, ppa_runs=len(rows), comparison=comparison,
        simulator=read("version.txt").strip(), compiler=read("compiler.txt").strip(),
        seeds=dict(fixtures=20261005, params="20261016 + NB*100 + ES + SF_W", pipeline="20261005 + NB*17 + ES"),
        oracle="Parser fixtures: L1 plus independent sequential field scan; edge parameters: independent SV scan and cycle equality to frozen dual-detector pipeline. SoftPosit is not linked for field tests; integration uses existing NF/F oracle harnesses.",
        limits="Binary-input simulation, not formal equivalence. Three implementation directives, not random seeds. Registered input boundary adds 34 benchmark FF; same constraints/part/source dependencies. P1 STA estimate=1000/(5ns-slack); no board/full-MAC Fmax, power, CDC/RDC signoff or final large NF/F matrix claim.",
        commands=["bash --noprofile --norc scripts/verify_parser_xor.sh",
                  'LAYOUT_RESULTS_DIR=results/parser_xor_20261016/integration LAYOUT_NF_ES_LIST="2 3" bash --noprofile --norc scripts/verify_rtl_layout.sh',
                  "powershell -NoProfile -File scripts/run_parser_xor_ppa.ps1 -Part <part>",
                  "python scripts/collect_parser_xor.py"])
    inputs = list((OUT / "source").rglob("*"))
    inputs += list(ROOT.glob("scripts/*parser_xor*")) + list(ROOT.glob("tb/*parser_xor*.sv"))
    result["input_sha256"] = {p.relative_to(ROOT).as_posix(): sha(p) for p in inputs if p.is_file()}
    (OUT / "summary.json").write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps({k:result[k] for k in ("status", "comb_checks", "pipeline_checks", "param_checks", "ppa_runs", "comparison")}, indent=2))


if __name__ == "__main__":
    main()
