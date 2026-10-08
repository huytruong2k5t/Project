# Thư mục Mã nguồn RTL (`rtl/`)

**Hợp đồng tích hợp cập nhật 06/10/2026 — SPEC v1.4:** RTL baseline v0/v1 giữ profile L1 normative: cfg_ops=0/1, cfg_n đếm fraction, hidden khởi tạo riêng; paper_source_config/predictor7-bit là nghiên cứu riêng. H là ngân sách hạng thanh ghi; không bubble thì L_valid=H-1, L_handshake=H (E0 là input handshake). n=0 dùng token init_only; core_done=q+2 cạnh sau OPS launch, q=max(1,n), last chỉ hoàn tất ở accumulator. Top rst_n đồng bộ dùng reset bridge/startup barrier để phối hợp leaf reset_n và nhận A/B/C nguyên tử. Đây là hợp đồng triển khai, chưa nghiệm thu core/bridge/MAC RTL. Chi tiết và trạng thái tại [SPEC §4–§5 và §11](../SPEC_Posit_MAC_IP.md). Bước tiếp theo: packer tuần8, rồi core và tích hợp; chồng lấn sau baseline.

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
| [`lod_lzd_core.sv`](lod_lzd_core.sv) | Bộ dò tìm và đếm số 1 / số 0 đầu chuỗi (LOD/LZD) sử dụng cấu trúc **Cây nhị phân phẳng (Flat Binary Tree)**, tối ưu $O(\log_2 N)$ tầng MUX trên LUT6 FPGA. | `N=32`, `MODE=0/1`, `S=$clog2(N)` | **Hoàn thành (100% Pass)** |
| [`dyn_left_shifter.sv`](dyn_left_shifter.sv) | Bộ dịch trái động logarit đa tầng ($S = \lceil \log_2 N \rceil$ tầng MUX), dịch $2^i$ bằng pure wiring, tích hợp cơ chế bảo vệ chống tràn ($b \ge N \implies \text{out} = 0$). | `N=32`, `SHIFT_W=$clog2(N)` | **Hoàn thành (100% Pass)** |
| [`dyn_right_shifter.sv`](dyn_right_shifter.sv) | Bộ dịch phải động logarit đa tầng, hỗ trợ dịch logic (`ARITH=0`), dịch số học (`ARITH=1`), và điền bit động (`fill_val`), bảo vệ chống tràn ($b \ge N \implies \text{out} = \{N\{fill\}\}$). | `N=32`, `SHIFT_W=$clog2(N)`, `ARITH=0/1` | **Hoàn thành (100% Pass)** |
| [`posit_parser_comb.sv`](posit_parser_comb.sv) | Parser tổ hợp: bù hai → LOD/LZD song song → chọn cnt/Rgm → dịch payload → tách sf/fraction, chặn Zero/NaR. | `NB, ES, FRAC_MAX, SF_W` | ModelSim đạt trong bốn format nghiệm thu; chưa có pipeline |

### B. Các Module Datapath Theo Kiến trúc §5 (Pipeline Architecture)

| Tên Module | Vai trò trong Datapath (§5 SPEC) | Tầng Pipeline & Chu kỳ | Kế hoạch |
|:---|:---|:---:|:---:|
| [`posit_parser.sv`](posit_parser.sv) | Parser elastic hai tầng; dấu/cờ, count và payload cùng stall. Reset có hai FF đồng bộ nhả reset. | Tầng P, hai slot, II=1 khi không stall | Tuần 7; xem nghiệm thu mục5 |
| [`posit_pack.sv`](posit_pack.sv) | Bộ đóng gói và làm tròn RNE FloPoCo (10 bước, có tiền kẹp $sf$) hoặc cắt cụt TRUNC sang Posit bitstring. | TRUNC H=1; RNE H=2: P1 mã hóa/dịch/G-R-S, P2 RNE/carry/dấu (§5.9-D); cần STA | Tuần 8 |
| Context M0 trong `mul_iter_core` (kế hoạch) | Chốt OPS và config nguyên tử tại launch; giữ metadata đến retire. | Một bank M0, không thêm bank OPS trước context | Tuần9, chưa triển khai |
| [`ops_sel_comb.sv`](ops_sel_comb.sv) | OPS normative tổ hợp; cắt fraction trước min-popcount, hòa chọn A, dấu/sf và input_cut. | Chưa có FF; bank M0 là context core theo §5.5-A | Tuần9: kiểm tổ hợp đạt; wrapper tuần tự còn triển khai |
| `sac.sv` | Shift Amount Calculator: đếm số 0 đầu bằng LZD, tính $sa$, tích lũy tổng dịch $S$, và dịch loại bit 1 của $fx$. | Tầng M1..Mn (Lặp $n$) | Tuần 9 |
| [`sac_step_comb.sv`](sac_step_comb.sv) | Một bước fraction: LOD MODE0 đếm zero đầu, sa=clz+1, fx_next/scale_next và exhausted/state_error. | Chưa có FF; controller sở hữu token/count | Tuần9: kiểm tổ hợp đạt; core chưa tích hợp |
| `sbm.sv` | Shift-Based Multiplier: Shifter $1.f_Y \gg S$ và Accumulator tích lũy duy trì bit `sticky_acc`. | Tầng Shifter/Accum | Tuần 9 |
| `mul_norm.sv` | Chuẩn hóa tích ($\text{acc} \ge 2.0$), dịch phải 1 bit và tăng scale factor: $sf = sf + 1$. | Tầng MN (1 chu kỳ) | Tuần 9 |
| `posit_add.sv` | Bộ cộng/trừ 2 số Posit unpacked: A1 (Align kẹp cứng $\le 29$), A2 (Add/Sub), A3 (LZC Normalize). | Tầng A1–A3 (3 chu kỳ) | Tuần 10 |
| `round_unpacked.sv` | Làm tròn trong miền unpacked cho MAC v1 (tiết kiệm 2 chu kỳ đóng gói/giải mã, bit-exact với SoftPosit non-fused). | Tầng R (1 chu kỳ) | Tuần 11 |
| `posit_mac_top.sv` | Module đỉnh tích hợp toàn bộ lõi IP Posit MAC, FSM điều khiển luồng, Operand C FIFO, nhánh bypass và Skid Buffer. | Baseline một giao dịch; H=q+10/TRUNC hoặc q+11/RNE mục tiêu | Tuần 11 |

