import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
nar, mask, limit, base = 1 << 31, (1 << 32)-1, 240, 532

def decode(raw):
    if raw == 0:
        return 0
    negative = bool(raw & nar)
    mag = (-raw) & mask if negative else raw
    position, run = 30, 0
    polarity = (mag >> position) & 1
    while position >= 0 and (mag >> position) & 1 == polarity:
        run += 1
        position -= 1
    position -= 1  # regime terminator, absent at maxpos
    exponent = 0
    for _ in range(3):
        exponent <<= 1
        if position >= 0:
            exponent |= (mag >> position) & 1
            position -= 1
    available = max(0, position+1)
    coefficient = (1 << available) | (mag & ((1 << available)-1))
    scale = (run-1 if polarity else -run)*8 + exponent - available
    value = coefficient << (base+scale)
    return -value if negative else value

def encode(value):
    if not value:
        return 0
    negative = value < 0
    mag = abs(value)
    top = mag.bit_length()-1
    sf = top-base
    if sf >= limit:
        code = nar-1
    elif sf < -limit:
        code = 1
    else:
        k, exponent = divmod(sf, 8)
        stream = ('1'*(k+1)+'0') if k >= 0 else ('0'*(-k)+'1')
        stream += f'{exponent:03b}'
        stream += format(mag, 'b')[1:]
        stream += '0'*max(0, 33-len(stream))
        code = int(stream[:31], 2)
        if stream[31] == '1' and (code & 1 or '1' in stream[32:]):
            code += 1
        code = max(1, min(nar-1, code))
    return (-code if negative else code) & mask

checked, zeros, cancellation = 0, 0, 0
for line in (root/'results/week11/fused_pilot.txt').read_text().splitlines():
    magnitude, scale, q, sign, zero, special, c, expected, expected_sign, top, expected_zero = map(int, line.split())
    if special or c == nar:
        actual = nar
    else:
        product = 0 if zero else magnitude << (base+scale-q)
        if sign:
            product = -product
        cv = decode(c)
        total = product+cv
        actual = encode(total)
        assert bool(expected_zero) == (total == 0)
        if total:
            assert bool(expected_sign) == (total < 0)
            assert top == abs(total).bit_length()-1
        zeros += total == 0
        cancellation += product != 0 and product == -cv
    assert actual == expected, (checked, actual, expected)
    checked += 1
report = dict(status='PASS: W11 software fused full-sum pilot only',checked=checked,
              mismatches=0,exact_zero=zeros,exact_cancellation=cancellation,
              seed=20261013,format='32/3 Q12 FLOOR OPS1 n0..8',
              limits=['No fused RTL/window/flags/acc_mode acceptance',
                      'Python checks exact P_hat+C; not paper provenance or accuracy versus original A*B+C'])
(root/'results/week11/fused_pilot_summary.json').write_text(json.dumps(report,indent=2)+'\n')
print('W11 F PYTHON AUDIT PASS',checked,'mismatches=0')
