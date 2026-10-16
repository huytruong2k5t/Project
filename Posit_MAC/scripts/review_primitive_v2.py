"""Matched-strategy review; this file reports evidence and never promotes RTL."""
from pathlib import Path
from collections import defaultdict
from statistics import median
import csv,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'
groups=defaultdict(dict)
for part in ('xc7a35tcpg236-1','xc7a100tcsg324-1'):
  for phase in ('confirm','release','adoption'):
    path=OUT/part/phase/'metrics.csv'
    if not path.exists():continue
    for r in csv.DictReader(path.open()):
        key=tuple(r[x] for x in ('n','kind','mode','arith','fill','shift_w'))
        groups[(part,key,r['variant'])][r['strategy']]=r
rows=[]
for (part,key,v),data in groups.items():
    if v=='baseline':continue
    baseline=groups.get((part,key,'baseline'),{})
    if set(data)!=set(('default','explore','runtime')) or set(baseline)!=set(data):continue
    pairs=[]
    for strategy in ('default','explore','runtime'):
        b=baseline[strategy];c=data[strategy]
        pairs.append(dict(strategy=strategy,sta_gain_pct=100*((5-float(b['slack']))/(5-float(c['slack']))-1),
            lut_change_pct=100*(int(c['lut'])/int(b['lut'])-1),baseline_lut=int(b['lut']),candidate_lut=int(c['lut']),
            baseline_ff=int(b['ff']),candidate_ff=int(c['ff']),baseline_slack=float(b['slack']),candidate_slack=float(c['slack']),hold=float(c['hold'])))
    rows.append(dict(part=part,variant=v,**{k:int(val) for k,val in zip(('n','kind','mode','arith','fill','shift_w'),key)},
        median_matched_gain_pct=median(x['sta_gain_pct'] for x in pairs),
        min_matched_gain_pct=min(x['sta_gain_pct'] for x in pairs),
        median_lut_change_pct=median(x['lut_change_pct'] for x in pairs),
        max_lut_change_pct=max(x['lut_change_pct'] for x in pairs),
        hold_min=min(x['hold'] for x in pairs),pairs=pairs))
report=dict(status='REVIEW_ONLY',script_modifies_production=False,rows=rows,
    note='Matched ratios complement median/min/max absolute STA estimates. No automatic production choice; all completed strategies, both parts and relevant chains must be considered.')
(OUT/'review.json').write_text(json.dumps(report,indent=2)+'\n')
if rows:
    with (OUT/'review.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=[k for k in rows[0] if k!='pairs']);w.writeheader();w.writerows({k:v for k,v in r.items() if k!='pairs'} for r in rows)
print('Complete matched candidate/part groups:',len(rows))
