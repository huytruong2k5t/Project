# TIẾN ĐỘ ĐỒ ÁN — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

**Ngày cập nhật:** 14/11/2026 (giờ Việt Nam)
**Sinh viên:** Đan Huy — HK261, HCMUT  
**Đề tài:** Thiết kế và kiểm chứng lõi IP Posit MAC trên FPGA, có mở rộng ASIC.  
**Tài liệu chi tiết:** [SPEC v1.29](../SPEC_Posit_MAC_IP.md), [PLAN L1](../l1/PLAN.md), [README L1](../l1/README.md), [Optimization](../../doc/Optimization.md).

**Cách chạy kiểm chứng:** [Hướng dẫn WSL và ModelSim từ Windows CMD](HUONG_DAN_CHAY_WSL_MODELSIM.md).

File này theo dõi **mốc lớn**: hiện trạng ở mục1, việc còn lại ở mục2, tiến độ tuần ở mục3 và cập nhật theo ngày ở mục4. Chi tiết tối ưu, kiểm chứng/synthesis/STA lưu trong Optimization; PLAN giữ kiến trúc/build. Tiến độ chỉ giữ mốc, công việc còn mở và nhật ký; raw bằng chứng ở results.

**Trạng thái:** `✅` = hoàn thành phạm vi của dòng và có kiểm chứng; `processing` = đã làm một phần hoặc còn thiếu tiêu chí; `không` = chưa thực hiện.

## 0. Tóm tắt chốt tiến độ nộp ngày 14/11/2026

Tài liệu tóm tắt nhanh phục vụ báo cáo tiến độ ngày 14/11/2026 (khớp với [Báo cáo tiến độ PDF](../../doc/Bao_cao_tien_do_Posit_MAC_20261114.pdf) và [Bản thảo hội đồng](../../doc/Ban_thao_hoi_dong_Posit_MAC_20261114_final.pdf); các bảng số liệu đầy đủ được lưu trong bản thảo hội đồng):

### Các hạng mục đã thực hiện và mốc chính
- **Kiến trúc RTL `Posit(32,3)` (`0 DSP`) và tách tải tầng `S1`:** Hoàn thiện lõi trọng tâm `MAC-F` (hợp nhất tích nội bộ 26 bit vào bộ cộng 5 tầng `S1--S5` giữ trọn 26 bit ở nhánh `C`, bỏ đóng gói trung gian), cùng các biến thể đối chứng `MAC-NF`, `MAC-Quire` (lưới 972 bit theo từ 36 bit) và 3 cấu hình `Xilinx FP32` trên `xc7a35tcpg236-1`. Tách 4 nhánh `choose_a` ở `posit_add_prepare_comb.sv` giữ tương đương `bit-exact` (`201.764` kiểm tra), tiết kiệm `23,3% LUT`, `14,7% FF` và rút `3` chu kỳ/MAC so với `MAC-NF`.
- **Kiểm chứng chức năng và độ phủ RTL cuối:** Mô hình vàng khớp `0` sai lệch với `SoftPosit` (`100.867` bộ / `403.468` phép `es=2`) và số liệu công bố của Norris--Kim (`12/12` ô `< 0,94` pp). Phần cứng đạt `0` sai lệch qua `1.634.048` phép nhân (`n=0..12`), `377.032` bộ ghép cặp `(A,B,C)`, `110.000` vectơ/lõi hồi quy hỗn hợp trước/sau tách `S1`, `1.500` trace `ModelSim` (độ trễ quan sát `12--23` chu kỳ cho `MAC-F` và `15--26` cho `MAC-NF` theo quy ước đếm giữa `accept` và `out_valid`) và `48` chuỗi `MAC-Quire` (`16.320` MAC). Đo `Verilator 5.032` trên RTL cuối đạt `96,30%` (`MAC-F`) / `98,03%` (`MAC-NF`) dòng sau rà soát (`90,91%` / `91,98%` thô), `100%` nhánh, đóng `100%` `functional bin` (`2,6` triệu tx/lõi) và `100%` nhánh khối co giãn trên bài thử $II=1$.
- **Sai số số học và ứng dụng thực tế:** Tại `OPS1/n12`, bộ nhân đạt `P95 = 0,0297%`. Trên bộ lọc FIR `32` hệ số, `MAC-F` đạt `SNR = 72,5 dB` (`3,75 us`/mẫu, vượt `FP16` `+10,3 dB` và `BF16` `+28,4 dB`); trên `NN` `128` chiều đạt `P95 = 5,66e-4`; đạt `0/200` lỗi ở các kịch bản dựng có chủ đích nằm ngoài dải `FP32` (`DynScale` `10^-45..10^43` và `Cancel`); và chạy chuỗi `1.024` MAC nhanh hơn `1,33x` (`MAC-NF`) và `3,57x` (`MAC-Quire`) tại $F_{\max,\mathrm{R2R}}$.
- **Triển khai FPGA, công suất và đánh đổi với `Xilinx FP32`:** Sau định tuyến OOC `100 MHz` và siết chu kỳ ràng buộc thực tế, `MAC-F` dùng `1.221 LUT`, `781 FF`, `0 DSP`, đóng sau route đạt $F_{\max,\mathrm{R2R}} \ge 153,8\text{ MHz}$ (`153,85 MHz` @ `6,5 ns`; ước lượng `10 ns` là `154,42 MHz`) và $F_{\max}$ toàn thiết kế $\ge 142,9\text{ MHz}$ (`142,86 MHz` @ `7,0 ns`, `WNS = +0,045 ns`, ngân sách I/O `2,5/0,5 ns`; ước lượng `10 ns` là `129,0 MHz`), thông lượng trung bình `8,53 M MAC/s`, `Pdyn = 4 mW` (`0,721 nJ/MAC`, độ phân giải `±0,5 mW`). So với `Xilinx FP32` (`180--195 MHz` suy ra tuyến tính từ lượt `10 ns`), `MAC-F` dùng nhiều LUT hơn (`1.221` vs `765--993`), năng lượng/MAC cao hơn ~`3x`, SNR FIR thấp hơn (`72,5` vs `138,9 dB`) và thua luồng độc lập $II=1$, nhưng bù lại dùng `0 DSP`, ít hơn `48,6% FF` so với `0-DSP`, giảm `5--7x` công suất động, dải động $2^{\pm 240}$ và bám sát tốc độ `FP32 0-DSP` trên một chuỗi phụ thuộc đơn lẻ (`8,53` vs `8,88 M MAC/s`).
- **Hồ sơ báo cáo hội đồng:** Đã rà soát hoàn chỉnh bản thảo hội đồng trước phản biện (`Ban_thao_hoi_dong_Posit_MAC_20261114_final.pdf`), đồng bộ số liệu đóng timing sau route, câu cân bằng đánh đổi và định nghĩa đo kiểm.

### Các công việc chưa hoàn thành (còn mở cho giai đoạn tiếp theo)

- **Tích hợp bus hệ thống & kiểm thử trên bo mạch Artix-7 thật:** Đăng ký hóa ngõ ra sẵn sàng khi bọc `AXI4-Stream` để đưa đường găng về nội bộ `reg-to-reg` ($\ge 153,8\text{ MHz}$) và nạp bitstream lên bo mạch thật qua UART.
- **Mở rộng đa giao dịch & quét multi-seed P&R:** Hỗ trợ kiến trúc `multi-outstanding` / nhân lặp phân tầng cho các bài toán luồng độc lập và chạy quét nhiều hạt giống P&R kèm `phys_opt_design`.
- **Đóng timing `100 MHz` cho `MAC-Quire`:** Chèn thêm `1` tầng thanh ghi trung gian ngắt đường tổ hợp tới ngân hàng `q_words` để khép kín slack âm `-0,187 ns` (`98,16 MHz`).
- **Mở rộng hồi quy dài hạn:** Chạy bổ sung đối chiếu ghép cặp đủ mọi mức `n` (`0..12`) và các chiến dịch stress dài hạn (`AC-01`, `AC-03`).

---

## 1. Tổng quan

**Phương án A04/11 — đã hiện thực:** gỡ hồi tiếp Posit32 trong NF/F, nhận C trực tiếp; driver ngoài commit state khi retire. Verilator mỗi lõi100k completed, ModelSim49701 completed +299 reset-aborted,0 mismatch; strict lint31 module/68 instance. Matched synthesis A35T: F F2F6.777→5.340ns (~187.3MHz nghịch đảo datapath;178.9MHz gồm setup nội bộ), NF9.344→8.945ns (~111.8/106.1MHz). Mỗi lõi giảm34FF. Fmax toàn giao diện chỉ ước lượng F136.8/NF91.3MHz, WHS−0.055ns; chưa route/main52×10M/coverage mới. Quire không đổi. [Báo cáo](../results/feedforward_a_20261104/summary.md).

**Mở rộng03/11:** quire Q12-1024 đã build và kiểm chức năng: W972/grid2^-480,
cùng core approximate12;10M MAC retired/0 mismatch,ModelSim và unit đạt.
Coverage sau3 loại trừ có giải thích nguồn đạt96.04/95.12/97.05%.
A35T OOC route100MHz còn setup−12.016ns (hold+0.015ns),10339 LUT/4453 FF.
Trạng thái **processing về timing**, chưa MAC_Q12_VERIFIED. [Bằng chứng](../results/quire_20261103/summary.json).
Quire không đóng thay ma trận/gate NF/F còn mở bên dưới.

**Hiện hành02/11:** approximate12, FULL_TERM26/Q24, mặc định OPS1/n12; NF/F dùng chung mã bộ nhân và adder.31 module active, không cfg_mode/exact.143934016 so sánh unit và7.2M MAC completed/0 mismatch; ModelSim mỗi NF/F29820 completed+180 reset-aborted.31 strict lint/68 instance đủ cổng. Đây là pilot đã kiểm chức năng, **chưa nghiệm thu cuối**: main520M, quota regime, coverage nhánh/line, paired accuracy và PPA nguồn mới còn mở. [Bằng chứng](../results/shared_multiplier_20261102/summary.json).

Các số54 module/20M/W14/120,48MHz, FLOOR/exact và các bảng tuần10–14 bên dưới giữ ý nghĩa **lịch sử đúng snapshot**; không suy PASS/STA/coverage sang nguồn FULL_TERM mới. Mốc chuyển hợp đồng02/11 là công việc đang làm, không xóa thành quả cũ.

Đã hoàn thành nền tảng L0, Gate1 của L1 và bộ cộng tuần5. Bộ nhân lặp L1 đã được kiểm chứng; profile source từng đạt ngưỡng TableI nhưng không khớp output ví dụ gốc. Baseline gốc bài báo chưa xác định; giữ nghiên cứu phụ. Mục tiêu chính chuyển sang MAC non-fused làm baseline nội bộ và fused làm biến thể so sánh.

MAC L1/Gate1B, parser/packer, Gate2 multiplier và Gate3 NF đã có bằng chứng. L1 fused W32 và RTL F profile chính đã kiểm trong phạm vi công bố. NF production giữ lịch OPT-03, đã promote OPT-02c/05/09/10A và khóa38 module ngày18/10. Chi tiết số lượt/mismatch, freeze và timing lịch sử chuyển về Optimization; final approximate per-n/AC04,reset/interface review và paired standalone accuracy đã đạt W14;exact/AC02,matched PPA và Gate4 còn mở.

## 2. Công việc còn lại và ưu tiên

