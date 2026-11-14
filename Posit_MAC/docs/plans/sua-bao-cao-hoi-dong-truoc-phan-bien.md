# Plan: Sửa bản thảo báo cáo hội đồng trước buổi phản biện

Ngày lập: 14/11/2026 · Người thực hiện: Codex/Gemini theo plan này · Người duyệt: Đan Huy

## 1. Mục tiêu (usecase)

Bản thảo hội đồng (`doc/Posit_MAC_LaTeX/council.tex` và `council/*.tex`) đã đúng về kỹ thuật và
khớp với RTL đóng băng. Tuy vậy, buổi review ngày 14/11 chỉ ra một số chỗ dễ bị hội đồng bắt bẻ.
Các chỗ này nằm ở **cách diễn giải và đối chứng**, không nằm ở thiết kế. Plan này liệt kê từng chỗ
cần sửa, vị trí trong nguồn LaTeX, nội dung đề xuất và cách kiểm tra.

Kết quả mong muốn là một bản PDF mới mà:
- không còn câu nào tuyên bố mạnh hơn số liệu của chính báo cáo;
- mọi con số Fmax, thông lượng và thời gian thực đều nhất quán với lượt route thực ngày 14/11
  (`Posit_MAC/results/fmax_route_sweep_20261114/`);
- các lỗi nhỏ về định dạng và trích dẫn đã được sửa.

## 2. Phạm vi

**Trong phạm vi:** chỉ sửa câu chữ, số liệu và chú thích trong:
- `doc/Posit_MAC_LaTeX/council.tex`
- `doc/Posit_MAC_LaTeX/council/*.tex`
- `doc/Posit_MAC_LaTeX/council/tables/*.tex`

**Ngoài phạm vi:**
- Không sửa RTL, testbench, script đo hay bất kỳ thư mục `results/` nào.
- Không chạy thêm phép đo mới. Mục 4.4 là việc tùy chọn, chỉ làm nếu còn thời gian.
- Không đổi cấu trúc chương, không thêm hoặc bớt hình.

## 3. Hiện trạng trước khi sửa (đã kiểm ngày 14/11, 22:30)

Kết quả sweep Fmax đã PASS TC-01..TC-08 và **đã được đưa phần lớn vào LaTeX**
(Tóm tắt, Abstract, §1.3, §1.7, §3.4.1, Bảng 5.4, 5.8, 5.9, 5.10, §5.7.2, §6.1).
Các số dưới đây là mốc chuẩn để đối chiếu khi sửa:

| Đại lượng | MAC-F | MAC-NF | Nguồn |
|---|---:|---:|---|
| Fmax R2R đã kiểm chứng | ≥ 153,85 MHz (route 6,5 ns, WNS R2R +0,632) | ≥ 135,14 MHz (route 7,4 ns, WNS R2R +0,209) | `fmax_route_sweep_20261114/summary.csv` |
| Fmax toàn thiết kế đã route thực | **≥ 142,86 MHz** (route 7,0 ns, WNS toàn TK +0,045) | 100 MHz (8,0 ns: −0,074; 10 ns: +0,669) | như trên, io_mode A |
| Dải WNS R2R ở 10 ns qua 3 directive | +3,184 … +3,524 ns | +2,639 … +2,994 ns | nhóm P2 |
| WNS R2R ở 10 ns **trước** tách S1 | +2,768 ns (1 lượt Default) | +2,943 ns | `route_nf_f_internal_20261113` |
| Thông lượng tại Fmax kiểm chứng | 6,15–10,99 (TB 8,53) M MAC/s | 4,83–7,95 (TB 6,43) | 153,85/chu kỳ; 135,14/chu kỳ |
| Chuỗi 1.024 MAC | ≈ 119,9–120,1 µs | ≈ 159,2–159,5 µs | Bảng 5.4 tính lại |
| Quire / F (chuỗi 1.024) | **≈ 3,57×** | NF / F ≈ 1,33× | như trên |

