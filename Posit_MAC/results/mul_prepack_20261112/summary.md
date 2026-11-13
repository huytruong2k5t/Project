# Sai số bộ nhân FULL_TERM trước Packer — §4.3.1, 12/11/2026

ModelSim hoàn tất **1.634.048 giao dịch, 0 sai lệch** trên MAC-F với OPS=1 và n=0…12. Ở n=12, tích RTL bằng tích chính xác của hai toán hạng đã giữ 12 bit fraction trên cả 125.668 cặp hữu hạn khác 0. Trong 100.000 cặp lấy mẫu đều theo mã Posit, sai số tương đối so với tích chính xác đầy đủ có **P95 0,029718%** và **max 0,045962%**. Số vòng thực tế trung bình là **5,02741**, P95 là 7 và max là 10. Ca chủ đích có đủ 12 bit 1 ở cả hai toán hạng chạy đủ 12 vòng.

## Thiết lập và đối chiếu

Tập A/B cố định được sinh bằng Python `random.Random` (MT19937), seed **20261112**. Mỗi n chạy cùng 125.696 cặp theo cùng thứ tự:

| Nhóm | Cặp mỗi n | Cách chọn |
| --- | ---: | --- |
| `uniform_raw` | 100.000 | Hai mã 32 bit lấy độc lập, đều và có hoàn lại trong tập hữu hạn khác 0. |
| `stratified_regime` | 25.600 | 100 cặp mỗi ô trong 8 nhóm độ dài regime của A × 8 của B × 4 tổ hợp dấu theo SPEC §6.3. Trong mỗi nhóm, lấy đều trên các tổ hợp độ dài và polarity hợp lệ, sau đó lấy đều các bit còn lại. |
| `directed_finite` | 68 | Minpos/maxpos có dấu, biên regime, ca FT-05, popcount X từ 0 đến 12, OPS hòa/đổi vai và các mẫu fraction có chủ đích. |
| `directed_zero` | 13 | Có toán hạng Zero, cả hai toán hạng hữu hạn. |
| `directed_nar` | 15 | Có toán hạng NaR, gồm cả NaR × Zero và Zero × NaR. |

Nguồn là cây làm việc đã hồi quy ngày 07/11. Runner so SHA-256 của cả 30 tệp RTL trong `mac_active.f`, file list và header với [manifest build MAC-F 07/11](../shared_parser_mul_20261107/build_f.json), rồi mô phỏng từ bản sao trong `source/`. [Manifest của phép đo](manifest.json) khóa các đầu vào build, testbench, oracle, lệnh ModelSim và bằng chứng đầu ra. [Biên dịch ModelSim ALTERA Starter Edition 10.1d](verify/compile.log)

Testbench cấp A/B và C=0 qua giao diện MAC-F. Tại `u_wrapper.u_core.core_done`, testbench ghi độ lớn Q24 `acc`, dấu, số mũ cơ sở có dấu `sf_o`, `iterations_done`, `input_cut_o` và `approx_cut`. Mô hình độc lập giải mã Posit ES3 bằng số nguyên, chọn trực tiếp tối đa n bit 1 cao nhất của fraction X theo OPS=1 và tính tích dạng đóng. Khi MAC-F retire, testbench ghi thêm `d` và năm cờ để so với mã và cờ từ oracle RNE. Cả hai điểm đối chiếu dùng cùng giao dịch đã nhận. [Testbench](source/tb/tb_multiplier_prepack.sv) · [Oracle ES3](source/scripts/gen_refactored_mac_vectors.py)

## Định nghĩa sai số

Với cặp hữu hạn khác 0, gọi `b` là tổng số mũ cơ sở, `s` là dấu tích và `M` là độ lớn đọc từ RTL:

- `P = (−1)^s × full_q52 × 2^(b−52)` dùng toàn bộ fraction của A và B.
- `P12 = (−1)^s × trunc_q24 × 2^(b−24)` nhân chính xác hai significand đã giữ 12 bit fraction.
- `P_hat = (−1)^s × M × 2^(b−24)` là tích RTL trước chuẩn hóa và Packer.

Sai số tổng là `100 × |P_hat−P|/|P|`. Sai số do cắt đầu vào là `100 × |P12−P|/|P|`. Sai số do giới hạn vòng là `100 × |P_hat−P12|/|P12|`. Các tỉ số được tính từ hệ số nguyên đã đưa về cùng lưới, rồi xuất dưới dạng phần trăm. Hai mốc `P` và `P12` cố định theo `pair_id`. P95 lấy phần tử hạng `ceil(0,95 × N)` sau khi sắp tăng dần trong từng nhóm. Max là giá trị lớn nhất quan sát được. Zero và NaR được kiểm riêng, với ô sai số tương đối để trống. Số vòng `t` đếm các số hạng fraction được xử lý. Phần đóng góp từ bit ẩn được khởi tạo riêng.

## Kết quả trên 100.000 cặp lấy mẫu đều