**Kết quả cập nhật 13/11.** Đã hoàn thiện [bản nộp 14/11, 20 trang](../../doc/Posit_MAC_LaTeX/Bao_cao_tien_do_Posit_MAC_20261114.pdf) và [bản thảo hội đồng, 46 trang](../../doc/Posit_MAC_LaTeX/Ban_thao_hoi_dong_Posit_MAC_20261113.pdf). Bản nộp có hai mã giả tiếng Anh nguyên khối, đồ thị sai số theo n và diễn giải theo nhóm mẫu. Bản hội đồng gồm sáu chương, hình datapath theo RTL 07/11, ma trận bằng chứng và phần phân tích timing. [Đối chiếu Word, LaTeX và manifest](../../doc/Posit_MAC_LaTeX/DOI_CHIEU_BAN_THAO_HOI_DONG.md)

**Kiểm mới cho hình giao thức.** ModelSim chạy FT-05, n0, giữ response qua ba cạnh stall và reset hủy một request trên RTL khóa 07/11. Kết quả 4 nhận, 3 retire, 1 reset hủy, 0 sai lệch. [Trace CSV](../results/report_trace_20261113/trace.csv) · [Manifest](../results/report_trace_20261113/manifest.json)

**Phần kỹ thuật còn mở.** Ưu tiên coverage AC-04 trên snapshot nghiệm thu, ma trận AC-01, paired accuracy AC-03 theo từng n, rồi STA sau tích hợp với ràng buộc chân và I/O cụ thể. Quire tiếp tục có luồng nghiệm thu riêng.

### Kế hoạch mở rộng bản tiến độ thành bản thảo khoảng 50 trang

**Mục tiêu bàn giao:** khoảng 50 trang PDF A4 tính cả phần đầu, tài liệu tham khảo và phụ lục. Mức **70%** là độ hoàn thiện của **bản thảo báo cáo hội đồng**: bài toán, thiết kế, hình, phương pháp và kết quả hiện có đã viết thành chương có thể giữ lại khi hoàn thiện. Tiến độ nghiệm thu RTL tiếp tục được theo dõi theo SPEC và theo từng snapshot. Giữ MAC-F làm thiết kế chính, MAC-NF làm đối chứng và MAC-quire làm khảo sát mở rộng.

**Tài liệu đối chiếu:** [bản Word 73 trang](../../doc/Project%202%20-%20Bao%20cao%20tien%20do.docx), [bản LaTeX 20 trang](../../doc/Posit_MAC_LaTeX/Bao_cao_tien_do_Posit_MAC_20261114.pdf), [sườn báo cáo](../../doc/Suon%20bao%20cao%20Posit%20MAC.md), [luận văn Fahad](../../RTL_Design_Synthesis/Muhammad%20Fahad%20-%20MSc%20Thesis%20-%20Posit%20Multiplier%202026.pdf) và [bảng nguồn phép đo](NGUON_VA_CAU_HINH_DO_BAO_CAO_20261112.md). Bản Word có 5 chương, 18 bảng và 9 hình kỹ thuật đánh số ở Chương 3, trong đó Hình 3.1 gồm hai sơ đồ NF/F. Chương lý thuyết cũ chiếm 29 trang. Bản mở rộng lấy lại các phần trực tiếp phục vụ thiết kế và kiểm chứng, đồng thời dùng số liệu mới của LaTeX để thay các nhận định phụ thuộc bản Word cũ.

#### Bố cục và ngân sách trang

| Phần | Trang mục tiêu | Nội dung hoàn thiện cho bản tiến độ |
| --- | ---: | --- |
| Phần đầu | 5 | Bìa, tóm tắt có số liệu, mục lục, danh mục hình/bảng/thuật toán và ký hiệu. Tóm tắt nêu bài toán, quyết định chọn F, kết quả sai số, timing OOC và các việc còn mở. |
| Chương 1. Bài toán và công trình liên quan | 4 | Khôi phục từ Ch. 1 Word phần bài toán, mục tiêu, phạm vi và phương pháp. Viết rõ hai bài toán: nhân–cộng độc lập và chuỗi tích lũy. Đối chiếu Norris–Kim về nhân lặp và Fahad về cách đánh giá. Nêu các phần đã hiện thực, phép đo hỗ trợ từng kết luận và ranh giới tái lập bài báo gốc. |
| Chương 2. Cơ sở số học, đặc tả và lựa chọn kiến trúc | 8 | Chọn lọc §2.2–2.6 Word: Posit(32,3), một ví dụ giải mã, Q24, khai triển dịch–cộng, cắt fraction và bỏ số hạng, căn chỉnh/jam, triệt tiêu và RNE. Chốt công thức NF/F/quire và OPS1/n12. Kết chương bằng hình ba phương án và lý do chọn F dựa trên đối chứng cùng điều kiện. Chuyển lịch sử Unum và các phép tính tay dài sang tài liệu tham khảo hoặc phụ lục khi cần. |
| Chương 3. Kiến trúc và thiết kế RTL MAC-F | 13 | Mở rộng từ §3.2–3.7 Word: top, giao thức, Parser P1/P2, OPS–SAC–SBM/T1–T3, chuẩn hóa tích, adder S1–S5, Packer P1/P2. Giữ hai mã giả tiếng Anh. Dùng một ca FT-05 xuyên qua bộ nhân, kèm một trace riêng cho stall/reset hoặc triệt tiêu nếu có bằng chứng. Đặt các hình chi tiết cạnh phần giải thích thanh ghi, dữ liệu và điều khiển. |
| Chương 4. Phương pháp và kết quả kiểm chứng chức năng | 7 | Khôi phục §4.1–4.7 Word: vai trò model/golden/ideal, sơ đồ testbench, scoreboard tại accept/retire, reset hủy giao dịch và backpressure. Đưa một bảng ma trận yêu cầu → ca thử → kết quả → mốc nguồn. Tách unit, hồi quy hỗn hợp và tiêu chí AC-01/03/04. Lệnh build dài để ở phụ lục. |
| Chương 5. Đánh giá sai số, chuỗi và FPGA | 8 | Mở rộng từ §4.3–4.4 LaTeX và §5.2–5.5 Word: đồ thị sai số theo n, phân tích đuôi sai số, paired NF/F ở OPS1/n12, ca gần triệt tiêu, 48 chuỗi và đánh đổi với quire. Trình bày tổng hợp 06/11 và route OOC 12/11 trên nguồn 07/11 thành hai phép đo. Bổ sung một bảng đường găng và đoạn giới hạn kết luận. |
| Chương 6. Kết luận và việc còn lại | 2 | Trả lời các mục tiêu đã đặt, dẫn về kết quả tương ứng, nêu giới hạn của OOC và mẫu đã chạy. Ghi kế hoạch nghiệm thu, coverage và tích hợp. |
| Tài liệu tham khảo và phụ lục | 3 | BibTeX, bảng cổng đầy đủ, trace hoặc bảng F2F bổ sung, manifest/CSV và lệnh tái chạy. Có thể điều chỉnh số trang phụ lục khi dàn trang để giữ dung lượng gần 50. |
| **Tổng** | **50** | Dùng số trang để cân đối dung lượng. Ưu tiên ví dụ, hình và phân tích có dữ liệu kiểm chứng. |

**Cách áp dụng Fahad:** Dùng §1.2–1.4 để tổ chức vấn đề → mục tiêu → đóng góp. Dùng Ch. 3–4 để trình bày cơ sở toán, mã giả, sơ đồ tổng thể rồi giải thích datapath theo từng khối. Dùng §3.7 và §5.2 để tách kiểm chức năng khỏi đo sai số và phân tích cả đuôi sai số. Dùng §5.9 và §5.11 để viết đối chứng trước–sau cùng điều kiện và nêu giới hạn. Với đồ án này, ba mức đánh giá tương ứng là **bộ nhân trước Packer**, **toàn MAC và chuỗi tích lũy**, **triển khai FPGA**.

#### Kế hoạch kiểm tra và vẽ lại datapath

Mốc đề xuất cho hình NF/F là RTL **07/11**, lấy từ `results/route_nf_f_20261112/source/rtl/` và đối chiếu manifest. Hình quire phải ghi rõ kiến trúc đang vẽ thuộc bản backend 04/11 hay bản dùng trong phép đo chuỗi. Dựng hình vector TikZ để sửa nhãn và độ rộng cùng mã LaTeX.

| Hình Word cũ / hình cần có | Hành động | Bằng chứng để duyệt |
| --- | --- | --- |
| **3.1 NF/F** và hai hình tổng quan TikZ | Giữ hình ba phương án ở Ch. 2. Vẽ chi tiết riêng MAC-F ở Ch. 3: A/B/C, vị trí chốt OPS/n, context C, đường chuẩn hóa tích, adder và Packer. Dùng nét riêng cho valid/ready và metadata. | `mac_f_wrapper.sv`: `pair_accept` chốt cấu hình, `pair_retire` chốt C, `core_done` cấp valid cho adder, `retire` giải phóng busy. Hình hồi tiếp D→C ghi rõ phần bên ngoài lõi. |
| **3.2 Parser P1/P2** | Dùng hình cũ làm bản nháp. Vẽ lại bù hai, XOR lân cận, sentinel, dò chuyển tiếp và ranh giới P1/P2. Ghi riêng fraction cao 12 bit, thấp 14 bit và `tail_cut`. | `posit_parser_mul.sv` và Algorithm 3.1. Chỉ rõ A/B dùng fraction cao, C dùng đủ 26 bit. |
| **3.3–3.5 OPS/SAC/SBM** | Gộp thành một sơ đồ pipeline và một trace ngắn. Vẽ bộ chọn OPS, context, token T1, dịch T2, cộng/commit T3, accumulator Q24 26 bit và đường `core_done`. | `ops_sel_comb.sv`, `mul_iter_core.sv`, các module SAC/SBM trong file list và Algorithm 3.2. Kiểm trace FT-05, n=0 và dừng sớm. |
| **3.6–3.8 adder S1/S2/S5** | Giữ ý chính các hình cũ, dựng một sơ đồ S1–S5 đầy đủ, bổ sung S3/S4 và dùng hình chi tiết S2/S5 cho phần jam và triệt tiêu. | `posit_add.sv` và các module tầng. Kiểm ranh giới thanh ghi, độ rộng, dấu/scale, sticky/cờ và quy tắc valid/ready. Ghi rõ chỗ chuyển từ payload nội bộ sang đầu vào Packer. |
| **3.9 Packer** | Ưu tiên vẽ mới vì chú thích bản Word đã ghi cần cập nhật. Tách P1 chuẩn bị payload, dịch và tạo G/R/S khỏi P2 làm tròn, kẹp và tạo cờ. | `posit_pack.sv`, `posit_pack_prepare.sv`, `posit_pack_finish.sv` của bản 07/11. Thể hiện payload 59 bit và nhánh sticky song song ở mức cần thiết. |
| **Hình bổ sung về giao dịch và kiểm chứng** | Vẽ sequence/waveform từ trace đã lưu hoặc chạy lại một fixture nhỏ: accept → Parser/core → response → retire, kèm một ca stall hoặc reset. Nếu có hình quire chi tiết, thể hiện CLEAR/MAC/READ và đường Q theo đúng nguồn. | Trace và manifest tương ứng. Ghi tên fixture, cấu hình, snapshot và điểm lấy mẫu. Các ca mới chỉ đưa vào PDF khi đã có trace kiểm chứng. |

**Điều kiện duyệt hình:** Mỗi hình có snapshot, tên module, biên pipeline và tên/độ rộng bus ở các ranh giới quan trọng. Chú thích phân biệt sơ đồ khái niệm với sơ đồ theo RTL. Khi hình cũ và RTL khác nhau, vẽ theo RTL gắn với phép đo. Nếu có sơ đồ hoặc thay đổi RTL mới muốn dùng cho bản hội đồng, Đan Huy xác nhận snapshot và gửi bản chỉnh trước khi thay các hình liên quan. Có thể soạn các hình từ snapshot 07/11 trong lúc chờ xác nhận phiên bản mới.

