"""Independent Python Fraction decoder/encoder and metric calibration."""
from fractions import Fraction
from decimal import Decimal, localcontext
from pathlib import Path
import json
import hashlib

R=Path(__file__).resolve().parents[1];O=R/'results/week14/accuracy'
NAR=0x80000000


def decode(raw):
    if raw==NAR:return None
    if raw==0:return Fraction(0)
    sign=raw>>31;mag=(-raw)&0xffffffff if sign else raw
    i=30;pol=(mag>>i)&1;run=0
    while i>=0 and ((mag>>i)&1)==pol:run+=1;i-=1
    k=run-1 if pol else -run
    i-=1;e=0
    for _ in range(3):
        e=2*e+((mag>>i)&1 if i>=0 else 0);i-=1
    f=max(0,i+1);coefficient=(1<<f)+(mag&((1<<f)-1))
    exponent=k*8+e-f
    value=Fraction(coefficient)*(2**exponent if exponent>=0 else Fraction(1,2**(-exponent)))
    return -value if sign else value


def encode(v):
    if v is None:return NAR
    if not v:return 0
    sign=v<0;v=abs(v);coefficient=v.numerator;den=v.denominator
    assert den&(den-1)==0
    h=coefficient.bit_length()-1;sf=h-(den.bit_length()-1)
    if sf>=240:code=NAR-1
    elif sf < -240:code=1
    else:
        k,e=divmod(sf,8);run=k+1 if k>=0 else -k
        bits=[int(k>=0)]*run+[int(k<0)]+[(e>>i)&1 for i in range(2,-1,-1)]
        bits += [(coefficient>>i)&1 for i in range(h-1,-1,-1)]
        bits += [0]*max(0,33-len(bits))
        code=0
        for bit in bits[:31]:code=2*code+bit
        if bits[31] and ((code&1) or any(bits[32:])):code+=1
        code=max(1,min(NAR-1,code))
    return (-code)&0xffffffff if sign else code


def close(decimal_value, exact):
    with localcontext() as ctx:
        ctx.prec=100
        actual=Decimal(decimal_value);expected=Decimal(exact.numerator)/Decimal(exact.denominator)
        return abs(actual-expected)<=max(abs(expected)*Decimal('1e-15'),Decimal('1e-300'))


def main():
    counts=[]
    for n in range(9):
        rows=[json.loads(line) for line in (O/f'n{n}.jsonl').read_text().splitlines()]
        assert len(rows)>=1000
        expected={k:dict(finite_nonzero=0,nar=0,reference_zero=0,zero_match=0,correct_counts=[0]*4,max_ulp=0) for k in ('nf','f')}
        for row in rows:
            a,b,c=(decode(row[key]) for key in ('a','b','c'))
            ideal=None if any(v is None for v in (a,b,c)) else a*b+c
            assert row['ref']==encode(ideal),(n,row['i'],'reference RNE')
            assert bool(row['nar'])==(ideal is None)
            if ideal is None:
                for k in expected:expected[k]['nar']+=1
                continue
            assert close(row['ideal'],ideal),(n,row['i'],'ideal value')
            for k,name in enumerate(('nf','f')):
                y=decode(row[name]);assert y is not None
                e=expected[name]
                if ideal:
                    e['finite_nonzero']+=1
                    e['max_ulp']=max(e['max_ulp'],abs((row[name] if row[name]<NAR else row[name]-2*NAR)-(row['ref'] if row['ref']<NAR else row['ref']-2*NAR)))
                else:
                    e['reference_zero']+=1;e['zero_match']+=y==0
                error=abs(ideal-y)
                assert close(row['metrics'][k]['absolute'],error),(n,row['i'],name,'absolute')
                pct=100*error/abs(ideal) if ideal else Fraction(0)
                assert close(row['metrics'][k]['err_percent'],pct),(n,row['i'],name,'relative')
                # Check strict threshold decisions independently, including equality.
                for j,threshold in enumerate((Fraction(1,10),Fraction(1,2),Fraction(1),Fraction(5))):
                    if ideal:
                        assert bool(row['metrics'][k]['correct'][j])==(pct<threshold)
                        e['correct_counts'][j]+=pct<threshold
        result=json.loads((O/f'n{n}.json').read_text())
        assert result['samples']==100000 and result['n']==n
        for name in ('nf','f'):
            s=result[name];assert s['finite_nonzero']+s['nar']+s['reference_zero']==100000
            for key,value in expected[name].items():assert result['calibration_'+name][key]==value,(n,name,key)
        counts.append(len(rows))
    summary=dict(status='PASS',cpp_samples_per_n=100000,n=list(range(9)),
                 python_fraction_checks_per_n=counts,total_python_checks=sum(counts),
                 metrics='decode, exact real A*B+C, independent RNE, absolute/relative error and strict thresholds',
                 tolerance='long-double numerical metrics relative1e-15; exact integer classification/reference bits',
                 scope='standalone accuracy pilot, not RTL main accuracy or W14-09',
                 policy='Standalone shared C; future acc_mode suite reports own NF/F states and exact-real reference state separately, never silently reuses common C across divergent feedback')
    (O/'python_check.json').write_text(json.dumps(summary,indent=2)+'\n')
    print('ACCURACY FRACTION CHECK PASS',sum(counts),'rows; 9x100000 samples')


if __name__=='__main__':main()
