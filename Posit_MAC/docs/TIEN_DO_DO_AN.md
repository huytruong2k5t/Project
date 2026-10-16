# TIẾN ĐỘ ĐỒ ÁN — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

**Ngày cập nhật:** 16/10/2026 (giờ Việt Nam)  
**Sinh viên:** Đan Huy — HK261, HCMUT  
**Đề tài:** Thiết kế và kiểm chứng lõi IP Posit MAC trên FPGA, có mở rộng ASIC.  
**Tài liệu chi tiết:** [SPEC v1.18](../SPEC_Posit_MAC_IP.md), [PLAN L1](../l1/PLAN.md), [README L1](../l1/README.md).

**Cách chạy kiểm chứng:** [Hướng dẫn WSL và ModelSim từ Windows CMD](HUONG_DAN_CHAY_WSL_MODELSIM.md).

File này theo dõi **mốc lớn**: hiện trạng ở mục1, việc còn lại ở mục2, tiến độ tuần ở mục3 và cập nhật theo ngày ở mục4. Lệnh chạy, số vector, seed, tên file và log kỹ thuật lưu trong README/PLAN và thư mục `Posit_MAC/results`.

**Trạng thái:** `✅` = hoàn thành phạm vi của dòng và có kiểm chứng; `processing` = đã làm một phần hoặc còn thiếu tiêu chí; `không` = chưa thực hiện.

## 1. Tổng quan

Đã hoàn thành nền tảng L0, Gate1 của L1 và bộ cộng tuần5. Bộ nhân lặp L1 đã được kiểm chứng; profile source từng đạt ngưỡng TableI nhưng không khớp output ví dụ gốc. Baseline gốc bài báo chưa xác định; giữ nghiên cứu phụ. Mục tiêu chính chuyển sang MAC non-fused làm baseline nội bộ và fused làm biến thể so sánh.

MAC L1 đã hoàn thành và nghiệm thu Gate1B. Parser/packer và Gate2 multiplier đạt;NF/Gate3 tuần11 đạt với10 triệu/0 mismatch. Tuần12 đã có oracle và L1 fused W32/flags/state,main phân tầng2.208.768 ca mỗi nền tảng Linux/Windows/UBSan0 mismatch. Toàn NF post-route sơ bộ đạtmedian45,07MHz trênCycloneIV,chưa setup100MHz. RTL fused profile chính tuần13 đã kiểm10 triệu/0 mismatch và STA A35T100MHz R2R đạt; ma trận cuối, paired accuracy/PPA và Gate4 còn mở.

## 2. Công việc còn lại và ưu tiên

| Mốc lớn | Trạng thái | Phần cần hoàn thiện |
| --- | --- | --- |
| Baseline nội bộ và so sánh NF/F | processing | RTL NF/F profile chính đã kiểm; còn accuracy, final per-n và paired PPA. Baseline paper giữ nghiên cứu phụ |
| MAC L1 — Gate1B | ✅ | MAC v0/v1, tích lũy và API đã triển khai, kiểm chứng đạt |
| RTL và kiểm chứng tích hợp — Gate2/3 | processing | Gate2/adder, NF tuần11 và F profile chính đã kiểm; còn ma trận final và coverage cuối NF/F |
| PPA, mở rộng và hồ sơ — Gate4 | processing | NF CycloneIV45,07MHz là lịch sử; F A35T100MHz R2R đạt. Còn đo matched NF/F, accuracy và hồ sơ cuối |

**Thứ tự tiếp theo:** primitive Xilinx§8.18 và parser một detector§8.19 đã hoàn tất phạm vi refactor; tiếp SAC và khối lớn theo STA. LOD nhóm4 riêng MODE0,N31/32; parser dùng XOR và một LOD N=NB-2, hai shifter giữ gốc. Không suy Fmax toàn MAC từ benchmark leaf/chuỗi. Theo lựa chọn15/10, phép đo mới dùng Xilinx; số CycloneIV giữ ý nghĩa lịch sử. Giữ fraction nhân12 bit; ACC_WIN32 là cửa sổ cộng fused. Hạn chính29/11, đệm30/11–04/12 trước05/12/2026 giữ nguyên; W14 tại mục3.2/PLAN§8.17.


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
| 13 | RTL fused | processing | Đã triển khai sớm15/10: main10M/0 mismatch,pipeline/XSim đạt,STA A35T100MHz R2R đạt; còn hoàn thiện coverage/signoff,final per-n và so sánh theo tuần14–15 |
| 14 | Regression và accuracy paired NF/F | không | 09–15/11: nghiệm thu đúng riêng từng bản, coverage và corpus chung. Đã lập plan W14-00..08 tại mục3.2, chờ duyệt test case |
| 15 | PPA hai bản và bản thảo — Gate4 | không | 16–22/11: cùng điều kiện,≥3 run/config; accuracy/timing/II/tài nguyên và kết luận |
| 16 | Báo cáo, demo và bảo vệ | processing | 23–29/11: chốt hồ sơ/tái lập/slide/demo; hiện mới có slide các khối. Đệm30/11–04/12 |

