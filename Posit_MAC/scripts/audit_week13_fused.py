"""Audit source-bound W13 evidence; no simulation, no edits to frozen W12."""
from pathlib import Path
from collections import defaultdict
import gzip
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/week13'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(value, message):
    if not value:
        raise RuntimeError(message)


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def snapshot(run):
    for line in (run / 'source.sha256').read_text().splitlines():
        digest, name = line.split(maxsplit=1)
        src = run / name
        require(sha(src) == digest, f'snapshot modified: {src}')
        canonical = ROOT / name.removeprefix('src/')
        require(canonical.is_file() and sha(canonical) == digest,
                f'canonical source differs: {canonical}')


def coverage():
    # Counts are instrumented points, with no exclusions or inferred waivers.
    grouped = defaultdict(dict)
    for path in [OUT/'verilator/pilot.coverage.dat', OUT/'pipe/pipe.coverage.dat']:
        for line in path.read_text().splitlines():
            if not line.startswith('C '):
                continue
            raw, hits = line[3:].rsplit("' ", 1)
            fields = dict(x.split('\x02', 1) for x in raw.split('\x01')[1:])
            filename = Path(fields['f']).name
            kind = fields.get('page', '').split('/')[0]
            if not fields['f'].startswith('src/rtl/'):
                continue
            # Aggregate hierarchy instances for the same source instrumentation.
            key = tuple((k, v) for k, v in sorted(fields.items()) if k not in ('h', 'f', 'page'))
            table = grouped[(filename, kind)]
            table[key] = table.get(key, 0) + int(hits)
        target = path.with_suffix(path.suffix + '.gz')
        target.write_bytes(gzip.compress(path.read_bytes(), mtime=0))
    rows = []
    for (filename, kind), values in sorted(grouped.items()):
        hit = sum(v > 0 for v in values.values())
        rows.append(dict(file=filename, kind=kind, hit=hit, total=len(values),
                         percent=100 * hit / len(values)))
    (OUT/'coverage.json').write_text(json.dumps({
        'definition': 'Raw Verilator instrumented points, aggregate instances by source point; no waiver/exclusion.',
        'limits': 'Line points are not physical source-line percentages; not final AC04 signoff.',
        'rows': rows}, indent=2)+'\n', encoding='utf-8')
    return rows


