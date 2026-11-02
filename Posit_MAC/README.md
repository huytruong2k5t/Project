## Dọn dẹp RTL/results — 02/11/2026

RTL hiện có **31 module MAC**, **8 module reference** ngoài DUT. NF/F dùng chung một thiết kế bộ nhân FULL_TERM26/Q24; bỏ đường exact và `cfg_mode`. Nguồn trước sửa được bảo toàn trong [ZIP có hash](archive/shared_multiplier_before_20261102.zip). Số6.602ns/1265LUT/820FF thuộc snapshot FLOOR cũ, chưa đo PPA nguồn mới.

[Kết quả hiện dùng](results/README.md) · [Biên bản](docs/DON_DEP_RTL_RESULTS_20261102.md) · [Archive và phục hồi](archive/cleanup_20261102/INDEX.md).

Các mục lịch sử bên dưới giữ ngày/scope của snapshot tương ứng; đường dẫn cũ đã archive cần restore trước khi replay.

---

# Posit MAC — NF và fused

Đồ án chuyên ngành HK261, HCMUT — Đan Huy. Thiết kế SystemVerilog cho `D = A × B + C_eff`, duy nhất **Posit(32,3)**; NF là baseline nội bộ để so sánh với F. NF làm tròn tích trước cộng; F cộng tích trước pack rồi RNE đầu ra. Tích lũy hiện lưu kết quả Posit đã làm tròn mỗi giao dịch, không phải quire.

## 1. Hợp đồng mục tiêu và mã đang làm việc

| Nội dung | Trạng thái |
| --- | --- |
| Hợp đồng | [SPEC v1.27](SPEC_Posit_MAC_IP.md): approximate-only, fraction đầu vào12 bit, **FULL_TERM26/Q24**, n0..12, OPS0/1 (mặc định **OPS1/n12**), RNE |
| Nguồn hiện tại | Cả NF/F dùng `ops_sel_comb`, `mul_iter_core`, `mul_prepack_norm_comb` chung; không cfg_mode/exact/FLOOR từng term. Đây là dùng chung mã kiến trúc, không chia sẻ một instance giữa hai top chạy đồng thời |
| File list đang dùng | [`rtl/mac_active.f`](rtl/mac_active.f), **31 module**; không compile đệ quy toàn bộ RTL |
| Kiến trúc hiện tại | Parser2, multiplier26/Q24, adder5 và Packer RNE2. NF RNE tích trước cộng; F giữ frac26 không RNE trung gian. F giữ parser riêng `posit_parser_f` |
| Nguồn lịch sử | [`rtl/production.f`](rtl/production.f)54 module và [`production_freeze.json`](rtl/production_freeze.json) thuộc checkpoint cũ; không dùng PASS cũ để nghiệm thu cây hiện tại |

Golden Posit32/ES3 dùng oracle số nguyên độc lập theo SPEC §6.1; **SoftPosit p32/ES2 không thay được oracle32/3**. Model FULL_TERM, Python fixture và checkpoint đã đối chiếu; nhánh phần mềm lịch sử không phải chế độ DUT. Độ rộng RTL cố định, không truyền NB/ES hoặc feature override vào DUT.

## 2. Bằng chứng quan trọng và giới hạn

Mỗi PASS/số đo chỉ áp dụng đúng nguồn, manifest và recipe của lượt chạy đó.

| Mốc | Kết quả được lưu | Giới hạn / nơi đối chiếu |
| --- | --- | --- |
| Shared FULL_TERM02/11 | **143934016** so sánh unit; **7.2M MAC completed/0 mismatch** gồm52 điểm×100k và default1M mỗi NF/F. ModelSim mỗi bản29820 completed+180 aborted,core53249 case;31 strict lint,68 instance đủ cổng | [Summary/source guard](results/shared_multiplier_20261102/summary.json). Đủ10 mã cờ NF/8 mã F trên hợp pilot; không exhaustive toàn MAC. Main520M và AC04 còn mở |
| F `p00`,01/11 | A35T OOC synthesis10ns: F2F **7.697→6.602ns**, LUT1374→1265, FF820; regression50k accepted, parser4M magnitude, LOD500063 và streaming PASS | Vẫn FLOOR/Q12; accepted gồm reset-aborted. Chưa route, WHS−0.055ns; F2F không phải Fmax. [Báo cáo và lệnh chạy](results/f_timing_optimization_20261101/summary.md) |
| Refactor31/10–01/11 | Adder5 tầng39.534 completed; packer10.692 completed; MAC NF/F mỗi bản4.970 completed +30 aborted;0 mismatch | Kiểm tương đương của các snapshot refactor; chi tiết trong bản README lưu trữ ở §5, không tự áp dụng mọi thay đổi sau đó |
| OPT-17 FULL_TERM | Candidate2P NF/F mỗi bản10M completed/0 mismatch; golden2.053.248 checks; ModelSim mỗi bản8.192 completed/0 mismatch | **Chưa promote**; parent thay đổi trong lúc chạy, benchmark/matched PPA còn thiếu. [Summary](results/opt17_20261029/summary.json) |
| Fixed32/3,22–23/10 | NF10M + F10M completed/0 mismatch;740k kiểm tổ hợp; ModelSim36.056 completed/0 mismatch;54 strict lint | Release `POSIT_MAC_RTL_20261022_FIXED32_3`; chỉ checkpoint gốc, không nguồn refactor. [Summary](results/fixed32_3_20261022/summary.json) |
| W14 / OPT12 lịch sử | W14 aggregate350M/0 mismatch và9M accuracy paired; OPT12 A35T OOC8.3ns≈120.48MHz, NF WNS/WHS+0.227/+0.053ns, F+0.093/+0.040ns | Theo nguồn cũ, chưa phải board/Fmax hay STA nguồn hiện tại. [Handoff](results/week14/handoff.json), [recipe/constraints](syn/opt12_120mhz_release.json) |