Xilinx FP32 (180 / 191 / 195 MHz) vẫn là **Fmax suy ra** bằng `1000/(10 − WNS_R2R)` từ lượt 10 ns
(`results/fpga_power_and_fp32/*_metrics.txt`), chưa có lượt route thực ở chu kỳ tương ứng.

## 4. Danh sách việc cần sửa

Mức ưu tiên: **P1** = nhiều khả năng bị hỏi hoặc trừ điểm; **P2** = nên sửa; **P3** = lỗi nhỏ.

### 4.1 Hoàn tất cập nhật Fmax (P1, việc còn sót)

| ID | Vị trí | Hiện tại | Sửa thành |
|---|---|---|---|
| F-1 | `council/06.tex:81` (Bảng 6.1, ô MAC-Quire) | "Chậm hơn 3,55–3,64× về thời gian thực tại 1.024 MAC" | "Chậm hơn ≈ 3,57× …" (khớp với Tóm tắt, vốn đã ghi 3,57×) |
| F-2 | Tóm tắt (`council.tex:46-47`), Abstract (`council.tex:92`), `council/01.tex:80-81`, `council/05.tex:272`, `council/05_analysis.tex:155`, `council/06.tex:18,78`, `council/tables/literature_comparison.tex:12` | MAC-F "toàn thiết kế 129,0 MHz" (ước lượng từ lượt 10 ns) | Thêm số đã route thực: "toàn thiết kế ≥ 142,9 MHz (route 7,0 ns, WNS +0,045 ns, ngân sách I/O 2,5/0,5 ns)". Giữ 129,0 MHz trong ngoặc như ước lượng ở 10 ns nếu muốn. MAC-NF giữ "107,2 MHz (ước lượng tại 10 ns)" và thêm "chưa đạt ở 8,0 ns". |
| F-3 | `council/05_analysis.tex` khoảng dòng 165-175 (đoạn sau "Như vậy") | Chưa so sánh trực tiếp trước và sau tách S1 bằng dải directive | Thêm một câu: "Ngay cả ở directive kém nhất, WNS R2R của MAC-F sau tách S1 (+3,184 ns) vẫn cao hơn lượt Default trước tách (+2,768 ns) là +0,416 ns, lớn hơn biên độ dao động giữa các directive (≈ 0,34 ns)." Thêm "chỉ có một lượt trước tách" để trung thực. |
| F-4 | `council/05.tex:276,284`, `council/06.tex:20` | Cụm "ép xung" | Đổi thành "quét chu kỳ ràng buộc" hoặc "siết ràng buộc clock". "Ép xung" (overclock) là chạy chip vượt định mức, không phải đặt ràng buộc STA. |
| F-5 | Bảng 5.9 (`council/tables/fpga_power_throughput.tex`) và Bảng 5.10 | Fmax Xilinx 180/191/195 MHz không ghi phương pháp | Thêm chú thích: "Fmax Xilinx suy ra từ WNS R2R ở lượt 10 ns, chưa route thực ở chu kỳ tương ứng; Fmax MAC-F/NF đã route thực." Như vậy thông lượng Xilinx là cận lạc quan, phép so sánh vẫn công bằng về phía Xilinx. |

### 4.2 Diễn giải và đối chứng (P1)

