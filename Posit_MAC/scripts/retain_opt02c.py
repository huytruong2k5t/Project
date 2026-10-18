"""Keep compact, verified release evidence; delete only owned build caches."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
from audit_rtl_release import validate

R = Path(__file__).resolve().parents[1]
ROOT = R / 'results/opt02c_20261018'
CACHES = {'work', 'tmp', 'appdata', 'localappdata', '.Xil', '__pycache__'}
SUFFIXES = {'.sv','.vh','.cpp','.hpp','.h','.vlt','.tcl','.xdc','.ps1','.sh',
            '.py','.json','.csv','.sha256','.log','.rpt','.txt','.do','.f','.vectors'}


def main():
    validate(json.loads((R/'rtl/production_freeze.json').read_text()))
    target = ROOT/'evidence.zip'
    assert not target.exists(), 'Preserve existing archive'
    files = {}
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path in sorted(ROOT.rglob('*')):
            if not path.is_file():
                continue
            parts = path.relative_to(ROOT).parts
            if any(p in CACHES or p.startswith('obj') for p in parts):
                continue
            if path.suffix not in SUFFIXES or path.stat().st_size > 32*1024*1024:
                continue
            if path.name in {'archive_manifest.json','retention.json'}:
                continue
            payload = path.read_bytes()
            name = path.relative_to(ROOT).as_posix()
            archive.writestr(name,payload)
            files[name] = {'sha256':hashlib.sha256(payload).hexdigest(),'bytes':len(payload)}
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        for name, record in files.items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == record['sha256']
    # Frozen sources, transcripts, fixtures and reports are all checked above.
    (ROOT/'archive_manifest.json').write_text(json.dumps({
        'files':files, 'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
        'archive_bytes':target.stat().st_size,
        'excluded':'binaries, checkpoints, work/obj/runtime caches, waves; regenerate from saved sources/commands'
    },indent=2)+'\n',encoding='utf-8')
    removed=[]
    directories=[p for p in ROOT.rglob('*') if p.is_dir() and
                 (p.name in CACHES or p.name.startswith('obj'))]
    for path in sorted(directories,key=lambda p:len(p.parts)):
        if not path.exists():
            continue
        absolute=path.resolve()
        assert absolute.is_relative_to(ROOT.resolve()) and absolute!=ROOT.resolve()
        size=sum(p.stat().st_size for p in path.rglob('*') if p.is_file())
        removed.append({'path':path.relative_to(ROOT).as_posix(),'bytes':size})
        shutil.rmtree(path)
    (ROOT/'retention.json').write_text(json.dumps({
        'removed_build_caches':removed,'bytes_freed':sum(p['bytes'] for p in removed),
        'preserved':'source, reports, fixtures, runner failures and local routed DCPs; verified evidence.zip'
    },indent=2)+'\n',encoding='utf-8')
    print('Verified archive:',len(files),'files,',target.stat().st_size,'bytes')
    print('Removed owned build caches:',sum(p['bytes'] for p in removed),'bytes')


if __name__=='__main__':
    main()
