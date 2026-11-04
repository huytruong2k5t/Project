"""Freeze the two current NF/F source versions after source-bound regression."""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'results/nf_f_lock_20261105/final'
PACKAGE=ROOT/'releases/nf_f_20261105'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert not PACKAGE.exists(), 'Never overwrite a locked version'
    audit=json.loads((RUN/'ports_and_lint.json').read_text())
    assert audit['status']=='PASS' and audit['active_modules']==31
    units=json.loads((RUN/'units.json').read_text());assert units['status']=='PASS' and units['mismatches']==0
    inputs=set();reports={};builds={}
    for kind in ['units','nf','f']:
        build=json.loads((RUN/('build_'+kind+'.json')).read_text());builds[kind]=build
        for rel,h in build['source_sha256'].items():
            assert sha(ROOT/rel)==h, rel
            inputs.add(rel)
    simulation=json.loads((RUN/'modelsim/manifest.json').read_text(encoding='utf-8-sig'))
    assert (RUN/'modelsim/verify/status.txt').read_text(encoding='utf-8-sig').strip()=='PASS'
    for rel,h in simulation['sha256'].items():
        assert sha(ROOT/rel).lower()==h.lower(),rel
        inputs.add(rel)
    for variant in ['nf','f']:
        r=json.loads((RUN/('locked_mixed_'+variant+'.json')).read_text())
        assert r['status']=='PASS' and r['completed']==100000 and r['mismatches']==0
        assert r['accepted']==r['completed']+r['reset_aborted'] and all(r['bins'])
        reports[variant]=r
    inputs.update(['rtl/mac_active.f','rtl/posit_mac.vh','SPEC_Posit_MAC_IP.md',
        'Makefile','scripts/audit_shared_multiplier.py','scripts/freeze_current_nf_f.py'])
    PACKAGE.mkdir(parents=True)
    source_hashes={}
    for rel in sorted(inputs):
        target=PACKAGE/'source'/rel;target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/rel,target);source_hashes[rel]=sha(target)
    paths=[p for p in (ROOT/'rtl/mac_active.f').read_text().splitlines() if p.strip()]
    texts={Path(p).stem:re.sub(r'//[^\n]*|/\*.*?\*/','',(ROOT/p).read_text(),flags=re.S) for p in paths}
    edges={n:{c for c in texts if re.search(r'\b'+c+r'\s+\w+\s*\(',s)} for n,s in texts.items()}
    evidence={}
    for p in RUN.glob('*.json'):
        if p.name=='cleanup_plan.json':continue
        evidence[p.relative_to(ROOT).as_posix()]=sha(p)
    evidence[(RUN/'modelsim/manifest.json').relative_to(ROOT).as_posix()]=sha(RUN/'modelsim/manifest.json')
    for name in ['adder','packer','core','nf','f']:
        rel=(RUN/'modelsim/verify'/(name+'.log')).relative_to(ROOT).as_posix()
        evidence[rel]=sha(ROOT/rel)
    records=[]
    for variant in ['nf','f']:
        top='posit_mac_'+variant;needed=set();todo=[top]
        while todo:
            n=todo.pop()
            if n not in needed:needed.add(n);todo.extend(edges[n]-needed)
        files=[p for p in paths if Path(p).stem in needed]
        filename='rtl/mac_'+variant+'.f'
        (PACKAGE/'source'/filename).write_text(''.join(p+'\n' for p in files))
        source_hashes[filename]=sha(PACKAGE/'source'/filename)
        dut={rel:source_hashes[rel] for rel in files+['rtl/posit_mac.vh',filename]}
        timing=None
        old=ROOT/'results/nf_parser_recheck_20261104/manifest.json'
        if variant=='nf' and old.exists():
            previous=json.loads(old.read_text(encoding='utf-8-sig'))['sha256']
            if all(previous.get(p,'').lower()==sha(ROOT/p).lower() for p in files+['rtl/posit_mac.vh']):
                timing={'report':'results/nf_parser_recheck_20261104/summary.json',
                    'source_match':True,'scope':'Historical synthesis only; not route/timing signoff'}
        record={'id':'MAC_'+variant.upper()+'_POSIT32_ES3_FULLTERM_20261105',
            'top':top,'status':'SOURCE_LOCKED_REGRESSION_VERIFIED','final_acceptance_release':False,
            'date':'2026-11-05','configuration':{'nb':32,'es':3,'fraction_bits':12,
                'product_bits':26,'product_fractional_bits':24,'n_range':[0,12],'ops':[0,1],
                'feed_forward':True,'internal_posit_feedback':False,'rounding':'RNE'},
            'rtl_modules':len(files),'dut_source_sha256':dut,
            'verification':{'verilator_completed':reports[variant]['completed'],
                'mismatches':0,'modelsim_completed':9940,'modelsim_reset_aborted':60,
                'strict_lint_modules':31,'main_52x10M':False,'new_coverage_signoff':False},
            'evidence_sha256':evidence,'matching_synthesis':timing,
            'timing_signoff':False}
        (PACKAGE/(variant+'.lock.json')).write_text(json.dumps(record,indent=2)+'\n')
        records.append({'variant':variant,'id':record['id'],'manifest':(PACKAGE/(variant+'.lock.json')).relative_to(ROOT).as_posix(),
                        'manifest_sha256':sha(PACKAGE/(variant+'.lock.json'))})
    (PACKAGE/'source.sha256.json').write_text(json.dumps(source_hashes,indent=2)+'\n')
    index={'status':'LOCKED','versions':records,'package':PACKAGE.relative_to(ROOT).as_posix(),
           'source_index_sha256':sha(PACKAGE/'source.sha256.json')}
    (ROOT/'releases/current.json').write_text(json.dumps(index,indent=2)+'\n')
    print('NF_F_SOURCE_LOCKED',[(r['variant'],r['id']) for r in records],len(source_hashes),'shared inputs')


if __name__=='__main__':main()
