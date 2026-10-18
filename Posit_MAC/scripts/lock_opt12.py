"""Promote the user-selected, byte-identical OPT12 trial; preserve the old lock."""
from pathlib import Path
import copy
import hashlib
import json
import shutil
from audit_opt12 import collect, R, O, sha, read
from audit_rtl_release import validate


def main():
    old_path = R/'rtl/production_freeze.json'
    old = json.loads(read(old_path))
    assert old['release_id'] == 'POSIT_MAC_RTL_20261018_OPT02C'
    validate(old)
    result = collect()
    qualified = json.loads(read(O/'qualification.json'))
    assert sha(O/'summary.json') == qualified['summary_sha256']
    saved = json.loads(read(O/'summary.json'))
    for key in ('units', 'pilots', 'stress', 'events', 'ppa'):
        assert result[key] == saved[key], key
    selected = [row for row in result['ppa']
                if row['variant'] == 'negate' and row['clock_ns'] == 8.3
                and row['strategy'] == 'Explore']
    assert {row['top'] for row in selected} == {'nf', 'f'}
    assert all(row['full_timing_pass'] for row in selected)
    hashes = json.loads(read(O/'variants.json'))['variants']['negate']
    for name, digest in hashes.items():
        assert sha(O/'source/negate'/name) == digest
        if not name.startswith('rtl/parser/'):
            assert sha(R/name) == digest, name
    assert not (O/'promotion.json').exists(), 'Preserve existing promotion'
    assert not (O/'reference_freeze.json').exists()
    shutil.copyfile(old_path, O/'reference_freeze.json')
    for leaf in ('posit_parser.sv', 'posit_parser_comb.sv'):
        source = R/'rtl/candidates/parser/opt12'/leaf
        assert sha(source) == hashes[f'rtl/parser/{leaf}']
        shutil.copyfile(source, R/'rtl/parser'/leaf)
    clock = R/'syn/constraints/a35t_clock_120mhz.xdc'
    assert not clock.exists()
    run = R/selected[0]['path']
    shutil.copyfile(run/'source/syn/constraints/a35t_clock.xdc', clock)
    recipe = dict(
        release_id='POSIT_MAC_RTL_20261018_OPT12_120',
        part='xc7a35tcpg236-1', strategy='Explore', clock_ns=8.3,
        clock_xdc=clock.relative_to(R).as_posix(),
        io_xdc='syn/constraints/a35t_benchmark_100mhz.xdc',
        input_min_ns=2.5, input_max_ns=2.5,
        output_min_ns=0.0, output_max_ns=0.5,
        uncertainty_setup_ns=0.1, uncertainty_hold_ns=0.1,
        place_directive='Explore', route_directive='Explore',
        read_xdc_before_synthesis=True,
        qualified_runs=selected,
        scope='OOC measured profiles only; not board signoff or matched NF/F PPA',
        replay='scripts/run_opt12_ppa.ps1 -Variant negate -Strategy Explore -Period 8.300 -Top nf|f -Attempt <fresh-id>')
    recipe_path = R/'syn/opt12_120mhz_release.json'
    assert not recipe_path.exists()
    recipe_path.write_text(json.dumps(recipe, indent=2)+'\n', encoding='utf-8')
    new = copy.deepcopy(old)
    new.update(release_id=recipe['release_id'], parent_release=old['release_id'],
               selected_variant='OPT12 negate',
               authorization='User requested locking the tested 120MHz RTL on 18/10/2026')
    new['rtl_sha256'] = {name: sha(R/name) for name in old['rtl_sha256']}
    assert new['rtl_sha256'] == hashes
    for name in (clock.relative_to(R).as_posix(), recipe_path.relative_to(R).as_posix()):
        new['build_contract_sha256'][name] = sha(R/name)
    new['qualification'] = dict(
        parser_strict_lint_profiles=870, parser_cycle_checks=84272,
        parser_exhaustive_checks=66480,
        nf_main_completed=10000000, f_main_completed=10000000,
        nf_modelsim_completed=111456, f_modelsim_completed=8192,
        mismatches=0, event_clock_ns=8.0,
        NF_PPA='A35T Explore 8.3ns: WNS +0.227ns, WHS +0.053ns',
        F_PPA='A35T Explore 8.3ns: WNS +0.093ns, WHS +0.040ns')
    new['evidence'] = dict(study='results/opt120_20261018',
                          summary_sha256=sha(O/'summary.json'),
                          qualification_sha256=sha(O/'qualification.json'),
                          reference_freeze_sha256=sha(O/'reference_freeze.json'))
    new['limits'] = [
        'Not W14 final per-n/AC04 acceptance or Gate4; W14 not started.',
        '120.48MHz OOC qualified only for declared profiles and Explore, not board or maximum Fmax.',
        'NF EXACT_EN1 and F EXACT_EN0 are not a matched NF/F PPA pair.',
        'Default F and RuntimeOptimized NF timing failures retained, not waived.',
        '100MHz XDC retained for historical replay; use explicit 8.3ns release recipe for 120MHz.',
        'Any frozen RTL/model/build change requires change review and a new qualified release.']
    validate(new)
    old_path.write_text(json.dumps(new, indent=2)+'\n', encoding='utf-8')
    receipt = dict(status='PROMOTED_LOCKED_FOR_W14', release_id=new['release_id'],
                   release_manifest_sha256=sha(old_path),
                   parent_manifest_sha256=sha(O/'reference_freeze.json'),
                   summary_sha256=sha(O/'summary.json'),
                   selected_variant='negate', strategy='Explore', clock_ns=8.3,
                   changed_rtl=[name for name in hashes if hashes[name] != old['rtl_sha256'][name]],
                   w14_execution='NOT_STARTED', new_simulation='NONE: exact tested bytes promoted')
    (O/'promotion.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print('PROMOTED '+new['release_id']+'; unchanged tested bytes, old lock preserved')


if __name__ == '__main__':
    main()
