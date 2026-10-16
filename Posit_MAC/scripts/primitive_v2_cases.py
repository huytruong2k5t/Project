"""Create bounded screening/confirmation lists without modifying measured rows."""
from pathlib import Path
import csv
import json
import argparse

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'


def row(case,strategy='default'):
    v,n,k,m,a,f=[case[x] for x in ('variant','n','kind','mode','arith','fill')]
    ident=f'{v}_n{n}_k{k}_m{m}_a{a}_f{f}_{strategy}'
    return '\t'.join(map(str,(ident,v,n,k,m,a,f,strategy)))+'\n'


def main():
    parser=argparse.ArgumentParser();parser.add_argument('phase',choices=['screen','chain','extensions'])
    args=parser.parse_args()
    manifest=json.loads((OUT/'manifest.json').read_text())
    if args.phase=='screen':
        for phase,kinds in [('lod',{2}),('shift',{0,1})]:
            text=''.join(row(c) for c in manifest['cases'] if c['kind'] in kinds)
            (OUT/f'{phase}_cases.tsv').write_text(text,newline='\n')
            print(phase,len(text.splitlines()),'cases')
    elif args.phase=='extensions':
        extra=[dict(variant=v,n=n,kind=k,mode=0,arith=0,fill=0)
               for n in (12,31) for k in (3,4) for v in ('native','radix4')]
        mixed=[dict(variant='group4_mixed',n=n,kind=2,mode=0,arith=0,fill=1)
               for n in (26,30,31,32)]
        for phase,cases in [('chain_extra',extra),('lod_mixed',mixed)]:
            path=OUT/f'{phase}_cases.tsv';text=''.join(row(c) for c in cases)
            if path.exists() and path.read_text()!=text:
                raise RuntimeError('Measured extension list differs: '+phase)
            path.write_text(text,newline='\n')
            print(phase,len(cases),'cases')
    else:
        import shutil
        dst=OUT/'source/combined_reverse';dst.mkdir(exist_ok=True)
        for module in ('lod_lzd_core','dyn_left_shifter','dyn_right_shifter'):
            src=OUT/'source'/('group4' if module=='lod_lzd_core' else 'reverse')/(module+'.sv')
            target=dst/src.name
            if target.exists() and target.read_bytes()!=src.read_bytes():raise RuntimeError('Combined snapshot differs')
            shutil.copyfile(src,target)
        shutil.copyfile(ROOT/'rtl/posit_mac.vh',dst/'posit_mac.vh')
        # Test reverse order in chains even when its isolated score is lower:
        # low count bits can arrive later than high bits from an encoder.
        cases=[dict(variant=v,n=n,kind=k,mode=0,arith=0,fill=0)
               for n in (12,26,31) for k in (3,4)
               for v in ('baseline','group4','reverse','combined_reverse')]
        path=OUT/'chain_cases.tsv';text=''.join(row(c) for c in cases)
        if path.exists() and path.read_text()!=text:raise RuntimeError('Measured chain list differs')
        path.write_text(text,newline='\n')
        print('chain',len(cases),'cases')


if __name__=='__main__':main()
