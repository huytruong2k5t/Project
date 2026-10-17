"""Copy this session's explicit source/evidence set into the clean backup checkout."""
from pathlib import Path
import hashlib
import json
import shutil

R=Path(__file__).resolve().parents[1]
C=R/'scratch/github_week9_backup'
assert (C/'.git').is_dir() and (C/'Posit_MAC').is_dir()
files=[]
for family in ('rtl/candidates/multiplier/opt05','rtl/candidates/mac_nf/opt09','rtl/candidates/packer/opt10a'):
    files.extend(p for p in (R/family).rglob('*') if p.is_file())
for family in ('scripts','tb'):
    files.extend(p for p in (R/family).iterdir() if p.is_file() and
                 any(x in p.name for x in ('opt05','opt09','opt10a','optcombo','opt825')))
files.extend(R/p for p in ('.gitattributes','.gitignore','docs/TIEN_DO_DO_AN.md'))
for study in ('opt05_20261017','opt09_20261018','opt10a_20261018','optcombo_20261018'):
    for name in ('freeze.json','summary.json','optimization_summary.json',
                 'archive_manifest.json','retention.json','evidence.zip'):
        p=R/'results'/study/name
        if p.exists():files.append(p)
copied=[]


def copy(source,destination,root_mirror=False):
    assert destination.resolve().is_relative_to(C.resolve())
    assert source.resolve().is_relative_to(R.parent.resolve())
    destination.parent.mkdir(parents=True,exist_ok=True)
    data=source.read_bytes()
    if root_mirror:
        text=data.decode('utf-8')
        for old,new in (('(../SPEC_Posit_MAC_IP.md)','(../Posit_MAC/SPEC_Posit_MAC_IP.md)'),
                        ('(../l1/PLAN.md)','(../Posit_MAC/l1/PLAN.md)'),
                        ('(../l1/README.md)','(../Posit_MAC/l1/README.md)'),
                        ('(../../doc/Optimization.md','(Optimization.md'),
                        ('(HUONG_DAN_CHAY_WSL_MODELSIM.md)','(../Posit_MAC/docs/HUONG_DAN_CHAY_WSL_MODELSIM.md)')):
            text=text.replace(old,new)
        data=text.encode('utf-8')
    destination.write_bytes(data)
    assert destination.read_bytes()==data
    copied.append({'path':destination.relative_to(C).as_posix(),'bytes':len(data),
                   'sha256':hashlib.sha256(data).hexdigest()})


for p in sorted(set(files)):copy(p,C/'Posit_MAC'/p.relative_to(R))
copy(R.parent/'doc/Optimization.md',C/'doc/Optimization.md')
copy(R/'docs/TIEN_DO_DO_AN.md',C/'doc/TIEN_DO_DO_AN.md',root_mirror=True)
manifest=R/'results/opt05_20261017/backup_manifest.json'
manifest.write_text(json.dumps({'files':copied,'scope':'explicit OPT8.25 source/docs/compact evidence only'},indent=2)+'\n')
copy(manifest,C/'Posit_MAC/results/opt05_20261017/backup_manifest.json')
print('Prepared '+str(len(copied))+' explicit files; no deletion/staging/commit')
