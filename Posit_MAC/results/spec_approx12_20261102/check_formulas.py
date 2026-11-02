from fractions import Fraction
import json
checks = 0
ys = [4096,4097,5461,6144,8190,8191]
for fx in range(4096):
    positions = [12-bit for bit in range(11,-1,-1) if fx & (1<<bit)]
    for y in ys:
        base = y << 12
        for n in range(13):
            selected = positions[:n]
            m = base
            mask = 0
            for shift in selected:
                assert base & ((1<<shift)-1) == 0
                m += base >> shift
                mask |= 1 << (12-shift)
            assert m == (4096+mask)*y
            assert 0 < m < 1<<26
            carry = m >> 25
            frac26 = ((m & ((1<<25)-1))<<1) if carry else ((m & ((1<<24)-1))<<2)
            normalized = Fraction((1<<26)+frac26,1<<26) * (1<<carry)
            assert normalized == Fraction(m,1<<24)
            checks += 1

# Exhaust run/exponent layouts, not all raw32 words: prove dyadic grid bound.
layout_checks = 0
smallest_lsb = 0
for first in range(2):
    for run in range(1,32):
        if first == 0 and run == 31:
            continue  # zero has no hidden/significand
        payload = 0 if run == 31 else 30-run
        eb = min(3,payload)
        fb = payload-eb
        k = run-1 if first else -run
        for e_raw in range(1<<eb):
            sf = 8*k + (e_raw << (3-eb))
            lsb = sf-min(fb,12)
            assert -240 <= sf <= 240
            assert lsb >= -240
            smallest_lsb = min(smallest_lsb,lsb)
            layout_checks += 1
assert smallest_lsb == -240
assert 8191**2 == 67092481
assert (((8191**2)&((1<<25)-1))<<1) == 67076098
assert Fraction(1) + 3*Fraction(1,1<<28) > Fraction(1) + Fraction(1,1<<27)
for h in range(65):
    w = 962+h
    assert (1<<h)*(1<<960) <= (1<<(w-1))-1

print(json.dumps({"formula_cases":checks,"layout_checks":layout_checks,"minimum_operand_grid_exponent":smallest_lsb,"status":"PASS","scope":"Formulas only; no RTL/L1 simulation"}))
