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
