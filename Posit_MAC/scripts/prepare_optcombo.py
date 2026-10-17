"""Combine only functionally checked candidates, never promote production."""
from pathlib import Path
import hashlib
import json
import shutil

R = Path(__file__).resolve().parents[1]
O = R / 'results/optcombo_20261018'


def main():
    if O.exists():
        raise SystemExit('Preserve existing study')
    required = ('opt05_20261017/verify/abc_tree/status.txt',
                'opt05_20261017/leaf_native_v2/status.txt',
                'opt05_20261017/leaf_event/status.txt',
                'opt09_20261018/verify/magnitude/status.txt',
                'opt09_20261018/product/status.txt',
                'opt10a_20261018/leaf/status.txt',
                'opt10a_20261018/verify/sticky/status.txt')
    for item in required:
        assert (R / 'results' / item).read_text().strip() == 'COMPLETE', item
    shutil.copytree(R / 'results/opt05_20261017/source/baseline', O / 'source/baseline')
    shutil.copytree(R / 'results/opt09_20261018/source/magnitude', O / 'source/combined')
    for name in ('sac_step_comb.sv', 'iter_ctrl.sv'):
        shutil.copy2(R / 'results/opt05_20261017/source/abc_tree' / name, O / 'source/combined' / name)
    shutil.copy2(R / 'results/opt10a_20261018/source/sticky/posit_pack_prepare.sv',
                 O / 'source/combined/posit_pack_prepare.sv')
    hashes = {v: {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in sorted((O / 'source' / v).iterdir())} for v in ('baseline','combined')}
    (O / 'freeze.json').write_text(json.dumps({'candidates': ['OPT05 ABC-tree','OPT09','OPT10A'],
         'production_promotion': False, 'source_sha256': hashes}, indent=2)+'\n')
    print(O)


if __name__ == '__main__':
    main()
