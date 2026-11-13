# Sai số toàn MAC — §4.3.2, 12/11/2026

MAC-NF và MAC-F đều khớp oracle ở **377.032 bộ A/B/C**, gồm `d` và năm cờ tại mỗi handshake đầu ra. ModelSim 10.1d chạy OPS=1/n=12 trên RTL khớp SHA-256 với bản 07/11. [Manifest](manifest.json)

## Thiết lập

Dùng lại 125.696 cặp A/B từ §4.3.1 (seed 20261112). Với mỗi cặp hữu hạn khác 0, tạo ba giá trị C từ tích chính xác `P=A×B`, bằng `R(P/2)`, `R(−P/2)` và `R(−P)`. Hàm `R` thực hiện đóng gói theo SPEC, gồm kẹp khi vượt miền. Với 28 cặp Zero/NaR, dùng C=0. NF và F nhận cùng mã A/B/C ở mỗi phép đo standalone. [Tập A/B](../mul_prepack_20261112/pairs.csv) · [SPEC](../../docs/SPEC_Posit_MAC_IP.md)

Oracle số nguyên ES3 kiểm chức năng theo quy tắc làm tròn của từng lõi. Mốc đo sai số là tổng chính xác `r=P+C` với C đã giải mã từ mã thực sự cấp vào RTL. Sai số tuyệt đối là `|decode(d)−r|`. Sai số tương đối dùng `100×|decode(d)−r|/|r|` cho nhóm thông thường. Tách nhóm `r=0` và nhóm gần 0 theo `0<|r|≤2⁻¹²|P|`. P95 dùng hạng `ceil(0,95×N)`. Mỗi phép so tốt hơn hoặc kém hơn được quyết định bằng sai số tuyệt đối số nguyên, trước khi định dạng CSV.

## Kết quả

Trên 100.000 cặp A/B lấy mẫu đều, cả nhóm cùng dấu và trái dấu đều có 100.000 tổng thông thường:

| C cấp cho hai lõi | P95 NF (%) | P95 F (%) | Max NF (%) | Max F (%) | Số ca F nhỏ hơn / bằng / lớn hơn NF |
| --- | ---: | ---: | ---: | ---: | ---: |
| `R(P/2)` | 0,019824 | 0,019823 | 0,256383 | 0,256383 | 2.501 / 95.063 / 2.436 |
| `R(−P/2)` | 0,059461 | 0,059445 | 0,765227 | 0,575784 | 6.538 / 86.917 / 6.545 |

Trong nhóm `C=R(−P)`, 108.703 ca đạt ngưỡng gần 0. P95 sai số tuyệt đối trên toàn nhóm này là **6,19861×10¹⁰ (NF)** và **5,17001×10¹⁰ (F)**. Max lần lượt là **3,87660×10⁵⁸** và **6,38744×10⁵⁸**. Độ lớn tuyệt đối phụ thuộc thang số. Riêng 99.994 ca gần 0 từ nhóm A/B lấy đều có P95 **5,86053×10⁷ (NF)** và **5,85749×10⁷ (F)**. Trên 108.703 ca gần 0, F nhỏ hơn/bằng/lớn hơn NF ở **12.753 / 83.578 / 12.372** ca.

Trong cùng nhóm đặt C để triệt tiêu, 4.272 ca có tổng đúng 0. Cả hai lõi trả đúng Zero trên 3.966 ca. Sai số tuyệt đối max của mỗi lõi trên 4.272 ca là **1,58456×10²⁹**. Thêm 16 ca `R(−P/2)` và 13 ca A/B có Zero cho tổng đúng 0, tất cả đều trả Zero ở hai lõi. Cả 15 ca A/B có NaR đều trả NaR. Có 12.693 ca `R(−P)` cho tổng ngoài ngưỡng gần 0, gồm 2.881 ca C kẹp min, 3.328 ca kẹp max và 6.484 ca còn lại. CSV giữ riêng các phân nhóm này.

Gộp toàn bộ 377.017 ca hữu hạn, F có sai số nhỏ hơn NF trên **47.534** ca, bằng trên **305.545** ca và lớn hơn trên **23.938** ca. Ví dụ `pair_id=35`, A=`1141ee15`, B=`33f45b16`, C=`0c9e9823` (hex). NF trả `0e36ebd9` với sai số **0,00785865%**, F trả `0e36ebd8` với sai số **0,00786356%**. Làm tròn tích trước khi cộng có thể đưa kết quả về gần tổng chính xác hơn ở từng ca. [Ví dụ F có sai số lớn hơn](f_worse_examples.csv)

## Bằng chứng và tái lập

[CSV thống kê theo nhóm](summary.csv) · [CSV từng giao dịch](samples.csv.gz) · [Manifest nguồn, tool, lệnh và hash bằng chứng](manifest.json). Đã đối soát lại mã A/B, nhóm C, phân loại triệt tiêu, sai số và số lượng của toàn bộ dữ liệu. Đây là khảo sát báo cáo ở OPS1/n12. Ma trận paired accuracy AC-03 tiếp tục theo khối lượng và cấu hình trong SPEC.

Từ thư mục `Posit_MAC`, với Python 3.11 và ModelSim trên PATH:

```powershell
py -3 -B scripts/measure_paired_mac_accuracy.py audit paired_mac_20261112
py -3 -B results/paired_mac_20261112/source/scripts/measure_paired_mac_accuracy.py run paired_mac_20261112_replay --jobs 6
```
