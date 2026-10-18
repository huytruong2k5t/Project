"""Independent directed coverage addendum; preserve original corpus and freezes."""
from pathlib import Path
from fractions import Fraction as Q
import json,shutil
from check_week14_accuracy import encode
from audit_week14 import sha,R,O
E=O/'closure'


def main():
    assert not E.exists();E.mkdir()
    cases=[]
    def add(p,c,label,b=Q(1)):
        cases.append(dict(a=encode(p),b=encode(b),c=encode(c),label=label))
    for d in (0,1,2,8,29):add(Q(3,2),Q(5,4) if d==0 else Q(2)**-d,f'P_same_d{d}')
    for d in (1,2,8,29):add(Q(2)**-d,Q(3,2),f'C_same_d{d}')
    for z in (1,3,10,20):add(Q(3,2),-(Q(3,2)-Q(2)**-z),f'P_opposite_d0_z{z}')
    for p,c,z in [(Q(7,4),-Q(1,2),0),(Q(3,2),-Q(3,4),1),
                  (Q(1),-(1-Q(2)**-3),3),(Q(1),-(1-Q(2)**-10),10),(Q(1),-(1-Q(2)**-20),20)]:
        add(p,c,f'P_opposite_d1_z{z}')
    for d in (2,8,29):
        for p,z in [(Q(3,2),0),(Q(1),1)]:add(p,-Q(2)**-d,f'P_opposite_d{d}_z{z}')
    for p,c,z in [(Q(1,2),-Q(7,4),0),(Q(1,2),-Q(5,4),1),(Q(7,8),-Q(1),3),(1-Q(2)**-10,-Q(1),10)]:
        add(p,c,f'C_opposite_d1_z{z}')
    for d in (2,8,29):
        for c,z in [(-Q(3,2),0),(-Q(1),1)]:add(Q(2)**-d,c,f'C_opposite_d{d}_z{z}')
    assert len(cases)==34
    add(Q(2)**-27,Q(1),'packer_tie_hold')
    add(Q(2)**-27,1+Q(2)**-26,'packer_tie_up')
    add(Q(2)**-28,Q(1),'packer_down')
    add(3*Q(2)**-28,Q(1),'packer_up')
    cases.append(dict(a=encode(Q(2)**-20),b=encode(Q(1)),c=0x5fffffff,label='packer_carry_regime'))
    add(Q(2)**200,Q(0),'sat_max',Q(2)**200)
    add(Q(2)**-240,Q(0),'sat_min',Q(2)**-240)
    add(Q(1),-Q(1),'exact_zero')
    (E/'cases.json').write_text(json.dumps(cases,indent=2)+'\n')
    text=(R/'tb/week14_fused_harness.cpp').read_text()
    start=text.index('Input generate(');end=text.index('unsigned incoming(',start)
    arr=',\n'.join('        {'+f"{r['a']}u,{r['b']}u,{r['c']}u,FIXED_N,FIXED_OPS,false,false"+'}' for r in cases)
    text=text[:start]+'Input generate(std::mt19937_64&,uint64_t i,uint32_t) {\n    const Input rows[]={\n'+arr+'\n    };return rows[i%'+str(len(cases))+'];\n}\n'+text[end:]
    helper='''
std::array<uint64_t,7> packer(const Model::Result& exp) {
    std::array<uint64_t,7> bins{};
    if(exp.flags&16)return bins;
    bins[4]=bool(exp.flags&8);bins[5]=bool(exp.flags&4);
    const auto& t=exp.trace;
    if(t.zero||bins[4]||bins[5])return bins;
    const bool up=t.guard&&(t.retained_lsb||t.round||t.sticky);
    bins[0]=up;bins[1]=(t.guard||t.round||t.sticky)&&!up;
    bins[2]=t.guard&&!t.round&&!t.sticky&&up;bins[3]=t.guard&&!t.round&&!t.sticky&&!up;
    int k=t.sf/8;if(t.sf<0&&t.sf%8)--k;
    const int exponent=t.sf-k*8;
    const unsigned run=unsigned(k>=0?k+1:-k),header=run+4,h=Model::top(t.magnitude);
    auto bit=[&](unsigned i){if(i<run)return k>=0;if(i==run)return k<0;
        if(i<header)return bool((exponent>>(header-1-i))&1);
        int p=int(h)-1-int(i-header);return p>=0&&bool((t.magnitude>>unsigned(p))&1);};
    uint32_t mag=0;for(unsigned i=0;i<31;++i)mag=mag*2+bit(i);
    auto regime=[](uint32_t m){bool pol=(m>>30)&1;unsigned count=0;
        for(int b=30;b>=0&&bool((m>>b)&1)==pol;--b)++count;return 32*unsigned(pol)+count;};
    bins[6]=up&&mag&&mag<0x7fffffff&&regime(mag)!=regime(mag+1);
    return bins;
}
'''
    text=text.replace('int main(int argc,char** argv)',helper+'\nint main(int argc,char** argv)')
    text=text.replace('std::array<uint64_t,9> n_hits{},iteration_hits{};',
        'std::array<uint64_t,9> n_hits{},iteration_hits{};std::array<uint64_t,7> packer_hits{};')
    text=text.replace('++completed;++n_hits[row.n];','const auto pb=packer(exp);for(unsigned j=0;j<7;++j)packer_hits[j]+=pb[j];\n                ++completed;++n_hits[row.n];')
    text=text.replace('check(reset_busy&&reset_stall&&invalid&&commits&&clears,"protocol coverage hole");',
                      'check(reset_busy&&reset_stall&&invalid,"directed reset coverage");')
    text=text.replace('array("n_hits",n_hits);','array("packer_bins",packer_hits);array("n_hits",n_hits);')
    (E/'f_directed.cpp').write_text(text,encoding='utf-8',newline='\n')
    shutil.copyfile(R/'tb/nf_coverage_harness.cpp',E/'nf_mixed.cpp')
    # Fixed-n original corpora remain unchanged. This additional mixed exact/approx suite
    # covers the full public NF mode contract on the same full-instrumentation netlist.
    legal=[];excluded={}
    for ca in (0,1):
        for different in (0,1):
            for d in range(5):
                for z in range(5):
                    key=z+5*d+25*different+50*ca
                    reason=None
                    if ca and d==0:reason='Anchor ties choose P, never C'
                    elif not different and z:reason='Same-sign positive-magnitude sum cannot left-normalize'
                    elif different and d==0 and z==0:reason='Equal-scale opposite magnitudes differ by less than anchor unit'
                    elif different and d>=2 and z>=2:reason='Scale gap>=2 makes |large-small|>0.5 anchor unit'
                    elif ca and different and d==1 and z==4:reason='P has <=14 significant bits; below C boundary gap>=2^-14 anchor units'
                    if reason:excluded[key]=reason
                    else:legal.append(key)
    assert len(legal)==34
    policy=dict(parent_matrix_sha256=sha(O/'matrix_freeze.json'),fused_legal=legal,fused_excluded=excluded,
        scope='Mathematical reachability for32/3 FW12 W32 exact-disabled top, not exclusion based only on missing hits',
        requests=[dict(kind='f_directed',n=3,ops=ops,count=30000,seed=2026102100+ops) for ops in (0,1)],
        nf_mixed_goals=dict(nf32_3=100000,nf32_2=100000),
        source_sha256={p.name:sha(p) for p in E.iterdir() if p.is_file()})
    (E/'plan.json').write_text(json.dumps(policy,indent=2)+'\n')
    print('Closure addendum frozen:34 F bins +7 packer classes, independent extra suites; no original corpus change')


if __name__=='__main__':main()
