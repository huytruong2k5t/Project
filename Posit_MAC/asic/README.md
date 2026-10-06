# Thư mục Luồng Thiết kế ASIC RTL-to-GDSII (`asic/`)

Thư mục này phục vụ mục mở rộng **EXT-A** (§8 của [SPEC_Posit_MAC_IP.md](../SPEC_Posit_MAC_IP.md)) và đóng vai trò là **Bậc D4 trong chính sách bậc thang PPA (§7.6)** sử dụng bộ công cụ hoàn toàn mã nguồn mở **OpenROAD-flow-scripts (ORFS)**:

---

## 1. Mục tiêu và Vai trò

- **Thẩm định PPA trên Silicon Thực**: Đo đạc diện tích thực ($\mu\text{m}^2$), trễ cổng logic (ps), và công suất tiêu thụ ước tính (mW) trên thư viện chuẩn (Standard Cell Library), khắc phục hạn chế đo đạc trừu tượng bằng LUT/FF của FPGA.
- **Phương án dự phòng độc lập bản quyền (Bậc D4)**: Nếu không có giấy phép Vivado hoặc thiếu thiết bị `xcvu9p`, luồng ASIC OpenROAD được nâng thành đường PPA chính để so sánh tỉ lệ diện tích/tần số với thiết kế baseline.

---

## 2. Nền tảng Công nghệ & Các bước Luồng

- **PDK / Standard Cell Library**: Hỗ trợ hai nền tảng mở phổ biến:
  - `Nangate45`: Thư viện logic 45nm học thuật (phổ biến trong nghiên cứu kiến trúc).
  - `SKY130HD`: Công nghệ SkyWater 130nm High-Density mã nguồn mở của Google/SkyWater.
- **Các bước luồng thực thi**:
  1. `Synthesis`: Yosys tổng hợp SystemVerilog RTL sang gate-level netlist.
  2. `Floorplan`: Xác định kích thước core, tỷ lệ khung (aspect ratio) và I/O placement.
  3. `Placement`: Global & Detailed Placement với độ lấp đầy mục tiêu (Core Utilization: 60% – 70%).
  4. `CTS`: Clock Tree Synthesis tối ưu hóa clock skew và insertion delay.
  5. `Routing`: Global & Detailed Routing loại bỏ DRC violations.
  6. `STA`: Static Timing Analysis (đủ setup/hold) trích xuất WNS, TNS và $f_{\max}$.
- **Xem Layout GDSII**: File GDSII ngõ ra được kiểm tra trực quan bằng **KLayout**.

---

## 3. Lệnh Thực thi

```bash
# Chạy luồng ASIC tự động
make asic
```
