"""Close week12 only with source-bound oracle/model/coverage and real NF STA."""
import copy
import hashlib
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'results/week12'


def read(path):
    raw=path.read_bytes()
    return raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8-sig')


def load(path):return json.loads(read(path))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def dump(path,value):path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def check_manifest(path):
    count=0
    for line in read(path).splitlines():
        digest,name=line.split(maxsplit=1)
        if name.startswith('/mnt/c/'):item=Path('C:/'+name[7:])
        else:item=ROOT/name
        assert item.resolve().is_relative_to(ROOT.resolve()),('Out of project manifest',name)
        assert sha(item)==digest,('Hash mismatch',path,name)
        count+=1
    assert count>0


def check_coverage(report):
    assert report['status']=='PASS' and report['cases']==2208768 and report['W']==32
    assert report['mismatches']==report['F_W_F_ref_differences']==0
    assert len(report['crosses'])==256 and min(report['crosses'])>=4000
    assert report['min_cross']==min(report['crosses'])
    assert len(report['run_polarity'])==61 and min(report['run_polarity'])>=10000
    assert report['min_run_polarity']==min(report['run_polarity'])
    assert len(report['n_hits'])==9 and min(report['n_hits'])>=100000
    assert sum(report['n_hits'])==report['cases']
    assert len(report['popcount'])==6 and min(report['popcount'])>0
    assert len(report['iterations'])==9 and min(report['iterations'])>0
    assert sum(report['iterations'])==sum(report['popcount'])==report['cases']
    for when in ['before','after']:
        standalone=report[f'delta_{when}_standalone'];acc=report[f'delta_{when}_acc_mode']
        assert len(standalone)==len(acc)==5 and min(standalone+acc)>0
        assert sum(standalone+acc)==report[f'near_{when}']
        assert report[f'near_{when}']>=0.3*report['cases']
    assert report['borrow'] and report['tail'] and report['resets'] and report['acc_clr'] and report['acc_transactions']


for folder in ['oracle','window','coverage']:
    assert read(RUN/folder/'status.txt').strip()=='COMPLETE',folder
    assert read(RUN/folder/'linux_status.txt').strip()=='COMPLETE',folder
    check_manifest(RUN/folder/'source.sha256')
oracle=load(RUN/'oracle/linux.json')
assert oracle['status']=='PASS' and oracle['p8_exhaustive'] and oracle['p8_checked']==2**24
for platform in ['linux','windows','ubsan']:
    report=load(RUN/f'oracle/{platform}.json')
    assert report['mismatches']==0
    for key in ['p16_softposit_fma','p32_es2_softposit_fma','p32_es3_prepack_fullsum']:
        assert report[key]>=100000
pilots=[]
for width in [32,48,64,96]:
    p=load(RUN/f'window/pilot_{width}.json')
    assert p['W']==width and p['cases']==100000 and p['mismatches']==p['F_W_F_ref_bit_differences']==0
    assert p['corner_checks']==6402 and p['invalid_rejected']==6
    assert p['tie_even'] and p['tie_odd'] and p['borrow'] and p['sat_max'] and p['sat_min']
    pilots.append(p)
selection=load(RUN/'window/selection.json')
assert selection['W']==32==min(p['W'] for p in pilots)
window=load(RUN/'window/linux.json')
assert window['cases']==1000000 and window['mismatches']==0
for platform in ['windows','ubsan']:
    assert load(RUN/f'window/{platform}.json')==window,'Initial cross-platform model mismatch'
coverage=load(RUN/'coverage/linux.json')
check_coverage(coverage)
for platform in ['windows','ubsan']:
    assert load(RUN/f'coverage/{platform}.json')==coverage,'Stratified cross-platform mismatch'
