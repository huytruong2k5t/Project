#!/usr/bin/env python3
"""Reachability, named-port, shared-source and strict-lint audit for quire."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/os.environ.get('QUIRE_RESULTS_ROOT','results/quire_current_20261105')


def clean(text):return re.sub(r'//[^\n]*|/\*.*?\*/','',text,flags=re.S)
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    paths=[p for p in (ROOT/'rtl/quire_active.f').read_text().splitlines() if p.strip()]
    benches=['tb/quire_checker.sv','tb/quire_units.sv','tb/tb_posit_mac_quire.sv','tb/quire_ppa_top.sv']
    modules={};texts={};edges={};instances=[]
    for path in paths+benches:
        text=clean((ROOT/path).read_text());texts[path]=text
        assert len(re.findall(r'\bmodule\s+\w+',text))==1,path
        header=re.search(r'\bmodule\s+(\w+)\s*\((.*?)\);',text,re.S)
        if header:
            ports=set(re.findall(r'\b(?:input|output|inout)\s+(?:(?:wire|logic|signed|reg)\s+)*(?:\[[^\]]+\]\s*)?(\w+)',header[2]))
            name=header[1]
        else:
            name=re.search(r'\bmodule\s+(\w+)\s*;',text)[1];ports=set()
        assert name==Path(path).stem and name not in modules,path
        if path in paths:assert not re.search(r'\bparameter\b|\bcfg_mode\b|`timescale',text),path
        modules[name]=ports;edges[name]=set()
    for path,text in texts.items():
        parent=Path(path).stem
        for callee,ports in modules.items():
            for match in re.finditer(r'\b'+callee+r'\s+(\w+)\s*\((.*?)\)\s*;',text,re.S):
                names=re.findall(r'\.(\w+)\s*\(',match[2])
                assert len(names)==len(set(names)) and set(names)==ports,(path,match[1])
                assert not re.search(r'\.\w+\s*\(\s*\)',match[2]),(path,match[1],'empty')
                edges[parent].add(callee)
                instances.append({'parent':parent,'instance':match[1],'module':callee,'ports':len(names)})
    reached=set();todo=['posit_mac_quire']
    while todo:
        name=todo.pop()
        if name not in reached:reached.add(name);todo.extend(edges[name])
    assert reached=={Path(p).stem for p in paths},'Unreachable active module'
    index=json.loads((ROOT/'releases/current.json').read_text())
    reference=ROOT/index['package']/'source.sha256.json'
    locked=json.loads(reference.read_text())
    common={p:sha(ROOT/p) for p in paths if not p.startswith('rtl/mac_quire/')}
    assert all(locked[p]==h for p,h in common.items()),'Shared RTL differs from current NF/F locks'
    logs=OUT/'lint';logs.mkdir(parents=True,exist_ok=True)
    (OUT/'tmp').mkdir(exist_ok=True)
    env=os.environ.copy();env['TMPDIR']=str(OUT/'tmp')
    def lint(name):
        command=['verilator','--lint-only','--timing','--assert','-Wall','-Irtl',
                 '--top-module',name,'-f','rtl/quire_active.f','--Mdir',str((logs/name).relative_to(ROOT))]
        result=subprocess.run(command,cwd=ROOT,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        (logs/(name+'.log')).write_text(result.stdout)
        if result.returncode:raise RuntimeError(name+'\n'+result.stdout)
        return {'top':name,'status':'PASS','command':command}
    with ThreadPoolExecutor(max_workers=4) as pool:lint_results=list(pool.map(lint,sorted(reached)))
    text=texts['tb/quire_ppa_top.sv']
    assert re.search(r'BUFG\s+u_clk\s*\(\s*\.I\s*\(clk\),\s*\.O\s*\(clk_buf\)\s*\)',text,re.S)
    report={'status':'PASS','active_modules':len(paths),'named_instances':len(instances),'clock_primitive_bindings':1,
            'missing_or_empty_ports':0,'public_dut_parameters':0,'shared_nf_f_rtl_unchanged':True,
            'source_sha256':{p:sha(ROOT/p) for p in paths+benches},'instances':instances,'lint':lint_results}
    (OUT/'ports_and_lint.json').write_text(json.dumps(report,indent=2)+'\n')
    print('QUIRE_AUDIT_PASS',len(paths),'modules',len(instances),'instances +1BUFG')


if __name__=='__main__':main()
