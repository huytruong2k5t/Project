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
    if manifest.get('parent_release')=='POSIT_MAC_RTL_20261018_OPT02C':
        evidence=manifest['evidence']
        study=root/evidence['study']
        for name,key in (('summary.json','summary_sha256'),
                         ('qualification.json','qualification_sha256'),
                         ('reference_freeze.json','reference_freeze_sha256')):
            assert sha(study/name)==evidence[key],f'Release evidence changed: {name}'
        qualified=json.loads((study/'qualification.json').read_text())
        assert qualified['summary_sha256']==evidence['summary_sha256']
        for name,digest in qualified['recommendation']['source_sha256'].items():
            assert sha(root/name)==digest,f'Production differs from tested OPT12: {name}'
        variants=json.loads((study/'variants.json').read_text())
        assert manifest['rtl_sha256']==variants['variants']['negate']
        recipe=json.loads((root/'syn/opt12_120mhz_release.json').read_text())
        assert recipe['release_id']==manifest['release_id']
        assert recipe['part']=='xc7a35tcpg236-1' and recipe['strategy']=='Explore'
        assert recipe['clock_ns']==8.3
        assert [recipe[key] for key in ('input_min_ns','input_max_ns','output_min_ns','output_max_ns')]==[2.5,2.5,0,0.5]
        assert '-period 8.300' in (root/recipe['clock_xdc']).read_text()
        summary=json.loads((study/'summary.json').read_text())
        assert {row['top'] for row in recipe['qualified_runs']}=={'nf','f'}
        for row in recipe['qualified_runs']:
            assert row in summary['ppa'] and row['full_timing_pass']
            assert row['variant']=='negate' and row['strategy']=='Explore' and row['clock_ns']==8.3
        for top in ('nf','f'):
            run=summary['stress']['negate'][top]
            assert run['completed']==10000000 and run['mismatches']==0
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
