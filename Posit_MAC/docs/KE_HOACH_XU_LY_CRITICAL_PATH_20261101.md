# Kế hoạch xử lý critical path MAC NF/F

Ngày lập: 01/11/2026. Cập nhật: đã thực hiện phần F, chọn P00 sau bốn thử nghiệm đã verify/synthesis; F2F7.697→6.602ns, LUT1374→1265, FF820 giữ nguyên. [Báo cáo và bằng chứng](../results/f_timing_optimization_20261101/summary.md). Chưa triển khai tối ưu NF hoặc thêm pipeline. Các mục bên dưới giữ kế hoạch và điều kiện thử nghiệm ban đầu.

## 1. Kết quả cần đạt và phạm vi

Giảm độ trễ toàn MAC trên Artix-7 xc7a35tcpg236-1 bằng thay đổi có thể kiểm chứng, trước hết giữ nguyên số học, valid/ready, reset và số tầng pipeline. Ưu tiên F vì lần refactor gần nhất làm F2F tăng; NF xử lý theo đường OPS→SAC riêng.

| Mốc đo | F F2F / LUT / FF | NF F2F / LUT / FF |
| --- | --- | --- |
| Bản trước refactor Parser/LOD | 6.602 ns / 1257 / 820 | 7.334 ns / 2098 / 1077 |
| Bản đang chẩn đoán | 7.697 ns / 1374 / 820 | 7.334 ns / 2214 / 1077 |
| Mục tiêu đầu tiên | Khôi phục F2F ≤6.602 ns | Giảm xuống dưới7.334 ns |

Mục tiêu tối ưu tiếp theo là vượt bản trước refactor, đồng thời đánh giá LUT/FF và latency/II. Chưa đặt yêu cầu200MHz hay suy Fmax bằng nghịch đảo Data Path Delay.

Nguồn bằng chứng: [báo cáo đo](../results/parser_lod_refactor_recheck_20261101/summary.md), [chẩn đoán từng cell/net](../results/parser_lod_refactor_recheck_20261101/critical_path_diagnosis_final/diagnosis.md).

Giữ cùng Vivado2026.1, OOC synthesis, clock10ns, uncertainty0.1ns, input min=max2.5ns, output min0/max0.5ns, rebuilt hierarchy, DSP/BRAM0. Các lần thực thi thuộc kế hoạch chính gồm verification, synthesis và truy vấn DCP. Place/route, bitstream và đo trên kit là giai đoạn riêng nếu mở rộng phạm vi sau này; chưa thuộc kế hoạch thực thi chính.

## 2. Bước 0 — Khóa phép so sánh trước khi sửa

1. Lưu baseline cũ, bản hiện tại, RTL/TB/file list/constraints/golden bằng manifest SHA256 trong thư mục riêng; không ghi đè kết quả đã có. Nếu working tree đã thay đổi so với snapshot đang chẩn đoán, coi đó là candidate mới và verify trước khi dùng số đo.
2. Dùng snapshot hiện tại làm gốc của mọi candidate; áp đúng một thay đổi đã ghi tên. Không sửa trực tiếp baseline hoặc golden để làm expected khớp DUT.
3. Giữ số học FLOOR hiện hành cho loạt tối ưu timing đầu tiên: NF approximate n0..8, F n0..12, OPS0/1, Posit(32,3). Chưa trộn FULL_TERM26/Q24, tăng N_MAX hoặc thay precision vào cùng phép thử timing.
4. Theo SPEC mục tiêu, NF sẽ cần approximate-only. Thử bỏ exact ở bước NF dưới đây là một thay đổi phạm vi chức năng có báo cáo riêng, không gọi là equivalence trên mọi cấu hình của phần cứng cũ. Chưa tự động nghiệm thu FULL_TERM chỉ vì đã bỏ exact.

Đầu ra: manifest, bảng candidate và cùng một tập vector/seed cho các phép so sánh trực tiếp.

## 3. Bước 1 — Tách ảnh hưởng magnitude và LOD ở F

