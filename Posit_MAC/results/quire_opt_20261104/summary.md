# Tối ưu MAC-quire — 04/11/2026

Đã triển khai theo Optimization §8.42: giữ nguyên Posit32/ES3, approximate12 FULL_TERM26/Q24, Q signed972/grid2^-480, L_max1024, CLEAR/MAC/READ và RNE chỉ khi READ. Chỉ bốn module quire riêng thay đổi; RTL NF/F và oracle độc lập giữ nguyên.

## Kết quả synthesis đối chứng

Vivado2026.1, xc7a35tcpg236-1, OOC clock10ns, uncertainty0.1ns, input max/min2.5ns, output max0.5ns/min0ns; constraints được đọc trước synthesis. Cả hai snapshot dùng cùng recipe, DSP0/BRAM0. Không place/route/bitstream.

| Chỉ tiêu | Backend trước sửa | Backend tối ưu |
|---|---:|---:|
| LUT | 10156 | 2888 |
| FF | 4458 | 2636 |
| F2F D/CE (ns) | 18.483 | 9.579 |
| 1000/F2F (MHz) | 54.1 | 104.4 |
| Fmax nội bộ tính setup/skew/uncertainty (MHz) | 52.7 | 101.7 |
| Fmax toàn giao diện ước lượng (MHz) | 52.7 | 101.7 |
| Setup WNS tại10ns | -8.965 | +0.170 |
| Hold WHS | -0.055 | -0.055 |

Giảm LUT71.6%, FF40.9%, F2F48.2%. Nghịch đảo datapath chỉ là trần sơ bộ; ước lượng nội bộ dùng1000/(10−worst_F2F_slack), toàn giao diện dùng1000/(10−WNS). Net delay là ước lượng unplaced; hold âm nên chưa timing signoff hoặc Fmax board.

Critical path mới: `u_dut/u_wrapper/pre_magnitude_q_reg[5]/C` → `u_dut/u_wrapper/u_bank/index_q_reg[0]/D`; 3.173ns logic +6.406ns net ước lượng, 11 mức logic. Đường găng đã chuyển sang tạo descriptor/địa chỉ word; không còn barrel shifter972 bit hoặc NOR term972 bit trên đường bank accept.

## Thiết kế đã thay đổi

- Thêm bank prepack43 bit, chốt magnitude26/scale11/sign/zero/NaR/error/loss/cut trước khâu align; thêm một chu kỳ trên MAC.
- `quire_align_comb` tạo coefficient27 bit +word_index5 +bit_offset6, vẫn kiểm suffix khi scale âm và báo invalid khi ngoài bound; giữ nguyên số học và dấu.
- `quire_bank` dựng từng term word bằng shifter cục bộ63 bit; thay term_work972 bit bằng descriptor38 bit. Q và pending tổ chức27 word36, không dịch cả vector mỗi clock. Còn một shadow transaction để bảo toàn Q trên overflow và không lộ partial Q. Entry pending cuối không cần lưu vì word cuối commit trực tiếp.
- READ dùng bank Q ổn định nhờ một lệnh outstanding, không sao chép972 bit. Mỗi word qua FETCH lấy trị tuyệt đối36 bit rồi REDUCE tìm bit đầu, ghép cửa sổ và OR tail; chỉ giữ hai word trước, một abs word và sticky. Phép RNE vẫn chỉ ở Packer cuối.
- Recipe synthesis mới và recipe route cũ đều đọc XDC clock/I/O trước synth. Lượt này chỉ chạy recipe synthesis mới.

Kế hoạch cũ ước lượng READ có ba bản972 bit; snapshot thực tế ở đầu lượt này chỉ có một `work_q` trong READ. Báo cáo dùng số tài nguyên đo thực tế, không lấy ước lượng tiết kiệm trong kế hoạch làm kết quả.

Đánh đổi latency: MAC thêm tầng prepack; READ quét27 word×2 pha kể cả Q=0/NaR. Nhờ ownership của top, Q không thay đổi trong READ; leaf READ yêu cầu bank đầu vào ổn định cho tới khi hoàn tất. Tính atomic và reset epoch được giữ. Đây là lựa chọn tiết kiệm tài nguyên; chưa tối ưu latency READ zero/NaR.

## Verification mới trên đúng nguồn

- Strict lint19 module,26 instance +1 BUFG đủ cổng.
- Unit:32768 align trên toàn signed sf bus/cả dấu;21948 READ so sf/fraction53/sticky/RNE;11061 bank gồm10000 phép cộng compact ngẫu nhiên độc lập, biên word, carry/borrow, overflow bảo toàn Q, count/capacity và không lộ partial Q.
- ModelSim bigint fixtures:4881 accepted,4876 completed +5 reset-aborted,0 mismatch;4833 commit,19512 chu kỳ stall,72 kiểm invalid.
- pilot_opt: 100000 MAC retired,0 mismatch; 208 chuỗi>12, 4 chuỗi1024; seed20261103, 5 reset-aborted, latency retire quan sát3..63 chu kỳ. Q972 bit được so từng commit với hai model độc lập; toàn26 OPS×n được kiểm trong pilot.
- default_1m: 1000000 MAC retired,0 mismatch; 1915 chuỗi>12, 5 chuỗi1024; seed20261104, 5 reset-aborted, latency retire quan sát3..64 chu kỳ. Q972 bit được so từng commit với hai model độc lập; toàn26 OPS×n được kiểm trong pilot.

Đây là regression1.1M MAC mới, chưa thay main10M/coverage của snapshot03/11 và chưa gắn MAC_Q12_VERIFIED. Số route cũ10339LUT/4453FF,WNS−12.016ns thuộc snapshot/flow khác; không dùng để suy mức cải thiện timing sau route của bản này.

[CSV đối chứng](comparison.csv) · [Summary và source guards](summary.json) · [Nguồn trước](before/source/rtl/mac_quire/quire_bank.sv) · [Nguồn đã verify](verified_source/rtl/mac_quire/quire_bank.sv) · [F2F sau tối ưu](synth_after/f2f_stages.csv) · [Worst paths](synth_after/whole_D_CE.rpt) · [ModelSim](modelsim_opt/manifest.json).

Giữ source, vector, recipe, manifest, log, DCP và reports trong synth_before/synth_after. Các cache/work/binary có thể build lại theo runner với QUIRE_RESULTS_ROOT mới. Không sửa hoặc kế thừa checkpoint03/11 như nghiệm thu của nguồn mới.