#### Thứ tự thực hiện và điều kiện bàn giao

1. **Chốt mốc nguồn và lập mục lục chi tiết.** Gắn từng chương Word với mục LaTeX tương ứng, giữ phần đã có bằng chứng. Chốt snapshot hình NF/F và quire, và bảng liên kết từng phép đo với nguồn/manifest.
2. **Dựng hình và viết Ch. 2–3 trước.** Ưu tiên top MAC-F, bộ nhân, Packer rồi Parser và adder. Duyệt hình với mã giả và trace. Viết mỗi khối theo thứ tự đầu vào → xử lý → thanh ghi → đầu ra → lý do lựa chọn.
3. **Viết Ch. 4–5 từ bằng chứng hiện có.** Dựng sơ đồ kiểm chứng và đồ thị từ CSV. Có đoạn giải thích sau mỗi bảng: quan sát, điều kiện đo, hệ quả và giới hạn. Giữ riêng mốc tổng hợp 06/11, nguồn RTL 07/11, lượt route ngày 12/11 và dữ liệu quire.
4. **Ghép phần đầu, kết luận và phụ lục.** Chuyển các bảng rộng, lệnh chạy và trace dài sang phụ lục. Kiểm mục lục, số hình/bảng/thuật toán, DOI, tham chiếu và dàn trang PDF. Bản 50 trang đạt mốc bản thảo khi sáu chương đã đọc liền mạch, hình chính đã duyệt, bảng chính truy được nguồn và phần còn mở có tiêu chí đóng.

**Phần hoàn thiện cho hội đồng:** AC-01 main, AC-03 main theo từng n, coverage AC-04 đúng snapshot, timing sau tích hợp với ràng buộc I/O thực, và kết quả tối ưu hoặc kiểm tra bổ sung nếu được thực hiện. Cập nhật từng kết quả vào chương đã chuẩn bị, kèm manifest và giới hạn. Mốc bản thảo 70% có thể dùng các lượt đo hiện có để trình bày đầy đủ phương pháp và kết luận tiến độ.

### Rà soát bản nộp hạn 14/11/2026

**Bản rà soát:** [PDF LaTeX 20 trang](../../doc/Posit_MAC_LaTeX/Bao_cao_tien_do_Posit_MAC_20261114.pdf), bìa ngày 14/11, gồm năm chương và ba phụ lục. PDF hiện tại trùng bản dựng `.build/main.pdf`. Đã rà bố cục tổng thể và đọc phần thiết kế, kiểm chứng, kết quả và kết luận.

**Đã có trong bản nộp:** Lý thuyết Norris–Kim, sơ đồ ba phương án và sơ đồ MAC-F, hai thuật toán đánh số, bảng sai số trước Packer cho n=0…12, so sánh NF/F trên 377.032 bộ A/B/C và khảo sát 48 chuỗi mỗi lõi. Cả NF/F có setup và hold slack dương trong lượt route OOC 100 MHz trên nguồn 07/11. Bảng F2F đã ghi đúng 4,040 ns cho Parser A/B/C P1 của MAC-F. Các mục trong kế hoạch 12/11 bên dưới phản ánh thời điểm lập kế hoạch. Trạng thái nộp hiện tại căn cứ bản LaTeX và [bảng nguồn, cấu hình đo](NGUON_VA_CAU_HINH_DO_BAO_CAO_20261112.md).

| Ưu tiên | Vị trí trong báo cáo | Việc hoàn thiện và tiêu chí kiểm tra |
| --- | --- | --- |
| **Trước khi nộp** | Tóm tắt và Chương 5 | Thêm một kết quả sai số định lượng vào tóm tắt, chẳng hạn P95 **0,029718% trước Packer ở OPS1/n12 trên 100.000 cặp hữu hạn lấy mẫu đều**. Kết luận chọn F dựa trên chi phí IP và kết quả timing đã đo. Phân biệt 06/11 tổng hợp, 07/11 nguồn RTL, và 12/11 ngày chạy route OOC. Khi nêu giảm **347 LUT và 135 FF**, ghi rõ đó là so sánh trong cùng lượt 06/11. |
| **Trước khi nộp** | §3.2–3.3, Thuật toán 3.1 và 3.2 | Đổi hai danh sách đánh số thành khối mã giả có **Đầu vào**, **Đầu ra**, số dòng và nhánh/vòng lặp rõ ràng theo mẫu Fahad. Thuật toán 3.1 hiện bị ngắt giữa trang PDF 9 và 10. Ưu tiên giữ mỗi khối trên một trang, kiểm lại Zero/NaR, n=0, bit ẩn và điều kiện dừng với RTL đang mô tả. |
| **Trước khi nộp** | §4.3.1–4.3.3 | Thêm diễn giải ngay sau các bảng: P95 có thể gần bão hòa trong khi đuôi sai số còn giảm, ví dụ từ n=8 đến n=10 trên nhóm lấy mẫu đều. Ghi rõ 100.000 cặp là nhóm của bảng chính, còn 125.696 cặp là toàn bộ mẫu mỗi n gồm ca phân tầng và ca chủ đích. Giữ điều kiện **48 chuỗi**, **4 chuỗi mỗi nhóm/độ dài** và **đầu ra luôn sẵn sàng** khi diễn giải độ trễ. Dùng “số chu kỳ” khi nói về so sánh NF/F/quire ở RTL. |
| **Trước khi nộp** | §4.1, §4.4, Chương 5 và phụ lục | Nêu rõ mốc nguồn ngay cạnh kết quả chính và dẫn đến manifest hoặc bảng nguồn đo. Rà AC-01, AC-03, AC-04 theo phạm vi từng lượt. Bảng route ghi OOC 100 MHz với budget I/O giả định. Sau khi biên dịch, kiểm bìa, mục lục, tham chiếu, ngắt trang, bảng dài và PDF đúng bản dựng cuối. |
| **Nếu còn thời gian** | §4.3.1 và tài liệu tham khảo | Thêm một đồ thị sai số theo n lấy từ CSV để thấy P95 và max hội tụ khác nhau. Chú thích nhóm mẫu và cách thể hiện giá trị 0 nếu dùng trục log. Bổ sung liên kết kho lưu trữ cho luận văn Fahad trong thư mục tài liệu tham khảo. |

**Sau mốc báo cáo tiến độ:** AC-01 main 520 triệu, AC-03 main theo từng n, coverage AC-04 trên đúng nguồn nghiệm thu, và STA của thiết kế tích hợp có placement và ràng buộc chân/I/O cụ thể. Ghi các mục này trong bảng việc còn mở. Phép đo chuỗi của quire và timing của NF/F có manifest riêng.

### Kế hoạch hoàn thiện báo cáo theo sườn ngày 12/11/2026

Xem [sườn báo cáo mới](../../doc/Suon%20bao%20cao%20Posit%20MAC.md). MAC-F là trọng tâm trình bày và tối ưu, MAC-NF là đối chứng nội bộ, MAC-quire là khảo sát mở rộng. Cấu hình benchmark mặc định là `cfg_ops=1`, `cfg_n=12`. Phạm vi và ngưỡng nghiệm thu RTL theo [đặc tả hiện hành](SPEC_Posit_MAC_IP.md). Bảng dưới theo dõi phần việc để hoàn thiện hồ sơ báo cáo.

| Thứ tự | Việc cần làm | Hoàn thành khi | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chốt phiên bản RTL và cấu hình cho từng phép đo | Có bảng ghi phiên bản nguồn, oracle, seed, số mẫu và cấu hình đầu vào. Bảng tài nguyên ngày 06/11 ghi rõ tổng hợp lõi có cổng cấu hình động. | ✅ Chốt RTL 07/11 cho các lượt đo sai số MAC và timing sau route. [Bảng nguồn và cấu hình](NGUON_VA_CAU_HINH_DO_BAO_CAO_20261112.md) |
| 2 | Kiểm và đo sai số bộ nhân trước Packer (§4.3.1) | Đối chiếu tích, dấu, số mũ, số vòng và cờ cắt với oracle FULL_TERM. Dùng cùng tập cặp A/B đo ở OPS1/n12 và một số mức n thấp hơn. Có mốc tích chính xác đầy đủ và mốc tích của toán hạng đã giữ 12 bit fraction để phân biệt hai nguồn sai số. Lưu CSV, seed, số mẫu, phân vị 95, sai số lớn nhất quan sát được và số vòng thực tế. | ✅ Nguồn MAC-F khớp hash 07/11. OPS1, n=0…12, 125.696 cặp mỗi n, 1.634.048 giao dịch, 0 sai lệch. [Báo cáo §4.3.1](../results/mul_prepack_20261112/summary.md) · [Tập A/B cho bước 4](../results/mul_prepack_20261112/pairs.csv) |
| 3 | Đối chiếu phương pháp với Norris–Kim (§1.3, §2.2, §4.3.1) | Viết phần lý thuyết có trích dẫn. Nếu đưa số công bố vào bảng, ghi điều kiện và cách đo có sẵn. Dùng tích chính xác trên cùng đầu vào làm mốc định lượng chính. | ✅ [Nội dung và trích dẫn](../../doc/DOI_CHIEU_NORRIS_KIM_20261112.md) |
| 4 | Đo sai số toàn MAC (§4.3.2) | Dùng lại tập cặp A/B và thêm C cùng dấu, trái dấu, gần triệt tiêu. So MAC-F và MAC-NF với tổng chính xác trên cùng A/B/C. Báo riêng sai số tuyệt đối ở tổng bằng hoặc gần 0, cùng các ca F kém NF nếu có. | ✅ RTL 07/11, OPS1/n12, 377.032 bộ A/B/C, 0 sai lệch d/flags mỗi lõi. [Kết quả §4.3.2](../results/paired_mac_20261112/summary.md) |
| 5 | Hoàn thiện bằng chứng kiểm chứng và timing (§4.2, §4.4) | Gắn số hồi quy với đúng snapshot, đối chiếu coverage và ma trận theo đặc tả. Sửa ba hàng Parser A/B/C P1 của MAC-F trong bảng đưa sang LaTeX thành 4,040 ns theo CSV ngày 06/11. Cập nhật setup/hold sau đặt và định tuyến khi có kết quả. | ✅ Hồ sơ báo cáo đã đối chiếu. RTL 07/11 route OOC 100 MHz, WNS/WHS NF +0,665/+0,043 ns và F +2,142/+0,043 ns. [Kiểm chứng và phạm vi còn mở](../../doc/DOI_CHIEU_KIEM_CHUNG_NF_F_20261112.md) · [Timing sau route](../results/route_nf_f_20261112/summary.md) |
| 6 | Viết lại chương thiết kế và chọn kiến trúc (§2–3) | Có hình ba phương án, sơ đồ đường dữ liệu MAC-F, hai khối mã giả Parser và FULL_TERM đã đối chiếu RTL, bảng NF/F cùng điều kiện và bảng quire trước–sau theo lượt đo riêng. | ✅ Nguồn LaTeX và hai hình TikZ đã đối chiếu RTL. [Chương 2](../../doc/Posit_MAC_LaTeX/chapters/02_arithmetic.tex) · [Chương 3](../../doc/Posit_MAC_LaTeX/chapters/03_design.tex). Biên dịch cùng báo cáo ở mục 8. |
| 7 | Nếu đánh giá tốc độ chuỗi, đo ở cấp hệ thống (§4.3.3) | Có cùng dãy đầu vào, trạng thái ban đầu và điều kiện giao tiếp. Ghi tổng số chu kỳ, gồm hồi tiếp ngoài hoặc READ, và sai số cuối. | ✅ 48 chuỗi trên cả ba lõi, 0 sai lệch với oracle, có số chu kỳ và sai số cuối. [Khảo sát chuỗi](../results/mac_chains_20261112/summary.md) |
| 8 | Hoàn thiện bản LaTeX (§5 và phụ lục) | Ghép các chương, dẫn nguồn vào tệp .bib, liên kết hình/bảng/thuật toán, kiểm số liệu với CSV và biên dịch PDF. Mục kết luận ghi rõ trạng thái của từng phép đo. | ✅ Bản nộp cập nhật 13/11, 20 trang đã kiểm bố cục, bìa ngày nộp 14/11/2026. [PDF](../../doc/Posit_MAC_LaTeX/Bao_cao_tien_do_Posit_MAC_20261114.pdf) · [Nguồn LaTeX và cách dựng](../../doc/Posit_MAC_LaTeX/README.md) |

