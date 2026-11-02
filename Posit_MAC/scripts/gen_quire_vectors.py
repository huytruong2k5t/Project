#!/usr/bin/env python3
"""Unbounded Python-int quire oracle and compact 4-state command fixtures."""
import argparse
import json
from pathlib import Path
import random

NAR=0x80000000
MASK=(1<<972)-1


def decode(raw):
    negative=bool(raw&NAR);code=(-raw)&0xffffffff if negative else raw
    if not code:return False,0,0
    if code==NAR:raise ValueError('NaR decode')
    p=30;run=0;first=(code>>p)&1
    while p>=0 and ((code>>p)&1)==first:run+=1;p-=1
    if p>=0:p-=1
    exp=0
    for _ in range(3):
        exp<<=1
        if p>=0:exp|=(code>>p)&1;p-=1
    available=p+1
    coeff=(1<<26)|((code&((1<<available)-1))<<(26-available))
    return negative,coeff,((run-1) if first else -run)*8+exp


def product(a,b,n=12,ops=1):
    if a==NAR or b==NAR:return 0,True,False,False
    if not a or not b:return 0,False,False,False
    sa,ca,ea=decode(a);sb,cb,eb=decode(b)
    fa=(ca>>14)&4095;fb=(cb>>14)&4095
    if ops and fb.bit_count()<fa.bit_count():fa,fb=fb,fa
    selected=0;left=n
    for bit in range(11,-1,-1):
        if (fa>>bit)&1 and left:selected|=1<<bit;left-=1
    m=(4096+selected)*(4096+fb);shift=ea+eb+456
    if shift<0:
        assert m&((1<<-shift)-1)==0
        term=m>>-shift
    else:term=m<<shift
    if sa!=sb:term=-term
    return term,False,bool((ca|cb)&16383),selected!=fa


def encode(q,loss=False,cut=False,nar=False):
    if nar:return NAR,16
    flags=(2 if loss else 0)|(1 if cut else 0)
    if not q:return 0,flags
    negative=q<0;m=abs(q);h=m.bit_length()-1;sf=h-480
    if sf>=240:code=NAR-1
    elif sf< -240:code=1
    else:
        k=sf//8;e=sf-k*8;run=k+1 if k>=0 else -k;header=run+4
        def bit(i):
            if i<run:return int(k>=0)
            if i==run:return int(k<0)
            if i<header:return (e>>(header-1-i))&1
            at=h-1-(i-header)
            return ((m>>at)&1) if at>=0 else 0
        code=0
        for i in range(31):code=(code<<1)|bit(i)
        guard=bit(31);round_bit=bit(32)
        sticky=any(bit(i) for i in range(33,header))
        low=h-max(0,33-header)
        sticky|=low>0 and bool(m&((1<<low)-1))
        if guard and ((code&1) or round_bit or sticky):code+=1
        code=max(1,min(NAR-1,code))
    raw=(-code)&0xffffffff if negative else code
    _,coefficient,scale=decode(raw)
    exact=coefficient<<(scale+454)
    flags|=8 if sf>240 or (sf==240 and m!=(1<<h)) else 0
    flags|=4 if sf< -240 else 0
    flags|=2 if m!=exact else 0
    return raw,flags


class State:
    def __init__(self):self.clear()
    def clear(self):self.q=0;self.count=0;self.nar=False;self.loss=False;self.cut=False
    def mac(self,a,b,n=12,ops=1):
        assert self.count<1024 and n<=12 and ops<=1
        term,nar,loss,cut=product(a,b,n,ops)
        self.count+=1;self.nar|=nar;self.loss|=loss or cut;self.cut|=cut
        if not self.nar:self.q+=term
        assert -(1<<971)<=self.q<(1<<971)
    def response(self,cmd):
        if cmd==2:return encode(self.q,self.loss,self.cut,self.nar)
        return 0,16 if self.nar else ((2 if self.loss else 0)|(1 if self.cut else 0))


def main():
    parser=argparse.ArgumentParser();parser.add_argument('out',type=Path);args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True);s=State();rng=random.Random(20261103);rows=[]
    def emit(cmd,a=0,b=0,n=12,ops=1,abort=0):
        if cmd==0:s.clear()
        elif cmd==1:s.mac(a,b,n,ops)
        bits,flags=s.response(cmd)
        rows.append(f'{cmd} {a:08x} {b:08x} {n} {ops} {abort} {bits:08x} {flags:02x} {s.q&MASK:0243x} {s.count} {int(s.nar)} {int(s.loss)} {int(s.cut)}')
        if abort:s.clear()
    one=0x40000000
    emit(0,n=15,ops=3);emit(2,n=15,ops=3)
    emit(1,one,one)
    for _ in range(3):emit(1,0x14000000,0x14000000)
    assert s.response(2)[0]==0x40000001
    emit(2);emit(2);emit(0)
    for abort in (1,2,3):emit(1,one,one,abort=abort)
    emit(1,one,one);emit(2,abort=1);emit(1,one,one);emit(2,abort=2)
    emit(0);emit(1,0,NAR);emit(1,one,one);emit(2);emit(0);emit(2)
    for a,b in ((1,1),(NAR-1,NAR-1),(0xffffffff,1),(NAR+1,NAR-1)):
        emit(0)
        for _ in range(1024):emit(1,a,b)
        emit(2);emit(2);emit(0)
    emit(1,NAR-1,NAR-1);emit(1,1,1);emit(1,NAR+1,NAR-1);emit(2);emit(0)
    # Tie-even, tie-odd, and low-only sticky after an exact sum.
    emit(1,one,one)
    for i in range(6):
        emit(1,0x14000000,0x14000000)
        if i in (1,5):emit(2)
    emit(0);emit(1,one,one)
    small=encode(1<<440)[0];emit(1,small,small);emit(2);emit(0)
    for ops in range(2):
        for n in range(13):
            for _ in range(16):emit(1,rng.getrandbits(32),rng.getrandbits(32),n,ops)
            emit(2);emit(0)
    pairs=[(rng.getrandbits(32),rng.getrandbits(32)) for _ in range(128)]
    final=None
    for order in (pairs,list(reversed(pairs))):
        emit(0)
        for a,b in order:emit(1,a,b)
        if final is None:final=s.q
        else:assert s.q==final
        emit(2)
    (args.out/'commands.txt').write_text('\n'.join(rows)+'\n')
    (args.out/'vectors.json').write_text(json.dumps({'status':'GENERATED','rows':len(rows),'seed':20261103,
        'oracle':'Python unbounded signed integer, grid2^-480; independent raw decoder and serial RNE',
        'columns':'cmd a b n ops abort bits flags q_twos972 count nar loss cut'},indent=2)+'\n')
    print('QUIRE_VECTORS',len(rows))


if __name__=='__main__':main()
