# Hồ sơ Bằng chứng Thực nghiệm & Kiểm chứng — Posit(32,3) MAC IP (0-DSP)

Tài liệu phụ lục tổng hợp đầy đủ bằng chứng RTL, mô phỏng kiểm chứng, bài toán ứng dụng và triển khai FPGA dùng trong quyển báo cáo hội đồng 87 trang (biên dịch từ `doc/Posit_MAC_LaTeX/council.tex`).

## 1. Chỉ mục tệp kết quả gốc & mã toàn vẹn SHA-256

| Hạng mục / Tệp gốc | Kích thước | Mã SHA-256 | Vai trò |
|---|---:|---|---|
| `Báo cáo hội đồng PDF (87 trang, biên dịch từ doc/Posit_MAC_LaTeX/council.tex)` | 615.967 B | `b4c6557a621acd814096e1c1af45e6ad4d2cb8cf6be413385ef3ebcab0f3c7d9` | Bản PDF báo cáo cuối cùng trình hội đồng |
| `Posit_MAC/rtl/mac_f/mac_f_wrapper.sv` | 9.454 B | `ed79d79b852d48e7835c3ba8ab6a733467baf6992e3b731d96000d602df3e9fe` | Top RTL lõi hợp nhất MAC-F |
| `Posit_MAC/rtl/mac_nf/mac_nf_wrapper.sv` | 11.897 B | `c2c66280cb3fdf14bb67dc3b460bbd3c259c46858e89bcea5639a4faadc67d56` | Top RTL lõi đối chứng không hợp nhất MAC-NF |
| `Posit_MAC/rtl/mac_quire/mac_quire_wrapper.sv` | 11.100 B | `edd43defc1caee6330b5327787b3bf6743c534cabad43598f76add37925e567f` | Top RTL lõi tích lũy Quire 972 bit theo từ 36 bit |
| `Posit_MAC/rtl/adder/posit_add_prepare_comb.sv` | 3.488 B | `0058b56a50c90916925a84d74d81602c2233e49127a3efaf02a77bb722345ecd` | Khối S1 tối ưu tách fanout 4 nhánh choose_a (bit-exact) |
| `Posit_MAC/results/nf_f_coverage_final/coverage_summary.json` | 2.416 B | `744a680d88b2ca3c61a5558feb9ce5df875acd3c051f28e08e8036d2ae9f5e51` | Tổng hợp độ phủ dòng/nhánh/bit trên RTL cuối cùng |
| `Posit_MAC/results/app_benchmarks/summary.json` | 4.397 B | `895cedb26adaa3e4cc94d9561572a4db13668e10d039e22b305a987c936aa75b` | Kết quả ứng dụng FIR 32 tap & Dot Product 128D |
| `Posit_MAC/results/fpga_power_and_fp32/run_xilinx_fp32.tcl` | 7.789 B | `08e65455cd6cbb59bbc87d6b329dbe40ecb4e1dae88c26c0dc08020fbe29ea2c` | Kịch bản Vivado sinh & route 3 IP Xilinx FP32 OOC |
| `Posit_MAC/results/fpga_power_and_fp32/mac_f_power.rpt` | 8.355 B | `d3c8ab37987c8efd64daec4f2fec7d3709cf94c10e3990636b586354d664d9ec` | Báo cáo Vivado report_power cho MAC-F (100 MHz) |
| `Posit_MAC/results/fpga_power_and_fp32/fp32_nf_nodsp_power.rpt` | 8.758 B | `c88a21d23698cc5ca4d08881d284dc7c926fc47dde2b884b4d4a90dc8112d44c` | Báo cáo Vivado report_power cho IP Xilinx FP32 0-DSP |
| `Posit_MAC/rtl/common/lod_lzd_core_fixed4.sv` | --- | `6bd4838facfa08b0beedc910c2c2b9711c1544bd105ad00916c1c163d54b3ece` | Bộ dò bit 1 đầu tiên 12 bit (đệm 16 bit) cho SAC |
| `Posit_MAC/rtl/parser/posit_parser_f_regime_lod.sv` | --- | `c936f7dd2c6e24f5744df75c65c7d6fbd8e93fafe9b21b5d0cb452926f741475` | Bộ dò regime 31 bit (đệm 64 bit, 3 cấp gộp) |
| `Posit_MAC/rtl/common/lod_lzd_core_fixed2.sv` | --- | `5e062a4cd49601c808655e78d327627a38b276128df132492c9905e5cd409f6c` | Bộ dò LOD ưu tiên 31 bit cho chuẩn hóa bộ cộng |

