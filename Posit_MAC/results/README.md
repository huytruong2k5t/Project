# Kết quả kiểm chứng và đo tài nguyên

## 1. Bằng chứng cần giữ

| Nhóm | Kết quả chính |
| --- | --- |
| RTL tuần 9 và trạng thái Gate 2 | `week9_implementation/summary.json`; `week9_multiplier/stratified_acceptance/{summary,functional_coverage}.json` |
| Parser / packer / shifter / LOD-LZD | `parser_comb/summary.json`, `packer/summary.json`, `modelsim_shifters/summary.json`, `modelsim_lod_lzd/simulation.log` |
| Baseline paper 2021 | `paper_discriminators/acceptance/measurement.csv`, `paper_discriminators/summary.json`; vector phân biệt và trace CSV trong cùng nhóm |
| Baseline paper 2024 | `paper_journal2024/measurement/summary.json`, CSV pilot và trace Table VI |
| Rà soát báo cáo baseline mới | `baseline_report_review/review.json` và các log chạy lại |
| Top paper / hợp đồng thuật toán | `paper_top/audit.json`, `paper_contract_audit/summary.json`; trace phân biệt, ảnh hình gốc và snapshot nguồn |
| PPA / tối ưu packer | `ops_ppa_summary.csv`, `packer_ppa/summary.json`, `packer_p2_optimization/comparison.json`; báo cáo fitter/STA gốc |
| Các Gate / L0-L1 / MAC đã chạy | Log nghiệm thu, compiler, seed, lệnh, `.sha256`, bảng CSV và JSON trong thư mục này |

Các kết quả PASS/FAIL lịch sử được giữ nguyên. Dọn dữ liệu không đóng Gate 2 hoặc xác nhận baseline gốc.

## 2. Dọn dung lượng ngày 09/10/2026

Đã xóa 3.291 file sinh tự động: vector lớn, bản sao fixture của các lượt cũ, thư viện ModelSim/XSim, database tổng hợp, binary và wave/cache. Dung lượng giảm từ khoảng 1.458,67 MiB xuống 30 MiB, gồm cả manifest dọn dẹp.

Giữ bộ fixture nhỏ `week9_multiplier/final_pilot` và `week9_multiplier/corners_final_rtl` để debug; các fixture nhỏ còn lại được giữ theo danh mục manifest. Những tập này không thay corpus nghiệm thu lớn.

[cleanup_manifest.json](cleanup_manifest.json) ghi danh mục file đã xóa, dung lượng, hash và mẫu đầu/cuối của fixture, cùng danh mục bằng chứng đã giữ. Kiểm 1.513 file giữ lại bằng SHA256 ngay sau dọn: không thay đổi ngoài ý muốn. README này được cập nhật sau phép kiểm; manifest ghi riêng cập nhật tài liệu.

## 3. Sinh lại khi cần kiểm RTL

Vector lớn không còn sẵn. Audit đọc trực tiếp các vector ấy và chế độ thu thập kết quả cũ có thể báo thiếu file; cần sinh lại trước. Không sửa checker để bỏ qua hash hoặc coi file thiếu là PASS.

Ví dụ build và sinh lại từ thư mục `Posit_MAC`, dùng WSL `bash --noprofile --norc` và TMPDIR nằm trong dự án:

```sh
make -C l1 gen_parser_vectors gen_packer_vectors gen_week9_frontend gen_week9_arithmetic gen_week9_multiplier gen_paper_top test_paper_contract_audit
./l1/gen_parser_vectors results/parser_comb
./l1/gen_packer_vectors results/packer
./l1/gen_week9_frontend results/week9_frontend
./l1/gen_week9_arithmetic results/week9_arithmetic/windows
./l1/gen_week9_multiplier results/week9_multiplier/stratified_corpus 1056000 stratified
./l1/gen_week9_multiplier results/week9_multiplier/acceptance_corpus 630000
./l1/gen_paper_top results/paper_discriminators/linux/vectors.csv results/paper_top/linux
./l1/test_paper_contract_audit results/paper_contract_audit/linux
```

Packer cần fixture parser, nên phải sinh parser trước. Với ModelSim trên Windows, build các target `.exe` tương ứng và dùng runner trong `scripts/`; tuần 9 dùng `verify_week9_multiplier_parallel.ps1 -FixtureRun stratified_corpus -RunName stratified_acceptance` sau khi sinh corpus.

Lệnh trên dùng generator hiện hành. Để replay đúng một lượt lịch sử, đối chiếu phiên bản nguồn/compiler, seed, số dòng và hash fixture trong summary/manifest của lượt đó; nếu hash khác thì chưa được coi là cùng corpus. Giữ riêng báo cáo lịch sử trước khi chạy runner vào cùng thư mục.

Không dùng `make clean && make all` như một cam kết tái tạo toàn bộ các thí nghiệm lịch sử. Từng nhóm có generator và runner riêng; lệnh, phiên bản công cụ và phạm vi kiểm nằm trong summary tương ứng.

## 4. Bằng chứng Gate2 — 10/10/2026


Gate2 multiplier **✅** theo mốc tuần9 (10/10/2026):16.815.920 giao dịch phân tầng/0 mismatch; scoreboard trực tiếp L1/L0 và oracle ES3; strict lint16/16 sạch; corner114.656/0 mismatch trên ModelSim và Verilator. Seed20261009, SoftPosit0.4.1, GCC15.2.0, Verilator5.032 và ModelSim10.1d; lệnh/hash/phiên bản lưu với bằng chứng.

Coverage chức năng đạt256/256 bin posit32, min4104 mẫu/bin,26241 operands/run/polarity và36 ô config/profile; structural coverage sau ghép corner: line 91.67–96.23%; branch 91.84–94.79%; toggle 73.10–87.33%, giữ các điểm chưa hit. Mốc này không quy định ngưỡng phần trăm structural coverage và không phải coverage100% hoặc signoff vật lý.

Trạng thái canonical tại `results/week9_implementation/gate2_acceptance.json`; hướng dẫn tái lập và giải thích phạm vi tại PLAN L1 mục7.11. Những mục processing trước đây là lịch sử. Ma trận cuối SPEC§6.7, tuần10 adder/tuần11 MAC-Gate3 và PPA/Gate4 còn mở; provenance/TableI giữ processing, không chạy lại TableI trong phiên này.


Sau nghiệm thu10/10 đã dọn 2579.15 MiB gồm fixture phân tầng vừa sinh và bản sao nguồn/cache Verilator. Giữ raw coverage, mọi log PASS/hash/report và fixture pilot/corner nhỏ. Danh mục tại `week9_implementation/gate2_cleanup_manifest.json`. Audit cần fixture/snapshot phải sinh lại và build theo PLAN7.11; thiếu file không được coi là PASS.
