# Tối ưu hóa nghẽn cổ chai Post-Route của `MAC-F` (`u_core -> u_norm -> u_s1_prepare`) — 13/11/2026

## 1. Bối cảnh và mục tiêu
Ở cấu hình khóa `07/11` (chạy P&R 100 MHz ngày `12/11`), `MAC-F` có Setup WNS nội bộ `reg-to-reg` sau tổng hợp đạt **+4,319 ns** (`176,03 MHz`), nhưng sau Place & Route tụt xuống **+2,768 ns** (`138,27 MHz`, giảm `-1,551 ns`). Nguyên nhân gốc từ `routed.dcp`: chuỗi nối tiếp **3 tầng tổ hợp** giữa nhân và cộng (`core_sf_inc_q / acc_q[25]` (`fo=130`) -> `mul_prepack_norm_comb` -> `posit_add_prepare_comb` với tín hiệu `choose_a` `fo=62` -> `s1_*_q`) bị khuếch đại trễ định tuyến lên `5,170 ns` (`dp = 7,018 ns`).

Thử nghiệm dưới đây cô lập 5 phương án kỹ thuật trong `Posit_MAC/results/f_s1_opt_20261113/` (chưa ghi đè `Posit_MAC/rtl/` hoặc `doc/`):
- **`c1a_split_only`**: Chỉ sửa `posit_add_prepare_comb.sv`, tách tín hiệu điều khiển `choose_a` (`fo=62`) thành 4 nhánh `(* dont_touch = "true" *)` cân bằng theo lát bit `[8:0]`, `[17:9]`, `[25:18]` và metadata. Giữ nguyên `mul_iter_core`, wrapper, số FF và độ trễ (`9+k`).
- **`c1b_key_split`**: Gộp so sánh `(sf, frac)` thành khóa 37-bit `mag_key` + tách 4 nhánh `choose_a`.
- **`c2_prenorm0`**: Đưa `mul_prepack_norm_comb` (`u_norm`) lên thực thi ngay trong chu kỳ cuối tầng L3 (qua `acc_next_o`, `acc_done_next_o`) và chốt vào `product_sf_q[10:0]`, `product_frac_q[25:0]` đúng cạnh clock kết thúc nhân (**0 chu kỳ phụ**), kèm `c1b`.
- **`c2a_prenorm_split`**: Kết hợp **tiền chuẩn hóa L3 không tốn chu kỳ** (`c2`) với **tách fanout `choose_a`** (`c1a`, không dùng chuỗi carry 37-bit của `c1b`).
- **`c3_pipe1`**: Chèn thêm 1 tầng pipeline đăng ký sau `u_norm` trong `mac_f_wrapper.sv` (tăng độ trễ thêm `+1` chu kỳ thành `10+k`).

---

## 2. Kết quả kiểm chứng chức năng (`Verilator` + `ModelSim ASE 10.1d`)

Tất cả 5 phương án đều **PASS 100%**:
- **Verilator strict lint** (`--lint-only --timing --assert -Wall` trên `posit_mac_f`, `posit_mac_nf`, `posit_add_prepare_comb`, `posit_mac_quire`): **PASS** toàn bộ.
- **Đối chiếu bit-exact tổ hợp S1** (`tb_s1_prepare_equiv` so với `posit_add_prepare_comb` khóa `07/11`): **201.764 mẫu biên + ngẫu nhiên, 0 sai khác** trên cả 5 phương án.
- **Mô phỏng hồi quy ModelSim 10.000 vector có backpressure/stall & reset-abort** (`tb_refactored_mac`):
  - `MAC-F` (`vectors/f.txt`, `rows=10000`, `completed=9940`, `aborted=60`, `stalls=36231`): **PASS** toàn bộ (`latency_observed = 12..23` ở 4 phương án 0-chu-kỳ; `13..24` ở `c3_pipe1`).
  - `MAC-NF` (`vectors/nf.txt`, `rows=10000`, `completed=9940`, `aborted=60`, `stalls=36231`, `latency_observed = 15..26`): **PASS** toàn bộ.
