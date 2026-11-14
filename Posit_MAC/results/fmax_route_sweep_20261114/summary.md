# Tổng hợp xác nhận Fmax bằng lượt route thực (MAC-F & MAC-NF)

- Ngày tạo: 2026-11-14 22:53:19
- Part: `xc7a35tcpg236-1` (Vivado 2026.1, OOC, `-max_dsp 0 -max_bram 0`, `general.maxThreads 4`)
- Thư mục bằng chứng: `results/fmax_route_sweep_20261114`

> **Lưu ý về đường I/O `in_ready`**: Trong chế độ `A` (giữ nguyên ngân sách `input_delay=2,500 ns`, `output_delay=0,500 ns` của hợp đồng A35T-C2 100 MHz), đường từ FF ra cổng tổ hợp `in_ready` có WNS toàn thiết kế (`wns_all`) bị âm khi chu kỳ clock siết xuống dưới ~8 ns. Do vậy, kết luận $F_{\max,\mathrm{R2R}}$ dựa hoàn toàn trên miền nội bộ `reg-to-reg` (`REG2REG_CLK_SETUP` / `REG2REG_CLK_HOLD`), giữ `wns_all` để đối chiếu minh bạch.

## 1. Kết luận Fmax R2R đã kiểm chứng (theo §7)

- **MAC-F (tách S1)**: đạt ở chu kỳ nhỏ nhất **6.500 ns** → **$F_{\max,\mathrm{R2R}}$ đã kiểm chứng = 153.85 MHz** (WNS R2R = `+0.632 ns`, WHS R2R = `+0.043 ns`, đường găng `u_dut/u_wrapper/u_core/acc_q_reg[25]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[5]/D`, `dp=5.728 ns`, `levels=8`; ước lượng tuyến tính từ lượt 10 ns là 154.42 MHz).
- **MAC-NF (tách S1)**: đạt ở chu kỳ nhỏ nhất **7.400 ns** → **$F_{\max,\mathrm{R2R}}$ đã kiểm chứng = 135.14 MHz** (WNS R2R = `+0.209 ns`, WHS R2R = `+0.046 ns`, đường găng `u_dut/u_wrapper/u_product_pack/d_q_reg[0]/C` → `u_dut/u_wrapper/product_frac_q_reg[24]/D`, `dp=6.983 ns`, `levels=6`; ước lượng tuyến tính từ lượt 10 ns là 135.85 MHz).

## 2. Dải dao động WNS R2R ở 10,000 ns qua 3 directive (nhóm P2)

Ghi chú kỹ thuật: trong Vivado 2026.1, `ExtraTimingOpt` là directive của `place_design` nhưng `route_design` không nhận tên này (lỗi `Constraints 18-641`), nên lượt `ExtraTimingOpt` ghép `place_design -directive ExtraTimingOpt` với `route_design -directive NoTimingRelaxation` (theo cặp chiến lược `Performance_ExtraTimingOpt` của UG904).

| Lõi | Default (ns) | Explore (ns) | ExtraTimingOpt (ns) | Min / Median / Max WNS R2R (ns) | Dải Fmax R2R suy ra (MHz) |
|---|---:|---:|---:|---|---|
| MAC-F | +3.524 | +3.524 | +3.184 | +3.184 / +3.524 / +3.524 | 146.71 – 154.42 |
| MAC-NF | +2.639 | +2.994 | +2.965 | +2.639 / +2.965 / +2.994 | 135.85 – 142.73 |

## 3. Chẩn đoán P3 (MAC-F tại 6,500 ns, `io_mode B` bỏ ràng buộc I/O)

- Lượt `f_6p500_B_Default` đạt `LUT=1229`, `FF=781`, `WNS_all = WNS_R2R = +0.182 ns`, `WHS = +0.035 ns`, `unrouted_nets=0` (`pass_r2r = true`).
- Khi loại bỏ áp lực I/O OOC (2,500 ns / 0,500 ns), toàn thiết kế vẫn đóng định thời sạch ở 6,500 ns (`153,85 MHz`), xác nhận `wns_all = -0,513 ns` ở lượt `f_6p500_A_Default` chỉ đến từ đường tổ hợp tới cổng `in_ready`.

## 4. Bảng kết quả chi tiết toàn bộ các lượt chạy

