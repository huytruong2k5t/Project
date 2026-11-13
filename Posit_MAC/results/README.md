# Báo cáo và bằng chứng được giữ — 05/11/2026

## Coverage NF/F mới

[Lượt05/11 r2](nf_f_coverage_20261105_r2/README.md) dùng testbench cập nhật trên
RTL NF/F hiện tại; báo riêng 52 điểm pilot, counter structural, functional bin,
raw/reviewed và waiver có giải thích. `verification_summary.json` liên kết thêm
unit, lint, model và ModelSim. Không tính các lượt thăm dò `matrix_*` vào kết quả.

## Hai bản nguồn đã khóa hiện tại

[Khóa NF/F05/11](../releases/nf_f_20261105/README.md) là hai phiên bản nguồn được giữ hiện hành. [Verification mới](nf_f_lock_20261105/final/summary.json): mỗi lõi100000 completed/0 mismatch, ModelSim9940 completed +60 reset-aborted, strict lint31 module/68 instance và unit arithmetic đạt. Chưa thay main52×10M/coverage/timing sau route.

## Báo cáo đối chiếu

Theo yêu cầu người dùng, giữ báo cáo/log/vector nhưng gỡ snapshot RTL, gói source và manifest khóa cũ. ZIP hỗn hợp đã bỏ các entry nguồn; các entry báo cáo/vector còn lại được kiểm hash không đổi. Kết quả cũ mô tả đúng nguồn khi đo; không còn đầy đủ source để replay, không dùng audit khóa cũ hoặc số PASS cũ cho cây hiện tại.

| Nhóm | Báo cáo đối chiếu |
|---|---|
|[NF sau chỉnh parser/core](nf_parser_recheck_20261104/summary.md)|F2F6.314ns,LUT1604/FF916; thuộc đúng snapshot khi đo.|
|[NF/F feed-forward](feedforward_a_20261104/summary.md)|So trước/sau bỏ hồi tiếp; F5.340ns,NF8.945ns ở nguồn lúc đó.|
|[Quire tối ưu](quire_opt_20261104/summary.md)|LUT10156→2888,FF4458→2636,F2F18.483→9.579ns;1.1M MAC/0 mismatch; synthesis unplaced,hold còn âm.|
|[Quire03/11](quire_20261103/summary.json)|10M MAC/0 mismatch trên nguồn cũ; route100MHz chưa đạt.|
|[Parser hợp nhất](parser_unified_20261104/)|Audit/regression trung gian; không gộp volume với phiên bản sau.|
|[FULL_TERM dùng chung02/11](shared_multiplier_20261102/summary.json)|Unit/pilot trước feed-forward; nguồn khóa cũ đã gỡ.|
|[Tối ưu F01/11](f_timing_optimization_20261101/summary.md)|Các thử nghiệm parser/F2F FLOOR cũ.|
|[Critical path cũ](parser_lod_refactor_recheck_20261101/critical_path_diagnosis_final/diagnosis.md)|Phân tích đường găng theo netlist ngày đo.|
|[README recheck](readme_refactor_recheck_20261101/)|Mốc refactor trước FULL_TERM.|
|[Refactor r3](refactored_mac_20261101_r3/)|Mốc pipeline/packer lịch sử.|
|[Fixed32/3](fixed32_3_20261022/summary.json)|Nghiệm thu checkpoint cũ; không còn giữ bản source đã khóa.|
|[W14](week14/handoff.json)|Coverage/accuracy và aggregate cũ, không chuyển sang nguồn05/11.|
|[OPT17](opt17_20261029/summary.json)|Candidate lịch sử, đã gỡ source candidate.|
|[L1 FLOOR](l1_floor_rne_freeze/)|Báo cáo profile thuật toán cũ.|
|[SPEC approximate12](spec_approx12_20261102/)|Kiểm công thức/hợp đồng.|

Các liên kết source/restore trong chính báo cáo lịch sử có thể không còn tồn tại sau lần gỡ nguồn này. Bản báo cáo được giữ nguyên nội dung. Số synthesis unplaced không là Fmax sau route hoặc board signoff.
