"""Freeze the reviewed existing L1 and explicit prepack profile; not fused RTL."""
import hashlib
import json
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
result = root / "results/l1_floor_rne_freeze"
def read(name):
    raw = (result / name).read_bytes()
    return raw.decode("utf-16") if raw.startswith(b"\xff\xfe") else raw.decode("utf-8-sig")

pattern = r"PREPACK PASS checks=(\d+) trace_checks=(\d+) exact_checks=(\d+) Q12_pairs=(\d+) seed=20261011 mismatches=0"
linux = re.search(pattern, read("linux.log"))
windows = re.search(pattern, read("windows.log"))
ubsan = re.search(pattern, read("ubsan.log"))
assert linux and windows and ubsan and linux.groups() == windows.groups()
assert "runtime error:" not in read("ubsan.log")
assert "MAC_GATE1B SMOKE PASS" in read("mac_regression.log")
assert "FAIL" not in read("round_regression.log")
assert "PASS" in read("round_regression.log")
assert "MULTIPLIER GENERATOR PASS rows=32000" in read("generator.log")
compatibility = []
for current in sorted((result / "replay").glob("mul_*.txt")):
    original = root / "results/week9_multiplier/final_pilot" / current.name
    normalized = lambda path: path.read_bytes().replace(b"\r\n", b"\n")
    assert normalized(current) == normalized(original), current.name
    compatibility.append(dict(profile=current.stem, rows=2000,
                              normalized_sha256=hashlib.sha256(normalized(current)).hexdigest(),
                              historical_sha256=hashlib.sha256(original.read_bytes()).hexdigest()))
assert len(compatibility) == 16
sources = sorted((root / "l1/include").glob("*.hpp"))
sources += [root / path for path in ("l1/Makefile", "l1/test/test_prepack_product.cpp",
                                   "tb/week9_exact_reference.hpp", "scripts/audit_l1_floor_rne.py")]
sources += sorted((root / "l1/src").glob("*.*"))
sources += sorted((root / "l1/include").glob("*.h"))
hashes = {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
          for path in sources if path.is_file()}
assert all(arg == "--refreeze" for arg in sys.argv[1:]), "usage: audit_l1_floor_rne.py [--refreeze]"
existing = result / "summary.json"
if existing.exists() and "--refreeze" not in sys.argv[1:]:
    frozen = json.loads(existing.read_text())
    assert frozen["source_sha256"] == hashes, "Frozen sources changed; review and rerun tests before explicit --refreeze"
(result / "frozen_sources.sha256").write_text(
    "".join(f"{digest}  {name}\n" for name, digest in hashes.items()), encoding="utf-8")
report = dict(status="PASS", checkpoint="L1_FLOOR_RNE_PREPACK_V1", date="2026-10-11",
              profile=dict(NB=32, ES=3, FRAC_W=12, N_MAX=8, OPS=1,
                           ROUND_SCHEME="FLOOR", ROUND_MODE="RNE"),
              checks=int(linux[1]), trace_checks=int(linux[2]), exact_checks=int(linux[3]),
              exhaustive_Q12_pairs=int(linux[4]), mismatches=0, seed=20261011,
              platforms="Linux full = Windows full; UBSan smoke PASS",
              replay=compatibility, source_sha256=hashes,
              compiler=read("compiler.log").splitlines()[0],
              windows_compiler=read("windows_compiler.log").splitlines()[0],
              softposit_sha256=hashlib.sha256((root / "l0/libsoftposit.so").read_bytes()).hexdigest(),
              binary_sha256={name: hashlib.sha256((root / "l1" / name).read_bytes()).hexdigest()
                             for name in ("test_prepack_product", "test_prepack_product.exe", "test_prepack_product_ubsan")},
              regression_logs={name: hashlib.sha256((result / name).read_bytes()).hexdigest()
                               for name in ("linux.log", "windows.log", "ubsan.log",
                                            "mac_regression.log", "round_regression.log", "generator.log")},
              commands=["make -C l1 test_prepack_product test_prepack_product.exe test_prepack_product_ubsan",
                        "./l1/test_prepack_product", "l1/test_prepack_product.exe",
                        "./l1/test_prepack_product_ubsan --smoke",
                        "./l1/test_mac_gate1b --samples 100000 --seed 314159",
                        "./l1/test_round_unpacked",
                        "./l1/gen_week9_multiplier results/l1_floor_rne_freeze/replay 2000",
                        "python3 scripts/audit_l1_floor_rne.py"],
              scope="Existing L1 plus prepack metadata; arithmetic/defaults unchanged, 32000 historical rows identical modulo LF/CRLF",
              remaining=["Fused L1 signed alignment/residual contract and full oracle suite",
                         "Fused/NF MAC RTL and final AC matrix/coverage/PPA",
                         "No fresh RTL Gate2 run; original Gate2 evidence remains historical source checkpoint"])
(result / "summary.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
print("FREEZE PASS", report["checkpoint"], report["checks"], "mismatches=0; 32000 payload rows unchanged")
