"""Archive compact reproducibility evidence; remove only this study's build caches."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

from collect_opt825 import R, STUDIES, main as collect

EXCLUDED = {'work','tmp','appdata','localappdata','.Xil','__pycache__'}
SUFFIXES = {'.sv','.vh','.cpp','.hpp','.h','.vlt','.tcl','.xdc','.ps1','.sh','.py',
            '.json','.csv','.sha256','.log','.rpt','.txt','.do','.f'}


def eligible(p,root):
    parts=p.relative_to(root).parts
    return (not any(x in EXCLUDED or x.startswith('obj') for x in parts)
            and p.suffix in SUFFIXES and p.name not in
            {'archive_manifest.json','retention.json'} and p.stat().st_size < 10*1024*1024)


def main():
    collect()
    final=R/'results/optcombo_20261018'
    assert (final/'acceptance_status.txt').read_text().strip()=='COMPLETE'
    assert (final/'modelsim/status.txt').read_text().strip()=='COMPLETE'
    assert (final/'fused_event_v2/status.txt').read_text().strip()=='COMPLETE'
    for study in STUDIES:
        if (R/'results'/study/'summary.json').exists():
            assert not json.loads((R/'results'/study/'summary.json').read_text())['pending_ppa']
    for study in STUDIES:
        root=R/'results'/study
        if not root.exists():continue
        target=root/'evidence.zip'
        if target.exists():raise RuntimeError('Preserve existing archive')
        files={}
        with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
            for p in sorted(root.rglob('*')):
                if p.is_file() and eligible(p,root):
                    name=p.relative_to(root).as_posix()
                    data=p.read_bytes()
                    z.writestr(name,data)
                    files[name]={'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)}
        with zipfile.ZipFile(target) as z:
            assert z.testzip() is None
            for name,info in files.items():
                assert hashlib.sha256(z.read(name)).hexdigest()==info['sha256']
        (root/'archive_manifest.json').write_text(json.dumps({'files':files,
            'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
            'archive_bytes':target.stat().st_size},indent=2)+'\n')
        removed=[]
        directories=[p for p in root.rglob('*') if p.is_dir() and
                     (p.name in EXCLUDED or p.name.startswith('obj'))]
        # Validate absolute targets stay under the explicitly created study roots.
        # Never touch source, fixture, logs or old studies; keep routed DCP locally.
        for p in sorted(directories,key=lambda p:len(p.parts)):
            if not p.exists():continue
            resolved=p.resolve()
            assert resolved.is_relative_to(root.resolve()) and resolved != root.resolve()
            size=sum(f.stat().st_size for f in p.rglob('*') if f.is_file())
            removed.append({'path':p.relative_to(root).as_posix(),'bytes':size})
            shutil.rmtree(p)
        (root/'retention.json').write_text(json.dumps({'removed_build_caches':removed,
            'bytes_freed':sum(x['bytes'] for x in removed),
            'preserved':'source, reports, command/hash, native inputs, fixtures and local routed checkpoints'},indent=2)+'\n')
        print(study,target.stat().st_size,sum(x['bytes'] for x in removed))


if __name__=='__main__':main()
