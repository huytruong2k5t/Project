"""Replay representative pilots with the frozen final binaries and normalized counters."""
from pathlib import Path
import json,os,subprocess
from audit_week14 import R,O,load,sha,validate_result,inputs


def main():
    inputs();out=O/'final_replay';assert not out.exists();out.mkdir()
    parent=load(O/'matrix_freeze.json');nf=load(O/'nf_extension/freeze.json')
    requested=['f32_3_ops1_n3','nf32_3_ops1_n3','nf32_2_ops0_n1','nf32_3_ex0_ops1_n3']
    assert set(requested)<=set(j['id'] for j in parent['jobs'])
    plan=dict(status='PREPARED_BEFORE_REPLAY',parent_matrix_sha256=sha(O/'matrix_freeze.json'),
              nf_extension_sha256=sha(O/'nf_extension/freeze.json'),requested=requested,
              runner_sha256=sha(Path(__file__)))
    (out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
    records=[]
    for job in parent['jobs']:
        if job['id'] not in requested:continue
        fused=job['top']=='f';profile='f32_3_fast' if fused else f"nf32_{job['es']}"+('_ex0' if not job['exact_en'] else '')
        build=(O/'builds' if fused else O/'nf_extension/builds')/profile
        exe=build/('obj/Vweek13_fused_tb' if fused else 'obj/Vposit_mac_nf')
        frozen=parent if fused else nf;assert sha(exe)==frozen['binary_sha256'][exe.relative_to(R).as_posix()]
        prefix=out/job['id'];command=[str(exe),'20000',str(prefix),str(job['n']),str(job['ops']),str(job['seed'])]
        env=os.environ.copy();env['LD_LIBRARY_PATH']=str(build/'src/l0');env['TMPDIR']=str(O/'tmp')
        with prefix.with_suffix('.log').open('w') as log:
            code=subprocess.call(command,cwd=build,env=env,stdout=log,stderr=subprocess.STDOUT)
        assert code==0
        report=Path(str(prefix)+('.json' if fused else '_summary.json'));d=load(report)
        validate_result(d,job,20000)
        old=O/('pilot_fast' if fused else 'nf_extension/pilot')/job['id']/('result.json' if fused else 'result_summary.json')
        assert d==load(old),(job['id'],'normalized replay mismatch')
        records.append(dict(id=job['id'],completed=d['completed'],mismatches=0,command=command,
                            binary_sha256=sha(exe),report_sha256=sha(report),reference_sha256=sha(old)))
    (out/'summary.json').write_text(json.dumps(dict(status='PASS',replayed=records),indent=2)+'\n')
    print('W14 FINAL REPLAY PASS 4 profiles x20000; numerical/protocol/counter JSON identical')


if __name__=='__main__':main()
