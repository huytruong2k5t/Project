#!/usr/bin/env python3
"""
Test script for SoftPosit Golden Model (L0) - Week 2 Milestone
Verifies p8/p16/p32 arithmetic, TV-RND test vectors, and the full Corner List (§6.4)
Outputs results to console and logs to results/corner.log
"""

import os
import sys

# Ensure workspace root is in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

from l0.softposit import (
    Posit8, Posit16, Posit32,
    p8_add, p8_sub, p8_mul, p8_mulAdd, p8_to_double, double_to_p8,
    p16_add, p16_sub, p16_mul, p16_mulAdd, p16_to_double, double_to_p16,
    p32_add, p32_sub, p32_mul, p32_mulAdd, p32_to_double, double_to_p32
)

class TestRunner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.logs = []

    def log(self, msg: str):
        print(msg)
        self.logs.append(msg)

    def check(self, name: str, actual: int, expected: int, fmt: str = "0x{:08X}", note: str = ""):
        act_str = fmt.format(actual)
        exp_str = fmt.format(expected)
        if actual == expected:
            self.passed += 1
            status = "[PASS]"
            self.log(f"{status} {name:<42} : {act_str} == {exp_str} {note}")
            return True
        else:
            self.failed += 1
            status = "[FAIL]"
            self.log(f"{status} {name:<42} : {act_str} != {exp_str} (EXPECTED) {note}")
            return False

