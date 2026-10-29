> **Phân biệt nguồn trước khi replay:** đối chiếu Git ngày29/10 phát hiện51/54 file RTL
> và manifest tại máy đã khác commit `c4fe1f7` trước phiên đóng gói;ví dụ F đổi N_MAX8→12.
> Hash manifest hiện tại không trùng hash trong summary release cũ.Vì vậy số10M/0 mismatch
> lịch sử chỉ áp dụng checkpoint Git gốc,không tự áp dụng nguồn hiện tại.
> `manage_rtl_support_archive.py restore` phục hồi các file của **snapshot hiện tại**,không rollback
> mã của bạn về bản gốc.Bản gốc được giữ riêng trong `archive/rtl_release_git_c4fe1f7_20261029.zip`;
> muốn replay đúng bản đã nghiệm thu,cần giải nén checkpoint đó vào thư mục mới và cung cấp
> đúng runtime/dependency theo hướng dẫn lịch sử.Audit hash không thay mô phỏng chức năng.

# Posit MAC — NF và fused

Đồ án chuyên ngành HK261, HCMUT — Đan Huy.
Thiết kế và kiểm chứng IP tính `D = A × B + C_eff`, với bộ nhân lặp,
cấu hình xấp xỉ và hai kiến trúc MAC để so sánh nội bộ.

