"""Update existing documents from the audited OPT-03 metrics, idempotently."""
from pathlib import Path
import json

R=Path(__file__).resolve().parents[1]
D=json.loads((R/'results/opt03_20261017/summary.json').read_text(encoding='utf-8'))
assert D['status']=='PASS_OPT03_SCOPE'


def append_section(path,heading,body,before=None):
    p=R/path
    s=p.read_text(encoding='utf-8')
    start=f'<!-- OPT03_REPORT_START:{path} -->'
    end=f'<!-- OPT03_REPORT_END:{path} -->'
    text=f'{start}\n{heading}\n\n{body.strip()}\n{end}\n'
    if start in s:
        a=s.index(start);b=s.index(end,a)+len(end)
        s=s[:a]+text.rstrip()+s[b:]
    elif before:
        a=s.index(before);s=s[:a]+text+'\n'+s[a:]
    else:s=s.rstrip()+'\n\n'+text
    p.write_text(s,encoding='utf-8')


table='''| Part | Median STA MHz trước → sau | Thay đổi | Median LUT trước → sau | FF trước → sau |
| --- | --- | --- | --- | --- |
'''
for c in D['comparisons']:
    a,b=c['baseline'],c['candidate']
    table+=f"| {c['part']} | {a['sta_estimate_mhz']:.2f} → {b['sta_estimate_mhz']:.2f} | {c['frequency_change_percent']:+.2f}% | {a['lut']:g} → {b['lut']:g} | {a['ff']:g} → {b['ff']:g} |\n"
