"""Prepare default-strategy post-route checks; no tool installation or model edits."""
from pathlib import Path
import csv
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'
template=(ROOT/'tb/templates/tb_primitive_v2_netlist.sv.in').read_text()
cases=[]
for part in ('xc7a35tcpg236-1','xc7a100tcsg324-1'):
  for phase in ('confirm','release','adoption'):
    file=OUT/f'{part}/{phase}/metrics.csv'
    if not file.exists():continue
    for row in csv.DictReader(file.open()):
        if row['strategy']!='default':continue
        folder=file.parent/row['id'];net=folder/'functional_netlist.v'
        if not net.exists():continue
        text=template
        for k,field in [('N','n'),('KIND','kind'),('MODE','mode'),('ARITH','arith'),('FILL','fill'),('SW','shift_w')]:
            text=text.replace('@'+k+'@',row[field])
        run=folder/'netlist_check';run.mkdir(exist_ok=True)
        (run/'tb_primitive_v2_netlist.sv').write_text(text,newline='\n')
        cases.append(run.relative_to(ROOT).as_posix())
(OUT/'netlist_cases.json').write_text(json.dumps(cases,indent=2)+'\n')
print('Prepared',len(cases),'post-route functional/latency checks')
