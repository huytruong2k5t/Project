# Kiểm chứng README refactor và so sánh synthesis/F2F ngày 01/11/2026

Kết luận: chức năng PASS trong các suite đã chạy; F2F tổng NF giảm 8.08%, F giảm 8.99% sau synthesis. Packer cải thiện rõ; tối ưu OPS/Parser chưa cải thiện đồng đều. Chưa đủ bằng chứng cho toàn MAC200MHz hoặc timing closure post-route.

## Phạm vi và nguồn

Baseline: ../refactored_mac_20261101_r3. Candidate: snapshot source/ của lần này; đã kiểm lại mọi SHA256 và xác nhận RTL working tree không đổi trong khi verify/synthesis. README được lưu tại source/docs_review/README.md. Không sửa RTL trong phiên này.

Cùng Vivado2026.1, part xc7a35tcpg236-1, OOC, clock10ns/uncertainty0.1ns, input min=max2.5ns, output min0/max0.5ns, rebuilt hierarchy, DSP/BRAM0. Không chạy opt/place/route/bitstream. Số net delay là ước lượng unplaced.

## Verification mới

- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- PACKER_REFACTOR_PASS completed=10851 stalls=3552 errors=0
- OPS_POPCOUNT_PASS checked=149152
- MAC_REFACTOR_PASS F=0 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=15..22
- MAC_REFACTOR_PASS F=1 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=12..23

MAC kiểm 50,000 request/top, d/5flags theo golden Python integer32/3 cho FLOOR/Q12 hiện hành (NF n0..8; F n0..12; OPS0/1), state/clear/reset/stall/context. OPS kiểm bằng popcount serial độc lập, gồm chế độ full26 của module NF và approximate12, hòa/swap/invalid. Adder là equivalence comb/pipeline, không thay oracle độc lập MAC.

Testbench Packer cũ đổi kích thích ngay khi nguồn đang stall, chỉ kiểm handshake một DUT và FAIL không trả mã lỗi. Đã bổ sung giữ input khi stall, so ready/valid hai DUT, kiểm giữ output và watchdog/$fatal. Vì driver thay đổi, counts10851/3552 khác README10692/3528; không suy là mất giao dịch từ chênh lệch hai lần chạy. Chưa chạy toàn ma trận52 điểm/520M hoặc coverage signoff.

## Tổng hợp và F2F tổng

| Top | LUT cũ → mới | FF cũ → mới | WNS synthesis cũ → mới (ns) | F2F cũ → mới (ns) | Giảm F2F |
| --- | ---: | ---: | ---: | ---: | ---: |
| NF | 2319 → 2098 | 1066 → 1077 | 1.770 → 2.025 | 7.979 → 7.334 | 8.08% |
| F | 1380 → 1257 | 804 → 820 | 2.178 → 2.689 | 7.254 → 6.602 | 8.99% |

Cả hai hoàn tất synthesis với 0 errors/critical warnings. DSP=BRAM=0. WHS vẫn -0.055ns ở cả hai top; đây chưa là setup/hold closure. DRC có CFGBVS-1 trong benchmark OOC chưa khai báo điện áp cấu hình; chưa phải project board/bitstream.

## F2F từng bank

Data Path Delay trên path setup slack xấu nhất từ FF tới chân D bank đích (whole_f2f xét cả D/CE), gồm C→Q/logic/net ước lượng, không gồm setup/skew/uncertainty. Nhóm theo đích, có thể chứa feedback/control/metadata. Không phải Fmax. Parser A/B P1 nhận data trực tiếp từ port, nên F2F của bank đó là control/valid; input-to-flop không nằm trong bảng.

### NF

