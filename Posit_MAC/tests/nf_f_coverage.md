# Kiểm chứng NF/F hiện tại

Posit(32,3), approximate fraction12, FULL_TERM26/Q24, RNE. Hai top nhận A/B/C
trực tiếp; chỉ driver giữ trạng thái hồi tiếp ngoài. `cfg_ops=0/1`, `cfg_n=0..12`.
Golden: `opt17_reference::mac` và `Oracle<32,3>`, dùng decoder/selected-bit product/
full-grid encoder độc lập với RTL; không lấy SoftPosit p32/es2 làm expected.

## Cấu trúc bộ testbench

| Thành phần | Trách nhiệm |
|---|---|
| `tb/shared_mac_harness.cpp` | Corpus có seed, driver valid/ready, chốt expected tại accept, scoreboard tại retire, reset-abort và external feedback. |
| `tb/shared_mac_checker.sv` | Chọn NF/F trong verification, nối đầy đủ top, đưa checkpoint core và tín hiệu hợp lệ của adder/packer tới monitor. Không sửa DUT. |
| `tb/nf_f_functional_coverage.hpp` | Bin có tên: n/OPS/t/cut, popcount, corner từng toán hạng, flags, protocol, RNE/GRS, align/LOD. |
| `scripts/verify_nf_f_coverage.py` | Build riêng binary fast và instrumented trên cùng SHA nguồn; chạy đủ 52 điểm, không ghi đè báo cáo. |
| `scripts/report_nf_f_coverage.py` | Hợp counter cùng elaboration, chỉ tính RTL, tách raw/reviewed, liệt kê bin và điểm chưa chạm. |
| `tests/nf_f_coverage_waivers.json` | Từng điểm loại có ID, nguồn/line/SHA và chứng minh; nguồn đổi hoặc điểm được chạm thì waiver bị từ chối. |

Driver giữ payload/config của request đang chờ. Có thể đưa request standalone kế
tiếp vào cổng khi DUT đang bận; request hồi tiếp chỉ chốt C sau retire của request
trước. Khi không đưa request mới, driver làm thay đổi A/B/C/n/OPS để kiểm context
đã chốt. Kiểm ổn định output khi stall tới >=32 chu kỳ, reset idle/busy/giữ output,
invalid n13..15/OPS2..3, occupancy một giao dịch, done/last/commit từng vòng,
không mất/nhân đôi output và drain rỗng. Reset-aborted không tính completed.

Corpus gồm vector ngẫu nhiên phân tầng, lát dành riêng cho 256 ô regime/sign,
near-cancellation delta-sf0..4, popcount0..12, RNE tie-even/odd, sticky-only,
biên shift28/29, cancellation sâu và corner trên cả A/B/C. Bộ unit kiểm miền
OPS/SAC/SBM/normalizer riêng; không gọi đó là exhaustive toàn bộ MAC.

## Bin hợp lệ và điểm loại

`required_bins()` trong reporter là danh sách bin bắt buộc, kể cả bin chưa từng
được chạm; không lấy số bin quan sát được làm mẫu số. Regime có 256 bin;
run/polarity hữu hạn gồm run0=1..30 và run1=1..31 (zero/NaR kiểm riêng).
Transaction bin chỉ lấy tại retire. Các bin `pipeline/` lấy tại valid/ready của
tầng, có thể bao gồm token về sau bị reset hủy; báo cáo ghi rõ khác biệt này.

Adder finite operands có <=26 bit fraction. Với scale bằng nhau, hiệu khác zero
có lượng tử ít nhất 8 trong Q29; scale lệch một có lượng tử ít nhất 4; lệch >=2
không triệt tiêu sâu như vậy. Vì thế leading count hợp lệ của kết quả add là
0..28, không bắt top F kích count29/30 bằng dữ liệu nội bộ bất hợp lệ. LOD leaf
vẫn được unit/equivalence kiểm riêng; NF có thể chạm các counter tổ hợp count29/30
khi metadata giữa các tầng chưa đồng bộ, không dùng đó làm bin retire hợp lệ.

