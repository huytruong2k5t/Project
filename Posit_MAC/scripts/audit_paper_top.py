"""Audit observed RTL counts, platform replay and the previously checked trace."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
result = root / "results/paper_top"
observed = json.loads((result / "windows/summary.json").read_text(encoding="utf-8-sig"))
if observed["status"] != "PASS" or observed["mismatches"] != 0:
    raise RuntimeError("no successful observed RTL evidence")

hashes = {}
for name, key in (("transactions.txt", "transactionsSHA256"), ("traces.txt", "tracesSHA256")):
    raw = (result / "windows" / name).read_bytes()
    if hashlib.sha256(raw).hexdigest().upper() != observed[key]:
        raise RuntimeError("observed fixture hash mismatch")
    normalized = raw.replace(b"\r\n", b"\n")
    for platform in ("linux", "ubsan"):
        replay = (result / platform / name).read_bytes().replace(b"\r\n", b"\n")
        if replay != normalized:
            raise RuntimeError(f"replay differs: {platform}/{name}")
    hashes[name] = hashlib.sha256(normalized).hexdigest()

transactions = [line.split() for line in (result / "windows/transactions.txt").read_text().splitlines()]
traces = [line.split() for line in (result / "windows/traces.txt").read_text().splitlines()]
old = [line.split() for line in (root / "results/week9_paper/windows/paper.txt").read_text().splitlines()]
prefix_count = sum(int(row[4]) for row in transactions[:293])
if prefix_count != len(old) or prefix_count != 843:
    raise RuntimeError("frozen trace length mismatch")
mapping = [(1, 9, 16), (2, 10, 10), (3, 11, 10), (4, 12, 16),
           (5, 13, 16), (6, 14, 16), (8, 19, 16), (9, 15, 16),
           (10, 16, 10), (11, 17, 16), (12, 18, 16)]
for new_row, old_row in zip(traces[:prefix_count], old):
    if any(int(new_row[a], base) != int(old_row[b], base) for a, b, base in mapping):
        raise RuntimeError("state trace differs from previously checked corpus")
    expected_term = abs(int(old_row[18], 16) - int(old_row[14], 16))
    if int(new_row[7], 16) != expected_term:
        raise RuntimeError("term differs from frozen accumulator delta")
for row, previous in zip(transactions[:293], [r for r in old if int(r[21], 16)]):
    if int(row[0], 16) != int(previous[0], 16) or int(row[1], 16) != int(previous[1], 16) or int(row[5], 16) != int(previous[20], 16):
        raise RuntimeError("output differs from previously checked corpus")
if len(transactions) != observed["transactions"] or len(traces) != observed["commits"]:
    raise RuntimeError("observed count mismatch")
if {int(row[2]) for row in transactions} != set(range(1, 9)):
    raise RuntimeError("missing n_terms values")

# Recover the published force-X accumulator sequence from generated observations.
offset = 0
fig4 = []
for row in transactions:
    count = int(row[4])
    if [int(row[0], 16), int(row[1], 16), int(row[2]), int(row[3])] == [0x1c900000, 0x3c820000, 3, 1]:
        sequence = [int(r[12], 16) for r in traces[offset:offset+count]]
        if sequence != [4616, 5770, 5914] or int(row[5], 16) != 0x1ae34000:
            raise RuntimeError("published force-X sequence mismatch")
        fig4.append(sequence)
    offset += count
sources = ("rtl/posit_mac.vh", "l1/test/gen_paper_top.cpp",
           "l1/test/paper_discriminator_study.hpp", "l1/include/paper_multiplier.hpp",
           "l1/include/paper_fig3_accumulator.hpp", "scripts/verify_paper_top_modelsim.ps1",
           "scripts/audit_paper_top.py", "results/paper_discriminators/linux/vectors.csv")
report = {
    "status": "PASS", "observed_transactions": observed["transactions"],
    "observed_commits": observed["commits"], "mismatches": 0,
    "previous_frozen_trace_commits_identical": prefix_count,
    "previous_checked_trace_sha256": hashlib.sha256((root / "results/week9_paper/windows/paper.txt").read_bytes()).hexdigest(),
    "Linux_Windows_UBSan_fixture_replay": "MATCH after newline normalization",
    "fixture_normalized_sha256": hashes, "Fig4_accumulator_Q12": fig4,
    "n_terms_covered": list(range(1, 9)),
    "oracle": "frozen Fig3 L1 reconstruction, checked against independent Q96 signed residual; not author RTL",
    "coverage": "directed functional scenarios only; no line/branch/toggle or Gate2 acceptance",
    "TableI": "not rerun: autonomous feedback introduces no source-confirmed numerical change",
    "compilers": {platform: (result / f"compiler_{platform}.log").read_text().splitlines()[0]
                  for platform in ("linux", "windows")},
    "build_command": "make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan (TMPDIR=results/paper_top/tmp; WSL bash --noprofile --norc)",
    "generator_commands": ["./l1/gen_paper_top results/paper_discriminators/linux/vectors.csv results/paper_top/linux",
                           "./l1/gen_paper_top_ubsan results/paper_discriminators/linux/vectors.csv results/paper_top/ubsan",
                           "scripts/verify_paper_top_modelsim.ps1", "scripts/audit_paper_top.py"],
    "generator_binary_sha256": {name: hashlib.sha256((root / "l1" / name).read_bytes()).hexdigest()
                               for name in ("gen_paper_top", "gen_paper_top.exe", "gen_paper_top_ubsan")},
    "additional_source_sha256": {s: hashlib.sha256((root / s).read_bytes()).hexdigest() for s in sources},
}
(result / "audit.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
print(f"PAPER TOP AUDIT PASS transactions={len(transactions)} commits={len(traces)} frozen_identical={prefix_count} mismatch=0")
