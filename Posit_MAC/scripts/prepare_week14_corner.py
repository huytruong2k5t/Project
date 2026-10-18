"""Build a separate directed F corner driver; never alter the main binary."""
from pathlib import Path
import json
import hashlib
from check_week14_accuracy import encode
from fractions import Fraction

R=Path(__file__).resolve().parents[1];O=R/'results/week14/corner'


def main():
    assert not O.exists()
    O.mkdir()
    p=lambda sf,negative=False:encode(Fraction(-1 if negative else 1)*(Fraction(2)**sf))
    cases=[]
    def add(a,b,c,label):cases.append(dict(a=a,b=b,c=c,label=label))
    add(encode(Fraction(10)),encode(Fraction(11,32)),encode(Fraction(1,2)),'TV-FUSE-01')
    add(encode(Fraction(10)),encode(Fraction(11,32)),encode(Fraction(-8)),'TV-FUSE-02')
    for d in (28,29,-28,-29):
        for negative in (False,True):add(p(0),p(0),p(d,negative),f'delta_{d}_sign_{negative}')
    for key in ('a','b','c'):
        row=dict(a=p(0),b=p(0),c=p(-1));row[key]=0x80000000
        add(row['a'],row['b'],row['c'],'NaR_'+key)
    add(0,p(0),p(-1),'zero_product_A')
    add(p(0),0,p(-1),'zero_product_B')
    add(p(0),p(0),0,'zero_C')
    add(p(0),p(0),p(0,True),'C_minus_AxB_zero')
    while len(cases)<64:
        add(p(0),p(0),0xc0000001 if len(cases)%2 else 0xc0000000,'deep_LZC_or_exact_zero')
    text=(R/'tb/week14_fused_harness.cpp').read_text()
    start=text.index('Input generate(');end=text.index('unsigned incoming(',start)
    arr=',\n'.join('        {'+f"{r['a']}u,{r['b']}u,{r['c']}u,FIXED_N,FIXED_OPS,false,false"+'}' for r in cases)
    generator='Input generate(std::mt19937_64&,uint64_t i,uint32_t) {\n    const Input rows[]={\n'+arr+'\n    };\n    return rows[i%64];\n}\n'
    text=text[:start]+generator+text[end:]
    text=text.replace('check(reset_busy&&reset_stall&&invalid&&commits&&clears,"protocol coverage hole");',
                      'check(reset_busy&&reset_stall&&invalid,"corner reset/invalid coverage");')
    text=text.replace('std::array<uint64_t,9> n_hits{},iteration_hits{};',
                      'std::array<uint64_t,9> n_hits{},iteration_hits{};std::array<uint64_t,64> corner_hits{};')
    text=text.replace('++completed;++n_hits[row.n];','++corner_hits[failure_serial%64];\n                ++completed;++n_hits[row.n];')
    text=text.replace('array("n_hits",n_hits);','array("corner_hits",corner_hits);array("n_hits",n_hits);')
    text=text.replace('check(n_hits[FIXED_N]==completed,"mixed fixed-n run");',
                      'check(n_hits[FIXED_N]==completed,"mixed fixed-n run");\n    for(auto count:corner_hits)check(count>0,"unhit corner tag");')
    (O/'week14_corner.cpp').write_text(text,encoding='utf-8',newline='\n')
    (O/'cases.json').write_text(json.dumps(dict(cases=cases,seed=2026102000,
        expected_golden_n_ge1=[encode(Fraction(63,16)),encode(Fraction(-73,16))],
        counts_per_n=20000,description='Standalone corner driver; state/commit/feedback verified in regular pilots and main'),indent=2)+'\n')
    print('Directed F corner source prepared; no main harness or RTL changes')


if __name__=='__main__':main()
