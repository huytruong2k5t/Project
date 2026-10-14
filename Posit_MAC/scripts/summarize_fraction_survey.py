"""Audit paired L1 precision survey and export statistics/standard plots.

Run from Posit_MAC. Optional local matplotlib dependencies are never installed
into the runtime: scratch/fraction_plot_deps is used if present.
"""
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / "results/fraction_survey_20261015"
WIDTHS = [8, 10, 12, 14, 16, 18, 20, 24, 26]
POLICIES = ["n2", "n4", "n8", "full", "input_only"]
GROUPS = ["near_one", "balanced_scale", "uniform_bits"]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_rows(path):
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def audit(rows, count):
    assert len(rows) == len(GROUPS) * (len(WIDTHS) * len(POLICIES) + 1)
    index = {(r["group"], int(r["width"]), r["policy"]): r for r in rows}
    assert len(index) == len(rows), "Duplicate configurations"
    for group in GROUPS:
        expected = {(group, w, p) for w in WIDTHS for p in POLICIES} | {(group, 26, "exact")}
        selected = [r for r in rows if r["group"] == group]
        assert set(k for k in index if k[0] == group) == expected
        assert {int(r["samples"]) for r in selected} == {count}
        assert len({r["corpus_fnv1a"] for r in selected}) == 1
        for r in selected:
            assert 0 <= int(r["matches"]) <= count
            assert math.isclose(float(r["match_pct"]), int(r["matches"])*100/count, abs_tol=1e-10)
            assert 0 <= int(r["iteration_cut"]) <= count
            assert 0 <= float(r["mean_iterations"]) <= int(r["budget"])
            for prefix in ["pre", "out"]:
                vals = [float(r[f"{prefix}_{field}_pct"]) for field in ["p50", "p95", "p99", "max"]]
                assert all(math.isfinite(v) and v >= 0 for v in vals)
                assert vals == sorted(vals)
            cdf = [int(v) for k, v in r.items() if k.startswith("lt_")]
            assert cdf == sorted(cdf) and all(0 <= v <= count for v in cdf)
            if r["policy"] in ["full", "input_only", "exact"]:
                assert int(r["iteration_cut"]) == 0
        exact = index[group, 26, "exact"]
        input26 = index[group, 26, "input_only"]
        assert int(exact["matches"]) == count and float(exact["pre_max_pct"]) == 0
        assert int(input26["matches"]) == count and float(input26["pre_max_pct"]) == 0
        assert exact["out_p99_pct"] == input26["out_p99_pct"]
        for w in WIDTHS:
            assert float(index[group, w, "input_only"]["pre_p99_pct"]) <= float(index[group, w, "full"]["pre_p99_pct"]) + 1e-12
        # Same budget at W=8 must give identical n8/full outcomes.
        for field in ["pre_p99_pct", "out_p99_pct", "matches", "mean_iterations"]:
            assert index[group, 8, "n8"][field] == index[group, 8, "full"][field]
    return index


assert (RUN / "status.txt").read_text() == "COMPLETE", "Model run is incomplete"
assert (RUN / "pilot.csv").read_bytes() == (RUN / "pilot_ubsan.csv").read_bytes()
sources = {}
for line in (RUN / "source.sha256").read_text().splitlines():
    digest, relative = line.split(maxsplit=1)
    assert sha(ROOT / relative) == digest, f"Changed model source: {relative}"
    sources[relative] = digest
sources["scripts/summarize_fraction_survey.py"] = sha(Path(__file__))
for name in ["pilot.log", "pilot_ubsan.log", "main.log"]:
    log = (RUN / name).read_text()
    assert re.search(r"COMPLETE independent_checks=\d+ mismatches=0", log)
    assert "FAIL" not in log
rows = read_rows(RUN / "accuracy.csv")
index = audit(rows, 100000)
audit(read_rows(RUN / "pilot.csv"), 1000)

