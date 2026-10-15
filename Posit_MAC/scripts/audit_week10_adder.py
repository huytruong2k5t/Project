"""Audit adder unit evidence; never infer MAC/STA/fused acceptance."""
import collections
import hashlib
import json
import re
from pathlib import Path
from rtl_paths import rtl_source, resolve_source

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / "results/week10_adder"


def read(path):
    raw = path.read_bytes()
    return raw.decode("utf-16") if raw.startswith(b"\xff\xfe") else raw.decode("utf-8-sig")


def coverage(paths):
    points = collections.Counter()
    for path in paths:
        for line in read(path).splitlines():
            if line.startswith("C '"):
                key, count = line[3:].rsplit("' ", 1)
                points[key] += int(count)
    total, hit = collections.Counter(), collections.Counter()
    missing = []
    for key, count in points.items():
        fields = dict(x.split("\x02", 1) for x in key.split("\x01") if "\x02" in x)
        kind = fields["page"].split("/", 1)[0].removeprefix("v_")
        total[kind] += 1
        hit[kind] += count > 0
        if not count:
            missing.append(dict(kind=kind, file=fields.get("f"), line=fields.get("l"),
                                hierarchy=fields.get("h"), object=fields.get("o")))
    assert all(x in total for x in ("line", "branch", "toggle"))
    return dict(metrics={k:dict(hit=hit[k], total=total[k], percent=100*hit[k]/total[k]) for k in total},
                unhit_points=missing, exclusions="None; static/parameter points remain included")


for directory in ("verilator", "modelsim_comb_final", "modelsim_pipeline_final", "invalid_params"):
    assert read(RUN / directory / "run_status.txt").strip() == "COMPLETE", f"Incomplete or failed run: {directory}"

for directory in ("modelsim_comb_final", "modelsim_pipeline_final", "invalid_params"):
    hashes = json.loads(read(RUN / directory / "source_sha256.json"))
    assert all(hashlib.sha256(resolve_source(ROOT / n).read_bytes()).hexdigest() == h for n, h in hashes.items()), f"ModelSim sources changed: {directory}"

for case in range(3):
    rejected = read(RUN / f"invalid_params/case_{case}.log")
    assert "unsupported parameters" in rejected and "INVALID CONFIG WAS NOT REJECTED" not in rejected

profiles = []
comb_rows = pipe_completed = pipe_aborts = 0
for nb, es in ((8, 0), (16, 1), (32, 2), (32, 3)):
    comb = read(RUN / f"modelsim_comb_final/simulate_{nb}_{es}.log")
    pipe = read(RUN / f"modelsim_pipeline_final/simulate_{nb}_{es}.log")
    assert not re.search(r"\*\*\s+(Error|Fatal):", comb + pipe)
    c = re.search(rf"W10 COMB PASS NB={nb} ES={es} rows=(\d+) mismatches=0", comb)
    q = re.search(rf"W10 PIPE PASS NB={nb} ES={es} accepted=(\d+) completed=(\d+) reset_aborts=(\d+) stalls=(\d+) input_stalls=(\d+) max_occupancy=3 reset_events=(\d+) mismatches=0", pipe)
    assert c and q
    rows = sum(1 for _ in (RUN / f"pilot/add_{nb}_{es}.txt").open())
    assert rows == int(c[1]) == int(q[1]) and int(q[2]) + int(q[3]) == rows
    comb_rows += rows
    pipe_completed += int(q[2])
    pipe_aborts += int(q[3])
    for top in ("posit_add_comb", "posit_add"):
        log = read(RUN / f"lint/{top}_{nb}_{es}.log")
        assert not re.search(r"%Warning|%Error", log)
    folder = RUN / f"verilator/{nb}_{es}"
    pilot = json.loads((folder / "pilot_summary.json").read_text())
    assert pilot["completed"] >= 50000 and not pilot["mismatches"]
    assert "W10 HARNESS PASS" in read(folder / "pilot.log")
    cov_paths = [folder / "pilot_coverage.dat"]
    main = None
    if nb == 32:
        main = json.loads((folder / "acceptance_summary.json").read_text())
        assert main["completed"] >= 10000000 and not main["mismatches"]
        assert main["accepted"] == main["completed"] + main["reset_aborts"]
        assert main["max_slots"] == 3 and main["reset_busy"] and main["reset_output_stall"] and main["long_stalls"]
        assert "W10 HARNESS PASS" in read(folder / "acceptance.log")
        cov_paths.append(folder / "acceptance_coverage.dat")
    # Every source used by the compiled snapshot still matches the live source.
    for saved in (folder / "src").rglob("*"):
        if not saved.is_file():
            continue
        if saved.parent.name == "l1":
            live = ROOT / "l1/include" / saved.name
        elif saved.suffix in (".sv", ".vh"):
            live = (ROOT/"tb"/saved.name if saved.name == "adder_verification_top.sv" else rtl_source(saved.name))
        elif saved.name in ("week10_adder_harness.cpp", "week10_add_reference.hpp"):
            live = ROOT / "tb" / saved.name
        else:
            live = ROOT / "l0" / saved.name
        assert saved.read_bytes() == live.read_bytes(), f"Source changed: {saved}"
    measured = coverage(cov_paths)
    (folder / "structural_coverage.json").write_text(json.dumps(measured, indent=2)+"\n")
    profiles.append(dict(NB=nb, ES=es, comb_rows=rows, pipeline_modelsim=dict(accepted=int(q[1]),
                        completed=int(q[2]), reset_aborts=int(q[3]), stalls=int(q[4]),
                        input_stalls=int(q[5]), max_occupancy=3, reset_events=int(q[6])),
                        pilot=pilot, acceptance=main, coverage_metrics=measured["metrics"],
                        fixture_sha256=hashlib.sha256((RUN / f"pilot/add_{nb}_{es}.txt").read_bytes()).hexdigest()))
