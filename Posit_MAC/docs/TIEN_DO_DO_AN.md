# TIẾN ĐỘ ĐỒ ÁN — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

**Ngày cập nhật:** 18/10/2026 (giờ Việt Nam)
**Sinh viên:** Đan Huy — HK261, HCMUT  
**Đề tài:** Thiết kế và kiểm chứng lõi IP Posit MAC trên FPGA, có mở rộng ASIC.  
**Tài liệu chi tiết:** [SPEC v1.20](../SPEC_Posit_MAC_IP.md), [PLAN L1](../l1/PLAN.md), [README L1](../l1/README.md), [Optimization](../../doc/Optimization.md).

**Cách chạy kiểm chứng:** [Hướng dẫn WSL và ModelSim từ Windows CMD](HUONG_DAN_CHAY_WSL_MODELSIM.md).

File này theo dõi **mốc lớn**: hiện trạng ở mục1, việc còn lại ở mục2, tiến độ tuần ở mục3 và cập nhật theo ngày ở mục4. Chi tiết tối ưu, kiểm chứng/synthesis/STA lưu trong Optimization; PLAN giữ kiến trúc/build. Tiến độ chỉ giữ mốc, công việc còn mở và nhật ký; raw bằng chứng ở results.

**Trạng thái:** `✅` = hoàn thành phạm vi của dòng và có kiểm chứng; `processing` = đã làm một phần hoặc còn thiếu tiêu chí; `không` = chưa thực hiện.

## 1. Tổng quan

Đã hoàn thành nền tảng L0, Gate1 của L1 và bộ cộng tuần5. Bộ nhân lặp L1 đã được kiểm chứng; profile source từng đạt ngưỡng TableI nhưng không khớp output ví dụ gốc. Baseline gốc bài báo chưa xác định; giữ nghiên cứu phụ. Mục tiêu chính chuyển sang MAC non-fused làm baseline nội bộ và fused làm biến thể so sánh.

MAC L1/Gate1B, parser/packer, Gate2 multiplier và Gate3 NF đã có bằng chứng. L1 fused W32 và RTL F profile chính đã kiểm trong phạm vi công bố. NF production giữ lịch OPT-03, đã promote OPT-02c/05/09/10A và khóa38 module ngày18/10. Chi tiết số lượt/mismatch, freeze và timing lịch sử chuyển về Optimization; final per-n/AC04, CDC/RDC, paired accuracy/PPA và Gate4 còn mở.

## 2. Công việc còn lại và ưu tiên

| Mốc lớn | Trạng thái | Phần cần hoàn thiện |
| --- | --- | --- |
| Baseline nội bộ và so sánh NF/F | processing | RTL NF/F profile chính đã kiểm; còn accuracy, final per-n và paired PPA. Baseline paper giữ nghiên cứu phụ |
| RTL và kiểm chứng tích hợp — Gate2/3 | processing | Gate2/adder, NF tuần11 và F profile chính đã kiểm; còn ma trận final và coverage cuối NF/F |
| PPA, mở rộng và hồ sơ — Gate4 | processing | NF CycloneIV45,07MHz là lịch sử; F A35T100MHz R2R đạt. Còn đo matched NF/F, accuracy và hồ sơ cuối; số đo riêng xem Optimization |

**Trạng thái tối ưu:** đã mở lại candidate trên120MHz theo yêu cầu18/10; release POSIT_MAC_RTL_20261018_OPT02C giữ làm reference100MHz, chưa chốt bản cuối mới; OPT-02c/05/09/10A đã promote, xem mục3.3 và Optimization8.30. Giữ fraction12/W32, phép đo mới chỉ A35T xc7a35tcpg236-1; không nới precision/constraint. Hạn chính29/11, đệm30/11–04/12, hoàn thành trước05/12/2026.


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
| 14 | Regression và accuracy paired NF/F | không | 09–15/11: nghiệm thu đúng riêng từng bản, coverage và corpus chung. Trình tự review → harness → pilot → freeze → main → closure tại mục3.2; chưa thực thi TC W14 |
| 15 | PPA hai bản và bản thảo — Gate4 | không | 16–22/11: cùng điều kiện,≥3 run/config; accuracy/timing/II/tài nguyên và kết luận |
| 16 | Báo cáo, demo và bảo vệ | processing | 23–29/11: chốt hồ sơ/tái lập/slide/demo; hiện mới có slide các khối. Đệm30/11–04/12 |