## 2. Đối chiếu 14 sơ đồ Datapath Chương 3 với RTL (`.sv`)

| Hình | Tệp TikZ | Mô-đun RTL | Đặc điểm kỹ thuật |
|---|---|---|---|
| 3.1 MAC-F tổng thể | `mac.tex` | `rtl/mac_f/mac_f_wrapper.sv, rtl/multiplier/mul_prepack_norm_comb.sv` | 3 Parser song song, context C, ghép thẳng S1 bỏ qua Packer tích |
| 3.2 Context | `context.tex` | `rtl/mac_f/mac_f_wrapper.sv` | Chốt cfg_ops/cfg_n tại accept, pair_retire, giải phóng retire |
| 3.3 Parser | `parser.tex` | `rtl/parser/posit_parser_mul.sv` | 2 tầng P1/P2: giải mã regime/exp, ghép scale và tách fraction |
| 3.4 Dò regime | `regime_lod.tex` | `rtl/parser/posit_parser_f_regime_lod.sv` | XOR kề có sentinel, đệm 31->64 bit, 3 cấp gộp ưu tiên MSB |
| 3.5 Bộ dò LOD | `other_lod.tex` | `rtl/common/lod_lzd_core_fixed4.sv, lod_lzd_core_fixed2.sv` | SAC12 (đệm 16) và LOD 31 bit; đã test 4.096 + 560 mẫu 0 lỗi |
| 3.6 Bộ nhân lặp | `mul.tex` | `rtl/multiplier/{ops_sel,sac_step,sbm_shift,sbm_accum}_comb.sv, mul_iter_core.sv` | OPS/SAC/SBM, dừng sớm theo n và popcount(X_mant), Q24 |
| 3.7 Adder 5 tầng | `adder.tex` | `rtl/adder/posit_add.sv + 5 khối *_comb.sv` | Đường ống cộng Posit 5 tầng thanh ghi S1--S5 |
| 3.8 Tầng S1 Prepare | `adder_s1.tex` | `rtl/adder/posit_add_prepare_comb.sv` | 2 bộ trừ scale 12 bit, kẹp |Δsf|>28, 4 nhánh choose_a tách tải |
| 3.9 Tầng S2 Align | `adder_s2.tex` | `rtl/adder/posit_add_align_comb.sv` | Dịch phải 31 bit, mặt nạ nhiệt 25 bit, gộp jam/tail |
| 3.10 Tầng S3 & S4 | `adder_tail.tex` | `rtl/adder/posit_add_arith_comb.sv, posit_add_lod_comb.sv` | Cộng/trừ 31 bit, tiền tăng scale, dò LOD 31 bit, lost_carry |
| 3.11 Tầng S5 Norm | `adder_s5.tex` | `rtl/adder/posit_add_norm_comb.sv` | Dịch trái 30 bit, cập nhật sf_inc - K, phân loại Zero/NaR |
| 3.12 Packer | `packer.tex` | `rtl/packer/{posit_pack,posit_pack_prepare,posit_pack_finish}.sv` | Payload 59 bit, offset, G/R/S, RNE 1 phép cộng và mã bù 2 |
| 3.13 Biên tích NF/F | `nf.tex` | `rtl/mac_nf/{mac_nf_wrapper,posit_magnitude_parse,posit_product_pack}.sv` | Ranh giới P1/P2 của tích trung gian trên NF vs truyền thẳng trên F |
| 3.14 Quire | `quire.tex` | `rtl/mac_quire/{mac_quire_wrapper,quire_align_comb,quire_bank,quire_read}.sv` | Lưới 972 bit chia 27 từ 36 bit, CLEAR (3 cyc) và READ (59 cyc) |

## 3. Tổng hợp Công cụ, Kiểm chứng Chức năng & Độ phủ Verilator 5.032

