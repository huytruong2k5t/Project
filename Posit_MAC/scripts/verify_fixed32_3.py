#!/usr/bin/env python3
"""Build fixed-format NF/F, with cycle-by-cycle pre-change RTL comparison.

The existing independent integer/dyadic oracle and stage probes remain active.
All temporary files and logs are confined to results/fixed32_3_20261022.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
from fix_posit32_3 import ROOT, OUT, run
REVISION = os.environ.get('POSIT32_BUILD_TAG', '_literal_ports')
if not re.fullmatch(r'_[A-Za-z0-9_]+', REVISION):
    raise ValueError('Build tag must start with underscore, then letters/digits')


def ensure_reference():
    """Restore the preserved comparator for a clean checkout, inside OUT only."""
    reference = OUT/'reference'
    expected = json.loads((OUT/'reference_sha256.json').read_text())
    if not (reference/'rtl/production.f').exists():
        with zipfile.ZipFile(OUT/'reference_source.zip') as archive:
            for item in archive.infolist():
                relative = Path(item.filename)
                if relative.is_absolute() or '..' in relative.parts or ':' in item.filename:
                    raise ValueError('Invalid reference archive path')
                if item.is_dir():
                    continue
                data = archive.read(item)
                if hashlib.sha256(data).hexdigest() != expected[item.filename]:
                    raise ValueError('Reference archive checksum mismatch')
                destination = reference/relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(data)
    for relative, digest in expected.items():
        if hashlib.sha256((reference/relative).read_bytes()).hexdigest() != digest:
            raise ValueError('Reference input changed: '+relative)


def restore_self_test():
    global OUT
    previous = OUT
    temporary = previous/'restore_self_test_20261023'
    if temporary.exists():
        raise SystemExit('Preserve existing restore self-test')
    temporary.mkdir()
    for name in ['reference_source.zip', 'reference_sha256.json']:
        shutil.copy2(previous/name, temporary/name)
    try:
        OUT = temporary
        ensure_reference()
        result = {'status': 'PASS', 'scope': 'Fresh reference restore, archive SHA256 checked',
                  'restored_files': len(json.loads((temporary/'reference_sha256.json').read_text()))}
        (temporary/'summary.json').write_text(json.dumps(result, indent=2)+'\n')
        print(json.dumps(result))
    finally:
        OUT = previous


def generate_harnesses():
    nf = (ROOT / 'tb/nf_coverage_harness.cpp').read_text()
    start = nf.index('#ifndef PROFILE_NB')
    end = nf.index('constexpr uint32_t NAR')
    nf = nf[:start]+'''// Fixed verification profile: posit32/ES3, multiplier fraction12.
namespace {
constexpr int NB = 32, ES = 3;
constexpr unsigned F = 26, FW = 12;
'''+nf[end:]
    start = nf.index('    constexpr unsigned width = []()')
    end = nf.index('    return int(value', start)
    nf = nf[:start]+'    constexpr unsigned width = 11; // clog2(4*240+4)+1\n'+nf[end:]
    nf = nf.replace('20261014 + 100*NB + ES', '20261022')
    (ROOT / 'tb/fixed32_3_nf_harness.cpp').write_text(nf)
    fused = (ROOT / 'tb/week13_fused_harness.cpp').read_text()
    fused = fused.replace('constexpr uint64_t SEED = 20261015;',
                          'constexpr uint64_t SEED = 20261022;')
    (ROOT / 'tb/fixed32_3_f_harness.cpp').write_text(fused)


def reference_units():
    ensure_reference()
    target = OUT/'units'
    (target/'reference').mkdir(parents=True, exist_ok=True)
    old_files = (OUT/'reference/rtl/production.f').read_text().splitlines()
    names = [Path(p).stem for p in old_files]
    token = re.compile(r'\b('+'|'.join(names)+r')\b')
    for rel in old_files:
        text = token.sub(lambda m: 'reference_'+m[0], (OUT/'reference'/rel).read_text())
        if Path(rel).stem == 'lod_lzd_core':
            text = text.replace("POS_W'(group_index)", "pos_cast_t'(group_index)")
            text = text.replace("S'(pos_tree[LEVELS][0])", "count_cast_t'(pos_tree[LEVELS][0])")
            text = text.replace('            assign match_bits',
                                '            typedef logic [POS_W-1:0] pos_cast_t;\n'
                                '            typedef logic [S-1:0] count_cast_t;\n'
                                '            assign match_bits')
        if Path(rel).stem == 'mac_f_wrapper':
            text = text.replace("I_W'(N_MAX)", "iteration_cast_t'(N_MAX)")
            text = text.replace('    localparam int I_W = $clog2(FRAC_W+1);',
                                '    localparam int I_W = $clog2(FRAC_W+1); '
                                'typedef logic [I_W-1:0] iteration_cast_t;')
        (target/'reference'/('reference_'+Path(rel).name)).write_text(text)


def generate_units():
    import xml.etree.ElementTree as ET
    from fix_posit32_3 import literal
    target = OUT/'units'
    if target.exists():
        raise SystemExit('Preserve unit evidence')
    (target/'reference').mkdir(parents=True)
    old_files = (OUT/'reference/rtl/production.f').read_text().splitlines()
    names = [Path(p).stem for p in old_files]
    token = re.compile(r'\b('+'|'.join(names)+r')\b')
    for rel in old_files:
        text = token.sub(lambda m: 'reference_'+m[0], (OUT/'reference'/rel).read_text())
        if Path(rel).stem == 'lod_lzd_core':
            text = text.replace("POS_W'(group_index)", "pos_cast_t'(group_index)")
            text = text.replace("S'(pos_tree[LEVELS][0])", "count_cast_t'(pos_tree[LEVELS][0])")
            text = text.replace('            assign match_bits',
                                '            typedef logic [POS_W-1:0] pos_cast_t;\n'
                                '            typedef logic [S-1:0] count_cast_t;\n'
                                '            assign match_bits')
        if Path(rel).stem == 'mac_f_wrapper':
            text = text.replace("I_W'(N_MAX)", "iteration_cast_t'(N_MAX)")
            text = text.replace('    localparam int I_W = $clog2(FRAC_W+1);',
                                '    localparam int I_W = $clog2(FRAC_W+1); '
                                'typedef logic [I_W-1:0] iteration_cast_t;')
        (target/'reference'/('reference_'+Path(rel).name)).write_text(text)
    definitions = {}
    for xml in OUT.glob('*.xml'):
        tree = ET.parse(xml)
        types = {v.get('id'): v for v in tree.findall('./netlist/typetable/*')}
        for node in tree.findall('./netlist/module'):
            params = {v.get('name'): literal(v) for v in node.findall('var')
                      if v.get('param') == 'true'}
            definitions[(node.get('origName'), tuple(params.items()))] = (node, types)
    declarations, instances, stimuli, checks, covered = [], [], [], [], []
    for row in json.loads((OUT/'specialization.json').read_text()):
        original = Path(row['original']).stem
        node, types = definitions[(original, tuple(row['constants'].items()))]
        ports = [v for v in node.findall('var') if v.get('dir')]
        if any(v.get('name') == 'clk' for v in ports):
            continue
        tag = 'm'+str(len(covered))
        fixed_connections, old_connections = [], []
        for var in ports:
            name = var.get('name')
            dtype = types[var.get('dtype_id')]
            left, right = dtype.get('left'), dtype.get('right')
            dim = '['+left+':'+right+'] ' if left is not None else ''
            signal = tag+'_'+name
            declarations.append('    logic '+dim+signal+';')
            fixed_connections.append('.'+name+'('+signal+')')
            if var.get('dir') == 'input':
                old_connections.append('.'+name+'('+signal+')')
                stimuli.append('            '+signal+' = (step==0) ? \'0 : (step==1) ? \'1 : {$urandom,$urandom,$urandom};')
            else:
                declarations.append('    wire '+dim+signal+'_reference;')
                old_connections.append('.'+name+'('+signal+'_reference)')
                checks.append('            if ('+signal+' !== '+signal+'_reference) $fatal(1,"'+row['module']+'.'+name+'");')
        instances.append('    '+row['module']+' '+tag+'_fixed ('+', '.join(fixed_connections)+');')
        args = ', '.join('.'+k+'('+v+')' for k,v in row['constants'].items())
        instances.append('    reference_'+original+' #('+args+') '+tag+'_reference ('+', '.join(old_connections)+');')
        covered.append(row['module'])
    text = '`timescale 1ns/1ps\nmodule tb_fixed32_3_units;\n'
    text += '\n'.join(declarations+instances)
    text += '''
    integer seed = 20261022;
    integer ignored;
    initial begin
        ignored = $urandom(seed);
        for (integer step=0; step<20000; step=step+1) begin
'''+ '\n'.join(stimuli)+'\n            #2;\n'+'\n'.join(checks)
    text += '\n        end\n        $display("FIXED32_UNITS_PASS modules='+str(len(covered))+' vectors='+str(len(covered)*20000)+' mismatch=0 seed=20261022");\n        $finish;\n    end\nendmodule\n'
    (ROOT/'tb/tb_fixed32_3_units.sv').write_text(text)
    (target/'tb_fixed32_3_units.sv').write_text(text)
    (target/'matrix.json').write_text(json.dumps({'modules': covered, 'per_module': 20000,
                                                'seed': 20261022}, indent=2)+'\n')
    print('Combinational fixed variants:', len(covered))


def build(kind):
    ensure_reference()
    target = OUT / ('build_'+kind+REVISION)
    if target.exists():
        raise SystemExit('Preserve existing build '+str(target))
    src = target / 'src'
    (src / 'rtl').mkdir(parents=True)
    (target / 'tmp').mkdir()
    shutil.copytree(ROOT/'l1/include', src/'l1/include')
    (src/'tb').mkdir()
    for path in (ROOT/'tb').glob('*.hpp'):
        shutil.copy2(path, src/'tb'/path.name)
    (src/'l0').mkdir()
    for name in ['softposit_api.h', 'libsoftposit.so']:
        shutil.copy2(ROOT/'l0'/name, src/'l0'/name)
    current_lock = json.loads((ROOT/'rtl/production_freeze.json').read_text())
    fixed = ROOT if current_lock.get('status') == 'FIXED32_3_FUNCTION_VERIFIED' else OUT/'fixed'
    files = (fixed/'rtl/production.f').read_text().splitlines()
    for rel in files:
        shutil.copy2(fixed/rel, src/'rtl'/Path(rel).name)
    shutil.copy2(fixed/'rtl/posit_mac.vh', src/'rtl/posit_mac.vh')

    # Keep the old RTL in a separate namespace, never as the arithmetic oracle.
    old_files = (OUT/'reference/rtl/production.f').read_text().splitlines()
    names = [Path(p).stem for p in old_files]
    token = re.compile(r'\b('+'|'.join(names)+r')\b')
    for rel in old_files:
        text = (OUT/'reference'/rel).read_text()
        text = token.sub(lambda m: 'reference_'+m[0], text)
        (src/'rtl'/('reference_'+Path(rel).name)).write_text(text)

    top = 'posit_mac_nf' if kind == 'nf' else 'week13_fused_tb'
    dut = 'posit_mac_nf' if kind == 'nf' else 'posit_mac_f'
    path = src/'rtl'/(dut+'.sv')
    text = path.read_text()
    ports = ['clk', 'rst_n', 'in_valid', 'a', 'b', 'c', 'acc_mode',
             'acc_clr', 'cfg_mode', 'cfg_n', 'cfg_ops', 'out_ready']
    connections = ',\n'.join('        .'+name+'('+name+')' for name in ports)
    connections += ',\n        .in_ready(reference_ready), .out_valid(reference_valid),\n'
    connections += '        .d(reference_d), .flags(reference_flags)'
    companion = '''
    // Verification-only reference: cycle equivalence includes reset and stalls.
    wire reference_ready;
    wire reference_valid;
    wire [31:0] reference_d;
    wire [4:0] reference_flags;
    reference_DUT #(.NB(32), .ES(3), .FRAC_W(12)) reference_instance (
CONNECTIONS
    );
    always @(posedge clk) begin
        assert (in_ready === reference_ready) else $fatal(1,"reference ready");
        assert (out_valid === reference_valid) else $fatal(1,"reference valid");
        if (out_valid) begin
            assert (d === reference_d) else $fatal(1,"reference bits");
            assert (flags === reference_flags) else $fatal(1,"reference flags");
        end
    end
'''.replace('DUT', dut).replace('CONNECTIONS', connections)
    path.write_text(text.replace('endmodule', companion+'\nendmodule', 1))
    harness = 'fixed32_3_'+kind+'_harness.cpp'
    shutil.copy2(ROOT/'tb'/harness, src/'tb'/harness)
    extra = []
    if kind == 'nf':
        conf = (ROOT/'tb/nf_coverage.vlt').read_text()
        conf += '\n'.join(line.replace('"posit_pack"', '"posit_product_pack"')
                           for line in conf.splitlines() if '-module "posit_pack"' in line)+'\n'
        (src/'tb/nf_coverage.vlt').write_text(conf)
        extra = ['src/tb/nf_coverage.vlt']
    else:
        shutil.copy2(ROOT/'tb/week13_fused_tb.sv', src/'tb/week13_fused_tb.sv')
        extra = ['src/tb/week13_fused_tb.sv']
    rtl = [str(p.relative_to(target)) for p in sorted((src/'rtl').glob('*.sv'))]
    # Reference filenames have been prefixed; suppress only that diagnostic.
    args = ['verilator', '--cc', '--exe', '--no-timing', '--assert',
            '--coverage-line', '-Wall', '-Wno-ASSIGNDLY', '-Wno-DECLFILENAME',
            '--top-module', top, '-Isrc/rtl', '--Mdir', 'obj',
            '-CFLAGS', '-O3 -std=c++17 -I../src/l1/include -I../src/tb -I../src/l0',
            '-LDFLAGS', '-L../src/l0 -lsoftposit']+rtl+extra+['src/tb/'+harness]
    (target/'commands.json').write_text(json.dumps(args, indent=2)+'\n')
    run(args, 'build_'+kind+REVISION+'/build.log', target)
    run(['make', '-C', 'obj', '-f', 'V'+top+'.mk', 'CURDIR=.', '-j4'],
        'build_'+kind+REVISION+'/make.log', target)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    manifest = {str(p.relative_to(target)): sha(p) for p in src.rglob('*') if p.is_file()}
    manifest['obj/V'+top] = sha(target/'obj'/('V'+top))
    (target/'source_binary_sha256.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('BUILD PASS', kind)


def simulate(kind, count, label):
    target = OUT/('build_'+kind+REVISION)
    report = target/(label+('_summary.json' if kind == 'nf' else '.json'))
    if report.exists():
        raise SystemExit('Preserve existing simulation '+label)
    top = 'posit_mac_nf' if kind == 'nf' else 'week13_fused_tb'
    env = os.environ.copy()
    env['TMPDIR'] = str(target/'tmp')
    env['LD_LIBRARY_PATH'] = str(target/'src/l0')
    args = [str(target/'obj'/('V'+top)), str(count), label]
    (target/(label+'_command.json')).write_text(json.dumps(args)+'\n')
    with (target/(label+'.log')).open('w') as log:
        subprocess.run(args, cwd=target, env=env, stdout=log,
                       stderr=subprocess.STDOUT, check=True)
    print(report.read_text()[:400])


if __name__ == '__main__':
    os.chdir(ROOT)
    if sys.argv[1:] == ['harnesses']:
        generate_harnesses()
    elif sys.argv[1:] == ['units']:
        generate_units()
    elif sys.argv[1:] == ['unit-reference']:
        reference_units()
    elif sys.argv[1:] == ['restore-self-test']:
        restore_self_test()
    elif len(sys.argv) == 3 and sys.argv[1] == 'build':
        build(sys.argv[2])
    elif len(sys.argv) == 5 and sys.argv[1] == 'run':
        simulate(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    else:
        raise SystemExit('harnesses | build nf/f | run nf/f count label')