## 3.1. Phần còn lại của tuần13

W13-01..05 đã hoàn thành phạm vi bản đầu; checklist chi tiết đã gỡ. Bằng chứng triển khai/kiểm tại Optimization mục8.15.6 và results/week13/summary.json. Chỉ giữ hai hạng mục chưa đủ tiêu chí:

| ID | Phần còn lại | Trạng thái | Liên hệ |
| --- | --- | --- | --- |
| W13-06 | Chuẩn bị counters/harness tại W14-02/03,kiểm pilot W14-04; đóng coverage tại W14-08 sau main | processing | Không yêu cầu100% hit trước khi chuẩn bị W14; SPEC§6.6/6.7 |
| W13-07 | Reset/interface review trước main ở W14-01; comparator W14-10 và matched PPA/signoff tuần15 | processing | Không dùng matched PPA chưa làm làm điều kiện bắt đầu chuẩn bị W14 |

## 3.2. Kế hoạch tuần14 cho Codex — regression, coverage và paired accuracy NF/F

**Lập ngày:** 15/10/2026; **sắp lại trình tự:** 18/10/2026 theo yêu cầu sinh viên. **Mốc gốc:** 09–15/11/2026; có thể chuẩn bị sớm trên release đã khóa. **Người thực hiện:** Codex. **Nghiệm thu:** sinh viên, cùng người review kế hoạch/test.
**Mục tiêu:** chứng minh NF/F bit-exact trên ma trận bắt buộc, đạt coverage AC04 và đo paired accuracy để bàn giao PPA tuần15.
**Đầu vào tham chiếu:** `POSIT_MAC_RTL_20261018_OPT02C`, `rtl/production_freeze.json`. **Chưa chạy W14 trong khi mở candidate120+MHz**; sau khi chọn/kiểm candidate phải khóa release cuối và gắn hash đó vào matrix. Không lấy audit PASS của reference cũ làm nghiệm thu candidate mới.

W13-06 được đóng sau khi counters đã kiểm và coverage thực sự đạt W14-08; không yêu cầu phủ100% trước khi có harness. Phần reset/interface của W13-07 kiểm ở W14-01; matched PPA vẫn thuộc tuần15, không dùng nó làm điều kiện bắt đầu chuẩn bị W14.

### 3.2.1. Quy tắc bắt buộc và điều kiện chuyển bước

1. **Chốt TC trước khi triển khai harness.** Dùng bảng3.2.3 làm danh sách đề nghị duyệt; chưa có nghĩa TC đã được chạy hoặc PASS. Sau khi sinh viên duyệt phạm vi TC mới triển khai generator/scoreboard/collector. Trong phiên sắp lịch18/10 chỉ cập nhật kế hoạch.
2. **Không sửa RTL/L1/oracle/constraint đã khóa.** Được thêm testbench/harness/generator/audit W14 riêng, dùng lại model frozen; không sửa header model/corpus đã khóa để tiện thêm tham số test. Kiểm `python scripts/audit_rtl_release.py --self-test` trước build và trước main. Mismatch phải dừng job bị ảnh hưởng, lưu seed/A/B/C_port/C_eff/config/expected/actual/flags/state cùng lệnh tái lập và báo lại; không sửa RTL/oracle để cho khớp.
3. **Pilot trước main, không hạ ngưỡng.** Snapshot seed/generator/corpus/test trước pilot; lưu cả pilot FAIL. Nếu sửa harness do lỗi phải có phiên bản và hash mới, chạy lại pilot chịu ảnh hưởng; không bỏ seed khó hoặc đổi phân bố để che FAIL. Chỉ khóa matrix main sau pilot PASS; trước và sau main kiểm lại toàn bộ hash.
4. **Tách từng điểm nghiệm thu.** Mỗi profile/n/OPS/rounding có job ID và counters riêng; chỉ completed hợp lệ được tính vào ≥10^7. Tách accepted/reset-aborted; kiểm đối soát giao dịch. Không lấy10M aggregate cũ thay10M cho từng n. 32/3 dùng oracle integer/full-grid độc lập; NF so `week11::Model`, F so L1 F_W32, không dùng SoftPosit ES2 cho ES3.
5. **Coverage ngay từ thiết kế harness.** Định nghĩa universe/bin hợp lệ và cách tính line/branch/toggle trên toàn hierarchy trước pilot. Báo riêng từng top, không gộp điểm NF/F hoặc chỉ module mới để vượt ngưỡng. Không coi --coverage-line là đủ AC04. Bin không thể đạt cần căn cứ cấu hình/RTL và review; bin chưa hit không tự được loại.
6. **Accuracy có corpus và mục tiêu riêng.** Cùng A/B/C/config/reference cho phép so standalone; với acc_mode phải khóa chính sách chuỗi/reset/reference và báo state riêng NF/F/Ideal. Không dùng tỷ lệ gộp của corpus ép near-cancellation để suy accuracy ứng dụng. Đối chuẩn collector bằng Python độc lập trước main accuracy.
7. Mọi report ghi tool/compiler, seed, lệnh, source/test/corpus hash, số completed/mismatch, phạm vi và phần chưa kiểm. Audit phải từ chối RUNNING, thiếu log, sai hash, sai profile hoặc thiếu số mẫu. Kết quả ở `results/week14/`; lệnh/kết quả chi tiết vào Optimization, tiến độ chỉ ghi mốc.
8. **Không cam kết runtime main trước pilot.** Pilot phải ghi wall-clock, tốc độ completed/s, thời gian build, RAM và dung lượng output. Dự trù từng profile từ phép đo đó. Chỉ chạy song song khi đủ tài nguyên; mặc định tuần tự, lưu summary/counters và failure nhỏ, không dump wave/CSV mọi vector.

