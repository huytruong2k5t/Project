"""Write the existing optimization/progress documents from audited measurements."""
from pathlib import Path
import json
import statistics

from collect_opt825 import R, main as collect


def load(study):
    return json.loads((R/'results'/study/'summary.json').read_text())


def main():
    collect()
    sac=load('opt05_20261017'); product=load('opt09_20261018')
    sticky=load('opt10a_20261018'); combo=load('optcombo_20261018')
    assert not any(x['pending_ppa'] for x in (sac,product,sticky,combo))
    assert combo['acceptance_status']=='COMPLETE' and 'f_modelsim' in combo
    assert len(combo['ppa'])==3
    reference={x['strategy']:x for x in sac['ppa'] if x['variant']=='baseline'}
    final={x['strategy']:x for x in combo['ppa']}
    assert set(reference)==set(final)=={'Default','Explore','RuntimeOptimized'}
    def stage(run,name):return next(x for x in run['stages'] if x['group']==name)
    lines=['<!-- OPT825_REPORT_START -->','',
      '#### 8.28.1. Kết quả kiểm chứng và phép đo đã hoàn tất','',
      f"SAC: {sac['leaf_cases']:,} input cases trên54 cấu hình W_X1..27, S_W tối thiểu và+2; bốn candidate khớp RTL gốc và oracle serial scan độc lập ({sac['candidate_oracle_comparisons']:,} so sánh candidate/oracle),0 mismatch. ModelSim riêng130.156 ca tại W1/5/12/26/27 cũng đạt. Cả bốn candidate sạch54 strict leaf lint và bốn strict NF lint; tổng320.000 pilot NF/0 mismatch. Bản range-check generate giữ hành vi overflow và bỏ CMPCONST ở W=2^S−1; mã cũ trước sửa giữ riêng, freeze.json là mốc ban đầu, manifest thực chạy khóa bản đã sửa.", '',
      'Lượt ModelSim54-instance song song đã dừng vì runtime cao, không tính PASS. Lượt native đầu vướng GNU Make không nhận khoảng trắng trong CURDIR; bản v2 dùng make CURDIR=. Không che warning RTL candidate: chỉ build testbench/RTL gốc dùng Wno-fatal, strict lint candidate vẫn không warning/error. ModelSim10.1d dùng typedef unsigned cùng width thay parameter-sized cast trong bản LOD private; F thêm adapter tương tự cho assertion iterations_done. Không sửa source production hoặc tắt assertion. Lỗi compile F đầu giữ riêng, không tính nghiệm thu.', '',
      f"OPT-09: round-trip parse(pack(u)) so trên{product['roundtrip_cycles']:,} chu kỳ/{product['roundtrip_completed']:,} completed,4 format×RNE/TRUNC,reset/stall/specials/carry/range,0 mismatch;4 pilot tổng80.000 completed/0 mismatch. OPT-10A:435 strict lint tuples NB4..32,ES0..NB−4 ở F_IN tối thiểu; {sticky['leaf_cases']:,} ca so mọi field P1 với bản gốc,8 tuple gồm ES0,NB không lũy thừa2,FIN tối thiểu/63 và SF sweep/one-hot;4 pilot80.000 completed/0 mismatch. Prefix OR tính từ toàn payload và giữ fill khi offset quá lớn; không chỉ từ fraction.", '',
      'Tổ hợp khảo sát: SAC A+B+C-tree + OPT-09 + OPT-10A trên mốc OPT-02b. NF4 pilot80.000, main32/3 **10.000.000 completed/85.316 reset-aborted,0 mismatch**. Toàn bộ JSON counters/cycle/coverage khớp checkpoint OPT-02b;72 control bins và256 regime/sign cross không mất. F profile32/3 FW12 W32 approximate-only: pilot100.000 và **main10.000.000 completed/0 mismatch**,59.356.752 stage observations; toàn JSON main khớp checkpoint tuần13. Frozen L1 và production giữ nguyên. ES3 dùng oracle integer/dyadic/full-grid riêng; SoftPosit chỉ cho đúng format hỗ trợ.', '',
      'ModelSim NF:82.944 corner+28.512 protocol completed/288 reset-aborted,0 mismatch; F8192 completed/24 abort,0 mismatch,CK2Q1ns. Không đổi reset release,stall,order,C/config context,commit,first/last/drain. NF vẫn14 tầng,L_valid=q+12,H=q+13,II=q+14; F13 tầng,q+11/q+12/q+13. Không dùng regression này thay final per-n/AC04/CDC/RDC/Gate4.', '',
      '#### 8.28.2. Tách tác động từng candidate — Default C2','',
      '| Candidate SAC | LUT | FF | CARRY4 | WNS ns | WHS ns | SAC state/token setup ns |',
      '| --- | ---: | ---: | ---: | ---: | ---: | --- |']
    for name in ('baseline','a','ab','abc_sub','abc_tree'):
        x=next(x for x in sac['ppa'] if x['variant']==name and x['strategy']=='Default')
        res=x['resources']
        lines.append(f"| {name} | {res['Slice LUTs']} | {res['Slice Registers']} | {res['CARRY4']} | {x['wns_ns']:+.3f} | {x['whs_ns']:+.3f} | {float(stage(x,'sac_state')['setup_slack_ns']):+.3f}/{float(stage(x,'sac_token_l1')['setup_slack_ns']):+.3f} |")
    lines += ['', 'C-sub tăng carry/LUT; cây zero/one-hot không thêm carry, cải thiện SAC token rõ hơn nhưng không tự cải thiện WNS toàn MAC khi đường găng chuyển sang P1/A1. Không chọn candidate chỉ dựa tên thuật toán hoặc một bank.', '',
      '| Candidate độc lập trên OPT-02b | LUT/FF/CARRY4 | WNS/WHS ns | Bank chính trước → sau, setup ns |',
      '| --- | --- | --- | --- |']
    for data,label,bank in ((product,'OPT-09','product_parse_bank'),(sticky,'OPT-10A','product_packer_p1')):
        x=data['ppa'][0];res=x['resources'];b=reference['Default']
        lines.append(f"| {label} | {res['Slice LUTs']}/{res['Slice Registers']}/{res['CARRY4']} | {x['wns_ns']:+.3f}/{x['whs_ns']:+.3f} | {float(stage(b,bank)['setup_slack_ns']):+.3f} → {float(stage(x,bank)['setup_slack_ns']):+.3f} |")
    lines += ['', 'OPT-09 thay bank biểu diễn, không thêm bank: P2 tăng từ38 lên39 FF. Magnitude đã round/clamp lưu một lần; không thêm signed code hoặc adder thứ hai. Packer public và parser public giữ nguyên.', '',
      '#### 8.28.3. Matched toàn NF — A35T-C2, ba chiến lược','',
      '**Reference ở đây là candidate OPT-02b, không phải production OPT-03. Chưa promote OPT-02b hoặc tổ hợp vào production.** Cùng part xc7a35tcpg236-1,10ns,input min/max2,500ns,output min0/max0,500ns,uncertainty setup/hold0,100ns; XDC nạp trước synthesis. Không thêm exception hoặc đổi hold budget.', '',
      '| Chiến lược | Reference LUT/FF/CARRY4 | Reference WNS/WHS ns | Tổ hợp LUT/FF/CARRY4 | Tổ hợp WNS/WHS ns | R2R WNS reference → tổ hợp ns | F_STA reference → tổ hợp MHz |',
      '| --- | --- | --- | --- | --- | --- | --- |']
    for strategy in ('Default','Explore','RuntimeOptimized'):
        b=reference[strategy];x=final[strategy];br=b['resources'];xr=x['resources']
        lines.append(f"| {strategy} | {br['Slice LUTs']}/{br['Slice Registers']}/{br['CARRY4']} | {b['wns_ns']:+.3f}/{b['whs_ns']:+.3f} | {xr['Slice LUTs']}/{xr['Slice Registers']}/{xr['CARRY4']} | {x['wns_ns']:+.3f}/{x['whs_ns']:+.3f} | {b['r2r_wns_ns']:+.3f} → {x['r2r_wns_ns']:+.3f} | {b['f_sta_estimate_mhz']:.2f} → {x['f_sta_estimate_mhz']:.2f} |")
    for label,values in (('Reference',list(reference.values())),('Tổ hợp',list(final.values()))):
        fs=[x['f_sta_estimate_mhz'] for x in values]
        lines += ['',f"{label} F_STA min/median/max={min(fs):.2f}/{statistics.median(fs):.2f}/{max(fs):.2f}MHz; WNS min/median/max={min(x['wns_ns'] for x in values):+.3f}/{statistics.median(x['wns_ns'] for x in values):+.3f}/{max(x['wns_ns'] for x in values):+.3f}ns."]
    lines += ['', 'Explore dùng place/route Explore; RuntimeOptimized dùng place RuntimeOptimized và route Default. Đây là ba chiến lược, không gọi là ba seed độc lập. Chỉ đo toàn NF trong đợt này; chưa có matched PPA F hoặc kết luận lợi ích fusion. DSP/BRAM/latch/unrouted/unclassified đều0 ở các run đã audit. TNS/THS và recovery/removal giữ trong timing.rpt; số chi tiết,24 bank D/CE và worst paths ở summary.json/stages.csv, không trộn async reset vào bank data.', '',
      'Default: WNS toàn bộ budget+0,730ns tại parser valid→in_ready; Internal R2R+0,987ns tại A1. Tổ hợp đạt setup/hold100MHz cả ba chiến lược. Đánh đổi Default so reference:+31LUT,+1FF,−8CARRY4; không kết luận giảm LUT toàn MAC từ việc OPT-09 riêng tiết kiệm102LUT. Median F_STA tăng khoảng8,41%,chưa đạt mục tiêu115–125MHz.', '',
      '| Bank Default | Reference setup/hold ns | Tổ hợp setup/hold ns |',
      '| --- | --- | --- |']
    for row in reference['Default']['stages']:
        name=row['group'];after=stage(final['Default'],name)
        lines.append(f"| {name} | {float(row['setup_slack_ns']):+.3f}/{float(row['hold_slack_ns']):+.3f} | {float(after['setup_slack_ns']):+.3f}/{float(after['hold_slack_ns']):+.3f} |")
    lines += ['',
      'F_STA=1000/(10−WNS_R2R),chỉ là ước lượng từ STA tại100MHz; chưa P&R ở clock cao hơn hoặc đo board. OOC không có HD.PARTPIN_LOCS nên timing I/O chỉ theo budget giả định, chưa board/interface signoff. Không suy slack hold thực bằng cách cộng lại uncertainty.', '',
      '#### 8.28.4. Quyết định và phần còn mở','',
      'Giữ tổ hợp như candidate đã kiểm; chưa đổi production.f hoặc SPEC hiện thực production. Việc promote riêng OPT-02b cần matched với production; phép đo ở đây dùng nó làm mốc khảo sát đúng8.25.1. OPT-10B chưa mở vì P1/P2 đã có margin; OPT-11 vẫn là tùy chọn nếu cần mục tiêu cao hơn và phải khóa bundle/FF trước sửa. A1 đang là nút thắt kế tiếp; không lấy CE slack A2 làm ngân sách số học. Mục tiêu115–125MHz chưa được nghiệm thu; không tự tăng tầng/II để đạt con số. Gói kết quả không đóng Gate4 hoặc final ma trận NF/F.', '',
      'Tái chạy từ Posit_MAC,WSL bash --noprofile --norc: prepare_opt05.py → verify_opt05.sh từng a/ab/abc_sub/abc_tree; verify_opt05_leaf_native.sh tự tạo TB54 cấu hình và verify_opt05_leaf_event.ps1 kiểm ModelSim đại diện (không cần chạy lại matrix ModelSim ban đầu). prepare_opt09.py → verify_opt09_product.sh và verify_opt09.sh; prepare_opt10a.py → verify_opt10a_leaf.sh và verify_opt10a.sh; prepare_optcombo.py → verify_optcombo.sh → verify_optcombo_acceptance.sh; ModelSim dùng verify_optcombo_modelsim.ps1 và verify_optcombo_fused_modelsim.ps1. L0 libsoftposit.so tái build từ source trước native NF trên checkout mới.', '',
      'PPA Windows: run_opt05_ppa.ps1 -Variant baseline/abc_tree -Strategy Default/Explore/RuntimeOptimized; thêm -StudyRoot results/opt09_20261018 -Variant magnitude hoặc opt10a_20261018/-Variant sticky cho phép đo riêng; tổ hợp dùng -StudyRoot results/optcombo_20261018 -Variant combined với ba strategy. Mọi runner từ chối output cũ; để tái chạy cần study root mới và sửa có chủ đích, không xóa checkpoint đã nghiệm thu. collect_opt825.py audit nguồn/hash/constraint/counters; retain_opt825.py nén và kiểm CRC/SHA trước dọn build caches. Seed NF20264217,F20261015,SAC20261017,product/sticky20261018; Verilator5.032,GCC15.2.0,ModelSim10.1d,Vivado2026.1 build6511674. Nguồn/lệnh/hash và báo cáo raw nằm trong evidence.zip của từng study.', '', '<!-- OPT825_REPORT_END -->']
    path=R.parent/'doc/Optimization.md'
    text=path.read_text(encoding='utf-8')
    start='<!-- OPT825_REPORT_START -->';end='<!-- OPT825_REPORT_END -->'
    retention=[R/'results'/name/'retention.json' for name in
               ('opt05_20261017','opt09_20261018','opt10a_20261018','optcombo_20261018')]
    if all(p.exists() for p in retention):
        freed=sum(json.loads(p.read_text())['bytes_freed'] for p in retention)
        lines[-1:-1]=['',f'Đã nén lossless và kiểm CRC/SHA từng entry trước dọn build caches,giải phóng{freed:,}byte (~{freed/1048576:.1f}MiB). Giữ source/lệnh/hash/report/fixture và routed DCP local; không đưa binary,wave,work hoặc cache vào Git. Archive manifest mô tả cả lượt lỗi/interrupted riêng,không cộng vào nghiệm thu.','']
    body='\n'.join(lines)+'\n'
    if start in text:text=text[:text.index(start)]+body+text[text.index(end)+len(end):]
    else:text=text.rstrip()+'\n\n'+body
    path.write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')
    progress=R/'docs/TIEN_DO_DO_AN.md'
    text=progress.read_text(encoding='utf-8')
    old='### 4.17. Mẫu cập nhật tiếp theo'
    row='''### 4.17. Ngày18/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Khảo sát SAC,product magnitude và sticky theo8.25 | Leaf/pilot/round-trip và tổ hợp NF10M+F10M/0 mismatch; ModelSim NF/F đạt. Matched A35T-C2 ba chiến lược, bảng kết quả ở Optimization8.28. Giữ candidate,chưa promote production hoặc đóng Gate4 | ✅ |
| 2 | Promote và mục tiêu timing cao hơn | Còn đối chiếu production/OPT-02b trước promote; OPT-10B/11 chỉ mở khi cần. Final per-n/AC04,CDC/RDC và paired PPA NF/F giữ lịch riêng | processing |

### 4.18. Mẫu cập nhật tiếp theo'''
    if old in text:text=text.replace(old,row)
    progress.write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')
    print('Existing optimization/progress reports updated; production unchanged')


if __name__=='__main__':main()
