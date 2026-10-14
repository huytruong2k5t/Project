"""Audit isolated alignment candidate; do not replace the frozen production RTL."""
import hashlib
import json
from pathlib import Path
import re
import statistics

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'results/align_refactor_20261015'


def read(path):
    return path.read_text(encoding='utf-8-sig')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(read(path))


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')


def check_sources(mapping):
    for name, digest in mapping.items():
        assert sha(ROOT/name) == digest, ('Source changed', name)


def interface(path):
    s = read(path).split('    localparam int ADD_W', 1)[0]
    s = s[s.index('module '):].replace('posit_add_align_candidate', 'posit_add_align')
    return re.sub(r'\s+', '', re.sub(r'//[^\n]*', '', s))


before = ROOT/'rtl/posit_add_align.sv'
candidate = ROOT/'rtl/posit_add_align_candidate.sv'
assert sha(before) == sha(RUN/'before/posit_add_align.sv'), 'Production leaf changed'
assert interface(before) == interface(candidate), 'Ports/parameters/defaults changed'
assert read(candidate).split('    dyn_right_shifter #(',1)[1] == read(before).split('    dyn_right_shifter #(',1)[1].replace('End of posit_add_align.sv','End of posit_add_align_candidate.sv'), 'Shifter or special/output logic changed'
assert "lost_mask = shift_amount == '0 ? '0" in read(candidate)
assert "(word_t'(1) << shift_amount) - word_t'(1);" in read(candidate)

assert read(RUN/'modelsim/status.txt').strip() == 'COMPLETE'
matrix = load(RUN/'modelsim/summary.json')
assert matrix['status']=='PASS' and matrix['mismatches']==0 and len(matrix['profiles'])==11
assert matrix['checks']==823872
assert all(all(p[k]>0 for k in ['nar_zero','clamp','threshold','tie']) for p in matrix['profiles'])
check_sources(matrix['source_sha256'])
assert read(RUN/'lint/status.txt').strip()=='COMPLETE'
leaf_logs=list((RUN/'lint').glob('leaf_*.log'))
assert len(leaf_logs)==9 and all(not re.search(r'%Warning|%Error',read(p)) for p in leaf_logs)

assert read(RUN/'integration/status.txt').strip()=='COMPLETE'
integration=[]
for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
    folder=RUN/'integration'/f'{nb}_{es}'
    assert not re.search(r'%Warning|%Error',read(folder/'lint.log'))
    copied=read(folder/'src/posit_add_align.sv')
    assert copied==read(candidate).replace('module posit_add_align_candidate #(','module posit_add_align #(')
    for line in read(folder/'source.sha256').splitlines():
        digest,name=line.split(maxsplit=1)
        assert sha(folder/name)==digest, ('Integration source changed',nb,es,name)
    for stage in ['pilot']+(['trial'] if (nb,es)==(32,3) else []):
        report=load(folder/f'{stage}_summary.json')
        assert report['mismatches']==0 and report['completed']>= (1000000 if stage=='trial' else 50000)
        assert report['accepted']==report['completed']+report['reset_aborts']
        assert report['max_slots']==3 and report['reset_busy'] and report['reset_output_stall'] and report['long_stalls']
        assert report['L0_RNE_checks']==(0 if es==3 else report['accepted'])
        assert 'W10 HARNESS PASS' in read(folder/f'{stage}.log')
        integration.append(dict(stage=stage,**report))

assert read(RUN/'ppa/status.txt').strip()=='COMPLETE'
ppa=load(RUN/'ppa/summary.json')
assert ppa['status']=='MEASURED' and len(ppa['rows'])==6
check_sources(ppa['source_sha256'])
paths=[]
for row in ppa['rows']:
    folder=RUN/'ppa'/f"{row['variant']}_seed{row['seed']}"
    selected=read(before if row['variant']=='before' else candidate)
    assert read(folder/'src/posit_add_align.sv')==selected.replace('module posit_add_align_candidate #(','module posit_add_align #(')
    for name in ['dyn_right_shifter.sv','align_ppa_boundary.sv','align_ppa_top.sv','posit_mac.vh']:
        assert sha(folder/'src'/name)==sha(ROOT/'rtl'/name)
    fit=read(folder/'output_files/align.fit.summary')
    report=read(folder/'output_files/align.sta.rpt')
    assert int(re.search(r'Total combinational functions\s*:\s*([\d,]+)',fit)[1].replace(',',''))==row['LUT4']
    assert int(re.search(r'Total registers\s*:\s*([\d,]+)',fit)[1].replace(',',''))==row['registers']
    assert not re.search(r'inferred.*latch|latch.*inferred',read(folder/'output_files/align.map.rpt'),re.I)
    section=report.split("; Slow 1200mV 85C Model Setup: 'clk'",1)[1]
    top=[]
    for line in section.splitlines():
        fields=[x.strip() for x in line.strip().strip(';').split(';')]
        if len(fields)==8 and re.fullmatch(r'-?\d+\.\d+',fields[0]):
            top.append(dict(slack_ns=float(fields[0]),startpoint=fields[1],endpoint=fields[2],
                clock_skew_ns=float(fields[6]),data_delay_ns=float(fields[7])))
            if len(top)==10: break
    assert len(top)==10 and top[0]['slack_ns']==row['setup_wns_ns']
    corners=[]
    for model in ['Slow 1200mV 85C','Slow 1200mV 0C','Fast 1200mV 0C']:
        item={'model':model}
        for kind in ['Setup','Hold']:
            # Anchor the boxed report heading, not the table-of-contents occurrence.
            match=re.search(r';\s*'+re.escape(model)+rf' Model {kind} Summary.*?;\s*clk\s*;\s*(-?[\d.]+)\s*;\s*(-?[\d.]+)',report,re.S)
            assert match
            item[kind.lower()+'_wns_ns']=float(match[1]);item[kind.lower()+'_tns_ns']=float(match[2])
        assert item['hold_wns_ns']>=0, 'Hold failed'
        corners.append(item)
    paths.append(dict(variant=row['variant'],seed=row['seed'],timing_corners=corners,top10_setup=top))
