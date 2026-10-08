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

Git không có checkout: push chưa thực hiện; không tự init, thay remote, force hoặc sửa thư mục khác. Nguồn + hash được lưu local, không gọi đó là GitHub backup.
