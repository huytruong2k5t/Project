# Thư mục Môi trường Kiểm chứng (`tb/`)

Thư mục này chứa toàn bộ hệ thống testbench phục vụ xác minh tính đúng đắn của lõi IP Posit MAC từ mức module đơn vị (Unit TB) đến mức tích hợp toàn hệ thống (System TB) theo 3 tầng đối chiếu (§6 SPEC).

---

## 1. Cấu trúc Thư mục Kiểm chứng

```text
tb/
├── tb_lod_lzd_core.sv        # Testbench đơn vị tự kiểm tra cho LOD/LZD
├── tb_dyn_left_shifter.sv    # Testbench đơn vị tự kiểm tra cho Dynamic Left Shifter
├── tb_dyn_right_shifter.sv   # Testbench đơn vị tự kiểm tra cho Dynamic Right Shifter
├── verilator/                # Đường A: C++ Harness hiệu năng cao (10^7 - 10^9 vector)
│   └── README.md
└── uvm_lite/                 # Đường B: Môi trường SystemVerilog Class-based / DPI-C
    └── README.md
```

---

## 2. Các Testbench Đơn vị Đã Hiện thực (Self-checking Unit Testbenches)

Tất cả các testbench đơn vị đều tích hợp mô hình vàng (Golden Reference Model), tự động so sánh từng chu kỳ và báo cáo số lượng vector đạt được (`0 mismatches`):

### 1. [`tb_lod_lzd_core.sv`](tb_lod_lzd_core.sv)
- **Đối tượng**: Kiểm tra module [`lod_lzd_core.sv`](../rtl/lod_lzd_core.sv).
- **Phạm vi kiểm tra**:
  - Quét cạn (Exhaustive) 256 vector trên $N=8$ cho cả 2 chế độ LOD (`MODE=0`) và LZD (`MODE=1`).
  - N=31: 10.000 vector ngẫu nhiên, 2 ca toàn 0/1, 62 walking-one/zero và 62 ca phân tầng theo vị trí bit đầu; tổng 10.126 vector.
  - N=32: 10.000 vector ngẫu nhiên, 2 ca toàn 0/1, 64 walking-one/zero và 64 ca phân tầng; tổng 10.130 vector.
  - PRNG xorshift32 có seed cố định `0x31c0ffee`/`0x32c0ffee`, tái lập độc lập seed ngẫu nhiên của simulator.
  - Đối chiếu cả `vld` và `K`, kể cả `K=0` khi không tìm được bit; kiểm tra mọi vị trí đầu ra và ca invalid của cả hai MODE. Sai lệch hoặc timeout kết thúc bằng `$fatal(1)`.
  - Tổng: **20.512 vector / 41.024 phép đối chiếu MODE**. Đây là phạm vi test, chưa phải kết quả PASS nếu chưa chạy mô phỏng.

Chạy từ thư mục `Posit_MAC` với Icarus Verilog đã cài:

```bash
iverilog -g2012 -s tb_lod_lzd_core -o results/tb_lod_lzd_core.vvp rtl/lod_lzd_core.sv tb/tb_lod_lzd_core.sv
vvp results/tb_lod_lzd_core.vvp > results/lod_lzd.log
```

Kết quả thành công phải có dòng `LOD/LZD PASSED: 20512 vectors, 41024 checks, 0 mismatches`.

**Kết quả 03/10/2026:** chạy RTL bằng ModelSim Altera 10.1d trên Windows đạt 20.512 vector / 41.024 đối chiếu, 0 mismatch; mọi vị trí đầu ra và ca invalid đều được phủ cho cả hai MODE, cả ba độ rộng. Log: [compile.log](../results/modelsim_lod_lzd/compile.log), [simulation.log](../results/modelsim_lod_lzd/simulation.log).

Chạy bằng ModelSim trong PowerShell từ thư mục gốc đồ án (các công cụ đã nằm trong PATH):

```powershell
New-Item -ItemType Directory -Force Posit_MAC/results/modelsim_lod_lzd | Out-Null
vlib Posit_MAC/results/modelsim_lod_lzd/work
vlog -sv -work Posit_MAC/results/modelsim_lod_lzd/work -l Posit_MAC/results/modelsim_lod_lzd/compile.log Posit_MAC/rtl/lod_lzd_core.sv Posit_MAC/tb/tb_lod_lzd_core.sv
vsim -c -onfinish exit -lib Posit_MAC/results/modelsim_lod_lzd/work -l Posit_MAC/results/modelsim_lod_lzd/simulation.log tb_lod_lzd_core -do 'run -all; quit -code 1'
```

