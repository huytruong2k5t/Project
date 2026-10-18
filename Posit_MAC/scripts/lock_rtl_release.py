"""Lock only the promoted bytes that passed the active file-list checks."""
from pathlib import Path
import json
import re

from audit_opt02c import R,O,collect,read,sha
from audit_rtl_release import validate


def main():
    path=R/'rtl/production_freeze.json'
    if path.exists():raise RuntimeError('Do not overwrite an existing lock')
    result=collect(require_complete=True)
    promotion=json.loads(read(O/'promotion.json'))
    selected=promotion['selected_variant']
    active=O/'active_checks'
    assert read(active/'status.txt').strip()=='COMPLETE'
    logs=list((active/'lint').glob('*.log'))
    assert len(logs)==37 and all(not re.search(r'%Warning|%Error',read(p)) for p in logs)
    active_smoke=json.loads(read(active/'nf_smoke/pilot_summary.json'))
    assert active_smoke==json.loads(read(O/'verify/candidate/nf/32_3/pilot_summary.json'))
    events=O/'active_event_v2'
    assert read(events/'status.txt').strip()=='COMPLETE'
    sources=json.loads(read(events/'source_sha256.json'))
    assert len(sources)==39
    for name,digest in sources.items():assert sha(R/name)==digest,name
    for name in ('corner_32_3.log','protocol_32_3.log'):
        text=read(events/name)
        assert 'W11 MODELSIM PASS' in text and not re.search(r'\*\*\s+(Error|Fatal):',text)
    assert 'W13_EVENT_PASS completed=8192 reset_aborts=24 mismatch=0 CK2Q=1ns' in read(events/'fused.log')
    files=(R/'rtl/production.f').read_text().splitlines()
    assert len(files)==38
    for name in files+['rtl/posit_mac.vh']:
        assert sha(R/name)==sha(O/'source'/selected/Path(name).name),name
    original=json.loads(read(O/'freeze.json'))
    model={name:sha(R/name) for name in original['verification_inputs']
           if name.startswith('l1/include/') or (name.startswith('tb/') and name.endswith('.hpp'))}
    controls=['rtl/production.f','scripts/rtl_paths.json','scripts/rtl_paths.tsv','scripts/week13_sources.txt',
              'syn/constraints/a35t_clock.xdc','syn/constraints/a35t_benchmark_100mhz.xdc']
    promotion['status']='PROMOTED_AND_ACTIVE_CHECKS_PASSED'
    (O/'promotion.json').write_text(json.dumps(promotion,indent=2)+'\n')
    manifest={'release_id':'POSIT_MAC_RTL_20261018_OPT02C','status':'LOCKED_FOR_W14',
       'selected_variant':selected,'production_files':files,
       'rtl_sha256':{name:sha(R/name) for name in files+['rtl/posit_mac.vh']},
       'model_sha256':model,'build_contract_sha256':{name:sha(R/name) for name in controls},
       'profiles':{'NF':'8/0,16/1,32/2,32/3; FW=min(F,12),N_MAX8,EXACT_EN=OPS_EN1; runtime exact/approx',
                   'F':'32/3 FW12 W32/Q29 approximate-only,EXACT_EN0,OPS_EN1'},
       'latency':{'NF':'14 stages; L_valid=q+12,H=q+13,II=q+14',
                  'F':'13 stages; L_valid=q+11,H=q+12,II=q+13','q':'max(1,actual iterations)'},
       'qualification':{'strict_active_lint_profiles':37,'nf_main_completed':10000000,
           'nf_modelsim_completed':111456,'nf_modelsim_reset_aborted':288,
           'active_nf_smoke_completed':20000,'active_nf_modelsim_completed':27864,
           'active_f_modelsim_completed':8192,'active_f_modelsim_reset_aborted':24,
           'f_smoke_completed':100000,'f_main_reused_completed':10000000,'mismatches':0,
           'NF_PPA':'3 matched A35T-C2 strategies vs production OPT03; 100MHz setup/hold met',
           'F_PPA':'1 A35T-C2 release check; not paired NF/F PPA'},
       'evidence':{'study':'results/opt02c_20261018','summary_sha256':sha(O/'summary.json'),
                   'promotion_sha256':sha(O/'promotion.json')},
       'limits':['Not W14 final per-n/AC04 acceptance or Gate4.',
                 'OOC budget; no higher-clock P&R or board frequency claim.',
                 'Defined-clock CDC/pre-freeze reset review done; detailed W14-00b RDC/interface review remains.',
                 'Do not change frozen RTL/L1/oracle/constraint to repair a failing W14 test; preserve failure and review a new release.']}
    validate(manifest)
    path.write_text(json.dumps(manifest,indent=2)+'\n',newline='\n')
    receipt={'status':'LOCKED_FOR_W14','release_id':manifest['release_id'],'manifest_sha256':sha(path),
             'root':'rtl/production_freeze.json','postpromotion_validation':'37 strict lint, active NF smoke + NF/F ModelSim passed'}
    (O/'lock_receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(receipt['release_id']+' LOCKED; source/model/constraint fingerprints recorded')


if __name__=='__main__':main()
