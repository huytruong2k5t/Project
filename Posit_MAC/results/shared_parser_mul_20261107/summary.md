# Verification sau khi hợp nhất parser của NF/F

Ngày 07/11/2026. Chạy trên checkout chuẩn bị công bố. Hai wrapper cùng dùng `posit_parser_mul` cho A, B và C. A/B dùng 12 bit cao và `tail_cut`. C đưa đủ 26 bit fraction vào đường cộng. Cả ba ngõ ra fraction/cờ được chốt cùng thanh ghi valid tại P2.

Strict lint Verilator đạt 30 module. Kiểm tra phân cấp và cổng đạt 66 instance. Hai bản build dùng seed `20261107`, cấu hình hỗn hợp `n = 0…12` và OPS 0/1, đối chiếu mã Posit(32,3) cùng năm cờ với golden độc lập.

| Lõi | Giao dịch hoàn tất | Reset hủy | Mismatch | Tổ hợp n × OPS |
| --- | ---: | ---: | ---: | ---: |
| MAC-NF | 100.000 | 600 | 0 | 26/26 |
| MAC-F | 100.000 | 518 | 0 | 26/26 |

Bằng chứng gồm [lint](ports_and_lint.json), [NF](mixed_nf.json) và [F](mixed_f.json). Lượt này là hồi quy chức năng và giao thức. Timing sau tổng hợp và mức cắt bỏ thanh ghi trên netlist của phiên bản này chưa được đo.
