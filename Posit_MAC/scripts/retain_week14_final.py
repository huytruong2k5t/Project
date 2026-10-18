"""Compact final delta archive, preserving the immutable W14-06 archive."""
from pathlib import Path
import hashlib,json,zipfile
from audit_week14 import R,O,sha,load


def main():
    completion=load(O/'completion.json');assert completion['total_completed']==350000000 and completion['mismatches']==0
    archive=O/'evidence_w14_final.zip';assert not archive.exists()
    old=load(O/'archive_manifest.json');assert sha(O/old['archive'])==old['archive_sha256']
    allowed={'.cpp','.hpp','.sv','.vh','.vlt','.h','.xdc','.tcl','.sh','.ps1','.py',
             '.txt','.json','.jsonl','.log','.sha256','.dat','.hex','.do','.csv'}
    skip={'obj','obj_fast','obj_dir','__pycache__','pycache','pycache_win','tmp','work','.Xil','appdata','localappdata'}
    files={}
    for p in O.rglob('*'):
        if not p.is_file() or set(p.relative_to(O).parts)&skip or p.suffix not in allowed:continue
        name=p.relative_to(O).as_posix()
        if name in ('final_archive_manifest.json','handoff.json'):continue
        if old['files'].get(name)==sha(p):continue
        files[name]=p
    for directory in ('scripts','tb'):
        for p in (R/directory).glob('*week14*'):
            if not p.is_file():continue
            name='external_inputs/'+p.relative_to(R).as_posix()
            if old['files'].get(name)!=sha(p):files[name]=p
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for name,p in sorted(files.items()):z.write(p,name)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for name,p in files.items():assert hashlib.sha256(z.read(name)).hexdigest()==sha(p)
    manifest=dict(archive=archive.name,archive_sha256=sha(archive),archive_bytes=archive.stat().st_size,
        predecessor_archive=old['archive'],predecessor_sha256=old['archive_sha256'],
        files={name:sha(p) for name,p in sorted(files.items())},
        retention='Delta plus preserved predecessor = complete W14 evidence; no binary/cache/wave/DCP, no local deletion. Restore only in new workspace, verify both manifests.')
    (O/'final_archive_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    handoff=dict(status='PASS_W14_01_THROUGH_11_LOCAL_READY_FOR_GIT_BACKUP',
        verification_sha256=sha(O/'completion.json'),archive_sha256=sha(archive),
        archive_manifest_sha256=sha(O/'final_archive_manifest.json'),release_sha256=completion['release_sha256'],
        completed=350000000,mismatches=0,W14_12='DEFERRED_OPEN_AC02',
        backup='Successful ordinary Git push must be verified externally; this artifact does not claim a push or board/PPA signoff.')
    (O/'handoff.json').write_text(json.dumps(handoff,indent=2)+'\n',encoding='utf-8')
    print('W14 FINAL ARCHIVE CRC/SHA PASS',len(files),'delta files',archive.stat().st_size,'bytes; predecessor preserved')


if __name__=='__main__':main()
