"""Third implementation: Python integers verify complete serialized F_W traces."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'results/week12/window'
NAR=1<<31
MASK=(1<<32)-1
BASE=532
LIMIT=240


def decode(raw):
    if raw==0:return 0
    assert raw!=NAR
    negative=bool(raw&NAR)
    code=(-raw)&MASK if negative else raw
    position=30;run=0;regime=(code>>position)&1
    while position>=0 and (code>>position)&1==regime:
        run+=1;position-=1
    if position>=0:position-=1
    exponent=0
    for _ in range(3):
        exponent*=2
        if position>=0:
            exponent|=(code>>position)&1;position-=1
    fraction_bits=position+1
    coefficient=(1<<fraction_bits)|(code&((1<<fraction_bits)-1))
    power=(run-1 if regime else -run)*8+exponent-fraction_bits
    value=coefficient<<(BASE+power)
    return -value if negative else value


def encode(value):
    if not value:return 0,(False,False,False)
    negative=value<0;magnitude=abs(value);h=magnitude.bit_length()-1;sf=h-BASE
    grs=(False,False,False)
    if sf>=LIMIT:code=NAR-1
    elif sf < -LIMIT:code=1
    else:
        k,exponent=divmod(sf,8)
        stream=('1'*(k+1)+'0' if k>=0 else '0'*(-k)+'1')+f'{exponent:03b}'+bin(magnitude)[3:]
        stream+='0'*max(0,34-len(stream))
        code=int(stream[:31],2)
        grs=(stream[31]=='1',stream[32]=='1','1' in stream[33:])
        if grs[0] and (code&1 or grs[1] or grs[2]):code+=1
        code=max(1,min(NAR-1,code))
    return ((-code)&MASK if negative else code),grs


checks=borrow_cases=zero_prior=0
for line in (RUN/'complete_trace.jsonl').read_text().splitlines():
    t=json.loads(line);checks+=1
    if t['p_nar'] or t['C_eff']==NAR:
        assert (t['bits'],t['flags'])==(NAR,16)
        continue
    p=0 if t['p_zero'] else t['P']<<(BASE+t['scale']-t['q'])
    if t['p_sign']:p=-p
    c=decode(t['C_eff']);total=p+c
    bits,grs=encode(total)
    metadata=0 if t['p_zero'] else (2 if t['input_cut'] or t['iteration_cut'] or t['term_cut'] else 0)|(1 if t['iteration_cut'] else 0)
    flags=metadata
    if total:
        sf=abs(total).bit_length()-1-BASE
        flags|=8 if abs(total)>(1<<(BASE+LIMIT)) else 0
        flags|=4 if sf < -LIMIT else 0
        flags|=2 if decode(bits)!=total else 0
        low=BASE+t['anchor']-29
        assert low>=0
        unit=1<<low
        assert int(t['P_ret'],16)==abs(p)//unit
        assert int(t['C_ret'],16)==abs(c)//unit
        assert int(t['magnitude'],16)==abs(total)//unit
        assert bool(t['residual'])==bool(abs(total)%unit)
        assert bool(t['sign'])==(total<0) and t['sf']==sf
        signed_ret=(-1 if p<0 else 1)*(abs(p)//unit)+(-1 if c<0 else 1)*(abs(c)//unit)
        assert bool(t['borrow'])==(abs(signed_ret)>abs(total)//unit)
        borrow_cases+=bool(t['borrow'])
    else:zero_prior+=bool(flags&2)
    assert (t['bits'],t['flags'])==(bits,flags)
    assert tuple(map(bool,[t['G'],t['R'],t['S']]))==grs
assert checks==138 and borrow_cases and zero_prior
report=dict(status='PASS',checked=checks,borrow_cases=borrow_cases,zero_prior_inexact=zero_prior,
            mismatches=0,oracle='independent Python signed full-grid integers')
(RUN/'python_trace.json').write_text(json.dumps(report,indent=2)+'\n')
print('W12 PYTHON TRACE PASS',checks,'mismatches=0')
