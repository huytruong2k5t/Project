"""Freeze inputs, clean only generated caches, or stage a scoped backup copy."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys

R=Path(__file__).resolve().parents[1]
O=R/'results/opt02b_20261017'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def freeze():
    assert not (O/'verification_inputs.json').exists()
    paths=set()
    for pattern in ['scripts/*opt02b*','tb/*opt02b*']:
        paths.update(p for p in R.glob(pattern) if p.is_file())
    paths.update(R/name for name in ['tb/nf_coverage_harness.cpp','tb/nf_coverage_corpus.hpp',
        'tb/nf_coverage.vlt','tb/week11_model.hpp','tb/week10_add_reference.hpp',
        'tb/week9_exact_reference.hpp','tb/tb_week11_mac.sv','tb/prepack_nf_ppa_top.sv',
        'results/opt02b_20261017/posit_add_align_before.sv'])
    manifest={}
    for p in sorted(paths):
        name=p.relative_to(R).as_posix();d=O/'verification_inputs'/name
        d.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,d)
        manifest[name]=sha(p)
    (O/'verification_inputs.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (O/'runtime_sha256.json').write_text(json.dumps({'l0/libsoftposit.so':sha(R/'l0/libsoftposit.so')},indent=2)+'\n')
    print('OPT02B_INPUTS_FROZEN')


def cleanup():
    m=json.loads((O/'archive_manifest.json').read_text())
    assert sha(O/'evidence.zip')==m['archive_sha256']
    skip={'work','obj_fast','obj_dir','tmp','.Xil','appdata','localappdata','__pycache__'}
    targets=[]
    for p in sorted(O.rglob('*'),key=lambda p:len(p.parts)):
        if any(p.is_relative_to(t) for t in targets):continue
        if (p.is_dir() and p.name in skip) or (p.is_file() and p.suffix in {'.so','.wlf','.jou'}):targets.append(p)
    for name,digest in m['files'].items():
        assert sha(O/name)==digest
        assert not any((O/name).is_relative_to(t) for t in targets),name
    removed=0
    for p in targets:
        resolved=p.resolve()
        assert resolved.is_relative_to(O.resolve()) and resolved!=O.resolve()
        removed+=sum(x.stat().st_size for x in p.rglob('*') if x.is_file()) if p.is_dir() else p.stat().st_size
        if p.is_dir():shutil.rmtree(resolved)
        else:p.unlink()
    for name,digest in m['files'].items():assert sha(O/name)==digest
    (O/'retention.json').write_text(json.dumps(dict(removed_cache_bytes=removed,archive_bytes=(O/'evidence.zip').stat().st_size,preserved_files=len(m['files'])),indent=2)+'\n')
    print('OPT02B_CLEANUP_PASS',removed)


def package():
    b=R/'scratch/github_week9_backup'
    def git(*a):return subprocess.check_output(['git',*a],cwd=b).decode().strip()
    assert Path(git('rev-parse','--show-toplevel')).resolve()==b.resolve()
    assert git('branch','--show-current')=='main'
    assert git('remote','get-url','origin')=='https://github.com/huytruong2k5t/Project.git'
    assert not git('status','--porcelain'), 'Preserve user changes/staging'
    m=json.loads((O/'archive_manifest.json').read_text());assert sha(O/'evidence.zip')==m['archive_sha256']
    paths={'.gitattributes','SPEC_Posit_MAC_IP.md','l1/PLAN.md','rtl/README.md','docs/TIEN_DO_DO_AN.md',
        'rtl/candidates/adder/opt02b/posit_add_align.sv'}
    for pattern in ['scripts/*opt02b*','tb/*opt02b*']:
        paths.update(p.relative_to(R).as_posix() for p in R.glob(pattern) if p.is_file())
    paths.update(p.relative_to(R).as_posix() for p in O.iterdir() if p.is_file() and p.suffix in {'.json','.zip','.sv','.sha256'})
    paths.update(p.relative_to(R).as_posix() for p in (O/'source').rglob('*') if p.is_file())
    out=[]
    for name in sorted(paths):
        src=R/name;assert src.resolve().is_relative_to(R.resolve())
        dst=b/'Posit_MAC'/name;dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(src,dst);out.append(dst.relative_to(b).as_posix())
    text=(R/'docs/TIEN_DO_DO_AN.md').read_text(encoding='utf-8')
    for name in ['SPEC_Posit_MAC_IP.md','l1/PLAN.md','l1/README.md']:text=text.replace(f'(../{name})',f'(../Posit_MAC/{name})')
    text=text.replace('(HUONG_DAN_CHAY_WSL_MODELSIM.md)','(../Posit_MAC/docs/HUONG_DAN_CHAY_WSL_MODELSIM.md)')
    (b/'doc/TIEN_DO_DO_AN.md').write_text(text,encoding='utf-8');out.append('doc/TIEN_DO_DO_AN.md')
    (R/'scratch/opt02b_git_paths.txt').write_text('\n'.join(out)+'\n')
    print('OPT02B_PACKAGE_PASS',len(out))


if __name__=='__main__':
    assert len(sys.argv)==2 and sys.argv[1] in ['freeze','cleanup','package']
    globals()[sys.argv[1]]()