### 3.2.2. Trình tự thực thi và điểm dừng

Mã W14-01..11 trùng đúng bước1..11 theo thứ tự thực hiện; W14-12 là nhánh exact ngoài đường chính. Các mã W14 cũ trước lần đánh số18/10 chỉ dùng truy vết lịch sử, không dùng để giao việc mới. Tất cả mục dưới là kế hoạch, chưa ghi nhận hoàn thành.

| Bước | ID | Việc cần làm | Chỉ chuyển bước khi |
| --- | --- | --- | --- |
| 1 | W14-01 | Kiểm lock release; review reset bridge/2FF release, startup, CE, giao dịch bị reset và interface NF/F; đối chiếu guideline với CDC/methodology đã có | TC-W14-01 PASS; không còn vấn đề nghiêm trọng chưa giải thích. Không cần chạy lại P&R nếu nguồn/flow không đổi |
| 2 | W14-02 | Định nghĩa bins/cross NF/F theo §6.3/6.6, miền hợp lệ, mẫu số near và kế hoạch structural coverage; triển khai counters và test nhỏ kiểm cách đếm | TC-W14-02 PASS về định nghĩa và tính đúng counters; chưa đòi tất cả bin đã hit |
| 3 | W14-03 | Lập matrix nháp; xây harness chọn cố định n/OPS/profile, oracle/scoreboard và failure replay; chuẩn bị bộ đo accuracy và comparator EXACT_EN0; snapshot pilot trước chạy | TC-W14-03 PASS; mỗi job định danh rõ, audit chống sai số mẫu/hash/status đã được thử bằng dữ liệu lỗi |
| 4 | W14-04 | Pilot NF/F qua mọi n và các profile bắt buộc, corner/protocol và comparator; pilot accuracy10^5, đối chuẩn ≥1000 mẫu bằng Python; đo runtime/tài nguyên | TC-W14-04a và TC-W14-04b PASS; mọi hàng có pilot, không dùng pilot ít mẫu tuyên bố đạt coverage cuối |
| 5 | W14-05 | Khóa `results/week14/matrix_freeze.json`: từng job, số mẫu, seed, source/model/harness/generator/oracle hash, coverage policy, corpus accuracy và provenance pilot | TC-W14-05 PASS; cấu hình main trùng phạm vi pilot đã kiểm, nguồn release không đổi |
| 6 | W14-06 | Main F32/3 FW12 W32 OPS1 FLOOR/RNE, n0..8: ≥10^7 completed/n; kiểm bits/flags/state và near trước/sau cut | TC-W14-06a/b/c PASS cho toàn bộ9 n; mismatch dừng và giữ failure |
| 7 | W14-07 | Main NF:32/3 OPS1 n0..8;32/3 OPS0 n{0,1,2,3,4,5,6,8};32/2 OPS0/1 n1..4, ≥10^7 completed/điểm | TC-W14-07 PASS cho mọi hàng; có thể chạy song song bước6 chỉ khi pilot xác nhận đủ RAM/CPU/disk |
| 8 | W14-08 | Gộp coverage từ các lượt final cùng release/instrumentation; kiểm ngưỡng và functional bins. Nếu thiếu, thêm suite directed có manifest riêng trước chạy, giữ nguyên corpus/main gốc | TC-W14-08 PASS; mỗi top line≥95%,branch≥90%,toggle≥85%,100% functional bin hợp lệ; không tự miễn bin còn thiếu |
| 9 | W14-09 | Main paired accuracy ≥10^6 triple/profile: n2/4/8 trước, sau đó đủ n0..8 trên corpus đã khóa | TC-W14-09 PASS; correctness NF/F đã đạt, báo cả trường hợp F kém NF |
| 10 | W14-10 | Main comparator NF EXACT_EN0: ≥10^7 profile chính sau pilot; freeze derivative manifest tham chiếu release gốc, không sửa RTL | TC-W14-10 PASS; same feature policy với F, cfg_mode0 bị từ chối, strict lint/reset/stall/state đạt |
| 11 | W14-11 | Audit các mục bắt buộc, replay pilot, đóng gói evidence/hash; cập nhật trạng thái SPEC/Optimization/tiến độ và commit/push | TC-W14-11 PASS; chỉ bàn giao PPA tuần15 khi W14-10 đã đạt |
| Ngoài đường chính | W14-12 | Exact NF/AC02: lên job riêng cho p8 MAC2^24, p32/2≥10^8+corner và yêu cầu p16 của SPEC; chỉ dùng tài nguyên rảnh sau pilot | Không chặn các bước chuẩn bị/main approx. Chưa chạy/đạt thì giữ mở AC02, không tuyên bố toàn SPEC đã nghiệm thu |

