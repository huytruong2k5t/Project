#!/usr/bin/env python3
"""Source-bound quire evidence summary; timing failure cannot become signoff."""
import hashlib
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/quire_20261103'


def load(name):return json.loads((OUT/name).read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def guard(mapping):
    for path,expected in mapping.items():assert sha(ROOT/path)==expected.lower(),path


def main():
    for name in ('build_rtl_final.json','build_units_final.json','build_cov_final.json',
                 'model_manifest.json','ports_and_lint.json','modelsim_signoff/manifest.json',
                 'ppa_final/manifest.json'):
        guard(load(name)['source_sha256'])
    main=load('main_final_summary.json');pilot=load('pilot_final.json');units=load('units_final.json')
    model=load('model.json');bounds=load('bounds.json');coverage=load('coverage_review.json')
    assert bounds['script_sha256']==sha(ROOT/'scripts/verify_quire_bounds.py')
    assert main['status']=='PASS' and main['main_volume_met'] and main['sequence_quota_met']
    for report in (main,pilot,units,model):assert report['status']=='PASS' and report['mismatches']==0
    assert coverage['status']=='PASS'
    rows=[load(label+'.json') for label in main['shards']]
    assert len({row['seed'] for row in rows})==len(rows)
    assert sum(row['main_mac_retired'] for row in rows)==10000000
    assert all(row['accepted']==row['retired']+row['reset_aborted'] for row in rows)
    assert all(row['main_default_only'] and row['build_manifest']=='build_rtl_final.json' for row in rows)
    assert all(x>0 for x in pilot['config_bins'])
    ms=load('modelsim_signoff/manifest.json')
    nf_f=load('nf_f_retained_tests/manifest.json')
    guard(nf_f['sha256'])
    retained=[]
    for label in ('adder','packer','core','nf','f'):
        text=(OUT/('nf_f_retained_tests/verify/'+label+'.log')).read_text(errors='replace')
        markers=[line.strip() for line in text.splitlines() if '_PASS ' in line]
        assert len(markers)==1 and '** Fatal:' not in text and '** Error:' not in text,label
        retained+=markers
    ms_log=(OUT/'modelsim_signoff/simulate.log').read_text(errors='replace')
    marker=next(line.strip() for line in ms_log.splitlines() if 'QUIRE_MODELSIM_PASS' in line)
    latency=[line.strip() for line in ms_log.splitlines() if 'QUIRE_RESPONSE_LATENCY' in line]
    ppa=load('ppa_final/result.json')
    timing_met=ppa['setup_slack_ns']>=0 and ppa['hold_slack_ns']>=0
    text=(OUT/'ppa_final/route_utilization.rpt').read_text()
    def number(name):
        match=re.search(r'\|\s*'+re.escape(name)+r'\s*\|\s*(\d+)\s*\|',text)
        if not match:raise RuntimeError('Missing utilization: '+name)
        return int(match[1])
    resources={key:number(name) for key,name in [('LUT','Slice LUTs'),('FF','Slice Registers'),
                                               ('BRAM_tiles','Block RAM Tile'),('DSP','DSPs')]}
    audit=load('ports_and_lint.json')
    summary={
        'date':'2026-11-03','profile':'MAC_Q12_FULL_TERM_Q12_1024',
        'status':'FUNCTION_VERIFIED_TIMING_OPEN' if not timing_met else 'FUNCTION_VERIFIED_SINGLE_ROUTE',
        'MAC_Q12_VERIFIED':False,
        'configuration':{'posit_bits':32,'es':3,'fraction_bits':12,'M_bits':26,'M_Q':24,
                         'E_LSB':-480,'quire_bits':972,'L_max':1024,'word_bits':36,'word_steps':27,
                         'default_n':12,'default_ops':1},
        'source_guards':'PASS','main':main,'pilot':{k:pilot[k] for k in ('main_mac_retired','config_bins','seed','mismatches')},
        'models':model,'bounds':bounds,'units':{k:units[k] for k in ('align_checks','read_checks','normalizer_checks','bank_checks','mismatches')},
        'modelsim':{'version':ms['modelsim'],'seed':20261103,'marker':marker,'response_latency':latency},
        'audit':{k:audit[k] for k in ('active_modules','named_instances','clock_primitive_bindings','shared_nf_f_rtl_unchanged')},
        'coverage':{'raw':coverage['raw'],'adjusted':coverage['adjusted'],'source_exclusions':len(coverage['exclusions']),
                    'review':'coverage_review.json','scope':coverage['scope']},
        'PPA':{'result':ppa,'resources':resources,'timing_met_at_100MHz':timing_met,
               'scope':'Single A35T OOC route, not board signoff or measured Fmax',
               'worst_path':'u_core.sf_o_reg[0]/C -> u_bank.sum_work_q_reg[824]/CE',
               'data_path_delay_ns':21.575,'logic_levels':32,'route_delay_ns':15.505},
        'gates':{'Q_MODEL':'PASS','TC_Q_BOUND':'PASS','Q_RTL':'PASS',
                 'Q_COVER_STRUCTURAL':'PASS_WITH_3_SOURCE_EXPLAINED_LINE_EXCLUSIONS',
                 'Q_PPA_100MHz':'PASS' if timing_met else 'FAIL_SETUP'},
        'remaining':['Close setup on scale/align/term-zero/error to bank-enable path, then rerun affected tests/PPA',
                     'Full quire timing signoff and any board validation remain open',
                     'Ideal full-input dot-product accuracy comparison is separate and not measured in this session',
                     'NF/F main520M/paired accuracy and timing are separate gates; quire results do not close them'],
        'limits':['Exact accumulation of selected approximate products, not full26-fraction exact Posit dot-product',
                  'No exhaustive2^64 A/B simulation claim; bounds use447 symbolic field geometries',
                  'Interrupted main_v2 and preliminary builds are excluded from main counts',
                  'All commands receive one response; MAC/CLEAR acknowledge d0, READ RNE only'],
        'cleanup':load('cleanup_result.json'),
        'generated_cleanup':load('generated_cleanup_result.json'),
        'preliminary_archive':load('preliminary_archive.json'),
        'retained_nf_f_checks':retained,
        'commands':['python3 -B scripts/verify_quire_bounds.py',
                    'python3 -B scripts/gen_quire_vectors.py results/quire_20261103/python_vectors',
                    'python3 -B scripts/verify_quire.py model',
                    'python3 -B scripts/audit_quire.py',
                    'python3 -B scripts/verify_quire.py build --tag <fresh> --kind units --coverage',
                    'python3 -B scripts/verify_quire.py run --tag <unit-tag> --label <fresh>',
                    'python3 -B scripts/verify_quire.py build --tag <fresh>',
                    'python3 -B scripts/verify_quire.py run --tag <rtl-tag> --label <fresh> --count 100000',
                    'python3 -B scripts/run_quire_main.py --tag <rtl-tag> --label <fresh> --total 10000000 --shards 4',
                    'python scripts/verify_quire_modelsim.py --bin <ModelSim-bin> --label <fresh>',
                    'python scripts/verify_quire_ppa.py --vivado <Vivado-executable> --label <fresh>']}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    print('QUIRE_SUMMARY',summary['status'],'main=10M/0 mismatch','PPA=',resources,ppa)


if __name__=='__main__':main()
