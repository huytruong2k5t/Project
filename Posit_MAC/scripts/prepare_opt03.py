"""Freeze OPT-03 sources and drivers; never overwrite an earlier experiment."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/opt03_20261017'


def freeze(variant):
    dest = OUT / 'source' / variant
    assert not dest.exists(), f'Preserve existing snapshot: {dest}'
    dest.mkdir(parents=True)
    for name in (ROOT / 'rtl/production.f').read_text().splitlines():
        if name.strip():
            shutil.copy2(ROOT / name, dest)
    shutil.copy2(ROOT / 'rtl/posit_mac.vh', dest)
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
              for p in dest.iterdir()}
    (OUT / f'{variant}_sha256.json').write_text(json.dumps(hashes, indent=2)+'\n')


if __name__ == '__main__':
    import sys
    freeze(sys.argv[1])
