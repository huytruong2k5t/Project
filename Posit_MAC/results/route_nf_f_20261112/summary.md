# Timing sau route NF/F 100 MHz — 12/11/2026

Cả MAC-NF và MAC-F có setup và hold slack dương trong lượt triển khai **out-of-context** ở 100 MHz trên RTL khớp bản 07/11. Vivado 2026.1 dùng `xc7a35tcpg236-1`, clock 10 ns, uncertainty 0,1 ns, input delay min/max 2,5 ns và output delay min/max 0/0,5 ns. Wrapper giữ cổng cấu hình động. Hai wrapper và hai XDC khớp SHA-256 với lượt tổng hợp 06/11. Place/route dùng directive `Default` cho cả hai lõi.

| Lõi | LUT sau route | FF sau route | WNS (ns) | TNS (ns) | WHS (ns) | THS (ns) | Endpoint setup/hold lỗi |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| MAC-NF | 1.558 | 916 | +0,665 | 0,000 | +0,043 | 0,000 | 0 / 0 |
| MAC-F | 1.211 | 781 | +2,142 | 0,000 | +0,043 | 0,000 | 0 / 0 |

DSP và BRAM đều bằng 0. Toàn bộ net cần route đã định tuyến, với 0 lỗi định tuyến ở mỗi lõi. [STA NF](nf/route_timing.rpt) · [STA F](f/route_timing.rpt) · [Route NF](nf/route_status.rpt) · [Route F](f/route_status.rpt)

Đường setup xấu nhất đi từ thanh ghi đồng bộ reset đến `in_ready` ở cả hai lõi. Ở NF, đầu launch nằm trong Packer cuối. Ở F, đầu launch nằm trong wrapper. Hold xấu nhất là đường nội bộ từ S1 đến S2 của bộ cộng ở NF, và từ thanh ghi cờ đầu ra bộ cộng đến Packer P1 ở F.

Vivado báo `Route 35-198` về các cổng OOC thiếu `HD.PARTPIN_LOCS`. Slack ở bảng trên thuộc mô hình OOC với budget I/O giả định. Đường đến `in_ready` cần được đánh giá lại sau khi tích hợp vào thiết kế có placement và ràng buộc I/O cụ thể. Lượt này dùng một directive và lưu checkpoint sau route.

[Manifest kết quả](manifest.json) · [Chỉ mục SHA-256 nguồn](source_sha256.json) · [Tài nguyên NF](nf/route_utilization.rpt) · [Tài nguyên F](f/route_utilization.rpt) · [Recipe Tcl](source/syn/route_mac_100mhz.tcl)
