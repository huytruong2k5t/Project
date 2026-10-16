"""Bounded follow-up: confirm promising points; include actual packer SHIFT_W=5."""
from pathlib import Path
from collections import defaultdict
import csv
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'


def main():
    # Separate driver preserves the already running screening driver's identity.
    source=(ROOT/'scripts/primitive_v2_ppa.tcl').read_text()
    source=source.replace('lassign [split $line \\t] id variant n kind mode arith fill strategy',
        'lassign [split $line \\t] id variant n kind mode arith fill strategy shift_width\n    if {$shift_width eq ""} {set shift_width [expr {int(ceil(log($n)/log(2)))}]}')
    source=source.replace('strategy,lut,ff,slack','strategy,shift_w,lut,ff,slack')
    source=source.replace('set row [list $id $part $variant $n $kind $mode $arith $fill $strategy $lut $ff',
        'set row [list $id $part $variant $n $kind $mode $arith $fill $strategy $shift_width $lut $ff')
    source=source.replace('    foreach module {lod_lzd_core',
        '    set cache [file join [pwd] cache_${variant}_n${n}_k${kind}_m${mode}_a${arith}_f${fill}_w${shift_width}.dcp]\n    if {[file exists $cache]} {\n        open_checkpoint $cache\n    } else {\n    foreach module {lod_lzd_core')
    source=source.replace('FILL_KIND=$fill] -flatten_hierarchy','FILL_KIND=$fill SHIFT_W=$shift_width] -flatten_hierarchy')
    source=source.replace('    opt_design\n','    opt_design\n    write_checkpoint -force $cache\n    }\n')
    dest=ROOT/'scripts/primitive_v2_followup.tcl'
    if dest.exists() and dest.read_text()!=source:raise RuntimeError('Frozen follow-up driver changed')
    dest.write_text(source,newline='\n')
    net_source=source.replace('    report_utilization -file',
        '    write_verilog -force -mode funcsim [file join $case_dir functional_netlist.v]\n    report_utilization -file')
    net_dest=ROOT/'scripts/primitive_v2_confirm.tcl'
    if net_dest.exists() and net_dest.read_text()!=net_source:raise RuntimeError('Confirm driver already differs')
    net_dest.write_text(net_source,newline='\n')
    text=''
    for n in (59,60):
        for v in ('baseline','reverse','radix4','native'):
            ident=f'{v}_n{n}_k1_m0_a0_f1_w5_default'
            text+='\t'.join(map(str,(ident,v,n,1,0,0,1,'default',5)))+'\n'
    (OUT/'packer_cases.tsv').write_text(text,newline='\n')
    rows=[]
    for phase in ('lod','lod_mixed','shift','chain','chain_extra','packer'):
        path=OUT/f'xc7a35tcpg236-1/{phase}/metrics.csv'
        if path.exists():
            data=list(csv.DictReader(path.open()))
            expected=len((OUT/f'{phase}_cases.tsv').read_text().splitlines())
            if len(data)!=expected:
                print(f'{phase}: still processing; confirmation selection not frozen');return
            rows+=data
        else:
            print(f'{phase}: not yet measured; follow-up driver/packer cases ready');return
    groups=defaultdict(list)
    for r in rows:
        sw=int(r.get('shift_w') or (int(r['n'])-1).bit_length())
        groups[tuple(int(r[x]) for x in ('n','kind','mode','arith','fill'))+(sw,)].append(r)
    chosen=[]
    for key,data in groups.items():
        baseline=next(r for r in data if r['variant']=='baseline')
        base_delay=5-float(baseline['slack']);base_lut=int(baseline['lut'])
        promising=[]
        for r in data:
            if r['variant']=='baseline' or float(r['hold'])<0:continue
            speed=base_delay/(5-float(r['slack']))-1
            area=int(r['lut'])/base_lut-1
            # Broad screening only. Production still requires the stricter
            # predeclared review, matched strategies, both parts and chain checks.
            if (speed>=0.03-1e-12 and area<=0.10+1e-12) or (area<=-0.05+1e-12 and speed>=-0.02-1e-12):promising.append(r)
        if not promising:continue
        for r in [baseline]+promising:
            n,k,m,a,f,sw=key
            for strategy in ('default','explore','runtime'):
                ident=f'{r["variant"]}_n{n}_k{k}_m{m}_a{a}_f{f}_w{sw}_{strategy}'
                chosen.append('\t'.join(map(str,(ident,r['variant'],n,k,m,a,f,strategy,sw)))+'\n')
    path=OUT/'confirm_cases.tsv';text=''.join(chosen)
    if path.exists() and path.read_text()!=text:raise RuntimeError('Confirmation selection already frozen')
    path.write_text(text,newline='\n')
    (OUT/'confirmation_policy.json').write_text(json.dumps(dict(
        screening='>=3% speed with <=10% LUT growth, or >=5% LUT saving with <=2% speed regression; nonnegative hold.',
        production='Separate >=5% timing review and chain/cross-part evidence; no automatic promotion.',
        cases=len(chosen)),indent=2)+'\n')
    print('Prepared',len(chosen),'confirmation runs per part')


if __name__=='__main__':main()