- **Đối chiếu trace từng chu kỳ `tb_report_mac_f_trace`**: **PASS** (`accepted=4 retired=3 aborted=1`); riêng `c1a`, `c1b`, `c2_prenorm0`, `c2a_prenorm_split` khớp **từng chu kỳ (100% bit-identical)** với `Posit_MAC/results/report_trace_20261113/trace.csv` (`cycle_exact_trace_match_vs_baseline = true`).

---

## 3. So sánh tổng hợp (`Synth`) và sau định tuyến (`Route`) trên `MAC-F` (`xc7a35tcpg236-1`, OOC `100 MHz`)

*(Nguồn baseline: `Posit_MAC/results/route_nf_f_20261112/f/` và `Posit_MAC/results/route_nf_f_internal_20261113/f_*`)*

| Cấu hình | Chu kỳ trễ F | Synth Toàn mạch WNS (ns) | Synth Nội bộ Reg2Reg WNS (ns) | Synth LUT / FF | Route Toàn mạch WNS (ns) | Route Nội bộ Reg2Reg WNS (ns) | Route Fmax Nội bộ (MHz) | Route LUT / FF | Đường găng nội bộ sau Route |
| :--- | :---: | ---: | ---: | :---: | ---: | ---: | ---: | :---: | :--- |
| **Baseline `07/11`** | `9+k` | +2,689 | +4,319 | 1.235 / 781 | +2,142 | **+2,768** | **138,27** | 1.211 / 781 | `core_sf_inc_q[4] -> u_add/s1_sf_q[1]` (`dp=7,018 ns`) |
| **`c1a_split_only`** | `9+k` (`trace_exact`) | +2,689 | +4,319 | 1.244 / 781 | **+2,247** | **+3,524** (`+0,756`) | **154,42** (`+16,15`) | 1.221 / 781 | `c_frac_q[9] -> u_add/s1_x_frac_q[1]` (`dp=6,321 ns`) |
| **`c1b_key_split`** | `9+k` (`trace_exact`) | +2,689 | +4,181 | 1.245 / 781 | +2,231 | +2,946 (`+0,178`) | 141,76 | 1.221 / 781 | `core_sf_inc_q[1] -> u_add/s1_sf_q[5]` (`dp=6,663 ns`) |
| **`c2_prenorm0`** | `9+k` (`trace_exact`) | +2,689 | +4,319 | 1.274 / 817 | +2,078 | +3,234 (`+0,466`) | 147,80 | 1.251 / 817 | `u_a/p2_frac_q[3] -> u_core/y_q[0]` (`dp=6,254 ns`; S1 `+3,811 ns`) |
| **`c2a_prenorm_split`** | **`9+k` (`trace_exact`)** | +2,689 | +4,319 | 1.272 / 817 | +2,075 | **+3,651** (`+0,883`) | **157,51** (`+19,24`) | 1.247 / 817 | **`u_a/meta_sync2 -> u_b/p1_first_regime_bit_q/CE`** (`dp=5,889 ns`; datapath `fx_q[7]->fx_q[8]` `+3,794 ns`; S1 > `+3,946 ns`) |
| **`c3_pipe1`** | `10+k` (`+1` chu kỳ) | +2,689 | +4,329 | 1.277 / 823 | +1,190 | +3,750 | 160,00 | 1.254 / 823 | `u_core/meta_sync2 -> u_b/p1_payload_seed_q[24]/CE` (đường `in_ready` ra cổng bị tụt còn `+1,190 ns`) |

Mọi lượt P&R đều đạt `setup_fail = 0`, `hold_fail = 0` (`WHS` từ `+0,023` đến `+0,056 ns`), `0` net lỗi định tuyến (`route_status.rpt`: `1818/1818` nets fully routed ở `c2a_prenorm_split`, `1773/1773` ở `c1a_split_only`), DSP = 0, BRAM = 0.

---

## 4. Ảnh hưởng chéo lên `MAC-NF` (`prepack_nf_ppa_top`) do dùng chung `posit_add_prepare_comb.sv`

