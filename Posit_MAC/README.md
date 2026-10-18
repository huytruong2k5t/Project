# ĐỒ ÁN CHUYÊN NGÀNH — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP (FPGA & ASIC)

## Release production đã khóa — 18/10/2026

**Workflow cập nhật18/10:** candidate OPT-12 negate đã qua10M NF+10M F/0 mismatch và
post-route120,48MHz với Explore cho cả NF/F (Optimization8.31.7). Chờ sinh viên chọn,
chưa promote/lock mới hoặc chạy W14; release100MHz bên dưới giữ làm reference có hash.


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
2. **Hai kiến trúc MAC so sánh nội bộ**: NF làm tròn tích rồi cộng, D=R(R(P_hat)+C_eff); fused cộng P_hat với C_eff trong cửa sổ W32 trước RNE cuối. NF hiện dùng product pack P1/P2 và magnitude parse riêng; không còn tuyên bố loại bỏ pack/parse trung gian. Lịch NF14 tầng và F13 tầng theo SPECv1.20; final per-n/AC04 và paired accuracy/PPA còn mở.
3. **Tối ưu các khối tổ hợp**: Masked OPS, SAC abc_tree, A1 parallel shift/jam và prefix sticky giữ bit-exact, không tăng latency so lịch OPT-03. Gói NF đạt setup/hold100MHz trên A35T-C2 qua3 strategy, với đánh đổi LUT/FF được ghi tại Optimization8.30.
4. **Môi trường Kiểm chứng 3 Tầng**: Golden Model độc lập SoftPosit (L0), C++ Algorithmic Model (L1), và RTL SystemVerilog với phương pháp lấy mẫu phân tầng (Stratified Sampling).
5. **PPA có điều kiện so sánh thống nhất**: Các lượt đo tiếp theo chỉ dùng Vivado/A35T-C2, cùng nguồn, XDC và strategy cho các biến thể. Số liệu CycloneIV/A100T giữ làm lịch sử; chưa có paired NF/F PPA cuối hoặc đo tần số board.

---

## 2. Cấu trúc Thư mục Dự án

RTL đã phân nhóm theo chức năng; xem [bản đồ RTL](rtl/README.md). Danh sách build chính: `rtl/production.f`. Không compile chung các candidate trùng tên module.


```text
Posit_MAC/
├── README.md               # Giới thiệu tổng quan toàn bộ dự án
├── SPEC_Posit_MAC_IP.md    # Tài liệu đặc tả kỹ thuật chi tiết nhất (v1.20)
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
  - [`rtl/common/lod_lzd_core.sv`](rtl/common/lod_lzd_core.sv): Cây nhị phân phẳng dò Lead One / Lead Zero.
  - [`rtl/common/dyn_left_shifter.sv`](rtl/common/dyn_left_shifter.sv): Bộ dịch trái logarit đa tầng kèm chống tràn ($b \ge N$).
  - [`rtl/common/dyn_right_shifter.sv`](rtl/common/dyn_right_shifter.sv): Bộ dịch phải logarit đa tầng hỗ trợ dịch logic/arithmetic/custom fill kèm chống tràn.
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
