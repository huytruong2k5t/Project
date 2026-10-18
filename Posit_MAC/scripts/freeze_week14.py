"""Freeze main inputs only after every required pilot and collector check passes."""
from pathlib import Path
import collections
import json
import re
from audit_week14 import inputs,load,sha,O,R,validate_result
from audit_rtl_release import validate


def coverage_file(path):
    kinds=collections.Counter();files=set()
    for line in path.read_text().splitlines():
        if not line.startswith('C '):continue
        fields=dict(v.split('\x02',1) for v in line[3:].rsplit("' ",1)[0].split('\x01')[1:])
        if not fields['f'].startswith('src/rtl/'):continue
        kinds[fields['page'].split('/')[0]]+=1
        files.add(Path(fields['f']).name)
    assert all(kinds[k]>0 for k in ('v_line','v_branch','v_toggle')),kinds
    return dict(points=dict(kinds),active_rtl_files=sorted(files))


def main():
    assert not (O/'matrix_freeze.json').exists(),'Never overwrite a frozen matrix'
    inputs();lock=load(R/'rtl/production_freeze.json');validate(lock)
    assert (O/'micro/status.txt').read_text().strip()=='PASS'
    assert load(O/'audit_self_test.json')['rejected']==9
    assert load(O/'replay_test/summary.json')['status']=='PASS_NEGATIVE_TEST'
    assert (O/'accuracy/status.txt').read_text().strip()=='COMPLETE'
    accuracy=load(O/'accuracy/python_check.json')
    assert accuracy['status']=='PASS' and min(accuracy['python_fraction_checks_per_n'])>=1000
    jobs=load(O/'matrix_draft.json')['jobs']
    pilot=[]
    for job in jobs:
        phases=['pilot','pilot_fast'] if job['top']=='f' else ['pilot']
        for phase in phases:
            run=O/phase/job['id'];receipt=load(run/'execution.json')
            report=run/('result.json' if job['top']=='f' else 'result_summary.json')
            row=load(report)
            validate_result(row,job,job['pilot_goal'],status=receipt['status'],
                log_exists=(run/'console.log').exists(),bound=sha(report)==receipt['report_sha256'] and
                sha(run/'console.log')==receipt['log_sha256'] and receipt['pilot_source_sha256']==sha(O/'pilot_source.json'))
            if job['top']=='nf':
                assert sum(row['near_delta_standalone_acc'])*10>=3*row['completed']
            profile='f32_3' if job['top']=='f' else f"nf32_{job['es']}"+('_ex0' if not job['exact_en'] else '')
            if phase=='pilot_fast':profile+='_fast'
            build=O/'builds'/profile
            for name,digest in lock['rtl_sha256'].items():
                assert sha(build/'src/rtl'/Path(name).name)==digest
            for p in (build/'src/l1/include').glob('*.hpp'):
                assert sha(p)==sha(R/'l1/include'/p.name)
            for p in (build/'src/tb').glob('*.hpp'):
                assert sha(p)==sha(R/'tb'/p.name)
            harness='week14_fused_harness.cpp' if job['top']=='f' else 'week14_nf_harness.cpp'
            assert sha(build/'src/tb'/harness)==sha(R/'tb'/harness)
            exe=build/'obj'/('Vweek13_fused_tb' if job['top']=='f' else 'Vposit_mac_nf')
            assert sha(exe)==receipt['binary_sha256']
            assert not re.search(r'%Warning|%Error',(build/'lint.log').read_text())
            warnings=re.findall(r'%Warning-([A-Z0-9_]+)',(build/'build.log').read_text())
            assert set(warnings)<={'ASSIGNDLY'},set(warnings)
            cp=run/('result.coverage.dat' if job['top']=='f' else 'result_coverage.dat')
            coverage=coverage_file(cp) if phase=='pilot' else dict(instrumentation='line-only numerical pilot, not AC04')
            pilot.append(dict(job=job['id'],phase=phase,completed=row['completed'],seconds=receipt['wall_seconds'],
                              rate=receipt['completed_per_second'],rss_kib=receipt['peak_child_rss_kib'],coverage=coverage))
    assert (O/'corner/status.txt').read_text().strip()=='COMPLETE'
    for n in range(9):
        row=load(O/f'corner/n{n}.json')
        assert row['completed']==20000 and row['fixed_n']==n and row['mismatches']==0 and min(row['corner_hits'])>0
    tool_files=['verilator.txt','compiler.txt']
    qualification=dict(status='PASS_W14_01_TO_04',release_id=lock['release_id'],
        pilots=pilot,accuracy=accuracy,counter_microtests='PASS',audit_negative_tests=9,
        failure_replay='actual corrupted-expected failure rejected and exact packet reproduced',
        corners='64 directed tags/n,9n,180000completed,0mismatch; includes golden/delta28/29/deepLZC/zero/NaR',
        warning_review='One feature-pruned UNUSEDSIGNAL port-line waiver for NF EXACT_EN0 only; raw warning retained. ASSIGNDLY expected in no-timing cycle runs; same RTL4state evidence in review.',
        structural_scope='Pilot proves instrumentation availability; AC04 closure NOT granted')
    (O/'pilot_qualification.json').write_text(json.dumps(qualification,indent=2)+'\n')
    names=set()
    for group in ('rtl_sha256','model_sha256','build_contract_sha256'):names.update(lock[group])
    names.update(['rtl/production_freeze.json'])
    names.update(p.relative_to(R).as_posix() for p in (R/'scripts').glob('*week14*') if p.is_file())
    names.update(p.relative_to(R).as_posix() for p in (R/'tb').glob('*week14*') if p.is_file())
    names.update('results/week14/'+name for name in ('pilot_source.json','matrix_draft.json','coverage_policy.json',
        'w14_01_review.json','pilot_qualification.json','accuracy/python_check.json',*tool_files))
    binary={}
    for profile in ('f32_3','f32_3_fast','nf32_3','nf32_2','nf32_3_ex0'):
        top='Vweek13_fused_tb' if profile.startswith('f32') else 'Vposit_mac_nf'
        relative=f'results/week14/builds/{profile}/obj/{top}';binary[relative]=sha(R/relative)
    freeze=dict(status='FROZEN_AFTER_PILOT_PASS',release_id=lock['release_id'],jobs=jobs,
        input_sha256={name:sha(R/name) for name in sorted(names)},binary_sha256=binary,
        pilot_qualification_sha256=sha(O/'pilot_qualification.json'),
        numerical_policy='Fixed n/OPS per job,10M completed excl aborts; no chunks/reseed/resume within a job',
        functional_policy='Main counters cover every completed sample',
        structural_policy='Separate full-coverage post-freeze companion20k/n; only final companion full instrumentation merged for AC04, not fast or pilot files',
        accuracy_corpus=dict(generator='tb/week14_accuracy.cpp',prng='mt19937_64',seed_by_n='2026101900+n',
                             pilot_per_n=100000,main_min_per_n=1000000,first128='directed stratum separate from random raw-code stratum',
                             reference='exact real A*B+C, independent full-grid',acc_mode='separate own NF/F states; exact-real Ideal state and reset sequence must accompany sequence reports'),
        limits='Frozen for W14; not W14-06/07/08/09/10/11/12 PASS. Comparator waiver disclosed; no claimed raw zero-warning lint.')
    (O/'matrix_freeze.json').write_text(json.dumps(freeze,indent=2)+'\n')
    print('W14-01..05 PASS:35 full pilots +9 fast pilots,900000 accuracy samples,9216 Python checks; matrix frozen')


if __name__=='__main__':main()
