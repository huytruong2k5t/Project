# Cẩm nang Phản biện Hội đồng Đồ án 2: Posit(32,3) MAC IP (`MAC-F`)

> **Mục tiêu tài liệu:** Tổng hợp sẵn các câu hỏi phản biện sắc bén nhất mà Hội đồng chấm Đồ án 2 có thể đặt ra (nhóm câu hỏi trọng tâm A1--A7 và B1--B5), kèm dẫn chứng định lượng, vị trí bảng/mục tương ứng trong quyển báo cáo và câu trả lời mẫu ngắn gọn, trung thực, khoa học.

---

## A1. Lõi lặp tuần tự (II = 14--25) chỉ đạt 8,56 M MAC/s và LUT×ns/MAC kém IP Xilinx FP32 II=1 hơn 28 lần — vậy thiết kế MAC-F có ý nghĩa thực tế ở đâu?

- **Vị trí dẫn chứng trong báo cáo:** *Tóm tắt đồ án*, Mục *5.3.1*, *Bảng 5.9* (`tab:fpga-power-throughput`) và *Bảng 5.10* (`tab:literature-comparison`).
- **Số liệu chuẩn cần nắm:**
  - `MAC-F` (`xc7a35tcpg236-1`): **1.221 LUT, 781 FF, 0 DSP**, $F_{\max,\mathrm{R2R}} = 154{,}42$\,MHz, $II \in [14, 25]$ (trung bình $18{,}0$ chu kỳ tại `OPS1/n12`), thông lượng $6{,}18\text{--}11{,}0$\,M\,MAC/s (TB **$8{,}56$\,M\,MAC/s**), $P_{\mathrm{dyn}} = 4$\,mW ($P_{\mathrm{tot}} = 72$\,mW tại 100\,MHz \textit{vectorless}, độ phân giải $\pm 0{,}5$\,mW), $E_{\mathrm{dyn}}/\mathrm{MAC} = 0{,}721$\,nJ, chỉ số $\mathrm{LUT}\times\mathrm{ns}/\mathrm{MAC} = 1{,}43{\times}10^5$.
  - `Xilinx FP32 0-DSP`: **993 LUT, 1.520 FF, 0 DSP**, $195$\,MHz, $II=1$, Latency $= 22$ chu kỳ, $P_{\mathrm{dyn}} = 22$\,mW, $E_{\mathrm{dyn}}/\mathrm{MAC} = 0{,}220$\,nJ (trên luồng độc lập).
- **Cách trả lời Hội đồng (2 ý súc tích):**
  1. **Thừa nhận thẳng sự đánh đổi:** Đúng là trên luồng dữ liệu hoàn toàn độc lập (*streaming $II=1$*), đường ống `Xilinx FP32` vượt trội về thông lượng đỉnh ($195$ vs $8{,}56$\,M\,MAC/s) và năng lượng/MAC ($0{,}220$ vs $0{,}721$\,nJ); đó là cái giá vật lý tất yếu khi chọn bộ nhân lặp dịch--cộng để loại bỏ hoàn toàn `DSP48E1` và giữ thanh ghi ít.
  2. **Chỉ rõ 3 tình huống `MAC-F` thắng hoặc ngang ngửa:**
     - **Tích lũy chuỗi phụ thuộc vòng lặp ($C_{i+1}=D_i$, e.g., IIR hoặc tích vô hướng tuần tự):** `Xilinx FP32` phải chờ hết độ trễ 17--22 chu kỳ mới nạp được phép kế tiếp nên thông lượng thực dụng rơi xuống **$8{,}88$\,M\,MAC/s** (`0-DSP`), ngang bằng mức $8{,}56$\,M\,MAC/s của `MAC-F`, trong khi `MAC-F` dùng **ít hơn $48{,}6\%$ FF** ($781$ vs $1.520$) và công suất động thấp hơn ($4$ vs $22$\,mW tại 100\,MHz).
     - **Bài toán dải động siêu rộng $2^{\pm 240}$ (`DynScale`, $10^{-45}\text{--}10^{43}$):** Mọi cấu hình `FP32` tràn/lỗi `100/200` mẫu, `FP16/BF16` hỏng `200/200` mẫu, còn `Posit(32,3)` giữ `0/200` lỗi.
     - **Hệ thống biên giới hạn tài nguyên FF/DSP nghiêm ngặt** (hoặc triển khai song hành nhiều lõi nhỏ trong vùng 1.2k LUT / <800 FF mà không đụng ngân sách DSP).

