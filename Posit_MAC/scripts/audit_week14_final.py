"""Final W14 handoff audit; AC02 is explicitly independent and still open."""
from pathlib import Path
import copy,json,sys
from audit_week14 import R,O,sha,load,inputs,validate_result
from audit_rtl_release import validate


def require_complete(records,expected,coverage,accuracy,replay):
    assert len(records)==len(expected)==35
    assert {r['id'] for r in records}==set(expected) and len({r['id'] for r in records})==35
    for r in records:
        assert r['status']=='COMPLETE' and r['completed']>=10000000 and r['mismatches']==0
        assert r['accepted']==r['completed']+r['reset_aborts']
        assert r['source_bound'] and r['log_bound'] and r['report_bound']
        assert r['near_percent']>=30
    assert coverage['status']=='PASS' and coverage['source_bound']
    for name in ('NF32_3','NF32_2','F32_3'):
        assert name in coverage['profiles']
        for k,limit in [('v_line',95),('v_branch',90),('v_toggle',85)]:
            assert coverage['profiles'][name]['reviewed'][k]['percent']>=limit
    assert accuracy['status']=='PASS' and len(accuracy['rows'])==9 and accuracy['python_fraction_checked']==9216
    assert {d['n'] for d in accuracy['rows']}==set(range(9))
    assert all(d['samples']>=1000000 for d in accuracy['rows'])
    assert replay['status']=='PASS' and len(replay['replayed'])==4


def negatives(records,expected,coverage,accuracy,replay):
    def mutate(which,fn):
        data=copy.deepcopy([records,expected,coverage,accuracy,replay]);fn(data[which])
        try:require_complete(*data)
        except (AssertionError,KeyError):return 1
        raise AssertionError('negative audit accepted invalid evidence')
    count=0
    for fn in [lambda r:r.pop(),lambda r:r[0].update(status='RUNNING'),
               lambda r:r[0].update(completed=9999999),lambda r:r[0].update(mismatches=1),
               lambda r:r[0].update(source_bound=False),lambda r:r[0].update(log_bound=False),
               lambda r:r[0].update(report_bound=False),lambda r:r[0].update(near_percent=29.99),
               lambda r:r[0].update(accepted=r[0]['accepted']+1),lambda r:r[0].update(id=r[1]['id'])]:
        count+=mutate(0,fn)
    count+=mutate(2,lambda c:c.update(source_bound=False))
    count+=mutate(2,lambda c:c['profiles'].pop('F32_3'))
    count+=mutate(2,lambda c:c['profiles']['NF32_3']['reviewed']['v_toggle'].update(percent=84.99))
    count+=mutate(3,lambda a:a['rows'][0].update(samples=999999))
    count+=mutate(4,lambda p:p.update(status='RUNNING'))
    assert count==15;return count


