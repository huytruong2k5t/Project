#!/usr/bin/env python3
"""Validate current coverage/unit/model/4-state evidence without upgrading AC01."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',required=True);a=ap.parse_args()
    root=Path(__file__).resolve().parents[1];out=(root/a.out).resolve()
    assert out.is_relative_to(root/'results')
    def read(name):return json.loads((out/name).read_text(encoding='utf-8-sig'))
    def guard(mapping):
        for p,h in mapping.items():assert sha(root/p).lower()==h.lower(),'Source drift: '+p
    coverage=read('coverage_summary.json');assert coverage['status']=='COVERAGE_PASS'
    guard(coverage['verification_support_sha256'])
    for p,h in coverage['evidence_sha256'].items():assert sha(out/p)==h,'Evidence drift: '+p
    guard(read('build_units.json')['source_sha256'])
    guard(read('ports_and_lint.json')['source_sha256'])
    guard(read('model_check_receipt.json')['source_sha256'])
    units=read('units.json');model=read('model_check.json');lint=read('ports_and_lint.json')
    assert units['status']==model['status']==lint['status']=='PASS'
    assert units['mismatches']==model['mismatches']==0
    ms=read('modelsim/manifest.json');guard(ms['sha256'])
    assert (out/'modelsim/verify/status.txt').read_text(encoding='utf-8-sig').strip()=='PASS'
    markers={}
    for k,token in [('adder','ADDER_REFACTOR_PASS'),('packer','PACKER_REFACTOR_PASS'),
                    ('core','SHARED_CORE_PASS'),('nf','MAC_REFACTOR_PASS'),('f','MAC_REFACTOR_PASS')]:
        p=out/f'modelsim/verify/{k}.log';body=p.read_text(errors='replace')
        assert '** Error:' not in body and '** Fatal:' not in body
        hits=[line.strip().removeprefix('# ').strip() for line in body.splitlines() if token in line]
        assert len(hits)==1,'Missing unique ModelSim PASS: '+k
        markers[k]={'marker':hits[0],'log_sha256':sha(p)}
    lock_audit=subprocess.run(['python3','-B','scripts/audit_current_locks.py','--frozen-only'],
                              cwd=root,check=True,capture_output=True,text=True)
    rtl_identity={}
    for v in json.loads((root/'releases/current.json').read_text())['versions']:
        m=json.loads((root/v['manifest']).read_text());different=[]
        for p,h in m['dut_source_sha256'].items():
            if p not in ['rtl/mac_nf.f','rtl/mac_f.f'] and sha(root/p)!=h:different.append(p)
        rtl_identity[v['variant']]={'locked_id':v['id'],'same_rtl_as_lock':not different,'different_paths':different}
    result={'status':'VERIFICATION_AND_COVERAGE_PASS_NOT_FINAL_ACCEPTANCE',
            'profile':coverage['profile'],'rtl_identity':rtl_identity,
            'frozen_source_lock_audit':lock_audit.stdout.splitlines(),
            'unit_component_comparisons':sum(units[k] for k in ['ops','ops_metadata','sac','sbm','accumulator','normalizer']),
            'model':model,'lint':{'modules':lint['active_modules'],'instances':lint['instances_checked'],'status':'PASS'},
            'coverage_summary_sha256':sha(out/'coverage_summary.json'),'modelsim':markers,
            'pilot_completed':sum(v['pilot_completed'] for v in coverage['variants'].values()),
            'instrumented_completed':sum(v['coverage_completed'] for v in coverage['variants'].values()),
            'minimum_near_cancellation_fraction':min(v['near_cancellation_min_fraction'] for v in coverage['variants'].values()),
            'minimum_regime_cell_per_point':min(v['minimum_regime_cell_per_point'] for v in coverage['variants'].values()),
            'main_10m_per_point_met':all(v['main_10m_per_point_met'] for v in coverage['variants'].values()),
            'main_regime_quota_met':all(v['regime_quota_4000_met'] for v in coverage['variants'].values()),
            'remaining':['52 x 10M AC01 and >=4000 regime samples/cell/point not completed by this pilot',
                         'AC03 paired accuracy and timing signoff remain separate'],
            'excluded_exploration':'matrix_* and the initial nf_f_coverage_20261105 exploration are not counted',
            'synthesis_run':False}
    evidence=['units.json','build_units.json','ports_and_lint.json','model_check.json','model_check_receipt.json',
              'modelsim/manifest.json','modelsim/verify/status.txt','coverage_summary.json']
    result['evidence_sha256']={p:sha(out/p) for p in evidence}
    (out/'verification_summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k in ['status','unit_component_comparisons',
          'pilot_completed','instrumented_completed','minimum_near_cancellation_fraction','minimum_regime_cell_per_point']},indent=2))


if __name__=='__main__':main()
