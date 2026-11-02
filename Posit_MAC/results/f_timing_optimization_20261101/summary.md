# Tối ưu timing MAC F — 01/11/2026

Thử nghiệm chỉ MAC F. Nguồn NF, parser dùng cho NF, bộ cộng và LOD dùng chung được giữ nguyên. Các candidate dùng posit_parser_f riêng tại A/B/C của F; không thêm tầng, không đổi số học FLOOR/Q12, không thay golden.

## Điều kiện đo

Vivado2026.1; xc7a35tcpg236-1; OOC synthesis; clock10ns, setup/hold uncertainty0.1ns; input min=max2.5ns, output min0/max0.5ns; rebuilt hierarchy; DSP/BRAM0. Không chạy place/route/bitstream. Net delay là ước lượng unplaced; WHS chưa đóng hold.

## So sánh

| Candidate | Magnitude/LOD parser | F2F (ns) | Logic (ns) | Net (ns) | Levels | LUT | FF | WNS (ns) | WHS (ns) |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before_parser_refactor | carry/group; shared old adder LOD | 6.602 | 2.878 | 3.724 | 10 | 1257 | 820 | 2.689 | -0.055 |
| p11_current | prefix/flat; current shared adder LOD | 7.697 | 1.495 | 6.202 | 7 | 1374 | 820 | 1.570 | -0.055 |
| p00 | carry/group; F-only parser | 6.602 | 2.878 | 3.724 | 10 | 1265 | 820 | 2.689 | -0.055 |
| p01 | carry/flat; F-only parser | 6.844 | 2.254 | 4.590 | 7 | 1268 | 820 | 2.537 | -0.055 |
| p10 | prefix/group; F-only parser | 6.865 | 1.371 | 5.494 | 6 | 1314 | 820 | 2.467 | -0.055 |
| p20 | carry + direct raw transition/group; F-only parser | 6.883 | 1.371 | 5.512 | 6 | 1466 | 820 | 2.173 | -0.055 |

P11 là snapshot đầu phiên đã verify/synthesis trước đó, không phải RTL được chọn sau tối ưu; số đo được tái dùng vì nguồn ban đầu và recipe trùng snapshot. Baseline before_parser_refactor còn dùng LOD cũ cho adder, vì vậy P00 giữ adder flat không hoàn toàn giống baseline đó. Các số setup WNS toàn top có cả I/O; F2F là Data Path Delay trên đường FF→D/CE có setup slack xấu nhất, không phải Fmax.

P20 là thử nghiệm bổ sung sau ma trận: giữ carry magnitude cho payload/FRB nhưng tính transition regime trực tiếp từ mã p. Với L[i]=OR các bit dưới i, m[i]=p[i] XOR (s AND L[i]); suy ra transition[i]=p[i] XOR p[i+1] XOR (s AND p[i] AND NOT L[i]). Đã kiểm riêng30 bit transition thực sự của DUT trên4M mẫu trước khi synthesis. Đây là một thay đổi topology tổ hợp, không thêm pipeline.

Worst endpoint/source có thể đổi giữa candidate; không cộng tuyến tính chênh lệch timing để quy riêng từng cấu trúc RTL. Đọc thêm parser_c_count_bits.csv và raw path để đối chiếu cùng đích. P10 có cảnh báo Synth8-3936 trim một bit lower_any không được dùng; giữ nguyên log để kiểm chứng.

## Phương án được chọn

Chọn p00: carry/group; F-only parser. F2F 7.697→6.602 ns, giảm 14.23% so bản trước phiên tối ưu; so baseline trước refactor 6.602 ns là +0.000 ns.

Worst path mới: `u_dut/u_wrapper/accumulator_q_reg[31]/C` → `u_dut/u_wrapper/u_c/p1_cnt_q_reg[0]/D`; 10 levels, logic 2.878 ns + net 3.724 ns. LUT 1374→1265; FF 820→820.

Đã đưa đúng byte RTL của candidate được chọn vào cây làm việc; [promotion.json](promotion.json) lưu hash toàn active RTL, chứng minh NF và shared RTL giữ nguyên. [before_promotion/](before_promotion/) giữ các file trước khi thay đổi. File list active và opt17 đã bổ sung hai module parser riêng cho F; production.f lịch sử không sửa.

## p00: nguồn và verification

