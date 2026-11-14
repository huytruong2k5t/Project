# Plan: Xác nhận Fmax bằng lượt route thực cho MAC-F và MAC-NF

Ngày lập: 14/11/2026 · Người thực hiện: Codex/Gemini theo plan này · Người duyệt: Đan Huy

## 1. Mục tiêu (usecase)

Báo cáo hội đồng hiện công bố MAC-F đạt **Fmax,R2R = 154,42 MHz** và MAC-NF đạt **135,85 MHz**.
Hai con số này được **suy ra** bằng công thức `1000 / (10 − WNS_R2R)` từ một lượt route duy nhất
ở chu kỳ 10 ns. Chưa có lượt route nào chạy ở đúng chu kỳ tương ứng (khoảng 6,5 ns và 7,4 ns).

Mục tiêu là có bằng chứng route thực trên **đúng RTL đang đóng băng**, để trả lời được câu hỏi của
hội đồng: "Fmax này đã chạy thật chưa? Chỉ có một lượt chạy thì có ổn định không?". Cụ thể:

1. Chạy route ở chu kỳ suy ra từ slack, cộng thêm hai mức dự phòng, để xác định
   **Fmax R2R đã kiểm chứng** của từng lõi.
2. Chạy thêm vài directive ở 10 ns để có **dải dao động** của WNS R2R (phản biện ý "chỉ 1 lượt").
3. Đưa kết quả vào báo cáo theo quy tắc quyết định ở §7. Không sửa RTL.

## 2. Phạm vi

**Trong phạm vi**
- `posit_mac_f` (top PPA `tb/week13_fused_ppa_top.sv`) và `posit_mac_nf` (top PPA `tb/prepack_nf_ppa_top.sv`).
- Nguồn RTL theo `rtl/mac_active.f`, giữ nguyên từng byte.
- Part `xc7a35tcpg236-1`, Vivado 2026.1, OOC, `-max_dsp 0 -max_bram 0`, `general.maxThreads 4`,
  giống hệt recipe `syn/route_mac_100mhz.tcl`.

**Ngoài phạm vi**
- Sửa RTL, kể cả đăng ký `in_ready`.
- MAC-Quire (báo cáo đã ghi rõ là chưa đạt 100 MHz).
- Chạy lại `report_power`: công suất vẫn công bố ở 100 MHz như hiện tại.
- Sửa hoặc ghi đè `syn/route_mac_100mhz.tcl`, `syn/constraints/*.xdc` và mọi thư mục `results/` đã có.

## 3. Hiện trạng và mốc đối chiếu

| Lõi | Lượt route 10 ns hiện có | LUT / FF | WNS toàn TK | WNS R2R | Fmax R2R suy ra |
|---|---|---|---:|---:|---:|
| MAC-F (tách S1) | `results/f_s1_opt_20261113/c1a_split_only/vivado_f/` | 1.221 / 781 | +2,247 | +3,524 | 154,42 MHz → **6,476 ns** |
| MAC-NF (tách S1) | `results/f_s1_opt_20261113/c1a_split_only/vivado_nf/` | 1.591 / 916 | +0,669 | +2,639 | 135,85 MHz → **7,361 ns** |

RTL live khớp logic với phương án `c1a_split_only` và khớp từng byte với HEAD của
`.github-publish-Project`. Cách lấy số R2R chuẩn là các lệnh trong
`results/route_nf_f_internal_20261113/query_internal.tcl` (`REG2REG_CLK_SETUP`/`REG2REG_CLK_HOLD`).

**Lưu ý quan trọng về đường I/O.** Đường xấu nhất toàn thiết kế là đường tổ hợp tới cổng `in_ready`.
Ở 10 ns, đường này chỉ còn dư +2,247 ns (F) và +0,669 ns (NF). Nếu siết chu kỳ xuống 6,5 ns
mà giữ input/output delay 2,5/0,5 ns, đường này **chắc chắn âm khoảng 1 ns**. Vì vậy kết luận Fmax ở
plan này **chỉ dựa trên WNS R2R**, đúng cách Bảng 5.8 đang tách. WNS toàn thiết kế vẫn được ghi lại
nhưng không dùng để kết luận Fmax.

