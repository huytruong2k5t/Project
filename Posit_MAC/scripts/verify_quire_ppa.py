#!/usr/bin/env python3
"""Single A35T OOC route with source snapshot and process-local runtime dirs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vivado',default='vivado')
    parser.add_argument('--label',required=True);args=parser.parse_args()
    if not args.label.replace('_','').isalnum():parser.error('Simple label required')
    run=ROOT/'results/quire_20261103'/args.label
    if run.exists():raise RuntimeError('Fresh label required')
    run.mkdir();env=os.environ.copy()
    for name in ('tmp','appdata','localappdata'):(run/name).mkdir()
    env.update({'TMP':str(run/'tmp'),'TEMP':str(run/'tmp'),'TMPDIR':str(run/'tmp'),
                'APPDATA':str(run/'appdata'),'LOCALAPPDATA':str(run/'localappdata'),
                'XILINX_LOCAL_USER_DATA':'no','QUIRE_SOURCE_ROOT':(run/'source').as_posix()})
    paths=(ROOT/'rtl/quire_active.f').read_text().splitlines()+[
        'rtl/quire_active.f','rtl/posit_mac.vh','tb/quire_ppa_top.sv','syn/quire_ooc.tcl',
        'scripts/verify_quire_ppa.py','syn/constraints/a35t_clock.xdc',
        'syn/constraints/a35t_benchmark_100mhz.xdc']
    hashes={p:sha(ROOT/p) for p in paths if p.strip()}
    for path in hashes:
        target=run/'source'/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/path,target)
    command=[args.vivado,'-mode','batch','-notrace','-source',str(run/'source/syn/quire_ooc.tcl'),
             '-log','vivado.log','-journal','vivado.jou']
    manifest={'source_sha256':hashes,'command':command,'part':'xc7a35tcpg236-1',
              'period_ns':10,'scope':'Single OOC route, not Fmax sweep/board signoff'}
    (run/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    with (run/'console.log').open('w') as f:
        p=subprocess.run(command,cwd=run,env=env,stdout=f,stderr=subprocess.STDOUT)
    if p.returncode:
        print((run/'console.log').read_text(errors='replace')[-4000:]);raise RuntimeError('Vivado failed; preserve logs')
    for path,expected in hashes.items():assert sha(ROOT/path)==expected,path
    result=json.loads((run/'result.json').read_text())
    manifest['status']='ROUTED';manifest['result']=result
    (run/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('QUIRE_PPA_DONE',result)


if __name__=='__main__':main()
