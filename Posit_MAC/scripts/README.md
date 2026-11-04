# Runner hiện hành — 05/11/2026

## NF/F đã khóa

- audit_current_locks.py: kiểm hai manifest hiện tại, hash snapshot, nguồn live và evidence.
- freeze_current_nf_f.py: script một lần để tạo gói05/11 sau khi verification PASS; không ghi đè gói đã khóa.
- audit_shared_multiplier.py: kiểm31 module/68 instance và strict lint.
- verify_shared_multiplier.py: build unit/NF/F, kiểm source guard, chạy golden integer độc lập.
- run_refactored_mac.ps1: ModelSim snapshot/replay; VerifyScope All/NF/F, CLI tool paths.
- run_feedforward_ppa.py và syn/report_mac_f2f.tcl: synthesis-only từ snapshot đã verify, đo D/CE theo bank.
- retire_old_rtl_versions_20261105.py: biên bản dọn nguồn cũ, chạy một lần; không dùng để dọn các khóa mới.

Kết quả khóa nằm tại results/nf_f_lock_20261105. Chọn root/tag/label mới khi chạy lại để giữ bằng chứng:

```sh
export SHARED_RESULTS_ROOT=results/nf_f_replay01
export SHARED_BUILD_TAG=replay01
python3 -B scripts/audit_shared_multiplier.py
python3 -B scripts/verify_shared_multiplier.py build nf
python3 -B scripts/verify_shared_multiplier.py build f
python3 -B scripts/verify_shared_multiplier.py run nf 100000 mixed -1 -1
python3 -B scripts/verify_shared_multiplier.py run f 100000 mixed -1 -1
```

## Quire và công cụ lịch sử

verify_quire.py, verify_quire_modelsim.py, measure_quire_synth.py và verify_quire_ppa.py vẫn dùng nguồn đang làm việc. Chọn QUIRE_RESULTS_ROOT hoặc nhãn mới khi replay; không ghi đè kết quả03/11/04/11. audit_quire.py đối chiếu dependency dùng chung với hai khóa NF/F hiện tại.

Các script summarize/package cũ mô tả snapshot lịch sử; sau khi source/khóa cũ bị gỡ, chúng không còn là audit của cây hiện tại. Đọc summary/log đã giữ khi cần đối chiếu. Không đổi hash hoặc tạo lại source giả để làm audit lịch sử qua. Tham số tool lấy từ PATH/CLI; output/temp nằm trong workspace.