Kiểm tra log có dòng tổng kết PASS và không có `FAIL`, `$fatal` hoặc lỗi simulator trước khi ghi nhận kiểm chứng đạt.
  - Kiểm tra trường hợp đặc biệt: toàn số 0, toàn số 1, walking 1s, walking 0s.
  - Kiểm tra tính hợp lệ của cờ `vld`.

### 2. [`tb_dyn_left_shifter.sv`](tb_dyn_left_shifter.sv)
- **Đối tượng**: Kiểm tra module [`dyn_left_shifter.sv`](../rtl/dyn_left_shifter.sv).
- **Phạm vi kiểm tra** (60,832 vectors, 100% Pass):
  - **Suite 1**: Quét cạn 4,096 tổ hợp trên $N=8, \text{SHIFT\_W}=4$.
  - **Suite 2**: Kiểm tra biên $N=32, \text{SHIFT\_W}=6$ qua toàn bộ 64 bước dịch ($0 \dots 63$), bao gồm NaR, maxpos, minpos.
  - **Suite 3**: Kiểm tra cấu hình $N=27$ (độ rộng fraction của Posit32 mantissa).
  - **Suite 4**: 10,000 vector ngẫu nhiên kiểm tra chịu tải và chống tràn ($b \ge N$).

### 3. [`tb_dyn_right_shifter.sv`](tb_dyn_right_shifter.sv)
- **Đối tượng**: Kiểm tra module [`dyn_right_shifter.sv`](../rtl/dyn_right_shifter.sv).
- **Phạm vi kiểm tra** (146,400 vectors, 100% Pass):
  - **Suite 1**: Quét cạn 12,288 tổ hợp trên $N=8$ trên cả 3 chế độ: Dịch logic, Dịch số học, và Điền bit động (`fill_val=1`).
  - **Suite 2**: Kiểm tra biên $N=32$ với các số âm có dấu (bảo toàn sign extension) và số dương qua các bước dịch $0 \dots 63$.
  - **Suite 3**: Kiểm tra cấu hình không lũy thừa của 2 ($N=27$).
  - **Suite 4**: 20,000 vector ngẫu nhiên kiểm tra cơ chế kẹp tràn ($b \ge N \implies \text{out} = \{N\{fill\}\}$).

---

## 3. Hai Đường Chạy Kiểm chứng Toàn hệ thống (§6.5 SPEC)

Parser tổ hợp tuần7 dùng [`tb_posit_parser_comb.sv`](tb_posit_parser_comb.sv): bốn checker đọc fixture do `l1/test/gen_parser_vectors.cpp` sinh sau khi đối chiếu L1/decoder độc lập. Nghiệm thu 05/10/2026: posit8 ES0 và posit16 ES1 vét cạn; posit32 ES2/ES3 phân tầng/corner; tổng 2.465.812 đầu vào, 0 mismatch. Chạy `scripts/verify_parser_comb_modelsim.ps1` sau khi build `l1/gen_parser_vectors.exe`. Script từ chối thiếu fixture, thiếu dòng, sai trường hoặc thiếu marker PASS. Xem hợp đồng và hướng dẫn trong `rtl/README.md`; chưa kiểm pipeline.

Parser pipeline dùng [`tb_posit_parser.sv`](tb_posit_parser.sv) và [`parser_pipeline_checker.sv`](parser_pipeline_checker.sv), mỗi file một module. Scoreboard lấy mẫu handshake trước NBA rồi kiểm đầu ra sau CK2Q; không đọc kết quả mới ở cùng cạnh để nhầm latency. Stream dùng lại toàn bộ fixture nghiệm thu tổ hợp, random handshake bằng xorshift32 seed `20261005+NB*17+ES`. Kiểm reset assert giữa cạnh clock, startup hai cạnh, flush một/hai slot, stall dài, nguồn giữ dữ liệu khi bị chặn, bubble, II=1 và thứ tự/không mất/không nhân đôi giao dịch. Dùng kiểm tra procedural với `$fatal` để tương thích ModelSim 10.1d. Lệnh chạy và số liệu ở `rtl/README.md` mục5 và `results/parser_pipeline/`.