- [Manifest nguồn](p00/manifest.json), [snapshot RTL](p00/source/rtl/mac_f/mac_f_wrapper.sv), [DCP synthesis](p00/synth_f_final/synthesis.dcp)
- [MAC F log](p00/verify/f.log), [parser/LOD log](p00/verify_parser_f/parser.log)
- [F2F từng bank CSV](p00/f2f_f/stages.csv), [worst F2F](p00/f2f_f/whole_f2f_D_CE.rpt), [top20 F2F](p00/f2f_f/whole_f2f_top20.rpt), [I/O→FF](p00/f2f_f/input_to_register_top10.rpt)

- MAC_REFACTOR_PASS F=1 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=12..23
- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- PACKER_REFACTOR_PASS completed=10851 stalls=3552 errors=0
- PARSER_MAG_DUT_PASS checked=4000000
- LOD_SERIAL_PASS checked=500063
- PARSER_PREVIOUS_EQUIV_PASS accepted=105394 completed=105367 aborted=27 stalls=35270

| Bank đích | Delay (ns) | Logic (ns) | Net (ns) | Levels |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 4.511 | 1.269 | 3.242 | 5 |
| adder_s1 | 4.842 | 1.680 | 3.162 | 5 |
| adder_s2 | 4.851 | 1.247 | 3.604 | 5 |
| adder_s3 | 2.958 | 2.206 | 0.752 | 8 |
| adder_s4 | 3.450 | 1.145 | 2.305 | 4 |
| adder_s5 | 3.924 | 1.141 | 2.783 | 4 |
| adder_valid_control | 2.355 | 0.875 | 1.480 | 2 |
| final_packer_p1 | 4.249 | 1.147 | 3.102 | 4 |
| final_packer_p2 | 4.732 | 1.123 | 3.609 | 4 |
| multiplier_acc_l3 | 2.738 | 1.855 | 0.883 | 5 |
| multiplier_ops_context | 4.996 | 1.247 | 3.749 | 5 |
| multiplier_sac_l1 | 4.606 | 1.909 | 2.697 | 5 |
| multiplier_sac_state | 5.243 | 1.494 | 3.749 | 6 |
| multiplier_shift_l2 | 2.986 | 0.875 | 2.111 | 2 |
| operand_c_context | 1.516 | 0.751 | 0.765 | 1 |
| parser_a_p1 | 4.511 | 1.269 | 3.242 | 5 |
| parser_a_p2 | 3.638 | 1.069 | 2.569 | 3 |
| parser_b_p1 | 4.511 | 1.269 | 3.242 | 5 |
| parser_b_p2 | 3.638 | 1.069 | 2.569 | 3 |
| parser_c_p1 | 6.602 | 2.878 | 3.724 | 10 |
| parser_c_p2 | 3.638 | 1.069 | 2.569 | 3 |
| reset_sync | 0.670 | 0.478 | 0.192 | 0 |
| top_control_context | 4.511 | 1.269 | 3.242 | 5 |
| whole_f2f | 6.602 | 2.878 | 3.724 | 10 |

## p01: nguồn và verification

- [Manifest nguồn](p01/manifest.json), [snapshot RTL](p01/source/rtl/mac_f/mac_f_wrapper.sv), [DCP synthesis](p01/synth_f_final/synthesis.dcp)
- [MAC F log](p01/verify/f.log), [parser/LOD log](p01/verify_parser_f/parser.log)
- [F2F từng bank CSV](p01/f2f_f/stages.csv), [worst F2F](p01/f2f_f/whole_f2f_D_CE.rpt), [top20 F2F](p01/f2f_f/whole_f2f_top20.rpt), [I/O→FF](p01/f2f_f/input_to_register_top10.rpt)

- MAC_REFACTOR_PASS F=1 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=12..23
- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- PACKER_REFACTOR_PASS completed=10851 stalls=3552 errors=0
- PARSER_MAG_DUT_PASS checked=4000000
- LOD_SERIAL_PASS checked=500063
- PARSER_PREVIOUS_EQUIV_PASS accepted=105394 completed=105367 aborted=27 stalls=35270

