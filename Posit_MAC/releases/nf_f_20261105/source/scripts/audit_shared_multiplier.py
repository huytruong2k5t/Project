#!/usr/bin/env python3
"""Check active hierarchy, named ports, wrapper liveness and strict lint."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/os.environ.get('SHARED_RESULTS_ROOT','results/nf_f_lock_20261105')
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'tmp').mkdir(exist_ok=True)

def clean(text): return re.sub(r'//[^\n]*|/\*.*?\*/','',text,flags=re.S)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    paths=[p.strip() for p in (ROOT/'rtl/mac_active.f').read_text().splitlines() if p.strip()]
    references=[p.strip() for p in (ROOT/'tb/reference/rtl/files.f').read_text().splitlines() if p.strip()]
    benches=['tb/shared_multiplier_units.sv','tb/shared_mac_checker.sv','tb/tb_mul_iter_core.sv',
             'tb/tb_refactored_mac.sv','tb/tb_posit_add_5stage_equiv.sv','tb/tb_posit_pack_equiv.sv',
             'tb/prepack_nf_ppa_top.sv','tb/week13_fused_ppa_top.sv']
    modules={};texts={}
    for path in paths+references+benches:
        s=clean((ROOT/path).read_text(encoding='utf-8-sig'));texts[path]=s
        assert len(re.findall(r'\bmodule\s+\w+',s))==1,(path,'one module per file')
        m=re.search(r'\bmodule\s+(\w+)(?:\s*#\s*\(.*?\))?\s*\((.*?)\);',s,re.S)
        if not m:
            m=re.search(r'\bmodule\s+(\w+)\s*;',s)
            assert m,path
            ports={}
        else:
            ports={}
            for p in re.finditer(r'\b(input|output|inout)\s+(?:(?:wire|logic|reg|signed|unsigned)\s+)*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?(\w+)',m[2]):
                ports[p[4]]={'direction':p[1],'width':abs(int(p[2])-int(p[3]))+1 if p[2] else 1}
        name=m[1]
        assert name==Path(path).stem,(path,name)
        assert name not in modules,(path,name)
        if path in paths:
            assert not re.search(r'\bparameter\b',s),path
            assert 'cfg_mode' not in s,path
            assert not re.search(r'\b(acc_mode|acc_clr|accumulator_q|c_eff)\b',s),path
        modules[name]={'path':path,'ports':ports}
    edges={n:set() for n in modules};instances=[]
    for path,s in texts.items():
        parent=Path(path).stem
        for callee in modules:
            pattern=r'\b'+re.escape(callee)+r'\s+(\w+)\s*\((.*?)\)\s*;'
            for inst in re.finditer(pattern,s,re.S):
                names=re.findall(r'\.(\w+)\s*\(',inst[2])
                assert len(names)==len(set(names)),(path,inst[1],'duplicate mapping')
                expected=set(modules[callee]['ports'])
                assert set(names)==expected,(path,inst[1],expected-set(names),set(names)-expected)
                assert not re.search(r'\.\w+\s*\(\s*\)',inst[2]),(path,inst[1],'empty port')
                edges[parent].add(callee)
                instances.append({'parent':parent,'instance':inst[1],'module':callee,'ports':len(names)})
    reached=set();todo=['posit_mac_nf','posit_mac_f']
    while todo:
        n=todo.pop()
        if n not in reached: reached.add(n);todo.extend(edges[n])
    active_names={Path(p).stem for p in paths}
    assert reached==active_names,('Unreachable active modules',active_names-reached)
    for variant in ['nf','f']:
        parent='mac_'+variant+'_wrapper'
        assert 'mul_iter_core' in edges[parent] and 'ops_sel_comb' in edges[parent]
        assert 'mul_prepack_norm_comb' in edges[parent]
        assert 'posit_add' in edges[parent] and 'posit_pack' in edges[parent]
        assert not re.search(r'\bunused\w*',texts[modules[parent]['path']])
    for top,cpp in [('shared_mac_checker','tb/shared_mac_harness.cpp'),('shared_multiplier_units','tb/shared_multiplier_units.cpp')]:
        used=set(re.findall(r'\bd\.(\w+)',(ROOT/cpp).read_text()))
        assert set(modules[top]['ports'])<=used,(top,'C++ does not consume/drive all verification ports',set(modules[top]['ports'])-used)
    clock_primitives=0
    for path in ['tb/prepack_nf_ppa_top.sv','tb/week13_fused_ppa_top.sv']:
        match=re.search(r'\bBUFG\s+\w+\s*\((.*?)\)\s*;',texts[path],re.S)
        assert match and set(re.findall(r'\.(\w+)\s*\(',match[1]))=={'I','O'},path
        assert not re.search(r'\.\w+\s*\(\s*\)',match[1]),path
        clock_primitives+=1
    lint_dir=OUT/'lint_active';lint_dir.mkdir(exist_ok=True)
    def lint(name):
        args=['verilator','--lint-only','--timing','--assert','-Wall','-Irtl','--top-module',name,'-f','rtl/mac_active.f','--Mdir',str((lint_dir/name).relative_to(ROOT))]
        env=os.environ.copy();env['TMPDIR']=str(OUT/'tmp')
        p=subprocess.run(args,cwd=ROOT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (lint_dir/(name+'.log')).write_text(p.stdout)
        if p.returncode: raise RuntimeError(name+'\n'+p.stdout)
        return {'top':name,'status':'PASS','command':args}
    with ThreadPoolExecutor(max_workers=4) as pool:
        lint_results=list(pool.map(lint,sorted(active_names)))
    historical=[]
    active_tb=set(benches)
    for p in (ROOT/'tb').glob('*.sv'):
        rel=str(p.relative_to(ROOT))
        if rel not in active_tb and re.search(r'\bcfg_mode\b|\bmul_iter_core_fixed2\b',clean(p.read_text(errors='replace'))):
            historical.append(rel)
    report={'status':'PASS','active_modules':len(paths),'strict_lint_tops':len(lint_results),
            'instances_checked':len(instances),'missing_or_empty_ports':0,'unreachable_active_modules':[],
            'pnr_clock_primitive_bindings_checked':clock_primitives,
            'dut_public_parameters':0,'cfg_mode_ports':0,'wrappers_unused_named_wires':0,
            'modules':modules,'instances':instances,'lint':lint_results,
            'historical_testbenches_require_matching_snapshot':historical,
            'source_sha256':{p:sha(ROOT/p) for p in paths+references+benches},
            'limits':'Static named-port audit and per-top strict lint; fixed zero/sentinel bits in shared leaves are intentional. No raw32 input exhaustiveness claim.'}
    (OUT/'ports_and_lint.json').write_text(json.dumps(report,indent=2)+'\n')
    print('SHARED_PORTS_LINT_PASS',len(paths),'modules',len(instances),'instances; all current verification ports driven/consumed')
if __name__=='__main__': main()
