# TIẾN ĐỘ ĐỒ ÁN — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

**Ngày cập nhật:** 10/10/2026 (giờ Việt Nam)  
**Sinh viên:** Đan Huy — HK261, HCMUT  
**Đề tài:** Thiết kế và kiểm chứng lõi IP Posit MAC trên FPGA, có mở rộng ASIC.  
**Tài liệu chi tiết:** [SPEC v1.5](../Posit_MAC/SPEC_Posit_MAC_IP.md), [PLAN L1](../Posit_MAC/l1/PLAN.md), [README L1](../Posit_MAC/l1/README.md).

**Cách chạy kiểm chứng:** [Hướng dẫn WSL và ModelSim từ Windows CMD](HUONG_DAN_CHAY_WSL_MODELSIM.md).

File này theo dõi **mốc lớn**: hiện trạng ở mục1, việc còn lại ở mục2, tiến độ tuần ở mục3 và cập nhật theo ngày ở mục4. Lệnh chạy, số vector, seed, tên file và log kỹ thuật lưu trong README/PLAN và thư mục `Posit_MAC/results`.

**Trạng thái:** `✅` = hoàn thành phạm vi của dòng và có kiểm chứng; `processing` = đã làm một phần hoặc còn thiếu tiêu chí; `không` = chưa thực hiện.

## 1. Tổng quan

Đã hoàn thành nền tảng L0, Gate1 của L1 và bộ cộng tuần5. Bộ nhân lặp L1 đã được kiểm chứng; profile source từng đạt ngưỡng TableI nhưng không khớp output ví dụ gốc. Baseline bài báo vẫn cần hoàn thiện.

MAC L1 đã hoàn thành và nghiệm thu Gate1B. Parser tuần7, packer tuần8 và chuỗi parser→packer đã kiểm chứng đạt ở cấp khối. Gate1/Gate1B/Gate2 multiplier✅; RTL MAC tích hợp và Gate3/4 chưa đạt. Đã khảo sát PPA riêng cho OPS và packer; chưa có PPA toàn hệ thống, packer benchmark riêng đạt setup100MHz ở ba seed mỗi mode sau tối ưu P2.

## 2. Công việc còn lại và ưu tiên

| Mốc lớn | Trạng thái | Phần cần hoàn thiện |
| --- | --- | --- |
| Chốt baseline gốc | processing | Đã kiểm predictor, width/cut và vector phân biệt; loại profile không khớp ví dụ gốc. Còn hoàn thiện TableI, tie/cờ và cách sinh dữ liệu gốc |
| MAC L1 — Gate1B | ✅ | MAC v0/v1, tích lũy và API đã triển khai, kiểm chứng đạt |
| RTL và kiểm chứng tích hợp — Gate2/3 | processing | Gate2 multiplier đã nghiệm thu với scoreboard trực tiếp, lint và coverage; còn RTL adder/MAC và Gate3 |
| PPA, mở rộng và hồ sơ — Gate4 | không | Đo toàn hệ thống, đối chiếu baseline; thực hiện mở rộng đã chọn, báo cáo và demo |

**Thứ tự tiếp theo:** RTL adder tuần10 → RTL MAC tuần11/Gate3 → coverage/PPA/Gate4 → báo cáo và bảo vệ. Kế hoạch chi tiết tại PLAN L1 mục7.

## 3. Tiến độ theo tuần

Tuần theo lộ trình SPEC, chưa gắn với lịch học. Một phần công việc hoàn thành không đồng nghĩa cả tuần đã đạt.

| Tuần | Mốc cần đạt | Trạng thái | Kết quả chính / phần còn lại |
| --- | --- | --- | --- |
| 1 | Tài liệu và nền tảng dự án | processing | Đã có đặc tả, kế hoạch và khung dự án; còn hoàn thiện lint/luồng tự động |
| 2 | Mô hình tham chiếu L0 | ✅ | SoftPosit đã build và kiểm thử đạt |
| 3 | L1 số học chính xác — Gate1 | ✅ | Parser/packer, nhân exact và round đã nghiệm thu |
| 4 | L1 nhân lặp và baseline bài báo | processing | Chức năng đã kiểm; baseline khớp ví dụ gốc chưa đạt TableI, provenance còn mở |
| 5 | L1 bộ cộng | ✅ | Đã triển khai và kiểm chứng đạt |
| 6 | L1 MAC — Gate1B | ✅ | MAC v0/v1, tích lũy và API đạt kiểm chứng Linux/Windows |
| 7 | RTL giải mã và khối cơ sở | ✅ | LOD/LZD, hai shifter và parser tổ hợp/pipeline kiểm chứng đơn vị đạt |
| 8 | RTL mã hóa và làm tròn | ✅ | Packer tổ hợp/pipeline và parser→packer đạt; PPA đơn vị đã khảo sát, sau tối ưu P2, benchmark đạt setup100MHz ở ba seed mỗi mode |
| 9 | RTL bộ nhân lặp — Gate2 | ✅ | Multiplier đã nghiệm thu trên16 cấu hình,0 mismatch; lint và coverage đạt phạm vi tuần9. Baseline gốc theo dõi riêng ở tuần4 |
| 10 | RTL bộ cộng | không | Chưa triển khai |
| 11 | RTL MAC — Gate3 | không | Chưa triển khai |
| 12 | Harness, regression và coverage | processing | Harness multiplier đã kiểm chứng; còn regression/coverage tích hợp toàn MAC |
| 13 | FPGA PPA và đối chiếu baseline | không | Chưa đo toàn hệ thống |
| 14 | Mở rộng và nghiệm thu — Gate4 | không | Mới có định hướng |
| 15 | Báo cáo và kiểm tra tái lập | không | Chưa hoàn thiện hồ sơ cuối |
| 16 | Slide, demo và bảo vệ | processing | Đã có slide một khối; chưa có demo/slide toàn đồ án |

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

### 4.10. Mẫu cập nhật tiếp theo

Thêm mục `Ngày DD/MM/YYYY` trước phần mẫu này; đánh số STT từ1 cho mỗi ngày.

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| … | Mốc lớn được thực hiện | Tóm tắt đã đạt gì và còn thiếu gì | ✅ / processing / không |
