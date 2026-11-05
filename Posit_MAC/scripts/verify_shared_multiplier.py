#!/usr/bin/env python3
"""Source-bound FULL_TERM build and replay. All generated data stays in project."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/os.environ.get('SHARED_RESULTS_ROOT','results/nf_f_lock_20261105')
OUT.mkdir(parents=True,exist_ok=True)
TMP = OUT/'tmp'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def sources():
    return [p.strip() for p in (ROOT/'rtl/mac_active.f').read_text().splitlines() if p.strip()]
def execute(args,cwd,log):
    env=os.environ.copy(); TMP.mkdir(exist_ok=True)
    env['TMPDIR']=str(TMP); env['PYTHONPYCACHEPREFIX']=str(TMP/'pycache')
    with log.open('w') as f:
        result=subprocess.run(args,cwd=cwd,env=env,stdout=f,stderr=subprocess.STDOUT)
    if result.returncode:
        print(log.read_text(errors='replace')[-6000:])
        raise RuntimeError(f'Command failed: {args[0]} ({result.returncode})')
def build(kind):
    tag=os.environ.get('SHARED_BUILD_TAG','v2')
    if not tag.replace('_','').isalnum(): raise ValueError('Simple build tag required')
    target=OUT/('obj_'+kind+'_'+tag)
    if target.exists(): raise RuntimeError('Preserve build directory; choose a fresh build tag in runner')
    target.mkdir()
    top='shared_multiplier_units' if kind=='units' else 'shared_mac_checker'
    cpp='tb/shared_multiplier_units.cpp' if kind=='units' else 'tb/shared_mac_harness.cpp'
    shutil.copyfile(ROOT/cpp,target/Path(cpp).name)
    paths=sources()+[f'tb/{top}.sv']
    relative_root=Path(os.path.relpath(ROOT,target)).as_posix()
    (target/'sources.f').write_text(''.join(relative_root+'/'+p+'\n' for p in paths))
    cflags=f'-O3 -std=c++17 -I{relative_root}/tb -I{relative_root}/tb/opt17 -I{relative_root}/l1/include'
    if kind!='units': cflags+=f' -DTEST_FUSED={int(kind=="f")}'
    args=['verilator','--cc','--exe','--timing','--timescale-override','1ns/1ps','--assert','-Wall',
          '-I'+relative_root+'/rtl','--top-module',top,'-f','sources.f',Path(cpp).name,
          '--Mdir','.', '-CFLAGS',cflags]
    if kind!='units': args+=['-GFUSED='+str(int(kind=='f'))]
    coverage=kind!='units' and os.environ.get('SHARED_COVERAGE','0')=='1'
    if coverage: args+=['--coverage']
    inputs=paths+['rtl/mac_active.f','rtl/posit_mac.vh',cpp,'scripts/verify_shared_multiplier.py']
    inputs+=['tb/opt17/full_term_reference.hpp','tb/week12_fused_reference.hpp']
    if kind!='units': inputs+=['tb/nf_f_functional_coverage.hpp']
    inputs += [str(p.relative_to(ROOT)) for p in (ROOT/'l1/include').glob('*.hpp')]
    input_hashes={p:sha(ROOT/p) for p in sorted(set(inputs))}
    execute(args,target,OUT/('generate_'+kind+'_'+tag+'.log'))
    # Verilator's make include checks CURDIR for whitespace. All source/include
    # paths here are relative, so a command-line CURDIR=. is accurate for the
    # compiler and avoids any filesystem writes outside the project.
    make_args=['make','-f','V'+top+'.mk','-j4','CURDIR=.']
    execute(make_args,target,OUT/('build_'+kind+'_'+tag+'.log'))
    for p,digest in input_hashes.items():
        if sha(ROOT/p)!=digest: raise RuntimeError('Source changed during build: '+p)
    manifest={'kind':kind,'binary':str((target/('V'+top)).relative_to(ROOT)),
              'command':args,'make_command':make_args,'cwd':str(target.relative_to(ROOT)),
              'coverage_enabled':coverage,'source_sha256':input_hashes,
              'verilator':subprocess.check_output(['verilator','--version'],text=True).strip(),
              'compiler':subprocess.check_output(['g++','--version'],text=True).splitlines()[0]}
    (OUT/('build_'+kind+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
    print('SHARED_BUILD_PASS',kind)
def load(kind):
    m=json.loads((OUT/('build_'+kind+'.json')).read_text())
    for p,digest in m['source_sha256'].items():
        if sha(ROOT/p)!=digest: raise RuntimeError('Source changed since build: '+p)
    return ROOT/m['binary']
def run_units():
    binary=load('units'); report=OUT/'units.json'
    execute([str(binary),str(report)],ROOT,OUT/'units.log')
    print(report.read_text().strip())
def run_mac(kind,count,label,n,ops):
    if not label.replace('_','').isalnum(): raise ValueError('Simple run label required')
    report=OUT/(label+'_'+kind+'.json')
    if report.exists(): raise RuntimeError('Preserve existing report')
    binary=load(kind)
    args=[str(binary),str(count),str(n),str(ops),os.environ.get('SHARED_SEED','20261105'),str(report)]
    execute(args,ROOT,report.with_suffix('.log'))
    print(report.read_text().strip())
if __name__=='__main__':
    if sys.argv[1]=='build': build(sys.argv[2])
    elif sys.argv[1]=='units': run_units()
    elif sys.argv[1]=='run': run_mac(sys.argv[2],int(sys.argv[3]),sys.argv[4],int(sys.argv[5]),int(sys.argv[6]))
    else: raise SystemExit('build units|nf|f; units; run nf|f COUNT LABEL N OPS')
