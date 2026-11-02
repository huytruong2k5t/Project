"""One-time user-authorized removal of local scratch/build and obsolete archives.

Does not follow reparse points or remove anything outside the workspace.
Preserves current source, delivered documents and every results artifact.
"""
from pathlib import Path
import hashlib
import json
import os
import stat

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / 'Posit_MAC'
RECEIPT = PROJECT / 'docs/local_build_cleanup_20261103_final.json'
TARGETS = ['.slide_build', 'posit_slide_build', 'tmp', 'Posit_MAC/tmp',
           'Posit_MAC/scratch', 'Posit_MAC/l0/__pycache__', 'xvlog.pb']
TARGETS += ['Posit_MAC/presentation/' + name for name in [
    '.build_add_comb_20261020', '.build_chuong3_20261028',
    '.build_mac_datapath_20261018', '.build_mac_share_20261020']]


def reparse(path):
    return bool(path.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT)


def inside(path):
    # Validate lexical path AND every parent; never traverse a junction.
    path = Path(os.path.abspath(path))
    relative = path.relative_to(ROOT)
    cursor = ROOT
    for part in relative.parts[:-1]:
        cursor = cursor / part
        if cursor.exists() and reparse(cursor):
            raise ValueError(f'Reparse parent: {cursor}')
    return path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def collect(path, files, links, directories, errors):
    path = inside(path)
    try:
        if not os.path.lexists(path):
            return
        if reparse(path):
            links.append(path)
        elif path.is_dir():
            directories.append(path)
            for child in path.iterdir():
                collect(child, files, links, directories, errors)
        else:
            files.append(path)
    except OSError as exc:
        errors.append({'path': str(path), 'error': str(exc)})


def protected():
    result = {}
    # Protect all project working inputs/results, excluding explicitly retired areas.
    for folder in ['rtl', 'tb', 'tests', 'scripts', 'l0', 'l1', 'syn',
                   'results', 'experiments', 'docs', 'presentation', 'asic']:
        base = PROJECT / folder
        for dp, dirs, names in os.walk(base, followlinks=False):
            dirs[:] = [d for d in dirs if d not in {'.git', '__pycache__'}
                       and not d.startswith('.build')
                       and not reparse(Path(dp) / d)]
            for name in names:
                p = Path(dp) / name
                if p == RECEIPT or reparse(p):
                    continue
                result[p.relative_to(ROOT).as_posix()] = digest(p)
    for folder in ['doc', 'Ppt', 'posit_slide_output']:
        for dp, dirs, names in os.walk(ROOT / folder, followlinks=False):
            dirs[:] = [d for d in dirs if not reparse(Path(dp) / d)]
            for name in names:
                p = Path(dp) / name
                if not reparse(p) and not name.startswith('~'):
                    result[p.relative_to(ROOT).as_posix()] = digest(p)
    for p in list(ROOT.glob('*')) + list(PROJECT.glob('*')):
        if p.is_file() and p.name != 'xvlog.pb' and not reparse(p):
            result[p.relative_to(ROOT).as_posix()] = digest(p)
    return result


def main():
    if RECEIPT.exists():
        raise SystemExit('Receipt exists; inspect it rather than rerunning destructive cleanup.')
    targets = [ROOT / p for p in TARGETS]
    archive = PROJECT / 'archive'
    targets += [p for p in archive.iterdir() if p.name not in {'README.md', '.gitattributes'}]
    files, links, directories, errors = [], [], [], []
    for path in targets:
        print('Inventory: ' + str(path.relative_to(ROOT)), flush=True)
        collect(path, files, links, directories, errors)
    print('Hashing preserved files', flush=True)
    before = protected()
    records = [{'path': p.relative_to(ROOT).as_posix(), 'bytes': p.stat().st_size}
               for p in files]
    report = {'date': '2026-11-03', 'status': 'PLANNED',
              'authorization': 'User requested deletion of generated local builds and obsolete frozen archives.',
              'targets': [p.relative_to(ROOT).as_posix() for p in targets],
              'planned_files': records,
              'links': [p.relative_to(ROOT).as_posix() for p in links],
              'scan_errors': errors, 'deleted_files': 0, 'deleted_bytes': 0,
              'deleted_links': [], 'failures': [],
              'protected_file_count': len(before), 'synthesis_run': False,
              'simulation_run': False}
    RECEIPT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    for p, record in zip(files, records):
        try:
            inside(p)
            if reparse(p):
                raise ValueError('Path changed to reparse point')
            p.unlink()
            report['deleted_files'] += 1
            report['deleted_bytes'] += record['bytes']
        except (OSError, ValueError) as exc:
            report['failures'].append({'path': str(p), 'error': str(exc)})
    for p in links:
        try:
            inside(p)
            if not reparse(p):
                raise ValueError('Expected reparse point')
            if p.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_DIRECTORY:
                os.rmdir(p)  # Junction itself only, never its target.
            else:
                p.unlink()
            report['deleted_links'].append(p.relative_to(ROOT).as_posix())
        except (OSError, ValueError) as exc:
            report['failures'].append({'path': str(p), 'error': str(exc)})
    for p in sorted(directories, key=lambda x: len(x.parts), reverse=True):
        try:
            inside(p)
            p.rmdir()  # Empty directories only.
        except OSError as exc:
            report['failures'].append({'path': str(p), 'error': str(exc)})
    after = protected()
    report['protected_files_unchanged'] = before == after
    report['changed_protected_files'] = sorted(k for k in before.keys() | after.keys()
                                                if before.get(k) != after.get(k))
    report['remaining_targets'] = [p.relative_to(ROOT).as_posix() for p in targets
                                   if os.path.lexists(p)]
    report['status'] = 'PASS' if before == after and not report['remaining_targets'] else 'PARTIAL'
    RECEIPT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: report[k] for k in ['status', 'deleted_files',
        'deleted_bytes', 'protected_file_count', 'protected_files_unchanged',
        'remaining_targets']}, indent=2))


if __name__ == '__main__':
    main()