---

## A2. Vì sao độ phủ thô chỉ ~88--92% mà tuyên bố 100% nhánh? Và vì sao đặt pipeline co giãn bên trong nếu wrapper khóa single-outstanding?

- **Vị trí dẫn chứng trong báo cáo:** *Mục 3.1.1* (`subsec:single-outstanding`), *Mục 4.2* và *Bảng 4.3* (`tab:coverage-waivers`).
- **Số liệu chuẩn cần nắm:**
  - Trên toàn lõi `MAC-F`: thô **$90{,}91\%$ dòng / $88{,}89\%$ nhánh / $93{,}03\%$ toggle**; sau loại trừ có chứng cứ **8 nhánh backpressure nội bộ**, đạt **$96{,}30\%$ dòng / $100\%$ nhánh** (và ở `MAC-NF`: thô $91{,}98\% / 88{,}37\% / 93{,}63\%$, sau rà soát 10 waiver đạt $98{,}03\% / 100\%$).
  - Bài thử co giãn $II=1$ độc lập trên chuỗi `posit_parser_mul -> posit_add -> posit_pack` (`20.000` vectơ, $15.079$ chu kỳ nạp liên tiếp không khe, $14.328$ chu kỳ kẹt ngược `out_ready=0` khi `out_valid=1`): **`0` sai lệch**, không biến đổi ngõ ra khi kẹt, và **`100%` nhánh rẽ** của cả 3 khối đều được kích hoạt ($10/10$, $24/24$, $10/10$).
- **Cách trả lời Hội đồng:**
  1. **Về kiến trúc:** Bộ nhân lặp `mul_iter_core` là máy trạng thái tuần tự phi đường ống ($1\text{--}12$ chu kỳ), đồng thời bài toán tích lũy $S_i = S_{i-1} + A_i B_i$ mang phụ thuộc dữ liệu nối tiếp giữa các bước; do đó wrapper IP chủ động khóa cơ chế `single-outstanding` để khỏi tốn hàng trăm bit thanh ghi đệm ngữ cảnh. Khi đó, các nhánh `else if (!ready)` bên trong `Parser`, `Adder` và `Packer` thực chất trở nên **bất khả đạt** ở cấp wrapper -- nên được ghi danh sách *waiver* minh bạch.
  2. **Về tái sử dụng và bằng chứng thực:** Lý do giữ giao thức `valid/ready` đầy đủ trong 3 khối con là để tái sử dụng ở các thiết kế đường ống *multi-outstanding* về sau; và luận điểm này đã được chứng minh bằng bài test `Verilator` đứng riêng ($20.000$ vectơ $II=1$ + ép kẹt luồng đạt **100% nhánh rẽ**, `0` lỗi).

---

## A3. Tại sao chọn cấu hình mặc định `n=12`? Ở `n=8`, P95 sai số đã tiệm cận giới hạn cắt 12 bit — có thực sự cần 12 vòng không?