check_manifest(RUN/'window/corpus.sha256')
check_manifest(RUN/'coverage/corpus.sha256')
assert sha(RUN/'window/fixtures/main.bin')==sha(RUN/'window/fixtures/windows.bin')
assert sha(RUN/'coverage/fixtures/main.bin')==sha(RUN/'coverage/fixtures/windows.bin')
assert (RUN/'coverage/fixtures/main.bin').stat().st_size==16*coverage['cases']
check_manifest(RUN/'window/trace_source.sha256')
trace=load(RUN/'window/python_trace.json')
assert trace['status']=='PASS' and trace['checked']==138 and trace['mismatches']==0 and trace['borrow_cases']
for line in read(RUN/'window/complete_trace.jsonl').splitlines():json.loads(line)
check_manifest(RUN/'accuracy/source.sha256')
accuracy=load(RUN/'coverage/accuracy.json')
assert accuracy['cases']==coverage['cases'] and accuracy['window_F_W_F_ref_bit_differences']==0
assert accuracy['product_approx_F_ref_vs_Ideal_same_F_Ceff_bit_differences']>0
ppa=load(RUN/'nf_ppa/summary.json')
assert ppa['status']=='MEASURED_POST_ROUTE' and len(ppa['rows'])==3
assert not ppa['meets_100MHz'] and ppa['unconstrained_setup_hold']==0
assert ppa['hold_recovery_removal_all_corners_pass']
for name,digest in ppa['source_sha256'].items():assert sha(ROOT/name)==digest
for r in ppa['rows']:
    assert r['DSP_9x9']==r['memory_bits']==0
    assert r['LUT4']==3926 and r['FF']==823 and r['arithmetic_mode_LE']==442
    assert all(c['setup_wns_ns']<0 for c in r['corners'][:1])
stages=load(RUN/'nf_ppa/stages.json')
assert len(stages)==27 and all(len(s['top10'])==10 for s in stages)
# No baseline RTL or frozen legacy L1 is rewritten by this week12 work.
frozen=load(ROOT/'results/l1_floor_rne_freeze/summary.json')
for name,digest in frozen['source_sha256'].items():assert sha(ROOT/name)==digest,('Frozen source changed',name)
current_nf=load(ROOT/'results/ops_refactor_20261014/summary.json')
assert current_nf['nf_completed']>=10000000 and current_nf['nf_mismatches']==0
assert current_nf['new_near_percent']>=30 and current_nf['modelsim_nf_completed']>0
assert sha(ROOT/'rtl/ops_sel_comb.sv')==current_nf['source_after']
for line in read(ROOT/'results/ops_refactor_20261014/nf/32_3/source.sha256').splitlines():
    digest,name=line.split(maxsplit=1)
    if Path(name).suffix in ['.sv','.vh']:
        live=ROOT/'rtl'/Path(name).name
        assert sha(live)==digest,('Production NF changed',live)
assert not (ROOT/'rtl/posit_mac_f.sv').exists(),'F RTL unexpectedly present before handoff'
contract=load(RUN/'contract.json');handoff=load(RUN/'handoff.json')
assert contract['profile']['FRAC_W']==12 and handoff['profile']['ACC_WIN']==32
assert len(handoff['stages'])==6 and handoff['latency_proposal']['H_handshake']=='q+12'
guards=[]
for case in ['mismatch','cross','near','n']:
    bad=copy.deepcopy(coverage)
    if case=='mismatch':bad['mismatches']=1
    if case=='cross':bad['crosses'][0]=3999
    if case=='near':bad['near_before']=0
    if case=='n':bad['n_hits'][0]=99999
    try:check_coverage(bad)
    except AssertionError:guards.append(dict(case=case,rejected=True))
    else:raise AssertionError(('Acceptance audit did not reject',case))
dump(RUN/'audit_guard_tests.json',guards)
source_names=set(ppa['source_sha256'])
source_names.update(p.relative_to(ROOT).as_posix() for p in (ROOT/'l1/include').glob('*.hpp'))
for folder,pattern in [('l1/test','*week12*'),('scripts','*week12*'),('tb','week12*')]:
    source_names.update(p.relative_to(ROOT).as_posix() for p in (ROOT/folder).glob(pattern) if p.is_file())
source_names.update(['l0/libsoftposit.so','l0/softposit.dll','l0/softposit_api.h',
    'tb/week11_model.hpp','tb/week11_fused_model.hpp','tb/week10_add_reference.hpp',
    'tb/week9_exact_reference.hpp','tb/nf_coverage_corpus.hpp'])
