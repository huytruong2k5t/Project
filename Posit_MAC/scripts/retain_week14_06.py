"""Package compact, byte-checked W14 evidence; never delete an active build."""
from pathlib import Path
import hashlib
import json
import zipfile

R=Path(__file__).resolve().parents[1];O=R/'results/week14'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    summary=json.loads((O/'summary.json').read_text(encoding='utf-8'))
    assert summary['status']=='PASS_W14_01_THROUGH_06_ONLY'
    archive=O/'evidence_w14_06.zip'
    assert not archive.exists()
    extensions={'.cpp','.hpp','.sv','.vh','.vlt','.h','.xdc','.tcl','.sh','.ps1','.py',
                '.txt','.json','.jsonl','.log','.sha256','.dat','.hex','.do'}
    files={}
    skipped={'obj','obj_fast','obj_dir','__pycache__','pycache','tmp','work','.Xil','appdata','localappdata'}
    for p in O.rglob('*'):
        if p.is_file() and not set(p.relative_to(O).parts)&skipped and p.suffix in extensions:
            files[p.relative_to(O).as_posix()]=p
    # Include exact runner/test sources and external review reports inside the archive.
    for directory in ('scripts','tb'):
        for p in (R/directory).glob('*week14*'):
            if p.is_file():files['external_inputs/'+p.relative_to(R).as_posix()]=p
    review=json.loads((O/'w14_01_review.json').read_text())
    for paths in review['evidence'].values():
        for name in paths:files['external_inputs/'+name.replace('\\','/')]=R/name
    for name in ('rtl/production_freeze.json','syn/opt12_120mhz_release.json',
                 'syn/constraints/a35t_clock_120mhz.xdc','syn/constraints/a35t_benchmark_100mhz.xdc'):
        files['external_inputs/'+name]=R/name
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for name,path in sorted(files.items()):z.write(path,name)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for name,path in files.items():assert hashlib.sha256(z.read(name)).hexdigest()==sha(path),name
    manifest=dict(archive=archive.name,archive_sha256=sha(archive),archive_bytes=archive.stat().st_size,
                  files={name:sha(path) for name,path in sorted(files.items())},
                  retention='Source/log/report/raw coverage and failures retained; binary/obj/cache/wave excluded from Git, local rebuild caches preserved while frozen receipts reference them')
    (O/'archive_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('W14 compact archive CRC/SHA PASS',len(files),'files',archive.stat().st_size,'bytes; no local deletion')


if __name__=='__main__':main()
