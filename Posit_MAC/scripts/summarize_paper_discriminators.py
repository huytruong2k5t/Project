"""Check archived discriminating traces, source evidence and paired Table I runs."""
import csv
import hashlib
import json
from collections import Counter
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/paper_discriminators"
NAMES = ["fig3", "tie_b", "legacy7", "input_anchor", "exact_residual",
         "guard1_pack12", "guard12_pack12", "source_uncut", "post_sum_pack12", "signed_floor"]
PAIRS = {"prefix126_127": ("fig3", "legacy7"), "equal_score": ("fig3", "tie_b"),
         "rnd_boundary": ("fig3", "exact_residual"), "anchor_cut": ("fig3", "input_anchor"),
         "term_cut": ("fig3", "guard12_pack12"), "guard_depth": ("guard1_pack12", "guard12_pack12"),
         "output_width": ("guard12_pack12", "source_uncut"),
         "post_sum_cut": ("fig3", "post_sum_pack12"), "signed_cut": ("fig3", "signed_floor")}


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def write_csv(name, rows):
    with (OUT / name).open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


for platform in ("windows", "linux", "ubsan"):
    assert "DISCRIMINATORS PASS checks=205882" in (OUT / f"test_{platform}.log").read_text(encoding="utf-8-sig")
for name in ("vectors.csv", "outputs.csv", "traces.csv", "coverage.csv",
             "first_differences.csv", "source_fixture.csv"):
    reference = read_csv(OUT / "windows" / name)
    assert reference == read_csv(OUT / "linux" / name) == read_csv(OUT / "ubsan" / name), name
vectors = read_csv(OUT / "linux/vectors.csv")
assert len(vectors) == 292
counts = Counter(row["category"] for row in vectors)
assert all(counts[category] == 32 for category in PAIRS)
outputs = {(r["case_id"], r["candidate"]): r for r in read_csv(OUT / "linux/outputs.csv")}
assert len(outputs) == 292 * 10
representatives = []
for category, (left, right) in PAIRS.items():
    selected = next(row for row in vectors if row["category"] == category)
    a, b = outputs[selected["case_id"], left], outputs[selected["case_id"], right]
    assert a["bits_hex"] != b["bits_hex"]
    representatives.append(dict(**selected, reference=left, alternative=right,
                                reference_bits=a["bits_hex"], alternative_bits=b["bits_hex"]))
write_csv("representative_vectors.csv", representatives)
fixture = read_csv(OUT / "linux/source_fixture.csv")
assert [r["candidate"] for r in fixture if r["packed_match"] == "0"] == ["source_uncut"]
assert all(r["projected_trace_match"] == "1" for r in fixture)
assert fixture[7]["actual_bits"] == "0x1ae34800"
assert all(r["expected_bits"] == "0x1ae34000" for r in fixture)

hypotheses = [
    ("fig3", "compatible_fixture_not_confirmed_original", "2021 Fig.4/5; 2024 Fig.3", "Internal hidden/carry layout and cut flags remain reconstructed."),
    ("tie_b", "unresolved", "Fig.4 forces X; no published equal-score OPS trace", "A/B tie candidates differ in local vectors; neither is selected by the source fixture."),
    ("legacy7", "conditional_disagreement_PT2_padding", "2024 Table IV; prefix126/127", "Q12 zero extension differs from 7-bit complement; original padding/LUT not fully available."),
    ("input_anchor", "incompatible_literal_anchor_contract", "2024 III-C/Fig.3", "Source shift=l1-lk and exponent uses l1. Fig.4 has l1=0 and cannot discriminate anchors."),
    ("exact_residual", "algorithm_control_incompatible_bitflip_contract", "2024 III-A eq.10-12", "Exact residual adds one after complement; paper describes bit inversion without add-one."),
    ("guard1_pack12", "unresolved_internal_precision", "2021 Fig.4/5", "Matches output and projected Q12 trace; internal guard not proved."),
    ("guard12_pack12", "compatible_output_not_confirmed_internal_width", "2021 Fig.4/5", "12-bit final fraction is supported; retaining 12 internal guard bits is a local hypothesis."),
    ("source_uncut", "rejected_as_2021_bit_exact_baseline", "2021 Fig.4 output and Fig.5 zero padding", "Returns 0x1ae34800 instead of 0x1ae34000. Retained only as historical statistical control."),
    ("post_sum_pack12", "unresolved_hidden_precision_alternative", "2024 Fig.3 logical shifter/adder; 2021 fixture", "Same published output; retaining exact fractional sums changes the finite-cut architecture."),
    ("signed_floor", "incompatible_logical_magnitude_shift_contract", "2024 Fig.3 logical right shift then add/subtract", "Negative term -ceil(Y/2^d) differs from applying coefficient to floor(Y/2^d). No published negative-tail trace."),
]
write_csv("hypotheses.csv", [dict(candidate=c, evidence_status=s, source=e, limitation=l)
                             for c, s, e, l in hypotheses])
pilot = read_csv(OUT / "pilot/measurement.csv")
assert pilot == read_csv(OUT / "linux/measurement.csv")
assert (OUT / "pilot.log").read_text(encoding="utf-8-sig").splitlines() == (OUT / "pilot_linux.log").read_text(encoding="utf-8-sig").splitlines()
measurement = read_csv(OUT / "acceptance/measurement.csv")
assert len(measurement) == 36
numeric = {}
for profile in ("fig3", "guard12_pack12", "source_uncut"):
    rows = [row for row in measurement if row["profile"] == profile]
    assert len(rows) == 12
    for row in rows:
        assert int(row["accepted"]) == 200000000
        assert Decimal(row["percent"]) == Decimal(row["count"]) / Decimal(2000000)
        assert Decimal(row["delta_pp"]) == Decimal(row["percent"]) - Decimal(row["paper_percent"])
    maximum = max(abs(Decimal(row["delta_pp"])) for row in rows)
    numeric[profile] = dict(max_delta_pp=str(maximum), numeric_threshold_pass=maximum <= 1,
                           original_baseline_accepted=False)