| Cấu hình `MAC-NF` | Synth Toàn mạch WNS (ns) | Synth Nội bộ Reg2Reg WNS (ns) | Synth LUT / FF | Route Toàn mạch WNS (ns) | Route Nội bộ Reg2Reg WNS (ns) | Route Fmax Nội bộ (MHz) | Route LUT / FF | Đường găng nội bộ sau Route |
| :--- | ---: | ---: | :---: | ---: | ---: | ---: | :---: | :--- |
| **Baseline `07/11`** | +1,843 | +3,435 | 1.582 / 916 | +0,665 | +2,943 | 141,70 | 1.558 / 916 | `u_product_pack/d_q[15] -> product_frac_q[5]` (`dp=6,658 ns`) |
| **`c1a_split_only`** | +1,843 | +3,435 | 1.616 / 916 | **+0,669** | +2,639 | 135,85 | 1.591 / 916 | `u_core/acc_q[20] -> u_product_pack/p1_guard_bit_q` (`dp=7,256 ns`) |
| **`c2a_prenorm_split`** | +1,843 | +3,435 | 1.616 / 916 | **+0,669** | +2,639 | 135,85 | 1.591 / 916 | `u_core/acc_q[20] -> u_product_pack/p1_guard_bit_q` (`dp=7,256 ns`) |

*(Ghi chú: ở `MAC-NF`, phần mở rộng `acc_next_o`/`acc_done_next_o` trong `mul_iter_core` không sử dụng nên bị tối ưu cắt bỏ hoàn toàn — kết quả `c2a_prenorm_split` của NF trùng khít 100% với `c1a_split_only`.)*

---

## 5. Khuyến nghị kỹ thuật trước khi cập nhật `rtl/` và `council.tex`

Hai lựa chọn khả quan nhất (đều **0 chu kỳ trễ phụ**, `trace_exact = true`):
1. **`c2a_prenorm_split` (Khuyến nghị nếu chấp nhận cập nhật hình datapath `MAC-F`):**
   - Triệt tiêu tận gốc nút cổ chai cầu nối `u_core -> u_norm -> u_s1_prepare`: đẩy tầng S1 từ `+2,768 ns` lên **`> +3,946 ns`**, nâng WNS nội bộ sau route lên **`+3,651 ns` (`157,51 MHz`, `+19,24 MHz`)**, độ trễ không đổi (`9+k`), chỉ tăng `+36 LUT / +36 FF` (`1.247 LUT / 817 FF` — vẫn gọn hơn nhiều so với `MAC-NF`).
   - Đường găng nội bộ mới (`meta_sync2 -> in_ready -> CE`) khớp trực tiếp với nhận định sẵn có về hướng phát triển đăng ký `in_ready`.
   - Phần thay đổi datapath `MAC-F` rất rõ ràng để minh họa trên hình báo cáo: khối `u_norm` (`mul_prepack_norm_comb`) chuyển lên nhánh lookahead trước cạnh chốt kết quả của L3 để ghi vào `product_sf_q` / `product_frac_q`.
2. **`c1a_split_only` (Phương án tối giản, giữ nguyên kiến trúc datapath `07/11`):**
   - Chỉ sửa 1 file `posit_add_prepare_comb.sv`, giữ nguyên `mul_iter_core.sv`, mọi wrapper, `0` FF phụ (`+10 LUT`, `1.221 / 781`).
   - Nâng WNS nội bộ sau route lên **`+3,524 ns` (`154,42 MHz`, `+16,15 MHz`)** và WNS toàn mạch lên **`+2,247 ns`**.
   - Nếu không muốn hiệu ứng đặt chỗ phụ làm giảm nhẹ nội bộ `MAC-NF` (`+2,943 -> +2,639 ns`, dù WNS toàn mạch NF vẫn giữ `+0,669 ns`), có thể xem xét tách riêng `posit_add_prepare_comb_split` cho F hoặc giữ `c1a`/`c2a` dùng chung tùy quyết định đồng nhất RTL.
