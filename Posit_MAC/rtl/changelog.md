# RTL Architecture & Refactoring Changelog

## [2026-11-07] - Dùng chung `posit_parser_mul` cho A, B và C

Cả MAC-NF và MAC-F dùng cùng định nghĩa parser hai tầng. A/B nhận 12 bit fraction cao và `tail_cut` đã chốt ở P2. C nhận đủ 26 bit bằng cách ghép `frac` và `frac_lo` ở cùng tầng. Mỗi wrapper vẫn phân tích ba toán hạng song song. `posit_parser.sv` được gỡ khỏi `mac_active.f` và vẫn thuộc luồng riêng đang sử dụng nó.

Strict lint đạt 30 module và kiểm đủ cổng của 66 instance. Hồi quy Verilator đối chiếu golden đạt 100.000 giao dịch hoàn tất, 0 mismatch và 26/26 cấu hình trên mỗi lõi. Xem [kết quả và phạm vi](../results/shared_parser_mul_20261107/summary.md).
