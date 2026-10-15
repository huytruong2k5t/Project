"""Source-bound equivalence, lint, integration and physical OPS benchmark audit."""
import hashlib
import json
import re
import statistics
from pathlib import Path
import audit_ops_refactor_nf as nf

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'results/ops_refactor_20261014'

def header(path):
    source=re.search(r'module ops_sel_comb\s*#\((.*?)\n\);',nf.read(path),re.S).group(1)
    return re.sub(r'\s+','',re.sub(r'//[^\n]*','',source))

old=RUN/'before/ops_sel_comb.sv'
new=ROOT/'rtl/multiplier/ops_sel_comb.sv'
assert header(old)==header(new), 'Public parameters or ports changed'
original=json.loads(nf.read(ROOT/'results/nf_coverage_20261014/completion.json'))
assert nf.sha(old)==original['core']['source_sha256']['rtl/ops_sel_comb.sv'], 'Incorrect reference RTL'
assert nf.read(RUN/'modelsim/run_status.txt').strip()=='COMPLETE'
matrix=json.loads(nf.read(RUN/'modelsim/summary.json'))
assert matrix['status']=='PASS' and matrix['mismatches']==0
assert matrix['fraction_pairs']==378 and len(matrix['profiles'])==382
assert matrix['feature_combinations']==4 and matrix['checks']==1334048
keys={(p['F'],p['FW']) for p in matrix['profiles']}
assert keys=={(f,w) for f in range(1,28) for w in range(1,f+1)}
for name,digest in matrix['source_sha256'].items():
    assert nf.sha(ROOT/name)==digest, ('Matrix source changed',name)
assert nf.read(RUN/'lint/status.txt').strip()=='COMPLETE'
lint=list((RUN/'lint').glob('*.log'))
assert len(lint)==399  # 378 pairs +20 feature/extra-width profiles +version.
assert all(not re.search(r'%Warning|%Error',nf.read(p)) for p in lint)
digest,name=nf.read(RUN/'lint/source.sha256').strip().split(maxsplit=1)
assert nf.sha(ROOT/name)==digest
ppa=json.loads(nf.read(RUN/'ppa/summary.json'))
assert ppa['status']=='PASS' and len(ppa['rows'])==6
assert nf.read(RUN/'ppa/status.txt').strip()=='COMPLETE'
for name,digest in ppa['source_sha256'].items():
    assert nf.sha(ROOT/name)==digest
assert all(r['registers']==151 and r['setup_wns_ns']>=0 for r in ppa['rows'])
paths=[]
for row in ppa['rows']:
    folder=RUN/'ppa'/f"{row['variant']}_seed{row['seed']}"
    report=nf.read(folder/'output_files/ops.sta.rpt')
    section=report.split("; Slow 1200mV 85C Model Setup: 'clk'",1)[1]
    top=[]
    for line in section.splitlines():
        fields=[x.strip() for x in line.strip().strip(';').split(';')]
        if len(fields)==8 and re.fullmatch(r'-?\d+\.\d+',fields[0]):
            top.append(dict(slack_ns=float(fields[0]),startpoint=fields[1],endpoint=fields[2],
                            data_delay_ns=float(fields[7])))
            if len(top)==10: break
    assert len(top)==10
    hold=re.search(r'Slow 1200mV 85C Model Hold Summary.*?;\s*clk\s*;\s*(-?[\d.]+)',report,re.S)
    assert hold and float(hold.group(1))>=0, 'Hold failed'
    corners=[]
    for model in ('Slow 1200mV 85C', 'Slow 1200mV 0C', 'Fast 1200mV 0C'):
        item={'model':model}
        for kind in ('Setup','Hold'):
            match=re.search(re.escape(model)+rf' Model {kind} Summary.*?;\s*clk\s*;\s*(-?[\d.]+)',report,re.S)
            assert match and float(match.group(1))>=0, (model,kind,'failed')
            item[kind.lower()+'_ns']=float(match.group(1))
        corners.append(item)
    assert not re.search(r'inferred.*latch|latch.*inferred',nf.read(folder/'output_files/ops.map.rpt'),re.I)
    paths.append(dict(variant=row['variant'],seed=row['seed'],hold_ns=float(hold.group(1)),
                      timing_corners=corners,top10_setup=top))
nf.dump(RUN/'ppa/critical_paths.json',paths)
nf.audit('final')
integration=json.loads(nf.read(RUN/'nf/summary.json'))
assert integration['completed']==10000000 and integration['mismatches']==0
assert json.loads(nf.read(RUN/'nf/32_3/acceptance_summary.json'))==json.loads(
    nf.read(ROOT/'results/nf_coverage_20261014/32_3/acceptance_summary.json')), 'NF counters changed'
before=[r for r in ppa['rows'] if r['variant']=='before']
after=[r for r in ppa['rows'] if r['variant']=='after']
bmed=statistics.median(r['fmax_MHz'] for r in before)
amed=statistics.median(r['fmax_MHz'] for r in after)
assert {r['LUT4'] for r in before}=={216}
assert {r['LUT4'] for r in after}=={196}
report=dict(status='PASS',date='2026-10-14',module='ops_sel_comb',public_interface='identical',
    source_before=nf.sha(old),source_after=nf.sha(new),
    equivalence_checks=matrix['checks'],width_pairs=378,feature_combinations=4,
    lint_profiles=398,lint_warnings=0,inferred_latches=0,
    nf_completed=integration['completed'],nf_mismatches=0,
    nf_counters_identical_before_after=True,
    modelsim_nf_completed=integration['modelsim_completed'],
    new_near_percent=integration['near_percent'],
    benchmark=dict(device=ppa['device'],profile=ppa['profile'],seeds=[1,2,3],
        LUT4_before=216,LUT4_after=196,LUT4_reduction_percent=100*(216-196)/216,
        registers_before=151,registers_after=151,
        median_fmax_before_MHz=bmed,median_fmax_after_MHz=amed,
        median_fmax_gain_percent=100*(amed/bmed-1),rows=ppa['rows']),
    mathematical_argument=[
        'Exact popcount receives every fraction bit unchanged.',
        'Approx popcount(high_prefix with masked low zeros) equals popcount(right_aligned_prefix).',
        'COUNT_W>=clog2(FRAC_MAX+1) prevents count overflow; strict < preserves tie-A.',
        'Prepared X equals old effective fraction; prepared Y equals hidden(W) OR effective fraction.',
        'Hidden insertion commutes with swapping because W/hidden are shared by A/B.',
        'Invalid-config candidates are zero; all metadata and modulo-SF_W addition preserve the old contract.',
        'Reduction OR equals the old OR fold; no-cut generate emits zero.'],
    limits=['Known 0/1 interface controls and data; no guaranteed behavior for X/Z configuration',
            'Small F<=5 fraction pairs exhaustive; large F directed/random, not 2^54 exhaustive or a formal HDL proof',
            'PPA is full-IO OPS benchmark on CycloneIV LUT4, not Xilinx LUT6 or full-MAC Fmax',
            'No production pipeline register or latency/II change; benchmark FF banks are measurement only',
            'Historical Gate2/NF source-bound audits intentionally reject current OPS hash; use preserved sources/reports for history and this checkpoint for current RTL'])
nf.dump(RUN/'summary.json',report)
print('OPS REFACTOR AUDIT PASS: interface identical;1,334,048 unit +10M NF mismatch=0;LUT4 -9.2593%;medianFmax +3.6362%')