Ứng viên OPT-15/16 chia sẻ parser/packer và các lựa chọn tối ưu cũ vẫn được giữ để đối chiếu tại [Optimization](../doc/Optimization.md), [kết quả](results/README.md) và [archive](archive/README.md); chưa mặc định là release đã promote. Provenance/Table I của paper vẫn là nghiên cứu phụ, chưa xác nhận baseline tác giả.

## 3. Công việc còn mở

Hợp đồng [MAC quire mở rộng](SPEC_Posit_MAC_IP.md#mac-quire-extension) đã được bổ sung: dùng cùng prepack FULL_TERM, tổng rộng không làm tròn từng MAC, RNE khi READ. Chưa triển khai/nghiệm thu quire; width và chiều dài chuỗi phải khóa riêng. Xem §5 và §6.9 của SPEC cho cấu trúc khối/testbench mới.

- Bổ sung kiểm đích cho coverage nhánh/line: NF96.05/89.13/93.67%, F76.06/89.74/93.11% (line/branch/toggle); chưa áp waiver RTL.
- Nghiệm thu **52 điểm NF/F×OPS×n**, mỗi điểm≥10M completed cùng coverage theo SPEC §6.7. Regression nhỏ/aggregate cũ không thay ma trận này.
- Đo matched PPA NF/F cùng điều kiện; đóng setup/hold sau route và kiểm trên board nếu thực hiện. Không suy Fmax từ F2F synthesis.
- Exact hardware/AC02 exact đã rút khỏi mục tiêu; các mốc exact chưa hoàn tất trước đây chỉ còn ý nghĩa lịch sử.

## 4. Tài liệu, thư mục và cách chạy

- [SPEC](SPEC_Posit_MAC_IP.md), [Digital Design Guidelines](Digital_Design_Guidelines.md): hợp đồng và quy tắc thiết kế.
- [PLAN](l1/PLAN.md), [tiến độ](docs/TIEN_DO_DO_AN.md), [Optimization](../doc/Optimization.md): kế hoạch, trạng thái và quyết định tối ưu.
- [Hướng dẫn WSL/ModelSim](docs/HUONG_DAN_CHAY_WSL_MODELSIM.md): build/replay; chọn đúng snapshot và dependency. Cache đã dọn phải build lại, file thiếu không phải PASS.

| Thư mục | Nội dung |
| --- | --- |
| `rtl/` | RTL theo chức năng, active file list và manifest lịch sử |
| `l0/`, `l1/` | Reference/oracle, mô hình thuật toán và sinh vector |
| `tb/`, `tests/`, `scripts/` | Testbench, harness, runner, audit và thu thập báo cáo |
| `syn/`, `results/` | Vivado/constraints, snapshot nguồn và bằng chứng kiểm chứng |
| `experiments/`, `archive/` | Candidate riêng và gói nguồn lịch sử có hash |
| `docs/`, `presentation/` | Tài liệu và PowerPoint; PDF tham khảo ở gốc dự án |
| `scratch/`, `asic/` | Dữ liệu làm việc/checkout sao lưu và luồng ASIC tham khảo ngoài mục tiêu hiện tại |

Ví dụ lint từ gốc `Posit_MAC` trong WSL đã có Verilator:

```sh
verilator --lint-only --timing --assert -Wall -Irtl --top-module posit_mac_f -f rtl/mac_active.f
verilator --lint-only --timing --assert -Wall -Irtl --top-module posit_mac_nf -f rtl/mac_active.f
```

Luồng mới: `make lint`, `SHARED_BUILD_TAG=<mới> make build`, `make smoke FIXED_RUN=<mới>`, `make regress FIXED_RUN=<mới>` (pilot100k/điểm). Main dùng thêm `SHARED_COUNT=10000000`; chưa chạy main trong phiên này. [Hướng dẫn](docs/HUONG_DAN_CHAY_WSL_MODELSIM.md) có lệnh ModelSim và coverage. Không trộn runner release54 với nguồn31.

## 5. Bảo toàn lịch sử và phục hồi

README được rút gọn ngày02/11/2026. **Toàn bộ bản trước khi rút gọn** (33.622 byte), gồm chi tiết OPS/SAC/SBM, adder5 tầng, packer/parser, lệnh và các mốc tối ưu, được giữ nguyên byte tại [readme_before_condense_20261102.zip](archive/readme_before_condense_20261102.zip). Trong ZIP có `README.md` và `MANIFEST.json`; SHA256 bản gốc: `b4a6aa0a4c26f42454511bea9f0c1d44804251a18eeedb598a31d4204306fbe5`.

[Archive README](archive/README.md) giải thích kho hỗ trợ và phục hồi. `manage_rtl_support_archive.py restore` chỉ phục hồi các file đã lưu của snapshot đó, **không rollback cây hiện tại về release gốc**. Checkpoint Git gốc được giữ riêng ở [rtl_release_git_c4fe1f7_20261029.zip](archive/rtl_release_git_c4fe1f7_20261029.zip); replay trong thư mục mới với đúng runtime/dependency, không giải nén đè cây đang sửa. Audit hash không thay mô phỏng chức năng.