**Ma trận tối thiểu:** NF250M + F90M =340M completed; comparator thêm10M =350M, chưa tính pilot, suite coverage bổ sung, accuracy và exact. Không giảm số mẫu vì runtime. Các nghĩa vụ legacy/exact khác của SPEC§6.7 được theo dõi riêng, không coi350M là toàn bộ nghiệm thu của mọi module.

**Phiên ngắn đầu tiên:** ưu tiên bước1 và chốt định nghĩa/TC của bước2–3. Nếu đủ thời gian mới triển khai sau khi phạm vi TC được duyệt; không ghép main vào phiên chỉ sửa kế hoạch. Các phiên tiếp lần lượt: harness/counters → pilot và benchmark → freeze → main → closure/audit. Chỉ ước lượng lịch main sau benchmark; giữ hạn chính29/11, đệm30/11–04/12, trước05/12/2026.

**Khi thiếu thời gian:** giữ nguyên các điều kiện đầu vào; sau freeze ưu tiên F main → NF main → AC04 → accuracy → comparator → audit. Hoãn khảo sát thêm và W14-12 trong lịch W14; ghi rõ AC02 còn mở. Không đưa W14-01..04 xuống sau main, không bỏ bước pilot/freeze/coverage để ghi hoàn thành.

### 3.2.3. Test case đề nghị duyệt trước triển khai