def run_all_tests():
    t = TestRunner()
    t.log("================================================================================")
    t.log("   SOFTPOSIT GOLDEN REFERENCE (L0) - WEEK 2 CORNER & TV-RND VERIFICATION")
    t.log("   Standard Configs: Posit8(ES=0), Posit16(ES=1), Posit32(ES=2)")
    t.log("================================================================================")

    # -------------------------------------------------------------------------
    # SUITE 1: Posit32 Corner Cases (§6.4)
    # -------------------------------------------------------------------------
    t.log("\n[Suite 1] Posit32 Corner List (§6.4)")
    t.log("--------------------------------------------------------------------------------")
    P32_ZERO   = 0x00000000
    P32_NAR    = 0x80000000
    P32_ONE    = 0x40000000  # +1.0
    P32_NEG1   = 0xC0000000  # -1.0
    P32_MINPOS = 0x00000001  # minpos
    P32_NEGMIN = 0xFFFFFFFF  # -minpos
    P32_MAXPOS = 0x7FFFFFFF  # maxpos
    P32_NEGMAX = 0x80000001  # -maxpos
    P32_TWO    = 0x48000000  # +2.0

    # Individual representation checks
    t.check("P32: zero value check", P32_ZERO, 0x00000000)
    t.check("P32: NaR value check", P32_NAR, 0x80000000)
    t.check("P32: +1.0 value check", double_to_p32(1.0), P32_ONE)
    t.check("P32: -1.0 value check", double_to_p32(-1.0), P32_NEG1)

    # Corner combinations (§6.4)
    t.check("P32: NaR * 0 -> NaR", p32_mul(P32_NAR, P32_ZERO), P32_NAR, note="(NaR dominant)")
    t.check("P32: 0 * NaR -> NaR", p32_mul(P32_ZERO, P32_NAR), P32_NAR, note="(NaR dominant)")
    t.check("P32: maxpos * maxpos -> maxpos", p32_mul(P32_MAXPOS, P32_MAXPOS), P32_MAXPOS, note="(Saturation overflow)")
    t.check("P32: minpos * minpos -> minpos", p32_mul(P32_MINPOS, P32_MINPOS), P32_MINPOS, note="(Saturation underflow)")
    t.check("P32: (-maxpos) * (-maxpos) -> maxpos", p32_mul(P32_NEGMAX, P32_NEGMAX), P32_MAXPOS, note="(Positive overflow)")
    t.check("P32: maxpos * minpos -> 1.0", p32_mul(P32_MAXPOS, P32_MINPOS), P32_ONE, note="(Exact 1.0 for ES=2)")
    t.check("P32: maxpos + maxpos -> maxpos", p32_add(P32_MAXPOS, P32_MAXPOS), P32_MAXPOS, note="(Add overflow)")
    t.check("P32: (+1) + (-1) -> 0.0", p32_add(P32_ONE, P32_NEG1), P32_ZERO, note="(Exact cancellation)")
    t.check("P32: maxpos + (-maxpos) -> 0.0", p32_add(P32_MAXPOS, P32_NEGMAX), P32_ZERO, note="(Exact cancellation)")
    t.check("P32: 1 + minpos -> 1.0", p32_add(P32_ONE, P32_MINPOS), P32_ONE, note="(Precision loss underflow)")

    # Posit32 MAC combinations
    t.check("P32: mulAdd(NaR, 1, 0) -> NaR", p32_mulAdd(P32_NAR, P32_ONE, P32_ZERO), P32_NAR, note="(MAC NaR operand A)")
    t.check("P32: mulAdd(1, NaR, 0) -> NaR", p32_mulAdd(P32_ONE, P32_NAR, P32_ZERO), P32_NAR, note="(MAC NaR operand B)")
    t.check("P32: mulAdd(1, 1, NaR) -> NaR", p32_mulAdd(P32_ONE, P32_ONE, P32_NAR), P32_NAR, note="(MAC NaR operand C)")
    t.check("P32: mulAdd(1, 1, 1) -> 2.0", p32_mulAdd(P32_ONE, P32_ONE, P32_ONE), P32_TWO, note="(1*1 + 1 = 2)")
    t.check("P32: mulAdd(1, -1, 1) -> 0.0", p32_mulAdd(P32_ONE, P32_NEG1, P32_ONE), P32_ZERO, note="(1*(-1) + 1 = 0)")

    # -------------------------------------------------------------------------
    # SUITE 2: TV-RND Posit8 Test Vectors (§3.4)
    # -------------------------------------------------------------------------
    t.log("\n[Suite 2] TV-RND Posit8 Test Vectors (§3.4)")
    t.log("--------------------------------------------------------------------------------")
    # TV-RND-00: 0.1 = 1.6 * 2^-4 -> 0x06
    tv00 = double_to_p8(0.1)
    t.check("TV-RND-00: double(0.1)", tv00, 0x06, fmt="0x{:02X}", note=f"(= {p8_to_double(tv00)})")

    # TV-RND-01: 1 + 2^-6 = 1.015625 -> 0x40 (1.0, tie even)
    tv01 = double_to_p8(1.0 + 1.0/64.0)
    t.check("TV-RND-01: double(1 + 2^-6)", tv01, 0x40, fmt="0x{:02X}", note="(1.0, RNE tie round-to-even)")

    # TV-RND-02: 1 + 3*2^-6 = 1.046875 -> 0x42 (1.0625, tie odd round up)
    tv02 = double_to_p8(1.0 + 3.0/64.0)
    t.check("TV-RND-02: double(1 + 3*2^-6)", tv02, 0x42, fmt="0x{:02X}", note="(1.0625, RNE tie round-up)")

    # TV-RND-03: 100 -> 0x7F (maxpos saturation = 64)
    tv03 = double_to_p8(100.0)
    t.check("TV-RND-03: double(100.0)", tv03, 0x7F, fmt="0x{:02X}", note="(maxpos = 64 saturation)")

    # TV-RND-04: 0.001 -> 0x01 (minpos saturation = 2^-6)
    tv04 = double_to_p8(0.001)
    t.check("TV-RND-04: double(0.001)", tv04, 0x01, fmt="0x{:02X}", note="(minpos = 2^-6 saturation)")

    # Posit8 arithmetic & corners
    P8_ONE = 0x40
    P8_MAX = 0x7F
    P8_MIN = 0x01
    P8_NAR = 0x80
    P8_ZERO = 0x00
    P8_TWO  = 0x60  # ES=0: k=1 -> regime 110 -> 0x60 = 2.0
    t.check("P8: NaR * 0 -> NaR", p8_mul(P8_NAR, P8_ZERO), P8_NAR, fmt="0x{:02X}")
    t.check("P8: maxpos * minpos -> 1.0", p8_mul(P8_MAX, P8_MIN), P8_ONE, fmt="0x{:02X}", note="(2^6 * 2^-6 = 1)")
    t.check("P8: mulAdd(1, 1, 1) -> 2.0", p8_mulAdd(P8_ONE, P8_ONE, P8_ONE), P8_TWO, fmt="0x{:02X}", note="(2.0 in P8)")

    # -------------------------------------------------------------------------
    # SUITE 3: Posit16 Corner Cases and Arithmetic
    # -------------------------------------------------------------------------
    t.log("\n[Suite 3] Posit16 Corner Cases (ES=1)")
    t.log("--------------------------------------------------------------------------------")
    P16_ZERO   = 0x0000
    P16_NAR    = 0x8000
    P16_ONE    = 0x4000
    P16_NEG1   = 0xC000
    P16_MINPOS = 0x0001
    P16_MAXPOS = 0x7FFF
    P16_TWO    = 0x5000  # ES=1: k=0, exp=1 -> 0x5000 = 2.0

    t.check("P16: NaR * 0 -> NaR", p16_mul(P16_NAR, P16_ZERO), P16_NAR, fmt="0x{:04X}")
    t.check("P16: 0 * NaR -> NaR", p16_mul(P16_ZERO, P16_NAR), P16_NAR, fmt="0x{:04X}")
    t.check("P16: maxpos * minpos -> 1.0", p16_mul(P16_MAXPOS, P16_MINPOS), P16_ONE, fmt="0x{:04X}", note="(2^28 * 2^-28 = 1)")
    t.check("P16: maxpos * maxpos -> maxpos", p16_mul(P16_MAXPOS, P16_MAXPOS), P16_MAXPOS, fmt="0x{:04X}", note="(Overflow)")
    t.check("P16: minpos * minpos -> minpos", p16_mul(P16_MINPOS, P16_MINPOS), P16_MINPOS, fmt="0x{:04X}", note="(Underflow)")
    t.check("P16: (+1) + (-1) -> 0.0", p16_add(P16_ONE, P16_NEG1), P16_ZERO, fmt="0x{:04X}")
    t.check("P16: mulAdd(1, 1, 1) -> 2.0", p16_mulAdd(P16_ONE, P16_ONE, P16_ONE), P16_TWO, fmt="0x{:04X}")

    # -------------------------------------------------------------------------
    # SUITE 4: Maximum Regime Verification (m = NB - 1)
    # -------------------------------------------------------------------------
    t.log("\n[Suite 4] Maximum Regime Verification (m = NB - 1)")
    t.log("--------------------------------------------------------------------------------")
    t.check("P8  Max Regime (m=7):  0x7F * 0x01", p8_mul(0x7F, 0x01), 0x40, fmt="0x{:02X}", note="(1.0)")
    t.check("P16 Max Regime (m=15): 0x7FFF * 0x0001", p16_mul(0x7FFF, 0x0001), 0x4000, fmt="0x{:04X}", note="(1.0)")
    t.check("P32 Max Regime (m=31): 0x7FFFFFFF * 0x00000001", p32_mul(0x7FFFFFFF, 0x00000001), 0x40000000, fmt="0x{:08X}", note="(1.0)")

    # -------------------------------------------------------------------------
    # SUITE 5: Python Object-Oriented Class Tests
    # -------------------------------------------------------------------------
    t.log("\n[Suite 5] Object-Oriented Interface (Posit8, Posit16, Posit32)")
    t.log("--------------------------------------------------------------------------------")
    a8 = Posit8(0x40)
    b8 = Posit8(0x40)
    c8 = a8 * b8
    t.check("OO: Posit8 1.0 * 1.0", c8.v, 0x40, fmt="0x{:02X}")

    a16 = Posit16(0x4000)
    b16 = Posit16(0x4000)
    c16 = a16 + b16
    t.check("OO: Posit16 1.0 + 1.0", c16.v, 0x5000, fmt="0x{:04X}")

    a32 = Posit32(0x40000000)
    b32 = Posit32(0x40000000)
    c32 = a32.mul_add(b32, a32)
    t.check("OO: Posit32 1.0 * 1.0 + 1.0", c32.v, 0x48000000, fmt="0x{:08X}")

    t.log("\n================================================================================")
    total = t.passed + t.failed
    t.log(f"   SUMMARY: {t.passed} PASSED, {t.failed} FAILED out of {total} total test cases.")
    t.log("================================================================================")

    # Save log to results/corner.log
    results_dir = os.path.join(PROJECT_ROOT, "results")
    os.makedirs(results_dir, exist_ok=True)
    log_path = os.path.join(results_dir, "corner.log")
    with open(log_path, "w", encoding="utf-8") as f:
        f.write("\n".join(t.logs) + "\n")
    print(f"\n[INFO] Detailed log written to: results/corner.log")

    return t.failed == 0

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
