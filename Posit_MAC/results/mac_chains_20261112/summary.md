# Khảo sát chuỗi MAC — §4.3.3, 12/11/2026

ModelSim 10.1d đối chiếu **48 chuỗi trên mỗi lõi**, 0 sai lệch. Mỗi lõi xử lý 16.320 MAC. Quire xử lý thêm 48 CLEAR và 48 READ. NF/F dùng RTL khớp bản 07/11. Quire dùng RTL hiện hành với chỉ mục SHA-256 riêng trong cùng manifest. [Manifest](manifest.json)

## Điều kiện đo

OPS=1/n=12. Sinh A/B bằng MT19937 seed 20261112, với độ lớn toán hạng trong [0,5; 2). Với mỗi độ dài 16, 64, 256 và 1.024, tạo bốn chuỗi cho mỗi nhóm:

- Cùng dấu: tất cả tích dương.
- Xen dấu: đổi dấu A ở vị trí chẵn theo thứ tự chuỗi.
- Gần triệt tiêu: chạy nửa đầu dương rồi chạy các cặp đối dấu tương ứng. Đảo bit thấp nhất của độ lớn A ở cặp cuối để tổng chính xác có phần dư nhỏ.

Hai lõi NF/F bắt đầu từ C=0, cấp lại `d` đã retire làm C của giao dịch tiếp theo. Quire chạy CLEAR, các MAC, rồi READ. Đầu ra luôn sẵn sàng và nguồn phát lệnh mới ở cơ hội handshake tiếp theo. Số chu kỳ đếm cả cạnh nhận đầu tiên và cạnh retire cuối. Với quire, hai cạnh đó thuộc CLEAR và READ. Kết quả và cờ từng giao dịch so với oracle số nguyên. Với quire, testbench còn kiểm giá trị Q và count ở từng response.

## Số chu kỳ

Mỗi ô là trung vị trên bốn chuỗi cùng nhóm và độ dài.

| Nhóm | MAC mỗi chuỗi | NF | F | Quire |
| --- | ---: | ---: | ---: | ---: |
| Cùng dấu | 16 | 345,5 | 297,5 | 727,5 |
| Cùng dấu | 64 | 1.348,5 | 1.156,5 | 2.690,5 |
| Cùng dấu | 256 | 5.389,5 | 4.621,5 | 10.571,5 |
| Cùng dấu | 1.024 | 21.528 | 18.456 | 42.070 |
| Xen dấu | 16 | 335 | 287 | 717 |
| Xen dấu | 64 | 1.328 | 1.136 | 2.670 |
| Xen dấu | 256 | 5.370,5 | 4.602,5 | 10.552,5 |
| Xen dấu | 1.024 | 21.552 | 18.480 | 42.094 |
| Gần triệt tiêu | 16 | 335 | 287 | 717 |
| Gần triệt tiêu | 64 | 1.355 | 1.163 | 2.697 |
| Gần triệt tiêu | 256 | 5.376 | 4.608 | 10.558 |
| Gần triệt tiêu | 1.024 | 21.513 | 18.441 | 42.055 |

Trên cả 48 chuỗi, F cần ít hơn NF đúng ba chu kỳ mỗi MAC. Quire cần nhiều chu kỳ hơn trong cả ba nhóm, do cập nhật bank theo word và có chi phí CLEAR/READ. Đây là số chu kỳ ở giao diện RTL với driver đã mô tả. Để quy đổi sang thời gian thực cần tần số của từng cấu hình tích hợp.

## Sai số cuối

Mốc chính xác là `Σ A_i × B_i` trên toàn bộ fraction, tính bằng số nguyên trên lưới `2^-532`. CSV giữ hệ số chính xác và sai số tuyệt đối theo từng chuỗi. Với độ dài 1.024, trung vị sai số tuyệt đối là:

| Nhóm | NF | F | Quire |
| --- | ---: | ---: | ---: |
| Cùng dấu | 0,207514 | 0,207514 | 0,207407 |
| Xen dấu | 0,00409376 | 0,00409376 | 0,00409233 |
| Gần triệt tiêu | 2,17405×10⁻⁵ | 2,17405×10⁻⁵ | 1,72529×10⁻⁸ |

Ở nhóm gần triệt tiêu, bit được đổi nằm ngoài 12 bit fraction mà bộ nhân sử dụng. Quire trả Zero cho cả 16 chuỗi nhóm này vì tổng các tích xấp xỉ triệt tiêu chính xác. Sai số tuyệt đối của quire vẫn bằng độ lớn phần dư của tổng tích đầy đủ. NF/F làm tròn khi ghi từng giá trị hồi tiếp, vì vậy kết quả cuối có thể mang thêm sai số tích lũy. Các số đo thuộc miền toán hạng và mẫu chuỗi đã chọn.

[Dãy A/B](chains.csv) · [Kết quả từng chuỗi](results.csv) · [CSV thống kê](summary.csv) · [Manifest](manifest.json)

```powershell
py -3 -B scripts/measure_mac_chains.py audit mac_chains_20261112
py -3 -B results/mac_chains_20261112/source/scripts/measure_mac_chains.py run mac_chains_20261112_replay
```
