# Synthesis và F2F sau phục hồi Packer — 06/11/2026

Snapshot mới được tạo riêng từ RTL live, không sửa RTL hoặc ghi đè lần đo trước. Chỉ phục hồi Packer (bộ dịch 59 bit + thermometer sticky mask); tối ưu bỏ clear_val ở S5 vẫn được giữ.

Vivado 2026.1, xc7a35tcpg236-1, OOC/flatten rebuilt, clock 10 ns, user uncertainty 0,1 ns, input delay 2,5 ns, output max/min 0,5/0 ns; max DSP/BRAM=0. Recipe synthesis và constraints giữ nguyên. Chỉ thêm báo cáo đầy đủ nhóm thanh ghi sau phần báo cáo cũ. Hai lượt synthesis NF/F; không implementation/place/route/bitstream.

## Tổng quan so với lần đo refactor_lut_20261106/candidate

| Lõi | LUT lần trước → phục hồi | FF mới | F2F D/CE lần trước → phục hồi (ns) | WNS toàn giao diện (ns) | WHS (ns) |
|---|---:|---:|---:|---:|---:|
| MAC-NF | 1564 → 1582 | 916 | 6.382 → 6.314 | 1.843 | -0.055 |
| MAC-F | 1239 → 1235 | 781 | 5.884 → 5.430 | 2.689 | -0.055 |

## F2F đầy đủ theo nhóm thanh ghi đích

Các số sau là độ trễ lớn nhất C→D/CE, tính từ mọi thanh ghi launch trong thiết kế tới nhóm thanh ghi đích. Bao gồm dữ liệu, metadata, flags, valid và clock enable; không đồng nghĩa chỉ đo từ tầng liền trước. CSV lưu riêng D-only và D/CE, logic/net delay, số tầng logic và hai đầu đường đi.

| Nhóm đích | NF (ns) | F (ns) |
|---|---:|---:|
| Parser A P1 | 5.278 | 4.040 |
| Parser A P2 | 5.019 | 5.019 |
| Parser B P1 | 5.278 | 4.040 |
| Parser B P2 | 5.019 | 5.019 |
| Parser C P1 | 5.278 | 4.040 |
| Parser C P2 | 3.638 | 3.638 |
| Multiplier context | 6.314 | 5.038 |
| Multiplier SAC / control | 6.048 | 5.430 |
| Multiplier T1 | 5.011 | 4.601 |
| Multiplier T2 | 2.914 | 2.923 |
| Multiplier accumulator / result | 3.022 | 3.022 |
| Adder S1 | 4.107 | 4.819 |
| Adder S2 | 4.851 | 4.851 |
| Adder S3 | 2.958 | 2.958 |
| Adder S4 | 3.450 | 3.450 |
| Adder S5 (đầy đủ) | 3.616 | 3.616 |
| Final Packer P1 | 4.732 | 4.271 |
| Final Packer P2 (đầy đủ) | 4.934 | 4.732 |
| Product Packer P1 | 5.030 | — |
| Product Packer P2 | 4.350 | — |
| Wrapper control / context | 6.134 | 4.164 |
| Reset synchronizers | 0.670 | 0.670 |
| Product Packer P2 — sign_q riêng | 3.520 | — |

Không cộng các giá trị F2F giữa các tầng. Đây là các đường song song và có thể xuất phát từ tầng/control khác nhau. Nhóm reset_sync có đường FF→FF nếu tồn tại, không phải kiểm tra recovery/removal của chân reset bất đồng bộ.

Riêng NF, bộ phân nhóm tách sign_q_reg của Product Packer thành product_pack_other; đây là metadata thuộc P2. Đường tới sign_q là 3,520 ns, nhỏ hơn cực đại P2 4,350 ns, nên gộp metadata này vào P2 không làm thay đổi con số cực đại P2. Inventory và báo cáo riêng vẫn giữ để kiểm lại.

## Đường găng và kiểm tra độ đầy đủ

- MAC-NF: `u_dut/u_wrapper/u_b/p2_frac_q_reg[10]/C` → `u_dut/u_wrapper/u_core/input_cut_o_reg/D`; tổng 6.314 ns = logic 1.371 + net ước lượng 4.943 ns.
- Inventory NF: 916 thanh ghi, mỗi cell được gán đúng một nhóm; 23 nhóm. Đối chiếu stage_register_inventory.csv với register_count trong báo cáo từng nhóm.
- MAC-F: `u_dut/u_wrapper/u_a/p2_frac_q_reg[8]/C` → `u_dut/u_wrapper/u_core/fx_q_reg[10]/D`; tổng 5.430 ns = logic 1.247 + net ước lượng 4.183 ns.
- Inventory F: 781 thanh ghi, mỗi cell được gán đúng một nhóm; 20 nhóm. Đối chiếu stage_register_inventory.csv với register_count trong báo cáo từng nhóm.

Báo cáo cũ vẫn giữ nguyên f2f_stages.csv để so sánh cùng phạm vi với lần trước: adder_s5 cũ chỉ chọn frac_hi_q, final_pack_p2 cũ chỉ chọn d_q. Các nhóm đầy đủ trong f2f_full_stages.csv mới bao gồm sf/sticky/sign/tags/flags và valid tương ứng. Khi so sánh phải dùng cùng định nghĩa nhóm.

## Kiểm chứng và dữ liệu lưu

- Strict lint: 31 module, 68 instance, PASS. Golden mixed regression: 100.000 completed mỗi lõi, 0 mismatch, đủ 26 tổ hợp OPS0/1 × n0..12. Đây là pilot kiểm chứng snapshot, không phải full coverage signoff.
- Chỉ Packer được phục hồi; hợp đồng raw payload Zero/NaR của adder sau bỏ clear_val vẫn khác bản khóa cũ. Lần này không chạy lại testbench raw-bus adder cũ; bằng chứng FAIL/raw và PASS/semantic của cùng adder được giữ ở results/refactor_lut_20261106.
- f2f_all_stages.csv: bảng hợp nhất NF/F, cả D-only và D/CE; summary.json chứa số đo và đường găng đầy đủ.
- candidate/synth_nf và candidate/synth_f: DCP, utilization, timing, CSV, báo cáo top 20 đường từng nhóm, inventory, constraints, execution receipt và log.
- candidate/manifest.json + candidate/source: đầu vào có SHA-256; kiểm tra snapshot và source live trước khi lập báo cáo.
- candidate/source/results/verification: log, build manifest và báo cáo golden/lint mới.
- detailed_stages.tcl: định nghĩa nhóm thanh ghi; measure.py: recipe synthesis gốc chỉ bổ sung reporting; evidence.sha256.json: hash các kết quả để kiểm lại.

Độ trễ net trong báo cáo là ước lượng chưa place/route. Không công bố các số này là Fmax thực tế trên kit; WHS âm vẫn cần xử lý trong luồng implementation nếu muốn signoff timing.