source_names.update('results/week12/'+p for p in ['contract.json','coverage_contract.json','handoff.json','pipeline_recommendations.json'])
sources={name:sha(ROOT/name) for name in sorted(source_names)}
binary_names=['oracle/bin/oracle','oracle/bin/oracle_ubsan','oracle/bin/oracle.exe',
    'window/bin/window','window/bin/window_ubsan','window/bin/window.exe',
    'coverage/bin/coverage','coverage/bin/coverage_ubsan','coverage/bin/coverage.exe']
assert 'v1.16' in read(ROOT/'SPEC_Posit_MAC_IP.md').split('### Lịch sử thay đổi',1)[0]
freeze=dict(status='G_F_L1_PASS_WEEK12',date='2026-10-15',revision='W12-F-1',spec_version='v1.16',
    profile=handoff['profile'],source_sha256=sources,
    binary_sha256={name:sha(RUN/name) for name in binary_names},
    corpus_sha256=dict(initial=sha(RUN/'window/fixtures/main.bin'),stratified=sha(RUN/'coverage/fixtures/main.bin')),
    scope='Selected L1 window/flags/state accepted; no F RTL, CDC/RDC, final accuracy or paired PPA acceptance')
dump(RUN/'freeze.json',freeze)
backup=load(RUN/'backup.json') if (RUN/'backup.json').exists() else None
if backup:
    assert backup['push_success'] and backup['branch']=='main' and backup['repository']=='https://github.com/huytruong2k5t/Project'
    assert re.fullmatch(r'[0-9a-f]{40}',backup['commit'])
milestones={f'W12-{i:02}':'complete within plan scope' for i in range(1,8)}
if not backup:milestones['W12-07']='technical handoff passed; final Git backup pending'
summary=dict(status='PASS_WEEK12_SCOPE' if backup else 'PASS_TECHNICAL_PENDING_BACKUP',date='2026-10-15',milestones=milestones,backup=backup,
    unchanged_NF_RTL=True,legacy_L1_unchanged=True,oracle=oracle,selected_window=32,
    window_pilots=[dict(W=p['W'],cases=p['cases'],mismatches=0) for p in pilots],
    initial_model_cases=1000000,selected_model_cases=coverage['cases'],platforms=['Linux','Windows','Linux UBSan'],
    mismatches=0,near_fraction=coverage['near_before']/coverage['cases'],
    min_regime_sign_cross=coverage['min_cross'],min_run_polarity=coverage['min_run_polarity'],
    accuracy_separation=accuracy,NF_post_route_median_fmax_MHz=ppa['median_fmax_MHz'],NF_meets_100MHz=False,
    next='Week13 F RTL using frozen W32 model; review five timing/LUT proposals before any NF retiming',
    limits=['Fused correctness is for the approximate P_hat, not exact original A*B+C',
        'Same-input bit differences are not mean/P99/relative-error accuracy; targeted cancellation corpus is not application distribution',
        'F RTL/reset/stall timing and final per-n/AC02/AC04 remain unimplemented/unrun',
        'Full NF setup100MHz fails on the measured CycloneIV; pipeline ideas are proposals only',
        'Current NF EXACT_EN1 PPA cannot be compared fairly against future F approximate-only without a validated matched NF configuration',
        'No TableI rerun, author RTL baseline, board/power or Gate4 claim'],
    commands=['bash scripts/verify_week12_oracle.sh','bash scripts/verify_week12_window.sh',
        'powershell -NoProfile -File scripts/verify_week12_windows.ps1',
        'bash scripts/verify_week12_coverage.sh','powershell -NoProfile -File scripts/verify_week12_coverage_windows.ps1',
        'bash scripts/verify_week12_accuracy.sh',
        './results/week12/accuracy/test_accuracy results/week12/coverage/fixtures/main.bin 2208768 results/week12/coverage/accuracy.json',
        'bash scripts/verify_week12_trace.sh','powershell -NoProfile -File scripts/run_week12_nf_ppa.ps1',
        'powershell -NoProfile -File scripts/survey_week12_nf_stages.ps1',
        'python scripts/collect_week12_nf.py','python scripts/audit_week12.py'])
dump(RUN/'summary.json',summary)
print(json.dumps({k:summary[k] for k in ['status','selected_window','selected_model_cases','mismatches',
    'near_fraction','min_regime_sign_cross','min_run_polarity','NF_post_route_median_fmax_MHz','NF_meets_100MHz']},indent=2))
