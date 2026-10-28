# Kết quả kiểm chứng và đo tài nguyên

**Giới hạn từ29/10/2026:** SPEC v1.23 §4.3 đã đổi hợp đồng mục tiêu sang FULL_TERM Q24/26 bit,
n0..12.Các summary/hash/accuracy/timing trong thư mục này vẫn thuộc profile nguồn ghi trên
từng report,không trở thành bằng chứng FULL_TERM.Ví dụFig.4 FLOOR0x1ae34000 giữ lịch sử;
vector FULL_TERM mục tiêu0x1ae34800 chưa có lượt RTL/L1 mới.Phiên này chỉ cập nhật tài liệu,
không sửa report,dataset,fixture hoặc freeze để đổi nhãn kết quả.
README này được bổ sung có chủ đích29/10 nên không còn cùng SHA với ảnh chụp README
trong biên bản dọn23/10;giữ nguyên hash/receipt lịch sử,không sửa chúng để khớp tài liệu mới.

## Đối chứng chính và dọn cache — 23/10/2026

| Nhóm cần giữ | Nơi tra cứu |
| --- | --- |
| Production fixed posit32/ES3 | `fixed32_3_20261022/summary.json`, `specialization.json`, `lint_summary.json`; NF/F mỗi bản10M completed,0 mismatch,ModelSim và740k so sánh tổ hợp đạt; không thay STA/PPA mới hoặc final per-profile |
| Snapshot trước cố định32/3 | `fixed32_3_20261022/reference_source.zip`, `reference_sha256.json`; giữ nguyên nguồn và hash để tái lập |
| Biên bản dọn cache | `cleanup_cache_20261023/cleanup.json`, `retained_sha256.json.gz`, `postcheck.json`, `release_audit.log` |
| W14, accuracy và timing/PPA lịch sử | Các nhóm có trong bảng phía dưới; giữ CSV/JSON,rpt,log PASS/FAIL,raw coverage,fixture và snapshot theo từng nguồn |

Đã dọn2.777 file trong89 thư mục build/library/cache,giải phóng646.415.018 byte
(khoảng616,5 MiB). SHA256 của34.725 file giữ lại đạt sau xóa; README này được cập nhật
có chủ đích sau phép kiểm và có ghi nhận hash trước/sau riêng trong biên bản.
Không xóa `.bin` fixture,`.dat` raw coverage,bảng số liệu,checkpoint PPA hoặc nguồn đối chứng.
Không chạm checkout Git,thư viện phụ thuộc trong scratch hoặc mã RTL/L1/oracle.
Binary Verilator và thư viện ModelSim cần build lại; chọn nhãn build/run mới theo
`../docs/HUONG_DAN_CHAY_WSL_MODELSIM.md`. Không dùng thiếu cache để bỏ kiểm hash
hoặc xem việc dọn dữ liệu là một lần nghiệm thu mô phỏng mới.

## Hiện trạng sau dọn — 19/10/2026

| Nhóm | Nơi tra cứu |
| --- | --- |
| RTL đã khóa, thử và chọn ở mốc 120 MHz | `opt120_20261018/`; recipe `../syn/opt12_120mhz_release.json` |
| OPT-15 chia sẻ tài nguyên NF, chưa promote | `opt15_share_20261019/summary.json`; `evidence.zip`, `archive_manifest.json`, PPA/stages và các replay trong cùng nhóm |
| W14, nghiệm thu và accuracy | `week14/`, đặc biệt `handoff.json`, `completion.json`, `coverage_closure.json`, `accuracy_inference.json` |
| Thử UltraScale+ | `xcvu9p_trial_20261018/` — chỉ là trial riêng |
| Quyết định chọn/bỏ các ứng viên trước mốc 120 MHz | Các nhóm `opt02b_*`, `opt02c_*`, `opt03_*`, `opt05_*`, `opt09_*`, `opt10a_*`, `optcombo_*`, `primitive_*`, `parser_xor_*`, `prepack_refactor_*`, `align_refactor_*`, `normalize_refactor_*` giữ nguyên |
| Nguồn ứng viên cũ đã lưu trữ | [Kho nén và cách phục hồi](../archive/README.md) |