| ID | Vị trí | Vấn đề | Cách sửa |
|---|---|---|---|
| D-1 | Tóm tắt `council.tex:51-54`, Abstract `council.tex:97-101`, `council/05.tex` khoảng dòng 330-345 (gạch đầu dòng "So sánh khách quan với IP Xilinx FP32"), `council/06.tex` gạch đầu dòng đầu tiên | Chỉ nêu mặt lợi ("tiết kiệm FF/DSP", "bám sát 8,53 vs 8,88"). Không nói MAC-F dùng **nhiều LUT hơn** Xilinx (1.221 so với 765–993), tốn năng lượng/MAC gấp khoảng 3 lần, và SNR FIR kém FP32 66 dB | Thêm một câu cân bằng, ví dụ: "Đổi lại, MAC-F dùng nhiều LUT hơn (1.221 so với 765–993), năng lượng động/MAC cao hơn khoảng 3× (0,721 so với 0,21–0,25 nJ) và độ chính xác thấp hơn FP32 (SNR FIR 72,5 so với 138,9 dB); ưu thế của MAC-F là 0 DSP, ít FF và dải động 2^±240." |
| D-2 | Cùng các vị trí của D-1 | Phép so "8,53 vs 8,88 M MAC/s" chỉ đúng khi Xilinx chạy **đúng một** chuỗi phụ thuộc | Thêm vế: "khi chỉ có một chuỗi phụ thuộc; nếu xen kẽ nhiều chuỗi độc lập (ví dụ nhiều đầu ra FIR), Xilinx lấy lại II = 1." |
| D-3 | Tóm tắt `council.tex:39-41`, Abstract `council.tex:85-86`, `council/05.tex:184-200`, `council/06.tex:53`, Bảng 6.1 hàng "Bài toán ứng dụng" | DynScale (10^-45–10^43) và Cancel (±10^45) có dữ liệu **nằm ngoài dải FP32 ngay từ đầu vào**, nên việc FP32 lỗi là hiển nhiên | (a) Ở `council/05.tex` thêm câu: "Hai kịch bản này được dựng có chủ đích với biên độ vượt dải FP32 để minh họa dải động; chúng không đại diện cho dữ liệu DSP/NN thông thường." (b) Ở Tóm tắt và Abstract: bỏ câu DynScale khỏi câu chốt, hoặc giữ nhưng thêm "(kịch bản dựng ngoài dải FP32)". |
| D-4 | `council/05.tex` khoảng dòng 90-115 (đoạn lớp `regular`) và `council/06.tex` Bảng 6.1 hàng "Sai số ghép cặp" | Câu "MAC-F vượt trội trên 12.691/12.693 mẫu, NF sai tới 2^240" đến từ các ca C = R(−P) khi \|P\| nằm ngoài dải Posit, tức ca biên do cách dựng tập thử | Thêm câu: "Lớp regular chỉ xuất hiện khi \|P\| vượt dải biểu diễn nên R(−P) bị kẹp; đây là ca biên do cách dựng tập thử. Trên dữ liệu thông thường, NF và F gần như tương đương (§5.2)." Ở Bảng 6.1, đổi "tránh sai lệch kẹp ngưỡng" thành "tránh sai lệch kẹp ngưỡng ở ca biên". |
| D-5 | `council/04.tex:86-87` | "độ trễ quan sát 15–26 (NF) và 12–23 (F)" mâu thuẫn với §3.5 và Hình 4.2: out_valid ở 12 + max(1,t), tức 13–24 (F) và 16–27 (NF). Lệch đúng 1 chu kỳ | **Trước khi sửa**, mở script ModelSim tập con 1.500 vector (`Posit_MAC/results/modelsim_subset_cov_20261113/run_modelsim_subset_cov.py` và testbench nó gọi) để xác định cách đếm `latency_observed`. Sau đó chọn một trong hai: (a) thêm định nghĩa, ví dụ "đếm số chu kỳ *giữa* cạnh accept và cạnh out_valid, không tính cạnh accept"; hoặc (b) đổi số sang quy ước §3.5 (13–24 và 16–27). Không đổi số khi chưa xác nhận cách đếm. |

### 4.3 Độ chính xác câu chữ và định dạng (P2–P3)