prior = read_csv(ROOT / "results/paper_fig3/table1_comparison.csv")
for old in prior:
    denominator = {"Err<0.1%": "1000", "Err<0.5%": "200", "Err<1%": "100", "Err<5%": "20"}[old["threshold"]]
    for profile, field in (("fig3", "fig3_percent"), ("source_uncut", "source_percent")):
        new = next(r for r in measurement if r["profile"] == profile and r["n"] == old["n"] and r["threshold_denominator"] == denominator)
        assert abs(Decimal(new["percent"]) - Decimal(old[field])) <= Decimal("0.000001")
log = (OUT / "table1_200m.log").read_text(encoding="utf-8-sig")
assert "accepted=200000000 attempted=200000021 excluded_zero=21 draws=400000042 seed=271828 fingerprint=4478e811a897da7" in log
metadata = dict(
    date="2026-10-08", steps_completed=[1, 2, 3, 4], original_baseline_status="processing",
    selected_records=292, unique_cases=len({(r["a_hex"], r["b_hex"], r["n"], r["force_a"]) for r in vectors}),
    categories=dict(counts), candidates=NAMES, searched_pairs_n=199800,
    verification=dict(checks_per_platform=205882, platforms=["Windows", "Linux", "Linux UBSan"],
                      cross_platform_csv="MATCH", raw_pairs=10000, raw_seed=20261008, n="1..8",
                      oracle="Independent signed residual Q96 and integer division; shared accepted parser/packer and frozen OPS",
                      scope="Local hypotheses, not author RTL; projected published trace does not establish internal precision"),
    source_fixture=dict(input_X="0x1c900000", input_Y="0x3c820000", force_X=True,
                        significands_Q12=[5248, 4616], scale_factors=[-10, -1], n_terms=3,
                        powers=[0, -2, -5], coefficients=[1, 1, 1], accumulators_Q12=[4616, 5770, 5914],
                        final_fraction="0x71a", expected_output="0x1ae34000", uncut_output="0x1ae34800",
                        OPS_tie_policy_test=False),
    measurement=dict(samples=200000000, seed=271828, distribution="uniform-value grid24 [0,1)",
                     generator="std::mt19937_64", oracle="Original FP32_RNE product before cut11",
                     format="posit32 ES3", input_fraction_bits=12, rounding="TRUNC",
                     thresholds="Strict <, exact integer comparison", attempted=200000021,
                     excluded_zero=21, draws=400000042, fingerprint="04478e811a897da7",
                     exit_status_scope="Measurement exits0 on successful execution; numeric gate stored separately", profiles=numeric),
    pilot=dict(samples=1000000, seed=271828, platforms=["Windows", "Linux"], exact_counts_match=True),
    compilers={p: (OUT / f"compiler_{p}.log").read_text(encoding="utf-8-sig").splitlines()[0] for p in ("linux", "windows")},
    SoftPosit="Not used by this research measurement: shared verified FP32_RNE oracle, thresholds compared by exact integers; L0 not changed",
    commands=["make -C l1 test_paper_discriminators test_paper_discriminators.exe test_paper_discriminators_ubsan",
              "./l1/test_paper_discriminators results/paper_discriminators/linux",
              "./l1/test_paper_discriminators_ubsan results/paper_discriminators/ubsan",
              r".\l1\test_paper_discriminators.exe results/paper_discriminators/windows",
              r".\l1\test_paper_discriminators.exe --measure results/paper_discriminators/pilot 1000000 271828",
              "./l1/test_paper_discriminators --measure results/paper_discriminators/linux 1000000 271828",
              "./l1/test_paper_discriminators --measure results/paper_discriminators/acceptance 200000000 271828",
              "python scripts/summarize_paper_discriminators.py"],
    remaining=["Original OPS tie and prefix padding/LUT", "Internal carry/normalize/cut implementation", "Author generator/seed/filter"],
    production_changes="No normative L1/RTL change; research-only test harness and build targets",
    sources=dict(paper2021="An Approximate and Iterative Posit Multiplier Architecture for FPGAs.pdf",
                 visual_page="results/paper_discriminators/paper2021_page3.png", journal2024_doi="10.1109/TVLSI.2024.3354726",
                 journal2024_url="https://www.scribd.com/document/818436812/Area-Efficient-Iterative-Logarithmic-Approximate-Multipliers-for-IEEE-754-and-Posit-Numbers"))
paths = [ROOT / "l1/test/test_paper_discriminators.cpp", ROOT / "l1/test/paper_discriminator_study.hpp",
         ROOT / "l1/Makefile", Path(__file__), ROOT / metadata["sources"]["paper2021"]]
paths += [ROOT / "l1" / name for name in ("test_paper_discriminators", "test_paper_discriminators.exe", "test_paper_discriminators_ubsan")]
paths += list((ROOT / "l1/include").glob("*.hpp"))
paths += [p for p in OUT.rglob("*") if p.is_file() and p.suffix in (".csv", ".log", ".png")]
metadata["sha256"] = {str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}
(OUT / "summary.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps(dict(verification="PASS", selected_records=292, unique_cases=metadata["unique_cases"], numeric=numeric, baseline="processing"), ensure_ascii=False))
