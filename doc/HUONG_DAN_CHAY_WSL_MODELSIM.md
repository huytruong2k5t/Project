# HƯỚNG DẪN BUILD VÀ KIỂM CHỨNG POSIT MAC — WSL / MODELSIM

Cập nhật: 10/10/2026. Đặt cạnh [tiến độ đồ án](TIEN_DO_DO_AN.md).

Hướng dẫn tổng hợp các luồng đã dùng đến Gate2 tuần9, đối chiếu với Makefile và runner hiện có. Đây là hướng dẫn tái chạy; tạo file này không đồng nghĩa đã chạy lại toàn bộ test. Trạng thái nghiệm thu tại `Posit_MAC/results/week9_implementation/gate2_acceptance.json` và PLAN L1 mục7.11.

## 1. Thư mục, công cụ và cách nhập lệnh

| Môi trường | Thư mục gốc dự án | Công cụ đã dùng |
| --- | --- | --- |
| Windows CMD | `C:\HCMUT\HK261\Do an 2\Posit_MAC` | ModelSim ALTERA STARTER 10.1d; gọi runner PowerShell từ CMD |
| WSL Bash | `/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC` | GCC/G++15.2.0, make, Python3, Verilator5.032 |
| Tham chiếu | `l0/`, `l1/` | SoftPosit0.4.1; ES3 dùng oracle độc lập |

WSL build `.so`/binary Linux; MinGW cross-compiler trong WSL build `.dll`/`.exe` cho Windows. ModelSim ở `C:\altera\13.0sp1\modelsim_ase\win32aloem`. Nếu máy khác dùng đường dẫn khác, đổi biến `MSIM` trong CMD. Hướng dẫn dùng công cụ đã cài, không yêu cầu cài lại hoặc đổi license/cấu hình hệ thống.

**Mở CMD**, nhập:

```bat
cd /d "C:\HCMUT\HK261\Do an 2\Posit_MAC"
set "MSIM=C:\altera\13.0sp1\modelsim_ase\win32aloem"
if not exist "results\manual_tmp" mkdir "results\manual_tmp"
set "TEMP=%CD%\results\manual_tmp"
set "TMP=%TEMP%"
"%MSIM%\vsim.exe" -version
```

Biến môi trường trên chỉ áp dụng cửa sổ CMD hiện tại. Các block `bat` phía dưới nhập trong CMD, không nhập trong Bash.

**Mở WSL từ một cửa sổ CMD khác**, nhập:

```bat
wsl.exe --cd "/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC" --exec bash --noprofile --norc
```

Sau khi vào WSL, nhập các block `bash`:

```bash
cd "/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC"
mkdir -p results/manual_tmp
export TMPDIR="$PWD/results/manual_tmp"
export LD_LIBRARY_PATH="$PWD/l0:$PWD/l1${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
g++ --version
make --version
python3 --version
verilator --version
command -v x86_64-w64-mingw32-g++
```

`exit` thoát WSL về CMD. Nếu cross-compiler không có, không chạy target `.exe`/`windows`; cần bổ sung công cụ trước, hoặc dùng binary Windows đã build tương ứng với mã nguồn.

Runner `.ps1` được gọi bằng `powershell -NoProfile -ExecutionPolicy Bypass -File ...` từ CMD. `Bypass` chỉ áp dụng tiến trình này để chạy script của dự án, không đổi execution policy toàn máy. Runner tự tạo thư viện `work`, compile và mô phỏng bằng `vsim -c`; không cần mở GUI ModelSim.

## 2. Quy tắc tái chạy và đọc kết quả