## 4. Các file cần tạo (không sửa file cũ)

| File mới | Nội dung |
|---|---|
| `syn/route_mac_fmax.tcl` | Bản sao của `syn/route_mac_100mhz.tcl` có tham số hóa. Xem §5.1. |
| `scripts/run_fmax_sweep.py` | Chạy ma trận §5.2, gom metrics, sinh `summary.md`, `summary.csv`, `manifest.json`. |
| `results/fmax_route_sweep_<YYYYMMDD>/` | Một thư mục con cho mỗi lượt chạy, đặt tên theo `<core>_<period>_<io>_<directive>`, ví dụ `f_6p500_A_Default/`. |

## 5. Các bước thực hiện

### 5.1 Viết `syn/route_mac_fmax.tcl`

Đối số: `variant period_ns io_mode directive`, ví dụ `-tclargs f 6.500 A Default`.

1. Giữ nguyên phần đọc `rtl/mac_active.f`, top PPA, `include_dirs`, part, `maxThreads 4`
   và các tùy chọn `synth_design`.
2. **Không đọc** `a35t_clock.xdc` hay `a35t_benchmark_100mhz.xdc`. Thay vào đó, tạo ràng buộc
   trong Tcl rồi ghi ra `constraints_used.xdc` trong thư mục lượt chạy để lưu vết:
   - `create_clock -name clk -period $period_ns [get_ports clk]`
   - `set_clock_uncertainty -setup 0.100` và `-hold 0.100` (giống hợp đồng A35T-C2)
   - `io_mode = A`: input delay max/min 2,500 ns, output delay max 0,500 / min 0,000 ns, tức
     **giữ nguyên giá trị tuyệt đối** của hợp đồng hiện tại. Đây là chế độ dùng để công bố.
   - `io_mode = B` (chỉ để chẩn đoán): không đặt input/output delay, chỉ có clock. Dùng để xem lõi
     có thay đổi khi bỏ áp lực từ đường I/O hay không. **Không công bố B làm Fmax.**
3. Thay kiểm tra clock cứng `PERIOD == 10.0` bằng kiểm tra `PERIOD == $period_ns` (sai số ≤ 1e-6).
   Nếu không khớp thì dừng bằng `error`.
4. Giữ nguyên chuỗi `opt_design → place_design -directive $directive → route_design -directive $directive`.
   Không thêm `phys_opt_design` (để so được với lượt 10 ns cũ).
5. Sau route, xuất **đủ** các report như recipe cũ (`route_timing.rpt`, `route_status.rpt`,
   `route_utilization.rpt`, `route_drc.rpt`, `routed.dcp`, `synthesis.dcp`, `effective_constraints_routed.xdc`).
   Xuất thêm `synth_metrics.txt` và `route_metrics.txt` theo **đúng định dạng** `dump_metrics` của
   `query_internal.tcl` (ALL_SETUP, ALL_HOLD, REG2REG_CLK_SETUP, REG2REG_ANY_SETUP, REG2REG_CLK_HOLD).
6. In dòng cuối `MAC_FMAX_ROUTE_COMPLETE variant=.. period_ns=.. io=.. directive=..`.

### 5.2 Ma trận chạy

Chạy theo thứ tự ưu tiên. Nếu thiếu thời gian, nhóm P1 là bắt buộc, P2 và P3 làm sau.

