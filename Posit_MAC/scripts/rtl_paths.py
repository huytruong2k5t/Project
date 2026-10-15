"""Resolve legacy RTL paths without changing historical evidence or its hashes."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
PATHS = json.loads((ROOT / 'scripts/rtl_paths.json').read_text())


def resolve_source(path):
    path = Path(path)
    try:
        relative = path.relative_to(ROOT).as_posix()
    except ValueError:
        return path
    return ROOT / PATHS.get(relative, relative)


def rtl_source(name):
    return resolve_source(ROOT / 'rtl' / name)


def rtl_files():
    return [ROOT / name for name in PATHS.values()]
