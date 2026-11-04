# Đo lại MAC NF/F sau refactor Parser và LOD — 01/11/2026

Kết luận: các suite chức năng đã chạy đều PASS, nhưng refactor chưa tốt hơn về F2F tổng: NF giữ 7.334 ns; F tăng 6.602 → 7.697 ns (+16.59%). LUT tăng ở cả hai top. Bộ cộng S4 cải thiện, nhưng điểm nghẽn toàn MAC chưa được giải quyết.

Baseline: ../readme_refactor_recheck_20261101. Nguồn mới được khóa tại source/ và manifest.json; toàn bộ hash RTL đang làm việc vẫn trùng snapshot đã verify/synthesis. Không sửa RTL trong lượt đo này.

Hai file thay đổi so với baseline: `rtl/parser/posit_parser.sv`, `rtl/common/lod_lzd_core_fixed2.sv`.

## Điều kiện đo

Vivado 2026.1; Artix-7 xc7a35tcpg236-1; OOC synthesis; clock 10 ns, uncertainty 0.1 ns; input min=max 2.5 ns; output min 0/max 0.5 ns; flatten_hierarchy rebuilt; DSP/BRAM=0. Cùng recipe với baseline. Không chạy opt/place/route/bitstream.

## Verification

- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- PACKER_REFACTOR_PASS completed=10851 stalls=3552 errors=0
- MAC_REFACTOR_PASS F=0 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=15..22
- MAC_REFACTOR_PASS F=1 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=12..23
- PARSER_MAG_DUT_PASS checked=4000000
- LOD_SERIAL_PASS checked=500063
- PARSER_PREVIOUS_EQUIV_PASS accepted=105394 completed=105367 aborted=27 stalls=35270

MAC so d/5 flags với golden Python integer độc lập cho Posit(32,3), FLOOR/Q12 hiện hành: NF n=0..8, F n=0..12, OPS0/1, cfg_mode=1; có accumulation/clear, thay context, reset và backpressure. 299 giao dịch/top bị reset hủy có chủ đích và được hạch toán.

Kiểm bổ sung dùng trực tiếp magnitude nội bộ của parser mới đối chiếu phép bù hai trên 4 triệu vector; LOD mới so với oracle quét bit tuần tự trên 500.063 vector; parser đầy đủ so với snapshot baseline, gồm data, ready/valid, stall/reset. Reference parser và LOD cũ chỉ đổi tên module trong verify_parser_lod/source/ để cùng biên dịch. Test tb_parser_mag_equiv hiện có chỉ tự tính lại công thức; vì vậy không dùng nó làm bằng chứng duy nhất cho RTL. Không dùng candidate LOD làm golden thay cho oracle.

Đây là regression theo RTL FLOOR hiện tại; chưa là nghiệm thu FULL_TERM26/Q24 hoặc toàn bộ ma trận 52 điểm/520 triệu completed của SPEC.

## Synthesis và F2F

| Top | LUT cũ → mới | FF cũ → mới | WNS cũ → mới (ns) | F2F cũ → mới (ns) | Giảm F2F |
| --- | ---: | ---: | ---: | ---: | ---: |
| NF | 2098 → 2214 | 1077 → 1077 | 2.025 → 2.025 | 7.334 → 7.334 | 0.00% |
| F | 1257 → 1374 | 820 → 820 | 2.689 → 1.570 | 6.602 → 7.697 | -16.59% |

Cả hai top synthesis hoàn tất với 0 errors, 0 critical warnings và 0 warnings trong synth_design. FF giữ nguyên, WHS cả hai vẫn −0.055 ns. LUT NF tăng 116 (+5.53%); F tăng 117 (+9.31%). Setup WNS tổng bao gồm cả I/O nên khác setup slack của đường F2F trích riêng.

F2F là Data Path Delay của đường có setup slack xấu nhất từ FF đến chân D/CE; bảng từng bank dùng D. Gồm C→Q, logic và net ước lượng trước placement; không gồm setup/skew/uncertainty, không phải Fmax. Parser A/B P1 nhận data từ port nên F2F tới bank đó chủ yếu là control/valid, còn Parser C P1 có đường dữ liệu feedback từ accumulator.

Đường Parser C P1 của F giữ cùng source/endpoint so với baseline: levels giảm 10→7, logic delay giảm 2.878→1.495 ns, nhưng net delay ước lượng tăng 3.724→6.202 ns. Vì vậy tổng tăng 1.095 ns. Fanout/cấu trúc kết nối sau ánh xạ cần được xem cùng logic depth; giảm CARRY4 không tự bảo đảm giảm tổng delay. Đây là kết quả của cả hai thay đổi cùng lúc, chưa tách riêng đóng góp prefix-OR và casez.

NF Parser C P1 chỉ giảm 7.063→7.019 ns, trong khi đường Parser B P2→SAC state vẫn 7.334 ns nên toàn NF không đổi. Adder S4 dùng chung LOD mới giảm 3.922→3.450 ns ở cả NF/F, là cải thiện cục bộ có thể đo được. Chưa có cơ sở chọn toàn bộ refactor này làm bản tối ưu timing thay baseline; cần thử tách từng thay đổi nếu tiếp tục tối ưu.


## F2F từng bank — NF

Critical path: `u_dut/u_wrapper/u_b/p2_frac_q_reg[9]/C` → `u_dut/u_wrapper/u_core/u_ctrl/fx_q_reg[10]/D`; 7.334 ns, logic 1.742 ns, net 5.592 ns, 8 levels; setup slack 2.466 ns.

