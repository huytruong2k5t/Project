#!/usr/bin/env python3
"""Run source-bound NF/F x OPS0/1 x n0..12 without merging old snapshots."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from verify_shared_multiplier import ROOT,OUT,load,execute

def variant(kind,count,label):
    binary=load(kind)
    reports=[]
    for ops in range(2):
        for n in range(13):
            p=OUT/f'{label}_{kind}_ops{ops}_n{n}.json'
            if p.exists(): raise RuntimeError('Preserve existing matrix point: '+str(p))
            execute([str(binary),str(count),str(n),str(ops),'20261102',str(p)],ROOT,p.with_suffix('.log'))
            r=json.loads(p.read_text())
            assert r['status']=='PASS' and r['completed']==count and r['mismatches']==0
            assert r['accepted']==r['completed']+r['reset_aborted']
            assert r['bins'][ops*13+n]==count and sum(r['bins'])==count
            assert not any(r['iterations'][n+1:])
            assert r['standalone']>=count//10 and r['accumulation']>=count//10
            assert r['near_cancellation']>=count*0.30
            assert all(x>0 for x in r['regime_bins'])
            reports.append(r)
            print(f'MATRIX_POINT_PASS {kind} OPS{ops} n{n} completed={count}',flush=True)
    flags=[sum(r['flags'][i] for r in reports) for i in range(32)]
    expected={0,2,3,6,7,10,11,16} if kind=='f' else {0,2,3,6,7,10,11,14,15,16}
    observed={i for i,c in enumerate(flags) if c}
    assert observed==expected,(kind,observed,expected)
    summary={'variant':kind,'points':26,'completed':sum(r['completed'] for r in reports),
             'mismatches':0,'all_legal_output_flag_codes_observed':sorted(observed),
             'near_min_fraction':min(r['near_cancellation']/count for r in reports),
             'minimum_regime_cell':min(min(r['regime_bins']) for r in reports),
             'main_volume_met':count>=10000000,
             'main_regime_quota_met':all(min(r['regime_bins'])>=4000 for r in reports),
             'claim':'Configuration/functional pilot; not all raw32 triples or structural signoff'}
    (OUT/f'{label}_{kind}_summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    return summary

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--count',type=int,default=100000)
    p.add_argument('--label',default='matrix_pilot');a=p.parse_args()
    if not a.label.replace('_','').isalnum(): raise ValueError('Simple label required')
    with ThreadPoolExecutor(max_workers=2) as pool:
        jobs=[pool.submit(variant,k,a.count,a.label) for k in ['nf','f']]
        results=[j.result() for j in jobs]
    result={'status':'PASS','points':52,'completed':sum(r['completed'] for r in results),'mismatches':0,
            'count_per_point':a.count,'seed':20261102,'variants':results,
            'gate_status':'VOLUME_ONLY_SUFFICIENT_IF_COUNT_10M; COVERAGE/PPA/STANDALONE_ACCURACY_SEPARATE' if a.count>=10000000 else 'PILOT_ONLY_MAIN_520M_NOT_RUN'}
    (OUT/f'{a.label}_summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result),flush=True)
