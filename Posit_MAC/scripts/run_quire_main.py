#!/usr/bin/env python3
"""Run a default-only quire main as independent-seed, source-bound shards."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from types import SimpleNamespace
from verify_quire import OUT,run


def main():
    p=argparse.ArgumentParser();p.add_argument('--tag',required=True);p.add_argument('--label',required=True)
    p.add_argument('--total',type=int,default=10000000);p.add_argument('--shards',type=int,default=4)
    a=p.parse_args()
    if not a.label.replace('_','').isalnum() or a.shards<1 or a.total%a.shards:p.error('Simple label and evenly divisible total required')
    report=OUT/(a.label+'_summary.json')
    if report.exists():raise RuntimeError('Fresh label required')
    labels=[a.label+'_s'+str(i) for i in range(a.shards)]
    def shard(i):
        run(SimpleNamespace(tag=a.tag,label=labels[i],count=a.total//a.shards,fixed=True,seed=20261103+1009*i))
        return json.loads((OUT/(labels[i]+'.json')).read_text())
    with ThreadPoolExecutor(max_workers=a.shards) as pool:rows=list(pool.map(shard,range(a.shards)))
    assert len({r['seed'] for r in rows})==a.shards
    assert all(r['status']=='PASS' and r['mismatches']==0 and r['main_default_only'] for r in rows)
    assert all(r['accepted']==r['retired']+r['reset_aborted'] for r in rows)
    summary={'status':'PASS','mismatches':0,'main_mac_retired':sum(r['main_mac_retired'] for r in rows),
             'long_sequences':sum(r['long_sequences'] for r in rows),
             'capacity_sequences':sum(r['capacity_sequences'] for r in rows),
             'clear_sequences':sum(r['clear_sequences'] for r in rows),
             'seeds':[r['seed'] for r in rows],'shards':labels,'build_manifest':'build_'+a.tag+'.json',
             'claim':'Independent-seed default OPS1/n12 shards; directed/mixed preambles excluded from main_mac_retired'}
    assert summary['main_mac_retired']==a.total
    summary['main_volume_met']=a.total>=10000000
    summary['sequence_quota_met']=summary['long_sequences']>=10000 and summary['capacity_sequences']>=1
    report.write_text(json.dumps(summary,indent=2)+'\n')
    print('QUIRE_MAIN_PASS',summary)


if __name__=='__main__':main()