Các phần có ngày phía dưới là lịch sử; trạng thái Gate tại mỗi mốc không thay thế
kết luận W14 hiện hành. Bằng chứng đo dưới 120 MHz vẫn cần để đối chiếu nên không xóa
summary, STA, CSV, seed, hash hoặc log thất bại theo ngưỡng tần số.

Lượt dọn này xóa cache `.gch/.o/.a/.d` trong `week14/**/obj/`, Python cache và
ModelSim `week14/event_protocol/work/`. Giữ generated source/header/makefile,
snapshot, fixture, counter, raw coverage `.dat` và các archive nghiệm thu.
`results/` giảm từ khoảng 2.088,75 xuống 884,08 MiB; tổng cache dọn cả trong
`scripts/__pycache__/` là 920 file/1.204,85 MiB.

Trước khi chạy lại phải build thư viện/binary cần thiết; không dùng việc thiếu cache
làm bằng chứng kiểm mới hoặc bỏ kiểm hash. Phiên này không chạy mô phỏng/STA,
không sửa nội dung báo cáo. [Danh mục và xác minh toàn vẹn](../archive/README.md).

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

## 5. Checkpoint L1 FLOOR/RNE — 11/10/2026

`l1_floor_rne_freeze/summary.json` và `frozen_sources.sha256` giữ profile/source/compiler/seed/lệnh. Logs Linux/Windows/UBSan, regression và normalized SHA pilot là bằng chứng. Binary và fixture replay là sản phẩm có thể build/sinh lại, không đưa vào Git; replay dùng generator 2000 dòng/profile và so final_pilot đóng băng. Hợp đồng tại SPEC§11.9, lệnh/checker PLAN§8.1. Chưa có L1/RTL fused được nghiệm thu.


## 6. Dọn cache và corpus sinh lại — 11/10/2026

Đã dọn2.039 file, tiết kiệm3.833,60 MiB: results giảm từ3.913,10 xuống khoảng80,50 MiB (gồm manifest mới). Xóa43 thư mục cache gốc (Verilator obj_dir, ModelSim work, tmp...) cùng16 fixture mul_*.txt phân tầng và wave sinh lại. Các thư mục rỗng được gỡ; các nhóm bằng chứng vẫn giữ nguyên.

Giữ mọi summary/CSV/log/hash, raw structural/functional coverage, source snapshots lịch sử, fitter/STA, trace phân biệt, hình nguồn và fixture pilot/corner/replay nhỏ. Kiểm SHA256 cả2.982 file giữ lại PASS ngay sau dọn; README và tiến độ cập nhật sau phép kiểm. Manifest [cleanup_20261011_manifest.json](cleanup_20261011_manifest.json) ghi file/dung lượng/reason, hash corpus đã xóa và hash bằng chứng giữ. Cleanup không đổi nghiệm thu hoặc kết luận baseline; không chạy lại Gate2 trong phiên này. Audit L1 FLOOR/RNE vẫn PASS với replay nhỏ được giữ.

**Chạy lại:** theo hướng dẫn [WSL/ModelSim](../../doc/HUONG_DAN_CHAY_WSL_MODELSIM.md), mục6.1 sinh stratified_corpus, mục6.4 build/run Verilator, rồi mới mục6.5 corners. Binary obj_dir không còn; không chạy corners ngay hoặc coi file thiếu là PASS. Corpus historical phải dùng đúng source/seed/compiler/hash của report, source snapshot và lịch sử Git; giữ report cũ trước khi runner ghi mới. Scripts/generator/reference ngoài results được giữ nguyên.

**Dọn lần sau:** PowerShell7 (`pwsh`), từ Posit_MAC, `./scripts/cleanup_results.ps1` chỉ xem kế hoạch; thêm `-Apply -Checkpoint YYYYMMDD` mới xóa. Script kiểm mọi đích thuộc results, từ chối link/process simulator đang chạy, ghi manifest trước xóa và kiểm hash phần giữ sau xóa. Chọn checkpoint mới; không ghi đè manifest cũ. Khi chạy WSL, hoàn tất mọi build/sim trước dọn; kiểm process Windows không bảo đảm phát hiện process Linux.

