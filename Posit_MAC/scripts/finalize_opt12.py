"""Publish the trial and recommend a candidate; do not promote or lock RTL."""
from pathlib import Path
import json
import shutil
from audit_opt12 import R,O,collect,read,sha


def main():
    result=collect()
    assert len(result['ppa'])==11,'Wait for every planned PPA run, including failures'
    assert len(result['units'])==3
    for variant in ('sentinel','negate'):
        assert set(result['stress'][variant])=={'nf','f'} and variant in result['events']
    main_runs=[x for x in result['ppa'] if x['variant']=='negate' and x['clock_ns']==8.3]
    assert {(x['top'],x['strategy']) for x in main_runs}=={
        (top,strategy) for top in ('nf','f') for strategy in ('Default','Explore','RuntimeOptimized')}
    paired_flows=[strategy for strategy in ('Default','Explore','RuntimeOptimized')
                  if all(any(x['top']==top and x['strategy']==strategy and x['full_timing_pass']
                             for x in main_runs) for top in ('nf','f'))]
    assert paired_flows,'Do not recommend a flow before both tops meet the declared clock'
    for leaf in ('posit_parser.sv','posit_parser_comb.sv'):
        tested=O/'source/negate/rtl/parser'/leaf
        canonical=R/'rtl/candidates/parser/opt12'/leaf
        canonical.parent.mkdir(parents=True,exist_ok=True)
        if canonical.exists():assert sha(canonical)==sha(tested)
        else:shutil.copyfile(tested,canonical)
        # This is a review alias, not an edit of production or a release manifest.
        shutil.copyfile(tested,O/'source/candidate/rtl/parser'/leaf)
    result['status']='TRIAL_COMPLETE_PENDING_USER_SELECTION'
    result['recommendation']={
        'variant':'negate','meaning':'adjacent XOR + sentinel + conditional negate',
        'candidate_path':'rtl/candidates/parser/opt12','target_clock_ns':8.3,
        'target_mhz':1000/8.3,'both_tops_passing_strategies':paired_flows,
        'source_sha256':{f'rtl/parser/{leaf}':sha(O/'source/negate/rtl/parser'/leaf)
                         for leaf in ('posit_parser.sv','posit_parser_comb.sv')},
        'limits':'OOC fixed-budget STA only; not board signoff, W14 or maximum Fmax proof; no promotion/lock'}
    (O/'summary.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    qualification={k:result[k] for k in ('status','recommendation','reference_release','production_unchanged','limits')}
    qualification['summary_sha256']=sha(O/'summary.json')
    (O/'qualification.json').write_text(json.dumps(qualification,indent=2)+'\n',encoding='utf-8')
    review=json.loads(read(O/'review.json'))
    review.update(status=result['status'],candidate_state='Recommended negate is tested; candidate review alias updated; production untouched',
        recommended_variant='negate',source_sha256_scope='Original reference source, not the tested candidate',
        w14_execution='ON_HOLD_PENDING_USER_SELECTION_PROMOTION_AND_NEW_FREEZE',
        qualification='qualification.json')
    (O/'review.json').write_text(json.dumps(review,indent=2)+'\n',encoding='utf-8')
    table=[]
    for x in result['ppa']:
        table.append(f"| {x['top'].upper()} | {x['variant']} | {x['strategy']} | {x['clock_ns']:.3f} | "
                     f"{x['frequency_mhz']:.2f} | {x['wns_ns']:+.3f} | {x['whs_ns']:+.3f} | "
                     f"{x['r2r_setup_ns']:+.3f} | {x['resources']['Slice LUTs']} | {x['resources']['Slice Registers']} | "
                     f"{'PASS' if x['full_timing_pass'] else 'FAIL'} |")
    source='''
#### 8.31.7. Thử OPT-12 và STA trực tiếp120,48/125MHz — 18/10/2026

**Đã hoàn tất thử nghiệm, chưa promote hoặc khóa RTL mới.** Candidate đề nghị là `negate`:
adjacent-XOR + sentinel + conditional-negate, tại `rtl/candidates/parser/opt12/`.
Hai file giữ nguyên byte từ source đã kiểm; production38 module, model/oracle, XDC100MHz và lock reference không đổi.
`source/candidate` trong study là alias review của negate; reference và các biến thể riêng vẫn được giữ để đối chiếu.
Chỉ thay hai parser comb/pipeline; không sửa common LOD, precision, OPS, SAC, packer hoặc lịch NF14/F13 tầng.
Không triển khai OPT-13/14. Macro clock/reset/valid/ready, C_eff và thuật toán giữ nguyên.

**Kiểm chức năng:** ba biến thể adjacent/sentinel/negate, mỗi biến thể870 strict lint cấu hình
(435 NB/ES × comb/pipeline),0 warning/error;13 profile cycle-equivalence với parser reference và decoder
trường độc lập,84.272 checks; vét cạn6 format nhỏ gồm8/0 và16/1,66.480 checks/biến thể.
Các profile biên gồm NB4/5/7/9/17/31/32,ES28 và SF_W9/40; có reset,bubble và stall.
Đây là bằng chứng kiểm thử, không phải formal exhaustive toàn posit32 hoặc tương đương X/Z.

Sentinel và negate **mỗi biến thể** đều đạt:

- NF pilot8/0,16/1,32/2,32/3:80.000 completed,0 mismatch; F32/3 pilot100.000,0 mismatch.
- NF32/3 main10.000.000 completed/85.316 reset-aborted,0 mismatch.
- F32/3 main10.000.000 completed/20.151 reset-aborted,0 mismatch,59.356.752 stage checks.
- Toàn bộ JSON numerical/protocol/coverage counters của các lượt10M bằng checkpoint reference tương ứng;
  không chỉ so một tổng số mismatch. Hai main này là lượt mới, không kế thừa hash source cũ để gọi PASS.
- ModelSim10.1d ở chu kỳ8ns/CK2Q1ns: NF bốn format111.456 completed/288 abort;
  F8.192 completed/24 abort;0 mismatch, kiểm reset/stall/latency/state. Đây là RTL event simulation, không phải SDF.

Verilator5.032,GCC15.2.0,SoftPosit0.4.1 đúng format cho NF8/0,16/1,32/2; ES3 dùng oracle độc lập.
NF seed20264217,F20261015; parser parameter generator giữ seed20261016+100*NB+ES+SF_W.
Lệnh/source/binary/compiler/simulator hashes và counters giữ tại study `results/opt120_20261018`.
Main vẫn trộn n/config; **không thay W14 per-n/AC04 hoặc nghiệm thu exact toàn SPEC**.

**STA/PPA:** Vivado2026.1 build6511674,A35T xc7a35tcpg236-1; clock8ns hoặc8,3ns đọc trước synthesis.
Giữ input min=max2,5ns,output min0/max0,5ns,user setup/hold uncertainty0,1ns; không thêm timing exception.
Profile clock cao riêng, không ghi đè C2/10ns và không scale I/O. Mỗi hàng là post-route thực tế,
không phải F_STA suy từ10ns. NF EXACT_EN1; F EXACT_EN0/W32; chưa phải paired NF/F PPA công bằng của tuần15.

| Top | Biến thể | Strategy | Clock ns | MHz | WNS toàn thiết kế ns | WHS ns | R2R setup ns | LUT | FF | Setup/hold toàn thiết kế |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
'''+ '\n'.join(table)+'''

TNS/THS bằng0 đối với các hàng PASS; hàng FAIL được giữ, không làm tròn slack âm thành0 hoặc bỏ khỏi bảng.
Default125MHz của reference/sentinel/negate đều chưa đạt toàn giao tiếp dù R2R đạt;
đường chặn là in_ready. Ở120,48MHz, F Default thiếu0,009ns; dùng strategy đã PASS cho cả NF/F được liệt kê
trong qualification.json, không tuyên bố mọi strategy đều đạt. Chưa quét Fmax cực đại hoặc xác nhận trên board.

NF reference Default tại8,3ns cũng đạt (WNS+0,083ns,WHS+0,016ns,2577LUT/931FF).
Negate Default cùng điều kiện đạt+0,166/+0,057ns,2423LUT/931FF: **giảm154LUT (~5,98%), FF không đổi**.
Đây là lợi ích đo được so reference cùng clock/flow; không quy toàn bộ việc đạt120MHz cho OPT-12.
Không so LUT của profile8ns với8,3ns để kết luận phần trăm tối ưu.

Giữ warning OOC về PARTPIN/CFGBVS và giới hạn báo cáo: budget I/O là giả định benchmark, chưa có pinout/load
hoặc timing giao tiếp board thực. Defined-clock CDC report không thay RDC/board signoff.
Lượt đầu `ppa/reference/p8000/Default` dừng trước synthesis do runner thay nhầm tên file I/O XDC khi đổi profile;
đã sửa runner, giữ failed log riêng và chạy vào *_r1. Lượt lỗi không được tính vào11 phép đo trong bảng.

**Lệnh chính từ Posit_MAC:**

```bash
bash --noprofile --norc scripts/verify_opt12.sh sentinel
bash --noprofile --norc scripts/verify_opt12.sh adjacent
bash --noprofile --norc scripts/verify_opt12.sh negate
bash --noprofile --norc scripts/verify_opt12_nf.sh negate
bash --noprofile --norc scripts/verify_opt12_fused.sh negate
bash --noprofile --norc scripts/stress_opt12.sh negate nf 10000000
bash --noprofile --norc scripts/stress_opt12.sh negate f 10000000
```

```powershell
./scripts/verify_opt12_modelsim.ps1 -Variant negate -AllFormats -RunRoot results/opt120_20261018/event_negate
./scripts/run_opt12_ppa.ps1 -Variant negate -Top nf -Period 8.300 -Strategy Explore
./scripts/run_opt12_ppa.ps1 -Variant negate -Top f -Period 8.300 -Strategy Explore
python scripts/audit_opt12.py
python scripts/audit_rtl_release.py --self-test
```

Các producer từ chối output root đã có; khi replay cần giữ nguyên bằng chứng, chọn attempt/root mới hoặc
restore snapshot vào bản sao workspace trong phạm vi dự án. Không chạy prepare/finalize để ghi đè checkpoint.
Evidence/nguồn/rpt/CSV/raw counters đóng gói gọn, kiểm CRC/SHA; binary/work/cache/wave không đưa vào Git.
**Chờ sinh viên chọn candidate trước promote/khóa cuối; W14 vẫn chưa chạy.**
'''
    path=R.parent/'doc/Optimization.md';text=read(path)
    assert '#### 8.31.7.' not in text
    text=text.rstrip()+'\n\n'+source.lstrip()
    text=text.replace('| Hướng tối ưu sâu 120+ MHz | Đã mở study candidate riêng; review OPT-12 trước, OPT-13/14 có điều kiện; chưa sửa RTL, chưa khóa release mới. W14 chưa chạy trong khi chọn candidate | Mục8.31.6 |',
        '| Hướng tối ưu sâu 120+ MHz | OPT-12 negate đã qua10M NF+10M F/0 mismatch,STA120,48MHz theo flow có PASS; chờ chọn/promote/khóa mới. OPT-13/14 chưa triển khai | Mục8.31.7 |')
    path.write_text(text,encoding='utf-8',newline='\n')
    path=R/'docs/TIEN_DO_DO_AN.md';text=read(path)
    text=text.replace('| OPT-12 parser | Thử adjacent-XOR/sentinel trước,conditional-negate A/B riêng; leaf/lint/pilot NF/F rồi PPA | không |',
        '| OPT-12 parser | Candidate negate đã qua lint/decoder/cycle-equivalence,pilot và10M NF+10M F/0 mismatch; ModelSim125MHz đạt | ✅ |')
    text=text.replace('| Timing trên120MHz | Đo clock cao trực tiếp,cùng budget; phân biệt R2R với I/O/ready. Không suy đạt chỉ từ slack100MHz | không |',
        '| Timing trên120MHz | Đã post-route8,3ns≈120,48MHz,NF/F có flow PASS; giữ cả hàng FAIL,đặc biệt F Default−0,009ns. Chi tiết8.31.7 | ✅ |')
    text=text.replace('| OPT-13/14 và khóa lại | Chỉ thử phần còn chặn theo STA; giữ contract/zero-extension. Chọn/kiểm candidate rồi mới lock release mới | không |',
        '| Chọn/promote/khóa lại | Chờ sinh viên chọn OPT-12 và flow; chưa promote/lock mới hoặc chạy W14. OPT-13/14 để riêng,chưa triển khai | processing |')
    needle='| 6 | Mở lại candidate trên120MHz |';a=text.index(needle);b=text.index('\n',a)
    text=text[:b]+'\n| 7 | Thử OPT-12 trên120MHz | Negate đạt10M NF+10M F/0 mismatch và ModelSim; post-route120,48MHz có flow NF/F PASS. Giảm154LUT NF Default so reference cùng clock; chờ chọn/promote/khóa,không chạy W14 | ✅ |'+text[b:]
    path.write_text(text,encoding='utf-8',newline='\n')
    print('Trial qualified for review; candidate aliases published; production and original lock unchanged')


if __name__=='__main__':main()
