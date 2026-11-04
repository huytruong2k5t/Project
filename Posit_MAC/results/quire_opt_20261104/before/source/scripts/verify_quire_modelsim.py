#!/usr/bin/env python3
"""ModelSim command-line replay. Supply installation bin or put tools on PATH."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bin',type=Path)
    parser.add_argument('--label',required=True)
    args=parser.parse_args()
    if not args.label.replace('_','').isalnum():parser.error('Simple label required')
    run=ROOT/'results/quire_20261103'/args.label
    if run.exists():raise RuntimeError('Fresh --label required; preserve previous run')
    run.mkdir();(run/'tmp').mkdir();(run/'source').mkdir()
    env=os.environ.copy();env['TMP']=env['TEMP']=str(run/'tmp')
    def tool(name):
        if args.bin:return str(args.bin.resolve()/(name+('.exe' if os.name=='nt' else '')))
        found=shutil.which(name)
        if not found:raise RuntimeError('Missing '+name+'; use --bin')
        return found
    def execute(command,name):
        with (run/(name+'.log')).open('w') as f:
            p=subprocess.run(command,cwd=run,env=env,stdout=f,stderr=subprocess.STDOUT)
        if p.returncode:
            print((run/(name+'.log')).read_text(errors='replace')[-7000:])
            raise RuntimeError(name+' failed')
    paths=(ROOT/'rtl/quire_active.f').read_text().splitlines()
    paths+=['rtl/quire_active.f','rtl/posit_mac.vh','tb/tb_posit_mac_quire.sv',
            'scripts/gen_quire_vectors.py','scripts/verify_quire_modelsim.py']
    hashes={p:sha(ROOT/p) for p in paths if p.strip()}
    for path in hashes:
        target=run/'source'/path;target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/path,target)
    execute([sys.executable,'-B',str(run/'source/scripts/gen_quire_vectors.py'),str(run/'vectors')],'generate')
    execute([tool('vlib'),'work'],'library')
    sources=[str(run/'source'/p) for p in (ROOT/'rtl/quire_active.f').read_text().splitlines() if p.strip()]
    sources+=[str(run/'source/tb/tb_posit_mac_quire.sv')]
    compile_command=[tool('vlog'),'-sv','-timescale','1ns/1ps','+incdir+'+str(run/'source/rtl'),'-work','work',*sources]
    execute(compile_command,'compile')
    (run/'run.do').write_text('onerror {quit -code 1}\nonbreak {quit -code 1}\nrun -all\nquit -code 0\n')
    command=[tool('vsim'),'-c','work.tb_posit_mac_quire','+VECTORS='+str(run/'vectors/commands.txt'),'-do','run.do','-wlf','wave.wlf']
    execute(command,'simulate')
    text=(run/'simulate.log').read_text(errors='replace')
    if 'QUIRE_MODELSIM_PASS' not in text or '** Fatal:' in text or '** Error:' in text:raise RuntimeError('Missing clean PASS')
    for path,expected in hashes.items():assert sha(ROOT/path)==expected,path
    version=subprocess.check_output([tool('vsim'),'-version'],cwd=run,env=env,text=True,stderr=subprocess.STDOUT).strip()
    manifest={'status':'PASS','source_sha256':hashes,'compiler':compile_command,'command':command,'modelsim':version,
              'seed':20261103,'marker':[s.strip() for s in text.splitlines() if 'QUIRE_MODELSIM_PASS' in s]}
    (run/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('\n'.join(manifest['marker']))


if __name__=='__main__':main()
