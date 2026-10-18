"""Audit the pre-W14 release experiment; do not rewrite old checkpoint PASS."""
from pathlib import Path
import hashlib
import json
import re
import statistics
import csv

from collect_opt825 import read

R=Path(__file__).resolve().parents[1]
O=R/'results/opt02c_20261018'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def ppa(run):
    """A measured timing-failing reference is evidence, never a timing PASS."""
    assert read(run/'status.txt').strip()=='COMPLETE'
    m=json.loads(read(run/'manifest.json'))
    for name,digest in m['source_sha256'].items():
        assert sha(run/'source'/name.replace('\\','/'))==digest,name
    source=run.parents[2]/'source'/m['variant']
    for p in (run/'source/rtl').rglob('*'):
        if p.suffix in ('.sv','.vh'):assert sha(p)==sha(source/p.name),p
    log=read(run/'vivado.log')
    assert not re.search(r'^ERROR:',log,re.M)
    critical=re.findall(r'^CRITICAL WARNING:.*$',log,re.M)
    # Route 35-39 truthfully reports a negative timing result. Never permit
    # constraint/parser/unrouted errors under this exception, or suppress logs.
    assert all('[Route 35-39] The design did not meet timing requirements.' in x for x in critical),critical
    for cmd in ('synth_design','place_design','route_design'):
        assert len(re.findall(r'^Command: '+cmd+r'\b',log,re.M))==1
    for name in ('a35t_clock.xdc','a35t_benchmark_100mhz.xdc'):
        assert sha(run/'source/syn/constraints'/name)==sha(R/'syn/constraints'/name)
    flow=read(run/'source/syn/run_a35t.tcl')
    assert flow.index('read_xdc')<flow.index('    synth_design')
    text=read(run/'timing.rpt')
    match=re.search(r'WNS\(ns\).*?\n\s*-.*?\n\s*([-\d.]+)\s+([-\d.]+)\s+\d+\s+\d+\s+([-\d.]+)\s+([-\d.]+)',text,re.S)
    assert match
    timing=dict(zip(('wns_ns','tns_ns','whs_ns','ths_ns'),map(float,match.groups())))
    if critical:assert timing['wns_ns']<0 or timing['whs_ns']<0
    for line in ('There are 0 register/latch pins with no clock.',
                 'There are 0 pins that are not constrained for maximum delay.'):
        assert line in text,line
    resource={}
    util=read(run/'utilization.rpt')
    for name in ('Slice LUTs','Slice Registers','CARRY4','DSPs','RAMB36/FIFO*','RAMB18'):
        hit=re.search(r'^\|\s*'+re.escape(name)+r'\s*\|\s*(\d+)',util,re.M)
        if hit:resource[name]=int(hit[1])
    r2r=float(re.search(r'Slack\s*\([^)]*\)\s*:\s*([-\d.]+)ns',read(run/'r2r_setup.rpt'))[1])
    result=dict(variant=m['variant'],strategy=m['strategy'],resources=resource,**timing,
                r2r_wns_ns=r2r,f_sta_estimate_mhz=1000/(10-r2r),critical_warnings=critical,
                timing_pass=timing['wns_ns']>=0 and timing['whs_ns']>=0,
                scope='A35T-C2 assumed OOC I/O budget, not board signoff')
    if (run/'stages.csv').exists():
        rows=list(csv.DictReader((run/'stages.csv').open()))
        assert len(rows)==24
        structural=dict(x.split('=',1) for x in read(run/'structural.txt').splitlines())
        assert structural['latches']==structural['unrouted']==structural['unclassified']=='0'
        result.update(stages=rows,structural=structural)
    return result


def header(p):
    text=read(p)
    return re.sub(r'\s+','',text[text.index('module '):].split(');',1)[0])


