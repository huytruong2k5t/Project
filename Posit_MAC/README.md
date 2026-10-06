# ĐỒ ÁN CHUYÊN NGÀNH — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP (FPGA & ASIC)

> **Dự án**: Thiết kế và kiểm chứng lõi IP Posit MAC xấp xỉ, lặp (Approximate & Iterative Posit MAC) trên FPGA, có mở rộng ASIC  
> **Sinh viên thực hiện**: Đan Huy  
> **Học kỳ**: HK261 — Trường Đại học Bách Khoa - ĐHQG TP.HCM (HCMUT)  
> **Tài liệu đặc tả chi tiết**: [`SPEC_Posit_MAC_IP.md`](SPEC_Posit_MAC_IP.md)  
> **Nhật ký quyết định thiết kế**: [`docs/ambiguity.md`](docs/ambiguity.md)  
> **Quy chuẩn mã nguồn RTL**: [`Digital_Design_Guidelines.md`](Digital_Design_Guidelines.md)  

---

## 1. Giới thiệu Đề tài

Đồ án tập trung nghiên cứu, thiết kế phần cứng và kiểm chứng toàn diện lõi IP **Posit Multiply-Accumulate (MAC)** ($D = A \times B + C$) với các đóng góp cốt lõi:
1. **Kiến trúc Nhân Lặp & Xấp xỉ (Iterative & Approximate Multiplier)**: Dựa trên bài báo tham chiếu [P] (*Norris & Kim, ISCAS 2021*), thực hiện phép nhân mantissa bằng chuỗi các phép dịch-cộng lặp (SAC $\rightarrow$ Shifter $\rightarrow$ Accumulator) với số vòng lặp $n$ có thể cấu hình linh hoạt lúc chạy, Bài báo báo cáo giảm44% LUT và tăng51% fmax ở điều kiện của tác giả; đề tài chưa đo PPA toàn MAC để xác nhận các tỷ lệ này.
2. **Khối Posit MAC Hoàn chỉnh (Đóng góp C1)**: Mở rộng bộ nhân của [P] thành lõi MAC thông suốt thông qua bộ cộng Posit Adder phân tầng 3 chu kỳ và kỹ thuật làm tròn trong miền unpacked (`round_unpacked`), loại bỏ khâu pack/parse trung gian với ngân sách giảm2 hạng ở TRUNC hoặc3 hạng ở RNE so với v0; số đo latency/II RTL chưa nghiệm thu. MAC L1 exact/RNE đã đối chuẩn non-fused ở các format hỗ trợ; ES3 dùng oracle riêng. Quy ước cạnh và profile baseline theo SPEC v1.4 §5.1/§5.5.
3. **Mạch Kẹp cứng & Dịch Logarit Đa tầng**: Tối ưu hóa triệt để các bộ dịch cân bằng số mũ (Alignment Shifter) và chuẩn hóa bằng kỹ thuật kẹp cứng $\le \text{FRAC\_MAX} + 2$, giới hạn độ rộng mạng dịch; lợi ích LUT và critical path toàn khối cần xác nhận bằng tổng hợp/STA.
4. **Môi trường Kiểm chứng 3 Tầng**: Golden Model độc lập SoftPosit (L0), C++ Algorithmic Model (L1), và RTL SystemVerilog với phương pháp lấy mẫu phân tầng (Stratified Sampling).
5. **Chính sách Bậc thang PPA Khách quan (§7.6)**: 5 bậc đánh giá từ Vivado Enterprise (D0), Vivado Free Standard 16nm UltraScale+ (D1), 7-Series (D2), Yosys (D3), đến OpenROAD ASIC (D4).

---

## 2. Cấu trúc Thư mục Dự án

```text
Posit_MAC/
├── README.md               # Giới thiệu tổng quan toàn bộ dự án
├── SPEC_Posit_MAC_IP.md    # Tài liệu đặc tả kỹ thuật chi tiết nhất (v1.4)
├── Digital_Design_Guidelines.md # Quy chuẩn thiết kế RTL số chuẩn công nghiệp
├── Makefile                # Kịch bản điều khiển luồng (lint, sim, syn, regress)
├── docs/                   # Tài liệu chi tiết, nhật ký quyết định (ambiguity.md)
├── rtl/                    # Mã nguồn phần cứng SystemVerilog
├── tb/                     # Môi trường testbench (Đơn vị, Verilator, UVM-lite)
├── l0/                     # Tầng L0: Wrapper thư viện chuẩn SoftPosit
├── l1/                     # Tầng L1: Mô hình thuật toán C++ bit-exact
├── tests/                  # Dữ liệu ca kiểm thử, corner cases, TV từ paper
├── syn/                    # Kịch bản tổng hợp FPGA Vivado (OOC, non-DSP)
├── asic/                   # Luồng thiết kế ASIC RTL-to-GDSII (OpenROAD)
├── scripts/                # Kịch bản Python tự động hóa và trích xuất PPA
└── results/                # Báo cáo đầu ra tự động (ppa.csv, summary.md)
```

---

## 3. Trạng thái Hiện thực Dự án

- ✅ **Quy chuẩn & Đặc tả**: Hoàn thành tài liệu [SPEC](SPEC_Posit_MAC_IP.md), [Design Guidelines](Digital_Design_Guidelines.md), và [Ambiguity Log](docs/ambiguity.md).
- ✅ **Khối Cơ sở RTL (100% Verified)**:
  - [`rtl/lod_lzd_core.sv`](rtl/lod_lzd_core.sv): Cây nhị phân phẳng dò Lead One / Lead Zero.
  - [`rtl/dyn_left_shifter.sv`](rtl/dyn_left_shifter.sv): Bộ dịch trái logarit đa tầng kèm chống tràn ($b \ge N$).
  - [`rtl/dyn_right_shifter.sv`](rtl/dyn_right_shifter.sv): Bộ dịch phải logarit đa tầng hỗ trợ dịch logic/arithmetic/custom fill kèm chống tràn.
- ✅ **Môi trường Testbench Đơn vị**:
  - [`tb/tb_lod_lzd_core.sv`](tb/tb_lod_lzd_core.sv) (Pass 100%).
  - [`tb/tb_dyn_left_shifter.sv`](tb/tb_dyn_left_shifter.sv) (Pass 100% trên 60,832 vectors).
  - [`tb/tb_dyn_right_shifter.sv`](tb/tb_dyn_right_shifter.sv) (Pass 100% trên 146,400 vectors).

---

## 4. Hướng dẫn Chạy Nhanh (Quick Start)

### Chạy kiểm chứng tự động các bộ dịch động:
```bash
# Kiểm tra bộ dịch trái động (60,832 vectors)
python scripts/verify_dyn_left_shifter.py

# Kiểm tra bộ dịch phải động (146,400 vectors)
python scripts/verify_dyn_right_shifter.py
```