Mốc để nối phần bộ nhân với phần MAC là **tập cặp A/B đã khóa và bảng sai số tại đầu ra bộ nhân trước Packer**. Dùng lại tập này ở bước 4 để giải thích tác động của phép cộng và vị trí làm tròn.

### Các mốc kỹ thuật đã ghi trước đó

**Quyết định hiện hành02/11:** chỉ posit32/ES3, FW12/FULL_TERM26/Q24/RNE/OPS1/n0..12; bỏ exact hardware và FLOOR từng term. Giữ NF làm baseline nội bộ; provenance/TableI là nghiên cứu phụ, quire mới là hợp đồng mở rộng. Ưu tiên kiểm đích coverage → main52×10M → paired accuracy/matched PPA → hồ sơ trước05/12. SoftPosit ES2 không là oracle32/3.

| Mốc lớn | Trạng thái | Phần cần hoàn thiện |
| --- | --- | --- |
| MAC quire Q12-1024 | processing | Model/RTL main10M/4-state/coverage đạt phạm vi; còn timing100MHz. Ưu tiên pipeline/giảm fanout sf→align/zero/error→bank CE, kiểm lại phần bị tác động |
| Đồng bộ NF/F approximate FULL_TERM | ✅ phạm vi refactor/pilot | Core/OPS/normalizer dùng chung; bỏ tín hiệu/đường exact dư; unit,ModelSim và pilot mới0 mismatch. Không đồng nghĩa đóng Gate cuối |
| Nghiệm thu FULL_TERM nguồn mới | processing | Main520M chưa chạy; pilot min188/189<4000/cell. NF line/branch/toggle96.05/89.13/93.67%; F76.06/89.74/93.11%; chưa waiver RTL. PPA/paired accuracy chưa đo lại |
| Khóa cấu hình duy nhất32/3 | ✅ phạm vi chức năng |54 module fixed,runner/mapping và wrapper synthesis đã đồng bộ;NF/F20M completed,ModelSim và kiểm tổ hợp0 mismatch. Còn STA/PPA mới,AC02 exact và final per-n/AC04;candidate lịch sử cần rebase riêng |
| Baseline nội bộ và so sánh NF/F | processing | RTL NF/F final approximate và paired standalone accuracy đã đạt; còn matched PPA. Baseline paper giữ nghiên cứu phụ |
| RTL và kiểm chứng tích hợp — Gate2/3 | processing | Gate2/adder, NF tuần11 và F profile chính đã kiểm; final approximate và coverage NF/F đã đạt;exact/AC02 vẫn mở riêng |
| PPA, mở rộng và hồ sơ — Gate4 | processing | NF CycloneIV45,07MHz là lịch sử; F A35T100MHz R2R đạt. Còn đo matched NF/F,AC02 và hồ sơ cuối; số đo riêng xem Optimization |

**Trạng thái tối ưu:** đã promote và khóa OPT-12 negate, release `POSIT_MAC_RTL_20261018_OPT12_120`, A35T Explore120,48MHz NF/F setup/hold đạt; OPT02C100MHz giữ lịch sử. Fraction12/W32, L1/oracle/latency và I/O budget giữ nguyên. Xem Optimization8.31.8. W14-01..11 đã đạt phạm vi bàn giao;tiếp theo matched PPA W15,W14-12/AC02 hoãn riêng. Hạn chính29/11, đệm30/11–04/12, hoàn thành trước05/12/2026.


## 3. Tiến độ theo tuần

Tuần1–9 giữ lịch sử; tuần10–16 có lịch dự kiến từ12/10/2026 theo hạn trước05/12. Ngày dự kiến không đồng nghĩa nghiệm thu đã đạt. Một phần công việc hoàn thành không đồng nghĩa cả tuần đã đạt.

| Tuần | Mốc cần đạt | Trạng thái | Kết quả chính / phần còn lại |
| --- | --- | --- | --- |
| 03/11 — mở rộng quire | Không RNE trong chuỗi, READ mới RNE | processing | Chức năng/10M/ModelSim✅; signed972,L_max1024; setup100MHz chưa đạt, không suy nghiệm thu NF/F |
| 02/11 — chuyển hợp đồng | Dùng chung multiplier FULL_TERM và kiểm nguồn mới | processing | Refactor/pilot✅; main52 điểm×10M,AC04,accuracy/PPA còn mở; không kế thừa PASS FLOOR |
| 1 | Tài liệu và nền tảng dự án | processing | Đã có đặc tả, kế hoạch và khung dự án; còn hoàn thiện lint/luồng tự động |
| 2 | Mô hình tham chiếu L0 | ✅ | SoftPosit đã build và kiểm thử đạt |
| 3 | L1 số học chính xác — Gate1 | ✅ | Parser/packer, nhân exact và round đã nghiệm thu |
| 4 | L1 nhân lặp và hợp đồng tích nội bộ | ✅ | FLOOR/RNE prepack đã chốt, kiểm độc lập và đóng băng; provenance/TableI lưu nghiên cứu phụ, fused còn theo tuần12 |
| 5 | L1 bộ cộng | ✅ | Đã triển khai và kiểm chứng đạt |
| 6 | L1 MAC — Gate1B | ✅ | MAC v0/v1, tích lũy và API đạt kiểm chứng Linux/Windows |
| 7 | RTL giải mã và khối cơ sở | ✅ | LOD/LZD, hai shifter và parser tổ hợp/pipeline kiểm chứng đơn vị đạt |
| 8 | RTL mã hóa và làm tròn | ✅ | Packer tổ hợp/pipeline và parser→packer đạt; PPA đơn vị đã khảo sát, sau tối ưu P2, benchmark đạt setup100MHz ở ba seed mỗi mode |
| 9 | RTL bộ nhân lặp — Gate2 | ✅ | Multiplier đã nghiệm thu trên16 cấu hình,0 mismatch; lint và coverage đạt phạm vi tuần9. Baseline gốc giữ nghiên cứu phụ |
| 10 | RTL adder và chốt so sánh NF/F | ✅ | Hoàn tất12/10: comb/pipeline, oracle/lượt lớn0 mismatch; matrix và corpus input đã chốt. R(P_hat)/carry đã xử lý ở tuần11; ma trận cuối/fused/PPA còn mở |
| 11 | MAC non-fused — Gate3 | ✅ | Hoàn thành14/10: lượt mới10 triệu/0 mismatch,near52,55548%,coverage và ModelSim corner đạt; giữ F pilot,final/F RTL/PPA còn theo các tuần sau |
| 12 | Oracle/L1 fused và timing sơ bộ NF | ✅ | Hoàn thành15/10:G-F-L1/W32,main phân tầng0 mismatch;đã đo toànNF,đề xuất pipeline,bàn giao và sao lưu. 100MHz chưa đạt,F RTL/accuracy/PPA cuối còn theo các tuần sau |
| 13 | RTL fused | ✅ | RTL/pipeline đã kiểm;final F90M và AC04 hoàn tất W14. Reset/interface đã review;matched PPA và board signoff không thuộc mốc RTL này |
| 14 | Regression và accuracy paired NF/F | ✅ phạm vi W14-01..11 | 350M completed/0 mismatch gồmF90M+NF250M+NF-EX010M;AC04 chính và9M paired standalone accuracy đạt. W14-12/AC02 hoãn riêng;Optimization8.34 |
| 15 | PPA hai bản và bản thảo — Gate4 | không | 16–22/11: cùng điều kiện,≥3 run/config; accuracy/timing/II/tài nguyên và kết luận |
| 16 | Báo cáo, demo và bảo vệ | processing | 23–29/11: chốt hồ sơ/tái lập/slide/demo; hiện mới có slide các khối. Đệm30/11–04/12 |

## 3.1. Bàn giao tuần13

W13-01..06 đã hoàn tất phạm vi RTL/counters/coverage;reset/interface của W13-07 đạt W14-01.
Matched PPA chuyển theo đúng lịch W15,không giữ lại checklist RTL đã nghiệm thu.
Chưa board signoff hoặc nghiệm thu toàn SPEC.

## 3.2. Tuần14 — đã hoàn thành phạm vi bàn giao W15