table_fields = ["group", "fraction_bits", "input_only_p99_pct", "n2_p99_pct", "n4_p99_pct",
                "n8_mean_pct", "n8_p99_pct", "n8_match_pct", "n8_iteration_cut_pct",
                "full_p99_pct", "full_match_pct", "full_mean_iterations"]
table = []
for group in GROUPS:
    for w in WIDTHS:
        n8, full = index[group, w, "n8"], index[group, w, "full"]
        table.append(dict(group=group, fraction_bits=w,
            input_only_p99_pct=float(index[group, w, "input_only"]["pre_p99_pct"]),
            n2_p99_pct=float(index[group, w, "n2"]["out_p99_pct"]),
            n4_p99_pct=float(index[group, w, "n4"]["out_p99_pct"]),
            n8_mean_pct=float(n8["out_mean_pct"]), n8_p99_pct=float(n8["out_p99_pct"]),
            n8_match_pct=float(n8["match_pct"]), n8_iteration_cut_pct=100*int(n8["iteration_cut"])/100000,
            full_p99_pct=float(full["out_p99_pct"]), full_match_pct=float(full["match_pct"]),
            full_mean_iterations=float(full["mean_iterations"])))
with (RUN / "selection_table.csv").open("w", encoding="utf-8", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=table_fields)
    writer.writeheader()
    writer.writerows(table)

# Numeric frontier only: fraction width is a proxy, not a LUT/power/timing result.
frontiers = {}
for group in GROUPS:
    entries = [r for r in table if r["group"] == group]
    keep = []
    for a in entries:
        if not any(b["fraction_bits"] <= a["fraction_bits"] and
            b["n8_mean_pct"] <= a["n8_mean_pct"] and b["n8_p99_pct"] <= a["n8_p99_pct"] and
            any(b[k] < a[k] for k in ["fraction_bits", "n8_mean_pct", "n8_p99_pct"])
            for b in entries if b is not a):
            keep.append(a["fraction_bits"])
    frontiers[group] = keep

summary = dict(status="PASS_RESEARCH_SURVEY", date="2026-10-15", format="posit(32,3)",
    seed=20261015, prng="SplitMix64; group state=seed+group_index*0x100000001b3",
    samples_per_distribution=100000, unique_main_pairs=300000,
    main_configurations=len(rows), main_numeric_evaluations=13800000,
    independent_checks=int(re.search(r"independent_checks=(\d+)", (RUN/"main.log").read_text())[1]),
    model_mismatches=0, pilot_ubsan_csv_equal=True,
    profile=dict(widths=WIDTHS, budgets=[2,4,8,"full fraction"], ops="min-popcount; tie A",
                 term_policy="FLOOR Q(width)", final_round="prepack-preserving RNE"),
    references=dict(exact="independent raw-Posit exact_reference<32,3>; checked against L1 exact prepack",
                    approximate="independent bit-position term traversal and serial dyadic encoder",
                    input_only="exact multiplication of truncated input significands; no per-term FLOOR"),
    metrics=dict(relative_error_pct="100*abs(measured - decoded_A*decoded_B)/abs(decoded_A*decoded_B)",
                 prepack="unrounded P_hat, before encoding/clamping", output="decoded final RNE Posit",
                 match="bit equality with RNE of full-width original Posit product",
                 percentile="nearest rank ceil(p*N)-1", cdf="strict error<threshold",
                 code_distance="signed Posit code steps; not constant-value ULPs"),
    distributions=dict(near_one="Independent random 26-bit fractions; |A|,|B| in [1,2); random signs",
        balanced_scale="Independent sf uniform [-32,31], uniform 26-bit significand, random signs; RNE to Posit before multiplication",
        uniform_bits="Uniform native 32-bit codes excluding Zero/NaR; broad tails and range clamping included"),
    corpus_fnv1a={g:index[g,26,"exact"]["corpus_fnv1a"] for g in GROUPS},
    numeric_frontier_n8_width_mean_p99=frontiers, threshold=None, selected_profile=None,
    limitations=["Software numeric study only; no RTL precision change or LUT/FF/Fmax/power measurement",
        "full permits n up to width in this study; frozen RTL cfg_n<=8 is unchanged",
        "26-bit FLOOR full is still approximate; exact retains the full 52-bit product grid",
        "No fused/NF MAC cancellation accuracy measured here; multiplier study only",
        "One seed, 100k/group; not an application distribution or exhaustive proof",
        "uniform_bits includes out-of-range products; in-range denominator reported separately",
        "A wider fraction need not improve fixed-budget OPS accuracy monotonically",
        "No precision threshold or final width selected"],
    source_sha256=sources, csv_sha256=sha(RUN/"accuracy.csv"), table=table,
    compiler=(RUN/"compiler.log").read_text().splitlines()[0],
    commands=["bash scripts/run_fraction_survey.sh", "python scripts/summarize_fraction_survey.py"])

