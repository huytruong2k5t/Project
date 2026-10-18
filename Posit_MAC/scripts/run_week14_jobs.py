"""Run source-bound fixed-point pilots or the nine frozen F main jobs in WSL."""
from pathlib import Path
import json
import os
import resource
import subprocess
import sys
import time
from audit_week14 import inputs, load, sha, O, R, validate_result


def run(job, phase):
    inputs()
    goal=job['main_goal'] if phase=='main' else 20000 if phase=='coverage_final' else job['pilot_goal']
    if phase in ('main','coverage_final'):
        frozen=load(O/'matrix_freeze.json')
        assert frozen['status']=='FROZEN_AFTER_PILOT_PASS'
        assert job in frozen['jobs']
        for name,digest in frozen['input_sha256'].items():assert sha(R/name)==digest,name
    profile='f32_3' if job['top']=='f' else f"nf32_{job['es']}"+('_ex0' if not job['exact_en'] else '')
    if job['top']=='f' and phase in ('main','pilot_fast'):profile+='_fast'
    build=O/'builds'/profile
    assert (build/'status.txt').read_text().strip()=='COMPLETE'
    exe=build/'obj'/('Vweek13_fused_tb' if job['top']=='f' else 'Vposit_mac_nf')
    if phase in ('main','coverage_final'):
        assert sha(exe)==frozen['binary_sha256'][exe.relative_to(R).as_posix()],'Frozen binary changed'
    prefix=O/phase/job['id']/'result'
    assert not prefix.parent.exists(),'Preserve previous job; review before new attempt'
    prefix.parent.mkdir(parents=True)
    command=[str(exe),str(goal),str(prefix),str(job['n']),str(job['ops']),str(job['seed'])]
    receipt=dict(status='RUNNING',job=job,phase=phase,goal=goal,command=command,
                 binary_sha256=sha(exe),pilot_source_sha256=sha(O/'pilot_source.json'),
                 runner_sha256=sha(Path(__file__)),log='console.log')
    path=prefix.parent/'execution.json'
    path.write_text(json.dumps(receipt,indent=2)+'\n')
    env=os.environ.copy();env['TMPDIR']=str(O/'tmp');env['LD_LIBRARY_PATH']=str(build/'src/l0')
    start=time.monotonic()
    with (prefix.parent/'console.log').open('w') as log:
        code=subprocess.call(command,cwd=build,env=env,stdout=log,stderr=subprocess.STDOUT)
    receipt.update(exit_code=code,wall_seconds=time.monotonic()-start,
                   peak_child_rss_kib=resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss)
    report=Path(str(prefix)+('.json' if job['top']=='f' else '_summary.json'))
    try:
        assert code==0,'simulator returned failure'
        row=load(report)
        validate_result(row,job,goal)
        receipt.update(status='COMPLETE',report_sha256=sha(report),log_sha256=sha(prefix.parent/'console.log'),
                       completed_per_second=row['completed']/receipt['wall_seconds'],
                       output_bytes=sum(p.stat().st_size for p in prefix.parent.iterdir() if p.is_file()))
    except Exception as exc:
        receipt.update(status='FAILED',reason=str(exc))
        path.write_text(json.dumps(receipt,indent=2)+'\n')
        raise
    path.write_text(json.dumps(receipt,indent=2)+'\n')
    print('W14',phase,job['id'],'PASS',goal,'%.3fs'%receipt['wall_seconds'],flush=True)


if __name__=='__main__':
    phase=sys.argv[1];assert phase in ('pilot','pilot_fast','main','coverage_final')
    jobs=load(O/'matrix_draft.json')['jobs']
    selected=jobs if len(sys.argv)==2 else [j for j in jobs if j['id'] in sys.argv[2:]]
    assert selected
    if phase in ('main','pilot_fast','coverage_final'):
        selected=[j for j in selected if j['top']=='f']
    for job in selected:run(job,phase)
