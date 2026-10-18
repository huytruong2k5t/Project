# Thư mục Mã nguồn RTL (`rtl/`)

## Release production đã khóa — 18/10/2026

`POSIT_MAC_RTL_20261018_OPT02C` (`LOCKED_FOR_W14`),38 module trong `rtl/production.f`.
Gói hiện hành: OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A; không đổi hợp đồng số học/latency.
NF thực hiện R(R(P_hat)+C_eff); F thực hiện R(P_hat+C_eff), với phạm vi/profile ở SPECv1.20.
Trước khi build/chạy W14, từ gốc Posit_MAC:

```powershell
python scripts/audit_rtl_release.py --self-test
```

37 profile strict lint và smoke ModelSim NF/F từ production đã đạt; NF acceptance10M/0 mismatch.
F10M được kế thừa theo hash nguồn của8.28 và có smoke mới; chưa chạy final per-n W14/Gate4.
Xem SPEC§11.17, `rtl/production_freeze.json` và Optimization§8.30.
Các câu “chưa promote” ở hồ sơ có ngày trước18/10 là trạng thái lịch sử.
Producer/audit kiểm hash checkpoint cũ phải dùng snapshot cũ, không sửa hash lịch sử để nhận PASS.


**Tài liệu hiện hành:** [PLAN — kiến trúc/build L1/NF/F](../l1/PLAN.md), [Optimization — tối ưu và kiểm chứng/STA](../../doc/Optimization.md), [tiến độ — việc còn mở](../docs/TIEN_DO_DO_AN.md).

## Bản đồ RTL hiện hành — 15/10/2026

Đọc mục này trước; các mục có ngày bên dưới là lịch sử triển khai, không phải danh sách file hiện hành.
Tổ chức lại chỉ đổi vị trí file, giữ nguyên byte mã nguồn, tên module, parameter, I/O và hành vi.

| Thư mục | Nội dung |
| --- | --- |
| `common/` | LOD/LZD, dịch trái và dịch phải dùng chung |
| `parser/` | Parser tổ hợp và pipeline |
| `packer/` | Packer P1/P2, tổ hợp và round_unpacked |
| `multiplier/` | OPS, SAC, SBM dịch/tích lũy, controller, core và top nhân |
| `adder/` | Bộ cộng NF: align → arithmetic → normalize, comb/pipeline |
| `mac_nf/` | Top `posit_mac_nf`, wrapper, product pack và magnitude parser |
| `mac_f/` | Top `posit_mac_f`, wrapper và pipeline F1–F5 |
| `research/paper/` | Nhánh tái dựng paper độc lập với hợp đồng NF/F |
| `candidates/adder/` | Snapshot alignment/normalization; OPT-02c đã promote, các bản khác giữ nghiên cứu |
| `candidates/primitives/` | Các phương án thử shifter/LOD; trùng tên module với bản chính |
| `benchmarks/` | Wrapper đo PPA/so sánh, không ghép vào IP sản phẩm |
| `posit_mac.vh` | Header dùng chung, giữ tại gốc để `-Irtl`/`+incdir+rtl` không đổi |
| `production.f` | Danh sách 38 module chính, không gồm nghiên cứu/candidate/benchmark |

**Không dùng glob đệ quy toàn bộ `rtl` để compile:** candidate primitive trùng tên module với production.
Từ gốc Posit_MAC, dùng file list chính hoặc các runner đã có:

```bash
verilator --lint-only --timing --assert -Wall -Irtl --top-module posit_mac_f -f rtl/production.f
python3 scripts/audit_rtl_release.py --self-test
```

Các runner chọn module động dùng `scripts/rtl_paths.{sh,ps1,py}` và bản đồ `rtl_paths.json`/`rtl_paths.tsv`.
Thêm module mới phải cập nhật file list và bản đồ nếu runner chọn theo tên.
Kiểm release hiện hành bằng `python scripts/audit_rtl_release.py`; audit_rtl_layout.py gắn hash layout cũ chỉ chạy với checkpoint15/10 tương ứng.

Kết quả cũ giữ nguyên đường dẫn/hash tại thời điểm đo. Bản đồ di chuyển và hash nằm ở
`results/layout_cleanup_20261015/rtl_migration.json`; script trước di chuyển lưu trong
`scripts_before_layout.zip` tại cùng thư mục. Không sửa hash lịch sử để hợp thức hóa một lượt chạy mới.
Audit lịch sử có kiểm binary hoặc hash script vẫn cần phục hồi/build đúng checkpoint;
không coi audit không chạy được sau cleanup là một lần kiểm mới thất bại về số học.


