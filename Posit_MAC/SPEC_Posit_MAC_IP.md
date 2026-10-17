# SPEC ĐỒ ÁN CHUYÊN NGÀNH — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

| Mục | Nội dung |
| --- | --- |
| Tên đề tài | Thiết kế và kiểm chứng lõi IP Posit MAC xấp xỉ, lặp (Approximate & Iterative Posit MAC) trên FPGA, có mở rộng ASIC |
| Sinh viên | Đan Huy |
| Tài liệu tham chiếu chính | [P] C. J. Norris, S. Kim, *An Approximate and Iterative Posit Multiplier Architecture for FPGAs*, ISCAS 2021 |
| Tài liệu liên quan | [15] Kim & Rutenbar, GLSVLSI 2019; [18] Babic et al. 2011; [23] Jaiswal & So, PACoGen, IEEE Access 2019; [4] Gustafson & Yonemoto 2017; [F] Murillo, Del Barrio & Botella, *Customized Posit Adders and Multipliers using the FloPoCo Core Generator*, FPL 2020 |
| Phiên bản | v1.19 — 2026-10-17 — OPT-03: NF product RNE P1/P2 và parse riêng; số học giữ nguyên |
| Quy ước từ khóa | **MUST** = bắt buộc; **SHOULD** = nên làm; **MAY** = tùy chọn/mở rộng |
| Quy ước ID | `FR-xx` yêu cầu chức năng; `NFR-xx` phi chức năng; `AC-xx` tiêu chí nghiệm thu; `TC-xx` test case; `TV-xx` test vector; `EXT-x` mở rộng |

Các số tham chiếu `[4]`, `[15]`, `[18]`, `[23]`, `[24]` giữ theo danh mục của [P]. `[F]` là bài báo FloPoCo bổ sung; `[19]` trong [P] là DRUM, không phải nguồn thuật toán đóng gói. SPEC mô tả yêu cầu và kiến trúc mục tiêu; kết quả thực hiện được ghi trong `results/` và nhật ký tiến độ. Nguồn local đã đối chiếu: [P](An%20Approximate%20and%20Iterative%20Posit%20Multiplier%20Architecture%20for%20FPGAs.pdf), [F](Customized%20Posit%20Adders%20and%20Multipliers%20using%20the%20FloPoCo%20Core%20Generator.pdf).

### Lịch sử thay đổi (Changelog)

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| v1.0 | 2026-09-30 | Phác thảo mục tiêu, yêu cầu và lộ trình. |
| v1.1 | 2026-10-02 | Chuẩn hóa non-fused v0/v1, bypass giữ thứ tự, FIFO/credit, round_unpacked và lộ trình baseline trước tối ưu. |
| v1.2 | 2026-10-02 | Bổ sung kiến trúc fused v2, vector kiểm tay và kiểm chứng tùy chọn ngoài đường găng. |
| v1.3 | 2026-10-03 | Gom mô tả lặp; sửa nguồn FloPoCo, parser và số liệu PPA; phân biệt exact/approx và yêu cầu/mục tiêu; làm rõ backpressure, tích lũy, phạm vi kiểm chứng và các giới hạn v2. |
| v1.4 | 2026-10-06 | Phân biệt số hạng thanh ghi/latency/handshake; khóa profile RTL và n; chốt reset bridge, lịch core n=0/early termination; cập nhật mục 11 và tài liệu phụ. Bổ sung ranh giới packer RNE P1/P2 ở §5.9-D; chưa nghiệm thu RTL tích hợp hoặc PPA. |
| v1.5 | 2026-10-07 | Triển khai packer tổ hợp và pipeline RNE2/TRUNC1; khóa F_IN/adapter; sửa pre-clamping minpos thành sf<-SF_MAX theo L1 để giữ RNE tại đúng biên. Bằng chứng tuần8 tại results/packer/; khảo sát PPA packer riêng tại results/packer_ppa/, chưa nghiệm thu MAC tích hợp hoặc Gate4. |
| v1.6 | 2026-10-11 | Chuyển mục tiêu so sánh sang baseline nội bộ MAC v1 vs fused v2; AC03/AC06 cập nhật, fused trở thành hạng mục chính; bảo toàn hợp đồng số học đã nghiệm thu và ma trận kiểm cuối. |
| v1.7 | 2026-10-11 | Chốt profile nhân FLOOR/RNE, exporter tích prepack và metadata; kiểm độc lập Linux/Windows/UBSan, đóng băng L1 hiện có; fused signed residual còn theo mốc riêng. |
| v1.8 | 2026-10-11 | Đồng bộ fused profile chính thành MUST trong latency/top/matrix/PPA/rủi ro; giữ exact fused và cấu hình phụ là MAY. Thêm matrix NF/F32/3 FLOOR/RNE n0..8, phân biệt sketch với hợp đồng chưa nghiệm thu; checklist tuần10 đặt tạm trong tiến độ. |
| v1.9 | 2026-10-12 | Chốt posit_add NF: input exact unpacked, output fraction mở rộng/sticky/flags, width và adapter; ba tầng elastic A1/A2/A3 với lịch cạnh/reset/stall; review mapping L1, chưa triển khai RTL adder. |
| v1.10 | 2026-10-12 | Hiện thực comb/pipeline adder ba tầng, oracle integer độc lập; ModelSim/pilot/20M lượt lớn đạt0 mismatch. Chốt input corpus NF/F và bàn giao tuần10; coverage AC04, MAC/Gate3, fused và PPA còn mở. |
| v1.11 | 2026-10-13 | Kiểm carry xác nhận legacy khác R(P_hat); thêm adapter bảo toàn prepack và MAC NF đơn giao dịch RNE/FLOOR, Gate3 đạt. Giữ freeze/Gate2 legacy; fused full-sum mới pilot, chưa RTL/coverage cuối/PPA. |
| v1.12 | 2026-10-13 | Gom khác biệt paper/NF tại §5.10-G; sửa mapping module, unsigned shift, metadata register và carry adapter. Chỉ làm rõ tài liệu, không đổi RTL hoặc hợp đồng số học đã kiểm. |
| v1.13 | 2026-10-14 | Đồng nhất profile/params, normalize/carry, ngoại lệ, feedback/latency và trạng thái fused; sửa pseudocode G/R/S, oracle ES3, luồng công cụ/PPA và truy vết. Phát hiện W11 chưa đạt tỷ lệ near-cancellation30%; giữ ngưỡng và mở lại phần coverage Gate3, không đổi RTL hoặc kết quả lịch sử. |
| v1.14 | 2026-10-14 | Bổ sung corpus/counters/probe NF: main10M/0 mismatch,near52,55548%,run/polarity và packer bins đạt; ModelSim corner82.944/0 mismatch. Đóng Gate3 tuần11,giữ checkpoint cũ và các yêu cầu final/F/PPA còn mở. |
| v1.15 | 2026-10-14 | Tách masked-popcount/data candidates và hidden trước swap; interface/M0 giữ nguyên. Matrix1,334M và NF10M0 mismatch;398 lint sạch;OPS216→196LUT4,median108,08→112,01MHz trên3seed/cấu hình. Giữ source-bound checkpoints cũ và giới hạn PPA toàn MAC. |
| v1.16 | 2026-10-15 | Chốt F post-prepack W32/Q29 với residual có dấu/borrow,flags/state và L1 đã kiểm. Oracle p8 exhaustive/FMA smoke; main phân tầng2.208.768 trên Linux/Windows/UBSan0 mismatch. Toàn NF post-route median45,07MHz trên CycloneIV,chưa đạt100MHz; bàn giao pipeline F dự kiến,giữ nguyên RTL NF và các ứng viên riêng. |
| v1.17 | 2026-10-15 | Theo lựa chọn sinh viên, phép đo PPA mới dùng Vivado/Xilinx D2; giữ các số đo CycloneIV làm lịch sử. Thử riêng shifter/LOD trước SAC/parser/MAC; giữ giao diện, parameter và tổ hợp. A35T/A100T có sẵn, Zynq7020 chưa được cài. Phân biệt R2R của benchmark, ước lượng Fmax từ STA và kiểm trên board. Không đổi hợp đồng số học/pipeline NF/F. |
| v1.18 | 2026-10-15 | Triển khai posit_mac_f 32/3 FW12 W32/Q29, F1–F5 và RNE cuối; 10M giao dịch/0 mismatch với oracle và trace, pipeline đầy/stall/reset và XSim CK2Q đạt. Core approximate thu hẹp12 bit, ABS/borrow một adder. Vivado A35T một run đạt100MHz R2R; giữ final per-n/AC04, CDC/RDC và paired NF/F PPA mở. |
| v1.19 | 2026-10-17 | NF tách normalize+product P1 → P2 → parse/product bank. L_valid=q+12, H=q+13, II_min=q+14; kiểm chứng/STA riêng tại §11.16. Không đổi L1 hoặc fused. |

**Nơi quy định chính:** độ trễ/ngữ nghĩa MAC ở §5.1; Zero/NaR ở §5.3; làm tròn ở §5.9; chồng lấn/backpressure ở §5.11; fused ở §5.12; phạm vi nghiệm thu ở §6. Profile hiện thực và giới hạn bằng chứng được tóm tắt tại §1.6/§11.10–§11.16. Nhật ký có ngày ở phụ lục là lịch sử, không ghi đè hợp đồng hiện hành hoặc tự mở rộng một mốc PASS thành toàn bộ AC.

---

## 1. Mục tiêu, phạm vi, đóng góp

### 1.1 Mục tiêu

Xây dựng một lõi IP Posit MAC (`D = A × B + C`) bằng SystemVerilog tham số hóa, trong đó phép nhân là **nhân xấp xỉ dạng lặp dịch-cộng** (theo [P], kế thừa [15]) với số vòng lặp `n` chọn được lúc chạy, kèm môi trường kiểm chứng tự động bit-accurate với SoftPosit, và bộ số liệu accuracy/PPA tái lập giữa MAC v1 non-fused (baseline nội bộ) và MAC v2 fused. FP32/FP16 là đối chứng bổ sung khi có thời gian; không yêu cầu tái hiện RTL gốc tác giả để đóng mục tiêu này.

### 1.2 Phạm vi

**Trong phạm vi (In-scope)**

- Định dạng posit tham số hóa `(NB, ES)`; cấu hình chuẩn: `(8,0)`, `(16,1)`, `(32,2)`, `(32,3)`.
- Các khối: Parser, Operand Selector (OPS), Shift Amount Calculator (SAC), Shift-Based Multiplier (SBM) + bộ điều khiển lặp, Posit Adder, Rounder/Packer, MAC top.
- **Hai bản bắt buộc:** MAC v1 non-fused làm baseline nội bộ và MAC v2 fused profile §11.8; hoàn thành NF/Gate3 trước, hoàn thành fused trước nghiệm thu đề tài. Exact fused và cấu hình F phụ là MAY.
- Ba tầng đối chiếu L0 SoftPosit, L1 mô hình thuật toán và Ideal; RTL là thiết kế được kiểm chứng (§6.1).
- Testbench tự động, coverage, hồi quy, thống kê sai số (Error Rate, MSE, max error).
- Tổng hợp/P&R Vivado theo **chính sách bậc thang thiết bị (§7.6)**: nền tảng hiện hành từ15/10 là Artix-7 D2 (`xc7a35t`/`xc7a100t`); D0 (`xcvu9p`) dành cho đối chiếu cùng device bài báo khi có điều kiện, D1/D3/D4 là phương án bổ sung. So sánh công bằng giữa NF/F; FP32/FP16 MAC là đối chứng bổ sung.
- **Chiến lược phân kỳ hiện thực (Staged Implementation Strategy)**:
  - *Giai đoạn 1 (Baseline - Hoàn thành trước Gate 3)*: Hoàn thiện lõi MAC **đơn lẻ cô lập**; exact/RNE khớp L0, approx khớp L1. Bắt tay, giữ đầu ra khi bị chặn và xử lý Zero/NaR đúng là bắt buộc từ giai đoạn này.
  - *Giai đoạn 2 (Advanced Optimization - Tích hợp sau Gate 3)*: Khảo sát chồng lấn giao dịch (mục tiêu $\text{II} \approx n$), bypass Zero/NaR với Order FIFO khi cần giữ thứ tự, Output Skid Buffer và tối ưu Clock Enable (CE). Early-stop khi fraction hết bit 1 đã có trong baseline; không coi đây là chức năng chưa triển khai.

**Ngoài phạm vi (Out-of-scope)**

- Chia, căn bậc hai, chuyển đổi FP↔posit bằng phần cứng (chỉ làm trong phần mềm để sinh vector).
- Quire phần cứng toàn miền và tích lũy cả chuỗi với một lần làm tròn cuối. Chỉ đề cập như hướng phát triển; không đồng nhất software full-sum của một giao dịch với quire RTL.
- Chip tape-out thật. (Phần ASIC chỉ dừng ở luồng RTL-to-GDSII mô phỏng bằng công cụ mã nguồn mở, xem EXT-A.)

### 1.3 Đóng góp dự kiến

| ID | Đóng góp | Ghi chú |
| --- | --- | --- |
| C1 | Hiện thực và kiểm chứng MAC trên cấu trúc nhân lặp tham khảo [P], thêm đường cộng C và điều khiển | Đây là phần tích hợp của đồ án; không tuyên bố phát minh thuật toán MAC/FMA. Paper có bộ cộng nội bộ SBM nhưng không có đường Posit add C của MAC |
| C2 | Golden model 3 tầng và phương pháp kiểm chứng phân tầng theo độ dài regime | Vá điểm yếu "random đều" |
| C3 | Đối chiếu kiến trúc với [P], ghi rõ giả định và giới hạn tái dựng | TableI/provenance là nghiên cứu phụ, không chặn baseline nội bộ |
| C4 | So accuracy/PPA MAC v1 non-fused vs v2 fused cùng cấu hình và corpus | Xem §11.8; FP32/FP16 bổ sung |
| C5 (chọn) | Luồng ASIC (EXT-A) hoặc khảo sát không gian thiết kế (EXT-B) | Xem §8 |

### 1.4 Tiêu chí nghiệm thu (Acceptance Criteria)

| ID | Tiêu chí | Ngưỡng đo được |
| --- | --- | --- |
| AC-01 | RTL khớp L1 bit-exact | **0 mismatch** trên ≥ 10^7 vector cho mỗi điểm approx bắt buộc của §6.7, gồm từng OPS, n, ROUND_MODE và ROUND_SCHEME đã chọn; exact theo AC-02. Các hàng MAY/EXT chỉ áp dụng khi triển khai |
| AC-02 | Chế độ exact (EXACT_EN=1, cfg_mode=0, RNE) khớp SoftPosit bit-exact | posit8: exhaustive mul (2^16 cặp), add (2^16 cặp), MAC (2^24 bộ ba); posit16: exhaustive mul và add (2^32 cặp); posit32: ≥ 10^8 vector ngẫu nhiên phân tầng + toàn bộ corner list. **0 mismatch**; p8/0,p16/1,p32/2 dùng SoftPosit đúng format,32/3 dùng oracle integer/rational độc lập đủ rộng |
| AC-03 | Đánh giá paired accuracy NF/F theo §11.8 | Pilot10^5, phép đo chính≥10^6 triple/profile; oracle độc lập, seed/corpus/ngoại lệ đóng băng, báo cả kết quả bất lợi. Không thay AC01/AC02 |
| AC-04 | Bao phủ | Line ≥ 95%, branch ≥ 90%, toggle ≥ 85%; functional coverage 100% các bin hợp lệ của §6.6. Bin không thể đạt do cấu hình phải có giải thích và loại trừ được truy vết |
| AC-05 | Tổng hợp | Báo cáo LUT/FF/CARRY/DSP/BRAM, WNS, fmax post-route cho ≥ 3 cấu hình; DSP = 0, BRAM = 0. Nền tảng theo chính sách bậc thang §7.6 (có phương án khi không có `xcvu9p`) |
| AC-06 | So sánh PPA | MAC v1 NF vs v2 F cùng device/tool/ràng buộc/config; ≥3 run/config, latency/II/throughput và tài nguyên; FP32/FP16 là MAY |
| AC-07 | Tái lập | Luồng build/generate/sim/audit/PPA được tài liệu hóa và chạy từ nguồn đóng băng; chỉ gọi make all là đầy đủ sau khi orchestration triển khai thực sự |
| AC-08 | Truy vết | Ma trận FR → TC → kết quả đầy đủ (Phụ lục D) |

### 1.5 Mức độ hoàn thành

Các Tier là định nghĩa mức nghiệm thu, không phải tự đánh dấu đã đạt theo số tuần.

| Mức | Điều kiện | Hiện trạng14/10/2026 |
| --- | --- | --- |
| Tier1 — nền tảng | Parser/packer, multiplier và adder đúng ở profile công bố; hoàn tất AC01/AC02/AC05 áp dụng | Các mốc đơn vị/Gate1/Gate2 đạt; ma trận final và PPA toàn khối chưa đạt |
| Tier2 — NF | MAC NF đúng số học/giao thức và coverage tích hợp theo SPEC; baseline nội bộ có nguồn đóng băng | Gate3 tuần11 đạt số học/protocol và coverage phân bố,near52,55548% (§11.12); ma trận final/PPA còn mở |
| Tier3 — mục tiêu đầy đủ | Tier2 cùng fused profile chính, paired accuracy/PPA và toàn bộ AC01..08 áp dụng | Chưa đạt; oracle/L1 F_W32/flags/state đã đạt tuần12; F RTL,ma trận cuối,paired accuracy/PPA và Gate4 còn mở |

Các Tier không bảo đảm xếp loại hội đồng. Một report PASS có phạm vi riêng không thay chứng cứ của các AC chưa chạy.

### 1.6 Profile và bằng chứng hiện hành

| Nhánh | Hiện thực / oracle | Phạm vi đã kiểm |
| --- | --- | --- |
| Legacy giữ lịch sử | L1 `PositMac`, `L1MultiplierIter`; RTL `posit_mul_iter`/`mul_iter_wrapper` với `mul_norm_comb` | Gate1/Gate1B/Gate2 và freeze L1 giữ nguyên. Multiplier đã kiểm bốn format,FLOOR/JAM,RNE/TRUNC; không dùng bits legacy làm R(P_hat) cho so NF/F khi carry |
| NF so sánh chính | `posit_mac_nf`/`mac_nf_wrapper`; `mul_prepack_norm_comb`; `week11::Model` ở tb/week11_model.hpp | RNE/FLOOR,main32/3,FRAC_W12,OPS1,n0..8; OPS0/exact kiểm bổ trợ. Main mới10M,near52,55548% và coverage Gate3 đạt; pilot bốn format0 mismatch. Chưa toàn ma trận final |
| F phần mềm | `FusedWindow`/`FusedWindowAccumulator` ở l1/include/posit_fused_window.hpp; Oracle full-grid độc lập ở tb/week12_fused_reference.hpp và Python trace | G-F-L1 tuần12:32/3,FW12,W32/Q29,FLOOR/RNE,n0..8,OPS0/1,flags/state;2.208.768 ca/nền tảng Linux/Windows/UBSan0 mismatch,near52,55300693%. Không phải RTL F hoặc FMA exact từ A×B |
| Paper research | `paper_mul_iter`, predictor/RND và các profile có tên riêng | Trace/Fig.4 và các khảo sát lịch sử có bằng chứng riêng; chưa có RTL tác giả/provenance/TableI nguyên bản |

RNE/NF mới được kiểm theo chính hợp đồng prepack đã chốt; không gọi nó approximate bit-exact với MAC legacy. Chọn đúng oracle theo tên nhánh trước khi chạy regression.

---

## 2. Nền tảng Posit dùng trong spec

### 2.1 Định nghĩa

Posit `(NB, ES)`: bit `NB-1` là dấu `s`; tiếp theo là **regime** (chuỗi bit giống nhau độ dài `m`, kết thúc bằng một bit đối); tiếp theo tối đa `ES` bit **exponent** `e`; phần còn lại là **fraction** `f`. Giá trị:

```
x = (-1)^s × useed^k × 2^e × (1.f),   useed = 2^(2^ES)
```

- Regime toàn 0 (m số 0, kết thúc bằng 1): `k = -m`. Regime toàn 1 (m số 1, kết thúc bằng 0): `k = m-1`.
- **Scale factor** `sf = k × 2^ES + e`, khi đó `x = (-1)^s × 2^sf × (1.f)`. Toàn bộ datapath làm việc trên bộ ba `(s, sf, 1.f)`.
- `0…0` là **zero**; `1 0…0` là **NaR** (Not a Real). Với kết quả hữu hạn khác 0, vượt dải thì bão hòa độ lớn về `maxpos`/`minpos`; zero vẫn được xuất khi tích bằng 0 hoặc tổng triệt tiêu chính xác. NaR chỉ xuất theo quy tắc lan truyền ngoại lệ.
- Số âm biểu diễn bằng bù hai của toàn bộ chuỗi bit.

### 2.2 Bảng cấu hình chuẩn

| Cấu hình | NB | ES | useed | FRAC_MAX = NB−3−ES | maxpos | minpos | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- | --- |
| posit8 | 8 | 0 | 2 | 5 | 2^6 = 64 | 2^-6 ≈ 1.56×10^-2 | Trùng kiểu p8 của SoftPosit |
| posit16 | 16 | 1 | 4 | 12 | 2^28 ≈ 2.7×10^8 | 2^-28 ≈ 3.7×10^-9 | Trùng kiểu p16 của SoftPosit |
| posit32 | 32 | 2 | 16 | 27 | 2^120 ≈ 1.3×10^36 | 2^-120 ≈ 7.5×10^-37 | Trùng kiểu p32 của SoftPosit |
| posit32-paper | 32 | 3 | 256 | 26 | 2^240 ≈ 1.8×10^72 | 2^-240 ≈ 5.6×10^-73 | Cấu hình của [P] |

Tham chiếu IEEE-754: FP32 có max ≈ 3.4×10^38, subnormal nhỏ nhất ≈ 1.4×10^-45; FP16 có max = 65504, subnormal nhỏ nhất ≈ 6.0×10^-8.

Hai nhận xét cần đưa vào báo cáo:

1. posit32 `ES=2` có `maxpos ≈ 1.3×10^36` **nhỏ hơn** FP32 max (3.4×10^38, lớn hơn khoảng 262 lần); muốn dải rộng hơn FP32 thì phải dùng `ES=3` như [P].
2. Ở quanh giá trị 1.0 (regime 2 bit), posit32 `ES=2` có 27 bit fraction, FP32 có 23 bit, tức mịn hơn 2^4 = 16 lần. Độ chính xác giảm dần khi ra xa 1.0.

### 2.3 Độ rộng scale factor

```
SF_MAX = (NB-2) × 2^ES            // ES=3, NB=32: 240;  ES=2: 120
SF_W   = $clog2(4×SF_MAX + 4) + 1 // dư 1 bit an toàn cho adder; ES=3: 11 bit, ES=2: 10 bit
```

Tích hai posit có `sf ∈ [-2·SF_MAX, 2·SF_MAX+1]`.

### 2.4 Ví dụ giải mã (posit16, ES=2, để minh họa thuật toán tổng quát)

Chuỗi bit `0000 1101 1011 1011` (`0x0DBB`):

| Bước | Kết quả |
| --- | --- |
| Dấu | `s = 0` |
| Regime | `x[14:0] = 000110110111011`; bit đầu 0, có 3 số 0 rồi bit 1 nên `m=3`, `k=-3`, regime chiếm `m+1 = 4` bit |
| Dịch trái `m+1 = 4` bit | `10110111011 0000` |
| Exponent | 2 bit đầu `10` nên `e = 2` |
| Fraction | 9 bit kế tiếp `110111011` = 443 nên `1.f = 1 + 443/512 = 1.865234375` |
| Scale | `sf = 4×(-3) + 2 = -10` |
| Giá trị | `2^-10 × 1.865234375 ≈ 1.8215×10^-3` |

Số đối `-0x0DBB` là `0xF245` (bù hai). Parser thấy `s=1`, lấy bù hai trở lại `0x0DBB` rồi giải mã như trên và gắn dấu.

### 2.5 Ví dụ mã hóa và làm tròn RNE (posit8, ES=0)

Quy tắc: xây chuỗi `regime | exponent | fraction` đầy đủ, cắt tại bit thứ `NB-1`; **guard** = bit ngay sau điểm cắt, **sticky** = OR của mọi bit sau guard; làm tròn về chẵn (round-to-nearest-even) theo chuỗi bit; làm tròn trên độ lớn rồi mới bù hai nếu âm.

| TV | Giá trị vào | Phân tích | Kết quả mong đợi |
| --- | --- | --- | --- |
| TV-RND-00 | 0.1 = 1.6×2^-4 | `sf=-4`, `k=-4` → regime `00001`; còn 2 bit fraction: 0.6 = `.1001…` → `10`, guard = 0 | `0x06` (=0.09375) |
| TV-RND-01 | 1 + 2^-6 = 1.015625 | k=0 → regime `10`, 5 bit fraction `00000`, guard=1, sticky=0 → hòa, LSB chẵn nên giữ | `0x40` (=1.0) |
| TV-RND-02 | 1 + 3×2^-6 = 1.046875 | 5 bit fraction `00001`, guard=1, sticky=0 → hòa, LSB lẻ nên làm tròn lên | `0x42` (=1.0625) |
| TV-RND-03 | 100 | vượt `maxpos = 64` | `0x7F` (bão hòa) |
| TV-RND-04 | 0.001 | dưới `minpos = 2^-6` | `0x01` (không về 0) |

(Các giá trị mong đợi phải được xác nhận lại bằng SoftPosit ở tuần 2 và đưa vào regression như test cố định.)

---

## 3. Yêu cầu chức năng và phi chức năng

### 3.1 Chức năng (FR)

| ID | Ưu tiên | Yêu cầu |
| :--- | :---: | :--- |
| FR-01 | MUST | Tham số hóa `(NB, ES)`; cấu hình chuẩn ở §2.2 phải tổng hợp và kiểm chứng được |
| FR-02 | MUST | Xử lý Zero/NaR và giữ thứ tự theo §5.3. Đúng chức năng là MUST; bypass rút ngắn độ trễ và CE là tối ưu SHOULD sau Gate 3 |
| FR-03 | MUST | Parser giải mã đúng `(s, is_zero, is_nar, sf, frac)` với mọi chuỗi bit, gồm cả số âm và trường hợp regime chiếm hết `NB-1` bit |
| FR-04 | MUST | Packer làm tròn RNE, bão hòa về maxpos/minpos, không sinh NaR/zero từ phép toán khác NaR/zero (trừ khi hai số hạng triệt tiêu chính xác cho ra 0) |
| FR-05 | MUST | Multiplier `cfg_mode=0`, `EXACT_EN=1`, `ROUND_MODE="RNE"`: giữ toàn bộ fraction, chạy đến khi SAC hết bit 1, khớp `p<N>_mul` của L0 ở các cấu hình §6.2 |
| FR-06 | MUST | Multiplier chế độ **approx**: số vòng lặp tối đa `cfg_n` cấu hình lúc chạy; khớp L1 bit-exact |
| FR-07 | MUST | Dừng sớm (early termination) khi SAC không còn bit 1 trong fraction toán hạng X |
| FR-08 | SHOULD | OPS chọn toán hạng làm X: cố định A, hoặc chọn toán hạng có ít bit 1 hơn (popcount) theo `cfg_ops` |
| FR-09 | MUST | Adder khớp `p<N>_add` bit-exact (RNE) |
| FR-10 | MUST | MAC NF mới: D=R(R(P_hat)+C_eff); exact P_hat=A×B và khớp add(mul(a,b),C_eff) của oracle đúng format. Approx P_hat là tổng term FLOOR đã chốt, không ngầm thay bằng tích exact hoặc bits legacy |
| FR-11 | MUST (profile so sánh §11.8) | MAC fused v2: làm tròn một lần ở đầu ra (§5.12). Approx cửa sổ hữu hạn phải khớp L1; so L0 chỉ đánh giá sai số. Exact fused posit8/16 chỉ được tuyên bố khi giữ đủ tích và phần căn chỉnh để khớp `p<N>_mulAdd`; không suy ra exact từ `ACC_WIN` mặc định |
| FR-12 | SHOULD | `acc_mode=1` dùng trạng thái tích lũy làm C, bỏ qua c bên ngoài; làm tròn sau từng giao dịch, duy trì ngữ nghĩa NaR trong accumulator (mã Posit hoặc cờ tương đương, không bắt buộc FF acc_nar_q riêng). Thứ tự cập nhật và ngữ nghĩa `acc_clr` theo §4.2 |
| FR-13 | MUST | Giao tiếp valid/ready, chịu backpressure, độ trễ thay đổi theo `n` |
| FR-14 | SHOULD | Cờ trạng thái: `nar`, `sat_max`, `sat_min`, `inexact`, `approx_cut` (bị cắt do đạt `cfg_n`) |
| FR-15 | MUST | MAC top dùng rst_n đồng bộ tích cực thấp; reset bridge và startup barrier theo §4.2. Sau reset out_valid=0, không phát sinh X; leaf giữ hợp đồng reset riêng |
| FR-16 | SHOULD | Chồng lấn giao dịch sau Gate 3; mục tiêu II và điều kiện áp dụng ở §5.10-E, §5.11. Baseline xử lý từng giao dịch và luôn chịu được backpressure; II thực tế phải được đo |

### 3.2 Phi chức năng (NFR)

| ID | Yêu cầu | Tối thiểu | Mục tiêu | Xuất sắc |
| --- | --- | --- | --- | --- |
| NFR-01 | Chất lượng RTL | Verilator `-Wall` không cảnh báo nghiêm trọng, không latch | + Verible lint sạch | + CI tự chạy |
| NFR-02 | Tài nguyên khối nhân (ES=3, FRAC_W=12) | ≤ 1000 LUT | ≤ 800 LUT | ≤ 700 LUT (bằng [P]: 698) |
| NFR-03 | fmax khối nhân, post-route | ≥ 350 MHz | ≥ 450 MHz | ≥ 575 MHz (bằng [P]) |
| NFR-04 | fmax MAC top | ≥ 250 MHz | ≥ 350 MHz | ≥ 450 MHz |
| NFR-05 | DSP/BRAM | 0/0 | 0/0 | 0/0 |
| NFR-06 | Tái lập | Có Makefile | Một lệnh chạy hết | + ghi phiên bản công cụ vào log |

NFR02..04 là mục tiêu khảo sát ban đầu, chưa phải số đo hoặc thành tựu của RTL hiện tại; chốt cùng GVHD sau tổng hợp/P&R sơ bộ NF tuần12. Tối ưu pipeline ở tuần12–13, kiểm lại ở tuần14 và xác nhận post-route tuần15; tăng Fmax phải báo cả FF,latency,II/throughput. Ngưỡng tuyệt đối NFR-02..04 chỉ đối chiếu ở D0; NFR-02/03 có mốc tỉ lệ §7.6 cho nền tảng khác. NFR-04 chưa có baseline MAC tương đương để quy đổi, nên báo số đo và chốt mục tiêu riêng theo part đã chọn.

---

## 4. Tham số và giao diện

### 4.1 Tham số SystemVerilog

**Phân biệt giao diện đã có với tham số kiến trúc:** posit_mac_nf hiện chỉ expose NB,ES,FRAC_W,N_MAX,EXACT_EN,OPS_EN,N_W; default NB32/ES2 và FRAC_W=min(NB-3-ES,12). Profile chính32/3 phải đặt ES=3 tường minh. NF hardwire RNE/FLOOR; FUSED,ACC_WIN,ROUND_MODE,ROUND_SCHEME,PIPE_PARSE/PIPE_PACK trong bảng là hợp đồng thiết kế chung hoặc tham số của module khác, không phải mọi mục đều truyền được vào top NF. Top fused hiện có là posit_mac_f, expose NB,ES,FRAC_W,N_MAX,EXACT_EN,OPS_EN,ACC_WIN,N_W; chỉ nhận profile32/3,FW12,W32,EXACT_EN0,OPS_EN1,N_MAX8,N_W4. Parameter khác bị elaboration fatal; không có tùy chọn FUSED=1 trong posit_mac_nf.

Phạm vi NF đã kiểm: bốn tuple ở §2.2,F=NB-3-ES>=2,FRAC_W=min(F,12),N_MAX8,EXACT_EN=OPS_EN=1. Feature-disable,độ rộng/tuple khác cần nghiệm thu riêng. Điều kiện rộng NB>=4,ES<=NB-4 của parser không tự chứng minh mọi cấu hình đó dùng được với adder hoặc NF.

| Tham số | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `NB` | 32 | Độ rộng tổng thể của số Posit (bitwidth) |
| `ES` | 2 | Số bit exponent tối đa (exponent size) |
| `FRAC_MAX` | tính | Số bit fraction tối đa `= NB - 3 - ES` (27 cho posit32 ES=2, 26 cho ES=3, 12 cho posit16, 5 cho posit8) |
| `FRAC_W` | NF: min(FRAC_MAX,12) | Độ rộng fraction SBM ở chế độ xấp xỉ; bằng12 cho profile32/3 và bằng5 cho8/0 |
| `EXACT_EN` | 1 | Bật khả năng chạy exact; chế độ từng giao dịch do `cfg_mode` chọn. Exact: `ACC_W = 2×FRAC_MAX + 2`. Approx vẫn dùng độ rộng/chính sách §5.6 dù `EXACT_EN=1` |
| `N_MAX` | 8 | Giá trị lớn nhất của `cfg_n` (quyết định độ rộng bộ đếm lặp) |
| `OPS_EN` | 1 | Bật khối chọn toán hạng (Operand Selector) |
| `FUSED` | 0 | 0: MAC v1 (làm tròn 2 lần). 1: kiến trúc v2 theo §5.12: cộng C_eff sau prepack,round cuối một lần; RTL posit_mac_f riêng đã triển khai profile§11.15; không truyền FUSED=1 vào top NF |
| `ACC_WIN` | 32 ở profile F32/3,FW12 | W32 gồm1 bit dấu,2 bit nguyên magnitude và Q29 bit fraction,miền có dấu[-4,4) theo anchor đã chuẩn hóa. Residual sign/nonzero và flags nằm ngoài W. Chỉ profile approx đã kiểm; không dùng32 bit để tuyên bố FMA exact từ A×B hoặc hỗ trợ mọi NB/ES |
| `ROUND_MODE` | `"RNE"` | Quy ước làm tròn tại Packer/round_unpacked: `"RNE"` theo FloPoCo/SoftPosit; `"TRUNC"` cắt cụt theo [P] |
| `ROUND_SCHEME` | 0 | Cơ chế xử lý bit khi dịch phải trong bộ nhân lặp SBM theo [15]: `0: FLOOR` (cắt bỏ hoàn toàn bit rơi ra ngoài); `1: STICKY_ACC` (gom bit rơi vào cờ `sticky_acc`) |
| `PIPE_PARSE` | 2 | Số tầng pipeline của parser. Hai hạng thanh ghi: sau XOR + detector/count và sau bộ dịch; ranh giới dữ liệu giữ như Fig. 5(a) |
| `PIPE_PACK` | 1 nếu ROUND_MODE="TRUNC", 2 nếu "RNE" | Baseline TRUNC một hạng; RNE hai hạng elastic: P1 mã hóa/dịch/G-R-S, P2 làm tròn/carry/dấu theo §5.9-D. Timing cần xác nhận STA |
| `SF_W` | tính | Độ rộng Scale Factor theo §2.3: `$clog2(4×SF_MAX + 4) + 1` |