| Biến thể lõi | Tx đo phủ / Đóng bin | v_line (Thô -> Rà soát) | v_branch (Thô -> Rà soát) | v_toggle | Functional bins |
|---|---|---|---|---|---|
| **MAC-NF** | 130.000 / 2.600.000 | 91,98% (149/162) -> 98,03% (149/152) | 88,37% (76/86) -> 100,00% (76/76) | 93,63% (5.750/6.141) | 510/517 -> 517/517 (missing=[]) |
| **MAC-F** | 130.000 / 2.600.000 | 90,91% (130/143) -> 96,30% (130/135) | 88,89% (64/72) -> 100,00% (64/64) | 93,03% (5.074/5.454) | 509/516 -> 516/516 (missing=[]) |

### Chi tiết giải trình Waiver & Unhit trên RTL cuối cùng (`results/nf_f_coverage_final/`)

| Tệp RTL | Dòng | Loại | Mã nguồn | Lý do (NF / F) |
|---|---|---|---|---|
| `rtl/adder/posit_add.sv` | 264, 282, 298, 312, 328 | v_branch (Waived) | `if (ready0) .. if (ready4)` | 5 / 5 điểm: Nhánh else kẹt ngược nội bộ không phát sinh ở cấu hình single-outstanding. |
| `rtl/parser/posit_parser_mul.sv` | 155, 204 | v_branch (Waived) | `end else if (p1_ready / p2_ready)` | 2 / 2 điểm: Ngõ ra Parser luôn thông suốt khi wrapper chỉ giữ một giao dịch. |
| `rtl/packer/posit_pack.sv` | 131 | v_branch (Waived) | `end else if (p1_ready)` | 1 / 1 điểm: Tầng đệm đầu Packer không bị kẹt ngược trong single-outstanding. |
| `rtl/mac_nf/posit_product_pack.sv` | 133, 153 | v_branch (Waived) | `end else if (p1_ready / p2_ready)` | 2 / 0 điểm: Chỉ tồn tại trên tầng đóng gói tích trung gian của lõi MAC-NF. |
| `rtl/mac_nf/mac_nf_wrapper.sv` | 382 | v_line (Unhit) | `end else if (meta_sync2) begin` | 1 / 0 điểm: Pop FIFO không kèm push đồng thời khi giữ đệm ngoài. |
| `rtl/mac_f/mac_f_wrapper.sv` | 309 | v_line (Unhit) | `end else if (meta_sync2) begin` | 0 / 1 điểm: Nhánh điều khiển FIFO tương ứng trên lõi MAC-F. |
| `rtl/packer/posit_pack_finish.sv` | 72, 76 | v_line (Unhit) | `if (magnitude_max) ... / default:` | 2 / 2 điểm: Bảo vệ biên bão hòa cực đại và nhánh default phòng thủ. |
| `rtl/common/lod_lzd_core_fixed2.sv` | 53, 54 | v_line (Unhit) | `31'b...1?: K=5'd29 / ...1: K=5'd30` | 0 / 2 điểm: Hai mức dịch cực đại K=29, 30 trong LOD 31 bit của MAC-F. |

## 4. Bài toán Ứng dụng Thực tế (`results/app_benchmarks/summary.json`)

| Cấu hình lõi | FIR SNR (dB) | FIR RMSE | T.gian/mẫu (µs) | NN P95 | DynScale P95 (Lỗi) | Cancel P95 (Lỗi) |
|---|---:|---:|---:|---:|---|---|
| **IEEE-754 FP32** | 138,9 | 6,00e-8 | --- | 1,32e-6 (0 lỗi) | 100% (200/200 lỗi) | NaN (200/200 lỗi) |
| **MAC-F (n=12)** | 72,5 | 1,25e-4 | 3,74 (577,0 cyc @ 154,4 MHz) | 5,66e-4 (0 lỗi) | 8,69e-3 (0 lỗi) | Mất phần dư (0 Inf/NaN) |
| **MAC-F (n=8)** | 72,4 | 1,28e-4 | 3,74 (576,9 cyc @ 154,4 MHz) | 5,58e-4 (0 lỗi) | --- | --- |
| **MAC-NF (n=12)** | 72,5 | 1,25e-4 | 4,95 (673,0 cyc @ 135,9 MHz) | 5,66e-4 (0 lỗi) | 8,27e-3 (0 lỗi) | Mất phần dư (0 Inf/NaN) |
| **MAC-Quire (n=12)** | 72,5 | 1,25e-4 | 14,0 (1.375,0 cyc @ 98,2 MHz) | 5,66e-4 (0 lỗi) | 1,14e-3 (0 lỗi) | 7,73e-4 (0 lỗi) |

