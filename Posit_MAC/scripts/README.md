# Thư mục Kịch bản Bổ trợ (`scripts/`)

Thư mục này chứa các kịch bản tự động hóa Python và shell script phục vụ kiểm chứng bit-accurate độc lập, tổng hợp PPA và xử lý đồ thị báo cáo đồ án.

---

## 1. Kịch bản Kiểm chứng Thuật toán & Module (Bit-Accurate Verification)

Các kịch bản này mô phỏng độc lập phần cứng ở cấp độ bit, cho phép xác minh tính đúng đắn 100% của giải thuật mà không cần cài đặt các bộ mô phỏng thương mại cồng kềnh:

| File Kịch bản | Module Kiểm chứng | Số lượng Vector đã xác nhận | Cách chạy |
|:---|:---|:---:|:---|
| [`verify_dyn_left_shifter.py`](verify_dyn_left_shifter.py) | [`dyn_left_shifter.sv`](../rtl/dyn_left_shifter.sv) | **60,832 vectors (100% Pass)** | `python scripts/verify_dyn_left_shifter.py` |
| [`verify_dyn_right_shifter.py`](verify_dyn_right_shifter.py) | [`dyn_right_shifter.sv`](../rtl/dyn_right_shifter.sv) | **146,400 vectors (100% Pass)** | `python scripts/verify_dyn_right_shifter.py` |

---

## 2. Kịch bản Xử lý Kết quả & Báo cáo PPA (§7 SPEC)

Các kịch bản phục vụ trích xuất dữ liệu tự động từ các log công cụ (Vivado / OpenROAD) để bảo đảm tiêu chí tái lập **AC-07** (`make all`):

- **`collect_ppa.py`**:
  - Tự động đọc các file log tổng hợp (`utilization.rpt`, `timing.rpt`, `power.rpt`) từ Vivado và OpenROAD.
  - Trích xuất các chỉ số: LUT, FF, CARRY, DSP, BRAM, WNS, $f_{\max}$, công suất tiêu thụ.
  - Tự động tính toán các chỉ số dẫn xuất: Throughput (Mops/s), Mops/s trên mỗi LUT, tích Diện tích $\times$ Trễ.
  - Xuất bảng kết quả tổng hợp ra [`results/ppa.csv`](../results/README.md) và [`results/ppa.md`](../results/README.md).

- **`plot_error.py`**:
  - Đọc file CSV kiểm tra hồi quy từ tầng L1/RTL.
  - Vẽ biểu đồ sai số Error Rate (%) và NMSE theo từng số vòng lặp $n \in \{1, 2, 3, 4, 5, 6, 8\}$ và theo từng nhóm regime $G_1 \dots G_8$.
  - Xuất biểu đồ đồ thị dưới định dạng vector (`.svg`) và hình ảnh (`.png`) chất lượng cao để chèn vào báo cáo đồ án.

- **`plot_pareto.py`**:
  - Dành cho mục mở rộng DSE (EXT-B).
  - Vẽ không gian thiết kế Pareto tối ưu giữa Diện tích (LUT) $\times$ Trễ (chu kỳ) $\times$ Độ chính xác (NMSE) để khuyến nghị cấu hình phần cứng tối ưu.

## 3. Kiểm chứng và khảo sát packer tuần8

- [`verify_packer_modelsim.ps1`](verify_packer_modelsim.ps1): sinh fixture bằng L1 và encoder bit-list độc lập, kiểm packer tổ hợp/pipeline và chuỗi parser→packer trên ModelSim. Chạy từ thư mục `Posit_MAC`: `./scripts/verify_packer_modelsim.ps1`; dùng `-CollectExisting` để kiểm lại hash và tổng kết log đã có. Kết quả ở `results/packer/summary.json`.
- [`run_packer_ppa.ps1`](run_packer_ppa.ps1): đo RNE/TRUNC trên Quartus, Cyclone IV EP4CE22F17C6, cùng biên thanh ghi vào/ra, seed 1/2/3 và clock 10ns. Kết quả ở `results/packer_ppa/summary.json`; đây là benchmark packer riêng, chưa nghiệm thu timing/PPA toàn MAC. Hướng dẫn và giới hạn ở `rtl/README.md` mục6.

- [`verify_packer_p2_equivalence.ps1`](verify_packer_p2_equivalence.ps1): đối chiếu P2 mới với bản trước tối ưu, 1.448.576 lượt, cả RNE/TRUNC. NB8 vét cạn toàn bundle nhị phân, NB16/32 dùng seed20261007+NB. Tham chiếu nằm trong `results/packer_p2_optimization/`; `comparison.json` so tài nguyên/timing trước–sau, baseline được giữ riêng. Đây là kiểm tương đương, không thay thế oracle L1/bit-list của suite packer.

## 4. Khởi động tuần9

