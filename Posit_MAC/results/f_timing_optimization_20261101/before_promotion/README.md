## Hợp đồng hiện hành ngày 01/11/2026

[SPEC v1.25](SPEC_Posit_MAC_IP.md) quy định duy nhất Posit(32,3), approximate FULL_TERM26/Q24,
fraction đầu vào12 bit, n0..12, OPS0/1 và RNE cho NF/F; không mode exact phần cứng.
Golden độc lập và model L1 được phân biệt tại [§6.1](SPEC_Posit_MAC_IP.md#61-golden-model-và-ideal),
ma trận nghiệm thu tại [§6.7](SPEC_Posit_MAC_IP.md#acceptance-matrix): 52 điểm NF/F×OPS×n,
≥10 triệu completed/điểm, giữ ngưỡng coverage; không có trục exact/format/TRUNC.

Nguồn hiện tại vẫn còn NF exact-capable/N_MAX8 và đường nhân FLOOR; xem §8 của SPEC.
Header FULL_TERM đã có nhưng API/harness còn mixed, phải khóa approximate=true và kiểm riêng.
Các lệnh, số đo và mốc có ngày bên dưới thuộc snapshot ghi kèm, không tự nghiệm thu
nguồn đang refactor hoặc thay golden32/3 bằng SoftPosit p32/es2. Lần cập nhật này chỉ sửa tài liệu.

---

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
AC02 exact đã rút khỏi phạm vi; golden32/3 dùng oracle số nguyên độc lập ở SPEC §6.1.

**Cập nhật tối giản `ops_sel_comb_fixed2` & `sac_step_comb_fixed2/3` (29/10/2026):**
- **OPS 12-bit:** Nhận trực tiếp `frac_a[11:0]` và `frac_b[11:0]` (tương ứng `Frac[11:0]` trích xuất sau giải mã theo Norris & Kim Fig. 5a); loại bỏ logic cắt bit và cờ `input_cut` bên trong khối OPS; thu gọn `cfg_ops` về 1 bit (`0`: cố định A, `1`: min-popcount).
- **Tối ưu hóa khối SAC (`sac_step_comb_fixed2/3`):** Thay thế toàn bộ cây generate 4 tầng phức tạp (mảng 2 chiều `zero_tree`/`one_tree` và chỉ thị `split_var`) bằng biểu thức boolean chuẩn `single_one = ((fx & (fx - 1'b1)) == 12'd0)`. Đơn giản hóa biểu thức tính `step_amount`, `scale_sum` và loại bỏ hoàn toàn các lỗi/cảnh báo lint (unpacked array, out-of-bounds, unused bits). Khớp bit-exact 100% với golden reference trên toàn bộ không gian trạng thái.

**Tối ưu hóa Timing & Triệt tiêu Critical Path khối SAC (`sac_step_comb_fixed2/3`) (30/10/2026):**
- **Decouple `term_valid` khỏi các MUX ngõ ra:** Tách rời tín hiệu phụ thuộc `term_valid` ra khỏi các bộ chọn `scale_next`, `fx_next` (dùng `leading_valid` trực tiếp từ LOD), triệt tiêu hoàn toàn đường trễ chuỗi `LOD -> Adder -> Compare >12 -> state_error -> term_valid -> MUXes`.
- **Rút gọn bộ tính `scale_sum`:** Gộp phép tính `step_amount` và `scale_sum` thành một bộ cộng đơn có carry-in `{1'b0, scale} + {1'b0, leading_count} + 1'b1`, loại bỏ 1 tầng cộng nối tiếp và 1 bộ MUX trung gian.
- **Triệt tiêu hoàn toàn Critical Path cho `exhausted`:** Rút gọn tối đa thành `exhausted = single_one = ((fx & (fx - 1'b1)) == 12'd0)`. Tín hiệu dừng lặp trở nên độc lập tuyệt đối, chạy song song 100% từ đầu vào `fx` mà không còn bất kỳ sự phụ thuộc nào vào bộ LOD, bộ cộng `scale_sum` hay bộ so sánh ngưỡng `state_error`.
- **Loại bỏ triệt để các cổng/tín hiệu không cần thiết:** Lược bỏ hoàn toàn cổng và dây trung gian không sử dụng `term_valid`, `sa`, `step_amount` trên `sac_step_comb_fixed2/3`, đồng bộ dọn sạch các dây `unused_valid`, `unused_sa` trên các wrapper điều khiển `iter_ctrl` và `iter_ctrl_fixed2`. Datapath được tối giản gọn gàng, giảm diện tích và loại bỏ hoàn toàn các cảnh báo linting về unconnected/unused ports.

**Tích hợp `dyn_right_shifter_fixed3` & Loại bỏ hoàn toàn `cfg_mode` trên toàn bộ lõi nhân (`mul_iter_core_fixed2`) (31/10/2026):**
- **Loại bỏ đồng bộ `cfg_mode` (cố định Approximate mode `cfg_mode = 1`):** Xóa bỏ hoàn toàn cổng `cfg_mode` và thanh ghi `mode_o` xuyên suốt toàn bộ phân cấp bộ nhân 12-bit/16-bit: [`iter_ctrl_fixed2.sv`](rtl/multiplier/iter_ctrl_fixed2.sv), [`sbm_shift_comb_fixed2.sv`](rtl/multiplier/sbm_shift_comb_fixed2.sv), [`sbm_accum_comb_fixed2.sv`](rtl/multiplier/sbm_accum_comb_fixed2.sv), [`sbm_accum_fixed2.sv`](rtl/multiplier/sbm_accum_fixed2.sv), [`mul_iter_core_fixed2.sv`](rtl/multiplier/mul_iter_core_fixed2.sv) và điểm gọi tại [`mac_f_wrapper.sv`](rtl/mac_f/mac_f_wrapper.sv).
- **Tối giản khối điều khiển SAC (`iter_ctrl_fixed2`):** Gán thẳng giới hạn vòng lặp `limit_q <= cfg_n`, loại bỏ hằng số `EXACT_LIMIT` và MUX chọn mode.
- **Tối giản khối dịch SBM (`sbm_shift_comb_fixed2`):**
  - Căn lề $Y$ base cố định bằng phép ghép dây thuần túy `assign y_base = {1'b0, y_mant, 2'b00}` (0 cổng logic, không dùng toán tử `<<`).
  - Trích xuất term qua module barrel shifter phẳng 4 tầng MUX [`dyn_right_shifter_fixed3.sv`](rtl/common/dyn_right_shifter_fixed3.sv) (triệt tiêu logic `is_overflow` và mảng 2D unpacked).
  - Rút gọn tạo `term` về 1 dòng dataflow `assign term = init_only ? 16'd0 : {shifted[15:2], 2'b00}`.
  - Tối giản tính `term_tail`: bỏ biến `integer` 32-bit và bộ cộng `scale + 2`; kiểm tra trực tiếp `scale` bit thấp nhất của `y_mant[12:0]` qua mặt nạ song song `discard_mask[12:0]` (`i[3:0] < scale`), `discarded_bits = y_mant & discard_mask`, và cổng OR rút gọn `|discarded_bits`.
- **Tối giản khối Accumulator (`sbm_accum_comb_fixed2` & `sbm_accum_fixed2`):** Loại bỏ nhánh chết `if (!cfg_mode || ROUND_SCHEME == 1)` và chuyển toàn bộ phép cộng tích lũy sang cấu trúc dataflow tường minh.
- **Đồng bộ Manifest:** Cập nhật [`rtl/mac_active.f`](rtl/mac_active.f) và [`experiments/opt17_20261029/sources.f`](experiments/opt17_20261029/sources.f) bổ sung `rtl/common/dyn_right_shifter_fixed3.sv`. Biên dịch kiểm tra sạch sẽ 0 lỗi, 0 cảnh báo.

**Tái cấu trúc phẳng hóa & Tinh gọn bộ nhân lặp (`mul_iter_core_fixed2`) (31/10/2026):**
- **Hợp nhất phân cấp vào parent sequential module:** Hợp nhất toàn bộ FSM điều khiển lặp (`iter_ctrl_fixed2`) và thanh ghi tích lũy (`sbm_accum_fixed2`) trực tiếp vào bên trong [`mul_iter_core_fixed2.sv`](rtl/multiplier/mul_iter_core_fixed2.sv). Toàn bộ pipeline registers (`t1_*`, `t2_*`), bộ đếm vòng lặp, và context register nằm gọn gàng tại một file duy nhất, giúp việc debug sóng và trace tín hiệu điều khiển trực quan hơn rất nhiều.
- **Bọc trực tiếp 3 khối tổ hợp datapath thuần túy:**
  1. [`sac_step_comb_fixed3.sv`](rtl/multiplier/sac_step_comb_fixed3.sv) (`u_sac`): L1 SAC step
  2. [`sbm_shift_comb_fixed2.sv`](rtl/multiplier/sbm_shift_comb_fixed2.sv) (`u_shift`): L2 SBM shift
  3. [`sbm_accum_comb_fixed2.sv`](rtl/multiplier/sbm_accum_comb_fixed2.sv) (`u_accum`): L3 SBM accum
- **Dọn sạch tín hiệu chết & tối giản handshake (Signal Pruning):**
  - Loại bỏ hoàn toàn cổng và dây `sticky_acc`, `sticky_next` khỏi [`sbm_accum_comb_fixed2.sv`](rtl/multiplier/sbm_accum_comb_fixed2.sv) và [`mul_iter_core_fixed2.sv`](rtl/multiplier/mul_iter_core_fixed2.sv) (chế độ approximate mode bit sticky cố định bằng 0).
  - Cập nhật [`mac_f_wrapper.sv`](rtl/mac_f/mac_f_wrapper.sv): gỡ bỏ cổng `sticky_acc`, xóa wire `sticky_acc`, cập nhật assertion sang `assert (acc[1:0] == 0)`.
  - Triệt tiêu các bản sao đồng bộ reset trùng lặp (`ctrl_ready`, `acc_ready`) và handshake nội bộ không cần thiết; dùng chung 1 bộ đồng bộ reset 2-flop `meta_sync2`.
- **Cập nhật Manifest:** Gỡ bỏ `rtl/multiplier/iter_ctrl_fixed2.sv` và `rtl/multiplier/sbm_accum_fixed2.sv` khỏi [`rtl/mac_active.f`](rtl/mac_active.f) và [`experiments/opt17_20261029/sources.f`](experiments/opt17_20261029/sources.f) trong khi vẫn bảo lưu 2 file trên ổ đĩa.
- **Xác minh mô phỏng:** Biên dịch toàn bộ top-level [`posit_mac_f`](rtl/mac_f/posit_mac_f.sv) và unit testbench [`tb_mul_iter_core_fixed2.sv`](tb/tb_mul_iter_core_fixed2.sv) bằng ModelSim 10.1d sạch sẽ 0 lỗi, 100% test cases (zero fraction, single/multi-step iterations, context handshakes) đều PASS.

**Nâng cấp & Tối ưu sâu Bộ cộng Posit 5 tầng cân bằng (`posit_add`) (31/10/2026):**
- **Tái cân bằng Pipeline từ 3 tầng lên 5 tầng (~200 MHz, đồng bộ tốc độ bộ nhân):**
  - Tách 2 nút cổ chai ~7.5–7.9 ns (`A1 Align` và `A3 Normalize`) thành 5 tầng tổ hợp siêu gọn bọc trực tiếp trong [`posit_add.sv`](rtl/adder/posit_add.sv):
    1. [`posit_add_prepare_comb.sv`](rtl/adder/posit_add_prepare_comb.sv) (`u_s1_prepare`): So sánh số mũ/phân số & hoán vị đảm bảo $X \ge Y$.
    2. [`posit_add_align_comb.sv`](rtl/adder/posit_add_align_comb.sv) (`u_s2_align`): Dịch phải phẳng 31-bit qua [`dyn_right_shifter_fixed4.sv`](rtl/common/dyn_right_shifter_fixed4.sv) + mặt nạ nhiệt kế song song tính `jam`/`alignment_tail` (thay thế 6 mảng bảng tra 192 dây cũ).
    3. [`posit_add_arith_comb.sv`](rtl/adder/posit_add_arith_comb.sv) (`u_s3_arith`): Cộng/trừ không dấu 31-bit (`X ± Y >= 0`, không cần tầng Abs/Borrow) chạy song song với phép tính trước `sf_inc = sf_base + 1`.
    4. [`posit_add_lod_comb.sv`](rtl/adder/posit_add_lod_comb.sv) (`u_s4_lod`): Phát hiện bit 1 đầu tiên thống nhất trên toàn bộ 31-bit `magnitude[30:0]` bằng cây Radix-4 [`lod_lzd_core_fixed2.sv`](rtl/common/lod_lzd_core_fixed2.sv) + chuẩn bị hạt giống `lost_carry`.
    5. [`posit_add_norm_comb.sv`](rtl/adder/posit_add_norm_comb.sv) (`u_s5_norm`): Chạy song song 100% bộ dịch trái phẳng 30-bit [`dyn_left_shifter_fixed6.sv`](rtl/common/dyn_left_shifter_fixed6.sv) và phép trừ đơn `sf_inc - count`, kết hợp MUX `NaR/Zero` duy nhất ở ngõ ra.
- **Dọn sạch tín hiệu & Flip-Flop dư thừa:** Xóa biểu thức nghẽn `!normalized[Q]`; triệt tiêu logic `is_overflow` chết ở cả 2 barrel shifter; loại bỏ 24 Flip-Flop hằng 0 ở `frac[23:0]`, 10 Flip-Flop hằng ở `x` (`s1_q`, `s2_q`), cờ `sf_equal` trung gian, và gộp `flags_in[4]` vào `is_nar`.
- **Xác minh tương đương Bit-Exact:** Cập nhật [`rtl/mac_active.f`](rtl/mac_active.f) và [`experiments/opt17_20261029/sources.f`](experiments/opt17_20261029/sources.f) (bảo lưu các file cũ trên ổ đĩa). Kiểm thử trên ModelSim 10.1d qua [`tb_posit_add_5stage_equiv.sv`](tb/tb_posit_add_5stage_equiv.sv) đối chiếu trực tiếp với golden [`posit_add_comb.sv`](rtl/adder/posit_add_comb.sv): **39.534 giao dịch hoàn tất, 20.310 chu kỳ kiểm tra giữ dữ liệu backpressure, 0 mismatch**.

**Tái cấu trúc & Tinh gọn toàn diện các khối Posit Packer (`posit_pack` & `posit_product_pack`) (01/11/2026):**
- **Phẳng hóa phân cấp & Loại bỏ mã chết (Dead Code & Generate Scope Pruning):**
  - Loại bỏ hoàn toàn khối `generate if (ROUND_MODE == "TRUNC")` chết và wrapper `generate if (ROUND_MODE == "RNE") begin : g_rne` bên trong [`posit_pack.sv`](rtl/packer/posit_pack.sv) và [`posit_product_pack.sv`](rtl/mac_nf/posit_product_pack.sv).
  - Toàn bộ thanh ghi Stage-1 (`p1_*_q`) và Stage-2 (`p2_valid_q`, `d_q`, `flags_q`, `sign_q`) được kéo trực tiếp ra phạm vi top-level của packer, loại bỏ hoàn toàn tiền tố scope rườm rà `g_rne.*` khi trace dạng sóng (waveform debugging) trên ModelSim/Vivado.
- **Tối ưu Datapath & Rút ngắn Critical Path khối P1 Prepare ([`posit_pack_prepare.sv`](rtl/packer/posit_pack_prepare.sv)):**
  - **Trích xuất Regime siêu gọn:** Thay thế toán tử dịch bit có dấu `offset_value_t'($signed(sf) >>> 3)` bằng phép trích xuất bit-slice trực tiếp kết hợp XOR đảo dấu `assign offset = sf[7:3] ^ {5{sf[10]}}` và `first_regime_bit = ~sf[10]`.
  - **Tối ưu Barrel Shifter 59-bit ([`dyn_right_shifter_fixed2.sv`](rtl/common/dyn_right_shifter_fixed2.sv)):** Phẳng hóa thành cây MUX 5 tầng 2:1 (`stage0`..`stage4`), triệt tiêu hoàn toàn mảng 2 chiều unpacked `stage[5:0]`, cờ cảnh báo `split_var`, và logic phát hiện tràn `is_overflow` dư thừa.
  - **Tách song song Sticky Prefix & Saturation Detection:** Tính toán `sticky_lookup` song song với bộ dịch, gộp các điều kiện tràn số (`sf_ge_max`, `sf_lt_min`, `maxpos_ovf`) độc lập với luồng `NORMAL`, giúp giảm số tầng logic trước flip-flop Stage-1 (`data_delay_ns` giảm đáng kể so với 7.065 ns trước đó).
- **Tối ưu khối P2 Finish ([`posit_pack_finish.sv`](rtl/packer/posit_pack_finish.sv)):**
  - Loại bỏ dead branches và giữ lại logic RNE chuẩn kết hợp 1 chuỗi carry 32-bit duy nhất gộp chung phép làm tròn và bù 2: `signed_base = {1'b0, mag_trunc} ^ {32{sign}}` và `rounded_signed = signed_base + (sign ^ round_up)`.
  - Bắt các điểm kẹp biên (`magnitude_zero`, `magnitude_max`) song song hoàn toàn với bộ cộng, đưa vào MUX ngõ ra dạng `unique case`.
- **Xác minh tương đương Bit-Exact trên ModelSim 10.1d ([`tb_posit_pack_equiv.sv`](tb/tb_posit_pack_equiv.sv)):**
  - Quét cạn toàn bộ không gian số mũ $sf \in [-260, +260]$ kết hợp tất cả các góc làm tròn (tie-to-even, round-up, round-down), kiểm tra trường hợp đặc biệt ($NaR$, $Zero$, $MAXPOS$, $MINPOS$) và áp lực backpressure ngẫu nhiên downstream.
  - Kết quả kiểm chứng đồng thời cả `posit_pack` và `posit_product_pack`: **10.692 giao dịch hoàn tất, 3.528 chu kỳ stall, 0 mismatch (PASS 100%)**.

**Tái cấu trúc Thống nhất Dùng chung Bộ cộng 5 tầng `posit_add` cho cả Fused & Non-Fused MAC (01/11/2026):**
- **Động cơ & Tối ưu Timing:**
  - Khắc phục sự lệch pha cấu hình: trước đó Non-Fused đã nâng cấp lên bộ cộng 5 tầng [`posit_add.sv`](rtl/adder/posit_add.sv) với timing rất tốt ($< 4.86\text{ ns}$ mỗi tầng), trong khi Fused MAC vẫn còn trỏ vào bộ cộng cũ [`fused_add_pipe.sv`](rtl/mac_f/fused_add_pipe.sv) dẫn đến hai nút thắt lớn trong tổng hợp (`fused_f1 = 7.254 ns` và `fused_f5 = 6.218 ns`).
- **Mạch chuyển đổi không suy hao (Lossless Prepack Adapter) trong [`mac_f_wrapper.sv`](rtl/mac_f/mac_f_wrapper.sv):**
  - Ở cấu hình Fused (`FRAC_W = 12`), tích thô $\hat{P}$ từ [`mul_iter_core_fixed2.sv`](rtl/multiplier/mul_iter_core_fixed2.sv) có `p_magnitude = acc[15:2]` (14 bit). Sau khi chuẩn hóa theo `p_magnitude[13]`, phần lẻ có tối đa 13 bit, vừa vặn hoàn hảo và bảo toàn nguyên vẹn 100% (lossless) trong ngõ vào 26 bit `a_frac[25:0]` của [`posit_add.sv`](rtl/adder/posit_add.sv) mà không cần qua bất kỳ bộ đóng gói/giải mã trung gian nào.
  - **Triệt tiêu Critical Path cho `product_sf`:** Tính toán trước giá trị tăng `core_sf_inc_q <= ops_sf + 11'sd1` ngay tại chu kỳ `pair_retire` (khi bắt đầu nhân). Khi nhân hoàn tất (`core_done`), `product_sf = p_magnitude[13] ? core_sf_inc_q : core_sf` chỉ là một MUX 2:1 (1 tầng LUT), loại bỏ hoàn toàn chuỗi carry-chain nối tiếp trước Stage 1 [`posit_add_prepare_comb.sv`](rtl/adder/posit_add_prepare_comb.sv).
- **Dọn sạch Danh sách Module Active & Tối ưu Kiến trúc:**
  - Loại bỏ hoàn toàn 6 file bộ cộng riêng của Fused khỏi [`rtl/mac_active.f`](rtl/mac_active.f) và [`experiments/opt17_20261029/sources.f`](experiments/opt17_20261029/sources.f) (vẫn bảo toàn nguyên vẹn file vật lý trên ổ đĩa): `fused_add_pipe.sv`, `fused_prepare_comb.sv`, `fused_align_comb.sv`, `fused_arith_comb.sv`, `fused_abs_borrow_comb.sv`, `fused_norm_comb.sv`.
  - Danh sách active giảm từ **46 xuống 40 module**. Cả hai kiến trúc `posit_mac_f` và `posit_mac_nf` giờ đây chia sẻ 100% bộ cộng 5 tầng [`posit_add.sv`](rtl/adder/posit_add.sv), bộ nhân lặp phẳng [`mul_iter_core_fixed2.sv`](rtl/multiplier/mul_iter_core_fixed2.sv), và bộ đóng gói [`posit_pack.sv`](rtl/packer/posit_pack.sv).
- **Xác minh mô phỏng Bit-Exact trên ModelSim 10.1d:**
  - Chạy [`tb_refactored_mac.sv`](tb/tb_refactored_mac.sv) với `FUSED=1` trên 5.000 vector kiểm thử: **5.000 accepted, 4.970 completed, 30 aborted, 18.115 stalls, 0 mismatch (PASS 100%)**.
  - Chạy [`tb_refactored_mac.sv`](tb/tb_refactored_mac.sv) với `FUSED=0` trên 5.000 vector kiểm thử: **5.000 accepted, 4.970 completed, 30 aborted, 18.115 stalls, 0 mismatch (PASS 100%)**.
  - Chạy [`tb_posit_add_5stage_equiv.sv`](tb/tb_posit_add_5stage_equiv.sv): **39.534 completed, 0 mismatch (PASS 100%)**.
  - Chạy [`tb_posit_pack_equiv.sv`](tb/tb_posit_pack_equiv.sv): **10.692 completed, 0 mismatch (PASS 100%)**.

**Tối ưu sâu Critical Path cho Packer P1/P2, Parser P2 & Khối Chọn Toán Hạng OPS (01/11/2026):**
- **Tối ưu Khối Packer P1 & P2 ([`posit_pack_prepare.sv`](rtl/packer/posit_pack_prepare.sv), [`posit_pack_finish.sv`](rtl/packer/posit_pack_finish.sv), [`mac_nf_wrapper.sv`](rtl/mac_nf/mac_nf_wrapper.sv)):**
  - **Thay thế bảng tra `sticky_lookup[offset]` bằng mặt nạ nhiệt kế song song 1-LUT6:** Tách `normal_sticky` thành phần tĩnh `sticky_low = sticky | (|frac[24:0])` (độc lập hoàn toàn với `offset`) và phần động 31-bit trên `sticky_upper = {sf[2:0], frac[52:25]}` dùng mặt nạ nhiệt kế `sticky_masked[k] = sticky_upper[k] & (IDX < offset)` (mỗi bit chỉ có 6 ngõ vào: 1 bit dữ liệu + 5 bit `offset` $\rightarrow$ ánh xạ gọn vào **1 LUT6 duy nhất**), loại bỏ 32 cây OR rộng và bộ MUX 32:1 (5–6 tầng LUT).
  - **Loại bỏ MUX trường hợp đặc biệt ở cuối tầng P1 & Dời cờ `inexact` sang P2:** Gỡ bỏ các MUX chọn `special_sel` trên `mag_trunc[30:0]`, `guard_bit`, `round_bit`, `sticky_bit` ở cuối [`posit_pack_prepare.sv`](rtl/packer/posit_pack_prepare.sv) (vì tầng P2 [`posit_pack_finish.sv`](rtl/packer/posit_pack_finish.sv) đã ghi đè `d` theo `special_sel` cho `ZERO`, `NAR`, `MAXPOS`, `MINPOS`). Đồng thời dời phép OR cờ `inexact` (`flags[1] |= guard_bit | round_bit | sticky_bit` ở nhánh `NORMAL`) sang P2, cắt đứt hoàn toàn đường critical path `p1_flags_q_reg[1]/D` (`7.979 ns` ở NF và `6.547 ns` ở F) khỏi bộ dịch và cây tính sticky.
  - **Tính trước `core_sf_inc_q` trong [`mac_nf_wrapper.sv`](rtl/mac_nf/mac_nf_wrapper.sv):** Đăng ký `core_sf_inc_q <= ops_sf + 11'sd1` ngay tại `pair_retire` và chọn `sf_norm` bằng MUX 2:1 theo bit tràn `acc[15]`/`acc[53]`, triệt tiêu chuỗi 3 tầng `CARRY4` nối tiếp trước `posit_product_pack` P1 (`6.202 ns` ở NF).
- **Tối ưu Khối Parser P2 & Bộ Dịch Trái ([`dyn_left_shifter.sv`](rtl/common/dyn_left_shifter.sv), [`posit_parser.sv`](rtl/parser/posit_parser.sv), [`posit_magnitude_parse.sv`](rtl/mac_nf/posit_magnitude_parse.sv)):**
  - **Phẳng hóa [`dyn_left_shifter.sv`](rtl/common/dyn_left_shifter.sv):** Chuyển mảng 2D `stage[6:0]` thành các dây `stage0..stage5` và loại bỏ bộ so sánh `is_overflow = (b >= 5'd29)` cùng MUX kẹp 0 dư thừa ở cuối tầng dịch (vì dịch trái 29 bit với $b \ge 29$ tự nhiên đẩy 29 bit 0 vào).
  - **Gỡ bỏ MUX xóa `Zero/NaR` dư thừa sau bộ dịch ở P2:** Trong cả [`posit_parser.sv`](rtl/parser/posit_parser.sv) và [`posit_magnitude_parse.sv`](rtl/mac_nf/posit_magnitude_parse.sv), `payload_seed[28:0]` đã bằng `29'd0` đối với cả `Zero` (`32'h0000_0000`) và `NaR` (`32'h8000_0000`), nên ngõ ra bộ dịch `shifted_payload` tự động bằng 0. Việc bỏ MUX `(is_zero || is_nar) ? 0 : ...` trên `frac_d[25:0]` và `sf_d[2:0]` giúp tiết kiệm 1 tầng LUT trên toàn bộ 29 bit ngõ ra P2.
- **Tối ưu Đường Xuất P2 Parser sang Bộ Nhân ([`ops_sel_comb_fixed2.sv`](rtl/multiplier/ops_sel_comb_fixed2.sv) & [`ops_sel_comb.sv`](rtl/multiplier/ops_sel_comb.sv)):**
  - Thay thế cây cộng nhị phân `split_var` (vốn bị tổng hợp thành 5–6 tầng LUT từ `u_a/p2_frac_q_reg` tới `fx_q_reg`/`y_q_reg`, chiếm `5.570 ns` ở F và `7.755 ns` ở NF) bằng kiến trúc đếm bit `popcount6` tối ưu cho LUT6 (mỗi nhóm 6 bit ánh xạ trực tiếp vào 1 LUT6, cộng hai giá trị 3 bit chỉ có 6 ngõ vào nên gọn trong 1 LUT6), rút ngắn mạch đếm popcount và so sánh xuống còn 2–3 tầng LUT6.
- **Xác minh tương đương Bit-Exact trên ModelSim 10.1d:**
  - Chạy [`tb_posit_pack_equiv.sv`](tb/tb_posit_pack_equiv.sv): **10.692 completed, 3.528 stalls, 0 errors (PASS 100%)**.
  - Chạy [`tb_refactored_mac.sv`](tb/tb_refactored_mac.sv) với `FUSED=1` và `FUSED=0` (5.000 vector mỗi cấu hình): **4.970 completed, 30 aborted, 18.115 stalls, 0 mismatch (PASS 100%)**.

**Parser C P1 – bỏ chuỗi CARRY4 lấy trị tuyệt đối & Tái cấu trúc phẳng hóa `lod_lzd_core_fixed2` (01/11/2026):**
- **Loại bỏ chuỗi bù 2 CARRY4:** Đường xấu nhất `accumulator_q[31] → u_c/p1_cnt_q` (NF 7.063 ns, F 6.602 ns, 6 CARRY4 + 5 LUT) do phép bù 2 `(p ^ {s}) + s` 32 bit nằm trước LOD regime. [`posit_parser.sv`](rtl/parser/posit_parser.sv) thay bằng công thức không carry `m[i] = p[i] ^ (s & |p[i-1:0])` (cây prefix-OR).
- **Tái cấu trúc phẳng hóa khối LOD 31-bit ([`lod_lzd_core_fixed2.sv`](rtl/common/lod_lzd_core_fixed2.sv)):**
  - Thay thế toàn bộ cây MUX Radix-4 3 tầng cồng kềnh (đệm 33 bit 0 giả lên 64 lá, mảng dây 2D `valid_tree`/`pos_tree` gắn directive `split_var`, tạo chuỗi 4 tầng LUT6/MUXF7) bằng khối giải mã ưu tiên phẳng (Flat Priority Encoder) chuẩn SystemVerilog.
  - Bộ tổng hợp Vivado ánh xạ trực tiếp thành mạch logic nông chỉ 3 tầng LUT thuần túy (không qua bộ MUXF7 ghép slice), triệt tiêu hoàn toàn độ trễ net và routing của mảng 64 phần tử.
- **Kiểm chứng tương đương Bit-Exact trên ModelSim 10.1d:**
  - [`tb_parser_mag_equiv.sv`](tb/tb_parser_mag_equiv.sv): 4.000.000 vector kiểm chứng công thức magnitude carry-free: **0 lỗi (PASS)**.
  - [`tb_lod_equiv.sv`](tb/tb_lod_equiv.sv): 500.000+ vector (gồm walking-1, walking-0, zero, random) đối chiếu trực tiếp `lod_lzd_core_fixed2` mới với reference cũ: **0 lỗi (PASS 100%)**.
  - [`tb_posit_add_5stage_equiv.sv`](tb/tb_posit_add_5stage_equiv.sv): 39.534 giao dịch hoàn tất, 20.310 chu kỳ stall kiểm tra Stage 4 của bộ cộng `posit_add`: **0 lỗi (PASS 100%)**.
  - [`tb_refactored_mac.sv`](tb/tb_refactored_mac.sv) với `FUSED=1` (12..23 cycles) và `FUSED=0` (15..22 cycles), 5.000 vectors mỗi mode: **4.970 completed, 30 aborted, 0 mismatch (PASS 100%)**.

## 1. Bản dùng hiện tại

**Chưa chuyển đổi số học:** RTL,L1 thực thi,testbench và runner dưới đây vẫn là
FLOOR/n≤8. Sinh viên tự sửa RTL/testbench;phiên29/10 chỉ chốt hợp đồng/tài liệu.
Không dùng PASS,accuracy hoặc timing cũ để kết luận FULL_TERM đã chạy đúng.
Freeze/manifest nguồn cũ giữ nguyên;chỉ tạo release mới sau khi có kiểm chứng mới.

Release đã khóa chức năng: **`POSIT_MAC_RTL_20261022_FIXED32_3`** (`FIXED32_3_FUNCTION_VERIFIED`).
Cây MAC hiện hữu dùng [`rtl/mac_active.f`](rtl/mac_active.f), 40 module (dùng chung 100% bộ cộng 5 tầng `posit_add` cho cả NF và F).
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
