"""Prepare an isolated 8.3ns XCVU9P experiment from the locked release."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import re
from audit_rtl_release import validate

R = Path(__file__).resolve().parents[1]
O = R/'results/xcvu9p_trial_20261018'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    assert len(sys.argv) in (2, 3) and sys.argv[1] in ('nf', 'f')
    top = sys.argv[1]
    attempt = sys.argv[2] if len(sys.argv) == 3 else ''
    assert not attempt or re.fullmatch(r'[A-Za-z0-9_]+', attempt)
    release = json.loads((R/'rtl/production_freeze.json').read_text())
    validate(release)
    assert release['release_id'] == 'POSIT_MAC_RTL_20261018_OPT12_120'
    run = O/(top+'_p8300_Explore'+('_'+attempt if attempt else ''))
    assert not run.exists(), 'Preserve existing evidence; create a reviewed new attempt'
    for folder in ('source', 'tmp', 'appdata', 'localappdata'):
        (run/folder).mkdir(parents=True)
    names = release['production_files']+[
        'rtl/posit_mac.vh', 'rtl/production.f', 'rtl/production_freeze.json',
        'tb/prepack_nf_ppa_top.sv', 'tb/week13_fused_ppa_top.sv',
        'syn/constraints/a35t_clock_120mhz.xdc',
        'syn/constraints/a35t_benchmark_100mhz.xdc']
    for name in names:
        dest = run/'source'/name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(R/name, dest)
    flow = (R/'syn/run_a35t.tcl').read_text()
    flow = flow.replace('xc7a35tcpg236-1', 'xcvu9p-flgb2104-2-i')
    flow = flow.replace('benchmark_100mhz', 'xcvu9p_trial')
    flow = flow.replace('a35t_xcvu9p_trial.xdc', 'a35t_benchmark_100mhz.xdc')
    flow = flow.replace('a35t_clock.xdc', 'a35t_clock_120mhz.xdc')
    flow = flow.replace('- 10.0)', '- 8.3)').replace('clock_period_ns=10 ', 'clock_period_ns=8.3 ')
    flow = flow.replace('place_design -directive Default', 'place_design -directive Explore')
    flow = flow.replace('route_design -directive Default', 'route_design -directive Explore')
    flow = flow.replace('A35T-C2', 'XCVU9P-TRIAL-FIXED-IO')
    flow = flow.replace('A35T_', 'XCVU9P_')
    flow = flow.replace('Fixed 10 ns', 'Fixed 8.3 ns').replace('Fixed 100 MHz', 'Fixed 120.48 MHz')
    flow = flow.replace('create_project -in_memory -part $part',
        'if {[llength [get_parts -quiet $part]] != 1} {error "Device files unavailable: $part"}\n'
        'create_project -in_memory -part $part')
    flow = flow.replace('    report_drc -file drc.rpt',
        '    report_timing -from [all_inputs] -delay_type max -max_paths 10 -file input_setup.rpt\n'
        '    report_timing -to [all_outputs] -delay_type max -max_paths 10 -file output_setup.rpt\n'
        '    report_cdc -details -file cdc.rpt\n'
        '    report_drc -file drc.rpt')
    path = run/'source/syn/run_xcvu9p.tcl'
    path.write_text(flow, encoding='utf-8', newline='\n')
    assert flow.index('read_xdc') < flow.index('    synth_design')
    manifest = dict(
        status='PREPARED_NOT_SYNTHESIZED', top=top,
        part='xcvu9p-flgb2104-2-i', part_basis='Paper specifies xcvu9p only; package/grade chosen per SPEC example',
        release_id=release['release_id'], release_sha256=sha(R/'rtl/production_freeze.json'),
        clock_ns=8.3, strategy='Explore', input_min_ns=2.5, input_max_ns=2.5,
        output_min_ns=0.0, output_max_ns=0.5,
        uncertainty_setup_ns=0.1, uncertainty_hold_ns=0.1,
        source_sha256={p.relative_to(run/'source').as_posix(): sha(p)
                       for p in sorted((run/'source').rglob('*')) if p.is_file()},
        limits='Independent OOC device trial only, not original paper RTL, board signoff, Gate4 or paired NF/F PPA')
    (run/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print('Prepared isolated snapshot:', run.relative_to(R))


if __name__ == '__main__':
    main()
