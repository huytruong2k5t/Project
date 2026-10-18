"""Synchronize existing project documents after final verification (no RTL edits)."""
from pathlib import Path
import re
from audit_week14 import R,O,sha,load


def edit(path,fn):
    raw=path.read_bytes();nl='\r\n' if b'\r\n' in raw else '\n'
    old=raw.decode('utf-8').replace('\r\n','\n');new=fn(old)
    path.write_bytes(new.replace('\n',nl).encode('utf-8'))


def finish_status_tables():
    def spec(s):
        s=s.replace('| Mức | Điều kiện | Hiện trạng14/10/2026 |','| Mức | Điều kiện | Hiện trạng18/10/2026 |')
        s=s.replace('Các mốc đơn vị/Gate1/Gate2 đạt; ma trận final và PPA toàn khối chưa đạt',
                    'Các mốc đơn vị/Gate1/Gate2 đạt;final approximate W14 đạt;AC02 exhaustive và matched PPA vẫn mở')
        s=s.replace('Gate3 tuần11 đạt số học/protocol và coverage phân bố,near52,55548% (§11.12); ma trận final/PPA còn mở',
                    'Gate3 tuần11 và final NF250M/AC04 W14 đạt;AC02 exact và matched PPA còn mở,không gọi toàn Tier đạt')
        s=s.replace('Chưa đạt; oracle/L1 F_W32/flags/state đã đạt tuần12; F RTL,ma trận cuối,paired accuracy/PPA và Gate4 còn mở',
                    'Chưa đạt toàn Tier;F RTL90M,final approximate/AC04 và9M paired standalone accuracy đã đạt;AC02,matched PPA/Gate4 và hồ sơ vẫn mở')
        s=s.replace('Main mới10M,near52,55548% và coverage Gate3 đạt; pilot bốn format0 mismatch. Chưa toàn ma trận final',
                    'Gate3/pilot bốn format đạt;W14 NF250M completed/0 mismatch trên25 điểm32/3 và32/2,near≥30% từng điểm;AC04 main đạt. Exact/AC02 vẫn riêng')
        row='| F RTL so sánh chính | `posit_mac_f`/`mac_f_wrapper`,F1–F5,L1 F_W32 và oracle full-grid32/3 | W14 n0..8 OPS1/FLOOR/RNE,FW12 W32:90M completed/0 mismatch;AC04 main vàpaired standalone accuracy đạt. Chưa matched PPA/board signoff |\n'
        if row not in s:s=s.replace('| Paper research |',row+'| Paper research |',1)
        s=s.replace('results/week9_implementation/gate2_acceptance.json; final per-profile matrix còn mở',
                    'results/week9_implementation/gate2_acceptance.json;final approximate MAC profiles results/week14/completion.json,không thay AC02')
        s=s.replace('results/week10_adder/summary.json; final AC02/AC04 còn mở',
                    'results/week10_adder/summary.json;AC04 tích hợp main đạt tại results/week14/coverage_closure.json;exact/AC02 vẫn mở')
        s=s.replace('results/week11/summary.json; coverage near30% chưa đạt theo §11.11,không gọi mọi tiêu chí Gate3 đã đóng',
                    'results/week11/summary.json,results/nf_coverage_20261014/summary.json;W14 NF250M/0 mismatch,near≥30% mỗi điểm và AC04 main đạt;AC02 riêng')
        s=s.replace('results/week12/{summary,freeze}.json: G-F-L1 đạt trong profile đã chốt; F RTL và ma trận final còn mở',
                    'results/week12/{summary,freeze}.json;W14 F90M/0 mismatch,AC04 main,9M paired standalone accuracy;matched PPA còn mở')
        s=s.replace('Logs đi cùng canonical reports; chưa CDC/RDC/STA signoff',
                    'Logs canonical;W14 reset/interface review và ModelSim đạt,EX0 có1 scoped lint waiver;không formal RDC/board signoff')
        s=s.replace('Đã có tái lập theo mốc; orchestration toàn bộ và traceability final cần hoàn thiện',
                    'W14 audit35 điểm,15 mutant,replay4 pilot vàarchive CRC/SHA đạt;backup theo Git push cuối phiên. Toàn SPEC/AC02 vẫn riêng')
        return s
    edit(R/'SPEC_Posit_MAC_IP.md',spec)
    def rtl(s):
        s=s.replace('Đây là OOC theo profile công bố, chưa board signoff, final per-n/AC04 W14 hoặc paired NF/F PPA.',
                    'Đây là OOC theo profile công bố;W14 final approximate/AC04 main đã đạt. Chưa board signoff,exact/AC02 hoặc paired NF/F PPA.')
        s=s.replace('Producer lịch sử không dùng để refreeze/ghi đè release mới. W14-01..06 đã đạt: F90M/0 mismatch, pilot/accuracy calibration/matrix freeze; W14-07..12 còn mở (Optimization8.33).',
                    'Producer lịch sử không dùng để refreeze/ghi đè release mới. W14-01..11 đạt:350M RTL completed/0 mismatch,AC04 main và9M paired standalone accuracy;Optimization8.34/results/week14/handoff.json. W14-12/AC02 hoãn riêng;EX0 structural diagnostic chưa claim toggle closure.')
        return s
    edit(R/'rtl/README.md',rtl)
    def progress(s):
        row='| **4. Exact/AC02 (W14-12)** | p8 MAC2^24,p16 exhaustive mul/add2^32,p32/2≥1e8+corner theo SPEC | không | Nhánh được hoãn riêng theo lịch;phải công bố phần chưa chạy trước nghiệm thu tổng/Gate4,không dùng W14 approximate thay AC02 |\n'
        if row not in s:s=s.replace('| **5. Timing giao tiếp tích hợp ngoại vi** |',row+'| **5. Timing giao tiếp tích hợp ngoại vi** |',1)
        return s
    edit(R/'docs/TIEN_DO_DO_AN.md',progress)


