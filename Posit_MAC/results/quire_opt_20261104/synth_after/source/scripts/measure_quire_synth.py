"""Fresh source-bound A35T synthesis only, no place/route/bitstream."""
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
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source-root',type=Path,default=ROOT)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--verified',type=Path)
    p.add_argument('--vivado',default='vivado')
    a=p.parse_args();source=a.source_root.resolve();out=a.output.resolve()
    assert out.is_relative_to(ROOT) and not out.exists()
    out.mkdir(parents=True)
    active=[r.strip() for r in (source/'rtl/quire_active.f').read_text().splitlines() if r.strip()]
    if a.verified:
        proof=json.loads(a.verified.read_text())
        assert proof['status']=='PASS'
        for rel in active+['rtl/quire_active.f','rtl/posit_mac.vh']:
            assert sha(source/rel)==proof['source_sha256'][rel],rel
    paths=active+['rtl/quire_active.f','rtl/posit_mac.vh','tb/quire_ppa_top.sv']
    hashes={}
    for rel in paths:
        dst=out/'source'/rel;dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(source/rel,dst);hashes[rel]=sha(dst)
    recipe={}
    for rel in ['syn/quire_synth_only.tcl','syn/report_quire_f2f.tcl',
                'syn/constraints/a35t_clock.xdc','syn/constraints/a35t_benchmark_100mhz.xdc',
                'scripts/measure_quire_synth.py']:
        dst=out/'source'/rel;dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/rel,dst);recipe[rel]=sha(dst)
    for name in ['tmp','appdata','localappdata']:(out/name).mkdir()
    env=os.environ.copy();env.update({'TMP':str(out/'tmp'),'TEMP':str(out/'tmp'),
        'APPDATA':str(out/'appdata'),'LOCALAPPDATA':str(out/'localappdata'),
        'XILINX_LOCAL_USER_DATA':'no'})
    command=[a.vivado,'-mode','batch','-notrace','-source',str(out/'source/syn/quire_synth_only.tcl'),
        '-log','vivado.log','-journal','vivado.jou','-tclargs',str(out/'source')]
    manifest={'source_sha256':hashes,'recipe_sha256':recipe,'command':command,
        'verified_manifest':str(a.verified) if a.verified else None,
        'part':'xc7a35tcpg236-1','period_ns':10,'implementation_run':False}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    with (out/'console.log').open('w') as f:
        result=subprocess.run(command,cwd=out,env=env,stdout=f,stderr=subprocess.STDOUT)
    if result.returncode:
        print((out/'console.log').read_text(errors='replace')[-4000:])
        raise RuntimeError('Synthesis failed; preserve evidence')
    assert (out/'status.txt').read_text().strip()=='SYNTHESIS_COMPLETE'
    for rel,h in hashes.items():assert sha(source/rel)==h,rel
    manifest['status']='SYNTHESIS_COMPLETE'
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('QUIRE_SYNTHESIS_PASS',out,flush=True)


if __name__=='__main__':main()
