# Điểm mơ hồ và quyết định thiết kế Posit MAC

Cập nhật 08/10/2026, đồng bộ SPEC v1.5. [SPEC §11](../SPEC_Posit_MAC_IP.md#11-quyết-định-rủi-ro-và-điều-kiện-triển-khai) giữ bảng trạng thái đầy đủ; tài liệu này tóm tắt quyết định và giới hạn, không sao chép thuật toán packer để tránh hai nguồn hợp đồng khác nhau.

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
| Pipeline mục tiêu | Parser hai hạng đã kiểm; packer TRUNC1/RNE2 đã chốt ranh giới: P1 mã hóa/dịch/G-R-S, P2 RNE/carry/dấu (§5.9-D). RNE hai slot/TRUNC một slot đã có RTL; F_IN=2*FRAC_MAX+1 và adapter theo §5.9-D, nghiệm thu theo results/packer/summary.json. STA khảo sát riêng, không tự bảo đảm100MHz | SPEC §4.1/§5.1 |

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
| Table I tái dựng source | Thống kê lịch sử đạt; bị loại khỏi baseline bit-exact2021 | 200 triệu accepted seed271828, max0,984213 điểm %; nhưng Fig.4 output sai:0x1ae34800 thay0x1ae34000. README L1 mục20; giữ làm control |
| Width/cut research fig3 | Chức năng đã nghiệm thu; TableI chưa đạt | Fraction12/payload13+carry/guard0, cut term trước áp dấu, normalize cuối; Windows/Linux/UBSan PASS. 200M max1,292319 điểm %, năm pilot đều vượt1. Layout cờ là tái dựng địa phương |
| Vector phân biệt/phương án3 | Bốn bước kiểm chứng hoàn thành; baseline còn processing |292 bản ghi/206 trường hợp,10 ứng viên;205.882 kiểm/nền tảng PASS. Guard12/cut12 khớp Fig.4 nhưng200M max1,338773 điểm %, chưa đạt; tie/guard/cờ/generator nguồn còn mở |
| RTL nhân tuần9 | processing; standalone đã kiểm pilot, Gate2 còn thiếu | Context/token/drain chốt SPEC §5.5-A, FLOOR normalize đúng lưới L1 ở §5.7.327.440 vector ModelSim0 mismatch; SBM/core/top standalone và paper trace đã kiểm; lint/harness chính thức theo PLAN mục7; lượt lớn/coverage chức năng đã đạt |
| Table II | Chưa hoàn tất | Chốt corpus FP64→posit32 ES3, nhóm mA/mB và oracle exact ES3; giả định cả hai nằm trong nhóm phải công bố |
| Packer RTL tuần8 | Đã nghiệm thu đơn vị |5.947.048 packer và4.931.624 chain,0 mismatch; results/packer/summary.json |
| Core/MAC RTL | Core và standalone đã kiểm pilot; MAC chưa triển khai | Reset/token/drain/slot đạt phạm vi pilot; Gate2/lint và Gate3 còn mở |
| PPA packer riêng | Đã khảo sát | Sau tối ưu P2, Quartus3seed: RNE537 LUT4/196FF,122,50–124,42MHz; TRUNC522 LUT4/152FF,100,67–101,01MHz; cả sáu run đạt setup100MHz. Có boundary, không phải full MAC |
| PPA toàn MAC | Chưa đo | Vivado synthesis/STA bị chặn license. OPS/packer Quartus riêng không thay Gate4; so cùng part/ES/ràng buộc hoặc báo bậc thiết bị §7.6 |

Uniform-value/grid24 cho Table I là giả định tái dựng có seed/filter rõ ràng; uniform-bits và stratified có mục đích kiểm độ nhạy/coverage. Không đổi phân bố chỉ để ép khớp bảng, không coi coverage là corpus gốc. n_terms=n_fraction+1 chỉ đổi cách đếm cùng chuỗi khai triển; RND/complement và profile normative không tự trở thành bit-exact nhờ phép đổi đó.

Đối chiếu journal2024 ngày08/10: README L1 mục18 ghi nguồn, phạm vi và kiểm PT2 PASS128 entry dưới giả định đệm Q12. Phương án tìm nguồn này hoàn thành; provenance baseline vẫn processing ở tie policy, width/cut/guard và generator. Kết quả source200M ở bảng trên giữ nguyên từ lượt04/10, không phải phép đo journal mới. Không đổi hợp đồng RTL.

Sau đó đã chốt/kiểm hợp đồng width/cut hữu hạn ở README mục19, và đo lại200M cùng corpus cho cả source/fig3. Source giữ kết quả cũ; fig3 chưa đạt AC-03. Guard12 không được xác nhận bởi Fig.3; carry riêng bảo toàn tràn không phải12 fractional guard. Không thay width normative bằng profile nghiên cứu hoặc đóng tuần4 nhờ kiểm chức năng đơn vị.

Đính chính sau phương án3 (README mục20): Fig.4/5 bản2021 yêu cầu output0x1ae34000; source Q24 không cut trả0x1ae34800 nên không phù hợp baseline bit-exact. Chỉ phép chiếu accumulator xuốngQ12 khớp là chưa đủ. Giữ12 bit fraction đầu ra có căn cứ nguồn, còn guard nội bộ/tie là giả thuyết. Đo200M không chọn được profile vừa khớp ví dụ vừa đạt TableI; không coi PASS số học của control source là nghiệm thu baseline gốc.

## 4. Trạng thái sau RTL paper và core — 09/10/2026

Paper843 commit/Fig.4 đạt cùng giả định fig3; chưa có bằng chứng mới cho tie/prefix/internal guard hoặc generator gốc, nên không chạy lại TableI. W9-03..05 đã có code/test; Gate2/tuần9 processing. Verilator/lint còn thiếu; GitHub backup đã có checkout riêng trong dự án. Không đổi mô hình để né tiêu chí.

ModelSim đối chiếu 16.815.920 giao dịch, hủy 80.080 giao dịch bằng reset,0 mismatch.

## 5. Top paper tự hồi tiếp — 09/10/2026

`paper_mul_iter`/`paper_mul_wrapper`/`paper_norm_comb` đã tự chạy từ A/B đến kết quả; ModelSim17.181 giao dịch và65.710 commit đạt0 mismatch,843 commit corpus cũ giữ nguyên, Fig.4=0x1ae34000. Linux/Windows/UBSan fixture MATCH; reset/stall/context/early-stop/special đạt trong suite. Hợp đồng research cố định posit32ES3/Q12, n_terms1..8, outputTRUNC; chi tiết PLAN L1 §7.5 và results/paper_top/{windows/summary,audit}.json. Không có nguồn mới hoặc thay đổi số học nên không chạy TableI; provenance baseline gốc và Gate2 vẫn processing.
