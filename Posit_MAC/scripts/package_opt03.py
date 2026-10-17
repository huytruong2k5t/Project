"""Copy an explicit, audited payload to the existing scoped Git backup checkout."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

R=Path(__file__).resolve().parents[1]
O=R/'results/opt03_20261017'
B=R/'scratch/github_week9_backup'


def git(*args):
    return subprocess.run(['git',*args],cwd=B,check=True,capture_output=True).stdout


assert Path(git('rev-parse','--show-toplevel').decode().strip()).resolve()==B.resolve()
assert git('branch','--show-current').decode().strip()=='main'
assert git('remote','get-url','origin').decode().strip()=='https://github.com/huytruong2k5t/Project.git'
assert not git('status','--porcelain'), 'Preserve user staged/unstaged changes'
assert json.loads((O/'summary.json').read_text())['status']=='PASS_OPT03_SCOPE'
m=json.loads((O/'archive_manifest.json').read_text())
assert hashlib.sha256((O/'evidence.zip').read_bytes()).hexdigest()==m['archive_sha256']
paths={'.gitattributes','.gitignore','SPEC_Posit_MAC_IP.md','l1/PLAN.md','l1/README.md',
    'rtl/README.md','scripts/README.md','docs/TIEN_DO_DO_AN.md','docs/HUONG_DAN_CHAY_WSL_MODELSIM.md',
    'rtl/mac_nf/mac_nf_wrapper.sv','tb/nf_coverage_harness.cpp','tb/tb_week11_mac.sv',
    'tb/week11_mac_harness.cpp','scripts/verify_prepack_nf.sh','scripts/verify_prepack_modelsim.ps1'}
for pattern in ['scripts/*opt03*','tb/*opt03*']:
    paths.update(p.relative_to(R).as_posix() for p in R.glob(pattern) if p.is_file())
paths.update(p.relative_to(R).as_posix() for p in O.iterdir() if p.is_file() and p.suffix in {'.json','.zip','.sha256'})
paths.update(p.relative_to(R).as_posix() for p in (O/'source').rglob('*') if p.is_file())
payload=[]
for relative in sorted(paths):
    src=R/relative
    assert src.is_file() and src.resolve().is_relative_to(R.resolve())
    dst=B/'Posit_MAC'/relative
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(src,dst)
    payload.append(dst.relative_to(B).as_posix())
t=(R/'docs/TIEN_DO_DO_AN.md').read_text(encoding='utf-8')
for name in ['SPEC_Posit_MAC_IP.md','l1/PLAN.md','l1/README.md']:
    t=t.replace(f'(../{name})',f'(../Posit_MAC/{name})')
t=t.replace('(HUONG_DAN_CHAY_WSL_MODELSIM.md)','(../Posit_MAC/docs/HUONG_DAN_CHAY_WSL_MODELSIM.md)')
(B/'doc/TIEN_DO_DO_AN.md').write_text(t,encoding='utf-8')
payload.append('doc/TIEN_DO_DO_AN.md')
(R/'scratch/opt03_git_paths.txt').write_text('\n'.join(payload)+'\n')
print('PACKAGE_OPT03_PASS',len(payload))
