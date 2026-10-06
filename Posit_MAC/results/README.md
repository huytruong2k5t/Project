# Thư mục Kết quả Tự động (`results/`)

Thư mục này chứa toàn bộ các file báo cáo, bảng số liệu PPA, log hồi quy và biểu đồ thống kê được sinh tự động bởi các lệnh `make regress`, `make ppa`, `make cov`, và `make all`.

---

## 1. Danh mục Tệp Đầu ra

| Tên Tệp | Định dạng | Nội dung và Ý nghĩa | Nguồn sinh |
|:---|:---:|:---|:---|
| `ppa.csv` | CSV | Bảng số liệu PPA thô gồm: LUT, FF, CARRY, DSP, BRAM, WNS, fmax, độ trễ, throughput (Mops/s), Mops/s/LUT, tích Diện tích $\times$ Trễ. | `scripts/collect_ppa.py` |
| `ppa.md` | Markdown | Bảng PPA đã định dạng kèm so sánh tỉ lệ $R_{\text{LUT}}, R_{f_{\max}}$ với bài báo [P], PACoGen và Floating-Point MAC theo §7. | `scripts/collect_ppa.py` |
| `summary.md` | Markdown | Tóm tắt kết quả kiểm tra hồi quy: số lượng vector đã chạy, tỉ lệ đạt (100% Pass), phân bố số vòng lặp thực tế, thống kê sai số (Error Rate, NMSE, MaxErr). | `tb/verilator/` |
| `corner.log` | Text Log | Báo cáo chi tiết kiểm định Bit-exact toàn bộ 40 trường hợp Corner (§6.4) và TV-RND (§3.4) với SoftPosit. | `l0/test_softposit_corners.py` |
| `fail_*.log` | Text Log | Tự động ghi lại chi tiết `(a, b, c, cfg, got, exp)` nếu phát sinh mismatch trong quá trình hồi quy để phục vụ gỡ lỗi. | Testbench |
| `error_vs_n.svg` / `.png` | Vector / Image | Biểu đồ sai số tương đối (Error Rate) theo số vòng lặp $n$ và theo 8 nhóm regime $G_1 \dots G_8$. | `scripts/plot_error.py` |
| `pareto_dse.svg` / `.png` | Vector / Image | Đồ thị Pareto khảo sát không gian thiết kế (DSE - EXT-B) giữa LUT $\times$ Trễ $\times$ NMSE. | `scripts/plot_pareto.py` |

---

## 2. Tiêu chuẩn Tái lập Dữ liệu (Reproducibility - AC-07)

- Toàn bộ nội dung trong thư mục này được quản lý tự động.
- Chạy lệnh `make clean && make all` từ thư mục gốc của repository sẽ tự động xóa sạch và tái lập 100% các bảng số liệu và biểu đồ mà không cần bất kỳ can thiệp thủ công nào.
