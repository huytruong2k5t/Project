"""Audit the requested adjacent stages from exactly one whole-MAC routed run."""
from pathlib import Path
import csv
import hashlib
import json
import re
import zipfile

R=Path(__file__).resolve().parents[1]
O=R/'results/single_a35_packer_20261017'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
log=(O/'vivado.log').read_text(encoding='utf-8',errors='replace')
counts={phase:len(re.findall(r'^Command: '+phase+r'\b',log,re.M)) for phase in ['synth_design','place_design','route_design']}
assert counts==dict(synth_design=1,place_design=1,route_design=1),counts
with (O/'stages.csv').open() as f:rows=list(csv.DictReader(f))
required=['whole_mac','before_product_p1_acc','product_p1','after_product_p1_p2','product_parse']
assert [r['group'] for r in rows[:5]]==required
for row in rows:
    row['register_count']=int(row['register_count']);row['levels']=int(row['levels'])
    for k in ['setup_slack_ns','hold_slack_ns','data_delay_ns','logic_delay_ns','route_delay_ns']:row[k]=float(row[k])
    assert row['register_count']>0 and row['hold_slack_ns']>=0
    for typ in ['setup','hold']:
        text=(O/f"{row['group']}_{typ}.rpt").read_text()
        assert 'Design State : Routed' in text
for name,digest in json.loads((O/'source_sha256.json').read_text(encoding='utf-8-sig')).items():
    p=O/('source' if name.startswith('rtl/') else 'driver')/Path(name).name
    assert sha(p)==digest,name
    if name.startswith('rtl/'):
        assert sha(R/name)==digest,name
        assert p.read_bytes()==(R/'results/opt03_20261017/source/candidate'/p.name).read_bytes(),name
errors=re.findall(r'^ERROR:.*$',log,re.M)
aux_failure='Empty target group: before_final_p1_a3' in log
if aux_failure:
    assert len(rows)==5 and all('Empty target group: before_final_p1_a3' in x for x in errors),errors
    if not errors:errors=['Tcl runtime error: Empty target group: before_final_p1_a3 (optional final-packer report, after requested reports)']
else:
    assert not errors and (O/'status.txt').read_text().strip()=='COMPLETE'
util=(O/'utilization.rpt').read_text()
resource={k:int(re.search(pattern,util)[1]) for k,pattern in {
    'LUT':r'\| Slice LUTs\s*\|\s*([0-9]+)',
    'FF':r'\| Slice Registers\s*\|\s*([0-9]+)'}.items()}
route=(O/'route.rpt').read_text()
count=lambda label:int(re.search(label+r'\.*\s*:\s*(\d+)',route)[1])
assert count('# of routable nets')==count('# of fully routed nets')
assert count('# of nets with routing errors')==0
summary=dict(status='PASS_REQUESTED_SCOPE',part='xc7a35tcpg236-1',profile='NF32/3 FW12 EXACT_EN1 OPS_EN1',
    clock_ns=10.0,uncertainty_ns=0.1,directive='Default',phase_counts=counts,
    RTL_changed=False,simulation_runs=0,stages=rows,resources=resource,
    sta_estimate_mhz=1000/(10-rows[0]['setup_slack_ns']),
    auxiliary_report_error=errors,
    limitations=['One OOC whole-MAC P&R run, not a sweep/median or board signoff',
        'No retiming or new functional verification; RTL bytes match tested OPT-03',
        'No assumption that positive slack can be transferred unchanged between stages'])
(O/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,indent=2))
print('SINGLE_A35_REQUESTED_SCOPE_PASS')