| Bank đích | Delay (ns) | Logic (ns) | Net (ns) | Levels |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 5.134 | 1.393 | 3.741 | 6 |
| adder_s1 | 4.842 | 1.680 | 3.162 | 5 |
| adder_s2 | 4.851 | 1.247 | 3.604 | 5 |
| adder_s3 | 2.958 | 2.206 | 0.752 | 8 |
| adder_s4 | 3.450 | 1.145 | 2.305 | 4 |
| adder_s5 | 3.924 | 1.141 | 2.783 | 4 |
| adder_valid_control | 2.355 | 0.875 | 1.480 | 2 |
| final_packer_p1 | 4.249 | 1.147 | 3.102 | 4 |
| final_packer_p2 | 4.934 | 1.395 | 3.539 | 6 |
| multiplier_acc_l3 | 2.738 | 1.855 | 0.883 | 5 |
| multiplier_ops_context | 4.875 | 1.123 | 3.752 | 4 |
| multiplier_sac_l1 | 4.599 | 1.909 | 2.690 | 5 |
| multiplier_sac_state | 5.448 | 1.247 | 4.201 | 5 |
| multiplier_shift_l2 | 2.986 | 0.875 | 2.111 | 2 |
| operand_c_context | 1.516 | 0.751 | 0.765 | 1 |
| parser_a_p1 | 4.489 | 1.269 | 3.220 | 5 |
| parser_a_p2 | 3.638 | 1.069 | 2.569 | 3 |
| parser_b_p1 | 4.489 | 1.269 | 3.220 | 5 |
| parser_b_p2 | 3.638 | 1.069 | 2.569 | 3 |
| parser_c_p1 | 6.844 | 2.254 | 4.590 | 7 |
| parser_c_p2 | 3.638 | 1.069 | 2.569 | 3 |
| reset_sync | 0.670 | 0.478 | 0.192 | 0 |
| top_control_context | 4.489 | 1.269 | 3.220 | 5 |
| whole_f2f | 6.844 | 2.254 | 4.590 | 7 |

## p10: nguồn và verification

- [Manifest nguồn](p10/manifest.json), [snapshot RTL](p10/source/rtl/mac_f/mac_f_wrapper.sv), [DCP synthesis](p10/synth_f_final/synthesis.dcp)
- [MAC F log](p10/verify/f.log), [parser/LOD log](p10/verify_parser_f/parser.log)
- [F2F từng bank CSV](p10/f2f_f/stages.csv), [worst F2F](p10/f2f_f/whole_f2f_D_CE.rpt), [top20 F2F](p10/f2f_f/whole_f2f_top20.rpt), [I/O→FF](p10/f2f_f/input_to_register_top10.rpt)

- MAC_REFACTOR_PASS F=1 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=12..23
- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- PACKER_REFACTOR_PASS completed=10851 stalls=3552 errors=0
- PARSER_MAG_DUT_PASS checked=4000000
- LOD_SERIAL_PASS checked=500063
- PARSER_PREVIOUS_EQUIV_PASS accepted=105394 completed=105367 aborted=27 stalls=35270

| Bank đích | Delay (ns) | Logic (ns) | Net (ns) | Levels |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 5.134 | 1.393 | 3.741 | 6 |
| adder_s1 | 4.842 | 1.680 | 3.162 | 5 |
| adder_s2 | 4.851 | 1.247 | 3.604 | 5 |
| adder_s3 | 2.958 | 2.206 | 0.752 | 8 |
| adder_s4 | 3.450 | 1.145 | 2.305 | 4 |
| adder_s5 | 3.924 | 1.141 | 2.783 | 4 |
| adder_valid_control | 2.355 | 0.875 | 1.480 | 2 |
| final_packer_p1 | 4.249 | 1.147 | 3.102 | 4 |
| final_packer_p2 | 4.934 | 1.395 | 3.539 | 6 |
| multiplier_acc_l3 | 2.738 | 1.855 | 0.883 | 5 |
| multiplier_ops_context | 4.875 | 1.123 | 3.752 | 4 |
| multiplier_sac_l1 | 5.017 | 1.395 | 3.622 | 6 |
| multiplier_sac_state | 5.448 | 1.247 | 4.201 | 5 |
| multiplier_shift_l2 | 2.986 | 0.875 | 2.111 | 2 |
| operand_c_context | 1.516 | 0.751 | 0.765 | 1 |
| parser_a_p1 | 4.489 | 1.269 | 3.220 | 5 |
| parser_a_p2 | 3.616 | 1.047 | 2.569 | 3 |
| parser_b_p1 | 4.489 | 1.269 | 3.220 | 5 |
| parser_b_p2 | 3.616 | 1.047 | 2.569 | 3 |
| parser_c_p1 | 6.865 | 1.371 | 5.494 | 6 |
| parser_c_p2 | 3.616 | 1.047 | 2.569 | 3 |
| reset_sync | 0.670 | 0.478 | 0.192 | 0 |
| top_control_context | 4.489 | 1.269 | 3.220 | 5 |
| whole_f2f | 6.865 | 1.371 | 5.494 | 6 |

