#!/usr/bin/env python3
"""Materialize fixed posit32/ES3 RTL from evaluated elaboration constants.

Reference files are preserved before any production edits. No numerical model
is rewritten. Each shared primitive width becomes a separate fixed module.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/fixed32_3_20261022'


def run(args, log, cwd=ROOT):
    (OUT / 'tmp').mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env['TMPDIR'] = str(OUT / 'tmp')
    with (OUT / log).open('w') as stream:
        subprocess.run(args, cwd=cwd, env=env, stdout=stream,
                       stderr=subprocess.STDOUT, check=True)


def prepare():
    if OUT.exists():
        raise SystemExit('Preserve existing evidence; use another phase')
    (OUT / 'tmp').mkdir(parents=True)
    reference = OUT / 'reference'
    reference.mkdir()
    paths = (ROOT / 'rtl/production.f').read_text().splitlines()
    paths += ['rtl/production.f', 'rtl/production_freeze.json', 'rtl/posit_mac.vh']
    manifest = {}
    with zipfile.ZipFile(OUT / 'reference_source.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for rel in paths:
            source = ROOT / rel
            data = source.read_bytes()
            dest = reference / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            archive.writestr(rel, data)
            manifest[rel] = hashlib.sha256(data).hexdigest()
    (OUT / 'reference_sha256.json').write_text(json.dumps(manifest, indent=2)+'\n')
    run(['verilator', '--version'], 'verilator.txt')
    run(['g++', '--version'], 'compiler.txt')
    roots = ['posit_mac_nf', 'posit_mac_f', 'posit_mul_iter',
             'posit_add_comb', 'posit_pack_comb', 'round_unpacked_comb']
    for top in roots:
        args = ['verilator', '--xml-only', '--no-timing', '-Wno-fatal',
                '-Wno-ASSIGNDLY', '--top-module', top, '-Irtl',
                '-GNB=32', '-GES=3', '-f', 'rtl/production.f',
                '--xml-output', str(OUT / (top+'.xml'))]
        run(args, top+'_elaborate.log', reference)
    (OUT / 'status.txt').write_text('REFERENCE_ELABORATED\n')


def closing(text, start):
    depth = 0
    for i in range(start, len(text)):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if not depth:
                return i
    raise ValueError('Unbalanced parentheses')


def literal(var):
    const = var.find('const')
    if const is None:
        raise ValueError('Nonconstant parameter '+var.get('name'))
    value = const.get('name')
    if var.get('vartype') == 'int':
        match = re.fullmatch(r"(\d+)'(s?)h([0-9a-f]+)", value)
        if not match:
            raise ValueError(value)
        number = int(match[3], 16)
        if match[2] and number & (1 << (int(match[1])-1)):
            number -= 1 << int(match[1])
        return str(number)
    return value


def specialize():
    destination = OUT / 'fixed'
    if destination.exists() and not (OUT/'before_literal_ports.zip').exists():
        with zipfile.ZipFile(OUT/'before_literal_ports.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
            for item in destination.rglob('*'):
                if item.is_file():
                    archive.write(item, str(item.relative_to(destination)))
    (destination / 'rtl').mkdir(parents=True, exist_ok=True)
    variants = {}
    definitions = []
    xml_maps = []
    module_counts = {}
    for xml_path in sorted(OUT.glob('*.xml'), key=lambda p: (
            p.stem != 'posit_mac_nf', p.stem != 'posit_mac_f', p.name)):
        tree = ET.parse(xml_path)
        module_map = {}
        for node in tree.findall('./netlist/module'):
            original = node.get('origName')
            params = {v.get('name'): literal(v) for v in node.findall('var')
                      if v.get('param') == 'true'}
            key = (original, tuple(params.items()))
            if key not in variants:
                count = module_counts.get(original, 0)
                module_counts[original] = count + 1
                name = original if count == 0 else original + '_fixed' + str(count+1)
                variants[key] = name
                definitions.append((node, name, params, tree))
            module_map[node.get('name')] = variants[key]
        xml_maps.append((tree, module_map))

    known = {node.get('origName') for node, _, _, _ in definitions}
    sources = {Path(p).stem: p for p in
               (OUT / 'reference/rtl/production.f').read_text().splitlines()}
    generated = []
    mapping = []
    for node, name, params, tree in definitions:
        original = node.get('origName')
        relative = sources[original]
        text = (OUT / 'reference' / relative).read_text()
        module_map = next(m for t, m in xml_maps if t is tree)
        cells = {}
        for cell in node.iter('instance'):
            target = module_map[cell.get('defName')]
            cell_name = cell.get('origName', cell.get('name'))
            if cell_name in cells and cells[cell_name] != target:
                raise ValueError('Context-dependent generated cell '+cell_name)
            cells[cell_name] = target

        header = re.search(r'\bmodule\s+'+original+r'\s*#\s*\(', text)
        constants = []
        if header:
            opening = header.end()-1
            end = closing(text, opening)
            declarations = text[opening+1:end]
            for param_name, value in params.items():
                declaration = re.search(
                    r'\bparameter\s+([^=,]*?\b'+param_name+r')\s*=', declarations)
                if not declaration:
                    raise ValueError('Missing declaration '+original+'.'+param_name)
                original_expr = declarations[declaration.end():].split(',')[0].strip()
                constants.append('    // '+param_name+': '+original_expr.replace('\n', ' ')+' (original).\n'
                                 +'    localparam '+declaration[1].strip()+' = '+value+';\n')
            text = text[:header.start()]+'module '+name+' '+text[end+1:]
        else:
            text = re.sub(r'\bmodule\s+'+original+r'\b', 'module '+name, text, count=1)
        ports = re.search(r'\bmodule\s+'+name+r'\s*\(', text)
        port_end = closing(text, ports.end()-1)
        semi = text.index(';', port_end)
        text = text[:semi+1]+'\n    // Fixed posit32/ES3 elaboration; no public parameters.\n'+''.join(constants)+text[semi+1:]

        # Materialize evaluated module-scope localparams; loop/genvar constants
        # stay structural, because their value depends on that loop iteration.
        for var in node.findall('var'):
            if var.get('localparam') != 'true' or var.get('vartype') != 'int':
                continue
            param_name = var.get('name')
            pattern = r'(\blocalparam\s+int\s+'+param_name+r'\s*=\s*)([^;]+);'
            value = literal(var)
            text = re.sub(pattern, lambda m: m[1]+value+'; // '+m[2].strip().replace('\n', ' '),
                          text, count=1)

        pattern = re.compile(r'\b('+'|'.join(sorted(known, key=len, reverse=True))+r')\b\s*(#\s*\()?')
        replacements = []
        for match in pattern.finditer(text):
            # Module definitions and comments cannot be cells without a name + '('.
            after = match.end()
            if match[2]:
                after = closing(text, match.end()-1)+1
            tail = re.match(r'\s*([A-Za-z_]\w*)\s*\(', text[after:])
            if not tail:
                continue
            cell_name = tail[1]
            target = cells.get(cell_name)
            if target is None:
                # An inactive generate arm is never elaborated for this fixed
                # profile. Resolve its name without retaining free overrides.
                target = next(n for nd, n, _, _ in definitions if nd.get('origName') == match[1])
            replacements.append((match.start(), after, target+' '))
        for start, end, value in reversed(replacements):
            text = text[:start]+value+text[end:]
        # Literal ANSI port ranges also work in ModelSim10.1d, which does not
        # resolve a module-body localparam while parsing the preceding header.
        types = {v.get('id'): v for v in tree.findall('./netlist/typetable/*')}
        port_start = re.search(r'\bmodule\s+'+name+r'\s*\(', text).end()-1
        port_end = closing(text, port_start)
        port_text = text[port_start:port_end+1]
        for var in node.findall('var'):
            if not var.get('dir'):
                continue
            dtype = types[var.get('dtype_id')]
            if dtype.get('left') is not None:
                dim = '['+dtype.get('left')+':'+dtype.get('right')+'] '
                port_text = re.sub(r'\[[^\]]+\]\s*(?='+re.escape(var.get('name'))+r'\b)',
                                   lambda m: dim, port_text)
        text = text[:port_start]+port_text+text[port_end+1:]
        # Remove constants made unused by eliminating child overrides.
        while True:
            clean = re.sub(r'//[^\n]*|/\*.*?\*/', '', text, flags=re.S)
            removals = []
            for decl in re.finditer(r'\blocalparam\s+[^;=]+\s+(\w+)\s*=\s*[^;]+;', text):
                if len(re.findall(r'\b'+decl[1]+r'\b', clean)) == 1:
                    removals.append((decl.start(), decl.end()))
            if not removals:
                break
            for start, end in reversed(removals):
                text = text[:start]+text[end:]
        text = re.sub(r'// File\s*:[^\n]*', '// File          : '+name+'.sv', text, count=1)
        rel_new = str(Path(relative).with_name(name+'.sv'))
        dest = destination / rel_new
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text)
        generated.append(rel_new)
        mapping.append({'module': name, 'original': relative, 'constants': params,
                        'cells': cells})
    (destination / 'rtl/production.f').write_text('\n'.join(generated)+'\n')
    (destination / 'rtl/posit_mac.vh').write_bytes((OUT / 'reference/rtl/posit_mac.vh').read_bytes())
    (OUT / 'specialization.json').write_text(json.dumps(mapping, indent=2)+'\n')
    (OUT / 'status.txt').write_text('FIXED_SOURCES_GENERATED\n')
    print('Fixed modules:', len(generated))


def promote():
    from audit_fixed32_3 import evidence, static, sha, validate
    verification = evidence()
    assert (OUT/'units/modelsim/status.txt').read_text().strip() == 'PASS'
    assert 'FIXED32_UNITS_PASS modules=37 vectors=740000 mismatch=0' in (
        OUT/'units/modelsim/simulation.log').read_text()
    fixed = OUT/'fixed'
    paths = static(fixed)
    previous = json.loads((OUT/'reference/rtl/production_freeze.json').read_text())
    assert (ROOT/'rtl/production_freeze.json').read_bytes() == (
        OUT/'reference/rtl/production_freeze.json').read_bytes(), 'Live release changed'
    for rel, digest in previous['rtl_sha256'].items():
        assert sha(ROOT/rel) == digest, 'Concurrent production edit '+rel
    for rel, digest in previous['model_sha256'].items():
        assert sha(ROOT/rel) == digest, 'Numerical model changed '+rel
    assert set(previous['production_files']).issubset(paths)
    verification['comb_units'] = {'modules': 37, 'comparisons': 740000,
                                 'mismatches': 0, 'seed': 20261022}
    for rel in paths+['rtl/production.f']:
        target = ROOT/rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes((fixed/rel).read_bytes())
    maps = json.loads((ROOT/'scripts/rtl_paths.json').read_text())
    for rel in paths:
        maps['rtl/'+Path(rel).name] = rel
    (ROOT/'scripts/rtl_paths.json').write_text(json.dumps(maps, indent=2)+'\n')
    (ROOT/'scripts/rtl_paths.tsv').write_text(''.join(k+'\t'+v+'\n' for k,v in maps.items()))
    (ROOT/'scripts/week13_sources.txt').write_text('\n'.join(paths)+'\n')
    recipe = {'release_id': 'POSIT_MAC_RTL_20261022_FIXED32_3',
              'format': {'NB': 32, 'ES': 3}, 'part': 'xc7a35tcpg236-1',
              'source_list': 'rtl/production.f', 'clock_target_ns': 8.3,
              'clock_xdc': 'syn/constraints/a35t_clock_120mhz.xdc',
              'io_xdc': 'syn/constraints/a35t_benchmark_100mhz.xdc',
              'qualification': 'FUNCTION_ONLY_STA_NOT_RERUN',
              'generics': {}, 'nf_exact_enabled': True, 'f_exact_enabled': False}
    (ROOT/'syn/fixed32_3_release.json').write_text(json.dumps(recipe, indent=2)+'\n')
    active_tb = ['fixed32_3_nf_harness.cpp', 'fixed32_3_f_harness.cpp',
                 'tb_fixed32_3_nf.sv', 'tb_fixed32_3_units.sv',
                 'week13_fused_tb.sv', 'tb_week13_fused_event.sv',
                 'prepack_nf_ppa_top.sv', 'week13_fused_ppa_top.sv', 'nf_coverage.vlt']
    contract = ['rtl/posit_mac.vh', 'rtl/production.f', 'Makefile',
                'scripts/rtl_paths.json', 'scripts/rtl_paths.tsv', 'scripts/week13_sources.txt',
                'scripts/fix_posit32_3.py', 'scripts/verify_fixed32_3.py',
                'scripts/verify_fixed32_3_modelsim.ps1', 'scripts/verify_fixed32_3_units.ps1',
                'scripts/audit_fixed32_3.py', 'scripts/audit_rtl_release.py',
                'syn/fixed32_3_release.json', recipe['clock_xdc'], recipe['io_xdc']]
    contract += ['tb/'+name for name in active_tb]
    manifest = {'release_id': recipe['release_id'], 'status': 'FIXED32_3_FUNCTION_VERIFIED',
                'parent_release': previous['release_id'], 'format': recipe['format'],
                'production_files': paths, 'rtl_sha256': {p: sha(ROOT/p) for p in paths},
                'model_sha256': previous['model_sha256'],
                'build_contract_sha256': {p: sha(ROOT/p) for p in contract},
                'verification': verification,
                'limitations': ['No new post-route timing/PPA or board test',
                    'Aggregate10M per NF/F, not new10M per each n/OPS profile',
                    'Exact32/3 AC02>=100M remains open; no exact fused claim',
                    'Legacy parameterized testbenches/candidates require old snapshot',
                    'No new final structural AC04 closure; functional counters are recorded']}
    (ROOT/'rtl/production_freeze.json').write_text(json.dumps(manifest, indent=2)+'\n')
    summary = {'status': 'PASS', 'release_id': recipe['release_id'],
               'fixed_modules': 54, 'public_parameters': 0, 'strict_lint': '54/54 PASS',
               'tools': {'verilator': (OUT/'verilator.txt').read_text().strip(),
                         'compiler': (OUT/'compiler.txt').read_text().splitlines()[0],
                         'modelsim': (OUT/'event_literal_ports/version.log').read_text().strip()},
               'verification': verification, 'limitations': manifest['limitations']}
    (OUT/'summary.json').write_text(json.dumps(summary, indent=2)+'\n')
    inventory = []
    for base in ['rtl', 'tb']:
        for path in sorted((ROOT/base).rglob('*')):
            if path.suffix not in ['.sv', '.v', '.cpp', '.hpp']:
                continue
            rel = str(path.relative_to(ROOT))
            category = 'fixed_production' if rel in paths else (
                'active_fixed32_3_simulation' if rel in ['tb/'+n for n in active_tb] else
                'historical_or_research_not_in_fixed_build')
            inventory.append({'file': rel, 'category': category,
                              'parameter_tokens': len(re.findall(r'\bparameter\b',
                                  re.sub(r'//[^\n]*|/\*.*?\*/','',path.read_text(),flags=re.S)))})
    (OUT/'scope_inventory.json').write_text(json.dumps(inventory, indent=2)+'\n')
    validate(manifest)
    (OUT/'status.txt').write_text('FIXED32_3_FUNCTION_VERIFIED\n')
    print('PROMOTED', manifest['release_id'])


if __name__ == '__main__':
    os.chdir(ROOT)
    if sys.argv[1:] == ['prepare']:
        prepare()
    elif sys.argv[1:] == ['specialize']:
        specialize()
    elif sys.argv[1:] == ['promote']:
        promote()
    else:
        raise SystemExit('Usage: fix_posit32_3.py prepare')