- **[Đường A (Verilator + C++ Harness)](verilator/README.md)**: Chạy hàng triệu đến hàng trăm triệu vector phân tầng để nghiệm thu tiêu chí **AC-01** (RTL = L1) và **AC-02** (Exact = SoftPosit).
- **[Đường B (UVM-Lite / SystemVerilog Classes)](uvm_lite/README.md)**: Chạy kích thích ngẫu nhiên có ràng buộc (constrained random), thu thập Functional Coverage các bin regime, và kiểm tra các khẳng định SVA (`A-01` đến `A-09`).

## 4. Packer và chuỗi parser→packer tuần8

[`tb_posit_pack.sv`](tb_posit_pack.sv) dùng [`packer_checker.sv`](packer_checker.sv) để đối chiếu packer tổ hợp và pipeline với fixture độc lập cho posit8/ES0, posit16/ES1, posit32/ES2 và posit32/ES3, cả RNE/TRUNC. Kiểm biên regime, tie/carry, G/R/S, số âm, Zero/NaR, cờ trạng thái, latency, II=1, reset/flush và stall.

[`tb_parser_packer.sv`](tb_parser_packer.sv) dùng [`parser_packer_checker.sv`](parser_packer_checker.sv) kiểm chuỗi RTL thật với scoreboard theo handshake, backpressure và reset. Nghiệm thu 07/10/2026: 5.947.048 lượt packer và 4.931.624 lượt chuỗi, 0 mismatch. Lệnh chạy và hash lưu trong `scripts/verify_packer_modelsim.ps1` và `results/packer/`; phạm vi này chưa bao gồm RTL MAC tích hợp.

[`tb_packer_ppa.sv`](tb_packer_ppa.sv) kiểm riêng biên thanh ghi của benchmark PPA so với packer tổ hợp đã nghiệm thu; 3.994 lượt đạt. Test này không thay thế oracle số học độc lập của hai suite trên.

Tối ưu P2 một bộ cộng có test riêng [`tb_packer_finish_equivalence.sv`](tb_packer_finish_equivalence.sv) và [`packer_finish_equivalence_checker.sv`](packer_finish_equivalence_checker.sv): NB8 vét cạn cả selector không hợp lệ và flags, NB16/32 ngẫu nhiên, so trực tiếp bản trước cho cả RNE/TRUNC. Tổng 1.448.576 lượt đạt; chạy `scripts/verify_packer_p2_equivalence.ps1`.

## 5. OPS/SAC tổ hợp tuần9

[`tb_week9_frontend.sv`](tb_week9_frontend.sv) ghép năm [`ops_frontend_checker.sv`](ops_frontend_checker.sv) và năm [`sac_frontend_checker.sv`](sac_frontend_checker.sv), width1/5/12/26/27. OPS kiểm instance EXACT_EN/OPS_EN bật và tắt, cấu hình reserved, tie, input cut, dấu và sf. SAC kiểm fx rỗng, sa cuối width, exhausted và state_error khi scale vượt width.

ModelSim159.820 vector OPS +167.620 SAC,0 mismatch. Fixture do L1 và oracle đếm/quét bit độc lập tạo, seed20261008; cross-platform/UBSan đã kiểm. Chạy `scripts/verify_week9_frontend_modelsim.ps1`, sau đó `scripts/summarize_week9_frontend.py`. Scope chỉ là tổ hợp; chưa kiểm FF/reset/drain/handshake của multiplier. Kế hoạch ở PLAN L1 mục7, hợp đồng SPEC §5.5-A.

## 6. Kiểm chứng multiplier tuần9 — 09/10/2026

Các suite mới: `tb_week9_arithmetic` (term/acc/norm/adapter), `tb_week9_paper` (score/commit/pack paper), `tb_week9_core` (latency/reset/context/drain) và `tb_week9_multiplier` (baseline top,16 profile, cả d và flags).

ModelSim chạy fixture trong thư mục kết quả riêng; scripts fail khi thiếu vector/marker hoặc gặp Fatal/Error. Vector bị reset hủy được đếm riêng, không tính vào ngưỡng10⁷ so RTL=L1. Lượt pilot bản cuối31.840 so sánh và160 reset,0 mismatch. Competing input được giữ trong lúc busy; output bị stall; reset quay qua parser/core/drain/output. Nguồn phải đặt config hợp lệ trước chờ in_ready vì wrapper từ chối reserved/n>N_MAX.