| ID | Vị trí | Hiện tại | Sửa thành |
|---|---|---|---|
| M-1 (P2) | Abstract `council.tex:70-79, 87, 95` | Số trong chế độ math dạng `$100,867$`, `$1,634,048$`, `$1,221$`, `$1,024$`… hiển thị thành "100, 867" | Đổi thành `$100{,}867$` (hoặc viết ngoài chế độ math). Rà toàn bộ Abstract bằng regex `\$[0-9]+,[0-9]{3}` cho tới khi không còn kết quả |
| M-2 (P2) | Tóm tắt `council.tex:26` | "chuẩn Norris--Kim" | "số liệu công bố của Norris--Kim" (bài báo không phải chuẩn) |
| M-3 (P2) | `council/02.tex:70-71` | "tương đương độ chính xác phần định trị của FP16 10 bit hoặc BFloat16 7 bit" | "tương đương độ chính xác phần định trị của FP16 (10 bit); BF16 (7 bit, ≈ 2^-8) còn kém hơn" |
| M-4 (P2) | `council/05.tex:337` | "21–25 mW (5,25–6,25× của MAC-F)" | "21–25 mW (khoảng 5–7× của MAC-F, tính cả độ phân giải ±0,5 mW)" |
| M-5 (P3) | `council/appendices.tex:38` | `\path{rtl/quire/}` | `\path{rtl/mac_quire/}` |
| M-6 (P3) | Phần "Thuật toán, ký hiệu và từ viết tắt" (`council/frontmatter.tex`) | Thiếu nghĩa các thuật ngữ tiếng Anh dùng nhiều | Thêm: retire, commit, token, stall, corpus, waiver, R2R, TK (toàn thiết kế) |

### 4.4 Tùy chọn, chỉ làm nếu còn thời gian

- Route thực Xilinx FP32 ở khoảng 5,2 ns để Fmax hai bên cùng phương pháp. Nếu làm, tách thành một plan đo riêng như `xac-nhan-fmax-sau-route.md`.

## 5. Các bước thực hiện

1. Sao lưu: nén `doc/Posit_MAC_LaTeX/council.tex`, `council/` và PDF hiện tại thành
   `doc/Posit_MAC_LaTeX/.build/backup_truoc_sua_<YYYYMMDD_HHMM>.zip`.
2. Sửa theo thứ tự: 4.1 → 4.2 → 4.3. Mỗi ID sửa xong thì ghi ✔ vào checklist ở §8.
3. Với D-5, đọc script và testbench trước, ghi kết luận về cách đếm vào checklist, rồi mới sửa.
4. Biên dịch lại `council.tex` theo đúng lệnh trong `doc/Posit_MAC_LaTeX/README.md`
   (chạy đủ số lượt để cập nhật mục lục và tham chiếu chéo).
5. Chạy các kiểm tra ở §6 và lưu kết quả vào `doc/Posit_MAC_LaTeX/.build/kiem_tra_sua_<YYYYMMDD>.txt`.
6. Xuất PDF mới với tên `doc/Ban_thao_hoi_dong_Posit_MAC_<YYYYMMDD>_final.pdf`. Không ghi đè bản 14/11.

## 6. Test cases (phải PASS toàn bộ)

