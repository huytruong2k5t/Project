# RTL Architecture & Refactoring Changelog

## [2026-11-06] - Khôi phục `g_sticky_mask` song song tại Packer Stage P1 & Giữ nguyên tối ưu hóa `clear_val` ở Adder Stage S5

### 1. Mục đích & Bối cảnh Thực nghiệm Tổng hợp (Post-Synthesis Benchmark Insights)
Sau khi chạy tổng hợp thực tế trên Vivado (`xc7z020clg484-1`, Out-Of-Context `synth_design`) và đo đạc timing từng tầng pipeline (`results/refactor_lut_20261106/summary.md`), chúng ta thu được 2 kết quả đối lập rất rõ ràng giữa 2 thay đổi:

1. **Tối ưu hóa loại bỏ `clear_val` tại Adder Stage S5 (`posit_add_norm_comb.sv`) — THÀNH CÔNG RỰC RỠ:**
   - **Tài nguyên LUTs:** Giảm từ `487 -> 455 LUTs` (**-32 LUTs**) trên `posit_mac_nf` và từ `410 -> 389 LUTs` (**-21 LUTs**) trên `posit_mac_f`.
   - **Timing F2F (`adder_s5`):** Giảm từ **`3.924 ns -> 3.616 ns`** (**-0.308 ns**) trên cả 2 kiến trúc NF và F nhờ cắt bỏ hoàn toàn 1 tầng MUX 2:1 (41 bit) ở cuối bộ dịch chuẩn hóa `dyn_left_shifter_fixed6` và bộ trừ `sf_raw`.
   - **Quyết định:** **Giữ nguyên vĩnh viễn** thiết kế lược bỏ `clear_val` trong `posit_add_norm_comb.sv`.

2. **Thử nghiệm gộp `sticky_drop` nối tiếp theo tầng trong `dyn_right_shifter_fixed2.sv` — GÂY SUY GIẢM TIMING F2F:**
   - Mặc dù giúp giảm nhẹ ~8 LUT ở `posit_product_pack`, cách gom `sticky_drop = drop0 | drop1 | drop2 | drop3 | drop4` dọc theo các tầng dịch lại làm đường găng `final_pack_p1` tăng từ **`4.249 ns -> 5.884 ns`** (+1.635 ns) trên MAC-F (biến `final_pack_p1` thành bottleneck số 1 toàn chip) và làm `product_pack` tăng từ **`4.944 ns -> 6.382 ns`** (+1.438 ns) trên MAC-NF.
   - **Nguyên nhân vật lý trên FPGA 6-LUT (Xilinx 7-Series):**
     - **Nối tiếp hóa (Serialization):** Trong phương pháp `sticky_drop`, đại lượng `drop4 = b[4] & (|stage3[15:0])` nằm ở **cuối tầng dịch thứ 4 (`stage3`)**. Do đó, tín hiệu bắt buộc phải đi xuyên qua 4 tầng MUX của bộ dịch (`stage0 -> stage1 -> stage2 -> stage3`) **rồi mới bắt đầu** đi vào cây OR 16-bit (`|stage3[15:0]`) và cổng OR tổng hợp cuối cùng. Tổng số tầng logic bị đội lên **5–6 tầng LUT nối tiếp**.
     - **Tăng Fanout nội bộ & Phá vỡ gộp LUT:** Việc trích xuất `stage0..stage3` ra ngoài để tính `drop1..drop4` làm các nút trung gian của bộ dịch có fanout > 1 (`fo=2..3`), ngăn cản Vivado gộp 2 tầng dịch liên tiếp vào chung 1 LUT6 và cộng thêm `~1.111 ns` net delay ước lượng cho mỗi chặng LUT phát sinh.
     - **Ưu thế tuyệt đối của `g_sticky_mask` song song:** Với cấu trúc mặt nạ nhiệt kế song song `sticky_masked[k] = sticky_upper[k] & (IDX < offset)`, mỗi bit `sticky_upper[k]` được lấy **trực tiếp từ thanh ghi đầu vào (`frac_hi_q` / `sf_reg`)** mà không cần chờ bộ dịch Barrel Shifter! Vì mỗi phần tử chỉ có đúng 6 ngõ vào (1 bit dữ liệu + 5 bit `offset[4:0]`), Vivado ánh xạ toàn bộ 31 phép so sánh và cổng AND vào **đúng 1 tầng LUT6 duy nhất** chạy song song hoàn toàn với bộ dịch, sau đó đi qua cây OR để về đích ở **4 tầng LUT (`4.249 ns` trên F / `4.710 ns` trên NF)**. Hơn nữa, các bit thấp hằng số 0 (`frac[23:0]` từ Adder, `frac[26:0]` từ Multiplier) được Vivado tự động tối ưu hóa (constant propagation), nên `u_pack` giữ nguyên đúng **94 LUTs** mà không hề tốn thêm diện tích!
   - **Quyết định:** **Khôi phục `g_sticky_mask` song song** tại `posit_pack_prepare.sv` và khôi phục bộ dịch 59-bit thuần túy không trích rẽ nhánh trung gian tại `dyn_right_shifter_fixed2.sv`.

