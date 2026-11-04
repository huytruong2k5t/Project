"""Validate and summarize the source-bound quire backend optimization study."""
import csv
import hashlib
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/quire_opt_20261104'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    records=[]
    for label in ['before','after']:
        run=OUT/('synth_'+label)
        manifest=json.loads((run/'manifest.json').read_text())
        assert manifest['status']=='SYNTHESIS_COMPLETE'
        for rel,h in manifest['source_sha256'].items():assert sha(run/'source'/rel)==h,rel
        for rel,h in manifest['recipe_sha256'].items():assert sha(run/'source'/rel)==h,rel
        stages=list(csv.DictReader((run/'f2f_stages.csv').open()))
        delay=next(r for r in stages if r['group']=='whole' and r['target_kind']=='D_CE')
        setup=next(r for r in stages if r['group']=='whole_worst_setup')
        timing=next(csv.DictReader((run/'timing_metrics.csv').open()))
        util=(run/'synthesis_utilization.rpt').read_text()
        def used(name):return int(re.search(r'\|\s*'+re.escape(name)+r'\s*\|\s*(\d+)',util)[1])
        record={'snapshot':label,'luts':used('Slice LUTs*'),'ffs':used('Slice Registers'),
            'f2f_ns':float(delay['data_delay_ns']),
            'raw_f2f_mhz':1000/float(delay['data_delay_ns']),
            'internal_setup_estimate_mhz':1000/(10-float(setup['slack_ns'])),
            'whole_interface_estimate_mhz':1000/(10-float(timing['wns_ns'])),
            'wns_ns':float(timing['wns_ns']),'whs_ns':float(timing['whs_ns']),
            'critical_start':delay['startpoint'],'critical_end':delay['endpoint'],
            'logic_ns':float(delay['logic_delay_ns']),'estimated_net_ns':float(delay['net_delay_ns']),
            'logic_levels':int(delay['levels'])}
        records.append(record)
    verification={}
    for label in ['units_stress','pilot_opt','default_1m']:
        report=json.loads((OUT/(label+'.json')).read_text())
        assert report['status']=='PASS' and report['mismatches']==0
        build=json.loads((OUT/report['build_manifest']).read_text())
        for rel,h in build['source_sha256'].items():
            assert sha(OUT/'verified_source'/rel)==h,rel
            assert sha(ROOT/rel)==h,rel
        verification[label]=report
    assert verification['default_1m']['main_mac_retired']==1000000
    assert verification['pilot_opt']['main_mac_retired']==100000
    assert all(verification['pilot_opt']['config_bins'])
    assert verification['units_stress']['bank_checks']==11061
    modelsim=json.loads((OUT/'modelsim_opt/manifest.json').read_text())
    assert modelsim['status']=='PASS'
    for rel,h in modelsim['source_sha256'].items():assert sha(OUT/'modelsim_opt/source'/rel)==h,rel
    # The shared NF/F datapath and independent oracles must stay untouched.
    baseline=json.loads((OUT/'before/manifest.json').read_text())['source_sha256']
    changed=[rel for rel,h in baseline.items() if rel.startswith('rtl/') and rel.endswith('.sv') and sha(ROOT/rel)!=h]
    assert set(changed)=={'rtl/mac_quire/mac_quire_wrapper.sv','rtl/mac_quire/quire_align_comb.sv',
        'rtl/mac_quire/quire_bank.sv','rtl/mac_quire/quire_read.sv'}
    before,after=records
    reduction={key:100*(before[key]-after[key])/before[key] for key in ['luts','ffs','f2f_ns']}
    result={'status':'OPTIMIZED_REGRESSION_VERIFIED_SYNTHESIS_ONLY','date':'2026-11-04',
        'profile':'POSIT32_ES3_Q12_FULL_TERM26_Q24_W972_GRID_NEG480_LMAX1024',
        'MAC_Q12_VERIFIED':False,'records':records,'reduction_percent':reduction,
        'changed_rtl':changed,'shared_nf_f_rtl_unchanged':True,'oracles_unchanged':True,
        'verification':verification,'modelsim':modelsim['marker'],
        'synthesis_runs':2,'implementation_run':False,'main_10M_new_snapshot_run':False,
        'limits':'Matched OOC synthesis with clock XDC before synth; unplaced net estimates. Hold remains open. 03/11 routed result is historical and not matched to these synthesis estimates. Baseline backend frozen at task start; optimized snapshot reverified.'}
    (OUT/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    with (OUT/'comparison.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(records[0]));w.writeheader();w.writerows(records)
    lines=['# Tối ưu MAC-quire — 04/11/2026','','Đã triển khai theo Optimization §8.42: giữ nguyên Posit32/ES3, approximate12 FULL_TERM26/Q24, Q signed972/grid2^-480, L_max1024, CLEAR/MAC/READ và RNE chỉ khi READ. Chỉ bốn module quire riêng thay đổi; RTL NF/F và oracle độc lập giữ nguyên.','','## Kết quả synthesis đối chứng','','Vivado2026.1, xc7a35tcpg236-1, OOC clock10ns, uncertainty0.1ns, input max/min2.5ns, output max0.5ns/min0ns; constraints được đọc trước synthesis. Cả hai snapshot dùng cùng recipe, DSP0/BRAM0. Không place/route/bitstream.','','| Chỉ tiêu | Backend trước sửa | Backend tối ưu |','|---|---:|---:|']
    for text,key,fmt in [('LUT','luts','d'),('FF','ffs','d'),('F2F D/CE (ns)','f2f_ns','.3f'),('1000/F2F (MHz)','raw_f2f_mhz','.1f'),('Fmax nội bộ tính setup/skew/uncertainty (MHz)','internal_setup_estimate_mhz','.1f'),('Fmax toàn giao diện ước lượng (MHz)','whole_interface_estimate_mhz','.1f'),('Setup WNS tại10ns','wns_ns','+.3f'),('Hold WHS','whs_ns','+.3f')]:
        lines.append(f'| {text} | {before[key]:{fmt}} | {after[key]:{fmt}} |')
    lines += ['',f"Giảm LUT{reduction['luts']:.1f}%, FF{reduction['ffs']:.1f}%, F2F{reduction['f2f_ns']:.1f}%. Nghịch đảo datapath chỉ là trần sơ bộ; ước lượng nội bộ dùng1000/(10−worst_F2F_slack), toàn giao diện dùng1000/(10−WNS). Net delay là ước lượng unplaced; hold âm nên chưa timing signoff hoặc Fmax board.",'',
        f"Critical path mới: `{after['critical_start']}` → `{after['critical_end']}`; {after['logic_ns']:.3f}ns logic +{after['estimated_net_ns']:.3f}ns net ước lượng, {after['logic_levels']} mức logic. Đường găng đã chuyển sang tạo descriptor/địa chỉ word; không còn barrel shifter972 bit hoặc NOR term972 bit trên đường bank accept.",'','## Thiết kế đã thay đổi','',
        '- Thêm bank prepack43 bit, chốt magnitude26/scale11/sign/zero/NaR/error/loss/cut trước khâu align; thêm một chu kỳ trên MAC.',
        '- `quire_align_comb` tạo coefficient27 bit +word_index5 +bit_offset6, vẫn kiểm suffix khi scale âm và báo invalid khi ngoài bound; giữ nguyên số học và dấu.',
        '- `quire_bank` dựng từng term word bằng shifter cục bộ63 bit; thay term_work972 bit bằng descriptor38 bit. Q và pending tổ chức27 word36, không dịch cả vector mỗi clock. Còn một shadow transaction để bảo toàn Q trên overflow và không lộ partial Q. Entry pending cuối không cần lưu vì word cuối commit trực tiếp.',
        '- READ dùng bank Q ổn định nhờ một lệnh outstanding, không sao chép972 bit. Mỗi word qua FETCH lấy trị tuyệt đối36 bit rồi REDUCE tìm bit đầu, ghép cửa sổ và OR tail; chỉ giữ hai word trước, một abs word và sticky. Phép RNE vẫn chỉ ở Packer cuối.',
        '- Recipe synthesis mới và recipe route cũ đều đọc XDC clock/I/O trước synth. Lượt này chỉ chạy recipe synthesis mới.',
        '', 'Kế hoạch cũ ước lượng READ có ba bản972 bit; snapshot thực tế ở đầu lượt này chỉ có một `work_q` trong READ. Báo cáo dùng số tài nguyên đo thực tế, không lấy ước lượng tiết kiệm trong kế hoạch làm kết quả.', '',
        'Đánh đổi latency: MAC thêm tầng prepack; READ quét27 word×2 pha kể cả Q=0/NaR. Nhờ ownership của top, Q không thay đổi trong READ; leaf READ yêu cầu bank đầu vào ổn định cho tới khi hoàn tất. Tính atomic và reset epoch được giữ. Đây là lựa chọn tiết kiệm tài nguyên; chưa tối ưu latency READ zero/NaR.', '', '## Verification mới trên đúng nguồn', '',
        '- Strict lint19 module,26 instance +1 BUFG đủ cổng.',
        '- Unit:32768 align trên toàn signed sf bus/cả dấu;21948 READ so sf/fraction53/sticky/RNE;11061 bank gồm10000 phép cộng compact ngẫu nhiên độc lập, biên word, carry/borrow, overflow bảo toàn Q, count/capacity và không lộ partial Q.',
        '- ModelSim bigint fixtures:4881 accepted,4876 completed +5 reset-aborted,0 mismatch;4833 commit,19512 chu kỳ stall,72 kiểm invalid.']
    for label in ['pilot_opt','default_1m']:
        r=verification[label]
        lines.append(f"- {label}: {r['main_mac_retired']} MAC retired,0 mismatch; {r['long_sequences']} chuỗi>12, {r['capacity_sequences']} chuỗi1024; seed{r['seed']}, {r['reset_aborted']} reset-aborted, latency retire quan sát{r['latency_retire'][0]}..{r['latency_retire'][1]} chu kỳ. Q972 bit được so từng commit với hai model độc lập; toàn26 OPS×n được kiểm trong pilot.")
    lines += ['', 'Đây là regression1.1M MAC mới, chưa thay main10M/coverage của snapshot03/11 và chưa gắn MAC_Q12_VERIFIED. Số route cũ10339LUT/4453FF,WNS−12.016ns thuộc snapshot/flow khác; không dùng để suy mức cải thiện timing sau route của bản này.', '',
        '[CSV đối chứng](comparison.csv) · [Summary và source guards](summary.json) · [Nguồn trước](before/source/rtl/mac_quire/quire_bank.sv) · [Nguồn đã verify](verified_source/rtl/mac_quire/quire_bank.sv) · [F2F sau tối ưu](synth_after/f2f_stages.csv) · [Worst paths](synth_after/whole_D_CE.rpt) · [ModelSim](modelsim_opt/manifest.json).', '',
        'Giữ source, vector, recipe, manifest, log, DCP và reports trong synth_before/synth_after. Các cache/work/binary có thể build lại theo runner với QUIRE_RESULTS_ROOT mới. Không sửa hoặc kế thừa checkpoint03/11 như nghiệm thu của nguồn mới.', '']
    (OUT/'summary.md').write_text('\n'.join(lines),encoding='utf-8')
    print('QUIRE_OPT_SUMMARY_PASS',reduction)


if __name__=='__main__':main()