Vấn đề đã đo: logic giảm1.383ns nhưng net tăng2.478ns; sign C_eff[31] có64 sinks; cone count[0] tăng52→89 LUT. Chưa biết riêng hai thay đổi đóng góp bao nhiêu.

Thử ma trận dưới đây, giữ wrapper, C_eff, pipeline và các module khác giống nhau:

| Candidate | Magnitude Parser | LOD regime Parser | Mục đích |
| --- | --- | --- | --- |
| P00 | Bù hai dùng carry | Group/radix cũ | Mốc đối chứng trong ma trận |
| P01 | Bù hai dùng carry | Flat casez hiện tại | Đo riêng đổi LOD khi giữ carry |
| P10 | Prefix-OR hiện tại | Group/radix cũ | Đo riêng đổi magnitude khi giữ LOD cũ |
| P11 | Prefix-OR hiện tại | Flat casez hiện tại | Bản hiện tại; tái dùng số đo nếu hash/recipe trùng |

Điểm kiểm soát bắt buộc: `lod_lzd_core_fixed2` đang được gọi bởi `posit_parser`, `posit_add_lod_comb` và `posit_magnitude_parse` của NF. Đưa LOD regime thử nghiệm vào module/file riêng hoặc thay binding riêng tại parser; giữ LOD bộ cộng và decode tích giống bản hiện tại trong cả bốn candidate. P00 vì vậy không hoàn toàn giống baseline lịch sử, vốn có LOD cũ cả ở bộ cộng. Cần giữ cả baseline lịch sử và P00 để phân biệt ảnh hưởng.

Trình tự: verify candidate → synth top F → trích toàn-top và cone Parser C; chỉ chạy tích hợp/synth NF với phương án F được chọn vì parser dùng chung. Ba candidate mới là giới hạn thử đầu; không chạy lặp thêm khi không có giả thuyết mới.

Điểm đo: cả5 bit p1_cnt, sign/payload P1, toàn bộ F2F và top20 path, input-to-P1, LUT/FF, fanout sign, độ trễ từng net lớn, WNS/WHS. Không chỉ theo dõi endpoint count[0], vì critical có thể chuyển sang count[3]/[4], adder hoặc packer.

Điều kiện sang bước2: đã xác định được tổ hợp tốt nhất và phần thay đổi nào làm chậm. Nếu tổ hợp này đã đạt mục tiêu, dừng sửa F và chuyển sang NF.

## 4. Bước 2 — Tối ưu cone Parser bằng cấu trúc rõ ràng

Chỉ mở bước này nếu cần cải thiện thêm sau ma trận; thực hiện từng phương án và dừng khi không còn lợi ích toàn top.

| Thứ tự | Phương án | Điều cần kiểm qua netlist |
| --- | --- | --- |
| F1 | Giữ carry magnitude nếu bước1 cho kết quả tốt; dùng decoder regime phù hợp riêng Parser | Không kéo thay đổi LOD của Parser sang adder đang có S4 tốt hơn |
| F2 | Nếu giữ prefix: mô tả prefix theo nhóm/cây cân bằng, đồng thời chia decoder thành group-valid và encoder trong nhóm | Sign còn bao nhiêu sinks; chain LUT vào K[0] và K[3:4] có ngắn lại; synthesis có gộp lại thành cone cũ không |
| F3 | Tách cone tạo count khỏi cone payload, giảm chia sẻ trung gian làm sign đi xuyên nhiều nhánh hội tụ | LUT tăng/giảm bao nhiêu; critical path có giảm thật; logic nhân bản có bị synthesis gộp lại không |

Giả thuyết là điều chỉnh topology sẽ giảm phụ thuộc và net delay ước lượng. Chưa bảo đảm chỉ bằng đổi cú pháp, đổi tên module hay nhân bản wire. Không mặc định ép DONT_TOUCH/KEEP/MAX_FANOUT trên toàn parser: chỉ thử directive cục bộ khi đã chỉ rõ net cần kiểm và so sánh với bản không directive.