1. Giữ nguyên nguồn và script suốt một phiên chạy; không sửa runner khi nó đang chạy.
2. Sinh fixture → build/compile → mô phỏng → audit. JSON PASS cũ không chứng minh binary/vector còn trên đĩa.
3. Chờ từng lệnh hoàn tất thành công rồi chạy lệnh sau. Trong WSL kiểm `echo $?`; CMD kiểm `echo %ERRORLEVEL%` ngay sau lệnh cần kiểm.
4. Các runner có thể ghi đè log/report trong thư mục kết quả cố định. Muốn giữ phiên cũ, sao lưu các báo cáo/log/hash trước. Runner multiplier parallel có `-RunName` để tách tên phiên; các audit Gate2 hiện dùng tên canonical nêu ở mục6.
5. Kiểm PASS marker, số giao dịch, mismatch, seed và hash. Có file log hoặc kết thúc tiến trình chưa đủ kết luận PASS.
6. LF/CRLF có thể làm SHA256 khác dù nội dung số giống nhau. Dùng cùng fixture cho các simulator, không tự sửa hash để bỏ qua bất đồng.

Không chạy `make all`/`make clean` ở root để thay cho toàn bộ nghiệm thu: target synthesis/PPA ở root còn phần khung; clean có thể xóa sản phẩm build. Chọn từng luồng phía dưới.

## 3. L0/L1 — build và kiểm phần mềm trong WSL

### 3.1. L0 SoftPosit

```bash
make -C l0 linux
./l0/softposit_cli test_corners
./l0/softposit_cli p32_mul 0x40000000 0x40000000
sha256sum l0/libsoftposit.so
```

Ví dụ nhân1×1 trả `0x40000000`. Build bản Windows khi cần:

```bash
make -C l0 windows
```

### 3.2. L1 Gate1, round và bộ cộng

```bash
make -C l1 linux
make -C l1 gate1 P32_SEED=314159
make -C l1 test-round
make -C l1 test-round-ubsan
make -C l1 test-week5
```

`gate1` là luồng nghiệm thu lớn; nếu chỉ kiểm nhanh trước, chạy:

```bash
./l1/test_identity
./l1/test_mul_exact
./l1/test_round_unpacked
./l1/test_adder
```

Nhân posit32 riêng hoặc chia dải posit16 khi cần:

```bash
make -C l1 gate1-p32 P32_SEED=314159
make -C l1 gate1-p16-range P16_START=0 P16_END=65536 P32_SEED=314159
```

Dải posit16 phải được ghi rõ; không gọi một dải nhỏ là vét cạn toàn bộ nếu chưa chạy đủ.

### 3.3. MAC L1 — Gate1B

```bash
make -C l1 test-week6
make -C l1 gate1b P32_SEED=314159
make -C l1 test_mac_gate1b_ubsan
./l1/test_mac_gate1b_ubsan
```

`gate1b` chạy `--acceptance --samples 10000000`. Các lệnh này kiểm mô hình phần mềm MAC, không phải Gate3 của RTL MAC.

## 4. Chuẩn bị binary Windows cho ModelSim

Trong **WSL**, build generator cần dùng:

```bash
make -C l0 windows
make -C l1 gen_parser_vectors.exe gen_packer_vectors.exe
make -C l1 gen_week9_frontend.exe gen_week9_arithmetic.exe gen_week9_core.exe gen_week9_multiplier.exe
make -C l1 gen_week9_paper.exe gen_paper_top.exe test_paper_contract_audit.exe
```

Sau đó trong **CMD tại gốc Posit_MAC**:

```bat
copy /Y "l0\softposit.dll" "l1\softposit.dll"
```

Các generator dùng L0 cần DLL cạnh `.exe`. `.so` không thay cho DLL Windows. Không lấy `.exe` cũ để kiểm mã mới nếu chưa build lại.

## 5. ModelSim từ Windows CMD — kiểm từng khối

Các lệnh dưới giả định đã làm mục1 và mục4. Chỉ chạy những nhóm cần kiểm, không bắt buộc chạy toàn bộ mỗi lần.

### 5.1. LOD/LZD — N=8/31/32

Luồng compile/mô phỏng trực tiếp, sản phẩm nằm trong dự án:

```bat
if not exist "results\manual_lod_lzd" mkdir "results\manual_lod_lzd"
cd /d "C:\HCMUT\HK261\Do an 2\Posit_MAC\results\manual_lod_lzd"
if not exist work "%MSIM%\vlib.exe" work
"%MSIM%\vlog.exe" -sv -work work "..\..\rtl\lod_lzd_core.sv" "..\..\tb\tb_lod_lzd_core.sv" -l compile.log
(echo onerror {quit -code 1}& echo onbreak {quit -code 1}& echo run -all& echo quit -code 0)>run.do
"%MSIM%\vsim.exe" -c work.tb_lod_lzd_core -l simulate.log -do run.do
cd /d "C:\HCMUT\HK261\Do an 2\Posit_MAC"
```

Chỉ chạy `vsim` nếu `vlog` thành công. Marker: `LOD/LZD PASSED ... 0 mismatches`. Seed của N31/N32 nằm trong testbench; không đổi seed để né lỗi.

### 5.2. Hai barrel shifter

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_shifters_modelsim.ps1 -ModelSimBin "%MSIM%" -Seed 20261004
```

Kết quả: `results/modelsim_shifters/`; kiểm trái/phải và ma trận27 cấu hình.

### 5.3. Parser tổ hợp rồi pipeline

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_parser_comb_modelsim.ps1 -ModelSimBin "%MSIM%"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_parser_modelsim.ps1 -ModelSimBin "%MSIM%"
```

Comb tự sinh fixture bằng `gen_parser_vectors.exe`; pipeline dùng fixture ở `results/parser_comb/`. Sau dọn vector phải chạy comb trước. Bằng chứng ở `results/parser_comb/` và `results/parser_pipeline/`.

### 5.4. Packer và ghép parser→packer

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_packer_modelsim.ps1 -ModelSimBin "%MSIM%"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_packer_p2_equivalence.ps1 -ModelSimBin "%MSIM%"
```

Chạy sau parser comb: chain cần fixture parser. Kết quả ở `results/packer/` và `results/packer_p2_optimization/`. Luồng equivalence cần file reference đã giữ trong thư mục optimization. `-CollectExisting` chỉ đọc lại log hiện có của parser/packer, không chạy mô phỏng mới; không dùng khi fixture/log còn thiếu.

### 5.5. OPS/SAC → SBM/normalize/adapter → controller/core

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_frontend_modelsim.ps1 -ModelSimBin "%MSIM%"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_arithmetic_modelsim.ps1 -ModelSimBin "%MSIM%"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_core_modelsim.ps1 -ModelSimBin "%MSIM%"
```

Runner tự gọi generator Windows tương ứng. Bằng chứng lần lượt ở `results/week9_frontend/windows`, `week9_arithmetic/windows`, `week9_core/windows`. Mốc đã quan sát:327.440 frontend,252.455 arithmetic,39.580 giao dịch core;0 mismatch. Các test core còn kiểm420 reset hủy.

## 6. Quy trình Gate2 đầy đủ — WSL + ModelSim

Chạy đúng thứ tự dưới đây khi cần tái dựng nghiệm thu. Kiểm lại lớn tốn thời gian và vài GiB dữ liệu tạm; không cần làm mỗi lần chỉ sửa tài liệu. Các audit dùng tên thư mục cố định. Giữ báo cáo phiên trước trước khi dùng lại những tên ấy.

### 6.1. Build Linux và sinh corpus trong WSL

```bash
make -C l0 linux
make -C l1 gen_week9_multiplier
./l1/gen_week9_multiplier results/week9_multiplier/stratified_corpus 1056000 stratified
./l1/gen_week9_multiplier results/week9_multiplier/gate2_cornercorpus 7200 corners
```

Seed20261009;16 cấu hình8/0,16/1,32/2,32/3 × FLOOR/JAM × RNE/TRUNC. Tổng16.896.000 dòng phân tầng và115.200 dòng corner. Không sinh lại `final_pilot` bằng generator Linux nếu đang đối chiếu fixture Windows đóng băng: newline có thể đổi hash.