- **Vị trí dẫn chứng trong báo cáo:** *Mục 5.1.1* và *Bảng 5.1* (`tab:prepack`).
- **Số liệu chuẩn cần nắm (nhóm $100.000$ cặp `OPS1` lấy mẫu đều):**
  - Tại $n=8$: `Vòng TB = 5,02`, `Chu kỳ F TB = 18,02`, $E_{\text{tổng}}\,\mathrm{P95} = 0{,}0299\%$, $E_{\text{tổng}}\,\max = 0{,}156\%$ (còn $554$ mẫu rơi vòng).
  - Tại $n=12$: `Vòng TB = 5,03`, `Chu kỳ F TB = 18,03`, $E_{\text{tổng}}\,\mathrm{P95} = 0{,}0297\%$, $E_{\text{tổng}}\,\max = \mathbf{0{,}0460\%}$ (giảm **$3{,}39\times$** đỉnh sai số cực đại, còn $0$ mẫu rơi vòng).
- **Cách trả lời Hội đồng:**
  - Nhờ hai cơ chế **chọn ít bit 1 (`OPS=1`)** và **tự động dừng sớm (`early-stop`)**, trên dữ liệu thông thường việc nâng trần từ $n=8$ lên $n=12$ **hầu như không tốn thêm chu kỳ trung bình** (chỉ tăng $+0{,}01$ chu kỳ từ $18{,}02$ lên $18{,}03$), nhưng lại **triệt tiêu hoàn toàn sai số cắt vòng lặp** và giảm đỉnh sai số xấu nhất đi $3{,}39$ lần.
  - Vì vậy đồ án chọn `OPS1/n12` làm mặc định an toàn độ chính xác, đồng thời giữ cổng cấu hình `cfg_n` linh hoạt để người dùng hạ xuống `n=6..8` nếu gặp dữ liệu mật độ bit 1 dày đặc cần khống chế trần độ trễ xấu nhất (từ 25 xuống 19--21 chu kỳ).

---

## A4. Trên bài toán thật (FIR, mạng NN), `MAC-F`, `MAC-NF` và `MAC-Quire` đều ra cùng kết quả `72,5 dB` và `5,66e-4`. Vậy thiết kế `MAC-F` hay `MAC-Quire` có ích gì?

- **Vị trí dẫn chứng trong báo cáo:** *Mục 5.2* (`sec:app-benchmarks`) và *Bảng 5.5* (`tab:app-benchmarks`).
- **Số liệu chuẩn cần nắm:**
  - FIR 32 tap: `FP32` = $138{,}9$\,dB, **`MAC-F/NF/Quire` = $72{,}5$\,dB**, `FP16` = $62{,}2$\,dB, `BF16` = $44{,}1$\,dB.
  - NN-128 P95: `FP32` = $1{,}32{\times}10^{-6}$, **`MAC-F/NF/Quire` = $5{,}66{\times}10^{-4}$**, `FP16` = $7{,}01{\times}10^{-3}$, `BF16` = $5{,}74{\times}10^{-2}$.
- **Cách trả lời Hội đồng:**
  1. **Giải thích bản chất:** Trong bài toán FIR và `NN-128` chuẩn hóa, các số hạng cùng thang bậc $|C| \sim |AB|$, nên nguồn nhiễu chính là **bước cắt fraction 12 bit của bộ nhân xấp xỉ ($\approx 12$ bit hữu hiệu)** chứ không phải bước cộng/đóng gói 26 bit — vì thế cả ba lõi Posit hội tụ về cùng $72{,}5$\,dB (vượt **`FP16` $+10{,}3$\,dB** và vượt **`BF16` $+28{,}4$\,dB**).
  2. **Giá trị riêng của `MAC-F` trên các bài toán đó:** Dù cùng SNR, `MAC-F` hoàn thành mỗi mẫu FIR nhanh hơn (`3,74 us` vs `4,95 us` của `MAC-NF` và `14,0 us` của `MAC-Quire`), tốn ít hơn **$23{,}3\%$ LUT, $14{,}7\%$ FF, $3\times$ công suất động**, và bảo vệ hoàn toàn các mẫu tiệm cận biên kẹp (`Cancel regular`). Còn **`MAC-Quire`** chứng tỏ giá trị bắt buộc ở bài toán **`Cancel`** và chuỗi triệt tiêu dài ($7{,}73{\times}10^{-4}$ và $1{,}73{\times}10^{-8}$).