## 3.1. Bàn giao tuần13

Checklist tuần12 đã nghiệm thu và gỡ; giữ nhật ký/report tại PLAN8.14 và results/week12/summary.json. Đã đủ cơ sở bắt đầu RTL fused W12-F-1 (32/3, FW12, W32/Q29, FLOOR/RNE, approximate-only). PLAN§8.15 cập nhật15/10 có W13-01..07: khóa mapping prepack/giao diện/lịch cạnh → F1/F2 align/residual → F3/F4 add/sub/borrow → F5/packer → top/protocol → pilot/regression → STA/audit/backup. Dự kiến7–10 ngày làm việc, có thể bắt đầu sớm; không chờ NF tối ưu Fmax xong. Đã triển khai RTL F và kiểm main10M/0 mismatch tại PLAN§8.15.6; pipeline/XSim và STA ban đầu đạt. Final per-n tuần14,coverage/signoff và Gate4 giữ nguyên.

Kế hoạch tối ưu tại [PLAN§8.16](../Posit_MAC/l1/PLAN.md#816-kế-hoạch-tối-ưu-timinglut-trước-khi-sửa-rtl--bản-xem-xét-15102026) đã bổ sung thực thi leaf Xilinx ở §8.16.9. XSim117 cấu hình/7.275.184 đối chiếu đạt0 mismatch,strict lint197 lượt đạt;108 lượt P&R A35T/A100T hoàn tất. R2R đạt200MHz;31 lượt còn lỗi tại cổng OOC, chưa board signoff. Refactor chưa có lợi ích timing đồng nhất; giữ RTL chính, ứng viên và bảng đánh đổi riêng. Zynq7020 chưa có trong danh sách part bản cài. Cặp LOD/shifter và refactor NF lớn chưa triển khai; F được thực hiện riêng theo PLAN§8.15.6; không đổi fraction12 hoặc hợp đồng fused.

## 3.2. Kế hoạch tuần14 cho Codex — regression, coverage và paired accuracy NF/F

**Lập ngày:** 15/10/2026. **Mốc gốc:** 09–15/11/2026; được phép bắt đầu ngay sau khi đóng phần còn lại của tuần13. **Người thực hiện:** Codex. **Người lập plan và nghiệm thu:** Claude cùng sinh viên.  
**Usecase của sinh viên:** "Tôi cần chứng minh MAC NF và MAC F đều đúng bit-exact trên toàn ma trận cấu hình bắt buộc, đủ coverage theo AC04, và có bảng so sánh độ chính xác NF/F trên cùng corpus để đưa vào báo cáo và làm đầu vào cho PPA tuần15."  
**Cổng kiểm:** G-F-RTL, AC01, AC04 và phép đo AC03 (SPEC §9 tuần14). AC02 exact được xếp sau và chỉ chạy nếu còn thời gian (W14-07).

### 3.2.1. Quy tắc bắt buộc với Codex

1. **Test trước, code sau.** Mỗi task phải viết hoặc mở rộng harness/test và các TC trong bảng 3.2.3, rồi gửi lại danh sách TC để sinh viên duyệt. Chỉ sau đó mới sửa generator/scoreboard/script. Task chỉ được tính hoàn thành khi **toàn bộ** TC của task PASS.
2. **Không sửa datapath RTL** của `posit_mac_nf`, `posit_mac_f` và các leaf, cũng như L1 frozen (`results/l1_floor_rne_freeze`, `results/week12/freeze.json`). Tuần14 chỉ thêm testbench, harness, generator, collector và audit. Nếu phát hiện mismatch thì dừng, lưu failure JSON (seed/A/B/C/config/expected/actual) và báo lại. Không tự sửa RTL hay oracle để "cho khớp".
3. **Không hạ ngưỡng** của AC01/AC04/§6.7, và không đổi corpus/seed sau khi đã thấy FAIL. Corpus, seed và matrix phải được khóa bằng hash **trước** khi chạy main.
4. **Oracle đúng format:** 32/3 dùng oracle integer/full-grid độc lập (`tb/week12_fused_reference.hpp`, oracle NF tuần11). Không dùng SoftPosit ES2 làm chuẩn cho ES3. NF so với `week11::Model`, F so với L1 F_W32.
5. Mỗi report phải ghi tool/compiler version, seed, lệnh, source hash và số lượng accepted/completed/reset-aborted (tách riêng). Audit phải FAIL nếu thấy RUNNING, thiếu log hoặc hash bị đổi.
6. Kết quả canonical lưu tại `results/week14/`. Lệnh tái chạy và nhật ký kỹ thuật ghi ở PLAN§8.17 (Codex tạo mục này). File tiến độ chỉ cập nhật mốc.

### 3.2.2. Thứ tự công việc

| ID | Công việc | Phụ thuộc | Ước lượng |
| --- | --- | --- | --- |
| W14-00 | Đóng phần còn lại của W13-06/07: counters coverage F đầy đủ (bins fused §6.6), review CDC/RDC/reset bridge của NF/F bằng checklist guideline | — | 1 ngày |
| W14-01 | Khóa matrix final và corpus: hàng NF/F profile chính §6.7 (32/3, FW12, OPS1, FLOOR/RNE, n0..8), các hàng NF bắt buộc khác, corpus paired accuracy; lưu `results/week14/matrix_freeze.json` | W14-00 | 0,5 ngày |
| W14-02 | Final per-n AC01 cho NF: ≥10^7 completed cho mỗi n0..8 ở profile chính, kèm các hàng approx 32/3 OPS0 và 32/2 n1..4 OPS0/1 | W14-01 | 1,5 ngày (chạy nền) |
| W14-03 | Final per-n AC01 cho F (G-F-RTL): ≥10^7 completed cho mỗi n0..8 ở profile chính, kèm acc_mode/control/flags | W14-01 | 1,5 ngày (chạy nền, song song W14-02) |
| W14-04 | AC04 coverage: line/branch/toggle trên toàn top NF và toàn top F (không chỉ module mới), gộp từ các lượt final; functional bins §6.6 đủ 100% bin hợp lệ; bảng loại trừ có lý do | W14-02, W14-03 | 1 ngày |
| W14-05 | Paired accuracy AC03: pilot 10^5 rồi main ≥10^6 triple/profile cho n2/4/8, sau đó đủ n0..8; metrics theo §6.8 | W14-01 | 1,5 ngày |
| W14-06 | Comparator NF EXACT_EN0 cho PPA công bằng tuần15: kiểm feature-disable NF EXACT_EN=0 (pilot + 10^7 ở profile chính), freeze | W14-01 | 1 ngày |
| W14-07 (nếu còn thời gian) | AC02 exact NF: p8 MAC exhaustive 2^24, p32/2 ≥10^8 + corner list, p16 mul/add exhaustive nếu runtime cho phép | W14-02 | chạy nền |
| W14-08 | Audit tổng, freeze nguồn/bằng chứng, cập nhật SPEC §11.16 và PLAN§8.17, commit/push GitHub | Tất cả | 0,5 ngày |

Thứ tự ưu tiên khi thiếu thời gian: W14-03 > W14-02 > W14-05 > W14-04 > W14-06 > W14-00 > W14-07. Hạn chính 29/11 và đệm 30/11–04/12 giữ nguyên.

### 3.2.3. Test case cần duyệt trước khi Codex code

| TC | Task | Mục đích (usecase) | Tiêu chí PASS |
| --- | --- | --- | --- |
| TC-W14-00a | W14-00 | Có đủ functional coverage của F để ký AC04 | Cross fused §6.6 (mốc tích/C × dấu × \|ΔSF\| × LZC) có báo cáo số bin hợp lệ, số bin đã phủ và lý do loại từng bin; 100% bin hợp lệ được hit |
| TC-W14-00b | W14-00 | Reset/CDC an toàn khi đưa lên board | Checklist reset bridge, 2FF release và không có đường bất đồng bộ chưa đồng bộ hóa, đối chiếu từng mục guideline; Vivado `report_cdc`/`report_methodology` không còn lỗi nghiêm trọng chưa giải thích |
| TC-W14-01 | W14-01 | Ma trận và corpus không bị chọn lại sau khi có kết quả | `matrix_freeze.json` có hash của corpus/seed/source; audit FAIL nếu bất kỳ hash nào đổi giữa freeze và main |
| TC-W14-02 | W14-02 | NF đúng ở mọi n đã công bố | Với mỗi n∈{0..8}: ≥10^7 completed, **0 mismatch** d/flags so với `week11::Model` và oracle độc lập; near-cancellation ≥30% trên từng n hoặc trên gộp kèm phân bố theo n |
| TC-W14-03a | W14-03 | F đúng ở mọi n đã công bố | Với mỗi n∈{0..8}: ≥10^7 completed, **0 mismatch** bits/flags/state so với L1 F_W32 và oracle full-grid; near trước/sau cut ≥30% |
| TC-W14-03b | W14-03 | F chịu được các ca biên bắt buộc §6.4 | TV-FUSE-01/02, \|ΔSF\|=FRAC_MAX+2 và +3, C=−A×B (zero), near-cancellation LZC>15, C=0, tích=0, NaR mỗi toán hạng: 0 mismatch |
| TC-W14-03c | W14-03 | Protocol F ổn định trong regression lớn | Không mất/lặp/đảo thứ tự; output giữ nguyên khi stall; reset-abort tách khỏi completed; accumulator commit đúng một lần; request không hợp lệ không được accept |
| TC-W14-04 | W14-04 | Đạt ngưỡng coverage nghiệm thu | Mỗi top NF và F: line ≥95%, branch ≥90%, toggle ≥85% trên toàn hierarchy; functional bins hợp lệ 100%; danh sách loại trừ có lý do truy vết được |
| TC-W14-05a | W14-05 | Kiểm bộ đo accuracy trước khi tin số liệu | Pilot 10^5: metric tính bằng Python `fractions` độc lập khớp collector C++ trên ≥1000 mẫu; r=0, NaR và gần 0 được báo riêng, không chia tương đối |
| TC-W14-05b | W14-05 | Có bảng so sánh NF/F đưa vào báo cáo | ≥10^6 triple/profile ở n2/4/8 (sau đó n0..8): Err%, CorrectRate(0,1/0,5/1/5%), NMSE, MaxErr, percentile, ULP-distance, tỷ lệ thắng/thua/hòa NF vs F, khoảng tin cậy 95%; báo cả kết quả bất lợi cho F |
| TC-W14-06 | W14-06 | So PPA tuần15 công bằng (cùng EXACT_EN0) | NF EXACT_EN=0: strict lint sạch, pilot + 10^7 ở profile chính có 0 mismatch; request cfg_mode=0 bị từ chối; bản freeze riêng |
| TC-W14-07 | W14-07 | Exact NF khớp SoftPosit | p8 MAC 2^24 và p32/2 ≥10^8 + corner list: 0 mismatch với `p<N>_add(p<N>_mul)` |
| TC-W14-08 | W14-08 | Bằng chứng tái lập được | Audit PASS toàn bộ report tuần14; chạy lại pilot từ lệnh trong PLAN§8.17 cho kết quả trùng hash; push GitHub thành công |

### 3.2.4. Điều kiện hoàn thành tuần14

Tuần14 chỉ được đánh dấu `✅` khi TC-W14-01..05 và TC-W14-08 đều PASS. W14-06 PASS là điều kiện bắt đầu PPA tuần15. TC-W14-00 và TC-W14-07 nếu chưa xong phải ghi `processing` kèm lý do, không gộp vào trạng thái ✅.

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
| 2 | Slide datapath OPS, SAC và SBM | 7 slide nền trắng, sơ đồ tổng và phân rã theo RTL32/3; khối/mũi tên/bảng chỉnh sửa được, có lịch pipeline và ví dụ12 bit. Đã rà nguồn và kiểm bố cục, không đổi trạng thái coverage Gate3 | ✅ |
| 3 | Lập kế hoạch tuần12 | W12-01..07 ưu tiên coverage NF, oracle/hợp đồng/model fused và timing/pipeline; cập nhật PLAN8.8 và checklist tạm. Chỉ hoàn thành việc lập kế hoạch, chưa chạy hoặc nghiệm thu công việc tuần12 | ✅ |
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
| 6 | Lập kế hoạch tối ưu timing/LUT trước refactor | Bổ sung PLAN§8.16 và thứ tự thử SAC: dịch cố định trước → gộp cộng scale → exhausted song song cùng controller; giữ bit-exact và đo từng bước. Đã cập nhật kế hoạch theo góp ý; chưa sửa RTL hoặc chạy lại regression/PPA | ✅ |
| 7 | Rà soát ghi chú và ưu tiên khối cơ sở | Đọc Note.docx, đối chiếu mã và kiểm các đẳng thức số học; xác định cách sửa count của parser và giới hạn các ước lượng LUT. Cập nhật thứ tự shifter/LOD trước SAC và khối lớn; chưa sửa RTL hoặc đo PPA mới | ✅ |
| 8 | Khảo sát primitive trên Xilinx | XSim7.275.184 đối chiếu/0 mismatch,lint197 lượt và108 P&R hoàn tất. R2R đạt200MHz;refactor có đánh đổi theo width/part,chưa thắng đồng nhất;giữ RTL chính. I/O OOC chưa closure,không suy tần số MAC/kit. Bảng/snapshot tại PLAN§8.16.9 | ✅ |
| 9 | Cụ thể hóa kế hoạch RTL fused | Đối chiếu SPEC/guideline/L1 và bằng chứng tuần12; chốt phạm vi bản đầu, kế hoạch F1–F5 và W13-01..07, tiêu chí số học/protocol/STA. Đã đủ điều kiện bắt đầu; chưa sửa RTL hoặc chạy kiểm mới | ✅ |
| 10 | Triển khai và kiểm RTL fused | F1–F5/top main10M và pipeline/XSim đạt0 mismatch; strict lint sạch,STA A35T100MHz R2R đạt,1520LUT/815FF. Audit nguồn/kết quả đạt; còn final per-n/coverage/CDC và paired NF/F PPA | ✅ |
| 11 | Lập kế hoạch tuần14 cho Codex | Mục3.2: W14-00..08 và TC-W14-00a..08 cho final per-n NF/F, AC04, paired accuracy và comparator NF EXACT_EN0. Chỉ lập kế hoạch; chưa chạy hoặc sửa mã | processing |

### 4.15. Ngày 16/10/2026

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| 1 | Phân loại RTL và cập nhật đường dẫn | 55 file giữ nguyên byte; tách common/parser/packer/multiplier/adder/NF/F, paper, candidate và benchmark. Có file list production và bản đồ thư mục; runner WSL/ModelSim/Vivado dùng đường dẫn mới. Lint 17 profile sạch; smoke NF/F mỗi bản10.000, ModelSim143.976 và XSim8.192 đều0 mismatch | ✅ |
| 2 | Dọn dữ liệu kiểm chứng | Xóa build/cache có thể tái tạo, thu hồi khoảng3,9GB; giữ báo cáo, thống kê, biểu đồ, coverage, seed/lệnh/hash, snapshot nguồn và fixture. Có script dry-run/apply và kiểm hash dữ liệu giữ lại; không thay trạng thái nghiệm thu số học/PPA | ✅ |
| 3 | Tối ưu ba primitive dùng chung NF/F | Đã promote LOD nhóm4 riêng MODE0,N31/32; hai shifter giữ gốc theo timing chéo. Unit21.576.912/0 mismatch,524 lint,510 P&R và114 netlist đạt; smoke NF ES2/ES3/F mỗi bản10.000 đạt. Không suy Fmax toàn MAC | ✅ |

| 4 | Parser dùng một detector để giảm diện tích | Cả comb/pipeline dùng XOR tail + một LOD; giữ giao diện và hai tầng. Kiểm4.984.616 lượt parser/biên tham số0 mismatch,33 strict lint và NF ES2/ES3/F mỗi bản10.000 đạt.24 P&R: median225→205LUT (−8,89%),FF không đổi; timing thay đổi theo part/profile. SPEC/PLAN đồng bộ; chưa đo lại full MAC hoặc đóng200MHz | ✅ |

### 4.16. Mẫu cập nhật tiếp theo

Thêm mục `Ngày DD/MM/YYYY` trước phần mẫu này; đánh số STT từ1 cho mỗi ngày.

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| … | Mốc lớn được thực hiện | Tóm tắt đã đạt gì và còn thiếu gì | ✅ / processing / không |
