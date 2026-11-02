#!/usr/bin/env python3
"""Package verified source and compact quire evidence, without local products."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/quire_20261103'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))


def bundle(path,files):
    if path.exists():raise RuntimeError('Preserve existing bundle: '+str(path))
    manifest={name:sha(ROOT/name) for name in sorted(files)}
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for name in manifest:z.write(ROOT/name,name)
        z.writestr('BUNDLE_MANIFEST.json',json.dumps(manifest,indent=2)+'\n')
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        for name,expected in manifest.items():assert hashlib.sha256(z.read(name)).hexdigest()==expected,name
    return manifest


def main():
    summary=load(OUT/'summary.json')
    assert summary['status']=='FUNCTION_VERIFIED_TIMING_OPEN' and not summary['MAC_Q12_VERIFIED']
    sources={'.gitattributes','.gitignore','Makefile','README.md','SPEC_Posit_MAC_IP.md','Digital_Design_Guidelines.md',
             'rtl/mac_active.f','rtl/quire_active.f','rtl/posit_mac.vh','rtl/shared_multiplier_checkpoint.json',
             'rtl/README.md','rtl/multiplier/README.md','rtl/common/README.md','l1/README.md','l1/PLAN.md',
             'tb/README.md','scripts/README.md','results/README.md',
             'docs/TIEN_DO_DO_AN.md','docs/HUONG_DAN_CHAY_WSL_MODELSIM.md'}
    for name in ('mac_active.f','quire_active.f'):
        sources.update(p for p in (ROOT/'rtl'/name).read_text().splitlines() if p.strip())
    for name in ('build_rtl_final.json','build_units_final.json','model_manifest.json','ports_and_lint.json',
                 'modelsim_signoff/manifest.json','ppa_final/manifest.json'):
        m=load(OUT/name);sources.update(p for p in m['source_sha256'] if not p.startswith('results/'))
    sources.update(p for p in load(OUT/'nf_f_retained_tests/manifest.json')['sha256'] if not p.startswith('results/'))
    sources.update(p.relative_to(ROOT).as_posix() for p in (ROOT/'tb').rglob('*') if p.is_file())
    sources.update(p.relative_to(ROOT).as_posix() for p in (ROOT/'scripts').iterdir() if p.is_file())
    sources.add('syn/quire_ooc.tcl')
    # Only active retained files; cache/binary/waves were removed before this step.
    assert not any('/work/' in p or '/obj_' in p or p.endswith(('.wlf','.exe','.o','.vcd')) for p in sources)
    source_zip=OUT/'verified_sources.zip'
    source_hashes=bundle(source_zip,sources)
    evidence={p.relative_to(ROOT).as_posix() for p in OUT.iterdir() if p.is_file() and p.suffix!='.zip'}
    for folder in ('python_vectors','modelsim_signoff','nf_f_retained_tests','ppa_final','lint'):
        for path in (OUT/folder).rglob('*'):
            if not path.is_file():continue
            rel=path.relative_to(OUT/folder)
            if rel.parts[0]=='source':continue
            assert not any(x in rel.parts for x in ('work','tmp','.Xil','appdata','localappdata'))
            assert path.suffix not in ('.wlf','.vcd','.fst','.o','.exe')
            evidence.add(path.relative_to(ROOT).as_posix())
    evidence_zip=OUT/'verified_evidence.zip'
    bundle(evidence_zip,evidence)
    archives=[source_zip,evidence_zip,
              ROOT/'archive/legacy_tb_runners_before_quire_20261103.zip',
              ROOT/'archive/current_modelsim_runner_before_portable_20261103.zip',
              ROOT/'archive/quire_docs_before_results_20261103.zip',
              ROOT/'archive/quire_preliminary_20261103.zip']
    checkpoint={'id':'POSIT_MAC_QUIRE_Q12_1024_20261103_FUNCTION',
                'status':summary['status'],'MAC_Q12_VERIFIED':False,
                'configuration':summary['configuration'],'source_sha256':source_hashes,
                'summary_sha256':sha(OUT/'summary.json'),
                'archives':{p.relative_to(ROOT).as_posix():sha(p) for p in archives},
                'main_mac_retired':10000000,'mismatches':0,
                'remaining':summary['remaining'],'PPA':summary['PPA']}
    (ROOT/'rtl/quire_checkpoint.json').write_text(json.dumps(checkpoint,indent=2)+'\n')
    print('QUIRE_PACKAGE_PASS',len(sources),'source files',len(evidence),'evidence files',
          source_zip.stat().st_size,evidence_zip.stat().st_size,'bytes')


if __name__=='__main__':main()
