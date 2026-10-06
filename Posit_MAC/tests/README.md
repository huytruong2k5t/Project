# Thư mục Ca Kiểm thử và Dữ liệu Mẫu (`tests/`)

Thư mục này chứa danh mục các ca kiểm thử biên đặc biệt (Corner Cases), test vector trích xuất từ bài báo tham chiếu, và các bộ vector cố định phục vụ kiểm tra hồi quy nhanh (`make smoke`):

---

## 1. Danh mục Vector Cố định

| Tệp Dữ liệu | Mô tả chi tiết | Dẫn chứng SPEC |
|:---|:---|:---:|
| `corner_cases.md` | Danh sách 10 trường hợp biên bắt buộc cho Posit32/16/8: `zero`, `NaR`, `+1/-1`, `minpos/-minpos`, `maxpos/-maxpos`, các cặp triệt tiêu về 0, hòa RNE và regime tối đa $m = NB-1$. | [§6.4 SPEC](../SPEC_Posit_MAC_IP.md#L512-L523) |
| `tv_paper.txt` | Test vector mẫu **TV-PAPER-01** đọc từ Fig. 4 của bài báo [P] ($ES=3, \text{FRAC\_W}=12, n=2$), kết quả xuất ở chu kỳ thứ 8. | [§5.6 & §5.10-D](../SPEC_Posit_MAC_IP.md#L340-L349) |
| `tv_iter.txt` | Test vector **TV-ITER-01** (số học nhỏ tính tay: $1.25 \times 1.375$) để kiểm tra từng bước tính toán của SAC và SBM qua các vòng lặp $n=0, 1, \dots$. | [§5.6 SPEC](../SPEC_Posit_MAC_IP.md#L332-L339) |
| `stratified_regime.txt` | Bộ vector phân tầng bắt buộc: chia độ dài regime $m$ thành 8 nhóm $G_1 \dots G_8$ để kích hoạt toàn diện mọi tầng barrel shifter và LOD/LZD. | [§6.3 SPEC](../SPEC_Posit_MAC_IP.md#L494-L510) |

---

## 2. Quy ước Thực thi

- **Kiểm tra nhanh (Smoke Test)**:
  ```bash
  make smoke
  ```
  Thực thi toàn bộ `corner_cases.md`, `tv_paper.txt`, và `tv_iter.txt` trong vài giây trước mỗi commit.
- **Kiểm tra hồi quy toàn diện**:
  ```bash
  make regress
  ```
  Chạy toàn bộ ma trận cấu hình §6.7 đối chiếu song song với L0/L1.