def collect(require_complete=False):
    frozen=json.loads(read(O/'freeze.json'))
    for variant,files in frozen['variants'].items():
        for name,digest in files.items():assert sha(O/'source'/variant/name)==digest,(variant,name)
    assert sha(R/'rtl/candidates/adder/opt02c/posit_add_align.sv')==sha(O/'source/candidate/posit_add_align.sv')
    assert header(O/'source/production/posit_add_align.sv')==header(O/'source/candidate/posit_add_align.sv')
    for name,digest in frozen['verification_inputs'].items():assert sha(R/name)==digest,name
    changed=[p.name for p in (O/'source/candidate').iterdir()
             if sha(p)!=sha(O/'source/reference'/p.name)]
    assert changed==['posit_add_align.sv'],changed
    result={'scope':'pre-W14 promotion qualification, not W14 final or Gate4',
            'ppa':{},'pending_ppa':[],'functional':{}}
    for variant in ('production','candidate'):
        result['ppa'][variant]=[]
        for strategy in ('Default','Explore','RuntimeOptimized'):
            run=O/'ppa'/variant/strategy
            if (run/'status.txt').exists():result['ppa'][variant].append(ppa(run))
            else:result['pending_ppa'].append(f'{variant}/{strategy}')
    previous=R/'results/optcombo_20261018'
    result['ppa']['reference']=[ppa(previous/'ppa/combined'/strategy)
            for strategy in ('Default','Explore','RuntimeOptimized')]
    # Reuse reference measurements only after proving the frozen RTL, XDC,
    # wrapper, source ordering and implementation commands are identical.
    for x in result['ppa']['reference']:
        old=previous/'ppa/combined'/x['strategy']/'source'
        for name,digest in frozen['variants']['reference'].items():
            assert any(sha(p)==digest for p in (old/'rtl').rglob(name)),name
        assert (old/'rtl/production.f').read_text().splitlines()==frozen['production_f']+[
            'rtl/mac_nf/posit_product_pack.sv','rtl/mac_nf/posit_magnitude_parse.sv']
    result['reference_reused_from']='optcombo_20261018, immutable measured source and identical A35T-C2 flow'
    logs=list((O/'verify/candidate/lint').glob('*.log'))
    assert len(logs)==406 and all(not re.search(r'%Warning|%Error',read(p)) for p in logs)
    result['functional']['strict_leaf_lint']=406
    leaf=read(O/'leaf/simulate.log')
    counts=re.findall(r'ALIGN PASS NB=(\d+) ES=(\d+) SW=(\d+) checks=(\d+) mismatch=0 nar_zero=(\d+) clamp=(\d+) threshold=(\d+) tie=(\d+)',leaf)
    assert len(counts)==11 and 'ALIGN MATRIX PASS' in leaf and not re.search(r'\*\*\s+(Error|Fatal):',leaf)
    assert all(min(map(int,x[4:]))>0 for x in counts)
    result['functional']['leaf_cases']=sum(int(x[3]) for x in counts)
    result['functional']['leaf_profiles']=[dict(NB=int(x[0]),ES=int(x[1]),SF_W=int(x[2]),checks=int(x[3])) for x in counts]
    for nb,es in ((8,0),(16,1),(32,2),(32,3)):
        folder=O/f'verify/candidate/nf/{nb}_{es}'
        assert not re.search(r'%Warning|%Error',read(folder/'lint.log'))
        d=json.loads(read(folder/'pilot_summary.json'))
        assert d['completed']==20000 and d['mismatches']==0 and min(d['bins'])>0
    result['functional']['nf_pilot_completed']=80000
    large=O/'verify/candidate/nf/32_3/acceptance_summary.json'
    if large.exists():
        d=json.loads(read(large))
        assert d==json.loads(read(previous/'verify/combined/nf/32_3/acceptance_summary.json'))
        assert d['completed']==10000000 and d['mismatches']==0
        result['functional']['nf_main']=d
    else:assert not require_complete,'NF main pending'
    if (O/'modelsim/status.txt').exists():
        assert read(O/'modelsim/status.txt').strip()=='COMPLETE'
        events=[]
        for nb,es in ((8,0),(16,1),(32,2),(32,3)):
            for kind in ('simulate','protocol'):
                text=read(O/f'modelsim/{kind}_{nb}_{es}.log')
                m=re.search(r'W11 MODELSIM PASS NB=(\d+) ES=(\d+) rows=(\d+) completed=(\d+) aborted=(\d+) stalls=(\d+) mismatches=0',text)
                assert m and not re.search(r'\*\*\s+(Error|Fatal):',text)
                events.append(dict(zip(('NB','ES','rows','completed','aborted','stalls'),map(int,m.groups()))))
        result['functional']['nf_modelsim']=events
    else:assert not require_complete,'ModelSim pending'
    # The only OPT02c change is outside F's instantiated file list. Every
    # instantiated F source and every golden header must match the 10M proof.
    f_files=(R/'scripts/week13_sources.txt').read_text().splitlines()+['rtl/posit_mac.vh']
    assert all(sha(O/'source/candidate'/Path(p).name)==sha(previous/'source/combined'/Path(p).name) for p in f_files)
    result['functional']['f_10m_reused']={'completed':10000000,'mismatches':0,
        'basis':'all instantiated F dependencies byte-identical to optcombo; arithmetic/golden inputs unchanged',
        'source_sha256':{p:sha(O/'source/candidate'/Path(p).name) for p in f_files}}
    if (O/'fused/status.txt').exists():
        assert read(O/'fused/status.txt').strip()=='COMPLETE'
        d=json.loads(read(O/'fused/pilot.json'))
        assert d==json.loads(read(previous/'fused/pilot.json'))
        assert not re.search(r'%Warning|%Error',read(O/'fused/lint.log'))
        result['functional']['f_smoke']=d
    else:assert not require_complete,'F smoke pending'
    if require_complete:assert not result['pending_ppa'],result['pending_ppa']
    result['ready_for_selection']=not result['pending_ppa'] and all(
        key in result['functional'] for key in ('nf_main','nf_modelsim','f_smoke'))
    f_run=O/'ppa_f/candidate/Default'
    if (f_run/'status.txt').exists():
        result['f_release_sta']=ppa(f_run)
        assert result['f_release_sta']['timing_pass']
        assert result['f_release_sta']['tns_ns']==result['f_release_sta']['ths_ns']==0
    elif require_complete:raise AssertionError('F release timing pending')
    checks=O/'release_checks_v2'
    if (checks/'status.txt').exists():
        assert read(checks/'status.txt').strip()=='COMPLETE'
        reviewed={}
        for label in ('nf','f'):
            structure=dict(line.split('=',1) for line in read(checks/f'{label}_structure.txt').splitlines())
            assert structure['clocks']=='1' and structure['latches']==structure['unrouted']=='0'
            assert 'All paths are Safely Timed.' in read(checks/f'{label}_cdc.rpt')
            for kind,allowed in (('methodology',{'XDCH-2'}),('drc',{'CFGBVS-1'})):
                table=read(checks/f'{label}_{kind}.rpt').split('2. REPORT DETAILS')[-2]
                rules=re.findall(r'^\|\s*([A-Z][A-Z0-9_-]*-\d+)\s*\|\s*(\w+)\s*\|',table,re.M)
                assert all(rule in allowed and severity=='Warning' for rule,severity in rules),rules
            reviewed[label]=structure
        result['release_structure']=reviewed
        result['reset_review']={'clock_domains':1,'new_reset_domains':0,
          'basis':'existing bridge and per-leaf 2FF release preserved; new product sign shares P2 reset/CE; ModelSim abort/stall proof',
          'limits':'report_cdc is defined-clock CDC only; detailed W14-00b RDC/interface review remains, no formal RDC/board signoff',
          'known_warnings':{'XDCH-2':'fixed min=max benchmark input budget, unchanged by request',
                            'CFGBVS-1':'board CONFIG_VOLTAGE/CFGBVS absent in OOC IP benchmark'}}
    elif require_complete:raise AssertionError('Structural release checks pending')
    if result['ready_for_selection']:
        candidate=result['ppa']['candidate'];reference=result['ppa']['reference']
        for x in candidate:
            assert x['wns_ns']>=0 and x['whs_ns']>=0 and x['tns_ns']==x['ths_ns']==0
            assert x['resources']['Slice Registers']==931
        cmed=statistics.median(x['f_sta_estimate_mhz'] for x in candidate)
        rmed=statistics.median(x['f_sta_estimate_mhz'] for x in reference)
        result['selection']={'variant':'candidate' if cmed>=rmed else 'reference',
          'criterion':'functional equivalence and 100MHz setup/hold first; compare median R2R F_STA, report all area tradeoffs',
          'candidate_median_mhz':cmed,'reference_median_mhz':rmed,
          'production_median_mhz':statistics.median(x['f_sta_estimate_mhz'] for x in result['ppa']['production'])}
    (O/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    return result


if __name__=='__main__':
    import sys
    d=collect('--final' in sys.argv)
    print('OPT02C AUDIT '+('READY' if d['ready_for_selection'] else 'PARTIAL')+
          '; NF/oracle/protocol checked; pending PPA='+str(d['pending_ppa']))