def main():
    inputs();lock=load(R/'rtl/production_freeze.json');validate(lock)
    base=load(O/'matrix_freeze.json');extension=load(O/'nf_extension/freeze.json');rows=[]
    for seal in (base,extension,load(O/'accuracy_final/freeze.json')):
        for name,h in seal['input_sha256'].items():assert sha(R/name)==h,name
    for seal in (base,extension):
        for name,h in seal['binary_sha256'].items():assert sha(R/name)==h,name
    assert load(O/'summary.json')['status']=='PASS_W14_01_THROUGH_06_ONLY'
    for job in base['jobs']:
        fused=job['top']=='f';folder=(O/'main' if fused else O/'nf_extension/main')/job['id']
        rec=load(folder/'execution.json');p=folder/('result.json' if fused else 'result_summary.json');d=load(p)
        log=folder/'console.log';assert rec['exit_code']==0
        validate_result(d,job,10000000,status=rec['status'],log_exists=log.exists(),
                        bound=sha(p)==rec['report_sha256'] and sha(log)==rec['log_sha256'])
        assert rec.get('parent_matrix_sha256',sha(O/'matrix_freeze.json'))==sha(O/'matrix_freeze.json')
        if not fused:
            assert rec['job']==job and rec['runner_sha256']==sha(R/'scripts/run_week14_nf_ext.py')
            assert d['oracle_checks']==d['accepted']
            assert all(d[k]>0 for k in ('reset_busy','reset_stalled','invalid_checks','clears','acc_commits','long_stalls'))
        near=d['near'] if fused else sum(d['near_delta_standalone_acc'])
        rows.append(dict(id=job['id'],status=rec['status'],job=job,completed=d['completed'],accepted=d['accepted'],
            reset_aborts=d.get('reset_aborted',d.get('reset_aborts')),mismatches=d['mismatches'],
            near_percent=100*near/d['completed'],seconds=rec['wall_seconds'],
            source_bound=True,log_bound=True,report_bound=True,
            report=p.relative_to(R).as_posix(),report_sha256=sha(p),execution_sha256=sha(folder/'execution.json')))
    coverage=load(O/'coverage_closure.json');assert coverage['producer_sha256']==sha(R/'scripts/audit_week14_closure.py')
    for profile in list(coverage['profiles'].values())+[coverage['comparator_diagnostic']]:
        for name,h in profile['evidence_sha256'].items():assert sha(R/name)==h,name
    coverage['source_bound']=True
    accuracy=load(O/'accuracy_final/main_check.json');replay=load(O/'final_replay/summary.json')
    inference=load(O/'accuracy_inference.json');assert inference['status']=='PASS' and len(inference['rows'])==9
    assert inference['parent_accuracy_sha256']==sha(O/'accuracy_final/main_check.json')
    assert inference['producer_sha256']==sha(R/'scripts/check_week14_accuracy_inference.py')
    for name,h in inference['input_sha256'].items():assert sha(R/name)==h
    expected=[j['id'] for j in base['jobs']]
    require_complete(rows,expected,coverage,accuracy,replay)
    rejected=negatives(rows,expected,coverage,accuracy,replay)
    nf=[r for r in rows if r['job']['top']=='nf' and r['job']['exact_en']]
    f=[r for r in rows if r['job']['top']=='f'];cmp=[r for r in rows if r['job']['top']=='nf' and not r['job']['exact_en']]
    assert len(nf)==25 and len(f)==9 and len(cmp)==1
    report=dict(status='PASS_W14_01_THROUGH_11_VERIFICATION_ARCHIVE_AND_PUSH_PENDING',
        release_id=lock['release_id'],release_sha256=sha(R/'rtl/production_freeze.json'),
        parent_matrix_sha256=sha(O/'matrix_freeze.json'),nf_extension_sha256=sha(O/'nf_extension/freeze.json'),
        coverage_sha256=sha(O/'coverage_closure.json'),accuracy_sha256=sha(O/'accuracy_final/main_check.json'),
        accuracy_inference_sha256=sha(O/'accuracy_inference.json'),
        replay_sha256=sha(O/'final_replay/summary.json'),producer_sha256=sha(Path(__file__)),
        milestones={f'W14-{i:02}':'PASS_VERIFIED' for i in range(1,11)},
        W14_11='Verification/replay PASS; archive CRC/SHA and successful Git push required for final handoff',
        W14_12='DEFERRED_OPEN_AC02; p8 MAC2^24, p32/2>=1e8 and p16 exhaustive not run by this matrix',
        completed=dict(F=sum(r['completed'] for r in f),NF=sum(r['completed'] for r in nf),
                       NF_EX0_comparator=sum(r['completed'] for r in cmp)),
        total_completed=sum(r['completed'] for r in rows),total_reset_aborts=sum(r['reset_aborts'] for r in rows),
        mismatches=0,negative_audit_rejected=rejected,jobs=rows,
        tools=load(O/'summary.json')['tools'],
        limitations=['Main profile AC04 uses2 proved unreachable F branch exclusions; raw metrics retained.',
          'ComparatorEX0 has one scoped feature-unused lint waiver, raw report preserved; separate structural diagnostic not main AC04 claim.',
          'Paired accuracy is standalone frozen L1 over9M raw-code triples, not9M additional RTL transactions or application/feedback workload accuracy.',
          'AC02/exact exhaustive, matched PPA Gate4/W15, board signoff and author paper provenance remain outside this handoff.'])
    (O/'completion.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('W14 FINAL VERIFICATION PASS 350M completed 0 mismatch; 15/15 invalid audit mutations rejected; archive/push next')


if __name__=='__main__':main()
