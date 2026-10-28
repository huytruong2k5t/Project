# TIẾN ĐỘ ĐỒ ÁN — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

**Ngày cập nhật:** 23/10/2026 (giờ Việt Nam)
**Sinh viên:** Đan Huy — HK261, HCMUT  
**Đề tài:** Thiết kế và kiểm chứng lõi IP Posit MAC trên FPGA, có mở rộng ASIC.  
**Tài liệu chi tiết:** [SPEC v1.22](../SPEC_Posit_MAC_IP.md), [PLAN L1](../l1/PLAN.md), [README L1](../l1/README.md), [Optimization](../../doc/Optimization.md).

**Cách chạy kiểm chứng:** [Hướng dẫn WSL và ModelSim từ Windows CMD](HUONG_DAN_CHAY_WSL_MODELSIM.md).

File này theo dõi **mốc lớn**: hiện trạng ở mục1, việc còn lại ở mục2, tiến độ tuần ở mục3 và cập nhật theo ngày ở mục4. Chi tiết tối ưu, kiểm chứng/synthesis/STA lưu trong Optimization; PLAN giữ kiến trúc/build. Tiến độ chỉ giữ mốc, công việc còn mở và nhật ký; raw bằng chứng ở results.

**Trạng thái:** `✅` = hoàn thành phạm vi của dòng và có kiểm chứng; `processing` = đã làm một phần hoặc còn thiếu tiêu chí; `không` = chưa thực hiện.

## 1. Tổng quan

**Hiện hành23/10:** release `POSIT_MAC_RTL_20261022_FIXED32_3`,54 module fixed32/3 đã kiểm chức năng. NF10M+F10M completed/0 mismatch;37 biến thể tổ hợp740k so sánh,ModelSim36.056 giao dịch hoàn tất/0 mismatch,54 strict lint. L1/oracle không sửa. Các số120,48MHz/W14 và candidate OPT15/16 bên dưới vẫn gắn với nguồn cũ; không suy thành STA/PPA hoặc final coverage của release mới. Chi tiết tại results/fixed32_3_20261022/summary.json.

Đã hoàn thành nền tảng L0, Gate1 của L1 và bộ cộng tuần5. Bộ nhân lặp L1 đã được kiểm chứng; profile source từng đạt ngưỡng TableI nhưng không khớp output ví dụ gốc. Baseline gốc bài báo chưa xác định; giữ nghiên cứu phụ. Mục tiêu chính chuyển sang MAC non-fused làm baseline nội bộ và fused làm biến thể so sánh.

MAC L1/Gate1B, parser/packer, Gate2 multiplier và Gate3 NF đã có bằng chứng. L1 fused W32 và RTL F profile chính đã kiểm trong phạm vi công bố. NF production giữ lịch OPT-03, đã promote OPT-02c/05/09/10A và khóa38 module ngày18/10. Chi tiết số lượt/mismatch, freeze và timing lịch sử chuyển về Optimization; final approximate per-n/AC04,reset/interface review và paired standalone accuracy đã đạt W14;exact/AC02,matched PPA và Gate4 còn mở.

## 2. Công việc còn lại và ưu tiên

**Quyết định22/10:** chỉ posit32/ES3 cho thiết kế và nghiệm thu NF/F, theo lựa chọn sau trao đổi với giảng viên. Giữ FW12/FLOOR/RNE/OPS1/n0..8, F W32/Q29 và ngưỡng kiểm32/3. Các format khác lưu lịch sử; không tiếp tục exhaustive8/16 hoặc nghiệm thu32/2. Exact32/3 vẫn mở theo AC02 với oracle độc lập, không dùng SoftPosit ES2. Chỉ sửa phạm vi tài liệu; source/freeze và các kết quả cũ giữ nguyên. Hồ sơ mới phải tách số lượt32/3 khỏi tổng đa format cũ.

| Mốc lớn | Trạng thái | Phần cần hoàn thiện |
| --- | --- | --- |
| Khóa cấu hình duy nhất32/3 | ✅ phạm vi chức năng |54 module fixed,runner/mapping và wrapper synthesis đã đồng bộ;NF/F20M completed,ModelSim và kiểm tổ hợp0 mismatch. Còn STA/PPA mới,AC02 exact và final per-n/AC04;candidate lịch sử cần rebase riêng |
| Baseline nội bộ và so sánh NF/F | processing | RTL NF/F final approximate và paired standalone accuracy đã đạt; còn matched PPA. Baseline paper giữ nghiên cứu phụ |
| RTL và kiểm chứng tích hợp — Gate2/3 | processing | Gate2/adder, NF tuần11 và F profile chính đã kiểm; final approximate và coverage NF/F đã đạt;exact/AC02 vẫn mở riêng |
| PPA, mở rộng và hồ sơ — Gate4 | processing | NF CycloneIV45,07MHz là lịch sử; F A35T100MHz R2R đạt. Còn đo matched NF/F,AC02 và hồ sơ cuối; số đo riêng xem Optimization |

**Trạng thái tối ưu:** đã promote và khóa OPT-12 negate, release `POSIT_MAC_RTL_20261018_OPT12_120`, A35T Explore120,48MHz NF/F setup/hold đạt; OPT02C100MHz giữ lịch sử. Fraction12/W32, L1/oracle/latency và I/O budget giữ nguyên. Xem Optimization8.31.8. W14-01..11 đã đạt phạm vi bàn giao;tiếp theo matched PPA W15,W14-12/AC02 hoãn riêng. Hạn chính29/11, đệm30/11–04/12, hoàn thành trước05/12/2026.


## 3. Tiến độ theo tuần

Tuần1–9 giữ lịch sử; tuần10–16 có lịch dự kiến từ12/10/2026 theo hạn trước05/12. Ngày dự kiến không đồng nghĩa nghiệm thu đã đạt. Một phần công việc hoàn thành không đồng nghĩa cả tuần đã đạt.

| Tuần | Mốc cần đạt | Trạng thái | Kết quả chính / phần còn lại |
| --- | --- | --- | --- |
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

### 4.24. Mẫu cập nhật tiếp theo

Thêm mục `Ngày DD/MM/YYYY` trước phần mẫu này; đánh số STT từ1 cho mỗi ngày.

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| … | Mốc lớn được thực hiện | Tóm tắt đã đạt gì và còn thiếu gì | ✅ / processing / không |