def main():
    snapshot(OUT/'verilator')
    snapshot(OUT/'pipe')
    main_result = load(OUT/'verilator/main.json')
    pilot = load(OUT/'verilator/pilot.json')
    pipe = load(OUT/'pipe/pipe.json')
    require((OUT/'verilator/main.json').stat().st_mtime >=
            (OUT/'verilator/source.sha256').stat().st_mtime, 'main report predates build snapshot')
    for result, count in [(main_result, 10000000), (pilot, 100000)]:
        require(result['status'] == 'PASS' and result['mismatches'] == 0 and result['completed'] >= count,
                'numeric acceptance failed')
        require(result['accepted'] == result['completed'] + result['reset_aborted'], 'transaction accounting')
        require(result['near']*10 >= result['completed']*3 and result['near_after']*10 >= result['completed']*3,
                'near coverage')
        for key in ['n_hits','config_hits','iterations','flags','near_delta','regime_sign_cross','run_polarity','popcount','delta_before_mode','delta_after_mode']:
            require(min(result[key]) > 0, f'empty functional bin {key}')
    require(pipe['status'] == 'PASS' and pipe['mismatch'] == 0 and pipe['max_inflight'] == 5,
            'elastic pipeline failed')
    lint = (OUT/'lint.log').read_text()
    require('%Warning' not in lint and '%Error' not in lint and 'Built from' in lint, 'strict lint failed')
    for run in ['simulate', 'ppa']:
        for name, digest in load(OUT/run/'source_sha256.json').items():
            require(sha(ROOT/name) == digest, f'{run} source changed: {name}')
    event = (OUT/'simulate/simulate.log').read_text()
    require('W13_EVENT_PASS completed=8192 reset_aborts=24 mismatch=0' in event
            and not re.search(r'Fatal:|ERROR:', event), 'event simulator failed')
    ppa = (OUT/'ppa/metrics.txt').read_text()
    metrics = dict(line.split('=', 1) for line in ppa.splitlines() if '=' in line)
    require(metrics['latches'] == '0', 'inferred latch')
    require('W13_PPA_COMPLETE' in (OUT/'ppa/vivado.log').read_text(), 'PPA incomplete')
    setup, hold = float(metrics['setup_SLACK']), float(metrics['hold_slack'])
    util = (OUT/'ppa/utilization.rpt').read_text()
    lut = int(re.search(r'\| Slice LUTs\s*\|\s*(\d+)', util)[1])
    ff = int(re.search(r'\| Slice Registers\s*\|\s*(\d+)', util)[1])
    stages = {}
    for name in ['f1','f2','f3','f4','f5']:
        text = (OUT/f'ppa/{name}.rpt').read_text()
        stages[name] = dict(setup_slack_ns=float(re.search(r'Slack \(\w+\)\s*:\s*([-\d.]+)ns', text)[1]),
                            datapath_ns=float(re.search(r'Data Path Delay:\s*([\d.]+)ns', text)[1]))
    coverage()
    summary = {
        'status':'PASS_IMPLEMENTED_MAIN_PROFILE_WITH_REMAINING_SIGNOFF', 'date':'2026-10-15',
        'profile': {'NB':32,'ES':3,'FRAC_W':12,'ACC_WIN':32,'Q':29,'EXACT_EN':0,'OPS_EN':1,
                    'n':'0..8','ops':'0/1','term_cut':'FLOOR','rounding':'RNE'},
        'main':main_result, 'pilot':pilot, 'pipe':pipe,
        'event':{'simulator':'Vivado XSim 2026.1','completed':8192,'reset_aborts':24,'mismatches':0,'CK2Q_ns':1,'fixture_sha256':sha(OUT/'verilator/pilot.vectors')},
        'strict_lint':'Verilator 5.032 --timing --assert -Wall; zero warnings/errors',
        'latency':{'q':'max(1,t); NaR/zero bypass t=0','L_valid':'q+11','H_handshake':'q+12',
                   'II_min':'q+13 single transaction; stall extends retire'},
        'ppa':{'part':'xc7a35tcpg236-1','tool':'Vivado 2026.1 build6511674','strategy':'Default',
               'period_ns':10,'r2r_setup_slack_ns':setup,'r2r_hold_slack_ns':hold,
               'r2r_meets_100MHz':setup>=0 and hold>=0,'sta_estimate_MHz':1000/(10-setup),
               'LUT':lut,'FF':ff,'latches':0,'stages':stages,'critical_start':metrics['setup_STARTPOINT_PIN'],
               'critical_end':metrics['setup_ENDPOINT_PIN'],
               'limits':'One OOC run, synthetic I/O, no board pins or Fmax sweep; not paired NF/F PPA. Same min/max input delay yields XDCH-2 warnings.'},
        'remaining':['Final >=10^7 vectors per n per architecture and full AC04 coverage',
                     'Formal/CDC/RDC signoff and final coverage closure',
                     'Matched approximate-only NF on same Xilinx device; >=3 implementation runs and paired accuracy',
                     'Other formats/exact F, board validation and Gate4 not accepted'],
        'notes':['Fused RNE uses approximate P_hat, not exact original A*B.',
                 'Initial pilot generator missed accumulator coverage; fixed before acceptance, with unchanged thresholds.',
                 'Four-state startup exposed assertion enable X; guards fixed, arithmetic unchanged; final rerun required.',
                 'Shared production RTL/L1 unchanged; core instance narrowed to FRAC_MAX12 only within approximate F.'],
        'commands':['bash scripts/run_week13_acceptance.sh','bash scripts/verify_week13_pipe.sh',
                    'powershell -NoProfile -File scripts/run_week13_xilinx.ps1 -Mode simulate',
                    'powershell -NoProfile -File scripts/run_week13_xilinx.ps1 -Mode ppa',
                    'python scripts/audit_week13_fused.py']}
    files = [ROOT/x.strip() for x in (ROOT/'scripts/week13_sources.txt').read_text().splitlines()]
    files += [ROOT/'rtl/posit_mac.vh']
    files += list((ROOT/'tb').glob('*week13*')) + list((ROOT/'scripts').glob('*week13*'))
    files += [ROOT/'l1/include/posit_fused_window.hpp',ROOT/'tb/week12_fused_reference.hpp']
    summary['source_sha256'] = {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in files if p.is_file()}
    report_files = list((OUT/'ppa').glob('*.rpt'))+[OUT/'ppa/metrics.txt',OUT/'coverage.json',
        OUT/'simulate/simulate.log',OUT/'verilator/main.json',OUT/'verilator/pilot.json',OUT/'pipe/pipe.json',
        OUT/'verilator/source.sha256',OUT/'pipe/source.sha256',OUT/'lint.log']
    summary['evidence_sha256']={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in report_files}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print(f'W13 AUDIT PASS: main={main_result["completed"]} mismatch=0, LUT={lut}, FF={ff}, R2R100MHz={setup>=0 and hold>=0}')


if __name__ == '__main__':
    main()
