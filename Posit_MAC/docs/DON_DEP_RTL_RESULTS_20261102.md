# Dọn dẹp RTL và kết quả — 02/11/2026

Hoàn tất việc sắp xếp và lưu trữ; không sửa logic module RTL hoặc chạy Vivado. Sau khi chuyển reference bộ cộng, đã chạy lại luồng verification hiện hành ở mức smoke để kiểm đường dẫn snapshot/compile mới.

| Chỉ tiêu | Trước | Sau |
| --- | ---: | ---: |
| RTL .sv | 94 | 42 MAC; 7 reference chuyển sang tb |
| Nhóm thư mục results | 82 | 8 |
| Dữ liệu trong results | 1160.83 MiB | khoảng 222.01 MiB |

Đưa45 file SV không dùng trong MAC hiện tại và4 file phụ trợ ra khỏi RTL. Thêm7 file reference được chuyển nguyên byte sang [tb/reference/rtl/files.f](../tb/reference/rtl/files.f) vì testbench so sánh bộ cộng vẫn cần. Runner đã cập nhật đường dẫn mới và có fallback khi replay snapshot dùng đường dẫn cũ. File list DUT [mac_active.f](../rtl/mac_active.f) vẫn đủ42 module, đóng dependency từ hai top. Không sửa production.f/production_freeze.json lịch sử.

Giữ nguyên byte 7292 file cần bảo vệ, gồm RTL active/reference, header, manifest, snapshot, golden/constraints và bằng chứng kết quả không thuộc cache. Các manifest nguồn của những lần đo gần nhất vẫn khớp; F2F6.602ns của F và dữ liệu đối chiếu NF/F không bị thay đổi. Việc đối chiếu hash này không thay regression chức năng đầy đủ; smoke sau chuyển reference được ghi riêng bên dưới.

Tổng 35337 file được chuyển ra khỏi cây làm việc sau khi ZIP đã kiểm CRC/SHA256 từng entry. Bốn gói ZIP chính tổng 317.52 MiB; bảy reference di chuyển có ZIP/receipt riêng. Mọi byte gốc của các file đã gỡ đều có thể phục hồi; metadata README trước khi cập nhật cũng được lưu riêng.

## Cách dùng sau dọn

Common đã rà soát riêng:14→10 file SV; ba reference sang tb/reference/rtl/common, dyn_left_shifter_fixed4 lưu archive. Cả10 file còn lại đều reachable trong MAC; các phiên bản12/26/29/30/31/59 bit có chức năng khác nhau. [Bảng nơi gọi](../rtl/common/README.md), [bằng chứng dependency và SHA](../archive/cleanup_20261102/common_usage_audit.json). Không xóa helper đường exact NF khi kiến trúc NF chưa được chuyển sang approximate-only.

- [Kết quả đang giữ](../results/README.md): tám mốc có ý nghĩa và điểm vào CSV/report/log/source.
- [Archive/index và hướng dẫn restore](../archive/cleanup_20261102/INDEX.md).
- [Plan/danh mục chính xác](../archive/cleanup_20261102/plan.json), [receipt/hash ZIP](../archive/cleanup_20261102/receipt.json), [kiểm tra sau dọn](../archive/cleanup_20261102/validation.json).

Luồng hiện tại run_refactored_mac.ps1, run_f_parser_equiv.ps1, report_refactored_mac_f2f.ps1 và query_mac_critical_paths.ps1 có đủ RTL/reference/source/report đầu vào. Script mô phỏng luôn build work mới khi chọn RunRoot mới. Các workflow/benchmark lịch sử đã archive cần phục hồi đúng snapshot/đường dẫn trước khi replay; không trộn module cùng tên giữa các thế hệ.

## Kiểm tra đã thực hiện

Đối chiếu SHA256 toàn ZIP và từng entry, kiểm hash tất cả file được bảo vệ, kiểm đủ42 module reachable từ hai top và đúng42 SV trong RTL, giữ nguyên các report được freeze lịch sử tham chiếu. Bảy reference mới được đối chiếu hash tại đường dẫn tb; [biên bản chuyển](../archive/cleanup_20261102/reference_migration.json) giữ mapping và ZIP trước di chuyển. Đã kiểm 7 manifest/430 hash nguồn của các lần đo gần nhất và thử phục hồi3 file đại diện RTL/kết quả lịch sử/cache: tất cả PASS. Các bản phục hồi thử được gỡ sau khi đối chiếu đúng hash. [Bằng chứng bổ sung](../archive/cleanup_20261102/evidence_validation.json).

Verification sau chuyển: bộ cộng5 tầng39534 completed/0 mismatch, packer10851 completed/0 errors, MAC F1000 accepted theo golden hiện hành: PASS. [Log và nguồn đã kiểm](../archive/cleanup_20261102/reference_verification/verify/). Đây là smoke kiểm đường dẫn runner, không thay các mốc regression/synthesis lớn đã giữ nguyên trong results.
