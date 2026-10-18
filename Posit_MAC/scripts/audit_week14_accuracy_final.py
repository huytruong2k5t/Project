"""Check Fraction calibration and confidence intervals for the paired final corpus."""
from fractions import Fraction as Q
from math import sqrt
from pathlib import Path
import json,sys
from audit_week14 import R,O,sha,load,inputs
from check_week14_accuracy import decode,encode,close,NAR
E=O/'accuracy_final'


def dump(path,obj):path.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')


def wilson(k,n):
    if not n:return None
    z=1.959963984540054;p=k/n;den=1+z*z/n
    center=(p+z*z/(2*n))/den;radius=z*sqrt(p*(1-p)/n+z*z/(4*n*n))/den
    return [100*max(0,center-radius),100*min(1,center+radius)]


def check(phase):
    count=100000 if phase=='pilot' else 1000000;reports=[]
    for n in (2,4,8,0,1,3,5,6,7):
        p=E/phase/f'n{n}';d=load(p.with_suffix('.json'));old=load(O/f'accuracy/n{n}.json')
        assert d['samples']==count and d['seed']==2026101900+n and d['n']==n
        rows=[json.loads(v) for v in p.with_suffix('.jsonl').read_text().splitlines()]
        assert len(rows)==1024
        # Generator and reference prefix must replay the original calibrated corpus.
        assert p.with_suffix('.jsonl').read_bytes()==(O/f'accuracy/n{n}.jsonl').read_bytes()
        errors={'nf':[],'f':[]}
        for row in rows:
            a,b,c=[decode(row[k]) for k in ('a','b','c')]
            ideal=None if None in (a,b,c) else a*b+c
            assert encode(ideal)==row['ref'] and bool(row['nar'])==(ideal is None)
            if ideal is None:continue
            assert close(row['ideal'],ideal)
            for i,k in enumerate(('nf','f')):
                y=decode(row[k]);assert y is not None
                err=abs(y-ideal);pct=100*err/abs(ideal) if ideal else Q(0)
                assert close(row['metrics'][i]['absolute'],err)
                assert close(row['metrics'][i]['err_percent'],pct)
                for j,t in enumerate((Q(1,10),Q(1,2),Q(1),Q(5))):
                    if ideal:assert bool(row['metrics'][i]['correct'][j])==(pct<t)
                if ideal:errors[k].append(pct)
        for k in ('nf','f'):
            assert close(str(d['calibration_'+k]['mean_err_percent']),sum(errors[k],Q(0))/len(errors[k]))
            for prefix in ('','random_','directed_','calibration_'):
                s=d[prefix+k]
                assert s['finite_nonzero']+s['nar']+s['reference_zero']==({'':count,'random_':count-128,'directed_':128,'calibration_':1024}[prefix])
                assert all(0<=v<=s['finite_nonzero'] for v in s['correct_counts'])
                assert s['correct_counts']==sorted(s['correct_counts'])
                assert s['mean_err_percent']>=0 and s['relative_nmse']>=0
                if phase=='pilot':
                    clean={key:v for key,v in s.items() if key!='mean_err_percent'}
                    assert clean==old[prefix+k],(n,k,prefix,'original pilot replay')
            s=d['random_'+k];den=s['finite_nonzero'];mu=s['mean_err_percent']
            # Descriptive CLT interval, separate from Wilson binomial rate interval.
            var=max(0,s['relative_nmse']*10000-mu*mu)*den/(den-1)
            half=1.959963984540054*sqrt(var/den)
            s['correct_rate_percent']=[100*v/den for v in s['correct_counts']]
            s['correct_rate_wilson95_percent']=[wilson(v,den) for v in s['correct_counts']]
            s['mean_err_normal95_percent']=[max(0,mu-half),mu+half]
        assert sum(d['f_win_lose_tie'])==d['paired_finite_nonzero']
        win,lose,tie=d['f_win_lose_tie']
        d['f_win_among_decisive_wilson95_percent']=wilson(win,win+lose)
        reports.append(d)
    return reports


def freeze():
    names=['scripts/prepare_week14_accuracy_final.py','scripts/run_week14_accuracy_final.sh',
           'scripts/audit_week14_accuracy_final.py','results/week14/accuracy_final/collector.cpp',
           'results/week14/accuracy_final/plan.json','results/week14/accuracy_final/collector']
    dump(E/'freeze.json',dict(status='FROZEN_AFTER_PILOT',parent_matrix_sha256=sha(O/'matrix_freeze.json'),
        input_sha256={name:sha(R/name) for name in names},pilot=load(E/'pilot_check.json')))


def main():
    inputs();plan=load(E/'plan.json');assert plan['parent_matrix_sha256']==sha(O/'matrix_freeze.json')
    assert sha(E/'collector.cpp')==plan['source_sha256']
    phase=sys.argv[1]
    if phase!='pilot':
        f=load(E/'freeze.json');assert f['status']=='FROZEN_AFTER_PILOT'
        for name,h in f['input_sha256'].items():assert sha(R/name)==h,name
    if phase=='preflight':
        # Accuracy main begins only after numerical NF/F and coverage closure.
        assert all(load(p)['status']=='COMPLETE' for p in (O/'nf_extension/main').glob('*/execution.json'))
        assert len(list((O/'nf_extension/main').glob('*/execution.json')))==26
        assert load(O/'coverage_closure.json')['status']=='PASS'
        print('ACCURACY MAIN PREFLIGHT PASS');return
    reports=check(phase)
    result=dict(status='PASS',phase=phase,samples_per_n=100000 if phase=='pilot' else 1000000,
        python_fraction_checked=9216,release_sha256=sha(R/'rtl/production_freeze.json'),
        parent_matrix_sha256=sha(O/'matrix_freeze.json'),rows=reports,
        metric_definitions=dict(Err_percent='100*abs(y-exact(A*B+C))/abs(exact(A*B+C))',
            relative_NMSE='mean((y-r)^2/r^2) over finite nonzero reference; not ratio of global powers',
            CorrectRate='strict Err% < {0.1,0.5,1,5}; integer grid comparison',ULP='distance in signed Posit code to RNE(exact real sum)',
            percentiles='nearest lower order statistic at floor((N-1)*p/100)',
            CI95='Wilson binomial on IID random finite/nonzero stratum; normal mean interval descriptive only'),
        limitations=['NaR and exact reference-zero reported separately, no division by zero',
            'Directed first128 not IID and not included in headline random confidence intervals',
            'Standalone shared C_port accuracy; feedback correctness measured by RTL main, no feedback application accuracy claim',
            'Random raw Posit32 codes are not a neural-network workload distribution'])
    dump(E/f'{phase}_check.json',result)
    if phase=='pilot':freeze()
    print('ACCURACY',phase,'PASS',len(reports),'points, 9216 Fraction checks')


if __name__=='__main__':main()