---

## 3. Quy trình Kiểm tra và Tổng hợp

- **Kiểm tra cú pháp & Linting**:
  ```bash
  verilator --lint-only -Wall -Irtl rtl/<module_name>.sv
  ```
- **Chạy Testbench đơn vị tương ứng**: Xem hướng dẫn chi tiết tại [`tb/README.md`](../tb/README.md).

## 4. Nghiệm thu parser tổ hợp — 05/10/2026

Hợp đồng đầy đủ tại SPEC §5.2: `sf` signed, fraction không hidden bit, giữ toàn bộ `FRAC_MAX` bit. Hai detector nhận `NB-2` bit sau FRB; detector được chọn invalid trả `cnt=NB-2`. Payload rộng `NB-3` bit, loại terminator trước khi lấy exponent. Zero/NaR có sf/frac=0 và dấu lần lượt 0/1. Không có clock, reset hoặc ready/valid ở module này.

ModelSim Altera 10.1d kiểm **2.465.812 đầu vào, 0 mismatch** trên tất cả năm đầu ra. Posit8 ES0: vét cạn 256; posit16 ES1: vét cạn 65.536; posit32 ES2 và ES3: mỗi format 1.200.010 corner/phân tầng. Seed `20261005`; mỗi polarity/run regime hữu hạn có ít nhất 19.672 lượt, mỗi nhóm regime/dấu ít nhất 39.344. Phân tầng ưu tiên bao phủ, không phải phân bố đo Table I. Bộ sinh so L1 với decoder tuần tự trường độc lập trước khi xuất fixture; không link SoftPosit trực tiếp. Các format ngoài bốn cấu hình trên chưa nghiệm thu.

Tái chạy: trong WSL, vào `l1` và chạy `make gen_parser_vectors.exe`; sau đó ở thư mục dự án cha, PowerShell chạy `& ./Posit_MAC/scripts/verify_parser_comb_modelsim.ps1`. Script sinh lại vector, compile/mô phỏng, kiểm marker và tổng số lượt, lưu SHA256. Log, phiên bản compiler/simulator, seed và lệnh ở `results/parser_comb/`. Linux build bằng `make gen_parser_vectors`, chạy `./gen_parser_vectors ../results/parser_comb` khi chưa có mô phỏng đọc fixture.

Vivado 2026.1 `xvlog --sv` đã compile RTL/testbench đạt (`vivado_compile.log`); kiểm chứng runtime ở đây dùng ModelSim. Chưa tổng hợp/STA/PPA và chưa nghiệm thu latency/backpressure; chỉ thêm pipeline sau nghiệm thu tổ hợp.

## 5. Parser pipeline hai tầng

Nghiệm thu 05/10/2026: **2.465.812 fixture, 0 mismatch** trên ModelSim10.1d: posit8 ES0/posit16 ES1 vét cạn và posit32 ES2/ES3 phân tầng. Ngoài stream có các giao dịch directed kiểm reset/stall; ba lần reset mỗi format, gồm hủy một/hai slot. Không mở rộng kết luận sang các format chưa chạy hoặc MAC tích hợp.

`posit_parser.sv` dùng cùng hợp đồng dữ liệu với parser tổ hợp. P1: bù hai → LOD/LZD → mux count → thanh ghi cnt/FRB và payload/metadata. P2: tạo regime từ cnt/FRB song song với dịch payload → tách trường/ghép sf → thanh ghi đầu ra. Hai tầng có enable riêng; `p2_ready = !p2_valid_q || out_ready`, `p1_ready = !p1_valid_q || p2_ready`. Sức chứa là hai giao dịch; khi đầy và đầu ra bị chặn thì `in_ready=0`.

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

