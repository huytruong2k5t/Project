#!/usr/bin/env python3
"""Merge identical elaborations; report raw counters, reviewed waivers and gaps."""
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def required_bins(kind):
    required=[]
    required += [f'config/ops{o}/n{n}' for o in range(2) for n in range(13)]
    required += [f'iterations/{n}' for n in range(13)]
    required += ['iterations/early_stop','iterations/limit_reached']
    required += [f'popcount/{p}/{i}' for p in ['a','b'] for i in range(6)]
    required += ['ops/tie_a','ops/keep_a','ops/swap_b']
    required += [f'corner/{p}/{i}' for p in ['a','b','c'] for i in range(8)]
    required += ['corner/nar_times_zero','corner/zero_times_nar','corner/zero_product_nonzero_c']
    required += ['scenario/'+s for s in ['standalone','feedback','clear_feedback','chain_gt12']]
    required += ['protocol/'+s for s in ['reset_idle','reset_busy','reset_output_stall','input_stall',
                                        'output_stall','output_stall_ge32','invalid_rejected','drain_empty',
                                        'context_changed_after_accept','input_bubble']]
    required += [f'cut/{i}' for i in range(4)]
    required += [f'near/delta/{i}' for i in range(5)] + ['near/standalone','near/feedback','arithmetic/exact_cancellation']
    required += [f'flags/{i}' for i in ([0,2,3,6,7,10,11,16] if kind=='f' else [0,2,3,6,7,10,11,14,15,16])]
    required += [f'pipeline/pack/special/{i}' for i in (range(5) if kind=='f' else range(4))]
    required += [f'pipeline/pack/grs/{i}' for i in range(8)]
    required += ['pipeline/pack/'+s for s in ['tie_even','tie_odd','round_up','round_down']]
    required += [f'pipeline/add/shift/{i}' for i in range(32)]
    required += ['pipeline/add/'+s for s in ['clamped','unclamped','sub','add']]
    required += [f'pipeline/add/lzc/{i}' for i in range(29)]
    required += [f'regime/{i}' for i in range(256)]
    required += [f'run/{polarity}/{run}' for polarity in range(2) for run in range(1,31+polarity)]
    return required


def read_counters(path):
    counters={}
    for line in path.read_text().splitlines():
        if not line.startswith('C '):continue
        key=line.split("'",2)[1]
        fields=dict(token.split('\x02',1) for token in key.split('\x01') if '\x02' in token)
        f=fields.get('f','').replace('\\','/')
        if '/rtl/' not in f:continue # verification scaffolding is not DUT coverage
        category=fields.get('page','').split('/')[0]
        if category not in {'v_line','v_branch','v_toggle'}:continue
        fields['source']='rtl/'+f.rsplit('/rtl/',1)[1]
        counters[key]=(fields,int(line.rsplit(' ',1)[1]))
    assert {v[0]['page'].split('/')[0] for v in counters.values()}=={'v_line','v_branch','v_toggle'},path
    return counters


def structural(root,out,kind,raws):
    combined={}
    for p in raws:
        data=read_counters(p)
        if combined:assert set(combined)==set(data),'Cannot merge different elaborations'
        for key,(fields,count) in data.items():
            combined.setdefault(key,[fields,0])[1]+=count
    waivers_path=root/'tests/nf_f_coverage_waivers.json'
    waivers=json.loads(waivers_path.read_text()) if waivers_path.exists() else []
    waiver_by_id={w['id']:w for w in waivers if w['variant']==kind}
    assert len(waiver_by_id)==sum(w['variant']==kind for w in waivers),'duplicate waiver'
    raw=defaultdict(lambda:[0,0]);adjusted=defaultdict(lambda:[0,0]);misses=[];applied=[];used=set()
    for key,(fields,count) in combined.items():
        cat=fields['page'].split('/')[0];raw[cat][0]+=bool(count);raw[cat][1]+=1
        point_id=hashlib.sha256(key.encode()).hexdigest()
        if point_id in waiver_by_id:
            w=waiver_by_id[point_id];used.add(point_id)
            assert w['reason'] and w['proof'] and w['source']==fields['source']
            assert w['source_sha256']==sha(root/w['source']),'stale waiver'
            assert not count,'Waived point became reachable; remove waiver'
            applied.append(w);continue
        adjusted[cat][0]+=bool(count);adjusted[cat][1]+=1
        if not count:
            source=root/fields['source'];lines=source.read_text().splitlines()
            lineno=int(fields.get('l','0'))
            misses.append({'id':point_id,'variant':kind,**fields,'source_sha256':sha(source),
                           'code':lines[lineno-1] if 1<=lineno<=len(lines) else ''})
    assert used==set(waiver_by_id),'waiver does not match this elaboration'
    thresholds={'v_line':95,'v_branch':90,'v_toggle':85}
    def metrics(counts):
        # Verilator's line analysis instruments control-flow basic blocks.
        # Branch-arm blocks (page v_branch) also belong in the line denominator;
        # reporting only the nonbranch v_line page would overstate raw line hit.
        counts={k:list(v) for k,v in counts.items()}
        counts['v_line']=[counts['v_line'][i]+counts['v_branch'][i] for i in range(2)]
        return {k:{'hit':v[0],'total':v[1],'percent':100*v[0]/v[1],
                   'threshold_percent':thresholds[k],'met':100*v[0]/v[1]>=thresholds[k]}
                for k,v in sorted(counts.items())}
    (out/f'unhit_{kind}.json').write_text(json.dumps(misses,indent=2)+'\n')
    return {'raw':metrics(raw),'reviewed':metrics(adjusted),'waivers':applied,
            'all_thresholds_met':all(v['met'] for v in metrics(adjusted).values()),
            'denominator':'DUT RTL counters; Verilator-compressed hierarchy; line includes v_line + v_branch control-flow blocks; branch uses v_branch; toggle uses nonzero edge counters; union of identical per-variant builds',
            'unhit_report':f'unhit_{kind}.json'}