main=D['native_main']
target=all(r['slack']>=0 for r in D['ppa'] if r['variant']=='candidate')
target_text='đạt R2R setup100MHz ở cả6 run' if target else 'chưa đạt R2R setup100MHz ở tất cả run'
proof=f'''Đã triển khai và giữ OPT-03 trong production: `normalize + product P1 → P2 → parse/product bank → adder A1/A2/A3 → final packer P1/P2`. Chỉ `rtl/mac_nf/mac_nf_wrapper.sv` thay đổi so với snapshot trước phiên. Không ghép OPT-01 candidate, OPT-02/04/05; không đổi L1, fused, precision hoặc thuật toán RNE. `round_unpacked_comb` vẫn giữ làm reference/unit. Giao diện/parameter top giữ nguyên; lịch NF thay đổi có chủ đích.

**Hợp đồng:** q=max(1,t thực tế), E0 accept; product P1 ở E(q+5), P2 E(q+6), parse/product E(q+7); first-valid E(q+12), handshake không stall E(q+13), nhận mới E(q+14). Tăng2 chu kỳ so checkpoint W11. C_eff/context giữ một giao dịch tới retire. Product packer dùng ready/valid elastic, flags đi cùng dữ liệu; product_capture=product_pack_valid && (!norm_valid_q || add_ready). Core_done một xung, chỉ có một reservation nên không thiếu credit. Không thêm bản sao C/context hoặc register wide normalized. Numerical sticky tích=0; cut/tail xấp xỉ chỉ là status như hợp đồng P_hat cũ.

**Chức năng:** native bốn pilot20.000/format8/0,16/1,32/2,32/3; main32/3 **{main['completed']:,} completed/{main['reset_aborts']:,} reset-aborted,0 mismatch**. Seed main20264217, Verilator5.032/GCC15.2.0; ES3 dùng integer/dyadic oracle độc lập, không dùng SoftPosit ES2. Strict lint `--timing -Wall` cả4 format sạch; native `--no-timing` chỉ bỏ CK2Q để kiểm chu kỳ. 72/72 control bins,256/256 regime–dấu main, kiểm trực tiếp product/C_eff vào adder; near-cancellation standalone/acc lần lượt {100*D['near_fraction_standalone_acc'][0]:.4f}%/{100*D['near_fraction_standalone_acc'][1]:.4f}%. Cùng generator/seed nhưng vì generator phụ thuộc clock, không gọi đây là byte-identical stream với checkpoint trước retiming.

ModelSim10.1d giữ CK2Q:82.944 corner và28.512 protocol completed/288 reset-aborted,0 mismatch. Schedule suite thêm284 lần reset theo mọi age pipeline trên4 format; kiểm product capture sau core_done đúng2 cạnh, không token cũ lọt qua reset, first-valid/handshake/II ở cả exact/approx và không stall. Private LOD copy chỉ đổi parameter-sized cast thành typedef cùng width cho compiler cũ; unit41.024/0 mismatch; production LOD giữ nguyên. Reset/stall/context/acc commit và output giữ ổn định được kiểm.

**STA/PPA:** Vivado2026.1 build6511674, NF32/3,FW12,EXACT_EN=OPS_EN1; cả runtime exact/approx còn trong netlist. Cùng BUFG wrapper, part/speed-grade,10ns/uncertainty0,1ns,I/O max=min input2,5ns/output max0,5ns min0. Ba directive Default/Explore/RuntimeOptimized, không gọi là ba random seed.6 candidate P&R mới;6 baseline reference từ OPT-01 được tái dùng sau xác nhận toàn36 SV+header giống byte và run Default mới trên cả2 part tái lập đúng mọi metric. Hai lần tổng hợp baseline thừa được chủ động dừng; log giữ riêng `calibration/`, không tính là run nghiệm thu. Candidate tổng hợp một lần/part rồi mỗi directive đọc lại checkpoint synthesis trước opt/place/route, không nối tiếp placement của run trước.

{table}
STA MHz=1000/(10−R2R slack), là ước lượng theo constraint của run; {target_text}. Hold/latch/unrouted, setup, I/O, recovery/removal và methodology lưu raw report; không board signoff hoặc matched NF/F. FF không gồm bank I/O thêm vì benchmark chỉ thêm BUFG. Không suy gain fusion từ so với F profile EXACT_EN0.

**Tác động throughput:** top một giao dịch nên phải tính fclk/II, không chỉ MHz. Bảng `throughput_ratio_by_q` trong summary báo q1/2/4/8 với II cũ=q+12, mới=q+14; đây là tỷ lệ ước lượng từ median STA, chưa là throughput đã chạy trên kit. Gate4/final per-n/AC04/CDC/RDC/formal còn mở; không chạy Table I.

**Tái lập:** `bash --noprofile --norc scripts/verify_opt03.sh` (WSL, đặt `OPT03_RESULTS_DIR=results/opt03_replay` để giữ bằng chứng cũ); Windows `scripts/verify_opt03_modelsim.ps1 -RunRoot results/opt03_replay`, rồi `scripts/verify_opt03_schedule.ps1 -RunRoot results/opt03_replay`. STA: `scripts/run_opt03_ppa.ps1 -Part xc7a35tcpg236-1 -RunRoot results/opt03_ppa_replay` và tương tựA100T. Runner từ chối ghi đè run đã có kết quả; snapshot gốc giữ trong source/. `python scripts/audit_opt03.py restore` khôi phục raw proof từ archive; `collect` audit checkpoint gốc. Hash nguồn, driver, fixture, compiler, binary đã chạy, counters và lệnh ở results/opt03_20261017. Không tự chạy prepare_opt03/prepare_opt03_sta trên checkpoint đã khóa.
'''
append_section('l1/PLAN.md','### 8.21. OPT-03 — product RNE P1/P2 và parse riêng, 17/10/2026',proof)
append_section('SPEC_Posit_MAC_IP.md','### 11.16. NF OPT-03 — pipeline làm tròn tích, 17/10/2026',
    'Hợp đồng hiện hành tại §5.1/§5.11-B: product RNE P1/P2 trước parse/product bank; L_valid=q+12,H=q+13,II_min=q+14. R(P_hat), flags, width và fused giữ nguyên. Chi tiết reset/credit/sticky và cạnh clock tại §5.11-B; kết quả/commands tại PLAN§8.21.\n\n'+table+
    f'\nNative main10M/{main["reset_aborts"]} abort,0 mismatch;4 strict lint sạch. ModelSim82.944 corner+28.512 protocol/288 abort và284 reset-age đạt. {target_text}; chưa board signoff/final per-n/AC04 hoặc matched NF/F. Baseline reference source-identical được tái dùng và Default được kiểm lại2 part. Không xác nhận baseline gốc paper hoặc chạy Table I.',
    before='## Phụ lục A')
