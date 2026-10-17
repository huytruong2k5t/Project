# Constraint và luồng đo A35T

**Hợp đồng mới: A35T-C1, 17/10/2026.** Chỉ dùng xc7a35tcpg236-1. Tách timing nội bộ IP khỏi timing giao tiếp; không lấy giả định I/O của run lịch sử làm thông số board.

## 1. Các file dùng cho phép đo tiếp theo

| File | Vai trò |
| --- | --- |
| constraints/a35t_clock.xdc | Clock10ns, uncertainty setup0,100ns và hold0,100ns; dùng chung NF/F, synthesis và implementation |
| constraints/a35t_io_template.xdc | Mẫu system-synchronous; min/max và nguồn timing để trống có chủ ý; phải cấu hình bản sao trước tích hợp |
| run_a35t.tcl | Đọc XDC trước synthesis, chỉ part A35T; chế độ validate/synth/implement |
| ../scripts/run_a35t_sta.ps1 | Runner khóa snapshot nguồn/XDC/hash và thư mục kết quả mới |

Các script cũ dưới scripts/ giữ nguyên để tái lập đúng checkpoint. measured_constraints.xdc trong results/ là bản xuất của từng run, không phải file chỉnh chung. Không sửa snapshot hoặc cập nhật hash lịch sử để đổi điều kiện đo.

## 2. Hai phạm vi constraint

### ip_ooc — mặc định, chỉ đánh giá R2R

Chỉ nạp a35t_clock.xdc. Không set_input_delay, set_output_delay, false-path hoặc multicycle để làm số đẹp. Không tự coi input sớm nhất là2,5ns. Giữ cả100ps hold uncertainty; không nới hold margin.

Các đường thanh ghi→thanh ghi (D/CE) trong thiết kế được timing theo clock. Các đường port→FF đầu, FF cuối→port và control từ cổng ngoài chưa có timing giao tiếp: check_timing có thể báo no_input_delay/no_output_delay và I/O unconstrained. Đây là giới hạn công khai của profile, không được gọi toàn thiết kế đã signoff. Unconstrained endpoints nội bộ hoặc no_clock vẫn phải được giải quyết; không dùng giới hạn I/O để bỏ qua lỗi nội bộ.

Wrapper hiện có chỉ BUFG, không thêm input/output FF. Vì vậy R2R không xác nhận trọn đường dữ liệu đầu vào parser P1 hoặc đường out_ready→control. Nếu cần benchmark toàn bộ core từ một nguồn FF nội bộ, phải thiết kế wrapper có FF biên riêng và báo overhead/latency benchmark; chưa thêm wrapper đó trong lần chuẩn hóa này. Không đổi14 tầng NF/13 tầng F của IP.

### integration — có thông số giao tiếp thật

Đọc clock chung, sau đó bản sao I/O XDC do người tích hợp cấu hình. Không có default I/O budget. Mẫu hiện dùng cùng clock tham chiếu clk và chia nhóm data/control; mỗi nhóm cần min/max riêng và reference/datasheet/timing của nguồn/đích. Tùy giao tiếp thực tế có thể cần chia từng port, virtual/generated clock hoặc phase khác; không ép giao tiếp khác vào mẫu cùng-clock này.

Input delay lấy từ clock-to-output và quan hệ đường data/clock của nguồn, quy về biên thiết kế. Output delay từ setup/hold và quan hệ data/clock tới đích; min có thể âm. Không mặc định min=max, không chọn min chỉ để xóa hold. rst_n của top là input đồng bộ của reset bridge, cũng cần budget nếu dùng profile tích hợp này. Mẫu fail khi trống, max<min, trùng/thiếu port hoặc sai hướng; chưa có thông số thật thì không chạy integration.

Đây vẫn là timing contract tại biên IP. Pinout, IOSTANDARD, nguồn clock/PLL và thiết kế tích hợp thực tế phải được review riêng trước board signoff. Không đưa pin giả hoặc kết luận board hoạt động từ OOC.

## 3. Lệnh từ gốc Posit_MAC

Mặc định chỉ validate: đọc RTL, elaborate và kiểm XDC/clock, không full synthesis, place/route hoặc mô phỏng.

```powershell
./scripts/run_a35t_sta.ps1 -Variant nf -Profile ip_ooc -Action validate -RunRoot results/a35t_new_validate_nf
./scripts/run_a35t_sta.ps1 -Variant f -Profile ip_ooc -Action validate -RunRoot results/a35t_new_validate_f
```

Khi được yêu cầu đo tiếp, chọn RunRoot mới và Action synth hoặc implement. synth chỉ là số liệu sau synthesis; implement mới tạo post-route reports. Runner từ chối ghi đè thư mục có sẵn. COMPLETE chỉ xác nhận chạy xong, không tự có nghĩa timing PASS.

```powershell
./scripts/run_a35t_sta.ps1 -Variant nf -Profile ip_ooc -Action implement -RunRoot results/a35t_new_nf
```

Variant nf dùng production NF32/3 FW12 EXACT_EN1; variant f dùng F32/3 FW12/W32 EXACT_EN0. Không compile OPT-02b candidate trong luồng mặc định, không coi đây là comparator NF EXACT_EN0 đã nghiệm thu hoặc paired PPA công bằng. Chọn candidate/comparator mới phải có source list/manifest và kiểm chức năng riêng trước đo.

Tích hợp: copy syn/constraints/a35t_io_template.xdc sang file mới trong dự án, điền timing thật rồi truyền -Profile integration -IoXdc đường_dẫn_tương_đối. Không chạy file mẫu chưa điền. Không có file board constraint hoàn chỉnh trong phiên này.

## 4. Kết quả và diễn giải

Mỗi run giữ manifest.json (nguồn/XDC/runner SHA, variant/profile/action/lệnh), scope.txt, clocks.rpt, effective_constraints.xdc và log. Implementation thêm routed checkpoint, R2R setup/hold, timing/unconstrained, utilization/hierarchy/route/DRC/methodology. Database/binary không push Git; giữ báo cáo gọn và snapshot cần tái lập.

Không trộn WNS/hold hoặc min/median/max của A35T-C1 với các run cũ min=max input2,5ns. Khác cả thời điểm nạp constraint trước synthesis có thể làm netlist và P&R đổi: cần baseline/candidate matched mới trước kết luận lợi ích. Số đo cũ và kết luận phạm vi cũ vẫn giữ nguyên trong Optimization.

Chi tiết và trạng thái: [Optimization](../../doc/Optimization.md), [PLAN build](../l1/PLAN.md), [tiến độ](../docs/TIEN_DO_DO_AN.md). Đợt này chỉ chuẩn hóa và kiểm nạp ràng buộc, không nghiệm thu Fmax mới.

Bằng chứng kiểm nạp C1: results/a35t_c1_constraints_20261017/summary.json và evidence.zip. Ba lượt nạp hợp lệ không warning/error; mẫu trống bị từ chối. Các lượt thử lỗi cũ chỉ ở nhóm intermediate_not_acceptance. Test I/O dùng số giả lập, không phải board budget.
