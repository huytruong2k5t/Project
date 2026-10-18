# Optimization — Tối ưu RTL và hồ sơ kiểm chứng Posit MAC

**Cập nhật:** 18/10/2026. Chuyển từ `Posit_MAC/l1/PLAN.md` theo yêu cầu sinh viên.

Tài liệu này giữ các phương án tối ưu, thay đổi RTL, kết quả mô phỏng/lint, synthesis và STA/PPA, gồm cả ứng viên không được chọn và giới hạn bằng chứng. Mọi đường dẫn code/results và lệnh trong phần lịch sử được hiểu từ gốc `Posit_MAC`, trừ liên kết Markdown đã ghi rõ. Không di chuyển hoặc sửa mã nguồn, kết quả, seed hay hash của checkpoint.

- [PLAN xây dựng L1/baseline/NF/F](../Posit_MAC/l1/PLAN.md): thuật toán, mapping và cách build hiện hành.
- [Tiến độ đồ án](../Posit_MAC/docs/TIEN_DO_DO_AN.md): công việc còn mở, lịch tuần và nhật ký mốc lớn.
- [SPEC](../Posit_MAC/SPEC_Posit_MAC_IP.md) và [Digital Design Guidelines](../Posit_MAC/Digital_Design_Guidelines.md): hợp đồng thiết kế.

## 1. Cách đọc và trạng thái hiện hành

**Phạm vi khảo sát tiếp theo — chốt17/10/2026:** chỉ Artix-7 A35T `xc7a35tcpg236-1`, áp dụng primitive, candidate, toàn MAC NF/F và paired PPA. Không lập hoặc chạy thêm A100T; các bảng/log A100T đã có giữ nguyên làm lịch sử. Xác nhận matched nhiều chiến lược trên cùng A35T, không còn yêu cầu cross-part để promote trong đợt này; không suy kết luận độc lập thiết bị. Quy tắc này thay các đề xuất đa part cũ bên dưới.

Các mã mục cũ `7.x`/`8.x` được giữ để truy vết report và liên kết; đây là mã hồ sơ, không phải thứ tự công việc hiện hành. Ghi chép có ngày giữ trạng thái tại thời điểm đo: câu “chưa triển khai” trong một mốc cũ không phủ nhận kết quả mới hơn. Công việc chưa làm/processing được quản lý tập trung tại tiến độ §3.1–§3.4. Checklist tuần đã hoàn thành được gỡ khỏi PLAN, không dùng lại như lệnh thực thi.

| Nhóm | Quyết định hiện hành | Bằng chứng |
| --- | --- | --- |
| Primitive và parser | LOD nhóm4 chỉ MODE0,N31/32; parser XOR một detector; shifter giữ gốc | Mục8.18/8.19 |
| OPS | Masked-popcount và data candidates chạy song song, một swap cuối | Mục8.10 |
| Prepack OPT-01 | Không promote; production normalizer giữ gốc | Mục8.20 |
| NF OPT-03 | Production dùng product RNE P1/P2 và parse/product bank riêng | Mục8.21 |
| A1 OPT-02c | Đã promote và khóa; A1 Default+2,144ns,0 FF thêm | Mục8.30 |
| SAC/packer/parse | Production OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A; LOCKED_FOR_W14,38 module; cả3 strategy đạt100MHz | Mục8.30 |
| Hướng tối ưu sâu 120+ MHz | OPT-12 negate đã qua10M NF+10M F/0 mismatch,STA120,48MHz theo flow có PASS; chờ chọn/promote/khóa mới. OPT-13/14 chưa triển khai | Mục8.31.7 |

Các script report/prepare gắn checkpoint cũ là producer lịch sử, không chạy lại để tái chèn nhật ký vào PLAN hiện hành. Dùng snapshot/README của study khi tái lập; không sửa các script đã khóa hash chỉ để đổi nhãn báo cáo. Collector bảng toàn tầng hiện hành đã được đổi sang vùng báo cáo giới hạn trong tài liệu này.

Phân biệt LUT4/thiết bị Intel lịch sử với Slice LUTs/Xilinx. Bảng100MHz của OPT-02b thuộc candidate; không gán cho production. Chưa có paired NF/F PPA hoặc board signoff. Các lần Default lặp cùng cấu hình không được tính thành seed độc lập.

## 2. Phương án tối ưu, thay đổi RTL và số đo

<a id="legacy-8-10"></a>

### 8.10. Refactor OPS và kiểm lại NF — 14/10/2026

OPS refactor **✅ trong phạm vi tổ hợp**,giữ public parameters/ports,hidden chỉ ởY vàgenerate no-cut. Matrix378 cặp fraction widths×4features,extra SW2/WW tăng:1.334.048 checks/0 mismatch;398 strict lint0warning/no latch. Proof đếm trên masked prefix bằng đếm trên prefix căn phải; chuẩn bị hidden trước swap giữ cùng kết quả. F<=5 exhaustive,larger directed/random,không formal HDL solver hoặc quét2^54.

NF với OPS mới:pilot4format20k và main32/3 10.000.000 completed/75.379 reset-abort,0 mismatch,cùngseed20264217/corpus checkpoint8.9;near52,55548%. ModelSim4format28.512 completed/288abort0 mismatch. Các counters/latency/reset/stall/metadata/feedback giữ nguyên. Source/L1 frozen không đổi ngoàiops_sel_comb; không ghi đè8.9 hoặc kết quả lịch sử. Audit source-bound cũ fail với hash OPS mới là expected; dùng nguồn snapshot/commit trước để replay lịch sử. Checkpoint hiện hành:results/ops_refactor_20261014/summary.json và nf/summary.json.

Đo OPS F26/FW12/SW11,dynamic exact/approx vàOPS,bank input/output giống nhau,3seed/bản,Quartus13.0sp1/EP4CE30F23C6:216→196LUT4 (-9,26%),151FF không đổi;median108,08→112,01MHz (+3,64%). Seed1 datapathcfg_mode_q→Y12 before,data9,045ns;→X8 after,data8,866ns. Setup/hold R2R6/6 đạt10ns;top10/raw STA giữ. Full I/O benchmark cần nhiều pins:partF17 không fit,virtual IO không có subscription;package/device hợp lệF23 dùng chung toàn6run,không sửa license. Không ngoại suy LUT6,V9 hoặc Fmax/II/PPA toàn MAC.

Lệnh từ working directory Posit_MAC:

```bash
bash scripts/lint_ops_refactor.sh
bash scripts/verify_ops_refactor_nf.sh pilot
python3 scripts/audit_ops_refactor_nf.py pilot
bash scripts/verify_ops_refactor_nf.sh acceptance
```

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_ops_refactor_modelsim.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_ops_refactor_nf_modelsim.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_ops_refactor_ppa.ps1
```

Sau các luồng COMPLETE:`python3 scripts/audit_ops_refactor.py`. WSL dùngbash --noprofile --norc;compilerGCC15.2.0,Verilator5.032,SoftPosit0.4.1,ModelSim10.1d. Unitseed20261014+xorshift theo profile;NFseed20261014+100NB+ES. Fixture NF giữ nguyên hash từ8.9,cần sinh lại với prepare_nf_coverage.sh nếu đã dọn,rồi copy sang checkpoint refactor đúng namespace. Binary/work/waves/fixtures không backup;giữ source/oracle/hash/report/raw coverage gọn.

Đây là phần khảo sát sớm W12-06:chưa chuyển MUX qua M0 hoặc chốt pipeline toàn NF,chưa STA/PPA toàn MAC(W12-05). Lịch/source freezeF/model vẫn theo W12-02..04.

Hình OPS đã đồng bộ sau refactor tại [PowerPoint r5](../Posit_MAC/presentation/DATAPATH_OPS_SAC_SBM_r5.pptx),giữ bản r3 để tham chiếu lịch sử. Slide2 tách nhánh masked popcount và nhánh căn phải/tạo bốn ứng viên chạy song song,hidden chỉ chèn trongY trước một tầng swap gồm haiMUX bus. Nét liền là dữ liệu,nét đứt là select;X/Y chốt ởR0 tạiL0 như trước. Slide1 cập nhật nhãn OPS,slide3..7 giữ nguyên. Đã xem bản render từng slide và kiểm các đối tượng native,7slide/0ảnh raster,hai bảng chỉnh sửa được;không tuyên bố đã chạy trong PowerPoint. Manifest `presentation/DATAPATH_OPS_SAC_SBM_r5_source.json` lưu hash RTL/SPEC,bản nguồn và deck. Tái xuất từ working directory Posit_MAC bằng runtime Node có sẵn:`node scripts/build_datapath_ops_sac_sbm.mjs <revision-mới>`;script nhập r3,không ghi đè file output đã tồn tại. Việc sửa hình không thay đổi RTL,latency hoặc trạng thái nghiệm thu timing/PPA toànMAC.

<a id="legacy-8-11"></a>

### 8.11. Khảo sát mức fraction trước lựa chọn cấu hình — 15/10/2026

Theo yêu cầu sinh viên, lập thống kê và biểu đồ trước khi chọn mức bit/triển khai bước tiếp theo. **Chưa chốt ngưỡng hoặc cấu hình mới.** Giữ SPEC v1.15, L1/RTL frozen và baseline NF12bit/n0..8; không đổi tên approximate thành exact. Đây là khảo sát số học bộ nhân, chưa phải accuracy NF/F hoặc PPA. W12-02..07 không được nghiệm thu bởi khảo sát này.

**Ma trận đã chạy:** posit(32,3), fraction8/10/12/14/16/18/20/24/26, OPS1 min-popcount/tie-A, FLOOR mỗi term và RNE tích theo prepack-preserving. So giới hạn n2/n4/n8 với xử lý hết fraction; nhánh `input_only` nhân chính xác hai significand đã cắt để tách riêng sai số lượng tử hóa đầu vào. Exact dùng toàn26bit đầu vào và lưới tíchQ52 làm đối chứng. 26bit/FLOOR Q26 kể cả chạy hết vòng vẫn là approximate. N_MAX26 chỉ nằm trong runner nghiên cứu để đo `full`, không tuyên bố RTL cfg_n hỗ trợ trên8.

**Phân bố và mẫu số:** SplitMix64,seed20261015;100.000 cặp/nhóm,300.000 cặp chính,138 hàng thống kê/13.800.000 lượt đánh giá số học. Các ứng viên dùng cùng cặp trong từng nhóm,hash corpus ghi ở report. near_one: độ lớn A/B trong[1,2),26bit fraction ngẫu nhiên,dấu ngẫu nhiên. balanced_scale: sf đều[-32,31],26bit significand/dấu ngẫu nhiên rồi RNE sang Posit,đo trên giá trị Posit thực tế. uniform_bits: mã32bit ngẫu nhiên loạiZero/NaR; bao gồm đuôi biên và clamp,ghi riêng số mẫu trong range. Ba nhóm không được trộn trọng số để tự kết luận phân bố ứng dụng hoặc paper. Zero/NaR/corner có kiểm riêng,không đưa vào mẫu số sai số tương đối.

**Oracle và thống kê:** reference exact đọc trực tiếp rawPosit rồi nhân/encode bằng integer/bit-list; so L1 exact trên toàn300.000 cặp. Recurrence approximate được kiểm bằng quét vị trí bit độc lập SAC/SBM. RNE kiểm L1 normalize-preserving/packer so serial dyadic encoder. 38.700.073 kiểm tra điều kiện độc lập,0 mismatch; pilot1.000/nhóm và UBSan cho CSV giống byte. Sai số%=100×|giá trị đo−A×B|/|A×B|,với A/B đã decode; lưu riêng prepack và output RNE,mean/P50/P95/P99/max,tỷ lệ khớp bit với R(A×B),CDF ngưỡng nghiêm ngặt `<`,số vòng trung bình,iteration_cut và vector sai số lớn nhất. P99 dùng nearest-rank; sai số output gồm làm tròn/clamp vốn có,không coi exact là0 sai số so tích chưa round. Code distance chỉ là bước mã Posit,không gọi là ULP có giá trị cố định.

| Fraction | Mean output%,n8 | P99 output%,n8 | P99 output%,hết fraction | Vòng trung bình,hết fraction |
| --- | --- | --- | --- | --- |
| 12 | 0,04792283 | 0,09481529 | 0,09401057 | 5,03011 |
| 16 | 0,00441030 | 0,01956308 | 0,00730434 | 6,88420 |
| 18 | 0,00201460 | 0,01955483 | 0,00201567 | 7,81429 |
| 20 | 0,00148903 | 0,02112145 | 0,00054471 | 8,74601 |
| 26 | 0,00160351 | 0,02586121 | 0,00000921 | 11,56655 |

Bảng là100.000 cặp near_one,không phải toàn miền. 16–20bit là các ứng viên đáng khảo sát thêm,**chưa chọn tối ưu**: mean và P99 có đánh đổi khi n8; đổi width có thể đổi quyết định OPS và số bit1 chưa xử lý nên không bảo đảm monotonic. Trong cả ba phân bố,mức24/26 bị mức20 chi phối về width/mean/P99 n8 ở lượt này,nhưng đây chỉ là frontier số học dùng width làm proxy,không phải LUT/Fmax/power frontier. Chênh nhỏ P99 giữa16/18 không đủ để khẳng định18 tốt hơn cho mọi dữ liệu. Bước tiếp sau khi sinh viên xem bảng: chốt mục tiêu mean/P99/tỷ lệ dưới ngưỡng,số vòng và phân bố ứng dụng; rồi mở thêm seed/mẫu cho ứng viên và đo PPA cùng điều kiện. Chưa sửa RTL hoặc mở rộng fused dựa trên một seed.

**Kết quả và tái chạy:** [bảng chọn cấu hình](../Posit_MAC/results/fraction_survey_20261015/selection_table.csv),[biểu đồ accuracy](../Posit_MAC/results/fraction_survey_20261015/fraction_accuracy.png),[bảng phân bố CDF](../Posit_MAC/results/fraction_survey_20261015/fraction_distribution.png). Report/hash:results/fraction_survey_20261015/summary.json,accuracy.csv,source.sha256; có SVG để đưa vào báo cáo. GCC15.2.0;WSL bash --noprofile --norc;long double64bit significand,đủ biểu diễn tích dyadic54bit. Không dùng SoftPosit ES2 làm oracle ES3. Lệnh từ Posit_MAC:

```bash
bash scripts/run_fraction_survey.sh
python3 scripts/summarize_fraction_survey.py --no-plots
```

Vẽ chart bằng Python cómatplotlib/numpy:`python scripts/summarize_fraction_survey.py`. Phiên này dùng runtime Python3.12,matplotlib3.11.2/numpy2.5.4 cài riêng `scratch/fraction_plot_deps`,cache trong results/.../tmp;không cài hệ thống. Không backup dependencies/cache/binary;giữ source,CSV/hash/log gọn,PNG/SVG và summary để tái chạy. Chưa nghiệm thu RTL/PPA,FMA hoặc chọn ngưỡng độ chính xác.

<a id="legacy-8-12"></a>

### 8.12. Thử refactor alignment adder — 15/10/2026

Theo yêu cầu sinh viên, đã tạo `rtl/candidates/adder/posit_add_align_candidate.sv` để thử hai hiệu sf signed chạy song song, tính abs(delta) từ sf trực tiếp,không chờ so sánh fraction hoặc MUX chọn sf lớn/nhỏ. Chọn dữ liệu vẫn dùng so sánh sf/fraction trực tiếp. Giữ mask,shifter,jam,clamp F+2 và toàn bộ logic ngoại lệ/output của bản hiện tại;NaR ưu tiên Zero. Cast từng toán hạng trước phép trừ; hằng clamp viết `delta_t'(F)+delta_t'(2)` để sạch lint khi SF_W35. Parameter/default/ports giữ nguyên ngoài tên module ứng viên. **Không thay `posit_add_align.sv`,không thêm bank/latency hoặc thay L1/SPEC normative.** Snapshot baseline tại results/align_refactor_20261015/before; bản đo đầu trước sửa cast lưu ở ppa_r1,số đo ba seed ứng viên giữ nguyên sau sửa cast.

**Kiểm chức năng:** ModelSim10.1d kiểm823.872 trường hợp/11 cấu hình,0 mismatch giữa baseline,candidate và oracle alignment số nguyên độc lập. Gồm bốn format nghiệm thu,F2/F3,F5 vét cạn fraction ở delta biên,SF_W tăng và SF_W35,raw signed min/max,tie A,delta0/F+2/F+3,flags32 giá trị và payload special bẩn. Đã kiểm tổ hợp haiZero với NaR/flags_in[4] trả is_zero0. Không tuyên bố formal hoặc vét cạn toàn input. Strict Verilator5.032 --timing -Wall:9 leaf+4 integrated profiles sạch,không latch. Harness chu kỳ --no-timing chỉ bỏ ASSIGNDLY của CK2Q; không waiver lint định thời.

**Pipeline ứng viên trong source copy riêng:** pilot50k ở(8,0),(16,1),(32,2),(32,3),rồi trial≥1m ES3; tổng1.200.012 completed/1.194 reset-aborted,0 mismatch với L1/oracle integer/bit-list và SoftPosit ở format hỗ trợ. ES3 không so SoftPosit ES2. Giữ H_ADD3,handshake không stall3 cạnh,max_slots3,reset khi busy/output stalled,long/input/output stalls,thứ tự và payload/flags RNE/TRUNC. Seed harness giữ20261012+100NB+ES; unitseed20261015+100NB+ES+10000SF_W,xorshift32. GCC15.2.0,ModelSim10.1d,Verilator5.032,oracle/library/source hashes và lệnh lưu trong checkpoint. Lượt trial chưa thay regression frozen NF10 triệu hoặc coverage final.

**PPA thực đo:** Quartus13.0sp1,EP4CE30F23C6/LUT4,NB32/ES3 F26/SF_W11,bank input/output giống nhau,cả hai xử lý full raw I/O,clock10ns,cùng seed1/2/3.

| Chỉ tiêu leaf benchmark | Baseline | Candidate | Đánh đổi |
| --- | --- | --- | --- |
| LUT4 | 404 | 420 | +3,96% |
| FF | 163 | 163 | Giữ nguyên |
| Fmax trung vị | 69,84MHz | 95,63MHz | +36,93% |
| Fmax từng seed | 74,13 /68,91 /69,84MHz | 95,23 /95,63 /95,66MHz | Cả ba ứng viên cao hơn cả ba baseline |
| Setup WNS trung vị ở10ns,slow85 | −4,318ns | −0,457ns | **Cả hai chưa đạt100MHz** |

Hold đạt cả18 tổ hợp run/corner slow85/slow0/fast0. Setup/TNS,cảnh báo công cụ và top10 paths giữ trong raw reports/ppa/critical_paths.json. Seed1: trước b_frac_q[0]→alignment_tail,data13,768ns; sau b_sf_q[1]→y[0],data10,783ns. Đường điều khiển dịch/jam từsf vẫn cần xem xét nếu tối ưu tiếp; endpoint alone không chứng minh riêng lost_mask là nút thắt duy nhất. Benchmark riêng không suy Fmax toànadder/MAC,Xilinx LUT6 hoặc power. I/O không có board/input/output delay constraints; cảnh báo pin constants/I/O assignments và feature license không được dùng là giới hạn benchmark,không tự sửa license hoặc tạo timing exception.

**Kết luận:** thử nghiệm cải thiện timing rõ với chi phí16LUT4,không mất chức năng trong phạm vi đã kiểm; giữ làm ứng viên,**chưa thay baseline sản xuất**. W12-06 vẫn processing vì chưa STA/PPA toànNF và chưa kiểm lại toànNF với ứng viên. Nếu chọn đưa vào baseline,cần regression/source freeze NF thích hợp và số đo full-system trước tuyên bố Fmax/latency/II củaMAC. Không dùng trial này để chọn width của khảo sát8.11 hoặc nghiệm thu fused/Gate4.

Report canonical: `results/align_refactor_20261015/summary.json`,modelsim/summary.json,ppa/summary.json và ppa/critical_paths.json. Lệnh từ Posit_MAC:

```cmd
powershell -NoProfile -File scripts\verify_align_refactor_modelsim.ps1
powershell -NoProfile -File scripts\run_align_refactor_ppa.ps1
```

```bash
bash scripts/verify_align_refactor.sh
python3 scripts/audit_align_refactor.py
```

Chỉ source copy riêng ở results/integration thay tên candidate thành posit_add_align; core RTL và pipeline thật giữ nguyên. `-CandidateOnly` chỉ tái đo ứng viên khi baseline ba seed đã có và hash boundary/reference còn đúng. Backup source/snapshot,summary/log/raw PPA gọn; binary,work,wave,db,obj/cache tái tạo từ script.

Trong Git backup,raw STA lưu lossless dạng `align.sta.rpt.gz`;local giữ bản .rpt để đọc/audit. Muốn audit toàn checkpoint trên checkout mới,tái chạy các script trên để tạo lại source copy/runtime rồi audit;summary/log gọn đọc được ngay. Byte baseline và hai helper có sẵn được bảo toàn theo .gitattributes để hash tái chạy không đổi vì CRLF/LF; không đổi logic hoặc ghép candidate vào posit_add.

<a id="legacy-8-13"></a>

### 8.13. Khảo sát refactor normalization adder — 15/10/2026

Theo ưu tiên đã thống nhất, đo ba biến thể: `before` là posit_add_normalize hiện tại; `zero` bỏ điều kiện !normalized[Q] trong phát hiện zero; `shared` thêm cách viết chung bộ cộng scale với bù hai/carry-in. Hai ứng viên riêng tại rtl/candidates/adder/posit_add_normalize_zero.sv và rtl/candidates/adder/posit_add_normalize_shared.sv; **không thay production RTL, SPEC v1.15, nguồn L1 hoặc checkpoint Gate3**. I/O, parameter/default, lịch A1/A2/A3, flags và sticky giữ nguyên.

Với carry, hidden sau dịch phải luôn1; không carry và leading_valid1, LOD/dịch trái đưa bit1 lên Q. Vì vậy is_zero_in|!(leading_valid|carry) đủ cho đầu vào nhị phân. Ứng viên chỉ dịch Q bit fraction cần giữ, thay Q+1 bit gồm hidden; LOD vẫn nhận Q+1 bit đầy đủ. Phép chiếu này loại bit hidden không còn dùng và tránh lint unused; không mất bit có trọng số trong frac. TB kiểm invariant hidden của baseline và output đầy đủ bằng oracle tìm bit cao nhất/dịch trực tiếp, không gọi lại LOD/shifter của DUT.

Nhánh shared mở rộng left_shift đúng SF_W, dùng operand=carry?1:~L và cin=!carry; sf=sf_base+operand+cin. Không dùng phép đổi dấu nối tiếp trước adder. Đây là cách diễn đạt RTL để synthesis chia sẻ số học, **không tự chứng minh có đúng một physical adder**. Map cả ba bản đều có11 arithmetic-mode cells; không có bằng chứng rằng baseline trước đó tốn hai carry chain hoàn chỉnh.

**Chức năng:** ModelSim10.1d,11 profile gồm8/0,16/1,32/2,32/3,F2/F3,SF_W35 và hai override scale-width: **2.905.200 vector chung cho cả hai ứng viên,0 mismatch** với baseline/oracle. Kiểm mọi số vị trí dịch,carry,zero và NaR ưu tiên,zero giữ incoming inexact,retained-bit1/sticky0 và retained-bit0/sticky1,raw signed scale biên/wrap và dirty special payload. Có duyệt hết miền magnitude/scale cho F2/SF_W<=8 với metadata phân bố; không gọi là exhaustive mọi tích Descartes hoặc formal HDL equivalence. ModelSim cũ báo vsim-8607 ở replication multiplier0 khi F2 trong baseline và ứng viên; biểu thức được bỏ replication0 như chủ đích,giữ log,không suppress. Strict Verilator5.032 --timing -Wall sạch22/22 leaf và8/8 integration,không latch.

Mỗi ứng viên được ghép trong bản sao source riêng của adder ba tầng, **alignment vẫn là production**, không ghép đồng thời ứng viên align của8.12. Pilot50k/bốn format và trial≥1m ES3/mỗi ứng viên: tổng **2.400.024 completed/2.388 reset-aborted,0 mismatch**. Kiểm toàn unpacked,packed RNE/TRUNC,flags,reset/stall/thứ tự,handshake3 cạnh và3 slot; L1/oracle integer/bit-list độc lập,SoftPosit0.4.1 ở8/0,16/1,32/2; ES3 không dùng oracle SoftPosit ES2. GCC15.2.0. Seed unit20261015+100NB+ES+10000SF_W,xorshift32; harness20261012+100NB+ES,mt19937_64. Không thay regression toàn NF đã freeze.

**PPA:** Quartus13.0sp1,EP4CE30F23C6,LUT4,NB32/ES3/F26/SF_W11,bank input/output giống nhau,clock10ns,seed1/2/3 và slow85 để so sánh.

| Biến thể | LUT4 | FF | Fmax ba seed (MHz) | Fmax trung vị | Đổi so baseline |
| --- | --- | --- | --- | --- | --- |
| before | 240 | 100 | 113,47 /115,53 /111,99 | 113,47 | — |
| zero | 236 | 100 | 113,12 /115,04 /107,99 | 113,12 | LUT−1,67%;Fmax−0,31% |
| shared | 233 | 100 | 114,50 /109,96 /119,19 | 114,50 | LUT−2,92%;Fmax+0,91% |

Cả9 run đạt setup100MHz; hold đạt cả27 run/corner slow85/slow0/fast0. WNS slow85 trung vị1,187/1,160/1,266ns; raw top10 paths và TNS/corners lưu trong ppa/critical_paths.json. Seed1 critical: before magnitude_q[27]→frac[47],data8,718ns; shared magnitude_q[17]→frac[52],data8,663ns. Endpoint chưa phân giải delay từng tầng; không kết luận riêng adder scale là critical path. Phải khảo sát đầy đủ cone LOD/shifter/canonicalization trước tối ưu tiếp.

**Kết luận:** hai thay đổi giữ chức năng trong phạm vi đã kiểm và tiết kiệm ít LUT. Chưa chứng minh tăng Fmax bền vững: phân bố ba seed chồng lấn,worst-seed shared109,96MHz thấp hơn baseline111,99MHz. Giữ hai ứng viên để lựa chọn khi ưu tiên diện tích,**chưa đưa vào baseline chính**. Benchmark riêng không suy Fmax toàn adder/MAC,Xilinx LUT6,board signoff hoặc power. Không có input/output delay và pin assignment board; warnings constant fraction/pin assignments/parallel compilation không có license được giữ,không sửa license hoặc tạo timing exception. W12-05/06 và Gate4 toàn hệ thống còn mở.

Report canonical `results/normalize_refactor_20261015/summary.json`; nguồn,seed/tool/lệnh/hash,log/summary ModelSim,strict lint,integration và9 run PPA giữ để tái chạy. Không tạo file Markdown mới. Từ Posit_MAC:

```cmd
powershell -NoProfile -File scripts\verify_normalize_refactor_modelsim.ps1
powershell -NoProfile -File scripts\run_normalize_refactor_ppa.ps1
```

```bash
bash scripts/verify_normalize_refactor.sh
python3 scripts/audit_normalize_refactor.py
```

Source copy,work,obj/db,wave/binary có thể sinh lại,không backup lên Git; raw STA lưu lossless normalize.sta.rpt.gz trong Git và .rpt ở local. Trên checkout mới,tái chạy trước audit đầy đủ để tạo lại source copy/runtime. Audit giữ hash baseline,so giao diện/canonical flags và đối chiếu report gốc; không dùng summary PASS thay nghiệm thu hệ thống.

Git giữ nguyên byte CRLF của baseline normalization đã đo bằng .gitattributes; đây chỉ là khác biệt newline so với blob LF cũ,không sửa logic hoặc chọn ứng viên làm production. Các file nguồn phụ có sẵn giữ nguyên byte/hash; không ghi đè checkpoint lịch sử.

<a id="legacy-8-16"></a>

### 8.16. Kế hoạch tối ưu timing/LUT trước khi sửa RTL — bản xem xét 15/10/2026

**Trạng thái cập nhật 15/10: đã cho phép triển khai riêng BASE-01/02 và chuyển phép đo mới sang Vivado/Xilinx.** Các phần SAC/parser/MAC/pipeline lớn vẫn là kế hoạch xem xét. Phần mô tả phiên lập kế hoạch/rà Note ở dưới giữ ý nghĩa lịch sử; thực thi primitive và bằng chứng mới tập trung tại §8.16.9.

Phạm vi là IP MAC NF hiện tại và phần dùng chung với F dự kiến tuần13. Kit FPGA, AXI/DMA và AI accelerator là bước tích hợp tiếp theo sau khi chọn phần cứng; chưa đưa vào đường bắt buộc của đợt tối ưu này. Các hợp đồng số học và tiêu chí nghiệm thu lấy từ SPEC v1.18 (giữ số học v1.16) và Digital_Design_Guidelines.md; phạm vi refactor NF ở đây giới hạn leaf§8.16.9; triển khai F được cho phép riêng và ghi tại§8.15.6.

<a id="legacy-8-16-1"></a>

#### 8.16.1. Mục tiêu và những điều giữ cố định

- Rút ngắn đường tổ hợp dài, giảm LUT khi có căn cứ, sau đó cân bằng các tầng pipeline.
- Giữ kết quả, flags, thứ tự giao dịch, reset và trạng thái accumulator bit-exact với mô hình đã đóng băng. Không thay corpus/oracle để làm ứng viên đạt.
- Profile chính giữ `NB=32`, `ES=3`, `FRAC_W=12`, `N_MAX=8`, FLOOR/RNE, OPS1 và n0..8. Exact và OPS0 tiếp tục kiểm theo khả năng công bố của từng top.
- Giữ nguyên cổng và parameter hiện có của các module được refactor tổ hợp. Nếu cần tín hiệu nội bộ hoặc module pipeline mới, lập bảng giao diện trước; top NF vẫn giữ giao diện giao dịch. Không thêm parameter chưa được kiểm rồi tuyên bố đã hỗ trợ.
- `ACC_WIN=32` của F là cửa sổ cộng, không phải thay fraction nhân thành32 hoặc chọn lại precision của §8.11. F tiếp tục dùng W12-F-1, không pack/làm tròn tích trước cộng.
- Giữ NF đã nghiệm thu và mọi report/hash cũ. Mỗi ứng viên chạy trong source copy/project riêng, chỉ thay một ý tưởng mỗi lần; bản kết hợp phải được kiểm và đo riêng.

**Mốc timing đề xuất để xem xét:** khảo sát đạt setup ở chu kỳ10ns trên nền tảng đang có, đồng thời tăng throughput thực tế. Đây là mốc trung gian100MHz, chưa phải cam kết và không thay NFR. SPEC§3.2 đã quy định NFR02..04 là mục tiêu khảo sát ban đầu; với nền tảng khác D0, NFR04 phải chốt riêng theo part cùng GVHD. Chỉ chọn tần số chạy sau khi kiểm setup/hold tại chính tần số đó.

<a id="legacy-8-16-2"></a>

#### 8.16.2. Điểm xuất phát đã đo

Baseline: toàn NF32/3, `EXACT_EN=OPS_EN=1`, Quartus13.0sp1/TimeQuest, `EP4CE30F23C6`, cùng constraints và seed1/2/3 của tuần12. Tài nguyên3926LUT4/823FF; DSP0, memory0. Fmax47,10/45,07/44,65MHz, trung vị45,07MHz. Nguồn bằng chứng: `results/week12/nf_ppa/{summary,stages}.json`, `stages.csv` và raw reports.

| Đường / tầng | Data delay seed1 | Setup WNS tại10ns | Ý nghĩa đối với kế hoạch |
| --- | --- | --- | --- |
| Tích: accumulator → normalize → pack/parse → product register | 21,477ns | −11,233ns | Ưu tiên cao nhất; phải phân rã delay trước chọn vị trí thêm bank |
| Adder A1 align | 17,203ns | −7,642ns | Nút thắt thứ hai; ứng viên tách delta đã có nhưng chưa đo trong toàn NF |
| SAC feedback | 12,314ns | −2,383ns | Cần giảm logic hồi tiếp; thêm tầng có thể làm tăng khoảng phát term |
| Adder A3 normalize | 12,144ns | −2,216ns | Có thể chuyển một phần công việc về A2 |
| Adder A2 arithmetic | 4,893ns | +5,031ns | Có slack để khảo sát LOD sau phép cộng; không cộng/trừ trực tiếp slack để bảo đảm closure |
| OPS → M0/core | 10,301ns | −0,382ns | Xét sau các đường dài hơn; tránh đẩy MUX sang SAC đang chậm |

Các delay là số đo seed1 để định hướng, không phải dự đoán mức cải thiện. Kết luận toàn thiết kế phải dùng cả ba seed, gồm logic, routing, fanout và control paths. Reset release có fanout833; Quartus13 chưa nhận thuộc tính ASYNC_REG của Xilinx nên cần review riêng, không xem STA đạt là đã ký duyệt CDC/RDC/MTBF.

<a id="legacy-8-16-3"></a>

#### 8.16.3. Các bước thực hiện được đề xuất

BASE-01/02 đã được khảo sát, kết quả chọn primitive tại§8.18. OPT-01 đã thử và đo§8.20, giữ production cũ vì chưa có lợi ích timing nhất quán. Cập nhật17/10: OPT-03 đã vào production (§8.21); OPT-02b đã kiểm/đo nhưng còn là candidate (§8.23/8.24); OPT-04/05 chưa triển khai. Rà soát Note.docx và kiểm đẳng thức số học tại §8.16.8 chỉ là bằng chứng đánh giá đề xuất, không phải kiểm RTL. Những thử nghiệm đơn vị đã có ở §8.12/8.13 được dùng làm đầu vào, không đổi thành bằng chứng toàn MAC. Kế hoạch tiếp theo giữ latency/II được đề xuất tại §8.25, đang chờ sinh viên xem xét trước chạy.

| ID | Công việc và phương án | Kết quả cần có để xem xét bước tiếp |
| --- | --- | --- |
| OPT-00 | Khóa snapshot nguồn, source list, tools, profile, constraints, seed và lịch cạnh của baseline; kiểm runner có dùng đúng snapshot | Manifest và bảng so sánh trước/sau. Chỉ tái chạy baseline nếu nguồn/điều kiện đã khác hoặc thiếu report cần đối chứng |
| BASE-01 | Thử riêng left shifter: bỏ comparator cho phần b thấp vì cascade tự dịch hết bit. Sau đó thử tương tự ở right shifter, giữ fill/sign và guard bit b cao | Kiểm toàn miền shift mã hóa, N không lũy thừa2, SHIFT_W nhỏ/bằng/lớn, N1; đo leaf trước, chưa ghép vào toàn NF |
| BASE-02 | Thử cây LOD/LZD tạo K0 ngay trong cây bằng bit nhánh thấp có qualify vld_lo; thu hẹp phần MUX theo level | Giữ K0 khi vld0, cả MODE và padding/S override; không chỉ bỏ MUX cuối của bản cũ. Lint/unit rồi đo leaf |
| BASE-03 | Đo cặp LOD→shifter có input/output bank giống nhau; ghép hai thay đổi đã qua unit. Đảo thứ tự stage là biến thể riêng; radix4 chỉ xét theo FPGA được chọn | Đánh giá delay từ data và từng bit control, fanout/LUT; giữ tổ hợp có lợi. Không suy timing MAC từ benchmark riêng |
| OPT-01 | Refactor `mul_prepack_norm_comb`: thay chỉ số đích động/runtime integer bằng ánh xạ bit hằng cho exact/approx và carry/no-carry, chọn ứng viên ở cuối | Bit-exact mọi output trong miền hỗ trợ; không thêm FF/cycle. Đo lại toàn NF để biết nút thắt còn ở normalize hay pack/parse |
| OPT-02 | Ghép riêng `posit_add_align_candidate` đã kiểm ở §8.12 vào source copy của NF; nhánh delta chạy song song với so sánh fraction, lost-mask chạy song song barrel shift | Whole-NF pilot và PPA; xác định lợi ích timing với chi phí LUT. Mức +16LUT4 của leaf không được dùng làm chi phí toàn MAC |
| OPT-03 | Nếu đường tích vẫn quá dài: khảo sát bank tại đầu ra packed-value; nếu norm+pack còn chậm, cân nhắc tách chuẩn hóa và/hoặc dùng các tầng RNE P1/P2 đã có trước parser | Bảng delay từng đoạn, số bank/FF/context, latency/II mới; chọn số tầng tối thiểu đạt mục tiêu đang xét |
| OPT-04 | Cân bằng A2/A3: tính LOD từ `magnitude_d` sau phép cộng ở A2, chốt count/valid cùng magnitude; A3 nhận sẵn điều khiển dịch và cập nhật scale | Giữ H_ADD3 nếu cả A2/A3 đều đạt; khoảng5 bit count+1valid là ước lượng cho32/3, tài nguyên thực phải tổng hợp |
| OPT-05 | Thử tuần tự SAC-A: dịch cố định1 bit trước, barrel shift theo leading_count sau → SAC-B: gộp scale+leading_count+1 → SAC-C: phát hiện exhausted song song và nối vào controller. Chi tiết bên dưới | Giữ từng term, scale, fx_next, exhausted/state_error, token và số vòng; đo riêng từng bước, không thêm tầng hồi tiếp |
| OPT-06 | Khảo sát tiết kiệm LUT có chọn lọc: ghép riêng bản `zero` hoặc `shared` của normalization đã kiểm ở §8.13; kiểm mapper của phép cộng/trừ A2 trước cân nhắc chia sẻ carry chain | Chọn theo PPA toàn hệ thống; không mặc định cách viết một adder sẽ sinh một carry chain hoặc tăng Fmax |
| OPT-07 | Chọn tổ hợp ứng viên có lợi, kiểm tương tác và chạy regression tích hợp chính thức; cập nhật SPEC/lịch, freeze và backup sau khi có bằng chứng | 0 mismatch, protocol/coverage đạt phạm vi áp dụng, ≥3 P&R run/config; ghi rõ phần final còn thiếu |
| OPT-08 | Bàn giao thay đổi dùng chung cho RTL F tuần13; chuẩn bị comparator NF approximate-only đã kiểm riêng trước paired PPA | NF/F cùng precision, OPS, feature policy, part/tool/constraints; tách lợi ích fusion khỏi lợi ích refactor |

**Thứ tự lịch sử sau góp ý Note.docx:** OPT-00 → BASE-01 → BASE-02 → BASE-03 → OPT-05 → OPT-01 → OPT-02 → đọc lại STA → chọn OPT-03/04 → OPT-07 → OPT-08. Thực tế đã đóng leaf§8.18 và parser XOR§8.19; thử OPT-01§8.20 rồi triển khai OPT-03§8.21. OPT-02b hiện là candidate riêng; OPT-04/05 chưa ghép. Điểm xuất phát CycloneIV tại §8.16.2 được giữ làm lịch sử, không dùng để xác định đường găng hiện hành. STA candidate A35T §8.24 hiện chỉ ra SAC/controller, parse tích, product P1 và A1 là các nhóm sát giới hạn nhất; thứ tự đề xuất tiếp theo và điều kiện giữ latency/II ở §8.25. Các nhánh tùy chọn còn lại chỉ mở khi STA mới có căn cứ.

**OPT-01 — điều kiện về parameter:** các lát bit ở §8.14 chỉ minh họa trường hợp `F_IN=2F+1`. Cần giữ đúng mapping khi override `F_IN`, `ACC_W`, `SF_W` trong miền công bố; dùng generate/ánh xạ từng bit tại elaboration để tránh dải âm, replication âm và out-of-range. Với `EXACT_EN=0`, không tham chiếu nhánh exact không tồn tại. Không rút width, bỏ carry hay coi hai bit padding của FLOOR là numerical sticky. Kiểm cả carry/no-carry, zero/NaR payload và scale signed biên.

**OPT-03 — lựa chọn pipeline cần trình bày trước khi sửa:**

- Phương án A: `norm+pack → bank packed/flags/valid → parse → product bank`. Thêm tối thiểu38FF payload/control cho32-bit packed result,5flags,1valid; còn CE/reset và metadata phụ. Chưa bảo đảm đoạn norm+pack đạt10ns.
- Phương án B: tách thêm bank normalized và/hoặc dùng RNE P1/P2, rồi parser. Lập riêng ngân sách từng đoạn; không giả định dùng packer2 tầng chỉ tăng đúng một chu kỳ.
- C và config đã được wrapper giữ khi busy thì ưu tiên tái sử dụng context hiện có. Chỉ bỏ bank dư sau khi chứng minh ổn định suốt vòng đời giao dịch; data, flags, valid và trạng thái commit phải cùng token.
- Nếu A1 vẫn vi phạm sau OPT-02, khảo sát tách `SF/delta/swap preparation → bank → shift/lost-tail/jam`. Đây là lựa chọn thêm tầng adder, khác OPT-04 retiming và phải sửa lịch adder/top tương ứng.

Việc viết lại `round_unpacked` trực tiếp để tránh pack→parse là nhánh nghiên cứu sâu, rủi ro cao hơn: chỉ mở khi sinh viên chọn và cần chứng minh đầy đủ `parse(pack(u))`, RNE qua biên regime, minpos/maxpos, sign/special và flags. Không thay bằng cắt fraction hoặc dùng sticky của metadata để rút logic.

**OPT-04/06 — giới hạn:** bản normalization hiện giữ inexact đầu vào khi kết quả0; giữ riêng ý nghĩa retained bit và sticky. Không xóa flags/sticky hoặc thay zero rule để làm số liệu LUT đẹp hơn. Tương đương với dữ liệu nhị phân hợp lệ và không-X trên output sau reset cần kiểm riêng; không tuyên bố đã chứng minh mọi tổ hợp X/Z.

**OPT-05 — thứ tự được sinh viên chọn để bổ sung vào kế hoạch, chưa triển khai RTL:**

| Bước | Phương án thử | Điều kiện giữ đúng chức năng / điểm cần đo |
| --- | --- | --- |
| SAC-A | Dịch trái cố định1 bit ở nhánh dữ liệu trước, sau đó barrel shift theo `leading_count`; LOD vẫn đếm trên `fx` ban đầu | Trong W_X bit, `(fx<<1)<<leading_count` bằng `fx<<(leading_count+1)`. Không đưa dữ liệu đã dịch vào LOD. Port `sa` vẫn trả clz+1 khi term_valid; giữ state khi lỗi. W_X=1 có generate riêng, tránh dải bit âm |
| SAC-B | Trên ứng viên A, tính trực tiếp `scale_sum = scale_extended + count_extended + 1`, hướng tới dùng carry-in=1 của cùng chuỗi cộng | Mở rộng cả hai toán hạng và hằng1 lên S_W+1 bit trước cộng để giữ carry. Không lấy kết quả đã wrap để kiểm lỗi. Viết ba số hạng trong RTL chưa chứng minh chỉ có một physical adder; kiểm netlist, tài nguyên và STA |
| SAC-C | Trên ứng viên A+B, phát hiện `single_one` từ fx song song với LOD/shifter; tạo exhausted tương đương rồi dùng trong `iter_ctrl` | Không bỏ qualification theo lỗi. Kiểm controller dùng đúng cờ theo exact/approx cho last và approx_cut, đồng thời giữ nhánh n0/init_only |

Hợp đồng cờ ở SAC-C: `exhausted = !leading_valid || (term_valid && single_one)`.

Mỗi bước so với snapshot trước đó và baseline gốc: A, A+B, A+B+C. Nếu B hoặc C không có lợi thì giữ ứng viên trước đó và báo đánh đổi; không bắt buộc ghép cả ba vào bản cuối. Các bước này đều là refactor tổ hợp/control, mục tiêu giữ nguyên giao diện, FF, latency, lịch token và II; mọi mức thay đổi tài nguyên/timing phải đo thực tế.

**Lưu ý bắt buộc với SAC-C:** `iter_ctrl` hiện nối hai output exhausted vào `unused_exhausted_exact/approx`, rồi tự kiểm `fx_next=='0'` cho is_last và `fx_next!='0'` cho approx_cut. Chỉ sửa cờ trong leaf có thể bị synthesis loại bỏ và không cải thiện controller. Cần chọn exhausted theo mode và chứng minh cờ đó tương đương phép kiểm zero của fx_next đang được chọn, gồm cả trạng thái lỗi. Khi thay nhánh điều khiển phải giữ count/limit, launch nạp fx mới, first từ count0, đường t1_first/t2_first, n0/init_only và xả hai tầng sau last; không phát core_done ngay khi SAC exhausted.

Không tách qualification lỗi khỏi output exhausted chỉ để rút đường điều khiển. Ví dụ W_X8, fx=00100000, scale7: sa3 làm scale_sum10 vượt8, nên term_valid0, fx_next giữ00100000 và exhausted0; single_one riêng lẻ bằng1 sẽ làm sai hành vi. Với fx0, exhausted vẫn bằng1 và các output state giữ nguyên, kể cả khi scale đầu vào không hợp lệ.

Phát hiện single_one có thể thử bằng cây phát hiện có ít nhất hai bit1 hoặc biểu thức kiểm `fx & (fx-1)` kèm kiểm nonzero. Phương án sau tạo thêm phép trừ, không mặc định ít LUT hoặc nhanh hơn. Tận dụng cây valid của LOD chỉ khi có thể giữ hợp đồng module dùng chung; không tự mở rộng I/O của lod_lzd_core để ghép ứng viên. Báo cả nhánh fx feedback và nhánh last/approx_cut; không chỉ đo cổng exhausted của leaf.

**Kiểm riêng OPT-05:** W_X1/5/12/26/27 và width nhỏ khả thi để vét cạn; S_W tối thiểu và tăng; fx0, từng one-hot ở mọi vị trí, nhiều bit1, sa=W_X, scale0/W_X-1/W_X và vượt giới hạn. So toàn bộ term_valid/sa/scale_next/fx_next/exhausted/state_error, không chỉ tích cuối. Sau đó kiểm core exact/approx, n0..8/early-stop, first/last/init_only/approx_cut, số token, drain và reset/stall tích hợp. Chỉ qua T1/T2 mới đo PPA theo T3; lượt xác nhận tổ hợp theo T4.

Giữ cả hành vi scale không hợp lệ, fx=0 và `sa=W_X`; kiểm exact26/27-bit và approximate12-bit riêng. Chỉ khảo sát remaining-scale budget nếu sau A/B/C, STA vẫn chỉ ra state_error gating là nút thắt. Pipeline trong feedback là thay đổi kiến trúc khác, chỉ mở sau khi có lịch term/first/last mới, vì có thể giảm throughput dù tăng MHz.

OPS/MUX relocation và reset fanout là nhánh sau: chỉ chuyển swap khi cone OPS thực sự giới hạn toàn top. Không sửa reset contract hoặc thêm timing exception để che đường dữ liệu. Mọi thay đổi synchronizer/CE phải review theo đúng vendor và giữ quy tắc reset của SPEC/guideline.

<a id="legacy-8-16-4"></a>

#### 8.16.4. Cách kiểm từng ứng viên trước lượt lớn

| Cổng kiểm | Phạm vi dự kiến | Điều kiện qua |
| --- | --- | --- |
| T0 — source/lint | So diff với snapshot; strict Verilator `--timing -Wall`, các tuple/parameter chịu ảnh hưởng; xem latch/width/signedness | Không lỗi lint chưa giải quyết, không latch; chỉ có thay đổi dự định |
| T1 — leaf | Baseline/candidate/oracle độc lập; directed trước random, exhaustive miền nhỏ khả thi; giữ seed cố định trước chạy | 0 mismatch trên mọi output, gồm flags và trạng thái lỗi được công bố |
| T2 — pipeline/top pilot | Native tối thiểu20k completed mỗi tuple8/0,16/1,32/2,32/3 đang hỗ trợ; trial32/3 ≥100k. ModelSim replay/corner với CK2Q và4-state | Reset/startup, busy/stall, stable output, thứ tự, flags, acc_clr/acc_mode và lịch cạnh đúng; aborted không tính completed |
| T3 — PPA khảo sát | BASE-01/02 đo leaf, BASE-03 đo cặp LOD→shifter cùng bank trước; sau đó ứng viên tích hợp đo whole-NF cùng điều kiện. Vivado dùng ≥3 chiến lược được tool hỗ trợ, matched trước/sau; không giả định có tùy chọn seed như Quartus | Report đủ, parse thiếu phải FAIL; ghi cả run bất lợi; benchmark leaf không thay whole-NF |
| T4 — xác nhận tổ hợp | Ứng viên kết hợp sau khi chọn: replay corpus NF phân tầng10M của checkpoint hiện hành với runner/lịch cập nhật; đủ ModelSim corner và coverage liên quan | 0 mismatch, coverage không suy giảm thiếu giải thích, freeze nguồn/corpus/commands; không gọi là đã thay toàn ma trận final |

Exact ở8/0,16/1,32/2 dùng SoftPosit đúng format khi áp dụng;32/3 dùng integer/rational oracle độc lập. NF và F so L1 riêng; bit-exact trước/sau đối chiếu theo transaction ID nếu retiming, không ép output cùng chu kỳ khi latency được phép đổi.

Với OPT-01 cần kiểm tuple và các override width/feature đã công bố; với align/normalize có thể kế thừa leaf report cũ nếu nguồn và môi trường không đổi, nhưng tích hợp vào NF vẫn cần T2/T4. Không chạy lại tất cả unit suites cho từng ứng viên không đụng tới chúng. Dừng khi gặp mismatch và giữ vector/seed/config đầu tiên để debug; không chạy P&R lượt lớn khi chức năng chưa đạt.

T4 là kiểm an toàn sau refactor, **không hạ AC01/AC02/AC04 hoặc SPEC§6.7**. Ma trận final tuần14 vẫn gồm ≥10^7 mỗi n0..8 và mỗi bản NF/F profile chính, cùng các hàng MUST khác; line≥95%, branch≥90%, toggle≥85% và functional bins hợp lệ. Phải lập lại manifest/coverage cho bản cuối đã thay nguồn, không gắn report Gate3 cũ cho RTL mới.

<a id="legacy-8-16-5"></a>

#### 8.16.5. Quy tắc đo và lựa chọn

1. Theo lựa chọn mới của sinh viên15/10, chỉ dùng Vivado/Xilinx cho các phép đo mới. Tạo baseline Artix-7 mới cùng part/tool/constraints cho cả hai bản; giữ CycloneIV tuần12 làm lịch sử, không chạy thêm Quartus/Altera. LUT4 và Slice LUTs không quy đổi trực tiếp. Chưa có pinout/board signoff; Zynq7020 hiện chưa được cài.
2. Dùng snapshot baseline hiện có khi hash/runner/constraints còn phù hợp; runner mới phải ghi thư mục kết quả riêng như `results/nf_optimization/<candidate>/`, không ghi đè `results/week12/nf_ppa` hoặc report lịch sử. Không sửa nguồn/constraints trong lúc run.
3. Khóa riêng constraints của đợt Xilinx tại §8.16.9/manifest trước đo ứng viên; mốc10ns và derive_clock_uncertainty trước đây thuộc Quartus tuần12, không áp lẫn vào Vivado. Không bỏ exact logic, đổi width/OPS, thêm false-path/multicycle, đổi chiến lược hoặc hạ clock riêng cho ứng viên nhằm tạo lợi thế.
4. Báo tài nguyên theo vendor, WNS/TNS setup/hold/recovery/removal, unconstrained paths, top paths theo stage, fanout và min/median/max ≥3 run/chiến lược matched. Xilinx dùng Slice LUTs/FF/CARRY4/DSP/BRAM; arithmetic-mode LE của Quartus cũ không cộng thêm như một loại LUT độc lập. Primitive/measurement bank không có reset thì recovery/removal ghi không áp dụng.
5. Fmax từ timing model là khảo sát. Sau khi chọn tần số vận hành phải P&R/xác nhận setup và hold với constraints của tần số đó; không chỉ lấy nghịch đảo data delay hoặc Fmax báo cáo ở run đang fail10ns rồi gọi đã closure.
6. Với `f_run_Hz` tính bằng Hz, đánh giá `throughput_ops_s=f_run_Hz/II`, `latency_ns=10^9*L_handshake/f_run_Hz` và throughput/LUT ở n2/4/8, dùng số vòng thực tế q và không stall; báo riêng workload có early-stop. Không dùng cfg_n thay q hoặc lấy II của leaf adder làm II của MAC.
7. Với NF OPT-03 hiện hành, ngân sách là `L_valid=q+12`, `L_handshake=q+13`, `II_min=q+14`; checkpoint trước OPT-03 là q+10/q+11/q+12. Nếu chỉ thêm d tầng nối tiếp và giữ controller thì ngân sách dự kiến tăng d cho cả ba đại lượng; phải kiểm theo cạnh, reset và stall trước ghi thành kết quả. Retiming A2/A3 cố gắng d=0. Thay feedback SAC cần lập lịch riêng, không áp máy móc công thức này.
8. Một phương án thêm tầng chỉ tăng throughput khi tỷ số tần số đạt được lớn hơn tỷ số II mới/cũ; vẫn báo tác động latency và FF. Nếu giảm LUT nhưng timing hoặc throughput giảm, trình bảng đánh đổi cho sinh viên; không tự ghép chỉ vì tốt hơn ở một chỉ tiêu.

Không cam kết tiết kiệm một số LUT hoặc đạt một mức MHz trước khi đo. Khi lợi ích nằm trong dao động giữa seed hoặc không ổn định, giữ là ứng viên chưa được chọn. Chọn Pareto theo timing/tài nguyên/latency/II, không chỉ seed tốt nhất.

<a id="legacy-8-16-6"></a>

#### 8.16.6. Liên hệ NF/F, guideline và phạm vi nghiệm thu

- NF gốc `EXACT_EN=1` vẫn là checkpoint đã kiểm. F tuần13 là approximate-only `EXACT_EN=0`; comparator NF approximate-only phải kiểm/freeze riêng. Tiết kiệm do bỏ exact được báo riêng, không gọi là hiệu quả của refactor hoặc fusion.
- Phần nhân/OPS/SAC/chuẩn hóa dùng chung phải có cùng phiên bản trong phép so NF/F, hoặc trình riêng từng yếu tố. Tầng pack/parse tích của NF là riêng cho NF; F không kế thừa bước làm tròn tích này. F dùng signed residual/borrow của W12-F-1, không lấy clamp F+2 của adder NF làm align fused.
- Bàn giao F1..F5/P1/P2 và ngân sách q+12 hiện ở §8.15 vẫn là đề xuất. Đổi stage phải cập nhật bảng token/context/reset/ready và cạnh accept/valid/retire trong SPEC, PLAN, TB, README và tiến độ trước freeze mới.
- RTL mới theo guideline: một module/file, structural top, named ports/mỗi port một dòng, width/cast tường minh, combinational có defaults, no latch, sequential always_ff/load-enable/CK2Q, reset bridge/2FF release leaf. Không dùng LUT-gated clocks. Chỉ mô phỏng chu kỳ mới dùng --no-timing; ModelSim giữ CK2Q và strict lint vẫn --timing.
- Chưa có bằng chứng bất đồng số học mới giữa SPEC và RTL từ phiên lập kế hoạch. Điểm cần quyết định là part/timing target và thay đổi lịch pipeline; không tự sửa SPEC để biến lựa chọn đang xem xét thành hợp đồng đã chốt.

<a id="legacy-8-16-8"></a>

#### 8.16.8. Rà soát Note.docx và chuyển sang tối ưu khối cơ sở — 15/10/2026

Đã đọc toàn bộ244 paragraph và41 công thức native của `../doc/Note.docx`; không có ảnh, embedded code file hoặc tracked changes. SHA256 của Word: `5420827cac2516273380b873e431fb2a3ed9fc953e2edc417c51b108063c9de9`. Hai module mã tham khảo là lod_lzd_core và dyn_left_shifter; phần parser XOR là ý tưởng, chưa phải một parser RTL hoàn chỉnh. Word, RTL, SPEC và guideline được giữ nguyên.

| Góp ý trong Note | Đánh giá khả thi | Điều kiện / điểm cần sửa trong lập luận |
| --- | --- | --- |
| Bỏ comparator b thấp>=N ở left shifter | Đáng thử trước; đúng với cascade trên dữ liệu nhị phân | Tổng lượng dịch thấp>=N đã làm dữ liệu về0. Giữ guard OR phần b cao khi SHIFT_W>S; giữ N1. Có thể mở rộng sang right shifter nhưng kết quả phải là fill, không luôn0 |
| Giảm số stage khi SHIFT_W<S | Đúng chức năng, giúp biểu diễn gọn | Các stage b thiếu của bản cũ vốn là wire/bypass và có thể đã được synthesis bỏ; chưa chứng minh giảm LUT |
| Cây LOD tự tạo K0 khi không có match | Mã tham khảo hợp lý về số học; cần thử RTL/PPA | Dùng nhánh `~vld_hi & vld_lo` ở từng level và chọn phần position thấp; nhờ invariant invalid→pos0 mới bỏ được MUX cuối. Bỏ MUX cuối riêng lẻ ở bản cũ sẽ làm K invalid thành toàn1 |
| Thu hẹp position/MUX theo level | Hợp lý để thể hiện cấu trúc; lợi ích vật lý chưa đo | Mã Note vẫn khai báo tree_pos rộng S ở mọi node. So 155 MUX với26 bằng số bit khai báo bỏ qua constant propagation của baseline; không dùng làm mức tiết kiệm LUT |
| Thay loop padding bằng nối vector | Đúng với parameter hợp lệ, dễ đọc | Loop hiện tại unroll thành wiring, không phải dịch tuần tự theo clock. Không mặc định có lợi ích LUT/timing |
| Đảo thứ tự stage shifter | Tương đương số học khi giữ fill và guard; là ứng viên đo riêng | K MSB vẫn chờ cây valid phía dưới, không phải chỉ một cổng tính từ input. Các bit thấp chỉ bị xóa khi select dịch lớn bằng1, không luôn là hằng0. Cần arrival time sau mapping/route |
| Radix4 / ghép hai MUX2 thành MUX4 trong LUT6 | Có thể phù hợp 7-series/UltraScale+; tùy tool và part | Không cam kết mỗi hai stage luôn thành một LUT6 hoặc delay giảm một nửa. Nền tảng tuần12 là LUT4 CycloneIV; phải đo riêng khi chuyển FPGA |
| Parser dùng XOR và một detector | Đã được sinh viên chọn thực hiện16/10; kết quả tại §8.19 | Giữ r riêng; XOR `magnitude[NB-3:0]` với r, đếm NB-2 bit sau FRB. Nếu không match thì cnt=NB-2. Không đưa count từ vector NB-1 bit gồm FRB vào logic cnt/k/payload hiện tại |

**Sửa lệch một bit của parser:** parser hiện dùng cnt=m-1 khi có terminator, không dùng m. Ví dụ posit8/0 `0x40` là1: cnt0, k0, sf0. Đếm cả FRB theo XOR rồi đưa count1 vào công thức cũ sẽ thành k1/sf1, tức2. Cách XOR đúng là giữ cùng miền đếm sau FRB; nếu chọn đếm cả FRB thì phải thiết kế lại chuyển đổi count và xử lý no-terminator, không thay trực tiếp một dây. Khi hiện thực phải đồng bộ comb/pipeline và SPEC§5.2, giữ cnt/r/payload bank và hai tầng elastic đã kiểm.

Không khẳng định giảm50% LUT parser hoặc đúng một LUT6_2 cho mỗi cụm4bit. LUT6_2 chỉ có hai output; một detector4bit đầy đủ có hai bit K và vld. Input inversion có thể được absorb trong LUT nhưng chưa xác minh tài nguyên tổng thể. Tham khảo chính hãng: [AMD LUT6_2](https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/LUT6_2), [AMD LUT6](https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/LUT6). Chỉ dẫn `verilator split_var` dành cho chia biến của Verilator; chưa có căn cứ quy nó thành rào cản LUT combining của Vivado: [Verilator extensions](https://verilator.org/guide/latest/extensions.html).

**Kiểm đánh giá đã chạy, chỉ mô hình số học 0/1:** `scripts/review_note_primitives.py`, seed20261015, report `results/note_review_20261015/summary.json`. Có hash Word, hai đoạn mã tham khảo, RTL/SPEC/guideline và script để truy vết; script không thực thi code trong Word.

| Nhóm | Số ca | Kết quả / phạm vi |
| --- | --- | --- |
| Cây LOD baseline/Note/oracle scan độc lập | 42.348 | 0 khác biệt; vét cạn N2..12, cả MODE và S=min/min+1; N lớn tới64 có directed/random |
| Shifters ascending/descending, guard mới/cũ và oracle từng bit | 1.570.320 | 0 khác biệt; left, right fill0/fill1/sign; N1..64 theo danh sách report, SHIFT_W nhỏ/bằng/lớn; N<=8 vét cạn data, mọi shift mã hóa |
| Parser XOR tail đúng so quy tắc đếm hiện tại | 66.184 | 0 khác biệt trên fields; vét cạn raw8/0,16/1, sample32/2 và32/3. Cách full-vector thay trực tiếp có66.170 ca khác, minh họa lỗi tích hợp, không phải kết luận ý tưởng XOR sai |

Chưa compile mã tham khảo, chưa RTL simulation/formal/XZ equivalence, synthesis hoặc STA mới. Các report ModelSim shifter/parser và Gate3 cũ thuộc nguồn cũ, không chuyển thành nghiệm thu các ứng viên này. Khi triển khai phải kiểm known-binary bit-exact, invalid K0, no-X sau reset với valid và báo rõ các khác biệt X/Z nếu có; không tự thay hợp đồng để làm test qua.

Theo thứ tự mới, BASE-01 là điểm bắt đầu triển khai được đề xuất: left shifter riêng, sau đó right shifter riêng; BASE-02 LOD/LZD tiếp theo, rồi đo cặp ở BASE-03. Mỗi leaf giữ I/O/parameter, không thêm clock hoặc stage. Sau khi đủ T0/T1 và benchmark leaf mới ghép SAC/parser, sau đó whole-NF; không chạy ngay toàn bộ regression cuối cho mỗi thay đổi nhỏ.

Tái chạy phần đánh giá bằng Python3 chuẩn, đọc đúng Note.docx trong doc; phiên này dùng Python bundled của workspace. Lệnh từ Posit_MAC: `python scripts/review_note_primitives.py --note ../doc/Note.docx`. Không tạo thêm Markdown, không sửa Word hoặc RTL trong phiên rà soát.

<a id="legacy-8-16-9"></a>

#### 8.16.9. Thực thi primitive trên Vivado/Xilinx — 15/10/2026

Sinh viên đã chọn bỏ Altera cho các phép đo mới, bắt đầu riêng shifters và LOD/LZD. BASE-01/02 dùng ứng viên độc lập trong `rtl/candidates/primitives/`; RTL sản xuất của NF, SAC, parser, SBM và các khối lớn giữ nguyên. Chưa triển khai BASE-03 hoặc các OPT tích hợp. Hai part đo là `xc7a35tcpg236-1` (Basys3) và `xc7a100tcsg324-1` (Arty/NexysA7-100T), cùng Artix7/speed−1. Bản cài trả rỗng cho `get_parts *7z020*`, nên PYNQ-Z2 chưa có số đo; không tự cài device support hoặc sửa license. Vivado2026.1 build6511674 nhận license synthesis/implementation; XSim hiện chạy được.

**Cách refactor:**

- Left/right bỏ comparator kiểm `b[S-1:0]>=N`. Với bit nhị phân, mỗi tầng là phép dịch theo hằng; tổng số bit dịch bằng phần thấp của b. Khi tổng này≥N, cascade tự cho toàn0 ở left hoặc toàn fill ở right. Vẫn giữ guard OR phần b cao ngoài cascade; right giữ cả custom fill và ARITH. N1/SHIFT_W ngắn có generate riêng.
- LOD/LZD tạo K0 cho subtree không hợp lệ ngay trong cây bằng `~vld_hi & vld_lo` ở bit vị trí mới. Các bit thấp chọn từ subtree tương ứng; bit cao chưa dùng gán0. Vì subtree vô hiệu đã có K0, root không cần MUX che K cuối; không chỉ xóa MUX của bản cũ. Giữ padding phía thấp, cả MODE và S override.
- Không thêm clock, bank hoặc stage trong DUT, không thay cổng/parameter. I/O đã có tên K/S/MODE được giữ để tương thích; không đổi tên vì guideline quy ước chữ thường.

**Kiểm chức năng đã đạt:** XSim2026.1, seed20261015,117 cấu hình và7.275.184 lượt đối chiếu,0 mismatch. Shifter37 cấu hình N1/2/3/5/8/12/26/27/29/31/32/33/64, SHIFT_W nhỏ/bằng/lớn, mọi mã shift và cả fill0/fill1/sign; N≤8 vét cạn input. LOD80 cấu hình N2..12/26/27/29/31/32/33/53/54/64,MODE0/1,S tối thiểu/tăng1; N≤12 vét cạn, width lớn10k random kèm zero/ones/one-hot/one-cold. Baseline và candidate cùng được so với oracle scan tuyến tính hoặc ánh xạ từng output bit. Output dùng kiểm4-state để bắt X trên input nhị phân đã biết; không tuyên bố tương đương mọi tổ hợp X/Z. Strict Verilator5.032 `--timing -Wall`:197 lần gọi đạt, không warning/error, không waive lint ứng viên.

**Hợp đồng đo:** snapshot/hash `results/primitive_xilinx_20261015/manifest.json`, N12/26/32, ba leaf left/right custom-fill/LOD MODE0; ARITH1/MODE1 chưa đo PPA. Cùng structural top/BUFG và input/output bank, clock5ns/uncertainty0,1ns; ngân sách I/O giả định input min=max2,5ns,output max0,5/min0ns. Smoke đầu dùng min0,5ns có hold ở cổng OOC; đã khóa ngân sách mới trước mọi phép đo ứng viên. Không thêm timing exception; R2R luôn single-cycle. Ba cặp place/route là `Default/Default`, `Explore/Explore`, `RuntimeOptimized/Default`,108 lượt cho cả hai part. Help chung còn liệt kê AggressiveExplore nhưng placement Artix7 từ chối; lần lỗi lưu riêng, không tính thành kết quả hoặc thành chiến lược đã đạt.

**Giới hạn diễn giải:** lấy Slice LUTs vật lý từ utilization, không cộng số logical LUT cells có thể ghép O5/O6. Tần số200MHz chỉ được xác nhận cho R2R khi cả setup và hold tại5ns đạt. `1000/(5−slack)` là ước lượng STA trên netlist đã route, chưa là Fmax được sweep hoặc clock đo trên kit; I/O OOC chưa có PARTPIN_LOCS, không có board signoff. Benchmark không sở hữu protocol/reset state; FF ở bank ghi đè mỗi cạnh. Không suy throughput/latency MAC hoặc thay trạng thái Gate3/Gate4. Chiến lược có thể cho cùng placement ở thiết kế nhỏ; không coi ba kết quả giống nhau là ba seed ngẫu nhiên độc lập.

**Đã hoàn tất khảo sát BASE-01/02:**108/108 lượt sau route, collector và entry replay kiểm lại đạt. Cả108 đường R2R đại diện setup/hold đạt ở5ns/200MHz; worst setup slack+0,736ns, worst hold slack+0,032ns. Không latch, routing error hoặc endpoint nội bộ thiếu ràng buộc; DSP/BRAM/CARRY4 đều0. Cả25 file RTL sản xuất giữ nguyên hash. Có31/108 run còn vi phạm setup/hold **tại cổng I/O OOC**, worst−0,017ns; không tuyên bố toàn benchmark hoặc board đã closure. Recovery/removal không áp dụng vì DUT/bank đo không có reset.

**Bảng dưới dùng trung vị ba chiến lược**, đơn vị Slice LUTs vật lý và MHz. `f_STA` là `1000/(5−R2R_setup_slack)`, **ước lượng từ STA**, không phải tần số đã sweep/đạt trên kit. Số cũ→ứng viên; FF giữ nguyên ở từng cấu hình. Đầy đủ min/median/max, delay logic/routing, flags độ dao động và source/report hash tại `results/primitive_xilinx_20261015/{summary.json,comparison.csv}`; raw reports giữ riêng từng run.

| N | Leaf | A35T LUT cũ→mới | A35T f_STA cũ→mới | A100T LUT cũ→mới | A100T f_STA cũ→mới |
| --- | --- | --- | --- | --- | --- |
| 12 | Left | 22→20 | 337,15→302,11 | 22→20 | 371,06→301,57 |
| 12 | Right/custom-fill | 21→23 | 321,54→340,83 | 21→23 | 348,68→351,99 |
| 12 | LOD/MODE0 | 9→9 | 312,21→312,21 | 9→9 | 312,01→312,01 |
| 26 | Left | 58→56 | 263,09→272,33 | 58→56 | 259,07→263,85 |
| 26 | Right/custom-fill | 67→67 | 262,95→249,19 | 67→67 | 272,55→258,87 |
| 26 | LOD/MODE0 | 21→24 | 273,15→261,16 | 21→23 | 263,64→270,86 |
| 32 | Left | 70→70 | 256,94→256,94 | 70→70 | 254,65→254,65 |
| 32 | Right/custom-fill | 84→84 | 268,38→268,38 | 84→84 | 259,40→259,40 |
| 32 | LOD/MODE0 | 26→29 | 242,78→234,52 | 26→29 | 243,43→262,74 |

**Lựa chọn sau khảo sát:** giữ bản đang dùng, chưa promote ứng viên vào NF/SAC/parser. Left26 giảm2LUT (−3,45%), median f_STA tăng3,51%/1,85% nhưng lợi ích nhỏ so dao động chiến lược, đặc biệt A100T; chưa gọi là cải thiện timing đáng kể/bền vững. Left12 giảm2LUT nhưng chậm hơn10,39%/18,73%. Right12 nhanh hơn6,00%/0,95% với giá tăng2LUT; Right26 không giảm LUT và chậm khoảng5% ở cả hai part. LOD12 và shifters32 trùng kết quả; LOD26/32 tăng LUT, timing phụ thuộc part. LOD32 giảm4→3 tầng logic nhưng A35T vẫn chậm hơn3,40%; A100T tăng7,93% với3LUT thêm. Không chỉ dựa số tầng/MUX trong RTL để kết luận.

Baseline left12/A100T có f_STA334,11–371,06MHz, chênh11,06% theo max/min−1; đã đánh dấu dao động>10%, không dùng371,06 như một giá trị ổn định. Những chiến lược cho cùng placement không được coi là seed ngẫu nhiên độc lập. Chưa đo PPA ARITH1/MODE1, chưa chạy board/bitstream hoặc cặp LOD→shifter. Bước xem xét tiếp theo vẫn là BASE-03/biến thể thứ tự stage hoặc radix4 riêng, trước khi quyết định tích hợp; không tự mở SAC/MAC trong phiên này. Nguồn/log ở `results/primitive_xilinx_20261015/`, không ghi đè report tuần12.

Tái chạy từ Posit_MAC: `powershell -NoProfile -File scripts/verify_primitive_xilinx.ps1`; WSL: `bash scripts/lint_primitive_xilinx.sh` từ đúng thư mục dự án; lần lượt `powershell -NoProfile -File scripts/run_primitive_xilinx_ppa.ps1 -Part xc7a35tcpg236-1` và `-Part xc7a100tcsg324-1`; cuối cùng `python scripts/collect_primitive_xilinx.py`. Các runner đặt runtime/tmp/work/log trong dự án và không nạp profile WSL. Chỉ đọc/chạy tool hệ thống; không thay cài đặt, registry, license hoặc home.

Khi dùng lại checkpoint đã lưu, vào bằng `powershell -NoProfile -File scripts/replay_primitive_xilinx.ps1 -Mode check` để kiểm hash nguồn/snapshot/report và thu thập lại số liệu. `-Mode verify` chạy lại XSim; `-Mode resume -Part <part>` tiếp tục các lượt PPA chưa xong, không có nghĩa tự chạy P&R mới cho các dòng đã có. Entry này kiểm nguồn trước khi gọi các helper phía trên. Không dùng lại thư mục kết quả/checkpoint hiện tại cho RTL hoặc constraints mới; phải tạo study mới và khóa manifest mới. Không gọi helper chuẩn bị để ghi đè snapshot rồi dùng lại DCP của study cũ.

<a id="legacy-8-18"></a>

### 8.18. Khảo sát và chọn primitive v2 — 16/10/2026

Theo thứ tự đã thống nhất: khóa baseline → thử LOD/LZD nhóm4 → shifter đảo tầng/radix4/native → đo leaf và chuỗi trên hai Xilinx → chỉ promote phần có lợi, kiểm lại tích hợp. Giữ nguyên tên module, parameter, I/O và latency; không sửa SAC, parser, SBM, controller hoặc số học NF/F.

**Quyết định production:** `rtl/common/lod_lzd_core.sv` dùng nhóm4 chỉ khi MODE0,N31/32,S=clog2N; mọi cấu hình khác giữ cây nhị phân. Hai shifter `common/` giữ nguyên byte so với checkpoint8f9d884. Tổ hợp được nghiệm thu là `source/lod_only`; nguồn `selected` còn native12 là bản thử, không được copy toàn bộ sang production. Quyết định/hash ở `results/primitive_v2_20261016/adoption.json`.

LOD31 được chọn theo chuỗi normalization: ≥5% gain ở cả hai part, không có chiến lược chậm hơn, LUT tăng≤10%. Riêng leaf31 A35T chỉ+3,83%, không gọi là thắng ngưỡng leaf5%. Native left12 giảm22→19LUT nhưng leaf A100T chậm khoảng14%; native left31 giảm khoảng1,56% ở A100T. Các right shifter chưa giữ được lợi ích timing qua fill/width/part; đặc biệt packer thực tế trên A35T nhanh hơn các bản thử. Đây là kết luận trong các kiến trúc đã đo, không khẳng định tối ưu toàn cục.

**Kiểm chức năng và công cụ:** XSim2026.1, seed20261016; bảy bộ nguồn×138 cấu hình, mỗi bộ3.082.416 checks, tổng21.576.912/0 mismatch. Exhaustive nhỏ/all shift codes, zero/ones/one-hot/one-cold và directed/random ở width lớn; N1 shifter, MODE0/1, S override, SHIFT_W nhỏ/bằng/lớn, fill0/custom/sign và overshift. Counts lặp corpus giữa các bộ nguồn, không phải số vector ngẫu nhiên độc lập. Verilator5.032 strict lint524 lượt sạch, không waive; hash đầu vào lint đã lưu. Lượt đầu500-pattern43.510.464/0 mismatch có nguồn/log riêng tại source_initial.zip/verification_initial, không cộng với suite cuối để gọi là vector độc lập.

**Điều kiện đo:** Vivado2026.1 build6511674, xc7a35tcpg236-1 và xc7a100tcsg324-1. Chu kỳ5ns, uncertainty0,1ns, OOC input min=max2,5ns, output max0,5/min0ns, hai bank khai báo giống nhau. Default sàng lọc, sau đó Default/Explore/Runtime xác nhận; đây là chiến lược, không phải ba random seed. F_STA=1000/(5−slack_R2R), chưa sweep Fmax, chưa đo kit/power. Dòng chuỗi vẫn có slack âm tại200MHz; không gọi là closure200MHz hoặc Fmax toàn MAC.

| Part | Cấu hình MODE0 | LUT vật lý trung vị | FF bank đo | F_STA trung vị MHz | Tăng |
| --- | --- | --- | --- | --- | --- |
| A35T | LOD31 | 25→26 | 37→37 | 249.50→259.07 | +3.83% |
| A35T | LOD32 | 26→26 | 38→38 | 242.78→277.47 | +14.29% |
| A35T | LOD31→left31 | 120→123 | 68→67 | 162.26→178.00 | +9.70% |
| A100T | LOD31 | 25→26 | 37→37 | 249.75→280.50 | +12.31% |
| A100T | LOD32 | 26→26 | 38→38 | 243.43→277.24 | +13.89% |
| A100T | LOD31→left31 | 120→123 | 68→67 | 168.49→177.37 | +5.27% |

LUT/FF là từ report utilization sau route. Primitive tổ hợp không có FF nội bộ; implementation có thể gộp/nhân bản FF ở bank đo. Kiểm netlist chức năng sau route đối chiếu oracle và latency hai bank, không SDF. Bản LOD-only có12 netlist/120.000 checks đạt0 mismatch; tổng netlist của toàn study xem summary.json, chỉ báo hoàn tất khi đủ matrix. Đã kiểm nguồn ghép chính xác trước promote, không suy từ phép cộng các điểm thắng leaf.

| Instance posit32 | Độ rộng primitive | Phạm vi kết luận |
| --- | --- | --- |
| Parser | LOD/LZD30; left29,SW5 | Giữ nguyên; không lấy gain N31/N32 thay số đo N30 |
| SAC | Fraction12 hoặc exact26/27; SW=clog2(N+1) | Không sửa hoặc đo toàn SAC/scale/exhausted/control |
| Add alignment | Right32(ES2)/31(ES3),fill0 | Không suy từ bản fill động |
| Add normalization | LOD+left31(ES2)/30(ES3) | Bản31 hưởng LOD mới, bản30 giữ gốc |
| Packer | Right60(ES2)/59(ES3),SW5,fill động | Phase riêng; kết quả SW6 không đại diện packer |

KIND3/4 của benchmark dùng shifter SW+1. KIND3 bit thêm bằng0 và được tối ưu; KIND4 chỉ là chuỗi trừu tượng. `selected` chỉ bật native12 khi SW4, nên KIND4 N12/SW5 đi qua fallback; không dùng số này để nghiệm thu native12 trong SAC thật. Group4_mixed dùng pad lũy thừa2/root nhị phân cũng đã thử; không sửa benchmark, seed hoặc ngưỡng giữa lượt đo để ép kết quả.

**Tích hợp sau promote:** nguồn common thực tế khớp hash snapshot được chọn;17 lint profile sạch. NF32 ES2 và ES3 mỗi bản10.000 completed (79/77 reset-aborted), F32 ES3 10.000 completed, tất cả0 mismatch. Compiler/tool/seed/source+binary hashes và counters ở integration/summary.json; NF seed20261013+100×32+ES, F seed20261015. Không thay ma trận10M đã nghiệm thu hoặc báo cáo source freeze cũ; đây là checkpoint hiện thực mới và smoke phù hợp với primitive bit-exact. Có kiểm thêm replay vào RunRoot riêng để tránh ghi đè bằng chứng.

**Tái lập:** hướng dẫn hiện hành tại scripts/README.md và docs/HUONG_DAN_CHAY_WSL_MODELSIM.md. Archive được kiểm SHA và có lệnh restore không ghi đè nội dung khác. Sau promote dùng `-FrozenSources` để replay snapshot cũ; không chạy preparer baseline lên common mới. Ví dụ: `scripts/verify_primitive_v2.ps1 -Variants lod_only -FrozenSources -RunRoot results/my_replay`; PPA `scripts/run_primitive_v2_ppa.ps1 -Phase adoption -Part <part> -FrozenSources -RunRoot results/my_ppa` (thêm -PlanOnly để preflight). Mỗi RunRoot mới đo lại, cùng RunRoot chỉ tiếp tục ID còn thiếu. Collector mặc định audit checkpoint gốc, không tự thu thập số đo RunRoot khác.

Build/cache/DCP/wave không đưa vào Git; giữ snapshot/checker, report/CSV, raw coverage, lệnh/seed/tool/hash trong gói nhỏ có thể restore. Không chạy TableI, không tự tăng trạng thái Gate4 hoặc nghiệm thu tuần14; [tiến độ tuần14](../Posit_MAC/docs/TIEN_DO_DO_AN.md#32-kế-hoạch-tuần14-cho-codex--regression-coverage-và-paired-accuracy-nff) vẫn dành cho W14.

**Trạng thái toàn study:** hoàn tất510 lượt place/route,114 netlist/1.140.000 checks/0 mismatch; collector --final COMPLETE. Build/cache mới đã dọn có kiểm hash dữ liệu giữ lại; nguồn/report được nén để backup. Trạng thái canonical tại results/primitive_v2_20261016/summary.json. Commit/push thực hiện cuối phiên, không suy số toàn MAC hoặc thay Gate.

<a id="legacy-8-19"></a>

### 8.19. Parser dùng một detector qua XOR — 16/10/2026

Theo lựa chọn mới của sinh viên, ưu tiên giảm diện tích parser và chấp nhận đánh đổi timing P1. Triển khai sau khi đóng khảo sát primitive§8.18, độc lập với SAC/retiming khối lớn. Cả `rtl/parser/posit_parser_comb.sv` và `posit_parser.sv` dùng một `lod_lzd_core` MODE0,N=NB-2; `terminator_bits=magnitude[NB-3:0] ^ {(NB-2){r}}`. Giữ FRB ngoài miền đếm, no-terminator→cnt=NB-2 và payload từ magnitude gốc. Giữ nguyên I/O/parameter, signed scale, hai tầng elastic, lịch E0/E1/E2, reset và II1; không giảm precision hoặc thay L1.

Kiểm chức năng bằng Verilator5.032 --timing/CK2Q: tổ hợp2.465.812 và pipeline2.465.812 lượt,0 mismatch; exhaustive raw8/0,16/1, phân tầng32/2,32/3. GeneratorL1 được so với decoder tuần tự độc lập,seed20261005; min19.672 mẫu/polarity/run và39.344/group/sign ở từng format32. Pipeline kiểm reset rỗng/một/hai slot, hủy3 giao dịch/profile, stall dài/full, bubbles, simultaneous push/pop, thứ tự và latency. Chín tuple/width biên có52.992 lượt; independent scan và so chu kỳ với bản dual-detector đóng băng, gồm32/28,SF_W36;32/3,SF_W9 và32/2,SF_W40. Không tuyên bố vét cạn toàn miền tham số.

Strict lint parser16 profile sạch; integration17 profile sạch. NF32/2,NF32/3 và F32/3 mỗi bản10.000 giao dịch0 mismatch; F có59.340 đối chiếu stage. Đây là regression cục bộ/smoke cho checkpoint refactor, không chạy lại ma trận final10M hoặc coi như đã đo Fmax toàn MAC. Không chạy TableI.

Bằng chứng tại `results/parser_xor_20261016`: source/baseline và source/xor, fixture/source SHA, seed/tool/compiler/commands và summary.json. PPA đã hoàn thành24 lượt: hai Artix7,ES2/3,Default/Explore/RuntimeOptimized, cùng input bank34FF và clock5ns/uncertainty0,1ns. Không lấy số input-to-register của thử nghiệm OOC không có bank (`ppa_unbanked_rejected`) để kết luận. R2R từ input bank đến P1 và toàn benchmark báo riêng; file p2.rpt/p2_slack.txt của driver thực chất chứa toàn R2R, không phải phép đo tách riêng P2. OOC chưa có HD.CLK_SRC, nên không phải board/clock-tree signoff; ba directive không phải ba random seed.


**Kết luận nghiệm thu refactor parser:** giữ bản XOR một detector làm nguồn hiện hành theo ưu tiên diện tích của sinh viên. Median LUT225→205 (−8,89%) ở cả bốn part/profile; FF114 gồm34FF input bank, không tăng. Từng cặp cùng strategy đều giảm LUT (8,89–12,79%). Không thay I/O/parameter hoặc bất kỳ bank/handshake/reset nào; collector kiểm đồng nhất header, bank/control và source SHA.

| Part | NB/ES | Median LUT cũ → XOR | FF benchmark | P1 STA MHz cũ → XOR | Thay đổi |
| --- | --- | --- | --- | --- | --- |
| xc7a35tcpg236-1 | 32/2 | 225 → 205 | 114 → 114 | 157.33 → 156.57 | -0.49% |
| xc7a35tcpg236-1 | 32/3 | 225 → 205 | 114 → 114 | 152.44 → 164.53 | +7.93% |
| xc7a100tcsg324-1 | 32/2 | 225 → 205 | 114 → 114 | 164.02 → 156.84 | -4.38% |
| xc7a100tcsg324-1 | 32/3 | 225 → 205 | 114 → 114 | 164.96 → 155.71 | -5.61% |

MHz là ước lượng1000/(5ns−R2R slack), đã bao gồm yêu cầu setup/clock uncertainty/skew của benchmark; không phải nghịch đảo riêng datapath delay. Cả24 lượt có latches0/unrouted0; P1 hold dương. Setup ở5ns vẫn âm, chưa đóng200MHz. Toàn R2R có cùng đường dài nhất P1 trong24 lượt; không gán file p2 thành timing riêng tầng2. Không đo lại full NF/F PPA, power hoặc CDC/RDC; không chuyển PASS chức năng lịch sử thành bằng chứng final cho source mới. Các bước tiếp của SAC/khối lớn và paired NF/F vẫn theo§8.16/8.17.

<a id="legacy-8-20"></a>

### 8.20. OPT-01 — refactor prepack normalization và đo STA, 16/10/2026

**Phạm vi sinh viên chọn:** chỉ refactor `mul_prepack_norm_comb` và đo lại STA. Không triển khai OPT-02/03, không chèn bank hoặc đổi pipeline, không sửa SAC/adder/packer/parser. Baseline đóng băng sau parser XOR§8.19, ở commit53dd86b. Giữ nguyên mọi module production khác và header; hai variant khác đúng một module.

Thay runtime integer q/hidden_position và ghi bit vào chỉ số đích động bằng bốn ứng viên ánh xạ hằng tại elaboration: exact/approx × carry/no-carry. Với bit output i, exact lấy acc[i+2F−F_IN+carry] nếu nằm dưới hidden; approximate lấy acc[i+FRAC_W−F_IN+carry+2] trong miền tương ứng. Các vị trí ngoài miền là0. Bit carry là acc[2F+1] cho exact hoặc acc[FRAC_W+3] cho approx; scale tăng đúng1 khi carry. Không dịch bỏ bit giá trị, không đổi carry/sticky/metadata hoặc precision. F_IN nhỏ chỉ kiểm tính tương đương mapping cũ, không thêm profile số học mới.

**Kiểm chức năng đã đạt:** strict lint70 cấu hình leaf;1.592.064 đối chiếu baseline/candidate/oracle mask+shift độc lập0 mismatch. Bao gồm exhaustive miền nhỏ, random/directed quanh carry, SF wrap, F_IN rộng/hẹp, ACC_W đệm tới80, EXACT_EN0 hợp lệ mode1 và các width4 format. NF main EXACT_EN1 strict lint4 format sạch; pilot8/0,16/1,32/2 mỗi bản20.000 và32/3 100.000 giao dịch0 mismatch. Replay NF32/3 phân tầng10M có75.379 reset-aborted,0 mismatch; toàn bộ counters trong JSON trùng checkpoint corpus14/10. Đây là T4 của refactor, không thay final per-n NF/F hoặc ký AC04 structural coverage mới.

ModelSim10.1d chạy82.944 ca corner,0 mismatch, CK2Q/4-state. Chỉ bản sao LOD cho simulator thay hai sized-cast POS_W/S bằng typedef unsigned cùng width vì compiler2012 không hỗ trợ cú pháp đó;41.024 kiểm LOD/LZD của bản sao đạt0 mismatch. Production LOD/parser và toàn RTL F giữ nguyên. Cảnh báo pre-existing ở whole NF32/2 EXACT_EN0 (`sbm_shift_comb.y_mant[27:16]` unused) được tái hiện cả baseline/candidate; không sửa ngoài scope và không nghiệm thu thêm profile feature-disable này. Leaf EXACT_EN0 vẫn được kiểm riêng trong miền hợp lệ.

**STA đã hoàn thành12 lượt:** NF32/3,FRAC_W12,EXACT_EN=OPS_EN1; hai part A35T/A100T, ba directive Default/Explore/RuntimeOptimized matched trước/sau. Clock10ns, uncertainty0,1ns; inputmin=max2,5ns,outputmax0,5/min0; wrapper chỉ thêm BUFG giống nhau, không thêm data bank hoặc exception dữ liệu. Báo cả toàn R2R và cone norm_round, tài nguyên, endpoint, setup/hold/recovery/removal và I/O/unconstrained/methodology từ report. Không so trực tiếp số LUT4/MHz CycloneIV cũ với Slice LUTs/MHz Xilinx để quy lợi ích cho OPT-01; không suy NF/F paired PPA từ profile NF có exact.

Nguồn, SHA, seed, công cụ/lệnh, corpus reference và dữ liệu tại `results/prepack_refactor_20261016`. Kết thúc sau báo cáo OPT-01 và backup; các bước tiếp theo chờ yêu cầu mới của sinh viên.


**Kết luận OPT-01:** ứng viên bit-exact nhưng chưa có lợi ích STA nhất quán; giữ production bản cũ và lưu RTL mới tại `rtl/candidates/multiplier/mul_prepack_norm_comb.sv` (không thuộc production.f). Toàn bộ36 module production sau phiên giống baseline đầu phiên; riêng candidate ở thư mục thử nghiệm. Không gọi là tối ưu timing đã đạt hoặc đóng100MHz.

| Part | Median LUT trước → candidate | FF trước → candidate | Median MHz STA trước → candidate | ΔMHz | R2R đạt100MHz |
| --- | --- | --- | --- | --- | --- |
| xc7a35tcpg236-1 | 2464 → 2464 | 847 → 847 | 52.31 → 52.15 | -0.31% | 0/3 ở cả hai bản |
| xc7a100tcsg324-1 | 2458 → 2453 | 847 → 847 | 53.69 → 52.38 | -2.45% | 0/3 ở cả hai bản |

12/12 lượt latches0/unrouted0, hold R2R dương; setup100MHz vẫn âm. Toàn R2R và nhóm norm_round cùng có đường dài nhất trong các lượt này. Nhánh đi từ acc/sf_o của core qua normalize và round_unpacked(pack/parse) tới product_frac_q hoặc norm_sf_q. Routing còn chiếm phần lớn delay (ví dụ candidate Default A35:13,161/19,076ns), nên cách viết nối bit hằng chưa giải quyết được đường tổ hợp chung này. Không coi việc giảm mức logic của một lượt riêng (32→27) là cải thiện toàn MAC khi median/part chưa ủng hộ. Đây là giới hạn đo của OPT-01, không tự chuyển sang tách pipeline.

Runners tái lập bằng source frozen và output mới; báo cáo/corner/source/corpus được nén ở evidence.zip, có SHA và helper restore an toàn. Version/seed/commands trong summary.json; raw line coverage giữ lại, chưa tái ký structural AC04 hoặc final per-n. Dừng tại đây theo yêu cầu sinh viên; chỉ backup phiên, không triển khai thêm bước thiết kế.

<!-- OPT03_REPORT_START:l1/PLAN.md -->

<a id="legacy-8-21"></a>

### 8.21. OPT-03 — product RNE P1/P2 và parse riêng, 17/10/2026

Đã triển khai và giữ OPT-03 trong production: `normalize + product P1 → P2 → parse/product bank → adder A1/A2/A3 → final packer P1/P2`. Chỉ `rtl/mac_nf/mac_nf_wrapper.sv` thay đổi so với snapshot trước phiên. Không ghép OPT-01 candidate, OPT-02/04/05; không đổi L1, fused, precision hoặc thuật toán RNE. `round_unpacked_comb` vẫn giữ làm reference/unit. Giao diện/parameter top giữ nguyên; lịch NF thay đổi có chủ đích.

**Hợp đồng:** q=max(1,t thực tế), E0 accept; product P1 ở E(q+5), P2 E(q+6), parse/product E(q+7); first-valid E(q+12), handshake không stall E(q+13), nhận mới E(q+14). Tăng2 chu kỳ so checkpoint W11. C_eff/context giữ một giao dịch tới retire. Product packer dùng ready/valid elastic, flags đi cùng dữ liệu; product_capture=product_pack_valid && (!norm_valid_q || add_ready). Core_done một xung, chỉ có một reservation nên không thiếu credit. Không thêm bản sao C/context hoặc register wide normalized. Numerical sticky tích=0; cut/tail xấp xỉ chỉ là status như hợp đồng P_hat cũ.

**Chức năng:** native bốn pilot20.000/format8/0,16/1,32/2,32/3; main32/3 **10,000,000 completed/85,316 reset-aborted,0 mismatch**. Seed main20264217, Verilator5.032/GCC15.2.0; ES3 dùng integer/dyadic oracle độc lập, không dùng SoftPosit ES2. Strict lint `--timing -Wall` cả4 format sạch; native `--no-timing` chỉ bỏ CK2Q để kiểm chu kỳ. 72/72 control bins,256/256 regime–dấu main, kiểm trực tiếp product/C_eff vào adder; near-cancellation standalone/acc lần lượt 66.2674%/32.2673%. Cùng generator/seed nhưng vì generator phụ thuộc clock, không gọi đây là byte-identical stream với checkpoint trước retiming.

ModelSim10.1d giữ CK2Q:82.944 corner và28.512 protocol completed/288 reset-aborted,0 mismatch. Schedule suite thêm284 lần reset theo mọi age pipeline trên4 format; kiểm product capture sau core_done đúng2 cạnh, không token cũ lọt qua reset, first-valid/handshake/II ở cả exact/approx và không stall. Private LOD copy chỉ đổi parameter-sized cast thành typedef cùng width cho compiler cũ; unit41.024/0 mismatch; production LOD giữ nguyên. Reset/stall/context/acc commit và output giữ ổn định được kiểm.

**STA/PPA:** Vivado2026.1 build6511674, NF32/3,FW12,EXACT_EN=OPS_EN1; cả runtime exact/approx còn trong netlist. Cùng BUFG wrapper, part/speed-grade,10ns/uncertainty0,1ns,I/O max=min input2,5ns/output max0,5ns min0. Ba directive Default/Explore/RuntimeOptimized, không gọi là ba random seed.6 candidate P&R mới;6 baseline reference từ OPT-01 được tái dùng sau xác nhận toàn36 SV+header giống byte và run Default mới trên cả2 part tái lập đúng mọi metric. Hai lần tổng hợp baseline thừa được chủ động dừng; log giữ riêng `calibration/`, không tính là run nghiệm thu. Candidate tổng hợp một lần/part rồi mỗi directive đọc lại checkpoint synthesis trước opt/place/route, không nối tiếp placement của run trước.

| Part | Median STA MHz trước → sau | Thay đổi | Median LUT trước → sau | FF trước → sau |
| --- | --- | --- | --- | --- |
| xc7a35tcpg236-1 | 52.31 → 78.41 | +49.90% | 2464 → 2462 | 847 → 930 |
| xc7a100tcsg324-1 | 53.69 → 79.28 | +47.66% | 2458 → 2449 | 847 → 930 |

STA MHz=1000/(10−R2R slack), là ước lượng theo constraint của run; chưa đạt R2R setup100MHz ở tất cả run. Hold/latch/unrouted, setup, I/O, recovery/removal và methodology lưu raw report; không board signoff hoặc matched NF/F. FF không gồm bank I/O thêm vì benchmark chỉ thêm BUFG. Không suy gain fusion từ so với F profile EXACT_EN0.

**Tác động throughput:** top một giao dịch nên phải tính fclk/II, không chỉ MHz. Bảng `throughput_ratio_by_q` trong summary báo q1/2/4/8 với II cũ=q+12, mới=q+14; đây là tỷ lệ ước lượng từ median STA, chưa là throughput đã chạy trên kit. Gate4/final per-n/AC04/CDC/RDC/formal còn mở; không chạy Table I.

**Tái lập:** `bash --noprofile --norc scripts/verify_opt03.sh` (WSL, đặt `OPT03_RESULTS_DIR=results/opt03_replay` để giữ bằng chứng cũ); Windows `scripts/verify_opt03_modelsim.ps1 -RunRoot results/opt03_replay`, rồi `scripts/verify_opt03_schedule.ps1 -RunRoot results/opt03_replay`. STA tiếp theo chỉ A35T: `scripts/run_opt03_ppa.ps1 -Part xc7a35tcpg236-1 -RunRoot results/opt03_ppa_replay`; không chạy thêm A100T. Runner từ chối ghi đè run đã có kết quả; snapshot gốc giữ trong source/. `python scripts/audit_opt03.py restore` khôi phục raw proof từ archive; `collect` audit checkpoint gốc. Hash nguồn, driver, fixture, compiler, binary đã chạy, counters và lệnh ở results/opt03_20261017. Không tự chạy prepare_opt03/prepare_opt03_sta trên checkpoint đã khóa.
<!-- OPT03_REPORT_END:l1/PLAN.md -->

**Đường còn vướng sau OPT-03:** cả6 run có critical endpoint `u_add/a1_q_reg[y][0]`, từ C_sf/C_frac hoặc product_frac qua align. WNS A1 từ−3,114 đến−2,065ns ở10ns. Cone P2→parse/product bank còn−1,798..−0,241ns; product P1 từ−0,260 đến+0,301ns (không đạt100MHz đồng nhất), product P2 có+2,818..+3,469ns. Ưu tiên đợt sau là thử OPT-02 tại toàn NF rồi đánh giá parse/P1; chưa triển khai thêm trong phiên này. Kiểm dense II có292 lần handshake cặp liên tiếp đạt đúngq+14. Lỗi runner `read_checkpoint` sau Default đã sửa thành `open_checkpoint`; bảo toàn driver/log Default và SHA checkpoint, resume hai directive còn lại từ synthesis, không sửa RTL để xử lý lỗi công cụ.

<a id="legacy-8-22"></a>

### 8.22. Một lượt STA A35T: hai tầng kề product P1 — 17/10/2026

Theo yêu cầu sinh viên, chỉ chạy **một synth_design, một place_design Default, một route_design Default** của toàn NF32/3 FW12 EXACT_EN1 OPS_EN1 trên xc7a35tcpg236-1, Vivado2026.1 build6511674. OOC wrapper chỉ BUFG, clock10ns/uncertainty0,1ns; inputmin=max2,5ns,outputmax0,5ns/min0. Không sửa RTL, không mô phỏng hoặc sweep. Toàn36 SV+header giống byte với OPT-03 đã kiểm; source/driver snapshot và SHA tại results/single_a35_packer_20261017.

| Đoạn vào bank | Setup slack ns | Hold slack ns | Data delay ns | Register đích |
| --- | --- | --- | --- | --- |
| Trước P1: cộng tích lũy → ACC | +3,831 | +0,148 | 6,042 | 54 |
| ACC → normalize/encode/GRS → P1 | +0,301 | +0,137 | 9,527 | 43 |
| Sau P1: RNE/sign → P2, gồm data/flags/valid | +3,467 | +0,182 | 6,391 | 38 |
| P2 → parse/product bank | −0,327 | +0,130 | 10,203 | 44 |

Worst path trước P1: t2_first_reg→acc_reg[53], qua chọn first và cộng term/acc. P1: acc_reg[15]→p1_sticky_bit_q_reg. P2: p1_mag_trunc_q_reg[25]→d_q_reg[18]. Đây là worst setup của mọi launch register tới từng nhóm đích (bao gồm đường điều khiển tới D/CE nếu có), không dùng slack SAC làm thay thế accumulator hoặc chỉ lấy một cặp bit thuận lợi. Danh sách register, top10 setup/top5 hold từng nhóm giữ trong report.

Hai tầng kề P1 đều có slack dương ở chính lượt A35T này; P1 chỉ dư0,301ns. Có cơ sở khảo sát cân bằng logic, ưu tiên phần sticky/inexact sang P2; không cộng/trừ slack giữa tầng như ngân sách cố định vì routing/CE/FF thay đổi. Chuyển về phía ACC cần giữ raw accumulator và quan hệ hồi tiếp từng term, không chuẩn hóa lại trạng thái mỗi vòng. Chưa chốt retiming hoặc thêm stage.

Toàn MAC: WNS R2R−2,887ns,hold+0,056ns,2462LUT/930FF,ước lượng STA77,60MHz; critical c_sf_q[2]→A1.y[0],chưa đạt100MHz. Một run không thay median OPT-03 hoặc Gate4/board signoff. Phần parse sau P2 vẫn thiếu timing.

**Giới hạn runner:** P&R và cả5 nhóm báo cáo yêu cầu đã xuất đầy đủ. Sau đó, truy vấn phụ ngoài phạm vi tới bank A3 của packer tổng dùng sai tên `a3_q` (RTL thực dùng các output register riêng), làm batch exit1. Không chạy lại P&R. Collector chỉ nghiệm thu PASS_REQUESTED_SCOPE, ghi nguyên lỗi phụ trong summary; giữ driver thực thi và log gốc. Script canonical đã bỏ truy vấn phụ để tránh lặp lại lỗi; không tuyên bố toàn batch cũ exit0. Không có lỗi sửa RTL hoặc kiểm chức năng trong phiên này.

Lệnh đã chạy: PowerShell `./scripts/run_single_a35_packer_sta.ps1`; kiểm lại bằng `python scripts/collect_single_a35_packer.py`. Runner từ chối output đã tồn tại, không tự chạy thêm lượt. Dữ liệu gọn trong evidence.zip + archive_manifest.json, stages.csv và summary.json; giữ raw report quan trọng. Nhật ký Git sao lưu gồm nguồn/script/bằng chứng/tài liệu, không binary, checkpoint hoặc cache.

<a id="legacy-8-23"></a>

### 8.23. OPT-02b — A1 tổ hợp với SF-only shifter và prefix OR, 17/10/2026

Theo đề xuất sinh viên, thử candidate riêng `rtl/candidates/adder/opt02b/posit_add_align.sv` với cùng tên module/I/O/parameter như production. Hai hiệu signed mở rộng SF_W+1 và clamp tính song song. Chọn seed trước shifter chỉ theo dấu hiệu scale; cùng sf bypass shifter, chọn small fraction bằng comparator ở MUX cuối. Tạo prefix lo_or bằng reduction trên lát bit cố định, không chuỗi OR nối tiếp; lookup jam[s]=lo_or[s+1] là wiring cố định, không thêm adder cho chỉ số. Chỉ dịch upper bits; bit0 lấy từ jam lookup. Không mask động, không phép trừ tạo mask. Giữ nhánh delta>F+2 trả y=1/tail=1, tie chọn A và ưu tiên NaR/Zero/flags. Không thêm thanh ghi, C prefix register, max_fanout hoặc đổi latency/II. Candidate không thuộc production.f; không compile đồng thời với module production cùng tên.

**Chức năng:** ModelSim10.1d leaf baseline/candidate/integer oracle đạt **880,656/0 mismatch**,11 profile gồm4 format và F2..27, SF_W đến35/override. Directed mọi vị trí one-hot và shift0..F+3, hai chiều sf, cả dấu, equal fraction, dirty special, signed extrema; F<=5 có exhaustive fraction/delta như checker. Seed20261017+100*NB+ES+10000*SF_W. Không gọi là formal hoặc exhaustive mọi cặp fraction32-bit/XZ.

Verilator5.032/GCC15.2.0: **406 strict leaf lint**,4 strict whole-NF lint sạch; native4 pilot20k và main32/3 **10.000.000 completed/85.316 reset-aborted,0 mismatch**,seed20264217. Toàn bộ JSON counters/cycle/bin khớp checkpoint OPT-03, xác nhận cùng stream vì latency và điều khiển không đổi. ES3 dùng oracle integer/dyadic độc lập; exact ES0/1/2 còn so SoftPosit đúng format. ModelSim NF82.944 corner+28.512 protocol completed/288 abort,0 mismatch,giữ CK2Q/reset/stall/context/commit. Native no-timing chỉ bỏ CK2Q; strict lint vẫn timing. Bản khởi đầu có cảnh báo cast hằng F+2 khi SF_W>32; đã đổi thành delta_t'(F)+delta_t'(2) và chạy lại toàn bộ nghiệm thu trên bản cuối. Log pre_cast_fix giữ riêng, không cộng vào tổng.

**PPA:** một candidate P&R A35T xc7a35tcpg236-1 Default, Vivado2026.1 build6511674, toàn NF32/3 FW12 EXACT_EN=OPS_EN1. Cùng source baseline37file,BUFG wrapper,source order và chuỗi lệnh synth/constraints/opt/place/route trước report với lượt single_a35_packer_20261017. Clock10ns/uncertainty0,1ns,inputmin=max2,5ns,outputmax0,5/min0; không exception mới. Chỉ thay file A1 trong snapshot private; production giữ nguyên.

| Chỉ tiêu | Baseline Default | OPT-02b Default |
| --- | --- | --- |
| A1 setup slack ns | −2,887 | +0.674 |
| A1 data delay / logic levels | 12,749ns /19 | 9.189ns /12 |
| Toàn MAC R2R setup slack ns | −2,887 | +0.251 |
| Toàn MAC R2R hold slack ns | +0,056 | +0.047 |
| STA MHz ước lượng | 77.60 | 102.57 (+32.19%) |
| LUT / FF / CARRY4 | 2462 /930 /99 | 2516 /930 /94 |
| DSP / BRAM | 0 /0 | 0 /0 |

P1 setup+0.528ns,P2+3.765ns,parse/product+0.434ns,accumulator+3.318ns. Slack của các đoạn không đổi RTL vẫn thay đổi do placement/routing; không quy toàn bộ chênh lệch này cho thay thuật toán của chúng. A1 còn12 logic levels, không xác nhận ước lượng8–9. Critical mới: `u_dut/u_wrapper/u_core/u_ctrl/fx_q_reg[4]/C` → `u_dut/u_wrapper/u_core/u_ctrl/emitting_q_reg/D`, phía SAC/controller; routing chiếm80.17% delay đường này.

**Kết luận phạm vi:** candidate đạt setup/hold100MHz trong một OOC run; LUT tăng54 (+2,19%),FF không đổi,CARRY4 giảm5. Giữ candidate để review, **chưa promote production** vì chưa có>=3 chiến lược P&R matched xác nhận. Quyết định17/10 chỉ yêu cầu khảo sát tiếp trên A35T, không còn điều kiện cross-part/A100T. Không gọi là board signoff, Gate4 hoặc paired NF/F PPA; no new final AC04/per-n. Không ghép C precompute hoặc đổi P1/P2.

Lệnh đã chạy: `scripts/verify_opt02b_leaf.ps1`, WSL `bash --noprofile --norc scripts/verify_opt02b.sh`, `scripts/verify_opt02b_modelsim.ps1`, `scripts/run_opt02b_a35_ppa.ps1`; sau đó `python scripts/audit_opt02b.py collect`. Nguồn/driver/seed/compiler/hash/counter/report lưu results/opt02b_20261017; archive gọn và manifest SHA. `audit_opt02b.py restore` khôi phục raw bằng chứng khi clone, collect kiểm checkpoint đã lưu. Runner chặn ghi đè bằng chứng đã có; không chạy lại prepare vào snapshot đã khóa. Giữ dữ liệu lịch sử trước đó và cập nhật tiến độ theo mốc thử nghiệm, không đánh dấu toàn Gate4.

<a id="legacy-8-24"></a>

<!-- NF_ALL_STAGES_REPORT_START -->
### 8.24. Bảng STA đủ bank MAC NF candidate OPT-02b — 17/10/2026

Một lượt synth/place/route Default mới trên xc7a35tcpg236-1, Vivado2026.1 build6511674; nguồn37file giống byte checkpoint OPT-02b trước đó. NF32/3, FW12, EXACT_EN=OPS_EN1,100MHz/10ns, uncertainty0,1ns,inputmin=max2,5ns/outputmax0,5ns min0. Không sửa RTL, mô phỏng hoặc promote candidate; đây là đo lại cùng cấu hình, không tính là một directive/seed độc lập để nghiệm thu đa run.

Mỗi hàng lấy worst setup và worst hold của mọi đường được timing vào chân D/CE của bank đích; gồm launch từ register hoặc input port, và control/enable. Hai giá trị có thể thuộc hai đường khác nhau. Không gọi data delay là setup time của FF, không cộng slack các tầng. Các bank context/control/feedback không làm tăng số tầng số học. Parser A/B/C chạy song song; L1/L2/L3 lặp theo term.

| Bank / tầng đích | FF | Setup slack (ns) | Hold slack (ns) | Data delay worst setup (ns) |
| --- | ---: | ---: | ---: | ---: |
| Parser A — P1 | 39 | +1.543 | +0.221 | 7.867 |
| Parser A — P2 | 39 | +4.532 | +0.207 | 5.374 |
| Parser B — P1 | 39 | +1.395 | +0.178 | 8.628 |
| Parser B — P2 | 39 | +4.288 | +0.071 | 5.342 |
| Parser C_eff — P1 | 39 | +1.190 | +0.143 | 8.649 |
| Parser C_eff — P2 | 39 | +3.181 | +0.135 | 6.234 |
| OPS → M0/context core | 44 | +2.222 | +0.141 | 7.631 |
| SAC/controller — state feedback | 43 | +0.251 | +0.068 | 9.693 |
| SAC/controller → token L1 | 10 | +0.323 | +0.265 | 9.583 |
| SBM dịch → L2 | 59 | +4.316 | +0.109 | 5.536 |
| SBM tích lũy → L3 | 57 | +3.318 | +0.078 | 6.246 |
| Normalize + pack tích — P1 | 43 | +0.528 | +0.117 | 9.326 |
| Pack tích — P2/RNE | 38 | +3.765 | +0.093 | 6.086 |
| Parse lại tích → product bank | 44 | +0.434 | +0.068 | 9.413 |
| Adder — A1 align | 76 | +0.674 | +0.129 | 9.189 |
| Adder — A2 cộng/trừ | 49 | +5.095 | +0.047 | 4.322 |
| Adder — A3 normalize | 48 | +1.707 | +0.105 | 7.87 |
| Packer tổng — P1 | 44 | +1.491 | +0.117 | 8.294 |
| Packer tổng — P2/RNE | 38 | +3.310 | +0.129 | 6.619 |
| C/context giữ giao dịch | 40 | +4.576 | +0.054 | 4.839 |
| Điều khiển transaction | 10 | +2.885 | +0.164 | 7.011 |
| Accumulator feedback/commit | 32 | +1.239 | +0.125 | 8.101 |
| Reset bridge/synchronizer | 21 | +7.962 | +0.060 | 0.432 |
| Toàn bộ bank dữ liệu/CE | 930 | +0.251 | +0.047 | 9.693 |

Partition phủ toàn bộ930 FF, không trùng/thiếu bank; reset được tách riêng, recovery/removal còn trong timing.rpt. Báo cáo setup/hold từng nhóm giữ top3 đường và danh sách FF. Output port có worst setup+0,345ns (in_ready),hold+1,482ns (d[10]); đây không phải bank pipeline mới. Vivado cảnh báo Route35-198: port OOC chưa có HD.PARTPIN_LOCS; các đường launch từ input port (đặc biệt parser P1) hoặc tới output chỉ là ước lượng với constraint I/O, chưa có routing chân board chính xác. Phải xem startpoint trong CSV; không coi slack I/O này là signoff phần cứng. Đây là OOC STA, không board signoff hoặc paired NF/F. Production A1 chưa áp dụng OPT-02b; không gán bảng candidate này cho production. Giữ routed.dcp local để truy vấn thêm mà không phải P&R lại; checkpoint/cache không push Git. Evidence zip và manifest SHA giữ nguồn, driver, reports và summary gọn tại results/nf_all_stages_20261017. Lệnh: scripts/run_nf_all_stages_sta.ps1; python scripts/collect_nf_all_stages.py.
<!-- NF_ALL_STAGES_REPORT_END -->

<a id="legacy-8-25"></a>

### 8.25. Tối ưu Fmax/tài nguyên giữ latency/II — triển khai từ17/10/2026

**Trạng thái: processing.** Sinh viên đã yêu cầu triển khai mục8.25 ngày17/10; bằng chứng mới ghi tại8.28. Phần mô tả phương án dưới đây không tự là nghiệm thu timing hoặc Gate4. Giữ candidate tách production đến khi đủ kiểm chứng và matched PPA.

<a id="legacy-8-25-1"></a>

#### 8.25.1. Điểm xuất phát và giới hạn

- Production NF là OPT-03, A1 production chưa đổi sang OPT-02b. Candidate OPT-02b đã kiểm bit-exact và đo A35T tại §8.23/8.24. Dùng snapshot candidate làm mốc khảo sát tiếp, đồng thời giữ production/reference và mọi report lịch sử. Việc thử tổ hợp không tự promote OPT-02b.
- Profile NF khảo sát: NB32/ES3, FRAC_W12, EXACT_EN=OPS_EN1, FLOOR/RNE; kiểm cả runtime exact/approx và OPS0/1 theo hợp đồng. Baseline/candidate phải cùng feature policy. F hiện chỉ hỗ trợ profile approximate W12-F-1, không dùng khác biệt EXACT_EN để suy lợi ích fusion.
- Giữ 14 tầng datapath NF và 13 tầng F hiện hành. Với q=max(1,t thực tế), NF giữ L_valid=q+12, H=q+13, II_min=q+14; F giữ q+11/q+12/q+13. Giữ early-stop, reset/startup, stall, commit và thứ tự; số chu kỳ không đổi tại từng giao dịch. Không tính các bank context/reset/control thành tầng số học mới.
- Đợt này không thêm tầng pipeline. Có thể đổi nội dung bank nội bộ khi cân bằng logic, nhưng phải lập hợp đồng bundle trước sửa, ghi chi phí FF và giữ top I/O/parameter. Hợp đồng số học, precision, flags và L1 frozen giữ nguyên. Nếu đổi ranh giới P1/P2 hoặc A1/A2, cập nhật mô tả hiện thực/spec/TB cùng lúc trước nghiệm thu.
- Mục tiêu115–125MHz chỉ là hướng khảo sát. Không cam kết giảm2,5–3ns, tiết kiệm8 CARRY4+32LUT hoặc đạt slack>2ns trước đo. Báo Fmax ước lượng, tần số thực sự kiểm bằng STA và throughput=f_run/II riêng; chưa có phép đo power thì chỉ kết luận timing/tài nguyên.

<a id="legacy-8-25-2"></a>

#### 8.25.2. Thứ tự và điểm dừng

| Ưu tiên / ID | Việc dự kiến | Điều kiện chuyển bước |
| --- | --- | --- |
| 0 — OPT-00 bổ sung | Khóa hash production, OPT-02b và runner/constraints; xác nhận snapshot thực tế dùng cho từng phép so sánh | Phân biệt production, candidate tham chiếu và candidate mới; tái dùng bằng chứng cũ chỉ khi điều kiện còn khớp |
| 1 — OPT-05 | SAC-A → SAC-B → SAC-C; C so riêng hai cách phát hiện zero/one-hot | Leaf/core/top bit-exact; xem cả fx feedback và đường last/approx_cut; giữ ứng viên trước nếu bước sau không có lợi |
| 2 — OPT-09 | Product P2 lưu magnitude dương đã RNE/clamp, parser tích nhận magnitude trực tiếp | Định nghĩa bundle magnitude/sign/specials/flags/valid và backpressure; giữ parse(pack(u)), không bỏ làm tròn tích |
| 3 — OPT-10A | Thay mask/lost reduction của packer bằng prefix OR và lookup hậu tố phù hợp | Thử trong P1 trước, không thêm bank; so đầy đủ G/R/S, specials và flags trên các format hỗ trợ |
| 3b — OPT-10B, đóng sau 8.28 | Cân bằng sticky/flags từ P1 sang P2 (không mở vì 10A đã đưa `product_packer_p1` lên `+1.697 ns` và `final_packer_p1` lên `+3.184 ns`) | Đã đóng theo §8.28.4 / §8.29.3; không tăng FF biên P1/P2 |
| 4a — OPT-02c, ưu tiên cho A1 | Tách `clamp_ab/ba` khỏi `shift_amount`, thay so sánh `>` 12-bit bằng bit-check và tra `jam/tail` song song theo `shift_ab`/`shift_ba` trong `posit_add_align.sv` | 0 FF, không đổi biên A1/A2; đặc tả chi tiết tại §8.29.2 |
| 4b — OPT-11, dự phòng sau 02c | Cân bằng phần jam/alignment_tail từ A1 sang A2 (đóng nhánh `C-prefix precompute` vì đường găng xuất phát từ `norm_sf_q`) | Chỉ mở nếu sau `OPT-02c` vẫn cần thêm biên độ; không lấy CE slack A2 làm ngân sách số học (§8.29.2) |
| 5 — OPT-07/08 | Chọn tổ hợp cuối (`OPT-02b/02c + OPT-05 abc_tree + OPT-09 + OPT-10A`), đối chiếu `OPT-03`, freeze/promote và đồng bộ NF/F | Đủ xác nhận theo §8.16.4/5 và §8.28/8.29; khóa baseline trước khi chạy W14-01..08 |

Đọc lại STA toàn top sau mỗi bước đã qua kiểm chức năng; các nhánh `OPT-04` (A2/A3 LOD), `OPT-06` (`posit_add_norm` zero/shared), `direct round_unpacked` và `remaining-scale budget` được đóng chính thức tại §8.29.3 do các bank tương ứng đã dư biên độ timing (`+1.344 .. +5.007 ns`).

<a id="legacy-8-25-3"></a>

#### 8.25.3. OPT-05 — SAC/controller

SAC-A dịch cố định1 bit trước barrel shifter, LOD nhận fx gốc; giữ sa=clz+1 ở cổng hiện có và generate riêng W_X1. SAC-B mở rộng scale/count/hằng1 lên S_W+1 bit rồi cộng; kiểm carry, state_error và netlist thay vì mặc định biểu thức ba toán hạng sinh một adder. Giữ hành vi không hợp lệ đã nêu ở §8.16.3.

SAC-C so hai phương án: (a) fx&(fx-1) với quy ước zero rõ ràng; (b) cây cân bằng zero/one-hot. Phương án(a) có thể tạo carry chain mới. Với cây(b), mỗi nhóm trả zero và exactly_one; ghép zero=zL&zR, one=(oneL&zR)|(zL&oneR). Dùng single_one=zero|one khi cần nghĩa nhiều nhất một bit1, rồi giữ exhausted=!leading_valid||(term_valid&&single_one).

Controller phải chọn exhausted đúng exact/approx và chứng minh tương đương kiểm zero/nonzero của fx_next đang chọn, cả khi lỗi. Giữ launch, n0/init_only, limit/count, first/last/approx_cut, token drain và core_done; không phát done sớm. Không chỉ đổi cờ leaf đang nối unused. Đo A, A+B và A+B+C riêng; routing hiện chiếm khoảng80% đường SAC nên không dự đoán gain từ logic levels đơn thuần.

<a id="legacy-8-25-4"></a>

#### 8.25.4. OPT-09 — bỏ chuyển đổi dấu thừa tại product P2 → parse

P2 hiện đã gộp RNE và mã hóa dấu trong một carry chain ở posit_pack_finish; chưa có sẵn magnitude dương sau làm tròn để xuất miễn phí. Hướng khảo sát: đường product nội bộ lưu mã magnitude dương đã RNE/clamp và metadata cần thiết, rồi giải mã magnitude trực tiếp thay cho lấy bù hai lại từ packed signed code. Ưu tiên thay biểu diễn của bank hiện có; tránh lưu cả signed code lẫn magnitude hoặc thêm bộ cộng thứ hai chỉ để tạo cổng phụ.

Trước sửa, khóa sơ đồ và bundle thay thế product P2: width/magnitude/sign/Zero/NaR/flags/valid, ready/CE/reset và quy tắc giữ khi stall. Nếu cần module nội bộ riêng thì giữ packer dùng chung và top API; không tự thêm cổng/parameter công bố chưa được kiểm. Không nối raw prepack sang adder NF để tránh pack/parse, vì sẽ thay R(P_hat). F tiếp tục dùng prepack của profile fused.

Kiểm RNE tie-even/odd, carry đổi regime/exponent, hai dấu, zero/NaR, minpos/maxpos, flags và metadata approximate. So output unpacked với parse(pack(u)) và product bank hiện hành; identity của đầu vào Posit không đủ thay kiểm round-trip từ unpacked có G/R/S. Báo chi phí FF/LUT/CARRY4 toàn MAC; số8 CARRY4 trên đường parse cũ là bằng chứng vị trí tối ưu, không phải cam kết tài nguyên tiết kiệm.

<a id="legacy-8-25-5"></a>

#### 8.25.5. OPT-10 — sticky packer và cân bằng P1/P2

NF32/3 hiện F26, F_IN53, PAYLOAD_W=2+ES+F_IN+1=59, không phải82 bit. Phải suy width từ parameter cho các format hỗ trợ. Sticky hiện gồm incoming sticky, bit gốc rơi khi dịch và low shifted bits; offset phụ thuộc sf sau normalize.

10A: suy biểu thức OR của hậu tố payload tương đương, tạo prefix bằng lát bit hằng/cây phù hợp rồi chọn theo offset song song với shifter. Không mặc định prefix chỉ từ frac: bit exponent cũng có thể rơi vào phần bỏ. Giữ regime fill, offset0/cực đại, ES0, guard/round/sticky và ưu tiên special/clamp. Kiểm netlist xem synthesis đã rút gọn mask/OR tới đâu trước kết luận tiết kiệm.

10B chỉ mở nếu cần: chuyển một phần gộp sticky/inexact sang P2, sau khi chốt cụ thể raw bits hoặc partial OR nào đi qua bank. Chốt cả shifted_low có thể tăng nhiều FF; chỉ dời OR cuối có thể giảm rất ít delay. Giữ RNE dùng đúng sticky cùng token, flags[1] đầu vào, NaR/Zero/range overrides và cả RNE2/TRUNC1 nếu sửa module dùng chung. Đo lại cả product packer và final packer, cùng tác động lên F khi dùng chung; không lấy slack+3,765 hoặc+3,310ns làm ngân sách chuyển trực tiếp.

<a id="legacy-8-25-6"></a>

#### 8.25.6. OPT-11 — cân bằng A1/A2

Mốc A1 là OPT-02b, chưa phải production. Có thể chốt upper shifted data và các điều khiển/partial OR cần thiết tại A1, tạo y[0]/alignment_tail ở đầu A2 trước phép cộng/trừ. Trước sửa phải xác định rõ bundle mới và số FF; giữ signed delta/clamp, equal-sf bypass, tie chọn A, y=1 khi clamped, specials và ý nghĩa tail khi cancellation. Leaf A1 hiện có output hoàn chỉnh; nếu đặt lại ranh giới thì dùng cấu trúc pipeline nội bộ có hợp đồng rõ, không âm thầm đổi nghĩa output của leaf dùng chung.

A2 worst setup+5,095ns trong §8.24 là đường điều khiển từ meta_sync2 tới CE, không phải delay riêng của bộ cộng. Cần lấy thêm đường D qua arithmetic từ routed checkpoint và xem mọi đường D/CE sau thay đổi. Không dự đoán chuyển3 mức LUT sẽ đổi slack A1/A2 đúng một lượng cố định.

Precompute prefix C tại pair_retire là biến thể độc lập, chỉ dùng khi đã chứng minh C_eff giữ đúng giao dịch suốt busy. Kiểm acc_mode/acc_clr, reset hủy, stall/retire và chi phí FF; không tính nhiều chu kỳ ổn định của C là multicycle exception. So riêng với biến thể jam retiming trước chọn kết hợp.

<a id="legacy-8-25-7"></a>

#### 8.25.7. Constraint, kiểm chứng và tiêu chí chọn

- Phép đo tiếp theo dùng A35T-C2 tại mục8.27: ở10ns giữ input min=max2,5ns, output min0/max0,5ns, uncertainty setup/hold0,1ns; nạp XDC trước synthesis. Không đổi riêng constraint/exception/hold-fix cho candidate. Baseline/candidate cần matched cùng luồng C2; không mở A100T. C1 clock-only ở mục8.26 là thử nghiệm đã được điều chỉnh, không còn mặc định100MHz.
- Hold+0,047ns đã gồm user uncertainty0,100ns, nhưng không đổi nhãn thành slack thực+0,147ns. Giữ margin hiện hành; chưa cần tối ưu hold trước setup khi chưa vi phạm. phys_opt_design -hold_fix là nhánh P&R riêng nếu có nhu cầu thực tế, không bảo đảm nâng slack dương; áp cùng chính sách cho hai bản và báo cả chi phí setup/tài nguyên. Không xóa ASYNC_REG hoặc đổi reset để cải thiện số đo.
- Qua T0/T1/T2 trước đo: strict lint/latch/width/signedness; baseline/candidate/oracle trên mọi output bị ảnh hưởng; corner/exhaustive miền nhỏ rồi pilot. Module dùng chung phải kiểm các tuple đang hỗ trợ, không chỉ32/3. SAC theo bộ biên §8.16.3; packer/adder theo các corner ở trên. ES3 dùng oracle integer/dyadic độc lập, không dùng SoftPosit ES2 làm oracle ES3.
- Khi thay ranh giới bank, so scoreboard theo ID và cùng cạnh clock với baseline: latency/II lần này phải giữ nguyên, không chấp nhận dịch output chu kỳ. Kiểm first-valid/handshake/next-accept, reset/startup/abort, stall/full/bubble, output stable, C/config context và accumulator commit đúng một lần. Native cycle và ModelSim CK2Q có phạm vi riêng, không thay thế nhau.
- T3 khảo sát có thể dùng một cặp Default đã xác nhận nguồn/điều kiện để loại ứng viên không có lợi; ghi rõ chưa đủ promote. Trước freeze, chạy matched >=3 chiến lược P&R theo §8.16.4/5, không đếm hai lần Default cùng cấu hình là hai seed độc lập. Giữ mọi run, min/median/max và resources/route/control paths. T4 tổ hợp chọn cuối cần corpus NF10M/0 mismatch, ModelSim corner/protocol và coverage liên quan; thay đổi ảnh hưởng F thì kiểm F riêng theo profile đã công bố. Chưa thay final per-n/AC04 bằng regression refactor.
- Báo đủ setup/hold/TNS/THS/recovery/removal, unconstrained/latch/unrouted, LUT/FF/CARRY4/DSP/BRAM và worst paths D/CE của mọi bank. Kiểm lại các nút thắt kế tiếp: parserC P1+1,190ns, feedback+1,239ns, finalP1+1,491ns và output in_ready+0,345ns của mốc cũ. Không coi bốn bước đủ để bảo đảm115–125MHz. Đường I/O OOC chưa có PARTPIN/board routing chỉ là ước lượng; không nới I/O để tuyên bố Fmax hệ thống.
- Khi chọn tần số cao hơn, phải kiểm tại chính clock period đó; slack dương ở100MHz hoặc phép suy F_STA chưa là closure120MHz. So throughput/latency thời gian thực trên cùng q/workload, n0..8 và early-stop; ghi đánh đổi LUT/FF. Không giảm latency/II bằng thay thuật toán hoặc precision.
- Mỗi ứng viên có manifest nguồn, công cụ, seed/corpus, lệnh và bằng chứng gọn trong output riêng; giữ report lịch sử, không sửa snapshot đang chạy. Nếu mismatch, protocol lệch, width/latch lỗi hoặc PPA bất lợi thì dừng ứng viên đó, giữ mốc trước và báo căn cứ. Sau chọn tổ hợp mới đồng bộ SPEC/README/tiến độ và xem xét promote; phiên lập kế hoạch này chỉ sửa PLAN.md.

Tài liệu AMD đã đối chiếu khi review: [UG949 — Additional Uncertainty](https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Additional-Uncertainty), [UG835 — phys_opt_design](https://docs.amd.com/r/2024.2-English/ug835-vivado-tcl-commands/phys_opt_design). Báo cáo RTL/STA local ở §8.23/8.24 là căn cứ chính cho thứ tự khảo sát.

## 3. Hồ sơ kiểm chứng nền tảng và baseline đã chuyển khỏi PLAN

Phần này bảo toàn kết quả chức năng, oracle, freeze và provenance đã ghi trước đây; không phải tất cả đều là thí nghiệm tối ưu. Các checklist/lịch tuần đã hoàn thành đã gỡ. Các kết luận TableI không thay bằng chứng nguồn gốc của tác giả.

### L1 nhân lặp và bộ cộng — hồ sơ04/10

**Cập nhật 04/10/2026:** các header và test tuần 4 đã triển khai. TV-ITER/TV-PAPER và oracle bit-position approximate đạt; nhánh iterative exact đối chiếu L0 cho ES=0/1/2, đối chiếu nhân rộng cho ES=3. Đây chưa phải chạy lại toàn miền posit16/posit32 phân tầng cho nhánh iterative mới.
Thống kê 10 triệu cặp mỗi n=1..6 đã chạy theo hai phân bố ghi rõ trong README/log. Chưa đạt ngưỡng Table I ≤1 điểm phần trăm; tuần 4 vẫn processing. Không điều chỉnh thuật toán normative chỉ để ép khớp số liệu. Lệnh make test_table1 trả lỗi nếu chưa đạt; chạy test_table1_reproduce không có --require-match chỉ xác nhận thí nghiệm chạy xong.

**Nghiệm thu 04/10/2026:** posit_adder.hpp và test_adder.cpp đã triển khai. Posit8/16 vét cạn 65.536/4.294.967.296 cặp và posit32 ES2 phân tầng 10 triệu khớp SoftPosit, 0 mismatch. ES3 kiểm 10 triệu bằng oracle integer rộng, không gọi là đối chuẩn L0 ES3. Cả4 format có corner/ties/clamp/cancellation; >=30% near-opposite và mọi polarity/run hữu hạn >=10.000 operands. Linux/Windows/UBSan smoke 3.468.043 đối chiếu/nền tảng, regression đạt; Windows có thêm 10 triệu ES2/ES3. Full suite Linux 4.316.435.339 đối chiếu đạt. Tuần 5 hoàn thành; Gate 1B vẫn chờ MAC tuần 6. Xem README mục 12, results/week5_adder_* và make test-adder-acceptance.

### Parser/packer — kiểm chứng và tinh chỉnh ban đầu

**Nghiệm thu tổ hợp 05/10/2026:** `posit_parser_comb.sv` và testbench đạt 2.465.812 lượt trên ModelSim, 0 mismatch; posit8/16 vét cạn, posit32 ES2/ES3 mỗi format 1.200.010 mẫu, seed20261005. Chi tiết tái chạy và log xem `rtl/README.md`, `results/parser_comb/`.

**Nghiệm thu pipeline 05/10/2026:** `posit_parser.sv` hai tầng elastic đạt toàn bộ 2.465.812 fixture trên ModelSim, 0 mismatch; cả bốn format kiểm reset/startup/flush, stall dài, sức chứa hai slot, bubble, handshake đồng thời và thứ tự/không mất/không nhân đôi giao dịch. Cạnh input E0 → output valid sau E1 → output handshake sớm nhất E2, II=1 khi không stall. Reset leaf `reset_n` assert bất đồng bộ/deassert qua hai FF theo Guidelines; reset top `rst_n` theo SPEC; hợp đồng bridge/startup barrier hiện chốt tại §4.2, RTL tích hợp chưa triển khai. Vivado2026.1 compile/elaborate đạt; chưa tổng hợp/STA. Tuần7 hoàn thành phạm vi đơn vị, chưa phải Gate2/3. Bước tiếp theo là RTL packer/RNE tuần8 rồi kiểm parser→packer. Lệnh, coverage và hash tại `rtl/README.md` mục5, `results/parser_pipeline/`.

**Tinh chỉnh06/10/2026:** chuyển tạo Rgm sang P2 theo Fig.5(a), P1 giữ cnt/FRB thay cho cnt/k. Giảm5 bit thanh ghi RTL mỗi parser NB32; ModelSim2.465.812 fixture và reset/stall/latency/II kiểm lại đạt,0 mismatch. Vivado compile/elaborate đạt, tổng hợp so FF/LUT bị chặn do thiếu license nên chưa công bố lợi ích PPA. Không ảnh hưởng nghiệm thu tuần7 hoặc thứ tự tiếp theo tuần8.

**Nghiệm thu RTL tuần8 —07/10/2026, ✅ đơn vị:** packer tổ hợp/pipeline RNE2/TRUNC1 bốn format đạt5.947.048 lượt fixture, chain parser→packer4.931.624 lượt,0 mismatch trên ModelSim. Vét cạn identity8/16,32 phân tầng; ties/sticky/carry/clamp, flags, reset/full slot/stall/order/II/latency đạt. L1/bit-list generator2.973.524 dòng, seed20261006, hash và lệnh tại results/packer/. Vivado compile/elaborate đạt; Quartus3seed/cấu hình sau tối ưu P2: RNE537 LUT4/196FF,122,50–124,42MHz; TRUNC522 LUT4/152FF,100,67–101,01MHz; cả sáu run đạt setup100MHz ở benchmark riêng. Bộ cộng gộp làm tròn/dấu giảm LUT, không thêm tầng. Không suy Gate2/3 toàn MAC. Tiếp theo core tuần9; tối ưu timing theo đường tới hạn đã đo, chưa tự thêm tầng hoặc đổi spec.

### Cập nhật thực nghiệm baseline + cải tiến — 04/10/2026

Đã hoàn thành các bước triển khai/kiểm chứng theo quy trình baseline trước, biến thể sau:
1. `paper_multiplier.hpp`: RND có dấu, complement và n đếm tổng số hạng; ví dụ [15] và Fig.4 [P] đã kiểm.
2. OPS predictor n=2/7-bit tái dựng; tie-A là giả định; 128-entry truth table đã kiểm độc lập.
3. Generator [0,1) uniform-value grid24, oracle FP32 RNE, chính sách loại zero được ghi; paper chưa cung cấp seed/phân bố chi tiết.
4. 200 triệu cặp/hàng: max lệch Kim [15] 0,942710 điểm %, Proposed [P] 1,352910 điểm %; chưa đạt tiêu chí Proposed <=1 điểm %, không đánh dấu tuần 4 hoàn thành.
5. Cùng dữ liệu chỉ thay OPS min-popcount; ModelSim 116.384 cặp và Quartus ba seed/policy trên EP4CE22F17C6. Cây cân bằng giảm LUT4 73->63, nhưng register 15->25; fmax range chồng lấn và độ chính xác ngưỡng chặt giảm.

Nguồn đầy đủ/giả định/log/lệnh: README mục 6, SPEC phụ lục B/C, `results/paper_table1_200m.log` và `results/ops_ppa_summary.csv`. Không coi khảo sát OPS riêng là Gate 2 hoặc kết quả full MAC. Khóa các giả định còn lại trước khi mở rộng RTL.

### Bước 2 OPS đã tách và vét cạn — 04/10/2026

`paper_ops.hpp` cung cấp predictor cố định n=2/7-bit và tiền xử lý FP32 normal cắt 11 bit, giữ 12 bit fraction; predictor chỉ nhận 7 bit cao. `PaperMultiplier` dùng chung module; không đổi bảng hay RND/SBM. `test_paper_ops` kiểm 33.587.337 đối chiếu Linux/Windows/UBSan, gồm toàn bộ fraction23 và 4096x4096 cặp OPS, tie và n-independence. FP32 special classification có bypass/preserve payload, chưa là full IEEE multiply. Xem README mục 7 và log `paper_ops_step2_*.log`.

### Bước 3 bộ đo đã tách và kiểm chứng — 04/10/2026

`paper_measurement.hpp` khóa generator FP32 [0,1), seed/PRNG, oracle RNE trước cắt, thứ tự lọc và counters; so bốn ngưỡng bằng số nguyên chính xác. Suite 1.900.058 đối chiếu Linux/Windows/UBSan đạt, gồm oracle integer độc lập một triệu tích và ties tại ngưỡng. Replay/Linux/Windows khớp 100.000 accepted cho cả hai phân bố về tỷ lệ, counters và fingerprint. Xem README mục 8 và logs paper_measurement_step3. Bước 3 chức năng hoàn thành; lần 200 triệu trước là lịch sử, cần chạy lại bộ đo mới để nghiệm thu Table I. Tuần 4 giữ processing.

### Bước 4 chạy lại 200 triệu đã hoàn tất — 04/10/2026

Bộ đo bước 3 chạy seed 314159/grid24 trên 200.000.000 accepted (attempted=200.000.023, zero loại 23), fingerprint b4c229e09c0ec0ba. Các hàng trùng lịch sử ở độ chính xác log; max Proposed=1,352910 điểm %, max Kim=0,942710. --require-match trả 1 đúng vì chưa đạt Proposed <=1 điểm %. Xem README mục 9 và results/paper_table1_step4_*. Tuần 4 vẫn processing; ưu tiên khảo sát các giả định tái dựng còn mở và độ nhạy seed, ghi rõ nguyên nhân chưa được xác định.

### Khảo sát giả định và seed đã hoàn tất — 04/10/2026

Công cụ nghiên cứu test_paper_sensitivity kiểm một yếu tố mỗi lượt, 7 profile x 5 seed x 10 triệu accepted/hàng. Baseline max Proposed 1,337120–1,372450 điểm %; tie/pack không giải quyết sai lệch, guard12 có ảnh hưởng nhưng chưa đạt. Relative predictor E/M đạt <=1 trên 5 pilot seed; xác nhận seed mới 271828/200 triệu cho max 0,976696 điểm %, baseline cùng corpus 1,347652. Self-test Linux/Windows/UBSan 1.500.128 đối chiếu đạt; smoke cross-platform khớp. Xem README mục 10, paper_sensitivity_* logs/CSV/hash. Baseline/RTL giữ nguyên và tuần 4 processing: kết quả của biến thể không chứng minh LUT gốc. Bước tiếp theo có căn cứ là đưa relative_prediction thành tùy chọn nghiên cứu được kiểm chứng và đo chi phí comparator/PPA trước khi chọn cải tiến cuối.

### Tích hợp E/M và nghiệm thu profile L1 đã đạt — 04/10/2026

API paper_ops_select_relative<W>, PaperOps::PredictN2Relative và --profile relative đã tích hợp; mặc định/enum cũ/cfg_ops normative giữ nguyên. 35.503.586 đối chiếu Linux/Windows/UBSan đạt; make test đạt; smoke mặc định không đổi, relative cross-platform khớp. Target make paper-table1-relative chạy 200 triệu accepted seed271828: PASS/exit0, max Proposed 0,976696 điểm %, output khớp công cụ khảo sát. Xem README mục 11 và paper_relative_integration_* logs/CSV/hash.

Đã hoàn thành phần tích hợp, kiểm chứng và nghiệm thu số học của tùy chọn E/M. Tuần4 giữ processing vì yêu cầu tái hiện baseline hiện hành còn chưa đạt; không đánh đồng biến thể đạt ngưỡng với chứng minh LUT gốc. Đo PPA E/M phục vụ lựa chọn cải tiến sau đó, không bổ sung thành điều kiện bắt buộc của tuần4 L1.


### Đối chiếu [18] và ưu tiên khóa baseline — 04/10/2026

Đã đọc toàn bộ bản Babić 2010 vừa tải và đối chiếu [15]/[P]; bản được trích dẫn là 2011, chưa có toàn văn tương ứng. Recurrence hai toán hạng/CT và audit 65.025 cặp dương 8-bit được ghi ở README mục13; AE khớp Table4, một ô Table3 còn lệch0,1 điểm %. Không dùng kết quả này để đóng TableI FP32.

Ưu tiên baseline tiếp theo: kiểm cách căn accumulator theo exponent số hạng đầu l1 trong [15] §3.3. Mô hình hiện căn theo scale đầu vào; fixture p1=1 cho khác biệt khi cắt từng số hạng. Khảo sát anchor-first riêng, đối chiếu trace p1=0/1, oracle và nhiều độ rộng, rồi đo cùng corpus/seed trước khi quyết định sửa baseline. Chưa xác nhận đây là nguyên nhân sai lệch. Full LUT n2/tie, width và generator vẫn mở; E/M giữ vai trò cải tiến. Tuần4 processing và tuần5 đã nghiệm thu được giữ nguyên.




### Kết quả thực hiện ưu tiên baseline — 04/10/2026

Mục1: anchor-first đã triển khai/kiểm oracle; riêng anchor/guard chưa đạt. Mục2: đã quét guard0/1/2/12 và post-sum cut, kiểm oracle Q96/Q64; width gốc chưa xác minh. Mục3:2.097.282 đối chiếu tám fixture Table2/all don't-care tails,128 prefix/Fig2 đạt; prefix7 zero-extended trước complement tạo2 entry126/127 khác, nhưng chưa có full LUT n2/tie tác giả.

Mục4:200 triệu paired FP32/Posit, conversion/cut input không khác,12 tỷ lệ giống ở6 chữ số; source maxKim0,801969. Mục5:source_config đã tích hợp và29.878.945 đối chiếu Linux/Windows/UBSan đạt, regression đạt; bộ đo chính thức200 triệu seed271828 PASS maxProposed0,984213, legacy baseline/relative không đổi. Pilot5seed max0,970200–1,006150, hai seed vượt1; không công bố mọi seed đạt.

Mục6:PDF Babic2011 từ tác giả trảHTTP403; chưa tìm code/LUT/generator gốc. Tìm thấy publication2024 trên trang tác giả, chưa đọc full và chưa dùng thay baseline2021. Mục7:comparator Babic FP32 riêng200 triệu cùngcorpus PASS max0,009091 điểm %.

TableI baseline tái dựng đã đạt tiêu chí số học; xác minh baseline gốc vẫn processing ở LUT/width/provenance. Giữ default cũ và cfg_ops normative; source là profile có tên/lệnh rõ ràng để review. README mục14 và results/paper_source_* chứa bằng chứng. Không tự coi tuần4 hoàn thành về nguồn gốc, không thay tiến độ tuần5/6.

### Phương án1 — đọc và đối chiếu journal2024 — 08/10/2026

Đã đọc toàn văn và đối chiếu hình/bảng; kết quả ở README mục18 và `results/paper_journal2024/summary.json`. Kiểm PT2 theo pattern độc lập PASS128 entry dưới giả định prefix7 đệm0 đến Q12; củng cố predictor `source` và anchor-first. Chưa xác minh tie policy, guard12 hoặc generator gốc. Phép đo journal khác format/oracle2021, không dùng thay TableI2021.

Hoàn thành phạm vi tìm/đọc/kiểm của phương án1; mục3 và6 trong danh sách ưu tiên, cùng tuần4, vẫn **processing**. Không sửa profile normative hoặc công bố lượt200M mới. Ưu tiên còn lại: lập hợp đồng width/cut có căn cứ từ sơ đồ, kiểm riêng với oracle và control `source`; chỉ đo lại khi có thay đổi đã kiểm chứng. Lưu rõ phần suy luận nếu vẫn thiếu RTL/LUT/generator tác giả.

### Chốt và kiểm accumulator theo Fig.3 — 08/10/2026

Mốc width/cut L1 **✅**: `paper_fig3_config()` giữ Q12, guard thấp0, term logical-shift/cut trước khi áp dấu, normalize cuối vòng; payload13 + carry riêng biểu diễn tổng độ lớn14 bit. Mã hóa hidden/carry là hợp đồng tái dựng vì Fig.3 lược bỏ mạch cờ; không tuyên bố layout tác giả đã xác minh. Profile normative §5.6 và source guard12 giữ nguyên.

Vét cạn16.777.216 cặp mantissa và raw/corner/n1..8 PASS trên Windows/Linux/UBSan, regression liên quan đạt. Đo200 triệu cùng seed271828: fig3 **NOT_REPRODUCED**, max1,292319 điểm %, source control vẫn0,984213; năm pilot10M đều vượt1. README mục19 và results/paper_fig3 chứa hợp đồng,12 ô, log/CSV/metadata/hash.

Mục2 trong danh sách ưu tiên đã hoàn tất phần triển khai/kiểm/đo của hợp đồng tái dựng; provenance layout/cut gốc vẫn mở. **Tuần4 giữ processing**: không dùng nghiệm thu chức năng thay tiêu chí TableI, không sửa seed/guard để ép khớp. Cần xác minh generator, tie/PT2 padding và normalize/cờ nguyên bản trước khi kết luận nguyên nhân gap; chưa đủ căn cứ đưa profile paper vào RTL normative.

### Phương án3 — vector phân biệt, bốn bước hoàn thành — 08/10/2026

1. Tìm199.800 cặp `(A,B,n)`, chọn292 bản ghi/206 trường hợp khác nhau cho10 ứng viên; đủ32 vector mỗi nhóm9 loại và4 fixture trực tiếp.
2. Xuất trace từng vòng/output/first-difference;205.882 đối chiếu/nền tảng Windows/Linux/UBSan PASS. CSV ba nền tảng và pilot1M exact counts khớp.
3. Đọc lại Fig.4/5 bản2021: ép X theo hình, accumulator Q12=4616→5770→5914, output0x1ae34000. Source-uncut trả0x1ae34800 nên **loại khỏi baseline bit-exact2021**; các profile cut12 khớp ví dụ. Fig.4 không quyết định OPS tie, p1=1 hay precision nội bộ.
4. Đo200M cùng seed271828/corpus cũ cho fig3, guard12/cut12 và source-uncut. Maxgap lần lượt1,2923195 /1,3387730 /0,9842130 điểm %; hai profile khớp output chưa đạt thống kê, source chỉ đạt thống kê và giữ làm control.

README mục20 và `results/paper_discriminators/summary.json` chứa36 ô/counts, ma trận bằng chứng, compiler/seed/lệnh/hash. Mốc kiểm chứng phương án3 **✅**, baseline gốc/tuần4 **processing**. Kết luận source TableI đạt ở các mục lịch sử04/10 chỉ áp cho phép đo thời điểm đó, không xác nhận thuật toán gốc. Không đổi default/normative/RTL. Ưu tiên tiếp theo là nguồn trace/LUT cho tie/prefix126–127/đuôi âm, normalize/cờ và generator; không tăng guard/đổi seed để ép khớp.

<a id="legacy-7-1"></a>

### 7.1. Công việc mở đầu đã thực hiện — 08/10/2026

Đã chốt bundle context/token/accumulator, độ rộng và lịch drain trong SPEC §5.5-A. M0 chính là bank chốt context tại L0, không chốt OPS rồi thêm một bank context ngầm. cfg_n đếm fraction; exact không bị N_MAX giới hạn. init_only chỉ nạp Y; last commit tại accumulator mới phát done. SPEC §5.7 làm rõ FLOOR normalize trên Q(FRAC_W), không giữ bit rơi thành guard mới do thanh ghi có padding G/R.

Đã triển khai `rtl/multiplier/ops_sel_comb.sv` và `rtl/multiplier/sac_step_comb.sv`: OPS cắt trước cây popcount cân bằng, tie-A và kiểm cấu hình; SAC dùng LOD/shifter đã kiểm, hỗ trợ W_X=1, dịch bằng chiều rộng và kiểm S không wrap. Hai khối chỉ có logic tổ hợp; chưa phải M0/SAC pipeline hoặc multiplier hoàn chỉnh.

ModelSim kiểm159.820 vector OPS (feature bật/tắt) và167.620 trạng thái SAC ở độ rộng1/5/12/26/27,0 mismatch. W_X<=12 vét cạn fx và toàn miền scale biểu diễn; OPS width1/5 vét cạn cặp/mode/policy, width12/26/27 có directed +50.000 random mỗi width. Generator đối chiếu L1 với oracle đếm/quét bit độc lập, Linux/Windows/UBSan PASS và fixture khớp. Seed20261008; compile/mô phỏng cuối không warning. Log/compiler/seed/lệnh/hash ở `results/week9_frontend/summary.json`. Chưa có Verilator lint, STA/PPA hoặc handshake core từ mốc này.

<a id="legacy-7-4"></a>

### 7.4. Triển khai và kiểm chứng — 09/10/2026

W9-03 đã kiểm shifter, cộng tổ hợp, normalize/adapter:252.455 commit trên width1/5/12/26/27, hai scheme,0 mismatch. Bank `sbm_accum` được kiểm trong core; FLOOR bỏ padding trước normalize, không đưa input_cut vào numerical sticky.

W9-R1 chốt interface `paper_ops_comb`/`paper_step_comb`: Q12/prefix7 đệm0, tie-A, anchor số hạng đầu và payload13+carry1 là giả định tái dựng; RND/complement, coefficient âm và cut trước cộng/trừ ghi riêng. W9-R2 đạt843 commit,293 bản ghi (292 bản ghi corpus/206 trường hợp phân biệt + một fixture Fig.4),0 mismatch. Output force-X=0x1ae34000; kiểm thêm đủ128 entry PT2 và tie-A đạt. Không có bằng chứng mới để chạy R3 hoặc xác nhận RTL tác giả.

W9-04 đạt39.580 giao dịch hoàn tất và420 lượt reset hủy; width1/5/12/26/27, exact vượt N_MAX, n=0/early-stop, done=t+2 hoặc3, drain và context cố định đều được kiểm. W9-05 tích hợp parser A/B → M0/core → norm → packer với một slot dự trữ; pilot bản cuối31.840 giao dịch +160 reset hủy,0 mismatch. Reset bridge lấy mẫu rst_n; out_valid bị chặn tại cạnh reset, mỗi leaf nhả qua hai FF. RNE: L_valid=max(1,t)+7, TRUNC:max(1,t)+6; handshake khi không stall sau đó một cạnh. Thử config reserved/n>N_MAX, NaR/zero, stall dài, cạnh reset và giữ thứ tự.

ModelSim đối chiếu 16.815.920 giao dịch, hủy 80.080 giao dịch bằng reset,0 mismatch.

Corpus random-bit10.080.000 dòng chỉ kiểm số học, không đủ coverage regime dài. Đã bổ sung corpus phân tầng16.896.000 dòng/16 profile, có36 ô mode/ops/n, nhóm regime–dấu và fraction đặc thù theo §6.3. Generator phân tầng kiểm3.168.256 exact/RNE với L0 và1.056.256 với oracle ES3 độc lập; chỉ số này chưa thay kiểm RTL. Chạy riêng từng profile bằng verify_week9_multiplier_parallel.ps1; pilot đối chuẩn cùng checker đạt31.840 giao dịch/0 mismatch. Lượt16-DUT cũ đã dừng và không được tính nghiệm thu. Generator/fixture không thay nghiệm thu RTL. Verilator chưa có; `make lint` hiện trả lỗi khi thiếu công cụ thay vì skip rồi báo thành công. Harness C++ và `scripts/verify_week9_verilator.sh` đã chuẩn bị nhưng chưa build/chạy, cần đối chuẩn pilot khi có công cụ. Không tự cài công cụ ngoài quyền đã cấp.

Quartus13 phân tích/tổng hợp NB32/ES2/FLOOR/RNE đạt0 lỗi,14 warning đã phân loại (license parallel, attribute ASYNC_REG của Xilinx và constant resize có giới hạn); không có cảnh báo latch. Đây không thay strict lint, STA, CDC, PPA hay Gate4. Chỉ đổi generate/genvar để hỗ trợ compiler cũ trong hai shifter/OPS, không đổi phương trình; đã chạy lại327.440 frontend vector và843 paper commit đạt.

Bằng chứng, compiler, seed20261009, SoftPosit library hash, lệnh và SHA256: `results/week9_implementation/summary.json`; các log ở `results/week9_arithmetic`, `week9_paper`, `week9_core`, `week9_multiplier`. Gate2/tuần9 vẫn processing do lint/harness chính thức còn thiếu (coverage chức năng phân tầng đã đạt); tuần4/provenance paper giữ processing. GitHub đã push checkpoint 0ae39c4 lên main bằng checkout riêng trong Posit_MAC; kết quả lượt lớn được bổ sung cuối phiên.

Lượt phân tầng cuối đạt16.815.920 giao dịch hoàn tất,80.080 reset hủy; control random-bit đạt10.032.224 giao dịch,47.776 reset hủy; cả hai0 mismatch. Audit đối chiếu SHA fixture với log PASS và loại reset-abort trước coverage:16 profile đầy đủ, posit32 đạt256/256 bin regime–dấu, tối thiểu4.104 mẫu/bin và26.241 operands mỗi run/polarity hữu hạn;36 ô mode/OPS/n mỗi profile. Code coverage line/branch/toggle chưa đo.

Corner riêng đạt114.656 so sánh/544 reset hủy,3600 trường hợp khác nhau mỗi profile (100 cặp ×36 config), gồm ±1, ±minpos/maxpos và NaR×0/0×NaR; Linux/Windows/UBSan và replay32.000 dòng uniform cũ khớp. Pilot stall96 chu kỳ đạt31.840 so sánh/160 reset,336 lượt giữ dài;0 mismatch. Chỉ chỉnh khoảng trắng RTL để tách port/parameter, có proof và pilot biên dịch lại; SHA nguồn trước/sau lưu riêng. Logic không đổi, TableI không chạy lại.

Gate2/W9-06 vẫn processing: Verilator chưa có, harness C++ và lint chính thức chưa build/chạy. Không tự cài công cụ hoặc thay tiêu chí. Bằng chứng: results/week9_multiplier/{stratified_acceptance,acceptance_parallel,corners_final_rtl,long_stall_pilot}; snapshot/version/seed/lệnh tại results/week9_implementation/summary.json.

<a id="legacy-7-5"></a>

### 7.5. Top paper hồi tiếp tự động — 09/10/2026

`paper_mul_iter` là top structural riêng, logic trong `paper_mul_wrapper` và `paper_norm_comb`; cố định posit32/ES3, fraction12, PT2 prefix7 đệm0/tie-A, complement/RND, anchor số hạng đầu, accumulator Q2.12/14 bit và per-term FLOOR trước áp dấu, output cut12/TRUNC. Các lựa chọn tái dựng giữ nguyên; không đổi hợp đồng normative. `n_terms=1..8` đếm cả số hạng đầu, khác `cfg_n` normative; 0 và9..15 không được nhận. `force_a` phục vụ fixture/so fixed-A, bình thường0. NaR ưu tiên Zero.

E0 nhận A/B/n/force nguyên tử qua valid/ready; chốt X/Y, sign, sf_base, anchor và limit. Mỗi cạnh tiếp theo tự cập nhật một term cùng mantissa/exponent/coefficient/accumulator; dừng khi residual0 hoặc đủ n_terms. Sau t commit, cạnh E(t+1) chốt kết quả normalize→packer và phát out_valid; special t=0. Một slot giữ kết quả tới retire, không nhận thêm khi busy/stalled. `reset_n` assert bất đồng bộ, deassert qua hai FF tại wrapper; reset hủy giao dịch và chặn valid/ready/trace. Đây là lịch research địa phương, chưa xác nhận pipeline/timing của tác giả.

ModelSim10.1d đạt **17.181 giao dịch hoàn tất /65.710 commit,0 mismatch**. Bao gồm292 bản ghi corpus phân biệt cũ + fixture Fig.4, toàn4096 fraction A Q12 ở n1/3/8,100 cặp corner x3 giá trị n x2 policy force,500 cặp random x n1..8; seed20261009. Đối chiếu thụ động trace trước/sau từng vòng và output; không cấp lại trạng thái, không hierarchical force/write. Audit xác nhận843 commit cũ giống hoàn toàn, Linux/Windows/UBSan fixture MATCH; reference residual Q96 độc lập kiểm power/coefficient/accumulator/pack.

Fig.4 force-X: accumulator4616→5770→5914, output **0x1ae34000**. Kiểm216 special,24.036 term âm,14.199 term0,45.468 term có tail,1.082 dừng sớm,178 stall96 chu kỳ và4 reset hủy (sau capture, giữa vòng, PACK, HOLD) đạt; config/context đổi khi busy không ảnh hưởng giao dịch đang sở hữu. Không nghiệm thu flags riêng của paper, code coverage, lint, STA/PPA hoặc Gate2 bằng suite này.

Bằng chứng: `results/paper_top/windows/summary.json`, `results/paper_top/audit.json`; lệnh `make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan`, `scripts/verify_paper_top_modelsim.ps1`, `scripts/audit_paper_top.py`. Compiler/seed/lệnh/hash được lưu cùng kết quả. Không có thay đổi số học hoặc bằng chứng nguồn mới: **không chạy pilot TableI**, baseline gốc và tuần4 tiếp tục processing; Gate2 normative giữ trạng thái trước đó.

<a id="legacy-7-6"></a>

### 7.6. Rà soát SAC/n và packer theo nguồn — 09/10/2026

Audit trực tiếp nguồn2019/2021 và kiểm deterministic163.840 cặp cho thấy RND/complement và quét bit1 không tương đương. Fig4 khớp n_fraction2/n_total3 (0x1ae34000), nhưng n_total2 cho0x1ad14000; TableI Proposed chưa khóa cách đếm/recurrence từ nguồn. Giữ nguyên profile normative và top RND nghiên cứu, không đổi n/seed để ép bảng.

Reference cổng Fig5 độc lập khớp L1 trên3.940.352 trường hợp; ModelSim155.648 trường hợp đạt0 mismatch, Linux/Windows/UBSan MATCH.8.448 raw/clamped differences nằm ngoài miền sf−240..240, do range handling đồ án bổ sung; không phải lỗi RTL hoặc xác nhận clamp tác giả. Không chạy pilotTableI, baseline gốc/Gate2 vẫn processing. Chi tiết duy nhất tại README L1 §24; bằng chứng/lệnh/hash/compiler tại results/paper_contract_audit/{summary.json,windows/summary.json}.

<a id="legacy-7-7"></a>

### 7.7. Đối chiếu baseline Posit journal2024 — 09/10/2026

Pilot journal2024 dùng Posit32 ES2/Q12/PT2 tuyệt đối, oracle SoftPosit0.4.1; n đếm tổng số hạng. Self-test600.127 đối chiếu/lượt đạt0 mismatch, smoke Linux/Windows MATCH và UBSan đạt. Hai phân bố địa phương10M mỗi loại chưa khớp Fig9: rawPosit n2 Err<0,1%=8,954950%, cột nguồn khoảng53–57%. Cận OPS lý tưởng trong cùng hợp đồng chỉ9,667460%. TableVI khớp output n2 nhưng còn dư; lời văn nói t2=0 bất nhất với bảng. Không kết luận số liệu2021/2024 sai; không đổi n/cut/seed để ép bảng, không chạy full200M hoặc RTL ES2. Baseline gốc/tuần4 và Gate2 vẫn processing. Chi tiết tại README L1 §25, kết quả/compiler/seed/lệnh/hash tại results/paper_journal2024/measurement/summary.json.

<a id="legacy-7-8"></a>

### 7.8. Gate2 tool availability recheck - 10/10/2026

Rechecked 2026-10-10: WSL PATH contains g++ and make, but no Verilator or yosys. No installation is authorized. Official Verilator lint/harness remain unrun; Gate2 stays processing. No RTL changes, no simulation rerun, no Table I rerun. Historical stratified ModelSim evidence remains 16,815,920 completed transactions, 80,080 reset aborts, 0 mismatch. W9-03/R1/R2/04/05 evidence is retained; W9-06 is not accepted. No new source evidence justifies W9-R3.

<a id="legacy-7-9"></a>

### 7.9. Verilator installed; lint timing option corrected - 10/10/2026

Verilator 5.032 (Debian 5.032-1) is now installed by the user. Makefile lint explicitly uses --timing, preserving CK2Q delays. Re-run make lint: NEEDTIMINGOPT removed, exit 2 from make, 60 warnings remain (including MULTITOP, width and UNOPTFLAT diagnostics). No warning suppression, no RTL arithmetic changes, no functional harness run or Table I rerun; Gate2 remains processing. Raw output/version appended to results/week9_implementation/lint.log. Earlier missing-tool entry is historical.

<a id="legacy-7-10"></a>

### 7.10. Harness Verilator pilot — 10/10/2026

Pilot Verilator5.032 đã build/chạy đủ16 profile từ final_pilot:32.000 dòng,31.840 so sánh,160 reset hủy,336 stall96 chu kỳ,0 mismatch. Hash fixture và counters khớp ModelSim parallel_pilot; kiểm config reserved/n>8, startup/reset, latency, đổi context lúc busy, stall/order. Runner mặc định chuyển sang final_pilot còn giữ; preflight16 fixture, snapshot nguồn và make với đường dẫn tương đối/CURDIR=. xử lý thư mục có khoảng trắng, không sửa cài đặt. --no-timing bỏ delay CK2Q cho mô phỏng chu kỳ; warning giữ trong build.log, -Wno-fatal chỉ dùng build chức năng, không thay strict lint. Đây là fixture replay, chưa phải scoreboard gọi trực tiếp L1/L0. Gate2/W9-06 vẫn processing: lint còn cảnh báo, cần scoreboard trực tiếp, corpus phân tầng>=10^7 và coverage; line/branch/toggle chưa đo. Vector lớn đã dọn, phải sinh lại và kiểm hash trước replay. Không sửa RTL số học hoặc chạy TableI. Bằng chứng results/week9_multiplier/verilator/final_pilot/summary.json; lệnh bash --noprofile --norc scripts/verify_week9_verilator.sh final_pilot, audit scripts/audit_week9_verilator.py. Seed20261009; compiler/make/version và hash lưu cùng kết quả.

<a id="legacy-7-11"></a>

### 7.11. Nghiệm thu Gate2 — 10/10/2026


**Gate2 normative multiplier / W9-01..06: ✅ — 10/10/2026.** Nghiệm thu theo [hồ sơ Gate2](Optimization.md#legacy-7-11) và mốc tuần9 của SPEC; không thay ma trận regression cuối §6.7, Gate3 MAC, STA/PPA hoặc baseline gốc của tác giả. Các ghi chép processing phía trước là trạng thái lịch sử, được thay bằng kết quả này.

- Verilator5.032/GCC15.2.0:16 profile NB/ES=8/0,16/1,32/2,32/3 × FLOOR/JAM × RNE/TRUNC, EXACT_EN=OPS_EN=1. Corpus seed20261009 có16.896.000 dòng, hash khớp corpus ModelSim đã nghiệm thu; **16.815.920 so sánh,80.080 reset hủy,173.376 stall dài,0 mismatch**.
- Scoreboard gọi L1 trực tiếp trên16.896.000 dòng; exact/RNE đối chiếu3.168.256 với L0 SoftPosit0.4.1 và1.056.256 với oracle ES3 integer/bit-list độc lập. Counts oracle gồm cả input bị reset hủy; counts RTL chỉ gồm giao dịch hoàn tất. Source/fixture/library SHA256, compiler và lệnh được lưu.
- Corner đạt114.656 so sánh/544 reset hủy/0 mismatch trên cùng binary Verilator và ModelSim10.1d; đủ3600 ô corner/config mỗi profile. Pilot cuối31.840/160/0; frontend327.440, core39.580 và top paper17.181 giao dịch/65.710 commit đều0 mismatch khi chạy lại sau sửa lint; Fig.4 force-X giữ0x1ae34000.
- Strict lint `--timing -Wall` sạch16/16, không tắt warning. Sửa cast/width, tên debug và tách dependency tổ hợp; split_var chỉ hướng dẫn phân tích array. Functional build dùng `--no-timing`, bỏ CK2Q cho kiểm chu kỳ; warning ASSIGNDLY được giữ, không thay lint/ModelSim4-state hoặc STA.
- Coverage chức năng đạt mọi bin hợp lệ; posit32:256/256 bin regime–dấu, tối thiểu4104 mẫu/bin,26241 operands/run/polarity,36 ô mode/OPS/n mỗi profile. Raw coverage sau ghép stratified+corner: **line 91.67–96.23%; branch 91.84–94.79%; toggle 73.10–87.33%**. Giữ đầy đủ điểm chưa hit, không loại điểm để nâng tỷ lệ; padding/constants và nhánh config bị chặn ở top còn trong raw metrics. Mốc tuần9 không quy định ngưỡng phần trăm structural coverage. Chưa gọi đây là coverage100% hoặc signoff vật lý.

Báo cáo chốt: `results/week9_implementation/gate2_acceptance.json`; bằng chứng `results/week9_multiplier/verilator/gate2_stratified/{summary.json,comparisons.csv,functional_coverage.json,structural_coverage.json}` và `results/week9_implementation/lint_gate2/`. JSON chức năng/structure riêng không tự nghiệm thu Gate2; báo cáo tích hợp là trạng thái hiện hành.

Tái lập từ Posit_MAC với WSL `bash --noprofile --norc`, TMPDIR trong dự án:

```sh
make -C l1 gen_week9_multiplier
./l1/gen_week9_multiplier results/week9_multiplier/stratified_corpus 1056000 stratified
./l1/gen_week9_multiplier results/week9_multiplier/gate2_cornercorpus 7200 corners
make lint
bash scripts/verify_week9_verilator.sh stratified_corpus gate2_stratified
bash scripts/verify_gate2_corners.sh
make cov
python3 scripts/audit_gate2_acceptance.py
```

WSL runner cuối trả lỗi parser shell sau khi16 binary đã PASS do script được chỉnh khi còn chạy. `bash -n` trên bản cuối đạt; audit nguồn/hash/counters được chạy độc lập rồi replay corner và audit coverage đạt. Không coi exit của runner ấy là nghiệm thu; chỉ báo cáo tích hợp dựa trên đủ16 log và hash đã kiểm. Khi tái lập phải giữ runner/nguồn cố định suốt phiên.

Bước tiếp theo: tuần10 RTL adder → tuần11 MAC v1/Gate3. Ma trận lớn cuối §6.7, STA/CDC/PPA/Gate4 và provenance/TableI còn mở. Không có thay đổi số học được xác minh bằng nguồn paper trong phiên này, nên không chạy lại TableI; tuần4 giữ processing.

<a id="legacy-8-1"></a>

### 8.1. Checkpoint FLOOR/RNE prepack — 11/10/2026

Profile chính đã khóa tại SPEC§11.9, chọn tường minh qua `floor_rne_profile(n)`; không đổi API legacy. Exporter giữ magnitude/scale/Q trước mul_norm/pack, metadata cut tách khỏi numerical sticky. Linux/Windows17.184.416 kiểm mỗi bản khớp, UBSan smoke đạt; MAC/round regression và32.000 payload pilot cũ không đổi. Hash đóng băng tại results/l1_floor_rne_freeze/summary.json. Mốc W4 mới “hợp đồng nhân và tích nội bộ” đã kiểm; research TableI chưa xác nhận và được giữ riêng.

Đóng băng này không nghiệm thu L1 fused/căn chỉnh C/đuôi có dấu hoặc MAC RTL. Bước tiếp theo vẫn adder/NF/Gate3; L1 F cần oracle riêng và chính sách cửa sổ/cancellation trước RTL.

Tái kiểm từ Posit_MAC, WSL với TMPDIR trong dự án và LD_LIBRARY_PATH trỏ l0/l1:

```sh
make -C l1 test_prepack_product test_prepack_product.exe test_prepack_product_ubsan
./l1/test_prepack_product
./l1/test_prepack_product_ubsan --smoke
python3 scripts/audit_l1_floor_rne.py
```

Windows chạy l1/test_prepack_product.exe; audit còn cần log Linux/Windows, regression và fixture replay. Không xóa fixture replay trước audit. Source đổi thì audit từ chối; không dùng --refreeze để bỏ qua test lỗi.

<a id="legacy-8-3"></a>

### 8.3. Bàn giao W10-01 — 12/10/2026

Đã chốt posit_add NF ở SPEC§5.8-A..D: operand exact normalized F bits sau parser/round_unpacked; output F_OUT=2F+1+sticky tách metadata, ba tầng elastic A1/A2/A3 (H3,valid E2,handshake E3 khi input E0). GRS cuối do packer, không truyền tích prepack chưa round vào adder NF. Reset leaf/bridge, special/flags, enables và slot/order đã quy định; pipeline chưa triển khai.

Projection L1→ports→packer365.836 cặp,bốn format,0 mismatch; kiểm mọi32 metadata và RNE/TRUNC, UBSan cùng đạt. Kết quả chỉ kiểm hợp đồng/mapping, không thay RTL/oracle/STA. L1 frozen source hash giữ nguyên. Bằng chứng results/week10_contract/summary.json và l1/test/test_week10_adder_contract.cpp; W10-01✅, tuần10 processing. Tiếp W10-02: khóa vector/oracle/control/flags matrix trước RTL.

<a id="legacy-8-4"></a>

### 8.4. Bàn giao tuần10 — 12/10/2026

W10-02 oracle raw-bit/full-grid/serial-pack độc lập đã kiểm L1 và L0 ở đúng format; W10-03/04 comb align/arithmetic/normalize; W10-05 ba tầng elastic; W10-06 strict lint8/8,ModelSim143.976 comb/143.376 completed+600 abort,0 mismatch và fullES2/ES3 tổng20.000.004 completed; W10-07 matrix/corpus input/metric/width requirements đã chốt. Canonical results/week10_adder/summary.json. Không đổi hash L1 đã frozen, không chạy TableI.

W10✅ ở phạm vi adder đơn vị, không phải Gate3 hoặc final AC02/AC04: raw line80,00–80,95%,branch92,31–96,15%,toggle75,18–84,74%; giữ mọi unhit point, không waiver. P16 fullRTL2^32/P32>=1e8 và final coverage còn thực hiện; không giảm ngưỡng. F reference/Ideal full-sum, signed residual và RTL window còn tuần12. Input corpus paired100k/seed20261012 đã replay byte-exact; chưa có accuracy hoặc PPA NF/F.

Tái chạy từ Posit_MAC: build gen_week10_adder.cpp -I l1/include -L l0 -lsoftposit với LD_LIBRARY_PATH l0, sinh pilot20000; chạy scripts/verify_week10_adder_comb.ps1 và pipeline.ps1 với RunName *_final; WSL bash scripts/verify_week10_adder_verilator.sh; cuối cùng python scripts/audit_week10_adder.py. Build snapshot/relative paths giải quyết thư mục có khoảng trắng, TMPDIR đặt trong results/week10_adder. Audit cần fixture/source snapshot/rawcoverage được giữ tới cuối kiểm; missing không là PASS.

Theo yêu cầu sinh viên, checklist tạm W10 đã gỡ khỏi tiến độ sau nghiệm thu; giữ hàng tổng kết và nhật ký/report. Bước tiếp tuần11: ghép multiplier đã kiểm→round_unpacked→adder→packer, context C_eff/reset/acc_mode, rồi Gate3. Tại checkpoint12/10 chưa tạo checklist tuần11 hoặc triển khai MAC mới; kế hoạch hiện hành bổ sung ở mục8.5 ngày13/10.

Lệnh W10 chuẩn đã kiểm từ nguồn (WSL không nạp profile, các runner PowerShell từ Posit_MAC):

```sh
bash scripts/prepare_week10_adder.sh
bash scripts/verify_week10_adder_verilator.sh
python3 scripts/audit_week10_adder.py
```

Giữa prepare và audit chạy Windows `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify_week10_adder_comb.ps1 -RunName modelsim_comb_final`, tương tự pipeline.ps1 với modelsim_pipeline_final, và verify_week10_invalid_params.ps1. Chạy cả ModelSim và Verilator trước audit. prepare chốt pilot143.976 rows/UBSan/corpus paired100k; native runner pilot50k/format trước full10M/format32. Invalid params3/3 chặn F/SF_W/F_OUT sai. Khi dùng Git, scripts W10 .sh giữ LF bằng .gitattributes. Giữ report cũ trước chạy lại nếu cần bảo toàn checkpoint lịch sử.

<a id="legacy-8-6"></a>

### 8.6. Bàn giao tuần11 sớm — 13/10/2026

W11-01 xác nhận238.906 legacy differences trên900.000 random; adapter R(P_hat) đạt1.244.064 kiểm,0 mismatch. W11-02..04 hiện thực top posit_mac_nf và wrapper một giao dịch theo SPEC§11.10, RNE/FLOOR; C_eff/context/reset/acc_mode/acc_clr và output-commit đã khóa. Giữ nguyên frozen L1/Gate2; NF mới so mô hình prepack-preserving, không gọi approximate tương đương PositMac legacy. Guideline áp cho mã mới: top chỉ instances, một module/file, named ports, no latch, always_ff/enables/CK2Q và reset bridge/2FF.

W11-05 ModelSim4-state28.512 completed/288 reset-aborted,0 mismatch; strict lint4/4 và native pilot80.000 completed,0 mismatch. W11-06 main32/3 10.000.000 completed/75.801 abort,0 mismatch; direct NF model và oracle độc lập,72 config/control bins,256 regime–dấu,min34944/bin. L_valid=max(1,t)+10,handshake+1; stall làm handshake dài hơn, không làm thay đổi first-valid ở top một giao dịch. Raw ghép pilot+main (toggle chỉ từ pilot): line96.92%,branch94.26%,toggle88.71%; final AC02/AC04 vẫn mở. Không suy từ >=10M aggregate ra >=10M/n/profile cuối.

W11-07 audit/hash/manifest NF đạt; canonical results/week11/summary.json, baseline_nf_manifest.json, source/fixture/binary hashes và logs. W11-08 full-sum F software pilot100k/0 mismatch với Python integer độc lập,24.996 exact cancellation; signed grid bảo toàn phần dư. Chưa F RTL/window/flags/acc_mode acceptance, không đo paired accuracy/PPA. Checklist tuần11 được gỡ khỏi tiến độ sau nghiệm thu phạm vi này; tuần12 tiếp oracle F và PPA sơ bộ NF theo lịch26/10–01/11, có thể bắt đầu sớm theo yêu cầu sinh viên.

Tái lập từ Posit_MAC (WSL không profile,TMPDIR trong results/week11):

```sh
mkdir -p results/week11/tmp
export TMPDIR="$PWD/results/week11/tmp"
export LD_LIBRARY_PATH="$PWD/l0"
g++ -O3 -std=c++17 -I l1/include l1/test/test_week11_prepack.cpp -o results/week11/test_prepack
./results/week11/test_prepack > results/week11/prepack.log
g++ -O3 -std=c++17 -I l1/include l1/test/gen_week11_mac.cpp -o results/week11/gen_mac
./results/week11/gen_mac > results/week11/generator.log
sha256sum results/week11/fixtures/*.txt > results/week11/fixtures.sha256
bash scripts/verify_week11_mac.sh
g++ -O3 -std=c++17 -I l1/include l1/test/test_week11_fused.cpp -o results/week11/test_fused
./results/week11/test_fused > results/week11/fused_generator.log
python3 scripts/check_week11_fused.py
```

Windows chạy `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify_week11_modelsim.ps1`. Build thêm gen_week11_mac/test_week11_fused với -fsanitize=undefined -fno-sanitize-recover=undefined và chạy tới generator_ubsan.log/fused_ubsan.log trước `python3 scripts/audit_week11_mac.py`. Audit từ chối RUNNING/missing/source/fixture hash đổi; snapshot và fixtures cần giữ tới audit. Không sửa mã/runner trong lúc chạy. Các pilot thiếu coverage trước đó bị loại, không dùng làm nghiệm thu.


Đối chiếu kiến trúc paper/NF hiện hành được gom tại SPEC v1.12§5.10-G; đây là cập nhật tài liệu ngày13/10, không đổi RTL/seed/hợp đồng số học hoặc kết quả Gate3.

<a id="legacy-8-7"></a>

### 8.7. Rà soát SPEC và coverage Gate3 còn mở — 14/10/2026 (lịch sử trước bổ sung)

Phần thiếu tại lúc rà soát đã đóng bằng bằng chứng mới ở §8.9; giữ counters/checkpoint cũ bên dưới.

SPEC v1.13 đồng nhất profile/normalize,params,special/feedback/latency và trạng thái fused/PPA/công cụ; không sửa RTL/L1 hoặc counters cũ. W11-01..05 và F full-sum pilot giữ PASS; W11-06 đạt numeric/protocol nhưng strict coverage chưa đóng. W11-07 manifest là freeze mốc nguồn/test13/10,không signoff mọi yêu cầu SPEC. Bảng✅ mục8.5 và bàn giao8.6 là phạm vi checkpoint lúc13/10; trạng thái hiện hành bổ sung ở đây.

W11-COV (processing): bổ sung corpus đạtnear>=30% tại ngõ vào adder với C_eff thực tế; tách acc_mode/standalone,specials và reset-abort; giữ min4k/cross256 và per-run/polarity>=10k,thu packer bins riêng. Counters W11 hiện cho cậnnear<=4,20303% trên10M,không đủ30%. Pilot oracle/ModelSim trước lượt chính; log bộ đếm trực tiếpΔsf0..4,histogram/seed/hash và0 mismatch trước đóng strict Gate3. Không hạ ngưỡng hoặc đổi corpus để đẹp số. Có thể chuẩn bị L1 F độc lập; trước RTL F vẫn phải khóa oracle/window/residual theo tuần12.

Giữ nguyên AC01/AC02/AC04 final và timeline hạn05/12. Tối ưu pipeline NF/F tuần12–13 dựa critical path đo được,regression tuần14 rồi post-route tuần15; không tuyên bố Fmax từ số tầng. Trạng thái mốc sơ bộ và final luôn ghi riêng. Chi tiết findings và proofgap tại results/spec_review_20261014/summary.json, SPEC§11.11.

<a id="legacy-8-9"></a>

### 8.9. Hoàn tất tuần11 và bàn giao — 14/10/2026

W11-COV **✅**,W11-06/07 đã đóng phạm vi Gate3 NF bằng checkpoint mới `results/nf_coverage_20261014/completion.json`; SPECv1.14§11.12 là hiện trạng mới. Kết quả: main10.000.000/75.379 reset-abort,0 mismatch,near52,55548%;256 cross min30.114 và61 run/polarity min199.470;72 control,24 adder,6 popcount,13 iteration×mode reachable và7 nhóm packer. Counters đo thụ động RTL tại handshake, chỉ cộng vào coverage khi giao dịch completed. Corpus mới khóa sau pilot; không sửa RTL/model frozen/report13/10.

ModelSim fixture mới28.512 completed/288 abort và corner82.944 completed/0 abort đều0 mismatch. Corner giữ riêng:8 mã Zero/NaR/±1/±minpos/±maxpos cubed,36 config/mode/OPS,n0..8;16 cặp fraction0/ones/AA/55×4 cặp dấu. Đường exact chạm hết F=5/12/27/26. Corner không cộng vào mẫu số near của main. Format SoftPosit0.4.1 chỉ8/0,16/1,32/2;32/3 dùng oracle dyadic/exact/full-grid độc lập.

Định nghĩa bin P1: up=g&&(LSB||r||s),down-inexact=(g||r||s)&&!up,tie=g&&!r&&!s;tie-up/hold theo LSB. Sat-max/min quan sát special_sel3/4 kèm cờ tương ứng;carry-regime khi increment làm đổi run/polarity mã magnitude. Counts riêng ở product/final packer;final NF sat-min unreachable do tổng hai Posit là bội minpos. Approx iteration>8 unreachable;exact>8 không áp dụngp8. Raw unhit giữ nguyên;mainline96,9231%,branch94,2623%,togglepilot88,7136%;chưa finalAC04 toàn ma trận.

**Tái chạy trên WSL**,từ project path có khoảng trắng (bash --noprofile --norc):

```bash
cd '/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC'
bash scripts/prepare_nf_coverage.sh
bash scripts/verify_nf_coverage.sh pilot
python3 scripts/audit_nf_coverage.py pilot
bash scripts/verify_nf_coverage.sh acceptance
bash scripts/prepare_nf_corners.sh
```

**ModelSim từ Windows CMD**,working directory Posit_MAC:

```cmd
cd /d "C:\HCMUT\HK261\Do an 2\Posit_MAC"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_nf_coverage_modelsim.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_nf_corners_modelsim.ps1
```

Sau khi hai luồng ModelSim COMPLETE,quay WSL:

```bash
python3 scripts/test_nf_coverage_audit.py
python3 scripts/audit_nf_completion.py
```

Build runtime L0 trước nếu libsoftposit.so đã dọn;phụ thuộc xem [Optimization §8.6](Optimization.md#legacy-8-6). Rebuild/generate snapshots/fixtures trước audit sau cleanup. Thư mục mới giữ report/seed/lệnh/hash/raw coverage gọn;binaries,obj/work/wave/fixtures tái sinh không đưa Git. Compiler GCC15.2.0,Verilator5.032,ModelSim10.1d;seed20261014+100·NB+ES,mt19937_64;generator UBSan byte-identical. Audit phản chứng4/4 từ chối RUNNING,source/fixture đổi và near<30%.

**Việc chưa hoàn thành,không chặn đóng tuần11:** final≥10^7/n/bản NF/F và exhaustive/AC02;AC04 toàn matrix;F_W contract/oracle/model/RTL/flags/state;paired accuracy;STA/CDC/RDC và PPA toàn MAC. Không phát hiện mismatch RTL trong phiên này. Không đo/tuyên bố Fmax và không chạy TableI. W12-01 được giải quyết khi đóng tuần11,W12-02..07 vẫn không; tiếp theo ưu tiên W12-02→03→04,nhánh timing W12-05→06 khi đủ công cụ.

<a id="legacy-8-14"></a>

### 8.14. Nghiệm thu kỹ thuật tuần12 và bàn giao F — 15/10/2026

**W12-01..07 ✅; G-F-L1 ✅;đã sao lưu GitHub.** Canonical results/week12/summary.json;model/corpus/contract tại freeze.json. NF/Gate3 và legacy L1/RTL giữ nguyên byte/hash;không thêm RTL F hoặc ghép ứng viên align/normalize vào baseline. Thực hiện sớm theo yêu cầu,lịch gốc26/10–01/11 và hạn trước05/12 giữ nguyên.

**W12-02:** Oracle full-grid integer,raw decoder/serial encoder độc lập,không gọi L1 parser/packer. Exhaustive16.777.216 triples p8 so SoftPosit0.4.1 FMA;smoke100k mỗi format p16/1,p32/2 và100k32/3 cùng prepack so limb full-sum cũ,tất cả0 mismatch. Windows/UBSan smoke100k cũng đạt. ES3 không dùng SoftPosit ES2 làm oracle. GCC15.2.0 Linux,GCC13-win32 cross compiler;source/library/binary hashes,lệnh và seed20261014 lưu cùng report.

**W12-03:** W12-F-1 khóa trước pilot,seed20261014 và quy tắc chọn smallest admitted zero-difference window. F cộng C_eff sau prepack,FLOOR/RNE,FW12,OPS0/1,n0..8;exact request bị từ chối. Giữ P_hat đầu vào và chưa chọn fraction mới từ khảo sát8.11. Anchor theo tích đã normalize e_P=scale+msb(M)-q;không dùng sf_A+sf_B khi tích có carry.

W32 gồm1 sign,2 integer magnitude,29 fraction;residual sign/nonzero và flags riêng,không nằm trong32. Cận Q≥max(F,FW+1)+3 bảo đảm toán hạng lớn fit chính xác,chỉ toán hạng nhỏ có một residualδ. Nếu ngược dấu retained sum,đổi |Z|−δ thành (|Z|−1)+(1−δ),không jam dương tùy tiện. Tail chỉ xuất hiện khi Δsf≥4,nên không có zero-retained/tail≠0 hoặc normalize trái sâu lúc có tail. F_W32 round đúng P_hat+C_eff trong miền đã kiểm;P_hat vẫn xấp xỉ A×B. Sat_max/min chỉ từ tổng cuối;zero giữ metadata inexact;approx_cut chỉ iteration bỏ. acc_mode có state F riêng,commit một lần mỗi transaction,C_raw bị bỏ khi dùng accumulator. Đây là model giao dịch,không phải kiểm CK2Q/stall RTL F.

**W12-04:** Bốn pilot100k ởW32/48/64/96 đều0 khác F_ref;chọnW32 theo luật đã khóa. Lượt đầu1m Linux/Windows/UBSan0 mismatch. Bổ sung suite để đạt đầy đủ phân tầng SPEC§6.3: **2.208.768 ca/nền tảng Linux,Windows,UBSan;0 mismatch** bits/flags,retained magnitude/tail và own accumulator. Corpus35.340.288byte,Windows/Linux sinh lại byte-exact,SHA256 `87f17cbf5d5c0a88098738b9afc0d50835880f60e19017401da3ee2a2943ab3d`.

| Chỉ tiêu main bổ sung | Kết quả |
| --- | --- |
| Near trước/sau cut | 1.160.774/2.208.768=52,55300693% |
| Regime-group/dấu | 256/256,min4128 mỗi cross |
| Run/polarity hữu hạn | 61/61,min26161 operands |
| n0..8 | min245418 mỗi n |
| Δsf0..4 | đủ từng bin,standalone/acc_mode,trước và sau cut |
| Popcount/iteration | đủ6 nhóm popcount và9 mức iteration0..8 |
| Borrow/tail | 454079/994659 |
| Reset/acc_clr/acc transactions | 540/2724/264193 |

Thêm6402 corner/lượt trong suite đầu,tie even/odd,range,metadata/special và6 invalid requests không đổi state;Python signed integers kiểm138 trace đầy đủ/0 mismatch. Audit có4 negative guards,từ chối mismatch/thiếu cross/near/n. Corpus phân tầng có coverage_contract.json khóa trước sinh/chạy;không dò seed hoặc hạ ngưỡng. Report cũ1m giữ riêng,không trộn mẫu số.

Tách sai số: F_W/F_ref0 khác;F_ref/Ideal tại cùng F_Ceff khác1.377.327 bit-result. Đây là số ca khác mã,không phải phần trăm sai số tương đối. NF/F/Ideal dùng state riêng ởacc_mode. Corpus cố ý đánh near-cancellation bằng F reference,không dùng để khẳng định accuracy ứng dụng;mean/P99/ULP/NMSE và paired RTL tuần14 còn mở. Report coverage/accuracy.json.

**W12-05:** Nguyên bản toàn NF32/3,FW12,EXACT_EN=OPS_EN=1,Quartus13.0sp1/TimeQuest,EP4CE30F23C6. Parser trong source copy riêng chỉ thêm generate/endgenerate vì Quartus13 không nhận implicit generate;audit bỏ delimiter rồi so tokens với production. Không sửa canonical RTL. Clock10ns,I/O budget max0,5/min0,1ns cho input/output,derive_clock_uncertainty;không false-path/multicycle. Budget I/O là giả định khảo sát,chưa board signoff.

| Chỉ tiêu toàn NF post-route | Kết quả |
| --- | --- |
| LUT4/FF | 3926/823,mọi seed |
| Arithmetic-mode LE | 442,đã nằm trong tài nguyên LE;không phải CARRY8 |
| DSP/memory | 0/0 |
| Fmax seed1/2/3 | 47,10 /45,07 /44,65MHz;median45,07MHz |
| Setup100MHz | **Chưa đạt**,WNS slow85−11,233/−12,186/−12,395ns |
| Hold/recovery/removal | Đạt mọi corner/run đã báo |
| Unconstrained setup/hold | 0 port/clock/path theo report |

Raw full timing có10paths/run và9 nhóm stage/run,logic/routing/fanout,resource hierarchy;collector collect_week12_nf.py FAIL nếu thiếu report/parse lỗi. Số đo từ mô hình chip sau place-route,không đo board. Quartus13 bỏ qua ASYNC_REG;reset release fanout833,còn review CDC/RDC/MTBF. Không so trực tiếp MHz/LUT4 này với paper trên UltraScale+.

**W12-06 — đề xuất,chưa áp dụng:**

| Ưu tiên | Bằng chứng seed1 | Hướng thử và tác động |
| --- | --- | --- |
| 1 | acc→norm→pack/parse→product_frac_q:data21,477ns,WNS−11,233ns,63levels;logic9,669/routing11,609ns | Đổi variable destination index trong mul_prepack_norm_comb thành fixed slices/carry MUX trước,không thêm FF/latency. Sau đó đo để chọn bank norm/packed value nếu cần tách pipeline |
| 2 | A1align:data17,203ns,WNS−7,642ns | Đo align candidate8.12 trong toàn NF;nếu chưa đủ,tách SF/swap khỏi shift/jam. Candidate comb không đổiH;thêm tầng đổiH/II và tăng bank/context |
| 3 | A2arith WNS+5,031ns;A3norm−2,216ns | Cân nhắc LOD sau cộng ởA2,chốt count/valid choA3:khoảng5+1FF,có thể giữH_ADD3;phải đo vì A2 dài hơn |
| 4 | SAC feedback:data12,314ns,WNS−2,383ns | Shift theo clz rồi dịch1 cố định,tínhsa/scale song song;khảo sát remaining-scale budget để rút state_error. Không tùy tiện pipeline hồi tiếp vì thay term interval/II |
| 5 | OPS WNS−0,382ns,control+3,899ns | Chuyển swap sauM0 chỉ khi tổng thể có lợi;SAC đang chậm nên không mặc định chuyển MUX sẽ tăngFmax |

Với FIN=2F+1,fixed slices có thể chuẩn bị exact-no-carry `{acc[2F-1:0],1'b0}`,exact-carry `acc[2F:0]`;approx-no-carry `{acc[FW+1:2],zeros(FIN-FW)}`,approx-carry `{acc[FW+2:2],zeros(FIN-FW-1)}`. Carry từ acc[2F+1] hoặcacc[FW+3],sf_norm=sf+carry. Đây là phương án chưa viết RTL;cần generate guard EXACT_EN/width và kiểm raw/special/carry. u_norm109LUT4,u_round889LUT4 ở hierarchy seed1 là mức đang dùng,không phải số chắc chắn tiết kiệm.

Bank packed trung gian cần ít nhất32data+5flags+valid=38FF payload/control,+1cycle;chưa tính điều khiển/reset. Có thể cần bank normalized nếu norm+pack vẫn dài. Dùng nguyên pack2+parser2 có latency khác cách chia comb một bank;phải đo và sửa SPEC/lịch. Shared core optimizations áp cho cảNF/F hoặc báo riêng,không gán toàn lợi ích tối ưu RTL cho fusion.

**W12-07:** bàn giaoF1(anchor/seeds/delta),F2(align/tail),F3(signed add/sub),F4(abs/borrow),F5(normalize/SF/adapter),packerP1/P2;ngân sách H=q+12,valid=q+11,II≥q+13 với q=max(1,t). ChưaF RTL hoặc timingF,có thể điều chỉnh sau pilot/STA tuần13. Top một giao dịch giữcontext,reset bridge/leaf2FF,valid/ready vàflags đi cùng data;accumulator commit một lần,giữ output tới retire. Ports/stages tại handoff.json. ExactF chưa hỗ trợ;futureNF comparator approximate-only cần test/freeze vì số đo NF hiệnEXACT_EN1 khácF EXACT_EN0.

Tái lập từ Posit_MAC,WSL bash --noprofile --norc,runtime đã cài,temporary/bin trong results/week12:

Trên checkout mới,build L0 bằng `make -C l0 all` trước oracle để tái tạo libsoftposit.so/softposit.dll từ source đã có;không đưa thư viện binary vào Git. Có thể khác byte binary khi compiler/build khác,phải ghi hash/version mới và kiểm lại,không sửa hash checkpoint lịch sử.

```bash
bash scripts/verify_week12_oracle.sh
bash scripts/verify_week12_window.sh
bash scripts/verify_week12_coverage.sh
bash scripts/verify_week12_accuracy.sh
./results/week12/accuracy/test_accuracy results/week12/coverage/fixtures/main.bin 2208768 results/week12/coverage/accuracy.json
bash scripts/verify_week12_trace.sh
```

```cmd
powershell -NoProfile -File scripts\verify_week12_windows.ps1
powershell -NoProfile -File scripts\verify_week12_coverage_windows.ps1
powershell -NoProfile -File scripts\run_week12_nf_ppa.ps1
powershell -NoProfile -File scripts\survey_week12_nf_stages.ps1
python scripts\collect_week12_nf.py
python scripts\audit_week12.py
```

Audit đầy đủ cần sinh lạibin/corpus/source copy trên checkout mới. Backup chỉsource,manifest/hash,JSON/CSV/trace/log và raw reports nén lossless;không exe,ELF,SO,SOF,wave,obj/db/fixtures/cache. Không tạo Markdown mới. Receipt results/week12/backup.json chỉ được tạo sau push thành công;khi có receipt,summary mới đóngW12-07.

<a id="legacy-8-15-5"></a>

### 8.15.5. Timing và so sánh công bằng với NF

Ưu tiên có bản F đúng chức năng rồi đo critical path thực tế; tránh đưa nhiều refactor chưa nghiệm thu vào lần tích hợp đầu. Theo dõi F1 scale/anchor, F2 shift/tail, F3 add/sub, F4 ABS/borrow, F5 LOD/shift và P1/P2. Khi có đường chậm, đề xuất riêng thay đổi logic hoặc bank cùng tác động FF/latency/II trước khi sửa; không hứa F sẽ có Fmax cao hơn NF.

Đo tiếp theo chỉ bằng Vivado trên A35T xc7a35tcpg236-1 theo quyết định17/10, cùng clock/I/O constraints và chiến lược implementation cho NF/F. Không chạy thêm Altera. Số200MHz của primitive không phải số toàn MAC. OOC chưa có pin/board constraints thì không gọi là board signoff; báo F_STA estimate tách khỏi tần số thực sự đạt setup/hold.

Chuẩn bị comparator NF approximate-only EXACT_EN0 đã kiểm/freeze, cùng NB32/ES3, FW12, OPS_EN1 và n; NF EXACT_EN1 cũ lưu historical. Dùng cùng ngân sách tối ưu, báo shared changes và thay đổi riêng mỗi kiến trúc. Báo ít nhất Fmax/clock đạt, LUT/FF/DSP/BRAM, latency, II, throughput=f_clk/II và sai số paired; pipeline có thể khác số tầng. Acc_mode dùng state riêng đúng từng mô hình, không ép NF/F có cùng C_eff sau khi chuỗi đã phân kỳ.

**Phần còn mở sau hiện thực §8.15.6:** exact F và format phụ ngoài32/3 không thuộc bản đầu; final coverage/per-n, CDC/RDC, comparator NF và paired accuracy/PPA/Gate4 còn theo các mốc sau. RTL F, mapping prepack/giao diện/lịch cạnh và STA sơ bộ đã có bằng chứng; không dùng các trạng thái trước hiện thực để phủ nhận mốc mới.

<a id="legacy-8-15-6"></a>

### 8.15.6. Kết quả triển khai RTL F — 15/10/2026

Đã thực hiện theo yêu cầu tiếp theo của sinh viên. W13-01..05 đạt phạm vi bản đầu32/3 FW12 W32/Q29. W13-06 đạt pilot/main10M/0 mismatch, còn mở coverage chi tiết/final; W13-07 đạt STA ban đầu và audit, chưa CDC/RDC/paired multi-run/Gate4. Checklist W13-01..05 đã gỡ sau khi hoàn thành; bảng dưới giữ kết quả tại thời điểm bàn giao. Công việc còn mở chuyển sang tiến độ mục3.1–3.2.

| Hạng mục | Bằng chứng / kết quả | Trạng thái |
| --- | --- | --- |
| Hợp đồng và RTL F1–F5/top | 8 module mới, raw prepack từacc[15:2], signed residual và borrow; reuse core approximate12bit, final packerRNE | ✅ |
| Kiểm chức năng tích hợp | Pilot100k,main10M/0 mismatch;59.356.752 stage observations,near48,46403%,bits/flags/state/latency và reset/stall/order đạt | ✅ |
| Pipeline và event simulator | Unit100.005/0 mismatch,5 inflight; XSim8192/0 mismatch,24 reset-aborts,CK2Q1ns | ✅ |
| Lint và STA sơ bộ | Strict lint0 warning/error; A35T100MHz R2R đạt,1520LUT/815FF,0latch; một run OOC | ✅ |
| Coverage/nghiệm thu cuối | Raw points module mới line20/21,branch39/40,toggle2168/2392; chưa đóng AC04 toàn thiết kế/final per-n; counters run/polarity/popcount và delta theo mode đã bổ sung | processing |
| So sánh NF/F và signoff | Còn matched NF approximate-only trên Xilinx,>=3run/accuracy,CDC/RDC và board/Gate4 | không |

Mapping xây dựng hiện hành ở PLAN mục4; checklist đã hoàn thành không còn là lịch thực thi. Không dùng trạng thái 'không' lúc lập để nói RTL F chưa tồn tại. Source/evidence và commands ở results/week13/summary.json; SPECv1.18§11.15 ghi interface,stage,latency và giới hạn. L_valid=q+11,H=q+12,II_min=q+13 với q=max(1,t); zero/NaR dùng init-only t0. FMA vẫn trên P_hat xấp xỉ,không exactA×B+C/quire.

Tối ưu trong bản đầu: fixed carry slices; seed/delta song song; mask/lost song song shifter; F3 add/sub một carry chain; F4 gộp ABS vàborrow; không giữ field sau tầng hết dùng. Không promote các candidate NF/primitive cũ. Critical path đo được accumulator→parserC (8,221ns),F1/F5 lần lượt7,660/7,528ns; chưa thêm bank ngoài lịch đã chốt. F_STA120,16MHz là ước lượng,mục tiêu thực đo ở100MHz,một run không thay paired PPA tuần15.

Tái chạy từ Posit_MAC: `bash scripts/run_week13_acceptance.sh`, `bash scripts/verify_week13_pipe.sh`; Windows `powershell -NoProfile -File scripts/run_week13_xilinx.ps1 -Mode simulate` rồi `-Mode ppa`; cuối `python scripts/audit_week13_fused.py`. WSL dùng bash --noprofile --norc; runtime/tmp/snapshot/log đặt trong results/week13. Không gọi lại scripts/run_week12_nf_ppa.ps1 (Altera) cho phép đo mới. Main >=10M tích hợp không thay final >=10M/n/bản tuần14.

### Bảo trì cấu trúc RTL/kết quả — hồ sơ15/10

RTL được phân nhóm tại `rtl/README.md`, manifest build chính `rtl/production.f`; tên module/I/O/parameter và nội dung RTL giữ nguyên.
Runner WSL/ModelSim/Vivado dùng đường dẫn mới và resolver cho danh sách theo tên. Đây là bảo trì dự án, không đổi hợp đồng NF/F hay trạng thái Gate.
Kết quả đo cũ giữ nguyên; bản đồ di chuyển/hash và kiểm smoke riêng tại `results/layout_cleanup_20261015`.
Build/cache đã dọn; xem `scripts/README.md` để tái build hoặc dọn định kỳ. Không chạy lại regression 10M hoặc PPA chỉ vì đổi thư mục.


<a id="legacy-8-26"></a>

### 8.26. Chuẩn hóa constraint A35T-C1 — 17/10/2026

Theo yêu cầu sinh viên, tách clock nội bộ và budget tích hợp thật. Không sửa RTL, mô hình số học, pipeline hoặc báo cáo cũ. Các run min=max input2,5ns và output0/0,5ns giữ nguyên giá trị lịch sử; đó là ngân sách OOC giả định, không phải timing board. Không tăng min để chữa hold hoặc giảm uncertainty để tuyên bố closure.

| Thành phần mới | Nội dung |
| --- | --- |
| [a35t_clock.xdc](../Posit_MAC/syn/constraints/a35t_clock.xdc) | Clock10ns, setup uncertainty0,100ns và hold uncertainty0,100ns; không I/O delay/false-path/multicycle |
| [a35t_io_template.xdc](../Posit_MAC/syn/constraints/a35t_io_template.xdc) | Mẫu system-synchronous theo nhóm data/control; min/max/reference để trống bằng token, không được chạy như thông số board |
| [run_a35t.tcl](../Posit_MAC/syn/run_a35t.tcl) và [runner](../Posit_MAC/scripts/run_a35t_sta.ps1) | Chỉ A35T; nạp XDC trước synthesis; validate/synth/implement; snapshot/hash/lệnh và output riêng, không ghi đè |
| [Hướng dẫn constraint](../Posit_MAC/syn/README.md) | Phạm vi R2R/I/O, lệnh chạy và điều kiện tái lập |

**Profile ip_ooc:** chỉ đánh giá R2R D/CE; I/O không có budget và được công khai trong scope/check_timing. Wrapper hiện chỉ BUFG, không input/output FF banks, nên không xác nhận đường port→parser P1 hoặc out_ready→control. Không gọi là timing toàn bộ giao tiếp/board; lỗi unconstrained nội bộ vẫn phải xử lý. Không thêm exception để che đường ngoài phạm vi. NF/F giữ số tầng và lịch giao dịch.

**Profile integration:** chỉ chạy với bản sao I/O XDC đã điền nguồn timing và min/max độc lập từ mạch nguồn/đích, data/clock connection. Mẫu cùng-clock không thay virtual/generated-clock hoặc phase contract nếu giao tiếp khác. Kiểm đủ/trùng/hướng port, min/max và clock. Chưa có budget thực, pinout/IOSTANDARD hoặc board signoff; không dùng số giả lập của testcase làm mặc định.

**Kiểm nạp constraint:** Vivado2026.1 build6511674, Action validate chỉ RTL elaboration (-rtl), không full synthesis/place/route hoặc simulation. Clock-only NF/F nạp clock và hai uncertainty, không I/O delays. Test tích hợp với số giả lập có nhãn TEST_ONLY_NOT_BOARD kiểm cú pháp/phủ port và output min âm; mẫu chưa điền phải bị từ chối. Không có số đo Fmax/LUT/hold mới từ các kiểm tra này. NF trong runner mặc định vẫn EXACT_EN1, F EXACT_EN0; chưa thay nghiệm thu comparator NF EXACT_EN0 hoặc paired PPA.

Trong phát triển runner, lượt đầu vướng đường dẫn khoảng trắng ở read_xdc; đã sửa bằng Tcl list. Mẫu XDC đầu dùng dict/foreach khiến Vivado chỉ phát critical warning và bỏ constraint; các lượt này không được nghiệm thu. Bản cuối dùng XDC thuần, preflight ở driver và từ chối critical warning/error; log thử lỗi giữ riêng trong bằng chứng, không cộng vào kiểm tra thành công.

Bằng chứng đã lưu tại results/a35t_c1_constraints_20261017: summary.json và evidence.zip/manifest SHA. Bốn kiểm tra đạt phạm vi: NF clock-only và F clock-only (mỗi lượt0 warning/critical warning/error), tích hợp số giả lập (0 warning/critical warning/error, đủ8 lệnh min/max gồm output min âm), và từ chối mẫu trống như dự kiến. Đối chiếu94 file RTL/L1 giữ nguyên byte. Không có full synthesis/place/route hoặc mô phỏng; elaboration không tạo Fmax mới. Các lượt thử trước sửa được nén riêng intermediate_not_acceptance, không dùng nhãn VALIDATED cũ làm bằng chứng. Nguồn, lệnh và XDC hiệu lực của từng kiểm tra đều có trong archive. Main timing cũ không được tự nâng nhãn sau chuẩn hóa: thời điểm nạp XDC trước synthesis và bỏ I/O budget có thể đổi cả netlist/P&R. Khi đo tiếp phải tạo matched baseline/candidate C1 và kiểm tại clock mục tiêu, chỉ báo closure trong phạm vi đã timing. Các producer lịch sử vẫn dùng điều kiện checkpoint cũ, không sửa source/hash của chúng.


<a id="legacy-8-27"></a>

### 8.27. Giữ budget100MHz theo yêu cầu sinh viên — A35T-C2, 17/10/2026

Sau đề xuất C1, sinh viên yêu cầu giữ nguyên bộ constraint ở mọi benchmark10ns: input min/max2,500ns, output min0/max0,500ns, uncertainty setup/hold0,100ns. Đã cập nhật file I/O benchmark riêng và runner mặc định benchmark_100mhz; clock/I/O nạp trước synthesis. Không đổi RTL, pipeline, snapshot hay kết quả cũ. C1 và các kiểm nạp ở mục8.26 là lịch sử, không dùng làm nghiệm thu C2.

Ngoại lệ đã được mô tả là quét clock cao hơn (ví dụ8ns/125MHz): có thể chỉ đọc Internal R2R; nếu giảm input_delay theo tỷ lệ chu kỳ thì phải có profile sweep riêng, cùng điều kiện cho baseline/candidate và báo thay đổi giả định giao tiếp. Ưu tiên R2R riêng, không tự thay budget. I/O setup âm dưới budget2,5ns là chưa đạt budget đó, không tự là âm giả; không suy toàn giao tiếp hoặc board đạt từ kết quả R2R. Đường Parser B P1 ở báo cáo8.24 có data delay8,628ns/clock10ns và chịu cả clock latency/skew; không dùng con số xấp xỉ6,1ns hoặc T-input_delay đơn lẻ để kết luận timing.

Sinh viên nói có hai ngoại lệ nhưng mới cung cấp một; ngoại lệ thứ hai để chưa xác định, không tự gán cho profile tích hợp. Runner C2 hiện cố định100MHz, chưa triển khai/chạy sweep hoặc tự chia tỷ lệ input_delay. Mẫu tích hợp được giữ tham khảo, không tự kích hoạt như ngoại lệ thứ hai.

Lần chỉnh này chỉ cập nhật chính sách/file/runner và kiểm cú pháp tĩnh, chưa chạy lại synthesis/STA/P&R hoặc có Fmax mới. Các số đo cũ không đổi; nạp constraint trước synthesis vẫn cần matched mới trước kết luận cải thiện.

### 8.28. Triển khai mục8.25 — 17–18/10/2026

Đang kiểm các candidate riêng; chưa promote production. Nguồn tham chiếu là snapshot OPT-02b, constraint A35T-C2 nạp trước synthesis. Không dùng số timing cũ thay phép đo matched mới. Bằng chứng SAC tại `results/opt05_20261017`; script prepare/verify/run_opt05 lưu phiên bản, seed, hash và lệnh chạy. Candidate canonical ở `rtl/candidates/multiplier/opt05`.

**OPT-09 — hợp đồng bank khảo sát:** product P2 giữ duy nhất mã magnitude đã RNE/clamp rộng NB bit (bit cao chỉ dùng mã NaR), sign1 bit, flags5 và valid1. Zero/NaR nhận diện từ mã magnitude, không thêm hai FF special hoặc lưu signed code song song. Parser nội bộ bỏ bước bù hai, trả sign canonical: Zero0, NaR1, finite theo sign đã chốt. Bank payload dự kiến tăng1 FF so với P2 cũ; báo số thực sau synthesis. P1/P2 ready/CE, hai FF reset release, reset dữ liệu và giữ khi stall theo packer hiện hành; sign chốt cùng magnitude/flags. NF vẫn tính R(P_hat)+C_eff, giữ nguyên top API, precision, flags, số tầng, latency/II và frozen L1. Packer công bố dùng chung không sửa. Module nội bộ mới `posit_product_pack` và `posit_magnitude_parse`; candidate wrapper giữ nguyên I/O/parameter. Nguồn tại `results/opt09_20261018`, so độc lập với cùng mốc OPT-02b; chưa ghép SAC khi chưa chọn bằng STA.

<!-- OPT825_REPORT_START -->

#### 8.28.1. Kết quả kiểm chứng và phép đo đã hoàn tất

SAC: 1,399,460 input cases trên54 cấu hình W_X1..27, S_W tối thiểu và+2; bốn candidate khớp RTL gốc và oracle serial scan độc lập (5,597,840 so sánh candidate/oracle),0 mismatch. ModelSim riêng130.156 ca tại W1/5/12/26/27 cũng đạt. Cả bốn candidate sạch54 strict leaf lint và bốn strict NF lint; tổng320.000 pilot NF/0 mismatch. Bản range-check generate giữ hành vi overflow và bỏ CMPCONST ở W=2^S−1; mã cũ trước sửa giữ riêng, freeze.json là mốc ban đầu, manifest thực chạy khóa bản đã sửa.

Lượt ModelSim54-instance song song đã dừng vì runtime cao, không tính PASS. Lượt native đầu vướng GNU Make không nhận khoảng trắng trong CURDIR; bản v2 dùng make CURDIR=. Không che warning RTL candidate: chỉ build testbench/RTL gốc dùng Wno-fatal, strict lint candidate vẫn không warning/error. ModelSim10.1d dùng typedef unsigned cùng width thay parameter-sized cast trong bản LOD private; F thêm adapter tương tự cho assertion iterations_done. Không sửa source production hoặc tắt assertion. Lỗi compile F đầu giữ riêng, không tính nghiệm thu.

OPT-09: round-trip parse(pack(u)) so trên800,000 chu kỳ/371,020 completed,4 format×RNE/TRUNC,reset/stall/specials/carry/range,0 mismatch;4 pilot tổng80.000 completed/0 mismatch. OPT-10A:435 strict lint tuples NB4..32,ES0..NB−4 ở F_IN tối thiểu; 1,298,720 ca so mọi field P1 với bản gốc,8 tuple gồm ES0,NB không lũy thừa2,FIN tối thiểu/63 và SF sweep/one-hot;4 pilot80.000 completed/0 mismatch. Prefix OR tính từ toàn payload và giữ fill khi offset quá lớn; không chỉ từ fraction.

Tổ hợp khảo sát: SAC A+B+C-tree + OPT-09 + OPT-10A trên mốc OPT-02b. NF4 pilot80.000, main32/3 **10.000.000 completed/85.316 reset-aborted,0 mismatch**. Toàn bộ JSON counters/cycle/coverage khớp checkpoint OPT-02b;72 control bins và256 regime/sign cross không mất. F profile32/3 FW12 W32 approximate-only: pilot100.000 và **main10.000.000 completed/0 mismatch**,59.356.752 stage observations; toàn JSON main khớp checkpoint tuần13. Frozen L1 và production giữ nguyên. ES3 dùng oracle integer/dyadic/full-grid riêng; SoftPosit chỉ cho đúng format hỗ trợ.

ModelSim NF:82.944 corner+28.512 protocol completed/288 reset-aborted,0 mismatch; F8192 completed/24 abort,0 mismatch,CK2Q1ns. Không đổi reset release,stall,order,C/config context,commit,first/last/drain. NF vẫn14 tầng,L_valid=q+12,H=q+13,II=q+14; F13 tầng,q+11/q+12/q+13. Không dùng regression này thay final per-n/AC04/CDC/RDC/Gate4.

#### 8.28.2. Tách tác động từng candidate — Default C2

| Candidate SAC | LUT | FF | CARRY4 | WNS ns | WHS ns | SAC state/token setup ns |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| baseline | 2516 | 930 | 94 | +0.229 | +0.056 | +0.547/+0.601 |
| a | 2570 | 930 | 94 | +0.215 | +0.055 | +0.679/+0.427 |
| ab | 2538 | 930 | 94 | +0.277 | +0.058 | +0.873/+0.799 |
| abc_sub | 2572 | 930 | 104 | +0.380 | +0.056 | +1.014/+1.024 |
| abc_tree | 2531 | 930 | 94 | +0.177 | +0.054 | +1.011/+1.944 |

C-sub tăng carry/LUT; cây zero/one-hot không thêm carry, cải thiện SAC token rõ hơn nhưng không tự cải thiện WNS toàn MAC khi đường găng chuyển sang P1/A1. Không chọn candidate chỉ dựa tên thuật toán hoặc một bank.

| Candidate độc lập trên OPT-02b | LUT/FF/CARRY4 | WNS/WHS ns | Bank chính trước → sau, setup ns |
| --- | --- | --- | --- |
| OPT-09 | 2414/931/86 | +0.317/+0.046 | +0.477 → +1.999 |
| OPT-10A | 2514/930/94 | +0.409/+0.051 | +0.229 → +1.030 |

OPT-09 thay bank biểu diễn, không thêm bank: P2 tăng từ38 lên39 FF. Magnitude đã round/clamp lưu một lần; không thêm signed code hoặc adder thứ hai. Packer public và parser public giữ nguyên.

#### 8.28.3. Matched toàn NF — A35T-C2, ba chiến lược

**Reference ở đây là candidate OPT-02b, không phải production OPT-03. Chưa promote OPT-02b hoặc tổ hợp vào production.** Cùng part xc7a35tcpg236-1,10ns,input min/max2,500ns,output min0/max0,500ns,uncertainty setup/hold0,100ns; XDC nạp trước synthesis. Không thêm exception hoặc đổi hold budget.

| Chiến lược | Reference LUT/FF/CARRY4 | Reference WNS/WHS ns | Tổ hợp LUT/FF/CARRY4 | Tổ hợp WNS/WHS ns | R2R WNS reference → tổ hợp ns | F_STA reference → tổ hợp MHz |
| --- | --- | --- | --- | --- | --- | --- |
| Default | 2516/930/94 | +0.229/+0.056 | 2547/931/86 | +0.730/+0.028 | +0.229 → +0.987 | 102.34 → 110.95 |
| Explore | 2517/930/94 | +0.440/+0.056 | 2548/931/86 | +0.669/+0.046 | +0.440 → +0.860 | 104.60 → 109.41 |
| RuntimeOptimized | 2546/930/94 | -0.099/+0.046 | 2587/931/86 | +0.845/+0.039 | -0.099 → +0.988 | 99.02 → 110.96 |

Reference F_STA min/median/max=99.02/102.34/104.60MHz; WNS min/median/max=-0.099/+0.229/+0.440ns.

Tổ hợp F_STA min/median/max=109.41/110.95/110.96MHz; WNS min/median/max=+0.669/+0.730/+0.845ns.

Explore dùng place/route Explore; RuntimeOptimized dùng place RuntimeOptimized và route Default. Đây là ba chiến lược, không gọi là ba seed độc lập. Chỉ đo toàn NF trong đợt này; chưa có matched PPA F hoặc kết luận lợi ích fusion. DSP/BRAM/latch/unrouted/unclassified đều0 ở các run đã audit. TNS/THS và recovery/removal giữ trong timing.rpt; số chi tiết,24 bank D/CE và worst paths ở summary.json/stages.csv, không trộn async reset vào bank data.

Default: WNS toàn bộ budget+0,730ns tại parser valid→in_ready; Internal R2R+0,987ns tại A1. Tổ hợp đạt setup/hold100MHz cả ba chiến lược. Đánh đổi Default so reference:+31LUT,+1FF,−8CARRY4; không kết luận giảm LUT toàn MAC từ việc OPT-09 riêng tiết kiệm102LUT. Median F_STA tăng khoảng8,41%,chưa đạt mục tiêu115–125MHz.

| Bank Default | Reference setup/hold ns | Tổ hợp setup/hold ns |
| --- | --- | --- |
| accumulator_feedback | +0.803/+0.076 | +2.609/+0.079 |
| accumulator_l3 | +3.454/+0.098 | +4.013/+0.028 |
| adder_a1 | +0.562/+0.118 | +0.987/+0.127 |
| adder_a2 | +4.507/+0.056 | +5.007/+0.067 |
| adder_a3 | +1.530/+0.120 | +2.318/+0.125 |
| c_context | +4.531/+0.067 | +5.202/+0.046 |
| final_packer_p1 | +1.667/+0.079 | +3.184/+0.131 |
| final_packer_p2 | +3.707/+0.071 | +4.202/+0.077 |
| ops_m0_core_context | +1.695/+0.128 | +2.088/+0.108 |
| parser_a_p1 | +1.651/+0.178 | +1.612/+0.216 |
| parser_a_p2 | +3.852/+0.066 | +4.151/+0.144 |
| parser_b_p1 | +1.663/+0.361 | +1.904/+0.158 |
| parser_b_p2 | +4.149/+0.100 | +3.792/+0.123 |
| parser_c_p1 | +1.297/+0.232 | +1.895/+0.156 |
| parser_c_p2 | +4.253/+0.095 | +4.609/+0.072 |
| product_packer_p1 | +0.229/+0.181 | +1.697/+0.187 |
| product_packer_p2 | +3.312/+0.119 | +3.967/+0.071 |
| product_parse_bank | +0.477/+0.103 | +3.208/+0.077 |
| reset_sync | +7.875/+0.060 | +7.997/+0.060 |
| sac_state | +0.547/+0.175 | +1.344/+0.149 |
| sac_token_l1 | +0.601/+0.143 | +2.814/+0.189 |
| sbm_shift_l2 | +3.857/+0.121 | +3.213/+0.166 |
| transaction_control | +2.849/+0.162 | +3.642/+0.163 |
| whole_data | +0.229/+0.056 | +0.987/+0.028 |

F_STA=1000/(10−WNS_R2R),chỉ là ước lượng từ STA tại100MHz; chưa P&R ở clock cao hơn hoặc đo board. OOC không có HD.PARTPIN_LOCS nên timing I/O chỉ theo budget giả định, chưa board/interface signoff. Không suy slack hold thực bằng cách cộng lại uncertainty.

#### 8.28.4. Quyết định và phần còn mở

Giữ tổ hợp như candidate đã kiểm; chưa đổi production.f hoặc SPEC hiện thực production. Việc promote riêng OPT-02b cần matched với production; phép đo ở đây dùng nó làm mốc khảo sát đúng8.25.1. OPT-10B chưa mở vì P1/P2 đã có margin; OPT-11 vẫn là tùy chọn nếu cần mục tiêu cao hơn và phải khóa bundle/FF trước sửa. A1 đang là nút thắt kế tiếp; không lấy CE slack A2 làm ngân sách số học. Mục tiêu115–125MHz chưa được nghiệm thu; không tự tăng tầng/II để đạt con số. Gói kết quả không đóng Gate4 hoặc final ma trận NF/F.

Tái chạy từ Posit_MAC,WSL bash --noprofile --norc: prepare_opt05.py → verify_opt05.sh từng a/ab/abc_sub/abc_tree; verify_opt05_leaf_native.sh tự tạo TB54 cấu hình và verify_opt05_leaf_event.ps1 kiểm ModelSim đại diện (không cần chạy lại matrix ModelSim ban đầu). prepare_opt09.py → verify_opt09_product.sh và verify_opt09.sh; prepare_opt10a.py → verify_opt10a_leaf.sh và verify_opt10a.sh; prepare_optcombo.py → verify_optcombo.sh → verify_optcombo_acceptance.sh; ModelSim dùng verify_optcombo_modelsim.ps1 và verify_optcombo_fused_modelsim.ps1. L0 libsoftposit.so tái build từ source trước native NF trên checkout mới.

PPA Windows: run_opt05_ppa.ps1 -Variant baseline/abc_tree -Strategy Default/Explore/RuntimeOptimized; thêm -StudyRoot results/opt09_20261018 -Variant magnitude hoặc opt10a_20261018/-Variant sticky cho phép đo riêng; tổ hợp dùng -StudyRoot results/optcombo_20261018 -Variant combined với ba strategy. Mọi runner từ chối output cũ; để tái chạy cần study root mới và sửa có chủ đích, không xóa checkpoint đã nghiệm thu. collect_opt825.py audit nguồn/hash/constraint/counters; retain_opt825.py nén và kiểm CRC/SHA trước dọn build caches. Seed NF20264217,F20261015,SAC20261017,product/sticky20261018; Verilator5.032,GCC15.2.0,ModelSim10.1d,Vivado2026.1 build6511674. Nguồn/lệnh/hash và báo cáo raw nằm trong evidence.zip của từng study.


Đã nén lossless và kiểm CRC/SHA từng entry trước dọn build caches,giải phóng642,878,086byte (~613.1MiB). Giữ source/lệnh/hash/report/fixture và routed DCP local; không đưa binary,wave,work hoặc cache vào Git. Archive manifest mô tả cả lượt lỗi/interrupted riêng,không cộng vào nghiệm thu.

<!-- OPT825_REPORT_END -->

<a id="legacy-8-29"></a>

### 8.29. Phương án OPT-02c cho Adder A1 align và sàng lọc hạng mục tối ưu sau 8.28 — 18/10/2026

Sau khi gói kết hợp (`OPT-02b + OPT-05 abc_tree + OPT-09 + OPT-10A`) tại mục 8.28 đạt bit-exact (10M NF + 10M F, 0 mismatch) và vượt ngưỡng 100 MHz trên cả 3 chiến lược (`F_STA = 109.41 / 110.95 / 110.96 MHz`, `Overall WNS = +0.669 / +0.730 / +0.845 ns`), các nút thắt cũ đã được giải tỏa (`product_packer_p1 = +1.697 ns`, `product_parse_bank = +3.208 ns`, `sac_state = +1.344 ns`, `sac_token_l1 = +2.814 ns`, `final_packer_p1 = +3.184 ns`). Đường tới hạn nội bộ số 1 hiện tại trên cả 3 chiến lược nằm tại **`adder_a1` (`+0.860 ns` ở Explore, `+0.987 ns` ở Default, `+0.988 ns` ở RuntimeOptimized)**.

#### 8.29.1. Giải phẫu đường găng `adder_a1` trong `optcombo_20261018`

Theo báo cáo `results/optcombo_20261018/ppa/combined/Default/adder_a1_setup.rpt`, đường găng `norm_sf_q_reg[1]/C -> a1_q_reg[y][0]/D` (data delay `8.870 ns`, 12 logic levels, slack `+0.987 ns`) và đường thứ hai vào `a1_q_reg[alignment_tail]/D` (slack `+1.153 ns`) bị kéo dài bởi 3 nguyên nhân nối tiếp trong `rtl/candidates/adder/opt02b/posit_add_align.sv`:

1. **Hai chuỗi `CARRY4` nối tiếp nhau trước khi tạo `shift_amount`:**
   - Chuỗi `CARRY4` thứ nhất (`3.260 -> 5.073 ns`, 3 `CARRY4`): tính hiệu 12-bit `diff_ba = b_sf - a_sf` và `diff_ab = a_sf - b_sf` (dòng 84–85).
   - Nhánh so sánh tiếp theo (`5.073 -> 6.840 ns`) gồm 2 `CARRY4`, LUT và net, tổng `1.767 ns`: riêng delay hai CARRY4 là `0.672 ns`, còn LUT/net là `1.095 ns`. Đây là arrival tại các điểm của đường đã route; chưa chứng minh bỏ comparator sẽ tiết kiệm nguyên `1.767 ns`.
2. **Nút thắt `shift_amount` bị chặn bởi `clamp_ab`/`clamp_ba` (fanout = 60):**
   - Tại dòng 90–92:
     ```systemverilog
     shift_ab = clamp_ab ? shift_t'(F + 2) : shift_t'(diff_ab[SHIFT_W-1:0]);
     shift_ba = clamp_ba ? shift_t'(F + 2) : shift_t'(diff_ba[SHIFT_W-1:0]);
     shift_amount = sf_a_lt_b ? shift_ba : shift_ab;
     ```
   - `shift_ab`/`shift_ba` phụ thuộc clamp; đường report đi qua `shift_amount[3]` có fanout60, arrival `7.735 ns` tại LUT5 và `8.520 ns` sau net. Không gán fanout60 cho mọi bit nếu chưa đo. Với32/3,F26,ADD_W31,`u_align_shift` chỉ dịch30 bit phía trên; bit0 tạo riêng bằng jam.
3. **Tra bảng 32-to-1 `jam`/`tail` nối tiếp sau `shift_amount` (`8.520 -> 11.674 ns`, 4 tầng LUT):**
   - Sau khi `shift_amount` được chọn bởi `sf_a_lt_b = diff_ab[SF_W]`, tín hiệu còn phải đi qua cây MUX 32-to-1 (`jam_a[shift_amount]` / `jam_b[shift_amount]`) rồi mới trộn với `clamped` và `sf_equal` để nạp vào `a1_q.y[0]` và `a1_q.alignment_tail`.

#### 8.29.2. Đặc tả kỹ thuật phương án `OPT-02c` (Tối ưu tổ hợp nội bộ `posit_add_align.sv`, 0 FF, giữ nguyên biên tầng)

Quan sát hợp đồng đầu ra của tầng A1 tại `posit_add_align.sv` (dòng 160–167):
```systemverilog
end else if (clamped) begin
  y = word_t'(1);
  alignment_tail = 1'b1;
```
Khi `clamped == 1'b1`, toàn bộ kết quả của bộ dịch `shifted_main`, `jam_bit` và `lost_tail` **đều bị ghi đè hoàn toàn** bởi hằng số (`y = 1`, `alignment_tail = 1`). Do đó, việc kẹp `shift_ab`/`shift_ba` về `F + 2` bằng `clamp_ab`/`clamp_ba` trước khi đưa vào `shift_amount` là dư thừa về mặt logic nhưng lại cộng thêm `~2.0 ns` vào đường găng có fanout = 60.

Phương án **`OPT-02c`** thử 3 cải tiến thuần tổ hợp trong `posit_add_align.sv` (không thêm FF RTL, không thay đổi `align_context_t` hay giao diện `posit_add_arith.sv` / `posit_add_comb.sv`). Mức giảm delay/LUT và slack>+2ns là mục tiêu, phải kiểm netlist/STA trước kết luận:

1. **Tách `clamp_ab`/`clamp_ba` khỏi `shift_amount`:**
   - Gán trực tiếp 5 bit thấp của hiệu scale factor:
     ```systemverilog
     shift_ab = shift_t'(diff_ab[SHIFT_W-1:0]);
     shift_ba = shift_t'(diff_ba[SHIFT_W-1:0]);
     shift_amount = sf_a_lt_b ? shift_ba : shift_ab;
     ```
   - Các bit thấp không cần chờ clamp hoặc carry vào bit cao. Đây là cơ sở rút ngắn đường điều khiển; số CARRY4 và thời điểm sẵn sàng thực tế phụ thuộc mapping/routing, chưa hứa giảm1,8–2ns.
2. **Tra bảng `jam` và `tail` song song theo `shift_ab` / `shift_ba` trước khi chọn theo `sf_a_lt_b`:**
   - Thay vì đợi bit dấu `sf_a_lt_b = diff_ab[SF_W]` ở đỉnh chuỗi `CARRY4` thứ 3 chọn xong `shift_amount` rồi mới tra bảng 32-to-1, thực hiện tra bảng song song trên từng nhánh ngay khi 5 bit thấp `shift_ab`/`shift_ba` vừa có:
     - Nhánh `a >= b` (`b` là toán hạng nhỏ hơn, dịch bởi `shift_ab`): tính trước `jam_ab = jam_b[shift_ab]` và `tail_ab = tail_b[shift_ab]`.
     - Nhánh `a < b` (`a` là toán hạng nhỏ hơn, dịch bởi `shift_ba`): tính trước `jam_ba = jam_a[shift_ba]` và `tail_ba = tail_a[shift_ba]`.
   - Đưa lookup lên trước phép chọn theo dấu. Phép chọn và override cuối có thể cần nhiều mức LUT do special/equal/clamp; xác nhận độ sâu sau synthesis, không bảo đảm chỉ một LUT.
3. **Thay bộ so sánh `CARRY4` 12-bit của `clamp_ab`/`clamp_ba` bằng kiểm tra bit trực tiếp:**
   - Với hiệu không âm (`!diff[SF_W]`), điều kiện `diff > (F + 2)` tương đương với việc có bất kỳ bit cao nào trong `diff[SF_W-1:SHIFT_W]` khác 0, hoặc phần thấp `diff[SHIFT_W-1:0] > shift_t'(F + 2)`:
     ```systemverilog
     clamp_ab = !diff_ab[SF_W] && ((|diff_ab[SF_W-1:SHIFT_W]) || (diff_ab[SHIFT_W-1:0] > shift_t'(F + 2)));
     clamp_ba = !diff_ba[SF_W] && ((|diff_ba[SF_W-1:SHIFT_W]) || (diff_ba[SHIFT_W-1:0] > shift_t'(F + 2)));
     ```
   - Với32/3, so phần thấp5-bit với28 có thể map vào LUT5; OR phần cao, qualification theo dấu và override vẫn là logic riêng. Không mặc định Vivado sẽ bỏ mọi CARRY4 hoặc đạt mức giảm delay dự đoán. Các format khác dùng F+2 và SHIFT_W tương ứng.

**So sánh `OPT-02c` với `OPT-11` (A1 $\rightarrow$ A2 retiming):**
- `OPT-02c` giữ nguyên 100% biên thanh ghi A1/A2, 0 FF tăng thêm, dùng chung trực tiếp cho cả `posit_add_comb` và `posit_add`, cắt bỏ cả chuỗi `CARRY4` thứ hai lẫn độ trễ nối tiếp của MUX 32-to-1 sau `sf_a_lt_b`.
- `OPT-11` cần chốt bundle `align_context_t` và đếm FF theo tín hiệu thực sự chuyển tầng; chưa có cơ sở khóa con số7 FF. Logic jam phải hoàn tất trước cộng/trừ ở A2. Ưu tiên thử OPT-02c trước, không tự mở retiming trong đợt khóa RTL này.

#### 8.29.3. Quyết định sàng lọc các hạng mục tối ưu sau 8.28

Để tập trung nguồn lực cho kiểm chứng cuối Tuần 14–15 (`W14-00..08` và Gate 4), các hạng mục tối ưu trong mục 8.25 được phân loại lại dựa trên bằng chứng STA thực tế tại mục 8.28.3:

1. **Các hạng mục ĐÁNG LÀM / TIẾP TỤC (`open` / `processing`):**
   - **`OPT-00` / `OPT-02b` + `OPT-07/08` (Đối chiếu baseline `OPT-03` và Promote gói kết hợp lên `production`):** Chốt bảng so sánh 3 chiến lược giữa `production OPT-03` và gói kết hợp trên cùng `A35T-C2`, đồng bộ module dùng chung NF/F và promote lên `rtl/production.f`.
   - **`OPT-02c` (Tối ưu tổ hợp `posit_add_align.sv`):** Thử nghiệm nhanh ứng viên `OPT-02c` trên nền gói 8.28 để nâng slack `adder_a1` (`+0.860..+0.988 ns`) lên vùng `> +2.0 ns` mà không tốn FF.
2. **Các hạng mục ĐÓNG / KHÔNG CẦN TỐI ƯU THÊM (`closed — no longer needed`):**
   - **`OPT-10B` (Dời sticky/flags từ P1 sang P2):** Đóng vì `OPT-10A` đã nâng `product_packer_p1` lên `+1.697 ns` và `final_packer_p1` lên `+3.184 ns`.
   - **Nhánh `C-prefix precompute` tại `pair_retire` (thuộc `OPT-11`):** Đóng vì toàn bộ top critical paths tại `adder_a1` xuất phát từ `norm_sf_q` (scale factor của tích) qua bộ trừ `diff_ab/ba`, không xuất phát từ `c_frac_q`; thêm ~30 FF tại `pair_retire` không rút ngắn đường găng.
   - **`OPT-04` (A2/A3 LOD) và `OPT-06` (`posit_add_norm` zero/shared):** Đóng vì `adder_a2` (`+5.007 ns`) và `adder_a3` (`+2.318 ns`) đã có biên độ timing rộng, cải tiến trước đó chỉ lệch 4–7 LUT.
   - **Nhánh `direct round_unpacked` (bỏ qua pack $\rightarrow$ parse) và `remaining-scale budget` trong SAC:** Đóng vì `OPT-09` (`product_parse_bank = +3.208 ns`) và `OPT-05 abc_tree` (`sac_state = +1.344 ns`, `sac_token_l1 = +2.814 ns`) đã giải quyết triệt để các bank này với rủi ro thấp hơn nhiều.

<a id="legacy-8-30"></a>

### 8.30. OPT-02c, promote và khóa RTL trước W14 — 18/10/2026

**Đã chọn và promote** `OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A` vào production.
Release `POSIT_MAC_RTL_20261018_OPT02C`, trạng thái `LOCKED_FOR_W14`, gồm38 module SV và header.
Manifest: `rtl/production_freeze.json`; bằng chứng: `results/opt02c_20261018/summary.json`,
`promotion.json`, `lock_receipt.json`, `evidence.zip` và `archive_manifest.json`.
Nguồn trước promote, reference8.28 và candidate được giữ riêng trong snapshot/archive;
không sửa hash hoặc ghi đè hồ sơ cũ.

#### 8.30.1. Thay đổi RTL và giữ nguyên hợp đồng

- A1: hai hiệu scale, hai clamp và hai nhánh tra jam/tail chạy song song; clamp không còn nối tiếp vào điều khiển shifter.
  So sánh clamp bằng bit-check được qualify bằng dấu hiệu số. Equal-scale, specials, flags và jam giữ bit-exact; không thêm FF.
- SAC/controller: fixed shift1, gộp scale+count+1 và zero/one-hot cân bằng (`abc_tree`); controller dùng exhausted đã kiểm.
- Packer P1: prefix OR/lookup sticky; product P2 lưu magnitude đã RNE và sign riêng,
  rồi `posit_magnitude_parse` giải mã magnitude trực tiếp.
- Bảy file SV thay đổi/thêm được ghi hash trước/sau trong promotion.json.
  Hai helper mới là `rtl/mac_nf/posit_product_pack.sv` và `posit_magnitude_parse.sv`.
  `production.f` từ36 lên38 module; public ports/parameters, số học, reset/stall/commit và latency không đổi.
  NF14 tầng: Lvalid=q+12, H=q+13, II=q+14. F13 tầng: q+11/q+12/q+13, q=max(1,t thực tế).
  Magnitude P2 thêm1 FF metadata so với production cũ, không thêm bank hoặc tầng.
  L1/oracle và hai XDC A35T-C2 giữ nguyên byte.

#### 8.30.2. Chức năng và công cụ

ModelSim10.1d, Verilator5.032, GCC15.2.0; Vivado2026.1 build6511674.
NF seed20264217; F smoke seed20261015. Lệnh, source/tool/hash và counters giữ trong study.
ES3 dùng oracle độc lập; không gọi SoftPosit32 ES2 là oracle ES3.

| Kiểm chứng | Kết quả |
| --- | --- |
| A1 leaf baseline/candidate/oracle,11 profile, gồm F2..27 và SF_W35 | 0 mismatch;406 profile strict lint đạt |
| NF pilot8/0,16/1,32/2,32/3 | 80.000 completed,0 mismatch |
| NF acceptance32/3 | 10.000.000 completed,85.316 reset-abort,0 mismatch; toàn bộ JSON counters bằng8.28 |
| NF ModelSim candidate4 format | 111.456 completed,288 reset-abort,0 mismatch |
| F acceptance10M từ8.28 | Kế thừa có kiểm hash:23 SV+header dùng thực tế đều byte-identical; không chạy lại10M |
| F smoke mới | 100.000 completed,0 mismatch; counters bằng8.28 |
| Build từ production sau promote | 37 profile strict lint0 warning/error; NF smoke20.000/0 mismatch |
| ModelSim từ production sau promote | NF32/3:27.864 completed/72 abort; F:8.192 completed/24 abort;0 mismatch, kiểm CK2Q1ns |

Kiểm có reset khi busy/stall, metadata, thứ tự giao dịch, latency, flags và feedback.
Đây là qualification trước W14, **chưa phải** final per-n, coverage AC04 hay Gate4.

#### 8.30.3. PPA matched A35T-C2

Part xc7a35tcpg236-1,10ns; uncertainty setup/hold0,100ns;
input min=max2,500ns, output min0/max0,500ns. XDC đọc trước synthesis.
Production là OPT-03 cũ; reference là tổ hợp OPT-02b của8.28, được dùng lại chỉ sau đối chiếu
hash nguồn, thứ tự file, wrapper, XDC và flow. Candidate chỉ đổi A1 so với reference.
Không nới ràng buộc, không thêm timing exception.

| Gói | Strategy | WNS toàn thiết kế (ns) | R2R WNS (ns) | WHS (ns) | LUT | FF | CARRY4 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| production | Default | -2.840 | -2.840 | +0.014 | 2463 | 930 | 99 |
| production | Explore | -2.454 | -2.454 | +0.014 | 2463 | 930 | 99 |
| production | RuntimeOptimized | -3.202 | -3.202 | +0.014 | 2463 | 930 | 99 |
| reference | Default | +0.730 | +0.987 | +0.028 | 2547 | 931 | 86 |
| reference | Explore | +0.669 | +0.860 | +0.046 | 2548 | 931 | 86 |
| reference | RuntimeOptimized | +0.845 | +0.988 | +0.039 | 2587 | 931 | 86 |
| candidate | Default | +0.894 | +1.259 | +0.053 | 2546 | 931 | 82 |
| candidate | Explore | +0.894 | +1.259 | +0.053 | 2546 | 931 | 82 |
| candidate | RuntimeOptimized | +1.011 | +1.453 | +0.053 | 2587 | 931 | 82 |

Median F_STA nội bộ: production77,88MHz → reference110,95MHz → candidate114,40MHz.
Đây là 1000/(10−R2R_WNS), **ước lượng từ STA tại100MHz**, chưa phải quét clock hoặc đo kit.
Candidate đạt setup/hold100MHz trên cả3 strategy; Default/Explore cho cùng kết quả vật lý,
không tính là hai seed ngẫu nhiên độc lập. Default so production: +83 LUT,+1 FF,−17 CARRY4;
so reference:−1 LUT,0 FF,−4 CARRY4. Không tuyên bố giảm tổng LUT so production.

A1 Default: data delay8,870→7,718ns,12→7 logic levels, setup slack+0,987→+2,144ns.
Đường găng R2R mới thuộc accumulator→parserC P1 (+1,259ns).
Không mở thêm tối ưu parser/control sau khi khóa.

F release Default32/3 FW12 W32 EXACT_EN0: WNS+0,982ns,WHS+0,045ns,
R2R+2,002ns,1486 LUT/815 FF/69 CARRY4; đạt mốc100MHz.
NF trong bảng dùng EXACT_EN1, vì vậy **không dùng bảng này kết luận paired NF/F PPA**.
Comparator NF EXACT_EN0 và matched PPA tuần15 còn phải làm.

**Bảng setup/hold của release đã khóa — strategy Default.** Nguồn là candidate đã promote thành
`POSIT_MAC_RTL_20261018_OPT02C`, post-route Vivado2026.1, A35T-C2/10ns với budget/uncertainty nêu trên.
NF32/3 FW12 EXACT_EN1; F32/3 FW12 W32 EXACT_EN0. Hai cấu hình này chưa tạo phép so paired PPA.
Các dòng NF theo nhóm endpoint D/CE, gồm cả đường enable; setup và hold là hai phép tìm worst path độc lập,
không nhất thiết cùng một đường. 24 nhóm trong stages.csv gồm23 nhóm bank và một dòng whole_data tổng hợp,
**không phải24 tầng pipeline** (NF vẫn14 tầng, F13 tầng).

| Bản / phạm vi Default | Setup slack nhỏ nhất (ns) | Hold slack nhỏ nhất (ns) |
| --- | ---: | ---: |
| **NF — toàn thiết kế (WNS/WHS)** | **+0.894** | **+0.053** |
| NF — Parser A — P1 | +2.029 | +0.156 |
| NF — Parser A — P2 | +4.797 | +0.135 |
| NF — Parser B — P1 | +1.910 | +0.160 |
| NF — Parser B — P2 | +4.476 | +0.090 |
| NF — Parser C — P1 | +1.259 | +0.164 |
| NF — Parser C — P2 | +4.093 | +0.106 |
| NF — OPS — M0/core context | +2.800 | +0.154 |
| NF — SAC — state/feedback | +1.850 | +0.073 |
| NF — SAC — token L1 | +2.844 | +0.053 |
| NF — SBM dịch — L2 | +3.989 | +0.117 |
| NF — SBM tích lũy — L3 | +4.165 | +0.125 |
| NF — Packer tích — P1 (kể cả normalize phía trước) | +1.769 | +0.199 |
| NF — Packer tích — P2 magnitude/sign | +4.531 | +0.102 |
| NF — Magnitude parse → product bank | +3.418 | +0.125 |
| NF — Adder — A1 align/jam | +2.144 | +0.082 |
| NF — Adder — A2 arithmetic | +5.282 | +0.063 |
| NF — Adder — A3 normalize | +2.369 | +0.112 |
| NF — Packer kết quả — P1 | +3.152 | +0.086 |
| NF — Packer kết quả — P2 | +3.401 | +0.073 |
| NF — Context C/specials | +4.206 | +0.054 |
| NF — Điều khiển giao dịch | +3.589 | +0.163 |
| NF — Accumulator feedback/commit | +2.535 | +0.240 |
| NF — Reset bridge/synchronizer (D/CE) | +7.992 | +0.060 |
| NF — Toàn bộ bank D/CE (có thể gồm đường input) | +1.259 | +0.053 |
| NF — Internal R2R riêng | +1.259 | +0.053 |
| **F — toàn thiết kế (WNS/WHS)** | **+0.982** | **+0.045** |
| F — Internal R2R riêng | +2.002 | +0.045 |

Tất cả slack trong bảng đều dương tại mốc100MHz đã đo. Setup R2R nhỏ nhất của NF nằm ở
accumulator→Parser C P1 (+1,259ns); hold R2R nhỏ nhất ở SAC token L1 (+0,053ns).
WNS toàn thiết kế có thể nhỏ hơn R2R do có thêm đường I/O với budget giả định.
F chưa có bảng phân nhóm F1–F5 trong checkpoint này; hai dòng F chỉ báo tổng thể/R2R, không suy số từng tầng.
Các nhóm reset D/CE ở đây không thay kiểm recovery/removal hoặc review RDC.

Nguồn đối chiếu: [NF stages.csv](../Posit_MAC/results/opt02c_20261018/ppa/candidate/Default/stages.csv),
`ppa/candidate/Default/*_setup.rpt`, `*_hold.rpt`, `timing.rpt`, `r2r_*.rpt` và
`ppa_f/candidate/Default/timing.rpt`, `r2r_*.rpt` trong study `results/opt02c_20261018`.
Các report/CSV có trong evidence.zip đã kiểm SHA theo archive_manifest.json; không chạy lại STA trong lần bổ sung bảng này.

#### 8.30.4. Reset/CDC, giới hạn và lỗi runner đã xử lý

NF/F có1 clock,0 latch,0 unrouted;931/815 FF,20/18 ASYNC_REG.
report_cdc: All paths are Safely Timed. Giữ bridge và2FF reset release;
sign P2 mới dùng cùng reset/CE. Không thêm clock/reset domain.
Đây chưa phải formal RDC hoặc board signoff; review interface/RDC W14-01 vẫn phải hoàn tất.
Methodology XDCH-2 do budget input min=max và DRC CFGBVS-1 do benchmark OOC không cấu hình
điện áp board được giữ nguyên, ghi rõ giới hạn. Không bỏ warning để làm đẹp kết quả.

Production cũ không đạt setup: Route35-39 trong các lượt baseline được ghi là timing fail,
không phải candidate pass. Collector chỉ chấp nhận warning này khi đi cùng slack âm tương ứng.
Các lỗi launcher không được tính làm bằng chứng PASS: CR cuối lệnh tail sau NF10M
(JSON mô phỏng đã hoàn tất; sửa LF, không chạy lại10M), đường dẫn DCP có khoảng trắng ở
release_checks (sửa ởv2), và PowerShell unwrap tuple làm thiếu ES ở active_event
(sửa ở active_event_v2). Giữ log các lượt lỗi để truy vết.

#### 8.30.5. Khóa nguồn và bàn giao W14

```powershell
python scripts/audit_rtl_release.py --self-test
```

Validator kiểm hash38 SV+header, L1/oracle headers, production.f, maps, filelistF và haiXDC;
4/4 mutation giả lập bị từ chối, không sửa nguồn thật.
Không sửa các file đã khóa khi chạy W14; nếu phát hiện lỗi phải mở change review,
kiểm lại phạm vi ảnh hưởng và tạo release mới, không âm thầm rehash.
Script lịch sử kiểm hash cũ cần chạy trên snapshot tương ứng, không đổi hash để nhận PASS.

Mã công việc hiện hành theo tiến độ đã đánh lại18/10: W14-01 review, W14-02/03 counters/harness,
W14-04 pilot, W14-05 matrix freeze, W14-06/07 main F/NF, W14-08..11 closure/audit; W14-12 exact riêng.
Các mã trong hồ sơ lịch sử giữ ý nghĩa tại thời điểm ghi. **Chưa chạy W14 final matrix, chưa đóng Gate4.** Các nhánh đã đóng ở8.29
tiếp tục đóng. Không chạy thêm A100T hoặc thay FW12.

<a id="legacy-8-31"></a>

### 8.31. Phương án tối ưu sâu hướng tới mốc 120+ MHz (Parser C P1, Packer tích P1 và SAC/OPS launch) — 18/10/2026

**Trạng thái:** Đặc tả kỹ thuật ứng viên (`OPT-12`, `OPT-13`, `OPT-14`) dựa trên kết quả giải phẫu STA post-route của bản release `POSIT_MAC_RTL_20261018_OPT02C` (mục 8.30.3). Bản `LOCKED_FOR_W14` hiện tại giữ nguyên hash; nếu triển khai một hoặc cả ba bước dưới đây để vượt mốc **120 MHz** (`T = 8.333 ns`, tương ứng yêu cầu `R2R setup slack >= +1.667 ns` trên thang đo 10 ns trước khi quét trực tiếp tại clock 8.333 ns), phải thực hiện trong study root mới và mở change review theo mục8.30.5. Không sửa/ghi đè lock cũ để cho candidate PASS; chỉ tạo release mới sau khi kiểm chứng và chọn candidate. Review hiện hành tại8.31.6 thay các dự đoán chưa được đo bên dưới.

#### 8.31.1. Các nhóm đường găng R2R khi hướng tới 120+ MHz sau khi khóa `OPT-02c`

Sau khi `OPT-02c` đẩy `adder_a1` lên `+2.144 ns` (`7.718 ns`, 7 logic levels), bảng phân bố slack nội bộ (Internal R2R, strategy Default tại mục 8.30.3) cho thấy **4 nhóm endpoint** nằm dưới ngưỡng `+2.000 ns` (`~125 MHz`):

| Thứ tự găng | Nhóm bank (Default) | Setup slack tại 10 ns | Ước lượng `F_STA` | Đường găng đại diện (`Source -> Destination`) | Data delay / Logic levels |
| :---: | --- | ---: | ---: | --- | --- |
| **#1** | `Parser C — P1` (`parser_c_p1`) | **`+1.259 ns`** | `114.40 MHz` | `accumulator_q_reg[0]/C -> u_c/p1_cnt_q_reg[0]/D` | `8.594 ns` / **14 levels** (`8 CARRY4 + 6 LUT`) |
| **#2** | `Packer tích — P1` (`product_packer_p1`) | **`+1.769 ns`** | `121.49 MHz` | `u_core/u_acc/acc_reg[53]/C -> u_product_pack/g_rne.p1_flags_q_reg[1]/D` | `8.090 ns` / **8 levels** (`2 CARRY4 + 6 LUT`) |
| **#3** | `SAC — state/feedback` (`sac_state`) | **`+1.850 ns`** | `122.70 MHz` | `mode_q_reg/C -> u_core/u_ctrl/fx_q_reg[24]/D` (qua `u_ops`) | `7.937 ns` / **7 levels** (`7 LUT`, route `80.4%`) |
| **#4** | `Parser B — P1` (đường CE) | **`+1.910 ns`** | `123.61 MHz` | `u_a/p2_valid_q_reg/C -> u_b/p1_payload_seed_q_reg[4]/CE` | `7.255 ns` / **7 levels** |

- Để vượt mốc **120 MHz** (`slack >= +1.667 ns` ở 10 ns): **bắt buộc phải giải quyết `Parser C — P1` (`OPT-12`)** vì hai nhóm `#2` (`+1.769 ns`) và `#3` (`+1.850 ns`) đã nằm trên ngưỡng `+1.667 ns`.
- Để tiến lên vùng **125–130+ MHz** (`slack >= +2.000 .. +2.308 ns` trên toàn bộ R2R): kết hợp thêm **`OPT-13` (`Packer tích — P1`)** và **`OPT-14` (`SAC/OPS launch`)**. Mục tiêu là tối ưu tổ hợp, không đổi số tầng hoặc `L_valid / H / II`; chi phí0FF chỉ áp dụng các biến thể không nhân bản thanh ghi. Bất kỳ duplicate FF nào phải báo chi phí riêng và review trước, xem8.31.6.

---

#### 8.31.2. `OPT-12` — Tối ưu `Parser — P1` (`posit_parser.sv` & `posit_parser_comb.sv`)

**1. Nguyên nhân gốc rễ từ `results/opt02c_20261018/ppa/candidate/Default/parser_c_p1_setup.rpt`:**
- **Vì sao chỉ `Parser C — P1` nằm trên đường R2R:** `u_a` và `u_b` nhận trực tiếp port `a`, `b` (thuộc nhóm Input-to-Register; worst path được báo vào `u_a`/`u_b` là đường `CE` có slack `+2.029 ns` và `+1.910 ns`). Ngược lại, `u_c` nhận `c_eff = acc_mode ? (acc_clr ? 0 : accumulator_q) : c` từ thanh ghi nội bộ `accumulator_q_reg[31:0]`. Do đó, toàn bộ chặng `accumulator_q_reg[0] -> chặng c_eff (LUT4 và routing, khoảng1.331 ns) -> P1 combinational` trở thành đường R2R nội bộ (trong cả NF ở `+1.259 ns` lẫn F ở `+2.002 ns`).
- **Ba điểm nghẽn nối tiếp bên trong `posit_parser.sv` (dòng 118–144):**
  1. *MUX chọn dấu nằm sau chuỗi `CARRY4` (`6.391 -> 8.164 ns`, mất `1.773 ns`):* Cách viết `assign magnitude = s_d ? (~p + 1'b1) : p;` khiến Vivado tổng hợp `magnitude0 = ~p + 1` qua 8 `CARRY4` (`4.582 -> 6.391 ns`), rồi đặt thêm một tầng `LUT6` (`p1_first_regime_bit_q_i_1__1`, `0.303 ns`) ở **phía sau** `CARRY4` thứ 8 kèm hai chặng dây (`0.918 ns` trước LUT và `0.552 ns` sau LUT với **fanout = 27**) để tạo `first_regime_bit`.
  2. *Cả 30 bit `terminator_bits[29:0]` phải chờ bit MSB `first_regime_bit = magnitude[30]`:* Biểu thức `terminator_bits = regime_tail ^ {(NB-2){first_regime_bit}}` bắt tất cả các bit thấp (vốn đã ra khỏi `CARRY4` từ `5.364 .. 6.057 ns`) phải đứng đợi carry lan truyền lên tận bit 30 và chờ mạng fanout 27 của `first_regime_bit` tại `8.164 ns` rồi mới bắt đầu vào cây LOD.
  3. *Độ rộng `N = NB - 2 = 30` trượt khỏi nhánh `g_group4` và bị chặn cuối bởi MUX `MAX_COUNT` (`8.164 -> 11.389 ns`, mất `3.225 ns`):* Trong `lod_lzd_core.sv` (dòng 25), nhánh cây 4-nhóm (`g_group4`) chỉ bật cho `N == 31 || N == 32`. Do `posit_parser` gọi `N = 30`, nó rơi về cây nhị phân `g_baseline` và phải nối tiếp thêm MUX bão hòa `cnt_d = terminator_valid ? terminator_count : MAX_COUNT` ở cuối (trong đó `cnt_d[0]` phải chờ `terminator_valid` qua đường dây dài `0.997 ns`).

**2. Ba cải tiến kỹ thuật của `OPT-12` (0 FF, giữ nguyên hợp đồng P1/P2):**
1. **Dùng XOR hai bit kề nhau cho `terminator_bits` để cắt đứt sự phụ thuộc vào `first_regime_bit` (fanout 27 $\rightarrow$ 1):**
   - Thay `assign terminator_bits = regime_tail ^ {(NB-2){first_regime_bit}};` bằng:
     ```systemverilog
     assign terminator_bits = magnitude[NB-3:0] ^ magnitude[NB-2:1];
     ```
   - *Chứng minh tương đương bit-exact:* Giả sử từ bit `NB-2` xuống bit `m+1`, các bit của `magnitude` đều bằng `r`, và bit `m` là bit đầu tiên bằng `~r`. Khi đó với mọi `k > m`, `magnitude[k] == magnitude[k+1] == r` nên `magnitude[k] ^ magnitude[k+1] == 0`; tại `k = m`, `magnitude[m] ^ magnitude[m+1] == (~r) ^ r == 1`. Vì `lod_lzd_core` (`MODE = 0`) chỉ tìm **vị trí bit `1` đầu tiên tính từ MSB** (`k = m`) và bỏ qua mọi bit tại `k < m`, kết quả `terminator_count` và `terminator_valid` của `magnitude[NB-3:0] ^ magnitude[NB-2:1]` **đồng nhất 100%** với `magnitude[NB-3:0] ^ {(NB-2){magnitude[NB-2]}}` trên mọi giá trị nhị phân!
   - *Lợi ích:* Mỗi bit `terminator_bits[k]` sẵn sàng ngay khi `CARRY4` đi qua bit `k+1`, không cần đợi carry lên tới bit 30 và xóa bỏ hoàn toàn mạng fanout 27 của `first_regime_bit` trên đường vào LOD.
2. **Ghép bit sentinel `'1'` vào LSB của bộ dò regime (`{terminator_bits, 1'b1}`) để bỏ MUX `terminator_valid` và kích hoạt `g_group4` (`N = 31`):**
   - Khi không có bit terminator trong `NB - 2` bit (`terminator_bits == '0`), giá trị cần trả về là `MAX_COUNT = NB - 2` (`30` với Posit32).
   - Nếu ghép thêm hằng số `1'b1` vào ngay sau LSB:
     ```systemverilog
     wire [NB-2:0] detector_in = {terminator_bits, 1'b1};
     ```
     thì bit `'1'` nối thêm nằm ở đúng chỉ số **`NB - 2 = MAX_COUNT`** tính từ MSB!
   - Với các cấu hình thỏa `$clog2(NB - 1) == CNT_W` (đúng cho mọi Posit chuẩn `NB = 8, 16, 32`; dùng `generate if ($clog2(NB - 1) == CNT_W)` để giữ tương thích với các `NB` lẻ trong lint):
     - Gọi `lod_lzd_core #(.N(NB - 1), .MODE(0), .S(CNT_W))` với `.in(detector_in)` và nối thẳng `.K(cnt_d)`.
     - Nếu `terminator_bits != '0`, vị trí bit `1` đầu tiên nằm trong `0 .. NB-3` (không đổi). Nếu `terminator_bits == '0`, bit `1` đầu tiên chính là bit sentinel tại chỉ số `NB - 2 = MAX_COUNT`!
     - **Xóa bỏ hoàn toàn logic `terminator_valid` và tầng MUX `terminator_valid ? terminator_count : MAX_COUNT` ở cuối P1**, đồng thời với `NB = 32` thì `N = NB - 1 = 31` **tự động bật nhánh cây 4-nhóm `g_group4`** trong `lod_lzd_core.sv` (và có thể mở rộng thêm `N == 30 || N == 31 || N == 32` trong `lod_lzd_core.sv` cho `posit_magnitude_parse.sv`).
3. **Đảo bit có điều kiện ngay trước dây chuyền nhớ `CARRY4`:**
   - Viết `assign magnitude = (p ^ {NB{s_d}}) + {{(NB-1){1'b0}}, s_d};` để `magnitude` lấy trực tiếp từ ngõ ra `O` của `CARRY4`, tránh phát sinh LUT MUX chọn `s_d` phía sau chuỗi `CARRY4`.

---

#### 8.31.3. `OPT-13` — Tối ưu sâu `Packer tích — P1` (`mul_prepack_norm_comb.sv` & `posit_pack_prepare.sv`)

**1. Nguyên nhân gốc rễ từ `results/opt02c_20261018/ppa/candidate/Default/product_packer_p1_setup.rpt`:**
- **Path 1 (`+1.769 ns`, `acc_reg[53]/C -> p1_flags_q_reg[1]/D`, 8 levels) & Path 2 (`+1.822 ns`, `acc_reg[53]/C -> p1_mag_trunc_q_reg[13]/D`, 8 levels):**
  1. *Nút thắt `carry` (`acc_reg[53]`, fanout = 97) nối tiếp vào bộ cộng `sf_norm = sf + 1` (fanout = 47):* Trong `mul_prepack_norm_comb.sv` (dòng 33–36), bit nhớ `grid[q+1]` (`acc_reg[53]`) vừa phải lái MUX 53-bit của `frac_norm` (làm fanout = 97, mất `1.035 ns` đi dây), vừa đi vào đáy chuỗi `CARRY4` cộng `sf_norm = sf + 1` (`4.417 -> 5.171 ns`), rồi `sf_norm[4]` (fanout = 47, mất thêm `1.216 ns` đi dây) mới tới được `posit_pack_prepare` ở `6.387 ns` để tính `offset` (`7.969 ns`, fanout = 32).
  2. *Ghi đè dư thừa `mag_trunc` và `G/R/S` theo `MAXPOS`/`MINPOS` ngay tại P1:* Trong `posit_pack_prepare.sv` (dòng 119–153), khi `sf >= SF_MAX` hoặc `sf < -SF_MAX`, mạch tổ hợp P1 ép `mag_trunc = {NB-1{1'b1}}` (hoặc `1`) và xóa `guard/round/sticky = 0`. Tuy nhiên, ở tầng P2 (`posit_pack_finish.sv` dòng 76–90), khi `special_sel != NORMAL`, tầng P2 **đã chọn trực tiếp hằng số `0 / NaR / max_encoded / min_encoded` và bỏ qua hoàn toàn `p1_mag_trunc_q`, `p1_guard_bit_q`, `p1_round_bit_q`, `p1_sticky_bit_q`**! Việc ép lại `mag_trunc` ở P1 khiến toàn bộ 31 bit `p1_mag_trunc_q` (Path 2) phải đi qua bộ so sánh `sf >= SF_MAX` và 3 tầng LUT MUX cuối (`6.396 -> 10.836 ns`, mất `4.440 ns`).
  3. *Tính cờ `flags_o[1]` (`inexact`) ở cuối P1:* Trong Path 1 (`+1.769 ns`), sau khi tra bảng `sticky_lookup[offset]` xong ở `8.295 ns`, tín hiệu còn phải đi qua **3 tầng LUT6** (`8.295 -> 10.891 ns`, mất `2.596 ns`) để OR `guard_bit | round_bit | sticky_bit` và kết hợp với các điều kiện `is_nar`, `is_zero`, `sf >= SF_MAX`, `sf < -SF_MAX`.

**2. Ba cải tiến kỹ thuật của `OPT-13` (0 FF, giữ nguyên hợp đồng Packer):**
1. **Tính trước `sf_plus1 = sf + 1` từ `core_sf` (`sf_o_reg`) và chọn `sf_norm` / `offset` bằng MUX 2:1 theo `carry`:**
   - Thanh ghi `sf_o_reg` (`core_sf`) trong `mul_iter_core.sv` đã được chốt cố định ngay từ chu kỳ `launch` (ổn định suốt `q + 3` chu kỳ trước khi `core_done` bật).
   - Thay vì đưa `carry = grid[q+1]` vào đáy chuỗi `CARRY4` cộng `sf + carry`, tính sẵn `sf_plus1 = sf + sf_t'(1)` chỉ phụ thuộc vào `sf` (`sf_o_reg`), rồi chọn `sf_norm = carry ? sf_plus1 : sf` (hoặc tính sẵn `offset_0` từ `sf` và `offset_1` từ `sf_plus1` rồi chọn `offset = carry ? offset_1 : offset_0`). Nhờ đó, `acc_reg[53]` không còn phải đi qua chuỗi `CARRY4` 12-bit trước khi điều khiển `offset`!
2. **Tách nhân bản thanh ghi hoặc buffer cho tín hiệu điều khiển fanout cao (`mode_o` fanout 109 và `carry` fanout 97):**
   - Trong `mul_prepack_norm_comb.sv`, tách tín hiệu chọn `carry_data` (lái 53 bit `frac_norm`) và `carry_ctrl` (lái `sf_norm`/`offset`) để tổng hợp viên không gộp chung net fanout = 97 vào đường điều khiển `offset`.
3. **Rút ngắn nhánh override cuối P1 của `posit_pack_prepare.sv` (hoặc dời phép OR `guard | round | sticky` của `flags[1]` sang P2 nơi đang dư `+4.531 ns` slack):**
   - Trong `posit_pack_prepare.sv`, tính song song điều kiện tràn `ovf = (int'($signed(sf)) >= SF_MAX)` và `udf = (int'($signed(sf)) < -SF_MAX)` độc lập với đường dịch `shifted` / `sticky_lookup[offset]`.
   - Đặc biệt đối với `posit_product_pack.sv` (và `posit_pack.sv` ở chế độ RNE), vì P1 đã chốt đầy đủ `p1_guard_bit_q`, `p1_round_bit_q`, `p1_sticky_bit_q` và `p1_special_sel_q` qua thanh ghi P1, phép gộp `inexact = flags_in[1] | guard_bit | round_bit | sticky_bit` khi `special_sel == NORMAL` có thể đặt ở đầu `posit_pack_finish.sv` (nơi `product_packer_p2` có slack **`+4.531 ns`** và `final_packer_p2` có slack **`+3.401 ns`**) mà **không tốn thêm 1 FF nào** ở biên P1/P2!

---

#### 8.31.4. `OPT-14` — Tối ưu sâu `SAC — state/feedback` bằng cách tách `cfg_mode` khỏi đáy cây Popcount trong `ops_sel_comb.sv`

**1. Nguyên nhân gốc rễ từ `results/opt02c_20261018/ppa/candidate/Default/sac_state_setup.rpt`:**
- Cả 3 đường găng chậm nhất của nhóm `sac_state` (`+1.850 ns` vào `fx_q_reg[24]/D`, `+1.925 ns` vào `fx_q_reg[14]/D`, `+2.030 ns` vào `fx_q_reg[25]/D`) **không còn nằm ở vòng lặp nội bộ `fx_q -> sac_step_comb -> fx_q`** (vốn đã được rút ngắn bởi `OPT-05 abc_tree`), mà đều là **đường nạp khởi tạo khi `launch`**:
  `u_wrapper/mode_q_reg/C (fanout = 112, route 1.283 ns) -> ops_sel_comb (cây popcount 5 tầng -> choose_b, fanout = 25, arrival 9.735 ns) -> MUX swap x_frac -> MUX launch -> u_core/u_ctrl/fx_q_reg/D`!
- **Tại sao `mode_q_reg` phải đi xuyên qua 5 tầng LUT của cây popcount trong `ops_sel_comb.sv`?**
  Tại `ops_sel_comb.sv` (dòng 69–77):
  ```systemverilog
  for (bit_index = 0; bit_index < FRAC_MAX; bit_index++) begin : g_count_mask
      if (bit_index < CUT_W) begin : g_low
          assign pop_a[bit_index] = frac_a[bit_index] & !cfg_mode;
          assign pop_b[bit_index] = frac_b[bit_index] & !cfg_mode;
  ```
  Việc dùng `!cfg_mode` để che 14 bit thấp ngay tại **tầng lá (level 0)** của cây cộng popcount 26-bit làm phát sinh hai hệ lụy:
  1. `mode_q_reg` phải kéo thêm 28 cổng AND ở đáy cây popcount (đẩy tổng **fanout của `mode_q_reg` lên 112**, mất `1.283 ns` chỉ riêng dây dẫn từ FF tới LUT đầu tiên!).
  2. Tín hiệu từ `mode_q_reg` phải leo qua toàn bộ **5 tầng LUT của cây cộng popcount 26-bit + bộ so sánh `count_b < count_a`** (`4.541 -> 9.735 ns`, mất **`5.194 ns`**) mới tạo ra được bit điều khiển hoán vị `choose_b`!

**2. Hai cải tiến kỹ thuật của `OPT-14` (0 FF, giữ nguyên giao diện `ops_sel_comb.sv`):**
1. **Đưa `cfg_mode` ra khỏi đáy cây popcount — tính song song `choose_b_approx` và `choose_b_exact` rồi mới MUX 1-bit ở đỉnh:**
   - Các bit `frac_a[25:0]` và `frac_b[25:0]` xuất phát trực tiếp từ thanh ghi P2 của `u_a` và `u_b` (`p2_frac_q_reg`, nơi đang có slack rất lớn).
   - Thay vì che `!cfg_mode` ở đáy cây:
     - Nhánh 12-bit cao (`frac_a[FRAC_MAX-1 -: FRAC_W]` và `frac_b[FRAC_MAX-1 -: FRAC_W]`): tính trực tiếp tổng số bit 1 phần cao `count_hi_a`, `count_hi_b` và kết quả so sánh `choose_b_approx = (count_hi_b < count_hi_a)` **hoàn toàn không phụ thuộc `cfg_mode`**.
     - Nhánh 14-bit thấp (`frac_a[CUT_W-1:0]` và `frac_b[CUT_W-1:0]`): tính tổng số bit 1 phần thấp `count_lo_a`, `count_lo_b`, cộng với `count_hi_a`/`count_hi_b` để tạo `count_full_a`, `count_full_b` và `choose_b_exact = (count_full_b < count_full_a)` **hoàn toàn không phụ thuộc `cfg_mode`**.
     - Tại đỉnh cây, chỉ dùng **1 MUX 2:1 duy nhất** theo `cfg_mode`:
       ```systemverilog
       assign choose_b = OPS_EN && (cfg_ops == 2'd1)
                       && (cfg_mode ? choose_b_approx : choose_b_exact);
       ```
   - *Lợi ích:* `mode_q_reg` giảm ngay ~28 tải fanout và **không còn phải đi qua 5 tầng LUT của cây popcount**, rút ngắn đường `mode_q_reg -> choose_b -> fx_q_reg` khoảng **3–4 tầng LUT (`~1.5 – 2.0 ns`)**!
2. **Không ép xóa 14 bit cao `candidate_x_a/b[FRAC_MAX-1:FRAC_W]` theo `cfg_mode` khi nạp `x_frac` (hoặc bật `g_group4` cho `N = 26` trong `lod_lzd_core.sv`):**
   - Trong `iter_ctrl.sv` (dòng 53), khi `mode_q == 1` (approximate), mạch SAC chỉ đọc `fx_approx = fx_q[FRAC_W-1:0]` và hoàn toàn không dùng `fx_q[FRAC_MAX-1:FRAC_W]`. Đồng thời, nếu muốn tăng thêm biên độ cho cả vòng lặp `fx_q -> sac_step_comb -> fx_q` của chế độ exact (`W_X = 26`), chỉ cần mở rộng điều kiện `g_group4` trong `lod_lzd_core.sv` (dòng 25) để bao gồm thêm `N == 26` (cùng `N == 30, 31, 32`).

---

#### 8.31.5. Thứ tự triển khai khuyến nghị nếu mở đợt nâng cấp 120+ MHz

| Bước | Mã ứng viên | File RTL tác động | Chi phí FF / Chu kỳ | Mục tiêu Setup Slack (ở 10 ns) | Mục tiêu `F_STA` toàn NF |
| :---: | :--- | :--- | :---: | :---: | :---: |
| **Bước 1 (Thử trước, chưa bảo đảm timing)** | **`OPT-12`** | `posit_parser.sv`, `posit_parser_comb.sv`, `posit_magnitude_parse.sv` | `0 FF` / `0 cycle` | Kéo `Parser C — P1` từ `+1.259 ns` lên **`> +2.10 ns`** | **`~121.5 MHz`** (bị chặn tiếp bởi `product_packer_p1` ở `+1.769 ns`) |
| **Bước 2 (Chỉ khi còn găng)** | **`OPT-13`** | `mul_prepack_norm_comb.sv`, `posit_pack_prepare.sv`, `posit_pack_finish.sv` | `0 FF` / `0 cycle` | Kéo `Packer tích — P1` từ `+1.769 ns` lên **`> +2.40 ns`** | **`~122.7 MHz`** (bị chặn tiếp bởi `sac_state` ở `+1.850 ns`) |
| **Bước 3 (Hướng tới 125–130 MHz)** | **`OPT-14`** | `ops_sel_comb.sv` (và tùy chọn `lod_lzd_core.sv` `N=26/30`) | `0 FF` / `0 cycle` | Kéo `SAC — state/feedback` từ `+1.850 ns` lên **`> +2.40 ns`** | **`125 – 130+ MHz`** (mục tiêu khảo sát; chưa có bằng chứng mọi bank đạt, kể cả CE Parser B) |

#### 8.31.6. Change review và mở lại candidate — 18/10/2026

**Quyết định hiện hành:** theo yêu cầu sinh viên, mở lại nghiên cứu candidate cho mục tiêu **trên120MHz**;
chưa triển khai tối ưu RTL và chưa chạy W14. Production/lock `POSIT_MAC_RTL_20261018_OPT02C` giữ nguyên
làm reference100MHz có bằng chứng, không còn là quyết định chốt cuối cho đợt nghiệm thu sắp tới.
Study mới: `results/opt120_20261018/review.json`, trạng thái `OPEN_PENDING_OPT12_IMPLEMENTATION`;
`source/reference` và `source/candidate` hiện cùng byte, chưa có candidate được kiểm/promote.
Snapshot reference RTL/model/build/XDC được đóng gói trong reference_source.zip, đã kiểm SHA/CRC.
Mở candidate không có nghĩa bỏ hash của checkpoint cũ hoặc được chạy W14 trên nguồn đang đổi.

**Đánh giá:** đồng ý hướng OPT-12 trước; chưa đồng ý triển khai nguyên cả8.31 như một gói.
Các điều chỉnh dưới đây là điều kiện cho lần triển khai sau:

| Hạng mục | Đánh giá và giới hạn |
| --- | --- |
| OPT-12: XOR hai bit kề | Hợp lý: giữ vị trí bit1 đầu tiên/invalid của detector với dữ liệu nhị phân; vector terminator_bits không giống từng bit ở phía sau terminator. Vẫn giữ first_regime_bit và payload magnitude cho P1/P2. Không tuyên bố tương đương X/Z |
| OPT-12: sentinel1 | Hợp lý: nối ở LSB vật lý, khoảng cách tính từ MSB là NB−2; đếm no-terminator đúng MAX_COUNT. CNT_W vốn bằng clog2(NB−1), nên guard đề xuất là đồng nhất, không phải trường hợp riêng cho NB chẵn/lẻ. Phải kiểm toàn miền NB/ES/width hợp lệ trước adopt |
| OPT-12: conditional negate | Hai biểu thức tương đương trên số nhị phân NB bit, kể cả0/NaR; phù hợp thử A/B riêng. Cách viết không bảo đảm Vivado bỏ MUX hoặc giảm CARRY/LUT. Fanout27→1 và mức tăng slack là giả thuyết, chưa phải số đo |
| OPT-13: sf+1 tính song song | Đáng khảo sát nếu Packer P1 vẫn găng sau OPT-12. RTL hiện đã viết sf+1 trong nhánh carry; chỉ đổi cú pháp có thể tổng hợp lại cùng netlist. SF ổn định nhiều chu kỳ không tự cho phép multicycle hay bỏ timing; không thêm exception |
| OPT-13: tách carry_data/carry_ctrl | Hai wire alias sẽ bị tối ưu gộp, không bảo đảm giảm fanout. Duplicate thanh ghi là tăng FF dù không tăng cycle; không được ghi0FF. Chỉ dùng tối ưu vật lý có đo và báo chi phí, không thêm buffer/FF mù |
| OPT-13: special overrides/inexact | Không được xóa override hoặc đổi flags ở public posit_pack_prepare rồi vẫn gọi bit-exact từng leaf. Module này dùng chung với comb/RNE/TRUNC và NF/F. Chỉ thử cặp helper nội bộ với hợp đồng rõ hoặc giữ nguyên leaf công khai; kiểm Zero/NaR/max/min,biên SF,flags đầu vào,RNE/TRUNC và reset/stall. OR G/R/S ở P2 chỉ cho NORMAL, giữ flags đặc biệt đúng contract |
| OPT-14: hai predictor exact/approx | Hợp lý về hàm chọn: popcount high cho approx và full cho exact, tie giữ A. cfg_mode chỉ chọn ở cuối; có thể tăng LUT/routing do thêm sum/comparator. EXACT_EN0 phải loại cone exact khi elaboration; CUT_W0 không sinh slice âm. Không mặc định tiết kiệm LUT hoặc nhanh thêm1,5–2ns |
| OPT-14: bỏ x_frac high-bit clearing | **Không chấp thuận như đề xuất hiện tại.** x_frac là output đã quy định và controller kiểm cả fx_q ở is_init=(fx_q==0)||(limit_q==0), cùng approx_cut dùng fx_q!=0. Chỉ nhìn fx_approx slice không chứng minh các bit cao là don't-care; giữ zero-extension để bảo toàn output/iteration/token/flags |
| Mở group4 cho N26/30 | Thử riêng sau khi cần, không gộp vào OPT-12. Sentinel của parser32 đã cho N31 và dùng group4 hiện có; không cần sửa common LOD ngay. Magnitude parser đang có slack+3,418ns, chưa phải ưu tiên |

Kiểm nhanh biểu thức bằng Python: vét NB4..16, **131.056 trường hợp/0 mismatch** về count sau adjacent-XOR
và sentinel. Đây chỉ là kiểm đại số nhị phân, **chưa phải test RTL/parser hoặc bằng chứng timing**.

**Chỉnh cách đọc STA và mục tiêu:**

- +1,667ns tại10ns chỉ là mốc sàng lọc ước lượng120MHz; đúng120MHz chưa đạt mục tiêu trên120MHz.
  Không thể kết luận OPT-12 chắc chắn đủ hoặc ba bước chắc chắn đạt125–130MHz, vì placement/routing,
  skew,CE và đường găng có thể đổi. Parser B P1 CE+1,910ns cũng dưới mốc+2ns cho125MHz.
- NF Default còn đường output in_ready WNS+0,894ns, F toàn thiết kế+0,982ns tại100MHz.
  Vì vậy chỉ tối ưu R2R parser chưa bảo đảm toàn giao tiếp đạt trên120MHz với cùng budget I/O.
  Khi đo clock cao phải báo setup/hold I/O và Internal R2R riêng; nếu chỉ R2R PASS thì chỉ kết luận R2R.
- Giữ A35T-C2/10ns và cả hai XDC gốc để đối chiếu. Lần đo clock cao tạo profile mới, đề xuất8ns/125MHz,
  user uncertainty0,1ns và cùng I/O budget, không ghi đè profile100MHz hoặc ngầm giảm delay để nhận PASS.
  Timing cao chỉ được công bố sau post-route trực tiếp tại clock đó, setup/hold đều đạt và không có đường unconstrained.

**Thứ tự thử sau review:** baseline → adjacent-XOR → adjacent-XOR+sentinel → thêm conditional-negate như
một biến thể riêng; kiểm bit-exact/lint/parameter/Zero/NaR trước, pilot NF/F reset/stall/flags/state,
rồi mới matched PPA A35T. Chọn theo số đo timing/LUT/FF, không theo dự báo. Chỉ mở OPT-13/14 hoặc nhánh
ready/CE nếu báo cáo mới cho thấy còn chặn mục tiêu. Không thêm tầng, đổi precision hoặc oracle trong đợt này.
Sau khi chọn biến thể và kiểm tích hợp cần thiết mới phát hành lock mới và tiếp tục W14-01..12.
**Hiện chưa chạy RTL simulation, synthesis hoặc STA mới.**

#### 8.31.7. Thử OPT-12 và STA trực tiếp120,48/125MHz — 18/10/2026

**Đã hoàn tất thử nghiệm, chưa promote hoặc khóa RTL mới.** Candidate đề nghị là `negate`:
adjacent-XOR + sentinel + conditional-negate, tại `rtl/candidates/parser/opt12/`.
Hai file giữ nguyên byte từ source đã kiểm; production38 module, model/oracle, XDC100MHz và lock reference không đổi.
`source/candidate` trong study là alias review của negate; reference và các biến thể riêng vẫn được giữ để đối chiếu.
Chỉ thay hai parser comb/pipeline; không sửa common LOD, precision, OPS, SAC, packer hoặc lịch NF14/F13 tầng.
Không triển khai OPT-13/14. Macro clock/reset/valid/ready, C_eff và thuật toán giữ nguyên.

**Kiểm chức năng:** ba biến thể adjacent/sentinel/negate, mỗi biến thể870 strict lint cấu hình
(435 NB/ES × comb/pipeline),0 warning/error;13 profile cycle-equivalence với parser reference và decoder
trường độc lập,84.272 checks; vét cạn6 format nhỏ gồm8/0 và16/1,66.480 checks/biến thể.
Các profile biên gồm NB4/5/7/9/17/31/32,ES28 và SF_W9/40; có reset,bubble và stall.
Đây là bằng chứng kiểm thử, không phải formal exhaustive toàn posit32 hoặc tương đương X/Z.

Sentinel và negate **mỗi biến thể** đều đạt:

- NF pilot8/0,16/1,32/2,32/3:80.000 completed,0 mismatch; F32/3 pilot100.000,0 mismatch.
- NF32/3 main10.000.000 completed/85.316 reset-aborted,0 mismatch.
- F32/3 main10.000.000 completed/20.151 reset-aborted,0 mismatch,59.356.752 stage checks.
- Toàn bộ JSON numerical/protocol/coverage counters của các lượt10M bằng checkpoint reference tương ứng;
  không chỉ so một tổng số mismatch. Hai main này là lượt mới, không kế thừa hash source cũ để gọi PASS.
- ModelSim10.1d ở chu kỳ8ns/CK2Q1ns: NF bốn format111.456 completed/288 abort;
  F8.192 completed/24 abort;0 mismatch, kiểm reset/stall/latency/state. Đây là RTL event simulation, không phải SDF.

Verilator5.032,GCC15.2.0,SoftPosit0.4.1 đúng format cho NF8/0,16/1,32/2; ES3 dùng oracle độc lập.
NF seed20264217,F20261015; parser parameter generator giữ seed20261016+100*NB+ES+SF_W.
Lệnh/source/binary/compiler/simulator hashes và counters giữ tại study `results/opt120_20261018`.
Main vẫn trộn n/config; **không thay W14 per-n/AC04 hoặc nghiệm thu exact toàn SPEC**.

**STA/PPA:** Vivado2026.1 build6511674,A35T xc7a35tcpg236-1; clock8ns hoặc8,3ns đọc trước synthesis.
Giữ input min=max2,5ns,output min0/max0,5ns,user setup/hold uncertainty0,1ns; không thêm timing exception.
Profile clock cao riêng, không ghi đè C2/10ns và không scale I/O. Mỗi hàng là post-route thực tế,
không phải F_STA suy từ10ns. NF EXACT_EN1; F EXACT_EN0/W32; chưa phải paired NF/F PPA công bằng của tuần15.

| Top | Biến thể | Strategy | Clock ns | MHz | WNS toàn thiết kế ns | WHS ns | R2R setup ns | LUT | FF | Setup/hold toàn thiết kế |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| NF | negate | Default | 8.000 | 125.00 | -0.154 | +0.055 | +0.072 | 2428 | 931 | FAIL |
| NF | negate | Default | 8.300 | 120.48 | +0.166 | +0.057 | +0.538 | 2423 | 931 | PASS |
| NF | negate | Explore | 8.300 | 120.48 | +0.227 | +0.053 | +0.309 | 2424 | 931 | PASS |
| NF | negate | RuntimeOptimized | 8.300 | 120.48 | -0.058 | +0.056 | +0.105 | 2465 | 931 | FAIL |
| NF | reference | Default | 8.000 | 125.00 | -0.333 | +0.039 | +0.450 | 2597 | 931 | FAIL |
| NF | reference | Default | 8.300 | 120.48 | +0.083 | +0.016 | +0.150 | 2577 | 931 | PASS |
| NF | sentinel | Default | 8.000 | 125.00 | -0.147 | +0.030 | +0.142 | 2565 | 931 | FAIL |
| NF | sentinel | Default | 8.300 | 120.48 | +0.329 | +0.036 | +0.329 | 2546 | 931 | PASS |
| F | negate | Default | 8.300 | 120.48 | -0.009 | +0.040 | +0.601 | 1361 | 815 | FAIL |
| F | negate | Explore | 8.300 | 120.48 | +0.093 | +0.040 | +0.608 | 1362 | 815 | PASS |
| F | negate | RuntimeOptimized | 8.300 | 120.48 | +0.470 | +0.046 | +0.765 | 1375 | 815 | PASS |

TNS/THS bằng0 đối với các hàng PASS; hàng FAIL được giữ, không làm tròn slack âm thành0 hoặc bỏ khỏi bảng.
Default125MHz của reference/sentinel/negate đều chưa đạt toàn giao tiếp dù R2R đạt;
đường chặn là in_ready. Ở120,48MHz, F Default thiếu0,009ns; dùng strategy đã PASS cho cả NF/F được liệt kê
trong qualification.json, không tuyên bố mọi strategy đều đạt. Chưa quét Fmax cực đại hoặc xác nhận trên board.

NF reference Default tại8,3ns cũng đạt (WNS+0,083ns,WHS+0,016ns,2577LUT/931FF).
Negate Default cùng điều kiện đạt+0,166/+0,057ns,2423LUT/931FF: **giảm154LUT (~5,98%), FF không đổi**.
Đây là lợi ích đo được so reference cùng clock/flow; không quy toàn bộ việc đạt120MHz cho OPT-12.
Không so LUT của profile8ns với8,3ns để kết luận phần trăm tối ưu.

Giữ warning OOC về PARTPIN/CFGBVS và giới hạn báo cáo: budget I/O là giả định benchmark, chưa có pinout/load
hoặc timing giao tiếp board thực. Defined-clock CDC report không thay RDC/board signoff.
Lượt đầu `ppa/reference/p8000/Default` dừng trước synthesis do runner thay nhầm tên file I/O XDC khi đổi profile;
đã sửa runner, giữ failed log riêng và chạy vào *_r1. Lượt lỗi không được tính vào11 phép đo trong bảng.

**Lệnh chính từ Posit_MAC:**

```bash
bash --noprofile --norc scripts/verify_opt12.sh sentinel
bash --noprofile --norc scripts/verify_opt12.sh adjacent
bash --noprofile --norc scripts/verify_opt12.sh negate
bash --noprofile --norc scripts/verify_opt12_nf.sh negate
bash --noprofile --norc scripts/verify_opt12_fused.sh negate
bash --noprofile --norc scripts/stress_opt12.sh negate nf 10000000
bash --noprofile --norc scripts/stress_opt12.sh negate f 10000000
```

```powershell
./scripts/verify_opt12_modelsim.ps1 -Variant negate -AllFormats -RunRoot results/opt120_20261018/event_negate
./scripts/run_opt12_ppa.ps1 -Variant negate -Top nf -Period 8.300 -Strategy Explore
./scripts/run_opt12_ppa.ps1 -Variant negate -Top f -Period 8.300 -Strategy Explore
python scripts/audit_opt12.py
python scripts/audit_rtl_release.py --self-test
```

Các producer từ chối output root đã có; khi replay cần giữ nguyên bằng chứng, chọn attempt/root mới hoặc
restore snapshot vào bản sao workspace trong phạm vi dự án. Không chạy prepare/finalize để ghi đè checkpoint.
Evidence/nguồn/rpt/CSV/raw counters đóng gói gọn, kiểm CRC/SHA; binary/work/cache/wave không đưa vào Git.
**Chờ sinh viên chọn candidate trước promote/khóa cuối; W14 vẫn chưa chạy.**