| Bank đích | Cũ (ns) | Mới (ns) | Δ mới−cũ (ns) | Levels cũ→mới |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 5.369 | 5.369 | +0.000 | 7→7 |
| adder_s1 | 4.107 | 4.107 | +0.000 | 4→4 |
| adder_s2 | 4.851 | 4.851 | +0.000 | 5→5 |
| adder_s3 | 2.958 | 2.958 | +0.000 | 8→8 |
| adder_s4 | 3.922 | 3.450 | -0.472 | 5→4 |
| adder_s5 | 3.924 | 3.924 | +0.000 | 4→4 |
| adder_valid_control | 2.358 | 2.358 | +0.000 | 2→2 |
| final_packer_p1 | 4.710 | 4.710 | +0.000 | 6→6 |
| final_packer_p2 | 4.934 | 4.934 | +0.000 | 6→6 |
| multiplier_acc_l3 | 4.390 | 4.390 | +0.000 | 14→14 |
| multiplier_ops_context | 7.087 | 7.087 | +0.000 | 7→7 |
| multiplier_sac_l1 | 6.469 | 6.469 | +0.000 | 7→7 |
| multiplier_sac_state | 7.334 | 7.334 | +0.000 | 8→8 |
| multiplier_shift_l2 | 5.125 | 5.125 | +0.000 | 6→6 |
| operand_c_context | 1.527 | 1.527 | +0.000 | 1→1 |
| parser_a_p1 | 5.361 | 5.361 | +0.000 | 7→7 |
| parser_a_p2 | 3.638 | 3.616 | -0.022 | 3→3 |
| parser_b_p1 | 5.361 | 5.361 | +0.000 | 7→7 |
| parser_b_p2 | 3.638 | 3.616 | -0.022 | 3→3 |
| parser_c_p1 | 7.063 | 7.019 | -0.044 | 11→7 |
| parser_c_p2 | 3.638 | 3.616 | -0.022 | 3→3 |
| product_packer_p1 | 5.930 | 5.930 | +0.000 | 6→6 |
| product_packer_p2 | 4.350 | 4.350 | +0.000 | 5→5 |
| product_parse_bank | 6.131 | 6.222 | +0.091 | 7→7 |
| reset_sync | 0.670 | 0.670 | +0.000 | 0→0 |
| top_control_context | 5.369 | 5.369 | +0.000 | 7→7 |

## F2F từng bank — F

Critical path: `u_dut/u_wrapper/accumulator_q_reg[31]/C` → `u_dut/u_wrapper/u_c/p1_cnt_q_reg[0]/D`; 7.697 ns, logic 1.495 ns, net 6.202 ns, 7 levels; setup slack 2.052 ns.

| Bank đích | Cũ (ns) | Mới (ns) | Δ mới−cũ (ns) | Levels cũ→mới |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 4.511 | 4.477 | -0.034 | 5→6 |
| adder_s1 | 4.842 | 4.842 | +0.000 | 5→5 |
| adder_s2 | 4.851 | 4.851 | +0.000 | 5→5 |
| adder_s3 | 2.958 | 2.958 | +0.000 | 8→8 |
| adder_s4 | 3.922 | 3.450 | -0.472 | 5→4 |
| adder_s5 | 3.924 | 3.924 | +0.000 | 4→4 |
| adder_valid_control | 2.355 | 2.355 | +0.000 | 2→2 |
| final_packer_p1 | 4.249 | 4.249 | +0.000 | 4→4 |
| final_packer_p2 | 4.732 | 4.934 | +0.202 | 4→6 |
| multiplier_acc_l3 | 2.738 | 2.738 | +0.000 | 5→5 |
| multiplier_ops_context | 4.996 | 4.869 | -0.127 | 5→4 |
| multiplier_sac_l1 | 4.606 | 5.116 | +0.510 | 5→7 |
| multiplier_sac_state | 5.243 | 5.559 | +0.316 | 6→7 |
| multiplier_shift_l2 | 2.986 | 2.986 | +0.000 | 2→2 |
| operand_c_context | 1.516 | 1.516 | +0.000 | 1→1 |
| parser_a_p1 | 4.511 | 4.477 | -0.034 | 5→6 |
| parser_a_p2 | 3.638 | 3.616 | -0.022 | 3→3 |
| parser_b_p1 | 4.511 | 4.477 | -0.034 | 5→6 |
| parser_b_p2 | 3.638 | 3.616 | -0.022 | 3→3 |
| parser_c_p1 | 6.602 | 7.697 | +1.095 | 10→7 |
| parser_c_p2 | 3.638 | 3.616 | -0.022 | 3→3 |
| reset_sync | 0.670 | 0.670 | +0.000 | 0→0 |
| top_control_context | 4.511 | 4.477 | -0.034 | 5→6 |

## Giới hạn

WHS vẫn cần đọc cùng timing report; số synthesis chưa xác nhận setup/hold sau route hay hoạt động trên kit. DRC OOC CFGBVS-1 liên quan điện áp cấu hình board chưa khai báo trong benchmark. Không suy tốc độ 200 MHz từ số level LUT hoặc công thức RTL; casez/prefix-OR phải được đánh giá theo ánh xạ thực tế.

## Tái chạy

Từ thư mục Posit_MAC, dùng RunRoot mới để giữ nguyên bằng chứng:

```powershell
./scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot results/<run_moi> -VectorCount 50000
./scripts/run_parser_lod_recheck.ps1 -RunRoot results/<run_moi>
./scripts/run_refactored_mac.ps1 -Stage SynthNF -RunRoot results/<run_moi> -SynthSuffix _final
./scripts/run_refactored_mac.ps1 -Stage SynthF -RunRoot results/<run_moi> -SynthSuffix _final
./scripts/report_refactored_mac_f2f.ps1 -Variant nf -RunRoot results/<run_moi>
./scripts/report_refactored_mac_f2f.ps1 -Variant f -RunRoot results/<run_moi>
```
