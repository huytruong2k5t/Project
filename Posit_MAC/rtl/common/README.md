# Common cho Posit(32,3) — 02/11/2026

Bảy module trong mac_active.f đều reachable từ NF/F; không có public parameter.
Hậu tố fixed phân biệt độ rộng helper, không phải định dạng Posit khác.

| Module | Độ rộng | Nơi dùng |
| --- | ---: | --- |
| dyn_left_shifter | 29 | Parser NF/F, decode tích NF |
| dyn_left_shifter_fixed5 | 12 | SAC approximate dùng chung |
| dyn_left_shifter_fixed6 | 30 | Normalize S5 bộ cộng |
| dyn_right_shifter_fixed2 | 59 | Prepare P1 Packer, fill |
| dyn_right_shifter_fixed4 | 31 | Align S2 bộ cộng, zero fill |
| lod_lzd_core_fixed2 | 31 | Parser NF, decode tích NF, LOD bộ cộng |
| lod_lzd_core_fixed4 | 12 | SAC approximate dùng chung |

Ba helper fixed3 phục vụ nhánh exact/term16 cũ đã được kiểm hash và lưu trong
[ZIP trước sửa](../../archive/shared_multiplier_before_20261102.zip), không còn trong cây active.
Các helper reference đặt riêng tại tb/reference/rtl/common; chỉ dùng file list
verification khi cần, không compile đệ quy cả kho.

[Audit31 module/68 instance](../../results/shared_multiplier_20261102/ports_and_lint.json)
và [summary kiểm chứng](../../results/shared_multiplier_20261102/summary.json).
Main520M, phần coverage còn thiếu và PPA nguồn mới chưa hoàn tất.
Bản README10 helper trước thay đổi nằm trong
[archive tài liệu](../../archive/shared_multiplier_docs_before_20261102.zip).