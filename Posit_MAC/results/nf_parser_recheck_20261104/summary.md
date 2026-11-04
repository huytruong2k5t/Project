# Synthesis MAC-NF sau chỉnh parser/core — 04/11/2026

Đã chạy một lượt synthesis MAC-NF từ code người dùng chỉnh sửa, trên Vivado2026.1, `xc7a35tcpg236-1`. Không sửa RTL, không synthesis F, không implementation/route/bitstream. Snapshot54 file đầu vào giữ nguyên hash và khớp nguồn live khi hoàn tất.

Giữ điều kiện lần trước: OOC, flatten rebuilt, clock10ns, uncertainty setup/hold0.1ns, input max/min2.5ns, output max0.5ns/min0ns, không DSP/BRAM. Adapter `prepack_nf_ppa_top` chỉ thêm BUFG.

| Chỉ tiêu | NF Phương án A trước sửa parser/core | NF hiện tại |
|---|---:|---:|
| F2F C→D/CE |8.945ns|**6.314ns**|
| Nghịch đảo datapath1000/F2F |111.8MHz|**158.4MHz**|
| Fmax nội bộ ước lượng có setup/skew/uncertainty |106.1MHz|**152.3MHz**|
| Fmax toàn giao diện ước lượng |91.3MHz|**122.6MHz**|
| Slice LUT |1613|**1604**|
| FF |942|**916**|
| Setup WNS tại10ns |−0.955ns|**+1.843ns**|
| Hold WHS |−0.055ns|−0.055ns|

F2F giảm **29.4%**. Nghịch đảo datapath không bao gồm setup/skew/uncertainty; ước lượng nội bộ dùng `1000/(10 − worst_F2F_slack)` với slack3.435ns. Toàn giao diện dùng `1000/(10 − WNS)`; đường setup giới hạn toàn giao diện hiện là `out_ready → in_ready`. Đây là ước lượng unplaced sau synthesis, chưa là Fmax đạt sau route. Hold vẫn âm nên chưa timing signoff.

## Thay đổi nguồn được đo

- Parser A/B chuyển sang `posit_parser_mul`: P2 chỉ giữ fraction12 bit và `tail_cut`, thay26 fraction bit. Tổng FF giảm26 phù hợp với hai bank giảm13 bit mỗi bank.
- `posit_parser` dùng magnitude CARRY và grouped regime LOD.
- `mul_iter_core.launch_ready` bỏ điều kiện phụ thuộc `y_mant`. Đường Parser B→OPS→kiểm hợp lệ Y→launch/CE từng dài8.945ns không còn là critical path.

Đường F2F mới:

`u_dut/u_wrapper/u_b/p2_frac_q_reg[10]/C` → `u_dut/u_wrapper/u_core/input_cut_o_reg/D`.

Tổng6.314ns = **1.371ns logic +4.943ns net ước lượng**,6 mức LUT. Report đi qua logic OPS/chọn toán hạng và xử lý metadata vào core; tên net/cell sau flatten có thể được Vivado gắn dưới hierarchy Parser A. Khoảng78.3% delay của đường là net ước lượng.

## Verification và bằng chứng

Trước synthesis đã chụp nguồn và chạy ModelSim:

- NF10000 request: **9940 completed +60 reset-aborted,0 mismatch**;36231 chu kỳ giữ output, latency quan sát15..26. Driver hồi tiếp ngoài có6211 completed, chuỗi dài nhất70.
- Adder39534 completed; packer10851 completed; multiplier core53249 case/231437 checkpoint, đều PASS.
- Đây là regression mới trên đúng snapshot hiện tại. Không kế thừa100k PASS trong `parser_unified_20261104` vì `posit_parser_mul.sv` đã đổi sau lượt build đó. Chưa là ma trận nghiệm thu52×10M hoặc coverage mới.

[Summary và hash](summary.json) · [CSV trước/sau](comparison.csv) · [F2F từng bank](synth_nf/f2f_stages.csv) · [Critical paths D/CE](synth_nf/whole_D_CE.rpt) · [Timing toàn giao diện](synth_nf/synthesis_timing.rpt) · [Utilization](synth_nf/synthesis_utilization.rpt) · [Snapshot RTL](source/rtl/mac_nf/mac_nf_wrapper.sv).

Giữ `manifest.json`, `source/`, vectors, log verification, recipe đo và DCP để kiểm chứng lại. Chỉ runner được bổ sung lựa chọn VerifyScope NF và guard tương ứng; không thay đổi RTL người dùng.
