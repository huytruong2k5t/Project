"""Validate archived logs and record the Fig.3 reconstruction outcome."""
import csv
import hashlib
import io
import json
import re
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "paper_fig3"
FIELDS = ["Err<0.1%", "Err<0.5%", "Err<1%", "Err<5%"]
PAPER = [["9.87", "32.19", "50.03", "95.57"],
         ["44.69", "83.17", "95.05", "99.99"],
         ["87.09", "99.79", "99.99", "99.99"]]


def write_csv(name, rows):
    with (OUT / name).open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


log = (OUT / "table1_200m_windows.log").read_text(encoding="utf-8-sig")
header = next(line for line in log.splitlines() if line.startswith("profile,n,"))
data = [line for line in log.splitlines()
        if re.match(r"^(baseline|minpop|relative|source|fig3),[234],", line)]
rows = list(csv.DictReader(io.StringIO("\n".join([header] + data))))
assert len(rows) == 15
write_csv("table1_all_profiles.csv", rows)

with (ROOT / "results/paper_source_table1.csv").open(encoding="utf-8-sig") as stream:
    previous = {(row["profile"], row["n"]): row for row in csv.DictReader(stream)}
current = {(row["profile"], row["n"]): row for row in rows}
for profile in ("baseline", "relative", "source"):
    for n in ("2", "3", "4"):
        for field in FIELDS:
            assert current[profile, n][field] == previous[profile, n][field]

comparison = []
for n in range(2, 5):
    fig3, source = current["fig3", str(n)], current["source", str(n)]
    for j, field in enumerate(FIELDS):
        rate = Decimal(fig3[field])
        comparison.append(dict(
            n=n, threshold=field, paper_percent=PAPER[n - 2][j],
            fig3_percent=fig3[field], source_percent=source[field],
            fig3_minus_paper_pp=str(rate - Decimal(PAPER[n - 2][j])),
            fig3_minus_source_pp=str(rate - Decimal(source[field]))))
write_csv("table1_comparison.csv", comparison)

pilots = []
for seed in (314159, 314160, 42, 2026, 20261004):
    name = f"pilot_10m_seed{seed}.log"
    text = (OUT / name).read_text(encoding="utf-8-sig")
    result = re.search(r"NOT_REPRODUCED max_delta_pp=([0-9.]+)", text)
    assert result and "accepted=10000000 " in text
    pilots.append(dict(seed=seed, accepted=10000000, max_delta_pp=result[1],
                       status="NOT_REPRODUCED", log=name))
write_csv("pilot_summary.csv", pilots)

for platform in ("windows", "linux", "ubsan"):
    text = (OUT / f"test_{platform}.log").read_text(encoding="utf-8-sig").strip()
    assert "FIG3_WIDTH PASS checks=509407337 exhaustive_pairs=16777216" in text

def read_csv(name):
    with (OUT / name).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))

assert read_csv("trace_windows.csv") == read_csv("trace_linux.csv")
smokes = []
for platform in ("windows", "linux"):
    lines = (OUT / f"pilot_1m_seed271828_{platform}.log").read_text(encoding="utf-8-sig").splitlines()
    smokes.append([line for line in lines if not line.startswith("Table_I_numeric_acceptance=")])
assert smokes[0] == smokes[1]
for name, marker in (("source_regression.log", "SOURCE_PROFILE PASS checks=29878945"),
                     ("anchor_regression.log", "SELF_TEST PASS checks=3300128"),
                     ("legacy_regression.log", "checks=531039 seed=314159 PASS")):
    assert marker in (OUT / name).read_text(encoding="utf-8-sig")
assert "accepted=200000000 attempted=200000021 excluded_zero=21" in log
assert "pair_fingerprint_fnv1a64=4478e811a897da7" in log
result = re.search(r"NOT_REPRODUCED max_delta_pp=([0-9.]+) elapsed_seconds=([0-9.]+)", log)
assert result

