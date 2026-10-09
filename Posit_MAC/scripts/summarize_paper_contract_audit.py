"""Record source facts separately from reconstruction and observed tests."""
import csv
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
out = root / "results/paper_contract_audit"
rtl = json.loads((out / "windows/summary.json").read_text(encoding="utf-8-sig"))
if rtl["status"] != "PASS":
    raise RuntimeError("RTL PASS required")
replay = {}
for name in ("packer.txt", "divergent.csv", "sac_counts.csv", "source2019_trace.csv", "source2021_count.csv"):
    expected = (out / "windows" / name).read_bytes().replace(b"\r\n", b"\n")
    for platform in ("linux", "ubsan"):
        if (out / platform / name).read_bytes().replace(b"\r\n", b"\n") != expected:
            raise RuntimeError(f"replay mismatch {platform}/{name}")
    replay[name] = hashlib.sha256(expected).hexdigest()
if hashlib.sha256((out / "windows/packer.txt").read_bytes()).hexdigest().upper() != rtl["fixtureSHA256"]:
    raise RuntimeError("observed RTL fixture changed")
with (out / "windows/sac_counts.csv").open() as handle:
    counts = [{key:int(value) for key,value in row.items()} for row in csv.DictReader(handle)]
pdfs = ("An Approximate and Iterative Posit Multiplier Architecture for FPGAs.pdf",
        "An Area-Efficient Iterative Single-Precision Floating-Point Multiplier Architecture for FPGA.pdf")
sources = (*pdfs, "l1/test/test_paper_contract_audit.cpp", "tb/tb_paper_fig5_pack.sv",
           "scripts/verify_paper_contract_modelsim.ps1", "scripts/summarize_paper_contract_audit.py")
report = {
    "date": "2026-10-09", "status": "AUDIT COMPLETE; original baseline not identified",
    "source_facts": [
        {"source":"GLSVLSI2019 PDF p2 Algorithm1, p3 Eq10-12/Table1",
         "fact":"n counts signed power terms; hardware rounds at significand1.5 and approximates upper residual by complement",
         "test":"published Table1 mantissa/exponent reproduces powers[-1,-5,-8], coefficients[+1,-1,-1] and next exponents[-5,-9,-11]"},
        {"source":"ISCAS2021 PDF p3 Fig3/4 and III-C",
         "fact":"description scans next fraction one; example starts with Y, labels fraction updates n=1,2; output0x1ae34000",
         "test":"2 fraction updates/3 total terms match; 2 total terms output0x1ad14000"},
        {"source":"GLSVLSI2019 p5 Table3 and ISCAS2021 p4 TableI",
         "fact":"all12 Kim2019 correct-rate cells are repeated exactly in Kim column2021",
         "inference":"supports shared row labels for Kim comparator; does not uniquely establish Proposed SAC or its count convention"},
        {"source":"ISCAS2021 p3 Fig5(b)",
         "fact":"offset=Rgm[4:0] XOR replicatedRgm[5]; leading bits from XNOR/XOR with sign, lower29bits XOR sign; arithmetic shift then add sign",
         "test":"independent gate reference equals L1 normal encoding across sign/fraction12 and sf[-240,240]; RTL directed/exhaustive subset passes"}],
    "SAC": {"pairs":163840, "selection":"force A to isolate recurrence and count",
            "counts":counts,
            "example":{"x_Q12":6144,"y_Q12":4097,"n_total":2,
                       "rnd":"0x42008000","scan":"0x42004000"},
            "conclusion":"not bit-equivalent; the all-positive Fig4 fixture cannot resolve the round-up/negative-term branch"},
    "packer":rtl,
    "range_limit":"raw Fig5 omits range/special flags.8448 directed raw/clamped differences are outside sf[-240,240], including underflow and wrapped six-bit Rgm controls; not RTL mismatch",
    "cross_platform":"Linux/Windows/UBSan MATCH after newline normalization",
    "normalized_fixture_sha256":replay,
    "source_sha256":{s:hashlib.sha256((root/s).read_bytes()).hexdigest() for s in sources},
    "compilers":{name:(root/f'results/paper_top/compiler_{name}.log').read_text().splitlines()[0]
                 for name in ("linux","windows")},
    "commands":["make -C l1 test_paper_contract_audit test_paper_contract_audit.exe test_paper_contract_audit_ubsan",
                "./l1/test_paper_contract_audit results/paper_contract_audit/linux",
                "./l1/test_paper_contract_audit_ubsan results/paper_contract_audit/ubsan",
                "scripts/verify_paper_contract_modelsim.ps1","scripts/summarize_paper_contract_audit.py"],
    "seed":"deterministic exhaustive/directed; no seed fitting",
    "TableI":"NOT RERUN: source disagreement found, no uniquely source-confirmed numerical replacement selected",
    "production_changes":"none; normative and frozen RND paper top unchanged",
    "remaining":["source trace/code or clarification for Proposed2021 SAC/count",
                 "original OPS tie/prefix padding/score","internal cut/normalize flags","measurement generator/filter"],
}
(out / "summary.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
print("PAPER CONTRACT AUDIT: source count/recurrence unresolved; independent Fig5 encoding PASS; no TableI change")
