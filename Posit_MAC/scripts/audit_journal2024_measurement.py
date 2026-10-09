"""Summarize observed runs; graph estimates never count as original raw data."""
import csv
import hashlib
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/paper_journal2024/measurement"


def normalized(path):
    return path.read_bytes().replace(b"\r\n", b"\n")


for distribution in ("raw", "value"):
    for name in ("measurement.csv", "table_vi_trace.csv"):
        assert normalized(OUT / f"linux_{distribution}" / name) == normalized(
            OUT / f"windows_{distribution}" / name
        ), f"cross-platform mismatch: {distribution}/{name}"
    linux = (OUT / f"linux_{distribution}.log").read_text(encoding="utf-8-sig")
    windows = (OUT / f"windows_{distribution}.log").read_text(encoding="utf-8-sig")
    assert re.search(r"fingerprint=(\w+)", linux)[1] == re.search(
        r"fingerprint=(\w+)", windows
    )[1]
assert normalized(OUT / "ubsan_raw/table_vi_trace.csv") == normalized(
    OUT / "linux_raw/table_vi_trace.csv"
)

measurements = {}
for name, expected in (("linux_raw", 1000000), ("linux_value", 1000000),
                       ("windows_raw", 1000000), ("windows_value", 1000000),
                       ("ubsan_raw", 10000), ("pilot_raw", 10000000),
                       ("pilot_value", 10000000)):
    log = (OUT / f"{name}.log").read_text(encoding="utf-8-sig")
    assert "SELF_TEST PASS checks=600127 mismatches=0" in log
    assert "JOURNAL2024_ACCEPTANCE=UNCONFIRMED" in log
    with (OUT / name / "measurement.csv").open(encoding="utf-8-sig") as stream:
        rows = list(csv.DictReader(stream))
    assert [int(row["n"]) for row in rows] == [2, 3, 4, 5]
    for row in rows:
        assert int(row["samples"]) == expected
        count_keys = [f"below_{threshold}_count" for threshold in ("0.1", "0.5", "1", "5")]
        counts = [int(row[key]) for key in count_keys]
        assert counts == sorted(counts)
        for threshold in ("0.1", "0.5", "1", "5"):
            rate = float(row[f"below_{threshold}_pct"])
            bound = float(row[f"ideal_ops_{threshold}_pct"])
            assert 0 <= rate <= bound <= 100
    counters = re.search(
        r"attempted=(\d+) accepted=(\d+) excluded_zero=(\d+) excluded_nar=(\d+) "
        r"swaps=(\d+) avg_output_regime_run=([\d.]+) fingerprint=(\w+)", log
    )
    assert counters and int(counters[2]) == expected
    assert int(counters[1]) == expected + int(counters[3]) + int(counters[4])
    measurements[name] = {
        "samples": expected,
        "rows": rows,
        "attempted": int(counters[1]),
        "excluded_zero": int(counters[3]),
        "excluded_nar": int(counters[4]),
        "swaps": int(counters[5]),
        "avg_output_regime_run": float(counters[6]),
        "fingerprint": counters[7],
    }

# Coarse intervals read visually from Fig.9 at 200% in the public reader.
# No decimal source table, raw measurement data or author generator available.
intervals = [(53, 57), (70, 74), (91, 95), (99, 100)]
comparison = []
for row, (low, high) in zip(measurements["pilot_raw"]["rows"], intervals):
    rate = float(row["below_0.1_pct"])
    comparison.append({
        "n": int(row["n"]),
        "threshold_percent": 0.1,
        "source_visual_interval_percent": [low, high],
        "local_rate_percent": rate,
        "interval_distance_pp": max(low - rate, rate - high, 0),
        "ideal_ops_bound_percent": float(row["ideal_ops_0.1_pct"]),
    })

files = [
    "l1/test/test_journal2024_measurement.cpp", "l1/Makefile",
    "l1/include/paper_multiplier.hpp", "l1/include/paper_ops.hpp",
    "l1/include/paper_fig3_accumulator.hpp", "l0/softposit_api.c",
    "l0/SoftPosit_src/source/p32_mul.c", "l0/libsoftposit.so", "l0/softposit.dll",
    "scripts/audit_journal2024_measurement.py",
]
files += [str(path.relative_to(ROOT)).replace("\\", "/")
          for path in OUT.rglob("*")
          if path.is_file() and "tmp" not in path.parts and path.name != "summary.json"]