| n | Sai số tổng P95 (%) | Sai số tổng max (%) | Sai số giới hạn vòng P95 (%) | Sai số giới hạn vòng max (%) | t trung bình | t P95 | t max | Cặp còn số hạng |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 47,120876 | 49,980270 | 47,114267 | 49,975574 | 0,00000 | 0 | 0 | 99.962 |
| 1 | 20,681315 | 24,970405 | 20,671401 | 24,963361 | 0,99962 | 1 | 1 | 99.347 |
| 2 | 7,602552 | 12,465473 | 7,593142 | 12,457255 | 1,99309 | 2 | 2 | 96.024 |
| 3 | 2,542602 | 6,213006 | 2,525701 | 6,204201 | 2,95333 | 3 | 3 | 85.857 |
| 4 | 0,758724 | 3,086773 | 0,745976 | 3,077675 | 3,81190 | 4 | 4 | 64.804 |
| 5 | 0,212453 | 1,523657 | 0,198020 | 1,514411 | 4,45994 | 5 | 5 | 37.552 |
| 6 | 0,059807 | 0,742098 | 0,042863 | 0,732780 | 4,83546 | 6 | 6 | 14.874 |
| 7 | 0,032008 | 0,351319 | 0 | 0,341964 | 4,98420 | 7 | 7 | 3.724 |
| 8 | 0,029948 | 0,155930 | 0 | 0,146556 | 5,02144 | 7 | 8 | 554 |
| 9 | 0,029735 | 0,058235 | 0 | 0,048852 | 5,02698 | 7 | 9 | 43 |
| 10 | 0,029718 | 0,045962 | 0 | 0 | 5,02741 | 7 | 10 | 0 |
| 11 | 0,029718 | 0,045962 | 0 | 0 | 5,02741 | 7 | 10 | 0 |
| 12 | 0,029718 | 0,045962 | 0 | 0 | 5,02741 | 7 | 10 | 0 |

Sai số do cắt đầu vào trên nhóm này có P95 **0,029718%** và max **0,045962%**, giống nhau ở cả 13 cấu hình. Ở n=7, P95 của sai số do giới hạn vòng đã bằng 0 nhưng 3.724 cặp vẫn còn số hạng, với max **0,341964%** so với `P12`. Ở n=12, cặp có sai số tổng lớn nhất trong nhóm này là `pair_id=81781`, A=`0x78814fa0`, B=`0x200efd00`.

## Nhóm phân tầng và ca biên

| Nhóm ở n=12 | Sai số tổng P95 (%) | Sai số tổng max (%) | t trung bình | t P95 | t max |
| --- | ---: | ---: | ---: | ---: | ---: |
| 25.600 cặp phân tầng regime/dấu | 0,021800 | 0,043773 | 2,66215 | 7 | 10 |
| 68 cặp hữu hạn có chủ đích | 0 | 0,024411 | 2,60294 | 11 | 12 |

Ở n=12, toàn bộ cặp hữu hạn của cả ba nhóm có `iteration_cut=0`. Ca A=B=`0x43ffc000` đạt `M=67.092.481`, `b=0`, `t=12`. Qua 13 mức n, 169 giao dịch Zero và 195 giao dịch NaR đều khớp oracle, với `t=0`. Các thống kê phản ánh từng tập mẫu của phép đo. Số vòng fraction mô tả hoạt động của bộ nhân trong phạm vi §4.3.1.

## Dữ liệu và tái lập

- [pairs.csv](pairs.csv) giữ nguyên mã A/B dạng hex tám chữ số, hai mốc tích dạng hệ số nguyên, nhóm và `pair_id`. Dùng lại file này khi bổ sung C cho §4.3.2. SHA-256 là `e89808ee7ff91209c945f989f90dec8ea01f2093946a07cd5610f5ab96f4df34`.
- [samples.csv.gz](samples.csv.gz) giữ một bản ghi quan sát cho mỗi `(n, pair_id)`, gồm dữ liệu RTL và ba sai số theo phần trăm. [summary.csv](summary.csv) lưu thống kê đủ mọi n và mọi nhóm. [rounds_hist.csv](rounds_hist.csv) lưu số mẫu tại từng t=0…12.
- Đã đọc lại toàn bộ CSV chi tiết để kiểm số dòng, ghép đúng `pair_id` qua 13 mức n, đối chiếu phân vị, max và histogram. Tập A/B cũng được kiểm bằng giải mã độc lập để xác nhận hai mốc tích và đủ 256 ô regime/dấu.

Từ thư mục `Posit_MAC`, dùng Python 3.11 và ModelSim trên PATH. Lệnh replay đọc nguồn đã sao lưu và ghi vào thư mục kết quả mới.

```powershell
py -3 -B scripts/measure_multiplier_prepack.py audit mul_prepack_20261112
py -3 -B results/mul_prepack_20261112/source/scripts/measure_multiplier_prepack.py run mul_prepack_20261112_replay --jobs 6
```