### 6.2. Pilot và các báo cáo đối chiếu ModelSim — CMD

Giữ nguyên16 fixture nhỏ ở `results/week9_multiplier/final_pilot/` nếu còn đầy đủ. **Chỉ khi pilot thiếu**, tái tạo bằng runner Windows sau mục4:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_multiplier_modelsim.ps1 -ModelSimBin "%MSIM%" -PerProfile 2000 -RunName final_pilot
```

Đối chuẩn pilot bằng runner một DUT mỗi tiến trình; dùng đúng tên báo cáo mà audit Verilator đọc:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_multiplier_parallel.ps1 -ModelSimBin "%MSIM%" -FixtureRun final_pilot -RunName gate2_final_pilot -Jobs 8
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_multiplier_parallel.ps1 -ModelSimBin "%MSIM%" -FixtureRun gate2_cornercorpus -RunName gate2_corners_modelsim -Jobs 8
```

Đối chiếu phân tầng bằng ModelSim nếu bắt đầu từ đầu, thay nguồn/fixture, hoặc báo cáo cũ không còn phù hợp:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_multiplier_parallel.ps1 -ModelSimBin "%MSIM%" -FixtureRun stratified_corpus -RunName stratified_acceptance -Jobs 8
```

Đây là lượt lớn, có thể giảm `-Jobs` nếu máy thiếu RAM. Khi nguồn/fixture tương ứng không thay đổi và đủ hash, giữ báo cáo phân tầng lịch sử thay vì chạy lại vô ích. Không dùng runner16-DUT một tiến trình cho corpus lớn; parallel tách DUT để dễ kiểm/debug.

### 6.3. Strict lint và pilot Verilator — WSL

```bash
make lint
bash scripts/verify_week9_verilator.sh final_pilot gate2_pilot
```

Lint dùng `--timing -Wall`, không suppress warning; phải PASS đủ16 profile. Pilot phải đạt31.840 so sánh/160 reset hủy/0 mismatch, counters/hash khớp ModelSim. Lệnh `make smoke` tương đương runner pilot trên; không chạy cả hai nếu không có lý do chạy lại.

### 6.4. Verilator phân tầng — tạo binary trước khi chạy corner

```bash
bash -n scripts/verify_week9_verilator.sh
bash scripts/verify_week9_verilator.sh stratified_corpus gate2_stratified
```

Runner snapshot nguồn, build16 binary, kiểm pilot của từng binary rồi chạy corpus lớn. Cuối phiên tự audit. `make regress` tương đương lượt này; chỉ chọn một cách gọi. Mốc đúng: **16.815.920 completed,80.080 reset_aborts,0 mismatch**; direct L1=16.896.000,L0=3.168.256,ES3=1.056.256. L1/oracle kiểm cả input bị reset hủy; RTL counts chỉ giao dịch hoàn tất.

Functional simulation dùng `--no-timing` để bỏ CK2Q theo kiểm chu kỳ, giữ warning trong build.log. Nó không thay strict lint `--timing`, ModelSim4-state hoặc STA.

### 6.5. Corner trên chính binary vừa kiểm, rồi coverage và acceptance

```bash
test -x results/week9_multiplier/verilator/gate2_stratified/8_0_0_0/obj_dir/Vposit_mul_iter
bash scripts/verify_gate2_corners.sh
make cov
python3 scripts/audit_gate2_acceptance.py
```

`test -x` chỉ kiểm một binary mẫu; phải có đủ16 binary và thư viện `src/libsoftposit.so`. Corner đạt114.656 completed/544 reset hủy/0 mismatch. `make cov` đọc corpus phân tầng còn trên đĩa và raw coverage của lượt phân tầng+corner. Acceptance yêu cầu thêm ModelSim corner và strict lint khớp nguồn.

Nếu cần audit độc lập sau runner, khi fixture và snapshot vẫn còn:

```bash
python3 scripts/audit_week9_verilator.py stratified_corpus gate2_stratified
```

Audit riêng không chạy mô phỏng mới. Nếu chạy lại audit summary sau nghiệm thu tích hợp, chạy lại acceptance để cập nhật liên kết hash báo cáo.

### 6.6. Nơi xem kết quả và giới hạn

| Nội dung | File/thư mục dưới Posit_MAC |
| --- | --- |
| Chốt Gate2 hiện hành | `results/week9_implementation/gate2_acceptance.json` |
| Lint16 cấu hình và source hash | `results/week9_implementation/lint_gate2/` |
| Full Verilator/counts per profile | `results/week9_multiplier/verilator/gate2_stratified/summary.json`, `comparisons.csv` |
| Coverage chức năng/cấu trúc | Cùng thư mục trên: `functional_coverage.json`, `structural_coverage.json` |
| Log một cấu hình | Cùng thư mục trên: `32_3_0_0/run.log`, `corner_run.log`, `build.log` |
| Pilot/corner ModelSim | `results/week9_multiplier/gate2_final_pilot/`, `gate2_corners_modelsim/` |

Gate2 tuần9 kiểm multiplier normative. Coverage chức năng đã đạt; raw line/branch/toggle chưa100%, giữ các điểm chưa hit. Mốc này không nghiệm thu RTL MAC/Gate3, toàn ma trận cuối SPEC§6.7, PPA/Gate4 hoặc baseline gốc bài báo.

## 7. Nhánh paper — chạy riêng với hợp đồng normative

### 7.1. RTL research và top tự hồi tiếp — CMD

Sau khi build generator Windows ở mục4, xác nhận còn `results/paper_discriminators/linux/vectors.csv`, rồi chạy:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_week9_paper_modelsim.ps1 -ModelSimBin "%MSIM%"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_paper_top_modelsim.ps1 -ModelSimBin "%MSIM%"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_paper_contract_modelsim.ps1 -ModelSimBin "%MSIM%"
```

