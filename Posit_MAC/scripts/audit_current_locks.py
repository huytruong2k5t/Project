"""Verify the two current source locks, their evidence and optional live RTL."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--frozen-only',action='store_true')
    a=ap.parse_args()
    index=json.loads((ROOT/'releases/current.json').read_text())
    package=ROOT/index['package']
    assert sha(package/'source.sha256.json')==index['source_index_sha256']
    files=json.loads((package/'source.sha256.json').read_text())
    for rel,h in files.items():
        assert sha(package/'source'/rel)==h,rel
        if not a.frozen_only and rel not in ['rtl/mac_nf.f','rtl/mac_f.f']:
            assert sha(ROOT/rel)==h,'Live input differs from lock: '+rel
    for version in index['versions']:
        path=ROOT/version['manifest'];assert sha(path)==version['manifest_sha256']
        manifest=json.loads(path.read_text())
        for rel,h in manifest['dut_source_sha256'].items():
            assert sha(package/'source'/rel)==h,rel
            # Per-variant .f lives in the package; active sources also exist live.
            if not a.frozen_only and rel not in ['rtl/mac_nf.f','rtl/mac_f.f']:
                assert sha(ROOT/rel)==h,'Live source differs from lock: '+rel
        for rel,h in manifest['evidence_sha256'].items():assert sha(ROOT/rel)==h,rel
        print('SOURCE_LOCK_AUDIT_PASS',version['variant'],manifest['rtl_modules'],'RTL modules')


if __name__=='__main__':main()
