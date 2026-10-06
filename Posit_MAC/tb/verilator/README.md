# Testbench Đường A: Verilator C++ Harness (`tb/verilator/`)

Thư mục này chứa môi trường kiểm chứng hiệu năng cao sử dụng trình biên dịch mô phỏng mã nguồn mở **Verilator** kết hợp với C++ Test Harness:

---

## 1. Vai trò Cốt lõi (§6.5 SPEC)

- **Môi trường Nghiệm thu Chính thức**: Là công cụ chính phục vụ đánh giá đạt/hỏng cho các tiêu chí nghiệm thu quan trọng nhất của đồ án:
  - **AC-01**: RTL khớp L1 bit-exact trên $\ge 10^7$ vector cho mỗi cấu hình thuộc ma trận §6.7.
  - **AC-02**: Chế độ exact khớp 100% với SoftPosit trên toàn bộ không gian quét cạn (Exhaustive) của `posit8` và `posit16`, kèm $\ge 10^8$ vector cho `posit32`.
  - **AC-03**: Tái hiện độ chính xác Table I và Table II của bài báo [P].
- **Tốc độ Thực thi Vượt trội**: Khác với các trình mô phỏng hướng sự kiện (event-driven simulators), Verilator biên dịch SystemVerilog thành mã máy C++ đa luồng, cho phép chạy hàng chục triệu vector trong vài phút.

---

## 2. Cấu trúc C++ Harness

- `sim_main.cpp`: Điểm khởi chạy mô phỏng, khởi tạo clock, reset và kết nối DUT với generator.
- `dpi_bridge.cpp`: Gọi trực tiếp các hàm SoftPosit L0 và mô hình thuật toán L1.
- `stat_collector.cpp`: Tính toán các chỉ số sai số thống kê thời gian thực:
  - $\text{Err}(\%) = |r - y| / |r| \times 100$
  - $\text{NMSE} = \frac{1}{N} \sum ((r - y)/r)^2$
  - Tỷ lệ sai số $\text{ErrorRate}(\theta)$ với $\theta \in \{0.1\%, 0.5\%, 1.0\%, 5.0\%\}$.
- Xuất log lỗi chi tiết ra `results/fail_*.log` khi phát hiện mismatch.

---

## 3. Lệnh Thực thi

```bash
# Biên dịch và chạy smoke test Verilator
make smoke

# Chạy toàn bộ ma trận hồi quy
make regress
```