| Bank đích | Cũ (ns) | Mới (ns) | Δ mới−cũ (ns) | Levels cũ→mới |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 5.364 | 5.369 | +0.005 | 7→7 |
| adder_s1 | 4.107 | 4.107 | +0.000 | 4→4 |
| adder_s2 | 4.851 | 4.851 | +0.000 | 5→5 |
| adder_s3 | 2.958 | 2.958 | +0.000 | 8→8 |
| adder_s4 | 3.922 | 3.922 | +0.000 | 5→5 |
| adder_s5 | 3.924 | 3.924 | +0.000 | 4→4 |
| adder_valid_control | 2.358 | 2.358 | +0.000 | 2→2 |
| final_packer_p1 | 6.156 | 4.710 | -1.446 | 7→6 |
| final_packer_p2 | 4.934 | 4.934 | +0.000 | 6→6 |
| multiplier_acc_l3 | 4.377 | 4.390 | +0.013 | 14→14 |
| multiplier_ops_context | 6.970 | 7.087 | +0.117 | 6→7 |
| multiplier_sac_l1 | 6.474 | 6.469 | -0.005 | 7→7 |
| multiplier_sac_state | 7.755 | 7.334 | -0.421 | 7→8 |
| multiplier_shift_l2 | 5.125 | 5.125 | +0.000 | 6→6 |
| operand_c_context | 1.527 | 1.527 | +0.000 | 1→1 |
| parser_a_p1 | 5.356 | 5.361 | +0.005 | 7→7 |
| parser_a_p2 | 3.527 | 3.638 | +0.111 | 4→3 |
| parser_b_p1 | 5.356 | 5.361 | +0.005 | 7→7 |
| parser_b_p2 | 3.527 | 3.638 | +0.111 | 4→3 |
| parser_c_p1 | 7.063 | 7.063 | +0.000 | 11→11 |
| parser_c_p2 | 3.527 | 3.638 | +0.111 | 4→3 |
| product_packer_p1 | 7.979 | 5.930 | -2.049 | 7→6 |
| product_packer_p2 | 4.326 | 4.350 | +0.024 | 5→5 |
| product_parse_bank | 6.629 | 6.131 | -0.498 | 6→7 |
| reset_sync | 0.670 | 0.670 | +0.000 | 0→0 |
| top_control_context | 5.364 | 5.369 | +0.005 | 7→7 |
| whole_f2f | 7.979 | 7.334 | -0.645 | 7→8 |

Raw reports: f2f_nf/stages.csv và *_D.rpt; có startpoint/endpoint, logic/net delay. Các tầng F4 ABS cũ và S4 LOD mới khác cấu trúc; đối chiếu theo bank không có nghĩa phép toán ở hai tầng giống nhau.

### F

| Bank đích | Cũ (ns) | Mới (ns) | Δ mới−cũ (ns) | Levels cũ→mới |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 4.561 | 4.511 | -0.050 | 6→5 |
| adder_s1 (cũ: fused_f1) | 7.254 | 4.842 | -2.412 | 9→5 |
| adder_s2 (cũ: fused_f2) | 3.807 | 4.851 | +1.044 | 4→5 |
| adder_s3 (cũ: fused_f3) | 3.270 | 2.958 | -0.312 | 9→8 |
| adder_s4 (cũ: fused_f4) | 3.355 | 3.922 | +0.567 | 3→5 |
| adder_s5 (cũ: fused_f5) | 6.218 | 3.924 | -2.294 | 5→4 |
| adder_valid_control | — | 2.355 | — | —→2 |
| final_packer_p1 | 6.547 | 4.249 | -2.298 | 6→4 |
| final_packer_p2 | 4.934 | 4.732 | -0.202 | 6→4 |
| multiplier_acc_l3 | 2.738 | 2.738 | +0.000 | 5→5 |
| multiplier_ops_context | 5.570 | 4.996 | -0.574 | 6→5 |
| multiplier_sac_l1 | 4.554 | 4.606 | +0.052 | 5→5 |
| multiplier_sac_state | 5.570 | 5.243 | -0.327 | 6→6 |
| multiplier_shift_l2 | 2.986 | 2.986 | +0.000 | 2→2 |
| operand_c_context | 1.510 | 1.516 | +0.006 | 1→1 |
| parser_a_p1 | 4.561 | 4.511 | -0.050 | 6→5 |
| parser_a_p2 | 3.527 | 3.638 | +0.111 | 4→3 |
| parser_b_p1 | 4.561 | 4.511 | -0.050 | 6→5 |
| parser_b_p2 | 3.527 | 3.638 | +0.111 | 4→3 |
| parser_c_p1 | 6.472 | 6.602 | +0.130 | 11→10 |
| parser_c_p2 | 3.527 | 3.638 | +0.111 | 4→3 |
| reset_sync | 0.670 | 0.670 | +0.000 | 0→0 |
| top_control_context | 4.561 | 4.511 | -0.050 | 6→5 |
| whole_f2f | 7.254 | 6.602 | -0.652 | 9→10 |

