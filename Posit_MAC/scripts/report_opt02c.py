"""Publish the measured pre-W14 release in existing documents only."""
from pathlib import Path
import json
import statistics

R = Path(__file__).resolve().parents[1]
S = R / 'results/opt02c_20261018'


def write(path, text):
    path.write_text(text, encoding='utf-8', newline='\n')


def main():
    data = json.loads((S / 'summary.json').read_text())
    assert data['ready_for_selection']
    lock = json.loads((R / 'rtl/production_freeze.json').read_text())
    assert lock['status'] == 'LOCKED_FOR_W14'
    table = []
    for variant in ('production', 'reference', 'candidate'):
        for run in data['ppa'][variant]:
            area = run['resources']
            table.append(f"| {variant} | {run['strategy']} | {run['wns_ns']:+.3f} | "
                         f"{run['r2r_wns_ns']:+.3f} | {run['whs_ns']:+.3f} | "
                         f"{area['Slice LUTs']} | {area['Slice Registers']} | {area['CARRY4']} |")
    section = '''
<a id="legacy-8-30"></a>

### 8.30. OPT-02c, promote và khóa RTL trước W14 — 18/10/2026

**Đã chọn và promote** `OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A` vào production.
Release `POSIT_MAC_RTL_20261018_OPT02C`, trạng thái `LOCKED_FOR_W14`, gồm38 module SV và header.
Manifest: `rtl/production_freeze.json`; bằng chứng: `results/opt02c_20261018/summary.json`,
`promotion.json`, `lock_receipt.json`, `evidence.zip` và `archive_manifest.json`.
Nguồn trước promote, reference8.28 và candidate được giữ riêng trong snapshot/archive;
không sửa hash hoặc ghi đè hồ sơ cũ.

#### 8.30.1. Thay đổi RTL và giữ nguyên hợp đồng

- A1: hai hiệu scale, hai clamp và hai nhánh tra jam/tail chạy song song; clamp không còn nối tiếp vào điều khiển shifter.
  So sánh clamp bằng bit-check được qualify bằng dấu hiệu số. Equal-scale, specials, flags và jam giữ bit-exact; không thêm FF.
- SAC/controller: fixed shift1, gộp scale+count+1 và zero/one-hot cân bằng (`abc_tree`); controller dùng exhausted đã kiểm.
- Packer P1: prefix OR/lookup sticky; product P2 lưu magnitude đã RNE và sign riêng,
  rồi `posit_magnitude_parse` giải mã magnitude trực tiếp.
- Bảy file SV thay đổi/thêm được ghi hash trước/sau trong promotion.json.
  Hai helper mới là `rtl/mac_nf/posit_product_pack.sv` và `posit_magnitude_parse.sv`.
  `production.f` từ36 lên38 module; public ports/parameters, số học, reset/stall/commit và latency không đổi.
  NF14 tầng: Lvalid=q+12, H=q+13, II=q+14. F13 tầng: q+11/q+12/q+13, q=max(1,t thực tế).
  Magnitude P2 thêm1 FF metadata so với production cũ, không thêm bank hoặc tầng.
  L1/oracle và hai XDC A35T-C2 giữ nguyên byte.

#### 8.30.2. Chức năng và công cụ

ModelSim10.1d, Verilator5.032, GCC15.2.0; Vivado2026.1 build6511674.
NF seed20264217; F smoke seed20261015. Lệnh, source/tool/hash và counters giữ trong study.
ES3 dùng oracle độc lập; không gọi SoftPosit32 ES2 là oracle ES3.

| Kiểm chứng | Kết quả |
| --- | --- |
| A1 leaf baseline/candidate/oracle,11 profile, gồm F2..27 và SF_W35 | 0 mismatch;406 profile strict lint đạt |
| NF pilot8/0,16/1,32/2,32/3 | 80.000 completed,0 mismatch |
| NF acceptance32/3 | 10.000.000 completed,85.316 reset-abort,0 mismatch; toàn bộ JSON counters bằng8.28 |
| NF ModelSim candidate4 format | 111.456 completed,288 reset-abort,0 mismatch |
| F acceptance10M từ8.28 | Kế thừa có kiểm hash:23 SV+header dùng thực tế đều byte-identical; không chạy lại10M |
| F smoke mới | 100.000 completed,0 mismatch; counters bằng8.28 |
| Build từ production sau promote | 37 profile strict lint0 warning/error; NF smoke20.000/0 mismatch |
| ModelSim từ production sau promote | NF32/3:27.864 completed/72 abort; F:8.192 completed/24 abort;0 mismatch, kiểm CK2Q1ns |

Kiểm có reset khi busy/stall, metadata, thứ tự giao dịch, latency, flags và feedback.
Đây là qualification trước W14, **chưa phải** final per-n, coverage AC04 hay Gate4.

#### 8.30.3. PPA matched A35T-C2

Part xc7a35tcpg236-1,10ns; uncertainty setup/hold0,100ns;
input min=max2,500ns, output min0/max0,500ns. XDC đọc trước synthesis.
Production là OPT-03 cũ; reference là tổ hợp OPT-02b của8.28, được dùng lại chỉ sau đối chiếu
hash nguồn, thứ tự file, wrapper, XDC và flow. Candidate chỉ đổi A1 so với reference.
Không nới ràng buộc, không thêm timing exception.

| Gói | Strategy | WNS toàn thiết kế (ns) | R2R WNS (ns) | WHS (ns) | LUT | FF | CARRY4 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
''' + '\n'.join(table) + '''

Median F_STA nội bộ: production77,88MHz → reference110,95MHz → candidate114,40MHz.
Đây là 1000/(10−R2R_WNS), **ước lượng từ STA tại100MHz**, chưa phải quét clock hoặc đo kit.
Candidate đạt setup/hold100MHz trên cả3 strategy; Default/Explore cho cùng kết quả vật lý,
không tính là hai seed ngẫu nhiên độc lập. Default so production: +83 LUT,+1 FF,−17 CARRY4;
so reference:−1 LUT,0 FF,−4 CARRY4. Không tuyên bố giảm tổng LUT so production.

A1 Default: data delay8,870→7,718ns,12→7 logic levels, setup slack+0,987→+2,144ns.
Đường găng R2R mới thuộc accumulator→parserC P1 (+1,259ns).
Không mở thêm tối ưu parser/control sau khi khóa.

F release Default32/3 FW12 W32 EXACT_EN0: WNS+0,982ns,WHS+0,045ns,
R2R+2,002ns,1486 LUT/815 FF/69 CARRY4; đạt mốc100MHz.
NF trong bảng dùng EXACT_EN1, vì vậy **không dùng bảng này kết luận paired NF/F PPA**.
Comparator NF EXACT_EN0 và matched PPA tuần15 còn phải làm.

#### 8.30.4. Reset/CDC, giới hạn và lỗi runner đã xử lý

NF/F có1 clock,0 latch,0 unrouted;931/815 FF,20/18 ASYNC_REG.
report_cdc: All paths are Safely Timed. Giữ bridge và2FF reset release;
sign P2 mới dùng cùng reset/CE. Không thêm clock/reset domain.
Đây chưa phải formal RDC hoặc board signoff; review interface/RDC W14-00b vẫn phải hoàn tất.
Methodology XDCH-2 do budget input min=max và DRC CFGBVS-1 do benchmark OOC không cấu hình
điện áp board được giữ nguyên, ghi rõ giới hạn. Không bỏ warning để làm đẹp kết quả.

Production cũ không đạt setup: Route35-39 trong các lượt baseline được ghi là timing fail,
không phải candidate pass. Collector chỉ chấp nhận warning này khi đi cùng slack âm tương ứng.
Các lỗi launcher không được tính làm bằng chứng PASS: CR cuối lệnh tail sau NF10M
(JSON mô phỏng đã hoàn tất; sửa LF, không chạy lại10M), đường dẫn DCP có khoảng trắng ở
release_checks (sửa ởv2), và PowerShell unwrap tuple làm thiếu ES ở active_event
(sửa ở active_event_v2). Giữ log các lượt lỗi để truy vết.

#### 8.30.5. Khóa nguồn và bàn giao W14

```powershell
python scripts/audit_rtl_release.py --self-test
```

Validator kiểm hash38 SV+header, L1/oracle headers, production.f, maps, filelistF và haiXDC;
4/4 mutation giả lập bị từ chối, không sửa nguồn thật.
Không sửa các file đã khóa khi chạy W14; nếu phát hiện lỗi phải mở change review,
kiểm lại phạm vi ảnh hưởng và tạo release mới, không âm thầm rehash.
Script lịch sử kiểm hash cũ cần chạy trên snapshot tương ứng, không đổi hash để nhận PASS.

Bước kế: W14-00 (matrix freeze/đối chiếu contract và review W14-00b), rồi W14-01..08
theo tiến độ. **Chưa chạy W14 final matrix, chưa đóng Gate4.** Các nhánh đã đóng ở8.29
tiếp tục đóng. Không chạy thêm A100T hoặc thay FW12.
'''
    path = R.parent / 'doc/Optimization.md'
    text = path.read_text(encoding='utf-8')
    marker = '<a id="legacy-8-30"></a>'
    if marker in text:
        text = text[:text.index(marker)].rstrip()
    text = text.replace('| A1 OPT-02b | Candidate đã kiểm; chưa promote theo tiêu chí đa chiến lược | Mục8.23/8.24 |',
                        '| A1 OPT-02c | Đã promote và khóa; A1 Default+2,144ns,0 FF thêm | Mục8.30 |')
    start = '| SAC/packer/parse/A1–A2 tiếp theo |'
    lines = text.splitlines()
    lines = [('| SAC/packer/parse | Production OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A; LOCKED_FOR_W14,38 module; cả3 strategy đạt100MHz | Mục8.30 |'
              if line.startswith(start) else line) for line in lines]
    write(path, '\n'.join(lines).rstrip() + '\n\n' + section.lstrip())

    path = R / 'docs/TIEN_DO_DO_AN.md'
    text = path.read_text(encoding='utf-8').replace('SPEC v1.19', 'SPEC v1.20')
    a = text.index('Gói kết hợp (`OPT-02b')
    b = text.index('### 3.3.2.', a)
    text = text[:a] + '''Release **`POSIT_MAC_RTL_20261018_OPT02C` đã LOCKED_FOR_W14**: production38 module,
L1/oracle/constraint không đổi; NF10M/0 mismatch, F10M kế thừa theo hash và smoke mới đạt.
Candidate đạt100MHz cả3 strategy A35T-C2; median R2R F_STA114,40MHz (ước lượng STA, không phải đo kit).
Chi tiết và giới hạn: [Optimization §8.30](../../doc/Optimization.md#legacy-8-30).

### 3.3.1. Mốc tối ưu và khóa RTL đã hoàn tất trước W14

| ID / nhóm | Mốc chính | Trạng thái | Bằng chứng |
| --- | --- | --- | --- |
| OPT-05 / OPT-09 / OPT-10A | SAC abc_tree, magnitude P2/parse, prefix sticky | ✅ | Đã promote cùng gói; không đổi lịch pipeline |
| OPT-02c | A1 parallel shift/jam/tail, clamp bit-check,0 FF thêm | ✅ | Leaf11 profile/0 mismatch;406 lint; NF10M/0 mismatch |
| OPT-00 / OPT-02b / OPT-02c | Đối chiếu production cũ/reference/candidate,3 strategy cùng A35T-C2 | ✅ | Candidate WNS+0,894/+0,894/+1,011ns; hold dương; bảng §8.30 |
| OPT-07 / OPT-08 | Promote38 module và khóa hash RTL/L1/build/constraint | ✅ | production_freeze.json;37 strict lint; ModelSim NF/F; audit release PASS |

''' + text[b:]
    old = 'Kế hoạch tối ưu chỉ còn bước thử nghiệm gọn `OPT-02c` và thủ tục promote `OPT-07/08` trước khi khóa hoàn toàn RTL. Quy tắc “không sửa RTL” của tuần14 áp dụng ngay sau khi hoàn tất promote gói tổ hợp lên `production`.'
    text = text.replace(old, 'Tối ưu và promote đã hoàn tất. Quy tắc **không sửa RTL/L1/constraint đã khóa** có hiệu lực từ release18/10; W14 chạy trên hash này. Nếu có lỗi phải review và phát hành release mới, không tự rehash để vượt gate.')
    text = text.replace('Promote gói tối ưu 8.28/8.29 (`OPT-07/08`), khóa `matrix_freeze.json`,',
                        'RTL đã promote/khóa tại §8.30; tiếp theo khóa `matrix_freeze.json`,')
    text = text.replace('sau khi promote RTL |', 'trên release đã khóa; chưa chạy final matrix |')
    # Preserve the user's historical daily entry while closing its planned work.
    lines = text.splitlines()
    for i,line in enumerate(lines):
        if line.startswith('| 2 | Đặc tả OPT-02c cho A1'):
            lines[i] = line.rsplit('| processing |',1)[0] + '| ✅ |'
    text = '\n'.join(lines)
    a = text.index('### 4.17.')
    b = text.find('\n### ', a + 5)
    if b < 0: b = len(text)
    entry = '| 3 | Tối ưu, promote và khóa RTL trước W14 | OPT-02c+05+09+10A đã vào production38 module; NF10M/0 mismatch, F10M kế thừa theo hash và smoke mới;37 strict lint/ModelSim NF/F đạt. A35T100MHz setup/hold đạt3 strategy. Release POSIT_MAC_RTL_20261018_OPT02C đã khóa; W14 final và Gate4 chưa chạy | ✅ |\n'
    if '| 3 | Tối ưu, promote và khóa RTL trước W14 |' not in text:
        end_table = text.find('\n\n', text.index('| 2 |', a))
        text = text[:end_table] + '\n' + entry.rstrip() + text[end_table:]
    write(path,text.rstrip()+'\n')

    banner = '''
## Release production đã khóa — 18/10/2026

`POSIT_MAC_RTL_20261018_OPT02C` (`LOCKED_FOR_W14`),38 module trong `rtl/production.f`.
Gói hiện hành: OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A; không đổi hợp đồng số học/latency.
NF thực hiện R(R(P_hat)+C_eff); F thực hiện R(P_hat+C_eff), với phạm vi/profile ở SPECv1.20.
Trước khi build/chạy W14, từ gốc Posit_MAC:

```powershell
python scripts/audit_rtl_release.py --self-test
```

37 profile strict lint và smoke ModelSim NF/F từ production đã đạt; NF acceptance10M/0 mismatch.
F10M được kế thừa theo hash nguồn của8.28 và có smoke mới; chưa chạy final per-n W14/Gate4.
Xem SPEC§11.17, `rtl/production_freeze.json` và Optimization§8.30.
Các câu “chưa promote” ở hồ sơ có ngày trước18/10 là trạng thái lịch sử.
Producer/audit kiểm hash checkpoint cũ phải dùng snapshot cũ, không sửa hash lịch sử để nhận PASS.
'''
    for rel in ('README.md','rtl/README.md','scripts/README.md','syn/README.md',
                'docs/HUONG_DAN_CHAY_WSL_MODELSIM.md'):
        path = R / rel
        text = path.read_text(encoding='utf-8-sig')
        heading = '## Release production đã khóa — 18/10/2026'
        if heading not in text:
            first, sep, rest = text.partition('\n')
            text = first+'\n'+banner+'\n'+rest
        if rel=='syn/README.md':
            text = text.replace('Không ghép OPT-02b hoặc coi NF này là comparator approximate-only đã nghiệm thu.',
                                'Production18/10 đã ghép OPT-02c/05/09/10A; NF EXACT_EN1 vẫn không phải comparator approximate-only đã nghiệm thu.')
        write(path,text)
    print('Published release report and synchronized current documents; frozen inputs untouched')


if __name__ == '__main__':
    main()