def report(root,out,label,count,seed,pilot_label=None,pilot_count=100000):
    variants={};evidence={}
    for kind in ['nf','f']:
        manifest_path=out/f'build_{kind}.json';manifest=json.loads(manifest_path.read_text())
        for p,h in manifest['source_sha256'].items():assert sha(root/p)==h,'Live source drift: '+p
        evidence[manifest_path.name]=sha(manifest_path)
        hits=Counter();rs=[];raws=[]
        for ops in range(2):
            for n in range(13):
                p=out/f'{label}_{kind}_ops{ops}_n{n}.json'
                r=json.loads(p.read_text());rs.append(r)
                assert r['status']=='PASS' and r['mismatches']==0 and r['completed']==count
                assert r['fixed_n']==n and r['fixed_ops']==ops and r['seed']==seed
                assert r['accepted']==r['completed']+r['reset_aborted']
                assert r['bins'][ops*13+n]==count and sum(r['bins'])==count
                assert not any(r['iterations'][n+1:])
                hits.update(r['functional_coverage']['hits'])
                hits.update({f'regime/{i}':c for i,c in enumerate(r['regime_bins'])})
                hits.update({f'run/{i//32}/{i%32}':c for i,c in enumerate(r['run_polarity'])})
                raw=Path(str(p)+'.dat');raws.append(raw)
                evidence[p.name]=sha(p);evidence[raw.name]=sha(raw);evidence[p.with_suffix('.log').name]=sha(p.with_suffix('.log'))
        pilot=[]
        if pilot_label:
            mp=out/f'fast_build_{kind}.json';fm=json.loads(mp.read_text())
            for p,h in fm['source_sha256'].items():assert sha(root/p)==h,'Fast build source drift: '+p
            assert not fm['coverage_enabled']
            assert fm['source_sha256']==manifest['source_sha256'],'Fast and coverage builds have different sources'
            evidence[mp.name]=sha(mp)
            for ops in range(2):
                for n in range(13):
                    p=out/f'{pilot_label}_{kind}_ops{ops}_n{n}.json';r=json.loads(p.read_text());pilot.append(r)
                    assert r['status']=='PASS' and r['mismatches']==0 and r['completed']==pilot_count
                    assert r['seed']==seed and r['fixed_n']==n and r['fixed_ops']==ops
                    assert r['accepted']==r['completed']+r['reset_aborted']
                    assert r['bins'][ops*13+n]==pilot_count and sum(r['bins'])==pilot_count
                    assert not any(r['iterations'][n+1:])
                    hits.update(r['functional_coverage']['hits'])
                    hits.update({f'regime/{i}':c for i,c in enumerate(r['regime_bins'])})
                    hits.update({f'run/{i//32}/{i%32}':c for i,c in enumerate(r['run_polarity'])})
                    evidence[p.name]=sha(p);evidence[p.with_suffix('.log').name]=sha(p.with_suffix('.log'))
        acceptance=pilot or rs;acceptance_count=pilot_count if pilot else count
        required=required_bins(kind);missing=[b for b in required if not hits[b]]
        structure=structural(root,out,kind,raws)
        variants[kind]={'coverage_completed':sum(r['completed'] for r in rs),
            'pilot_completed':sum(r['completed'] for r in pilot),
            'completed':sum(r['completed'] for r in rs+pilot),'reset_aborted':sum(r['reset_aborted'] for r in rs+pilot),
            'mismatches':0,'functional':{'required_bins':len(required),'hit_bins':len(required)-len(missing),
                'percent':100*(len(required)-len(missing))/len(required),'missing':missing,
                'hits':dict(sorted(hits.items())),'all_required_bins_met':not missing},'structural':structure,
            'controls_per_point_met':all(r['standalone']>=acceptance_count*.1 and r['accumulation']>=acceptance_count*.1 for r in acceptance),
            'near_cancellation_min_fraction':min(r['near_cancellation']/acceptance_count for r in acceptance),
            'minimum_regime_cell_per_point':min(min(r['regime_bins']) for r in acceptance),
            'regime_quota_4000_met':all(min(r['regime_bins'])>=4000 for r in acceptance),
            'run_polarity_quota_10000_met':all(hits[b]>=10000 for b in required if b.startswith('run/')),
            'main_10m_per_point_met':acceptance_count>=10000000}
    coverage_met=all(v['functional']['all_required_bins_met'] and v['structural']['all_thresholds_met']
                     and v['controls_per_point_met'] and v['near_cancellation_min_fraction']>=.30
                     for v in variants.values())
    result={'status':'COVERAGE_PASS' if coverage_met else 'COVERAGE_OPEN','profile':'POSIT32_ES3_APPROX12_FULL_TERM26_Q24_RNE',
            'seed':seed,'points':52,'coverage_count_per_point':count,'pilot_count_per_point':pilot_count if pilot_label else 0,
            'variants':variants,'evidence_sha256':evidence,
            'spec':'docs/SPEC_Posit_MAC_IP.md','spec_sha256':sha(root/'docs/SPEC_Posit_MAC_IP.md'),
            'verification_support_sha256':{p:sha(root/p) for p in ['scripts/verify_nf_f_coverage.py',
                'scripts/report_nf_f_coverage.py','tests/nf_f_coverage.md','tests/nf_f_coverage_waivers.json']},
            'limits':['AC01 main volume, per-point regime quotas and AC03 accuracy are separate from this coverage gate.',
                      'Transaction bins count retired transactions; pipeline bins count valid/ready samples, including later aborts.',
                      'No synthesis, route, or 4-state signoff is implied by Verilator coverage.']}
    (out/'coverage_summary.json').write_text(json.dumps(result,indent=2)+'\n')
    lines=['# NF/F coverage — 05/11/2026','',f'Status: **{result["status"]}**. Posit(32,3), FW12/FULL_TERM26/Q24/RNE.',
           f'Instrumented: {52*count:,} completed / 52 points. Fast pilot: {52*pilot_count if pilot_label else 0:,} completed. Seed {seed}; zero mismatches.','',
           '| Variant | Functional | Raw line | Raw branch | Raw toggle | Reviewed line/branch/toggle |',
           '|---|---:|---:|---:|---:|---|']
    for kind,v in variants.items():
        s=v['structural'];m=s['raw'];r=s['reviewed'];f=v['functional']
        lines.append(f'| {kind.upper()} | {f["hit_bins"]}/{f["required_bins"]} | '+
                     ' | '.join(f'{m[k]["percent"]:.3f}%' for k in ['v_line','v_branch','v_toggle'])+' | '+
                     ' / '.join(f'{r[k]["percent"]:.3f}%' for k in ['v_line','v_branch','v_toggle'])+' |')
        print(kind,'functional',f['hit_bins'],f['required_bins'],'structural', {k:round(x['percent'],3) for k,x in r.items()},'missing',f['missing'],flush=True)
    lines += ['', 'Thresholds: line >=95%, branch >=90%, toggle >=85%; functional 100% of the declared legal-bin plan.',
              'Raw counters and source-bound waiver reasons remain in coverage_summary.json; unhit points are listed separately.',
              '', 'This does not close AC01 52 x 10M, regime quota >=4000/cell/point, AC03 paired accuracy or post-route timing.',
              'No RTL arithmetic or existing release manifests were changed.']
    (out/'README.md').write_text('\n'.join(lines)+'\n')
    print('NF_F_COVERAGE',result['status'],flush=True)
    return result
