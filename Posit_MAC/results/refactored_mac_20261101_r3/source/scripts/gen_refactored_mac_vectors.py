"""Independent integer golden for the CURRENT FLOOR/Q12 RTL, not FULL_TERM signoff."""
from pathlib import Path
import argparse,random,json
NAR=0x80000000
MASK=0xffffffff
BASE=532

def decode(raw):
    sign=bool(raw&NAR);code=(-raw)&MASK if sign else raw
    if not code:return sign,0,0
    if code==NAR:raise ValueError('NaR')
    bit=30;run=0;polarity=(code>>bit)&1
    while bit>=0 and ((code>>bit)&1)==polarity:run+=1;bit-=1
    if bit>=0:bit-=1
    exponent=0
    for _ in range(3):
        exponent*=2
        if bit>=0:exponent|=(code>>bit)&1;bit-=1
    frac=(code&((1<<(bit+1))-1))<<(26-bit-1)
    return sign,(1<<26)|frac,(run-1 if polarity else -run)*8+exponent

def encode(value):
    if not value:return 0,0
    sign=value<0;m=abs(value);h=m.bit_length()-1;sf=h-BASE
    if sf>=240:code=NAR-1
    elif sf < -240:code=1
    else:
        k,e=divmod(sf,8);run=k+1 if k>=0 else -k
        bits=[int(k>=0)]*run+[int(k<0)]+[(e>>b)&1 for b in range(2,-1,-1)]
        bits += [(m>>b)&1 for b in range(h-1,-1,-1)]
        bits += [0]*max(0,33-len(bits))
        code=0
        for b in bits[:31]:code=(code<<1)|b
        if bits[31] and ((code&1) or any(bits[32:])):code+=1
        code=max(1,min(NAR-1,code))
    raw=(-code)&MASK if sign else code
    s,c,q=decode(raw);rounded=(-1 if s else 1)*(c<<(BASE+q-26))
    flags=(8 if sf>240 or (sf==240 and m!=(1<<h)) else 0)|(4 if sf < -240 else 0)|(2 if rounded!=value else 0)
    return raw,flags

def value(raw):
    s,c,q=decode(raw)
    return (-1 if s else 1)*(c<<(BASE+q-26))

def golden(a,b,c,n,ops,fused):
    if NAR in (a,b,c):return NAR,16
    if not a or not b:return c,0
    sa,ca,qa=decode(a);sb,cb,qb=decode(b)
    fa=(ca>>14)&4095;fb=(cb>>14)&4095
    cut=bool((ca|cb)&16383)
    if ops and fb.bit_count()<fa.bit_count():fa,fb=fb,fa
    selected=[b for b in range(11,-1,-1) if fa&(1<<b)]
    y=4096+fb;m=y;tail=False
    for bit in selected[:n]:
        shift=12-bit;m+=y>>shift;tail|=bool(y&((1<<shift)-1))
    iteration_cut=len(selected)>n
    flags=(2 if cut or tail or iteration_cut else 0)|(1 if iteration_cut else 0)
    p=(-1 if sa!=sb else 1)*(m<<(BASE+qa+qb-12))
    if not fused:
        packed,pf=encode(p);flags|=pf;p=value(packed)
    d,sf=encode(p+value(c))
    return d,flags|sf

def main():
    ap=argparse.ArgumentParser();ap.add_argument('output');ap.add_argument('--count',type=int,default=5000);args=ap.parse_args()
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    summary={}
    corners=[0,NAR,1,MASK,0x7fffffff,0x80000001,0x40000000,0xc0000000,0x43ffc000,0x40004000]
    for fused,max_n in [(False,8),(True,12)]:
        rng=random.Random(20261101);state=0;aborted=0;bins={}
        path=out/('f.txt' if fused else 'nf.txt')
        with path.open('w',encoding='ascii') as f:
            for i in range(args.count):
                n=i%(max_n+1);ops=(i//(max_n+1))%2
                a,b,c=(rng.getrandbits(32) for _ in range(3))
                mode=(i//7)%2;clear=bool(mode and i%37==0)
                if i%5==0:a=corners[(i//5)%len(corners)];b=corners[(i//50)%len(corners)]
                if i%11==0:c=0
                if i%13==0:a=0x40000000;b=0x40000000;c=0xc0000000
                if i%17==0:a=0x43ffc000;b=0x43ffc000
                abort=1 if i%251==99 else 2 if i%503==105 else 0
                effective=0 if clear else state if mode else c
                d,flags=golden(a,b,effective,n,ops,fused)
                f.write(f'{a:08x} {b:08x} {c:08x} {n} {ops} {int(mode)} {int(clear)} {d:08x} {flags:02x} {abort}\n')
                if abort:state=0;aborted+=1
                else:
                    if mode:state=d
                    key=f'n{n}_ops{ops}';bins[key]=bins.get(key,0)+1
        summary[path.stem]={'rows':args.count,'completed':args.count-aborted,'aborted':aborted,'bins':bins}
    (out/'vectors.json').write_text(json.dumps({'profile':'current RTL FLOOR Q12; cfg_mode=1','seed':20261101,'counts':summary},indent=2))

if __name__=='__main__':main()