Ràng buộc IP: `NB >= 4`, `0 <= ES <= NB-4`, `1 <= FRAC_W <= FRAC_MAX`, `N_MAX >= 1`; điểm quét không thỏa phải loại và ghi lý do. RTL parser hiện giới hạn `NB<=32`; phạm vi đã nghiệm thu theo §5.2. `cfg_mode=0` chỉ hợp lệ khi `EXACT_EN=1`; `cfg_n` bị kiểm giới hạn [0,N_MAX] khi cfg_mode=1; n=0 chỉ hidden. Khi cfg_mode=0, RTL bỏ qua cfg_n và dùng FRAC_MAX làm giới hạn fraction. Ma trận nghiệm thu hiện vẫn cấp n0..8; không tuyên bố đã kiểm mọi mã cfg_n cao hơn trong exact. Bộ đếm exact phải biểu diễn đến `FRAC_MAX` dù `N_MAX` nhỏ hơn. `OPS_EN=0` chỉ nhận cfg_ops=0 và buộc X=A; top từ chối cfg_ops=1 khi tắt OPS. cfg_ops=2,3 chưa hỗ trợ, top giữ in_ready=0; TB phải kiểm các request bị từ chối. Các biến thể TRUNC không thuộc nghiệm thu exact↔SoftPosit RNE. `PIPE_PARSE/PIPE_PACK` mô tả cấu hình kiến trúc mục tiêu; parser RTL hiện cố định hai tầng, chưa có lựa chọn số tầng tùy ý.

**Phân biệt rõ ràng giữa hai tham số làm tròn (`ROUND_SCHEME` vs. `ROUND_MODE`)**:

- **`ROUND_SCHEME` (Nội bộ bên trong bộ nhân lặp SBM, §5.6)**: Quy định xử lý đuôi mantissa $1.f_Y$ sau dịch phải $S$ ở từng vòng. FLOOR cắt term về FRAC_W bit phân số. STICKY_ACC giữ thêm G/R và OR phần thấp hơn vào `sticky_acc` (§5.6); cờ này chỉ báo có bit bị mất, không bảo toàn độ lớn tổng phần dư hoặc carry qua nhiều term. Đây vẫn là chính sách xấp xỉ. NF hiện hardwire FLOOR.
- **`ROUND_MODE` (Khâu đóng gói cuối cùng Packer & `round_unpacked`, §5.9)**: Quy định thuật toán làm tròn kết quả số học hoàn chỉnh sang chuỗi bit Posit chuẩn. Nếu `ROUND_MODE = "RNE"` (mặc định), áp dụng thuật toán Round-to-Nearest-Even phỏng theo [F], được kiểm chứng với SoftPosit; nếu `ROUND_MODE = "TRUNC"`, cắt độ lớn theo hợp đồng local/research. Chọn TRUNC không tự chứng minh tái hiện số liệu hay RTL của [P]. NF tuần11 chỉ hỗ trợ RNE.

### 4.2 Cổng

| Tín hiệu | Hướng | Độ rộng | Mô tả |
| --- | --- | --- | --- |
| `clk` | in | 1 | Xung nhịp |
| `rst_n` | in | 1 | Reset đồng bộ, tích cực thấp |
| `in_valid` / `in_ready` | in / out | 1 | Bắt tay đầu vào |
| `a`, `b` | in | NB | Hai thừa số |
| `c` | in | NB | Số hạng cộng (bỏ qua nếu `acc_mode=1`) |
| `acc_mode`, `acc_clr` | in | 1, 1 | Chế độ tích lũy |
| `cfg_mode` | in | 1 | 0: exact; 1: approx |
| `cfg_n` | in | max(1,$clog2(N_MAX+1)) | Giới hạn fraction khi cfg_mode=1; exact bỏ qua, hidden khởi tạo riêng |
| `cfg_ops` | in | 2 | Chính sách OPS |
| `out_valid` / `out_ready` | out / in | 1 | Bắt tay đầu ra |
| `d` | out | NB | Kết quả |
| `flags` | out | 5 | `{nar, sat_max, sat_min, inexact, approx_cut}` |

**Giao thức và cơ chế Backpressure**:

- Bắt tay chuẩn `valid && ready`. Khi giao dịch hoàn tất, `out_valid` được kéo lên. Nếu `!out_ready` (downstream consumer bận), mạch phải giữ nguyên dữ liệu ngõ ra `d` và `flags` không đổi cho đến khi `out_ready=1`.
- **Sức chứa đầu ra:** baseline giữ một giao dịch và hạ in_ready khi chưa có chỗ. Nếu chồng lấn, dùng cơ chế dự trữ slot/credit theo §5.11-A; skid buffer là một phần sức chứa, không thay cho kiểm soát tất cả kết quả đang bay.
- Cấu hình (`cfg_*`) được chốt tại thời điểm handshake ngõ vào (`in_valid && in_ready`) và cố định trong toàn bộ chu trình xử lý của giao dịch đó. Đầu ra trả kết quả tuần tự theo đúng thứ tự nạp vào (in-order).

- `acc_mode` và `acc_clr` được chốt cùng giao dịch. `acc_clr=1` chỉ hợp lệ khi `acc_mode=1`: xóa trạng thái tích lũy trước khi tính giao dịch đó, nên C hiệu dụng bằng 0. Khi stalled ở đầu vào, tín hiệu này không gây xóa độc lập. Reset hủy mọi giao dịch đang chờ và xóa accumulator/NaR.
- Trạng thái tích lũy cập nhật một lần khi kết quả đã được chốt vào nơi lưu đầu ra, không cập nhật lặp theo `out_valid`. Giao dịch sau phải dùng trạng thái của giao dịch tích lũy trước; không cho đọc một C cũ khi các giao dịch chồng lấn.
- `flags[4:0]={nar,sat_max,sat_min,inexact,approx_cut}`; NaR ưu tiên và xóa bốn cờ còn lại. `sat_max/min` báo kẹp kết quả hữu hạn vượt dải; `inexact` báo phần dư/làm tròn bị mất; `approx_cut` báo còn bit 1 sau giới hạn n. Chỉ cắt fraction về FRAC_W có thể làm `inexact=1` dù `approx_cut=0`.
- Trong v0/v1, bốn cờ số học được OR qua bước nhân/làm tròn tích và bước cộng/đóng gói tổng; vì vậy cờ bão hòa có thể phản ánh tích trung gian dù kết quả cuối không ở biên. Bypass không thực hiện số học thì bốn cờ bằng 0.
- Cấu hình reserved/không hợp lệ bị từ chối bằng in_ready=0; không tạo giao dịch hoặc tự xuất NaR cho request đó. Người gửi phải cung cấp cấu hình hợp lệ để handshake.
- Top hiện là MAC; multiplier standalone là module/harness riêng. Trong MAC, đặt C=0 không thay thế hoàn toàn giao diện multiplier vì NaR và cờ vẫn xử lý theo ngữ cảnh giao dịch.

**Reset bridge của RTL tích hợp (standalone multiplier và MAC NF đã triển khai; hợp đồng NF hiện thực tại §11.10):** rst_n ở top chỉ được lấy mẫu tại cạnh clk. Một thanh ghi reset bridge nhận 0 khi rst_n=0 và 1 khi rst_n=1; ngõ ra thanh ghi này cấp cùng nguồn reset_n cho các leaf có assert bất đồng bộ/deassert đồng bộ. Không nối trực tiếp rst_n đồng bộ vào chân reset bất đồng bộ của leaf. Khi top lấy mẫu reset=0, top flush valid, pending, credit, metadata và accumulator; leaf được assert sau cạnh đó. Không có handshake hợp lệ tại cạnh reset.

Sau nhả reset, startup barrier giữ in_ready=out_valid=0 cho đến khi tất cả leaf đã nhả reset; phải tính cả cạnh bridge nhả và hai FF của leaf, không mặc định toàn MAC chỉ chờ hai cạnh như parser đơn vị. Barrier dùng các trạng thái init_done hoặc bộ đếm startup bảo thủ phù hợp số tầng reset của mọi leaf; điều kiện và số cạnh thực tế phải được TB kiểm trước Gate3. A/B/C chỉ nhận đồng thời khi cả ba parser sẵn sàng và top có slot: top_in_ready=run_ready && slot_free && ready_A && ready_B && ready_C; valid vào mỗi parser chỉ phát cùng một handshake top. Reset lúc rỗng/đang tính/đang stall phải hủy giao dịch cũ và không được xuất lại kết quả trước reset.

---

## 5. Vi kiến trúc

### 5.1 Tổng quan luồng dữ liệu (dạng bảng)

| Tầng | Khối | Vai trò | Chu kỳ mục tiêu |
| --- | --- | --- | --- |
| P | `posit_parser` × 3 (A, B, C) | Bù hai theo dấu, LOD/LZD, dịch, tách `(s, sf, frac)` (`PIPE_PARSE = 2`) | 2 |
| M0 | `ops_sel_comb` + context trong core/wrapper | Chọn X (điều khiển vòng lặp) và Y (bị dịch); cộng `sf`, xor dấu | 1 |
| M1..Mq+2 | `iter_ctrl`/`sac_step_comb` → `sbm_shift_comb` → `sbm_accum` | Ba tầng SAC → Shifter → Accumulator, token khởi tạo khi n=0; q=max(1,n) | q+2 |
| MN/P1 | `mul_prepack_norm_comb` + product `posit_pack_prepare` | Chuẩn hóa bảo toàn prepack, mã hóa và G/R/S; chốt P1 | 1 |
| MP2 | Product `posit_pack_finish` | Quyết định RNE, cộng làm tròn/dấu; chốt packed product và flags | 1 |
| MR | `posit_parser_comb` | Parse tích đã làm tròn; chốt product unpacked/flags | 1 |
| A1 | `posit_add` (Stage 1) | So sánh $sf$, hoán đổi toán hạng, tính $\Delta sf$ (kẹp cứng $\le \text{FRAC\_MAX}+2$) và Alignment Shifter | 1 |
| A2 | `posit_add` (Stage 2) | Cộng/trừ số học mantissa ($m_1 \pm m_2$), xử lý dấu và bit nhớ | 1 |
| A3 | `posit_add` (Stage 3) | LZC (Leading Zero Counter), Normalization Shifter và cập nhật scale factor | 1 |
| K | `posit_pack` | Chèn regime, dịch, làm tròn RNE, bù hai (`PIPE_PACK = 1 hoặc 2 tùy ROUND_MODE`) | 1 hoặc 2 |

Quy ước duy nhất: E0 là cạnh handshake đầu vào. `L_valid` là số khoảng clock từ E0 đến cạnh sau đó dữ liệu và out_valid xuất hiện; `L_handshake` là số khoảng clock đến handshake đầu ra đầu tiên, khi out_ready luôn bằng 1. Với chuỗi H hạng thanh ghi cập nhật bằng non-blocking, không có bubble điều khiển: `L_valid=H-1`, `L_handshake=H`. Tầng sau nhận dữ liệu ở cạnh kế tiếp, không nhận giá trị vừa chốt ở cùng cạnh. Stall và startup reset được báo cáo riêng. INIT/ITER/DONE chỉ thêm latency nếu thực sự tạo bubble.

Bảng dưới là **ngân sách H theo lịch mục tiêu**, không phải số đo RTL hoặc trực tiếp là L_valid. Với baseline v0/v1, gọi n là số hạng fraction thực tế và `q=max(1,n)`; token khởi tạo cho n=0 vẫn đi qua ba tầng core (§5.5). Với n>=1, các công thức q+... giữ nguyên ngân sách n+... trước đây.

| Đường dữ liệu | Ngữ nghĩa | H, TRUNC (PIPE_PACK=1) | H, RNE (PIPE_PACK=2) |
| --- | --- | --- | --- |
| Multiplier | parse → OPS → core → norm/pack | q+6 | q+7 |
| MAC v0 | mul → pack → parse → add → pack | q+12 | q+14 |
| MAC v1 | core → norm/product P1 → P2 → parse → add → pack | Chưa hỗ trợ ở top hiện hành | q+13 |
| MAC v2 (profile chính32/3 đã kiểm) | core prepack → F1..F5 → pack | Chưa hỗ trợ trong profile chính | q+12, kiểm tại §11.15 |

Multiplier giữ lịch riêng. NF hiện hành OPT-03 dùng RNE tại cả tích và tổng: H=q+13, L_valid=q+12, L_handshake=q+13, II_min=q+14. Ví dụ t=2: first-valid sau E14, handshake E15, nhận mới sớm nhất E16. q=max(1,t), t là số vòng thực tế kể cả early-stop; special/init-only dùng q=1. Lịch cũ W11 q+10/q+11/q+12 giữ trong bằng chứng lịch sử §11.10, không áp dụng top mới. Các dòng v0/TRUNC là ngân sách chưa có top tương ứng. F giữ H=q+12 và valid=q+11 (§11.15).

**Ngữ nghĩa:** v0/v1 đều làm tròn tích trước khi cộng; v1 bảo đảm round_unpacked tương đương (§5.9-C); OPT-03 hiện thực pack pipeline rồi parse tổ hợp. V2 làm tròn một lần nhưng cửa sổ approx vẫn có sai số cắt/căn chỉnh (§5.12). Chỉ đường exact/RNE đáp ứng các điều kiện độ rộng mới được yêu cầu khớp SoftPosit. Độ trễ bypass được quy định ở §5.3.

### 5.2 Parser (`posit_parser`)

Ngõ vào `p[NB-1:0]`; ngõ ra `s`, `is_zero`, `is_nar`, `sf[SF_W-1:0]`, `frac[FRAC_MAX-1:0]` (căn MSB, không chứa hidden bit).

**Hợp đồng parser tổ hợp chốt ngày 05/10/2026:** `rtl/parser/posit_parser_comb.sv` không có clock/reset/handshake; đầu ra có hiệu lực sau khi logic tổ hợp ổn định với đầu vào nhị phân đã biết. `s=p[NB-1]`; `sf` là vector **signed**, rộng theo §2.3; `FRAC_MAX=NB-3-ES` và fraction thiếu bit đệm 0 phía LSB. Zero trả `(s,is_zero,is_nar,sf,frac)=(0,1,0,0,0)`; NaR trả `(1,0,1,0,0)`. Đầu ra giữ toàn bộ fraction, chưa cắt về `FRAC_W`; hidden bit được khôi phục ở khối số học khi toán hạng hữu hạn khác 0. Đối chiếu L1 bằng `frac_RTL=(frac_L1 >> (63-FRAC_MAX)) & ((1ULL<<FRAC_MAX)-1)`.

Phạm vi module hiện tại: `4<=NB<=32`, `0<=ES<=NB-4` để có ít nhất một bit fraction, phù hợp ràng buộc `FRAC_W>=1` của IP. Không hỗ trợ ghi đè `FRAC_MAX` khác công thức; `SF_W` phải đủ chứa `Rgm` ghép exponent. Biểu thức tính độ rộng dùng hằng 64-bit để tránh tràn tại elaboration. Phạm vi nghiệm thu hiện tại là `(NB,ES)=(8,0),(16,1),(32,2),(32,3)`; các cấu hình khác cần kiểm thêm trước khi dùng. `PIPE_PARSE=2` là số hạng của parser pipeline hiện tại, không phải latency của module tổ hợp.

**Hợp đồng pipeline `rtl/parser/posit_parser.sv`:** hai tầng elastic, hai slot lưu giao dịch. P1 chốt dấu, cờ, `cnt`, bit regime đầu `r` và payload seed sau chọn regime; P2 tạo `Rgm=k` từ `cnt/r` song song với dịch payload, tách exponent/fraction, ghép scale factor rồi chốt đầu ra. Không cần chốt thêm vector `k` trong P1, theo Fig.5(a). Với NB32, phần trạng thái regime giảm từ `cnt5+k6=11` bit xuống `cnt5+r1=6` bit trong RTL. Chỉ nhận dữ liệu khi `in_valid && in_ready`; nguồn giữ `p` và `in_valid` trong lúc bị chặn. Khi `out_valid && !out_ready`, toàn bộ dấu/cờ/sf/fraction và `out_valid` giữ nguyên. Hai tầng có enable độc lập; có thể nhận và trả một giao dịch đồng thời, luôn theo thứ tự. Dữ liệu khi `out_valid=0` không mang ý nghĩa giao dịch, nhưng vẫn là giá trị xác định sau reset.

Parser dùng cổng reset cục bộ `reset_n` theo Digital Design Guidelines: assert bất đồng bộ, deassert qua hai flip-flop trên `clk`; `in_ready=out_valid=0` trong reset/startup. Reset xóa toàn bộ dữ liệu/cờ và hủy các giao dịch còn trong hai slot. Khi tích hợp, dùng reset bridge và startup barrier §4.2; không thay reset leaf đã kiểm chứng. Chờ hai cạnh từ lúc reset_n cục bộ nhả để synchronizer nhả reset không tính vào latency dữ liệu. Mọi bank dữ liệu đều dùng cùng reset đã đồng bộ, không chia cờ và datapath sang các miền reset khác nhau.

**Quy ước đếm chu kỳ:** gọi cạnh nhận đầu vào là E0. P1 chốt tại E0, P2 chốt và `out_valid` lên sau E1; handshake đầu ra sớm nhất tại E2. Vì vậy có hai hạng thanh ghi, khoảng cách input/output handshake không stall là hai chu kỳ, còn từ cạnh nhận đầu vào đến cạnh bắt đầu valid là một chu kỳ. `II=1` khi không stall. Quy ước này làm rõ mục tiêu hai tầng ở §5.1; không cộng một tầng chỉ để làm số chu kỳ từ E0 đến valid bằng 2. Khi ghép MAC phải dùng lịch cạnh thực tế thay vì cộng latency theo hai quy ước khác nhau.

**Hiện thực parser tiết kiệm diện tích — 16/10/2026:** cả tổ hợp và pipeline chia sẻ một detector LOD sau XOR theo `r`, thay cho hai cây LOD/LZD và MUX chọn count. Đây là chia sẻ tổ hợp, không dùng luân phiên theo clock và không thêm tầng. Chỉ XOR tail sau FRB; payload seed luôn lấy từ magnitude gốc. Giữ `cnt=NB-2` khi không có terminator, canonical Zero/NaR, scale signed, enable/reset và lịch cạnh ở trên. Sinh viên chấp nhận đánh đổi timing P1 để ưu tiên diện tích; mức giảm LUT và thay đổi STA phải đo theo PLAN§8.19, không mặc định giảm một nửa parser. Kiểm 0/1 và smoke mới có bằng chứng riêng; các checkpoint NF/F trước đó vẫn gắn với hash nguồn cũ. Phiên bản hợp đồng số học vẫn v1.18 vì không đổi giao diện hoặc ngữ nghĩa.

Thuật toán Parser (theo Fig. 5a của [P], tối ưu bỏ bước cộng +1 trong lượng dịch):

1. `s = p[NB-1]`; `t1 = s ? (~p + 1) : p` (XOR + bộ cộng bù hai, như [P] Fig. 5a).
   - **Nhận diện 2 giá trị đặc biệt**:
     - Số 0: `is_zero = (p == {NB{1'b0}})`
     - NaR (Not-a-Real): `is_nar = (p[NB-1] == 1'b1) && (p[NB-2:0] == {(NB-1){1'b0}})`
2. `r = t1[NB-2]`                               // bit regime đầu
3. `terminator_bits = t1[NB-3:0] ^ {(NB-2){r}}`; dùng duy nhất một `lod_lzd_core`, `MODE=0`, `N=NB-2`.
   `cnt = terminator_valid ? terminator_count : NB-2`      // đếm sau FRB; r=0 tìm 1, r=1 tìm 0 qua XOR
                                                      // cnt ∈ [0, NB-2], rộng $clog2(NB-1) bit
                                                      // nếu cả chuỗi giống nhau (không có bit kết thúc): cnt = NB-2
                                                      // vld=0 của detector: thay K=0 bằng cnt=NB-2
4. `Rgm = ~({1'b0, cnt} ^ {($clog2(NB-1)+1){r}})`    // XNOR, Rgm rộng $clog2(NB-1)+1 bit, bù hai
                                                      // r=1: k = cnt;  r=0: k = ~cnt = -(cnt+1) = -m
5. `t2 = t1[NB-4:0] << cnt`                           // vector NB-3 bit như t1[28:0] trong Fig. 5(a)
                                                      // bỏ FRB và một bit kế; dịch cnt đưa hết regime/terminator ra ngoài
6. `e = t2[NB-4 -: ES]`; `frac = t2[NB-4-ES -: FRAC_MAX]`
                                                      // ES=0: không tạo part-select độ rộng 0; frac=t2
7. `sf = k * (1 << ES) + e`                           // RTL có thể ghép {Rgm,e} rồi sign-extend

Zero/NaR được xử lý riêng trước các bước 2–7. Exponent/fraction thiếu bit được đệm 0 ở phía thấp; regime toàn 1 không có terminator vẫn phải giải mã maxpos đúng. Tầng pipeline sau mux regime theo Fig. 5(a), PIPE_PARSE=2. Có thể dùng cách dễ kiểm chứng hơn: bỏ FRB, dịch cnt, rồi bỏ terminator bằng một phép dịch cố định thêm 1; hai cách phải cho cùng payload. Trong C++ không dịch trái một số k âm; dùng phép nhân số nguyên có dấu ở bước 7.

Ở chế độ approx, `frac` được rút về `FRAC_W` bit MSB (cắt bỏ phần thấp), hoặc chèn thêm 0 nếu ngắn hơn, theo [P] Fig. 2 và §III-B.

### 5.3 Giá trị đặc biệt và bypass

C_eff=c khi acc_mode0,accumulator khi acc_mode1,0 khi acc_clr của giao dịch được nhận (§4.2). NaR ưu tiên Zero; xét C_eff, không xét c bên ngoài bị bỏ qua trong acc_mode.

| Điều kiện | Kết quả bắt buộc | Hiện thực NF tuần11 |
| --- | --- | --- |
| A/B/C_eff là NaR | d=NaR,flags10000 | Mask x/y core, phát token init_only; vẫn đi qua các bank, không có bypass rút ngắn |
| A=0 hoặc B=0, không NaR | d=C_eff,flags0 | ProductZero qua adder/packer, bảo toàn C_eff |
| C_eff=0, tích hữu hạn khác0 | d=R(P_hat),giữ flags của tích | Adder vẫn nhận operandZero; không bỏ ba tầng adder trong top hiện tại |
| Hai operand cộng triệt tiêu | d=0; không tạo sat_min vì triệt tiêu | NF xét R(P_hat)+C_eff. Approx không chứng minh A×B+C_eff thật bằng0 |

Giá trị ngoại lệ đúng là MUST; ngừng hoạt động datapath hoặc bypass rút ngắn là tối ưu SHOULD sau baseline, không phải điều kiện value của FR02. Khi bypass được triển khai phải chốt lịch/token,giữ thứ tự và regression. Ngân sách khảo sát riêng: dùng trực tiếp bank parser có H2/validE1/handshakeE2; bypass C_eff0 bỏ adder có thể giảm3 hạng. Chưa dùng ngân sách đó làm latency đo của NF hiện tại.

Khi chồng lấn, bypass phải tuân thứ tự FIFO/tag; CE chỉ ngừng bank không còn token. Packer cuối vẫn phải giữ d/flags khi out_ready0.

### 5.4 OPS (`ops_sel`)

- `cfg_ops=0`: X = A, Y = B.
- `cfg_ops=1`: X là toán hạng có popcount fraction ít hơn, hòa chọn A; đếm trên fraction thực tế dùng trong chế độ hiện tại (FRAC_W với approx, FRAC_MAX với exact). Giảm vòng lặp không tự bảo đảm cùng sai số ở một n cho mọi đầu vào.
- `cfg_ops=2..3`: dành cho các chính sách khác lấy từ [15] (rounding scheme, operand selection); nếu chưa cài thì để cấm (assert).

Ngoài ra OPS thực hiện: `sign_o = sA ^ sB`; `sf_o = sfA + sfB`.

**Giao diện tổ hợp tuần9:** `ops_sel_comb` nhận fraction parser không hidden, rộng FRAC_MAX; ở approx lấy FRAC_W bit cao trước popcount. `x_frac` được căn phải, không hidden; `y_mant` căn phải trên Q(W_X), hidden nằm ở bit W_X. `active_width=W_X`. Input bị bỏ bit thấp đặt `input_cut`, không đưa cờ này vào sticky số học. `cfg_error` báo cfg_ops reserved, exact khi EXACT_EN=0 hoặc cfg_ops khác0 khi OPS_EN=0; bundle dữ liệu về0 và wrapper/TB phải từ chối cấu hình này. Khi OPS_EN=0, cấu hình hợp lệ cfg_ops=0 luôn giữ X=A, đồng nhất API L1. Zero/NaR được wrapper xử lý trước đường finite này.


**Refactor14/10/2026:** nhánh control giữ prefix FRAC_W ở vị trí gốc; các bit thấp AND với !cfg_mode rồi vào cây popcount. Popcount không phụ thuộc vị trí bit nên choose_b/tie-A giữ nguyên. Nhánh dữ liệu chuẩn bị độc lập X_A/X_B căn phải không hidden và Y_A/Y_B căn phải có hidden; chỉ chọn hai bus bằng một tầng Swap MUX cuối. cfg_error xóa các ứng viên trước swap; metadata swapped được tách khỏi block chuẩn bị dữ liệu. discarded dùng Reduction OR,generate no-cut trả0 khi FRAC_W=FRAC_MAX. Không thêm clock/FF/latency trong ops_sel_comb; M0/core launch vẫn giữ nguyên. Đây là hợp đồng 0/1 ở interface; không cam kết cách xử lý cfg_mode X/Z. Bằng chứng refactor/timing tại §11.13.

### 5.5 SAC (`sac`) và bộ điều khiển lặp

Trạng thái: thanh ghi fx chứa fraction X sau hidden bit, rộng W_X=FRAC_W ở approx và FRAC_MAX ở exact; tổng dịch S và bộ đếm i phải đủ cho W_X. Không dùng thanh ghi FRAC_W để cắt đường exact.

Mỗi chu kỳ, nếu `fx ≠ 0` và `i < n_lim`:

```
sa    = clz(fx) + 1        // vị trí bit 1 đầu tiên sau dấu chấm (1-indexed)
S     = S + sa             // tổng dịch lũy kế
fx    = fx << sa           // loại bit 1 vừa xử lý cùng các bit 0 đứng trước
i     = i + 1
```

`n_lim = cfg_mode ? cfg_n : FRAC_MAX`. Kết thúc khi `fx == 0` (hết fraction đang dùng) hoặc `i == n_lim` (cắt xấp xỉ, đặt cờ `approx_cut` nếu `fx ≠ 0`).

Số vòng lặp thực tế = `min(popcount(fx_ban_dau), n_lim)`, tức số bit 1 của fraction X **không tính hidden bit**. Hết bit X chỉ chứng minh không còn số hạng fraction; approx vẫn có thể sai do cắt Y/số hạng.

**Profile RTL baseline đã chốt:** v0/v1 dùng hợp đồng L1 normative tại §5.4–§5.6: cfg_ops=0/1, hidden bit khởi tạo riêng, cfg_n chỉ đếm số hạng fraction, width/cut theo §5.6. `paper_source_config` và predictor n=2/7-bit là profile nghiên cứu riêng; chưa thay mặc định RTL. Với cùng chuỗi khai triển, `n_terms=n_fraction+1` chỉ là ánh xạ bộ đếm; không bảo đảm cùng kết quả giữa thuật toán RND/complement và thuật toán normative. Test Table I phải ghi đúng tên profile, không dùng source Table I để nghiệm thu cfg_ops normative.

**Lịch core baseline không chồng lấn — đã triển khai và kiểm đơn vị 09/10/2026:** L0 là cạnh OPS chốt X/Y/config và phát launch. Core không stall sau launch; top dự trữ một slot kết quả và chưa nhận giao dịch khác đến khi giao dịch hiện tại đã trả đầu ra. Token có valid/first/last/init_only; metadata giữ trong thanh ghi giao dịch.

| n thực tế | SAC | Shifter | Accumulator / core_done |
| --- | --- | --- | --- |
| 0 (cfg_n=0 hoặc fx=0) | L1 phát token init_only, first=last=1 | L2 truyền token | L3 nạp Y đúng một lần, không cộng thêm Y; done sau L3 |
| 1 | L1 phát số hạng fraction thứ nhất, first=last=1 | L2 dịch Y theo S1 | L3 chốt Y+(Y>>S1); done sau L3 |
| 2 | L1/L2 phát hai token, first ở L1, last ở L2 | L2/L3 dịch | L3 chốt Y+term1, L4 chốt acc+term2; done sau L4 |
| n>=1 | L1..Ln phát mỗi cạnh một token | L2..L(n+1) | L3..L(n+2); done chỉ sau token last được chốt |

SAC xác định last từ fx kế tiếp bằng 0 hoặc đạt n_lim, không chờ thêm một chu kỳ FSM. Dừng sớm ngừng phát token mới nhưng vẫn xả hai tầng; done không được phát ngay tại SAC. Cắt n đặt approx_cut nếu fraction còn bit 1; n=0 dùng cùng quy tắc. Lịch này đã kiểm core/standalone và được dùng trong NF W11; các tối ưu chồng lấn vẫn cần lịch/test riêng. Chồng lấn, credit và II tối ưu chỉ bổ sung sau baseline.