metadata = dict(
    date="2026-10-08", timezone="Asia/Saigon", width_cut_milestone="PASS",
    table1_acceptance="NOT_REPRODUCED", original_baseline_status="processing",
    contract=dict(fraction_bits=12, significand_bits_including_hidden=13,
                  payload_bits=13, separate_carry_bits=1, logical_magnitude_bits=14,
                  fractional_guard_bits=0, anchor="first signed-power term",
                  term="floor(Y / 2^(p1-pk)) before coefficient; shift>=13 gives0",
                  accumulation="A += coefficient * term; preserve carry, reject wrap/borrow",
                  normalization="after last term, fixed Q12 feedback anchor",
                  final_fraction_bits=12, table1_pack="TRUNC",
                  layout_provenance="Local hidden/carry encoding; original flag RTL unavailable",
                  preserved_assumptions=["PT2 prefix7 zero-extended to Q12", "tie-A",
                                         "local generator/seed/filters", "final normalization flags"]),
    source=dict(doi="10.1109/TVLSI.2024.3354726",
                inspected="Fig.3 p460/III-C:12/13-bit labels at tb1=11, flags omitted",
                url="https://www.scribd.com/document/818436812/Area-Efficient-Iterative-Logarithmic-Approximate-Multipliers-for-IEEE-754-and-Posit-Numbers",
                guard12="Not confirmed; historical source profile retained separately"),
    verification=dict(platforms=["Windows", "Linux", "Linux UBSan"],
                      checks_per_platform=509407337, exhaustive_q12_pairs=16777216,
                      raw_corner_pairs=100100, n="1..8", raw_seed=20261008,
                      max_accumulator=12286, carry_states=21294248,
                      cleared_carries=224735, shifts_ge_13=45400064,
                      oracle="Independent signed residual Q96, integer division for cut",
                      scope="Scalar arithmetic; shared accepted parser/packer, frozen OPS",
                      cross_platform="MATCH trace and1M measurement rows/counters/fingerprint",
                      regressions=dict(source_checks=29878945, anchor_checks=3300128,
                                       legacy_checks=531039, status="PASS")),
    measurement=dict(accepted_pairs=200000000, attempted_pairs=200000021,
                     excluded_input_zero=21, excluded_other=0, generator_draws=400000042,
                     seed=271828, generator="std::mt19937_64; grid24 uniform-value [0,1)",
                     oracle="FP32_RNE before cut11", format="posit32 ES3, 2021 Table I",
                     threshold_comparison="strict < using integer comparisons",
                     fingerprint_fnv1a64="04478e811a897da7", fig3_max_delta_pp=float(result[1]),
                     source_max_delta_pp=0.984213, acceptance_limit_pp=1.0, exit_code=1,
                     exit_reason="Numeric acceptance failed; functional tests PASS",
                     historical_controls="36 accuracy cells baseline/relative/source MATCH",
                     elapsed_seconds=float(result[2]),
                     precision_note="Rates/gaps printed to6 decimals independently; last-digit rounding",
                     pilot_seeds=[row["seed"] for row in pilots], pilot_pairs_per_seed=10000000,
                     pilot_gap_range_pp=[min(float(row["max_delta_pp"]) for row in pilots),
                                         max(float(row["max_delta_pp"]) for row in pilots)],
                     pilot_status="All five NOT_REPRODUCED"),
    build=dict(compiler_linux=(OUT / "compiler_linux.log").read_text().splitlines()[0],
               compiler_windows=(OUT / "compiler_windows.log").read_text().splitlines()[0],
               softposit="Not used; FP32 oracle plus accepted L1 parser/packer",
               working_directory=str(ROOT),
               targets="make -C l1 test_paper_fig3 test_paper_fig3.exe test_paper_fig3_ubsan test_paper_table1.exe test_paper_source_profile.exe",
               windows_test="./l1/test_paper_fig3.exe results/paper_fig3/trace_windows.csv",
               linux_test="./l1/test_paper_fig3 results/paper_fig3/trace_linux.csv",
               ubsan_test="./l1/test_paper_fig3_ubsan",
               measurement="./l1/test_paper_table1.exe --samples 200000000 --seed 271828 --profile fig3 --require-match",
               pilot="./l1/test_paper_table1.exe --samples 10000000 --seed SEED --profile fig3",
               regression=["./l1/test_paper_source_profile", "./l1/test_paper_anchor --self-test", "./l1/test_paper_baseline"],
               normative_l1_changed=False, rtl_changed=False))

files = [ROOT / name for name in (
    "l1/include/paper_fig3_accumulator.hpp", "l1/include/paper_multiplier.hpp",
    "l1/include/paper_ops.hpp", "l1/include/paper_measurement.hpp",
    "l1/test/test_paper_fig3.cpp", "l1/test/test_paper_table1.cpp", "l1/Makefile",
    "l1/test_paper_fig3.exe", "l1/test_paper_fig3", "l1/test_paper_fig3_ubsan",
    "l1/test_paper_table1.exe", "scripts/summarize_paper_fig3.py")]
files += [path for path in OUT.iterdir() if path.is_file() and path.name != "summary.json"]
metadata["sha256"] = {path.relative_to(ROOT).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
                      for path in files}
(OUT / "summary.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
print("FIG3 SUMMARY PASS:15 rows,36 historical control cells,12 comparisons,5 pilots; baseline NOT_REPRODUCED")
