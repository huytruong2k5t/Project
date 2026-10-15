"""Parse real Quartus post-route reports; missing/invalid reports are failures."""
import csv
import hashlib
import json
from pathlib import Path
import re
import statistics

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'results/week12/nf_ppa'


def read(path):
    raw=path.read_bytes()
    if raw.startswith(b'\xff\xfe'):return raw.decode('utf-16')
    try:return raw.decode('utf-8-sig')
    except UnicodeDecodeError:return raw.decode('cp1252')  # Quartus13 ANSI degree symbol.


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dump(path,value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def cells(line):
    return [s.strip() for s in line.strip().strip(';').split(';')]


def path_report(path):
    text=read(path)
    assert 'Found 10 setup paths' in text,path
    summary=text.split('Path #1:',1)[0]
    paths=[]
    for line in summary.splitlines():
        fields=cells(line)
        if len(fields)==8 and re.fullmatch(r'-?\d+\.\d+',fields[0]):
            paths.append(dict(wns_ns=float(fields[0]),startpoint=fields[1],endpoint=fields[2],
                clock_skew_ns=float(fields[6]),data_delay_ns=float(fields[7])))
    assert len(paths)==10,path
    first=text.split('Path #1:',1)[1].split('Path #2:',1)[0]
    levels=re.search(r';\s*Number of Logic Levels\s*;\s*;\s*(\d+)',first)
    assert levels,path
    data=re.search(r';\s*Data\s*;[^\n]*\n(.*?);\s*Required Path\s*;',first,re.S)
    assert data,path
    physical={}
    for line in data[1].splitlines():
        fields=cells(line)
        if len(fields)==7 and fields[0] in ['IC','Cell','uTco']:
            physical[fields[0]]=float(fields[3])
    assert {'IC','Cell'}<=set(physical)<={'IC','Cell','uTco'},(path,physical)
    if 'uTco' not in physical:
        assert re.fullmatch(r'in_valid|out_ready|rst_n|cfg_mode|cfg_n\[\d+\]|cfg_ops\[\d+\]|acc_mode|acc_clr|[abc]\[\d+\]',paths[0]['startpoint']),('Missing CQ for non-port',path)
    assert abs(sum(physical.values())-paths[0]['data_delay_ns'])<0.005
    data_nodes=[]
    active=False
    arrival=first.split('Data Arrival Path',1)[1].split('Data Required Path',1)[0]
    for line in arrival.splitlines():
        fields=cells(line)
        if len(fields)!=7:continue
        if fields[6]=='data path':active=True;continue
        if active and fields[3] in ['IC','CELL','uTco']:
            data_nodes.append(dict(increment_ns=float(fields[1]),type=fields[3],
                fanout=int(fields[4]) if fields[4].isdigit() else None,node=fields[6]))
    assert data_nodes,path
    return dict(top10=paths,logic_levels=int(levels[1]),routing_ns=physical['IC'],
        logic_ns=physical['Cell'],clock_to_q_ns=physical.get('uTco'),
        max_data_fanout=max(n['fanout'] or 0 for n in data_nodes),data_nodes=data_nodes)


assert read(RUN/'status.txt').strip()=='COMPLETE'
source=json.loads(read(RUN/'source_sha256.json'))
for name,digest in source.items():assert sha(ROOT/name)==digest,('PPA source changed',name)
rows=[]
stages=[]
for seed in [1,2,3]:
    folder=RUN/f'baseline_seed{seed}'
    # The only private syntax adaptation is adding explicit generate delimiters.
    for original in source:
        if not original.startswith('rtl/'):continue
        live=ROOT/original;copied=folder/'src'/live.name
        if live.name=='posit_parser_comb.sv':
            clean=lambda s:re.sub(r'^\s*(?:generate|endgenerate)\s*$','',s,flags=re.M).split()
            assert clean(read(live))==clean(read(copied)),'Parser logic changed in compatibility copy'
        else:assert sha(live)==sha(copied),('Snapshot changed',seed,live.name)
    assert 'Error (' not in read(folder/'compile.log')
    assert 'successful' in read(folder/'stages.log')
    fit=read(folder/'output_files/nf.fit.summary')
    sta=read(folder/'output_files/nf.sta.rpt')
    mapping=read(folder/'output_files/nf.map.rpt')
    assert not re.search(r'inferred.*latch|latch.*inferred',mapping,re.I)
    lut=int(re.search(r'Total combinational functions\s*:\s*([\d,]+)',fit)[1].replace(',',''))
    ff=int(re.search(r'Total registers\s*:\s*([\d,]+)',fit)[1].replace(',',''))
    dsp=int(re.search(r'Embedded Multiplier 9-bit elements\s*:\s*([\d,]+)',fit)[1].replace(',',''))
    memory=int(re.search(r'Total memory bits\s*:\s*([\d,]+)',fit)[1].replace(',',''))
    fmax=float(re.search(r';\s*Slow 1200mV 85C Model Fmax Summary.*?;\s*([\d.]+) MHz',sta,re.S)[1])
    arithmetic=int(re.search(r'-- arithmetic mode\s*;\s*(\d+)',mapping)[1])
    corners=[]
    for corner in ['Slow 1200mV 85C','Slow 1200mV 0C','Fast 1200mV 0C']:
        values={'corner':corner}
        for kind in ['Setup','Hold','Recovery','Removal']:
            match=re.search(r';\s*'+re.escape(corner)+rf' Model {kind} Summary.*?;\s*clk\s*;\s*(-?[\d.]+)\s*;\s*(-?[\d.]+)',sta,re.S)
            assert match,(seed,corner,kind)
            values[kind.lower()+'_wns_ns']=float(match[1]);values[kind.lower()+'_tns_ns']=float(match[2])
        corners.append(values)
    unconstrained=read(folder/'unconstrained.rpt')
    for label in ['Illegal Clocks','Unconstrained Clocks','Unconstrained Input Ports',
                  'Unconstrained Input Port Paths','Unconstrained Output Ports','Unconstrained Output Port Paths']:
        match=re.search(r';\s*'+label+r'\s*;\s*(\d+)\s*;\s*(\d+)',unconstrained)
        assert match and int(match[1])==int(match[2])==0,(seed,label)
    top=path_report(folder/'setup_paths.rpt')
    assert top['top10'][0]['wns_ns']==corners[0]['setup_wns_ns']
    fitter=read(folder/'output_files/nf.fit.rpt')
    hierarchy=[]
    section=fitter.split('; Fitter Resource Utilization by Entity',1)[1]
    number=lambda s:int(re.match(r'([\d,]+)',s)[1].replace(',',''))
    for line in section.splitlines():
        fields=cells(line)
        if len(fields)==16 and fields[14].startswith('|posit_mac_nf'):
            hierarchy.append(dict(hierarchy=fields[14],LUT4=number(fields[11])+number(fields[13]),
                FF=number(fields[2]),logic_cells=number(fields[1])))
    assert hierarchy and hierarchy[0]['LUT4']==lut and hierarchy[0]['FF']==ff
    row=dict(seed=seed,LUT4=lut,FF=ff,DSP_9x9=dsp,memory_bits=memory,
        arithmetic_mode_LE=arithmetic,fmax_MHz=fmax,corners=corners,critical=top,hierarchy=hierarchy,
        max_fanout=int(re.search(r';\s*Maximum fan-out\s*;\s*(\d+)',mapping)[1]))
    rows.append(row)
    for group in ['ops','sac','accumulator','norm_round','add_align','add_arith','add_normalize','pack_p1','control']:
        stages.append(dict(seed=seed,stage=group,**path_report(folder/f'stage_{group}.rpt')))
summary=dict(status='MEASURED_POST_ROUTE',device='EP4CE30F23C6',tool='Quartus13.0sp1/TimeQuest',
    profile='original NF32/3 FW12 N_MAX8 EXACT_EN=OPS_EN=1 FLOOR/RNE',clock_ns=10,
    input_delay_max_min_ns=[0.5,0.1],output_delay_max_min_ns=[0.5,0.1],
    interface_budget='Provisional single-clock budget, not board timing signoff',
    median_fmax_MHz=statistics.median(r['fmax_MHz'] for r in rows),
    meets_100MHz=False,unconstrained_setup_hold=0,inferred_latches=0,
    hold_recovery_removal_all_corners_pass=all(c[k]>=0 for r in rows for c in r['corners'] for k in ['hold_wns_ns','recovery_wns_ns','removal_wns_ns']),
    source_sha256=source,rows=rows,
    limits=['This is full NF post-route on Intel LUT4; no D0/Virtex UltraScale+ or board/power claim',
        'Clock10ns target fails setup; milestone accepts a truthful preliminary measurement, not timing closure',
        'Private parser copy only adds explicit generate delimiters for Quartus13; production source unchanged',
        'ASYNC_REG attributes are ignored by Quartus13; this STA/RTL reset review is not CDC/RDC/MTBF signoff',
        'Intel arithmetic-mode LE count is reported; it is not a Xilinx CARRY8 primitive count',
        'No false-path or multicycle exceptions; no F RTL or paired PPA acceptance'])
dump(RUN/'summary.json',summary)
dump(RUN/'stages.json',stages)
with (RUN/'stages.csv').open('w',newline='',encoding='utf-8') as out:
    writer=csv.writer(out);writer.writerow(['seed','stage','WNS_ns','data_ns','routing_ns','logic_ns','levels','max_data_fanout','start','end'])
    for s in stages:
        p=s['top10'][0]
        writer.writerow([s['seed'],s['stage'],p['wns_ns'],p['data_delay_ns'],s['routing_ns'],s['logic_ns'],s['logic_levels'],s['max_data_fanout'],p['startpoint'],p['endpoint']])
print(json.dumps(dict(median_fmax_MHz=summary['median_fmax_MHz'],meets_100MHz=False,
    rows=[{k:r[k] for k in ['seed','LUT4','FF','arithmetic_mode_LE','fmax_MHz']} for r in rows]),indent=2))
