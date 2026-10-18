"""Archive trial evidence and remove only generated caches within this study."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
from audit_opt12 import R,O,collect,sha,read

CACHES={'work','tmp','appdata','localappdata','.Xil','__pycache__'}
EXTENSIONS={'.sv','.vh','.cpp','.hpp','.h','.vlt','.tcl','.xdc','.ps1','.sh',
            '.py','.json','.csv','.sha256','.log','.rpt','.txt','.do','.f','.vectors','.dat'}


def main():
    result=collect()
    qualification=json.loads(read(O/'qualification.json'))
    assert qualification['status']=='TRIAL_COMPLETE_PENDING_USER_SELECTION'
    assert sha(O/'summary.json')==qualification['summary_sha256']
    target=O/'evidence.zip';assert not target.exists(),'Preserve existing archive'
    files={}
    def store(archive,name,payload,origin):
        assert name not in files
        archive.writestr(name,payload)
        files[name]={'sha256':hashlib.sha256(payload).hexdigest(),'bytes':len(payload),'origin':origin}
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path in sorted(O.rglob('*')):
            if not path.is_file():continue
            parts=path.relative_to(O).parts
            if any(p in CACHES or p.startswith('obj') for p in parts):continue
            if path.suffix not in EXTENSIONS or path.stat().st_size>32*1024*1024:continue
            if path.name in ('archive_manifest.json','retention.json'):continue
            store(archive,path.relative_to(O).as_posix(),path.read_bytes(),'study')
        # Preserve externally bound NF fixture bytes as well. Restoring them to
        # existing paths requires a hash check; never overwrite a different file.
        fixture_names=set()
        for variant in ('sentinel','negate'):
            fixture_names.update(json.loads(read(O/f'event_{variant}/fixture_sha256.json')))
        for name in sorted(fixture_names):
            if not name.startswith('results/opt02b_20261017/'):continue
            path=(R/name).resolve();assert path.is_relative_to(R.resolve())
            store(archive,'external_inputs/'+name,path.read_bytes(),name)
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        for name,record in files.items():assert hashlib.sha256(archive.read(name)).hexdigest()==record['sha256']
    (O/'archive_manifest.json').write_text(json.dumps({'sha256':sha(target),'archive_bytes':target.stat().st_size,
        'files':files,'scope':'Verified sources, reports, raw counters, fixtures and failed setup log; excludes binary/wave/DCP caches'},indent=2)+'\n',encoding='utf-8')
    removed=[]
    directories=[p for p in O.rglob('*') if p.is_dir() and (p.name in CACHES or p.name.startswith('obj'))]
    for path in sorted(directories,key=lambda p:len(p.parts)):
        if not path.exists():continue
        resolved=path.resolve();assert resolved.is_relative_to(O.resolve()) and resolved!=O.resolve()
        size=sum(p.stat().st_size for p in path.rglob('*') if p.is_file())
        removed.append({'path':path.relative_to(O).as_posix(),'bytes':size});shutil.rmtree(path)
    waves=[]
    for path in O.rglob('*.wlf'):
        assert path.resolve().is_relative_to(O.resolve())
        waves.append({'path':path.relative_to(O).as_posix(),'bytes':path.stat().st_size});path.unlink()
    (O/'retention.json').write_text(json.dumps({'removed_caches':removed,'removed_waves':waves,
        'bytes_freed':sum(p['bytes'] for p in removed+waves),
        'preserved':'sources, model inputs, fixtures, reports, line coverage and routed checkpoints locally; compact verified archives in Git'},indent=2)+'\n',encoding='utf-8')
    print('Verified archive',len(files),'files;',target.stat().st_size,'bytes; freed',sum(p['bytes'] for p in removed+waves),'bytes')


if __name__=='__main__':main()