---

## A5. Tại sao trong `23.938` mẫu (6,3%), lõi không hợp nhất `MAC-NF` lại chính xác hơn lõi hợp nhất `MAC-F`? Và tại sao ở `MAC-F` vẫn dùng `Posit(32,3)` với bộ nhân 12 bit?

- **Vị trí dẫn chứng trong báo cáo:** *Mục 2.1* (*Phân tích phối hợp bất đối xứng*), *Mục 2.4* (`02_numeric.tex`) và *Mục 5.1.2* (`05.tex`).
- **Số liệu & cơ sở toán học:**
  1. **Thiên lệch cắt một phía ($\widehat{P} \le P_{\text{full}}$):** Phép kiểm chứng trên $125.668/125.668$ cặp hữu hạn (100\%) khẳng định tích $\widehat{P}$ của bộ nhân cắt 12 bit luôn nhỏ hơn hoặc bằng $P_{\text{full}}$ ($117.486$ nhỏ hơn chặt). Lõi `MAC-F` giữ nguyên độ lệch âm này đưa vào bộ cộng. Ngược lại, `MAC-NF` chạy thêm một bước làm tròn RNE $R(\widehat{P})$, có $50\%$ xác suất làm tròn **lên**, nên ở $\approx 6{,}3\%$ cặp đầu vào phần làm tròn lên này tình cờ bù trừ với phần cắt cụt trước đó. Xét tổng thể 377.017 phép thử, `MAC-F` thắng ở $47.534$ mẫu (gấp đôi $23.938$ mẫu thua) và tránh sai lệch mã tới $2^{240}$ tại biên `clamp` `regular` ($12.691/12.693$ mẫu thắng theo `code-distance`).
  2. **Vì sao dùng `Posit(32,3)` với bộ nhân 12 bit:** Cắt bộ nhân còn 12 bit giữ \texttt{0 DSP}, trong khi lưu trữ/cộng trên `Posit(32,3)` mang lại dải động $2^{\pm 240}$ ($\gg$ `FP16`/`FP32`) và nâng ngưỡng chênh thang bắt đầu mất bit cộng gấp **$65.536\times$** so với tích lũy 16 bit (`26` bit vs `10` bit ở `FP16`). Cần nhấn mạnh thêm theo chuẩn `Posit 2022` ($es=2$), `Posit(32,3)` ($es=3$) là biến thể mở rộng dải động kế thừa từ Norris--Kim.

---

## A6. Mô hình vàng tự viết bằng Python/C++ có chắc đúng không? Sao biết không bị lỗi đồng thời giống RTL? Còn ~380 toggle chưa đạt thì sao?

- **Vị trí dẫn chứng trong báo cáo:** *Mục 4.1.1* (`Đối chiếu chéo độc lập mô hình tham chiếu`) và *Mục 4.2*.
- **Số liệu chuẩn cần nắm:**
  - Mô hình vàng đã được đối chiếu chéo với thư viện chuẩn bên ngoài **`SoftPosit`** (ở chế độ $es=2$) trên **$100.867$ trường hợp** ($867$ biên/góc + $100.000$ ngẫu nhiên) qua cả 4 phép `add`, `sub`, `mul`, `fma` ($403.468$ phép kiểm): **`0` sai lệch**.
  - Ở cấu hình $es=3$, bộ nhân vàng khớp bảng số liệu bài báo gốc **Norris--Kim (2021)** trên cả $12/12$ ô dưới $0{,}94$ điểm phần trăm ($\Delta_{\max} = 0{,}9365$\,pp).
  - $380$ bit toggle chưa đảo hai chiều trên `MAC-F` ($93{,}03\%$ đạt) đã được giải trình chi tiết theo từng tệp RTL (chủ yếu ở các bit dịch cực trị trong `dyn_right_shifter_fixed2` [99 bit], `posit_pack_prepare` [51 bit], `sbm_shift_comb` [43 bit] và thanh ghi trạng thái tĩnh `mac_f_wrapper` [31 bit]).

