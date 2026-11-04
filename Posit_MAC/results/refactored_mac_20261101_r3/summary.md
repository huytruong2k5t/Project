# Kiểm tra refactor và synthesis MAC NF/F ngày 01/11/2026

Nguồn: snapshot `source/rtl/mac_active.f`, cùng SHA256 trong `manifest.json`. Đã kiểm lại mọi hash snapshot và xác nhận RTL làm việc không thay đổi. Vivado 2026.1, xc7a35tcpg236-1, OOC, clock10ns, uncertainty0.1ns, input min=max2.5ns, output min0/max0.5ns. Chỉ synthesis, không place/route/bitstream.

## Verification ModelSim

- ADDER_REFACTOR_PASS accepted=39535 completed=39534 aborted=1 stalls=20310
- MAC_REFACTOR_PASS F=0 rows=5000 accepted=5000 completed=4970 aborted=30 stalls=18115 latency_observed=15..22
- MAC_REFACTOR_PASS F=1 rows=5000 accepted=5000 completed=4970 aborted=30 stalls=18115 latency_observed=12..23

MAC replay dùng golden Python số nguyên độc lập cho Posit32/es3 nhưng **phép nhân FLOOR/Q12 hiện tại**: NF n0..8 và F n0..12, OPS0/1, cfg_mode1. Kiểm d/5flags theo handshake, thay đổi context sau accept, cấu hình invalid, state/clear, NaR/Zero/carry, stall dài, reset khi đang tính và khi đang giữ output; watchdog và exit FAIL khi có lỗi. Bộ cộng kiểm tương đương RTL comb/pipeline và hạch toán reset-abort, không là oracle số học độc lập.

5000 request/top là hồi quy refactor, chưa là nghiệm thu 52 điểm/520M hoặc closure coverage của SPEC. NF hardware vẫn exact-capable bank54, F bank16/FLOOR; không dùng chênh lệch tài nguyên để kết luận lợi thế kiến trúc cùng FULL_TERM.

## Synthesis

| Top | LUT | FF | DSP | BRAM | WNS synthesis (ns) | WHS synthesis (ns) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| NF | 2319 | 1066 | 0 | 0 | +1.770 | -0.055 |
| F | 1380 | 804 | 0 | 0 | +2.178 | -0.055 |

Cả hai hoàn tất synthesis, không có ERROR/CRITICAL WARNING. Setup slack dương ở clock100MHz. Hold slack âm sau synthesis chưa phải timing closure; chưa có route để kết luận setup/hold cuối, Fmax hoặc hoạt động trên board. DRC có CFGBVS-1 do chưa gán điện áp cấu hình trong benchmark OOC; chưa phải project board/bitstream. Xem raw reports trong synth_nf_final/ và synth_f_final/.

Các thư mục synth_nf/, synth_f/ và *_isolated giữ log lần khởi chạy không thành công do catalog user-app/đường dẫn XDC có dấu cách; chỉ *_final là kết quả synthesis hoàn tất. RTL không bị thay đổi trong các lần này.

## Tái chạy với thư mục mới

```powershell
./scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot results/my_refactor_run
./scripts/run_refactored_mac.ps1 -Stage SynthNF -RunRoot results/my_refactor_run
./scripts/run_refactored_mac.ps1 -Stage SynthF -RunRoot results/my_refactor_run
```

Verify chụp snapshot trước khi compile. Nguồn tham chiếu comb và dependencies chỉ thêm cho simulation, không đưa vào mac_active.f synthesis. Synthesis dùng snapshot đã PASS; execution.json ghi hash runner/Tcl thực thi, manifest.json ghi nguồn và generator. Golden, vector seed/config/counts nằm trong source/scripts/gen_refactored_mac_vectors.py và vectors/.
