#!/usr/bin/env python3
"""Archive inactive RTL without changing frozen RTL or historical release metadata.

The active MAC file list is separate from the frozen 54-module release list.
Legacy runners require `restore` first. No source text is rewritten here.
"""
from pathlib import Path
import hashlib
import io
import json
import re
import subprocess
import sys
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = ROOT / 'archive/rtl_support_20261029.json'
ZIP = ROOT / 'archive/rtl_support_20261029.zip'
ACTIVE = ROOT / 'rtl/mac_active.f'
DATE = '2026-10-29'
UNUSED = {
    'posit_mul_iter', 'mul_iter_wrapper', 'mul_norm_comb', 'posit_add_comb',
    'round_unpacked_comb', 'posit_pack_comb', 'posit_parser_comb',
    'dyn_left_shifter_fixed4',
}
LEGACY_TB = [
    'tb/multiplier_checker.sv',
    'tb/tb_week9_multiplier.sv',
    'tb/tb_week9_multiplier_single.sv',
    'tb/arithmetic_checker.sv',
    'tb/tb_week9_arithmetic.sv',
    'tb/tb_week10_adder_comb.sv',
    'tb/tb_week10_invalid_params.sv',
    'tb/tb_posit_parser_comb.sv',
    'tb/tb_paper_mul_iter.sv',
    'tb/tb_paper_fig5_pack.sv',
    'tb/tb_week9_paper.sv',
    'tb/tb_packer_ppa.sv',
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def inside(relative):
    # Used before every extraction, unlink, and directory removal.
    path = Path(relative)
    if path.is_absolute() or '..' in path.parts or ':' in str(relative):
        raise ValueError('Unsafe relative path: ' + str(relative))
    target = ROOT / path
    if not target.resolve().is_relative_to(ROOT.resolve()):
        raise ValueError('Path escapes project: ' + str(relative))
    return target


def strip_comments(text):
    return re.sub(r'//[^\n]*|/\*.*?\*/', '', text, flags=re.S)


def closure(files, read):
    codes = {Path(p).stem: strip_comments(read(p).decode('utf-8-sig')) for p in files}
    graph = {}
    for parent, text in codes.items():
        children = set()
        for name in codes:
            pattern = r'\b' + re.escape(name) + r'\s+\w+\s*\('
            for match in re.finditer(pattern, text):
                if not text[max(0, match.start()-12):match.start()].strip().endswith('module'):
                    children.add(name)
        graph[parent] = children
    seen = set()
    todo = ['posit_mac_nf', 'posit_mac_f']
    while todo:
        name = todo.pop()
        if name not in seen:
            seen.add(name)
            todo.extend(graph[name])
    return [p for p in files if Path(p).stem in seen]


def pack():
    if any(p.exists() for p in (RECEIPT, ZIP, ACTIVE)):
        raise RuntimeError('Preserve existing archive/active list; pack is one-time')
    freeze = json.loads((ROOT/'rtl/production_freeze.json').read_bytes())
    assert freeze['release_id'] == 'POSIT_MAC_RTL_20261022_FIXED32_3'
    files = freeze['production_files']
    assert len(files) == 54
    protected = {}
    for group in ('rtl_sha256', 'model_sha256', 'build_contract_sha256'):
        protected.update(freeze[group])
    for row in freeze['verification'].values():
        if 'report' in row:
            protected[row['report']] = row['sha256']
    for name, digest in protected.items():
        assert sha(inside(name).read_bytes()) == digest, 'Frozen input changed: ' + name
    active = closure(files, lambda name: inside(name).read_bytes())
    inactive = sorted(set(files)-set(active))
    assert {Path(p).stem for p in inactive} == UNUSED
    assert len(active) == 46
    extra = sorted(p.relative_to(ROOT).as_posix() for group in ('candidates', 'research', 'benchmarks')
                   for p in (ROOT/'rtl'/group).rglob('*') if p.is_file())
    assert sum(name.endswith('.sv') for name in extra) == 30
    removed = sorted(inactive + extra + LEGACY_TB)
    # Frozen TBs serve active release replay and are deliberately kept loose.
    assert not set(LEGACY_TB).intersection(protected)
    inventory = set(removed) | set(protected)
    for directory, pattern in [('rtl', '*'), ('tb', '*'), ('scripts', '*')]:
        for p in (ROOT/directory).rglob(pattern):
            if p.is_file() and '__pycache__' not in p.parts and p.suffix not in ('.pyc', '.pyo'):
                inventory.add(p.relative_to(ROOT).as_posix())
    inventory.update([
        'rtl/production_freeze.json', 'Makefile', '.gitattributes',
        'results/fixed32_3_20261022/specialization.json',
        'results/fixed32_3_20261022/summary.json',
        'results/fixed32_3_20261022/lint_summary.json',
        'results/fixed32_3_20261022/reference_sha256.json',
        'results/fixed32_3_20261022/reference_source.zip',
    ])
    payload = {name: inside(name).read_bytes() for name in sorted(inventory)}
    index = {
        'date': DATE, 'release_id': freeze['release_id'],
        'entries': {name: {'sha256': sha(data), 'bytes': len(data)} for name, data in payload.items()},
        'removed': removed, 'inactive_production': inactive,
        'inactive_other_rtl': extra, 'legacy_tb_removed': LEGACY_TB,
        'active_files': active,
        'notes': [
            'All RTL/TB contents preserved byte-for-byte; no functional change.',
            'Frozen production.f and production_freeze.json remain unchanged.',
            'Archive includes shared TB copies; frozen NF/F/shared TB originals stay live.',
            'Legacy parameterized TBs need their historical checkpoint, not fixed module overrides.',
            'No simulation, synthesis, timing, FULL_TERM or new numerical qualification is implied.',
        ],
    }
    with zipfile.ZipFile(ZIP, 'x', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in payload.items():
            archive.writestr(name, data)
        archive.writestr('ARCHIVE_INDEX.json', json.dumps(index, indent=2)+'\n')
    with zipfile.ZipFile(ZIP) as archive:
        assert archive.testzip() is None
        for name, data in payload.items():
            assert archive.read(name) == data, name
    # Recheck live bytes before deleting any file; do not lose concurrent edits.
    for name, data in payload.items():
        assert inside(name).read_bytes() == data, 'Concurrent edit: ' + name
    active_data = ('\n'.join(active)+'\n').encode()
    ACTIVE.write_bytes(active_data)
    receipt = {
        'status': 'PACK_VERIFIED_BEFORE_REMOVAL', 'date': DATE,
        'archive': ZIP.relative_to(ROOT).as_posix(), 'archive_sha256': sha(ZIP.read_bytes()),
        'archive_bytes': ZIP.stat().st_size, 'archive_entries': len(payload),
        'release_id': freeze['release_id'],
        'frozen_manifest_sha256': sha((ROOT/'rtl/production_freeze.json').read_bytes()),
        'active_list': ACTIVE.relative_to(ROOT).as_posix(), 'active_list_sha256': sha(active_data),
        'active_modules': len(active), 'removed': removed,
        'removed_bytes': sum(len(payload[name]) for name in removed),
        'verification': 'ZIP CRC and each entry SHA256; all frozen inputs checked before removal',
    }
    RECEIPT.write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    for name in removed:
        target = inside(name)
        assert sha(target.read_bytes()) == index['entries'][name]['sha256']
        target.unlink()
    # Only remove empty directories under the three archived RTL groups.
    for group in ('candidates', 'research', 'benchmarks'):
        base = inside('rtl/'+group)
        for directory in sorted((p for p in base.rglob('*') if p.is_dir()), key=lambda p: len(p.parts), reverse=True):
            inside(directory.relative_to(ROOT)).rmdir() if not any(directory.iterdir()) else None
        if not any(base.iterdir()):
            inside(base.relative_to(ROOT)).rmdir()
    receipt['status'] = 'ARCHIVED_AND_REMOVED'
    RECEIPT.write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    audit()


def load_archive():
    receipt = json.loads(RECEIPT.read_bytes())
    assert sha(ZIP.read_bytes()) == receipt['archive_sha256'], 'ZIP changed'
    with zipfile.ZipFile(ZIP) as archive:
        assert archive.testzip() is None
        index = json.loads(archive.read('ARCHIVE_INDEX.json'))
        assert set(archive.namelist()) == set(index['entries']) | {'ARCHIVE_INDEX.json'}
        payload = {}
        for name, item in index['entries'].items():
            inside(name)
            data = archive.read(name)
            assert len(data) == item['bytes'] and sha(data) == item['sha256'], name
            payload[name] = data
    return receipt, index, payload


def audit():
    receipt, index, payload = load_archive()
    assert sha(ACTIVE.read_bytes()) == receipt['active_list_sha256']
    assert sha((ROOT/'rtl/production_freeze.json').read_bytes()) == receipt['frozen_manifest_sha256']
    freeze = json.loads(payload['rtl/production_freeze.json'])
    removed = set(index['removed'])
    checked = 0
    for group in ('rtl_sha256', 'model_sha256', 'build_contract_sha256'):
        for name, digest in freeze[group].items():
            current = inside(name)
            data = current.read_bytes() if current.exists() else payload[name] if name in removed else b''
            assert sha(data) == digest, 'Frozen input changed/missing: ' + name
            checked += 1
    for row in freeze['verification'].values():
        if 'report' in row:
            assert sha(inside(row['report']).read_bytes()) == row['sha256']
    for name in removed:
        if inside(name).exists():
            assert inside(name).read_bytes() == payload[name], 'Changed restored file: ' + name
    active = ACTIVE.read_text(encoding='utf-8').splitlines()
    assert active == index['active_files']
    assert active == closure(freeze['production_files'], lambda name: inside(name).read_bytes() if inside(name).exists() else payload[name])
    assert all(inside(name).read_bytes() == payload[name] for name in active)
    if 'historical_git_checkpoint' in receipt:
        historical = receipt['historical_git_checkpoint']
        assert sha(inside(historical['archive']).read_bytes()) == historical['archive_sha256']
    print(f'ARCHIVE AUDIT PASS: {len(active)} active modules; {len(removed)} archived paths; {checked} frozen input hashes; historical report hashes intact')
    return receipt, index, payload


def restore():
    _, index, payload = load_archive()
    # Preflight every destination before writing any file. Never overwrite edits.
    for name in index['removed']:
        if inside(name).exists() and inside(name).read_bytes() != payload[name]:
            raise RuntimeError('Refuse to overwrite existing data: ' + name)
    count = 0
    for name in index['removed']:
        target = inside(name)
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as stream:
                stream.write(payload[name])
            assert sha(target.read_bytes()) == index['entries'][name]['sha256']
            count += 1
    print(f'RESTORE PASS: {count} files; existing identical files preserved')


def remove_empty_tree(target):
    target = inside(target.relative_to(ROOT))
    assert not any(p.is_file() for p in target.rglob('*')), 'Preserve unexpected self-test files'
    directories = sorted((p for p in target.rglob('*') if p.is_dir()), key=lambda p: len(p.parts), reverse=True)
    for directory in directories + [target]:
        for attempt in range(12):
            try:
                inside(directory.relative_to(ROOT)).rmdir()
                break
            except PermissionError:
                if attempt == 11:
                    raise
                time.sleep(0.25)


def self_test():
    receipt, index, payload = audit()
    relative = 'scratch/rtl_support_restore_selftest_20261029'
    target = inside(relative)
    if target.exists():
        # A prior Windows directory lock may leave empty folders after all
        # verified temporary files were removed. Preserve any remaining data.
        remove_empty_tree(target)
    target.mkdir(parents=True)
    for name, data in payload.items():
        destination = inside(relative+'/'+name)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        assert destination.read_bytes() == data
    run = subprocess.run([sys.executable, '-B', str(target/'scripts/audit_rtl_release.py'), '--self-test'],
                         cwd=target, text=True, capture_output=True)
    print(run.stdout.strip())
    if run.returncode:
        print(run.stderr)
        raise RuntimeError('Restored frozen release audit failed; self-test data preserved')
    assert 'RTL RELEASE PASS' in run.stdout
    git_audit = None
    historical_files = {}
    if 'historical_git_checkpoint' in receipt:
        historical = receipt['historical_git_checkpoint']
        with zipfile.ZipFile(io.BytesIO(inside(historical['archive']).read_bytes())) as archive:
            assert archive.testzip() is None
            for item in archive.infolist():
                if item.is_dir():
                    continue
                name = relative+'/git_checkpoint/'+item.filename
                destination = inside(name)
                destination.parent.mkdir(parents=True, exist_ok=True)
                data = archive.read(item)
                destination.write_bytes(data)
                historical_files[name] = data
        historical_root = target/'git_checkpoint/Posit_MAC'
        original = subprocess.run([sys.executable, '-B', str(historical_root/'scripts/audit_rtl_release.py'), '--self-test'],
                                  cwd=historical_root, text=True, capture_output=True)
        print(original.stdout.strip())
        if original.returncode:
            print(original.stderr)
            raise RuntimeError('Original Git checkpoint audit failed; extraction preserved')
        assert 'RTL RELEASE PASS' in original.stdout
        git_audit = {'status': 'PASS', 'commit': historical['commit'],
                     'scope': 'Original Git checkpoint; matches original summary manifest hash'}
        for name, data in historical_files.items():
            destination = inside(name)
            assert destination.read_bytes() == data
            destination.unlink()
    # Delete only the exact temporary files just extracted, after checking paths/hashes.
    for name, data in payload.items():
        destination = inside(relative+'/'+name)
        assert destination.read_bytes() == data
        destination.unlink()
    remove_empty_tree(target)
    receipt['restore_self_test'] = {
        'status': 'PASS', 'restored_entries': len(payload),
        'current_manifest_audit': '54 modules; 4/4 in-memory anti-tamper guards passed; not historical functional qualification',
        'original_git_checkpoint_audit': git_audit,
        'temporary_directory_removed': True,
    }
    RECEIPT.write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print('RESTORE SELF-TEST PASS: frozen release validated in an isolated extraction; live RTL unchanged')


if __name__ == '__main__':
    actions = {'pack': pack, 'audit': audit, 'restore': restore, 'self-test': self_test}
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        raise SystemExit('Usage: python scripts/manage_rtl_support_archive.py pack|audit|restore|self-test')
    actions[sys.argv[1]]()
