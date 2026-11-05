#!/usr/bin/env python3
"""Source-bound NF/F coverage: fresh output, 52 points, honest separate gates.

Run in WSL from project root; no synthesis. See tests/nf_f_coverage.md.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out',required=True)
    ap.add_argument('--stage',choices=['build','run','report','all'],default='all')
    ap.add_argument('--count',type=int,default=100000)
    ap.add_argument('--seed',type=int,default=20261105)
    ap.add_argument('--label',default='matrix')
    ap.add_argument('--engine',choices=['coverage','fast'],default='coverage')
    ap.add_argument('--pilot-label')
    ap.add_argument('--pilot-count',type=int,default=100000)
    a=ap.parse_args()
    root=Path(__file__).resolve().parents[1]
    out=(root/a.out).resolve()
    if not out.is_relative_to((root/'results').resolve()):ap.error('--out must be within results')
    if a.count<1 or not a.label.replace('_','').isalnum():ap.error('positive count and simple label required')
    if a.stage in ['build','all'] and out.exists() and a.engine=='coverage':ap.error('choose a fresh output directory')
    os.environ['SHARED_RESULTS_ROOT']=str(out.relative_to(root))
    os.environ['SHARED_BUILD_TAG']='coverage' if a.engine=='coverage' else 'fast'
    os.environ['SHARED_COVERAGE']='1' if a.engine=='coverage' else '0'
    from verify_shared_multiplier import build,execute
    if a.stage in ['build','all']:
        for kind in ['nf','f']:
            path=out/f'build_{kind}.json'
            saved=path.read_bytes() if path.exists() else None
            try:
                if a.engine=='fast' and (out/f'fast_build_{kind}.json').exists():
                    raise RuntimeError('Preserve fast build manifest')
                build(kind)
                if a.engine=='fast':(out/f'fast_build_{kind}.json').write_bytes(path.read_bytes())
            finally:
                if a.engine=='fast':
                    if saved is None:path.unlink(missing_ok=True)
                    else:path.write_bytes(saved)
    if a.stage in ['run','all']:
        def variant(kind):
            import hashlib
            prefix='' if a.engine=='coverage' else 'fast_'
            manifest=json.loads((out/f'{prefix}build_{kind}.json').read_text())
            for p,h in manifest['source_sha256'].items():
                assert hashlib.sha256((root/p).read_bytes()).hexdigest()==h,'Source drift: '+p
            binary=root/manifest['binary']
            assert manifest['coverage_enabled']==(a.engine=='coverage')
            for ops in range(2):
                for n in range(13):
                    p=out/f'{a.label}_{kind}_ops{ops}_n{n}.json'
                    if p.exists():raise RuntimeError('Preserve existing point: '+str(p))
                    execute([str(binary),str(a.count),str(n),str(ops),str(a.seed),str(p)],root,p.with_suffix('.log'))
                    r=json.loads(p.read_text())
                    assert r['status']=='PASS' and r['completed']==a.count and r['mismatches']==0
                    assert r['accepted']==r['completed']+r['reset_aborted']
                    assert r['bins'][ops*13+n]==a.count and sum(r['bins'])==a.count
                    assert not any(r['iterations'][n+1:])
                    if a.engine=='coverage':assert Path(str(p)+'.dat').is_file()
                    print(f'COVERAGE_POINT_PASS {kind} ops{ops} n{n} {a.count}',flush=True)
        with ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(variant,['nf','f']))
    if a.stage in ['report','all']:
        from report_nf_f_coverage import report
        result=report(root,out,a.label,a.count,a.seed,a.pilot_label,a.pilot_count)
        if result['status']!='COVERAGE_PASS':raise SystemExit(2)


if __name__=='__main__':main()
