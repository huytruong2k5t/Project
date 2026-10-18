"""Source-bound AC04 addendum; retain raw metrics and every unexcluded hole."""
from collections import Counter,defaultdict
from pathlib import Path
import json
from audit_week14 import R,O,sha,load,inputs
from rtl_paths import rtl_source


def dump(path,obj):path.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')


def structural(paths,exclude=()):
    points=Counter()
    for p in paths:
        for row in p.read_text().splitlines():
            if not row.startswith("C '"):continue
            raw,count=row[3:].rsplit("' ",1)
            fields=dict(x.split('\x02',1) for x in raw.split('\x01') if '\x02' in x)
            if fields['f'].startswith('src/rtl/'):points[raw]+=int(count)
    raw=defaultdict(list);adjusted=defaultdict(list);holes=[];excluded=[]
    for key,count in points.items():
        f=dict(x.split('\x02',1) for x in key.split('\x01') if '\x02' in x)
        kind=f['page'].split('/')[0];raw[kind].append(count)
        identity=(Path(f['f']).name,int(f['l']),f.get('o'))
        if kind=='v_branch' and identity in exclude:
            assert count==0
            excluded.append(dict(point=f,count=count));continue
        adjusted[kind].append(count)
        if not count:holes.append(dict(kind=kind,point=f))
    def metric(table):return {k:dict(hit=sum(v>0 for v in ns),total=len(ns),percent=100*sum(v>0 for v in ns)/len(ns)) for k,ns in table.items()}
    return dict(raw=metric(raw),reviewed=metric(adjusted),excluded=excluded,remaining_unhit=holes,
                evidence_sha256={p.relative_to(R).as_posix():sha(p) for p in paths})


def sum_array(rows,key):return [sum(values) for values in zip(*(r[key] for r in rows))]