| Nhóm | Lõi | Chu kỳ (ns) | io_mode | Directive | Mục đích |
|---|---|---|---|---|---|
| P0 | F | 10.000 | A | Default | Kiểm tra script mới tái tạo đúng mốc cũ (TC-02) |
| **P1** | **F** | **6.500**, 6.800, 7.000 | A | Default | Xác nhận 154 MHz, kèm hai mức dự phòng |
| **P1** | **NF** | **7.400**, 7.700, 8.000 | A | Default | Xác nhận 135 MHz, kèm hai mức dự phòng |
| P2 | F, NF | 10.000 | A | Explore, ExtraTimingOpt | Dải dao động WNS R2R giữa các lượt (phản biện "chỉ 1 lượt", giải thích NF −0,30 ns) |
| P3 | F | mức nhỏ nhất bị fail ở P1 | A | Explore | Xem directive mạnh hơn có đóng được không |
| P3 | F | 6.500 | B | Default | Chẩn đoán: lõi khi bỏ áp lực I/O |

Lệnh mẫu (chạy trong thư mục lượt chạy, để log và `.Xil` nằm gọn bên trong):

```text
vivado -mode batch -nojournal -source <root>/syn/route_mac_fmax.tcl -tclargs f 6.500 A Default
```

### 5.3 Gom kết quả (`scripts/run_fmax_sweep.py`)

1. **Trước khi chạy**: tính SHA-256 của mọi file trong `rtl/mac_active.f`, `rtl/posit_mac.vh`,
   hai top PPA trong `tb/` và `syn/route_mac_fmax.tcl`. Ghi vào `source_sha256.json`.
2. Chạy từng lượt, ghi `execution.json` (lệnh, exit code, thời gian, phiên bản Vivado).
3. **Sau khi chạy**: tính lại SHA-256 các file ở bước 1. Phải trùng 100% (TC-01).
4. Đọc `route_metrics.txt`, `route_utilization.rpt`, `route_status.rpt` rồi sinh `summary.csv` với các cột:
   `core, period_ns, io_mode, directive, lut, ff, dsp, bram, wns_all, whs_all, wns_r2r, whs_r2r,
   r2r_levels, r2r_datapath_ns, r2r_start, r2r_end, unrouted_nets, pass_r2r`.
   `pass_r2r = (wns_r2r ≥ 0) AND (whs_r2r ≥ 0) AND (whs_all ≥ 0) AND (unrouted_nets = 0)`.
5. Sinh `summary.md` bằng tiếng Việt: bảng kết quả, Fmax R2R đã kiểm chứng của từng lõi theo §7,
   dải WNS R2R ở 10 ns (min/median/max qua 3 directive) và ghi chú rằng đường `in_ready` không dùng để kết luận.
6. Sinh `manifest.json` chứa SHA-256 của mọi report, checkpoint và log (cùng định dạng với
   `results/route_nf_f_20261112/manifest.json`).

## 6. Test cases (phải PASS toàn bộ thì mới coi là xong)

| ID | Kiểm tra | Điều kiện đạt |
|---|---|---|
| TC-01 Đóng băng RTL | SHA-256 nguồn trước và sau khi chạy | Trùng 100%; và các file RTL trùng với HEAD của `.github-publish-Project` |
| TC-02 Tái lập mốc cũ | P0: F, 10 ns, A, Default | LUT = 1.221, FF = 781, WNS R2R = +3,524 ns (sai lệch ≤ 0,005 ns), WNS toàn TK = +2,247 ns. Nếu không khớp thì **dừng**, tìm nguyên nhân (thread, phiên bản, thứ tự đọc file) trước khi chạy P1 |
| TC-03 Hợp đồng clock | Mỗi lượt | `constraints_used.xdc` có đúng period và uncertainty; kiểm tra PERIOD trong Tcl không báo lỗi; chỉ có một clock tên `clk` |
| TC-04 Route sạch | Mỗi lượt | `route_status.rpt`: 0 net chưa route, 0 lỗi định tuyến; `route_drc.rpt` không có lỗi mức Error |
| TC-05 Tài nguyên | Mỗi lượt | DSP = 0, BRAM = 0 |
| TC-06 Hold | Mỗi lượt dùng để kết luận | WHS toàn thiết kế ≥ 0 và WHS R2R ≥ 0 |
| TC-07 Đủ ma trận | Toàn bộ nhóm P1 | Có đủ 6 lượt, mỗi lượt có `route_metrics.txt` hợp lệ (không có dòng `EMPTY`) |
| TC-08 Bằng chứng | Thư mục kết quả | Có `source_sha256.json`, `manifest.json`, `summary.md`, `summary.csv`; mọi hash trong manifest khớp file thật |

