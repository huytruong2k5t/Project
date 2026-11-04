# RTL đang sử dụng — 05/11/2026

Cây làm việc có36 file SV, tất cả thuộc NF/F hoặc quire. Không còn posit_parser_f.sv; posit_parser_f_regime_lod.sv vẫn là dependency đang sử dụng.

| Phạm vi | Top | File list | Module reachable |
|---|---|---|---:|
| NF/F hợp nhất |posit_mac_nf,posit_mac_f|[mac_active.f](mac_active.f)|31|
| NF riêng |posit_mac_nf|[mac_nf.f](../releases/nf_f_20261105/source/rtl/mac_nf.f)|29|
| F riêng |posit_mac_f|[mac_f.f](../releases/nf_f_20261105/source/rtl/mac_f.f)|27|
| Quire |posit_mac_quire|[quire_active.f](quire_active.f)|19|

NF/F dùng chung nguồn multiplier approximate12/FULL_TERM26/Q24, adder5 tầng, Packer RNE2 tầng. A/B dùng posit_parser_mul với fraction12/tail_cut; C dùng posit_parser26 fraction. Không cfg_mode/exact hoặc accumulator_q/acc_mode/acc_clr trong NF/F. Độ rộng cố định; C nhận trực tiếp ở top.

## Hai bản khóa hiện tại

- [NF lock](../releases/nf_f_20261105/nf.lock.json).
- [F lock](../releases/nf_f_20261105/f.lock.json).
- [Nguồn chung đã khóa](../releases/nf_f_20261105/source/rtl/).
- Kiểm nguồn live và snapshot: python3 -B scripts/audit_current_locks.py từ gốc Posit_MAC.

Đã gỡ production.f/production_freeze, shared_multiplier_checkpoint, feedforward_checkpoint và checkpoint quire cũ. Các khóa cũ không còn là nguồn hiện hành. Báo cáo lịch sử vẫn được giữ ở results; không dùng số10M hoặc timing cũ cho một nguồn khác.

Reference implementation trong tb/reference/rtl vẫn được giữ vì testbench equivalence hiện hành cần chúng. Chúng là reference kiểm chứng, không là phiên bản DUT đang khóa. RTL quire đang làm việc cũng giữ nguyên và không được gắn nhãn release NF/F.
