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
| `posit_pack.sv` | Bộ đóng gói và làm tròn RNE FloPoCo (10 bước, có tiền kẹp $sf$) hoặc cắt cụt TRUNC sang Posit bitstring. | TRUNC H=1 / RNE H=2 mục tiêu, cần STA | Tuần 8 |
| `ops_sel.sv` | Bộ chọn toán hạng $X$ (điều khiển lặp) và $Y$ (bị dịch), tính tổng scale factor gộp $sf = sf_A + sf_B$. | Tầng M0 (1 chu kỳ) | Tuần 9 |
| `sac.sv` | Shift Amount Calculator: đếm số 0 đầu bằng LZD, tính $sa$, tích lũy tổng dịch $S$, và dịch loại bit 1 của $fx$. | Tầng M1..Mn (Lặp $n$) | Tuần 9 |
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
