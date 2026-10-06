# Điểm mơ hồ và quyết định thiết kế Posit MAC

Cập nhật 06/10/2026, đồng bộ SPEC v1.4. [SPEC §11](../SPEC_Posit_MAC_IP.md#11-quyết-định-rủi-ro-và-điều-kiện-triển-khai) giữ bảng trạng thái đầy đủ; tài liệu này tóm tắt quyết định và giới hạn, không sao chép thuật toán packer để tránh hai nguồn hợp đồng khác nhau.

## 1. Quyết định dùng cho baseline RTL

| Nội dung | Quyết định | Căn cứ |
| --- | --- | --- |
| Profile | L1 normative v0/v1; cfg_ops=0/1, hidden khởi tạo riêng, cfg_n đếm fraction. Predictor n=2/7-bit và paper_source_config là nghiên cứu riêng | SPEC §5.4–§5.6 |
| Width/cut | Approx ACC_W=FRAC_W+4 là lựa chọn dự án, không phải width paper công bố. FLOOR cắt tại FRAC_W; STICKY_ACC giữ G/R và sticky riêng. Exact giữ đầy đủ tích | SPEC §5.6 |
| Rounding | ROUND_MODE=RNE/TRUNC ở packer; ROUND_SCHEME=FLOOR/STICKY_ACC ở SBM. TRUNC về0, lỗi không luôn âm. Sticky OR không bảo toàn tổng phần dư | SPEC §4.1/§5.9 |
| Non-fused | v1 dùng round_unpacked tương đương parse(pack(u)); tích đã làm tròn trước Adder. Yêu cầu đối chuẩn SoftPosit áp cho exact/RNE ở format hỗ trợ | SPEC §5.9-C/§6 |
| Latency | E0=input handshake. H là ngân sách lần chốt; không bubble thì L_valid=H-1, L_handshake=H. Parser H=2: valid E1, handshake E2 | SPEC §5.1/§5.2 |
| n=0 / drain | Token init_only đi SAC L1→shift L2→acc L3, nạp Y một lần. n>=1, last chỉ hoàn tất ở accumulator; core launch→done=q+2, q=max(1,n) | SPEC §5.5 |
| Reset | Top rst_n đồng bộ→bridge thanh ghi→leaf reset_n; mỗi leaf đồng bộ nhả reset. Startup barrier chặn giao dịch đến khi tất cả leaf sẵn sàng, A/B/C nhận nguyên tử | SPEC §4.2 |
| Baseline capacity | Một giao dịch, một slot output dự trữ; giữ d/flags khi stalled. Không chồng lấn trước nghiệm thu baseline | SPEC §4.2/§5.11 |
| Pipeline mục tiêu | Parser cố định hai hạng đã kiểm; packer TRUNC1/RNE2 là ngân sách cần xác nhận STA. Số tầng khác cần RTL và kiểm riêng | SPEC §4.1/§5.1 |

## 2. Tối ưu và giới hạn kết luận

- FIFO/tag giữ C_eff, sign, sf, cfg và flags; độ sâu suy từ in-flight và sức chứa. Skid2 không bảo đảm lưu mọi kết quả đang bay. Pop/commit theo handshake và hợp đồng §4.2/§5.11.
- Mục tiêu II=max(1,n) chỉ áp cho giao dịch độc lập sau khi lịch khởi tạo/drain/tài nguyên đã chứng minh. Hồi tiếp v1 có cận dưới II_acc>=max(II_core,4) theo ngân sách hiện hành; chưa có số đo RTL chứng minh equality.
- Bypass đúng kết quả là bắt buộc; rút ngắn latency là tối ưu sau Gate3. Đường trực tiếp parser H=2 cần dùng chung bank output; thêm bank thì tăng H. Khi pipeline bận phải giữ in-order (§5.3).
- Ghép scale factor tương đương sf=k*2^ES+e; lợi ích LUT/fmax cần đo. Parser P1 giữ cnt/r, P2 tạo k song song shifter; giảm5 bit thanh ghi mô tả NB32, chưa chứng minh giảm5 FF vật lý.
- RTL một module/file, cổng nối theo tên, always_ff/always_comb, enable và CK2Q header chung. Không gate clock bằng LUT, không latch. Guideline reset leaf là assert bất đồng bộ/deassert đồng bộ, không gọi reset toàn dự án là một giao diện duy nhất.
- Packer/RNE chỉ theo SPEC §5.9 và oracle L1. Không duy trì pseudocode riêng với width/part-select chưa xác định. Fused v2/phần dư có dấu theo §5.12-c, ngoài đường găng Gate1..3.

## 3. Nghiệm thu và vấn đề còn mở

| Phạm vi | Trạng thái | Bằng chứng / giới hạn |
| --- | --- | --- |
| L1 Gate1/Gate1B và round_unpacked | Đã nghiệm thu | README L1 mục15, results/week6_*; số học, chưa mô phỏng thời gian toàn MAC |
| Parser RTL comb/pipeline | Đã nghiệm thu đơn vị | 2.465.812 fixture,0 mismatch; reset/stall/ordering/II; results/parser_comb/ và parser_pipeline/ |
| Table I tái dựng source | Đạt corpus đã chốt | 200 triệu accepted seed271828, max0,984213 điểm %; hai pilot seed hơi vượt1. LUT/width/generator gốc chưa xác minh |
| Table II | Chưa hoàn tất | Chốt corpus FP64→posit32 ES3, nhóm mA/mB và oracle exact ES3; giả định cả hai nằm trong nhóm phải công bố |
| Packer/core/MAC RTL | Chưa nghiệm thu | Tuần8 packer trước; reset bridge, token/drain, scoreboard và Gate2/3 sau |
| PPA toàn MAC | Chưa đo | Vivado synthesis/STA bị chặn license. OPS Quartus riêng không thay Gate4; so cùng part/ES/ràng buộc hoặc báo bậc thiết bị §7.6 |

Uniform-value/grid24 cho Table I là giả định tái dựng có seed/filter rõ ràng; uniform-bits và stratified có mục đích kiểm độ nhạy/coverage. Không đổi phân bố chỉ để ép khớp bảng, không coi coverage là corpus gốc. n_terms=n_fraction+1 chỉ đổi cách đếm cùng chuỗi khai triển; RND/complement và profile normative không tự trở thành bit-exact nhờ phép đổi đó.
