"""Add fast NF pilots/main with a new freeze, preserving the completed F matrix."""
from concurrent.futures import ThreadPoolExecutor,as_completed
from pathlib import Path
import json,os,resource,subprocess,sys,time
from audit_week14 import inputs,load,sha,O,R,validate_result
from audit_rtl_release import validate
E=O/'nf_extension'


def profile(job):return f"nf32_{job['es']}"+('_ex0' if not job['exact_en'] else '')


def parent():
    inputs();p=load(O/'matrix_freeze.json')
    for name,digest in p['input_sha256'].items():assert sha(R/name)==digest,name
    validate(load(R/'rtl/production_freeze.json'))
    return p


def run(job,phase):
    p=parent();build=E/'builds'/profile(job);exe=build/'obj/Vposit_mac_nf'
    goal=20000 if phase=='pilot' else 10000000
    if phase=='main':
        f=load(E/'freeze.json');assert f['status']=='FROZEN_AFTER_FAST_PILOTS'
        for name,digest in f['input_sha256'].items():assert sha(R/name)==digest,name
        assert sha(exe)==f['binary_sha256'][exe.relative_to(R).as_posix()]
    run=E/phase/job['id'];assert not run.exists(),'Preserve evidence';run.mkdir(parents=True)
    prefix=run/'result';command=[str(exe),str(goal),str(prefix),str(job['n']),str(job['ops']),str(job['seed'])]
    receipt=dict(status='RUNNING',job=job,goal=goal,command=command,binary_sha256=sha(exe),
                 parent_matrix_sha256=sha(O/'matrix_freeze.json'),runner_sha256=sha(Path(__file__)))
    path=run/'execution.json';path.write_text(json.dumps(receipt,indent=2)+'\n')
    env=os.environ.copy();env['TMPDIR']=str(O/'tmp');env['LD_LIBRARY_PATH']=str(build/'src/l0')
    start=time.monotonic()
    with (run/'console.log').open('w') as log:code=subprocess.call(command,cwd=build,env=env,stdout=log,stderr=subprocess.STDOUT)
    receipt.update(exit_code=code,wall_seconds=time.monotonic()-start,
                   peak_child_rss_kib=resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss)
    try:
        assert code==0
        row=load(run/'result_summary.json');validate_result(row,job,goal)
        assert sum(row['near_delta_standalone_acc'])*10>=3*row['completed']
        if phase=='pilot':assert row==load(O/'pilot'/job['id']/'result_summary.json'),'Full/fast counter mismatch'
        receipt.update(status='COMPLETE',report_sha256=sha(run/'result_summary.json'),log_sha256=sha(run/'console.log'))
    except Exception as exc:
        receipt.update(status='FAILED',reason=str(exc));path.write_text(json.dumps(receipt,indent=2)+'\n');raise
    path.write_text(json.dumps(receipt,indent=2)+'\n')
    print('NF EXT',phase,job['id'],'PASS',goal,'%.3fs'%receipt['wall_seconds'],flush=True)


def freeze(jobs):
    assert not (E/'freeze.json').exists();parent()
    pilots=[];binaries={}
    for job in jobs:
        run=E/'pilot'/job['id'];r=load(run/'execution.json');assert r['status']=='COMPLETE'
        d=load(run/'result_summary.json');validate_result(d,job,20000)
        assert d==load(O/'pilot'/job['id']/'result_summary.json')
        exe=E/'builds'/profile(job)/'obj/Vposit_mac_nf';assert sha(exe)==r['binary_sha256']
        binaries[exe.relative_to(R).as_posix()]=sha(exe);pilots.append(r)
    available=int(next(x.split()[1] for x in Path('/proc/meminfo').read_text().splitlines() if x.startswith('MemAvailable:')))
    rss=max(r['peak_child_rss_kib'] for r in pilots)
    workers=3 if os.cpu_count()>=6 and available>max(1000000,rss*24) else 1
    names={p.relative_to(R).as_posix() for p in (R/'scripts').glob('*week14_nf*') if p.is_file()}
    names.add('results/week14/matrix_freeze.json')
    f=dict(status='FROZEN_AFTER_FAST_PILOTS',parent_matrix_sha256=sha(O/'matrix_freeze.json'),jobs=jobs,
           input_sha256={name:sha(R/name) for name in sorted(names)},binary_sha256=binaries,
           pilots=pilots,workers=workers,resources=dict(cpu_count=os.cpu_count(),mem_available_kib=available,pilot_peak_rss_kib=rss),
           scope='NF250M plus comparator10M; all parameters/corpus/seed unchanged from parent. Full coverage final companions separate.')
    (E/'freeze.json').write_text(json.dumps(f,indent=2)+'\n');print('NF extension FROZEN workers=',workers,flush=True)


if __name__=='__main__':
    jobs=[j for j in load(O/'matrix_freeze.json')['jobs'] if j['top']=='nf']
    action=sys.argv[1]
    if action=='pilot':
        for job in jobs:run(job,'pilot')
        freeze(jobs)
    elif action=='main':
        f=load(E/'freeze.json')
        with ThreadPoolExecutor(max_workers=f['workers']) as pool:
            work=[pool.submit(run,j,'main') for j in jobs]
            for future in as_completed(work):future.result()
    else:raise SystemExit('pilot|main')
