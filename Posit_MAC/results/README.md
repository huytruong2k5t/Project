# Danh mục bằng chứng thực nghiệm hiện hành — Posit MAC (`RTL 07/11–13/11/2026`)

Thư mục `results/` chỉ giữ lại 17 bộ kết quả đang gắn trực tiếp với RTL cuối cùng, báo cáo tiến độ (`Bao_cao_tien_do_Posit_MAC_20261114.pdf`) và bản thảo hội đồng (`Ban_thao_hoi_dong_Posit_MAC_20261113_datapath.pdf`). Các thư mục `_smoke` và kết quả RTL cũ trước mốc chốt đã được dọn dẹp.

## 1. Kiểm chứng RTL cuối cùng & coverage chức năng / cấu trúc
| Thư mục | Nội dung chính |
|---|---|
| `nf_f_coverage_final/` | Verilator structural coverage trên RTL cuối (NF/F, tổng hợp `coverage_summary.json`, closure functional bins `2.6M`/lõi, bảng waiver). |
| `shared_parser_mul_20261107/` | Hồi quy hỗn hợp `100.000` vector trên RTL khóa mốc `07/11` (shared parser & shared multiplier). |
| `modelsim_subset_cov_20261113/` | Kiểm chứng giao thức, `stall`, `reset` tập trung (`1.500` vector) trên ModelSim. |
| `report_datapath_detectors/` | Kiểm chứng khối LOD và phát hiện regime trên ModelSim (`4.096 + 560` trường hợp). |
| `report_trace_20261113/` | Truy vết dạng sóng theo từng chu kỳ (`FT-05`, `stall`, `reset`). |

## 2. Đánh giá độ chính xác nhân/cộng, chuỗi tích lũy & ứng dụng
| Thư mục | Nội dung chính |
|---|---|
| `mul_prepack_20261112/` | Đo sai số pre-Packer cho bộ nhân `12-bit` (`n = 0..12`, `1.634.048` giao dịch). |
| `paired_mac_20261112/` | So sánh ghép cặp `NF` vs `F` và phân tích triệt tiêu dấu (`377.032` cặp). |
| `paired_mac_20261112_extra/` | Dữ liệu mở rộng và phân rã lỗi chi tiết cho bộ thí nghiệm ghép cặp `NF/F`. |
| `mac_chains_20261112/` | Thực nghiệm `48` chuỗi tích lũy đa chiều dài trên `MAC-NF`, `MAC-F` và `MAC-Quire`. |
| `app_benchmarks/` | Benchmark ứng dụng thực: bộ lọc FIR `32-tap` và tích vô hướng `128-D` (`MAC-F` vs `FP32` vs `Quire`). |

## 3. Tổng hợp FPGA, Route 100 MHz, tối ưu fanout, công suất & đối chiếu Xilinx FP32
| Thư mục | Nội dung chính |
|---|---|
| `restored_f2f_20261106/` | Tổng hợp OOC nền và bảng phân tách độ trễ theo tầng (`F2F`). |
| `quire_opt_20261104/` | Tối ưu backend Quire sang word-bank `36-bit` (`LUT/FF`, so sánh trước/sau). |
| `f_s1_opt_20261113/` | Tối ưu tách fanout tầng `S1` trên `MAC-F`, kiểm chứng tương đương RTL & Synth/Route. |
| `route_nf_f_20261112/` | Kết quả Vivado `route_design` OOC `100 MHz` cho `MAC-NF` và `MAC-F`. |
| `route_nf_f_internal_20261113/` | Kết quả `route` và đường găng nội bộ (`R2R`) trên `MAC-NF` và `MAC-F`. |
| `route_quire_20261113/` | Kết quả Vivado `route_design` OOC `100 MHz` và đường găng trên `MAC-Quire`. |
| `fpga_power_and_fp32/` | Báo cáo công suất (`report_power`) và đối chiếu với Xilinx `Floating-Point FP32` OOC (có DSP & 0 DSP). |