---

### 2. Trạng thái Kiến trúc Hiện tại theo File (Active Baseline)

#### `rtl/adder/posit_add_norm_comb.sv` (Giữ nguyên tối ưu hóa ngày 2026-11-06)
- Loại bỏ hoàn toàn `clear_val` và 41 MUX 2:1 trên `sf`, `frac_hi`, `sticky`:
  ```systemverilog
  assign sf      = sf_raw;
  assign frac_hi = shifted_hi;
  assign sticky  = sticky_raw;
  ```
- Giữ nguyên logic bảo vệ cờ `final_zero`, `is_nar`, `sign`, và `flags_out`.

#### `rtl/packer/posit_pack_prepare.sv` & `rtl/common/dyn_right_shifter_fixed2.sv` (Khôi phục kiến trúc song song)
- Khôi phục bộ dịch phải 5 tầng thuần túy `dyn_right_shifter_fixed2` (không có tap `sticky_drop` trung gian để bảo toàn khả năng tối ưu hóa LUT của bộ dịch).
- Khôi phục khối tạo mặt nạ nhiệt kế song song 1-LUT6 `g_sticky_mask`:
  ```systemverilog
  wire        sticky_low   = sticky | (|frac[24:0]);
  wire [30:0] sticky_upper = {sf[2:0], frac[52:25]};
  wire [30:0] sticky_masked;

  genvar k;
  generate
      for (k = 0; k < 31; k = k + 1) begin : g_sticky_mask
          localparam [4:0] IDX = k;
          assign sticky_masked[k] = sticky_upper[k] & (IDX < offset);
      end
  endgenerate
  ```

---

### 3. Bảng tổng hợp Hiệu năng đạt được (Expected Post-Synthesis QoR)
Khi kết hợp **`posit_add_norm_comb.sv` (đã bỏ `clear_val`)** cùng **`posit_pack_prepare.sv` (`g_sticky_mask` song song)**:
- **Tiết kiệm LUTs ở Adder (`u_add`):** Giảm **32 LUTs** trên MAC-NF (`487 -> 455`) và giảm **21 LUTs** trên MAC-F (`410 -> 389`).
- **Timing `adder_s5`:** Cải thiện từ **`3.924 ns -> 3.616 ns`** trên cả MAC-NF và MAC-F.
- **Timing `final_pack_p1` & `product_pack`:** Giữ vững mức tối ưu **`4.249 ns`** trên MAC-F và **`4.710 ns` / `4.944 ns`** trên MAC-NF, giữ vững tần số mục tiêu $F_{\max}$ toàn hệ thống (`~202.27 MHz` trên NF và `~217.58 MHz` trên F).

---

### 4. Kết quả Kiểm định (Verification Evidence)
- **Strict Verilator Lint:** `SHARED_PORTS_LINT_PASS` (31/31 module active, 68/68 instance, 0 warnings).
- **Unit Verification:** `verify_shared_multiplier.py units` -> **PASS** (`mismatches = 0` trên toàn bộ OPS, SAC, SBM, Normalizer).
- **100,000 Mixed Transactions trên MAC-NF:** -> **PASS** (`mismatches = 0` so với Golden Oracle).
- **100,000 Mixed Transactions trên MAC-F:** -> **PASS** (`mismatches = 0` so với Golden Oracle).
