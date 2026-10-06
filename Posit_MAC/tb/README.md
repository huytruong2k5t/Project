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