- **Sketch stream cho fused, chưa chốt/triển khai:** chỉ áp dụng nếu chọn stream term vào C và chứng minh cùng P_hat. Đường F software hiện tại cộng C với prepack sau nhân, không yêu cầu sửa SAC:
   - Tại vòng 0, SAC phát số hạng tương ứng với hidden bit của $X$ ($1.0 \times Y$) với độ dịch nội tại $sa = 0$, sau đó quét fraction ở các vòng i=1..n. n_lim vẫn chỉ đếm fraction. Quy ước đếm này không tự chứng minh tái hiện Table I của [P]; fused và profile paper phải kiểm riêng.
  - Bổ sung đầu ra `shift_extra = max(0, -ΔSF)` (với $\Delta SF = sf_P - sf_C$) để cộng trực tiếp vào tổng lượng dịch $S$ ($S' = S + \text{shift\_extra}$) nhằm căn chỉnh độ lớn các số hạng của tích khi $C$ đóng vai trò làm mốc scale factor (xem chi tiết tại §5.12).
  - V2 giữ vòng hidden bit riêng; các thay đổi ghép số hạng cần đo timing và cập nhật lịch trước khi áp dụng.

> **Phân tầng:** mô tả vòng lặp là mô hình hành vi. Lịch baseline v0/v1 chọn SAC → Shifter → Accumulator, từ launch L0 đến core_done sau L(q+2), q=max(1,n). V2 và chồng lấn cần lịch riêng; không suy ra đã hỗ trợ chồng lấn chỉ từ Fig.3.

#### 5.5-A. Hợp đồng triển khai tuần9 — 08/10/2026

Đây là giao diện triển khai profile normative, không chọn paper RND/complement làm mặc định. Giao diện thanh ghi/token bên dưới đã chốt và đã có RTL đến multiplier standalone; Gate2 đã nghiệm thu10/10 theo PLAN7.11. Mô tả này thuộc core legacy/normative; adapter đầu ra NF mới ở §5.7/§11.10.

| Bundle / tín hiệu | Độ rộng / nội dung | Quy tắc |
| --- | --- | --- |
| Context tại launch L0 | x_frac[FRAC_MAX-1:0], y_mant[FRAC_MAX:0], active_width, sign_o, sf_o, cfg_mode, cfg_n, cfg_ops, input_cut | Chốt nguyên tử từ OPS tổ hợp; giữ đến khi trả giao dịch. Bank M0 chính là bank context, không thêm bank chốt OPS rồi chốt lại context |
| W_X | FRAC_MAX exact; FRAC_W approx | x_frac căn phải; đường exact không đi qua thanh ghi FRAC_W |
| WIDTH_W / S_W | max(1,$clog2(FRAC_MAX+1)) | Biểu diễn W_X và S tới FRAC_MAX, gồm phép dịch bằng đúng chiều rộng |
| N_W | max(1,$clog2(N_MAX+1)) | cfg_n chỉ giới hạn fraction ở approx; hidden riêng |
| I_W | max(1,$clog2(max(FRAC_MAX,N_MAX)+1)) | i exact đếm tới FRAC_MAX, không bị cắt bởi N_MAX |
| SAC token L1 | valid, first, last, init_only, scale[S_W-1:0], iteration[I_W-1:0], approx_cut | last quyết định từ fx_next/limit; init_only có iteration=0, scale=0, first=last=1 |
| Shifter token L2 | Giữ valid/first/last/init_only/iteration/approx_cut; thêm term và term_tail | term là độ lớn không dấu; Y bất biến trong context; init_only không tạo term cộng |
| Accumulator L3 | acc, sticky_acc, numerical_tail, iterations_done, approx_cut | first nạp Y trước cộng term; init_only chỉ nạp Y. last commit mới phát core_done |
| approx accumulator | FRAC_W+4 bit, Q(FRAC_W+2) vật lý | FLOOR đặt hai bit thấp0 sau mỗi cut term; STICKY_ACC giữ G/R và OR đuôi riêng |
| exact accumulator | 2*FRAC_MAX+2 bit, Q(2*FRAC_MAX) | Không cắt term, không mất bit trước normalize/packer |
| Port acc chung | max(FRAC_W+4,2*FRAC_MAX+2) nếu EXACT_EN; ngược lại FRAC_W+4 | Zero-extend payload, không thay đơn vị lưới. Nếu dùng hai bank, mux ở cuối; chi phí cần tổng hợp |

`sac_step_comb` có tham số W_X cố định; core chọn leaf FRAC_W hoặc FRAC_MAX theo context. Khi fx=0: term_valid=0, sa=0, giữ state, exhausted=1. Khi có bit1: sa=clz(fx)+1, scale_next=scale+sa, fx_next=fx<<sa trong W_X bit. Nếu scale hoặc scale+sa vượt W_X thì state_error=1, term_valid=0 và giữ state; TB/controller phải báo lỗi, không coi đó là early termination hợp lệ. Core không cần gửi state không hợp lệ trong vận hành bình thường.

**Handshake và drain:** core nhận launch_valid&&launch_ready tại L0; sau đó không stall ở SAC/Shifter/Accumulator. Wrapper dự trữ slot cho kết quả trước launch, giữ bận đến khi output đã được nhận. Không nhận context mới khi giao dịch cũ chưa trả. first/last/init_only/approx_cut luôn chốt cùng term. Nếu SAC phát t token fraction, core_done sau L(t+2); t=0 đi token init_only nên done sau L3. Không phát done ở SAC hoặc khi shifter vừa có last.

**Reset và debug:** các module tuần9 có FF dùng reset_n assert bất đồng bộ/deassert qua hai FF tại từng block, expose trạng thái sẵn sàng để startup barrier phối hợp. Reset hủy context/token/result; dùng CK2Q header chung, enable theo bundle và không gate clock bằng LUT. Trace gồm fx trước/sau, sa/S, token, term/tail và acc sau commit. Top tích hợp chỉ ghép instance; logic nhận cặp parser/retire/reset đặt trong wrapper điều khiển. Core đã kiểm done/reset/context; Gate2 standalone chốt10/10, NF kiểm W11 theo §11.10. Các mốc này không thay ma trận final hoặc physical signoff.

### 5.6 SBM (`sbm`)

- **Khởi tạo và tích lũy trong MAC v0/v1 (Non-fused)**:
  - Khởi tạo: `acc = Y_mant` (1.f của Y, đóng góp của hidden bit của X), `sticky_acc = 1'b0`. Mỗi vòng: `acc = acc + (Y_mant >> S)`.
  - **Đường approx (`cfg_mode=1`, độc lập giá trị `EXACT_EN`)**:
    - payload approx cần FRAC_W+4 bit; ACC_W vật lý=max(2*FRAC_MAX+2,FRAC_W+4) khi EXACT_EN1,hoặc FRAC_W+4 khi EXACT_EN0. Payload gồm (2 bit nguyên cho tích trong $[1.0, 4.0)$, `FRAC_W` bit phân số, và 2 bit phụ Guard/Round). Với FRAC_W12,payload16 bit có lưới Q14; FLOOR có hai bit padding0 nên P_hat hữu ích Q12/14 bit. NF32/3 EXACT_EN1 dùng bank vật lý54 bit, không phải16.
    - `ROUND_SCHEME=0`: cắt số hạng về FRAC_W bit phân số tại mỗi phép dịch, hai vị trí G/R trong thanh ghi bằng 0; đây là profile tái hiện Fig. 4. `ROUND_SCHEME=1`: giữ thêm G/R, gom phần thấp hơn vào cờ sticky_acc riêng. L1/RTL phải dùng cùng điểm cắt.
    - OR các đuôi bị mất chỉ là chính sách xấp xỉ, không tái tạo tổng phần dư hay carry của chúng. RNE cuối làm tròn giá trị nội bộ đã xấp xỉ; không có bảo đảm khớp tích exact chỉ vì đã có sticky.
  - **Đường exact (`cfg_mode=0`, yêu cầu `EXACT_EN=1`)**: giữ FRAC_MAX bit fraction của cả X/Y; `acc` gồm 2 bit nguyên và 2×FRAC_MAX bit phân số. Không giới hạn vòng exact bằng N_MAX và không mất bit tích trước Packer/RNE.

- **Sketch accumulator stream có dấu cho fused, chưa khóa cửa sổ RTL:**
  - Accumulator bù hai theo §4.1. Với (32,2): sign [32], ba bit nguyên [31:29], 27 bit phân số [28:2], G/R [1:0]; sticky là cờ riêng. Ba bit nguyên cần vì mantissa tích <4 và C căn chỉnh <2 có thể cộng thành giá trị gần 6.
  - Mux `first` nạp toán hạng $C'$ (đã căn chỉnh theo $\Delta SF$) thay cho $Y$. Số hạng $1.0 \times Y$ từ hidden bit của $X$ trở thành một số hạng riêng tại vòng 0.
  - Mỗi số hạng được cộng/trừ tích lũy tùy theo bit dấu của tích $s_P = s_A \oplus s_B$:
    $$\text{acc} \Leftarrow s_P \ ? \ (\text{acc} - (Y \gg S')) : (\text{acc} + (Y \gg S'))$$
    với lượng dịch tổng cộng $S' = S + \text{shift\_extra}$.
  - **Sketch chưa nghiệm thu cho fused:** sticky OR không phải chính sách residual có dấu. Các phép cộng/cắt stream trên chỉ hợp lệ khi chứng minh tương đương §11.9; không dùng để bỏ qua oracle/borrow/cancellation.
  - Thanh ghi `sticky` trong sketch: Thu gom OR logic của mọi bit bị trôi ra khỏi cửa sổ `ACC_WIN` khi thực hiện dịch $Y \gg S'$. Không dùng S'>FRAC_MAX+2 để bỏ toàn bộ vòng lặp rồi coi OR sticky là giá trị số. Tổng residual có dấu và near-cancellation phải được kiểm theo §5.12-c trước mọi shortcut.

**Ví dụ số TV-ITER-01** (bài toán nhỏ để kiểm tay): FracX = `1.0100`₂ = 1.25, FracY = `1.0110`₂ = 1.375, tích đúng = 1.71875.

| Bước | Thao tác | Kết quả |
| --- | --- | --- |
| Khởi tạo | `acc = Y` | `1.0110`₂ = 1.375 (sai số 20.0%): tương ứng n = 0 |
| n = 1 | `fx = 0100`: `clz=1`, `sa=2`, `S=2`; `acc += Y>>2` | với acc rộng: `1.011000 + 0.010110 = 1.101110`₂ = **1.71875, chính xác** (X chỉ có 1 bit 1 sau hidden) |
| n = 1 nhưng FRAC_W=4 | `Y>>2` bị cắt còn `0.0101`₂ | `1.0110 + 0.0101 = 1.1011`₂ = 1.6875, sai số 0.03125/1.71875 = 1.82% |

**Ví dụ TV-PAPER-01** (đọc từ [P] Fig. 4; ES=3, FRAC_W=12): X = `0 001 110 010010000000 0…0`, Y = `0 01 111 001000001000 0…0`.

- `kX=-2, eX=6`; `kY=-1, eY=7`; tổng `k=-3`, `e=13`; vì `e ≥ 8` nên `k=-2`, `e=5`; `sf_out = 8×(-2)+5 = -11` (kiểm: `sfX=-10`, `sfY=-1`, tổng -11 ✓).
- FracX = `1.010010000000`: bit 1 ở vị trí 2 và 5 (sau dấu chấm) → 2 vòng lặp. Vòng 1: `sa=2`, `S=2`; vòng 2: `fx` sau dịch = `001000000000`, `sa=3`, `S=5`.
- FracY = `1.001000001000`. Vòng 1: `Y>>2 = 0.010010000010` → acc = `1.011010001010`. Vòng 2: `Y>>5 = 0.000010010000` (cắt 12 bit) → acc = `1.011100011010`.
- Kết quả: `O = 0 001 101 011100011010 0…0`, tức `1.44384765625 × 2^-11`.
- Giá trị đúng = `1.28125 × 1.126953125 = 1.4439086914…`; sai số tương đối ≈ 2^-14 / 1.4439 ≈ 4.2×10^-5 (0.0042%), hoàn toàn do cắt 12 bit.

(Vector này phải khớp cả L1 lẫn RTL bit-exact; nếu L1 ra khác Fig. 4 của paper thì ghi vào danh sách sai khác ở §11.)

### 5.7 Chuẩn hóa tích và bảo toàn prepack

Tách hai hợp đồng để không làm thay đổi lịch sử:

| Đường | Normalize/carry | Oracle và phạm vi |
| --- | --- | --- |
| Legacy `mul_norm.hpp`/`mul_norm_comb` | Lưới q theo mode; khi acc>=2,dịch phải1,bit thấp chuyển sticky,sf tăng1 | Giữ nguyên L1/RTL/freeze và Gate2 legacy; có thể khác R(P_hat) ở approx khi carry |
| NF so sánh mới `mul_prepack_norm_comb` | Giữ nguyên magnitude M; hidden h=Q hoặc Q+1; sf_norm=scale+(h-Q). Căn các bit dưới hidden vào F_IN, không bỏ bit thấp khi carry | Làm tròn raw P_hat; dùng week11::normalize/dyadic và NF model mới (§11.9/§11.10) |

FLOOR bỏ hai padding0 vật lý trước khi xét M/Q,không bỏ bit có trọng số của M. Exact Q=2F,FLOOR Q=FRAC_W; F_IN=2F+1 đủ giữ fraction sau carry ở bốn format đã kiểm. Adapter mới không làm tròn; round_unpacked/packer thực hiện RNE. Nếu thiết kế tương lai giảm F_IN,phải giữ residual đúng và kiểm lại hợp đồng trước áp dụng.

**Ứng viên OPT-01 — 16/10/2026:** `rtl/candidates/multiplier/mul_prepack_norm_comb.sv` dùng ánh xạ bit hằng tại elaboration cho exact/approx và carry/no-carry, thay chỉ số đích động/runtime integer. Hai nhánh chuẩn bị fraction độc lập rồi chọn theo carry/mode; `sf_norm=sf+carry_selected` trên đúng SF_W bit. Không thêm FF/cycle, không đổi pack→parse hoặc lịch/context NF. Giữ bit dưới hidden khi carry, bỏ đúng hai padding vật lý của FLOOR và không sinh numerical sticky từ metadata. Guard của ứng viên yêu cầu FRAC_MAX>=1,1<=FRAC_W<=FRAC_MAX,F_IN>=1,SF_W>=1,ACC_W>=FRAC_W+4 và nếu EXACT_EN1 thì ACC_W>=2*FRAC_MAX+2. Khi EXACT_EN0, miền hợp lệ của leaf chỉ có cfg_mode1; parent từ chối cfg_mode0 và không tuyên bố tương đương X/Z hoặc dữ liệu của cấu hình bị từ chối. Kiểm override F_IN chỉ xác nhận mapping legacy, không phê duyệt một profile precision hẹp; NF chính vẫn F_IN=2F+1. Ứng viên đạt kiểm chức năng nhưng không có lợi ích STA nhất quán trên A35T/A100T; production `rtl/multiplier/mul_prepack_norm_comb.sv` giữ nguyên bản trước thử nghiệm. Bằng chứng chức năng/STA trước-sau và giới hạn phạm vi tại PLAN§8.20; không đổi hợp đồng số học v1.18 hoặc pipeline.

Với hữu hạn khác0: P_hat=(-1)^sign*M*2^(scale-Q),h là vị trí hidden cao nhất,normalized mantissa=M/2^h. Không cộng sfA+sfB lần thứ hai. FLOOR numerical_sticky=0; input_cut/iteration_cut/term_cut là metadata inexact,không dùng chúng khôi phục giá trị bằng GRS. JAM có hợp đồng legacy riêng,không được dùng adapter NF hardwire FLOOR để suy hỗ trợ JAM.

W11 xác nhận238.906/900.000 cặp khác legacy; adapter mới khớp oracle1.244.064 kiểm,0 mismatch. Đây là khác biệt của hai hợp đồng local,không chứng minh lỗi RTL tác giả.

### 5.8 Adder (`posit_add`)

Ngõ vào hai bộ ba unpacked `(s, sf, m)` với `m = 1.f` rộng `W = FRAC_MAX + 1`; ngõ ra unpacked chưa làm tròn; G/R nằm trong fraction mở rộng, sticky ngoài giữ numerical tail. GRS cuối do packer quyết định theo regime (§5.8-B/§5.9).

**Đặc tả chi tiết và giới hạn Alignment Shifter**:

- Chọn số hạng có độ lớn lớn hơn theo (sf,m); đặt $d=sf_L-sf_S\ge0$, dấu kết quả theo số hạng lớn khi trừ. Alignment phải giữ G/R và phần dư; khi trừ không được xử lý phần dư như một số hạng cộng dương.
- **Cơ chế Kẹp Cứng (Clamping)**: Do dải scale factor $sf$ rất rộng ($[-240, 240]$ với posit32/ES3; ES2 là $[-120,120]$), dịch theo toàn bộ dải sf cần datapath/control lớn hơn; tác động LUT/timing phải đo. Nhận xét rằng nếu $d > \text{FRAC\_MAX} + 2$, toàn bộ mantissa $m_2$ sẽ bị dịch trôi hoàn toàn ra ngoài vùng bit có nghĩa (ngoài cả bit Guard và Round). Khi đó:
  - Mạch kích hoạt cơ chế kẹp cứng: $d_{clamp} = \min(d, \text{FRAC\_MAX} + 2)$.
  - Nếu $d > \text{FRAC\_MAX} + 2$, toàn bộ $m_2$ được bypass/dồn thẳng vào bit Sticky: $S = |m_2| \ne 0$.
  - Nhờ vậy, bộ Alignment Barrel Shifter chỉ cần độ rộng dịch tối đa là $\text{FRAC\_MAX} + 2$ vị trí (ví dụ: với posit32, $\text{FRAC\_MAX}=27$, shifter chỉ cần 5 bit điều khiển cho tối đa 29 vị trí dịch).

#### A. Hợp đồng giao diện W10-01 — chốt 12/10/2026

**Phạm vi:** posit_add cho NF/v0/v1 và cộng hai Posit độc lập; bốn format nghiệm thu (8,0),(16,1),(32,2),(32,3). F=FRAC_MAX=NB-3-ES là fraction đầy đủ của format, khác FRAC_W12 của multiplier approximate. NB32/ES3 dùng F26, không cắt đầu vào adder còn12 bit. Các cấu hình khác chưa nghiệm thu; adapter baseline yêu cầu F>=2, không tuyên bố hỗ trợ toàn bộ tuple hợp lệ của IP. Không đổi mô hình L1 đóng băng.

Đầu vào hữu hạn khác0 là exact normalized 1.f: `a_frac/b_frac` chỉ chứa F bit sau hidden, scale signed trong[-SF_MAX,SF_MAX]; parser hoặc round_unpacked cung cấp. Không nhận prepack P_hat, GRS/đuôi của tích chưa round, hay sticky_input; metadata flags không thay giá trị toán hạng. Hai toán hạng, special và flags_in được nhận nguyên tử tại cùng handshake. Không có cfg_n/cfg_ops hoặc acc_mode bên trong adder; MAC quản lý C_eff/config/feedback theo §4.2.

| Cổng posit_add | Hướng / độ rộng | Hợp đồng |
| --- | --- | --- |
| clk / reset_n | in / 1 | Leaf reset assert bất đồng bộ, release qua hai FF theo guideline; top rst_n qua bridge/barrier §4.2 |
| in_valid / in_ready | in / out,1 | Handshake nhận cả A/B/flags; nguồn giữ toàn bộ payload khi valid và chưa ready |
| a_sign / b_sign | in / 1 | Dấu từng toán hạng |
| a_is_zero / b_is_zero | in / 1 | Khi1, sf/frac bị bỏ qua |
| a_is_nar / b_is_nar | in / 1 | NaR ưu tiên Zero và dữ liệu hữu hạn |
| a_sf / b_sf | in / signed SF_W | SF_W theo §2.3; không dùng ES làm độ rộng sf |
| a_frac / b_frac | in / F | Không chứa hidden; hữu hạn khác0 khôi phục hidden1 |
| flags_in | in / 5 | Metadata từ bước nhân/round; thứ tự §4.2; không OR vào sticky số học |
| out_valid / out_ready | out / in,1 | Xuất unpacked, chưa làm tròn; giữ cả payload khi stalled |
| sign / is_zero / is_nar | out / 1 | Canonical special theo mục C dưới |
| sf | out / signed SF_W | Scale sau normalize; không clamp về Posit tại adder |
| frac | out / F_OUT=2F+1 | Fraction mở rộng, không hidden; nối frac của packer F_IN=F_OUT |
| sticky | out / 1 | Numerical tail theo L1 `!sum.exact`; không phải OR của metadata approximate |
| flags_out | out / 5 | Metadata qua adder; packer nhận qua flags_in để hoàn thiện flags cuối |

F, F_OUT, SF_W là kích thước suy từ NB/ES theo công thức hiện hành; ghi đè sai phải bị chặn lúc elaboration. Module tổ hợp posit_add_comb dùng cùng cổng số học (không clk/reset/valid/ready); pipeline posit_add và comb phải cho cùng output. Mỗi module một file, named ports, mỗi cổng một dòng, always_comb có default, bank dùng always_ff/enable/CK2Q theo guideline. Không tạo stub RTL chưa có chức năng để gọi là triển khai.

#### B. Độ rộng, alignment và adapter packer

Q=F+3; x=unsigned({1,a_frac})<<3, y=unsigned({1,b_frac})<<3 sau chọn lớn theo(sf,m); tie độ lớn giữ A. Word sum/carry rộng Q+2=F+5; magnitude đã normalize rộng Q+1=F+4. Khôi phục hidden và zero-extend vào ADD_W trước khi dịch trái3; không dịch trong biểu thức hẹp F+1 bit làm mất MSB. Delta scale được tính bằng sign-extension rộng SF_W+1 rồi chuyển unsigned sau bảo đảm d>=0; không wrap subtraction trước clamp.

| NB/ES | F | Q | Word sum/carry | F_OUT | SF_W |
| --- | --- | --- | --- | --- | --- |
| 8/0 | 5 | 8 | 10 | 11 | 6 |
| 16/1 | 12 | 15 | 17 | 25 | 8 |
| 32/2 | 27 | 30 | 32 | 55 | 10 |
| 32/3 | 26 | 29 | 31 | 53 | 11 |

Ở d<=F+2: dịch y, gom mọi bit mất vào tail và jam bit0 như L1; ở d>F+2: y=1,tail=1 với toán hạng nhỏ hữu hạn khác0. Đây là clamp F+2 của mô hình đã kiểm, không lấy y sau dịch ở F+2 rồi OR1 cho nhánh vượt ngưỡng. Khác dấu tính x-y trên độ lớn đã chọn; không cộng tail dương vào tổng âm. Carry dịch phải1, jam bit rơi, tăng sf1; nếu nhỏ hơn hidden thì LZD/dịch trái và giảm sf đúng số vị trí; zero kiểm trước LZD.

Mapping hữu hạn: `frac={magnitude[Q-1:0], {(F-2){1'b0}}}`; `sticky=alignment_tail | carry_lost_bit` đúng L1 !sum.exact. Q bit fraction đã gồm F bit fraction, G=mag[2],R=mag[1],bit jam=mag[0]; S_trace=mag[0]|tail. G/R/S_trace là quan sát nội bộ, không thêm port G/R riêng và không OR mag[0] tùy tiện vào sticky ngoài: bit jam vẫn nằm trong frac, có thể được dịch lên khi normalize. Packer tự dịch regime và tính GRS cuối; không bỏ G/R trước pack, không round tại A3. Bypass zero operand đệm F_OUT-F bit0 vào fraction của operand còn lại. Các special trả frac/sticky0.

flags_out hữu hạn giữ flags_in[3:0] và OR numerical tail vào inexact; không tạo approx_cut mới. Các G/R và fraction thấp được packer dùng xác định inexact cuối theo §5.9; không báo saturation trước khi có kết quả normalized. Packer OR các flags trung gian, xác định sat_max/sat_min và final inexact; kết quả NaR luôn flags10000. Hòa/rounding/clamp cuối do ROUND_MODE của packer, không cần ROUND_MODE trong adder.

#### C. Special và giao thức ba tầng elastic

NaR nếu a_is_nar|b_is_nar|flags_in[4]: sign1,is_nar1,is_zero0,sf0,frac0,sticky0,flags_out10000. Hai Zero hoặc triệt tiêu exact: sign0,is_zero1,is_nar0,sf0,frac0,sticky0; giữ metadata hữu hạn flags_in[3:0]. Một Zero: giữ giá trị operand hữu hạn còn lại, frac đệm0, sticky0; vẫn qua pipeline. Không bypass special vượt thứ tự. Payload vô nghĩa khi out_valid0, nhưng dữ liệu/flags xác định sau reset.

| Tầng / cạnh không stall | Công việc và trạng thái cần giữ |
| --- | --- |
| A1 / E0 nhận input | Special/flags; chọn độ lớn/dấu/phép cộng-trừ; delta/clamp/dịch-jam; chốt x,y,tail,sf_base và context |
| A2 / E1 | Cộng/trừ magnitude, carry/zero candidate; chốt kết quả và context |
| A3 / E2 | Carry hoặc LZD-normalize, scale, adapter frac/sticky và flags; chốt output unpacked |

Ba slot elastic, enable độc lập: ready3=!valid3|out_ready; ready2=!valid2|ready3; ready1=!valid1|ready2. in_ready bị gate bởi reset/startup; stage chỉ cập nhật khi ready của chính stage và startup đã nhả. Không dùng enable chung làm mất giao dịch dưới backpressure. Không có CE ngoài ở giao diện đã chốt; clock enable là load-enable nội bộ. Có thể push/pop đồng thời, II=1 không stall; không nhân đôi handshake nếu downstream giữ ready.

Input handshake E0 → out_valid sau E2 → output handshake sớm nhất E3: H_ADD=3,L_valid=2,L_handshake=3. Startup chờ hai cạnh synchronizer release, stall báo riêng. Reset xóa cả3 valid/data/context và hủy giao dịch đang chờ; in_ready=out_valid0 khi reset/startup. Khi out_valid&&!out_ready, toàn bộ output giữ đến handshake hoặc reset. Reset ưu tiên handshake. RNE packer tiếp theo hai slot theo §5.9-D: giao dịch đầu vào adder E0 sang packer ở E3, packer valid sau E4 và handshake E5 nếu không stall; TRUNC packer valid sau E3 và handshake E4. Không tính hai lần bank A3/P1. Lịch feedback round_unpacked và C/context NF đã kiểm ở §11.10; ba tầng adder không tự nghiệm thu II_acc.

#### D. Điều kiện bàn giao W10-01

Hợp đồng W10-01 đã chốt trước hiện thực; RTL adder hiện đã kiểm theo §5.8-E. Review/projection365.836 cặp trên bốn format (posit8 exhaustive),23.413.504 kiểm metadata/mode, Linux và UBSan cùng PASS/0 mismatch,seed20261012; bằng chứng tại results/week10_contract; kiểm mapping L1 sang giao diện/packer không thay nghiệm thu số học L0 hoặc pipeline. W10-02 khóa vector/oracle/flags/control và counts trước chạy; W10-03..06 hiện thực/kiểm comb, pipeline, timing và assertions. Không coi interface PASS là RTL PASS, STA hoặc Gate3. Cửa sổ/residual fused tiếp tục §5.12, không đưa prepack vào giao diện NF này.

#### E. Nghiệm thu adder đơn vị tuần10 — 12/10/2026

Đã hiện thực posit_add_align → posit_add_arith → posit_add_normalize dùng chung ở posit_add_comb và posit_add ba tầng elastic. ModelSim10.1d: comb143.976 vector (posit8 có toàn65.536 cặp), pipeline143.376 completed/600 reset-aborted,0 mismatch; so từng khối, output unpacked, RNE/TRUNC và flags. Kiểm E2/E3, ba slot, input/output stall, reset/startup và thứ tự. Strict Verilator5.032 --timing -Wall8/8 format/top sạch.

Harness coverage/scoreboard trực tiếp: ES2 10.000.003 completed/9.787 reset-aborted; ES3 10.000.001/9.862;0 mismatch. Mỗi input nhận được đối chiếu L1, oracle integer/bit-list độc lập (decode/add/pack không dùng L1); SoftPosit RNE ở format hỗ trợ, không gán ES3 cho L0 ES2. Kiểm cả unpacked/packed RNE/TRUNC và flags; pilot bốn format chạy trước lượt lớn. UBSan generator đạt. Seed_base20261012, seed format=base+100NB+ES; compilerGCC15.2.0, SoftPosit0.4.1/hash/lệnh/source/binary/fixture cùng report.

Bằng chứng canonical results/week10_adder/summary.json; matrix.json, raw coverage và structural_coverage.json giữ tất cả unhit points. Coverage raw toàn verification hierarchy: line80,00–80,95%,branch92,31–96,15%,toggle75,18–84,74%; không loại point và **chưa đạt final AC04**, không dùng milestone tuần10 thay signoff coverage. Tại checkpoint tuần10 ngày12/10, P16 exhaustive RTL2^32, P32 final>=10^8 theo AC02, tích hợp MAC/feedback/Gate3 và STA/PPA còn mở. Mốc NF và phần coverage bổ sung đã đạt được cập nhật tại §11.10–§11.13. L1 frozen source hashes giữ nguyên; không gọi pipeline này là MAC fused.

Corpus NF/F common100.000 triple đầu vào đã đóng băng/replay byte-exact ở paired/manifest.json; chưa đo accuracy, oracle F/Ideal full-sum và window/residual vẫn theo tuần12. Tham chiếu software1024 bit trên grid2^-532 đủ bảo thủ cho32/3 (4SF_MAX+2F+4=1016 bit); không phải width RTL. Checklist tuần10 đã nghiệm thu phạm vi đơn vị và gỡ khỏi tiến độ, giữ nhật ký/report; tiếp tuần11 NF/Gate3. Ghép NF với packer pipeline/round_unpacked/feedback đã kiểm toàn MAC ở §11.10; kết quả đó không suy từ testbench packer tổ hợp.

### 5.9 Packer (`posit_pack`)

#### A. Thuật toán đóng gói RNE, phỏng theo Algorithm 2 của [F]

Khối đóng gói chuyển `(sign,sf,frac)` thành Posit NB bit. Pseudocode dưới đây là bản diễn giải của đề tài từ Algorithm 2 của [F], bổ sung tiền kẹp và ràng buộc biên; không phải nguyên văn hay mã RTL hoàn chỉnh. `normf` là phần fraction sau hidden bit; nếu đầu vào mang mantissa 1.f thì bỏ hidden bit khi ghép inshift.

```text
Input: sign,is_zero,is_nar,sf,normf[F_IN-1:0],sticky_in,flags_in
Output: out[NB-1:0],flags; normf excludes hidden

1. NaR (including flags_in[4]) overrides Zero and range.
   Zero returns0. Finite sf>=SF_MAX returns signed maxpos;
   sf<-SF_MAX returns signed minpos. sf==-SF_MAX stays on normal path.
   Range/inexact flags depend on the actual input,not only the selected code.
2. k = floor(sf / 2^ES); e = sf-k*2^ES.
   ES=0: omit exponent field; do not create a zero-width slice.
3. first_regime_bit=(k>=0); offset=k if k>=0 else -k-1.
   payload={first_regime_bit,!first_regime_bit,e,normf,1'b0}.
   P=2+ES+F_IN+1; payload/shifted indices are [P-1:0].
4. shifted=shift_right_fill(payload,offset,first_regime_bit).
   lost_sticky=OR(original payload bits discarded by this shift).
5. mag_trunc=shifted[P-1 -: NB-1]; L=mag_trunc[0].
   G=shifted[P-NB]; Rb=shifted[P-NB-1].
   S=sticky_in | lost_sticky | OR(shifted[P-NB-2:0]).
6. round_up=G & (L | Rb | S) for RNE; round_up=0 for TRUNC.
   For nonzero finite input,clamp mag_trunc+round_up to [1,maxpos].
   Apply sign with NB-bit two's complement; never wrap carry into NaR.
7. OR incoming finite flags with range/inexact from this pack;
   inexact includes G|Rb|S. NaR flags are10000.
```


#### B. Khác biệt giữa FloPoCo (RNE) [F] và Bộ nhân xấp xỉ [P]

| Đặc điểm | Profile TRUNC theo [P] | RNE phỏng theo [F], đối chiếu L0 |
| :--- | :--- | :--- |
| **Cơ chế** | Cắt magnitude trước range clamp; underflow khác 0 vẫn ra minpos, nên không thuần round-to-zero | **Round-to-Nearest-Even (RNE)** với cùng range clamp |
| **Độ phức tạp phần cứng** | Không cần tie/increment RNE; vẫn thu phần bỏ để tạo inexact và cần mã hóa dấu. RTL shared prepare vẫn tính G/R/S cho flags | G/R/S tham gia quyết định tăng; P2 gộp tăng RNE và dấu trong một carry chain |
| **Diện tích (Area)** | Bỏ logic RNE chuyên biệt khi tổng hợp cấu hình TRUNC | Thêm logic làm tròn/sticky và bank pipeline; mức chênh LUT/FF phải đo |
| **Sai số** | Trong miền chưa clamp, cắt độ lớn gây bias về 0; range clamp có thể đổi xu hướng ở biên | Hòa chọn chẵn; đúng RNE không tự bảo đảm sai số trung bình bằng 0 cho mọi phân phối |

Fig. 5(b) của [P] (chế độ TRUNC) chỉ có một hạng thanh ghi ở ngõ ra:
```
  m = Rgm[NB_R-2:0] XOR {Rgm[NB_R-1]}      // k>=0: m = k;  k<0: m = |k|-1
  FRB = ~Rgm[NB_R-1]                       // bit đầu regime
  Out = arith_shift_right({~FRB, FRB, Exp, Frac, zeros}, m) rồi cộng bit Sign
```
`ROUND_MODE="RNE"` dùng thuật toán mục A và chia hai hạng P1/P2 theo §5.9-D. Đây là cấu hình baseline đã chốt, không phải chứng minh mọi mục tiêu fmax đều cần hoặc chỉ cần hai hạng.

Packer và standalone legacy hỗ trợ hai chế độ qua ROUND_MODE; top NF tuần11 chỉ hardwire RNE:

- `ROUND_MODE="RNE"`: nghiệm thu exact theo AC-02; approx vẫn so L1. PIPE_PACK=2 theo §5.9-D; cần xác nhận timing.
- `ROUND_MODE="TRUNC"`: profile local tham khảo encoder của [P], PIPE_PACK=1; range handling theo hợp đồng đồ án. Chọn TRUNC không xác nhận đã tái hiện toàn bộ baseline paper; số liệu diện tích/độ chính xác phải đo.

#### C. round_unpacked cho MAC v1

Hợp đồng bắt buộc: round_unpacked(u, mode) tương đương parse(pack(u, mode)) về giá trị, dấu, sf và fraction chuẩn hóa, bao gồm Zero/NaR, regime dài, exponent thiếu bit, carry làm tròn và bão hòa. Không chỉ cắt fraction theo sf ban đầu: carry có thể thay đổi sf và số bit khả dụng.

Đầu ra thuộc đúng lưới Posit; các bit thấp dưới lưới bằng0; NF hiện dùng pack→parse tổ hợp chung với packer/parser đã kiểm, không chuyển phần dư G/R/S của tích chưa làm tròn sang Adder. Nhờ hợp đồng này v1 giữ ngữ nghĩa non-fused của §5.1. Cờ inexact của bước làm tròn vẫn phải được lưu trong metadata dù phần dư số học đã bỏ.

#### D. Hợp đồng phân tầng packer RNE P1/P2 — chốt 06/10/2026

**Phạm vi:** baseline ROUND_MODE="RNE", PIPE_PACK=2, cùng clk, hai slot elastic. Lõi tổ hợp và pipeline dùng cùng hai module posit_pack_prepare/posit_pack_finish, đối chiếu độc lập với L1. Đầu vào hữu hạn khác 0 đã chuẩn hóa thành sign, sf signed và fraction của 1.f; phần dư thấp chuyển thành sticky của độ lớn đúng. Packer không chuẩn hóa mantissa chưa chuẩn hóa và không diễn giải phần dư có dấu của fused bằng một sticky OR chung.

**Giao diện chốt07/10/2026:** rtl/packer/posit_pack_comb.sv và rtl/packer/posit_pack.sv dùng NB, ES, F_IN, SF_W, ROUND_MODE. F_IN mặc định 2*FRAC_MAX+1: posit8/0=11, posit16/1=25, posit32/2=55, posit32/3=53. Điều kiện F_IN>=FRAC_MAX+2 và <=63 cho adapter/oracle L1 hiện tại; bốn format này là phạm vi nghiệm thu, cấu hình khác cần kiểm riêng. frac[F_IN-1:0] không hidden, giá trị fraction=frac/2^F_IN; frac=0 cùng is_zero=0 biểu diễn mantissa1.0, không phải số0. F_IN mặc định giữ đủ tích của hai fraction FRAC_MAX bit sau chuẩn hóa, kể cả bit thấp thêm do tích>=2 được dịch phải một vị trí.

Ports số học: sign, is_zero, is_nar, sf signed, frac, sticky, flags_in[4:0]. Đầu ra d[NB-1:0], flags[4:0]; wrapper tuần tự thêm clk/reset_n/in_valid/in_ready/out_valid/out_ready. flags_in[4]=1 cũng buộc NaR, không cho mất NaR từ phép toán trước. Các bit cờ theo §4.2.

Adapter parser: frac_pack={frac_parser, zeros}, sticky=0, flags_in=0, giữ sign/sf/is_zero/is_nar. Adapter nhân/cộng chỉ sau chuẩn hóa: nếu fraction ngắn hơn F_IN thì đệm0 phía LSB; nếu dài hơn thì lấy F_IN bit cao và OR phần bỏ với sticky sẵn có. Không làm tròn thêm ở adapter; việc chuẩn hóa dấu/phần dư do khối số học chịu trách nhiệm. Với L1 u.frac hidden ở bit63: frac_pack=(u.frac>>(63-F_IN)) & mask_F_IN; sticky_pack=!u.exact OR các bit thấp bị bỏ. Test fixture packer đặt những bit thấp ngoài F_IN bằng0 và u.exact=!sticky để biểu diễn cùng đầu vào.

**Pre-clamping tại minpos:** chỉ kẹp sớm khi sf<-SF_MAX. sf=-SF_MAX phải đi qua mã hóa/RNE vì phần fraction vẫn có thể đổi mã, đặc biệt ES=0: posit8 giá trị1.5*minpos là tie giữa0x01/0x02, RNE chọn0x02. Dùng <= sẽ sai trường hợp này. Tại maxpos, sf=SF_MAX vẫn xuất maxpos, nhưng sat_max/inexact chỉ lên nếu fraction hoặc sticky làm giá trị vượt biên.

| Hạng thanh ghi | Logic tổ hợp trước bank | Dữ liệu chốt |
| --- | --- | --- |
| **P1 — mã hóa và chuẩn bị RNE** | Nhận diện NaR/Zero, pre-clamping; tách sf thành k/e; tạo regime, ghép payload và dịch có bit điền. Lấy magnitude chưa làm tròn và G/R/S; S bao gồm cả bit mất do dịch/điểm cắt và sticky đầu vào | mag_trunc[NB-2:0], G, R, S, sign, special_sel, flags_in và cờ range/inexact phát sinh; p1_valid |
| **P2 — làm tròn và xuất kết quả** | NORMAL: round_up=G AND (mag_trunc[0] OR R OR S); về số học, tăng magnitude rồi kẹp vào [1,maxpos] và áp dụng dấu NB bit. RTL được gộp làm tròn/dấu thành một bộ cộng tương đương; kiểm biên song song trước bộ cộng. Trường hợp đặc biệt chọn mã tương ứng; hợp nhất flags theo §4.2 | d[NB-1:0], flags[4:0], p2_valid; đây là bank đầu ra, không thêm bank thứ ba ngầm |

Ranh giới bắt buộc: bộ dịch payload và cây gom sticky nằm trước P1; quyết định round_up, bộ cộng làm tròn và bù hai ngõ ra nằm giữa P1/P2. LSB lấy từ mag_trunc[0], không cần một FF LSB trùng dữ liệu. Kết quả phải tương đương magnitude mở rộng/kẹp rồi áp dụng dấu, không cho carry tràn thành NaR. Không bắt buộc hai bộ cộng nối tiếp trong RTL. Không chốt lại sf, k/e, toàn bộ fraction hoặc vector đã dịch trong P1 nếu P2 chỉ cần bundle ở bảng trên; đây là chủ đích giảm trạng thái giữa tầng, không phải kết quả đo FF.

**Tối ưu P2 ngày07/10:** đặt m=zero_extend(mag_trunc), r=round_up. Khi không cần kẹp, d=((m XOR {NB{sign}})+(sign XOR r)) mod 2^NB: sign=0 cho m+r; sign=1 cho ~m+1-r=-(m+r). m=0 luôn chọn minpos; m=maxpos luôn chọn maxpos, cả hai giữ dấu. Hai kiểm biên chỉ phụ thuộc mag_trunc, chạy song song với bộ cộng; specials chọn các mã hằng đã có dấu. Đây là phép biến đổi logic tương đương, không thay đổi bundle P1, flags, latency hoặc handshake; TRUNC vẫn r=0.

special_sel có ý nghĩa NORMAL/ZERO/NAR/MAXPOS/MINPOS. NaR ưu tiên Zero và range; P2 xuất NaR với flags=10000. ZERO xuất 0; MAXPOS/MINPOS giữ dấu và bỏ phép tăng RNE. Các giá trị bằng đúng biên không tự bị gắn cờ vượt dải; cờ phải xét giá trị/phần dư thực và khớp L1. Metadata có flags_in để giữ cờ phép toán trước; sat/inexact được OR theo §4.2, approx_cut truyền nguyên, ngoại lệ NaR xóa bốn cờ còn lại. Trường không dùng của token đặc biệt phải được gán giá trị xác định, không dùng X làm don't-care trong RTL.

**Enable và handshake:**

```text
p2_ready = !p2_valid_q || out_ready
p1_ready = !p1_valid_q || p2_ready
in_ready = run_ready && p1_ready
out_valid = run_ready && p2_valid_q
```

run_ready chỉ có hiệu lực sau reset/startup. P1 nhận bundle mới khi in_valid && in_ready; nguồn giữ toàn bộ input bundle trong stall. P2 chuyển token khi p1_valid_q && p2_ready; khi p2_ready mà P1 rỗng thì tạo bubble, không lặp token cũ. Mọi trường của cùng bank dùng chung enable; out_valid && !out_ready giữ d/flags/out_valid. Hai slot cho phép nhận/trả đồng thời nhưng không tăng sức chứa dự trữ của MAC baseline ở §4.2/§5.5.

**Reset và lịch cạnh:** leaf packer dùng reset_n assert bất đồng bộ, deassert qua hai FF riêng theo Guidelines, tích hợp qua reset bridge/startup barrier §4.2. Reset flush cả hai valid, xóa dữ liệu/cờ và chặn in_ready/out_valid; không trả token trước reset. Với input nhận E0, P1 chốt E0, P2 chốt và valid sau E1, output handshake sớm nhất E2; H=2, L_valid=1, L_handshake=2, II=1 khi không stall. Token Zero/NaR/range đi qua cùng hai slot, không có đường vượt thứ tự. Startup và số chu kỳ stall báo riêng.

**TRUNC và timing:** ROUND_MODE là tham số elaboration. Baseline TRUNC một bank đầu ra (H=1, L_valid=0, handshake E1 cho input E0), loại logic chuyên biệt RNE; cờ inexact vẫn phải phản ánh phần bị cắt. Không ép TRUNC qua hai hạng của RNE. P1 có đường dịch/sticky; P2 dùng bộ cộng gộp làm tròn/dấu và mux biên; hai hạng không tự bảo đảm fmax. Nếu STA yêu cầu tầng thứ ba hoặc ranh giới khác, cập nhật contract PIPE_PACK, ngân sách §5.1/§5.11 và TB trước khi nghiệm thu, không âm thầm thêm latency.

**Nghiệm thu tuần8:** tổ hợp khớp L1, parser→packer đồng nhất exhaustive posit8/16 và corner/phân tầng posit32 ES2/ES3; thêm đầu vào có phần dư cho round-down/up, ties-even/odd, sticky-only, carry/regime dài và hai biên, cả hai dấu. Pipeline kiểm E0/E1/E2, II không stall, hai slot đầy, stall dài, bubble, nhận/trả đồng thời, reset rỗng/một slot/hai slot và thứ tự/không mất/không nhân đôi. Lưu log/seed/version/hash; nghiệm thu chức năng và STA/PPA báo riêng. Nghiệm thu07/10/2026: ModelSim10.1d đạt5.947.048 lượt fixture RNE/TRUNC (tổ hợp và pipeline),4.931.624 lượt chain parser→packer,0 mismatch; reset/stall/order/II/latency đạt. Generator2.973.524 dòng kiểm L1 và bit-list oracle độc lập. Vivado2026.1 compile/elaborate đạt. Bằng chứng results/packer/summary.json, logs, compiler/seed/hash. Nghiệm thu tuần8 đơn vị, chưa là Gate2/3 toàn MAC.

**Khảo sát PPA packer riêng07/10 — sau tối ưu P2:** Quartus13.0.1 Web, CycloneIV EP4CE22F17C6, NB32/ES2/F_IN55, cùng boundary input/output có thanh ghi, clock10ns, seed1/2/3. RNE537 LUT4/196 FF, fmax122,50–124,42MHz, WNS1,837–1,963ns; TRUNC522 LUT4/152 FF, fmax100,67–101,01MHz, WNS0,067–0,100ns. Cả sáu run đạt setup100MHz trong benchmark này; TRUNC có dư nhỏ. So với bản P2 hai bộ cộng: RNE giảm54 LUT4 (9,14%), TRUNC giảm40 LUT4 (7,12%), FF không đổi. RNE thêm15 LUT4 và44 FF so với TRUNC, II vẫn1; không thêm tầng. Đường setup xấu nhất RNE seed3 chuyển từ P1.mag_trunc[0]→P2.d[31] sang input.sf[9]→P1.flags[1]. Số FF gồm boundary benchmark; I/O auto-assigned, chỉ timing register-register, chưa board/power/full MAC. Export shifter chỉ thêm generate tường minh cho Quartus13, kiểm tương đương9120 basis, không đổi RTL gốc. Báo cáo/hash hiện tại tại results/packer_ppa/; bản trước và comparison.json tại results/packer_p2_optimization/. Chưa là Gate4 hoặc tái hiện PPA xcvu9p của paper.

### 5.10 Đối chiếu vi kiến trúc với Block Diagram Fig. 3 của [P]

Fig.3 của [P] là nguồn tham khảo cấu trúc Parser → OPS → SAC → SBM shifter → SBM accumulator → Packer. Bảng dưới ánh xạ chức năng sang RTL hiện thực, không chứng minh RTL, vị trí thanh ghi, LUT/FF hoặc kết quả Table I giống tác giả. Các khác biệt có chủ đích và giới hạn bằng chứng được tập hợp tại §5.10-G; hợp đồng NF hiện hành tại §11.10.

#### A. Bảng ánh xạ khối Fig.3 ↔ Module RTL hiện thực

| Khối/chức năng trên Fig.3 | Module RTL hiện tại | Chức năng và giới hạn tương đương |
| --- | --- | --- |
| Parser X/Y | `posit_parser` ×2; thêm parser C_eff cho MAC | Tách dấu, sf, fraction không hidden và Zero/NaR; hidden được khôi phục trong đường số học. Parser hai tầng theo §5.2 |
| OPS và hai mux chọn X/Y | `ops_sel_comb` | Chọn X/Y; cfg_ops0 giữ A, cfg_ops1 min-popcount/tie-A. Không dùng prefix predictor của paper trong NF hiện tại |
| XOR dấu, Rgm/Exp adder | `ops_sel_comb` | sign=sA XOR sB, sf=sfA+sfB. Scale gộp tương đương số học theo §5.10-B; Fig.3 không công bố logic cổng bên trong Rgm/Exp adder |
| First mux trước SAC và feedback | `iter_ctrl` | Launch nạp fraction X; các vòng sau dùng fx_next. Config/sign/sf giữ nguyên trong context của giao dịch |
| SAC | `sac_step_comb` + bank token trong `iter_ctrl` | Tìm bit1 tiếp theo, sa=clz(fx)+1, cộng tổng S và dịch loại bit đã xử lý. Hợp đồng normative ở §5.5, không mặc định đồng nhất mọi recurrence nghiên cứu của tác giả |
| SBM shifter | `sbm_shift_comb` | Dịch phải magnitude Y unsigned theo S; FLOOR cắt từng term. Scale có dấu không biến phép dịch magnitude thành arithmetic shift |
| First mux trước accumulator | `sbm_accum_comb` | Token đầu chọn y_base thay acc; cộng term nếu không init_only. Token init_only nạp Y đúng một lần |
| SBM accumulator | `sbm_accum` + `sbm_accum_comb` | Hồi tiếp tổng magnitude; numerical_tail/metadata cut tách khỏi numerical sticky. Trong FLOOR, phần đã cắt không còn thuộc P_hat và không được OR vào GRS của P_hat |
| Chuẩn hóa tích, không vẽ thành khối riêng trong Fig.3 | NF mới: `mul_prepack_norm_comb`; standalone legacy: `mul_norm_comb` | Khi carry, NF mới tăng sf và đổi vị trí hidden, giữ nguyên grid/bit thấp. Khác đường legacy dịch bỏ một bit; xem §11.9 |
| Packer của multiplier / làm tròn tích để ghép NF | Standalone: `posit_pack`; NF: product `posit_pack` P1/P2 → `posit_parser_comb` → `posit_add` → `posit_pack` cuối | Giữ parse(pack(u)) về số học; OPT-03 chốt P1, P2 và product unpacked. Adder và packer tổng là phần mở rộng MAC ngoài Fig.3 |

#### B. Scale factor gộp

sf_A+sf_B=(k_A+k_B)·2^ES+(e_A+e_B). Nếu tổng exponent ≥2^ES thì carry tăng k thêm 1, phần exponent còn lại là (e_A+e_B) mod 2^ES. Đây là cùng phép tính với các bộ cộng/điều chỉnh Rgm/Exp của Fig. 3, miễn SF_W đủ rộng.

RTL có thể dùng một bộ cộng sf có dấu thay các khối điều chỉnh riêng. Diện tích và timing có cải thiện hay không phải đo; sự tương đương số học không chứng minh tiết kiệm LUT.

#### C. Chức năng 5 đường thanh ghi (Reg) và hai bộ Mux First trong Fig. 3

Fig.3 đánh dấu năm ranh giới Reg ở mức sơ đồ tổng. Danh sách dưới giải thích vị trí chức năng của các ranh giới đó; không suy ra toàn multiplier/NF có đúng năm tầng vật lý, vì parser/packer còn có thanh ghi bên trong. Lịch RTL đo được theo §5.2, §5.5 và §11.10:

1. **Reg 1 (sau Parser)**: dấu, Rgm/Exp, Frac của x và y.
2. **Reg 2 (sau OPS, mux, XOR, Rgm/Exp adder)**: X và Y đã chọn, sf và dấu đầu ra.
3. **Reg 3 (sau SAC)**: tổng lượng dịch S và fx còn lại.
4. **Reg 4 (sau SBM shifter)**: Y >> S.
5. **Reg 5 (sau SBM accumulator)**: acc kèm Rgm/Exp, rồi vào Packer. Packer có thanh ghi riêng ở ngõ ra.

**Vai trò của hai bộ Multiplexer First (`first`)**:

- **First Mux 1 (tại ngõ vào SAC)**:
  - Khi bắt đầu một giao dịch mới (`first = 1`): Mux chọn fraction X đã qua OPS từ Reg 2.
  - Trong các chu kỳ lặp kế tiếp (`first = 0`): Mux chọn ngõ ra hồi tiếp của SAC ($fx$ đã loại bỏ bit 1 vừa xử lý).
- **First Mux 2 (tại ngõ vào Accumulator)**:
  - Khi bắt đầu một giao dịch mới (`first = 1`): Mux chọn trực tiếp mantissa $1.f_Y$ (đây chính là giá trị tương ứng với bit ẩn $1.0$ của toán hạng $X$, vì $1.0 \times Y = Y$).
  - Trong các chu kỳ lặp kế tiếp (`first = 0`): Mux chọn giá trị tích lũy hiện tại của thanh ghi Accumulator để cộng dồn thêm $1.f_Y \gg S$.

#### D. Bảng diễn biến theo chu kỳ cho Test Vector TV-PAPER-01 ($n = 2$)

Xét test vector mẫu TV-PAPER-01 từ bài báo [P] (Fig. 4):

- Toán hạng $X$ có $fx =$ `12'b0100_1000_0000` (hai bit 1 tại vị trí 2 và 5 sau dấu chấm), $n = 2$.
- Bảng dưới là lịch mục tiêu của tám lần chốt (H=n+6=8), không phải số đo RTL. CK1=E0, CK8=E7: out_valid sau E7, handshake sớm nhất E8. Giá trị khớp Fig.4 có sai số cắt 12 bit, không phải tích exact.

| Chu kỳ | Tầng | Diễn biến | Ghi chú |
| :---: | :---| :---| :---|
| **CK 1** | Parser, hạng 1 | LOD/LZD, mux cnt; chốt cnt/FRB, metadata và payload seed | Giải mã regime toán hạng ngõ vào |
| **CK 2** | Parser, hạng 2 | Tạo Rgm song song với dịch trái, tách exponent/fraction, ghép sf. Chốt Reg 1 | Hoàn tất Parse (`PIPE_PARSE = 2`, quy ước cạnh tại §5.2) |
| **CK 3** | OPS | Chọn X, Y; sf = -11; dấu = 0. Chốt Reg 2 | Đặt ngõ vào cho SAC và Accumulator |
| **CK 4** | SAC vòng 1 | first = 1, sa = 2, S = 2, fx ← 0010…. Chốt Reg 3 | SAC xử lý bit 1 đầu tiên |
| **CK 5** | SAC vòng 2, Shifter vòng 1 | sa = 3, S = 5; Y >> 2. Chốt Reg 4 | Shifter nhận S=2; SAC xử lý bit 1 thứ hai |
| **CK 6** | Shifter vòng 2, Accum vòng 1 | Y >> 5; acc = Y + (Y >> 2) | Shifter nhận S=5; Accumulator cộng vòng 1 |
| **CK 7** | Accum vòng 2 | acc += Y >> 5 = 1.011100011010. Chốt Reg 5 | Accumulator hoàn tất tích mantissa; Normalizer chưa rõ nằm trong accumulator hay packer (Fig. 3 chỉ cho thấy Rgm/Exp đi vào khối accumulator) |
| **CK 8 = E7** | Packer (TRUNC, 1 hạng) | out_valid sau E7, handshake sớm nhất E8. RNE có H=9, valid sau E8, handshake E9 | Mục tiêu lịch, chưa đo RTL tích hợp |

#### E. Điều kiện chồng lấn giao dịch

Các tầng SAC/Shifter/Accumulator có thể xử lý phần khác nhau của nhiều giao dịch. Với v0/v1, mục tiêu II=max(1,n_thực_tế) chỉ áp dụng khi tài nguyên khởi tạo/n=0 đã được lịch hóa, không stalled, FIFO đủ chỗ và giao dịch độc lập. Đây là mục tiêu kiến trúc của đề tài, không phải II đã được bài báo đo.

Trong TV-PAPER-01 (§5.10-D), SAC dùng CK4..CK5, Shifter CK5..CK6 và Accumulator CK6..CK7. Giao dịch sau chỉ được bắt đầu nếu token first/last và metadata không làm ghi đè trạng thái trước. Hồi tiếp tích lũy làm tăng II (§5.11-A5).

Mỗi giao dịch mang {tag, sign, sf, C_eff, cfg, flags}; độ sâu FIFO phải suy ra từ số giao dịch đang bay và sức chứa đầu ra, không ấn định 6–8 phần tử như bảo đảm cho mọi n/backpressure.

#### F. Các điểm chưa rõ trong Fig. 3 của paper [P] và Quyết định xử lý của Đề tài

Qua việc đối chiếu sâu bản vẽ Fig. 3, đề tài ghi nhận các điểm mơ hồ kỹ thuật mà tác giả [P] chưa công bố chi tiết:

1. **Thiếu cơ chế điều khiển FSM khi $n$ biến thiên động**: Fig. 3 không mô tả mạch tạo xung `first` và bộ đếm lặp khi các giao dịch liên tiếp có số bit 1 khác nhau ($n_1 \ne n_2$). *Xử lý*: Đề tài thiết kế bộ điều khiển lặp `iter_ctrl` với bộ đếm bit 1 động và cờ `first_q` được pipeline hóa.
2. **Đường truyền trễ của Rgm và Exp (Scale Factor)**: Trong Fig. 3, đường tín hiệu từ Rgm Exp Processing đi qua các Reg rồi vào khối accumulator, nhưng bản vẽ không vẽ rõ số tầng thanh ghi trễ bên trong để đồng bộ nhịp với mantissa. *Xử lý*: baseline NF hiện tại giữ sf/sign/config trong thanh ghi context của một giao dịch; các bundle đi qua bank cùng dữ liệu. Metadata FIFO/tag chỉ áp dụng khi triển khai chồng lấn sau baseline (§5.11), chưa có trong NF tuần11.
3. **Early termination**: khi fx=0 không còn số hạng fraction để phát; vẫn phải xả các tầng còn token. TV-PAPER-01 hết bit 1 sau hai vòng nhưng vẫn có sai số cắt 12 bit (§5.6), nên không coi là exact toàn độ rộng.
4. **Bypass Zero/NaR chưa được thể hiện trong Fig. 3**: không suy ra paper đã mô tả đầy đủ đường ngoại lệ từ sơ đồ này. *Xử lý*: kết quả ngoại lệ đúng là bắt buộc; bypass rút ngắn và Order FIFO là tối ưu sau baseline, với ngân sách hạng và quy ước cạnh tại §5.3.

#### G. Các khác biệt giữa paper và baseline MAC NF — 13/10/2026

| Nội dung | Bài báo [P] / Fig.3–5 | Đồ án hiện thực `posit_mac_nf` | Ý nghĩa khi báo cáo |
| --- | --- | --- | --- |
| OPS | Paper mô tả predictor dựa trên prefix fraction; LUT, tie và toàn bộ hợp đồng nguồn chưa được xác nhận. PT2/prefix7 là nhánh nghiên cứu tái dựng riêng | Profile chính cfg_ops1 đếm toàn bộ fraction đang dùng:12 bit cao ở approx32/3, toàn F bit ở exact; chọn ít bit1 hơn, hòa giữ A. cfg_ops0 giữ A | Khác chính sách chọn X/Y; có thể đổi số vòng thực tế và sai số khi giới hạn n. Không gọi min-popcount là predictor của tác giả |
| Làm tròn | Fig.5(b) lấy12 fraction bit, đệm0 và mã hóa dấu; nguồn không mô tả tầng RNE G/R/S như đồ án | FLOOR cắt từng term trong SBM; sau đó RNE(P_hat) trước cộng và RNE tổng ở cuối NF. Metadata cut không tham gia GRS của P_hat | Phân biệt ROUND_SCHEME nội bộ và ROUND_MODE đóng gói (§4.1/§5.9). RNE không khôi phục các term đã bị cắt |
| Width/carry | Fig.3 không công bố đủ width/bit carry/cut để xác nhận RTL nguyên bản; không lấy nhãn fraction12 làm width toàn accumulator | Approx FLOOR32/3: P_hat Q12,14 bit hữu ích; bank vật lý54 bit khi EXACT_EN1 để hỗ trợ exact Q52. Adapter NF giữ cả bit thấp khi carry, không dùng sticky thay trọng số bit đó | Kết quả W11 khác biệt carry là của legacy địa phương so với hợp đồng prepack; không suy thành lỗi RTL paper. Chi tiết/bằng chứng §5.6/§11.9 |
| Scale | Khối Rgm/Exp adder xử lý regime/exponent | Dùng sf signed và cộng sfA+sfB; carry mantissa tăng sf thêm1 | Tương đương về giá trị; chưa chứng minh giảm LUT hoặc tăng Fmax (§5.10-B) |
| Pipeline/control | Fig.3 thể hiện Reg/feedback/First nhưng không đủ quy tắc valid/ready/reset/order hoặc số tầng bên trong mọi khối | Parser2 tầng; core SAC→shift→acc; product P1/P2 và một bank parse/product; adder3 tầng; packer RNE2 tầng. Context một giao dịch, reset bridge, stall và output holding theo §11.10 | L_valid=max(1,t)+12; handshake không stall thêm1; II baseline tối thiểumax(1,t)+14. Không suy số này từ năm Reg của hình; timing/Fmax còn cần STA |
| Mở rộng MAC | Fig.3 dừng ở tích A×B | NF thêm C_eff, adder, packer tổng và trạng thái acc_mode/acc_clr | NF=R(R(P_hat)+C_eff), F_ref=R(P_hat+C_eff). Fused RTL chưa được nghiệm thu; xem §5.12/§11.10 |

**Cách mô tả phạm vi:** lõi nhân kế thừa cấu trúc dịch–cộng lặp của Fig.3; đồ án chọn hợp đồng số học/OPS/pipeline riêng và mở rộng thành MAC NF. Gate3 chứng minh RTL mới khớp mô hình/oracle của đồ án trong phạm vi đã kiểm, không chứng minh đã có baseline RTL tác giả hoặc tái hiện Table I. So sánh NF/F dùng cùng P_hat, corpus và điều kiện PPA theo §11.8–§11.10; lợi ích về tài nguyên/timing phải đo, không suy từ bảng mapping.

### 5.11 Vi kiến trúc Pipeline MAC tích hợp Adder và Chồng lấn giao dịch

Khác với bài báo tham chiếu [P] chỉ dừng lại ở phép nhân hai toán hạng ($A \times B$), đóng góp trọng tâm C1 của đề tài là xây dựng hoàn chỉnh lõi **Posit MAC** ($D = A \times B + C$) với vi kiến trúc pipeline thông suốt và hiệu năng cần đo bằng STA/PPA và throughput thực tế.

#### A. Các hợp đồng tích hợp

1. **C và metadata:** baseline giữ trong thanh ghi giao dịch; khi chồng lấn dùng FIFO/tag giữ đúng {C_eff, sign, sf, cfg, flags} theo §5.10-E. Chỉ pop khi bên nhận handshake; mul_done khi Adder chưa nhận không được làm mất C.
2. **Non-fused:** giữa bộ nhân và Adder dùng hợp đồng round_unpacked ở §5.9-C. Với exact/RNE, v0/v1 phải cho cùng kết quả L0.
3. **Backpressure:** baseline có thanh ghi đầu ra giữ d/flags. Với core không thể stall, mỗi handshake đầu vào phải đặt trước một slot lưu kết quả và chỉ trả credit khi đầu ra handshake. Số giao dịch chưa trả không vượt sức chứa kết quả đã bảo đảm. Skid buffer 2 phần tử chỉ đủ hấp thụ 2 kết quả, không thay cho lưu trữ của mọi giao dịch đang bay. Registered in_ready phải tính cả giao dịch nhận ở cạnh hiện tại khi quyết định credit tiếp theo.
4. **Thứ tự:** first/last, tag và metadata đi cùng mọi số hạng; giao dịch sau không được khởi tạo accumulator dùng chung trước khi số hạng cuối của giao dịch trước đã được chốt. Zero/NaR bypass theo §5.3. FIFO, credit và lịch hóa là điều kiện bắt buộc nếu chọn chồng lấn.
5. **Tích lũy NF hiện tại:** tổng đi qua A1/A2/A3→packer RNE P1/P2; bank P2 chứa kết quả Posit,không có round_unpacked thứ hai sau adder. Wrapper commit accumulator ở cạnh đầu quan sát pack_out_valid&&!committed_q,dù out_ready0,giữ busy tới retire. Với một giao dịch,II_acc như II standalone: tối thiểumax(1,t)+14 không stall; không dùng cận4 để mô tả top đã kiểm. V2 cộng C_eff sau prepack; II_min=q+13 đã kiểm tại §11.15. Không dùng lịch stream cũ hoặc giả định fused luôn ít chu kỳ hơn NF.

#### B. Lịch NF RNE hiện hành — OPT-03

E0 là cạnh accept. q=max(1,t), t là số vòng fraction thực tế.

| Cạnh / bank | Công việc / token |
| --- | --- |
| E0, E1 | Parser A/B/C_eff P1/P2 |
| E2 | OPS/core launch; lưu C_eff và context |
| sau E(q+4) | core_done cùng acc, core_sf/sign/mode và trạng thái cut |
| E(q+5) | Product P1 chốt kết quả normalize + encode/GRS/flags |
| E(q+6) | Product P2 chốt packed product sau RNE, flags và valid |
| E(q+7) | Parse tổ hợp từ P2, chốt product unpacked/flags |
| E(q+8)..E(q+10) | Adder A1/A2/A3 |
| E(q+11), E(q+12) | Final packer P1/P2; first-valid sau E(q+12) |
| E(q+13) | Handshake không stall; commit accumulator nếu chưa commit |
| E(q+14) | Cạnh accept sớm nhất giao dịch kế tiếp |

H=2+1+(q+2)+3+3+2=q+13; L_valid=q+12, L_handshake=q+13, II_min=q+14. Tất cả đường special/early-stop đi cùng pipeline; không có bypass rút ngắn lịch. Core_done chỉ phát một chu kỳ; wrapper chỉ nhận giao dịch nếu product packer sẵn sàng, giữ reservation tới retire. Với một transaction, P1/P2 product luôn có credit khi core_done đến. Product P2 giữ data/flags nếu product bank chưa sẵn sàng; product_capture=product_pack_valid && (!norm_valid_q || add_ready). Product bank giữ tới adder handshake, cờ và C_eff không lấy lại từ input ngoài. Reset/startup dùng bridge và reset synchronizer sẵn có của packer; không thêm clock gating hoặc timing exception. Accumulator commit đúng một lần ở cạnh quan sát final valid, kể cả out_ready=0.

Product numerical sticky luôn0: FLOOR/cut/tail của iterative approximation là flags/status, không được đưa lại làm phần dư số học của P_hat. Normalize/width/F_IN và RNE không đổi. `round_unpacked_comb` vẫn là reference/unit module; top NF không đi qua nó. Standalone multiplier và fused không đổi lịch.

#### C. Tối ưu sau baseline

Áp dụng bypass (§5.3), round_unpacked (§5.9-C), chồng lấn và credit (§5.11-A) theo từng bước có regression. Trên FPGA dùng Clock Enable của thanh ghi, không dùng LUT để gate clock. CE giảm hoạt động thanh ghi được khóa; muốn kết luận công suất toàn khối phải đo theo §7.1.

#### D. Kiểm chứng pipeline

SVA tập trung ở §6.6. Yêu cầu kiểm gửi liên tục ít nhất10^6 giao dịch, chấp nhận mỗi giao dịch chỉ khi in_ready1 (không đồng nghĩa nhận mỗi chu kỳ), với n thay đổi, n=0, Zero/NaR, acc_mode/acc_clr và out_ready ngẫu nhiên/kéo thấp dài; scoreboard kiểm thứ tự, không mất/nhân đôi giao dịch. Đo riêng II khi không stalled để đánh giá mục tiêu throughput; backpressure có thể làm II lớn hơn. NF hiện chưa có FIFO transaction; nếu triển khai FIFO/chồng lấn sau này,không ép khoảng ready cố định khi FIFO đầy. W11 đã kiểm mốc numeric/protocol và phân bố coverage tại §11.12; các yêu cầu final vẫn mở.

### 5.12 MAC v2 fused (profile chính bắt buộc theo §11.8, sau NF/Gate3)

**Hợp đồng hiện hành W12-F-1:** dùng cùng P_hat từ §11.9 cho NF và F: NF=R(R(P_hat)+C_eff), F_ref=R(P_hat+C_eff). Profile F đã chốt NB32/ES3,FW12,W32/Q29,OPS0/1,n0..8,FLOOR/RNE và approximate-only. Cộng C_eff đúng một lần với prepack sau nhân,không pack/saturate tích trước cộng. L1 F_W32 đã khớp F_ref về bits/flags trong phạm vi kiểm §11.14; không đổi P_hat thành tích exact. Các sketch stream §5.6 là nghiên cứu phụ,chưa dùng cho RTL F.

V2 cộng P_hat và C_eff trước Packer cuối. Không có bước làm tròn tích về lưới Posit như v1; mất mát FLOOR/input/iteration đã thuộc phép nhân xấp xỉ. Cửa sổ có hợp đồng residual riêng; phải báo khác biệt F_W/F_ref tách khỏi F_ref/Ideal. Không tuyên bố profile approximate khớp p32_mulAdd của A/B gốc.

**Trạng thái thiết kế:** oracle/L1 đóng băng tuần12; RTL posit_mac_f đã triển khai và kiểm profile chính tại §11.15. F1–F5, raw prepack, flags, reset/stall/acc_mode đã kiểm 10M giao dịch và event simulator. Chưa nghiệm thu final per-n/AC04, exact F, format phụ, CDC/RDC hoặc paired PPA/Gate4. Request exact bị từ chối trước handshake, không âm thầm đổi thành approximate.

#### a. Căn chỉnh Scale Factor và Chọn Mốc (Scale Alignment & Anchor Selection)
Với P_hat=M×2^(scale-q),đặt h_P=msb(M),e_P=scale+h_P-q và m_P=M/2^h_P∈[1,2). Đây là chuẩn hóa bảo toàn giá trị,không round hoặc bỏ bit carry. C_eff có m_C=1.f và scale sf_C. Chênh lệch dùng **scale tích đã chuẩn hóa**:
$$\Delta SF = sf_P - sf_C$$

Trong công thức này sf_P≡e_P; không dùng trực tiếp sf_A+sf_B khi tích có carry. Bỏ qua toán hạng zero khi chọn anchor=max(e_P,sf_C). Với W32,Q29,đơn vị lưới là2^(anchor-Q); mỗi magnitude sau căn chỉnh được floor trên độ lớn,trước khi áp dấu. Không dùng arithmetic-right-shift của số âm thay floor magnitude.

Căn cứ vào giá trị $\Delta SF$, mạch điều khiển xác định toán hạng làm mốc (Anchor) và cấu hình lượng dịch:

| Điều kiện | Mốc Scale Factor ($sf_{\text{base}}$) | Căn chỉnh toán hạng $C'$ nạp vào Accumulator | Lượng dịch thêm cho số hạng tích (`shift_extra`) |
| :--- | :---: | :--- | :---: |
| $\Delta SF \ge 0$ | **Tích** (anchor=e_P) | Dịch seed C phải ΔSF | Seed P không dịch thêm |
| $\Delta SF < 0$ | **C** (anchor=sf_C) | Seed C không dịch thêm | Dịch seed P phải −ΔSF |

Không có shortcut bỏ term/vòng chỉ từ |ΔSF|>F+2 trong hợp đồng fused hiện hành. Với cửa sổ hữu hạn,phải mô hình residual có dấu và chứng minh quyết định cuối trước khi áp clamp hoặc early termination.

#### b. Hậu xử lý

Sau căn chỉnh,cộng/trừ retained magnitude và xử lý residual theo mục c. Với magnitude dương đã sửa borrow,đặt h=msb(mag),sf_final=anchor+h-Q. Chuyển phần fraction dưới hidden và positive numerical tail sang packer cuối; giữ G/R và các bit thấp còn trong magnitude. Cửa sổ gồm1 sign+2 integer+29 fraction; không dùng số leading-zero toàn vector làm lượng giảm sf trực tiếp. Nếu chuyển về mantissa64 bit của L1,mọi bit bỏ khi thích nghi độ rộng phải OR vào numerical tail.

Adapter W32→F_IN53 có thể normalize magnitude31 bit về hidden30,rồi nối23 bit0 sau30 fraction bit. Residual ngoài word là mô tả nonzero,không phải giá trị dyadic chính xác. Cận ở mục c đảm bảo nó luôn dưới G/R cuối khi có tail,nên ánh xạ này bảo toàn quyết định RNE/flags;không gọi padding/sticky là khôi phục đầy đủ giá trị phần dư.

Sau chuẩn hóa, Packer làm tròn theo §5.9. Phần dư phải được chuyển sang thông tin G/R/S của độ lớn theo chính sách có dấu đã kiểm chứng; không gắn một sticky OR chung vào tổng khác dấu rồi tuyên bố RNE exact.

#### c. Phần dư có dấu và điều kiện exact

Viết mỗi số hạng magnitude y=y_trunc+δ, với 0≤δ<2^-Q; sticky chỉ cho biết δ khác 0, không phải δ=2^-Q. Với số hạng âm: -y=-y_trunc-δ. Do đó không OR đuôi rồi coi tất cả là phần dư dương, cũng không trừ một LSB tùy tiện ở mọi vòng. Tổng nhiều δ có thể tạo carry và triệt tiêu có thể đưa đuôi trở thành bit có nghĩa.

**Policy post-prepack đã kiểm:** Q≥max(F,FW+1)+3; với32/3,FW12,Q29 thỏa. Toán hạng lớn fit chính xác và chỉ toán hạng nhỏ có thể sinh một residualδ∈(0,1) theo đơn vị lưới. Cắt chỉ xảy ra khi |ΔSF|≥4,do đó khác dấu có residual chỉ normalize trái tối đa1 bit; còn ít nhất hai bit dưới fraction tối đaF26. G/R giữ trong word và cờ tail bên dưới đủ quyết định RNE trên miền đã nhận. Đây là cận cho **hai toán hạng sau prepack**,không bao quát stream nhiều term hoặc tích exact52 bit fraction.

Nếu residual cùng dấu với retained sum,giữ magnitude và positive tail. Nếu ngược dấu,đổi |Z|−δ thành (|Z|−1)+(1−δ): trừ đúng1 đơn vị lưới khỏi magnitude và giữ tail dương. Không jam1 vào số nhỏ trước trừ,không trừ1 ở mọi vòng. Trường hợp retained sum0 nhưng residual≠0 phải assertion/fail; theo cận trên nó không xuất hiện trong profile đã nhận. Triệt tiêu exact không có residual. Đổi width,precision,topology hoặc hỗ trợ exact cần chứng minh/kiểm mới.

Flags: NaR ưu tiên10000; sat_max/min chỉ từ tổng fused cuối. inexact gồm metadata input/term/iteration và mất mát số học cuối; approx_cut chỉ iteration còn bỏ. Zero giữ metadata hữu hạn trước đó. C_eff lấy từ c hoặc accumulator riêng của F; acc_clr chỉ tại request được nhận. Accumulator làm tròn sau từng giao dịch FMA và commit một lần; không giữ lịch sử flags của các giao dịch cũ như một quire.

Đối với exact fused, dùng số nguyên rộng hoặc Fraction làm oracle và giữ đủ toàn bộ tích/tổng trước RNE. Một lựa chọn tham chiếu an toàn là lưới cố định 2^(-2·SF_MAX) với số nguyên có dấu rộng 4·SF_MAX+3 bit (27 bit posit8, 115 bit posit16); đây là độ rộng bảo thủ, không phải yêu cầu phải dùng quire cho RTL. Giới hạn đó áp cho tích exact từ input Posit hợp lệ,không tự bao quát mọi record prepack giả định. F full-sum hiện dùng lưới bảo thủ2^-(2SF_MAX+2F),4SF_MAX+2F+4 bit dự phòng (32/3:2^-532,16 limb64 bit); đây là software oracle,không phải cửa sổ RTL. Cửa sổ hẹp hơn chỉ được gọi exact khi chứng minh cùng kết quả trên miền nghiệm thu; nếu approximate phải đo lỗi riêng. Công thức gần 3·(FRAC_MAX+1) không bao quát tự động chênh scale và triệt tiêu toàn miền.

#### d. Các Trường hợp Đặc biệt (Special Corner Cases)
- **$C_eff = 0$**: có thể dùng đường nhân với cùng profile chính xác và dấu; lịch vòng hidden bit/độ trễ phải ghi rõ.
- **Tích bằng 0 ($A = 0$ hoặc $B = 0$)**: kết quả C_eff nếu không có NaR; posit_mac_f dùng init-only rồi F1–F5/packer, L_valid=12 và H=13 khi không stall; đã kiểm §11.15.
- **NaR**: A/B/C_eff là NaR thì xuất NaR ưu tiên; latency bypass theo §5.3; posit_mac_f hiện chạy init-only với t=0 rồi F1–F5/packer, L_valid=12 và H=13, không bypass hai chu kỳ.
- **Triệt tiêu**: zero của kết quả nội bộ phải xét cả phần dư theo §5.12-c. Approx không được suy ra đã triệt tiêu chính xác tích thật chỉ từ acc=0.

#### e. Máy trạng thái điều khiển (FSM) của MAC v2
Pipeline đã hiện thực và kiểm tại §11.15: parse2 → OPS/init1 → core q+2 → F1(anchor/seeds/delta) → F2(shift/tail) → F3(signed add/sub) → F4(abs/borrow) → F5(normalize/scale/adapter) → packer RNE P1/P2. q=max(1,t) với t số iteration thực tế. H_handshake=q+12,L_valid=q+11,II tối thiểuq+13 cho top một giao dịch và chỉ nhận lại sau retire. n0/t1 đã kiểm valid sauE12,handshakeE13,nhận lạiE14. Thay stage khi timing yêu cầu phải sửa lịch,metadata/valid/reset/scoreboard và SPEC trước công bố. Không gắn thêm FF vào hồi tiếp SAC rồi giữ nguyên công thức số vòng/II.

#### f. Hai Ví dụ Số Kiểm Chứng Chi Tiết (Golden Test Vectors)
Hai ví dụ toán học dưới đây không mất bit ở Q12,n đủ hoàn tất fraction đã chọn; diễn giải bằng topology post-prepack,không gán chu kỳ stream cho RTL F chưa có.
1. **TV-FUSE-01 (Mốc Tích, $\Delta SF \ge 0$)**:
   - $A = 10 = 1.25 \times 2^3$ ($sf_A = 3, m_A = 1.01_2$); $B = 0.34375 = 1.375 \times 2^{-2}$ ($sf_B = -2, m_B = 1.011_2$).
   - $sf_P = 3 + (-2) = 1$. $C = 0.5 = 1.0 \times 2^{-1}$ ($sf_C = -1, m_C = 1.0_2$).
   - $\Delta SF = 1 - (-1) = 2 \ge 0 \implies$ Mốc = Tích ($sf_{\text{base}} = 1$), $\text{shift\_extra} = 0$.
   - $C$ căn chỉnh: $C' = 1.0 \gg 2 = 0.25$.
   - Tích prepack: $P=1.25\times1.375\times2^1=1.71875\times2^1$.
   - Cộng theo anchor1: $1.71875+0.25=1.96875$; không round tích trước phép cộng.
   - Vì $\text{acc} = 1.96875 \in [1, 2)$, không cần dịch chuẩn hóa. Giá trị kết quả: $1.96875 \times 2^1 = \mathbf{3.9375}$.
2. **TV-FUSE-02 (Mốc C, $\Delta SF < 0$)**:
   - Cùng $A, B \implies sf_P = 1$. $C = -8 = -1.0 \times 2^3$ ($sf_C = 3, s_C = 1, m_C = 1.0$).
   - $\Delta SF = 1 - 3 = -2 < 0 \implies$ Mốc = $C$ ($sf_{\text{base}} = 3$). Lượng dịch thêm: $\text{shift\_extra} = -\Delta SF = 2$.
   - P căn anchor3: $1.71875\times2^{-2}=0.4296875$.
   - Cộng hai magnitude có dấu: $0.4296875-1=-0.5703125$; residual0 nên không sửa borrow.
   - Hậu xử lý: $\text{acc} < 0 \implies sign = 1, |\text{acc}| = 0.5703125 = 1.140625 \times 2^{-1}$ (LZC = 1).
   - Chuẩn hóa: dịch trái 1 bit $\implies 1.140625$, cập nhật scale factor: $sf_{\text{final}} = 3 - 1 = 2$.
   - Kết quả: $-1.140625 \times 2^2 = \mathbf{-4.5625}$.

### 5.13 MAC top và điều khiển

Top đã có là posit_mac_nf structural; điều khiển ở mac_nf_wrapper bằng busy/valid/committed và handshake giữa leaf. iter_ctrl có state/register riêng cho phát token/drain. Không có FSM tuần tự top mang các state ADD_A1/ADD_A2/ADD_A3 như mô tả hành vi cũ; ba tầng adder tự chuyển token.

Luồng hành vi: nhận A/B/C_eff/config nguyên tử → parse → OPS launch → core/drain → norm/round bank → adder → packer → giữ output tới retire. Một bank norm/round,packer P2 là output bank; không thêm HOLD_OUTPUT register hoặc skid buffer ngầm. Output-commit và startup/reset theo §4.2/§11.10. V0 và fused top chưa hiện thực trong nhánh NF này; tối ưu bypass/chồng lấn cần contract/lịch mới và regression trước công bố.

---

## 6. Golden model và kiểm chứng

### 6.1 Ba tầng đối chiếu

| Tầng | Vai trò | So với RTL |
| --- | --- | --- |
| **L0** | SoftPosit (`p8_*`, `p16_*`, `p32_*`, các hàm `convertDoubleToP32`, `convertP32ToDouble`, `p32_mul`, `p32_add`, `p32_mulAdd`) | Chế độ exact: bit-exact. Chế độ approx: thống kê sai số (Err, MSE) |
| **L1** | Legacy khác week11::Model của NF; F_W32 và full-grid oracle đã kiểm theo W12-F-1 | Bit-exact theo từng profile; F32/3 approx FW12 đã đóng G-F-L1,không suy exact F hoặc RTL F đã đạt |
| **Ideal** | Tích/tổng chính xác của hai giá trị thực bằng số nguyên rộng (`unsigned __int128` cho mantissa, hoặc Python `fractions.Fraction`) | Dùng để tính Err theo định nghĩa của [P] |

Lý do cần tầng Ideal riêng: mỗi significand Posit32/ES2 có tối đa28 bit kể cả hidden,tích có thể dài56 bit, vượt độ chính xác 53 bit của `double`, nên không được dùng `double` làm chuẩn ở posit32.

**Nguyên tắc độc lập và thẩm định L1 trước khi kiểm chứng RTL**:

- Do mô hình thuật toán L1 (C++) và mã nguồn RTL (SystemVerilog) đều do cùng một tác giả xây dựng, rủi ro lớn nhất là **sai lệch nhận thức hệ thống (systematic common-mode bias)**: tác giả hiểu sai thuật toán từ lý thuyết và hiện thực cái sai đó lên cả C++ lẫn SystemVerilog. Khi đó, tiêu chí AC-01 (RTL khớp L1 100%) vẫn có thể đạt được dễ dàng nhưng cả hai thiết kế đều sai lệch so với chuẩn toán học Posit.
- **Quy định bắt buộc (Mandatory Prerequisite Gates)**: Mô hình L1 cần kiểm định độc lập đúng format: L0 SoftPosit cho8/0,16/1,32/2; integer/rational độc lập cho32/3 và các hợp đồng prepack/F. Khớp L1 cùng tác giả không tự thay bằng chứng oracle. Quy trình nghiệm thu L1 được chia thành hai mốc thực tế:
  - **Gate 1 (Tuần 3 — Parser, Packer và L1 Multiplier Exact)**: L1 parser/packer và bộ nhân ở chế độ exact bắt buộc phải pass 100% không sai lệch (0 mismatch) so với L0:
    - Vòng khép kín Parser $\rightarrow$ Packer: là phép đồng nhất 100% trên toàn bộ chuỗi bit hợp lệ của `posit8` ($2^8$) và `posit16` ($2^{16}$).
    - Nhân exact (`l1_mul` vs `p<N>_mul`): $2^{16}$ cặp nhân `posit8`, $2^{32}$ cặp nhân `posit16`, toàn bộ corner list (§6.4) và $\ge 10^7$ vector ngẫu nhiên phân tầng `posit32`.
  - **Gate 1B (Tuần 6 — L1 Adder và Full MAC Suite)**: Hoàn tất L1 Adder và MAC, đối chiếu bit-exact 100% với SoftPosit trước khi bắt đầu chuyển sang code RTL:
    - Cộng exact (`l1_add` vs `p<N>_add`): $2^{16}$ cặp cộng `posit8`, $2^{32}$ cặp cộng `posit16`, corner list và $\ge 10^7$ vector phân tầng `posit32`.
    - MAC exact (`l1_mac` vs `p<N>_add(p<N>_mul(a,b), c)`): $2^{24}$ bộ ba MAC `posit8`, corner list và $\ge 10^7$ vector phân tầng `posit32` (cho cả MAC non-fused và `acc_mode`).

### 6.2 Lưu ý khớp SoftPosit

- SoftPosit dùng `posit8: ES=0`, `posit16: ES=1`, `posit32: ES=2`. Vì vậy chỉ ba cấu hình này đối chiếu trực tiếp được. Với32/3 phải dùng oracle integer/rational độc lập đúng ES3 để kiểm L1/RTL. Chạy cùng mã ở ES2 với SoftPosit là kiểm bổ trợ,không chứng minh ES3 đúng. RNE tại đây là hợp đồng encode/GRS/range đã chốt,không coi chuyển format qua double là oracle.
- Cần kiểm tra phiên bản SoftPosit đang dùng (kiểu `ES` của p16) và ghi vào log; nếu thư viện cập nhật theo chuẩn mới (mọi kích thước dùng `ES=2`) thì khóa lại profile/oracle, kiểm lại trước khi đổi bảng; không tự sửa định dạng một nhánh đã đóng băng.
- Chạy `p32_mul` và `p32_add` tách rời cho FR-10; `p32_mulAdd` cho FR-11.

### 6.3 Sinh vector và Phân tầng kiểm chứng (Stratified Sampling)

**Vấn đề bão hòa thống kê khi dùng Uniform Random**:

- Cấu trúc số Posit phân bổ độ dài regime theo quy luật hình học: xác suất một chuỗi ngẫu nhiên 32-bit có regime dài $m$ giảm dần theo $2^{-m}$. Nếu chỉ dùng phân phối đều theo bit (Uniform bit distribution), trên 87.5% số vector sinh ra sẽ có $m \le 3$ (quanh giá trị 1.0), trong khi xác suất rơi vào các số cực nhỏ hoặc cực lớn ($m \ge 20$) là gần như bằng 0 (ví dụ $m=28$ có xác suất $2^{-28} \approx 3.7 \times 10^{-9}$).
- Hậu quả: Quá trình test dù chạy hàng chục triệu vector ngẫu nhiên vẫn tạo ra **cảm giác an toàn giả tạo (false confidence)**, vì các mạch dò dấu (LOD/LZD) ở độ sâu lớn, các tầng dịch barrel shifter quy mô lớn, và các trường hợp fraction bị cắt ngắn cạn kiệt bit hoàn toàn chưa hề được kích thích.

**Chiến lược Phân tầng bắt buộc (Stratified Sampling trong C++/SV)**:

1. **Phân chia nhóm regime (quy định của đề tài)**: Chia độ dài regime $m$ thành 8 nhóm: $G_1=[1,3], G_2=[4,7], G_3=[8,11], G_4=[12,15], G_5=[16,17], G_6=[18,22], G_7=[23,27], G_8=[28,31]$.
   - Lưới phân tầng: mỗi ô $(nhóm\ m_A, nhóm\ m_B, cặp\ dấu) = 8 \times 8 \times 4 = 256$ ô; mỗi ô bắt buộc $\ge 4000$ vector $\rightarrow \approx 1.02 \times 10^6$ vector cho một cấu hình cơ sở.
2. **Kích hoạt các trường hợp biên cấu trúc (Structural Edge Cases)**:
   - **Regime tối đa**: Ép sinh $m = NB - 1$ (chuỗi bit chỉ có sign và regime, không còn exponent và fraction) và $m = NB - 2$ (run và terminator đã chiếm hết payload; không còn exponent/fraction).
   - **Mantissa đặc thù**: Ép sinh các toán hạng có fraction toàn 1 (`1.111...1`), fraction toàn 0 (`1.000...0`), và các mẫu bit xen kẽ (`1.0101...`, `1.1010...`).
   - **Bao phủ regime**: trên độ lớn sau bù hai, mỗi polarity và độ dài run hữu hạn hợp lệ phải đạt ≥10^4 lượt toán hạng trong suite nghiệm thu posit32. Run 0 dài NB-1 là Zero, không phải số hữu hạn khác 0; kiểm riêng bằng corner. cnt ở parser bằng m-1, không nhầm với m. TB LOD/LZD độc lập phải phủ vị trí và nhánh invalid.
3. **Phân tầng theo số bit 1 của FracX**: (0, 1, 2, 3–4, 5–8, > 8) để phủ mọi kịch bản dừng sớm (early termination) và cắt xấp xỉ của vòng lặp $n$.
4. **Kích hoạt đường triệt tiêu (chỉ suite Adder/MAC)**: Tối thiểu 30% giao dịch hoàn tất trong suite nghiệm thu phải có hai toán hạng cộng hữu hạn khác 0, trái dấu và $|\Delta sf| \le 4$. Với NF, đo ở đầu vào adder thực tế: tích đã làm tròn `R(P_hat)` và `C_eff`; với adder đơn vị, đo hai input unpacked. Với F, đo tích prepack chuẩn hóa và `C_eff` trước cut của cửa sổ, đồng thời kiểm thêm sau cut. Đây là kích thích near-cancellation, không yêu cầu mọi cặp phải triệt tiêu ra zero.

   Lưu trực tiếp các counters Δsf=0,1,2,3,4 và mẫu số; báo riêng standalone/acc_mode, specials và reset-abort. Specials không được tính vào tử số, reset-abort không được tính như giao dịch hoàn tất. Không dùng raw port C khi acc_mode bỏ qua nó, hoặc dùng bucket2–7 để khẳng định tỷ lệ nhóm≤4 đã đạt.

**Tách hai profile**: phân tầng trên dùng kiểm chứng cấu trúc, không thay phân bố tái hiện Table I/II. Theo Fig. 6, Table I sinh FP32 rồi chuyển sang Posit (32,3), giới hạn m≤15; Table II sinh FP64 rồi chuyển sang Posit (32,3), m≥18, chuẩn là bộ nhân Posit exact. Ghi thuật toán chuyển đổi, seed, miền, cách chọn mA/mB và phân bố ở Phụ lục B. [P] chưa công bố đủ phân bố của 200 triệu cặp; N lớn không tự bảo đảm khớp tỷ lệ paper.

### 6.4 Corner list bắt buộc (posit32; tương tự cho posit8/16)

| Mã | Giá trị |
| --- | --- |
| zero | `0x00000000` |
| NaR | `0x80000000` |
| +1 / -1 | `0x40000000` / `0xC0000000` |
| minpos / -minpos | `0x00000001` / `0xFFFFFFFF` |
| maxpos / -maxpos | `0x7FFFFFFF` / `0x80000001` |

Tổ hợp bắt buộc: `NaR×0`, `0×NaR`, `maxpos×maxpos → maxpos`, `minpos×minpos → minpos`, `(-maxpos)×(-maxpos) → maxpos`, `maxpos×minpos` (ES=2: đúng bằng 1 = `0x40000000`), `maxpos + maxpos → maxpos`, `x + (-x) → 0`, `1 + minpos`, các cặp hòa RNE (TV-RND-01/02), và mọi cặp thuộc "regime tối đa" (m = NB-1).

**Tập vector kiểm chứng đặc thù cho Fused MAC (v2, §5.12)**:
- Vector kiểm tay mẫu: **TV-FUSE-01** (mốc Tích, $\Delta SF = 2$) và **TV-FUSE-02** (mốc C, $\Delta SF = -2$).
- Các trường hợp biên chênh lệch scale: $|\Delta SF| = \text{FRAC\_MAX} + 2$ và $|\Delta SF| = \text{FRAC\_MAX} + 3$ (kích hoạt ngưỡng rơi rụng bit hoàn toàn thành sticky).
- Triệt tiêu chính xác ($C = -A \times B$ cho kết quả 0): kiểm tra cơ chế triệt tiêu hoàn toàn và cờ zero.
- Triệt tiêu gần đúng ($C \approx -A \times B$ với dấu ngược nhau): sinh ra mantissa rất nhỏ, kích hoạt các mức LZC lớn (LZC > 15) để kiểm tra bộ dịch chuẩn hóa trái.
- Các trường hợp ranh giới: $C = 0$ và Tích $= 0$ ($A=0$ hoặc $B=0$).

### 6.5 Kiến trúc testbench

Hai đường chạy dùng chung một bộ vector và chung L0/L1:

**Đường A (nhanh, chính thức cho AC-01/02)**: Verilator + harness C++. C++ gọi trực tiếp oracle đúng format và L1; so giao dịch/flags,ghi counters/hash và failure khi có. NF hiện lưu summary JSON,không ghi CSV từng vector10M. Mục tiêu 10^7 đến 10^9 vector.

**Đường B hiện thực:** ModelSim testbench thủ tục replay fixture đã được generator/oracle đối chiếu; dùng kiểm4-state,CK2Q,reset/stall/context/latency. Đây là luồng W10/W11 đã chạy,không gọi là UVM/DPI-C.

**Đường B mở rộng (UVM-lite, MAY, chưa hiện thực):** testbench SystemVerilog dạng lớp (class) gồm: `sequence_item` (a, b, c, cfg), `generator` (ràng buộc ngẫu nhiên theo §6.3), `driver` (bắt tay valid/ready), `monitor`, `scoreboard` (gọi L0/L1 qua **DPI-C**), `coverage collector` (covergroup). Chạy trên trình mô phỏng hỗ trợ class và covergroup đầy đủ (Questa/VCS/Xcelium nếu trường có; xsim hỗ trợ hạn chế, phải kiểm tra). Nếu chỉ có Verilator thì đường B chỉ dùng phần class được hỗ trợ và coverage lấy từ đường A.

Nguyên mẫu DPI-C:

```systemverilog
import "DPI-C" function int unsigned l0_p32_mul   (input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned l0_p32_add   (input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned l0_p32_mulAdd(input int unsigned a, input int unsigned b, input int unsigned c);
// API scalar exact RNE đã triển khai ở tuần6:
import "DPI-C" function int unsigned l1_p32_mul   (input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned l1_p32_mac   (input int unsigned a, input int unsigned b, input int unsigned c);
// API fused dưới đây là dự kiến cho mục tiêu chính tuần11–14, chưa triển khai:
import "DPI-C" function int unsigned l1_mac_fused (input int unsigned a, input int unsigned b, input int unsigned c,
                                                   input int mode, input int n, input int ops, input int frac_w);
```

### 6.6 Kiểm tra khẳng định và bao phủ chức năng

**Khẳng định (SVA)**

| ID | Nội dung |
| --- | --- |
| A-01 | Không có X trên `d`, `flags`, `out_valid` sau reset |
| A-02 | out_valid && !out_ready ⇒ d, flags và out_valid giữ nguyên chu kỳ kế, trừ cạnh reset hủy giao dịch |
| A-03 | Số vòng lặp thực tế ≤ `cfg_n` khi `cfg_mode=1` |
| A-04 | Đường exact: `fx == 0` tại thời điểm hoàn tất |
| A-05 | Đầu ra NaR ⇔ A/B/C_eff là NaR; xét NaR của C_eff/accumulator và acc_clr theo giao dịch, ưu tiên NaR hơn Zero |
| A-06 | Đầu ra là zero chỉ khi (có A=0 hoặc B=0 với C_eff=0) hoặc triệt tiêu đúng hai operand của profile (NF: R(P_hat)+C_eff; F: P_hat+C_eff trước window cut) |
| A-07 | Giữa hai lần reset: mỗi input nhận có đúng một output đúng thứ tự khi downstream cuối cùng sẵn sàng; reset hủy pending và không trả lại giao dịch cũ |
| A-08 | Không ghi đè token/metadata/accumulator; occupancy không vượt capacity. Kiểm điều kiện first/last/credit, không dùng II>=n thay chứng minh an toàn |
| A-09 | in_ready chỉ lên khi run_ready và đủ slot/tài nguyên; baseline tối đa một giao dịch. Khi tối ưu, đo II từ handshake không stall và kiểm lịch đã chốt thay vì coi mục tiêu II là kết quả |
| A-10 | MAC v2: cộng tích lũy không tràn signed ACC_WIN; kiểm bằng phép cộng mở rộng 1 bit, không chỉ nhìn hai bit nguyên |
| A-11 | MAC v2: quyết định zero xét cả accumulator và phần dư có dấu theo hợp đồng §5.12-c; không lấy acc==0 đơn độc khi còn đuôi |

**Covergroup (rút gọn)**

- `cross(nhóm mA, nhóm mB, cặp dấu)` = 256 bin, tất cả phải trúng.
- `n_thuc_te ∈ {0,1,2,3,4,5–8,>8}` × `cfg_mode`.
- Adder (v0/v1): `d = sfΔ ∈ {0, 1, 2–7, 8–FRAC_MAX, > FRAC_MAX}` × `cùng dấu/khác dấu` × `{tràn, không đổi, triệt tiêu LZC ∈ {1, 2–4, 5–15, >15}}`.
- Fused MAC (v2): `cross(mốc ∈ {tích, C}, dấu ∈ {cùng, khác}, |ΔSF| ∈ {0, 1, 2–7, 8–FRAC_MAX+2, > FRAC_MAX+2})` × `{triệt tiêu LZC ∈ {0, 1, 2–4, 5–15, >15}}`.
- Packer: `{làm tròn lên, xuống, hòa-lên, hòa-giữ, bão hòa max, bão hòa min, carry sang regime}`.

Nhóm regime 256 bin áp dụng posit32; với NB nhỏ hơn phải cắt các khoảng theo NB-1 và loại nhóm rỗng. Các cross phụ thuộc cấu hình (n>8, popcount>8 ở posit8, mốc v2 khi v2 chưa triển khai...) không được coi là bin bắt buộc không thể đạt. Báo cáo phải nêu số bin hợp lệ, số đã phủ và lý do loại từng bin.

### 6.7 Ma trận cấu hình hồi quy

| Nhóm | (NB, ES) | FRAC_W | cfg_mode / n | OPS | Số vector | Kiểm |
| --- | --- | --- | --- | --- | --- | --- |
| Exact posit8 | (8,0) | 5 | exact | 0 | exhaustive | L0 bit-exact |
| Exact posit16 | (16,1) | 12 | exact | 0 | exhaustive mul/add; MAC ≥ 10^9 | L0 bit-exact |
| Exact posit32 | (32,2) | 27 | exact | 0,1 | ≥ 10^8 | L0 bit-exact |
| Approx posit32-paper | (32,3) | 12 | n ∈ {0,1,2,3,4,5,6,8} | 0,1 | ≥ 10^7 mỗi điểm bắt buộc | L1 bit-exact; Ideal/posit exact ES=3 thống kê, không dùng p32 ES=2 làm chuẩn cùng giá trị |
| Approx posit32 | (32,2) | 12 | n ∈ {1,2,3,4} | 0,1 | ≥ 10^7 mỗi n | L1 bit-exact; L0 thống kê |
| NF/F profile so sánh chính (MUST, cả hai bản) | (32,3) | 12 | approx; n ∈ {0,1,2,3,4,5,6,7,8} | 1 | ≥ 10^7 mỗi n và mỗi bản, FLOOR/RNE | NF=L1 NF; F_W=L1 F_W sau §5.12-c; oracle ES3 integer/rational cho kiểm reference/accuracy, không dùng SoftPosit ES2 |
| v2 approx posit32 bổ trợ (MAY) | (32,2) | 12 | n ∈ {1,2,3,4} | 0,1 | ≥ 10^7 mỗi n/OPS nếu triển khai | L1 fused sau khi chốt §5.12-c; p32_mulAdd thống kê |
| v2 exact posit8 (MAY) | (8,0) | 5 | exact | 0 | exhaustive (2^24) nếu triển khai | p8_mulAdd bit-exact, oracle đủ rộng |
| Quét FRAC_W (MAY) | (32,2) hoặc (32,3) | 8, 12, 16, 23 | n = 3 | 1 | ≥ 10^6 | Cho EXT-B |

Ma trận final khác ngưỡng Gate 1/1B ở §6.1. Hàng NF/F profile chính bổ sung, không thay hoặc giảm các hàng bắt buộc đã có. F32/3 OPS1/FLOOR/RNE là MUST; exact fused posit8 và F32/2 vẫn MAY. Nghiệm thu F gồm cả acc_mode/control/flags và coverage §6.6 hợp lệ; chọn test/corpus trước chạy. Tách theo module: final legacy multiplier vẫn kiểm exact/RNE,approx/RNE+STICKY_ACC và local TRUNC+FLOOR theo phạm vi công bố; không gọi local TRUNC là RTL tác giả. Final NF/F so sánh chính dùng FLOOR/RNE và cùng P_hat. NF top hiện không expose JAM/TRUNC; không dùng nghiệm thu legacy để suy NF/F đã hỗ trợ hai mode đó. Chạy từng OPS và n đã liệt kê; tổ hợp ROUND_MODE/SCHEME khác là MAY và phải có regression nếu công bố hỗ trợ. n=0 luôn có test đơn vị/corner cho mọi profile, dù không phải mỗi hàng đều chạy 10 triệu mẫu ở n=0.

### 6.8 Chỉ số sai số

Gọi `y` là kết quả xấp xỉ (giải mã sang số thực chính xác), `r` là chuẩn (Ideal hoặc L0 tùy bảng).

```
Err(%)        = |r - y| / |r| × 100                       // theo [P]/[15]/[18]
CorrectRate(θ)= tỉ lệ vector có Err < θ, θ ∈ {0.1, 0.5, 1.0, 5.0} (%)
NMSE          = (1/N) Σ ((r - y)/r)^2                     // MSE tương đối, ghi chú bên dưới
MaxErr        = max Err
ULP-distance  = |signed_code(y) - signed_code(RNE(r))|        // số bậc Posit giữa hai mã cùng NB/ES
```

Loại NaR khỏi các chỉ số số thực và báo riêng số lượng ngoại lệ. Khi r=0, không chia cho r: nếu y=0 ghi zero-match, nếu y≠0 báo số ca sai và sai số tuyệt đối riêng. N trong Err/NMSE là số mẫu hữu hạn có r≠0; không tính NaR/zero bị loại như mẫu đạt. RNE(r) là mã reference cùng NB/ES; r Ideal có thể không biểu diễn được trực tiếp. signed_code là mã Posit diễn giải bù hai, tính hiệu bằng số nguyên đủ rộng; ULP-distance là khoảng cách mã, không phải độ dài ULP cố định trên toàn dải.

ES=3 có dải xấp xỉ 10^±72, ES=2 xấp xỉ 10^±36; MSE tuyệt đối dễ bị các giá trị lớn chi phối. Báo cáo cửa sổ/miền và phân bố mẫu. Table I dùng Ideal theo Fig. 6(a). Table II của [P] dùng posit exact ES=3, nên p32 SoftPosit ES=2 không dùng trực tiếp; cần oracle Posit (32,3) độc lập đủ chính xác.

**Độ tin cậy thống kê** (khoảng tin cậy 95% của một tỉ lệ `p`, `±1.96·√(p(1-p)/N)`):

| N | p = 0.50 | p = 0.95 |
| --- | --- | --- |
| 10^6 | ±0.098% | ±0.043% |
| 10^7 | ±0.031% | ±0.0135% |
| 10^8 | ±0.0098% | ±0.0043% |

Với sai khác giữa "Proposed" và "Kim" ở Table I chỉ 0.0 đến 0.8 điểm phần trăm, N=10^7 là mốc mẫu của kế hoạch,không tự bảo đảm khác biệt có ý nghĩa thống kê; cần effect size,khoảng tin cậy và paired comparison đúng corpus.

Công thức khoảng tin cậy trên giả định mẫu Bernoulli độc lập cùng phân phối. Khi ép các tầng có trọng số khác nhau, báo cáo theo từng tầng hoặc dùng ước lượng có trọng số; không suy rộng tỷ lệ gộp 256 ô cân bằng thành tỷ lệ của dữ liệu ứng dụng.

### 6.9 Quy trình hồi quy và tiêu chí đạt/hỏng

| Luồng đã có | Lệnh/nguồn thực tế | Giới hạn |
| --- | --- | --- |
| Legacy Gate2 | make lint/smoke/regress/cov và scripts/audit_gate2_acceptance.py | Chỉ multiplier16 profile; không tự chạy NF/F final |
| Adder W10 | prepare_week10_adder.sh,verify_week10_adder_verilator.sh,runner ModelSim,audit_week10_adder.py | Scope đơn vị theo report |
| NF W11 checkpoint13/10 | verify_week11_mac.sh,verify_week11_modelsim.ps1,audit_week11_mac.py | 10M aggregate/main,fixture4-state,raw coverage; chưa phân bố near30% hoặc final per-n matrix |
| NF W11 coverage14/10 | prepare_nf_coverage.sh,verify_nf_coverage.sh,verify_nf_coverage_modelsim.ps1,audit_nf_completion.py; suite nf_corners riêng | Main mới10M/0 mismatch,near52,55548%,coverage chức năng/corner đạt; chưa final per-n/F/PPA |
| F pilot | test_week11_fused.cpp,check_week11_fused.py | Full-sum software100k,không RTL/window F |

Build/generate fixtures trước audit sau cleanup; lệnh cụ thể tại PLAN8.4/8.6 và doc/HUONG_DAN_CHAY_WSL_MODELSIM.md. Audit phải từ chối RUNNING,thiếu log/fixture hoặc nguồn/hash đổi. --no-timing dùng kiểm chu kỳ; ModelSim giữCK2Q/4-state; strict lint dùng --timing -Wall. Các luồng này không thay STA/CDC/RDC.

FAIL khi mismatch RTL/L1 hoặc exact/oracle đúng format; giữ seed/input/config và kết quả để tái lập. Harness13/10 in serial/expected/actual; harness coverage14/10 xuất thêm A/B/C_port/C_eff/config và expected/actual/flags vào failure JSON khi mismatch số học. Tự tạo regression và artifact cho mọi lỗi protocol vẫn còn mở. make all/syn/ppa/report/asic hiện chưa là orchestration đầy đủ (§10),không dùng echo/header CSV làm PASS AC07.

---

## 7. Tổng hợp và đánh giá PPA

### 7.1 Môi trường

- Công cụ: Vivado (ghi rõ phiên bản; [P] dùng 2020.1). Thiết bị: chọn theo **chính sách bậc thang ở §7.6**. Ưu tiên `xcvu9p` (part đầy đủ ví dụ `xcvu9p-flgb2104-2-i`) để cùng nền với [P]; nếu không có được thì dùng bậc thấp hơn và **so theo tỉ lệ thay vì số tuyệt đối**. Ghi rõ part đầy đủ, speed grade và phiên bản công cụ trong log.
- Chế độ: out-of-context, hạn chế DSP về 0 (ví dụ `-max_dsp 0` hoặc thuộc tính `use_dsp="no"`; kiểm tra cú pháp theo phiên bản), không BRAM.
- Ràng buộc: quét chu kỳ đích 1.6 ns, 2.0 ns, 2.5 ns, 3.3 ns; chạy ≥ 3 chiến lược/seed, báo min/median/max. `1/(T-WNS)` chỉ là ước lượng từ đường setup một clock tương ứng; không dùng WNS của đường I/O/false/multicycle khác để suy fmax. Tần số công bố phải đạt WNS≥0 và kiểm hold sau route với ràng buộc đầy đủ.
- Công suất: `report_power` có file SAIF từ mô phỏng post-route (MAY, khó); nếu không có thì ghi rõ là ước lượng vectorless và không dùng để kết luận năng lượng/phép tính.

### 7.2 Đối tượng đo

| Nhóm | Thiết kế |
| --- | --- |
| Đề tài | **So sánh chính MUST:** MAC v1 NF baseline nội bộ và MAC v2 F, cùng `(32,3)`, FRAC_W12, OPS1, FLOOR/RNE; n0..8, ưu tiên đo n2/4/8 rồi đủ sweep. F dùng ACC_WIN/chính sách cut được khóa sau L1 tuần12, không mặc định theo ứng viên §4.1. So accuracy, LUT/FF/CARRY/DSP/BRAM, timing post-route, latency, II và throughput theo §11.8. NF32/2 giữ yêu cầu bắt buộc của §6.7; F32/2, quét FRAC_W và exact fused là khảo sát bổ trợ; không đặt trước fmax hoặc mặc định F chính xác hơn NF. |
| Đối chứng posit bổ sung (MAY) | PACoGen multiplier ([23], mã nguồn [24]) sinh ra cho **cùng** `(NB, ES)` với thiết kế của bạn, DSP thay bằng LUT |
| Đối chứng FP32/FP16 bổ sung (MAY) | (B1) Xilinx Floating-Point Operator IP: bộ nhân + bộ cộng, không dùng DSP, độ trễ chọn để fmax gần nhất với thiết kế của bạn; (B2, MAY) bộ FP sinh bởi FloPoCo hoặc tự viết |
| Đối chiếu bài báo | Multiplier riêng lẻ (không adder), `(32,3)`, `FRAC_W=12` để so với 698 LUT / 289 FF / 575 MHz của [P] (so tuyệt đối chỉ khi ở bậc D0; nếu không thì so tỉ lệ theo §7.6) |

Lưu ý: [P] ghi so sánh với PACoGen dùng `es=6` mặc định, trong khi thiết kế của [P] dùng `es=3`. Phải so sánh cùng `ES` và ghi chú sự khác biệt này.

### 7.3 Chỉ số báo cáo

LUT, FF, CARRY8, DSP, BRAM, WNS, fmax, độ trễ (chu kỳ, cố định + n), tích Diện tích×Trễ, số phép/giây, phép/giây trên mỗi LUT, (nếu có SAIF) năng lượng/phép.

### 7.4 Chỉ số công bằng (phân tích trung thực)

Phép nhân lặp không xuất kết quả mỗi chu kỳ. Khi đánh giá hiệu năng trên diện tích (throughput / LUT), cần phân biệt rõ hai chế độ vận hành:

#### A. Chế độ đơn lẻ cô lập (Isolated mode — giả định minh họa)

Để minh họa từ số liệu paper, bảng giả định khoảng khởi phát bằng độ trễ được công bố ($\text{II} = \text{độ trễ}$), input luôn sẵn và output không stall. Đây không phải II đã đo của paper hoặc MAC NF hiện tại:

| Thiết kế | fmax | Độ trễ / II | Phép/giây | LUT | Phép/giây/LUT |
| --- | --- | --- | --- | --- | --- |
| [P], n = 3 | 575 MHz | 9 chu kỳ (n+6) | 63.9 M | 698 | 0.092 M |
| [P], n = 1 | 575 MHz | 7 chu kỳ | 82.1 M | 698 | 0.118 M |
| PACoGen pipelined | 380 MHz | II = 1 (độ trễ 5) | 380 M | 1247 | 0.305 M |

Số LUT/fmax/latency từ Table III của [P]; phép/giây là tính toán theo giả định trên. Theo giả định này, PACoGen cao hơn khoảng 2.6–3.3 lần về phép/giây/LUT. Không gọi đây là cận worst-case của một hệ thống: thời gian idle hoặc stall tùy ý có thể làm throughput thấp hơn nữa.

NF hiện tại có q=max(1,t), t là số vòng thực tế: first-valid=q+12, handshake không stall=q+13 và II không stall tối thiểu=q+14 vì chỉ nhận giao dịch tiếp ở cạnh sau retire (§11.10). PPA phải dùng II đo của chính top đang tổng hợp; không thế n+6 hoặc II=n vào công thức cho NF.

#### B. Mục tiêu chồng lấn và độ chính xác

Bảng dưới dùng LUT/fmax Table III để tính minh họa với giả định II=n, không phải phép đo throughput của [P] hay RTL đề tài. Tỷ lệ chính xác lấy đúng cột Proposed của Table I (Phụ lục A); không áp các tỷ lệ này cho phân bố phân tầng toàn miền.

| n | II giả định | Phép/giây | Phép/giây/LUT | So PACoGen II=1 | Err<0.1% | Err<0.5% |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 575,0 M | 0,824 M | 2,70× | [P] không báo cáo | [P] không báo cáo |
| 2 | 2 | 287,5 M | 0,412 M | 1,35× | 9,87% | 32,19% |
| 3 | 3 | 191,7 M | 0,275 M | 0,90× | 44,69% | 83,17% |
| 4 | 4 | 143,8 M | 0,206 M | 0,68× | 87,09% | 99,79% |

Không gắn 698 LUT/575 MHz của bộ nhân fraction 12 bit với tuyên bố exact posit32: xử lý hết bit 1 chỉ hết sai số lặp, không phục hồi fraction đã cắt. Đường exact rộng phải được tổng hợp riêng.

Báo cáo phải kèm (format, miền/phân bố đầu vào, ROUND_MODE/SCHEME, sai số, II đo thực tế, độ trễ và LUT). So multiplier với multiplier, MAC với MAC; đối chiếu FP32/FP16 non-fused cho v1, fused cho v2 nếu có. Mã ngoại lệ/range khác nhau của FP và Posit phải được tách khỏi thống kê sai số hữu hạn. Chỉ kết luận lợi thế throughput/LUT khi cùng điều kiện và mức accuracy phù hợp.

### 7.5 Đóng gói kết quả

Giữ raw report công cụ,part/speed grade,constraints,tool/source hash,seed và lệnh mỗi run; bảng NF/F phải truy vết được từng số. Script scripts/collect_ppa.py hiện mới tạo header CSV,không parse report hoặc xuất ppa.md như docstring; make syn/asic/report còn stub. Chưa nghiệm thu collector/PPA automation. Các khảo sát OPS/packer trước đây dùng report/JSON riêng trong results/ops_ppa và results/packer_ppa,không gọi header ppa.csv là số liệu đo toàn MAC.

Khi triển khai collector thật,thiếu report hoặc parse lỗi phải FAIL thay vì điền0; synthesis-only,post-route và power estimates có nhãn riêng. Không tạo thêm Markdown kết quả trong phiên rà soát này.

Tuần12 có collector chuyên biệt `scripts/collect_week12_nf.py` đã parse report Quartus thật vào results/week12/nf_ppa/{summary,stages}.json vàstages.csv;thiếu report/parse lỗi đều FAIL. Nó không thay scaffold collect_ppa.py hoặc chứng minh hỗ trợ tự động Vivado/ASIC/power. Phạm vi và số đo tại §11.14.

### 7.6 Chính sách thiết bị và phương án khi không có xcvu9p

Chọn part mà phiên bản Vivado và license hiện có hỗ trợ; ghi kết quả kiểm tra part/license vào log trước khi chốt nền tảng. Không cần board vật lý để tổng hợp/P&R. D0 dùng cùng device family như [P]; các bậc khác chỉ so trong cùng nền tảng và ghi rõ giới hạn đối chiếu. Không cố định tên gói miễn phí hay công nghệ chế tạo cho cả họ thiết bị vì hỗ trợ thay đổi theo part/phiên bản.

**Các bậc nền tảng**

| Bậc | Nền tảng | Điều kiện | Số liệu thu được | Giá trị so với [P] |
| --- | --- | --- | --- | --- |
| D0 | Vivado + xcvu9p | Phiên bản/license và constraints đã chốt | LUT/FF/fmax đo tại device này | Đối chiếu mốc công bố [P],không tự gọi tái hiện khi chưa có RTL/config tác giả |
| D1 | Vivado + UltraScale+ được bản cài/license hỗ trợ | Xác nhận theo part | LUT/FF/CARRY8, timing đo riêng | Chỉ so tỉ lệ đo cùng nền tảng |
| D2 | Vivado + 7-series (Artix-7 `xc7a35t`/`xc7a100t`, Zynq-7000 `xc7z020`) | Xác nhận part trong bản đã cài | LUT6/CARRY4; timing phải đo riêng | Chỉ so tỉ lệ |
| D3 | Yosys `synth_xilinx` (không cần Vivado; chọn family theo phiên bản Yosys) + số tầng LUT trên đường dài nhất (`ltp`) | Mã nguồn mở | LUT/FF/CARRY, độ sâu logic làm đại lượng thay cho fmax | Bằng chứng chéo, chỉ tỉ lệ |
| D4 | Yosys + OpenROAD (EXT-A), Nangate45 hoặc SKY130HD | Mã nguồn mở | Diện tích µm², WNS, fmax, công suất ước tính | Không so số của [P]; so xu hướng và tỉ lệ |

**Quy tắc để kết quả vẫn có giá trị**

**Lựa chọn hiện hành 15/10/2026:** sinh viên yêu cầu chuyển các phép đo mới sang Xilinx, bắt đầu bằng hai dynamic shifter và LOD/LZD riêng lẻ; chưa ghép SAC/parser/MAC. Vivado2026.1 build6511674 đã nhận license synthesis/implementation và các part `xc7a35tcpg236-1` (Basys3), `xc7a100tcsg324-1` (ArtyA7-100T/NexysA7-100T). `get_parts *7z020*` trả rỗng; chưa đo PYNQ-Z2/Zynq7020. Không cần cài board-file cho benchmark theo part. Tài liệu part: [Basys3](https://digilent.com/shop/basys-3-amd-artix-7-fpga-trainer-board-recommended-for-introductory-users/), [ArtyA7](https://digilent.com/shop/arty-a7-100t-artix-7-fpga-development-board/).

Ứng viên primitive giữ riêng tại `rtl/candidates/primitives/`, không đưa đồng thời với bản cùng tên trong `rtl/` vào một source list. Snapshot và điều kiện đo nằm ở `results/primitive_xilinx_20261015/manifest.json`; so N12/26/32, right custom-fill và LOD MODE0; ARITH1/MODE1 kiểm chức năng riêng, chưa suy PPA. Benchmark OOC có input/output bank giống nhau, BUFG, clock5ns/uncertainty0,1ns, ba cặp place/route `Default/Default`, `Explore/Explore`, `RuntimeOptimized/Default`, cùng chính sách DSP0/BRAM0. Bank đo không sở hữu valid/state nên ghi đè mỗi cạnh, không có reset/protocol; primitive vẫn thuần tổ hợp, không thay latency giao dịch NF/F.

Số LUT chính lấy **Slice LUTs vật lý** từ `report_utilization`, không dùng tổng số logical LUT cells vì hai cell có thể dùng chung O5/O6. Kiểm setup/hold R2R sau route ở clock thử; `1000/(T−slack)` chỉ là **ước lượng STA** tại clock đó, không gọi là Fmax đã sweep/đạt trên kit. I/O delays của benchmark là ngân sách tổng hợp giả định; cổng OOC chưa có `HD.PARTPIN_LOCS`, không phải timing/bitstream của board. Giữ các báo cáo CycloneIV trước đây làm lịch sử; không so trực tiếp LUT4 với Slice LUTs hoặc quy Fmax leaf thành Fmax MAC. Hai part hiện có cùng Artix7/speed−1, chưa đáp ứng bằng chứng độc lập khác family. Kết quả/giới hạn nghiệm thu cụ thể tại PLAN§8.16.9.

1. **Cùng điều kiện.** Mọi thiết kế được so sánh (posit, PACoGen, FP32, FP16) dùng cùng công cụ, phiên bản, thiết bị, ràng buộc, chế độ out-of-context, không DSP.
2. **Báo cáo tỉ lệ** `R_LUT = LUT_đề_tài / LUT_baseline`, `R_FF`, `R_fmax = fmax_đề_tài / fmax_baseline`. Mốc của [P] với PACoGen: `R_LUT = 698/1247 = 0.56`, `R_fmax = 575/380 = 1.51`.
3. **Kiểm chéo hai nền tảng khác bậc (SHOULD, cần nếu kết luận độc lập nền tảng)** (ví dụ D1 hoặc D2 cùng D3 hoặc D4). Một khẳng định về thứ hạng hay tỉ lệ chỉ được đưa vào kết luận nếu giữ nguyên trên cả hai; nếu chỉ đúng trên một nền tảng thì ghi rõ là phụ thuộc nền tảng.
4. **Phân rã theo module** (parser, packer, nhân, cộng) bằng `report_utilization -hierarchical`. Tỉ lệ đóng góp của từng module ổn định hơn số tuyệt đối; [P] nói phần lớn tài nguyên nằm ở parser/packer, nên đây là điểm dễ kiểm chứng.
5. **Độ nhạy.** ≥ 3 seed/chiến lược; nếu fmax giữa các seed chênh quá 10% thì coi là nhiễu và báo cáo khoảng min–max, không báo cáo một điểm.
6. **Dùng từ đúng.** D0 chỉ đủ cùng device; tái hiện TableIII còn cần source/profile/ràng buộc và số liệu tương ứng. Khi chưa có provenance,chỉ gọi đối chiếu mốc [P]. Các bậc khác báo NF/F cùng nền tảng; không gọi trùng tỷ lệ là bằng chứng tái hiện tác giả.

**Ví dụ số (giả định minh họa, không phải số đo thật).** Ở D2, PACoGen ra 1,410 LUT / 210 MHz, thiết kế của bạn ra 790 LUT / 330 MHz. Khi đó `R_LUT = 790/1410 = 0.560` (trùng mốc 0.56) và `R_fmax = 330/210 = 1.571`, lệch +3.8% so với mốc 1.513. Đây là kết quả tái hiện xu hướng tốt dù số tuyệt đối khác hẳn [P].

**Ngưỡng NFR quy đổi sang tỉ lệ** (quy từ NFR-02/03 với baseline 1247 LUT / 380 MHz):

| Mức | NFR-02 (tuyệt đối → `R_LUT`) | NFR-03 (tuyệt đối → `R_fmax`) |
| --- | --- | --- |
| Tối thiểu | ≤ 1000 LUT → ≤ 0.80 | ≥ 350 MHz → ≥ 0.92 |
| Mục tiêu | ≤ 800 LUT → ≤ 0.64 | ≥ 450 MHz → ≥ 1.18 |
| Xuất sắc | ≤ 700 LUT → ≤ 0.56 | ≥ 575 MHz → ≥ 1.51 |

Ngoài D0, dùng cột tỉ lệ. **Tiêu chí AC05/AC06 hiện hành:** đo NF/F trên ít nhất một nền tảng P&R hợp lệ,cùng device/tool/constraints/config và>=3 run/config; đủ raw report,setup/hold,latency/II và tài nguyên theo AC05/06. Cross-platform là kiểm bổ trợ; D3 depth/synthesis-only không thay timing post-route. Mốc±20% tỷ lệ paper chỉ là khảo sát lịch sử,không phải điều kiện chặn NF/F khi chưa có RTL tác giả. D4 dùng metric ASIC,không so LUT FPGA; lựa chọn nền tảng ghi trước chạy,không chọn lại chỉ vì kết quả bất lợi.

---

## 8. Các mở rộng EXT-A/B/C (Tier 3 theo §1.5)

### EXT-A. Luồng ASIC RTL-to-GDSII (khuyến nghị)

- Công cụ: Yosys + OpenROAD-flow-scripts, platform mã nguồn mở (Nangate45 hoặc SKY130HD), GDS xem bằng KLayout.
- Bước: `config.mk` và `constraint.sdc` → tổng hợp → floorplan → placement → CTS → routing → STA (đủ setup/hold) → kiểm tra DRC của platform (nếu có).
- Đối tượng: cùng RTL Posit MAC (v1) và FP32 MAC baseline (B2, cần bản RTL công khai); quét chu kỳ đích 3 mức.
- Chỉ số: diện tích (µm²), utilization, WNS/TNS, công suất từ báo cáo công cụ (ghi rõ điều kiện), số cell.
- Sản phẩm: thư mục `asic/` tái lập bằng `make asic`, bảng PPA ASIC cạnh bảng FPGA, phân tích đường tới hạn (parser LOD/LZD, packer shifter) và các biện pháp cải thiện đã thử (thêm pipeline, chia nhỏ shifter).
- Lý do đề xuất: cho số liệu diện tích/timing thực hơn LUT của FPGA và tận dụng trực tiếp kỹ năng thiết kế vật lý. Nếu không có Vivado hoặc thiết bị phù hợp, EXT-A được nâng thành đường PPA chính (bậc D4 ở §7.6).

### EXT-B. Khảo sát không gian thiết kế (DSE)

Quét `FRAC_W ∈ {8,12,16,23}`, `n ∈ {1..6}`, `ES ∈ {2,3}`, `ops ∈ {0,1}`; mỗi điểm cho `(LUT, fmax, CorrectRate@0.1%, NMSE, độ trễ trung bình)`. Xuất đồ thị Pareto (LUT × độ trễ trung bình × NMSE) và khuyến nghị 2–3 cấu hình cho các kịch bản (nhẹ, cân bằng, chính xác).

### EXT-C. Đánh giá mức ứng dụng

Dùng L1 thay phép nhân trong (i) bộ lọc FIR có hệ số biết trước, hoặc (ii) suy luận MLP nhỏ trên MNIST; báo cáo SNR/độ chính xác phân loại theo `n`, `FRAC_W` so với FP32 và FP16.

---

## 9. Kế hoạch 16 tuần

| Tuần | Công việc | Sản phẩm | Cổng kiểm |
| --- | --- | --- | --- |
| 1 | Đọc [P], [4], [15], [18]; lập bảng "điểm mơ hồ" (§11); dựng repo, Makefile, lint | `docs/ambiguity.md`, repo khung | |
| 2 | Cài SoftPosit; script gọi `p8/p16/p32`; xác nhận toàn bộ TV-RND và corner list bằng SoftPosit | `l0/` chạy được | Corner list khớp tay |
| 3 | L1: parser/packer/round + exact multiplier; đối chiếu L1 với SoftPosit ở `ES=2` | L1 parser, pack, mul exact | **Gate 1**: Parser $\rightarrow$ Packer đồng nhất; L1 mul exact = L0 ($2^{16}$ posit8, $2^{32}$ posit16, corner list + $\ge 10^7$ posit32) |
| 4 | L1 nhân lặp,OPS/SAC/SBM và hợp đồng prepack FLOOR/RNE | L1/prepack đóng băng; trace kiểm | Profile local/oracle đạt; TableI/provenance nghiên cứu phụ,không chặn NF/F |
| 5 | L1: Posit Adder (`l1_add`); kiểm tra bit-exact với SoftPosit `p<N>_add` | L1 adder | L1 adder = L0 ($2^{16}$ posit8, $2^{32}$ posit16, corner list + $\ge 10^7$ posit32) |
| 6 | L1: Posit MAC non-fused (`l1_mac`), `round_unpacked`, `acc_mode` | L1 mac hoàn chỉnh | **Gate 1B**: L1 MAC = L0 ($2^{24}$ posit8, corner list + $\ge 10^7$ posit32) trước khi code RTL |
| 7 | RTL parser + LOD/LZD + barrel shifter + testbench đơn vị | `posit_parser` | Exhaustive posit8/16 |
| 8 | RTL packer + RNE + pre-clamping; kiểm parser→packer đồng nhất | `posit_pack` | Corner list, exhaustive posit8/16 |
| 9 | RTL OPS + SAC + SBM + `iter_ctrl`; multiplier top | `posit_mul_iter` | **Gate 2**: RTL Multiplier = L1, $10^7$ vector, mọi n; exact mode khớp L0 |
| 10 | 12–18/10: chốt contract/corpus NF/F và RTL adder | posit_add, testbench và matrix | Adder=L1/L0, control/flags đạt |
| 11 | 19–25/10: MAC v1 non-fused, bắt đầu L1 F | Baseline NF có tag/hash, L1 F pilot | Gate3 NF; không gọi L1 F đã nghiệm thu |
| 12 | 26/10–01/11: L1 F/oracle,width/cut/cancellation,PPA sơ bộ NF và xác định critical path | Hợp đồng F đóng băng, corpus đối chuẩn | G-F-L1; xác nhận công cụ P&R |
| 13 | 02–08/11: RTL F theo model đã kiểm;tối ưu/chốt pipeline NF/F trước regression lớn | MAC v2 và checker | Pilot RTL F=L1 F, protocol/corner đạt |
| 14 | 09–15/11: regression, coverage và paired accuracy | Report NF/F cùng corpus | G-F-RTL, AC01/AC04 và phép đo AC03 mới |
| 15 | 16–22/11: P&R hai bản, ≥3 run/config, bản thảo | Bảng accuracy/PPA và hồ sơ | Gate4, AC05/AC06 |
| 16 | 23–29/11: báo cáo/slide/demo/tái lập; đệm30/11–04/12 | Hồ sơ chính hoàn tất29/11 | AC07/AC08; hoàn tất trước05/12 |

**Phân cấp lộ trình và quản lý rủi ro tiến độ**:
- **Đường găng dự án (Critical Path - Bắt buộc)**: Gate 1 (Tuần 3) $\rightarrow$ Gate 1B (Tuần 6) $\rightarrow$ Gate 2 (Tuần 9) $\rightarrow$ Gate 3 (Tuần 11) là các mốc nền tảng bộ nhân lặp và **MAC v1 Non-fused**. Đường hoàn tất mục tiêu đầy đủ tiếp tục qua L1 F → RTL F → kiểm paired/coverage → PPA NF/F → hồ sơ tuần16; NF/Gate3 riêng chưa hoàn thành đề tài.
- **MAC fused v2 (FR11)**: hạng mục so sánh chính của kế hoạch11/10; vẫn không chặn việc đóng NF/Gate3. L1 tuần11–12, RTL tuần13–14 sau oracle; lịch và phạm vi bắt buộc hiện hành tại §11.8.
- Nếu chậm tiến độ: giảm EXT-A/B/C, FP32/FP16, chồng lấn và cấu hình F phụ; giữ NF, fused profile chính và AC01/AC02/AC04. Báo rủi ro thay vì tuyên bố đạt khi còn mismatch.

---


## 10. Repo, chuẩn code, công cụ

| Đường dẫn hiện có | Vai trò |
| --- | --- |
| SPEC_Posit_MAC_IP.md,Digital_Design_Guidelines.md | Hợp đồng/chuẩn code |
| l0/ | SoftPosit wrapper,format và library hash |
| l1/ | Legacy model/freeze,test và PLAN/README |
| rtl/ | Một module/file; posit_mac_nf và các leaf |
| tb/ | Harness C++,oracle độc lập,testbench SV thủ tục; chưa UVM-lite integrated |
| scripts/ | Runner/generator/audit và tiện ích; chức năng thực theo §6.9 |
| syn/,asic/ | Script khảo sát và scaffold; không suy đã có flow MAC cuối |
| results/ | Canonical JSON,raw coverage/trace/report công cụ,version/seed/hash; binaries/fixture lớn tái sinh |
| ../doc/ | TIEN_DO_DO_AN.md và hướng dẫn chạy đã có |

Guideline áp dụng cho RTL mới: một module/file,named ports,mỗi port một dòng,no latch,blocking combinational/nonblocking sequential,always_ff/enable/CK2Q; reset bridge top và2FF release leaf. Initial $fatal trong generate chỉ kiểm cấu hình elaboration/simulation,không dùng initial khởi tạo phần cứng thay reset. Reset top rst_n theo giao diện SPEC; reset leaf reset_n theo guideline.

Makefile hiện lint/smoke/regress/cov cho Gate2 multiplier; syn/asic/report còn echo,ppa collector còn header. make all chưa đủ AC07. Các target/demo/summary.md mới là kế hoạch nếu chưa có code. Git giữ lịch sử nguồn,commit+manifest/tag ở mốc đã kiểm; không đưa token/license/binary/wave/cache vào commit. Checkout backup scratch/github_week9_backup giữ cấu trúc repository Posit_MAC/ và doc/,không đổi remote hoặc dùng force/reset/clean.

## 11. Quyết định, rủi ro và điều kiện triển khai

Cập nhật14/10/2026. SPEC là hợp đồng; kết quả nghiệm thu phải dẫn tới log/summary. “Đã chốt” không đồng nghĩa đã triển khai RTL. Nội dung normative ở §4–§6 có ưu tiên hơn nhật ký thí nghiệm lịch sử trong phụ lục.

### 11.1 Điểm mơ hồ và quyết định hiện hành

| # | Vấn đề | Quyết định / hợp đồng | Trạng thái và phần còn lại |
| --- | --- | --- | --- |
| 1 | OPS, recurrence và rounding của [15]/[P] | RTL baseline dùng cfg_ops=0/1 và profile normative §5.4–§5.6. Predictor n=2/7-bit, RND/complement và paper_source_config là nghiên cứu riêng | PT2 PASS128 prefix dưới giả định đệm Q12; LUT/tie gốc còn mở. README L1 mục20 loại source Q24 không cut khỏi baseline bit-exact2021 bằng output Fig.4; muốn đưa profile paper vào RTL phải bổ sung contract/API và oracle riêng |
| 2 | Phân bố, seed và ngoại lệ Table I/II | Table I tái dựng dùng grid24 [0,1), FP32 RNE Ideal, seed271828, 200 triệu accepted. Generator/seed/filter là giả định dự án; phân tầng dùng coverage, không thay corpus paper | Source lịch sử đạt max0,984213 điểm % nhưng không khớp output Fig.4; không dùng kết quả này để nghiệm thu baseline gốc. Đối chiếu profile cut12 ở README L1 mục20; generator gốc và Table II còn mở |
| 3 | Cut/sticky trong SBM | ROUND_SCHEME=0 cắt ở FRAC_W; =1 giữ G/R và OR đuôi vào sticky riêng, theo §5.6. Sticky không tái tạo carry của tổng phần dư | Legacy Gate2 kiểm đúng cut; NF mới chỉ FLOOR/RNE. JAM không tái tạo residual hoặc chứng minh exact; F_W32 đã khóa signed residual riêng tại §5.12 |
| 4 | Độ rộng accumulator | Payload approx FRAC_W+4,physical bank chọn theo EXACT_EN như §5.6; NF32/3 hiện54 bit. Research `fig3` giữ fraction12/payload13+carry/guard0; source guard12 giữ riêng làm control | README L1 mục19/20: fig3 chức năng PASS, TableI max1,2923195 điểm %; guard12/cut12 khớp output Fig.4 nhưng max1,338773, chưa đạt. Fig.5 hỗ trợ fraction đầu ra12, không xác minh guard hay mã hóa cờ nội bộ |
| 5 | m của hai toán hạng Table II | Giả định cả hai thuộc nhóm khảo sát; ideal là posit32 ES3 exact, không dùng L0 ES2 thay thế (§6.3) | Cần corpus, seed, conversion/filter và oracle ES3 trong báo cáo Table II |
| 6 | Baseline PACoGen/FP32/FP16 | Cùng ES, part, ràng buộc và tài nguyên khi so trực tiếp; khác thiết bị thì báo riêng theo §7.6 | Toàn NF đã post-route sơ bộ trên CycloneIV (§11.14); chưa paired NF/F,đối chiếu D0 hoặc Gate4 |
| 7 | TRUNC và RNE | ROUND_MODE là đóng gói; ROUND_SCHEME là cut/sticky nội bộ. TRUNC cắt độ lớn về 0; lỗi có dấu phụ thuộc dấu toán hạng | L1/round_unpacked và packer RTL RNE/TRUNC đã nghiệm thu đơn vị07/10; results/packer/summary.json |
| 8 | Số tầng và latency | H,L_valid,L_handshake theo §5.1; tách benchmark riêng với toàn hệ thống | Parser/packer và NF numeric đã kiểm; packer riêng122,50–124,42MHz không phải Fmax MAC. Toàn NF CycloneIV median45,07MHz,setup100MHz chưa đạt (§11.14). F pipeline q+12 mới là ngân sách |
| 9 | Ý nghĩa n | cfg_n normative đếm fraction, hidden riêng; n_terms=n_fraction+1 chỉ chuyển bộ đếm của cùng chuỗi khai triển (§5.5/PB-04) | Đã khóa profile RTL. Khác recurrence/cut/OPS không được coi tương đương chỉ nhờ đổi n |
| 10 | Reset và lịch core | Reset bridge/startup barrier §4.2; n=0/init_only, first/last và drain theo §5.5. Baseline giữ một giao dịch, dự trữ một slot đầu ra | Core/bridge/standalone đã kiểm Gate2; NF numeric/protocol W11 đạt. Coverage Gate3 bổ sung đạt tại §11.12; final vẫn mở |

### 11.2 Rủi ro hiện tại

| Rủi ro | Ảnh hưởng | Cách xử lý / điều kiện đóng |
| --- | --- | --- |
| Packer hoặc Adder RTL lệch L1 tại ties/clamp/cancellation | Cao | Packer đã kiểm tuần8; adder RTL đã kiểm mốc đơn vị tuần10. Gate1B là bằng chứng L1, không thay nghiệm thu RTL. Còn ma trận final và coverage tích hợp |
| Lệch một cạnh khi cộng số tầng | Cao | TB dùng E0, H, L_valid, L_handshake; kiểm n=0/1/2, early termination, bypass và bubble; không ép số đo vào công thức cũ |
| A/B/C hoặc metadata nhả reset/nhận giao dịch khác nhau | Cao | Reset bridge và startup barrier; nhận A/B/C nguyên tử; test reset rỗng, đang tính và output stall |
| Core_done sớm, khởi tạo hai lần hoặc mất token khi drain | Cao | Kiểm lịch §5.5; done chỉ sau last tại accumulator, init_only n=0 không cộng Y hai lần |
| Chồng lấn ghi đè accumulator, FIFO thiếu chỗ hoặc đọc C cũ | Cao | Baseline một giao dịch trước; sau đó chứng minh credit/capacity, ordering và hồi tiếp. Không ấn định FIFO6–8 hoặc II=max(1,n) như bảo đảm |
| Table I khớp corpus nhưng thiếu provenance/độ ổn định | Trung bình | Giữ nhãn tái dựng, công bố seed/profile và sensitivity; không chọn seed/width chỉ để ép khớp |
| Vivado không chạy tổng hợp/STA vì thiếu license | Cao đối với PPA | ModelSim dùng kiểm chức năng; Vivado compile/elaborate đã chạy cho parser nhưng không thay STA. Khôi phục license hoặc dùng luồng §7.6 và ghi rõ thiết bị/công cụ |
| Hết thời gian hoặc so PPA thiếu công bằng | Cao | Giữ NF và fused profile chính; cắt khảo sát phụ theo §9; so cùng điều kiện và phân biệt OPS riêng với toàn MAC |
| Fused v2 mất đuôi có dấu/triệt tiêu sâu, ABS/LZC hoặc carry dài | Cao đối với mục tiêu đầy đủ | Chốt oracle/hợp đồng §5.12-c trước RTL v2; đo STA/PPA. Không chặn NF/Gate3, nhưng bắt buộc trên đường hoàn tất tuần12–16 |

### 11.3 Điều kiện sẵn sàng và thứ tự thực hiện

1. **Đã nghiệm thu mô hình số học:** Gate1, round_unpacked tương đương parse(pack(u)), Adder và MAC L1 v0/v1 Gate1B. Bằng chứng tại README L1 mục15 và results/week6_*; ES3 dùng oracle riêng, không gọi là L0 SoftPosit ES3.
2. **Đã nghiệm thu parser RTL đơn vị:** comb và pipeline bốn format, 2.465.812 fixture, 0 mismatch; reset/stall/ordering/II được kiểm ở parser. Bằng chứng results/parser_comb/, results/parser_pipeline/ và rtl/README.md mục5. Không suy thành Gate2/3 toàn MAC.
3. **Đã nghiệm thu packer RTL tuần8:** tổ hợp/pipeline RNE2/TRUNC1 và parser→packer đạt0 mismatch trên bốn format; F_IN/adapter theo §5.9-D. Tuần9 đã chốt giao diện §5.5-A và kiểm OPS/SAC tổ hợp327.440 vector ModelSim,0 mismatch; SBM/core/top standalone đã triển khai và kiểm pilot 09/10; Gate2 multiplier đã nghiệm thu10/10: strict lint16 cấu hình, scoreboard trực tiếp và16.815.920 so sánh/0 mismatch; bằng chứng PLAN L1 mục7.11 và gate2_acceptance.json. Paper RTL843 commit/Fig.4 đạt trong profile tái dựng, không xác nhận baseline gốc. Sau tối ưu P2, packer benchmark riêng đạt setup100MHz ở ba seed mỗi mode; tiếp tục STA khi tích hợp, không gọi là Gate4 hoặc fmax toàn MAC.
4. **Trước nghiệm thu tích hợp:** thực hiện reset bridge, startup barrier và lịch core §4.2/§5.5; TB đối chiếu cạnh, config, flags, metadata và slot output. Multiplier standalone đã có reset bridge, startup barrier và kiểm pilot; Gate2 multiplier đã nghiệm thu; RTL adder đơn vị đã nghiệm thu§5.8-E; MAC NF/C/context và Gate3 đã kiểm theo §11.10; final matrix và fused còn mở.
5. **Chồng lấn sau baseline:** thêm FIFO/credit và chứng minh lịch first/last, n=0/drain, acc feedback trước khi kết luận II/throughput. Sức chứa phải suy ra, không dùng skid2 để bảo đảm mọi giao dịch đang bay.
6. **Tái hiện/PPA và v2:** provenance Table I, corpus Table II và PPA toàn khối còn mở; ghi đúng giới hạn. Fused v2 là mục tiêu so sánh chính theo §11.8; không thay bằng chứng tuần8 hoặc điều kiện đóng NF/Gate3.

---

Các mục11.4–11.7 dưới đây giữ kết luận **tại ngày của từng phiên**; câu “Gate2 processing” ở09/10 không phải trạng thái hiện hành. Gate2 hiện đã nghiệm thu10/10; trạng thái NF/F và coverage hiện hành ở §11.10–§11.13.

### 11.4 Bằng chứng RTL tuần9 — 09/10/2026

SBM/normalize/adapter đã kiểm252.455 lượt; core đạt39.580 giao dịch và420 reset hủy; standalone multiplier pilot31.840 giao dịch và160 reset hủy. Cả ba suite0 mismatch. Nghiên cứu paper riêng đạt843 commit/293 bản ghi, Fig.4 force-X=0x1ae34000; không xác nhận tie/padding/guard hoặc RTL gốc. Hợp đồng normative giữ §5.5-A/§5.7/§5.9-D.

ModelSim đối chiếu 16.815.920 giao dịch, hủy 80.080 giao dịch bằng reset,0 mismatch.

Gate2/tuần9 processing: cần lint/harness Verilator chính thức ; coverage chức năng §6.3 đã kiểm đạt, line/branch/toggle chưa đo. Quartus13 Analysis & Synthesis NB32/ES2 đạt0 lỗi,14 warning đã phân loại, không có cảnh báo latch; không thay STA/CDC/PPA. TableI không chạy lại vì chưa có thay đổi có căn cứ. Kế hoạch/bằng chứng chi tiết: PLAN L1 §7.4 và results/week9_implementation/summary.json. GitHub đã push checkpoint 0ae39c4 lên main bằng checkout riêng trong Posit_MAC; kết quả lượt lớn được bổ sung cuối phiên.

### 11.5 Top paper tự hồi tiếp — 09/10/2026

`paper_mul_iter`/`paper_mul_wrapper`/`paper_norm_comb` đã tự chạy từ A/B đến kết quả; ModelSim17.181 giao dịch và65.710 commit đạt0 mismatch,843 commit corpus cũ giữ nguyên, Fig.4=0x1ae34000. Linux/Windows/UBSan fixture MATCH; reset/stall/context/early-stop/special đạt trong suite. Hợp đồng research cố định posit32ES3/Q12, n_terms1..8, outputTRUNC; chi tiết PLAN L1 §7.5 và results/paper_top/{windows/summary,audit}.json. Không có nguồn mới hoặc thay đổi số học nên không chạy TableI; provenance baseline gốc và Gate2 vẫn processing.

### 11.6 Rà soát SAC/n và packer theo nguồn — 09/10/2026

Audit trực tiếp nguồn2019/2021 và kiểm deterministic163.840 cặp cho thấy RND/complement và quét bit1 không tương đương. Fig4 khớp n_fraction2/n_total3 (0x1ae34000), nhưng n_total2 cho0x1ad14000; TableI Proposed chưa khóa cách đếm/recurrence từ nguồn. Giữ nguyên profile normative và top RND nghiên cứu, không đổi n/seed để ép bảng.

Reference cổng Fig5 độc lập khớp L1 trên3.940.352 trường hợp; ModelSim155.648 trường hợp đạt0 mismatch, Linux/Windows/UBSan MATCH.8.448 raw/clamped differences nằm ngoài miền sf−240..240, do range handling đồ án bổ sung; không phải lỗi RTL hoặc xác nhận clamp tác giả. Không chạy pilotTableI, baseline gốc/Gate2 vẫn processing. Chi tiết duy nhất tại README L1 §24; bằng chứng/lệnh/hash/compiler tại results/paper_contract_audit/{summary.json,windows/summary.json}.

### 11.7 Pilot nguồn Posit journal2024 — 09/10/2026

Pilot journal2024 dùng Posit32 ES2/Q12/PT2 tuyệt đối, oracle SoftPosit0.4.1; n đếm tổng số hạng. Self-test600.127 đối chiếu/lượt đạt0 mismatch, smoke Linux/Windows MATCH và UBSan đạt. Hai phân bố địa phương10M mỗi loại chưa khớp Fig9: rawPosit n2 Err<0,1%=8,954950%, cột nguồn khoảng53–57%. Cận OPS lý tưởng trong cùng hợp đồng chỉ9,667460%. TableVI khớp output n2 nhưng còn dư; lời văn nói t2=0 bất nhất với bảng. Không kết luận số liệu2021/2024 sai; không đổi n/cut/seed để ép bảng, không chạy full200M hoặc RTL ES2. Baseline gốc/tuần4 và Gate2 vẫn processing. Chi tiết tại README L1 §25, kết quả/compiler/seed/lệnh/hash tại results/paper_journal2024/measurement/summary.json.

### 11.8. Baseline nội bộ và lịch NF/F — quyết định11/10/2026

Quyết định này cập nhật ưu tiên các phần kế hoạch cũ: TableI không còn là AC03 bắt buộc, bài báo không được gọi là baseline đã tái hiện; fused không còn là hạng mục có thể cắt khỏi mục tiêu đầy đủ. Logs/Phụ lục B mang nhãn AC03 cũ giữ ý nghĩa lịch sử paper, không đổi kết quả. Các hợp đồng số học §4–§5, ngưỡng kiểm đúng AC01/AC02/§6.7 và coverage AC04 cuối không được hạ vì thay timeline.

Lịch hiện hành tập trung tại §9 và PLAN8; ngày là kế hoạch,không phải status nghiệm thu. Hạn hồ sơ29/11,đệm30/11–04/12,trước05/12/2026. Tối ưu pipeline tuần12–13,chốt trước regression tuần14,xác nhận post-route tuần15.

### Hợp đồng baseline nội bộ và so sánh

Baseline chính là **MAC v1 non-fused normative**, biến thể là **MAC v2 fused**. Lõi nhân tuần9 tái sử dụng theo SPEC, không gọi là RTL gốc của [P]. Paper giữ vai trò nguồn kiến trúc/thảo luận và các thí nghiệm lịch sử; thiếu provenance không chặn các mốc mới. Không kết luận paper sai từ việc không tái hiện được.

Profile nhân so sánh đã chốt11/10: NB32/ES3, FRAC_W12, RNE, FLOOR, OPS1, N_MAX8; kiểm các n hợp lệ0..8, báo paired results cho n2/4/8 trước rồi bổ sung sweep đầy đủ. Tích prepack theo SPEC§11.9; matrix fused/corpus đánh giá còn chốt trước đo; format32/ES2 là kiểm bổ trợ có SoftPosit. Các format/feature đã nghiệm thu ở multiplier giữ nguyên trạng thái; không tự suy chúng đã được triển khai/kiểm trong fused. TRUNC/JAM và exact fused rộng là khảo sát bổ sung sau profile chính.

Gọi P_hat là tích xấp xỉ **trước pack** từ cùng hợp đồng nhân: NF=R(R(P_hat)+C); F=R(P_hat+C), với R là RNE về cùng Posit. Khi RTL F có cửa sổ hữu hạn W, L1 phải mô hình đầy đủ từng cut và phần dư có dấu; phải báo sai số cửa sổ riêng, không ngầm coi F_W là R(A×B+C) exact. Muốn cô lập tác động rounding phải có reference phần mềm dùng chung P_hat đủ chính xác và báo khác biệt do W. Không lấy tích đã pack của NF làm input F rồi gọi là fused.

Mỗi bản kiểm bit-exact với L1 riêng. NF exact so add(mul(A,B),C); F exact so mulAdd(A,B,C) ở format L0 hỗ trợ, ES3 dùng integer/rational độc lập. Exact oracle/reference không biến profile approx/cửa sổ hẹp thành exact. FMA một giao dịch làm tròn cuối không đồng nghĩa dot-product/quire tích lũy cả chuỗi chỉ làm tròn một lần; ghi rõ chuỗi acc_mode có làm tròn mỗi giao dịch.

Cùng bộ A/B/C, seed đóng băng, phân bố và quy tắc đặc biệt; dùng oracle số nguyên/hữu tỉ độ chính xác đủ cho A×B+C của input ban đầu để đo accuracy, không dùng NF làm chân lý của F. Báo sai số tuyệt đối/ULP-distance, NMSE theo miền, percentile/max, số ca triệt tiêu/zero/NaR và tỷ lệ mỗi bản thắng/thua/hòa. Với r=0 báo riêng, không chia tương đối; gần0 phải có nhóm riêng. Fused không được mặc định luôn tốt hơn khi nhân xấp xỉ hoặc cắt cửa sổ.

So PPA cùng part/speed-grade/tool, clock/I/O constraints và chính sách DSP/BRAM, cùng n/OPS/precision; ghi số stage khác nhau thay vì ép pipeline bất lợi cho một bản. Báo LUT/FF/CARRY/DSP/BRAM, WNS/hold post-route, fmax đạt timing, latency, II, throughput=fclk/II và throughput/LUT; tối thiểu3 run/config, báo min/median/max. Power chỉ đánh giá năng lượng/phép tính khi có activity phù hợp; không suy từ vectorless. Nếu chưa có công cụ P&R hợp lệ, ghi rõ blocker và không gọi synthesis-only là fmax post-route.

Pilot đo100.000 triple/profile; phép so chính tối thiểu1.000.000 triple/profile trên corpus paired đã đóng băng, kèm các ca phân tầng/triệt tiêu. Đây là số mẫu đánh giá kiến trúc, **không thay ngưỡng kiểm đúng AC01/AC02/§6.7**. Fused chọn ma trận bắt buộc riêng trong tuần10–12: RNE/profile chính, n0..8 và control/flags theo contract; chốt trước khi chạy, không giảm sau khi thấy FAIL. AC04 cuối vẫn line≥95%,branch≥90%,toggle≥85% và functional bins; coverage Gate2 milestone chưa đồng nghĩa đã đạt AC04 cuối.

Tính mới cần trình bày là hiện thực và kiểm chứng hai kiến trúc trên cùng multiplier lặp, xử lý width/cut/đuôi có dấu, phân tích đánh đổi bằng thực nghiệm và khả năng tái lập. Fused arithmetic có trước; không gọi việc thêm fused là thuật toán mới nếu chưa có cải tiến cụ thể và so sánh nguồn. Nguồn định nghĩa single-round FMA: https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Fused-Multiply_002dAdd.html; SoftPosit có fused-multiply-add: https://www.posithub.org/khub_community.

### 11.9. Hợp đồng tích prepack FLOOR/RNE và checkpoint L1 — 11/10/2026

**Đã chốt** profile `L1_FLOOR_RNE_PREPACK_V1`: NB32/ES3,FRAC_W12,N_MAX8,OPS1 (min-popcount/tie-A),ROUND_SCHEME=FLOOR,ROUND_MODE=RNE. cfg_n đếm fraction, hidden riêng; n=0 chỉ hidden, n>8 bị từ chối. Đây là cấu hình so sánh chính; không đổi mặc định IterConfig legacy (OPS0/TRUNC) hoặc profile research. API chọn tường minh `floor_rne_profile(n)` và `FloorRneMultiplier`.

Với hữu hạn khác0: P_hat=(-1)^sign * magnitude * 2^(scale-fractional_bits). `scale=sf_A+sf_B` trước normalization; magnitude chứa hidden/carry, chưa pack, chưa saturate và chưa round về Posit. Scale signed11 bit đủ cho cấu hình32/3 (tổng scale hữu hạn[-480,480]); L1 lưu int32_t. Không suy ES3 là scale3 bit.

| Trường PrepackProduct | Nghĩa và quy tắc |
| --- | --- |
| magnitude | Accumulator unsigned trước mul_norm; FLOOR giữ tổng từng số hạng đã cắt. Không lấy lại từ parse(bits) |
| fractional_bits / magnitude_bits | Q và độ rộng hữu ích Q+2. FLOOR Q12/14 bit; exact Q52/54 bit ở32/3; JAM Q14/16 bit là profile phụ, không đóng băng cho fused |
| sign / scale | Dấu A XOR B và scale chưa chuẩn hóa; mantissa không bắt buộc trong[1,2) |
| is_nar / is_zero | NaR ưu tiên Zero; special magnitude=0,scale=0,sign=0,sticky=0; Q/width vẫn mô tả config nhưng công thức hữu hạn không áp cho NaR |
| numerical_sticky | Với FLOOR luôn0: phần đã bỏ trong thuật toán không còn thuộc P_hat. JAM sticky chỉ thông báo, không định lượng residual; không được dùng nó để suy exact fused |
| input_cut / iteration_cut / term_cut | Ba loại mất thông tin: cut input, fraction còn sau n, cut từng term. Là metadata, không đưa vào GRS của P_hat. `IterResult.approx_cut` legacy vẫn chỉ phần iteration, không tự đổi semantics flags |
| iterations / remaining_fx | Giữ trong IterResult; đếm và trace kiểm trước/sau mỗi term |

Mapping RTL hiện hành: FLOOR export magnitude=acc>>2,Q12 vì hai bit thấp là padding0; exact export acc,Q52; JAM acc,Q14. ACC_W vật lý32/3 với EXACT_EN1 là54 bit (EXACT_EN0 approximate-only16 bit), khác độ rộng hữu ích14 bit FLOOR. Giới hạn64 bit của L1 an toàn cho các format đã nghiệm thu; không tuyên bố arbitrary NB/ES.

**Kết quả kiểm tích hợp — 13/10/2026:** W11-01 xác nhận238.906/900.000 cặp ngẫu nhiên khác giữa pack(mul_norm legacy) và R(P_hat); thêm344.064 phép kiểm magnitude/scale/sign biên, tổng1.244.064 kiểm adapter mới với oracle dyadic độc lập,0 mismatch. `mul_prepack_norm_comb` giữ grid nguyên, đổi vị trí hidden từ Q sang Q+1 khi carry; không dịch bỏ bit thấp hoặc dùng metadata cut làm sticky. Legacy L1/RTL/Gate2 và hash freeze giữ nguyên. MAC so sánh mới dùng `week11::Model`/`posit_mac_nf`, không tuyên bố approximate bit-exact với PositMac legacy.

NF=R(R(P_hat)+C); reference F=R(P_hat+C). FLOOR loss được ghi vào metadata và không khôi phục bằng numerical_tail. Phần dư phát sinh khi căn C với P_hat phải có dấu và oracle integer/rational giữ đủ; `acc=0` chưa bảo đảm sum0 khi còn residual. Cửa sổ F hữu hạn phải có hợp đồng riêng trước RTL; chưa chốt ACC_WIN/jam/borrow của F trong checkpoint này. Nếu stream term thẳng vào C, phải chứng minh cùng P_hat và đúng thứ tự cut; cut sau căn chỉnh không tự tương đương cut trước căn chỉnh. Các shortcut chọn mốc/sticky §5.12 còn là sketch cần kiểm, không nghiệm thu bằng checkpoint prepack.

Kiểm đã chạy: Linux và Windows mỗi bản17.184.416 kiểm,2.097.703 kiểm trace từng term,99.641 exact/RNE so oracle integer/bit-list độc lập; trong đó16.777.216 cặp Q12 vét cạn ở n2/OPS1. Random/corner bốn format bao n0..8,OPS0/1,FLOOR/JAM,RNE/TRUNC,exact/approx; không phải vét cạn tất cả config. UBSan smoke51.296 kiểm đạt; MAC regression264.000 và round_unpacked4.954.184 kiểm đạt. Replay32.000 payload dòng pilot lịch sử khớp hoàn toàn sau chuẩn hóa LF/CRLF. Mismatch0; seed test20261011, generator20261009.

Checkpoint đóng băng **L1 hiện có và giao diện tích**, không phải L1 fused đã hoàn thiện hoặc RTL fused. Bằng chứng/hash/source/compiler/commands tại `results/l1_floor_rne_freeze/{summary.json,frozen_sources.sha256}`; code `prepack_product.hpp`, `floor_rne_profile.hpp`, exporter trong `l1_multiplier_iter.hpp`. Không sửa RTL/số học/default; Gate2 lịch sử giữ checkpoint nguồn cũ, không gọi đây là rerun16,8M RTL. Sau thay source phải kiểm lại trước tạo checkpoint mới; audit mặc định từ chối source hash đổi, `--refreeze` chỉ dùng sau review/test và giữ lịch sử Git.



### 11.10. Hợp đồng hiện thực NF tuần11 — 13/10/2026

`posit_mac_nf` là top structural mới; `mac_nf_wrapper` chứa điều khiển một giao dịch, không sửa standalone multiplier đã nghiệm thu. Profile hiện thực RNE/FLOOR, EXACT_EN=OPS_EN=1, NB/ES8/0,16/1,32/2,32/3; FRAC_W=min(F,12), N_MAX8, cfg_ops0/1, approximate n0..8. TRUNC/JAM/fused và feature-disable chưa được nghiệm thu trong top này. Profile so sánh chính32/3 OPS1 giữ cùng P_hat cho NF/F; OPS0 và exact là kiểm bổ trợ.

**Checkpoint lịch sử W11; top hiện hành thay bằng OPT-03 §11.16.** Luồng thực: parser A/B/C_eff hai tầng → OPS/core → normalize bảo toàn prepack + round_unpacked_comb → thanh ghi product/context → adder A1/A2/A3 → packer RNE P1/P2. round_unpacked_comb dùng pack/parse **tổ hợp**, kiểm đúng parse(pack(u)); không có thanh ghi Posit trung gian như v0. Đây là hiện thực đúng chức năng ban đầu; đường tổ hợp norm/pack/parse dài cần STA trước tuyên bố fmax. Với t=iterations thực tế,q=max(1,t): E0 nhận→L_valid=q+10→L_handshake=q+11 khi out_ready luôn1; early-stop/special dùng t thực tế, không luôn dùng cfg_n. Không có bypass rút ngắn latency. Top không nhận lại tại cạnh retire: II không stall tối thiểuq+12, khác II1 của riêng adder.

A/B/C_eff/config/acc_mode/acc_clr được nhận cùng handshake. C_eff=c nếu acc_mode0, accumulator nếu acc_mode1, và0 nếu acc_clr1. NaR được lưu ngay trong mã accumulator; parser C_eff suy is_nar, không cần bank acc_nar độc lập có thể lệch dữ liệu. Cổng rst_n đồng bộ đi qua bridge; leaf nhả bằng hai FF; startup gate đợi core_run, ba parser, adder và packer sẵn sàng. Không dùng tên reset top làm lý do bỏ bridge theo guideline.

Output-commit của wrapper là cạnh đầu tiên quan sát pack_out_valid && !committed_q; cập nhật accumulator đúng một lần nếu acc_mode_q, dù output đang stall. Kết quả giữ trong bank P2 của packer tới retire; busy chỉ nhả sau retire, nên giao dịch sau không đọc trạng thái cũ. acc_clr chỉ xóa khi input handshake; reset hủy pending và xóa accumulator/valid/context. Invalid cfg_ops2/3,n>N_MAX khi approximate hoặc acc_clr1 khi acc_mode0 không được nhận. Exact bỏ qua cfg_n; dataset W11 cấp n0..8. Giữ flags OR qua tích và tổng, NaR ưu tiên/xóa bốn cờ khác; Zero product không đưa metadata cut vào flags.

Mốc số học/protocol Gate3 đã lưu13/10 (không phải đóng toàn coverage §6.3): native32/3 10.000.000 completed/75.801 reset-aborted,0 mismatch; ModelSim28.512 completed/288 aborted, bốn format; strict lint4/4 sạch. Native bốn pilot20k/format; scoreboard gọi mô hình NF mới, oracle dyadic/full-grid add độc lập và exact product oracle; SoftPosit đúng format cho pilot8/0,16/1,32/2.72 config/control bins và256/256 regime–dấu ở main, min34944/bin;24/24 reachable adder bins và7/7 iteration bins; latency, reset/stall/context/flags/accumulation đã kiểm. Raw coverage ghép: line/branch từ pilot+main, toggle từ pilot; line96.92%,branch94.26%,toggle88.71%; giữ unhit, chưa thay final AC02/AC04/§6.7. Bằng chứng/hash/tool/seed/lệnh tại results/week11/summary.json và baseline_nf_manifest.json. Rà soát14/10 phát hiện thiếu phân bố near-cancellation30%; Phát hiện tại §11.11 đã được xử lý bằng checkpoint mới14/10 ở §11.12. Không sửa hoặc xóa report/manifest lịch sử.

L1 fused full-sum pilot100.000 mẫu32/3,FLOOR/Q12,OPS1,n0..8 đã đối chiếu Python integer độc lập0 mismatch;24.996 triệt tiêu chính xác. Software grid2^-532 và16 limb64 bit giữ tổng có dấu; chưa chốt cửa sổ RTL, flags hoặc state acc_mode F. Chưa gọi pilot này là oracle/L1 fused cuối, paired accuracy, baseline paper hoặc RTL F. Tuần12 tiếp tục oracle/width/residual và PPA sơ bộ NF; final NF/F matrix, coverage và STA/PPA còn ở các mốc sau.

### 11.11. Rà soát toàn SPEC và phạm vi nghiệm thu — 14/10/2026

Phát hiện dưới đây giữ lịch sử rà soát; phần coverage NF đã được đóng bằng checkpoint mới ở §11.12 trong cùng ngày.

Đã đối chiếu các mục 1–12 và phụ lục với RTL, model, Makefile và canonical reports. Phiên này chỉ sửa tài liệu; nguồn số học, L1 frozen, reset và pipeline đã kiểm giữ nguyên. Gate1/Gate1B legacy, Gate2, W10 unit và W11 numeric/protocol vẫn có bằng chứng **0 mismatch**.

**Gate3 đầy đủ còn processing do thiếu coverage theo §6.3:**

- W11 lưu `adder_bins` theo Δsf=0,1,2–7,... Tổng bin trái dấu thuộc ba nhóm này là **420.303 / 10.000.000 completed = 4,20303%**. Vì nhóm2–7 còn chứa5–7, đây chỉ là **cận trên** của nhóm≤4 tại đầu vào adder NF. Kể cả lấy mẫu số7.936.965 phép cộng hữu hạn có counters, tỷ lệ vẫn dưới30%.
- Coverage256/256 regime–dấu và24/24 reachable adder crosses không chứng minh đã đạt tỷ lệ near-cancellation30%. Không hạ ngưỡng hoặc sửa counters lịch sử.
- Counters từng run/polarity≥10k và các bin packer chuyên biệt chưa được report W11 đủ để ký signoff tích hợp. Cần thu và lưu riêng; không suy đã đạt từ các bin gộp.

**Việc bổ sung để đóng coverage Gate3:** đóng băng corpus đạtnear≥30% với `C_eff` thực tế; tách standalone/acc_mode, specials và reset-abort; đo trực tiếp Δsf=0..4, run/polarity và packer bins. Chạy pilot rồi regression/oracle0 mismatch, audit nguồn/hash và lưu checkpoint mới. Giữ checkpoint13/10; không đổi label nghiệm thu để giữ lịch. Có thể chuẩn bị L1 F độc lập trong khi bổ sung coverage NF.

Các yêu cầu chưa đạt khác vẫn mở: ma trận final AC01/AC02 theo n/profile, AC04 toàn phạm vi, hợp đồng và RTL F_W (width/residual/flags/acc_mode), paired accuracy, STA/CDC/RDC và PPA toàn top. Collector/orchestration còn scaffold. NFR MHz/LUT là mục tiêu khảo sát, chưa phải số đo.

Khác biệt carry giữa legacy và R(P_hat) đã có adapter riêng và bằng chứng ở §5.7/§11.9; không suy thành lỗi RTL tác giả. Báo cáo phiên rà soát tại `results/spec_review_20261014/summary.json`; bằng chứng thực thi ở `results/week9_implementation`, `week10_adder` và `week11`. Cập nhật SPEC không phải chạy lại10M hoặc nghiệm thu thêm F/PPA.

### 11.12. Đóng coverage NF/Gate3 tuần11 — 14/10/2026

**Tuần11 hoàn thành trong phạm vi Gate3 NF của PLAN8.5.** Checkpoint mới tại `results/nf_coverage_20261014/completion.json`; giữ nguyên report/manifest13/10 và proofgap tại §11.11. Chỉ bổ sung bộ kiểm/corpus/probes chỉ đọc, không sửa datapath RTL hoặc L1 frozen. Không suy Gate3 thành nghiệm thu toàn bộ AC, fused hoặc timing.

- Main mới32/3,FRAC_W12,FLOOR/RNE: **10.000.000 completed,75.379 reset-aborted,0 mismatch**; oracle độc lập và đối chiếu trực tiếp product/C_eff tại handshake adder. Near-cancellation **5.255.548/10.000.000=52,55548%**, vượt30%; đo trực tiếp Δsf0..4, tách standalone/acc_mode. Specials không vào tử số; reset-abort và corner bổ sung không vào mẫu số.
- **256/256** cross regime–dấu,min30.114/bin; **61/61** run/polarity hữu hạn,min199.470 operands;72/72 control,24/24 adder reachable,6/6 popcount và13/13 iteration×mode reachable. Approx>8 không thể đạt vì N_MAX8; p8 không có popcount/iteration>8.
- Packer7/7 loại đã quan sát ở P1 trong RTL tích và tổng; lưu counts riêng. Sat-min tại packer cuối NF không thể đạt: hai toán hạng đã là mã Posit, tổng khác0 là bội nguyên của minpos. Kiểm underflow ở packer tích; giữ điểm chưa hit trong raw coverage, không xóa điểm để tăng tỷ lệ.
- Pilot native20.000/format8/0,16/1,32/2,32/3; ModelSim fixture mới28.512 completed/288 abort,0 mismatch. Corner ModelSim riêng **82.944 completed,0 mismatch**, phủ8 mã biên^3×exact/approx×n0..8×OPS0/1 và fraction0/ones/AA/55 theo4 cặp dấu. Exact chạy tới F=5/12/27/26 vòng; kiểm latency tới36 ở32/3. UBSan generator đạt, strict lint4/4 sạch; kiểm reset/stall/context/flags/feedback và audit source/fixture/counters đã đạt.
- Verilator5.032,GCC15.2.0,SoftPosit0.4.1,ModelSim10.1d; seedbase20261014+100·NB+ES,mt19937_64. Source/corpus khóa sau pilot và kiểm lại trước main; audit từ chối RUNNING,hash đổi hoặc near<30%. Lệnh tái chạy tại PLAN8.9. Coverage main32/3 line96,9231%,branch94,2623%,toggle88,7136%; toggle từ pilot, không phải finalAC04 toàn ma trận.

**Còn mở, chuyển tuần12–15:** oracle/L1 F_W và hợp đồng signed residual/window/flags/acc_mode; RTL F; paired accuracy; final AC01/AC02 theo n/profile và exhaustive; AC04 đầy đủ, STA/CDC/RDC/PPA toàn MAC. Không có thay đổi số học hoặc nguồn paper mới nên không chạy lại TableI. W12-01 đã được xử lý trong phiên đóng tuần11; W12-02..07 chưa thực hiện.

### 11.13. OPS parallel-path refactor — 14/10/2026

Đã refactor ops_sel_comb theo §5.4, giữ toàn bộ parameter/default/port và số học; bản trước lưu tại results/ops_refactor_20261014/before/ops_sel_comb.sv. Audit so public header,source hashes và oracle; không sửa L1 hoặc M0/SAC/SBM/reset. X vẫn không hidden; Y có hidden trước Swap MUX. No-cut guard hợp lệ ở FRAC_W=FRAC_MAX.

ModelSim so RTL mới/cũ và oracle bit-count độc lập đạt **1.334.048 kiểm/0 mismatch**:378 cặp F1..27/FW1..F,4 feature combinations EXACT_EN/OPS_EN,4 profile SF_W2/WIDTH_W tăng. F<=5 vét cạn cặp fraction,mode0/1 và cfg_ops0..3; F>5 directed/random,không tuyên bố vét cạn2^54 hoặc formal HDL proof. Verilator strict lint398 profile0 warning; không latch. NF pilot20k/format và main32/3 mới10M/0 mismatch cùng seed/corpus; near52,55548%;ModelSim tích hợp28.512 completed/288 reset-abort,0 mismatch. Đã kiểm pipeline/control/flags và adapter theo oracle đúng format; không đổi latency/II.

Benchmark OPS toàn I/O,cùng bank input/output,dynamic mode/OPS,F26/FW12/SF_W11,ba seed mỗi bản,Quartus13.0sp1/EP4CE30F23C6/LUT4: **216→196 LUT4 (-9,2593%)**,151 FF giữ nguyên; Fmax trung vị **108,08→112,01MHz (+3,6362%)**. Cả6 run setup/hold R2R đạt ở10ns. Path seed1 từcfg_mode_q:before→y_mant[12],data9,045ns;after→x_frac[8],data8,866ns. Path control vẫn là ứng viên critical; không kết luận đã tối ưu tuyệt đối hoặc Fmax MAC đạt112MHz. Pins vật lý;không có I/O delay/board signoff. Package F17 ban đầu thiếu pins và virtual-pin không có license; đã dùng cùng partF23 hợp lệ cho cả6 run,không sửa license.

Canonical results/ops_refactor_20261014/summary.json; raw timing/top10 ở ppa/critical_paths.json và report STA. Checkpoint13/10 và coverage NF14/10 trước refactor giữ nguyên; audit lịch sử sẽ từ chối nguồn OPS mới do hash khác,đây là đúng cơ chế freeze. Dùng snapshot/commit nguồn cũ khi tái chạy lịch sử; dùng checkpoint refactor NF khi kiểm RTL hiện hành. Gate3 tuần11 vẫn đạt phạm vi đã kiểm;final per-n/AC02/AC04,F_W/F RTL,paired accuracy và STA/PPA toàn MAC còn mở. Không chạy TableI vì không có thay đổi hợp đồng hoặc nguồn paper mới.

### 11.14. Hoàn thành tuần12 — oracle/L1 F và timing NF,15/10/2026

**W12-01..07 đạt phạm vi kế hoạch; G-F-L1 ✅;đã sao lưu GitHub.** Không có thay đổi logic RTL NF hoặc legacy L1; freeze mới chỉ cho model/corpus/contract F. Các ghi chép trước đây nói F_W/oracle/flags/state chưa chốt là trạng thái lịch sử,được cập nhật bằng mục này. Canonical results/week12/{summary,freeze}.json; chi tiết PLAN8.14.

Oracle số nguyên full-grid decode/encode độc lập: posit8 exhaustive2^24=16.777.216 bộ ba so SoftPosit FMA; p16/1,p32/2 mỗi format100k smoke; F_ref32/3 cùng prepack100k so full-sum limb cũ. Tất cả0 mismatch; Windows/UBSan smoke cũng đạt. SoftPosit0.4.1/hash thư viện,compiler Linux GCC15.2.0,Windows GCC13-win32,lệnh và seed20261014 lưu cùng kết quả. ES3 không dùng SoftPosit ES2 làm oracle.

Chọn W32 từ bốn pilot32/48/64/96,mỗi bản100k,quy tắc chọn smallest admitted W với0 khác F_ref và thỏa cận precision đã khóa trước chạy. W32/Q29 đáp ứng profile approx32/3,FW12,n0..8,OPS0/1. Main ban đầu1m rồi suite phân tầng bổ sung **2.208.768 ca trên mỗi nền tảng Linux/Windows/UBSan,0 mismatch** bits/flags/state/retained magnitude/residual với oracle full-grid; corpus Windows/Linux byte-exact. Near trước/sau cut **1.160.774/2.208.768=52,55300693%**;256 cross min4128,61 run/polarity min26161,mỗi n ít nhất245418. Có counters Δsf0..4 tách standalone/acc_mode,popcount,iteration,540 reset state,2724 acc_clr,264193 giao dịch acc_mode; reset ở đây là model giao dịch,không phải bằng chứng waveform RTL F.

Corner6402 mỗi lượt kiểm,bốn pilot,các tie even/odd,borrow,underflow/overflow,NaR/Zero và six invalid requests đã kiểm; Python integer kiểm138 trace đầy đủ/0 mismatch. F_W/F_ref0 khác trên miền đã kiểm; F_ref/Ideal tại cùng C_eff khác1.377.327 bit-result trong corpus phân tầng vì phép nhân còn xấp xỉ. Đây là số ca khác mã,không phải sai số tương đối hoặc kết luận F luôn tốt hơn NF. Corpus cố ý kích near-cancellation,không thay phân bố ứng dụng/accuracy cuối tuần14.

**Toàn NF post-route:** Quartus13.0sp1/TimeQuest,EP4CE30F23C6,LUT4,32/3 FW12,EXACT_EN=OPS_EN=1,FLOOR/RNE,seed1/2/3. **3926 LUT4,823 FF,442 arithmetic-mode LE,DSP0/memory0**; Fmax47,10/45,07/44,65MHz,median45,07. Clock10ns,ngân sách I/O giả định max0,5/min0,1ns,derive_clock_uncertainty; không false-path/multicycle. Không có đường setup/hold unconstrained;hold/recovery/removal đạt mọi corner đã báo. **Setup100MHz chưa đạt**,không đạt Gate4 hay ngưỡng D0 của paper. Mô hình/chip Intel không quy đổi trực tiếp sang LUT6/CARRY8; không board/power signoff. Quartus13 bỏ qua ASYNC_REG nên còn review CDC/RDC/synchronizer riêng. Parser chỉ thêm generate/endgenerate trong source copy riêng để tương thích compiler; audit xác nhận không đổi logic.

Đường chậm nhất cả ba seed từ acc core qua normalize→round_unpacked(pack+parse) tới product_frac_q. Seed1 data21,477ns,63 logic levels,logic9,669ns/routing11,609ns,WNS−11,233ns. A1 align WNS−7,642ns; SAC−2,383ns; A3normalize−2,216ns; A2arith+5,031ns. Đề xuất ưu tiên: constant slices trong mul_prepack_norm_comb; sau đó chọn bank tách norm/pack/parse; đánh giá align candidate ở toàn NF; cân nhắc chuyển LOD từ A3 sang A2 còn slack; rút ngắn điều khiển hồi tiếp SAC. Chi tiết/đánh đổi FF,H,II tại results/week12/pipeline_recommendations.json. **Chưa áp dụng các đề xuất hoặc thay baseline**.

Bàn giao tuần13 theo §5.12-e và results/week12/handoff.json. F approximate-only cần comparator NF với EXACT_EN tương ứng đã kiểm/freeze trước paired PPA; số đo NF EXACT_EN1 tuần12 không tự tạo phép so công bằng với F EXACT_EN0. Còn F RTL/protocol/coverage,ma trận final theo n,accuracy ứng dụng,CDC/RDC và paired PPA; không chạy TableI hoặc mở lại baseline tác giả trong phiên này.

### 11.15. RTL fused W12-F-1 — 15/10/2026

**Đã hiện thực profile chính**, chưa đóng toàn bộ final/Gate4. Module mới: posit_mac_f (structural), mac_f_wrapper, fused_add_pipe và năm leaf fused_prepare_comb/fused_align_comb/fused_arith_comb/fused_abs_borrow_comb/fused_norm_comb. NF và L1 frozen giữ nguyên. Ngữ nghĩa vẫn fused trên P_hat xấp xỉ, không exact tích A×B và không quire.

**Mapping chốt:** core instance approximate dùng FRAC_MAX=FRAC_W12, ACC_W16, I_W4; OPS vẫn nhận fraction26 để phát hiện input_cut, xuất hai ứng viên right-aligned trước core. P_hat magnitude=acc[15:2], q12, scale=core_sf, sign=core_sign. Hai bit acc[1:0] phải0 với FLOOR. numerical_tail của core là metadata term_cut, không gắn vào numerical sticky của F. loss[1]=input_cut|approx_cut|term_cut,loss[0]=approx_cut; zero/NaR đầu vào xóa loss như L1. C_eff/context giữ riêng tới retire; NaR bất kỳ toán hạng hữu hiệu ưu tiên10000.

**Tối ưu đã dùng:** normalize carry bằng fixed slices; seed và dual delta chạy song song ởF1; mask/lost reduction song song với right shifter ởF2; F3 dùng XOR/carry-in cho add/sub; F4 tính abs(Z)-borrow bằng một adder với correction=negative-borrow; F5 chỉ giữ30 bit fraction hữu hiệu trước padding. Không mang shift/base_sign/subtract qua các bank sau khi hết dùng. Cổng diagnostic bắt buộc của module dùng chung không tạo register phụ; synthesis loại dây/padding hằng không dùng. Strict lint không có waiver rộng; 0 latch ở netlist. Không khẳng định phần trăm cải thiện Fmax/LUT nếu chưa có cặp F trước/sau đo cùng điều kiện.

**Control:** top giữ một giao dịch; five-stage fused_add_pipe elastic có thể chứa5 giao dịch khi kiểm riêng. Invalid cfg_mode0/n>8/ops2,3/acc_clr không cùng acc_mode không được accept. Reset bridge và release đồng bộ2FF; commit accumulator một lần khi output lần đầu valid, output giữ tới handshake; không nhận mới trước retire. E0 là accept, L_valid=q+11 (12..19 trong test), H=q+12, II_min=q+13; q=max(1,t), special zero/NaR dùng init-only t0. Stall kéo dài retire, không tạo commit lặp.

**Bằng chứng results/week13/summary.json:**

- Verilator5.032 strict --timing --assert -Wall:0 warning/error. Cycle harness --no-timing bỏ CK2Q, được bổ sung XSim có timing thực; không dùng cycle test thay kiểm delay.
- Pilot100.000 và main10.000.000 completed,0 mismatch với L1 F_W và independent full-grid oracle; main59.356.752 stage observations kiểm raw prepack, anchor, retained operands, tail, sum, magnitude/borrow, normalize trước pack. Near48,46403%;256 regime/sign cross và n0..8/ops0,1/acc_mode đều có hits. Main20.151 reset-aborted tách khỏi completed; hai lịch reset trùng được tính theo trạng thái thực, không cộng hai yêu cầu reset thành hai abort; counters/seed20261015 trong report.
- Unit fused_add_pipe100.005 completed/190 reset-aborted,0 mismatch; max5 inflight,74.524 consecutive retires,58.221 stalled cycles; seed20261016. Synthetic prepack đúng miền bổ sung các scale lớn và borrow, ngoài A/B corpus tích hợp.
- XSim2026.1:8192 completed,24 reset-aborts theo tuổi pipeline,0 mismatch với CK2Q1ns; invalid config, thay input lúc busy và output stall96 chu kỳ được kiểm. Assertion startup đã sửa để chỉ enable sau reset release biết chắc1 trong mô phỏng4-state; không sửa số học.
- Raw coverage points của module mới, gộp pilot+unit, không loại trừ: line20/21,branch39/40,toggle2168/2392. Đây là instrumented points, không tự đồng nhất với final AC04 theo toàn thiết kế. Coverage chi tiết tại coverage.json; đã bổ sung counters61 run/polarity,6 nhóm popcount và delta0..4 theo standalone/acc_mode trước/sau cut. Matrix cuối vẫn theo tuần14.

**STA sơ bộ toàn F:** Vivado2026.1 build6511674,xc7a35tcpg236-1,Default,một run OOC,period10ns/uncertainty0,1ns.1520 Slice LUT,815 FF,DSP0/BRAM0/latch0. R2R setup+1,678ns,hold+0,039ns; synthetic whole-design setup+1,082ns. F_STA suy từ slack khoảng120,16MHz, không phải sweep đã chạy120MHz hoặc đo board. Critical path accumulator_q→parserC/p1_cnt_q,logic2,985ns/routing5,236ns. F1..F5 data delay lần lượt7,660/4,861/4,733/4,009/7,528ns. Inputmin=max2,5ns/outputmax0,5,min0 là budget tổng hợp khảo sát; XDCH-2,CFGBVS và OOC PARTPIN warnings được lưu, chưa board signoff. Không có routing error hoặc unconstrained endpoint nội bộ theo reports. Không so trực tiếp với NF45,07MHz CycloneIV.

**Còn mở:** final >=10^7 vector/n/bản, AC04 và coverage counters đầy đủ; CDC/RDC/formal; comparator NF EXACT_EN0 đã kiểm trên cùng Xilinx và >=3 run; paired accuracy/PPA/Gate4. Lần tối ưu tiếp nên xem accumulator→parser C và F1/F5; mọi retiming phải cập nhật latency/II và kiểm lại. Commands, tool/compiler, source/evidence hashes và giới hạn trong summary.json; audit_week13_fused.py từ chối nguồn/report không đồng nhất. Không tạo lại baseline tác giả hoặc chạy TableI trong mốc này.

## 12. Báo cáo và bảo vệ

**Cấu trúc báo cáo đề xuất**

1. Mở đầu: động lực, bài toán, đóng góp (C1..C5).
2. Cơ sở lý thuyết: posit, Mitchell/Babic, nhân lặp, các công trình liên quan.
3. Thiết kế: kiến trúc từng khối (theo §5), quyết định thiết kế và lý do.
4. Kiểm chứng: golden model 3 tầng, testbench, kết quả AC-01..AC-04, thống kê sai số.
5. Kết quả tổng hợp: PPA FPGA, so sánh baseline, phân tích §7.4, (EXT-A ASIC).
6. Thảo luận: sai khác so với paper, hạn chế, hướng phát triển (quire,chồng lấn,ứng dụng khác); fused là mục tiêu chính còn phải hoàn thành,không chuyển thành hướng tương lai để bỏ nghiệm thu.
7. Kết luận. Phụ lục theo SPEC: A (số liệu gốc [P]), B (giả định vector), C (kết quả tái hiện), D (truy vết), E (thuật ngữ); giao diện và log công cụ là phụ lục bổ sung của báo cáo.

**Bảng và đồ thị dữ liệu cần xuất từ script**: Correct Rate và Err theo n và nhóm regime; NMSE theo n; phân bố số vòng lặp thực tế; bảng PPA; Pareto (EXT-B); bảng tài nguyên theo module (hierarchical).

**Kịch bản demo mục tiêu:** ví dụ NF/F trên cùng A/B/C,n0/1/2/3/8 và exact; chạy runner smoke của đúng top,hiển thị canonical JSON và PPA đo. make demo/results/summary.md hiện chưa có; không trình bày scaffold như demo hoàn tất.

---

<!-- OPT03_REPORT_START:SPEC_Posit_MAC_IP.md -->
### 11.16. NF OPT-03 — pipeline làm tròn tích, 17/10/2026

Hợp đồng hiện hành tại §5.1/§5.11-B: product RNE P1/P2 trước parse/product bank; L_valid=q+12,H=q+13,II_min=q+14. R(P_hat), flags, width và fused giữ nguyên. Chi tiết reset/credit/sticky và cạnh clock tại §5.11-B; kết quả/commands tại PLAN§8.21.

| Part | Median STA MHz trước → sau | Thay đổi | Median LUT trước → sau | FF trước → sau |
| --- | --- | --- | --- | --- |
| xc7a35tcpg236-1 | 52.31 → 78.41 | +49.90% | 2464 → 2462 | 847 → 930 |
| xc7a100tcsg324-1 | 53.69 → 79.28 | +47.66% | 2458 → 2449 | 847 → 930 |

Native main10M/85316 abort,0 mismatch;4 strict lint sạch. ModelSim82.944 corner+28.512 protocol/288 abort và284 reset-age đạt. chưa đạt R2R setup100MHz ở tất cả run; chưa board signoff/final per-n/AC04 hoặc matched NF/F. Baseline reference source-identical được tái dùng và Default được kiểm lại2 part. Không xác nhận baseline gốc paper hoặc chạy Table I.
<!-- OPT03_REPORT_END:SPEC_Posit_MAC_IP.md -->

## Phụ lục A. Tóm tắt số liệu của [P] để đối chiếu

**Table I — độ chính xác trong dải SPFP** (tỉ lệ đúng, Err < ngưỡng)

| n | Thuật toán | <0.1% | <0.5% | <1.0% | <5.0% |
| --- | --- | --- | --- | --- | --- |
| 2 | Babic | 19.14 | 47.37 | 65.13 | 99.13 |
| 2 | Kim | 9.30 | 32.12 | 50.01 | 95.58 |
| 2 | Proposed | 9.87 | 32.19 | 50.03 | 95.57 |
| 3 | Babic | 70.52 | 95.52 | 99.43 | 100.00 |
| 3 | Kim | 43.94 | 83.01 | 95.03 | 100.00 |
| 3 | Proposed | 44.69 | 83.17 | 95.05 | 99.99 |
| 4 | Babic | 98.03 | 100.00 | 100.00 | 100.00 |
| 4 | Kim | 86.69 | 99.81 | 100.00 | 100.00 |
| 4 | Proposed | 87.09 | 99.79 | 99.99 | 99.99 |

**Table II — ngoài dải SPFP** (so với posit multiplier chính xác)

| n | m | <0.1% | <0.5% | <1.0% | <5.0% |
| --- | --- | --- | --- | --- | --- |
| 2 | > 22 | 92.13 | 92.13 | 92.13 | 92.33 |
| 2 | 18–22 | 26.41 | 31.17 | 45.85 | 95.56 |
| 3 | > 22 | 98.71 | 98.71 | 98.71 | 98.76 |
| 3 | 18–22 | 68.96 | 76.43 | 89.87 | 99.95 |
| 4 | > 22 | 99.73 | 99.73 | 99.73 | 99.74 |
| 4 | 18–22 | 92.53 | 95.69 | 98.61 | 99.95 |

**Table III — FPGA (xcvu9p)**

| | Babic† | Kim | Jaiswal (PACoGen) | Proposed |
| --- | --- | --- | --- | --- |
| Định dạng | SPFP | SPFP | posit32 | posit32 |
| Kiến trúc | Lặp | Lặp | Pipeline | Lặp |
| Thiết bị | xcvu190 | xcvu190 | xcvu9p | xcvu9p |
| fmax (MHz) | 450 | 500 | 380 | 575 |
| LUT | 685 | 308 | 1247 | 698 |
| FF | 241 | 100 | 303 | 289 |
| Độ trễ | n+4 | n+2 | 5 | n+6 |

Kiểm tra số học: (1247 − 698)/1247 = 44.0% (giảm LUT); 575/380 = 1.51 (tăng 51% fmax).

## Phụ lục B. Ghi nhận giả định (điền trong quá trình làm)

Mỗi giả định về phân phối vector, cách sinh, cách tính Err và cách so sánh ghi thành một dòng: `ID | mô tả | lý do | ảnh hưởng dự kiến | ngày`.

| ID | Mô tả | Lý do | Ảnh hưởng / giới hạn | Ngày |
| --- | --- | --- | --- | --- |
| W4-01 | FP32 normal dương, sf đều [-120,119], fraction 23 bit đều; đổi posit32 ES3 bằng RNE, loại m>15; không lọc scale tích | Diễn giải điều kiện đầu vào Fig. 6(a), phân bố gốc chưa đủ chi tiết | Ideal là tích FP32 gốc chưa làm tròn; tích có thể ngoài dải FP32, nên đây là giả định cần xác minh | 04/10/2026 |
| W4-02 | 900 ô mA/mB=1..15 × hai polarity regime mỗi toán hạng, exponent/fraction đều; input dương, Ideal là tích posit giải mã chưa làm tròn | Kiểm độ nhạy trên phân bố phân tầng | Không phải bộ dữ liệu gốc [P]; không dùng L0 posit32 ES2 để chuẩn ES3 | 04/10/2026 |
| W4-03 | FRAC_W=12, OPS=0/1 theo §5.4, FLOOR/TRUNC theo §5.6/5.9; STICKY_ACC là phép đo bổ sung riêng | Giữ thuật toán normative và phân biệt các profile | Chưa xác minh profile Table I gốc dùng cùng OPS, width, rounding; vector Fig. 4 khớp chưa chứng minh thống kê Table I khớp | 04/10/2026 |
| W4-04 | Seed 314159, 10 triệu cặp/hàng n=1..6, cùng đầu vào giữa các n; strict Err<ngưỡng | So sánh lặp lại được | Không suy rằng khác biệt phân bố là nguyên nhân duy nhất; cần đối chiếu [15] và điều kiện dải của tích | 04/10/2026 |


### Bổ sung sau khi đọc [15] và triển khai baseline — 04/10/2026

Các W4-01..04 ở trên mô tả thí nghiệm lịch sử. W4-01 không dùng miền 0..1 của [15], Ideal chưa làm tròn; không dùng log đó làm phép tái hiện baseline mới.

| ID | Quyết định / nguồn | Giới hạn |
| --- | --- | --- |
| PB-01 | [15] §4.1: 200 triệu phép nhân trên SPFP ngẫu nhiên 0..1. Dự án chọn mt19937_64 seed 314159 và grid k/2^24 trong [0,1); đây là giả định uniform-value, không phải seed/phân bố paper công bố | Chạy thêm uniform-bits một triệu cặp để kiểm độ nhạy; không thay phân bố để ép khớp |
| PB-02 | Baseline RND: threshold 1,5, số hạng có dấu, complement fraction; OPS LUT n=2/7-bit tái dựng, tie A; acc Q12 FLOOR từng số hạng, pack TRUNC | Paper không cung cấp LUT gốc/chi tiết toàn bộ cut; chưa tuyên bố RTL gốc bit-exact. PaperOps và POLICY của module khảo sát không đổi ngữ nghĩa cfg_ops §5.4 |
| PB-03 | Ideal là FP32 multiply đã round RNE; loại input zero/Ideal=0/m>15, N đếm cặp hợp lệ | Chính sách đếm zero là của dự án; oracle có ties/subnormal tests và conversion identity |
| PB-04 | Algorithm 1 [15] n đếm toàn bộ số hạng; API profile cũ tính hidden riêng. Fig.4 [P] hai bước fraction tái hiện bằng ba tổng số hạng của profile mới | Giữ nghĩa cfg_n normative cho RTL theo §5.5; n_terms=n_fraction+1 chỉ đổi bộ đếm cùng chuỗi, không chứng minh tương đương recurrence/cut |
| PB-05 | Variant chỉ đổi OPS sang min-popcount12; RTL popcount cây cân bằng. Quartus EP4CE22F17C6, clock 10ns, seed 1/2/3, same registered boundary | OPS riêng, chưa là full MAC, cùng LUT4 của device khảo sát; chưa đo I/O board/sign-off |

## Phụ lục C. Kết quả tái hiện (điền trong quá trình làm)

Bảng ba cột song song `[P] | L1 | RTL` cho Table I/II/III, kèm sai lệch và giải thích.

**Thí nghiệm L1 tuần 4 ngày 04/10/2026, chưa nghiệm thu tái hiện Table I.** Các ô tỷ lệ theo thứ tự Err<0.1% / 0.5% / 1% / 5%. L1 dưới đây dùng FP32 (W4-01), OPS=1, FLOOR/TRUNC, FRAC_W=12, 10 triệu cặp/hàng:

| n | [P] Proposed (%) | L1 (%) | RTL | Sai lệch tối đa (điểm %) |
| --- | --- | --- | --- | ---: |
| 2 | 9,87 / 32,19 / 50,03 / 95,57 | 8,325190 / 28,306250 / 42,170570 / 82,548550 | Chưa triển khai | 13,021450 |
| 3 | 44,69 / 83,17 / 95,05 / 99,99 | 24,316250 / 58,613290 / 73,548700 / 95,142350 | Chưa triển khai | 24,556710 |
| 4 | 87,09 / 99,79 / 99,99 / 99,99 | 47,330050 / 80,897990 / 88,906170 / 95,893540 | Chưa triển khai | 39,759950 |

Phân tầng W4-02 cũng chưa đạt (max 39,766460 điểm %), STICKY_ACC trên W4-01 max 34,582500 điểm %. TV-ITER-01/TV-PAPER-01 đã khớp trace; oracle approximate, iterative exact và UBSan đạt. Các kết quả chức năng không thay tiêu chí Table I ≤1 điểm %. Lệnh, giả định và toàn bộ n=1..6 xem `l1/README.md`, `results/week4_table1_floor.log`, `week4_table1_ops1.log`, `week4_table1_stratified.log`, `week4_table1_sticky.log`. Table II/III và RTL chưa đo.


### Kết quả baseline mới và biến thể — 04/10/2026

Thí nghiệm lịch sử ở trên được giữ để truy vết. Dưới đây là baseline RND/SEL mới, FP32_RNE Ideal, uniform-value [0,1), 200 triệu cặp/hàng; các tỷ lệ theo thứ tự Err<0,1/0,5/1/5%.

| n | [P] Proposed (%) | Baseline mới (%) | RTL multiplier | Max lệch Proposed (điểm %) |
| --- | --- | --- | --- | ---: |
| 2 | 9,87 / 32,19 / 50,03 / 95,57 | 8,714937 / 31,177290 / 49,285731 / 95,463330 | Chưa triển khai | 1,155063 |
| 3 | 44,69 / 83,17 / 95,05 / 99,99 | 43,337090 / 82,859994 / 94,981795 / 100 | Chưa triển khai | 1,352910 |
| 4 | 87,09 / 99,79 / 99,99 / 99,99 | 86,286286 / 99,797782 / 100 / 100 | Chưa triển khai | 0,803714 |

Max lệch so **Kim [15]** là 0,942710 điểm %, còn **Proposed [P] chưa đạt <=1 điểm %**. 200.000.023 cặp thử, 23 input-zero loại, N=200 triệu cặp hợp lệ. Min-popcount có tỷ lệ Err<0,1% n=2/3/4 lần lượt 4,076841 / 26,717347 / 72,468581; thấp hơn baseline.

OPS RTL đơn vị đã kiểm ModelSim 116.384 cặp. Quartus ba seed/policy: predictor 73 LUT4/15 FF, fmax 198,18–206,06 MHz; minpop cây cân bằng 63 LUT4/25 FF, fmax 200,40–220,90 MHz. Giảm LUT4 **13,70%**, tăng FF, fmax range chồng lấn và variant nhiễu >10%; chỉ kết luận đánh đổi giảm LUT ở thiết bị này, không suy full MAC/PPA của paper. I/O pin tự gán và chưa ràng buộc board; timing khảo sát register-register.

Bằng chứng: `results/paper_table1_200m.log`, `paper_baseline_verified.log`, `paper_baseline_ubsan.log`, `ops_ppa_summary.csv`, `ops_ppa/sim/verified.log`. Công thức, giả định và lệnh tại README L1 mục 5/6. Tuần 4 giữ processing.

## Phụ lục D. Ma trận truy vết hiện thực

| Yêu cầu | Suite hiện có | Bằng chứng / phần mở |
| --- | --- | --- |
| FR01,FR03 | parser_comb/parser_pipeline và tests tuple hỗ trợ | results/parser_comb,results/parser_pipeline; tuple khác chưa nghiệm thu |
| FR02,FR04 | packer unit/chain và NF special/context tests | results/packer/summary.json,results/week11/summary.json; bypass rút ngắn chưa có |
| FR05..FR08 | Gate2 standalone16 profile,OPS/SAC/core suites | results/week9_implementation/gate2_acceptance.json; final per-profile matrix còn mở |
| FR09 | W10 comb/pipeline + independent integer oracle | results/week10_adder/summary.json; final AC02/AC04 còn mở |
| FR10,FR12..FR15 | W11 direct NF model/oracle,harness và ModelSim replay | results/week11/summary.json; coverage near30% chưa đạt theo §11.11,không gọi mọi tiêu chí Gate3 đã đóng |
| FR11 | Oracle full-grid độc lập,L1 F_W32 và state/flags | results/week12/{summary,freeze}.json: G-F-L1 đạt trong profile đã chốt; F RTL và ma trận final còn mở |
| FR16 | Chồng lấn/FIFO/credit | Chưa triển khai; cần protocol/II coverage sau thiết kế |
| NFR01 | Strict lint Gate2/W10/W11 | Logs đi cùng canonical reports; chưa CDC/RDC/STA signoff |
| NFR02..05,AC05/06 | OPS/packer PPA riêng | results/ops_ppa,results/packer_ppa; chưa NF/F whole-top PPA |
| AC07/08 | Runner/source/fixture/library hashes và manifest | Đã có tái lập theo mốc; orchestration toàn bộ và traceability final cần hoàn thiện |

Tên TC-* chuẩn và fail-vector tự động sẽ gắn với suite/case cụ thể khi triển khai. Không dẫn tới các results/mac.csv/fused.csv/ppa.csv placeholder như bằng chứng tồn tại.

## Phụ lục E. Bảng thuật ngữ

| Thuật ngữ | Nghĩa |
| --- | --- |
| NaR | Not a Real, giá trị đặc biệt của posit (chuỗi `1 0…0`) |
| maxpos / minpos | Posit dương lớn nhất / nhỏ nhất |
| useed | `2^(2^ES)` |
| sf | Scale factor `= k·2^ES + e` |
| FRB | First Regime Bit, bit đầu của regime |
| LOD / LZD / LZC | Lead-One Detector / Lead-Zero Detector / Leading-Zero Counter |
| OPS / SAC / SBM | Operand Selector / Shift Amount Calculator / Shift-Based Multiplier |
| RNE | Round to Nearest, ties to Even |
| SPFP / DPFP | Single / Double-precision floating point |
| PPA | Power, Performance, Area |

### Bổ sung kiểm chứng bộ đo bước 3 — 04/10/2026

Profile nghiên cứu Table I dùng bộ đo `l1/include/paper_measurement.hpp` và quy tắc README L1 mục 8: Ideal FP32 RNE từ input gốc; loại ngoài miền, input zero, m>15, Ideal zero/nonfinite theo thứ tự; nhận subnormal khác 0. Bốn ngưỡng dùng so sánh số nguyên chính xác với dấu <. Grid24, PRNG và seed là lựa chọn tái lập của đồ án, không phải thông tin đã công bố của paper. Suite Linux/Windows/UBSan đạt 1.900.058 đối chiếu; smoke 100.000 accepted mỗi phân bố khớp counters/fingerprint. Chưa nghiệm thu lại 200 triệu bằng bộ đo mới; không đổi yêu cầu normative của MAC.

### Khảo sát giả định OPS — 04/10/2026

Công cụ nghiên cứu riêng test_paper_sensitivity khảo sát 7 profile, 5 seed x 10 triệu mẫu/hàng. Baseline không giải quyết sai lệch bằng đổi seed/tie/pack. Biến thể score predictor E/M (n=2, 7-bit) xác nhận 200 triệu mẫu seed 271828 có max lệch Proposed 0,976696 điểm %, baseline cùng corpus 1,347652. Đây là kết quả số học của biến thể, chưa chứng minh LUT gốc và chưa đo PPA; không thay cấu hình normative cfg_ops hay baseline hiện hành. Xem README L1 mục 10.

### Profile nghiên cứu E/M tích hợp L1 — 04/10/2026

PaperOps::PredictN2Relative chọn toán hạng theo E/(128+index7), LUT n=2/7-bit giữ nguyên; nhân chéo nguyên, tie-A. Chỉ áp dụng profile PaperMultiplier, không thay cfg_ops kiến trúc hoặc các mã reserved. API mặc định vẫn PredictN2. Kiểm chứng 35.503.586 đối chiếu Linux/Windows/UBSan; bộ đo chính thức --profile relative/--require-match đạt PASS trên 200 triệu accepted seed 271828, max Proposed 0,976696 điểm %. Baseline cùng corpus 1,347652. Đây là nghiệm thu chức năng/số học của biến thể với giả định generator địa phương, chưa xác nhận LUT gốc hoặc PPA. Xem README L1 mục 11.

### Nghiệm thu L1 adder tuần 5 — 04/10/2026

posit_adder.hpp hiện thực SPEC §5.8 với clamp F+2, jam đuôi/cộng-trừ theo độ lớn, carry/LZC và normalized unpacked output; API unpacked yêu cầu ngõ vào exact <=F bits (MAC v1 phải round_unpacked trước). Tuần 5 đã đạt 65.536 cặp posit8, toàn 4.294.967.296 cặp posit16 và 10 triệu posit32 ES2 so SoftPosit, 0 mismatch. ES3 thêm 10 triệu so oracle integer rộng; không suy ra đã đối chuẩn SoftPosit ES3. Linux/Windows/UBSan và regression đạt. Không đổi yêu cầu normative và không công bố Gate 1B vì chưa triển khai MAC. Xem README L1 mục 12 và results/week5_adder_acceptance.log.


### Baseline tái dựng theo nguồn và comparator Babic — 04/10/2026

PaperOps::PredictN2Pattern dùng prefix7 mở rộngQ12 trước complement; so lỗi tuyệt đối/tie-A. paper_source_config có anchor_first=true, accumulator_guard=12, inputfraction12 và packTRUNC. Đây là profile nghiên cứu có provenance, không thay cfg_ops §5.4, mặc định PaperConfig hoặc độ rộng normative §5.6; LUT n2/tie và width gốc chưa xác minh.

Bộ đo chính thức200 triệu accepted seed271828/grid24 đạt PASS maxProposed0,984213 điểm %, fingerprint04478e811a897da7; baseline cùngcorpus1,347652. API kiểm29.878.945 đối chiếu Linux/Windows/UBSan, regression đạt;24 ô baseline/relative cũ giữ nguyên. Pilot5seed có hai max hơi vượt1 (1,000560/1,006150), không tuyên bố mọi phân bố/seed đạt.

Paired FP32/Posit200 triệu có conversion/cut unchanged và12 tỷ lệ khớp ở độ chính xác log; maxKim0,801969. Comparator Babic riêng recurrence2010/full FP32 significand/no cut11/outputRNE đạt max0,009091 điểm % trên200 triệu cùngcorpus. Không thay core Proposed bằng recurrence hai toán hạng. Bản Babic2011 đầy đủ/code/generator chưa kiểm được. Nghiệm thu TableI số học của baseline tái dựng đạt; khẳng định thuật toán gốc bit-exact chưa đạt. Chi tiết API/lệnh/provenance/log tại README L1 mục14.

### Nghiệm thu MAC L1 tuần6 — 04/10/2026

MAC v0/v1 non-fused, flags OR qua hai bước làm tròn, bypass và trạng thái acc_mode/acc_clr đã triển khai. Gate1B Linux/Windows đạt36.841.216 đối chiếu/nền tảng: 2^24 bộ ba posit8, 10 triệu posit32 ES2 so L0 non-fused, 10 triệu ES3 so oracle integer, corner/state; 0 mismatch và coverage §6.3 đạt. API C/ctypes/client C, UBSan và regression đạt. Tuần6/Gate1B hoàn thành về mô hình số học; không suy ra đã nghiệm thu handshake, latency/II, stall hoặc RTL/DPI harness. README L1 mục15 và results/week6_* ghi bằng chứng. Phần mô tả tuần5 chưa có MAC ở trên là lịch sử tại thời điểm nghiệm thu tuần5.

### Đối chiếu nguồn journal2024 — 08/10/2026

Nguồn, các trang đã đối chiếu, giả định và lệnh kiểm ở README L1 mục18; `results/paper_journal2024/summary.json` ghi PASS128 entry PT2/0 mismatch, hai entry khác legacy. Chỉ nghiệm thu diễn giải predictor trên miền prefix7 đệm0 Q12; không xác nhận LUT/tie/width/generator gốc. Kết quả TableI200M trước đây không thay đổi; tuần4 giữ processing. Không thay §4–§6, profile normative, ES hoặc lịch RTL bằng cấu hình journal2024.

### Hợp đồng width/cut tái dựng Fig.3 — 08/10/2026

README L1 mục19 là mô tả/lệnh chi tiết; `paper_fig3_config()` và `paper_fig3_accumulator.hpp` thực thi fraction12, payload13 + carry riêng (tổng Q2.12/14 bit), guard thấp0. Tk=floor(Y/2^(p1−pk)) với Y có hidden; áp dấu ck sau cut rồi cập nhật A. Dịch>=13 trả0, carry đi cùng feedback, không wrap/borrow; normalize sau vòng cuối, fraction đầu ra12 và TableI packTRUNC. Đây là mã hóa địa phương cho mạch cờ bị lược khỏi hình; không thay ACC_W, ROUND_SCHEME hoặc cfg_ops normative.

Chức năng PASS Windows/Linux/UBSan, vét cạn16.777.216 cặp Q12, raw/corner đến n8, trace và regression liên quan; xem `results/paper_fig3/summary.json`. TableI200M cùng seed271828/fingerprint cũ cho max1,292319 điểm %, **chưa đạt AC-03**; source guard12 cùng lượt vẫn0,984213. Năm pilot10M đều vượt1. Mốc kiểm width/cut tái dựng hoàn thành, xác minh baseline gốc và tuần4 vẫn processing ở provenance/tie/generator cùng tiêu chí số học. Không suy ra gap do một giả định cụ thể khi chưa có nguồn xác nhận.

### Kiểm bằng vector phân biệt — 08/10/2026

README L1 mục20/`results/paper_discriminators/summary.json` ghi bốn bước đã hoàn thành:292 bản ghi/206 trường hợp,10 ứng viên,205.882 kiểm/nền tảng Windows/Linux/UBSan PASS và đối chiếu Fig.4/5 trực tiếp. Source không cut output trả0x1ae34800 thay0x1ae34000 nên bị loại khỏi baseline bit-exact2021; nghiệm thu source TableI trước đây chỉ giữ ý nghĩa thống kê lịch sử. Fraction đầu ra12 bit có căn cứ hình packer, guard nội bộ chưa được xác minh.

Đo200M accepted seed271828/fingerprint04478e811a897da7, cùng corpus cho fig3/guard12-pack12/source-uncut: maxgap1,2923195 /1,3387730 /0,9842130 điểm %. Hai profile khớp output chưa đạt ngưỡng TableI; source chỉ đạt thống kê. Baseline gốc vẫn processing ở tiêu chí số học và provenance tie/PT2 padding/normalize/cờ/generator. Không thay hợp đồng normative §4–§6 hoặc chọn cấu hình nhờ khớp tỷ lệ đơn thuần.


### Gate2 tool availability recheck - 10/10/2026

Rechecked 2026-10-10: WSL PATH contains g++ and make, but no Verilator or yosys. No installation is authorized. Official Verilator lint/harness remain unrun; Gate2 stays processing. No RTL changes, no simulation rerun, no Table I rerun. Historical stratified ModelSim evidence remains 16,815,920 completed transactions, 80,080 reset aborts, 0 mismatch. W9-03/R1/R2/04/05 evidence is retained; W9-06 is not accepted. No new source evidence justifies W9-R3.


### Verilator installed; lint timing option corrected - 10/10/2026

Verilator 5.032 (Debian 5.032-1) is now installed by the user. Makefile lint explicitly uses --timing, preserving CK2Q delays. Re-run make lint: NEEDTIMINGOPT removed, exit 2 from make, 60 warnings remain (including MULTITOP, width and UNOPTFLAT diagnostics). No warning suppression, no RTL arithmetic changes, no functional harness run or Table I rerun; Gate2 remains processing. Raw output/version appended to results/week9_implementation/lint.log. Earlier missing-tool entry is historical.


### Harness Verilator pilot — 10/10/2026

Pilot Verilator5.032 đã build/chạy đủ16 profile từ final_pilot:32.000 dòng,31.840 so sánh,160 reset hủy,336 stall96 chu kỳ,0 mismatch. Hash fixture và counters khớp ModelSim parallel_pilot; kiểm config reserved/n>8, startup/reset, latency, đổi context lúc busy, stall/order. Runner mặc định chuyển sang final_pilot còn giữ; preflight16 fixture, snapshot nguồn và make với đường dẫn tương đối/CURDIR=. xử lý thư mục có khoảng trắng, không sửa cài đặt. --no-timing bỏ delay CK2Q cho mô phỏng chu kỳ; warning giữ trong build.log, -Wno-fatal chỉ dùng build chức năng, không thay strict lint. Đây là fixture replay, chưa phải scoreboard gọi trực tiếp L1/L0. Gate2/W9-06 vẫn processing: lint còn cảnh báo, cần scoreboard trực tiếp, corpus phân tầng>=10^7 và coverage; line/branch/toggle chưa đo. Vector lớn đã dọn, phải sinh lại và kiểm hash trước replay. Không sửa RTL số học hoặc chạy TableI. Bằng chứng results/week9_multiplier/verilator/final_pilot/summary.json; lệnh bash --noprofile --norc scripts/verify_week9_verilator.sh final_pilot, audit scripts/audit_week9_verilator.py. Seed20261009; compiler/make/version và hash lưu cùng kết quả.

### Gate2 normative multiplier — nghiệm thu10/10/2026


Gate2 multiplier **✅** theo mốc tuần9 (10/10/2026):16.815.920 giao dịch phân tầng/0 mismatch; scoreboard trực tiếp L1/L0 và oracle ES3; strict lint16/16 sạch; corner114.656/0 mismatch trên ModelSim và Verilator. Seed20261009, SoftPosit0.4.1, GCC15.2.0, Verilator5.032 và ModelSim10.1d; lệnh/hash/phiên bản lưu với bằng chứng.

Coverage chức năng đạt256/256 bin posit32, min4104 mẫu/bin,26241 operands/run/polarity và36 ô config/profile; structural coverage sau ghép corner: line 91.67–96.23%; branch 91.84–94.79%; toggle 73.10–87.33%, giữ các điểm chưa hit. Mốc này không quy định ngưỡng phần trăm structural coverage và không phải coverage100% hoặc signoff vật lý.

Trạng thái canonical tại `results/week9_implementation/gate2_acceptance.json`; hướng dẫn tái lập và giải thích phạm vi tại PLAN L1 mục7.11. Những mục processing trước đây là lịch sử. Ma trận cuối SPEC§6.7, tuần10 adder/tuần11 MAC-Gate3 và PPA/Gate4 còn mở; provenance/TableI giữ processing, không chạy lại TableI trong phiên này.


### Ghi chú tổ chức nguồn — 15/10/2026

Đường dẫn hiện hành phân nhóm theo `rtl/README.md` và `rtl/production.f`; thư mục `research`, `candidates`, `benchmarks` tách khỏi file list production.
Đợt di chuyển không đổi phiên bản hợp đồng v1.18, nội dung RTL, giao diện hoặc lịch pipeline. Hash và số đo trong báo cáo cũ vẫn tham chiếu checkpoint gốc; bản đồ đường dẫn/hash ở `results/layout_cleanup_20261015/rtl_migration.json`.


### Ghi chú hiện thực primitive — 16/10/2026

`rtl/common/lod_lzd_core.sv` dùng cây chọn nhóm4 khi MODE=0,N=31 hoặc32,S=clog2(N); mọi cấu hình khác giữ cây nhị phân gốc. Đây là lựa chọn hiện thực đã kiểm bit-exact, không thay quy ước K/vld, parameter/ports, latency, precision hoặc hợp đồng số học v1.18. MODE1 và parser posit32 N30 vẫn dùng cây gốc. Hai dynamic shifter giữ nguyên sau khi khảo sát timing/LUT trên A35T và A100T; không chọn bản giảm LUT nếu đánh đổi timing không phù hợp.

Bằng chứng nguồn và tổ hợp LOD–shifter ở `results/primitive_v2_20261016/adoption.json`, chi tiết PLAN§8.18. Kiểm tích hợp NF32 ES2/ES3 và F32 ES3 mỗi bản10.000 giao dịch đạt0 mismatch; đây là smoke cho checkpoint hiện thực mới, không thay ma trận nghiệm thu cuối hoặc số đo Fmax toàn MAC. Checkpoint số học và hash nguồn cũ giữ nguyên ý nghĩa lịch sử; không sửa các báo cáo cũ để khớp nguồn mới. Mục11.16 dành cho nghiệm thu tuần14 theo kế hoạch hiện hành.