hashes = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in files}
report = {
    "date": "2026-10-09",
    "source_doi": "10.1109/TVLSI.2024.3354726",
    "source_reader": "https://www.scribd.com/document/818436812/Area-Efficient-Iterative-Logarithmic-Approximate-Multipliers-for-IEEE-754-and-Posit-Numbers",
    "source_sections": "III-A/C, V, VI-A/D; TableVI p462, Fig9 p463",
    "contract": {
        "format": "posit32 ES2", "fraction": "Q12",
        "recurrence": "RND/complement without +1",
        "ops": "PT2 absolute error; prefix7 zero5; tie-A",
        "anchor": "first signed-power term", "guard": 0,
        "term_cut": "FLOOR magnitude before coefficient", "output": "cut12/TRUNC",
        "n": "2..5 total terms, no relabeling or n+1 fitting",
        "oracle": "SoftPosit 0.4.1 l0_p32_mul ES2, not FP32",
        "generators": "mt19937_64 seed271828: raw uint32 Posit and uniform-value grid24 [0,1)",
        "specials": "NaR/zero input excluded with counters; finite saturation remains in corpus",
        "metric": "100*abs(obtained-reference)/abs(reference), strict inequalities; exact integer comparison",
    },
    "functional_status": "PASS",
    "self_test_per_run": {"checks": 600127, "mismatches": 0},
    "cross_platform": "Linux/Windows 1M CSV/trace/counters/fingerprint MATCH; UBSan PASS",
    "table_vi": {
        "force_x": True, "x": "0x1d200000", "y": "0x31040000",
        "output_n2": "0x15a28000", "printed_output_match": True,
        "acc_n2": [4616, 5770], "next_normalized_mantissa_n2": 4096,
        "table_t2": "0.001... (nonzero)", "prose_t2_zero": False,
        "output_n3": "0x15c68000", "acc_n3": [4616, 5770, 5914],
        "remainder_exhausted_n3": True,
        "finding": "Printed n2 output matches; prose that t2=0/early stop conflicts with table and recurrence",
    },
    "fig9_comparison": comparison,
    "original_baseline_accepted": False,
    "measurement_status": "NOT_REPRODUCED_WITH_DECLARED_LOCAL_CONTRACT",
    "paper_2021_incorrect_proven": False,
    "paper_2024_statistics_incorrect_proven": False,
    "full_200m_run": False,
    "full_run_reason": "Pilot n2 gap exceeds44pp even with coarse graph bounds; more samples cannot resolve missing protocol",
    "pilot_worst_case_95_percent_sampling_halfwidth_pp": 1.96 * 100 * math.sqrt(0.25 / 10000000),
    "remaining": [
        "Original PRNG/seed/value distribution and special filters",
        "Exact Fig9 numeric data and iteration semantics used in plotting",
        "Original PT2 low-bit/tie policy and accumulator flags/output cuts",
        "Original RTL/trace; ModelSim ES2 top not run in this audit",
    ],
    "measurements": measurements,
    "compiler_linux": (OUT / "compiler_linux.txt").read_text().splitlines()[0],
    "compiler_windows": (OUT / "compiler_windows.txt").read_text().splitlines()[0],
    "commands": {
        "build": "make -C l1 test_journal2024_measurement test_journal2024_measurement.exe test_journal2024_measurement_ubsan",
        "pilot_raw": "./l1/test_journal2024_measurement 10000000 271828 raw-posit results/paper_journal2024/measurement/pilot_raw",
        "pilot_value": "./l1/test_journal2024_measurement 10000000 271828 value01 results/paper_journal2024/measurement/pilot_value",
        "smoke": "same program/seed with1000000 samples forLinux/Windows and10000 forUBSan",
        "working_directory": "C:/HCMUT/HK261/Do an 2/Posit_MAC",
        "wsl_shell": "bash --noprofile --norc; TMPDIR project/results/paper_journal2024/measurement/tmp",
    },
    "sha256": hashes,
}
(OUT / "summary.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print("JOURNAL2024 audit PASS; numeric reproduction NOT_REPRODUCED; no source-error claim")
for item in comparison:
    print(item)