## p20: nguồn và verification

- [Manifest nguồn](p20/manifest.json), [snapshot RTL](p20/source/rtl/mac_f/mac_f_wrapper.sv), [DCP synthesis](p20/synth_f_final/synthesis.dcp)
- [MAC F log](p20/verify/f.log), [parser/LOD log](p20/verify_parser_f/parser.log)
- [F2F từng bank CSV](p20/f2f_f/stages.csv), [worst F2F](p20/f2f_f/whole_f2f_D_CE.rpt), [top20 F2F](p20/f2f_f/whole_f2f_top20.rpt), [I/O→FF](p20/f2f_f/input_to_register_top10.rpt)

- MAC_REFACTOR_PASS F=1 rows=50000 accepted=50000 completed=49701 aborted=299 stalls=181084 latency_observed=12..23
- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- PACKER_REFACTOR_PASS completed=10851 stalls=3552 errors=0
- PARSER_MAG_DUT_PASS checked=4000000
- PARSER_TRANSITION_DUT_PASS checked=4000000
- LOD_SERIAL_PASS checked=500063
- PARSER_PREVIOUS_EQUIV_PASS accepted=105394 completed=105367 aborted=27 stalls=35270

| Bank đích | Delay (ns) | Logic (ns) | Net (ns) | Levels |
| --- | ---: | ---: | ---: | ---: |
| accumulator_feedback | 4.566 | 1.393 | 3.173 | 6 |
| adder_s1 | 4.842 | 1.680 | 3.162 | 5 |
| adder_s2 | 4.851 | 1.247 | 3.604 | 5 |
| adder_s3 | 2.958 | 2.206 | 0.752 | 8 |
| adder_s4 | 3.450 | 1.145 | 2.305 | 4 |
| adder_s5 | 3.924 | 1.141 | 2.783 | 4 |
| adder_valid_control | 2.360 | 0.875 | 1.485 | 2 |
| final_packer_p1 | 4.249 | 1.147 | 3.102 | 4 |
| final_packer_p2 | 4.934 | 1.395 | 3.539 | 6 |
| multiplier_acc_l3 | 2.738 | 1.855 | 0.883 | 5 |
| multiplier_ops_context | 4.996 | 1.247 | 3.749 | 5 |
| multiplier_sac_l1 | 4.554 | 1.828 | 2.726 | 5 |
| multiplier_sac_state | 4.996 | 1.247 | 3.749 | 5 |
| multiplier_shift_l2 | 2.986 | 0.875 | 2.111 | 2 |
| operand_c_context | 1.516 | 0.751 | 0.765 | 1 |
| parser_a_p1 | 4.566 | 1.393 | 3.173 | 6 |
| parser_a_p2 | 3.638 | 1.069 | 2.569 | 3 |
| parser_b_p1 | 4.566 | 1.393 | 3.173 | 6 |
| parser_b_p2 | 3.638 | 1.069 | 2.569 | 3 |
| parser_c_p1 | 6.883 | 1.371 | 5.512 | 6 |
| parser_c_p2 | 3.638 | 1.069 | 2.569 | 3 |
| reset_sync | 0.670 | 0.478 | 0.192 | 0 |
| top_control_context | 4.566 | 1.393 | 3.173 | 6 |
| whole_f2f | 6.883 | 1.371 | 5.512 | 6 |

## Giới hạn và tái chạy

MAC regression dùng cfg_mode=1, n0..12, OPS0/1 với golden Python integer Posit32/es3 cho FLOOR hiện hành; 50000 accepted gồm reset-aborted được hạch toán. Parser kiểm4M magnitude trên RTL thật, LOD serial500063 vector, parser đầy đủ có stalls/reset và đối chiếu baseline. Không là nghiệm thu FULL_TERM26/Q24 hay ma trận52 điểm/520M của SPEC.

Tái chạy một candidate bằng RunRoot mới; chọn SourceRoot từ experiments/f_timing_20261101/<candidate>. Các source thí nghiệm và manifest được giữ nguyên.

```powershell
./scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot results/<run_moi> -VerifyScope F -VectorCount 50000 -SourceRoot experiments/f_timing_20261101/<candidate>
./scripts/run_f_parser_equiv.ps1 -RunRoot results/<run_moi>
./scripts/run_refactored_mac.ps1 -Stage SynthF -RunRoot results/<run_moi> -SynthSuffix _final
./scripts/report_refactored_mac_f2f.ps1 -Variant f -RunRoot results/<run_moi>
```
