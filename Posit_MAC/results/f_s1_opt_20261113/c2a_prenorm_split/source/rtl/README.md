# RTL đang sử dụng — 07/11/2026

Cây làm việc có36 file SV, tất cả thuộc NF/F hoặc quire. Không còn posit_parser_f.sv; posit_parser_f_regime_lod.sv vẫn là dependency đang sử dụng.

| Phạm vi | Top | File list | Module reachable |
|---|---|---|---:|
| NF/F hợp nhất |posit_mac_nf,posit_mac_f|[mac_active.f](mac_active.f)|30|
| NF khóa ngày 05/11 |posit_mac_nf|[mac_nf.f](../releases/nf_f_20261105/source/rtl/mac_nf.f)|29|
| F khóa ngày 05/11 |posit_mac_f|[mac_f.f](../releases/nf_f_20261105/source/rtl/mac_f.f)|27|
| Quire |posit_mac_quire|[quire_active.f](quire_active.f)|19|

NF/F dùng chung `posit_parser_mul` cho cả A, B và C. A/B dùng 12 bit fraction cao và `tail_cut`. C ghép hai ngõ ra fraction thành đủ 26 bit để đưa vào bộ cộng. Các instance giữ hai tầng elastic và nhận ba toán hạng song song. NF/F cũng dùng chung multiplier approximate12/FULL_TERM26/Q24, adder 5 tầng và Packer RNE 2 tầng. C nhận trực tiếp từ cổng top.

## Hai bản khóa ngày 05/11

- [NF lock](../releases/nf_f_20261105/nf.lock.json).
- [F lock](../releases/nf_f_20261105/f.lock.json).
- [Nguồn chung đã khóa](../releases/nf_f_20261105/source/rtl/).
- Kiểm nguồn live và snapshot: python3 -B scripts/audit_current_locks.py từ gốc Posit_MAC.

Đã gỡ production.f/production_freeze, shared_multiplier_checkpoint, feedforward_checkpoint và checkpoint quire cũ. Các khóa cũ không còn là nguồn hiện hành. Báo cáo lịch sử vẫn được giữ ở results; không dùng số10M hoặc timing cũ cho một nguồn khác.

Reference implementation trong tb/reference/rtl vẫn được giữ vì testbench equivalence hiện hành cần chúng. Chúng là reference kiểm chứng, không là phiên bản DUT đang khóa. RTL quire đang làm việc cũng giữ nguyên và không được gắn nhãn release NF/F.