dump(RUN/'ppa/critical_paths.json',paths)
old=[r for r in ppa['rows'] if r['variant']=='before']
new=[r for r in ppa['rows'] if r['variant']=='candidate']
assert {r['LUT4'] for r in old}=={404} and {r['LUT4'] for r in new}=={420}
assert {r['registers'] for r in ppa['rows']}=={163}
bmed=statistics.median(r['fmax_MHz'] for r in old)
cmed=statistics.median(r['fmax_MHz'] for r in new)
assert min(r['fmax_MHz'] for r in new)>max(r['fmax_MHz'] for r in old)
assert all(r['setup_wns_ns']<0 for r in ppa['rows']), 'Update reported 100MHz status'
sources=dict(matrix['source_sha256'],**ppa['source_sha256'])
for name in ['scripts/verify_align_refactor.sh','scripts/audit_align_refactor.py',
             'tb/week10_adder_harness.cpp','tb/week10_add_reference.hpp','tb/adder_verification_top.sv']:
    sources[name]=sha(ROOT/name)
summary=dict(status='PASS_ISOLATED_TRIAL',date='2026-10-15',production_replaced=False,
    interface='same parameter/default/port contract; candidate module name differs',
    unit_checks=matrix['checks'],unit_mismatches=0,strict_lint_leaf_profiles=9,
    strict_lint_integration_profiles=4,inferred_latches=0,
    integration_completed=sum(r['completed'] for r in integration),
    integration_reset_aborts=sum(r['reset_aborts'] for r in integration),
    integration_mismatches=0,integration=integration,
    benchmark=dict(device=ppa['device'],clock_ns=10,profile=ppa['profile'],
        lut4_before=404,lut4_candidate=420,lut4_increase_percent=(420-404)*100/404,
        registers_before=163,registers_candidate=163,
        median_fmax_before_MHz=bmed,median_fmax_candidate_MHz=cmed,
        fmax_gain_percent=(cmed-bmed)*100/bmed,
        median_setup_before_ns=statistics.median(r['setup_wns_ns'] for r in old),
        median_setup_candidate_ns=statistics.median(r['setup_wns_ns'] for r in new),
        meets_100MHz=False,hold_all_corners_pass=True,rows=ppa['rows']),
    source_sha256=sources,
    limits=['Known binary inputs; no formal exhaustive HDL equivalence proof',
        'One million ES3 trial plus four-format pilots; not replacement for full frozen NF/Gate3 regression',
        'LUT4 physical leaf benchmark with identical measurement banks, not whole adder/MAC or Xilinx LUT6',
        'No I/O-delay/board signoff or power measurement; all slow85 setup runs fail 10ns target',
        'Untimed cycle harness suppresses only ASSIGNDLY for project CK2Q; --timing strict lint has no waiver',
        'Typed constant fix for wide SF keeps all three measured candidate seeds identical to archived first trial'],
    commands=['powershell -NoProfile -File scripts/verify_align_refactor_modelsim.ps1',
        'bash scripts/verify_align_refactor.sh',
        'powershell -NoProfile -File scripts/run_align_refactor_ppa.ps1',
        'python scripts/audit_align_refactor.py'])
dump(RUN/'summary.json',summary)
print('PASS isolated alignment trial: unit=',summary['unit_checks'],'pipeline=',summary['integration_completed'],'mismatches=0')
print('PPA median Fmax',bmed,'->',cmed,'MHz; gain',summary['benchmark']['fmax_gain_percent'],'%; LUT4 404->420; 100MHz FAIL')