Kết quả tại `results/week9_paper/windows`, `results/paper_top/windows`, `results/paper_contract_audit/windows`. Top paper đã kiểm17.181 giao dịch/65.710 commit/0 mismatch; Fig4 force-X phải trả **0x1ae34000**. PASS với trace tái dựng không chứng minh có RTL gốc của tác giả.

Nếu muốn audit/summarize bằng WSL và còn đủ fixture/log Linux+Windows mà checker yêu cầu:

```bash
python3 scripts/audit_paper_top.py
python3 scripts/summarize_paper_contract_audit.py
```

Sau dọn dữ liệu, audit có thể báo thiếu fixture; cần đọc dependency của checker và sinh lại, không gọi PASS chỉ vì summary cũ còn.

### 7.2. TableI2021 và pilot2024 — WSL, chỉ chạy khi có mục đích nghiên cứu

Ví dụ pilot profile fig3 với seed lịch sử, không ép match:

```bash
make -C l1 test_paper_table1
./l1/test_paper_table1 --samples 10000000 --seed 271828 --profile fig3
```

Lượt lớn đã dùng cho profile fig3 (không cần chạy cùng Gate2):

```bash
./l1/test_paper_table1 --samples 200000000 --seed 271828 --profile fig3 --require-match
```

`--require-match` có thể trả FAIL vì không đạt ngưỡng bảng; đây không nhất thiết là lỗi build hoặc lỗi RTL. Profile `source` từng gần bảng thống kê nhưng không khớp output ví dụ; không gọi thống kê đạt là xác nhận baseline gốc. Không dò seed/profile để ép bảng.

Pilot journal2024 dùng oracle ES2 và hai phân bố địa phương:

```bash
make -C l1 test_journal2024_measurement
./l1/test_journal2024_measurement 10000000 271828 raw-posit results/paper_journal2024/measurement/pilot_raw
./l1/test_journal2024_measurement 10000000 271828 value01 results/paper_journal2024/measurement/pilot_value
```