Harness `week9_multiplier_harness.cpp` và script Verilator đã chuẩn bị, chưa có bằng chứng build/chạy do công cụ thiếu. Verilator --no-timing bỏ CK2Q cho kiểm chức năng theo cạnh; ModelSim là bằng chứng có CK2Q. Cần đối chuẩn pilot hai engine trước nhận lượt lớn Verilator. Bằng chứng hiện tại ở `results/week9_implementation/summary.json`.

ModelSim đối chiếu 16.815.920 giao dịch, hủy 80.080 giao dịch bằng reset,0 mismatch.

Lượt phân tầng cuối đạt16.815.920 giao dịch hoàn tất,80.080 reset hủy; control random-bit đạt10.032.224 giao dịch,47.776 reset hủy; cả hai0 mismatch. Audit đối chiếu SHA fixture với log PASS và loại reset-abort trước coverage:16 profile đầy đủ, posit32 đạt256/256 bin regime–dấu, tối thiểu4.104 mẫu/bin và26.241 operands mỗi run/polarity hữu hạn;36 ô mode/OPS/n mỗi profile. Code coverage line/branch/toggle chưa đo.

Corner riêng đạt114.656 so sánh/544 reset hủy,3600 trường hợp khác nhau mỗi profile (100 cặp ×36 config), gồm ±1, ±minpos/maxpos và NaR×0/0×NaR; Linux/Windows/UBSan và replay32.000 dòng uniform cũ khớp. Pilot stall96 chu kỳ đạt31.840 so sánh/160 reset,336 lượt giữ dài;0 mismatch. Chỉ chỉnh khoảng trắng RTL để tách port/parameter, có proof và pilot biên dịch lại; SHA nguồn trước/sau lưu riêng. Logic không đổi, TableI không chạy lại.

Gate2/W9-06 vẫn processing: Verilator chưa có, harness C++ và lint chính thức chưa build/chạy. Không tự cài công cụ hoặc thay tiêu chí. Bằng chứng: results/week9_multiplier/{stratified_acceptance,acceptance_parallel,corners_final_rtl,long_stall_pilot}; snapshot/version/seed/lệnh tại results/week9_implementation/summary.json.

## 7. Kiểm top paper tự hồi tiếp — 09/10/2026

`paper_mul_iter`/`paper_mul_wrapper`/`paper_norm_comb` đã tự chạy từ A/B đến kết quả; ModelSim17.181 giao dịch và65.710 commit đạt0 mismatch,843 commit corpus cũ giữ nguyên, Fig.4=0x1ae34000. Linux/Windows/UBSan fixture MATCH; reset/stall/context/early-stop/special đạt trong suite. Hợp đồng research cố định posit32ES3/Q12, n_terms1..8, outputTRUNC; chi tiết PLAN L1 §7.5 và results/paper_top/{windows/summary,audit}.json. Không có nguồn mới hoặc thay đổi số học nên không chạy TableI; provenance baseline gốc và Gate2 vẫn processing.

Bench `tb_paper_mul_iter.sv` chỉ điều khiển cổng công khai A/B/n_terms/force_a/reset/valid/ready, đọc trace thụ động; không nạp state DUT từ fixture. Latency được kiểm E(t+1), t là số commit thực tế. Có4 reset hủy không tính vào17.181 completed,178 output hold96cycles và kiểm cả8 encoding n_terms không hợp lệ.

## 8. Kiểm packer Fig5 độc lập — 09/10/2026

Audit trực tiếp nguồn2019/2021 và kiểm deterministic163.840 cặp cho thấy RND/complement và quét bit1 không tương đương. Fig4 khớp n_fraction2/n_total3 (0x1ae34000), nhưng n_total2 cho0x1ad14000; TableI Proposed chưa khóa cách đếm/recurrence từ nguồn. Giữ nguyên profile normative và top RND nghiên cứu, không đổi n/seed để ép bảng.

Reference cổng Fig5 độc lập khớp L1 trên3.940.352 trường hợp; ModelSim155.648 trường hợp đạt0 mismatch, Linux/Windows/UBSan MATCH.8.448 raw/clamped differences nằm ngoài miền sf−240..240, do range handling đồ án bổ sung; không phải lỗi RTL hoặc xác nhận clamp tác giả. Không chạy pilotTableI, baseline gốc/Gate2 vẫn processing. Chi tiết duy nhất tại README L1 §24; bằng chứng/lệnh/hash/compiler tại results/paper_contract_audit/{summary.json,windows/summary.json}.
