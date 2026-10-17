"""Update existing project documents from the audited one-run experiment."""
from pathlib import Path
import json

R=Path(__file__).resolve().parents[1]
O=R/'results/opt02b_20261017'
D=json.loads((O/'summary.json').read_text())
assert D['status']=='PASS_EXPERIMENT_SCOPE'
P=D['ppa'];S={x['group']:x for x in P['stages']}
B=json.loads((O/'baseline_reference/single_run_summary.json').read_text())
BS={x['group']:x for x in B['stages']}
body=f'''
### 8.23. OPT-02b — A1 tổ hợp với SF-only shifter và prefix OR, 17/10/2026

Theo đề xuất sinh viên, thử candidate riêng `rtl/candidates/adder/opt02b/posit_add_align.sv` với cùng tên module/I/O/parameter như production. Hai hiệu signed mở rộng SF_W+1 và clamp tính song song. Chọn seed trước shifter chỉ theo dấu hiệu scale; cùng sf bypass shifter, chọn small fraction bằng comparator ở MUX cuối. Tạo prefix lo_or bằng reduction trên lát bit cố định, không chuỗi OR nối tiếp; lookup jam[s]=lo_or[s+1] là wiring cố định, không thêm adder cho chỉ số. Chỉ dịch upper bits; bit0 lấy từ jam lookup. Không mask động, không phép trừ tạo mask. Giữ nhánh delta>F+2 trả y=1/tail=1, tie chọn A và ưu tiên NaR/Zero/flags. Không thêm thanh ghi, C prefix register, max_fanout hoặc đổi latency/II. Candidate không thuộc production.f; không compile đồng thời với module production cùng tên.

**Chức năng:** ModelSim10.1d leaf baseline/candidate/integer oracle đạt **{D['leaf_checks']:,}/0 mismatch**,11 profile gồm4 format và F2..27, SF_W đến35/override. Directed mọi vị trí one-hot và shift0..F+3, hai chiều sf, cả dấu, equal fraction, dirty special, signed extrema; F<=5 có exhaustive fraction/delta như checker. Seed20261017+100*NB+ES+10000*SF_W. Không gọi là formal hoặc exhaustive mọi cặp fraction32-bit/XZ.

Verilator5.032/GCC15.2.0: **406 strict leaf lint**,4 strict whole-NF lint sạch; native4 pilot20k và main32/3 **10.000.000 completed/85.316 reset-aborted,0 mismatch**,seed20264217. Toàn bộ JSON counters/cycle/bin khớp checkpoint OPT-03, xác nhận cùng stream vì latency và điều khiển không đổi. ES3 dùng oracle integer/dyadic độc lập; exact ES0/1/2 còn so SoftPosit đúng format. ModelSim NF82.944 corner+28.512 protocol completed/288 abort,0 mismatch,giữ CK2Q/reset/stall/context/commit. Native no-timing chỉ bỏ CK2Q; strict lint vẫn timing. Bản khởi đầu có cảnh báo cast hằng F+2 khi SF_W>32; đã đổi thành delta_t'(F)+delta_t'(2) và chạy lại toàn bộ nghiệm thu trên bản cuối. Log pre_cast_fix giữ riêng, không cộng vào tổng.

**PPA:** một candidate P&R A35T xc7a35tcpg236-1 Default, Vivado2026.1 build6511674, toàn NF32/3 FW12 EXACT_EN=OPS_EN1. Cùng source baseline37file,BUFG wrapper,source order và chuỗi lệnh synth/constraints/opt/place/route trước report với lượt single_a35_packer_20261017. Clock10ns/uncertainty0,1ns,inputmin=max2,5ns,outputmax0,5/min0; không exception mới. Chỉ thay file A1 trong snapshot private; production giữ nguyên.

| Chỉ tiêu | Baseline Default | OPT-02b Default |
| --- | --- | --- |
| A1 setup slack ns | −2,887 | {S['add_align']['setup_slack_ns']:+.3f} |
| A1 data delay / logic levels | 12,749ns /19 | {S['add_align']['data_delay_ns']:.3f}ns /{S['add_align']['levels']} |
| Toàn MAC R2R setup slack ns | −2,887 | {S['whole_mac']['setup_slack_ns']:+.3f} |
| Toàn MAC R2R hold slack ns | +0,056 | {S['whole_mac']['hold_slack_ns']:+.3f} |
| STA MHz ước lượng | {P['baseline_sta_estimate_mhz']:.2f} | {P['sta_estimate_mhz']:.2f} ({P['frequency_change_percent']:+.2f}%) |
| LUT / FF / CARRY4 | 2462 /930 /99 | {P['resources']['LUT']} /{P['resources']['FF']} /{P['resources']['CARRY4']} |
| DSP / BRAM | 0 /0 | {P['resources']['DSP']} /{P['resources']['BRAM']} |

P1 setup{S['product_p1']['setup_slack_ns']:+.3f}ns,P2{S['after_product_p1_p2']['setup_slack_ns']:+.3f}ns,parse/product{S['product_parse']['setup_slack_ns']:+.3f}ns,accumulator{S['before_product_p1_acc']['setup_slack_ns']:+.3f}ns. Slack của các đoạn không đổi RTL vẫn thay đổi do placement/routing; không quy toàn bộ chênh lệch này cho thay thuật toán của chúng. A1 còn12 logic levels, không xác nhận ước lượng8–9. Critical mới: `{S['whole_mac']['startpoint']}` → `{S['whole_mac']['endpoint']}`, phía SAC/controller; routing chiếm{100*S['whole_mac']['route_delay_ns']/S['whole_mac']['data_delay_ns']:.2f}% delay đường này.

**Kết luận phạm vi:** candidate đạt setup/hold100MHz trong một OOC run; LUT tăng54 (+2,19%),FF không đổi,CARRY4 giảm5. Giữ candidate để review, **chưa promote production** vì chưa có>=3 matched run/cross-part xác nhận theo kế hoạch. Không gọi là board signoff, Gate4 hoặc paired NF/F PPA; no new final AC04/per-n. Không ghép C precompute hoặc đổi P1/P2.

Lệnh đã chạy: `scripts/verify_opt02b_leaf.ps1`, WSL `bash --noprofile --norc scripts/verify_opt02b.sh`, `scripts/verify_opt02b_modelsim.ps1`, `scripts/run_opt02b_a35_ppa.ps1`; sau đó `python scripts/audit_opt02b.py collect`. Nguồn/driver/seed/compiler/hash/counter/report lưu results/opt02b_20261017; archive gọn và manifest SHA. `audit_opt02b.py restore` khôi phục raw bằng chứng khi clone, collect kiểm checkpoint đã lưu. Runner chặn ghi đè bằng chứng đã có; không chạy lại prepare vào snapshot đã khóa. Giữ dữ liệu lịch sử trước đó và cập nhật tiến độ theo mốc thử nghiệm, không đánh dấu toàn Gate4.
'''
p=R/'l1/PLAN.md';s=p.read_text(encoding='utf-8');assert '### 8.23.' not in s
p.write_text(s.rstrip()+'\n\n'+body.strip()+'\n',encoding='utf-8')
p=R/'rtl/README.md';s=p.read_text(encoding='utf-8')
s+='''

## A1 OPT-02b candidate — 17/10/2026

`candidates/adder/opt02b/posit_add_align.sv` dùng dual signed delta/clamp, sf-only shifter, equal-sf bypass và prefix-OR jam lookup. Cùng module name/I/O/parameter và zero added stages; chỉ thay thế file production trong source list private, không compile hai module cùng tên. Production A1 giữ nguyên; candidate đã qua leaf880.656 và NF10M/0 mismatch,406+4 strict lint, ModelSim tích hợp. Một run A35T100MHz đạt WNS+0,251ns/hold+0,047ns với2516LUT/930FF; cần matched>=3 run trước promote. Xem PLAN§8.23.
'''
p.write_text(s,encoding='utf-8')
p=R/'SPEC_Posit_MAC_IP.md';s=p.read_text(encoding='utf-8')
marker='#### B. Độ rộng, alignment và adapter packer'
note='''**Khảo sát hiện thực OPT-02b ngày17/10:** candidate A1 giữ nguyên hợp đồng bên dưới (signed delta, tie, clamp/jam và specials), không đổi I/O hoặc H_ADD3. Không thêm C-prefix register hoặc thuộc tính fanout. Leaf/NF kiểm bit-exact và một lượt A35T đạt100MHz; chưa promote production, không thay AC/Gate4. Bằng chứng PLAN§8.23 và results/opt02b_20261017.\n\n'''
assert note not in s;s=s.replace(marker,note+marker)
p.write_text(s,encoding='utf-8')
p=R/'docs/TIEN_DO_DO_AN.md';s=p.read_text(encoding='utf-8')
marker='<!-- OPT03_REPORT_END:docs/TIEN_DO_DO_AN.md -->'
row='| 3 | Thử OPT-02b cho A1 align | Leaf880.656,NF10M và ModelSim tích hợp0 mismatch;406+4 lint sạch. Một A35T Default đạt100MHz,WNS+0,251ns; LUT+54,FF giữ930. Lưu candidate, chưa promote/chốt đa run hoặc Gate4 | ✅ |\n'
assert row not in s;s=s.replace(marker,row+marker)
p.write_text(s,encoding='utf-8')
print('OPT02B_REPORT_UPDATED')