append_section('scripts/README.md','## OPT-03 NF product pipeline — 17/10/2026',
    'Dùng verify_opt03.sh, verify_opt03_modelsim.ps1, verify_opt03_schedule.ps1 và run_opt03_ppa.ps1. Native replay đặt OPT03_RESULTS_DIR mới; Windows đặt -RunRoot mới. Sources source/candidate được khóa, giữ baseline_reference và calibration riêng. audit_opt03.py restore/collect kiểm raw bằng chứng. Không chạy lại prepare vào checkpoint đã khóa. Chi tiết lệnh và giới hạn tại PLAN§8.21. Runner OPT-01 dùng harness/testbench cũ đã đóng băng, không dùng lịch OPT-03.')
append_section('docs/HUONG_DAN_CHAY_WSL_MODELSIM.md','## OPT-03 NF product RNE pipeline — 17/10/2026',
'''Mở terminal tại thư mục Posit_MAC. Khôi phục bằng chứng gọn khi clone mới:

```text
python scripts/audit_opt03.py restore
python scripts/audit_opt03.py collect
```

WSL (4 pilot và main32/3 10M):

```bash
export OPT03_RESULTS_DIR=results/opt03_replay
bash --noprofile --norc scripts/verify_opt03.sh
```

Windows PowerShell (từ CMD dùng `powershell -NoProfile -File` trước tên script):

```powershell
./scripts/verify_opt03_modelsim.ps1 -RunRoot results/opt03_replay
./scripts/verify_opt03_schedule.ps1 -RunRoot results/opt03_replay
./scripts/run_opt03_ppa.ps1 -Part xc7a35tcpg236-1 -RunRoot results/opt03_ppa_replay
./scripts/run_opt03_ppa.ps1 -Part xc7a100tcsg324-1 -RunRoot results/opt03_ppa_replay
```

ModelSim protocol fixture nằm trong evidence tại protocol_fixtures/; runner không phụ thuộc fixture đã dọn của checkpoint khác. Lịch mới là valid=q+12,handshake=q+13,II_min=q+14. Fixture lịch cũ giữ nguyên số học; testbench cộng đúng2 vào field latency. STA candidate tổng hợp một lần/part, đọc lại checkpoint cho từng directive. Dùng thư mục run mới nếu đã có output; collector mặc định chỉ nghiệm thu checkpoint gốc. Không chạy prepare vào nguồn/bằng chứng đã khóa.''')
p=R/'docs/TIEN_DO_DO_AN.md'
s=p.read_text(encoding='utf-8').replace('**Ngày cập nhật:** 16/10/2026','**Ngày cập nhật:** 17/10/2026').replace('[SPEC v1.18]','[SPEC v1.19]')
s=s.replace('dừng trước các bước tiếp theo theo yêu cầu sinh viên.',
    'OPT-03§8.21 đã triển khai17/10: product RNE P1/P2 → parse riêng, chức năng/latency đã kiểm; chưa làm OPT-02/04/05.')
p.write_text(s,encoding='utf-8')
short='; '.join(f"{x['part']}: {x['baseline']['sta_estimate_mhz']:.2f}→{x['candidate']['sta_estimate_mhz']:.2f}MHz" for x in D['comparisons'])
append_section('docs/TIEN_DO_DO_AN.md','### Ngày 17/10/2026',
    '| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |\n| --- | --- | --- | --- |\n'+
    f'| 1 | Tách pipeline RNE tích của NF — OPT-03 | Main10M và ModelSim corner/protocol0 mismatch; reset/latency/II đạt. STA: {short}; thêm2 chu kỳ và FF, {target_text}. SPEC/PLAN đồng bộ; final NF/F và Gate4 còn mở | ✅ |',
    before='### 4.16. Mẫu cập nhật tiếp theo')
print('OPT03_REPORTS_UPDATED')