## 5. Triển khai FPGA (`xc7a35tcpg236-1`), Thông lượng, Công suất & Đối chiếu Xilinx FP32

| Kiến trúc lõi | LUT | FF | DSP | WNS R2R (ns) | Fmax (MHz) | Chu kỳ (II/Lat) | Thông lượng (M MAC/s) | P_dyn / P_tot (mW) | E_dyn/MAC (nJ) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **MAC-F (tách S1, Route)** | 1.221 | 781 | 0 | +3,524 | 154,42 (154) | 14--26 (18,0) | 5,94--11,0 (8,56) | 4 / 72 | 0,721 |
| **MAC-NF (tách S1, Route)** | 1.591 | 916 | 0 | +2,639 | 135,85 (136) | 17--29 (21,0) | 4,68--7,99 (6,46) | 12 / 80 | 2,52 |
| **MAC-Quire (Route)** | 2.873 | 2.636 | 0 | -0,187 | 98,16 (98,2) | 37--49 (41,0) | 2,00--2,65 (2,39) | 29 / 98 | 11,9 |
| **Xilinx FP32 FMA Full** | 765 | 1.318 | 4 | +4,440 | 179,86 (180) | 1 / 20 | 180 (9,00*) | 25 / 94 | 0,250 |
| **Xilinx FP32 FMA Med** | 777 | 1.285 | 2 | +4,761 | 190,88 (191) | 1 / 17 | 191 (11,2*) | 21 / 89 | 0,210 |
| **Xilinx FP32 0-DSP (Mul+Add)** | 993 | 1.520 | 0 | +4,879 | 195,27 (195) | 1 / 22 | 195 (8,88*) | 22 / 91 | 0,220 |

## 6. Đối chiếu công trình quốc tế

| Thiết kế / Công trình | Phép toán / Chuẩn | Nền tảng | LUT | FF | DSP | Đặc điểm đối chiếu |
|---|---|---|---:|---:|---:|---|
| Đồ án: MAC-F | Fused MAC Posit(32,3) | Artix-7 A35T | 1.221 | 781 | 0 | 154 MHz; 14--26 cyc; P_dyn=4 mW; dải 2^(±240) |
| Đồ án: MAC-NF | Non-fused Posit(32,3) | Artix-7 A35T | 1.591 | 916 | 0 | 136 MHz; 17--29 cyc; P_dyn=12 mW |
| Đồ án: MAC-Quire | Quire MAC Posit(32,3) | Artix-7 A35T | 2.873 | 2.636 | 0 | 98,2 MHz; lưới 972 bit từ 36 bit; P_dyn=29 mW |
| Xilinx FP32 0-DSP | Mul+Add FP32 | Artix-7 A35T | 993 | 1.520 | 0 | 195 MHz; II=1, Lat=22; P_dyn=22 mW |
| Jaiswal & So (PACoGen, 2019) | Mul / Add Posit(32,6) | Virtex-7 | 854 / 946 | --- | 1 / 0 | 227 / 244 MHz; tách rời Mul (4 cyc) và Add (5 cyc) |
| Murillo et al. (FloPoCo, 2021) | Mul Posit(32,x) | FPGA 7-series | 572--682 | --- | 4 | Nhân chính xác (mốc tham chiếu của PLAM 0-DSP) |
| Mallasén et al. (PERCIVAL, 2022) | PAU+Quire Posit(32,2) | Kintex-7 325T | 11.879 | 2.985 | 4 | Đơn vị RISC-V đầy đủ (FPU 32 bit đối chứng: 4.046 LUT, 2 DSP) |

## 7. Tập lệnh Tái lập Thực nghiệm

```bash
# Vivado v.2026.1: OOC FP32 vs Posit MAC + report_power
vivado -mode batch -source results/fpga_power_and_fp32/run_xilinx_fp32.tcl
vivado -mode batch -source syn/route_mac_100mhz.tcl
vivado -mode batch -source syn/quire_ooc.tcl

# Verilator 5.032: 2.6M functional closure & structural coverage
python scripts/verify_nf_f_coverage.py --summary-out results/nf_f_coverage_final/coverage_summary.json
python scripts/report_nf_f_coverage.py
```