## 7. W10-01 — hợp đồng adder, 12/10/2026

week10_contract/summary.json, projection.log và ubsan.log kiểm mapping L1 sang cổng unpacked/packer365.836 cặp,bốn format,0 mismatch. Không phải test RTL/control hoặc oracle độc lập. Contract ở SPEC§5.8-A..D; source/lệnh/compiler/hash đi cùng summary. Binary/tmp có thể build lại, không đưa Git; không sửa L1 frozen.

## 8. Bàn giao tuần10 — 12/10/2026

week10_adder/summary.json canonical cho adder đơn vị: ModelSim143.976 comb,143.376 completed+600 abort; native full20.000.004 completedES2/ES3,0 mismatch; oracle/flags/latency/reset/stall/order và lint8/8 đạt. matrix.json, source/fixture/binary hashes, compiler, generator/UBSan/model logs và rawcoverage/unhit points được giữ. Raw line80,00–80,95%,branch92,31–96,15%,toggle75,18–84,74% chưa đạt finalAC04; AC02 cuối, MAC/Gate3, F và PPA vẫn mở. paired/manifest.json khóa common100k input/seed/metric/reference-width requirements, chưa có accuracy NF/F. Lệnh PLAN8.4; chạy audit sau sinh/build/sim, không coi file thiếu là PASS.

Sau kiểm W10 đã dọn553 file/361,93 MiB cache, wave, binary generator và bản replay/UBSan có thể sinh lại; results còn khoảng97,85 MiB. Primary pilot/corpus input, source snapshots, log/hash/report và rawcoverage giữ nguyên, hash đã kiểm. Danh mục results/cleanup_20261012_manifest.json; chạy lại prepare/build trước dùng binary, audit vẫn PASS sau dọn.


## 9. Bằng chứng tuần11 — 13/10/2026

posit_mac_nf/mac_nf_wrapper dùng mul_prepack_norm_comb bảo toàn carry và round_unpacked_comb=parse(pack(u)) tổ hợp; legacy L1/RTL freeze giữ nguyên. Approximate NF mới có thể khác legacy; cùng P_hat theo SPEC v1.11§11.10. Gate3 native32/3 10.000.000 completed, ModelSim28.512 completed/288 reset-aborted,0 mismatch; strict lint4/4,72 control bins và256 regime–dấu main. Canonical results/week11/summary.json; baseline_nf_manifest.json/source+binary+fixture hashes, raw coverage/unhit giữ nguyên. L1 fused full-sum pilot100k/Python independent0 mismatch; chưa fused RTL/window/flags/acc_mode, final AC02/AC04/per-n matrix hoặc accuracy/PPA. Commands PLAN8.6; rebuild binaries/fixtures trước audit sau cleanup.

## 10. Cập nhật phạm vi nghiệm thu — 14/10/2026

SPEC v1.13 đã được rà toàn bộ theo RTL/model/bằng chứng hiện hành. Nguồn RTL và L1 frozen không đổi; kết quả W11 numeric/protocol10.000.000 completed,0 mismatch vẫn giữ nguyên.

Gate3 đầy đủ còn **processing**: cận trên near-cancellation ở đầu vào adder NF chỉ420.303/10.000.000=4,20303%, thấp hơn yêu cầu30% của SPEC§6.3. Các bin regime/config đã hit không thay yêu cầu phân bố này. Counters từng run/polarity và packer bins cần được lưu đủ trước signoff; không hạ ngưỡng hoặc sửa report lịch sử.

Checkpoint13/10 và manifest NF đóng băng mốc số học/giao thức, không chứng minh mọi AC đã đạt. Công việc bổ sung tại PLAN§8.7/SPEC§11.11; chứng cứ rà soát ở results/spec_review_20261014/summary.json. F full-sum vẫn là pilot phần mềm; F RTL/window/flags/acc_mode, ma trận final và accuracy/PPA còn mở.
