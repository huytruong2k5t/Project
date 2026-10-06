# Tầng L0: Wrapper Thư viện Chuẩn SoftPosit (`l0/`)

Thư mục này chứa mã nguồn wrapper C/C++ và Python tích hợp thư viện chuẩn quốc tế **SoftPosit** (phát triển bởi nhóm tác giả Posit, CERG Lab):

---

## 1. Vai trò trong Hệ thống Kiểm chứng (§6.1 SPEC)

- **Chuẩn vàng Toán học (Golden Reference)**: Đóng vai trò là tầng tham chiếu chân lý cao nhất (Ground Truth) để thẩm định độ chính xác của mô hình thuật toán L1 và chế độ Exact của lõi RTL.
- **Tiêu chí nghiệm thu AC-02**:
  - `posit8 (ES=0)`: Quét cạn toàn bộ không gian (Exhaustive) với $2^{16}$ cặp nhân (`p8_mul`), $2^{16}$ cặp cộng (`p8_add`), và $2^{24}$ bộ ba MAC.
  - `posit16 (ES=1)`: Quét cạn $2^{32}$ cặp nhân và cộng.
  - `posit32 (ES=2)`: Khớp bit-exact trên toàn bộ Corner List (§6.4) và $\ge 10^8$ vector ngẫu nhiên phân tầng.
  - **Kết quả yêu cầu**: **0 mismatch tuyệt đối**.

---

## 2. Giao diện C và DPI-C cho Testbench

Header: [softposit_api.h](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l0/softposit_api.h), Implementation: [softposit_api.c](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l0/softposit_api.c).

Cung cấp giao diện C liên kết trực tiếp với trình mô phỏng SystemVerilog (Verilator, Questa, Xcelium, VCS) thông qua DPI-C:

```c
// Nguyên mẫu hàm DPI-C (Exported to SystemVerilog & ctypes)
uint32_t l0_p32_mul   (uint32_t a, uint32_t b);
uint32_t l0_p32_add   (uint32_t a, uint32_t b);
uint32_t l0_p32_sub   (uint32_t a, uint32_t b);
uint32_t l0_p32_div   (uint32_t a, uint32_t b);
uint32_t l0_p32_mulAdd(uint32_t a, uint32_t b, uint32_t c);
double   l0_p32_to_double(uint32_t a);
uint32_t l0_double_to_p32(double d);

uint16_t l0_p16_mul   (uint16_t a, uint16_t b);
uint16_t l0_p16_add   (uint16_t a, uint16_t b);
uint16_t l0_p16_sub   (uint16_t a, uint16_t b);
uint16_t l0_p16_div   (uint16_t a, uint16_t b);
uint16_t l0_p16_mulAdd(uint16_t a, uint16_t b, uint16_t c);

uint8_t  l0_p8_mul    (uint8_t a, uint8_t b);
uint8_t  l0_p8_add    (uint8_t a, uint8_t b);
uint8_t  l0_p8_sub    (uint8_t a, uint8_t b);
uint8_t  l0_p8_div    (uint8_t a, uint8_t b);
uint8_t  l0_p8_mulAdd (uint8_t a, uint8_t b, uint8_t c);
```

---

## 3. Biên dịch và Cấu trúc Nhị phân

Thư viện được biên dịch đa nền tảng bằng [Makefile](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l0/Makefile):

```bash
# Biên dịch cả bản Linux (.so, cli) và Windows (.dll, .exe):
make all

# Hoặc chỉ biên dịch riêng:
make windows   # Tạo softposit.dll và softposit_cli.exe
make linux     # Tạo libsoftposit.so và softposit_cli
```

Các file nhị phân được tạo:

- `softposit.dll`: Dynamic Link Library cho Windows x64 (dùng cho Python `ctypes`, C/C++, Verilator Windows).
- `libsoftposit.so`: Shared Object cho Linux x86_64 (dùng cho WSL, Verilator DPI-C).
- `softposit_cli.exe` & `softposit_cli`: Công cụ dòng lệnh tra cứu và kiểm thử nhanh.

---

## 4. Hướng dẫn Sử dụng CLI

```powershell
# Chạy toàn bộ test corner cases:
.\l0\softposit_cli.exe test_corners

# Thực hiện phép tính cụ thể:
.\l0\softposit_cli.exe p32_mul 0x40000000 0x40000000      # 1.0 * 1.0 = 0x40000000
.\l0\softposit_cli.exe p32_mulAdd 0x40000000 0x40000000 0x40000000  # 1*1 + 1 = 0x48000000 (2.0)
.\l0\softposit_cli.exe double_to_p8 0.1                   # -> 0x06
```

---

## 5. Hướng dẫn Sử dụng Python Wrapper (`l0/softposit.py`)

Python wrapper tự động nhận diện hệ điều hành để load `softposit.dll` (Windows) hoặc `libsoftposit.so` (Linux/WSL):

```python
from l0 import Posit8, Posit16, Posit32, p32_mul, p32_add, p32_mulAdd

# Cách 1: Sử dụng hàm số học bậc thấp (hex / int)
p_prod = p32_mul(0x40000000, 0x40000000)      # 0x40000000 (1.0)
p_mac  = p32_mulAdd(0x40000000, 0x40000000, 0x40000000) # 0x48000000 (2.0)

# Cách 2: Sử dụng lớp đối tượng (hỗ trợ nạp chồng toán tử +, -, *, /)
a = Posit32(0x40000000)  # 1.0
b = Posit32(0x40000000)  # 1.0
c = a * b
print(c.hex, c.double)   # 0x40000000 1.0
```

---

## 6. Kết quả Nghiệm thu Tuần 2 (Corner & TV-RND Validation)

Kịch bản kiểm thử: [test_softposit_corners.py](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l0/test_softposit_corners.py).
Log chi tiết: [results/corner.log](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/results/corner.log).

- **Số test case**: 40/40 PASSED (0 FAIL).
- **Phạm vi kiểm tra**:
  1. Toàn bộ Corner List theo §6.4: `zero`, `NaR`, `+1`, `-1`, `minpos`, `-minpos`, `maxpos`, `-maxpos`.
  2. Các tổ hợp tới hạn: `NaR * 0`, `0 * NaR`, `maxpos * maxpos` (tràn bão hòa), `minpos * minpos` (dưới bão hòa), `(-maxpos) * (-maxpos)`, `maxpos * minpos` (ra đúng 1.0 cho `ES=2`), `maxpos + maxpos`, `(+1) + (-1) -> 0`, `1 + minpos -> 1.0`.
  3. Lan truyền NaR và tích lũy trong phép MAC: `p32_mulAdd(NaR, 1, 0) -> NaR`, `p32_mulAdd(1, 1, NaR) -> NaR`.
  4. Tập vector làm tròn TV-RND (§3.4): TV-RND-00 (0.1 -> 0x06), TV-RND-01 (hòa RNE chẵn -> 0x40), TV-RND-02 (hòa RNE lẻ -> 0x42), TV-RND-03 (100 -> bão hòa 0x7F), TV-RND-04 (0.001 -> bão hòa 0x01).
  5. Maximum Regime ($m = NB - 1$) cho cả `posit8`, `posit16`, và `posit32`.
