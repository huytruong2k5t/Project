#!/usr/bin/env python3
"""Portable Q12-1024 build/replay; no home/config writes or fixed tool paths."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/quire_20261103'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inputs(kind='rtl'):
    paths=(ROOT/'rtl/quire_active.f').read_text().splitlines()
    paths+=['rtl/quire_active.f','rtl/posit_mac.vh','tb/quire_checker.sv','tb/quire_harness.cpp',
            'tb/quire_reference.hpp','tb/opt17/full_term_reference.hpp','tb/week12_fused_reference.hpp',
            'scripts/verify_quire.py']
    paths += [p.relative_to(ROOT).as_posix() for p in (ROOT/'l1/include').glob('*.hpp')]
    if kind=='units': paths+=['tb/quire_units.sv','tb/quire_units.cpp']
    return {p:sha(ROOT/p) for p in sorted(set(p for p in paths if p.strip()))}


def execute(command,cwd,log):
    env=os.environ.copy();(OUT/'tmp').mkdir(parents=True,exist_ok=True)
    env['TMPDIR']=str(OUT/'tmp');env['TMP']=str(OUT/'tmp');env['TEMP']=str(OUT/'tmp')
    with log.open('w') as stream:
        p=subprocess.run(command,cwd=cwd,env=env,stdout=stream,stderr=subprocess.STDOUT)
    if p.returncode:
        print(log.read_text(errors='replace')[-6000:])
        raise RuntimeError('Command failed: '+str(command))


def build(args):
    target=OUT/('obj_'+args.tag)
    if target.exists():raise RuntimeError('Use a fresh --tag; preserve previous build')
    target.mkdir(parents=True)
    top='quire_units' if args.kind=='units' else 'quire_checker'
    cpp='quire_units.cpp' if args.kind=='units' else 'quire_harness.cpp'
    sources=(ROOT/'rtl/quire_active.f').read_text().splitlines()+['tb/'+top+'.sv']
    (target/'sources.f').write_text(''.join('../../../'+p+'\n' for p in sources if p.strip()))
    shutil.copyfile(ROOT/'tb'/cpp,target/cpp)
    command=['verilator','--cc','--exe','--timing','--timescale-override','1ns/1ps','--assert',
             '-Wall','-I../../../rtl','--top-module',top,'-f','sources.f',
             cpp,'--Mdir','.',
             '-CFLAGS','-O3 -std=c++17 -I../../../tb -I../../../l1/include']
    if args.coverage:command+=['--coverage']
    before=inputs(args.kind)
    execute(command,target,OUT/('generate_'+args.tag+'.log'))
    make=['make','-f','V'+top+'.mk','-j4','CURDIR=.']
    execute(make,target,OUT/('build_'+args.tag+'.log'))
    if before!=inputs(args.kind):raise RuntimeError('Source changed during build')
    manifest={'source_sha256':before,'command':command,'make_command':make,
              'binary':(target/('V'+top)).relative_to(ROOT).as_posix(),'kind':args.kind,
              'cwd':target.relative_to(ROOT).as_posix(),'coverage':args.coverage,
              'verilator':subprocess.check_output(['verilator','--version'],text=True).strip(),
              'compiler':subprocess.check_output(['g++','--version'],text=True).splitlines()[0]}
    (OUT/('build_'+args.tag+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
    print('QUIRE_BUILD_PASS',args.tag)


def run(args):
    manifest=json.loads((OUT/('build_'+args.tag+'.json')).read_text())
    for path,expected in manifest['source_sha256'].items():
        if sha(ROOT/path)!=expected:raise RuntimeError('Source differs from build: '+path)
    report=OUT/(args.label+'.json')
    if report.exists():raise RuntimeError('Use fresh --label; preserve previous result')
    command=[str(ROOT/manifest['binary'])]
    if manifest['kind']=='rtl':command += [str(args.count),str(int(args.fixed)),str(report),str(args.seed)]
    else:command += [str(report)]
    execute(command,ROOT,OUT/(args.label+'.log'))
    r=json.loads(report.read_text());r['build_manifest']='build_'+args.tag+'.json'
    r['command']=command;report.write_text(json.dumps(r,indent=2)+'\n')
    print('QUIRE_RUN_PASS',args.label,r.get('main_mac_retired',r))


def model(args):
    binary=OUT/'quire_model_test'
    before=inputs();before['tb/quire_model_test.cpp']=sha(ROOT/'tb/quire_model_test.cpp')
    command=['g++','-O3','-std=c++17','-Itb','-Itb/opt17','-Il1/include',
             'tb/quire_model_test.cpp','-o',str(binary.relative_to(ROOT))]
    execute(command,ROOT,OUT/'model_build.log')
    fixture=(ROOT/args.fixtures).resolve()
    if not fixture.is_relative_to(ROOT):raise RuntimeError('Fixture outside project')
    before[fixture.relative_to(ROOT).as_posix()]=sha(fixture)
    execute([str(binary),str(OUT/'model.json'),str(fixture)],ROOT,OUT/'model.log')
    for path,expected in before.items():assert sha(ROOT/path)==expected,path
    (OUT/'model_manifest.json').write_text(json.dumps({'source_sha256':before,'command':command},indent=2)+'\n')
    print('QUIRE_MODEL_PASS',json.loads((OUT/'model.json').read_text()))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='action',required=True)
    p=sub.add_parser('build');p.add_argument('--tag',required=True);p.add_argument('--coverage',action='store_true')
    p.add_argument('--kind',choices=['rtl','units'],default='rtl')
    p=sub.add_parser('run');p.add_argument('--tag',required=True);p.add_argument('--label',required=True)
    p.add_argument('--count',type=int,default=100000);p.add_argument('--fixed',action='store_true')
    p.add_argument('--seed',type=int,default=20261103)
    p=sub.add_parser('model')
    p.add_argument('--fixtures',default='results/quire_20261103/python_vectors/commands.txt')
    args=parser.parse_args()
    for field in ('tag','label'):
        if hasattr(args,field) and not getattr(args,field).replace('_','').isalnum():parser.error('Simple tag/label required')
    OUT.mkdir(exist_ok=True)
    {'build':build,'run':run,'model':model}[args.action](args)


if __name__=='__main__':main()