**Thực hiện sớm18/10/2026** trên `POSIT_MAC_RTL_20261018_OPT12_120`,không sửa RTL/L1/oracle/constraints.
Checklist W14-01..11 đã nghiệm thu được gỡ khỏi kế hoạch; chi tiết TC,seed,lệnh,counter,
coverage/proof/accuracy và archive ở [Optimization8.33–8.34](../../doc/Optimization.md#834-hoàn-tất-w14-0711-trên-release-đã-khóa--18102026)
và `results/week14/completion.json`, `coverage_closure.json`, `accuracy_final/main_check.json`, `handoff.json`.
Backup cuối phiên được xác nhận bằng kết quả Git push,không suy từ file JSON.

| Mốc lớn | Kết quả | Trạng thái |
| --- | --- | --- |
| W14-01..05:review,harness,pilot và freeze | Release/counters/oracle/negative audit và accuracy calibration đạt; matrix/source/binary freeze trước main | ✅ |
| W14-06/07:main NF/F | F90M+NF250M completed,0 mismatch; đúng≥10M từng điểm,n/OPS/profile riêng,abort tách completed | ✅ |
| W14-08:coverage chính | NF32/2,NF32/3,F32/3 đạt line/branch/toggle và100% functional bin hợp lệ;F có2 loại trừ branch có căn cứ,giữ số thô | ✅ |
| W14-09:paired accuracy | 9n×1M standalone triples,Python Fraction9216 checks;CI95,ngoại lệ,kết quả F bất lợi lưu đầy đủ | ✅ |
| W14-10/11:comparator và tái lập | NF-EX010M/0 mismatch;15 audit mutants bị từ chối,4 pilot replay khớp;archive CRC/SHA và backup cuối phiên | ✅ phạm vi kỹ thuật |

**W14-12 / AC02 vẫn mở riêng**,không dùng main approximate hoặc pilot exact thay nghiệm thu exact:

| Phần còn lại | Tiêu chí chưa chạy đủ | Trạng thái |
| --- | --- | --- |
| Exact p32/3 | ≥10^8 vector phân tầng+corner,0 mismatch với oracle integer/rational độc lập32/3 theo AC02; tách khỏi các lượt approximate đã đạt | không |

W14-01..11 đủ bàn giao matched PPA W15;W14-12 được hoãn theo lịch đã duyệt,không được miễn AC02
hoặc gọi toàn SPEC/Gate4 đã đạt. ComparatorEX0 giữ structural diagnostic riêng,chưa claim toggle85%
cho derivative;lint có đúng1 waiver feature-unused đã công bố. Accuracy standalone không chứng minh
accuracy ứng dụng hoặc chuỗi feedback. Không đổi release để khắc phục test.

## 3.3. Tối ưu RTL — checkpoint100MHz và candidate120+MHz

**Phạm vi thiết bị:** chỉ A35T `xc7a35tcpg236-1` (`A35T-C2`) cho các lần kiểm chứng timing/synthesis/P&R tiếp theo, gồm paired NF/F tuần15. Không chạy A100T; giữ số đo A100T cũ như lịch sử.

Checkpoint **`POSIT_MAC_RTL_20261018_OPT02C` giữ lock/hash làm reference100MHz**; workflow đã mở lại candidate tại Optimization8.31.6: production38 module,
L1/oracle/constraint không đổi; NF10M/0 mismatch, F10M kế thừa theo hash và smoke mới đạt.
Candidate đạt100MHz cả3 strategy A35T-C2; median R2R F_STA114,40MHz (ước lượng STA, không phải đo kit).
Chi tiết và giới hạn: [Optimization §8.30](../../doc/Optimization.md#legacy-8-30).

### 3.3.1. Mốc tối ưu và khóa RTL đã hoàn tất trước W14

| ID / nhóm | Mốc chính | Trạng thái | Bằng chứng |
| --- | --- | --- | --- |
| OPT-05 / OPT-09 / OPT-10A | SAC abc_tree, magnitude P2/parse, prefix sticky | ✅ | Đã promote cùng gói; không đổi lịch pipeline |
| OPT-02c | A1 parallel shift/jam/tail, clamp bit-check,0 FF thêm | ✅ | Leaf11 profile/0 mismatch;406 lint; NF10M/0 mismatch |
| OPT-00 / OPT-02b / OPT-02c | Đối chiếu production cũ/reference/candidate,3 strategy cùng A35T-C2 | ✅ | Candidate WNS+0,894/+0,894/+1,011ns; hold dương; bảng §8.30 |
| OPT-07 / OPT-08 | Promote38 module và khóa hash RTL/L1/build/constraint | ✅ | production_freeze.json;37 strict lint; ModelSim NF/F; audit release PASS |

### 3.3.2. Các hạng mục ĐÓNG / KHÔNG CẦN TỐI ƯU NỮA (Dừng để bảo toàn lịch Tuần 14–15)

| ID / nhóm | Nội dung trước đây | Quyết định | Lý do kỹ thuật (theo STA mục 8.28.3 & 8.29.3) |
| --- | --- | --- | --- |
| OPT-10B | Chuyển phần sticky/flags từ P1 sang P2 | **Đóng (Bỏ qua)** | `OPT-10A` đã kéo `product_packer_p1` lên `+1.697 ns` và `final_packer_p1` lên `+3.184 ns`; không cần tốn thêm FF ở biên P1/P2 |
| OPT-11 (`C-prefix precompute`) | Tính trước prefix-OR cho toán hạng `C` tại `pair_retire` | **Đóng (Bỏ qua)** | Top critical paths của `adder_a1` xuất phát từ `norm_sf_q` (scale factor tích) qua `diff_ab/ba`, không xuất phát từ `c_frac_q`; thêm ~30 FF không giảm delay đường găng |
| OPT-11 (`A1→A2 jam retiming`) | Dời MUX `jam_bit`/`alignment_tail` sang đầu tầng A2 | **Tạm đóng (Dự phòng)** | Thay thế bằng `OPT-02c` (0 FF, sửa nội bộ A1). Chỉ mở lại nếu sau `OPT-02c` vẫn cần thêm biên độ cho mục tiêu tần số cao hơn |
| OPT-04 & OPT-06 | Cân bằng lại A2/A3 LOD; sửa `zero`/`shared` ở `posit_add_norm` | **Đóng (Bỏ qua)** | `adder_a2` (`+5.007 ns`) và `adder_a3` (`+2.318 ns`) đã rất rộng; thử nghiệm trước chỉ giảm 4–7 LUT và không cải thiện Fmax toàn cục |
| Direct `round_unpacked` & `Remaining-scale` SAC | Bỏ qua pack→parse ở tích NF; đếm lùi scale còn lại trong SAC | **Đóng (Bỏ qua)** | Rủi ro lệch số học cao trong khi `OPT-09` (`+3.208 ns`) và `OPT-05 abc_tree` (`+1.344 / +2.814 ns`) đã giải quyết gọn nhẹ cả hai vùng |
| Tinh chỉnh thêm biên `in_ready` | Giảm logic điều khiển parser-valid/ready tới `in_ready` | **Đóng (Bỏ qua)** | Default8.28: `u_a/p2_valid_q→in_ready`,6 tầng LUT,data5,829ns,slack+0,730ns; wrapper không có `fifo_count_q`. Dừng vì đạt budget100MHz hiện hành,không vì giả định đường chỉ có2 LUT |
| Khảo sát đổi `FRAC_W` | Đổi độ rộng fraction khỏi mức `FW12` hiện hành | **Đóng cho RTL chính** | Giữ nguyên `FW12` cho RTL NF/F và báo cáo so sánh; bảng khảo sát 8–26 bit tại [Optimization §8.11](../../doc/Optimization.md#legacy-8-11) dùng làm phân tích lựa chọn tham số trong luận văn |

Đợt100MHz giữ lịch sử;OPT12_120 đã promote và qua W14-01..11. L1/oracle và constraints không đổi;không mở lại tối ưu trước matched PPA.

### 3.3.3. Khóa production120MHz — 18/10

| Nhóm | Việc tiếp theo | Trạng thái |
| --- | --- | --- |
| Review OPT-12/13/14 | Đã đọc8.31,ghi điều kiện/sai phạm tại8.31.6; mở snapshot candidate bằng reference,không sửa RTL | ✅ |
| OPT-12 parser | Candidate negate đã qua lint/decoder/cycle-equivalence,pilot và10M NF+10M F/0 mismatch; ModelSim125MHz đạt | ✅ |
| Timing trên120MHz | Đã post-route8,3ns≈120,48MHz,NF/F có flow PASS; giữ cả hàng FAIL,đặc biệt F Default−0,009ns. Chi tiết8.31.7 | ✅ |
| Chọn/promote/khóa lại | Đã chọn negate/Explore8,3ns và promote đúng byte; khóa OPT12_120, audit PASS, giữ lock100MHz lịch sử. W14-01..11 đã đạt; OPT-13/14 không triển khai | ✅ |

## 3.4. Công việc mở khác và giới hạn phạm vi (Ưu tiên giai đoạn cuối Tuần 14–16)

| Nhóm | Việc còn lại | Trạng thái | Ưu tiên & Hướng xử lý |
| --- | --- | --- | --- |
| **1. Gói ứng viên OPT-15/16 và PPA đối xứng NF/F — Gate 4 (Tuần 15)** | NF chọn OPT-15 combined;F đã kiểm/đo hai parser với F1–F5 và với bộ cộng NF ba tầng. Cần chọn F candidate,kiểm derivative NF EXACT_EN0 nếu dùng,rồi đo matched ≥3 strategy/config trên A35T,8,300ns,budget I/O giữ nguyên | processing | **Ưu tiên số 1:** chốt đánh đổi LUT/FF/latency của F theo Optimization8.36 trước gói matched PPA. Các trial chưa promote production hoặc thay bằng chứng W14 |
| **2. Hồ sơ / Báo cáo / Slide bảo vệ (Tuần 16)** | Tổng hợp bằng chứng CDC/RDC đã kiểm ở `W14-01`, hoàn thiện luận văn, biểu đồ Pareto, slide và demo | processing | **Ưu tiên số 2:** Hạn chính29/11,đệm30/11–04/12. Kiểm CDC/RDC/reset thuộc ưu tiên1 trước matrix final,không dời kiểm kỹ thuật sang tuần16; công khai phạm vi OOC chưa board signoff |
| **3. Tái lập / Luồng tự động** | Duy trì collector/audit và kiểm tra hash nguồn frozen cho `results/week14` và `results/week15` | processing | **Ưu tiên duy trì:** Chỉ phục vụ nghiệm thu W14/W15; không chạy lại các lượt lịch sử chỉ vì cập nhật tài liệu |
| **4. Exact/AC02 (W14-12)** | Chỉ32/3: ≥1e8 vector phân tầng+corner,oracle integer/rational độc lập theo SPEC v1.21; không dùng approximate PASS thay exact | không | Nhánh được hoãn riêng theo lịch;phải công bố phần chưa chạy trước nghiệm thu tổng/Gate4,không dùng W14 approximate thay AC02 |
| **5. Timing giao tiếp tích hợp ngoại vi** | Điền budget I/O thực tế và pinout/IOSTANDARD nếu ghép vào hệ thống SoC/board cụ thể | **Đóng / Ngoài phạm vi bắt buộc** | Giữ mẫu `a35t_io_template.xdc` làm tài liệu bàn giao IP (`syn/README.md`); đánh giá lõi IP dùng chuẩn `A35T-C2` |
| **6. Provenance Baseline Paper gốc (2024)** | Xác minh phần dư provenance LUT/width/tie-breaking/seed gốc của tác giả bài báo | **Đóng (Giữ nghiên cứu phụ)** | Đã có đủ bằng chứng phân tích tại Optimization; không dò thêm tham số để ép khớp Table I |
| **7. Mở rộng tùy chọn ngoài đề cương chính** | Exact fused rộng, format phụ ngoài ma trận §6.7, TRUNC/JAM F, quire hoặc ASIC synthesis | **Đóng (Không thực hiện)** | Ngoài profile chính; dừng hoàn toàn để tập trung 100% cho nghiệm thu NF/F và viết báo cáo |

## 4. Nhật ký theo ngày

### Ngày 03/11/2026 — mốc mới nhất

| Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- |
| Dọn TB/runner và file local |400 file cũ đã archive/hash rồi bỏ khỏi cây làm việc; cache/binary/work/wave dọn; giữ bộ verification tái lập, bỏ đường dẫn home khỏi runner hiện hành | ✅ phạm vi dọn |
| Model/RTL quire Q12-1024 |Main10M/4 seed,19428 chuỗi>12,38 chuỗi1024; unit/model/Python/ModelSim0 mismatch.19 strict lint/26 instance+1 BUFG đầy đủ; nguồn dùng chung NF/F nguyên hash | ✅ chức năng |
| Timing quire và nghiệm thu cuối |OOC A35T10ns:10339 LUT/4453 FF;setup−12.016ns,hold+0.015ns. Cần pipeline/giảm fanout align→bank; chưa Fmax/board hoặc MAC_Q12_VERIFIED | processing |

### 4.0. Ngày 02/11/2026 — mốc mới nhất

| Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- |
| Dùng chung nhân NF/F, gọn wrapper và kiểm IO |31 module active;143934016 unit và7.2M MAC completed/0 mismatch;ModelSim core53249 case,MAC mỗi bản29820 completed;31 strict lint/68 instance+2 BUFG đủ cổng; nguồn cũ đã lưu ZIP/hash | ✅ phạm vi pilot |
| Nghiệm thu/PPA hợp đồng FULL_TERM |Main520M/quota regime chưa đạt;coverage line F và branch NF/F chưa đủ;paired accuracy/PPA/quire còn mở. Chi tiết seed,lệnh,tool,hash trong summary hiện hành | processing |

### 4.1. Cách cập nhật

- Mỗi dòng ghi một mốc hoặc nhóm công việc: kết quả chính, trạng thái và phần còn lại. Gộp sửa lỗi, build, test và cập nhật tài liệu vào mốc liên quan.
- Chỉ thêm dòng khi đạt mốc mới hoặc có thay đổi đáng kể; cập nhật đồng thời bảng tuần. Chi tiết tối ưu/kiểm chứng/timing để trong Optimization và raw reports; PLAN chỉ giữ phần xây dựng.
- Các bảng dưới đã gom từ nhật ký chi tiết trước đây, giữ ngày và diễn biến chính. Kết quả đạt ngưỡng TableI không đồng nghĩa đã xác minh baseline gốc.

### 4.2. Ngày 03/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Rà soát và hoàn thiện đặc tả | Đối chiếu tài liệu/mã nguồn, xác định phần còn thiếu; cập nhật SPEC v1.3 và tiến độ | ✅ |
| 2 | Xác nhận nền tảng L0/L1 | Build lại Linux/Windows, kiểm thử đạt; lưu thông tin tái chạy | ✅ |
| 3 | Gate1 — parser/packer và nhân exact | Bổ sung phạm vi kiểm thử theo SPEC; nghiệm thu đạt. Round riêng được hoàn thiện ngày04/10 | ✅ |
| 4 | RTL cơ sở | Bổ sung và mô phỏng LOD/LZD đạt; hai shifter mới kiểm mô hình Python, còn mô phỏng RTL | processing |

### 4.3. Ngày 04/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Hoàn tất nền tảng L1 — tuần3 | Sửa và kiểm chứng round/parser; regression Gate1 đạt | ✅ |
| 2 | Bộ nhân lặp L1 | Triển khai và kiểm chứng thuật toán, ngoại lệ và ví dụ bài báo | ✅ |
| 3 | Baseline bài báo — tuần4 | Đối chiếu nguồn và hoàn thiện bộ đo; từ chưa đạt đến source TableI đạt, maxProposed0,984213 điểm %. LUT/width/generator gốc còn mở | processing |
| 4 | Cải tiến OPS trong L1 | Tích hợp E/M và nghiệm thu số học đạt; chưa đo PPA của cải tiến này | ✅ |
| 5 | Khảo sát OPS trên FPGA | Mô phỏng và đo PPA khối OPS riêng; có kết quả đánh đổi tài nguyên/độ chính xác | ✅ |
| 6 | Bộ cộng L1 — tuần5 | Triển khai, đối chuẩn và nghiệm thu đạt; sẵn sàng ghép MAC | ✅ |
| 7 | Tổ chức hồ sơ tiến độ | Đồng bộ tài liệu/kết quả; rút gọn bảng theo mốc lớn và đánh số lại mục | ✅ |
| 8 | MAC L1 — tuần6/Gate1B | Hoàn thiện MAC v0/v1, tích lũy và API; nghiệm thu Linux/Windows, UBSan và regression đạt | ✅ |
| 9 | Hai shifter RTL — tuần7 | Sửa RTL/testbench và mô phỏng ModelSim đạt; Vivado runtime còn thiếu license, parser chưa hoàn thành | ✅ |
| 10 | Slide datapath LOD/LZD | Hoàn thành 4 slide phân rã kiến trúc đến cổng logic, sơ đồ chỉnh sửa trực tiếp trong PowerPoint | ✅ |

### 4.4. Ngày 05/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Parser RTL — tuần7 | Chốt hợp đồng, hoàn thiện tổ hợp và pipeline hai tầng; kiểm số học, reset và valid/ready trên ModelSim đạt, sẵn sàng ghép packer | ✅ |
| 2 | Slide báo cáo parser | Hoàn thành 3 slide nền trắng: datapath ngang, giao diện giải mã và pipeline/reset; sơ đồ chỉnh sửa trực tiếp trong PowerPoint | ✅ |

### 4.5. Ngày 06/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tinh chỉnh parser theo kiến trúc bài báo | Chốt cnt/FRB ở P1, tạo regime ở P2 để giảm thanh ghi mô tả; kiểm lại đạt, đồng bộ SPEC và slide. Số FF vật lý chưa đo do thiếu license tổng hợp | ✅ |
| 2 | Rà soát và đồng bộ hợp đồng SPEC | SPEC v1.4 chốt quy ước cạnh, profile RTL, reset, lịch core và phân tầng packer RNE P1/P2; đồng bộ PLAN/README/điểm mơ hồ. Packer RTL tiếp tục theo kế hoạch | ✅ |

### 4.6. Ngày 07/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Packer RTL — tuần8 | Hoàn thiện RNE P1/P2 và TRUNC; kiểm số học, flags, reset/stall và ghép parser→packer đạt,0 mismatch. Đồng bộ SPEC/PLAN và log tái lập | ✅ |
| 2 | Khảo sát tài nguyên/timing packer | Rút ngắn P2 thành một bộ cộng; kiểm tương đương đạt, giảm LUT và đạt setup100MHz ở ba seed mỗi mode cùng boundary. Chưa PPA full MAC | ✅ |

### 4.7. Ngày 08/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Xác minh baseline từ journal2024 | Đọc và đối chiếu nguồn, kiểm predictor đạt; tăng căn cứ cho ứng viên hiện tại. Còn hoàn thiện provenance baseline, đồng bộ SPEC/PLAN/README | processing |
| 2 | Hợp đồng và kiểm width/cut accumulator | Hoàn thành mô hình hữu hạn, kiểm chức năng và đo cùng corpus. Profile fig3 chưa đạt ngưỡng TableI; baseline gốc tiếp tục processing | ✅ |
| 3 | Kiểm baseline bằng vector phân biệt | Hoàn thành bốn bước, kiểm trace và đo200M. Loại source không khớp ví dụ gốc; các ứng viên cut12 chưa đạt TableI. Baseline gốc giữ processing | ✅ |
| 4 | Khởi động RTL nhân — tuần9 | Chốt giao diện/lịch và kiểm OPS/SAC tổ hợp đạt; lập kế hoạch SBM, lõi paper, controller và Gate2. Tuần9 tiếp tục processing | ✅ |

### 4.8. Ngày 09/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Lõi nhân RTL và tích hợp standalone — tuần9 | Hoàn thiện số học, controller và multiplier; lượt phân tầng16,8 triệu đạt0 mismatch và coverage chức năng. Còn lint/harness chính thức để đóng Gate2 | processing |
| 2 | Đối chiếu paper bằng RTL tối thiểu | Ghép top paper tự chạy từ A/B; kiểm từng vòng và kết quả đạt0 mismatch, giữ nguyên trace/Fig.4. Baseline gốc/TableI còn processing | ✅ |
| 3 | Hồ sơ kiểm chứng và bảo toàn dữ liệu | Đồng bộ tài liệu, lưu compiler/seed/lệnh/log/hash; đã commit và push mã/báo cáo kiểm chứng lên GitHub (5163797) | ✅ |
| 4 | Rà soát baseline theo nguồn | Phân biệt SAC/cách đếm vòng giữa các nguồn; kiểm packer Fig5 độc lập đạt0 mismatch. Audit hoàn thành, baseline gốc vẫn processing | ✅ |
| 5 | Kiểm baseline Posit bản2024 | Hoàn thành đối chiếu nguồn và pilot với oracle ES2; phát hiện bất nhất trong ví dụ. Chưa tái hiện Fig9, baseline gốc vẫn processing | ✅ |
| 6 | Kiểm báo cáo baseline mới | Chạy lại test và đối chiếu bằng chứng: có profile đạt ngưỡng thống kê, chưa đủ chốt baseline gốc; giữ trạng thái processing | ✅ |
| 7 | Tinh gọn kết quả kiểm chứng | Xóa cache và vector lớn có thể sinh lại; giữ báo cáo nghiệm thu, trace, coverage, seed/lệnh/hash và hướng dẫn tái lập | ✅ |

### 4.9. Ngày 10/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Nghiệm thu bộ nhân RTL — Gate2/tuần9 | Hoàn thiện lint và scoreboard trực tiếp;16,8 triệu so sánh cùng corner/reset/stall/coverage đạt,0 mismatch. Đồng bộ tài liệu nghiệm thu | ✅ |
| 2 | Phạm vi tiếp tục | Sẵn sàng triển khai adder/MAC tuần10–11; baseline gốc, regression cuối và PPA còn hoàn thiện theo mốc riêng | processing |
| 3 | Hướng dẫn tái chạy kiểm chứng | Tổng hợp build L0/L1, kiểm RTL và Gate2 trên WSL/ModelSim từ CMD; ghi dependency sau dọn cache và cách đọc kết quả | ✅ |

### 4.10. Ngày 11/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chuyển baseline và sắp lại timeline | Chốt non-fused đối chứng/fused biến thể; giữ Gate2, đồng bộ SPEC/PLAN. Lịch chính đến29/11, đệm trước05/12; chưa viết RTL mới | ✅ |
| 2 | Chốt tích nội bộ và đóng băng L1 — tuần4 | FLOOR/RNE prepack đã kiểm Linux/Windows/UBSan và regression đạt,0 mismatch; dữ liệu cũ không đổi. Fused signed residual chưa triển khai | ✅ |
| 3 | Đồng bộ mục tiêu NF/F và kế hoạch tuần10 | SPEC v1.8 sửa nhãn fused/matrix/PPA cho nhất quán; thêm checklist W10-01..07 tạm, gỡ sau nghiệm thu. Chưa triển khai hoặc kiểm RTL adder mới | ✅ |
| 4 | Dọn kết quả có thể tái sinh | Giải phóng khoảng3,74 GiB cache/corpus; giữ báo cáo, coverage, trace/hash và fixture nhỏ; manifest kiểm phần giữ không đổi, hướng dẫn build/sinh lại đã cập nhật | ✅ |

### 4.11. Ngày 12/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | W10-01 — hợp đồng adder | Chốt giao diện NF, width/adapter và ba tầng elastic; mapping Linux/UBSan0 mismatch, hash L1 giữ nguyên; kết quả hiện thực tiếp theo ở dòng2 | ✅ |
| 2 | W10-02..07 — RTL adder và bàn giao tuần10 | ModelSim comb/pipeline và20 triệu giao dịch ES2/ES3 đạt0 mismatch; corpus input NF/F chốt. Gỡ checklist W10; coverage AC04/MAC/Gate3/fused còn ở mốc sau | ✅ |

### 4.12. Ngày 13/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Audit tuần10 và lập kế hoạch tuần11 | Audit bằng chứng adder PASS/0 mismatch; bổ sung kiểm R(P_hat) khi carry trước ghép MAC, checklist NF/Gate3 và L1 F pilot. Chưa triển khai hoặc mô phỏng MAC mới | ✅ |
| 2 | Nghiệm thu NF/Gate3 và chuẩn bị fused — tuần11 | Xác nhận/sửa đường tích bằng adapter riêng; main10.000.000 và ModelSim28.512 completed,0 mismatch. Freeze NF manifest; F full-sum pilot100k đạt. Gỡ checklist tuần11; final coverage/accuracy/PPA và F RTL còn mở | ✅ |
| 3 | Làm rõ kiến trúc paper và NF | SPEC v1.12 gom khác biệt OPS, làm tròn, width/carry và pipeline; sửa mapping/metadata cho đúng RTL. Không đổi mã hoặc bằng chứng Gate3 | ✅ |

### 4.13. Ngày 14/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Rà toàn SPEC và đồng bộ hiện thực | SPEC v1.13 đồng nhất với RTL/model; audit W10/W11 PASS, nguồn và kết quả0 mismatch giữ nguyên. Near-cancellation W11 có cận trên4,20303%,chưa đạt30%; Gate3 đầy đủ processing,đã bổ sung việc coverage | ✅ |
| 2 | Slide datapath OPS, SAC và SBM | 7 slide nền trắng, sơ đồ tổng và phân rã theo RTL32/3; khối/mũi tên/bảng chỉnh sửa được, có lịch pipeline và ví dụ12 bit. Đã rà nguồn và kiểm bố cục, không đổi trạng thái coverage Gate3 | ✅ |
| 3 | Lập kế hoạch tuần12 | W12-01..07 ưu tiên coverage NF, oracle/hợp đồng/model fused và timing/pipeline; cập nhật [hồ sơ tuần đã chuyển](../../doc/Optimization.md#legacy-8-14) và checklist tạm. Chỉ hoàn thành việc lập kế hoạch, chưa chạy hoặc nghiệm thu công việc tuần12 | ✅ |
| 4 | Hoàn tất tuần11 — coverage NF/Gate3 | Main mới10 triệu/0 mismatch,near52,55548%;coverage chức năng/ModelSim corner đạt,nguồn đóng băng và audit PASS. Gỡ W11-COV,đánh dấu W12-01 đạt; final matrix,F_W/F RTL và accuracy/PPA còn mở | ✅ |
| 5 | Tối ưu OPS và kiểm lại NF | Masked popcount/candidates song song đã kiểm bit-exact,lượt NF10 triệu0 mismatch. OPS riêng giảm9,26%LUT4,medianFmax tăng3,64%;không thêm tầng M0. Timing/PPA toàn MAC còn mở | ✅ |
| 6 | Đồng bộ slide theo OPS mới | PowerPoint r5 vẽ rõ hai nhánh chạy song song và hai Swap MUX cuối;hidden củaY chuẩn bị trước swap. Giữ hình SAC/SBM,pipeline và ví dụ;đã rà cả7slide,khối/mũi tên/bảng vẫn chỉnh sửa được | ✅ |

### 4.14. Ngày 15/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Khảo sát mức fraction và số vòng | Có bảng/biểu đồ8–26bit trên300.000 cặp,ba phân bố;pilot/UBSan và oracle độc lập đạt. Đã tách sai số cắt đầu vào,FLOOR và giới hạn vòng;chưa chọn ngưỡng/cấu hình,chưa đổi RTL hoặc đo PPA | ✅ |
| 2 | Thử tối ưu critical path alignment | Ứng viên tách nhánh sf đã kiểm đơn vị/pipeline0 mismatch. Benchmark riêng tăng Fmax trung vị36,93%,LUT4 tăng3,96%,FF giữ nguyên;chưa đạt100MHz. Giữ bản thử riêng,chưa thay baseline hoặc đo fullMAC | ✅ |
| 3 | Khảo sát refactor normalization | Hai ứng viên đã kiểm đơn vị/pipeline0 mismatch;giảm4/7LUT4 nhưng chưa chứng minh cải thiện timing bền vững qua3seed. Giữ flags/sticky và RTL chính, lưu bản thử/report;chưa đo fullMAC | ✅ |
| 4 | Oracle và L1 fused — tuần12 | Chốt W32/flags/state;oracle p8 exhaustive và main phân tầng2.208.768 ca/nền tảng đạt0 mismatch. Giữ fraction12,RTL F và accuracy cuối còn ở tuần13–14 | ✅ |
| 5 | Timing toàn NF và bàn giao tuần12 | Đo post-route3seed,median45,07MHz/chưa100MHz;có5 đề xuất tối ưu và plan RTL F. Audit và sao lưu đạt;đã bàn giao tuần13 | ✅ |
| 6 | Lập kế hoạch tối ưu timing/LUT trước refactor | Bổ sung [Optimization §8.16](../../doc/Optimization.md#legacy-8-16) và thứ tự thử SAC: dịch cố định trước → gộp cộng scale → exhausted song song cùng controller; giữ bit-exact và đo từng bước. Đã cập nhật kế hoạch theo góp ý; chưa sửa RTL hoặc chạy lại regression/PPA | ✅ |
| 7 | Rà soát ghi chú và ưu tiên khối cơ sở | Đọc Note.docx, đối chiếu mã và kiểm các đẳng thức số học; xác định cách sửa count của parser và giới hạn các ước lượng LUT. Cập nhật thứ tự shifter/LOD trước SAC và khối lớn; chưa sửa RTL hoặc đo PPA mới | ✅ |
| 8 | Khảo sát primitive trên Xilinx | XSim7.275.184 đối chiếu/0 mismatch,lint197 lượt và108 P&R hoàn tất. R2R đạt200MHz;refactor có đánh đổi theo width/part,chưa thắng đồng nhất;giữ RTL chính. I/O OOC chưa closure,không suy tần số MAC/kit. Bảng/snapshot tại [Optimization §8.16.9](../../doc/Optimization.md#legacy-8-16-9) | ✅ |
| 9 | Cụ thể hóa kế hoạch RTL fused | Đối chiếu SPEC/guideline/L1 và bằng chứng tuần12; chốt phạm vi bản đầu, kế hoạch F1–F5 và W13-01..07, tiêu chí số học/protocol/STA. Đã đủ điều kiện bắt đầu; chưa sửa RTL hoặc chạy kiểm mới | ✅ |
| 10 | Triển khai và kiểm RTL fused | F1–F5/top main10M và pipeline/XSim đạt0 mismatch; strict lint sạch,STA A35T100MHz R2R đạt,1520LUT/815FF. Audit nguồn/kết quả đạt; còn final per-n/coverage/CDC và paired NF/F PPA | ✅ |
| 11 | Lập kế hoạch tuần14 cho Codex | Đã lập phạm vi final per-n NF/F, AC04, paired accuracy và comparator NF EXACT_EN0; mã công việc hiện hành được đánh lại tại mục3.2 ngày18/10. Chưa chạy nghiệm thu | processing |

### 4.15. Ngày 16/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Phân loại RTL và cập nhật đường dẫn | 55 file giữ nguyên byte; tách common/parser/packer/multiplier/adder/NF/F, paper, candidate và benchmark. Có file list production và bản đồ thư mục; runner WSL/ModelSim/Vivado dùng đường dẫn mới. Lint 17 profile sạch; smoke NF/F mỗi bản10.000, ModelSim143.976 và XSim8.192 đều0 mismatch | ✅ |
| 2 | Dọn dữ liệu kiểm chứng | Xóa build/cache có thể tái tạo, thu hồi khoảng3,9GB; giữ báo cáo, thống kê, biểu đồ, coverage, seed/lệnh/hash, snapshot nguồn và fixture. Có script dry-run/apply và kiểm hash dữ liệu giữ lại; không thay trạng thái nghiệm thu số học/PPA | ✅ |
| 3 | Tối ưu ba primitive dùng chung NF/F | Đã promote LOD nhóm4 riêng MODE0,N31/32; hai shifter giữ gốc theo timing chéo. Unit21.576.912/0 mismatch,524 lint,510 P&R và114 netlist đạt; smoke NF ES2/ES3/F mỗi bản10.000 đạt. Không suy Fmax toàn MAC | ✅ |
| 4 | Parser dùng một detector để giảm diện tích | Cả comb/pipeline dùng XOR tail + một LOD; giữ giao diện và hai tầng. Kiểm4.984.616 lượt parser/biên tham số0 mismatch,33 strict lint và NF ES2/ES3/F mỗi bản10.000 đạt.24 P&R: median225→205LUT (−8,89%),FF không đổi; timing thay đổi theo part/profile. SPEC/PLAN đồng bộ; chưa đo lại full MAC hoặc đóng200MHz | ✅ |
| 5 | Khảo sát refactor prepack và STA toàn NF | Candidate mapping hằng đạt1.592.064 leaf,10M NF và82.944 ModelSim corner0 mismatch;12 P&R cho median STA−0,31% A35T/−2,45% A100T, FF không đổi. Giữ production cũ, lưu candidate/bằng chứng; chưa đạt100MHz và chưa tách pipeline hoặc làm bước tiếp | ✅ |

<!-- OPT03_REPORT_START:docs/TIEN_DO_DO_AN.md -->
### 4.16. Ngày 17/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tách pipeline RNE tích của NF — OPT-03 | Đã triển khai và kiểm chức năng/lịch giao dịch; số đo và giới hạn ở Optimization8.21. Final NF/F và Gate4 còn mở | ✅ |
| 2 | Đo một lượt toàn NF A35T, kiểm hai tầng kề P1 | Đã có báo cáo theo phạm vi đo; lỗi truy vấn phụ và giới hạn được giữ ở Optimization8.22 | ✅ |
| 3 | Thử OPT-02b cho A1 align | Đã kiểm bit-exact và đo candidate; chưa promote. Xem Optimization8.23 | ✅ |
| 4 | Thống kê STA tất cả bank NF OPT-02b | Đã thống kê đủ bank của candidate; bảng setup/hold và phạm vi OOC tại Optimization8.24 | ✅ |
| 5 | Sắp xếp tài liệu kiến trúc và tối ưu | PLAN giữ build/thuật toán baseline/NF/F; chuyển tối ưu và bằng chứng sang doc/Optimization.md, gỡ checklist hoàn thành, gom việc mở vào mục3.1–3.4. Không đổi RTL hoặc chạy lại kiểm chứng | ✅ |
| 6 | Thu hẹp thiết bị khảo sát | Các phép đo tiếp theo chỉ A35T xc7a35tcpg236-1; bỏ yêu cầu A100T/cross-part, giữ dữ liệu lịch sử. Chỉ cập nhật tài liệu, chưa chạy kiểm chứng | ✅ |
| 7 | Chuẩn hóa constraint A35T-C1 | Tách clock và mẫu I/O, kiểm nạp bằng Vivado; bỏ budget2,5ns khỏi mặc định mới. Không đổi RTL hoặc đo Fmax mới; timing giao tiếp/board còn mở | ✅ |
| 8 | Giữ nguyên budget benchmark100MHz — C2 | Giữ input2,5/2,5ns và output0/0,5ns; khi sweep báo Internal R2R riêng, chưa mở ngoại lệ thứ hai. Chỉ cập nhật cấu hình, chưa đo lại STA | ✅ |
<!-- OPT03_REPORT_END:docs/TIEN_DO_DO_AN.md -->


### 4.17. Ngày18/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Khảo sát SAC,product magnitude và sticky theo8.25 | Leaf/pilot/round-trip và tổ hợp NF10M+F10M/0 mismatch; ModelSim NF/F đạt. Matched A35T-C2 ba chiến lược, bảng kết quả ở Optimization8.28. Giữ candidate,chưa promote production hoặc đóng Gate4 | ✅ |
| 2 | Đặc tả OPT-02c cho A1 và sàng lọc mục3.3/3.4 | Bổ sung Optimization8.29 (`OPT-02c`: tách `clamp` khỏi `shift_amount`, bit-check `>` F+2, tra `jam/tail` song song trong A1, 0 FF); đóng các nhánh tối ưu dư thừa (`OPT-10B`, `C-prefix`, `OPT-04/06`), chỉ giữ `OPT-02c` và promote `OPT-07/08` trước W14 | ✅ |
| 3 | Tối ưu, promote và khóa RTL trước W14 | OPT-02c+05+09+10A đã vào production38 module; NF10M/0 mismatch, F10M kế thừa theo hash và smoke mới;37 strict lint/ModelSim NF/F đạt. A35T100MHz setup/hold đạt3 strategy. Release POSIT_MAC_RTL_20261018_OPT02C đã khóa; W14 final và Gate4 chưa chạy | ✅ |
| 4 | Sắp lại trình tự tuần14 | Tách chuẩn bị coverage khỏi đóng coverage; bổ sung harness/pilot trước freeze/main,định rõ điểm dừng và comparator trước bàn giao PPA. Chỉ sửa kế hoạch,không chạy TC W14 hoặc đổi RTL | ✅ |
| 5 | Đánh lại mã tuần14 theo thứ tự thực hiện | W14-01..11 tương ứng các bước chính, W14-12 exact riêng; đồng bộ TC và tham chiếu. Pilot W14-04, main F/NF W14-06/07; chỉ đổi mã kế hoạch, không chạy nghiệm thu | ✅ |
| 6 | Mở lại candidate trên120MHz | Giữ reference100MHz và mở study mới,review OPT-12/13/14 có điều kiện; chưa sửa RTL,chưa chạy STA mới hoặc W14. Chi tiết8.31.6 | ✅ |
| 7 | Thử OPT-12 trên120MHz | Negate đạt10M NF+10M F/0 mismatch và ModelSim; post-route120,48MHz có flow NF/F PASS. Giảm154LUT NF Default so reference cùng clock; chờ chọn/promote/khóa,không chạy W14 | ✅ |
| 8 | Khóa RTL120MHz trước W14 | Promote đúng hai parser OPT-12 negate; Explore8,3ns NF/F setup/hold đạt; audit và backup. Không chạy lại regression lớn hoặc W14 | ✅ |
| 9 | Thử XCVU9P ngoài nền A35T | Đã setup NF/F và thử NF; thiếu device support trong Vivado, chưa có timing/PPA. Giữ khóa120MHz; xem Optimization8.32 | processing |
| 10 | Thực hiện W14-01 đến W14-06 | Review/counters/harness,pilot,accuracy calibration và matrix freeze đạt; MAC F90M/0 mismatch,corner/ModelSim đạt. Còn W14-07..12; chi tiết Optimization8.33 | ✅ |
| 11 | Hoàn thành W14-07..11 | NF250M+NF-EX010M mới/0 mismatch;kế thừaF90M đúng hash. AC04 chính,9M paired standalone accuracy và audit/replay đạt;archive/backup cuối phiên. Exact/AC02 hoãn riêng;chuyển W15 matched PPA | ✅ phạm vi kỹ thuật |
| 12 | Slide datapath RTL NF/F | Hoàn tất7 slide native PowerPoint:NF14 tầng,F13 tầng;phóng to parser/OPS,SAC/SBM,NF/F tail vàfeedback. Theo releaseOPT12_120,giữ đủMUX/FF/metadata quan trọng;không sửa RTL hoặc chạy STA/regression mới | ✅ |

### 4.18. Ngày 19/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Thử OPT-15 giảm LUT MAC NF | Hai parser input + packer dùng chung đạt11,08M completed/bản,0 mismatch và ModelSim bốn format. A35T120,48MHz đạt setup/hold; LUT2424→2104 (−13,20%),FF931→806 (−13,43%). Giữ latency/II; chỉ là candidate,một run Explore,chưa promote. Xem Optimization8.35;không push GitHub | ✅ thử nghiệm |
| 2 | Chọn nền ứng viên tối ưu tiếp NF/F | Chọn NF OPT-15 combined; chốt F dùng hai parser input và giữ một packer cuối. Các tối ưu sau đi từ nền này bằng revision mới. F OPT-15 chưa triển khai/kiểm/STA,gói chung chưa promote; xem Optimization8.35.5 | ✅ quyết định / processing triển khai F |

### 4.19. Ngày 20/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Sửa datapath NF/F cho hướng chia sẻ tài nguyên | Hai slide native PowerPoint thể hiện rõ parser A/C–B,MUX và bank FF;không thêm lịch chu kỳ. F chia sẻ parser được ghi dự kiến tại thời điểm vẽ;RTL thử sau đó ở mốc2 | ✅ |
| 2 | Thử F hai parser và reuse bộ cộng NF | OPT-15 parser2 và OPT-16 shared_add đạt10,1M completed/bản,0 mismatch,ModelSim và một run Explore120,48MHz. OPT-16 thêm100k luồng không stall,giảm2 chu kỳ;LUT/FF1362/815→1345/645. Parser2 riêng1262/771 tốt hơn về LUT. Giữ hai candidate/chưa promote,chưa Gate4;chi tiết Optimization8.36 và JSON nguồn;không push GitHub | ✅ thử nghiệm / chờ chọn |
| 3 | Slide datapath tổ hợp bộ cộng A1/A2/A3 | Hoàn tất5 slide PowerPoint đen trắng,native shapes:chọn/dịch/jam/clamp A1,cộng/trừ A2,normalize/Zero/NaR/sticky/cờ A3. Giữ nhãnMUX và width theo RTL32/3 hiện tại,không vẽ FF hoặc sửa RTL | ✅ |

### 4.20. Ngày 22/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chốt duy nhất posit32/ES3 | Đồng bộ SPEC v1.21, PLAN, README và phạm vi nghiệm thu mới; bỏ yêu cầu tiếp tục8/16/32-ES2, giữ chứng cứ lịch sử. Chưa sửa RTL/model/freeze hoặc chạy mô phỏng mới; còn đồng bộ default NF và kiểm exact32/3,matched PPA | ✅ quyết định / processing hiện thực |

### 4.21. Ngày 23/10/2026 — tiếp phiên cố định32/3 bắt đầu22/10

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cố định RTL và kiểm lại32/3 |54 module không public parameter,cổng literal;NF10M+F10M và740k so sánh tổ hợp/0 mismatch. ModelSim NF27.864+F8.192 completed/0 mismatch,abort tách riêng. Giữ snapshot,hash,seed20261022 và lệnh;khóa release mới,L1/oracle không sửa. Chưa STA/PPA/AC02 hoặc final per-n/AC04 mới;backup xác nhận theo push cuối phiên | ✅ chức năng |
| 2 | Hoàn thiện tái chạy và tài liệu | Build lại từ production,pilot100k mỗi NF/F,ModelSim NF/F và740k so sánh tổ hợp lặp lại đạt0 mismatch;runner không cần format generic. Bổ sung phục hồi comparator từ ZIP có SHA256,giữ mọi kết quả cũ;hướng dẫn luồng fixed tách khỏi lệnh đa format lịch sử | ✅ |
| 3 | Dọn cache và bảo toàn đối chứng | Xóa2.777 file build/library/cache,giải phóng616,5 MiB;34.725 file giữ lại được kiểm SHA256 sau xóa. Giữ fixture,raw coverage,bảng CSV/JSON,report/log,snapshot và hash. Không sửa RTL/L1/oracle hoặc chạy lại corpus;biên bản ở results/cleanup_cache_20261023 | ✅ |

### 4.22. Ngày 28/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Soạn mục 3.2 và sơ đồ kiến trúc tổng thể | Nội dung báo cáo và một slide PowerPoint native mô tả hai top NF/F riêng, giao tiếp và tích lũy; không vẽ thanh ghi. Đối chiếu RTL production32/3, kiểm hình và cấu trúc PPTX; không sửa RTL hoặc chạy lại kiểm chứng số học | ✅ |
| 2 | Lập và tinh gọn OPT-17 theo ý tưởng sinh viên | Optimization8.37 giữ lịch E0–E4:hai Parser A/C–B,một slot OPS,một bank C;cho stall kéo dài tại E4,tối đa hai independent,tích lũy giữ tuần tự. Chỉ cập nhật kế hoạch;chưa sửa RTL/SPEC,tạo candidate hoặc chạy kiểm/STA | ✅ lập kế hoạch / không triển khai |

### 4.23. Ngày 29/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
|1 | Lập đối chứng ba Parser và chu kỳ chuỗi tích lũy | Optimization8.38 thêm3P-P2/3P-OPS đối chiếu2P-OPS,giữ lịch E0–E4;phân tích q thực tế,N1.024/1M và phụ thuộc tổng trước. Chỉ tính lịch/chỉnh tài liệu,chưa sửa RTL/SPEC hoặc chạy mô phỏng/STA | ✅ lập kế hoạch / không triển khai |
|2 | Chốt hợp đồng approximate không FLOOR | SPEC v1.23 §4.3 và Optimization8.39 chốt FULL_TERM26 bit/Q24,n0..12,RNE NF/F;đồng bộ README/PLAN/hướng dẫn.L1/RTL/TB/runner/freeze giữ nguyên,người dùng tự sửa RTL/TB.Chưa có mô phỏng/accuracy/PPA profile mới | ✅ hợp đồng / không triển khai |
| 3 | Lưu trữ module hỗ trợ và làm gọn cây RTL | ZIP ngoài rtl giữ nguyên byte nguồn/TB và hash;54 đường dẫn đã chuyển,46 module MAC còn lại lint NF/F đạt.Thử giải nén/audit hai checkpoint54 đạt.Phát hiện51 RTL/manifest đã khác Git gốc từ trước;giữ cả hai bản,không kế thừa kết quả10M cho nguồn hiện tại.Không sửa nội dung RTL/TB | ✅ |

### 4.24. Ngày30/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chốt approximate-only và phạm vi bỏ exact | SPEC v1.24:32/3,FW12,FULL_TERM26/Q24,n0..12;NF/F cùngapprox,AC02 exacthardware không áp dụng.Đã lập danh mục exact-only/mixed/shared.Chưa sửa/xóa RTL/L1/TB hoặc chạy verification;core NF26 và runner mới còn phải triển khai | ✅ hợp đồng / processing hiện thực |

### 4.25. Ngày 02/11/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chốt spec approximate12 và mở rộng quire | SPEC v1.26:OPS1/n12 mặc định,FULL_TERM26/Q24 không FLOOR,block/prepack/adder5/testbench/52 điểm giữ ngưỡng;thêm hợp đồng quire,bounds,clear/MAC/READ và gate riêng. Đồng bộ tài liệu,lưu bản trước sửa/hash;chỉ kiểm công thức/tài liệu,không sửa RTL/L1/TB hoặc chạy nghiệm thu mới. Live còn FLOOR;quire chưa triển khai | ✅ đặc tả / processing hiện thực |

### 4.26. Mẫu cập nhật tiếp theo

Thêm mục `Ngày DD/MM/YYYY` trước phần mẫu này; đánh số STT từ1 cho mỗi ngày.

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| … | Mốc lớn được thực hiện | Tóm tắt đã đạt gì và còn thiếu gì | ✅ / processing / không |


### OPT-17 — kiểm chứng candidate29/10/2026, chưa promote

Study riêng ở experiments/opt17_20261029;giữ lịch2P-OPS,A/C–B,một bank C,hai credit,
accumulation tuần tự và core release theo result handshake.Đã dựng FULL_TERM Q24/26 bit
cùng reference3P;không sửa arithmetic của production trong phiên này.
Golden C++ mới đối chiếu oracle raw decoder/selected-bit product/full-grid integer:
2.053.248 checks đạt.Cả8 top lint và pilot100k đạt;candidate2P NF/F mỗi bản10M
completed,0 mismatch,tích từng vòng/d/5flags,credit tối đa2,reset/stall/accumulation đạt.
ModelSim CK2Q1ns:mỗi bản8.192 completed,0 mismatch.
Nguồn/testbench từng lượt được giữ trong source_bundle.zip và build manifests.
Chưa đóng toàn OPT-17:benchmark96 điểm bị chặn trước thực thi vì automatic approval
reviewer hết hạn mức;matched PPA reference/3P chưa chạy.PPA chỉ candidate2P đã chạy
3strategy trên A35T8,3ns,không phải bằng chứng cải thiện so parent.
Phát hiện4 file parent thay đổi trong lúc chạy:SAC fixed2/fixed3,OPS fixed2 và F wrapper.
Không ghi đè các thay đổi đó;20M chỉ áp dụng snapshot đã build,không tự áp dụng live mới.
Các phiên bản live khác được giữ dưới nhãn unverified_live_parent trong source bundle.
Chi tiết số liệu,phạm vi và phần còn thiếu:results/opt17_20261029/summary.json.
Không dùng SoftPosit ES2 làm oracle cho32/3;không claim Python/C++SoftPosit tương đương
hoặc nghiệm thu AC02/per-n10M,power,board hay production promotion.
