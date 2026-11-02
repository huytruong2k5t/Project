# Kết quả được giữ sau dọn dẹp — 02/11/2026

**Nguồn mới nhất:** [shared_multiplier_20261102/summary.json](shared_multiplier_20261102/summary.json): bộ nhân FULL_TERM dùng chung NF/F,31 module.143934016 unit và7.2M MAC completed/0 mismatch; ModelSim cuối mỗi bản29820 completed+180 aborted. Audit cổng,seed,tool,source guards và coverage raw được giữ. **Main520M/AC04/paired accuracy/PPA mới còn mở.** Các tám nhóm dưới là snapshot lịch sử, không phải kết quả nguồn mới.

Giữ tám nhóm có nguồn/manifest hoặc bằng chứng hữu ích để kiểm chứng và so sánh. Log, report, vector, golden profile, DCP/constraints và snapshot của các lượt hoàn tất được bảo toàn. Thư viện/cache sinh lại được, lượt chạy dở và nhóm lịch sử khác được lưu ngoài results, không xóa mất bằng chứng.

| Nhóm | Giá trị kiểm chứng/đối chiếu |
| --- | --- |
| [f_timing_optimization_20261101/](f_timing_optimization_20261101/) | MAC F đã chọn P00: F2F6.602ns, LUT1265/FF820; giữ cả4 candidate, DCP, logs, vector, source và promotion/hash. |
| [parser_lod_refactor_recheck_20261101/](parser_lod_refactor_recheck_20261101/) | Baseline trước tối ưu F: F7.697ns/NF7.334ns; giữ critical_path_diagnosis_final và các truy vấn hoàn tất. |
| [readme_refactor_recheck_20261101/](readme_refactor_recheck_20261101/) | Baseline NF/F trước refactor Parser/LOD: F6.602ns/NF7.334ns; kiểm OPS độc lập và regression. |
| [refactored_mac_20261101_r3/](refactored_mac_20261101_r3/) | Mốc refactor trước tối ưu packer/parser/OPS: F7.254ns/NF7.979ns; nguồn, verification, synthesis_final và F2F. |
| [fixed32_3_20261022/](fixed32_3_20261022/) | Release lịch sử: summary, source/reference freeze, log/vector và báo cáo được manifest bảo vệ. Không suy nghiệm thu cho RTL hiện tại. |
| [week14/](week14/) | Bằng chứng nghiệm thu/coverage/accuracy lịch sử; giữ nguồn, trace và corpus. Không suy kết quả cho RTL hiện tại. |
| [opt17_20261029/](opt17_20261029/) | Bằng chứng thí nghiệm gần đây, freeze/source bundle, model/profile và bảng đối chiếu. |
| [l1_floor_rne_freeze/](l1_floor_rne_freeze/) | Mốc hợp đồng/golden FLOOR/RNE và trace replay lịch sử. |

## Điểm vào cho thiết kế đang làm việc

- [So sánh tối ưu MAC F](f_timing_optimization_20261101/summary.md), [CSV toàn bộ phương án](f_timing_optimization_20261101/comparison.csv).
- [F2F từng tầng P00](f_timing_optimization_20261101/p00/f2f_f/stages.csv), [worst path](f_timing_optimization_20261101/p00/f2f_f/whole_f2f_D_CE.rpt), [top20](f_timing_optimization_20261101/p00/f2f_f/whole_f2f_top20.rpt).
- [Hash RTL đã áp dụng](f_timing_optimization_20261101/promotion.json); [nguồn đã đo](f_timing_optimization_20261101/p00/source/rtl/mac_f/mac_f_wrapper.sv).
- [Phân tích critical path NF/F](parser_lod_refactor_recheck_20261101/critical_path_diagnosis_final/diagnosis.md).

Các số trên là OOC synthesis của snapshot FLOOR; WHS−0.055ns, chưa place/route/board signoff. RTL hiện tại đã chuyển FULL_TERM; chưa đo PPA lại, không dùng các số trên làm nghiệm thu nguồn mới.

## Kết quả lịch sử và thư viện đã lưu trữ

[Danh mục archive và cách phục hồi](../archive/cleanup_20261102/INDEX.md). Những đường dẫn cũ trong tài liệu hoặc script lịch sử có thể cần restore trước khi dùng. Công cụ không ghi đè chỉnh sửa hiện tại. Khi chạy lại verification, nên chọn RunRoot mới và build work từ source thay vì phụ thuộc thư viện compiled cũ.

[Biên bản dọn dẹp](../docs/DON_DEP_RTL_RESULTS_20261102.md). Dọn thư mục và kiểm hash không thay cho chạy verification chức năng mới.