| ID | Kiểm tra | Điều kiện đạt |
|---|---|---|
| TC-01 Biên dịch | Biên dịch `council.tex` | Exit 0; log không có `Undefined reference`, `Citation ... undefined` hay `There were undefined references` |
| TC-02 Hết số Fmax cũ | `grep -nE "3\{,\}55\|3\{,\}64\|8\{,\}56\|ép xung"` trên `council.tex council/*.tex council/tables/*.tex` | Không còn kết quả. Riêng `154{,}42` và `129{,}0` chỉ được xuất hiện cùng chữ "ước lượng" trên cùng câu (kiểm bằng mắt từng chỗ) |
| TC-03 Số trong Abstract | Regex `\$[0-9]+,[0-9]{3}` trên `council.tex` | Không còn kết quả |
| TC-04 Nhất quán số liệu | Đối chiếu bảng §3 với Tóm tắt, Abstract, Bảng 5.4, 5.8, 5.9, 5.10, 6.1 | Mọi giá trị Fmax, thông lượng, thời gian chuỗi và tỉ số 3,57× / 1,33× khớp bảng §3 (làm tròn 3 chữ số có nghĩa) |
| TC-05 Câu cân bằng | Đọc Tóm tắt, Abstract, §5.3.1, §6.1 | Mỗi chỗ đều nêu rõ MAC-F dùng nhiều LUT hơn Xilinx, năng lượng/MAC cao hơn và độ chính xác thấp hơn FP32 (D-1), và có điều kiện "một chuỗi phụ thuộc" (D-2) |
| TC-06 Kịch bản dựng | Đọc §5.2, Tóm tắt, Abstract | DynScale/Cancel được ghi rõ là kịch bản dựng ngoài dải FP32 (D-3) |
| TC-07 Latency | Đọc §3.5, Hình 4.2, §4.2 | Không còn mâu thuẫn 1 chu kỳ; nếu giữ hai quy ước thì có câu định nghĩa rõ (D-5) |
| TC-08 Không đụng file ngoài phạm vi | SHA-256 của `Posit_MAC/rtl/`, `Posit_MAC/tb/`, `Posit_MAC/results/` trước và sau | Trùng 100% |
| TC-09 Chất lượng PDF | Mở PDF mới, xem các trang có bảng 2.6, 5.3, 5.13, B.1 và Abstract | Không vỡ bảng, không tràn lề, số hiển thị đúng định dạng |

## 7. Tiêu chí hoàn thành

1. Mọi ID trong §4.1–§4.3 đã được xử lý và đánh dấu ở §8 (hoặc ghi rõ lý do nếu giữ nguyên).
2. TC-01..TC-09 PASS và được ghi vào file kiểm tra ở bước 5.
3. Có PDF mới cùng bản sao lưu bản cũ.

## 8. Checklist theo dõi