Raw reports: f2f_f/stages.csv và *_D.rpt; có startpoint/endpoint, logic/net delay. Các tầng F4 ABS cũ và S4 LOD mới khác cấu trúc; đối chiếu theo bank không có nghĩa phép toán ở hai tầng giống nhau.

## Đối chiếu các nhận định trong README

- F thực sự dùng posit_add năm tầng; sáu module fused_* đã bỏ khỏi active.f. Đây là dùng chung mã nguồn; NF và F tổng hợp riêng vẫn có các instance phần cứng riêng.
- README nói cả NF/F dùng mul_iter_core_fixed2 là chưa đúng: NF vẫn gọi mul_iter_core/bank54, F dùng mul_iter_core_fixed2/bank16. Không kết luận paired FULL_TERM/approx-only từ số đo này.
- Packer: việc bỏ MUX P1/dời inexact sang P2 khớp kiểm chức năng. NF productP1 7.979→5.930ns; finalP1 NF6.156→4.710ns, F6.547→4.249ns. P2 không cải thiện nhiều: NFproduct4.326→4.350ns, finalNF4.934→4.934ns.
- Parser P2 giảm logic levels4→3 nhưng DataPathDelay3.527→3.638ns (net ước lượng thay đổi). Vì vậy bỏ một tầng LUT không bảo đảm giảm tổng F2F.
- OPS: F context Y5.570→4.996ns, nạp fx5.570→5.243ns. NF nạp fx7.755→7.334ns nhưng context Y6.970→7.087ns. Path nạp fx vẫn8 levels ở NF/6 ở F; nhận định đã xuống2–3 tầng toàn đường chưa được netlist xác nhận. Hàm popcount6 cho3 bit kết quả không đồng nghĩa một LUT6 vật lý duy nhất.
- Bottleneck mới NF: parserB P2 frac[9] → fx_q[10], 7.334ns. F: accumulator_q[31] → ParserC p1_cnt[0], 6.602ns; sau khi tối ưu adder/packer, feedback tích lũy trở thành đường dài nhất.
- Riêng adder mới của cả hai: S2 Align4.851ns là lớn nhất; S1 F4.842ns sát phía sau. Các giá trị này chưa chứng minh toàn MAC đạt200MHz; toàn top vẫn có đường6.602–7.334ns trước setup/uncertainty.

## Tái chạy

```powershell
./scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot results/fresh_label -VectorCount 50000
./scripts/run_refactored_mac.ps1 -Stage SynthNF -RunRoot results/fresh_label -SynthSuffix _final
./scripts/run_refactored_mac.ps1 -Stage SynthF -RunRoot results/fresh_label -SynthSuffix _final
./scripts/report_refactored_mac_f2f.ps1 -Variant nf -RunRoot results/fresh_label
./scripts/report_refactored_mac_f2f.ps1 -Variant f -RunRoot results/fresh_label
```

OPS supplement: compile source/tb/tb_ops_popcount_recheck.sv vào work của verify rồi chạy work.tb_ops_popcount_recheck với run.do; log verify/ops.log. SHA bổ sung ở additional_source_hashes.json.