| TC | Phạm vi | Tiêu chí PASS |
| --- | --- | --- |
| TC-W14-01 | Release/reset/interface review | Audit release PASS; checklist từng clock/reset domain, bridge/2FF release/startup/CE/stall/reset-abort có dẫn chứng. CDC/methodology không còn lỗi nghiêm trọng chưa giải thích; phân biệt OOC với board signoff |
| TC-W14-02 | Định nghĩa và kiểm counters | Có danh mục bins NF/F§6.6, cả cross fused mốc tích/C × dấu × \|ΔSF\| × LZC, số bin hợp lệ/loại và lý do; directed micro-tests cho kết quả đếm đã biết, zero/NaR/reset-abort không tính sai near. Chưa yêu cầu100% hit; đóng tiêu chí đó tại TC-W14-08 |
| TC-W14-03 | Harness/matrix nháp và audit | Cố định được n/OPS/profile và phân biệt request invalid; oracle đúng format; failure có input/C_eff/config/state và replay. Test audit từ chối hash đổi, thiếu log, RUNNING, trộn n, thiếu completed và sai đối soát accepted/completed/abort |
| TC-W14-04a | Pilot trước main | Mọi job point bắt buộc có pilot trước main, dự kiến10^4–10^5 completed/điểm;0 mismatch bits/flags/state, reset/stall/order/latency đúng. Giữ counters theo n/config và file tốc độ/RAM/disk; kiểm instrumentation line/branch/toggle toàn top. Pilot không thay số mẫu hoặc coverage cuối |
| TC-W14-04b | Accuracy pilot | 10^5 mẫu; collector C++ khớp Python fractions độc lập trên≥1000 mẫu, gồm NaR,r=0,gần0 và tie/ULP; chính sách denominator/ngoại lệ/chuỗi/state được khóa theo SPEC§6.8/11.8. Chạy trước main accuracy |
| TC-W14-05 | Main freeze | matrix_freeze ghi toàn bộ job/profile/n/OPS/count, seed, source/model/harness/generator/oracle/instrumentation hash, corpus và metric policy; liên kết pilot PASS. Audit trước/sau main từ chối mọi sai lệch; chunk chạy tiếp phải giữ sequence/seed/state và không đếm trùng |
| TC-W14-06a | F final | Với từng n0..8: ≥10^7 completed,0 mismatch bits/flags/state với L1 F_W32/oracle; near trước/sau cut≥30%, giữ phân tầng/counters§6.3 và phân bố theo n |
| TC-W14-06b | F corner | TV-FUSE-01/02,\|ΔSF\|=FRAC_MAX+2 và+3,C=−A×B zero,near LZC>15,C=0,tích=0,NaR từng operand:0 mismatch |
| TC-W14-06c | F protocol | Không mất/lặp/đảo thứ tự; giữ output khi stall; reset-abort tách completed; commit đúng một lần; request invalid không accept; latency theo release |
| TC-W14-07 | NF final | 0 mismatch d/flags/state với Model/oracle; ≥10^7 completed cho từng điểm ở bước7; giữ phân tầng§6.3,near≥30% theo suite đã chốt và phân bố theo n/standalone/acc_mode. Không dùng10M aggregate thay mỗi điểm |
| TC-W14-08 | AC04 closure | Mỗi top NF/F, toàn hierarchy: line≥95%,branch≥90%,toggle≥85%; functional bins hợp lệ100%. Cách gộp/instrumentation và loại trừ truy vết được; thiếu hit giữ FAIL/processing, không tự hạ ngưỡng |
| TC-W14-09 | Accuracy main | ≥10^6 triple/profile ở n2/4/8 rồi đủ n0..8; Err%,CorrectRate0,1/0,5/1/5%,NMSE,MaxErr,percentile,ULP,thắng/thua/hòa và CI95%; cùng corpus/reference và báo ngoại lệ,phân bố,trường hợp F bất lợi |
| TC-W14-10 | Comparator NF EXACT_EN0 | Pilot + ≥10^7 completed profile chính,0 mismatch; strict lint sạch,cfg_mode0 bị từ chối; kiểm reset/stall/state; manifest riêng liên kết release cùng source hash,khác parameter feature đã công bố |
| TC-W14-11 | Audit và bàn giao | Tất cả mục bắt buộc W14-01..10 PASS; audit từ chối thiếu job/mẫu/coverage/hash hoặc trạng thái RUNNING. Replay pilot có cùng corpus và normalized numerical/counter results; không đòi hash raw log chứa timestamp giống nhau. Archive/hash tái lập được,push GitHub thành công; AC02/W14-12 ghi riêng |
| TC-W14-12 | Exact/AC02 | Theo đúng SPEC§6.7/AC02: p8 MAC2^24,p32/2≥10^8+corner,p16 yêu cầu exhaustive;0 mismatch với oracle đúng format. Phần chưa chạy giữ mở,không dùng vài pilot gọi PASS toàn AC02 |

### 3.2.4. Điều kiện nghiệm thu và trạng thái hiện tại

- **Được chạy main:** TC-W14-01/02/03,TC-W14-04a/b và TC-W14-05 đều PASS; release lock không đổi. Có RTL đạt timing hoặc10M qualification cũ chưa đủ để bỏ các bước này.
- **Hoàn thành W14 để bàn giao W15:** W14-01..11 PASS theo từng TC. W14-11 phụ thuộc W14-01..10, không phụ thuộc W14-12 tùy lịch. Nếu thiếu comparator thì giữ W14/bàn giao PPA ở processing, không báo đã sẵn sàng paired PPA.
- **AC02/toàn SPEC:** W14-12 được hoãn trong lịch tuần14, không được miễn nghĩa vụ AC02. Nếu chưa đạt phải công bố rõ trước nghiệm thu tổng/Gate4 và xử lý theo phạm vi đã được sinh viên chốt; không tự bỏ p16 hoặc giảm count.
- **Hiện tại18/10:** RTL đã khóa và audit PASS; chưa triển khai/chạy các TC W14 mới, chưa có matrix_freeze hoặc final report W14; việc thực thi đang chờ candidate120+MHz được chọn/khóa. Trạng thái tuần14 giữ `không` cho phần thực thi; kế hoạch đã được sắp lại, chưa phải bằng chứng PASS.

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