**Phạm vi chốt22/10/2026: duy nhất posit(32 bit, ES=3)** cho cả NF và F.
Các format khác giữ bằng chứng lịch sử, không thuộc nghiệm thu mới.
**Hợp đồng mục tiêu29/10/2026:** approximate FW12,**FULL_TERM không FLOOR**,giữ đủ
tích26 bit/Q24,cfg_n0..12,OPS0/1,RNE ở packer theo NF/F. Chi tiết bắt buộc ở
[SPEC §4.3](SPEC_Posit_MAC_IP.md#full-term-contract).
F giữ mục tiêu W32/Q29 nhưng cần nghiệm thu lại với prepack26 bit.
RTL production hiện đã cố định32/3:54 module không còn public parameter,
cổng có độ rộng literal; build không truyền NB/ES hoặc feature override.
Exact32/3 vẫn theo AC02 với oracle độc lập; không dùng SoftPosit ES2 làm chuẩn.

## 1. Bản dùng hiện tại

**Chưa chuyển đổi số học:** RTL,L1 thực thi,testbench và runner dưới đây vẫn là
FLOOR/n≤8. Sinh viên tự sửa RTL/testbench;phiên29/10 chỉ chốt hợp đồng/tài liệu.
Không dùng PASS,accuracy hoặc timing cũ để kết luận FULL_TERM đã chạy đúng.
Freeze/manifest nguồn cũ giữ nguyên;chỉ tạo release mới sau khi có kiểm chứng mới.

Release đã khóa chức năng: **`POSIT_MAC_RTL_20261022_FIXED32_3`** (`FIXED32_3_FUNCTION_VERIFIED`).
Cây MAC hiện hữu dùng [`rtl/mac_active.f`](rtl/mac_active.f),46 module.
[`rtl/production.f`](rtl/production.f) giữ danh sách54 module của checkpoint cũ;
chạy `python3 -B scripts/manage_rtl_support_archive.py restore` trước runner/Makefile release54.
8 module hỗ trợ và candidate/research/benchmark đã nén ngoài rtl;
xem [`kho lưu trữ/cách phục hồi`](archive/README.md).
Kiểm bố cục hiện tại bằng `python3 -B scripts/manage_rtl_support_archive.py audit`.
Thông tin khóa nguồn ở [`rtl/production_freeze.json`](rtl/production_freeze.json).

NF/F mỗi bản10M completed/0 mismatch,740k so sánh trên37 biến thể tổ hợp,
ModelSim36.056 giao dịch hoàn tất/0 mismatch và54 strict lint đạt.
Xem [`kết quả fixed32/3`](results/fixed32_3_20261022/summary.json) và
[`hướng dẫn tái chạy`](docs/HUONG_DAN_CHAY_WSL_MODELSIM.md).
NF vẫn nhận exact/approx qua cfg_mode; F approximate-only. Hằng feature đã khóa,
không truyền tham số vào DUT. AC02 exact>=100M,final per-n/AC04 và STA/PPA mới
chưa được nghiệm thu bằng lượt aggregate này.

Gói đã chọn gồm OPT-02c, OPT-05 abc_tree, OPT-09, OPT-10A và OPT-12.
Các bản candidate đã chuyển vào `archive/rtl_support_20261029.zip`; mã chạy chính nằm ở
các thư mục chức năng của `rtl/`. Không compile đệ quy toàn bộ RTL vì có tên module trùng.

Kết quả OOC lịch sử của release OPT12, chưa đo lại trên fixed32/3: Artix-7 `xc7a35tcpg236-1`, Explore, chu kỳ 8,3 ns
(khoảng 120,48 MHz):

| Top | Setup WNS | Hold WHS |
| --- | ---: | ---: |
| NF | +0,227 ns | +0,053 ns |
| Fused | +0,093 ns | +0,040 ns |

Giữ input min/max 2,5 ns, output min 0/max 0,5 ns và uncertainty 0,1 ns.
Recipe: [`syn/opt12_120mhz_release.json`](syn/opt12_120mhz_release.json).
Đây là kết quả theo profile OOC đã công bố, chưa phải phép đo trên kit hoặc Fmax cực đại.

W14-01..11 đã hoàn tất trong phạm vi ghi ở
[`results/week14/handoff.json`](results/week14/handoff.json):
350 triệu giao dịch RTL hoàn tất, 0 mismatch; AC04 của profile chính và
9 triệu mẫu accuracy paired standalone đã được báo cáo.
W14-12/exact AC02 hoãn riêng; structural coverage của EX0 chưa được tuyên bố đóng.
Paired PPA NF/F và board signoff vẫn còn mở.

**Ứng viên riêng OPT-15 (19/10):** chia sẻ parser A/C và packer tích/tổng trong NF,
LUT 2.424→2.104, FF 931→806, giữ lịch giao dịch và qua STA 120,48 MHz trong một run Explore.
11,08 triệu completed/bản, 0 mismatch; chưa promote, không thay release đã khóa.
Đã chọn OPT-15 làm nền tối ưu tiếp cho NF/F: NF dùng `combined`.
Ngày20/10,F có hai candidate riêng: OPT-15 parser2 giữ F1–F5 và OPT-16 parser2
dùng bộ cộng NF ba tầng,cùng một packer cuối. Cả hai đạt10,1M completed/bản,
ModelSim và một run A35T120,48MHz;chưa promote. Xem [Optimization8.36](../doc/Optimization.md)
và [bản đồ nguồn JSON](rtl/candidates/opt15_sources.json);LUT/FF/latency có đánh đổi khác nhau.
Xem [Optimization §8.35](../doc/Optimization.md#835-opt-15--chia-sẻ-parserpacker-để-giảm-lut-nf--19102026)
và [báo cáo ứng viên](results/opt15_share_20261019/summary.json).

## 2. Bản đồ thư mục sau dọn — 19/10/2026

| Thư mục | Mục đích |
| --- | --- |
| [`rtl/`](rtl/README.md) | RTL production theo chức năng; file list và khóa nguồn |
| [`rtl/candidates/`](rtl/candidates/README.md) | 9 file snapshot của gói đã chọn, dùng đối chiếu khi cần |
| [`archive/`](archive/README.md) | Kho nén 23 file ứng viên cũ đã bỏ khỏi cây làm việc, có danh mục/hash/cách phục hồi |
| [`l0/`](l0/README.md) | Wrapper và thư viện SoftPosit/oracle |
| [`l1/`](l1/README.md) | Mô hình thuật toán và công cụ sinh vector |
| [`tb/`](tb/README.md), [`tests/`](tests/README.md) | Testbench, harness và dữ liệu kiểm thử |
| [`scripts/`](scripts/README.md) | Runner kiểm chứng, audit, tổng hợp và thu thập báo cáo |
| [`syn/`](syn/README.md) | Luồng Vivado, recipe và constraints; A35T là mục tiêu chính |
| [`results/`](results/README.md) | Kết quả 120 MHz, W14 và bằng chứng lịch sử giữ nguyên đường dẫn |
| [`docs/`](docs/README.md) | Tiến độ, hướng dẫn chạy và tài liệu chi tiết |
| `presentation/` | PowerPoint và nguồn dựng slide; sản phẩm MAC NF/F trong `MAC_NF_F_RTL_DATAPATH/` |
| `scratch/` | Dữ liệu làm việc và checkout sao lưu Git riêng; không phải nguồn production |
| [`asic/`](asic/README.md) | Luồng ASIC tham khảo |

Các PDF tham khảo, SPEC và guideline giữ nguyên vị trí để không làm hỏng đường dẫn.
Không đổi vị trí RTL production, L0/L1, testbench, runner, constraints hoặc kết quả nghiệm thu.

Các phương án thử cũ như OPT-02b, prepack OPT-01, SAC a/ab/abc_sub và
primitive thay thế được lưu tại [`archive/`](archive/README.md).
Giữ các báo cáo đo cũ để giải thích việc chọn kiến trúc, kể cả kết quả dưới 120 MHz.
Các runner lịch sử cần nguồn đã lưu trữ phải phục hồi archive trước khi chạy;
runner production dùng file list hiện hành.

## 3. Tài liệu cần đọc

- [Đặc tả IP](SPEC_Posit_MAC_IP.md).
- [Digital Design Guidelines](Digital_Design_Guidelines.md).
- [Kế hoạch và cách build L1/NF/F](l1/PLAN.md).
- [Tiến độ đồ án](docs/TIEN_DO_DO_AN.md).
- [Optimization — quyết định tối ưu và kết quả STA](../doc/Optimization.md).
- [Hướng dẫn WSL và ModelSim](docs/HUONG_DAN_CHAY_WSL_MODELSIM.md).

NF làm tròn tích trước phép cộng;fused cộng cùng P_hat FULL_TERM với `C_eff`
trước RNE cuối. Code hiện tại còn P_hat FLOOR;hợp đồng mới không phải exact của
fraction Posit26 bit và không phải quire tích lũy cả chuỗi chỉ làm tròn một lần.
Provenance và Table I của paper là nghiên cứu phụ, chưa được coi là baseline tác giả đã xác nhận.

## 4. Lệnh kiểm tra khi cần chạy lại

Từ gốc `Posit_MAC`, trong môi trường đã cài công cụ:

```sh
python3 scripts/audit_rtl_release.py --self-test
verilator --lint-only --timing --assert -Wall -Irtl --top-module posit_mac_f -f rtl/production.f
```

Đây là hướng dẫn, không phải các lệnh đã chạy trong phiên dọn thư mục này.
Cache biên dịch W14 đã được dọn; trước khi replay regression phải build lại theo runner tương ứng.
Giữ fixture, log, raw coverage, hash và archive bằng chứng. File thiếu không được coi là PASS.

## 5. Phạm vi phiên dọn

Ngày 19/10/2026: chỉ cập nhật README, lưu trữ ứng viên đã ngừng dùng và xóa
920 file cache có thể tạo lại, giải phóng khoảng **1.204,85 MiB**.
Danh mục và xác minh toàn vẹn ở [`archive/README.md`](archive/README.md).
Không sửa nội dung mã nguồn, SPEC, PLAN, constraints hoặc báo cáo.
Không chạy lại mô phỏng, synthesis, STA; không commit hoặc push GitHub.