def main():
    inputs();c=O/'closure';n=O/'nf_carry'
    assert (c/'status.txt').read_text().strip()==(n/'status.txt').read_text().strip()=='COMPLETE'
    for folder in (c,n):
        plan=load(folder/'plan.json')
        for name,digest in plan['source_sha256'].items():assert sha(folder/name)==digest
    # Only constant control and a two-state tautology are removed. In particular,
    # every internal ready/stall hole stays in the branch denominator.
    ops=rtl_source('ops_sel_comb.sv');fused=rtl_source('fused_add_pipe.sv');wrapper=rtl_source('mac_f_wrapper.sv')
    assert 'if (cfg_mode)' in ops.read_text().splitlines()[124]
    assert 'end else if (meta_sync2)' in fused.read_text().splitlines()[248]
    assert '.cfg_mode (MODE_APPROX)' in wrapper.read_text() and "MODE_APPROX = 1'b1" in wrapper.read_text()
    proofs=[dict(file=str(ops.relative_to(R)),line=125,branch='else',source_sha256=sha(ops),
        reason='F wrapper wires cfg_mode to localparam MODE_APPROX=1; exact branch cannot execute under any external config.',
        context_source_sha256=sha(wrapper)),
        dict(file=str(fused.relative_to(R)),line=249,branch='else',source_sha256=sha(fused),
        reason='if(!meta_sync2) ... else if(meta_sync2): final else requires X/Z, impossible in two-state Verilator. Four-state reset/startup tested separately in ModelSim; no general X-safety claim.')]
    fpaths=sorted((O/'coverage_final').glob('*/result.coverage.dat'))+[c/f'f_ops{i}.coverage.dat' for i in (0,1)]
    assert len(fpaths)==11
    profiles={'F32_3':structural(fpaths,{('ops_sel_comb.sv',125,'else'),('fused_add_pipe.sv',249,'else')})}
    nf_functional={}
    required=[(0,1,0)]+[(0,0,i) for i in (2,3,4,5,6)]
    required += [(1,1,i) for i in (0,1)]+[(1,0,i) for i in (1,2,3,4,5)]
    required += [(d,s,k) for d in (2,3) for s in (0,1) for k in ((0,1) if s else (1,2))]
    required += [(4,1,1),(4,0,1),(4,0,2)]
    valid={d*14+s*7+k for d,s,k in required};assert len(valid)==24
    for es in (3,2):
        name=f'nf32_{es}';rows=[load(c/f'{name}_summary.json'),load(n/f'{name}_summary.json')]
        for row in rows:
            assert row['mismatches']==0 and row['accepted']==row['completed']+row['reset_aborts']
            assert row['oracle_checks']==row['accepted']
        bins=sum_array(rows,'adder_bins');assert all(bins[i] for i in valid)
        assert all(v==0 for i,v in enumerate(bins) if i not in valid)
        for k in ('bins','regime_sign_bins','popcount_bins','flag_bins','product_packer_bins','near_delta_standalone_acc'):
            assert min(sum_array(rows,k))>0,k
        runs=sum_array(rows,'run_polarity_bins');run_valid=[i for i in range(64) if i not in (0,31,32)]
        assert all(runs[i]>0 for i in run_valid) and all(runs[i]==0 for i in (0,31,32))
        iterations=sum_array(rows,'iteration_mode_bins');assert all(iterations[:13]) and iterations[13]==0
        pack=sum_array(rows,'final_packer_bins');assert all(v for i,v in enumerate(pack) if i!=5) and pack[5]==0
        profiles['NF32_'+str(es)]=structural([c/f'{name}_coverage.dat',n/f'{name}_coverage.dat'])
        nf_functional[name]=dict(config_control='72/72',regime_sign='256/256',run_polarity='61/61',
            popcount='6/6',flags='5/5',iteration_mode='13/13',adder='24/24',product_packer='7/7',final_packer='6/6',
            adder_counts=bins,valid_adder_indices=sorted(valid),unreachable_adder_indices=sorted(set(range(70))-valid))
    for name,profile in profiles.items():
        for kind,limit in [('v_line',95),('v_branch',90),('v_toggle',85)]:
            assert profile['reviewed'][kind]['percent']>=limit,(name,kind,profile['reviewed'][kind])
    frows=[load(p/'result.json') for p in sorted((O/'coverage_final').iterdir())]
    for k in ('regime_sign_cross','run_polarity','popcount','delta_before_mode','delta_after_mode','flags'):
        assert min(sum_array(frows,k))>0,k
    cfg=sum_array(frows,'config_hits');assert all(cfg[n+9+18*a]>0 for n in range(9) for a in (0,1))
    assert all(sum_array(frows,'n_hits')) and all(sum_array(frows,'iterations'))
    fcross=[load(p/'result.functional.json') for p in sorted((O/'coverage_final').iterdir())]
    fcross += [load(c/f'f_ops{i}.functional.json') for i in (0,1)]
    hits=sum_array(fcross,'anchor_sign_delta_lzc');policy=load(c/'plan.json');legal=set(policy['fused_legal'])
    assert len(legal)==34 and all(hits[i] for i in legal)
    assert all(v==0 for i,v in enumerate(hits) if i not in legal)
    pack=[load(c/f'f_ops{i}.json')['packer_bins'] for i in (0,1)]
    assert all(sum(v) for v in zip(*pack))
    evidence=dict(status='PASS',parent_matrix_sha256=sha(O/'matrix_freeze.json'),profiles=profiles,
        producer_sha256=sha(Path(__file__)),branch_proofs=proofs,
        nf_functional=nf_functional,
        nf_reachability_proof=dict(adder='d0 same-sign always carries; d1..F same-sign may carry or stay; >F cannot carry. d0 opposite has at least1 LZ or exactzero; d1 opposite may stay or left-normalize; d>=2 opposite stays or LZ1 only.',
            run='Nonzero regime length >=1; allzero code excluded, positive regime max31, negative-polarity max30.',
            iteration='Approx n<=8 so bucket>8 unreachable; exact allows all seven buckets.',
            final_sat_min='Both final NF operands are Posit integer multiples of global minpos; a nonzero sum cannot lie below minpos. Product pack underflow is tested separately.'),
        fused_functional=dict(cross='34/34',cross_counts=hits,valid_indices=sorted(legal),
            excluded_indices=policy['fused_excluded'],packer='7/7',packer_counts=[sum(v) for v in zip(*pack)],
            regime_sign='256/256',run_polarity='61/61',popcount='6/6',n='9/9',iteration='9/9',
            config='18/18 main OPS1; OPS0 also exercised by separate directed suite',flags='5/5',delta_mode='10/10 before and after'),
        excluded_functional_review='Mathematical/source-domain mask, never merely unhit. All legal bins have observed witnesses. Original unresolved policy and raw reports retained.',
        scope='AC04 for main NF32/3, NF32/2 EXACT_EN1 and F32/3 profiles, full active RTL hierarchy, final full instrumentation only; no coverage_off.',
        comparator_diagnostic=structural([c/'ex0_final_coverage.dat']),
        limitations=['EX0 comparator full coverage diagnostic is reported separately; AC04 main profile closure does not claim exact-disabled derivative toggle closure.',
                     'Verilator two-state structural coverage; ModelSim companion validates reset/startup and CK2Q separately.',
                     'No formal universal proof or full exact AC02 claim.'])
    dump(O/'coverage_closure.json',evidence)
    print('W14 COVERAGE PASS NF32/3 NF32/2 F32/3; functional100%; two proved F branch exclusions, all other holes retained')


if __name__=='__main__':main()
