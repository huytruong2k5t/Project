#!/usr/bin/env python3
"""Reproducible isolated OPT-17 FULL_TERM build/run; never modify production."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'results/opt17_20261029'
STUDY = ROOT/'experiments/opt17_20261029'
TOPS = ('opt17_nf_ref','opt17_f_ref','opt17_nf','opt17_f',
        'opt17_nf_3p','opt17_f_3p','opt17_nf_3p_ops','opt17_f_3p_ops')
REVISION = os.environ.get('OPT17_BUILD_TAG','')
if REVISION and not re.fullmatch(r'_[A-Za-z0-9_]+',REVISION):
    raise ValueError('OPT17_BUILD_TAG must start with underscore')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_parent():
    parent = json.loads((OUT/'parent.json').read_bytes())
    for group in ('sources','model_inputs'):
        for name,digest in parent[group].items():
            assert sha(ROOT/name) == digest, 'Parent changed: '+name
    assert sha(ROOT/'rtl/production_freeze.json') == parent['parent_manifest_sha256']


def used_sources(top):
    files = (STUDY/'sources.f').read_text().splitlines()
    names = {Path(name).stem: name for name in files}
    assert len(names) == len(files)
    seen = set()
    todo = [top]
    while todo:
        parent = todo.pop()
        if parent in seen:
            continue
        seen.add(parent)
        text = re.sub(r'//[^\n]*|/\*.*?\*/','',(ROOT/names[parent]).read_text(),flags=re.S)
        for name in names:
            for match in re.finditer(r'\b'+re.escape(name)+r'\s+\w+\s*\(',text):
                if not text[max(0,match.start()-12):match.start()].strip().endswith('module'):
                    todo.append(name)
    return [name for name in files if Path(name).stem in seen]


def run(args, cwd, log):
    env = os.environ.copy()
    (OUT/'tmp').mkdir(exist_ok=True)
    env['TMPDIR'] = str(OUT/'tmp')
    log.parent.mkdir(parents=True,exist_ok=True)
    with log.open('w') as stream:
        result = subprocess.run(args,cwd=cwd,env=env,stdout=stream,stderr=subprocess.STDOUT)
    if result.returncode:
        print(log.read_text(errors='replace')[-8000:])
        raise RuntimeError('Command failed: '+str(args))


def lint():
    check_parent()
    evidence = {'tool': subprocess.check_output(['verilator','--version'],text=True).strip(), 'tops': {}}
    sources = (STUDY/'sources.f').read_text().splitlines()
    for top in TOPS:
        if not (STUDY/'rtl'/f'{top}.sv').exists():
            continue
        args = ['verilator','--lint-only','--timing','--assert','-Wall','-Irtl',
                '--top-module',top,'-f',str(STUDY.relative_to(ROOT)/'sources.f')]
        run(args,ROOT,OUT/'lint'/f'{top}.log')
        evidence['tops'][top] = {'status':'PASS','command':args}
    evidence['source_sha256'] = {name:sha(ROOT/name) for name in sources}
    (OUT/'lint.json').write_text(json.dumps(evidence,indent=2)+'\n')
    print('OPT17_LINT_PASS',len(evidence['tops']))


def build(top):
    check_parent()
    assert top in TOPS
    target = OUT/('build_'+top+REVISION)
    if target.exists():
        raise RuntimeError('Preserve existing build; use rebuild only after source changes: '+top)
    (target/'src/rtl').mkdir(parents=True)
    (target/'src/tb/opt17').mkdir(parents=True)
    shutil.copytree(ROOT/'l1/include',target/'src/l1/include')
    for path in (ROOT/'tb').glob('*.hpp'):
        shutil.copy2(path,target/'src/tb'/path.name)
    for path in (ROOT/'tb/opt17').glob('*'):
        if path.is_file():
            shutil.copy2(path,target/'src/tb/opt17'/path.name)
    sources = used_sources(top)
    for name in sources:
        shutil.copy2(ROOT/name,target/'src/rtl'/Path(name).name)
    shutil.copy2(ROOT/'rtl/posit_mac.vh',target/'src/rtl/posit_mac.vh')
    fused = top.startswith('opt17_f')
    reference = top.endswith('_ref')
    root = f'dut.rootp->{top}__DOT__u_wrapper__DOT__'
    descriptor = f'''#pragma once
#include "V{top}.h"
#include "V{top}___024root.h"
using DUT = V{top};
#define DUT_FUSED {int(fused)}
#define DUT_REFERENCE {int(reference)}
#define DUT_THREE_PARSER {int('_3p' in top)}
#define P_WRAPPER(name) {root}##name
#define P_FRONT(name) {root}u_front__DOT__##name
#define P_AC(name) {root}u_front__DOT__u_ac__DOT__##name
#define P_CORE(name) {root}u_core__DOT__##name
#define P_ACC_NEXT {root}u_core__DOT__u_acc__DOT__acc_next
'''
    (target/'src/tb/opt17/dut.hpp').write_text(descriptor)
    # Existing reference wrappers expose the same read-only probes by name.
    if reference:
        descriptor += '#define P_LAUNCH P_WRAPPER(pair_retire)\n'
        descriptor += '#define P_ITER P_WRAPPER('+('iterations_done' if fused else 'unused_iterations_done')+')\n'
    else:
        descriptor += '#define P_LAUNCH P_WRAPPER(launch)\n#define P_ITER P_WRAPPER(iterations_done)\n'
    (target/'src/tb/opt17/dut.hpp').write_text(descriptor)
    files = ['src/rtl/'+Path(name).name for name in sources]
    args = ['verilator','--cc','--exe','--no-timing','--assert','-Wall','-Wno-ASSIGNDLY',
            '--top-module',top,'-Isrc/rtl','--Mdir','obj',
            '-CFLAGS','-O3 -std=c++17 -I../src/l1/include -I../src/tb -I../src/tb/opt17',
            *files,'src/tb/opt17/harness.cpp']
    (target/'commands.json').write_text(json.dumps(args,indent=2)+'\n')
    run(args,target,target/'verilate.log')
    run(['make','-C','obj','-f',f'V{top}.mk','CURDIR=.','-j4'],target,target/'make.log')
    manifest = {p.relative_to(target).as_posix():sha(p) for p in (target/'src').rglob('*') if p.is_file()}
    manifest['obj/V'+top] = sha(target/'obj'/('V'+top))
    (target/'build_sha256.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('OPT17_BUILD_PASS',top)


def simulate(top,count,label,scenario):
    check_parent()
    if top not in TOPS or not re.fullmatch(r'[a-zA-Z0-9_]+',label):
        raise ValueError('Invalid top/label')
    target = OUT/('build_'+top+REVISION)
    if (target/(label+'.json')).exists():
        raise RuntimeError('Preserve existing report')
    for name,digest in json.loads((target/'build_sha256.json').read_bytes()).items():
        assert sha(target/name) == digest, 'Build changed: '+name
    # A stale compiled candidate must never be used to qualify edited RTL.
    for name in used_sources(top):
        assert (target/'src/rtl'/Path(name).name).read_bytes() == (ROOT/name).read_bytes(), name
    args = [str(target/'obj'/('V'+top)),str(count),label,scenario]
    (target/(label+'_command.json')).write_text(json.dumps(args,indent=2)+'\n')
    run(args,target,target/(label+'.log'))
    report = json.loads((target/(label+'.json')).read_bytes())
    assert report['completed'] >= count and report['mismatches'] == 0
    print('OPT17_RUN_PASS',top,scenario,report['completed'],'cycles',report['cycles'])


def prepare_ppa(top):
    check_parent()
    assert top in TOPS
    for kind in ('nf','f'):
        report = json.loads((OUT/f'build_opt17_{kind}_r2/main.json').read_bytes())
        assert report['completed'] == 10000000 and report['mismatches'] == 0
        assert (OUT/f'modelsim_opt17_{kind}_event/status.txt').read_text().strip() == 'PASS'
    target = OUT/'ppa'/top
    if target.exists():
        raise RuntimeError('Preserve PPA run')
    (target/'source/rtl').mkdir(parents=True)
    for name in used_sources(top):
        shutil.copy2(ROOT/name,target/'source/rtl'/Path(name).name)
    shutil.copy2(ROOT/'rtl/posit_mac.vh',target/'source/rtl/posit_mac.vh')
    ports = '''    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic acc_mode,
    input logic acc_clr,
    input logic cfg_mode,
    input logic [3:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags'''
    signals = ('clk','rst_n','in_valid','in_ready','a','b','c','acc_mode','acc_clr',
               'cfg_mode','cfg_n','cfg_ops','out_valid','out_ready','d','flags')
    connections = ',\n'.join('        .'+name+' ('+('clk_core' if name=='clk' else name)+')' for name in signals)
    wrapper = f'''// Matched OOC wrapper; same BUFG and public I/O budget for every variant.
module opt17_ppa_top (
{ports}
);
    wire clk_core;
    BUFG u_clk (
        .I (clk),
        .O (clk_core)
    );
    {top} u_dut (
{connections}
    );
endmodule
'''
    (target/'source/opt17_ppa_top.sv').write_text(wrapper)
    (target/'source/matched.xdc').write_text('''# Same OOC clock and fixed I/O assumptions for all OPT-17 variants.
create_clock -name clk -period 8.300 [get_ports clk]
set_clock_uncertainty -setup 0.100 [get_clocks clk]
set_clock_uncertainty -hold 0.100 [get_clocks clk]
set inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
set outputs [get_ports -filter {DIRECTION == OUT}]
set_input_delay -clock clk -max 2.500 $inputs
set_input_delay -clock clk -min 2.500 $inputs
set_output_delay -clock clk -max 0.500 $outputs
set_output_delay -clock clk -min 0.000 $outputs
''')
    shutil.copy2(ROOT/'scripts/opt17_ppa.tcl',target/'source/flow.tcl')
    sources = {p.relative_to(target).as_posix():sha(p) for p in (target/'source').rglob('*') if p.is_file()}
    (target/'manifest.json').write_text(json.dumps({'top':top,'source_sha256':sources,
        'part':'xc7a35tcpg236-1','clock_ns':8.3,'input_min_max_ns':2.5,
        'output_min_ns':0,'output_max_ns':0.5,'uncertainty_setup_hold_ns':0.1,
        'strategies':['Default','Explore','RuntimeOptimized'],
        'scope':'Matched FULL_TERM OOC; NF exact-capable; F approximate-only; no board/power claim'},indent=2)+'\n')
    print('OPT17_PPA_PREPARED',top)


def benchmark(count):
    # Identical indexed transactions, no reset after startup, no sink stalls.
    # Each DUT is driven independently; no shared-ready synchronization.
    for top in TOPS:
        for mode in ('ind','acc'):
            for n in (0,1,2,4,8,12):
                scenario = f'{mode}_n{n}'
                simulate(top,count,'bench_'+scenario,scenario)


def pilot_comparisons():
    for top in ('opt17_nf_ref','opt17_f_ref','opt17_nf_3p_ops','opt17_f_3p_ops'):
        simulate(top,100000,'pilot','stress')


if __name__ == '__main__':
    if sys.argv[1:] == ['lint']:
        lint()
    elif len(sys.argv) == 3 and sys.argv[1] == 'build':
        build(sys.argv[2])
    elif len(sys.argv) == 6 and sys.argv[1] == 'run':
        simulate(sys.argv[2],int(sys.argv[3]),sys.argv[4],sys.argv[5])
    elif len(sys.argv) == 3 and sys.argv[1] == 'prepare-ppa':
        prepare_ppa(sys.argv[2])
    elif len(sys.argv) == 3 and sys.argv[1] == 'benchmark':
        benchmark(int(sys.argv[2]))
    elif sys.argv[1:] == ['pilot-comparisons']:
        pilot_comparisons()
    else:
        raise SystemExit('lint | build TOP | run TOP COUNT LABEL SCENARIO')