---

## A7. Tần số `154,42 MHz` là `Fmax,R2R` hay toàn thiết kế? Có hiện tượng "lệch seed P&R" khi MAC-NF tụt từ 141,7 MHz xuống 135,85 MHz sau tách S1 không?

- **Vị trí dẫn chứng trong báo cáo:** *Tóm tắt*, *Bảng 5.8* (`tab:fpga-synth-vs-route`), *Bảng 5.13* (`tab:route-critical`) và *Mục 5.4.2* (`05_analysis.tex`).
- **Số liệu chuẩn cần nắm:**
  - **`MAC-F` sau tách S1:** $F_{\max,\mathrm{R2R}} = \mathbf{154{,}42}$\,MHz ($\mathrm{WNS}=+3{,}524$\,ns); còn **`Fmax` toàn thiết kế** (gồm đường tổ hợp từ `u_b/p2_valid_q_reg` ra cổng I/O `in_ready` chịu OOC `output_delay`) là **$129{,}0$\,MHz** ($\mathrm{WNS}=+2{,}247$\,ns).
  - **`MAC-NF` sau tách S1:** $F_{\max,\mathrm{R2R}} = \mathbf{135{,}85}$\,MHz ($+2{,}639$\,ns) và $F_{\max}$ toàn thiết kế $= \mathbf{107{,}2}$\,MHz ($+0{,}669$\,ns).
- **Cách trả lời Hội đồng:**
  - Việc báo cáo tách bạch hai mốc ($154{,}42$\,MHz R2R và $129{,}0$\,MHz toàn thiết kế) hoàn toàn minh bạch: khi tích hợp vào SoC/AXI-Stream thực tế, chỉ cần đặt 1 tầng FF ở chân `in_ready` thì đường giới hạn toàn chip sẽ về ngay miền R2R $154{,}4$\,MHz.
  - Ở `MAC-NF`, việc R2R giảm $0{,}304$\,ns sau khi chia sẻ khối S1 đã sửa ($141{,}70 \to 135{,}85$\,MHz) là **dao động P&R một hạt giống** (đường găng thực của `MAC-NF` nằm ở `u_core/acc_q_reg -> u_product_pack`, không nằm ở S1). Trong khi đó mức tăng $+0{,}756$\,ns ($+16{,}15$\,MHz) của `MAC-F` trực tiếp đến từ việc gỡ nút thắt 62 nhánh fanout của `choose_a` tại tầng S1 (tỉ lệ trễ dây giảm từ $73{,}67\%$ xuống $61{,}22\%$).

---

## Tóm tắt nhanh các lỗi hình thức B1--B5 đã hiệu đính xong
- **B1:** Khẳng định `Posit Standard 2022` định chuẩn $es=2$; `Posit(32,3)` là cấu hình mở rộng ($es=3$) theo Norris--Kim.
- **B2:** Tách bạch làm tròn RNE đơn bước ở cửa sổ 31 bit (ngưỡng mất bit cộng 26 bit nâng $65.536\times$ so với 16 bit) với bài toán chống nuốt số chuỗi dài thuộc về `MAC-Quire`.
- **B3:** Tách riêng trích dẫn `FloPoCo` (`[11,12]`) và `PLAM` (`[17]`), dùng đúng chuẩn tham số hóa `Posit(32,es)` cho `PACoGen` và bỏ tỉ lệ khập khiễng với `PERCIVAL`.
- **B4:** Xóa con số chưa kiểm chứng đầy đủ (`+3,651 ns / 157,51 MHz`), bổ sung định hướng *multi-outstanding* và quét *multi-seed* P\&R ở Mục 6.2.
- **B5:** Phân tách rành mạch phần kế thừa từ Norris--Kim (khối nhân lặp `OPS/SAC/SBM` 12 bit) với 4 đóng góp mới của đồ án ở Chương 1.