Không đẩy toàn bộ decode sang sau MUX ở một dạng khác rồi mặc định nhanh hơn. Nếu thử tính sẵn nhiều nhánh rồi chọn cuối, phải tính cả chi phí nhân bản decoder và MUX đầu ra trên toàn top.

Đầu ra F: một candidate được verify đầy đủ, F2F không tệ hơn6.602ns, kèm báo cáo area/timing và critical path mới. Nếu không đạt, giữ baseline tốt làm phương án phục hồi và ghi rõ kết quả âm.

## 5. Bước 3 — Xử lý đúng điểm nghẽn NF: OPS→SAC

Đường hiện tại: Parser B P2 fraction→mask/popcount→compare→choose_b→swap/bypass→MUX nạp/feedback SAC. Fanout choose_b=52; toàn đường7.334ns. Tối ưu Parser P1 không cắt đường này.

1. Chốt approximate-only theo SPEC trong một candidate riêng: bỏ nhánh exact/cfg_mode khỏi lõi thực sự và các bank/đường full26 chỉ phục vụ exact; giữ adapter legacy ngoài lõi nếu cần tương thích giao diện cũ. Giữ n0..8 và FLOOR ở loạt thử này để không thay đồng thời thuật toán/precision/giới hạn vòng. Xác định rõ oracle/profile và các cổng mới trước khi chạy; chưa gọi đây là lõi đạt SPEC v1.25.
2. So bit-exact candidate với baseline trong miền approximate hợp lệ; kiểm riêng từ chối cấu hình ở adapter. Synthesis không dùng false-path hoặc case-analysis để che đường còn tồn tại trong phần cứng đa chế độ. Nếu chỉ làm STA riêng mode, phải ghi đó là kết quả giới hạn mode, không so ngang với worst-case toàn mode.
3. Trên kiến trúc đã chọn, thử nhóm popcount12 và compare theo cấu trúc rõ, mỗi lần chỉ đổi một cone. Theo dõi cả count A/B, compare, choose_b và output swap; không dự đoán2–3 LUT cho toàn đường từ việc helper có6 input.
4. Tối ưu đoạn cuối swap/bypass và MUX launch/feedback vào fx_q; giảm tầng chọn nối tiếp nếu có thể chứng minh tương đương. Không đổi ưu tiên launch, điều kiện phát token hay trạng thái vòng lặp để lấy timing.

Đo tất cả đường vào SAC/OPS context/L1 và các đường khác của toàn NF; kiểm critical không đơn giản chuyển sang feedback SAC, parser hoặc accumulator.

Đầu ra NF: candidate F2F dưới7.334ns trong phạm vi đã công bố, với LUT/FF, latency/II và WNS/WHS. Chênh lệch do bỏ exact phải tách khỏi chênh lệch do refactor OPS.

## 6. Bước 4 — Chỉ đổi pipeline nếu các bước trước chưa đủ

Ưu tiên giữ pipeline hiện tại. Các phương án dưới đây là nhánh kiến trúc dự phòng, không triển khai cùng lúc với tối ưu tổ hợp.

| Phương án | Ranh giới cần tách | Điều phải sửa/kiểm |
| --- | --- | --- |
| F-C0: thanh ghi đầu vào Parser C | accumulator→MUX C_eff→C0; C0→decode→P1 | Capture C_eff đúng lúc accept; valid/ready C0; A/B và context chờ C đúng giao dịch; reset flush; dự kiến thêm1 chu kỳ cần đo lại |
| NF-M0: thanh ghi kết quả OPS trước SAC | Parser P2→OPS→M0; M0→SAC | Giữ X/Y, sf/sign, n và cờ cùng giao dịch; launch chỉ khi M0 retire; bypass/done/context/reset; đo lại latency/II |

Thêm FF không mặc định cải thiện tốc độ xử lý: với MAC phụ thuộc trạng thái, phải đo cycles/transaction, thời gian giao dịch tại clock mục tiêu và II bên cạnh F2F. Điểm nghẽn có thể chuyển sang đường khác sau khi chia stage.

