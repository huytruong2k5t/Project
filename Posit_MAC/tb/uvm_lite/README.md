# Testbench Đường B: UVM-Lite / SystemVerilog Class-based (`tb/uvm_lite/`)

Thư mục này chứa môi trường kiểm chứng hướng đối tượng (class-based) xây dựng bằng SystemVerilog chuẩn công nghiệp, phục vụ thẩm định phương pháp luận kiểm chứng vi mạch số nâng cao:

---

## 1. Cấu trúc Môi trường Class-based

- **`mac_seq_item.sv`**: Gói dữ liệu giao dịch chứa các toán hạng `a, b, c`, tín hiệu điều khiển `acc_mode, acc_clr` và cấu hình `cfg_mode, cfg_n, cfg_ops`.
- **`mac_generator.sv`**: Bộ sinh ngẫu nhiên có ràng buộc (**Constrained-Random Generator**) áp dụng phương pháp **Lấy mẫu Phân tầng (Stratified Sampling - §6.3)**:
  - Chia chiều dài regime thành 8 nhóm $G_1 \dots G_8$.
  - Kích thích bắt buộc các trường hợp biên cấu trúc: regime cực đại $m = NB-1, NB-2$, mantissa toàn 0/toàn 1, và kích hoạt đầy đủ 100% các nhánh đếm LOD/LZD.
  - Ép sinh $\ge 30\%$ vector triệt tiêu trong phép cộng ($|\Delta sf| \le 4$).
- **`mac_driver.sv`**: Điều khiển giao thức bắt tay `valid && ready`, mô phỏng ngẫu nhiên áp lực downstream backpressure (`out_ready` trễ từ 0 đến nhiều chu kỳ).
- **`mac_monitor.sv`**: Giám sát thụ động các bus ngõ vào và ngõ ra, đóng gói giao dịch hoàn tất gửi sang Scoreboard.
- **`mac_scoreboard.sv`**: Kết nối với mô hình C++ L0 (SoftPosit) và L1 qua **DPI-C**, đối chiếu bit-exact từng giao dịch và ghi nhận sai lệch.
- **`mac_coverage.sv`**: Thu thập Functional Coverage:
  - `cross(nhóm mA, nhóm mB, cặp dấu)` = 256 bin.
  - Phân bố số vòng lặp thực tế: $n \in \{0, 1, 2, 3, 4, 5\text{--}8, >8\}$.
  - Khối Adder: Chênh lệch $\Delta sf$ (bao gồm bin kẹp cứng $> 29$), cờ nhớ tràn, và số bit triệt tiêu LZC.

---

## 2. Hệ thống Khẳng định SystemVerilog Assertions (SVA)

Tích hợp giám sát thời gian thực các khẳng định từ **A-01 đến A-09** (§6.6):
- `A-01`: Không có trạng thái X/Z trên các bus ngõ ra sau reset.
- `A-02`: Dữ liệu ngõ ra `d` và `flags` giữ nguyên khi bị backpressure (`out_valid && !out_ready`).
- `A-03`: Số vòng lặp thực tế không bao giờ vượt quá `cfg_n`.
- `A-04`: Đường exact bắt buộc $fx = 0$ khi kết thúc.
- `A-05`: Ngõ ra NaR tương đương khi có toán hạng NaR.
- `A-06`: Ngõ ra zero chỉ khi toán hạng bằng 0 hoặc triệt tiêu chính xác.
- `A-07`: Bảo toàn giao dịch (mỗi input handshake cho đúng một output handshake, không mất, không nhân đôi).
- `A-08`: Không ghi đè pipeline khi nạp giao dịch chồng lấn (không xung đột dữ liệu).
- `A-09`: Ràng buộc khoảng cách khởi phát $\text{II} \ge \max(1, n_{\text{thực tế}})$.