Hợp đồng canonical tại SPEC §5.4/§5.5-A/§5.7; lịch thực thi và trạng thái tại PLAN L1 mục7. Profile chính dùng fixed-A/min-popcount và SAC quét bit1; predictor/RND paper có giao diện nghiên cứu riêng. Không dùng `ops_compare_top.sv` khảo sát PPA cũ thay trực tiếp OPS normative.

`ops_sel_comb.sv` nhận fraction parser không hidden; approx cắt xuống FRAC_W trước cây popcount cân bằng. Output x_frac căn phải không hidden, y_mant có hidden ở bit active_width. Tie chọn A, input_cut ghi phần bị bỏ; cfg_error trả bundle0 cho cấu hình bị cấm. Module chỉ nhận trường finite, chưa thực hiện bypass Zero/NaR hoặc M0 register.

`sac_step_comb.sv` trả term_valid, sa, fx_next/scale_next, exhausted/state_error. W_X=1 xử lý riêng; W_X>=2 dùng LOD MODE0 và dyn_left_shifter đã kiểm. Scale cộng mở rộng rồi kiểm <=W_X, không wrap. Controller tương lai sở hữu count/token first/last/init_only; leaf này không có clock/reset.

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

W9-R1 chốt interface `paper_ops_comb`/`paper_step_comb`: Q12/prefix7 đệm0, tie-A, anchor số hạng đầu và payload13+carry1 là giả định tái dựng; RND/complement, coefficient âm và cut trước cộng/trừ ghi riêng. W9-R2 đạt843 commit,293 bản ghi (292 bản ghi corpus/206 trường hợp phân biệt + một fixture Fig.4),0 mismatch. Output force-X=0x1ae34000. Không có bằng chứng mới để chạy R3 hoặc xác nhận RTL tác giả.

W9-04 đạt39.580 giao dịch hoàn tất và420 lượt reset hủy; width1/5/12/26/27, exact vượt N_MAX, n=0/early-stop, done=t+2 hoặc3, drain và context cố định đều được kiểm. W9-05 tích hợp parser A/B → M0/core → norm → packer với một slot dự trữ; pilot bản cuối31.840 giao dịch +160 reset hủy,0 mismatch. Reset bridge lấy mẫu rst_n; out_valid bị chặn tại cạnh reset, mỗi leaf nhả qua hai FF. RNE: L_valid=max(1,t)+7, TRUNC:max(1,t)+6; handshake khi không stall sau đó một cạnh. Thử config reserved/n>N_MAX, NaR/zero, stall dài, cạnh reset và giữ thứ tự.

Kiểm 10⁷ RTL đang chạy; chưa có kết quả nghiệm thu lượt lớn.

Corpus lớn10.080.000 dòng,16 profile,36 ô mode/ops/n mỗi profile; generator exact/RNE so SoftPosit1.890.000 lượt và oracle ES3 độc lập630.000 lượt. Generator/fixture không thay nghiệm thu RTL. Verilator chưa có; `make lint` hiện trả lỗi khi thiếu công cụ thay vì skip rồi báo thành công. Harness C++ và `scripts/verify_week9_verilator.sh` đã chuẩn bị nhưng chưa build/chạy, cần đối chuẩn pilot khi có công cụ. Không tự cài công cụ ngoài quyền đã cấp.

Quartus13 phân tích/tổng hợp NB32/ES2/FLOOR/RNE đạt0 lỗi,14 warning đã phân loại (license parallel, attribute ASYNC_REG của Xilinx và constant resize có giới hạn); không có cảnh báo latch. Đây không thay strict lint, STA, CDC, PPA hay Gate4. Chỉ đổi generate/genvar để hỗ trợ compiler cũ trong hai shifter/OPS, không đổi phương trình; đã chạy lại327.440 frontend vector và843 paper commit đạt.

Bằng chứng, compiler, seed20261009, SoftPosit library hash, lệnh và SHA256: `results/week9_implementation/summary.json`; các log ở `results/week9_arithmetic`, `week9_paper`, `week9_core`, `week9_multiplier`. Gate2/tuần9 vẫn processing do lint chính thức còn thiếu; tuần4/provenance paper giữ processing. Git push bị chặn vì thư mục không phải Git checkout; không tự init/force/reset hoặc sửa thư mục khác.

`posit_mul_iter` là top chỉ ghép instance. `mul_iter_wrapper` chốt cfg ở handshake E0, nhận cặp parser nguyên tử, giữ slot đến retire. `mul_iter_core` chốt context ở launch L0, `iter_ctrl` phát L1, bank term L2, `sbm_accum` commit L3. `mul_norm_comb` đồng thời thực hiện adapter không làm tròn; wrapper có một bank norm trước packer. Ports top:clk/rst_n/in_valid/in_ready/a/b/cfg_mode/cfg_n/cfg_ops/out_valid/out_ready/d/flags. ROUND_SCHEME và ROUND_MODE là tham số compile; cfg_mode/cfg_n/cfg_ops được chốt mỗi giao dịch. Baseline test EXACT_EN=OPS_EN=1; disable policy đã kiểm ở OPS đơn vị, không tuyên bố coverage full top mọi tham số tùy biến.