if "--no-plots" not in sys.argv:
    deps = ROOT / "scratch/fraction_plot_deps"
    if deps.is_dir(): sys.path.insert(0, str(deps))
    os.environ["MPLCONFIGDIR"] = str(RUN/"tmp/matplotlib")
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np
    plt.rcParams.update({"font.family":"DejaVu Sans", "font.size":11,
        "axes.spines.top":False, "axes.spines.right":False, "axes.titleweight":"bold"})
    colors={"n2":"#d95d39", "n4":"#cf9b16", "n8":"#1765a8", "full":"#168361", "input_only":"#7953a2"}
    labels={"n2":"n = 2", "n4":"n = 4", "n8":"n = 8", "full":"Hết fraction", "input_only":"Chỉ cắt đầu vào"}
    fig, axes=plt.subplots(2,2,figsize=(14,9),layout="constrained")
    fig.suptitle("Khảo sát độ rộng fraction: độ chính xác và số vòng",fontsize=20,fontweight="bold")
    fig.get_layout_engine().set(h_pad=0.08,w_pad=0.08)
    for policy in POLICIES:
        y=[float(index["near_one",w,policy]["pre_p99_pct"]) for w in WIDTHS]
        axes[0,0].plot(WIDTHS,[v if v else np.nan for v in y],marker="o",color=colors[policy],label=labels[policy])
    axes[0,0].set(title="P99 sai số tích trước làm tròn",xlabel="Bit fraction giữ lại",ylabel="Sai số tương đối (%)",yscale="log")
    axes[0,0].legend(fontsize=9,loc="upper right")
    axes[0,0].text(.03,.04,"Input-only 26 bit: sai số trước làm tròn = 0",transform=axes[0,0].transAxes,fontsize=9)
    for policy in ["n8","full"]:
        axes[0,1].plot(WIDTHS,[float(index["near_one",w,policy]["out_mean_pct"]) for w in WIDTHS],
            marker="o",color=colors[policy],label=f"{labels[policy]}: trung bình")
        axes[0,1].plot(WIDTHS,[float(index["near_one",w,policy]["out_p99_pct"]) for w in WIDTHS],
            marker="s",ls="--",color=colors[policy],label=f"{labels[policy]}: P99")
    axes[0,1].set(title="Sai số đầu ra sau RNE",xlabel="Bit fraction giữ lại",ylabel="Sai số tương đối (%)",yscale="log")
    axes[0,1].legend(fontsize=9)
    for policy in ["n8","full","input_only"]:
        axes[1,0].plot(WIDTHS,[float(index["near_one",w,policy]["match_pct"]) for w in WIDTHS],
            marker="o",color=colors[policy],label=labels[policy])
    axes[1,0].set(title="Tỷ lệ khớp bit với tích exact đã RNE",xlabel="Bit fraction giữ lại",ylabel="Cặp khớp (%)",ylim=(-2,104))
    axes[1,0].legend(fontsize=9)
    for policy in ["n2","n4","n8","full"]:
        axes[1,1].plot(WIDTHS,[float(index["near_one",w,policy]["mean_iterations"]) for w in WIDTHS],
            marker="o",color=colors[policy],label=labels[policy])
    axes[1,1].set(title="Số vòng fraction thực hiện trung bình",xlabel="Bit fraction giữ lại",ylabel="Vòng / phép nhân")
    axes[1,1].legend(fontsize=9)
    for ax in axes.flat:
        ax.set_xticks(WIDTHS); ax.grid(True,alpha=.18)
    fig.supxlabel("posit(32,3), 100.000 cặp chung, |A| và |B| trong [1,2). FLOOR/RNE, OPS min-popcount. Chưa đo PPA.",fontsize=10)
    fig.savefig(RUN/"fraction_accuracy.png",dpi=160)
    fig.savefig(RUN/"fraction_accuracy.svg")
    plt.close(fig)

    keys=[k for k in rows[0] if k.startswith("lt_")]
    thresholds=[k.removeprefix("lt_").removesuffix("_pct_count") for k in keys]
    fig,axes=plt.subplots(1,2,figsize=(17,7),layout="constrained")
    fig.suptitle("Phân bố sai số đầu ra: tỷ lệ mẫu dưới từng ngưỡng",fontsize=19,fontweight="bold")
    for ax,policy in zip(axes,["n8","full"]):
        values=np.array([[int(index["near_one",w,policy][k])*100/100000 for k in keys] for w in WIDTHS])
        im=ax.imshow(values,cmap="YlGnBu",vmin=0,vmax=100,aspect="auto")
        ax.set(title=labels[policy],xlabel="Ngưỡng sai số tương đối (%)",ylabel="Bit fraction",
            xticks=np.arange(len(keys)),xticklabels=thresholds,yticks=np.arange(len(WIDTHS)),yticklabels=WIDTHS)
        ax.tick_params(axis="x",labelrotation=45)
        for i in range(len(WIDTHS)):
            for j in range(len(keys)):
                v=values[i,j]
                label="100" if v==100 else "0" if v==0 else "~100" if v>=99.95 else "<0.1" if v<.05 else f"{v:.1f}"
                ax.text(j,i,label,ha="center",va="center",fontsize=9,
                    color="white" if values[i,j]>65 else "#142b45")
    fig.colorbar(im,ax=axes,label="Mẫu có sai số < ngưỡng (%)",shrink=.8)
    fig.supxlabel("100.000 cặp near_one chung. ~100 là gần 100%, chưa phải toàn bộ mẫu. Chưa chốt ngưỡng lựa chọn.",fontsize=11)
    fig.savefig(RUN/"fraction_distribution.png",dpi=160)
    fig.savefig(RUN/"fraction_distribution.svg")
    plt.close(fig)
    summary["plot_versions"]={"matplotlib":matplotlib.__version__,"numpy":np.__version__}
    summary["plot_sha256"]={p.name:sha(p) for p in RUN.glob("fraction_*.png")}
    summary["plot_sha256"].update({p.name:sha(p) for p in RUN.glob("fraction_*.svg")})
elif (RUN/"summary.json").exists():
    previous=json.loads((RUN/"summary.json").read_text())
    for key in ["plot_versions","plot_sha256"]:
        if key in previous: summary[key]=previous[key]
    for name,digest in summary.get("plot_sha256",{}).items(): assert sha(RUN/name)==digest
(RUN/"summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print("PASS: 138 rows; paired corpus; exact oracle; independent recurrence; pilot/UBSan identical.")
for r in table:
    if r["group"]=="near_one": print(json.dumps(r,ensure_ascii=False))
print("No threshold or final fraction width selected. Full-MAC/F/PPA remain unmeasured.")
