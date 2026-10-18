"""Copy only this release's reviewable payload into the existing backup checkout."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
from audit_rtl_release import validate

R=Path(__file__).resolve().parents[1]
B=R/'scratch/github_week9_backup'


def git(*args):
    return subprocess.check_output(['git','-C',str(B),*args],text=True).strip()


def main():
    lock=json.loads((R/'rtl/production_freeze.json').read_text())
    validate(lock)
    assert Path(git('rev-parse','--show-toplevel')).resolve()==B.resolve()
    assert (B/'.git').resolve().is_relative_to(B.resolve())
    assert git('branch','--show-current')=='main'
    assert git('remote','get-url','origin')=='https://github.com/huytruong2k5t/Project.git'
    assert not git('status','--porcelain'),'Preserve user changes/staging; review before copying'
    files=set(lock['production_files'])|{'rtl/posit_mac.vh','rtl/production.f','rtl/production_freeze.json',
        'scripts/rtl_paths.json','scripts/rtl_paths.tsv','README.md','rtl/README.md','scripts/README.md',
        'syn/README.md','SPEC_Posit_MAC_IP.md','l1/PLAN.md','docs/TIEN_DO_DO_AN.md',
        'docs/HUONG_DAN_CHAY_WSL_MODELSIM.md','.gitignore','.gitattributes',
        'rtl/candidates/adder/opt02c/posit_add_align.sv'}
    for pattern in ('*opt02c*','*rtl_release*'):
        files.update(p.relative_to(R).as_posix() for p in (R/'scripts').glob(pattern) if p.is_file())
    study=R/'results/opt02c_20261018'
    files.update(p.relative_to(R).as_posix() for p in study.glob('*.json'))
    files.add('results/opt02c_20261018/evidence.zip')
    copied={}
    for name in sorted(files):
        source=R/name
        dest=B/'Posit_MAC'/name
        assert source.is_file(),name
        assert dest.resolve().is_relative_to((B/'Posit_MAC').resolve())
        dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(source,dest)
        copied['Posit_MAC/'+name]=hashlib.sha256(dest.read_bytes()).hexdigest()
    # The repository has a historical progress mirror at doc/; adapt its links.
    progress=(R/'docs/TIEN_DO_DO_AN.md').read_text(encoding='utf-8')
    progress=progress.replace('(../../doc/Optimization.md','(Optimization.md')
    progress=progress.replace('(../','(../Posit_MAC/')
    progress=progress.replace('(HUONG_DAN_CHAY_WSL_MODELSIM.md)',
                              '(../Posit_MAC/docs/HUONG_DAN_CHAY_WSL_MODELSIM.md)')
    dest=B/'doc/TIEN_DO_DO_AN.md'
    dest.write_text(progress,encoding='utf-8',newline='\n')
    optimization=R.parent/'doc/Optimization.md'
    shutil.copyfile(optimization,B/'doc/Optimization.md')
    validate(lock,root=B/'Posit_MAC')
    print('Backup payload copied and release hashes validated:',len(copied),'project files +2 parent documents')
    print('No staging, commit, push, remote or history changes performed by this script')


if __name__=='__main__':main()