Đây là corpus địa phương, không phải generator/seed do tác giả công bố. Phiên Gate2 không chạy lại TableI do không có thay đổi số học được xác minh bằng nguồn.

## 8. Các lỗi thường gặp

| Hiện tượng | Nguyên nhân cần kiểm | Cách xử lý |
| --- | --- | --- |
| Corner script dòng14: `No such file or directory` | `obj_dir/Vposit_mul_iter` hoặc loader/library không còn; thường do đã dọn cache | Nếu binary thiếu, chạy lại mục6.4 trước mục6.5; nếu có binary thì kiểm library/kiến trúc. Summary PASS không tạo lại binary |
| Audit thiếu `mul_*.txt` hoặc `src/` | Fixture/snapshot đã dọn | Sinh corpus mục6.1 rồi build mục6.4; giữ file tới khi hoàn thành audit |
| `Expected sixteen frozen fixtures` | Chưa sinh đủ corpus/nhầm FixtureRun | Kiểm đúng thư mục và16 profile, không chạy simulator khi corpus thiếu |
| `NEEDTIMINGOPT` | Gọi Verilator có CK2Q mà thiếu lựa chọn timing | Lint dùng `make lint`; functional harness dùng runner `--no-timing`, không xóa CK2Q để né lỗi |
| DLL/shared library missing | Dùng nhầm Linux/Windows hoặc thư viện chưa build/copy | Build L0 đúng nền tảng; Windows copy DLL cạnh `.exe`; WSL dùng `.so` và môi trường mục1 |
| Bash báo `$'\r'`/`do\r` | Script checkout thành CRLF | Chuẩn hóa đúng file `.sh` cần chạy sang LF; không sửa hàng loạt fixture/hash. Sau sửa, giữ runner cố định suốt phiên |
| Build Verilator lỗi đường dẫn có khoảng trắng | Bỏ runner và gọi generated make bằng đường dẫn tuyệt đối | Dùng runner hiện có; nó snapshot đường dẫn tương đối và `CURDIR=.` trong dự án |
| Hash fixture không khớp | Khác nguồn/seed/sampling hoặc LF/CRLF | Xác định nguyên nhân, giữ cả bằng chứng cũ/mới; không thay hash reference để tự báo đạt |
| Simulation FAIL/timeout | Compile/config/protocol/số học chưa đúng | Xem compile.log rồi simulate/run.log của profile lỗi; không coi các profile còn lại PASS là toàn suite PASS |

**Ví dụ sửa CRLF cho đúng một script trong WSL khi cần**:

```bash
sed -i 's/\r$//' scripts/verify_gate2_corners.sh
bash -n scripts/verify_gate2_corners.sh
```

Chỉ áp dụng nếu đã xác định lỗi CRLF, không chỉnh source đang dùng trong một phiên kiểm còn chạy.

## 9. Sau khi chạy

Giữ source, seed, compiler/simulator version, lệnh, summary, log PASS/FAIL, fixture/library/source SHA256 và coverage. Có thể dọn vector lớn/build cache khi đã ghi đủ bằng chứng; khi chạy lại phải sinh/build lại. Không xóa reference hoặc thay PASS lịch sử bằng file thiếu.

Log/core counts không thay nghiệm thu tích hợp. Chỉ đánh dấu tiến độ hoàn thành theo phạm vi thực sự đã kiểm. Bước tiếp theo sau Gate2: RTL adder tuần10 → MAC v1/Gate3 tuần11 → regression cuối và PPA.

Repository sao lưu: `https://github.com/huytruong2k5t/Project`. Checkout Git hiện dùng nằm riêng ở `Posit_MAC/scratch/github_week9_backup`; không chạy `git init` thêm tại gốc dữ liệu dự án. Chỉ commit nguồn/tài liệu/bằng chứng gọn, không đưa DLL/binary, wave, cache hoặc vector lớn vào Git.
