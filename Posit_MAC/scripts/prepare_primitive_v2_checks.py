from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'
names=('lod_lzd_core','dyn_left_shifter','dyn_right_shifter')
for name in names:
    text=(OUT/f'source/baseline/{name}.sv').read_text()
    p=OUT/f'reference/{name}_reference.sv';p.parent.mkdir(exist_ok=True)
    p.write_text(text.replace('module '+name+' #(','module '+name+'_reference #('),newline='\n')
checks=OUT/'checks';checks.mkdir(exist_ok=True)
for name in ('primitive_lod_check','primitive_shift_check'):
    text=(ROOT/f'tb/{name}.sv').read_text().replace('20261015','20261016')
    # Initial 500-pattern run is retained separately. Final source closure keeps
    # exhaustive small widths/all shift encodings and 100 large-width patterns.
    if name=='primitive_shift_check':text=text.replace(': 500;',': 100;')
    (checks/f'{name}.sv').write_text(text,newline='\n')
instances=[]
for n in (1,2,3,5,8,12,26,27,29,30,31,32,33,59,60,64):
    s=max(1,(n-1).bit_length())
    for w in sorted({max(1,s-1),s,s+1}):
        i=len(instances)
        instances.append(f'primitive_shift_check #(.N({n}), .W({w})) u_{i} (.done(done[{i}]));')
for n in (*range(2,13),26,27,29,30,31,32,33,53,54,59,60,64):
    for s in ((n-1).bit_length(),(n-1).bit_length()+1):
        for mode in (0,1):
            i=len(instances)
            instances.append(f'primitive_lod_check #(.N({n}), .S({s}), .MODE({mode})) u_{i} (.done(done[{i}]));')
text='`timescale 1ns/1ps\nmodule tb_primitive_v2;\nwire ['+str(len(instances)-1)+':0] done;\n'
text+='\n'.join(instances)+'''\ninitial begin
    wait (&done);
    $display("PRIMITIVE_V2_ALL_PASS seed=20261016");
    $finish;
end
initial begin
    #2000000;
    $fatal(1,"PRIMITIVE_V2_TIMEOUT");
end
endmodule
'''
(checks/'tb_primitive_v2.sv').write_text(text,newline='\n')
print('Prepared',len(instances),'independent-oracle configurations per variant')
