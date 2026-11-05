# Vector và ca kiểm thử Posit MAC

Bộ NF/F mới: [kế hoạch, bin và lệnh coverage](nf_f_coverage.md). `make cov`
build từ nguồn hiện tại, chạy pilot và đo structural riêng; không dùng summary
cũ làm PASS. SPEC hiện nằm tại [docs/SPEC_Posit_MAC_IP.md](../docs/SPEC_Posit_MAC_IP.md).

Ma trận hiện hành: [SPEC §6.7](../SPEC_Posit_MAC_IP.md#acceptance-matrix), chỉ
Posit(32,3), approximate FW12/FULL_TERM26/Q24/RNE, NF/F, OPS0/1 và n0..12.
Không có test mode exact phần cứng, TRUNC hoặc format8/16/32-es2 trong nghiệm thu mới.

| Tài liệu/dữ liệu | Vai trò |
| --- | --- |
| [corner_cases.md](corner_cases.md) | Danh mục lịch sử; chọn ca đúng32/3 và bổ sung theo [corner hiện hành](../SPEC_Posit_MAC_IP.md#corner-cases). |
| tv_paper.txt | Trace paper/FLOOR lịch sử; không dùng bits/latency đó làm golden FULL_TERM. |
| tv_iter.txt | Ví dụ vòng lặp cũ; expected mới phải được tạo lại theo hợp đồng FULL_TERM và golden độc lập. |
| stratified_regime.txt | Mẫu phân tầng; counts nghiệm thu lấy từ suite thực tế, theo [SPEC §6.3](../SPEC_Posit_MAC_IP.md#verification-coverage). |

Golden là `opt17_reference::mac` với `Oracle<32,3>`; L1 `full_term32` phục vụ trace và
phải được đối chiếu golden trước sinh fixture. Khóa `Config{true,n,ops}` và state/C_eff
đúng từng NF/F. SoftPosit p32/es2 và so comb/pipeline không thay golden32/3 độc lập.

Trình tự: model/oracle → unit/fixture → pilot → 52 điểm main → audit.
Chỉ báo PASS khi đúng nguồn/manifest và đủ d/5flags, completed, reset/stall, coverage.
`make smoke/regress` hoặc runner legacy không mặc nhiên bao đủ ma trận mới;
xem phạm vi/lệnh của từng runner trong [hướng dẫn chạy](../docs/HUONG_DAN_CHAY_WSL_MODELSIM.md).