def main():
    final=load(O/'completion.json');assert final['total_completed']==350000000 and final['mismatches']==0
    cov=load(O/'coverage_closure.json');accuracy=load(O/'accuracy_final/main_check.json')
    release=final['release_id'];nf=[r for r in final['jobs'] if r['job']['top']=='nf' and r['job']['exact_en']]
    nftable='\n'.join(f"| {r['id']} | {r['completed']:,} | {r['reset_aborts']:,} | 0 | {r['near_percent']:.5f}% | {r['seconds']:.2f} |" for r in nf)
    cvtable='\n'.join(f"| {name} | {p['raw']['v_line']['hit']}/{p['raw']['v_line']['total']} ({p['raw']['v_line']['percent']:.3f}%) | {p['raw']['v_branch']['hit']}/{p['raw']['v_branch']['total']} ({p['raw']['v_branch']['percent']:.3f}%) | {p['reviewed']['v_branch']['hit']}/{p['reviewed']['v_branch']['total']} ({p['reviewed']['v_branch']['percent']:.3f}%) | {p['raw']['v_toggle']['hit']}/{p['raw']['v_toggle']['total']} ({p['raw']['v_toggle']['percent']:.3f}%) |" for name,p in cov['profiles'].items())
    accrows=[]
    for d in sorted(accuracy['rows'],key=lambda r:r['n']):
        cr=lambda k:'/'.join(f'{v:.4f}' for v in d['random_'+k]['correct_rate_percent'])
        w,l,t=d['f_win_lose_tie']
        accrows.append(f"| {d['n']} | {d['random_nf']['mean_err_percent']:.7g} / {d['random_f']['mean_err_percent']:.7g} | {cr('nf')} | {cr('f')} | {w}/{l}/{t} |")
    acctable='\n'.join(accrows)
    section=f'''

### 8.34. Hoàn tất W14-07..11 trên release đã khóa — 18/10/2026

**Phạm vi kỹ thuật W14-01..11 đã đạt, đủ chuyển sang matched PPA tuần15.**
Release `{release}`,38 module+header, L1/oracle và mọi constraints không đổi.
W14-12/AC02 vẫn mở riêng: không gọi đây là nghiệm thu toàn SPEC/Gate4 hoặc board signoff.
Backup Git được kiểm bằng kết quả push cuối phiên; JSON `handoff.json` không tự tuyên bố đã push.
W14-01..06 và archive8.33 giữ nguyên để truy vết, không ghi đè nguồn/kết quả lịch sử.

| Mốc | Bằng chứng chính |
| --- | --- |
| W14-07 | 25 điểm NF ×10M=250M completed;32/3 OPS1 n0..8,OPS0 n0..6 và8;32/2 OPS0/1 n1..4;0 mismatch bits/flags/state/oracle |
| W14-08 | NF32/3,NF32/2,F32/3 main đạt line≥95%,branch≥90%,toggle≥85%; functional100% miền hợp lệ, raw và proof/exclusion giữ riêng |
| W14-09 | 9n ×1M=9M paired standalone triples; n2/4/8 trước; pilot100k/n replay đúng counter cũ,9216 Fraction checks trước và sau main;CI95/ngoại lệ/kết quả F bất lợi được lưu |
| W14-10 | Comparator NF32/3 EXACT_EN0,OPS1,n3 ×10M completed;0 mismatch; mode0 từ chối,reset/stall/state/latency được kiểm, ModelSim companion8.33 và lint waiver có scope giữ nguyên |
| W14-11 | Audit35 điểm/350M;15 mutant thiếu job/count/status/hash/log/coverage/accuracy/replay đều bị từ chối;4 pilot×20k replay normalized JSON giống hệt; archive CRC/SHA và backup cuối phiên |

Tổng main **350.000.000 completed** = F90M + NF250M + comparator10M,
**{final['total_reset_aborts']:,} reset-abort /0 mismatch**. Abort không cộng vào completed hoặc mẫu số near.
F90M là bằng chứng8.33 tái dùng đúng source hash; phiên này thêm NF/comparator260M.
Near của mọi điểm đều≥30%; standalone/acc_mode,clear/commit,stall và invalid config có counter riêng.
Các reset abort kiểm scoreboard nhưng không gọi là phép tính hoàn thành.

| Điểm NF | Completed | Reset-abort | Mismatch | Near | Wall seconds |
| --- | --- | --- | --- | --- | --- |
{nftable}

**Hiệu năng harness:** giữ binary full instrumentation cũ; derivative line-only NF fast
copy nguyên snapshot nguồn,26 pilot20k từng điểm có JSON số học/protocol/counters trùng
byte-value với full pilot cũ. Khóa `nf_extension/freeze.json` trước main;workers3 được
chọn sau đo CPU/RAM/RSS. Không đổi seed,phân bố,n/OPS hoặc oracle để tăng tốc.
Tool Verilator5.032/GCC15.2.0,ModelSim10.1d; seed/lệnh/runtime/binary/source SHA trong execution.json.
Wall seconds phản ánh mô phỏng phần mềm có chạy đồng thời, không phải throughput FPGA.

**AC04 — số điểm instrumented toàn hierarchy RTL đang hoạt động, theo từng profile:**

| Profile | Line thô | Branch thô | Branch sau review | Toggle thô |
| --- | --- | --- | --- | --- |
{cvtable}

NF không loại điểm structural nào. F chỉ loại **2 branch**:
`ops_sel_comb.sv:125 else` vì F wrapper nối cfg_mode tới hằng MODE_APPROX=1;
`fused_add_pipe.sv:249 else` vì chuỗi `if(!meta_sync2) else if(meta_sync2)` không có
nhánh cuối trong mô hình2-state. Source SHA,identity/file/line/hierarchy và căn cứ ở
`coverage_closure.json`. Tất cả nhánh ready/stall chưa hit vẫn giữ trong mẫu số;
không miễn theo lý do “chưa hit”. Mô phỏng ModelSim4-state/reset/CK2Q là bằng chứng riêng,
không dùng coverage2-state để tuyên bố an toàn với mọi X/Z.

Full companion F20k/n đã chạy sau matrix freeze; thêm directed F30k/OPS0 và30k/OPS1,
NF mixed exact/approx100k/format và carry20k/format; mỗi suite có manifest trước chạy,
dùng đúng full RTL library cũ. Không trộn line-only main để suy toggle/branch.
Bin carry NF còn thiếu ban đầu được hit bằng vector `(2−2^-F)×1+2^-8`, đạt153/157 lần
ở32/3 và32/2; không sửa corpus main để nhận PASS.

Functional NF: regime/sign256/256,run61/61,popcount6/6,flags5/5,config72/72,
iteration-mode13/13,adder24/24 trong70 candidate,product packer7/7,final packer6/6.
Final sat_min không thể xảy ra vì hai toán hạng cộng đều là bội nguyên của minpos.
Các46 bin adder không hợp lệ có proof theo delta/sign/normalization.
F: cross anchor/sign/delta/LZC **34/34** trong100 candidate,packer7/7,regime/sign256/256,
run61/61,n9/9,iteration9/9,flags5/5 vàdelta/mode10/10 trước/sau cut.
66 bin cross còn lại được phân tích theo cùng-sign,anchor tie,delta≥2 và giới hạn14 bit
significant của P_hat; giữ từng lý do và directed witness ở closure/plan.json.

Comparator EX0 full companion20k giữ structural diagnostic riêng (toggle chưa đạt85%
trong diagnostic này); không gán coverage main EXACT_EN1 cho derivative EX0.
TC-W14-10 kiểm số học/protocol/lint/feature policy, không tuyên bố AC04 riêng cho EX0.
Lint comparator có đúng1 waiver UNUSEDSIGNAL tại sbm_shift_comb.sv:18 do pruning upper
y_mant khi exact disabled; unsuppressed warning vẫn lưu, không gọi raw strict là0 warning.

**Paired accuracy — mỗi n1M triples, directed128 tách IID random:**

| n | Mean Err% NF / F (random) | CorrectRate NF % (<0,1 /0,5 /1 /5%) | CorrectRate F % | F thắng/thua/hòa (paired finite) |
| --- | --- | --- | --- | --- |
{acctable}

Reference là exact-real `A×B+C` full-grid32/3, không phải kết quả nhân approximate.
Hai model nhận cùng A/B/C,OPS1,FLOOR/RNE,FW12;F W32/Q29. Main accuracy chạy L1 frozen,
không tính9M này vào350M RTL. Đối chuẩn Python Fraction độc lập1024/n=9216 ca kiểm
decode/RNE/reference/error/strict threshold; prefix trace khớp pilot đã kiểm.
Err%=100|y−r|/|r|;CorrectRate dùng `<` nghiêm ngặt bằng integer grid,không trừ floating
để quyết định ngưỡng hoặc win/lose/tie. Relative NMSE=mean((y−r)^2/r^2),không phải
ratio tổng công suất. MaxErr,p50/p90/p99,maxULP,NaR/reference-zero/zero-match lưu JSON.
CI95 Wilson cho CorrectRate trong random finite/nonzero;mean-error CI chuẩn là mô tả,
không bảo đảm đuôi phân bố nặng. Directed128 không vào CI IID. Win CI điều kiện trên
ca quyết định random,không gộp tie làm win. `accuracy_inference.json` trừ directed128
bằng Fraction trước khi tính CI thắng;field win CI gộp trong main_check giữ như số mô tả,
không dùng để suy luận IID. CorrectRate CI random không đổi. Không khẳng định F luôn chính xác hơn NF:
sai số nhân approximate và cửa sổ W32 có thể chi phối,lượt F kém NF vẫn công bố.
Đây là phân bố raw-code Posit32,không phải benchmark AI; chưa đo application/feedback accuracy.
Feedback đúng chức năng/state đã kiểm trong RTL main,nhưng không suy accuracy chuỗi từ standalone.

**Lệnh đã chạy từ Posit_MAC trong WSL không nạp profile cá nhân:**

```bash
bash scripts/build_week14_nf_fast.sh
python3 scripts/run_week14_nf_ext.py pilot
python3 scripts/run_week14_nf_ext.py main
bash scripts/run_week14_closure.sh
bash scripts/run_week14_nf_carry.sh
bash scripts/run_week14_ex0_coverage.sh
python3 scripts/audit_week14_closure.py
bash scripts/run_week14_accuracy_final.sh pilot
bash scripts/run_week14_accuracy_final.sh main
python3 scripts/replay_week14_final.py
python3 scripts/check_week14_accuracy_inference.py
python3 scripts/audit_week14_final.py
python3 scripts/report_week14_final.py
python3 scripts/retain_week14_final.py
```

Producer từ chối output đã tồn tại; đây là lệnh truy vết phiên,không chạy đè checkpoint.
Tái lập bằng hai archive `evidence_w14_06.zip` và `evidence_w14_final.zip`,source snapshot
và manifest; dùng workspace/output mới. Tool/binary khác phải có manifest replay riêng,
không rehash lịch sử. Archive bỏ binary/cache/wave/DCP,giữ nguồn/log/report/counter/raw coverage.
Một lệnh gọi bash qua heredoc từ PowerShell bị lỗi quoting trước thực thi; đổi sang script
file riêng. Collector/audit mới từng nhầm tên key plan; đã sửa auditor trước nghiệm thu,
không sửa dữ liệu hoặc RTL. Không có mismatch RTL bị che.

**Còn mở:** W14-12/AC02 p8 MAC2^24,p32/2≥1e8+corner vàp16 exhaustive theo SPEC;
matched PPA NF EXACT_EN1/NF EXACT_EN0/F trên A35T với≥3 run/config ở W15;
hồ sơ/demo W16. Không có STA mới trong phiên này,khóa timing8,3ns120,48MHz giữ nguyên.
Không tiếp tục paper baseline/TableI hoặc XCVU9P trong W14.
'''
    optimization=R.parent/'doc/Optimization.md'
    def opt(s):
        assert '### 8.34.' not in s
        return s+section
    edit(optimization,opt)
    compact='''## 3.2. Tuần14 — đã hoàn thành phạm vi bàn giao W15

**Thực hiện sớm18/10/2026** trên `POSIT_MAC_RTL_20261018_OPT12_120`,không sửa RTL/L1/oracle/constraints.
Checklist W14-01..11 đã nghiệm thu được gỡ khỏi kế hoạch; chi tiết TC,seed,lệnh,counter,
coverage/proof/accuracy và archive ở [Optimization8.33–8.34](../../doc/Optimization.md#834-hoàn-tất-w14-0711-trên-release-đã-khóa--18102026)
và `results/week14/completion.json`, `coverage_closure.json`, `accuracy_final/main_check.json`, `handoff.json`.
Backup cuối phiên được xác nhận bằng kết quả Git push,không suy từ file JSON.

| Mốc lớn | Kết quả | Trạng thái |
| --- | --- | --- |
| W14-01..05:review,harness,pilot và freeze | Release/counters/oracle/negative audit và accuracy calibration đạt; matrix/source/binary freeze trước main | ✅ |
| W14-06/07:main NF/F | F90M+NF250M completed,0 mismatch; đúng≥10M từng điểm,n/OPS/profile riêng,abort tách completed | ✅ |
| W14-08:coverage chính | NF32/2,NF32/3,F32/3 đạt line/branch/toggle và100% functional bin hợp lệ;F có2 loại trừ branch có căn cứ,giữ số thô | ✅ |
| W14-09:paired accuracy | 9n×1M standalone triples,Python Fraction9216 checks;CI95,ngoại lệ,kết quả F bất lợi lưu đầy đủ | ✅ |
| W14-10/11:comparator và tái lập | NF-EX010M/0 mismatch;15 audit mutants bị từ chối,4 pilot replay khớp;archive CRC/SHA và backup cuối phiên | ✅ phạm vi kỹ thuật |

**W14-12 / AC02 vẫn mở riêng**,không dùng main approximate hoặc pilot exact thay nghiệm thu exact:

| Phần còn lại | Tiêu chí chưa chạy đủ | Trạng thái |
| --- | --- | --- |
| Exact p8 | MAC exhaustive2^24 bộ ba,0 mismatch; các đơn vị exhaustive theo SPEC | không |
| Exact p16 | Exhaustive mul/add2^32 cặp mỗi phép,0 mismatch | không |
| Exact p32/2 | ≥10^8 vector phân tầng+corner,0 mismatch với SoftPosit đúng format | không |

W14-01..11 đủ bàn giao matched PPA W15;W14-12 được hoãn theo lịch đã duyệt,không được miễn AC02
hoặc gọi toàn SPEC/Gate4 đã đạt. ComparatorEX0 giữ structural diagnostic riêng,chưa claim toggle85%
cho derivative;lint có đúng1 waiver feature-unused đã công bố. Accuracy standalone không chứng minh
accuracy ứng dụng hoặc chuỗi feedback. Không đổi release để khắc phục test.

'''
    def progress(s):
        start=s.index('## 3.2.');end=s.index('## 3.3.',start)
        s=s[:start]+compact+s[end:]
        s=s.replace('final per-n/AC04, CDC/RDC, paired accuracy/PPA và Gate4 còn mở.',
                    'final approximate per-n/AC04,reset/interface review và paired standalone accuracy đã đạt W14;exact/AC02,matched PPA và Gate4 còn mở.')
        s=s.replace('RTL NF/F profile chính đã kiểm; còn accuracy, final per-n và paired PPA.',
                    'RTL NF/F final approximate và paired standalone accuracy đã đạt; còn matched PPA.')
        s=s.replace('còn ma trận final và coverage cuối NF/F','final approximate và coverage NF/F đã đạt;exact/AC02 vẫn mở riêng')
        s=s.replace('Còn đo matched NF/F, accuracy và hồ sơ cuối','Còn đo matched NF/F,AC02 và hồ sơ cuối')
        s=s.replace('Tiếp theo W14-01→W14-12 theo kế hoạch; chưa chạy W14.',
                    'W14-01..11 đã đạt phạm vi bàn giao;tiếp theo matched PPA W15,W14-12/AC02 hoãn riêng.')
        s=s.replace('| 13 | RTL fused | processing | Đã triển khai sớm15/10: main10M/0 mismatch,pipeline/XSim đạt,STA A35T100MHz R2R đạt; còn hoàn thiện coverage/signoff,final per-n và so sánh theo tuần14–15 |',
                    '| 13 | RTL fused | ✅ | RTL/pipeline đã kiểm;final F90M và AC04 hoàn tất W14. Reset/interface đã review;matched PPA và board signoff không thuộc mốc RTL này |')
        s=s.replace('| 14 | Regression và accuracy paired NF/F | processing | Đã chạy sớm18/10: W14-01..06 đạt,F90M/0 mismatch. Còn NF main,AC04,paired accuracy,comparator và audit cuối; xem mục3.2/Optimization8.33 |',
                    '| 14 | Regression và accuracy paired NF/F | ✅ phạm vi W14-01..11 | 350M completed/0 mismatch gồmF90M+NF250M+NF-EX010M;AC04 chính và9M paired standalone accuracy đạt. W14-12/AC02 hoãn riêng;Optimization8.34 |')
        start=s.index('## 3.1.');end=s.index('## 3.2.',start)
        s=s[:start]+'''## 3.1. Bàn giao tuần13

W13-01..06 đã hoàn tất phạm vi RTL/counters/coverage;reset/interface của W13-07 đạt W14-01.
Matched PPA chuyển theo đúng lịch W15,không giữ lại checklist RTL đã nghiệm thu.
Chưa board signoff hoặc nghiệm thu toàn SPEC.

'''+s[end:]
        # Repair a historical misplaced week8 row, retaining its content in the weekly table.
        row='| 8 | RTL mã hóa và làm tròn | ✅ | Packer tổ hợp/pipeline và parser→packer đạt; PPA đơn vị đã khảo sát, sau tối ưu P2, benchmark đạt setup100MHz ở ba seed mỗi mode |\n'
        if row in s:
            s=s.replace(row,'');pos=s.index('| 9 | RTL bộ nhân lặp')
            s=s[:pos]+row+s[pos:]
        s=s.replace('Đợt100MHz đã lưu lịch sử; study `results/opt120_20261018` đã thử, được sinh viên chọn và promote thành release OPT12_120 riêng. L1/oracle, constraints100MHz và qualification trial giữ nguyên; promotion.json/reference_freeze.json lưu chuyển tiếp. Chưa chạy W14.',
                    'Đợt100MHz giữ lịch sử;OPT12_120 đã promote và qua W14-01..11. L1/oracle và constraints không đổi;không mở lại tối ưu trước matched PPA.')
        s=s.replace('W14 chưa chạy; OPT-13/14 không triển khai','W14-01..11 đã đạt; OPT-13/14 không triển khai')
        old='| **1. Khóa RTL & Chạy Tuần 14 (`Paired NF/F`)** |'
        s='\n'.join(line for line in s.split('\n') if not line.startswith(old))
        s=s.replace('**2. PPA đối xứng NF/F','**1. PPA đối xứng NF/F').replace('**Ưu tiên số 2:** Thực hiện ngay sau `W14-10`','**Ưu tiên số 1:** W14-01..11 đã đạt;thực hiện tiếp W15')
        s=s.replace('**3. Hồ sơ / Báo cáo / Slide','**2. Hồ sơ / Báo cáo / Slide').replace('**Ưu tiên số 3:** Hạn chính','**Ưu tiên số 2:** Hạn chính')
        s=s.replace('**4. Tái lập / Luồng tự động**','**3. Tái lập / Luồng tự động**')
        marker='### 4.18. Mẫu cập nhật tiếp theo'
        assert marker in s
        pos=s.index(marker);day=s.rfind('### ',0,pos)
        block=s[day:pos].rstrip()+'\n| 11 | Hoàn thành W14-07..11 | NF250M+NF-EX010M mới/0 mismatch;kế thừaF90M đúng hash. AC04 chính,9M paired standalone accuracy và audit/replay đạt;archive/backup cuối phiên. Exact/AC02 hoãn riêng;chuyển W15 matched PPA | ✅ phạm vi kỹ thuật |\n\n'
        block=re.sub(r'(?<=\|)\n\n+(?=\|)','\n',block)
        s=s[:day]+block+s[pos:]
        return s
    edit(R/'docs/TIEN_DO_DO_AN.md',progress)
    note='W14-01..11 đã đạt18/10:350M completed RTL/0 mismatch (F90M+NF250M+NF-EX010M),AC04 main và9M paired standalone accuracy. W14-12/AC02 và matched PPA/Gate4 còn mở;Optimization8.34/results/week14/handoff.json. Không đổi hợp đồng số học,source release hoặc timing.'
    def plan(s):
        s=s.replace('W14-01..06 đã đạt:F90M/0 mismatch và counters/pilot/accuracy calibration/matrix freeze; NF final/AC04/accuracy/comparator/audit cuối còn mở (Optimization8.33).',note)
        return s
    edit(R/'l1/PLAN.md',plan)
    def spec(s):
        old='W14-01..06 đạt18/10 trên cùng release:F90M/0 mismatch,review/counters/harness/pilot/calibration/freeze; corner/ModelSim đạt. NF final,AC04,paired accuracy/comparator/audit cuối vẫn mở; chưa paired PPA/board signoff. Xem Optimization8.33 và results/week14/summary.json.'
        assert old in s;s=s.replace(old,note+' Chưa paired PPA/board signoff. Lint EX0 có1 scoped feature-unused waiver;AC04 chính không bao gồm toggle closure riêng EX0.')
        return s
    edit(R/'SPEC_Posit_MAC_IP.md',spec)
    edit(R/'l1/README.md',lambda s:s.replace('**Tài liệu hiện hành:**','**Trạng thái kiểm chứng18/10/2026:** '+note+' Các mô tả/tiến độ có ngày cũ bên dưới giữ lịch sử.\n\n**Tài liệu hiện hành:**',1))
    guide='''

## W14 final18/10 — nguồn chuẩn và cách tái lập

Production hiện hành là OPT12_120,không còn OPT02C100MHz. W14-01..11 đã đạt phạm vi kỹ thuật;
W14-12/AC02 và matched PPA W15 vẫn riêng. Xem Optimization8.33/8.34 và results/week14/handoff.json.
Hai archive evidence_w14_06.zip + evidence_w14_final.zip cùng hai archive_manifest.json/
final_archive_manifest.json giữ nguồn,lệnh,seed,report,counter và raw coverage. Kiểm SHA/CRC trước
giải nén trên workspace mới;không ghi đè checkpoint hiện có. Binary,obj,ModelSim work/wave cần build lại.

Runner main F lịch sử chỉ chạy F;NF dùng build_week14_nf_fast.sh/run_week14_nf_ext.py.
Các script prepare/build/freeze/collector có output cố định và từ chối chạy lại. Chúng ghi workflow
gốc,không phải một lệnh replay tùy thư mục. Dùng snapshot exact đã lưu để rebuild trên bản sao sạch;
compiler/binary khác cần manifest replay mới,không sửa source/hash của evidence cũ để gọi PASS.
prepare_week14.py là bootstrap trước các bản sửa harness,không chạy ghi đè harness hiện hành.

```bash
# Kiểm trên workspace hiện tại sau khi evidence đã được khôi phục:
python3 scripts/audit_rtl_release.py --self-test
python3 scripts/audit_week14_closure.py
python3 scripts/audit_week14_accuracy_final.py main
python3 scripts/audit_week14_final.py
```

Auditor final cần binaries frozen còn trong local hoặc rebuild tương thích byte đúng toolchain;
archive không chứa binary. Nếu hash mới khác,giữ nguyên receipt cũ và mở bản replay có provenance riêng.
replay_week14_final.py tạo4 output mới và từ chối thư mục final_replay đã tồn tại.
Không chạy lại STA hoặc regression lớn chỉ vì cập nhật tài liệu.
'''
    edit(R/'docs/HUONG_DAN_CHAY_WSL_MODELSIM.md',lambda s:s+guide)
    finish_status_tables()
    print('W14 existing documents synchronized; no RTL/model/constraints change')


if __name__=='__main__':main()
