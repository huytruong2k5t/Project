# Quyết định thiết kế Posit MAC

Cập nhật 01/11/2026. [SPEC v1.25](../SPEC_Posit_MAC_IP.md) là hợp đồng hiện hành;
nhật ký chi tiết trước rút gọn nằm trong
[bản lưu tài liệu](../archive/spec_v1_24_before_compact_20261101.zip).

| Nội dung | Quyết định và lý do |
| --- | --- |
| Format | Chỉ Posit(32,3); SoftPosit p32/es2 không là golden trực tiếp. |
| Phạm vi nhân | Approximate-only, fraction12, n0..12; hidden khởi tạo riêng, không giới hạn chiều dài chuỗi tích lũy. |
| FULL_TERM | M26/Q24, Y13<<12 rồi dịch S≤12; giữ đủ term, không FLOOR/JAM/RNE từng vòng. n12 chỉ đầy đủ với significand đã cắt. |
| OPS | 0 giữ A làm X; 1 min-popcount12, hòa chọn A. Hai chính sách phải được kiểm. |
| NF/F | NF=R(R(P_hat)+C_eff); F=R(P_hat+C_eff), cùng P_hat. Không có exact NF/F hoặc quire. |
| Giao diện | Top mục tiêu không cfg_mode/EXACT_EN/public parameter; adapter legacy nếu cần chỉ nhận cfg_mode1. |
| Packer/adder | Giữ đủ fraction53/RNE và residual cần thiết; bỏ exact không cho phép cắt bit phục vụ làm tròn. W32/Q29 phải khớp oracle full-grid. |
| Golden/model | Golden độc lập opt17_reference + Oracle<32,3>; L1 full_term32 cho trace/checkpoint; khóa Config{true,n,ops}. Ideal dùng toàn A/B để đo sai số. |
| Tích lũy | C_eff=c/S/0 theo acc_mode/clear; commit S một lần, state Posit32 sau mỗi giao dịch. |
| Reset/stall | Chốt input nguyên tử, giữ output, reset flush/startup barrier; kiểm protocol cùng số học. |
| Latency | Khóa theo RTL mới, t/n0/early-stop và handshake; không dùng lịch cũ để suy số chu kỳ/Fmax. |
| Nghiệm thu | 52 điểm NF/F×OPS0/1×n0..12, ≥10M completed/điểm, 0 mismatch d/5flags; coverage theo SPEC §6.6. AC02 exact retired. |
| Nguồn đang có | NF vẫn exact-capable/N_MAX8; F vẫn core16/FLOOR; header FULL_TERM/harness còn mixed. Phải hoàn thiện và nghiệm thu đúng snapshot. |

Số đo/fixture/PASS cũ giữ nguyên phạm vi nguồn; không sửa expected FLOOR thành FULL_TERM để đổi nhãn.
PPA theo cùng A35T/constraints sau kiểm chức năng, tách khỏi lần sửa tài liệu hiện tại.
