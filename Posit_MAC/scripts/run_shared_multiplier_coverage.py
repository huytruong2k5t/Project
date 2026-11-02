#!/usr/bin/env python3
"""Build coverage binaries while preserving the fast replay manifests."""
from concurrent.futures import ThreadPoolExecutor
import argparse
import hashlib
import json
import os
from verify_shared_multiplier import ROOT,OUT,build,execute

def run(kind,manifest,label,count):
    for p,h in manifest['source_sha256'].items():
        assert hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h,p
    report=OUT/f'{label}_{kind}.json'
    if report.exists(): raise RuntimeError('Preserve existing coverage run')
    execute([str(ROOT/manifest['binary']),str(count),'-1','-1','20261102',str(report)],ROOT,report.with_suffix('.log'))
    r=json.loads(report.read_text())
    assert r['completed']==count and r['mismatches']==0
    print('SHARED_COVERAGE_RUN_PASS',kind,r['completed'],flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--tag',default='coverage_v8')
    parser.add_argument('--label',default='coverage_stratified')
    parser.add_argument('--count',type=int,default=20000)
    args=parser.parse_args()
    if not args.label.replace('_','').isalnum() or args.count<1:
        parser.error('Simple label and positive count required')
    manifests={}
    os.environ['SHARED_BUILD_TAG']=args.tag
    os.environ['SHARED_COVERAGE']='1'
    for kind in ['nf','f']:
        p=OUT/('build_'+kind+'.json'); saved=p.read_bytes()
        try:
            build(kind)
            manifests[kind]=json.loads(p.read_text())
            evidence=OUT/f'{args.label}_build_{kind}.json'
            if evidence.exists(): raise RuntimeError('Preserve existing coverage manifest')
            evidence.write_bytes(p.read_bytes())
        finally:
            p.write_bytes(saved)
    with ThreadPoolExecutor(max_workers=2) as pool:
        jobs=[pool.submit(run,k,manifests[k],args.label,args.count) for k in ['nf','f']]
        for j in jobs:j.result()