assert "W10 GENERATOR PASS" in read(RUN / "generator.log")
assert "W10 GENERATOR PASS" in read(RUN / "generator_ubsan.log")
assert "runtime error:" not in read(RUN / "generator_ubsan.log")
frozen = json.loads((ROOT / "results/l1_floor_rne_freeze/summary.json").read_text())
assert all(hashlib.sha256(resolve_source(ROOT / n).read_bytes()).hexdigest() == h for n, h in frozen["source_sha256"].items())
paired = json.loads((RUN / "paired/manifest.json").read_text())
assert paired["sha256"] == hashlib.sha256((RUN / "paired/pilot.txt").read_bytes()).hexdigest()
source_files = [*ROOT.glob("rtl/adder/posit_add*.sv"), *ROOT.glob("tb/*week10*"),
                ROOT / "tb/adder_verification_top.sv", ROOT / "l1/test/gen_week10_adder.cpp",
                ROOT / "l1/test/gen_nf_f_corpus.cpp", *ROOT.glob("scripts/*week10*")]
report = dict(status="PASS: Week10 adder unit milestone and comparison-input contract", date="2026-10-12",
              scope="W10-02..07; NF MAC/Gate3 and fused implementation remain later milestones",
              comb_modelsim_rows=comb_rows, pipeline_modelsim_completed=pipe_completed,
              pipeline_modelsim_reset_aborts=pipe_aborts,
              large_completed=sum(p["acceptance"]["completed"] for p in profiles if p["acceptance"]),
              mismatches=0, profiles=profiles, strict_lint="8/8 clean --timing -Wall",
              invalid_params="3/3 rejected: SF_W too narrow, F mismatch, F_OUT mismatch",
              seed_base=20261012, compiler=read(RUN / "compiler.log").splitlines()[0],
              verilator=read(RUN / "verilator_version.log").strip(),
              modelsim=read(RUN / "modelsim_pipeline_final/version.log").strip(),
              softposit_sha256=hashlib.sha256((ROOT / "l0/libsoftposit.so").read_bytes()).hexdigest(),
              frozen_L1="PASS all source hashes unchanged", paired_input=paired,
              source_sha256={str(x.relative_to(ROOT)):hashlib.sha256(x.read_bytes()).hexdigest() for x in source_files if x.is_file()},
              limits=["Raw coverage unhit points retained, no final AC04 signoff claimed",
                      "P16 full2^32 and P32 final>=1e8 AC02 remain open",
                      "No MAC NF/C_eff/acc_mode feedback integration or Gate3 yet",
                      "No fused residual/window RTL, no paired accuracy or PPA results",
                      "Verilator --no-timing checks clocked function; ModelSim retains CK2Q/4-state checks"])
(RUN / "summary.json").write_text(json.dumps(report, indent=2)+"\n")
print("W10 AUDIT PASS", comb_rows, "comb;", pipe_completed, "pipeline;", report["large_completed"], "large completed; mismatches=0")
for p in profiles:
    print(p["NB"], p["ES"], p["coverage_metrics"])