| ID | Trạng thái | Ghi chú |
|---|---|---|
| F-1 | ✔ | Đã sửa Bảng 6.1 (`council/06.tex`): `3,55--3,64\times` -> `\approx 3,57\times`. |
| F-2 | ✔ | Đã đồng bộ `Fmax` toàn thiết kế đóng thực (`>= 142,9 MHz` / `142,86 MHz` @ `7,0 ns`, `WNS=+0,045 ns` cho MAC-F; `100 MHz`, lỗi `8,0 ns` `-0,074 ns` cho MAC-NF) và đánh dấu `129,0` / `154,42 MHz` là ước lượng `10 ns` ở Tóm tắt, Abstract, §1, Bảng 5.8, §5.3, §5.7, §6.1, Bảng 5.10, Bảng 6.1. |
| F-3 | ✔ | Đã bổ sung giải thích ở `council/05_analysis.tex`: `+3,184 ns` vẫn hơn lượt `Default` trước tách (`+2,768 ns`, chỉ có 1 lượt trước tách) là `+0,416 ns` (> biên độ dao động `~0,34 ns`). |
| F-4 | ✔ | Đã đổi toàn bộ cụm "ép xung" sang "quét chu kỳ ràng buộc" / "siết chu kỳ ràng buộc" / "siết ràng buộc clock" (`01_scope`, `05`, `05_analysis`, `06`). |
| F-5 | ✔ | Đã thêm chú thích ở Bảng 5.9, Bảng 5.10 và `council/05.tex` nêu rõ `180/191/195 MHz` của Xilinx FP32 suy ra tuyến tính từ `WNS_R2R` lượt `10 ns`, chưa route thực ở chu kỳ tương ứng. |
| D-1 | ✔ | Đã bổ sung câu cân bằng đánh đổi ở Tóm tắt, Abstract, §5.3.1, §6.1 và Bảng 6.1 (nhiều LUT hơn `1.221 vs 765-993`, năng lượng động/MAC ~3x `0,721 vs 0,210-0,250 nJ`, SNR FIR `72,5 vs 138,9 dB` đổi lấy `0 DSP`, ít `FF`, dải `2^{±240}`). |
| D-2 | ✔ | Đã bổ sung điều kiện phép so `8,53 vs 8,88 M MAC/s` chỉ đúng trên một chuỗi phụ thuộc đơn lẻ; xen kẽ nhiều chuỗi độc lập trả lại `II=1` cho Xilinx. |
| D-3 | ✔ | Đã ghi rõ `DynScale` (`10^{-45}..10^{43}`) và `Cancel` là kịch bản dựng có chủ đích ngoài dải FP32 ở `05.tex`, `06.tex`, Bảng 6.1, Tóm tắt và Abstract. |
| D-4 | ✔ | Đã giải thích lớp `regular` trong `C=R(-P)` là ca biên khi `|P|` vượt dải nên `R(-P)` bị kẹp; cập nhật Bảng 6.1 thành "ở ca biên trên nhánh `R(-P)`". |
| D-5 | ✔ | Cách đếm `latency_observed` (đã đọc `tb/tb_refactored_mac.sv` dòng 104-122 & `vsim_base_{f,nf}.log`): TB khởi tạo `latency=0` ở `@(negedge clk)` ngay sau `@(posedge clk)` accept và cộng dồn đến khi `out_valid===1`, tức đếm số chu kỳ *giữa* accept và out_valid (không tính cạnh accept), giải thích độ lệch đúng 1 chu kỳ (`15–26` NF / `12–23` F vs `16–27` / `13–24`). Đã thêm định nghĩa vào `council/04.tex`. |
| M-1 | ✔ | Đã chuyển toàn bộ số hàng nghìn/triệu trong chế độ math ở Abstract (`council.tex`) sang `{,}` (regex `\$[0-9]+,[0-9]{3}` còn 0 kết quả). |
| M-2 | ✔ | Đã đổi "chuẩn Norris--Kim" thành "số liệu công bố của Norris--Kim" (`council.tex`). |
| M-3 | ✔ | Đã sửa `council/02.tex`: `FP16` (10 bit) tương đương còn `BF16` (7 bit, `\approx 2^{-8}`) kém hơn rõ rệt. |
| M-4 | ✔ | Đã sửa `council/05.tex`: `21–25 mW` là `khoảng 5–7x` của `MAC-F` (tính cả độ phân giải `±0,5 mW`). |
| M-5 | ✔ | Đã sửa `\path{rtl/quire/}` -> `\path{rtl/mac_quire/}` trong `council/appendices.tex`. |
| M-6 | ✔ | Đã bổ sung `R2R`, `TK`, `retire`, `commit`, `token`, `stall`, `corpus`, `waiver` vào mục Thuật toán, ký hiệu và từ viết tắt (`council.tex:144-152`). |

## 9. Ghi chú cho buổi phản biện (không phải việc sửa file)

Hai câu hỏi sau không sửa được bằng câu chữ. Sinh viên nên chuẩn bị câu trả lời miệng:

- **"Tham số n có tạo ra đánh đổi hữu ích không? Sao không so với bộ nhân chính xác dùng DSP?"**
  Bảng 5.1 cho thấy giảm từ n = 12 xuống n = 6 chỉ bớt khoảng 1% chu kỳ. Nên trả lời rằng n là
  cơ chế giới hạn trần độ trễ (ca xấu nhất 25 → 19–21 chu kỳ), không phải để giảm trung bình;
  và thừa nhận baseline bộ nhân chính xác 13×13 là hướng mở rộng.
- **"Vivado có `phys_opt_design` và `MAX_FANOUT`, sao phải tách fanout bằng tay?"**
  Nên trả lời rằng cách tách tay giữ nguyên netlist giữa các lượt, nên so sánh trước/sau sạch hơn;
  và thừa nhận chưa đối chứng với `phys_opt_design` (đã ghi ở §6.2).