**Hợp đồng tích hợp cập nhật 08/10/2026 — SPEC v1.5:** RTL baseline v0/v1 giữ profile L1 normative: cfg_ops=0/1, cfg_n đếm fraction, hidden khởi tạo riêng; paper_source_config/predictor7-bit là nghiên cứu riêng. H là ngân sách hạng thanh ghi; không bubble thì L_valid=H-1, L_handshake=H (E0 là input handshake). n=0 dùng token init_only; core_done=q+2 cạnh sau OPS launch, q=max(1,n), last chỉ hoàn tất ở accumulator. Top rst_n đồng bộ dùng reset bridge/startup barrier để phối hợp leaf reset_n và nhận A/B/C nguyên tử. Core/bridge và multiplier standalone đã kiểm lượt lớn/coverage chức năng09/10; Gate2 processing, MAC RTL chưa nghiệm thu. Chi tiết và trạng thái tại [SPEC §4–§5 và §11](../SPEC_Posit_MAC_IP.md). Bước tiếp theo: đóng Gate2 tuần9 theo [hồ sơ Gate2](../../doc/Optimization.md#legacy-7-11); chồng lấn sau baseline.

Thư mục này chứa toàn bộ mã nguồn thiết kế phần cứng SystemVerilog cho lõi IP Posit MAC xấp xỉ và lặp, tuân thủ nghiêm ngặt chuẩn thiết kế [Digital Design Guidelines](../Digital_Design_Guidelines.md) và đặc tả [SPEC_Posit_MAC_IP.md](../SPEC_Posit_MAC_IP.md).

---

## 1. Quy ước Thiết kế Chuẩn (Design Conventions)

- **Cấu trúc file**: Mỗi file chứa đúng một module mang cùng tên file (`<module_name>.sv`).
- **Header chuẩn hóa**: Tất cả file RTL bắt buộc có header chuẩn mô tả tác giả, ngày tạo, dự án và tóm tắt chức năng.
- **Quy ước đặt tên**:
  - Tên tín hiệu: `snake_case`.
  - Hậu tố thanh ghi: `_q` cho trạng thái hiện tại, `_d` cho giá trị kế tiếp.
  - Xung nhịp: chữ thường có từ khóa `clk`.
- Reset leaf tuần tự: `reset_n`, assert bất đồng bộ, deassert qua hai flip-flop trên clock của khối theo Guidelines. MAC top rst_n đồng bộ qua reset bridge/startup barrier theo SPEC §4.2; không nối trực tiếp vào chân reset bất đồng bộ của leaf.
  - Hướng vector: Little-Endian (`[N-1:0]`).
- **Chỉ thị tiền xử lý**: Toàn bộ macro dự án được đặt tập trung trong [`posit_mac.vh`](posit_mac.vh), không dùng directive rải rác.
- **Không sử dụng Latch**: Logic tổ hợp dùng `always_comb` hoặc `assign`; logic tuần tự dùng `always_ff`, non-blocking assignment và enable, với reset đã đồng bộ của khối. Macro `CK2Q` lấy từ `posit_mac.vh`.

---

## 2. Danh mục Module RTL

### A. Các khối Cơ sở Đã Hiện thực (Foundation Units — 100% Verified)

| Tên Module / File | Mô tả chức năng & Kiến trúc phần cứng | Tham số chính | Trạng thái |
|:---|:---|:---|:---:|
| [`posit_mac.vh`](posit_mac.vh) | Header định nghĩa các hằng số, tham số cấu hình mặc định và macro phần cứng (`CK2Q`). | - | **Hoàn thành** |
| [`lod_lzd_core.sv`](common/lod_lzd_core.sv) | Bộ dò tìm và đếm số 1 / số 0 đầu chuỗi (LOD/LZD) sử dụng cấu trúc **Cây nhị phân phẳng (Flat Binary Tree)**, tối ưu $O(\log_2 N)$ tầng MUX trên LUT6 FPGA. | `N=32`, `MODE=0/1`, `S=$clog2(N)` | **Hoàn thành (100% Pass)** |
| [`dyn_left_shifter.sv`](common/dyn_left_shifter.sv) | Bộ dịch trái động logarit đa tầng ($S = \lceil \log_2 N \rceil$ tầng MUX), dịch $2^i$ bằng pure wiring, tích hợp cơ chế bảo vệ chống tràn ($b \ge N \implies \text{out} = 0$). | `N=32`, `SHIFT_W=$clog2(N)` | **Hoàn thành (100% Pass)** |
| [`dyn_right_shifter.sv`](common/dyn_right_shifter.sv) | Bộ dịch phải động logarit đa tầng, hỗ trợ dịch logic (`ARITH=0`), dịch số học (`ARITH=1`), và điền bit động (`fill_val`), bảo vệ chống tràn ($b \ge N \implies \text{out} = \{N\{fill\}\}$). | `N=32`, `SHIFT_W=$clog2(N)`, `ARITH=0/1` | **Hoàn thành (100% Pass)** |
| [`posit_parser_comb.sv`](parser/posit_parser_comb.sv) | Parser tổ hợp: bù hai → XOR tail theo FRB → một LOD/count → Rgm/dịch payload → tách sf/fraction, chặn Zero/NaR. | `NB, ES, FRAC_MAX, SF_W` | Checkpoint XOR: Verilator bốn format đạt; tổ hợp không có clock. ModelSim trước đây thuộc bản dual-detector |

### B. Các Module Datapath Theo Kiến trúc §5 (Pipeline Architecture)

| Tên Module | Vai trò trong Datapath (§5 SPEC) | Tầng Pipeline & Chu kỳ | Kế hoạch |
|:---|:---|:---:|:---:|
| [`posit_parser.sv`](parser/posit_parser.sv) | Parser elastic hai tầng; dấu/cờ, count và payload cùng stall. Reset có hai FF đồng bộ nhả reset. | Tầng P, hai slot, II=1 khi không stall | Tuần 7; xem nghiệm thu mục5 |
| [`posit_pack.sv`](packer/posit_pack.sv) | Bộ đóng gói và làm tròn RNE FloPoCo (10 bước, có tiền kẹp $sf$) hoặc cắt cụt TRUNC sang Posit bitstring. | TRUNC H=1; RNE H=2: P1 mã hóa/dịch/G-R-S, P2 RNE/carry/dấu (§5.9-D); cần STA | Tuần 8 |
| Context M0 trong `mul_iter_core` | Chốt OPS và config nguyên tử tại launch; giữ metadata đến retire. | Một bank M0, không thêm bank OPS trước context | Đã triển khai/kiểm core09/10; chưa đóng Gate2 |
| [`ops_sel_comb.sv`](multiplier/ops_sel_comb.sv) | OPS normative tổ hợp; cắt fraction trước min-popcount, hòa chọn A, dấu/sf và input_cut. | Chưa có FF; bank M0 là context core theo §5.5-A | Tuần9: kiểm tổ hợp đạt; wrapper tuần tự còn triển khai |
| `sac.sv` | Shift Amount Calculator: đếm số 0 đầu bằng LZD, tính $sa$, tích lũy tổng dịch $S$, và dịch loại bit 1 của $fx$. | Tầng M1..Mn (Lặp $n$) | Tuần 9 |
| [`sac_step_comb.sv`](multiplier/sac_step_comb.sv) | Một bước fraction: LOD MODE0 đếm zero đầu, sa=clz+1, fx_next/scale_next và exhausted/state_error. | Chưa có FF; controller sở hữu token/count | Tuần9: kiểm tổ hợp đạt; core chưa tích hợp |
| `sbm.sv` | Shift-Based Multiplier: Shifter $1.f_Y \gg S$ và Accumulator tích lũy duy trì bit `sticky_acc`. | Tầng Shifter/Accum | Tuần 9 |
| `mul_norm.sv` | Chuẩn hóa tích ($\text{acc} \ge 2.0$), dịch phải 1 bit và tăng scale factor: $sf = sf + 1$. | Tầng MN (1 chu kỳ) | Tuần 9 |
| `posit_add.sv` | Bộ cộng/trừ 2 số Posit unpacked: A1 (Align kẹp cứng $\le 29$), A2 (Add/Sub), A3 (LZC Normalize). | Tầng A1–A3 (3 chu kỳ) | Tuần 10 |
| `round_unpacked_comb.sv` | Reference tổ hợp parse(pack(u)); top NF hiện dùng product packer P1/P2 rồi parser tổ hợp để tách timing. | Product path3 bank, xem OPT-03 | Đã kiểm17/10 |
| `posit_mac_nf.sv` / `mac_nf_wrapper.sv` | Top cấu trúc và wrapper một giao dịch, giữ C_eff/context; chưa FIFO/bypass rút ngắn. | RNE: H=q+13, valid=q+12, II_min=q+14 | OPT-03 đã kiểm |

---

## 3. Quy trình Kiểm tra và Tổng hợp

- **Kiểm tra cú pháp & Linting**:
  ```bash
  verilator --lint-only --timing -Wall -Irtl --top-module posit_mac_f -f rtl/production.f
  ```
- **Chạy Testbench đơn vị tương ứng**: Xem hướng dẫn chi tiết tại [`tb/README.md`](../tb/README.md).

## 4. Nghiệm thu parser tổ hợp — 05/10/2026

Hợp đồng đầy đủ tại SPEC §5.2: `sf` signed, fraction không hidden bit, giữ toàn bộ `FRAC_MAX` bit. Hai detector nhận `NB-2` bit sau FRB; detector được chọn invalid trả `cnt=NB-2`. Payload rộng `NB-3` bit, loại terminator trước khi lấy exponent. Zero/NaR có sf/frac=0 và dấu lần lượt 0/1. Không có clock, reset hoặc ready/valid ở module này.

ModelSim Altera 10.1d kiểm **2.465.812 đầu vào, 0 mismatch** trên tất cả năm đầu ra. Posit8 ES0: vét cạn 256; posit16 ES1: vét cạn 65.536; posit32 ES2 và ES3: mỗi format 1.200.010 corner/phân tầng. Seed `20261005`; mỗi polarity/run regime hữu hạn có ít nhất 19.672 lượt, mỗi nhóm regime/dấu ít nhất 39.344. Phân tầng ưu tiên bao phủ, không phải phân bố đo Table I. Bộ sinh so L1 với decoder tuần tự trường độc lập trước khi xuất fixture; không link SoftPosit trực tiếp. Các format ngoài bốn cấu hình trên chưa nghiệm thu.

Tái chạy: trong WSL, vào `l1` và chạy `make gen_parser_vectors.exe`; sau đó ở thư mục dự án cha, PowerShell chạy `& ./Posit_MAC/scripts/verify_parser_comb_modelsim.ps1`. Script sinh lại vector, compile/mô phỏng, kiểm marker và tổng số lượt, lưu SHA256. Log, phiên bản compiler/simulator, seed và lệnh ở `results/parser_comb/`. Linux build bằng `make gen_parser_vectors`, chạy `./gen_parser_vectors ../results/parser_comb` khi chưa có mô phỏng đọc fixture.

Vivado 2026.1 `xvlog --sv` đã compile RTL/testbench đạt (`vivado_compile.log`); kiểm chứng runtime ở đây dùng ModelSim. Chưa tổng hợp/STA/PPA và chưa nghiệm thu latency/backpressure; chỉ thêm pipeline sau nghiệm thu tổ hợp.

## 5. Parser pipeline hai tầng

Nghiệm thu 05/10/2026: **2.465.812 fixture, 0 mismatch** trên ModelSim10.1d: posit8 ES0/posit16 ES1 vét cạn và posit32 ES2/ES3 phân tầng. Ngoài stream có các giao dịch directed kiểm reset/stall; ba lần reset mỗi format, gồm hủy một/hai slot. Không mở rộng kết luận sang các format chưa chạy hoặc MAC tích hợp.

`posit_parser.sv` dùng cùng hợp đồng dữ liệu với parser tổ hợp. P1: bù hai → XOR tail theo FRB → một LOD/count → thanh ghi cnt/FRB và payload/metadata. P2: tạo regime từ cnt/FRB song song với dịch payload → tách trường/ghép sf → thanh ghi đầu ra. Hai tầng có enable riêng; `p2_ready = !p2_valid_q || out_ready`, `p1_ready = !p1_valid_q || p2_ready`. Sức chứa là hai giao dịch; khi đầy và đầu ra bị chặn thì `in_ready=0`.

Theo Guidelines, reset cục bộ là `reset_n` tích cực thấp, assert bất đồng bộ, deassert đồng bộ qua `meta_sync1/meta_sync2` có thuộc tính `ASYNC_REG`. Reset flush hai slot và xóa dấu/cờ/dữ liệu; chỉ nhận giao dịch sau khi synchronizer nhả reset. Startup hai cạnh được tách khỏi latency dữ liệu. Không gated clock, không latch, không thêm delay trong logic tổ hợp; các FF dùng macro `CK2Q` trong header chung. Cổng nối theo tên, mỗi module một file và các khai báo/nhánh được tách dòng để debug.

Nếu nhận input tại E0 thì output valid sau E1, consumer nhận sớm nhất E2; khoảng cách handshake là hai chu kỳ, hai bank thanh ghi, `II=1` khi không stall. Đây là quy ước cạnh cụ thể, không phải ba bank với thêm một thanh ghi ngõ vào. Khi stall, dữ liệu/flags/valid đầu ra giữ nguyên đến handshake.

Tái chạy ở thư mục cha dự án: `& ./Posit_MAC/scripts/verify_parser_modelsim.ps1`. Cần fixture nghiệm thu của parser tổ hợp; script kiểm SHA256 fixture trước khi chạy. Testbench bốn format so tất cả trường với fixture, kiểm thứ tự/sức chứa, reset rỗng/một slot/hai slot, giữ đầu ra khi stall dài, bubble, handshake đồng thời và latency/II không stall. `results/parser_pipeline/` lưu compile/simulation, summary, phiên bản simulator và hash nguồn/fixture. `-CollectExisting` chỉ thu kết quả một lượt đã chạy khi hash nguồn khớp bản compile; mặc định chạy compile và simulation mới.

Vivado 2026.1 đã compile và elaborate RTL/testbench; ModelSim dùng để nghiệm thu runtime. Chưa có tổng hợp/STA/PPA hoặc xác nhận CDC/RDC bằng công cụ chuyên dụng.

**Rà soát vị trí Rgm ngày06/10/2026:** chọn cách Fig.5(a), chốt `cnt/r` trong P1 và tái tạo `k` trong P2 thay vì giữ đồng thời `cnt/k`. Giảm `CNT_W` bit thanh ghi mô tả mỗi parser, bằng5 bit với NB32. Phép XNOR tạo k đi song song với bộ dịch, không thêm tầng/handshake. Không đổi hợp đồng số học, reset, II hoặc latency. SPEC trước đó mô tả vị trí triển khai cũ, không phải ràng buộc số học buộc lưu k ở P1; đã cập nhật lại phân tầng §5.2 và bảng CK.

Kiểm lại toàn bộ2.465.812 fixture trên ModelSim đạt,0 mismatch, các kiểm tra reset/stall/II/latency vẫn đạt. Vivado compile/elaborate bản mới đạt. Thử tổng hợp so trước/sau bị chặn ngay lúc khởi động Vivado vì thiếu license, nên **chưa khẳng định giảm5 FF vật lý, LUT hoặc tăng fmax**. Snapshot cũ và trạng thái so sánh tại `results/parser_regime_retime/`; lệnh so khi có license: từ thư mục đó chạy `vivado -mode batch -source ../../scripts/compare_parser_regime_registers.tcl`. Đây là so tài nguyên tổng hợp trên Artix7, không phải đo PPA/post-route đối chiếu paper. Slide cập nhật: `Ppt/Datapath_Posit_Parser_20261006.pptx` ở thư mục cha dự án.

## 6. Packer RTL — tuần8

Giao diện theo SPEC §5.9-D: sign/is_zero/is_nar, sf signed, frac không hidden, sticky và flags_in; d/flags đầu ra. F_IN mặc định2*FRAC_MAX+1 (11/25/55/53 cho8/0,16/1,32/2,32/3), tối thiểuFRAC_MAX+2, tối đa63 với adapter L1 hiện tại. Cấu hình khác chưa nghiệm thu.

- posit_pack_prepare.sv: mã hóa P1, offset từ XOR các bit k với dấu (k<0: ~k=|k|-1), dùng dyn_right_shifter đã có và gom mọi bit bị mất vào sticky. Không cần adder để tính |k|-1.
- posit_pack_finish.sv: RNE/carry, clamp magnitude và bù hai dấu ở P2. TRUNC chọn tham số elaboration, bỏ tăng RNE; inexact vẫn phản ánh bit bị cắt.
- posit_pack_comb.sv: wrapper tổ hợp dùng chung hai khối; posit_pack.sv: wrapper RNE hai slot elastic hoặc TRUNC một slot. Mỗi module/file, enable chung cho bundle, CK2Q, reset_n assert bất đồng bộ/deassert hai FF. RNE E0→valid E1→handshake E2; TRUNC valid sau E0→handshake E1, II=1 không stall.
- Parser nối bằng frac_pack={frac_parser, zeros}, sticky=0, flags_in=0. Nhân/cộng phải chuẩn hóa trước, lấy F_IN bit cao và OR phần thấp bị bỏ vào sticky; không làm tròn ở adapter.

Pre-clamping minpos dùng sf<-SF_MAX, giữ đúng RNE ở biên; posit8/ES0 giá trị1.5*minpos là tie0x01/0x02, chọn0x02. flags_in[4] hoặc is_nar buộc NaR ưu tiên và flags10000; các cờ hữu hạn OR theo SPEC.

Tái lập: build fixture generator bằng make -C l1 gen_packer_vectors.exe trong môi trường MinGW/WSL, sau đó chạy scripts/verify_packer_modelsim.ps1 từ PowerShell. Script kiểm hash fixture parser, compile, chạy packer và chuỗi parser→packer; CollectExisting chỉ nhận snapshot/log khớp hash. Fixture/log/compiler/seed tại results/packer/; chỉ summary.json PASS mới là nghiệm thu đủ cả hai suite.

Khảo sát tài nguyên/timing: scripts/run_packer_ppa.ps1, cùng NB32/ES2/F_IN55 và boundary input/output có thanh ghi, EP4CE22F17C6, clock10ns, seed1/2/3. packer_ppa_top.sv chỉ chứa instances; packer_ppa_boundary.sv là continuous-stream benchmark, không phải MAC top/board interface. Boundary đã kiểm riêng3994 đối chiếu. Quartus13 dùng export shifter có generate tường minh, 9120 phép kiểm basis cho các độ rộng14/29/60/59; RTL gốc giữ nguyên. Chi tiết tại results/packer_ppa/. Đây là PPA packer riêng với LUT4 và I/O chưa ràng buộc board; không suy full MAC hoặc fmax Virtex của paper. Quartus bỏ qua ASYNC_REG của Xilinx nên khảo sát này không thay RDC/reset sign-off.

**Nghiệm thu07/10/2026 — ✅ tuần8 đơn vị:** results/packer/summary.json PASS:5.947.048 packer mode checks và4.931.624 chain checks,0 mismatch. Bốn format đều RNE/TRUNC; comb, flags, reset/startup/flush, slot capacity, stall dài, ordering, simultaneous handshake và128 giao dịch latency/II không stall mỗi suite đạt. Vivado compile/elaborate đạt, không gọi là XSim runtime.

PPA benchmark3seed/cấu hình sau tối ưu P2 ngày07/10: RNE537 LUT4/196FF, fmax122,50–124,42MHz; TRUNC522 LUT4/152FF, fmax100,67–101,01MHz. Cả ba seed mỗi mode đạt setup10ns; TRUNC dư nhỏ. So với bản trước, RNE giảm54 LUT4, TRUNC giảm40 LUT4, FF không đổi. RNE thêm15 LUT4/44FF so với TRUNC; FF gồm boundary chung. Đây là timing register-register của packer riêng, chưa timing board hoặc full MAC/Gate4. Baseline và comparison.json lưu tại results/packer_p2_optimization/.

P2 giữ cùng ports/P1 bundle và latency. Với m=zero_extend(mag_trunc), r=round_up, bộ cộng duy nhất tính `(m XOR {NB{sign}})+(sign XOR r)`. Kiểm m=0/maxpos song song trước bộ cộng và chọn mã biên có dấu, thay chuỗi tăng→kẹp→bù hai nối tiếp. Kiểm tương đương với bản trước bằng `scripts/verify_packer_p2_equivalence.ps1`: 1.448.576 lượt đạt, NB8 vét cạn mọi đầu vào nhị phân (kể cả selector không hợp lệ), NB16/32 ngẫu nhiên, cả RNE/TRUNC; không thay thế oracle L1 của hồi quy đầy đủ.

**Nghiệm thu lại sau tối ưu P2 —07/10:** hồi quy đầy đủ ModelSim PASS 5.947.048 packer +4.931.624 parser→packer,0 mismatch. Kiểm tương đương1.448.576 và boundary3.994 đạt; Vivado2026.1 compile/elaborate đạt. Tổng kết, SHA256 và lệnh tái lập tại results/packer_p2_optimization/summary.json.

## 7. Khởi động tuần9 — OPS/SAC tổ hợp — 08/10/2026

Hợp đồng canonical tại SPEC §5.4/§5.5-A/§5.7; lịch thực thi và trạng thái tại [hồ sơ Gate2](../../doc/Optimization.md#legacy-7-11). Profile chính dùng fixed-A/min-popcount và SAC quét bit1; predictor/RND paper có giao diện nghiên cứu riêng. Không dùng `ops_compare_top.sv` khảo sát PPA cũ thay trực tiếp OPS normative.

`ops_sel_comb.sv` nhận fraction parser không hidden; approx cắt xuống FRAC_W trước cây popcount cân bằng. Output x_frac căn phải không hidden, y_mant có hidden ở bit active_width. Tie chọn A, input_cut ghi phần bị bỏ; cfg_error trả bundle0 cho cấu hình bị cấm. Module chỉ nhận trường finite, chưa thực hiện bypass Zero/NaR hoặc M0 register.

`sac_step_comb.sv` trả term_valid, sa, fx_next/scale_next, exhausted/state_error. W_X=1 xử lý riêng; W_X>=2 dùng LOD MODE0 và dyn_left_shifter đã kiểm. Scale cộng mở rộng rồi kiểm <=W_X, không wrap. `iter_ctrl` sở hữu count/token first/last/init_only; leaf này không có clock/reset.

**Nghiệm thu tổ hợp:** ModelSim10.1d,159.820 vector OPS (feature bật/tắt) +167.620 trạng thái SAC,0 mismatch; width1/5/12/26/27. Generator L1 + oracle scalar độc lập, Linux/Windows/UBSan PASS và fixture khớp, seed20261008. Compile/mô phỏng cuối không warning. Log/hash/compiler/commands: `results/week9_frontend/summary.json`; chưa Gate2/latency/handshake/STA/PPA.

Tái chạy từ thư mục Posit_MAC:

```sh
# Trong WSL/MinGW:
make -C l1 gen_week9_frontend gen_week9_frontend.exe gen_week9_frontend_ubsan
./l1/gen_week9_frontend results/week9_frontend/linux
./l1/gen_week9_frontend_ubsan results/week9_frontend/ubsan
```

```powershell
./scripts/verify_week9_frontend_modelsim.ps1
python ./scripts/summarize_week9_frontend.py
```

Script PowerShell sinh fixture Windows và compile leaf/TB trong work riêng. Python kiểm count, fixture ba nền tảng, log và hash. Bước tiếp theo W9-03 là SBM/normalize và adapter packer; không thêm FF vào OPS/SAC tổ hợp trước khi xác nhận hợp đồng core.

## 8. Multiplier standalone và research paper — 09/10/2026

W9-03 đã kiểm shifter, cộng tổ hợp, normalize/adapter:252.455 commit trên width1/5/12/26/27, hai scheme,0 mismatch. Bank `sbm_accum` được kiểm trong core; FLOOR bỏ padding trước normalize, không đưa input_cut vào numerical sticky.

W9-R1 chốt interface `paper_ops_comb`/`paper_step_comb`: Q12/prefix7 đệm0, tie-A, anchor số hạng đầu và payload13+carry1 là giả định tái dựng; RND/complement, coefficient âm và cut trước cộng/trừ ghi riêng. W9-R2 đạt843 commit,293 bản ghi (292 bản ghi corpus/206 trường hợp phân biệt + một fixture Fig.4),0 mismatch. Output force-X=0x1ae34000; kiểm thêm đủ128 entry PT2 và tie-A đạt. Không có bằng chứng mới để chạy R3 hoặc xác nhận RTL tác giả.

W9-04 đạt39.580 giao dịch hoàn tất và420 lượt reset hủy; width1/5/12/26/27, exact vượt N_MAX, n=0/early-stop, done=t+2 hoặc3, drain và context cố định đều được kiểm. W9-05 tích hợp parser A/B → M0/core → norm → packer với một slot dự trữ; pilot bản cuối31.840 giao dịch +160 reset hủy,0 mismatch. Reset bridge lấy mẫu rst_n; out_valid bị chặn tại cạnh reset, mỗi leaf nhả qua hai FF. RNE: L_valid=max(1,t)+7, TRUNC:max(1,t)+6; handshake khi không stall sau đó một cạnh. Thử config reserved/n>N_MAX, NaR/zero, stall dài, cạnh reset và giữ thứ tự.

ModelSim đối chiếu 16.815.920 giao dịch, hủy 80.080 giao dịch bằng reset,0 mismatch.

Corpus random-bit10.080.000 dòng chỉ kiểm số học, không đủ coverage regime dài. Đã bổ sung corpus phân tầng16.896.000 dòng/16 profile, có36 ô mode/ops/n, nhóm regime–dấu và fraction đặc thù theo §6.3. Generator phân tầng kiểm3.168.256 exact/RNE với L0 và1.056.256 với oracle ES3 độc lập; chỉ số này chưa thay kiểm RTL. Chạy riêng từng profile bằng verify_week9_multiplier_parallel.ps1; pilot đối chuẩn cùng checker đạt31.840 giao dịch/0 mismatch. Lượt16-DUT cũ đã dừng và không được tính nghiệm thu. Generator/fixture không thay nghiệm thu RTL. Verilator chưa có; `make lint` hiện trả lỗi khi thiếu công cụ thay vì skip rồi báo thành công. Harness C++ và `scripts/verify_week9_verilator.sh` đã chuẩn bị nhưng chưa build/chạy, cần đối chuẩn pilot khi có công cụ. Không tự cài công cụ ngoài quyền đã cấp.

Quartus13 phân tích/tổng hợp NB32/ES2/FLOOR/RNE đạt0 lỗi,14 warning đã phân loại (license parallel, attribute ASYNC_REG của Xilinx và constant resize có giới hạn); không có cảnh báo latch. Đây không thay strict lint, STA, CDC, PPA hay Gate4. Chỉ đổi generate/genvar để hỗ trợ compiler cũ trong hai shifter/OPS, không đổi phương trình; đã chạy lại327.440 frontend vector và843 paper commit đạt.

Bằng chứng, compiler, seed20261009, SoftPosit library hash, lệnh và SHA256: `results/week9_implementation/summary.json`; các log ở `results/week9_arithmetic`, `week9_paper`, `week9_core`, `week9_multiplier`. Gate2/tuần9 vẫn processing do lint/harness chính thức còn thiếu (coverage chức năng phân tầng đã đạt); tuần4/provenance paper giữ processing. GitHub đã push checkpoint 0ae39c4 lên main bằng checkout riêng trong Posit_MAC; kết quả lượt lớn được bổ sung cuối phiên.

`posit_mul_iter` là top chỉ ghép instance. `mul_iter_wrapper` chốt cfg ở handshake E0, nhận cặp parser nguyên tử, giữ slot đến retire. `mul_iter_core` chốt context ở launch L0, `iter_ctrl` phát L1, bank term L2, `sbm_accum` commit L3. `mul_norm_comb` đồng thời thực hiện adapter không làm tròn; wrapper có một bank norm trước packer. Ports top:clk/rst_n/in_valid/in_ready/a/b/cfg_mode/cfg_n/cfg_ops/out_valid/out_ready/d/flags. ROUND_SCHEME và ROUND_MODE là tham số compile; cfg_mode/cfg_n/cfg_ops được chốt mỗi giao dịch. Baseline test EXACT_EN=OPS_EN=1; disable policy đã kiểm ở OPS đơn vị, không tuyên bố coverage full top mọi tham số tùy biến.

## 9. Top paper hồi tiếp tự động — 09/10/2026

`paper_mul_iter` là top structural riêng, logic trong `paper_mul_wrapper` và `paper_norm_comb`; cố định posit32/ES3, fraction12, PT2 prefix7 đệm0/tie-A, complement/RND, anchor số hạng đầu, accumulator Q2.12/14 bit và per-term FLOOR trước áp dấu, output cut12/TRUNC. Các lựa chọn tái dựng giữ nguyên; không đổi hợp đồng normative. `n_terms=1..8` đếm cả số hạng đầu, khác `cfg_n` normative; 0 và9..15 không được nhận. `force_a` phục vụ fixture/so fixed-A, bình thường0. NaR ưu tiên Zero.

E0 nhận A/B/n/force nguyên tử qua valid/ready; chốt X/Y, sign, sf_base, anchor và limit. Mỗi cạnh tiếp theo tự cập nhật một term cùng mantissa/exponent/coefficient/accumulator; dừng khi residual0 hoặc đủ n_terms. Sau t commit, cạnh E(t+1) chốt kết quả normalize→packer và phát out_valid; special t=0. Một slot giữ kết quả tới retire, không nhận thêm khi busy/stalled. `reset_n` assert bất đồng bộ, deassert qua hai FF tại wrapper; reset hủy giao dịch và chặn valid/ready/trace. Đây là lịch research địa phương, chưa xác nhận pipeline/timing của tác giả.

ModelSim10.1d đạt **17.181 giao dịch hoàn tất /65.710 commit,0 mismatch**. Bao gồm292 bản ghi corpus phân biệt cũ + fixture Fig.4, toàn4096 fraction A Q12 ở n1/3/8,100 cặp corner x3 giá trị n x2 policy force,500 cặp random x n1..8; seed20261009. Đối chiếu thụ động trace trước/sau từng vòng và output; không cấp lại trạng thái, không hierarchical force/write. Audit xác nhận843 commit cũ giống hoàn toàn, Linux/Windows/UBSan fixture MATCH; reference residual Q96 độc lập kiểm power/coefficient/accumulator/pack.

Fig.4 force-X: accumulator4616→5770→5914, output **0x1ae34000**. Kiểm216 special,24.036 term âm,14.199 term0,45.468 term có tail,1.082 dừng sớm,178 stall96 chu kỳ và4 reset hủy (sau capture, giữa vòng, PACK, HOLD) đạt; config/context đổi khi busy không ảnh hưởng giao dịch đang sở hữu. Không nghiệm thu flags riêng của paper, code coverage, lint, STA/PPA hoặc Gate2 bằng suite này.

Bằng chứng: `results/paper_top/windows/summary.json`, `results/paper_top/audit.json`; lệnh `make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan`, `scripts/verify_paper_top_modelsim.ps1`, `scripts/audit_paper_top.py`. Compiler/seed/lệnh/hash được lưu cùng kết quả. Không có thay đổi số học hoặc bằng chứng nguồn mới: **không chạy pilot TableI**, baseline gốc và tuần4 tiếp tục processing; Gate2 normative giữ trạng thái trước đó.

## 10. Phạm vi baseline paper sau audit nguồn — 09/10/2026

Audit trực tiếp nguồn2019/2021 và kiểm deterministic163.840 cặp cho thấy RND/complement và quét bit1 không tương đương. Fig4 khớp n_fraction2/n_total3 (0x1ae34000), nhưng n_total2 cho0x1ad14000; TableI Proposed chưa khóa cách đếm/recurrence từ nguồn. Giữ nguyên profile normative và top RND nghiên cứu, không đổi n/seed để ép bảng.

Reference cổng Fig5 độc lập khớp L1 trên3.940.352 trường hợp; ModelSim155.648 trường hợp đạt0 mismatch, Linux/Windows/UBSan MATCH.8.448 raw/clamped differences nằm ngoài miền sf−240..240, do range handling đồ án bổ sung; không phải lỗi RTL hoặc xác nhận clamp tác giả. Không chạy pilotTableI, baseline gốc/Gate2 vẫn processing. Chi tiết duy nhất tại README L1 §24; bằng chứng/lệnh/hash/compiler tại results/paper_contract_audit/{summary.json,windows/summary.json}.


## 11. Harness Verilator pilot — 10/10/2026

Pilot Verilator5.032 đã build/chạy đủ16 profile từ final_pilot:32.000 dòng,31.840 so sánh,160 reset hủy,336 stall96 chu kỳ,0 mismatch. Hash fixture và counters khớp ModelSim parallel_pilot; kiểm config reserved/n>8, startup/reset, latency, đổi context lúc busy, stall/order. Runner mặc định chuyển sang final_pilot còn giữ; preflight16 fixture, snapshot nguồn và make với đường dẫn tương đối/CURDIR=. xử lý thư mục có khoảng trắng, không sửa cài đặt. --no-timing bỏ delay CK2Q cho mô phỏng chu kỳ; warning giữ trong build.log, -Wno-fatal chỉ dùng build chức năng, không thay strict lint. Đây là fixture replay, chưa phải scoreboard gọi trực tiếp L1/L0. Gate2/W9-06 vẫn processing: lint còn cảnh báo, cần scoreboard trực tiếp, corpus phân tầng>=10^7 và coverage; line/branch/toggle chưa đo. Vector lớn đã dọn, phải sinh lại và kiểm hash trước replay. Không sửa RTL số học hoặc chạy TableI. Bằng chứng results/week9_multiplier/verilator/final_pilot/summary.json; lệnh bash --noprofile --norc scripts/verify_week9_verilator.sh final_pilot, audit scripts/audit_week9_verilator.py. Seed20261009; compiler/make/version và hash lưu cùng kết quả.

## 12. Nghiệm thu Gate2 — 10/10/2026


Gate2 multiplier **✅** theo mốc tuần9 (10/10/2026):16.815.920 giao dịch phân tầng/0 mismatch; scoreboard trực tiếp L1/L0 và oracle ES3; strict lint16/16 sạch; corner114.656/0 mismatch trên ModelSim và Verilator. Seed20261009, SoftPosit0.4.1, GCC15.2.0, Verilator5.032 và ModelSim10.1d; lệnh/hash/phiên bản lưu với bằng chứng.

Coverage chức năng đạt256/256 bin posit32, min4104 mẫu/bin,26241 operands/run/polarity và36 ô config/profile; structural coverage sau ghép corner: line 91.67–96.23%; branch 91.84–94.79%; toggle 73.10–87.33%, giữ các điểm chưa hit. Mốc này không quy định ngưỡng phần trăm structural coverage và không phải coverage100% hoặc signoff vật lý.

Trạng thái canonical tại `results/week9_implementation/gate2_acceptance.json`; hướng dẫn tái lập và giải thích phạm vi tại [hồ sơ Gate2](../../doc/Optimization.md#legacy-7-11). Những mục processing trước đây là lịch sử. Ma trận cuối SPEC§6.7, tuần10 adder/tuần11 MAC-Gate3 và PPA/Gate4 còn mở; provenance/TableI giữ processing, không chạy lại TableI trong phiên này.


## 13. RTL adder — nghiệm thu đơn vị tuần10, 12/10/2026

posit_add_comb và pipeline posit_add dùng chung posit_add_align/arith/normalize. Ba slot, E0 nhận→valid E2→handshake E3,II1 không stall, reset leaf2FF. ModelSim comb143.976, pipeline143.376/600 abort,0 mismatch; Verilator20.000.004 completedES2/ES3, oracle độc lập/flags/unpacked và RNE/TRUNC đạt. Strict lint8/8 sạch; canonical results/week10_adder/summary.json. Raw coverage chưa đạt finalAC04, giữ unhit points; không phải MAC/Gate3, STA hay fused. Source L1 frozen không đổi. Runner/commands tại [Optimization §8.4](../../doc/Optimization.md#legacy-8-4); không đưa prepack chưa round vào adder NF.


## 14. MAC NF — nghiệm thu Gate3 milestone, 13/10/2026

**Checkpoint W11 lịch sử (trước OPT-03):** posit_mac_nf/mac_nf_wrapper dùng mul_prepack_norm_comb bảo toàn carry và round_unpacked_comb=parse(pack(u)) tổ hợp; legacy L1/RTL freeze giữ nguyên. Approximate NF mới có thể khác legacy; cùng P_hat theo SPEC v1.11§11.10. Gate3 native32/3 10.000.000 completed, ModelSim28.512 completed/288 reset-aborted,0 mismatch; strict lint4/4,72 control bins và256 regime–dấu main. Canonical results/week11/summary.json; baseline_nf_manifest.json/source+binary+fixture hashes, raw coverage/unhit giữ nguyên. L1 fused full-sum pilot100k/Python independent0 mismatch; chưa fused RTL/window/flags/acc_mode, final AC02/AC04/per-n matrix hoặc accuracy/PPA. Commands [Optimization §8.6](../../doc/Optimization.md#legacy-8-6); rebuild binaries/fixtures trước audit sau cleanup.

## 15. Cập nhật phạm vi nghiệm thu — 14/10/2026

SPEC v1.13 đã được rà toàn bộ theo RTL/model/bằng chứng hiện hành. Nguồn RTL và L1 frozen không đổi; kết quả W11 numeric/protocol10.000.000 completed,0 mismatch vẫn giữ nguyên.

Gate3 đầy đủ còn **processing**: cận trên near-cancellation ở đầu vào adder NF chỉ420.303/10.000.000=4,20303%, thấp hơn yêu cầu30% của SPEC§6.3. Các bin regime/config đã hit không thay yêu cầu phân bố này. Counters từng run/polarity và packer bins cần được lưu đủ trước signoff; không hạ ngưỡng hoặc sửa report lịch sử.

Checkpoint13/10 và manifest NF đóng băng mốc số học/giao thức, không chứng minh mọi AC đã đạt. Công việc bổ sung tại [Optimization §8.7](../../doc/Optimization.md#legacy-8-7)/SPEC§11.11; chứng cứ rà soát ở results/spec_review_20261014/summary.json. F full-sum vẫn là pilot phần mềm; F RTL/window/flags/acc_mode, ma trận final và accuracy/PPA còn mở.


## 16. Hoàn thành coverage NF/Gate3 — 14/10/2026

Checkpoint mới `results/nf_coverage_20261014/completion.json` đạt main32/3 10.000.000 completed,75.379 reset-aborted,0 mismatch;near-cancellation52,55548% đo trực tiếp tại ngõ vào adder với C_eff.256 cross min30.114,61 run/polarity min199.470 và counters packer/control/popcount/iteration đã đạt. ModelSim fixture mới28.512 completed/288 abort và corner82.944 completed đều0 mismatch;fraction0/ones/AA/55 và exact depth5/12/27/26 đã kiểm.

Nguồn RTL/L1 frozen và checkpoint13/10 giữ nguyên; bổ sung verification/corpus/probe chỉ đọc. Mục cập nhật phạm vi trước đó là lịch sử phát hiện gap,bổ sung mới đã đóng tuần11. Lệnh/seed/hash/tool/audit tại [Optimization §8.9](../../doc/Optimization.md#legacy-8-9),SPECv1.14§11.12. Gate3 tuần11 không thay final per-n/exhaustive/AC04,oracle/model/cửa sổ/RTL fused,paired accuracy hoặc STA/CDC/RDC/PPA. W12-01 đạt;ưu tiên W12-02..04 tiếp theo.


## 17. OPS refactor bit-exact — 14/10/2026

ops_sel_comb tách masked-popcount và data alignment/hidden song song,trước một tầng swap cuối. Parameter/ports,hidden-X/Y,M0/latency và L1 giữ nguyên. ModelSim matrix1.334.048 checks/0 mismatch,398 lint sạch và NFmain10M/0 mismatch;ModelSim NF28.512 completed0 mismatch. Benchmarkcùng6run3seed/bản,F26/FW12/SW11,Quartus13/EP4CE30F23C6:216→196LUT4,151FF giữ nguyên,median108,08→112,01MHz. Đây làOPS riêng,không Fmax MAC hoặc LUT6. Canonicalresults/ops_refactor_20261014/summary.json;SPECv1.15§5.4/11.13 và [Optimization §8.10](../../doc/Optimization.md#legacy-8-10) có lệnh/scope. Source-bound lịch sử giữ nguyên,dùng snapshot cũ để audit lịch sử; dùng checkpoint mới cho RTL hiện hành. Fused/final matrix/toàn MAC timing/PPA còn mở.

## 18. Timing sơ bộ toàn NF và bàn giao F — 15/10/2026

Toàn posit_mac_nf32/3,FW12,EXACT_EN=OPS_EN=1 đã post-route Quartus13.0sp1/EP4CE30F23C6 trên3seed:3926LUT4/823FF,DSP0/memory0,median45,07MHz;setup100MHz chưa đạt. Đường chính từacc qua mul_prepack_norm_comb vàround_unpacked(pack/parse) tới product_frac_q. Córeport riêng9 nhóm stage,logic/routing/fanout vàI/O constraints giả định0,5/0,1ns;không đường setup/hold unconstrained. Không phải timingboard hoặc PPA so paper trênLUT6.

Source canonical RTL không đổi. Bản copy parser choQuartus13 chỉ thêm generate/endgenerate;audit so tokens xác nhận logic giữ nguyên. ASYNC_REG bịQuartus13 bỏ qua,còn review CDC/RDC riêng. Đề xuất constant slices/norm–round pipeline,A1align,A2/A3retiming vàSACfeedback tại [Optimization §8.14](../../doc/Optimization.md#legacy-8-14)/results/week12/pipeline_recommendations.json,chưa áp dụng hoặc thay baseline.

L1 F_W32/flags/state đã đóng G-F-L1 với oracle độc lập,nguồn tại l1/include/posit_fused_window.hpp;không có RTL F trong phiên tuần12. Hợp đồng W12-F-1 vàpipeline dự kiếnF1..F5 ởSPECv1.16§5.12/11.14,handoff.json. Tuần13 thực hiệnRTL theo model frozen trước pilot/regression. Runners/hash/timing tại results/week12/summary.json và[Optimization §8.14](../../doc/Optimization.md#legacy-8-14) và [PLAN — fused](../l1/PLAN.md#4-l1-và-rtl-fused-w12-f-1);final NF/F matrix,accuracy/PPA vàGate4 còn mở.


## Khảo sát primitive v2 — 16/10/2026

`candidates/primitives_v2/` chứa các nguồn thay thế cùng tên module để đo riêng: `group4`, `group4_mixed` cho LOD/LZD; `reverse`, `radix4`, `native` cho shifter. Mỗi lượt chỉ biên dịch đúng một triển khai cho một tên module. Các file này không nằm trong `production.f`.

`common/lod_lzd_core.sv` đã chọn nhóm4 riêng MODE0,N31/32,S=clog2N; các cấu hình khác vẫn dùng cây nhị phân. Hai shifter `common/` giữ nguyên byte: các bản thử chưa giữ được lợi ích timing qua cả hai Artix7 và các kiểu fill/width liên quan. Quyết định và hash nguồn ở `adoption.json`; đã kiểm tích hợp NF32 ES2/ES3 và F32 ES3, mỗi bản10.000 giao dịch/0 mismatch. Các nguồn `selected` còn gồm native12 chỉ là bản thử, không phải toàn bộ nguồn production. Snapshot/hash/báo cáo tại `results/primitive_v2_20261016`; lệnh tại `scripts/README.md`, phân tích tại PLAN L1 §8.18. Không thêm latency hoặc đổi giao diện số học trong khảo sát này.

## Parser một detector — 16/10/2026

Hai module parser tổ hợp/pipeline dùng XOR tail với FRB rồi một LOD MODE0,N=NB-2. Payload giữ magnitude gốc; no-terminator→cnt=NB-2. I/O/parameter, hai tầng elastic và lịch handshake giữ nguyên. Với posit32 detector N30 vẫn dùng nhánh binary của common/lod_lzd_core. Bản dual-detector trước sửa được giữ tại results/parser_xor_20261016/source/baseline, không nằm trong production.f. Kết quả kiểm và đánh đổi LUT/STA tại [Optimization §8.19](../../doc/Optimization.md#legacy-8-19).


Đợt parser XOR đã hoàn thành24 P&R A35T/A100T,32/2 và32/3: median225→205LUT, FF không đổi; STA tăng/giảm tùy part/profile ([Optimization §8.19](../../doc/Optimization.md#legacy-8-19)).4.984.616 lượt parser/parameter đạt0 mismatch và NF ES2/ES3/F smoke mỗi bản10.000 đạt; không thay ma trận final hoặc PPA toàn MAC.

## Prepack normalization OPT-01 — 16/10/2026

`candidates/multiplier/mul_prepack_norm_comb.sv` là ứng viên tạo fraction bằng nối bit hằng cho bốn trường hợp exact/approx và carry/no-carry, thay runtime integer/chỉ số đích động. Chỉ dùng MUX chọn ứng viên và cập nhật SF theo carry; I/O/parameter và mọi bank/handshake giữ nguyên. FLOOR bỏ hai padding vật lý, giữ bit giá trị dưới hidden khi carry. EXACT_EN0 không sinh cone exact, chỉ cfg_mode1 thuộc miền hợp lệ. Các kiểm width override không bổ sung profile precision mới; main NF vẫn F_IN=2F+1. Bản trước/sau, chức năng và STA tại results/prepack_refactor_20261016 và [Optimization §8.20](../../doc/Optimization.md#legacy-8-20); các bước OPT-02/03 chưa thực hiện.

Ứng viên prepack đã qua1.592.064 kiểm leaf, NF main10M và ModelSim82.944 corner0 mismatch;12 P&R cho median MHz giảm0,31% A35T và2,45% A100T, FF không đổi. Vì chưa có lợi ích timing nhất quán, `multiplier/mul_prepack_norm_comb.sv` giữ nguyên baseline; candidate không nằm trong production.f. Không thay pipeline hoặc làm OPT-02/03.


## NF product pipeline OPT-03 — 17/10/2026

Top NF dùng normalize+product packer RNE P1 → P2 → parser tổ hợp/product bank → adder3 → final packer2. Giữ bit-exact R(P_hat), flags và C_eff; product numerical sticky=0. L_valid=q+12, handshake=q+13, II_min=q+14 (thêm2 chu kỳ), q=max(1,t thực tế). Reset/stall/commit giữ một transaction; không thêm FIFO. Fused và standalone multiplier không đổi. Production prepack normalization giữ bản gốc; không ghép candidate OPT-01. Kết quả và hạn chế: [Optimization §8.21](../../doc/Optimization.md#legacy-8-21), SPEC§11.16, results/opt03_20261017/summary.json.


## A1 OPT-02b candidate — 17/10/2026

`candidates/adder/opt02b/posit_add_align.sv` dùng dual signed delta/clamp, sf-only shifter, equal-sf bypass và prefix-OR jam lookup. Cùng module name/I/O/parameter và zero added stages; chỉ thay thế file production trong source list private, không compile hai module cùng tên. Production A1 giữ nguyên; candidate đã qua leaf880.656 và NF10M/0 mismatch,406+4 strict lint, ModelSim tích hợp. Một run A35T100MHz đạt WNS+0,251ns/hold+0,047ns với2516LUT/930FF; cần matched>=3 run trước promote. Xem [Optimization §8.23](../../doc/Optimization.md#legacy-8-23).
