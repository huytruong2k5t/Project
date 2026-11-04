# F2F theo bank thanh ghi sau synthesis A35T

Nguồn: synthesis.dcp của synth_nf_final và synth_f_final, cùng snapshot đã kiểm chức năng. Chỉ open_checkpoint/query timing; không synthesis lại, không opt/place/route.

Định nghĩa: số Data Path Delay của path setup có slack xấu nhất, từ FF bất kỳ tới chân D của bank đích. Gồm C→Q + logic + net delay ước lượng sau synthesis; không gồm setup/skew/uncertainty. Không phải chu kỳ tối thiểu hoặc Fmax post-route. Các đường CE được tách trong CSV dưới target_kind D_CE (chọn path slack xấu nhất trong D/CE nên data delay có thể nhỏ hơn hàng D).

Nhóm tính theo thanh ghi đích, không buộc nguồn ở tầng ngay trước; có thể là feedback/control/metadata. Parser A/B P1 nhận data trực tiếp từ port, nên F2F của P1 là control/valid, không là toàn bộ decode input. Parser C P1 có đường từ accumulator hồi tiếp. Tên bank/FF có thể được Vivado gộp/đổi sau tối ưu; danh sách *_registers.txt và report từng bank là căn cứ.

## NF

| Bank đích | FF | Data delay (ns) | Logic (ns) | Net ước lượng (ns) | Slack (ns) |
| --- | ---: | ---: | ---: | ---: | ---: |
| accumulator_feedback | 32 | 5.364 | 1.495 | 3.869 | 4.385 |
| adder_s1 | 76 | 4.107 | 1.825 | 2.282 | 5.642 |
| adder_s2 | 74 | 4.851 | 1.247 | 3.604 | 4.898 |
| adder_s3 | 50 | 2.958 | 2.206 | 0.752 | 6.838 |
| adder_s4 | 55 | 3.922 | 1.293 | 2.629 | 5.827 |
| adder_s5 | 48 | 3.924 | 1.141 | 2.783 | 5.825 |
| adder_valid_control | 5 | 2.358 | 0.875 | 1.483 | 7.391 |
| final_packer_p1 | 44 | 6.156 | 1.495 | 4.661 | 3.593 |
| final_packer_p2 | 38 | 4.934 | 1.395 | 3.539 | 4.815 |
| multiplier_acc_l3 | 57 | 4.377 | 2.895 | 1.482 | 5.419 |
| multiplier_ops_context | 44 | 6.970 | 1.395 | 5.575 | 2.779 |
| multiplier_sac_l1 | 10 | 6.474 | 1.495 | 4.979 | 3.275 |
| multiplier_sac_state | 43 | 7.755 | 1.495 | 6.260 | 1.994 |
| multiplier_shift_l2 | 59 | 5.125 | 1.371 | 3.754 | 4.624 |
| operand_c_context | 40 | 1.527 | 0.775 | 0.752 | 8.222 |
| parser_a_p1 | 39 | 5.356 | 1.487 | 3.869 | 4.393 |
| parser_a_p2 | 39 | 3.527 | 1.145 | 2.382 | 6.222 |
| parser_b_p1 | 39 | 5.356 | 1.487 | 3.869 | 4.393 |
| parser_b_p2 | 39 | 3.527 | 1.145 | 2.382 | 6.222 |
| parser_c_p1 | 39 | 7.063 | 2.698 | 4.365 | 2.686 |
| parser_c_p2 | 39 | 3.527 | 1.145 | 2.382 | 6.222 |
| product_packer_p1 | 43 | 7.979 | 1.541 | 6.438 | 1.770 |
| product_packer_p2 | 39 | 4.326 | 1.247 | 3.079 | 5.423 |
| product_parse_bank | 44 | 6.629 | 1.397 | 5.232 | 3.120 |
| reset_sync | 21 | 0.670 | 0.478 | 0.192 | 8.986 |
| top_control_context | 10 | 5.364 | 1.495 | 3.869 | 4.385 |
| whole_f2f | 1066 | 7.979 | 1.541 | 6.438 | 1.770 |

CSV đầy đủ: [f2f_nf/stages.csv](f2f_nf/stages.csv). Raw path reports cùng thư mục, kèm startpoint/endpoint.

## F

| Bank đích | FF | Data delay (ns) | Logic (ns) | Net ước lượng (ns) | Slack (ns) |
| --- | ---: | ---: | ---: | ---: | ---: |
| accumulator_feedback | 32 | 4.561 | 1.393 | 3.168 | 5.188 |
| final_packer_p1 | 43 | 6.547 | 1.397 | 5.150 | 3.202 |
| final_packer_p2 | 38 | 4.934 | 1.395 | 3.539 | 4.815 |
| fused_control | 5 | 2.360 | 0.875 | 1.485 | 7.389 |
| fused_f1 | 76 | 7.254 | 3.438 | 3.816 | 2.527 |
| fused_f2 | 74 | 3.807 | 1.123 | 2.684 | 5.942 |
| fused_f3 | 49 | 3.270 | 2.385 | 0.885 | 6.526 |
| fused_f4 | 47 | 3.355 | 1.021 | 2.334 | 6.394 |
| fused_f5 | 47 | 6.218 | 1.293 | 4.925 | 3.531 |
| multiplier_acc_l3 | 17 | 2.738 | 1.855 | 0.883 | 7.058 |
| multiplier_ops_context | 27 | 5.570 | 1.389 | 4.181 | 4.179 |
| multiplier_sac_l1 | 9 | 4.554 | 1.828 | 2.726 | 5.195 |
| multiplier_sac_state | 25 | 5.570 | 1.389 | 4.181 | 4.179 |
| multiplier_shift_l2 | 19 | 2.986 | 0.875 | 2.111 | 6.763 |
| operand_c_context | 39 | 1.510 | 0.751 | 0.759 | 8.239 |
| parser_a_p1 | 39 | 4.561 | 1.393 | 3.168 | 5.188 |
| parser_a_p2 | 39 | 3.527 | 1.145 | 2.382 | 6.222 |
| parser_b_p1 | 39 | 4.561 | 1.393 | 3.168 | 5.188 |
| parser_b_p2 | 39 | 3.527 | 1.145 | 2.382 | 6.222 |
| parser_c_p1 | 39 | 6.472 | 2.698 | 3.774 | 3.277 |
| parser_c_p2 | 39 | 3.527 | 1.145 | 2.382 | 6.222 |
| reset_sync | 15 | 0.670 | 0.478 | 0.192 | 8.986 |
| top_control_context | 8 | 4.561 | 1.393 | 3.168 | 5.188 |
| whole_f2f | 804 | 7.254 | 3.438 | 3.816 | 2.527 |

CSV đầy đủ: [f2f_f/stages.csv](f2f_f/stages.csv). Raw path reports cùng thư mục, kèm startpoint/endpoint.

## Điểm chính

- NF: worst F2F 7.979ns: accumulator nhân → flags P1 product pack, logic1.541ns/netước lượng6.438ns.
- F: worst F2F 7.254ns: sf_o → shift_all F1, logic3.438ns/netước lượng3.816ns. WNS toàn top2.178ns ở báo cáo trước là path tới cổng in_ready, không phải path F2F này.
- Adder NF năm tầng: S1=4.107, S2=4.851, S3=2.958, S4=3.922, S5=3.924ns; S2 Align là tầng chậm nhất trong adder ở snapshot này.
- Chưa kết luận 200MHz hoặc timing closure; số hiện tại là post-synthesis/unplaced.
