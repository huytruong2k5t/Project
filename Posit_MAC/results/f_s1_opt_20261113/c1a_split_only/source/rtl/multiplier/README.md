# Bộ nhân dùng chung NF/F — 02/11/2026

Cả hai wrapper dùng cùng sáu module dưới đây cho Posit(32,3), approximate12,
FULL_TERM26/Q24. Dùng chung mã RTL và hợp đồng; mỗi top được instantiate độc lập,
không có arbiter chia một instance vật lý giữa hai top.

| Module | Chức năng / giao diện chính |
| --- | --- |
| ops_sel_comb | Chọn X/Y bằng min-popcount fraction12 (OPS1), hòa chọn A; OPS0 giữ A. Y có hidden13, dấu và sf signed11 |
| sac_step_comb | LOD trên fraction12 còn lại; phát scale4 và số hạng kế tiếp; early-stop khi hết bit1 |
| sbm_shift_comb | Y_base={0,Y13,12'b0}, dịch phải0..15 bằng MUX; miền hợp lệ1..12 không mất bit; init_only cho term0 |
| sbm_accum_comb | Cộng magnitude26 với term26, temp27 kiểm tràn; bit25 là carry chuẩn hóa hợp lệ |
| mul_iter_core | Context và pipeline SAC→shift→acc; n0..12, token init/first/last/iteration; giữ acc tới release; reset flush |
| mul_prepack_norm_comb | M26/Q24 và sf/sf_inc → sf_norm,frac26; lossless. NF mở rộng tới Packer53, F đưa trực tiếp vào adder |

Không còn cfg_mode, nhánh nhân exact, FLOOR từng term, term_tail hoặc numerical_tail
trong đường nhân. Wrapper chụp cấu hình khi accept; reset mặc định n12/OPS1.
Các token/context cần cho stall/đánh dấu commit vẫn được giữ, không phải tín hiệu dư.

[Audit cổng/lint](../../results/shared_multiplier_20261102/ports_and_lint.json):
31 module active reachable,68 instance đầy đủ cổng. Unit143934016 so sánh và
7.2M MAC completed đều0 mismatch; [summary](../../results/shared_multiplier_20261102/summary.json)
ghi rõ coverage còn thiếu/main520M chưa chạy. Không gọi đây là nghiệm thu cuối.

11 module/helper đã thay thế được giữ nguyên byte trong
[archive trước sửa](../../archive/shared_multiplier_before_20261102.zip);
[retired_sources.json](../../results/shared_multiplier_20261102/retired_sources.json)
ghi hash. Bảng14 module trước refactor được giữ trong
[archive tài liệu](../../archive/shared_multiplier_docs_before_20261102.zip).
Số PPA của p00/FLOOR không áp dụng cho cây FULL_TERM này.