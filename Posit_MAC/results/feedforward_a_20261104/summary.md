# Phương án A NF/F — kết quả 04/11/2026

Đã bỏ `accumulator_q`, `acc_mode`, `acc_clr` và MUX `c_eff` trong hai lõi NF/F. Cổng `c` nối thẳng vào Parser C. Chỉ bốn file top/wrapper RTL thay đổi; multiplier FULL_TERM26/Q24, parser, adder5 và packer giữ nguyên byte. Quire là IP riêng, giữ nguyên thanh ghi Q.

## Đo đối chứng cùng FULL_TERM

Vivado2026.1, xc7a35tcpg236-1, OOC synthesis, flatten rebuilt, clock10ns, setup/hold uncertainty0.1ns, input2.5ns, output max0.5ns. Mỗi NF/F đo trước/sau một lần, không place/route/bitstream. Baseline đã được kiểm trước khi chụp nguồn.

| Lõi | Snapshot | F2F D/CE (ns) | 1000/F2F (MHz) | Fmax nội bộ có setup (MHz) | Fmax toàn giao diện (MHz) | LUT | FF | WNS/WHS (ns) |
|---|---|---:|---:|---:|---:|---:|---:|---|
| NF | baseline | 9.344 | 107.0 | 101.8 | 82.6 | 1698 | 976 | -2.100/-0.055 |
| F | baseline | 6.777 | 147.6 | 143.3 | 135.4 | 1291 | 841 | +2.612/-0.055 |
| NF | candidate | 8.945 | 111.8 | 106.1 | 91.3 | 1613 | 942 | -0.955/-0.055 |
| F | candidate | 5.340 | 187.3 | 178.9 | 136.8 | 1262 | 807 | +2.689/-0.055 |

`1000/F2F` chỉ là nghịch đảo datapath. Ước lượng nội bộ có setup dùng `1000/(10 − slack_F2F_tệ_nhất)`; toàn giao diện dùng `1000/(10 − WNS_toàn_top)` với I/O budget giữ nguyên. Đây đều là ước lượng unplaced, chưa là Fmax đạt sau route. F2F bao gồm chân D và CE, không bỏ qua đường điều khiển.

## Đường găng sau sửa

- **NF**: `u_dut/u_wrapper/u_b/p2_frac_q_reg[24]/C` → `u_dut/u_wrapper/u_core/count_q_reg[0]/CE`; 1.743ns logic + 7.202ns net ước lượng = 8.945ns, 9 mức logic.
- **F**: `u_dut/u_wrapper/u_core/fx_q_reg[2]/C` → `u_dut/u_wrapper/u_core/fx_q_reg[9]/D`; 1.263ns logic + 4.077ns net ước lượng = 5.340ns, 5 mức logic.

Đã kiểm netlist không còn 32 FF hồi tiếp ở cả NF/F; tổng FF mỗi lõi giảm34 (32 dữ liệu, một acc_mode, một committed). Việc bỏ vòng hồi tiếp làm mất đường accumulator→Parser C trong IP, nhưng đường vào c→Parser C vẫn phải đáp ứng ràng buộc hệ thống. Nếu thêm thanh ghi hồi tiếp ngoài IP, phải STA lại toàn hệ thống; không kế thừa Fmax nội bộ như Fmax vòng tích lũy.

Con số5.243ns/~190MHz trong kế hoạch là dự đoán từ FLOOR cũ. Bảng này dùng baseline FULL_TERM hiện tại nên không áp trực tiếp con số lịch sử đó.

## Verification và bằng chứng

- Audit31 module,68 instance đủ cổng; strict lint từng module đạt.
- ModelSim: adder39534 completed, packer10851, core53249 case/231437 checkpoint. Mỗi NF/F50000 request,49701 completed +299 reset-aborted,0 mismatch; external-feedback31077 completed, chuỗi dài nhất70. Kiểm hold output, thay live inputs sau accept, invalid n13..15/OPS2..3 và reset khi tính/khi giữ output.
- Verilator + oracle integer độc lập: mỗi NF/F100000 completed,0 mismatch; kiểm magnitude/metadata từng vòng và26 tổ hợp n×OPS mỗi lõi trong corpus mixed.
- NF: 272789 checkpoint vòng nhân, 46977 giao dịch hồi tiếp ngoài, chuỗi dài nhất66, 448 reset-aborted.
- F: 270453 checkpoint vòng nhân, 46952 giao dịch hồi tiếp ngoài, chuỗi dài nhất66, 377 reset-aborted.

Đây là regression của thay đổi giao diện, chưa là main52×10M, chưa đo coverage mới hoặc accuracy/PPA sau route. Các kết quả cũ vẫn thuộc snapshot riêng.

[CSV đối chứng](comparison.csv) · [Summary/hash guards](summary.json) · [Nguồn trước sửa](baseline/source/rtl/mac_nf/mac_nf_wrapper.sv) · [Nguồn sau sửa](candidate/source/rtl/mac_nf/mac_nf_wrapper.sv) · [Audit](verification/ports_and_lint.json)

Các thư mục baseline/candidate giữ manifest, source, vectors, log, DCP và báo cáo theo tầng `f2f_stages.csv`, `whole_D_CE.rpt`, `input_c_to_register.rpt`. Baseline NF synthesis đã hoàn tất ngay lượt đầu; helper báo cáo gặp property Vivado không hỗ trợ, nên chỉ đọc lại DCP vào `baseline/synth_nf/f2f_recheck`, không synthesis lần hai.
