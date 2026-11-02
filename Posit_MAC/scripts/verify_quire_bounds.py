#!/usr/bin/env python3
"""Prove the Q12 grid by partitioning all Posit32/ES3 field geometries."""
import hashlib
import json
from pathlib import Path
from gen_quire_vectors import decode

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/quire_20261103'


def main():
    geometries=[];magnitude_codes=0
    for first in (0,1):
        for run in range(1,32):
            if run==31:
                if not first:continue  # All-zero code is zero, not a finite exponent.
                geometries.append({'sf':240,'fraction_bits':0,'pad12':12})
                magnitude_codes+=1;continue
            suffix=30-run
            exponent_bits=min(3,suffix)
            fraction_bits=suffix-exponent_bits
            for exp in range(1<<exponent_bits):
                k=run-1 if first else -run
                sf=8*k+(exp<<(3-exponent_bits))
                pad=max(0,12-fraction_bits)
                assert sf-fraction_bits>=-240
                assert sf-12+pad>=-240
                # Maximum value in this field partition does not exceed maxpos.
                coefficient=(1<<(fraction_bits+1))-1
                exponent=sf-fraction_bits
                assert (coefficient<<max(0,exponent)) <= ((1<<240)<<max(0,-exponent))
                geometries.append({'sf':sf,'fraction_bits':fraction_bits,'pad12':pad})
                magnitude_codes+=1<<fraction_bits
    assert magnitude_codes==(1<<31)-1
    pair_checks=0;negative_shift_pairs=0
    for a in geometries:
        for b in geometries:
            shift=a['sf']+b['sf']+456
            assert shift+a['pad12']+b['pad12']>=0
            pair_checks+=1;negative_shift_pairs+=shift<0
    assert 1024*(1<<960)==1<<970
    assert (1<<970)<(1<<971)-1
    result={'status':'PASS','profile':'Q12-1024','E_LSB':-480,'W':972,'L_max':1024,
            'geometry_cases':len(geometries),'geometry_pair_checks':pair_checks,
            'negative_alignment_shift_geometry_pairs':negative_shift_pairs,
            'positive_magnitude_codes_partitioned':magnitude_codes,
            'raw_codes_partitioned_including_sign_zero_NaR':2*magnitude_codes+2,
            'proof':['Each finite operand and its selected12-bit version is an integer multiple of2^-240',
                     'Selection only clears existing fraction bits and cannot introduce a lower nonzero bit',
                     'Every product is a multiple of2^-480; any negative alignment shift discards zeros',
                     '|P_hat|<=2^480 and1024 terms give |U|<=2^970 within signed972',
                     'Reference grid2^-532 gives magnitude<=2^1022 within1024 unsigned bits'],
            'limits':'Symbolic partition/inequality proof, not enumeration of4.29B simulations or a claim of minimal width',
            'script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    (OUT/'bounds.json').write_text(json.dumps(result,indent=2)+'\n')
    print('QUIRE_BOUNDS_PASS',len(geometries),'geometries',pair_checks,'pairs')


if __name__=='__main__':main()
