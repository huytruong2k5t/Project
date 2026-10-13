# TIẾN ĐỘ ĐỒ ÁN — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

**Ngày cập nhật:** 14/10/2026 (giờ Việt Nam)  
**Sinh viên:** Đan Huy — HK261, HCMUT  
**Đề tài:** Thiết kế và kiểm chứng lõi IP Posit MAC trên FPGA, có mở rộng ASIC.  
**Tài liệu chi tiết:** [SPEC v1.13](../Posit_MAC/SPEC_Posit_MAC_IP.md), [PLAN L1](../Posit_MAC/l1/PLAN.md), [README L1](../Posit_MAC/l1/README.md).

**Cách chạy kiểm chứng:** [Hướng dẫn WSL và ModelSim từ Windows CMD](HUONG_DAN_CHAY_WSL_MODELSIM.md).

File này theo dõi **mốc lớn**: hiện trạng ở mục1, việc còn lại ở mục2, tiến độ tuần ở mục3 và cập nhật theo ngày ở mục4. Lệnh chạy, số vector, seed, tên file và log kỹ thuật lưu trong README/PLAN và thư mục `Posit_MAC/results`.

**Trạng thái:** `✅` = hoàn thành phạm vi của dòng và có kiểm chứng; `processing` = đã làm một phần hoặc còn thiếu tiêu chí; `không` = chưa thực hiện.

## 1. Tổng quan

Đã hoàn thành nền tảng L0, Gate1 của L1 và bộ cộng tuần5. Bộ nhân lặp L1 đã được kiểm chứng; profile source từng đạt ngưỡng TableI nhưng không khớp output ví dụ gốc. Baseline gốc bài báo chưa xác định; giữ nghiên cứu phụ. Mục tiêu chính chuyển sang MAC non-fused làm baseline nội bộ và fused làm biến thể so sánh.

MAC L1 đã hoàn thành và nghiệm thu Gate1B. Parser tuần7, packer tuần8 và chuỗi parser→packer đã kiểm chứng đạt ở cấp khối. Gate1/Gate1B/Gate2 multiplier✅; NF đã đạt mốc số học/protocol tuần11; coverage Gate3 đầy đủ còn bổ sung. Gate4,fused và ma trận cuối còn mở. Đã khảo sát PPA riêng cho OPS và packer; chưa có PPA toàn hệ thống, packer benchmark riêng đạt setup100MHz ở ba seed mỗi mode sau tối ưu P2.

## 2. Công việc còn lại và ưu tiên

| Mốc lớn | Trạng thái | Phần cần hoàn thiện |
| --- | --- | --- |
| Baseline nội bộ và so sánh NF/F | processing | Đã chốt hướng: non-fused làm đối chứng, fused là mục tiêu chính; cần hoàn thiện RTL, oracle, accuracy và PPA. Baseline paper giữ nghiên cứu phụ |
| MAC L1 — Gate1B | ✅ | MAC v0/v1, tích lũy và API đã triển khai, kiểm chứng đạt |
| RTL và kiểm chứng tích hợp — Gate2/3 | processing | Gate2/adder và NF numeric/protocol đã kiểm; còn coverage near30% để đóng strict Gate3,ma trận cuối và fused |
| PPA, mở rộng và hồ sơ — Gate4 | không | Đo toàn hệ thống, đối chiếu baseline; thực hiện mở rộng đã chọn, báo cáo và demo |

**Thứ tự tiếp theo:** oracle/L1 fused → RTL fused → paired regression/accuracy → PPA → báo cáo. NF numeric/protocol đã đạt; bổ sung coverage Gate3 theo PLAN8.7. Hoàn tất chính29/11, đệm30/11–04/12 trước05/12/2026; chi tiết tại PLAN L1 mục8 và SPEC§11.8.

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
| 9 | RTL bộ nhân lặp — Gate2 | ✅ | Multiplier đã nghiệm thu trên16 cấu hình,0 mismatch; lint và coverage đạt phạm vi tuần9. Baseline gốc theo dõi riêng ở tuần4 |
| 10 | RTL adder và chốt so sánh NF/F | ✅ | Hoàn tất12/10: comb/pipeline, oracle/lượt lớn0 mismatch; matrix và corpus input đã chốt. Cần xác minh R(P_hat) khi carry trước ghép NF/F; coverage cuối/MAC/fused còn mở |
| 11 | MAC non-fused — Gate3 | processing | NF10 triệu/0 mismatch và F pilot đạt; rà soát14/10 phát hiện chưa đạtnear30%,cần bổ sung coverage trước strict Gate3 |
| 12 | Oracle/L1 fused và PPA sơ bộ NF | không | 26/10–01/11: width/cut/đuôi có dấu, kiểm triệt tiêu; chốt hợp đồng F và khả năng công cụ |
| 13 | RTL fused | không | 02–08/11: triển khai theo L1 đã kiểm, pilot số học/protocol; không mặc định exact |
| 14 | Regression và accuracy paired NF/F | không | 09–15/11: nghiệm thu đúng riêng từng bản, coverage và corpus chung |
| 15 | PPA hai bản và bản thảo — Gate4 | không | 16–22/11: cùng điều kiện,≥3 run/config; accuracy/timing/II/tài nguyên và kết luận |
| 16 | Báo cáo, demo và bảo vệ | processing | 23–29/11: chốt hồ sơ/tái lập/slide/demo; hiện mới có slide các khối. Đệm30/11–04/12 |

## 3.1. Bổ sung coverage tuần11

| Mốc | Công việc còn lại | Trạng thái |
| --- | --- | --- |
| W11-COV | Corpus>=30% near-cancellation với C_eff; counters per-run/polarity và packer bins; pilot/oracle/regression0 mismatch,audit/hash mới trước strict Gate3 | processing |

Giữ nguyên kết quả numeric/protocol13/10; chi tiết PLAN8.7/SPEC§11.11. Gỡ bảng này sau khi có bằng chứng bổ sung đạt,không theo ngày dự kiến.

## 4. Nhật ký theo ngày

### 4.1. Cách cập nhật

- Mỗi dòng ghi một mốc hoặc nhóm công việc: kết quả chính, trạng thái và phần còn lại. Gộp sửa lỗi, build, test và cập nhật tài liệu vào mốc liên quan.
- Chỉ thêm dòng khi đạt mốc mới hoặc có thay đổi đáng kể; cập nhật đồng thời bảng tuần. Chi tiết kỹ thuật để trong README/log.
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

### 4.14. Mẫu cập nhật tiếp theo

Thêm mục `Ngày DD/MM/YYYY` trước phần mẫu này; đánh số STT từ1 cho mỗi ngày.

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| … | Mốc lớn được thực hiện | Tóm tắt đã đạt gì và còn thiếu gì | ✅ / processing / không |
