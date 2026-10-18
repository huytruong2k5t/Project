"""W14 source/job validation. Refuse stale evidence, mixed n and incomplete jobs."""
from pathlib import Path
import copy
import hashlib
import json
import sys

R=Path(__file__).resolve().parents[1]
O=R/'results/week14'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))


def inputs():
    p=load(O/'pilot_source.json')
    assert sha(R/'rtl/production_freeze.json')==p['release_sha256']
    for name,digest in p['source_sha256'].items():
        assert sha(O/'source'/name)==digest, name
        if (R/name).exists():assert sha(R/name)==digest, 'canonical changed:'+name
    assert sha(O/'matrix_draft.json')==p['matrix_sha256']
    assert sha(O/'coverage_policy.json')==p['coverage_policy_sha256']
    return p


def validate_result(row, job, goal, status='COMPLETE', log_exists=True, bound=True):
    assert status=='COMPLETE' and log_exists and bound
    assert row['completed']>=goal and row['mismatches']==0
    assert row['fixed_n']==job['n'] and row['fixed_ops']==job['ops']
    assert row['seed']==job['seed']
    aborted=row.get('reset_aborted',row.get('reset_aborts'))
    assert row['accepted']==row['completed']+aborted
    if job['top']=='f':
        assert row['status']=='PASS'
        assert sum(row['n_hits'])==row['completed'] and row['n_hits'][job['n']]==row['completed']
        assert row['near']*10>=3*row['completed'] and row['near_after']*10>=3*row['completed']
        assert all(row[k]>0 for k in ('reset_busy','reset_stalled','invalid_checks','commits','clears'))
    else:
        assert row['NB']==job['nb'] and row['ES']==job['es']


def self_test():
    job=dict(n=3,ops=1,seed=100,top='nf',nb=32,es=3)
    row=dict(completed=20,mismatches=0,fixed_n=3,fixed_ops=1,seed=100,accepted=21,reset_aborts=1,NB=32,ES=3)
    validate_result(row,job,20)
    rejected=0
    for change in ({'completed':19},{'fixed_n':4},{'fixed_ops':0},{'seed':101},{'mismatches':1},{'accepted':22}):
        bad=copy.deepcopy(row);bad.update(change)
        try:validate_result(bad,job,20)
        except AssertionError:rejected+=1
    for kw in ({'status':'RUNNING'},{'log_exists':False},{'bound':False}):
        try:validate_result(row,job,20,**kw)
        except AssertionError:rejected+=1
    assert rejected==9
    (O/'audit_self_test.json').write_text(json.dumps(dict(status='PASS',rejected=9,valid_control_pass=True))+'\n')
    print('W14 AUDIT SELFTEST PASS 9/9 rejected: counts/config/seed/mismatch/accounting/status/log/hash')


if __name__=='__main__':
    if '--self-test' in sys.argv:self_test()
    inputs();print('W14 source/matrix/coverage policy audit PASS')