- [`verify_week9_frontend_modelsim.ps1`](verify_week9_frontend_modelsim.ps1): build trước `make -C l1 gen_week9_frontend.exe`, rồi chạy từ Posit_MAC. Sinh fixture Windows, compile/mô phỏng OPS/SAC tổ hợp, kiểm10 marker/count và ghi log/hash tại `results/week9_frontend/windows`.
- [`summarize_week9_frontend.py`](summarize_week9_frontend.py): chạy generator Linux và UBSan trước; so fixture với Windows, xác nhận327.440 dòng kiểm và log không warning/error, ghi `results/week9_frontend/summary.json`. Không dùng summary này nghiệm thu Gate2 hoặc baseline gốc của paper.

## 5. Kiểm chứng tuần9 và giới hạn quyền

Chạy từ Posit_MAC: `verify_week9_arithmetic_modelsim.ps1`, `verify_week9_paper_modelsim.ps1`, `verify_week9_core_modelsim.ps1`; integrated pilot: `verify_week9_multiplier_modelsim.ps1 -PerProfile 2000 -RunName final_pilot`. Lượt lớn: `-PerProfile 630000 -RunName acceptance`; script chỉ đóng ngưỡng số học khi số giao dịch hoàn tất đạt10⁷, không tính reset-abort.

`summarize_week9_implementation.py` kiểm fixture Linux/Windows/UBSan, coverage và hash. `update_week9_status.py` chỉ sửa Markdown hiện có, không tạo Markdown mới. `verify_week9_verilator.sh` chỉ dùng tool đã cài, trả BLOCKED khi thiếu, không sudo/download/install. Mọi file build/log/work/temp đặt dưới Posit_MAC. Quyền cập nhật ngoài dự án chỉ dành đúng doc/TIEN_DO_DO_AN.md.

GitHub đã push checkpoint 0ae39c4 lên main bằng checkout riêng trong Posit_MAC; kết quả lượt lớn được bổ sung cuối phiên.

Lượt phân tầng cuối đạt16.815.920 giao dịch hoàn tất,80.080 reset hủy; control random-bit đạt10.032.224 giao dịch,47.776 reset hủy; cả hai0 mismatch. Audit đối chiếu SHA fixture với log PASS và loại reset-abort trước coverage:16 profile đầy đủ, posit32 đạt256/256 bin regime–dấu, tối thiểu4.104 mẫu/bin và26.241 operands mỗi run/polarity hữu hạn;36 ô mode/OPS/n mỗi profile. Code coverage line/branch/toggle chưa đo.

Corner riêng đạt114.656 so sánh/544 reset hủy,3600 trường hợp khác nhau mỗi profile (100 cặp ×36 config), gồm ±1, ±minpos/maxpos và NaR×0/0×NaR; Linux/Windows/UBSan và replay32.000 dòng uniform cũ khớp. Pilot stall96 chu kỳ đạt31.840 so sánh/160 reset,336 lượt giữ dài;0 mismatch. Chỉ chỉnh khoảng trắng RTL để tách port/parameter, có proof và pilot biên dịch lại; SHA nguồn trước/sau lưu riêng. Logic không đổi, TableI không chạy lại.

Gate2/W9-06 vẫn processing: Verilator chưa có, harness C++ và lint chính thức chưa build/chạy. Không tự cài công cụ hoặc thay tiêu chí. Bằng chứng: results/week9_multiplier/{stratified_acceptance,acceptance_parallel,corners_final_rtl,long_stall_pilot}; snapshot/version/seed/lệnh tại results/week9_implementation/summary.json.

## 6. Tái chạy top paper tự hồi tiếp — 09/10/2026

`paper_mul_iter`/`paper_mul_wrapper`/`paper_norm_comb` đã tự chạy từ A/B đến kết quả; ModelSim17.181 giao dịch và65.710 commit đạt0 mismatch,843 commit corpus cũ giữ nguyên, Fig.4=0x1ae34000. Linux/Windows/UBSan fixture MATCH; reset/stall/context/early-stop/special đạt trong suite. Hợp đồng research cố định posit32ES3/Q12, n_terms1..8, outputTRUNC; chi tiết PLAN L1 §7.5 và results/paper_top/{windows/summary,audit}.json. Không có nguồn mới hoặc thay đổi số học nên không chạy TableI; provenance baseline gốc và Gate2 vẫn processing.

Trong WSL không nạp profile, cd vào Posit_MAC, đặt TMPDIR trong results/paper_top/tmp rồi make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan. Sinh fixture Linux/UBSan theo lệnh trong audit.json; PowerShell chạy scripts/verify_paper_top_modelsim.ps1, tiếp đó chạy scripts/audit_paper_top.py bằng Python có sẵn. ModelSim work/transcript/log/wave/temp đều ở results/paper_top; compiler timescale1ns/1ps nằm ở lệnh vlog. Không cài/sửa công cụ hệ thống.
