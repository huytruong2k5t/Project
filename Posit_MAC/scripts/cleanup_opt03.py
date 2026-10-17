"""Dry-run or remove only regenerable OPT-03 artifacts after proof is archived."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

R=Path(__file__).resolve().parents[1]
O=(R/'results/opt03_20261017').resolve()
assert len(sys.argv)==2 and sys.argv[1] in ['dry-run','apply']
assert json.loads((O/'summary.json').read_text())['status']=='PASS_OPT03_SCOPE'
manifest=json.loads((O/'archive_manifest.json').read_text())
assert hashlib.sha256((O/'evidence.zip').read_bytes()).hexdigest()==manifest['archive_sha256']
skip={'obj_fast','obj_dir','work','tmp','.Xil','appdata','localappdata','__pycache__','-p'}
suffix={'.dcp','.wlf','.wdb','.jou','.so'}
targets=[]
for root in [O,(R/'results/opt03_replay_smoke').resolve()]:
    assert root.is_relative_to((R/'results').resolve()) and root.name.startswith('opt03_')
    for p in sorted(root.rglob('*'),key=lambda x:len(x.parts)):
        if any(p.is_relative_to(x) for x in targets):continue
        if (p.is_dir() and p.name in skip) or (p.is_file() and (p.suffix in suffix or p.name in {'modelsim.ini','transcript'})):
            resolved=p.resolve()
            assert resolved.is_relative_to(root) and resolved!=root
            targets.append(resolved)
for name,digest in manifest['files'].items():
    p=O/name
    assert not any(p.resolve().is_relative_to(t) for t in targets), name
    assert hashlib.sha256(p.read_bytes()).hexdigest()==digest,name
sizes={str(p.relative_to(R)):sum(f.stat().st_size for f in p.rglob('*') if f.is_file()) if p.is_dir() else p.stat().st_size for p in targets}
print(json.dumps(dict(mode=sys.argv[1],targets=len(targets),bytes=sum(sizes.values())),indent=2))
if sys.argv[1]=='apply':
    for p in targets:
        # Resolve and check immediately before recursive deletion on Windows.
        assert p.resolve()==p and any(p.is_relative_to(root) for root in [O,(R/'results/opt03_replay_smoke').resolve()])
        if p.is_dir():shutil.rmtree(p)
        else:p.unlink()
    for name,digest in manifest['files'].items():
        assert hashlib.sha256((O/name).read_bytes()).hexdigest()==digest,name
    (O/'cleanup_summary.json').write_text(json.dumps(dict(status='PASS',removed=sizes,total_bytes=sum(sizes.values())),indent=2)+'\n')