Đợt promote100MHz đã hoàn tất; theo yêu cầu mới, mở study candidate riêng `results/opt120_20261018`. L1/oracle và nguồn reference giữ nguyên; chưa sửa production và chưa phát hành lock mới. Candidate phải kiểm lại trước promote/freeze; chưa chạy W14 hoặc tự rehash lock cũ.

### 3.3.3. Candidate trên120MHz — mở lại18/10

| Nhóm | Việc tiếp theo | Trạng thái |
| --- | --- | --- |
| Review OPT-12/13/14 | Đã đọc8.31,ghi điều kiện/sai phạm tại8.31.6; mở snapshot candidate bằng reference,không sửa RTL | ✅ |
| OPT-12 parser | Thử adjacent-XOR/sentinel trước,conditional-negate A/B riêng; leaf/lint/pilot NF/F rồi PPA | không |
| Timing trên120MHz | Đo clock cao trực tiếp,cùng budget; phân biệt R2R với I/O/ready. Không suy đạt chỉ từ slack100MHz | không |
| OPT-13/14 và khóa lại | Chỉ thử phần còn chặn theo STA; giữ contract/zero-extension. Chọn/kiểm candidate rồi mới lock release mới | không |

## 3.4. Công việc mở khác và giới hạn phạm vi (Ưu tiên giai đoạn cuối Tuần 14–16)

| Nhóm | Việc còn lại | Trạng thái | Ưu tiên & Hướng xử lý |
| --- | --- | --- | --- |
| **1. Khóa RTL & Chạy Tuần 14 (`Paired NF/F`)** | Đang chờ chọn/khóa candidate120+MHz (§8.31.6); sau đó mới khóa `matrix_freeze.json` tại W14-05, chạy final per-n AC01 NF/F, coverage AC04, paired accuracy AC03 và comparator `NF EXACT_EN=0` | processing | **Ưu tiên sau candidate:** W14-01..05 review/harness/pilot/freeze → W14-06/07 main F/NF → W14-08..11 closure và audit theo mục3.2; chưa chạy final matrix |
| **2. PPA đối xứng NF/F — Gate 4 (Tuần 15)** | Đo matched PPA giữa `NF` (`EXACT_EN=1` & `EXACT_EN=0`) và `F` trên cùng `A35T-C2` (≥3 chiến lược/cấu hình), lập bảng tổng hợp Accuracy – Timing – II – Resource | không | **Ưu tiên số 2:** Thực hiện ngay sau `W14-10`; dùng trực tiếp luồng runner `A35T-C2` đã chuẩn hóa |
| **3. Hồ sơ / Báo cáo / Slide bảo vệ (Tuần 16)** | Tổng hợp bằng chứng CDC/RDC đã kiểm ở `W14-01`, hoàn thiện luận văn, biểu đồ Pareto, slide và demo | processing | **Ưu tiên số 3:** Hạn chính29/11,đệm30/11–04/12. Kiểm CDC/RDC/reset thuộc ưu tiên1 trước matrix final,không dời kiểm kỹ thuật sang tuần16; công khai phạm vi OOC chưa board signoff |
| **4. Tái lập / Luồng tự động** | Duy trì collector/audit và kiểm tra hash nguồn frozen cho `results/week14` và `results/week15` | processing | **Ưu tiên duy trì:** Chỉ phục vụ nghiệm thu W14/W15; không chạy lại các lượt lịch sử chỉ vì cập nhật tài liệu |
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

### 4.18. Mẫu cập nhật tiếp theo

Thêm mục `Ngày DD/MM/YYYY` trước phần mẫu này; đánh số STT từ1 cho mỗi ngày.

| STT | Mốc / nhóm công việc | Kết quả chính / phần còn lại | Trạng thái |
| --- | --- | --- | --- |
| … | Mốc lớn được thực hiện | Tóm tắt đã đạt gì và còn thiếu gì | ✅ / processing / không |