## 7. Quy tắc quyết định và cách cập nhật báo cáo

**Định nghĩa.** *Fmax R2R đã kiểm chứng* của một lõi là `1000 / period` của **chu kỳ nhỏ nhất** trong
nhóm P1 (io_mode A) có `pass_r2r = true`.

| Kết quả P1 | Câu chữ trong báo cáo |
|---|---|
| F đạt ở 6,500 ns | "Fmax,R2R ≥ 153,8 MHz đã xác nhận bằng lượt route thực ở 6,5 ns (WNS R2R = +x ns)". Giữ 154,42 MHz làm con số ước lượng từ lượt 10 ns. |
| F chỉ đạt ở 6,8 hoặc 7,0 ns | Công bố mức đạt (147,1 hoặc 142,9 MHz) làm **Fmax R2R đã kiểm chứng**. Ghi 154,42 MHz là "ước lượng tuyến tính từ slack ở 10 ns". |
| F không đạt cả ba mức | Giữ 154,42 MHz nhưng ghi rõ "ước lượng, chưa đạt khi route ở 7,0 ns". Báo cáo WNS R2R thật ở 7,0 ns. Chạy P3 Explore. |
| NF | Áp dụng cùng quy tắc với các mức 7,4 / 7,7 / 8,0 ns. |

**Các vị trí cần cập nhật** (chỉ thay số và câu chữ, không đổi cấu trúc):
- Tóm tắt và Abstract: con số Fmax R2R, thêm "đã kiểm chứng bằng route ở x ns".
- §1.3 (iii), §1.7 (sửa câu "đóng định thời 100 MHz" thành chỉ áp dụng cho MAC-NF/F), §3.4.1.
- Bảng 5.8: thêm các hàng "Route @ x ns" cho F và NF. Thêm một dòng ghi chú về dải WNS R2R qua 3 directive ở 10 ns (từ P2).
- Bảng 5.4 và Bảng 5.9: tính lại thời gian thực và thông lượng theo **Fmax đã kiểm chứng**.
  Công thức không đổi: thông lượng = f / chu kỳ, thời gian = chu kỳ / f. Cột công suất và Edyn giữ nguyên (đo ở 100 MHz).
- §5.7.2: thay câu "+0,756 ns gắn trực tiếp với việc giải tỏa S1" bằng câu có dải dao động từ P2, ví dụ
  "cải thiện +0,756 ns ở lượt Default; dải WNS R2R qua 3 directive là [a, b] ns".
- §6.1 và Bảng 6.1: đồng bộ các con số.
- Bảng 5.10: cột tần số của MAC-F và MAC-NF.

Chỉ thay số trong báo cáo khi TC-01..TC-08 đều PASS. Nếu TC-02 không tái lập được mốc cũ thì
không công bố kết quả P1 cho tới khi tìm ra nguyên nhân.

## 8. Tiêu chí hoàn thành

1. TC-01..TC-08 PASS và được ghi trong `summary.md`.
2. Có giá trị *Fmax R2R đã kiểm chứng* cho cả MAC-F và MAC-NF, kèm chu kỳ, WNS/WHS R2R và đường găng.
3. Có dải WNS R2R ở 10 ns qua 3 directive cho cả hai lõi.
4. Không có file nào trong `rtl/`, `syn/constraints/` hay các thư mục `results/` cũ bị thay đổi
   (đối chiếu bằng SHA-256).
5. Báo cáo LaTeX được cập nhật theo §7 và biên dịch lại không lỗi.

## 9. Ước lượng thời gian

Thiết kế chỉ khoảng 1,2–1,6 nghìn LUT nên mỗi lượt synth + route mất khoảng 3–6 phút.
P0 + P1 = 7 lượt, khoảng 30–45 phút. P2 + P3 thêm khoảng 6 lượt, khoảng 30 phút.
