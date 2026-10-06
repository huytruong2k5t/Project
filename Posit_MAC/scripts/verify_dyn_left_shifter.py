#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# File          : verify_dyn_left_shifter.py
# Description   : Bit-accurate simulation and verification runner for dyn_left_shifter
#-----------------------------------------------------------------------------
import math
import random
import sys

def dyn_left_shifter(val: int, b: int, N: int, SHIFT_W: int) -> int:
    """Exact emulation of dyn_left_shifter.sv hardware logic."""
    if N <= 1:
        return 0 if (b != 0) else (val & 1)
    
    S = math.ceil(math.log2(N))
    
    # 1. Multi-stage MUX cascade
    cur = val & ((1 << N) - 1)
    for i in range(S):
        sel = (b >> i) & 1 if i < SHIFT_W else 0
        shift_val = 1 << i
        if sel and shift_val < N:
            # {stage[i][N - 1 - SHIFT_VAL : 0], {SHIFT_VAL{1'b0}}}
            shifted = (cur << shift_val) & ((1 << N) - 1)
            cur = shifted
        else:
            cur = cur

    # 2. Static overflow check (b >= N)
    is_overflow = False
    if SHIFT_W > S and ((1 << S) != N):
        upper_mask = ((1 << (SHIFT_W - S)) - 1) << S
        is_overflow = bool(b & upper_mask) or ((b & ((1 << S) - 1)) >= N)
    elif SHIFT_W > S:
        upper_mask = ((1 << (SHIFT_W - S)) - 1) << S
        is_overflow = bool(b & upper_mask)
    elif (1 << S) != N:
        is_overflow = (b & ((1 << S) - 1)) >= N

    return 0 if is_overflow else cur

def expected_shift(val: int, b: int, N: int) -> int:
    """Golden mathematical reference model."""
    if b >= N:
        return 0
    return (val << b) & ((1 << N) - 1)

def run_tests():
    total_tests = 0
    errors = 0

    print("==================================================================")
    print("   RUNNING VERIFICATION FOR dyn_left_shifter")
    print("==================================================================")

    # Suite 1: Exhaustive N=8, SHIFT_W=4
    print("[Suite 1] Exhaustive testing on N=8, SHIFT_W=4 (256 data x 16 shifts)...")
    for data in range(256):
        for sh in range(16):
            exp = expected_shift(data, sh, 8)
            got = dyn_left_shifter(data, sh, 8, 4)
            if got != exp:
                print(f"FAILED Suite 1: data={data:02x}, sh={sh} | got={got:02x}, exp={exp:02x}")
                errors += 1
            total_tests += 1

    # Suite 2: Corner cases N=32, SHIFT_W=6 (shifts 0..63)
    print("[Suite 2] Boundary and corner cases on N=32, SHIFT_W=6 (shifts 0..63)...")
    corners = [
        0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555,
        0x80000000, 0x7FFFFFFF, 0x00000001, 0x12345678,
        0xDEADBEEF, 0xCAFEBABE
    ]
    for data in corners:
        for sh in range(64):
            exp = expected_shift(data, sh, 32)
            got = dyn_left_shifter(data, sh, 32, 6)
            if got != exp:
                print(f"FAILED Suite 2: data={data:08x}, sh={sh} | got={got:08x}, exp={exp:08x}")
                errors += 1
            total_tests += 1

    # Walking 1s & 0s
    for bit in range(32):
        w1 = 1 << bit
        w0 = (~w1) & 0xFFFFFFFF
        for sh in range(64):
            exp1 = expected_shift(w1, sh, 32)
            got1 = dyn_left_shifter(w1, sh, 32, 6)
            if got1 != exp1:
                errors += 1
            total_tests += 1

            exp0 = expected_shift(w0, sh, 32)
            got0 = dyn_left_shifter(w0, sh, 32, 6)
            if got0 != exp0:
                errors += 1
            total_tests += 1

    # Suite 3: Non-power-of-2 N=27 (Posit32 mantissa), SHIFT_W=5
    print("[Suite 3] Non-power-of-2 verification on N=27 (Posit32 mantissa)...")
    for rep in range(1000):
        data = random.randint(0, (1 << 27) - 1)
        for sh in range(32):
            exp = expected_shift(data, sh, 27)
            got = dyn_left_shifter(data, sh, 27, 5)
            if got != exp:
                print(f"FAILED Suite 3: data={data:07x}, sh={sh} | got={got:07x}, exp={exp:07x}")
                errors += 1
            total_tests += 1

    # Suite 4: Randomized stress tests on N=32, SHIFT_W=6
    print("[Suite 4] Randomized stress testing (20,000 vectors on N=32)...")
    for _ in range(20000):
        data = random.getrandbits(32)
        sh = random.randint(0, 63)
        exp = expected_shift(data, sh, 32)
        got = dyn_left_shifter(data, sh, 32, 6)
        if got != exp:
            print(f"FAILED Suite 4: data={data:08x}, sh={sh} | got={got:08x}, exp={exp:08x}")
            errors += 1
        total_tests += 1

    print("==================================================================")
    if errors == 0:
        print(f"   SUCCESS: ALL {total_tests:,} VECTORS PASSED 100% (0 MISMATCHES)!")
    else:
        print(f"   FAILURE: {errors} ERRORS ENCOUNTERED OUT OF {total_tests:,} TESTS!")
    print("==================================================================")
    return errors == 0

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