Chưa ưu tiên cache sẵn C ở dạng decoded: cache phải phản ánh mã accumulator đã RNE/kẹp biên cuối cùng, và việc tạo cache có thể chuyển critical sang packer→decoder hoặc thêm độ trễ sẵn sàng. Chỉ mở phương án này khi hai ranh giới đơn giản trên không phù hợp.

## 7. Verification và điều kiện chọn candidate

| Lớp kiểm | Nội dung cần đạt |
| --- | --- |
| Parser/LOD | Magnitude4M vector đối chiếu arithmetic; LOD500063 vector với oracle serial; parser đầy đủ so decoded fields và handshake, gồm số âm/Zero/NaR/minpos/maxpos, walking-bit, regime dài |
| Tích hợp | Adder39534 completed, packer suite hiện hành; OPS149152 check nếu chạm OPS; MAC NF/F50000 accepted/top, so d và đủ5 flags với golden đúng profile |
| Trạng thái | Chained accumulation; clear chỉ tại accept; đổi input/config sau accept; stall dài; reset khi pending/output stalled; invalid cfg; không update accumulator lặp do backpressure |
| Kế toán giao dịch | accepted=completed+reset-aborted; không mất/lặp/đảo thứ tự; output giữ nguyên khi stall; timeout và mismatch trả lỗi thực sự |
| Nếu thêm pipeline | Scoreboard theo handshake, không hard-code latency; kiểm đồng bộ A/B/C/context và đo lại latency/II theo n, early-stop |

Các con số trên là mức regression ban đầu, không là nghiệm thu52 điểm/520M của SPEC. Với biến thể parser riêng, harness phải so module thực sự đang dùng, không chỉ tự tính công thức thay DUT.

Điều kiện chọn:

- Zero mismatch trong các suite liên quan, oracle và miền chức năng giữ đúng như khai báo.
- F khôi phục≤6.602ns rồi mới tuyên bố cải thiện vượt baseline; NF phải dưới7.334ns. Candidate chỉ tốt hơn bản7.697ns nhưng còn thua6.602ns được ghi nhận là tiến bộ trung gian.
- Đánh giá setup slack và hold toàn top, I/O, F2F và top20 path dưới cùng constraints. Không chọn chỉ vì một endpoint hay số tầng LUT giảm; nếu WNS/WHS xấu đi phải ghi rõ và xử lý trước khi promote.
- Báo cáo tăng LUT/FF so với baseline tương ứng; ưu tiên lợi ích timing với area hợp lý. Nhánh thêm pipeline cần thêm bảng latency/II, không so FF/chu kỳ như một refactor giữ nguyên kiến trúc.
- Dừng khi có phương án đáp ứng mục tiêu; không mở rộng sweep vô hạn. Sau khi cả F/NF được chọn, chạy một lượt regression tích hợp và synthesis xác nhận từ đúng snapshot cuối.

## 8. Đầu ra bàn giao và thứ tự thực hiện

Thứ tự: khóa snapshot → ma trận Parser F → tối ưu tổ hợp F nếu cần → approximate-only/OPS NF → pipeline dự phòng nếu cần → xác nhận snapshot cuối.

Bàn giao: RTL candidate và manifest, log verification, DCP, bảng F2F trước/sau và top20, WNS/WHS/I/O, LUT/FF, số tầng/latency/II, giải thích critical mới và thay đổi hợp đồng nếu có. Không ghi đè baseline; không dùng số synthesis để kết luận đã đóng timing sau route.

Các runner có thể tái sử dụng: `run_refactored_mac.ps1`, `run_parser_lod_recheck.ps1`, `report_refactored_mac_f2f.ps1`, `query_mac_critical_paths.ps1`. Nếu thêm module hoặc đổi giao diện/profile, cập nhật file list, snapshot và harness tương ứng trước khi chạy; runner hiện tại còn ghi cứng profile FLOOR/NF8/F12, không dùng nguyên trạng cho FULL_TERM hoặc top mới.
