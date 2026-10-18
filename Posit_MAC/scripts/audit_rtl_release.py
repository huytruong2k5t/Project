"""Read-only release gate for W14: any frozen RTL/model/constraint edit fails."""
from pathlib import Path
import copy
import hashlib
import json
import re
import sys

R=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def validate(manifest,root=R):
    assert manifest['status']=='LOCKED_FOR_W14','RTL release is not locked'
    for group in ('rtl_sha256','model_sha256','build_contract_sha256'):
        for name,digest in manifest[group].items():
            assert sha(root/name)==digest,f'Frozen {group} changed: {name}'
    names=(root/'rtl/production.f').read_text().splitlines()
    assert names==manifest['production_files'] and len(names)==38
    modules=[]
    for name in names:
        assert not any(x in name.split('/') for x in ('candidates','research','benchmarks'))
        code=(root/name).read_text(encoding='utf-8-sig')
        found=re.findall(r'^module\s+(\w+)',code,re.M)
        assert found==[Path(name).stem],name
        modules+=found
    assert len(modules)==len(set(modules))
    maps=json.loads((root/'scripts/rtl_paths.json').read_text())
    tsv=dict(line.split('\t') for line in (root/'scripts/rtl_paths.tsv').read_text().splitlines())
    assert maps==tsv
    for name in names:assert maps['rtl/'+Path(name).name]==name
    for name in (root/'scripts/week13_sources.txt').read_text().splitlines():assert name in names
    return True


def main():
    path=R/'rtl/production_freeze.json'
    if not path.exists():raise SystemExit('BLOCKED: no locked release; finish promotion qualification first')
    manifest=json.loads(path.read_text())
    validate(manifest)
    if '--self-test' in sys.argv:
        rejected=0
        for group in ('rtl_sha256','model_sha256','build_contract_sha256'):
            bad=copy.deepcopy(manifest)
            name=next(iter(bad[group]));bad[group][name]='0'*64
            try:validate(bad)
            except AssertionError:rejected+=1
        bad=copy.deepcopy(manifest);bad['status']='RUNNING'
        try:validate(bad)
        except AssertionError:rejected+=1
        assert rejected==4
        print('Freeze anti-tamper guards: 4/4 rejected in-memory mutations; live data untouched')
    print('RTL RELEASE PASS '+manifest['release_id']+'; 38 modules, frozen model/build contract unchanged')


if __name__=='__main__':main()