| Nhóm | Lõi | Chu kỳ (ns) | IO | Directive | LUT | FF | WNS toàn TK (ns) | WNS R2R (ns) | WHS R2R (ns) | Levels | Datapath (ns) | Pass R2R | Đường găng R2R (`start -> end`) |
|---|---|---:|---|---|---:|---:|---:|---:|---:|---:|---:|:---:|---|
| P0 | F | 10.000 | A | Default | 1221 | 781 | +2.247 | +3.524 | +0.043 | 7 | 6.321 | PASS | `u_dut/u_wrapper/c_frac_q_reg[9]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[1]/D` |
| P1 | F | 6.500 | A | Default | 1225 | 781 | -0.513 | +0.632 | +0.043 | 8 | 5.728 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[25]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[5]/D` |
| P1 | F | 6.800 | A | Default | 1226 | 781 | -0.119 | +0.431 | +0.033 | 7 | 6.209 | PASS | `u_dut/u_wrapper/c_frac_q_reg[15]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[3]/D` |
| P1 | F | 7.000 | A | Default | 1225 | 781 | +0.045 | +0.281 | +0.042 | 7 | 6.510 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[25]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[6]/D` |
| P1 | NF | 7.400 | A | Default | 1599 | 916 | -0.513 | +0.209 | +0.046 | 6 | 6.983 | PASS | `u_dut/u_wrapper/u_product_pack/d_q_reg[0]/C` → `u_dut/u_wrapper/product_frac_q_reg[24]/D` |
| P1 | NF | 7.700 | A | Default | 1596 | 916 | -0.530 | +1.180 | +0.040 | 5 | 6.379 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[20]/C` → `u_dut/u_wrapper/u_product_pack/p1_guard_bit_q_reg/D` |
| P1 | NF | 8.000 | A | Default | 1595 | 916 | -0.074 | +1.232 | +0.054 | 5 | 6.347 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[23]/C` → `u_dut/u_wrapper/u_product_pack/p1_mag_trunc_q_reg[5]/D` |
| P2 | NF | 10.000 | A | Default | 1591 | 916 | +0.669 | +2.639 | +0.041 | 5 | 7.256 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[20]/C` → `u_dut/u_wrapper/u_product_pack/p1_guard_bit_q_reg/D` |
| P2 | F | 10.000 | A | Explore | 1221 | 781 | +2.247 | +3.524 | +0.043 | 7 | 6.321 | PASS | `u_dut/u_wrapper/c_frac_q_reg[9]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[1]/D` |
| P2 | F | 10.000 | A | ExtraTimingOpt | 1221 | 781 | +1.922 | +3.184 | +0.050 | 6 | 6.703 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[25]/C` → `u_dut/u_wrapper/u_add/s1_x_frac_q_reg[1]/D` |
| P2 | NF | 10.000 | A | Explore | 1591 | 916 | +0.586 | +2.994 | +0.041 | 6 | 6.841 | PASS | `u_dut/u_wrapper/u_product_pack/d_q_reg[13]/C` → `u_dut/u_wrapper/product_frac_q_reg[9]/D` |
| P2 | NF | 10.000 | A | ExtraTimingOpt | 1593 | 916 | +0.537 | +2.965 | +0.040 | 6 | 6.666 | PASS | `u_dut/u_wrapper/u_pack/meta_sync2_reg/C` → `u_dut/u_wrapper/u_c/p1_payload_seed_q_reg[12]/CE` |
| P3 | F | 6.500 | B | Default | 1229 | 781 | +0.182 | +0.182 | +0.035 | 7 | 6.094 | PASS | `u_dut/u_wrapper/u_core/acc_q_reg[25]/C` → `u_dut/u_wrapper/u_add/s1_y_frac_q_reg[0]/D` |

## 5. Kết quả kiểm tra Test Cases (TC-01..TC-08)

| ID | Kiểm tra | Trạng thái | Chi tiết |
|---|---|:---:|---|
| TC-01 | Đóng băng RTL | **PASS** | SHA-256 nguồn khớp 100% trước/sau và khớp .github-publish-Project |
| TC-02 | Tái lập mốc cũ | **PASS** | LUT=1221 (mốc 1221), FF=781 (mốc 781), WNS_R2R=+3.524 ns (mốc +3.524), WNS_all=+2.247 ns (mốc +2.247) |
| TC-03 | Hợp đồng clock | **PASS** | Tất cả 13 lượt đúng period/uncertainty và chỉ có 1 clock 'clk' |
| TC-04 | Route sạch | **PASS** | Tất cả 13 lượt có 0 net chưa route, 0 lỗi định tuyến, 0 lỗi DRC Error |
| TC-05 | Tài nguyên | **PASS** | Tất cả 13 lượt đạt DSP=0, BRAM=0 |
| TC-06 | Hold | **PASS** | Mọi lượt có WHS_all >= 0 và WHS_R2R >= 0 (min WHS_R2R = +0.033 ns) |
| TC-07 | Đủ ma trận P1 | **PASS** | Đủ 6/6 lượt P1 và mọi route_metrics.txt không có dòng EMPTY |
| TC-08 | Bằng chứng | **PASS** | Đủ các file tổng hợp và 247 hash trong manifest khớp 100% |