NF đã RNE tích trước cộng; tổng hai Posit32 là bội của minpos, nên final pack
không có kết quả finite khác zero nhỏ hơn minpos. Bin final-MINPOS bắt buộc cho F;
NF kiểm product-underflow qua flags/ModelSim packer và multiplier suite. Không bỏ
bin underflow chức năng của NF chỉ vì final pack không thể sinh underflow mới.

Các waiver structural chỉ gồm nhánh ready của leaf không thể bị đầy với một
transaction: 12 điểm NF và 10 điểm F. Chứng minh từng điểm có trong JSON.
Các counter chưa chạm khác (monitor reset dư, encoding Packer dự phòng hoặc LOD)
vẫn giữ trong mẫu số line/toggle và liệt kê trong `unhit_nf/f.json`.
Không force nội bộ DUT, không tắt assert, không sửa RTL để tăng coverage.
Ngưỡng theo SPEC: line>=95%, branch>=90%, toggle>=85%; báo cả raw và reviewed.
Số phần trăm này là tỷ lệ **coverage point** của Verilator, không phải phần trăm
toàn bộ dòng văn bản RTL hoặc chứng minh mọi tổ hợp điều kiện.
Line tính cả basic block ở trang `v_line` và các nhánh `v_branch`; branch chỉ
tính `v_branch`. Hierarchy có thể được Verilator gộp các instance cùng module/
parameter. Toggle tính bit có counter edge khác zero, không phải hai counter
rise/fall tách riêng. Không dùng riêng trang `v_line` làm line coverage vì sẽ
bỏ sót nhánh chưa chạm khỏi mẫu số.

## Chạy lại

Từ gốc `Posit_MAC` trong WSL, chọn tên mới cho mỗi lượt:

```sh
make cov FIXED_RUN=20261105_r3 SHARED_COUNT=100000 NF_F_CODE_COUNT=5000
```

Lệnh build hai binary mỗi variant, chạy pilot100k/điểm (5.2M completed) và
instrumented5k/điểm (260k completed), rồi kiểm gate coverage. Mỗi binary có
manifest SHA RTL/TB/model/oracle và tool/command; reporter từ chối trộn nguồn.
Raw counter `.json.dat`, JSON từng điểm, log và `unhit_nf/f.json` được giữ.
Không chạy synthesis. `make cov` không tự chạy ModelSim Windows.

Chạy thêm lint/unit/model (với cùng thư mục kết quả mới):

```sh
export SHARED_RESULTS_ROOT=results/nf_f_coverage_20261105_r3
SHARED_BUILD_TAG=coverage python3 -B scripts/verify_shared_multiplier.py build units
python3 -B scripts/verify_shared_multiplier.py units
python3 -B scripts/audit_shared_multiplier.py
python3 -B scripts/check_shared_model.py --fixtures "$SHARED_RESULTS_ROOT/modelsim/vectors"
```

Fixture của lệnh cuối phải được sinh bởi runner ModelSim trước. Trong PowerShell:

```powershell
./scripts/run_refactored_mac.ps1 -Stage Verify `
  -RunRoot results/nf_f_coverage_20261105_r3/modelsim -VectorCount 10000 `
  -VerifyScope All -ModelSimBin 'C:/altera/13.0sp1/modelsim_ase/win32aloem' `
  -PythonExecutable 'C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
```

Coverage đạt không đồng nghĩa AC01/main đạt: SPEC vẫn yêu cầu 52x10M completed,
>=4000 mẫu/ô regime/điểm, >=10000 toán hạng/run-polarity, AC03 paired accuracy và
các điều kiện nghiệm thu khác. Không thay ngưỡng bằng pilot. Gói NF/F đã khóa
giữ nguyên source và TB cũ; các thay đổi TB hiện tại không sửa hash gói đã khóa.
