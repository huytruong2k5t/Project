#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# File          : verify_dyn_right_shifter.py
# Description   : Bit-accurate simulation and verification runner for dyn_right_shifter
#-----------------------------------------------------------------------------
import math
import random
import sys

def dyn_right_shifter(val: int, b: int, N: int, SHIFT_W: int, fill: int) -> int:
    """Exact emulation of dyn_right_shifter.sv hardware logic."""
    fill_bit = fill & 1
    if N <= 1:
        return fill_bit if (b != 0) else (val & 1)
    
    S = math.ceil(math.log2(N))
    
    # 1. Multi-stage MUX cascade
    cur = val & ((1 << N) - 1)
    for i in range(S):
        sel = (b >> i) & 1 if i < SHIFT_W else 0
        shift_val = 1 << i
        if sel and shift_val < N:
            # {{SHIFT_VAL{fill}}, stage[i][N - 1 : SHIFT_VAL]}
            shifted_data = cur >> shift_val
            fill_mask = (((1 << shift_val) - 1) << (N - shift_val)) if fill_bit else 0
            cur = (shifted_data | fill_mask) & ((1 << N) - 1)
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

    if is_overflow:
        return ((1 << N) - 1) if fill_bit else 0
    return cur

def expected_right_shift(val: int, b: int, N: int, fill: int) -> int:
    """Golden mathematical reference model for right shift."""
    fill_bit = fill & 1
    if b >= N:
        return ((1 << N) - 1) if fill_bit else 0
    shifted = (val & ((1 << N) - 1)) >> b
    fill_mask = (((1 << b) - 1) << (N - b)) if fill_bit else 0
    return (shifted | fill_mask) & ((1 << N) - 1)

def run_tests():
    total_tests = 0
    errors = 0

    print("==================================================================")
    print("   RUNNING VERIFICATION FOR dyn_right_shifter")
    print("==================================================================")

    # Suite 1: Exhaustive N=8, SHIFT_W=4 (Logical & Arithmetic & Custom)
    print("[Suite 1] Exhaustive testing on N=8, SHIFT_W=4 (Logical, Arith, Custom)...")
    for data in range(256):
        sign = (data >> 7) & 1
        for sh in range(16):
            # Logical (fill=0)
            exp_l = expected_right_shift(data, sh, 8, 0)
            got_l = dyn_right_shifter(data, sh, 8, 4, 0)
            if got_l != exp_l:
                print(f"FAILED Suite 1 Logical: data={data:02x}, sh={sh}")
                errors += 1
            total_tests += 1

            # Arithmetic (fill=sign)
            exp_a = expected_right_shift(data, sh, 8, sign)
            got_a = dyn_right_shifter(data, sh, 8, 4, sign)
            if got_a != exp_a:
                print(f"FAILED Suite 1 Arith: data={data:02x}, sh={sh}")
                errors += 1
            total_tests += 1

            # Custom fill=1
            exp_c = expected_right_shift(data, sh, 8, 1)
            got_c = dyn_right_shifter(data, sh, 8, 4, 1)
            if got_c != exp_c:
                print(f"FAILED Suite 1 Custom: data={data:02x}, sh={sh}")
                errors += 1
            total_tests += 1

    # Suite 2: Corner cases N=32, SHIFT_W=6 (shifts 0..63)
    print("[Suite 2] Boundary & corner cases on N=32, SHIFT_W=6 (shifts 0..63)...")
    corners = [
        0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555,
        0x80000000, 0x7FFFFFFF, 0x80000001, 0x00000001,
        0xF0F0F0F0, 0xDEADBEEF
    ]
    for data in corners:
        sign = (data >> 31) & 1
        for sh in range(64):
            # Logical
            exp_l = expected_right_shift(data, sh, 32, 0)
            got_l = dyn_right_shifter(data, sh, 32, 6, 0)
            if got_l != exp_l:
                print(f"FAILED Suite 2 Logical: data={data:08x}, sh={sh}")
                errors += 1
            total_tests += 1

            # Arith
            exp_a = expected_right_shift(data, sh, 32, sign)
            got_a = dyn_right_shifter(data, sh, 32, 6, sign)
            if got_a != exp_a:
                print(f"FAILED Suite 2 Arith: data={data:08x}, sh={sh}")
                errors += 1
            total_tests += 1

            # Custom fill=1
            exp_c = expected_right_shift(data, sh, 32, 1)
            got_c = dyn_right_shifter(data, sh, 32, 6, 1)
            if got_c != exp_c:
                print(f"FAILED Suite 2 Custom: data={data:08x}, sh={sh}")
                errors += 1
            total_tests += 1

    # Walking 1s & 0s
    for bit in range(32):
        w1 = 1 << bit
        w0 = (~w1) & 0xFFFFFFFF
        for sh in range(64):
            for fill in (0, 1):
                exp1 = expected_right_shift(w1, sh, 32, fill)
                got1 = dyn_right_shifter(w1, sh, 32, 6, fill)
                if got1 != exp1:
                    errors += 1
                total_tests += 1

                exp0 = expected_right_shift(w0, sh, 32, fill)
                got0 = dyn_right_shifter(w0, sh, 32, 6, fill)
                if got0 != exp0:
                    errors += 1
                total_tests += 1

    # Suite 3: Non-power-of-2 N=27 (Posit32 mantissa), SHIFT_W=5
    print("[Suite 3] Non-power-of-2 verification on N=27 (Posit32 mantissa)...")
    for _ in range(1000):
        data = random.randint(0, (1 << 27) - 1)
        for sh in range(32):
            for fill in (0, 1):
                exp = expected_right_shift(data, sh, 27, fill)
                got = dyn_right_shifter(data, sh, 27, 5, fill)
                if got != exp:
                    print(f"FAILED Suite 3: data={data:07x}, sh={sh}, fill={fill}")
                    errors += 1
                total_tests += 1

    # Suite 4: Randomized stress tests on N=32, SHIFT_W=6 (20,000 vectors)
    print("[Suite 4] Randomized stress testing (20,000 vectors on N=32)...")
    for _ in range(20000):
        data = random.getrandbits(32)
        sh = random.randint(0, 63)
        sign = (data >> 31) & 1
        custom_fill = random.randint(0, 1)

        # Logical
        exp_l = expected_right_shift(data, sh, 32, 0)
        got_l = dyn_right_shifter(data, sh, 32, 6, 0)
        if got_l != exp_l:
            errors += 1
        total_tests += 1

        # Arith
        exp_a = expected_right_shift(data, sh, 32, sign)
        got_a = dyn_right_shifter(data, sh, 32, 6, sign)
        if got_a != exp_a:
            errors += 1
        total_tests += 1

        # Custom fill
        exp_c = expected_right_shift(data, sh, 32, custom_fill)
        got_c = dyn_right_shifter(data, sh, 32, 6, custom_fill)
        if got_c != exp_c:
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
