# SPEC ĐỒ ÁN CHUYÊN NGÀNH — LÕI IP POSIT MAC XẤP XỈ VÀ LẶP

| Mục | Nội dung |
| --- | --- |
| Tên đề tài | Thiết kế và kiểm chứng lõi IP Posit MAC xấp xỉ, lặp (Approximate & Iterative Posit MAC) trên FPGA, có mở rộng ASIC |
| Sinh viên | Đan Huy |
| Tài liệu tham chiếu chính | [P] C. J. Norris, S. Kim, *An Approximate and Iterative Posit Multiplier Architecture for FPGAs*, ISCAS 2021 |
| Tài liệu liên quan | [15] Kim & Rutenbar, GLSVLSI 2019; [18] Babic et al. 2011; [23] Jaiswal & So, PACoGen, IEEE Access 2019; [4] Gustafson & Yonemoto 2017; [F] Murillo, Del Barrio & Botella, *Customized Posit Adders and Multipliers using the FloPoCo Core Generator*, FPL 2020 |
| Phiên bản | v1.5 — 2026-10-07 — Packer RTL tổ hợp/pipeline, giao diện fraction và nghiệm thu tuần8 |
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

**Nơi quy định chính:** độ trễ/ngữ nghĩa MAC ở §5.1; Zero/NaR ở §5.3; làm tròn ở §5.9; chồng lấn/backpressure ở §5.11; fused ở §5.12; phạm vi nghiệm thu ở §6. Các phần khác dẫn chiếu, không đặt thêm quy tắc khác cho cùng hành vi.

---

## 1. Mục tiêu, phạm vi, đóng góp

### 1.1 Mục tiêu

Xây dựng một lõi IP Posit MAC (`D = A × B + C`) bằng SystemVerilog tham số hóa, trong đó phép nhân là **nhân xấp xỉ dạng lặp dịch-cộng** (theo [P], kế thừa [15]) với số vòng lặp `n` chọn được lúc chạy, kèm môi trường kiểm chứng tự động bit-accurate với SoftPosit, và bộ số liệu PPA có thể tái lập so với baseline IEEE-754 FP32/FP16.

### 1.2 Phạm vi

**Trong phạm vi (In-scope)**

- Định dạng posit tham số hóa `(NB, ES)`; cấu hình chuẩn: `(8,0)`, `(16,1)`, `(32,2)`, `(32,3)`.
- Các khối: Parser, Operand Selector (OPS), Shift Amount Calculator (SAC), Shift-Based Multiplier (SBM) + bộ điều khiển lặp, Posit Adder, Rounder/Packer, MAC top.
- Ba tầng đối chiếu L0 SoftPosit, L1 mô hình thuật toán và Ideal; RTL là thiết kế được kiểm chứng (§6.1).
- Testbench tự động, coverage, hồi quy, thống kê sai số (Error Rate, MSE, max error).
- Tổng hợp/P&R Vivado theo **chính sách bậc thang thiết bị (§7.6)**: Ưu tiên UltraScale+ D0 (`xcvu9p`) hoặc D1 (miễn phí), có đường đối chiếu tỉ lệ trên 7-Series D2 (`xc7a100t`) và luồng mã nguồn mở D3/D4; so sánh công bằng với FP32/FP16 MAC.
- **Chiến lược phân kỳ hiện thực (Staged Implementation Strategy)**:
  - *Giai đoạn 1 (Baseline - Hoàn thành trước Gate 3)*: Hoàn thiện lõi MAC **đơn lẻ cô lập**; exact/RNE khớp L0, approx khớp L1. Bắt tay, giữ đầu ra khi bị chặn và xử lý Zero/NaR đúng là bắt buộc từ giai đoạn này.
  - *Giai đoạn 2 (Advanced Optimization - Tích hợp sau Gate 3)*: Kích hoạt các kỹ thuật tối ưu hóa nâng cao gồm: chồng lấn giao dịch (Pipelined Interleaving $\text{II} \approx n$), mạch ngắt sớm và Bypass Zero/NaR (Order FIFO), Output Skid Buffer, và quản lý năng lượng qua Clock Enable (CE).

**Ngoài phạm vi (Out-of-scope)**

- Chia, căn bậc hai, chuyển đổi FP↔posit bằng phần cứng (chỉ làm trong phần mềm để sinh vector).
- Quire đầy đủ (accumulator 512-bit cho posit32). Chỉ đề cập như hướng phát triển.
- Chip tape-out thật. (Phần ASIC chỉ dừng ở luồng RTL-to-GDSII mô phỏng bằng công cụ mã nguồn mở, xem EXT-A.)

### 1.3 Đóng góp dự kiến

| ID | Đóng góp | Ghi chú |
| --- | --- | --- |
| C1 | Lõi **MAC** (thêm adder, làm tròn, đóng gói) trên nền multiplier của [P] vốn chỉ có phép nhân | Paper không có adder; đây là phần mới |
| C2 | Golden model 3 tầng và phương pháp kiểm chứng phân tầng theo độ dài regime | Vá điểm yếu "random đều" |
| C3 | Tái hiện có kiểm soát Table I/II/III của [P], kèm ghi nhận sai khác | Giá trị khoa học của một đồ án |
| C4 | So sánh PPA với FP32/FP16 dưới cùng điều kiện, có phân tích throughput/LUT trung thực | Xem §7.4 |
| C5 (chọn) | Luồng ASIC (EXT-A) hoặc khảo sát không gian thiết kế (EXT-B) | Xem §8 |

### 1.4 Tiêu chí nghiệm thu (Acceptance Criteria)

| ID | Tiêu chí | Ngưỡng đo được |
| --- | --- | --- |
| AC-01 | RTL khớp L1 bit-exact | **0 mismatch** trên ≥ 10^7 vector cho mỗi điểm approx bắt buộc của §6.7, gồm từng OPS, n, ROUND_MODE và ROUND_SCHEME đã chọn; exact theo AC-02. Các hàng MAY/EXT chỉ áp dụng khi triển khai |
| AC-02 | Chế độ exact (EXACT_EN=1, cfg_mode=0, RNE) khớp SoftPosit bit-exact | posit8: exhaustive mul (2^16 cặp), add (2^16 cặp), MAC (2^24 bộ ba); posit16: exhaustive mul và add (2^32 cặp); posit32: ≥ 10^8 vector ngẫu nhiên phân tầng + toàn bộ corner list. **0 mismatch** |
| AC-03 | Tái hiện Table I của [P] | Sai lệch mỗi ô ≤ 1.0 điểm phần trăm, N ≥ 10^7 vector/ô (xem Phụ lục B) |
| AC-04 | Bao phủ | Line ≥ 95%, branch ≥ 90%, toggle ≥ 85%; functional coverage 100% các bin hợp lệ của §6.6. Bin không thể đạt do cấu hình phải có giải thích và loại trừ được truy vết |
| AC-05 | Tổng hợp | Báo cáo LUT/FF/CARRY/DSP/BRAM, WNS, fmax post-route cho ≥ 3 cấu hình; DSP = 0, BRAM = 0. Nền tảng theo chính sách bậc thang §7.6 (có phương án khi không có `xcvu9p`) |
| AC-06 | So sánh PPA | Bảng PPA Posit MAC vs FP32 MAC vs FP16 MAC cùng device, cùng ràng buộc (§7) |
| AC-07 | Tái lập | Lệnh `make all` từ repo sạch tạo lại toàn bộ bảng số liệu, không can thiệp tay |
| AC-08 | Truy vết | Ma trận FR → TC → kết quả đầy đủ (Phụ lục D) |

### 1.5 Mức độ hoàn thành

| Mức | Nội dung |
| --- | --- |
| Tier 1 (đạt) | Parser/Packer đúng, multiplier lặp đúng với L1, adder đúng, AC-01 với posit32, AC-05 |
| Tier 2 (giỏi) | Toàn bộ AC-01..AC-08, MAC v1 (làm tròn trong miền unpacked), phân tích Err/MSE theo regime |
| Tier 3 (xuất sắc) | Tier 2 và ít nhất một mở rộng hoàn chỉnh: EXT-A, EXT-B, EXT-C hoặc MAC fused FR-11; ghi rõ mở rộng được chọn |

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
| FR-10 | MUST | MAC non-fused: `D = round(round(A×B) + C)`; chế độ exact khớp `p<N>_add(p<N>_mul(a,b), c)` |
| FR-11 | MAY | MAC fused v2: làm tròn một lần ở đầu ra (§5.12). Approx cửa sổ hữu hạn phải khớp L1; so L0 chỉ đánh giá sai số. Exact fused posit8/16 chỉ được tuyên bố khi giữ đủ tích và phần căn chỉnh để khớp `p<N>_mulAdd`; không suy ra exact từ `ACC_WIN` mặc định |
| FR-12 | SHOULD | `acc_mode=1` dùng trạng thái tích lũy làm C, bỏ qua c bên ngoài; làm tròn sau từng bước, duy trì `acc_nar_q`. Thứ tự cập nhật và ngữ nghĩa `acc_clr` theo §4.2 |
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

Ngưỡng NFR là đề xuất khởi điểm; chốt với GVHD sau tổng hợp đầu tiên (tuần 10). Ngưỡng tuyệt đối NFR-02..04 chỉ đối chiếu ở D0; NFR-02/03 có mốc tỉ lệ §7.6 cho nền tảng khác. NFR-04 chưa có baseline MAC tương đương để quy đổi, nên báo số đo và chốt mục tiêu riêng theo part đã chọn.

---

## 4. Tham số và giao diện

### 4.1 Tham số SystemVerilog

| Tham số | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `NB` | 32 | Độ rộng tổng thể của số Posit (bitwidth) |
| `ES` | 2 | Số bit exponent tối đa (exponent size) |
| `FRAC_MAX` | tính | Số bit fraction tối đa `= NB - 3 - ES` (27 cho posit32 ES=2, 26 cho ES=3, 12 cho posit16, 5 cho posit8) |
| `FRAC_W` | 12 | Độ rộng toán tử fraction trong SBM ở chế độ xấp xỉ (theo [P] §III-B) |
| `EXACT_EN` | 1 | Bật khả năng chạy exact; chế độ từng giao dịch do `cfg_mode` chọn. Exact: `ACC_W = 2×FRAC_MAX + 2`. Approx vẫn dùng độ rộng/chính sách §5.6 dù `EXACT_EN=1` |
| `N_MAX` | 8 | Giá trị lớn nhất của `cfg_n` (quyết định độ rộng bộ đếm lặp) |
| `OPS_EN` | 1 | Bật khối chọn toán hạng (Operand Selector) |
| `FUSED` | 0 | 0: MAC v1 (làm tròn 2 lần, non-fused). 1: MAC v2 (làm tròn 1 lần, C gộp vào accumulator, fused) |
| `ACC_WIN` | `FRAC_MAX + 6` | Cửa sổ số học v2 approx: 1 bit dấu + 3 bit nguyên + `FRAC_MAX` bit phân số + 2 bit G/R; sticky là cờ riêng, không cộng như bit số học. Với ES=2: 33 bit, miền mantissa có dấu $[-8,8)$; với ES=3: 32 bit. Không dùng cửa sổ này làm bảo đảm exact fused |
| `ROUND_MODE` | `"RNE"` | Quy ước làm tròn tại Packer/round_unpacked: `"RNE"` theo FloPoCo/SoftPosit; `"TRUNC"` cắt cụt theo [P] |
| `ROUND_SCHEME` | 0 | Cơ chế xử lý bit khi dịch phải trong bộ nhân lặp SBM theo [15]: `0: FLOOR` (cắt bỏ hoàn toàn bit rơi ra ngoài); `1: STICKY_ACC` (gom bit rơi vào cờ `sticky_acc`) |
| `PIPE_PARSE` | 2 | Số tầng pipeline của parser. Mặc định 2 khớp Fig. 5(a), có hai hạng thanh ghi: sau mux LOD/LZD và sau bộ dịch |
| `PIPE_PACK` | 1 nếu ROUND_MODE="TRUNC", 2 nếu "RNE" | Baseline TRUNC một hạng; RNE hai hạng elastic: P1 mã hóa/dịch/G-R-S, P2 làm tròn/carry/dấu theo §5.9-D. Timing cần xác nhận STA |
| `SF_W` | tính | Độ rộng Scale Factor theo §2.3: `$clog2(4×SF_MAX + 4) + 1` |

Ràng buộc IP: `NB >= 4`, `0 <= ES <= NB-4`, `1 <= FRAC_W <= FRAC_MAX`, `N_MAX >= 1`; điểm quét không thỏa phải loại và ghi lý do. RTL parser hiện giới hạn `NB<=32`; phạm vi đã nghiệm thu theo §5.2. `cfg_mode=0` chỉ hợp lệ khi `EXACT_EN=1`; `cfg_n` hợp lệ trong `[0,N_MAX]` (0 chỉ giữ đóng góp hidden bit). Bộ đếm exact phải biểu diễn đến `FRAC_MAX` dù `N_MAX` nhỏ hơn. `OPS_EN=0` buộc X=A; `cfg_ops=2,3` chưa hỗ trợ phải bị chặn trong testbench. Các biến thể TRUNC không thuộc nghiệm thu exact↔SoftPosit RNE. `PIPE_PARSE/PIPE_PACK` mô tả cấu hình kiến trúc mục tiêu; parser RTL hiện cố định hai tầng, chưa có lựa chọn số tầng tùy ý.

**Phân biệt rõ ràng giữa hai tham số làm tròn (`ROUND_SCHEME` vs. `ROUND_MODE`)**:

- **`ROUND_SCHEME` (Nội bộ bên trong bộ nhân lặp SBM, §5.6)**: Quy định cách xử lý phần đuôi mantissa $1.f_Y$ khi bị dịch phải $S$ bit ở từng chu kỳ lặp. Nếu `ROUND_SCHEME = 0` (theo [P]), các bit bị dịch trôi ra khỏi độ rộng `FRAC_W` bị cắt bỏ thẳng (`floor`); nếu `ROUND_SCHEME = 1` (theo [15]), các bit này được dồn OR logic vào thanh ghi `sticky_acc` để bảo toàn thông tin phần dư, chống trôi sai số qua nhiều vòng lặp.
- **`ROUND_MODE` (Khâu đóng gói cuối cùng Packer & `round_unpacked`, §5.9)**: Quy định thuật toán làm tròn kết quả số học hoàn chỉnh sang chuỗi bit Posit chuẩn. Nếu `ROUND_MODE = "RNE"` (mặc định), áp dụng thuật toán Round-to-Nearest-Even phỏng theo [F], được kiểm chứng với SoftPosit; nếu `ROUND_MODE = "TRUNC"`, cắt cụt trực tiếp để tái hiện số liệu diện tích và bảng Table I/II/III của paper [P].

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
| `cfg_n` | in | `$clog2(N_MAX+1)` | Số vòng lặp tối đa (chỉ dùng khi `cfg_mode=1`) |
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
- Top hiện là MAC; multiplier standalone là module/harness riêng. Trong MAC, đặt C=0 không thay thế hoàn toàn giao diện multiplier vì NaR và cờ vẫn xử lý theo ngữ cảnh giao dịch.

**Reset bridge của RTL tích hợp (standalone multiplier đã triển khai; MAC còn theo kế hoạch):** rst_n ở top chỉ được lấy mẫu tại cạnh clk. Một thanh ghi reset bridge nhận 0 khi rst_n=0 và 1 khi rst_n=1; ngõ ra thanh ghi này cấp cùng nguồn reset_n cho các leaf có assert bất đồng bộ/deassert đồng bộ. Không nối trực tiếp rst_n đồng bộ vào chân reset bất đồng bộ của leaf. Khi top lấy mẫu reset=0, top flush valid, pending, credit, metadata và accumulator; leaf được assert sau cạnh đó. Không có handshake hợp lệ tại cạnh reset.

Sau nhả reset, startup barrier giữ in_ready=out_valid=0 cho đến khi tất cả leaf đã nhả reset; phải tính cả cạnh bridge nhả và hai FF của leaf, không mặc định toàn MAC chỉ chờ hai cạnh như parser đơn vị. Barrier dùng các trạng thái init_done hoặc bộ đếm startup bảo thủ phù hợp số tầng reset của mọi leaf; điều kiện và số cạnh thực tế phải được TB kiểm trước Gate3. A/B/C chỉ nhận đồng thời khi cả ba parser sẵn sàng và top có slot: top_in_ready=run_ready && slot_free && ready_A && ready_B && ready_C; valid vào mỗi parser chỉ phát cùng một handshake top. Reset lúc rỗng/đang tính/đang stall phải hủy giao dịch cũ và không được xuất lại kết quả trước reset.

---

## 5. Vi kiến trúc

### 5.1 Tổng quan luồng dữ liệu (dạng bảng)

| Tầng | Khối | Vai trò | Chu kỳ mục tiêu |
| --- | --- | --- | --- |
| P | `posit_parser` × 3 (A, B, C) | Bù hai theo dấu, LOD/LZD, dịch, tách `(s, sf, frac)` (`PIPE_PARSE = 2`) | 2 |
| M0 | `ops_sel` | Chọn X (điều khiển vòng lặp) và Y (bị dịch); cộng `sf`, xor dấu | 1 |
| M1..Mq+2 | `sac` + `sbm` + `iter_ctrl` | Ba tầng SAC → Shifter → Accumulator, token khởi tạo khi n=0; q=max(1,n) | q+2 |
| MN/R | `mul_norm` + `round_unpacked` | Chuẩn hóa tích, làm tròn unpacked (MAC v1) | 1 |
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
| MAC v1 | core → norm/round_unpacked → add → pack | q+10 | q+11 |
| MAC v2 (MAY) | core có vòng hidden bit → abs_norm → pack | n+8, chưa chốt lịch | n+9, chưa chốt lịch |

Multiplier gộp chuẩn hóa vào cuối core/packer; v1 thêm một tầng norm/round riêng. Ví dụ MAC v1 RNE, n=2: H=13, L_valid=12 và L_handshake=13 theo lịch không bubble. Đây là mục tiêu kiểm TB, chưa là nghiệm thu. V2 có n+1 số hạng và hai chu kỳ xả Shifter/Accumulator; ABS/LZC, bubble và hồi tiếp phải được lịch hóa riêng trước khi dùng ngân sách này.

**Ngữ nghĩa:** v0/v1 đều làm tròn tích trước khi cộng; v1 thay pack/parse trung gian bằng round_unpacked tương đương (§5.9-C). V2 làm tròn một lần nhưng cửa sổ approx vẫn có sai số cắt/căn chỉnh (§5.12). Chỉ đường exact/RNE đáp ứng các điều kiện độ rộng mới được yêu cầu khớp SoftPosit. Độ trễ bypass được quy định ở §5.3.

### 5.2 Parser (`posit_parser`)

Ngõ vào `p[NB-1:0]`; ngõ ra `s`, `is_zero`, `is_nar`, `sf[SF_W-1:0]`, `frac[FRAC_MAX-1:0]` (căn MSB, không chứa hidden bit).

**Hợp đồng parser tổ hợp chốt ngày 05/10/2026:** `rtl/posit_parser_comb.sv` không có clock/reset/handshake; đầu ra có hiệu lực sau khi logic tổ hợp ổn định với đầu vào nhị phân đã biết. `s=p[NB-1]`; `sf` là vector **signed**, rộng theo §2.3; `FRAC_MAX=NB-3-ES` và fraction thiếu bit đệm 0 phía LSB. Zero trả `(s,is_zero,is_nar,sf,frac)=(0,1,0,0,0)`; NaR trả `(1,0,1,0,0)`. Đầu ra giữ toàn bộ fraction, chưa cắt về `FRAC_W`; hidden bit được khôi phục ở khối số học khi toán hạng hữu hạn khác 0. Đối chiếu L1 bằng `frac_RTL=(frac_L1 >> (63-FRAC_MAX)) & ((1ULL<<FRAC_MAX)-1)`.

Phạm vi module hiện tại: `4<=NB<=32`, `0<=ES<=NB-4` để có ít nhất một bit fraction, phù hợp ràng buộc `FRAC_W>=1` của IP. Không hỗ trợ ghi đè `FRAC_MAX` khác công thức; `SF_W` phải đủ chứa `Rgm` ghép exponent. Biểu thức tính độ rộng dùng hằng 64-bit để tránh tràn tại elaboration. Phạm vi nghiệm thu hiện tại là `(NB,ES)=(8,0),(16,1),(32,2),(32,3)`; các cấu hình khác cần kiểm thêm trước khi dùng. `PIPE_PARSE=2` là số hạng của parser pipeline hiện tại, không phải latency của module tổ hợp.

**Hợp đồng pipeline `rtl/posit_parser.sv`:** hai tầng elastic, hai slot lưu giao dịch. P1 chốt dấu, cờ, `cnt`, bit regime đầu `r` và payload seed sau chọn regime; P2 tạo `Rgm=k` từ `cnt/r` song song với dịch payload, tách exponent/fraction, ghép scale factor rồi chốt đầu ra. Không cần chốt thêm vector `k` trong P1, theo Fig.5(a). Với NB32, phần trạng thái regime giảm từ `cnt5+k6=11` bit xuống `cnt5+r1=6` bit trong RTL. Chỉ nhận dữ liệu khi `in_valid && in_ready`; nguồn giữ `p` và `in_valid` trong lúc bị chặn. Khi `out_valid && !out_ready`, toàn bộ dấu/cờ/sf/fraction và `out_valid` giữ nguyên. Hai tầng có enable độc lập; có thể nhận và trả một giao dịch đồng thời, luôn theo thứ tự. Dữ liệu khi `out_valid=0` không mang ý nghĩa giao dịch, nhưng vẫn là giá trị xác định sau reset.

Parser dùng cổng reset cục bộ `reset_n` theo Digital Design Guidelines: assert bất đồng bộ, deassert qua hai flip-flop trên `clk`; `in_ready=out_valid=0` trong reset/startup. Reset xóa toàn bộ dữ liệu/cờ và hủy các giao dịch còn trong hai slot. Khi tích hợp, dùng reset bridge và startup barrier §4.2; không thay reset leaf đã kiểm chứng. Chờ hai cạnh từ lúc reset_n cục bộ nhả để synchronizer nhả reset không tính vào latency dữ liệu. Mọi bank dữ liệu đều dùng cùng reset đã đồng bộ, không chia cờ và datapath sang các miền reset khác nhau.

**Quy ước đếm chu kỳ:** gọi cạnh nhận đầu vào là E0. P1 chốt tại E0, P2 chốt và `out_valid` lên sau E1; handshake đầu ra sớm nhất tại E2. Vì vậy có hai hạng thanh ghi, khoảng cách input/output handshake không stall là hai chu kỳ, còn từ cạnh nhận đầu vào đến cạnh bắt đầu valid là một chu kỳ. `II=1` khi không stall. Quy ước này làm rõ mục tiêu hai tầng ở §5.1; không cộng một tầng chỉ để làm số chu kỳ từ E0 đến valid bằng 2. Khi ghép MAC phải dùng lịch cạnh thực tế thay vì cộng latency theo hai quy ước khác nhau.

Thuật toán Parser (theo Fig. 5a của [P], tối ưu bỏ bước cộng +1 trong lượng dịch):

1. `s = p[NB-1]`; `t1 = s ? (~p + 1) : p` (XOR + bộ cộng bù hai, như [P] Fig. 5a).
   - **Nhận diện 2 giá trị đặc biệt**:
     - Số 0: `is_zero = (p == {NB{1'b0}})`
     - NaR (Not-a-Real): `is_nar = (p[NB-1] == 1'b1) && (p[NB-2:0] == {(NB-1){1'b0}})`
2. `r = t1[NB-2]`                               // bit regime đầu
3. `cnt = ` số bit liên tiếp giống `r` trong `t1[NB-3:0]`   // LOD nếu r=0, LZD nếu r=1,
                                                      // cả hai chạy song song, mux theo r
                                                      // cnt ∈ [0, NB-2], rộng $clog2(NB-1) bit
                                                      // nếu cả chuỗi giống nhau (không có bit kết thúc): cnt = NB-2
                                                      // vld=0 của detector được chọn: thay K=0 bằng cnt=NB-2
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

Các mã Zero/NaR theo §2.1. Đặt C_eff bằng c khi acc_mode=0, bằng trạng thái tích lũy khi acc_mode=1; acc_clr của giao dịch làm C_eff=0 (§4.2). NaR có ưu tiên cao nhất.

| Điều kiện | Kết quả/hành vi |
| --- | --- |
| A hoặc B hoặc C_eff là NaR | d=NaR; flags=10000; không chạy nhân/cộng |
| A=0 hoặc B=0, không có NaR | Multiplier: d=0. MAC: d=C_eff |
| C_eff=0, tích khác 0 | MAC v1 bỏ Adder, nhưng tích unpacked phải qua Packer |
| Hai số hạng triệt tiêu chính xác | d=0; không coi đây là underflow |

Đúng các kết quả trên là MUST ngay ở baseline. Bypass rút ngắn thời gian là SHOULD sau Gate 3. Mục tiêu Zero/NaR khi pipeline rỗng và kết quả dùng trực tiếp bank parser: H=2, L_valid=1, L_handshake=2; thêm thanh ghi đầu ra riêng thì cộng thêm một hạng. Với v1 và C_eff=0, bỏ ba hạng Adder: H=q+7 (TRUNC), q+8 (RNE), q=max(1,n). Đây là ngân sách của đường bypass chưa triển khai, không phải latency đã kiểm chứng. Không áp cho v0/v2 nếu cấu trúc khác.

Khi chồng lấn, kết quả bypass phải chờ thứ tự giao dịch trong Order/Metadata FIFO; out_ready=0 vẫn phải giữ đầu ra ổn định. CE có thể ngừng cập nhật các khối không tham gia, nhưng không được ngừng các khối còn xử lý giao dịch trước.

### 5.4 OPS (`ops_sel`)

- `cfg_ops=0`: X = A, Y = B.
- `cfg_ops=1`: X là toán hạng có popcount fraction ít hơn, hòa chọn A; đếm trên fraction thực tế dùng trong chế độ hiện tại (FRAC_W với approx, FRAC_MAX với exact). Giảm vòng lặp không tự bảo đảm cùng sai số ở một n cho mọi đầu vào.
- `cfg_ops=2..3`: dành cho các chính sách khác lấy từ [15] (rounding scheme, operand selection); nếu chưa cài thì để cấm (assert).

Ngoài ra OPS thực hiện: `sign_o = sA ^ sB`; `sf_o = sfA + sfB`.

**Giao diện tổ hợp tuần9:** `ops_sel_comb` nhận fraction parser không hidden, rộng FRAC_MAX; ở approx lấy FRAC_W bit cao trước popcount. `x_frac` được căn phải, không hidden; `y_mant` căn phải trên Q(W_X), hidden nằm ở bit W_X. `active_width=W_X`. Input bị bỏ bit thấp đặt `input_cut`, không đưa cờ này vào sticky số học. `cfg_error` báo cfg_ops reserved, exact khi EXACT_EN=0 hoặc cfg_ops khác0 khi OPS_EN=0; bundle dữ liệu về0 và wrapper/TB phải từ chối cấu hình này. Khi OPS_EN=0, cấu hình hợp lệ cfg_ops=0 luôn giữ X=A, đồng nhất API L1. Zero/NaR được wrapper xử lý trước đường finite này.

### 5.5 SAC (`sac`) và bộ điều khiển lặp

Trạng thái: thanh ghi fx chứa fraction X sau hidden bit, rộng W_X=FRAC_W ở approx và FRAC_MAX ở exact; tổng dịch S và bộ đếm i phải đủ cho W_X. Không dùng thanh ghi FRAC_W để cắt đường exact.

Mỗi chu kỳ, nếu `fx ≠ 0` và `i < n_lim`:

```
sa    = clz(fx) + 1        // vị trí bit 1 đầu tiên sau dấu chấm (1-indexed)
S     = S + sa             // tổng dịch lũy kế
fx    = fx << sa           // loại bit 1 vừa xử lý cùng các bit 0 đứng trước
i     = i + 1
```

`n_lim = cfg_mode ? cfg_n : FRAC_MAX`. Kết thúc khi `fx == 0` (dừng sớm, chính xác) hoặc `i == n_lim` (cắt xấp xỉ, đặt cờ `approx_cut` nếu `fx ≠ 0`).

Số vòng lặp thực tế = `min(popcount(fx_ban_dau), n_lim)`, tức số bit 1 của fraction X **không tính hidden bit**. Hết bit X chỉ chứng minh không còn số hạng fraction; approx vẫn có thể sai do cắt Y/số hạng.

**Profile RTL baseline đã chốt:** v0/v1 dùng hợp đồng L1 normative tại §5.4–§5.6: cfg_ops=0/1, hidden bit khởi tạo riêng, cfg_n chỉ đếm số hạng fraction, width/cut theo §5.6. `paper_source_config` và predictor n=2/7-bit là profile nghiên cứu riêng; chưa thay mặc định RTL. Với cùng chuỗi khai triển, `n_terms=n_fraction+1` chỉ là ánh xạ bộ đếm; không bảo đảm cùng kết quả giữa thuật toán RND/complement và thuật toán normative. Test Table I phải ghi đúng tên profile, không dùng source Table I để nghiệm thu cfg_ops normative.

**Lịch core baseline không chồng lấn — đã triển khai và kiểm đơn vị 09/10/2026:** L0 là cạnh OPS chốt X/Y/config và phát launch. Core không stall sau launch; top dự trữ một slot kết quả và chưa nhận giao dịch khác đến khi giao dịch hiện tại đã trả đầu ra. Token có valid/first/last/init_only; metadata giữ trong thanh ghi giao dịch.

| n thực tế | SAC | Shifter | Accumulator / core_done |
| --- | --- | --- | --- |
| 0 (cfg_n=0 hoặc fx=0) | L1 phát token init_only, first=last=1 | L2 truyền token | L3 nạp Y đúng một lần, không cộng thêm Y; done sau L3 |
| 1 | L1 phát số hạng fraction thứ nhất, first=last=1 | L2 dịch Y theo S1 | L3 chốt Y+(Y>>S1); done sau L3 |
| 2 | L1/L2 phát hai token, first ở L1, last ở L2 | L2/L3 dịch | L3 chốt Y+term1, L4 chốt acc+term2; done sau L4 |
| n>=1 | L1..Ln phát mỗi cạnh một token | L2..L(n+1) | L3..L(n+2); done chỉ sau token last được chốt |

SAC xác định last từ fx kế tiếp bằng 0 hoặc đạt n_lim, không chờ thêm một chu kỳ FSM. Dừng sớm ngừng phát token mới nhưng vẫn xả hai tầng; done không được phát ngay tại SAC. Cắt n đặt approx_cut nếu fraction còn bit 1; n=0 dùng cùng quy tắc. Đây là lịch yêu cầu cho RTL/TB, không phải kết quả mô phỏng core. Chồng lấn, credit và II tối ưu chỉ bổ sung sau baseline.

- **Xử lý đặc thù ở MAC v2 (Fused MAC, `FUSED=1`)**:
   - Tại vòng 0, SAC phát số hạng tương ứng với hidden bit của $X$ ($1.0 \times Y$) với độ dịch nội tại $sa = 0$, sau đó quét fraction ở các vòng i=1..n. n_lim vẫn chỉ đếm fraction. Quy ước đếm này không tự chứng minh tái hiện Table I của [P]; fused và profile paper phải kiểm riêng.
  - Bổ sung đầu ra `shift_extra = max(0, -ΔSF)` (với $\Delta SF = sf_P - sf_C$) để cộng trực tiếp vào tổng lượng dịch $S$ ($S' = S + \text{shift\_extra}$) nhằm căn chỉnh độ lớn các số hạng của tích khi $C$ đóng vai trò làm mốc scale factor (xem chi tiết tại §5.12).
  - V2 giữ vòng hidden bit riêng; các thay đổi ghép số hạng cần đo timing và cập nhật lịch trước khi áp dụng.

> **Phân tầng:** mô tả vòng lặp là mô hình hành vi. Lịch baseline v0/v1 chọn SAC → Shifter → Accumulator, từ launch L0 đến core_done sau L(q+2), q=max(1,n). V2 và chồng lấn cần lịch riêng; không suy ra đã hỗ trợ chồng lấn chỉ từ Fig.3.

#### 5.5-A. Hợp đồng triển khai tuần9 — 08/10/2026

Đây là giao diện triển khai profile normative, không chọn paper RND/complement làm mặc định. Giao diện thanh ghi/token bên dưới đã chốt và đã có RTL đến multiplier standalone; nghiệm thu Gate2 còn processing. Nghiệm thu từng mốc và thứ tự tại PLAN L1 mục7.

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

**Reset và debug:** các module tuần9 có FF dùng reset_n assert bất đồng bộ/deassert qua hai FF tại từng block, expose trạng thái sẵn sàng để startup barrier phối hợp. Reset hủy context/token/result; dùng CK2Q header chung, enable theo bundle và không gate clock bằng LUT. Trace gồm fx trước/sau, sa/S, token, term/tail và acc sau commit. Top tích hợp chỉ ghép instance; logic nhận cặp parser/retire/reset đặt trong wrapper điều khiển. Core đã kiểm lịch done/reset/context 09/10; multiplier standalone đã kiểm pilot handshake. Không suy thành Gate2 hoặc RTL MAC.

### 5.6 SBM (`sbm`)

- **Khởi tạo và tích lũy trong MAC v0/v1 (Non-fused)**:
  - Khởi tạo: `acc = Y_mant` (1.f của Y, đóng góp của hidden bit của X), `sticky_acc = 1'b0`. Mỗi vòng: `acc = acc + (Y_mant >> S)`.
  - **Đường approx (`cfg_mode=1`, độc lập giá trị `EXACT_EN`)**:
    - `acc` chính có độ rộng `ACC_W = FRAC_W + 4` bit (2 bit nguyên cho tích trong $[1.0, 4.0)$, `FRAC_W` bit phân số, và 2 bit phụ Guard/Round). Với `FRAC_W = 12`, `ACC_W = 16` bit.
    - `ROUND_SCHEME=0`: cắt số hạng về FRAC_W bit phân số tại mỗi phép dịch, hai vị trí G/R trong thanh ghi bằng 0; đây là profile tái hiện Fig. 4. `ROUND_SCHEME=1`: giữ thêm G/R, gom phần thấp hơn vào cờ sticky_acc riêng. L1/RTL phải dùng cùng điểm cắt.
    - OR các đuôi bị mất chỉ là chính sách xấp xỉ, không tái tạo tổng phần dư hay carry của chúng. RNE cuối làm tròn giá trị nội bộ đã xấp xỉ; không có bảo đảm khớp tích exact chỉ vì đã có sticky.
  - **Đường exact (`cfg_mode=0`, yêu cầu `EXACT_EN=1`)**: giữ FRAC_MAX bit fraction của cả X/Y; `acc` gồm 2 bit nguyên và 2×FRAC_MAX bit phân số. Không giới hạn vòng exact bằng N_MAX và không mất bit tích trước Packer/RNE.

- **Đặc tả Accumulator có dấu trong MAC v2 (Fused MAC, `FUSED=1`)**:
  - Accumulator bù hai theo §4.1. Với (32,2): sign [32], ba bit nguyên [31:29], 27 bit phân số [28:2], G/R [1:0]; sticky là cờ riêng. Ba bit nguyên cần vì mantissa tích <4 và C căn chỉnh <2 có thể cộng thành giá trị gần 6.
  - Mux `first` nạp toán hạng $C'$ (đã căn chỉnh theo $\Delta SF$) thay cho $Y$. Số hạng $1.0 \times Y$ từ hidden bit của $X$ trở thành một số hạng riêng tại vòng 0.
  - Mỗi số hạng được cộng/trừ tích lũy tùy theo bit dấu của tích $s_P = s_A \oplus s_B$:
    $$\text{acc} \Leftarrow s_P \ ? \ (\text{acc} - (Y \gg S')) : (\text{acc} + (Y \gg S'))$$
    với lượng dịch tổng cộng $S' = S + \text{shift\_extra}$.
  - Thanh ghi `sticky`: Thu gom OR logic của mọi bit bị trôi ra khỏi cửa sổ `ACC_WIN` khi thực hiện dịch $Y \gg S'$. Nếu $S' > \text{FRAC\_MAX} + 2$, toàn bộ số hạng tích trôi ra ngoài cửa sổ và chỉ đóng góp vào bit `sticky`. (Xem chi tiết quy tắc trừ có mượn sticky tại §5.12-c).

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

### 5.7 Chuẩn hóa tích (`mul_norm`)

`acc ∈ [1, 4)`. Nếu `acc ≥ 2`, dịch phải 1 (giữ bit rơi vào sticky) và tăng sf=sfA+sfB thêm đúng 1. Không cộng lại sf lần thứ hai. Sau chuẩn hóa chuyển sang round_unpacked hoặc Packer.

**Ánh xạ lưới để khớp L1:** q=2*FRAC_MAX ở exact, q=FRAC_W ở FLOOR và q=FRAC_W+2 ở STICKY_ACC. Với FLOOR lưu vật lý thêm hai bit0 theo §5.6, phải bỏ hai bit padding trước normalize trên lưới q=FRAC_W; bit rơi lúc normalize gom vào sticky. Không giữ bit đó thành guard số học mới, vì sẽ đổi kết quả so `mul_norm.hpp`. Sau normalize, bỏ hidden, căn fraction vào F_IN=2*FRAC_MAX+1 bit của packer (§5.9-D), đệm0 và giữ sticky riêng; adapter không làm tròn. `input_cut`, `approx_cut` và numerical_tail tham gia inexact cuối nhưng không tự OR vào sticky RNE; sticky số học tuân theo ROUND_SCHEME và normalize.

### 5.8 Adder (`posit_add`)

Ngõ vào hai bộ ba unpacked `(s, sf, m)` với `m = 1.f` rộng `W = FRAC_MAX + 1`; ngõ ra bộ ba unpacked chưa làm tròn kèm các bit cờ `guard, round, sticky` (G, R, S).

**Đặc tả chi tiết và giới hạn Alignment Shifter**:

- Chọn số hạng có độ lớn lớn hơn theo (sf,m); đặt $d=sf_L-sf_S\ge0$, dấu kết quả theo số hạng lớn khi trừ. Alignment phải giữ G/R và phần dư; khi trừ không được xử lý phần dư như một số hạng cộng dương.
- **Cơ chế Kẹp Cứng (Clamping)**: Do dải scale factor $sf$ rất rộng ($[-240, 240]$ với posit32), nếu thiết kế bộ dịch theo toàn bộ dải $sf$ sẽ tiêu tốn tài nguyên LUTs khổng lồ và làm giảm nghiêm trọng $f_{max}$. Nhận xét rằng nếu $d > \text{FRAC\_MAX} + 2$, toàn bộ mantissa $m_2$ sẽ bị dịch trôi hoàn toàn ra ngoài vùng bit có nghĩa (ngoài cả bit Guard và Round). Khi đó:
  - Mạch kích hoạt cơ chế kẹp cứng: $d_{clamp} = \min(d, \text{FRAC\_MAX} + 2)$.
  - Nếu $d > \text{FRAC\_MAX} + 2$, toàn bộ $m_2$ được bypass/dồn thẳng vào bit Sticky: $S = |m_2| \ne 0$.
  - Nhờ vậy, bộ Alignment Barrel Shifter chỉ cần độ rộng dịch tối đa là $\text{FRAC\_MAX} + 2$ vị trí (ví dụ: với posit32, $\text{FRAC\_MAX}=27$, shifter chỉ cần 5 bit điều khiển cho tối đa 29 vị trí dịch).

### 5.9 Packer (`posit_pack`)

#### A. Thuật toán đóng gói RNE, phỏng theo Algorithm 2 của [F]

Khối đóng gói chuyển `(sign,sf,frac)` thành Posit NB bit. Pseudocode dưới đây là bản diễn giải của đề tài từ Algorithm 2 của [F], bổ sung tiền kẹp và ràng buộc biên; không phải nguyên văn hay mã RTL hoàn chỉnh. `normf` là phần fraction sau hidden bit; nếu đầu vào mang mantissa 1.f thì bỏ hidden bit khi ghép inshift.

```
Require: sign, sf (scale factor), normf (mantissa đã chuẩn hóa), inf (is_nar), z (is_zero)
Ensure : R in Posit<NB, ES> đã làm tròn RNE đúng quy chuẩn

0. Xử lý các ngoại lệ đặc biệt trước:
   - Nếu inf == 1 (NaR): R = {1'b1, {(NB-1){1'b0}}}, thoát.
   - Nếu z == 1 (Zero):  R = {NB{1'b0}}, thoát.

1. Tiền kẹp Scale Factor (sf pre-clamping):
   - Đặt SF_MAX = (NB - 2) << ES  (ví dụ: posit32 ES=2 có SF_MAX = 120; ES=3 có SF_MAX = 240)
   - Nếu sf >= SF_MAX:
       mag = {(NB-1){1'b1}}       // Trị tuyệt đối bão hòa về maxpos (0x7FFF_FFFF với NB=32)
       R = sign ? (-mag) : mag
       thoát.
    - Nếu sf < -SF_MAX:
       mag = {{(NB-2){1'b0}}, 1'b1} // Bão hòa về minpos (0x0000_0001 với NB=32)
       R = sign ? (-mag) : mag
       thoát.

2. Tách scale factor sf thành:
   - expF = sf[ES - 1 : 0]
   - regF = sf[SF_W - 1 : ES]
   - rc   = sf[SF_W - 1]          // bit dấu của regime (0: dương k >= 0, 1: âm k < 0)
3. Nếu rc == 1:
     regF = -regF                 // Lấy giá trị tuyệt đối của regime
4. Ghép vector trước khi dịch (inshift) và xác định lượng dịch (offset):
   - Nếu rc == 1:
       inshift = {1'b0, 1'b1, expF, normf}
       offset  = regF - 1
   - Ngược lại (rc == 0):
       inshift = {1'b1, 1'b0, expF, normf}
       offset  = regF
5. Thực hiện dịch phải arithmetic/logic:
   - ansshf = shift_right_fill(inshift, offset, fill_bit = NOT rc)
     // Hàm khái niệm: đệm đủ bit, thu mọi bit mất vào sticky; không phải cú pháp >>> của SV
6. Trích xuất các trường bit và bộ cờ RNE:
   - anstmp = ansshf[MSB - 1 : MSB - (NB - 1)]
   - LSB    = ansshf[MSB - (NB - 1)]
   - G      = ansshf[MSB - NB]
   - R      = ansshf[MSB - (NB + 1)]
   - S      = |ansshf[MSB - (NB + 2) : 0]   // Cây OR gom toàn bộ bit rơi ra ngoài
7. Đánh giá điều kiện làm tròn Round-to-Nearest-Even trên độ lớn (magnitude):
   - round = G & (LSB | R | S)
   - mag_rounded = anstmp + round
   - Giới hạn mag_rounded trong [1, 2^(NB-1)-1] với đầu vào hữu hạn khác 0
8. Áp dụng dấu bằng phép bù hai:
   - Nếu sign == 1:
       R = (-zero_extend(mag_rounded)) mod 2^NB
   - Ngược lại:
       R = {1'b0, mag_rounded}
9. Trả về R.
```

#### B. Khác biệt giữa FloPoCo (RNE) [F] và Bộ nhân xấp xỉ [P]

| Đặc điểm | Profile TRUNC theo [P] | RNE phỏng theo [F], đối chiếu L0 |
| :--- | :--- | :--- |
| **Cơ chế** | Cắt cụt trực tiếp (Truncation / Round-to-zero) | **Round-to-Nearest-Even (RNE)** |
| **Độ phức tạp phần cứng** | Không cần logic tính bit $G, R, S$, không cần bộ cộng làm tròn | Cần cây gom bit sticky $S$, logic `round = G & (LSB \| R \| S)` và một bộ cộng làm tròn $\text{anstmp} + \text{round}$ |
| **Diện tích (Area)** | Bỏ logic RNE chuyên biệt khi tổng hợp cấu hình TRUNC | Thêm logic làm tròn/sticky và bank pipeline; mức chênh LUT/FF phải đo |
| **Sai số** | Cắt độ lớn gây bias về 0; dấu sai số có thể đổi với số âm | Hòa chọn chẵn; đúng RNE không tự bảo đảm sai số trung bình bằng 0 cho mọi phân phối |

Fig. 5(b) của [P] (chế độ TRUNC) chỉ có một hạng thanh ghi ở ngõ ra:
```
  m = Rgm[NB_R-2:0] XOR {Rgm[NB_R-1]}      // k>=0: m = k;  k<0: m = |k|-1
  FRB = ~Rgm[NB_R-1]                       // bit đầu regime
  Out = arith_shift_right({~FRB, FRB, Exp, Frac, zeros}, m) rồi cộng bit Sign
```
`ROUND_MODE="RNE"` dùng thuật toán mục A và chia hai hạng P1/P2 theo §5.9-D. Đây là cấu hình baseline đã chốt, không phải chứng minh mọi mục tiêu fmax đều cần hoặc chỉ cần hai hạng.

Thiết kế hỗ trợ cả 2 chế độ thông qua tham số `ROUND_MODE`:

- `ROUND_MODE="RNE"`: nghiệm thu exact theo AC-02; approx vẫn so L1. PIPE_PACK=2 theo §5.9-D; cần xác nhận timing.
- `ROUND_MODE="TRUNC"`: profile tái hiện [P], PIPE_PACK=1; số liệu diện tích/độ chính xác phải đo, không suy ra bằng nhau chỉ từ lựa chọn chế độ.

#### C. round_unpacked cho MAC v1

Hợp đồng bắt buộc: round_unpacked(u, mode) tương đương parse(pack(u, mode)) về giá trị, dấu, sf và fraction chuẩn hóa, bao gồm Zero/NaR, regime dài, exponent thiếu bit, carry làm tròn và bão hòa. Không chỉ cắt fraction theo sf ban đầu: carry có thể thay đổi sf và số bit khả dụng.

Đầu ra thuộc đúng lưới Posit; các bit thấp dưới lưới bằng 0, không chuyển phần dư G/R/S của tích chưa làm tròn sang Adder. Nhờ hợp đồng này v1 giữ ngữ nghĩa non-fused của §5.1. Cờ inexact của bước làm tròn vẫn phải được lưu trong metadata dù phần dư số học đã bỏ.

#### D. Hợp đồng phân tầng packer RNE P1/P2 — chốt 06/10/2026

**Phạm vi:** baseline ROUND_MODE="RNE", PIPE_PACK=2, cùng clk, hai slot elastic. Lõi tổ hợp và pipeline dùng cùng hai module posit_pack_prepare/posit_pack_finish, đối chiếu độc lập với L1. Đầu vào hữu hạn khác 0 đã chuẩn hóa thành sign, sf signed và fraction của 1.f; phần dư thấp chuyển thành sticky của độ lớn đúng. Packer không chuẩn hóa mantissa chưa chuẩn hóa và không diễn giải phần dư có dấu của fused bằng một sticky OR chung.

**Giao diện chốt07/10/2026:** rtl/posit_pack_comb.sv và rtl/posit_pack.sv dùng NB, ES, F_IN, SF_W, ROUND_MODE. F_IN mặc định 2*FRAC_MAX+1: posit8/0=11, posit16/1=25, posit32/2=55, posit32/3=53. Điều kiện F_IN>=FRAC_MAX+2 và <=63 cho adapter/oracle L1 hiện tại; bốn format này là phạm vi nghiệm thu, cấu hình khác cần kiểm riêng. frac[F_IN-1:0] không hidden, giá trị fraction=frac/2^F_IN; frac=0 cùng is_zero=0 biểu diễn mantissa1.0, không phải số0. F_IN mặc định giữ đủ tích của hai fraction FRAC_MAX bit sau chuẩn hóa, kể cả bit thấp thêm do tích>=2 được dịch phải một vị trí.

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

Nhằm đảm bảo tính trung thực học thuật và khả năng tái hiện chính xác số liệu phần cứng của bài báo tham chiếu chính [P] (Norris & Kim, ISCAS 2021), sơ đồ khối Fig. 3 được phân tích và ánh xạ trực tiếp sang các module RTL của đề tài.

#### A. Bảng ánh xạ khối Fig. 3 ↔ Module RTL

| Khối trên Fig. 3 của [P] | Tương ứng trong RTL đề tài | Chức năng phần cứng & Tương đương |
| --- | --- | --- |
| **Data Parser (Operand 1 & 2)** | `posit_parser` × 2 (hoặc × 3 cho MAC) | Giải mã bitstring Posit thành bộ ba unpacked `(sign, sf, frac)`, trích xuất bit regime, exponent, hidden bit $1.f$ và nhận diện sớm Zero/NaR. |
| **OPS (Operand Selection)** | `ops_sel` | Lựa chọn toán hạng $X$ (điều khiển số vòng lặp) và $Y$ (bị dịch), xor bit dấu `sign_o = sA ^ sB`. |
| **Rgm Exp Processing (Adder / Subtractor / Comparator)** | Tích hợp trong `ops_sel` / Datapath Scale Factor gộp | Fig. 3 tách riêng hai bộ cộng cho Regime và Exponent kèm bộ so sánh $\ge 8$. Đề tài hợp nhất thành biến Scale Factor bù hai $sf = k \cdot 2^{ES} + e$ (xem chứng minh tương đương toán học bên dưới). |
| **First Mux (trước SAC)** | Mux khởi tạo $fx$ trong `sac` | Chu kỳ đầu (`first = 1`): nạp fraction $fx$ từ OPS. Các chu kỳ lặp sau (`first = 0`): nạp $fx$ đã dịch loại bỏ bit 1 từ ngõ ra SAC. |
| **SAC (Shift Amount Calculator)** | `sac` | Chứa bộ dò số 0 đầu chuỗi (LZD/CLZ), xác định vị trí bit 1 tiếp theo $sa = \text{clz}(fx) + 1$, tích lũy tổng độ dịch $S = S + sa$, và dịch loại bit 1: $fx \ll sa$. |
| **Shift Register / Delay Line** | Shifter Stage trong `sbm` | Nhận độ dịch lũy kế $S$ từ thanh ghi Reg sau SAC, thực hiện dịch phải số học $1.f_Y \gg S$. |
| **First Mux (trước Accumulator)** | Mux khởi tạo `acc` trong `sbm` | Chu kỳ đầu (`first = 1`): nạp trực tiếp mantissa $1.f_Y$ (đóng góp của hidden bit của $X$). Các chu kỳ lặp sau (`first = 0`): nạp tổng tích lũy từ ngõ ra Accumulator. |
| **Accumulator** | Bộ cộng tích lũy trong `sbm` | Cộng dồn: $\text{acc} = \text{acc} + (1.f_Y \gg S)$. Duy trì bit `sticky_acc` gom các bit bị đẩy ra ngoài. |
| **Normalizer** | `mul_norm` | Kiểm tra bit tràn của tích ($\text{acc} \ge 2.0$), dịch phải 1 bit nếu cần và tăng scale factor: $sf = sf + 1$. |
| **Data Packer** | `round_unpacked` + `posit_pack` | Chuyển đổi dữ liệu mantissa và scale factor trở lại định dạng Posit chuẩn với thuật toán làm tròn RNE ([F]) hoặc cắt cụt TRUNC ([P]). |

#### B. Scale factor gộp

sf_A+sf_B=(k_A+k_B)·2^ES+(e_A+e_B). Nếu tổng exponent ≥2^ES thì carry tăng k thêm 1, phần exponent còn lại là (e_A+e_B) mod 2^ES. Đây là cùng phép tính với các bộ cộng/điều chỉnh Rgm/Exp của Fig. 3, miễn SF_W đủ rộng.

RTL có thể dùng một bộ cộng sf có dấu thay các khối điều chỉnh riêng. Diện tích và timing có cải thiện hay không phải đo; sự tương đương số học không chứng minh tiết kiệm LUT.

#### C. Chức năng 5 đường thanh ghi (Reg) và hai bộ Mux First trong Fig. 3

Fig. 3 sử dụng các vạch đứt đoạn biểu diễn ranh giới 5 tầng thanh ghi pipeline:

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
2. **Đường truyền trễ của Rgm và Exp (Scale Factor)**: Trong Fig. 3, đường tín hiệu từ Rgm Exp Processing đi qua các Reg rồi vào khối accumulator, nhưng bản vẽ không vẽ rõ số tầng thanh ghi trễ bên trong để đồng bộ nhịp với mantissa. *Xử lý*: Đề tài sử dụng Metadata FIFO lưu trữ Scale Factor gộp $sf = k \cdot 2^{ES} + e$ và dấu $sign$, đồng bộ hóa độ trễ tuyệt đối với mantissa datapath.
3. **Early termination**: khi fx=0 không còn số hạng fraction để phát; vẫn phải xả các tầng còn token. TV-PAPER-01 hết bit 1 sau hai vòng nhưng vẫn có sai số cắt 12 bit (§5.6), nên không coi là exact toàn độ rộng.
4. **Bypass Zero/NaR chưa được thể hiện trong Fig. 3**: không suy ra paper đã mô tả đầy đủ đường ngoại lệ từ sơ đồ này. *Xử lý*: kết quả ngoại lệ đúng là bắt buộc; bypass rút ngắn và Order FIFO là tối ưu sau baseline, với ngân sách hạng và quy ước cạnh tại §5.3.

### 5.11 Vi kiến trúc Pipeline MAC tích hợp Adder và Chồng lấn giao dịch

Khác với bài báo tham chiếu [P] chỉ dừng lại ở phép nhân hai toán hạng ($A \times B$), đóng góp trọng tâm C1 của đề tài là xây dựng hoàn chỉnh lõi **Posit MAC** ($D = A \times B + C$) với vi kiến trúc pipeline thông suốt và hiệu năng cao.

#### A. Các hợp đồng tích hợp

1. **C và metadata:** baseline giữ trong thanh ghi giao dịch; khi chồng lấn dùng FIFO/tag giữ đúng {C_eff, sign, sf, cfg, flags} theo §5.10-E. Chỉ pop khi bên nhận handshake; mul_done khi Adder chưa nhận không được làm mất C.
2. **Non-fused:** giữa bộ nhân và Adder dùng hợp đồng round_unpacked ở §5.9-C. Với exact/RNE, v0/v1 phải cho cùng kết quả L0.
3. **Backpressure:** baseline có thanh ghi đầu ra giữ d/flags. Với core không thể stall, mỗi handshake đầu vào phải đặt trước một slot lưu kết quả và chỉ trả credit khi đầu ra handshake. Số giao dịch chưa trả không vượt sức chứa kết quả đã bảo đảm. Skid buffer 2 phần tử chỉ đủ hấp thụ 2 kết quả, không thay cho lưu trữ của mọi giao dịch đang bay. Registered in_ready phải tính cả giao dịch nhận ở cạnh hiện tại khi quyết định credit tiếp theo.
4. **Thứ tự:** first/last, tag và metadata đi cùng mọi số hạng; giao dịch sau không được khởi tạo accumulator dùng chung trước khi số hạng cuối của giao dịch trước đã được chốt. Zero/NaR bypass theo §5.3. FIFO, credit và lịch hóa là điều kiện bắt buộc nếu chọn chồng lấn.
5. **Tích lũy:** v1 hồi tiếp tổng qua A1→A2→A3→round_unpacked (4 tầng mục tiêu), nên II_acc không nhỏ hơn max(II_core,4) khi đường hồi tiếp không stalled. Bốn chu kỳ là cận dưới, không bảo đảm equality nếu lịch khởi tạo/tài nguyên cần thêm chu kỳ. Trạng thái commit theo §4.2. V2 phụ thuộc C ngay trước căn chỉnh/core, nên II_acc phải suy ra từ đường hồi tiếp v2 thực tế; không khẳng định n+5 hay nhanh/chậm gấp đôi khi chưa có lịch và số đo.

#### B. Ngân sách hạng thanh ghi MAC v1 (q+10 hoặc q+11)

| Tầng | Tên giai đoạn | Chức năng thực hiện | Chu kỳ |
| :---: | :--- | :--- | :---: |
| **T1..T2** | Parse | Giải mã đồng thời $A, B, C$ thành dạng unpacked `(sign, sf, frac)` (`PIPE_PARSE = 2`) | 2 |
| **T3** | OPS & Init | Chọn $X, Y$, tính $sf_{\text{mul}} = sf_A + sf_B$, nạp dữ liệu vào SAC và Mux First, đẩy $C$ vào FIFO | 1 |
| **T4..T(n+5)** | Iterative Core | 3 tầng lặp chồng lấn (SAC $\rightarrow$ Shifter $\rightarrow$ Accumulator) theo Fig. 3 | $n + 2$ |
| **T(n+6)** | Norm & Unpacked Round | Chuẩn hóa tích ($\text{acc} \ge 2$), làm tròn mantissa về lưới Posit qua `round_unpacked`, cắt bỏ bit dư | 1 |
| **T(n+7)..T(n+9)** | Adder Stages A1..A3 | A1 (Align kẹp cứng), A2 (Add/Sub số học), A3 (LZC Normalize & Update Scale) | 3 |
| **T(n+10)** hoặc **T(n+10..n+11)** | Packer Stages | Đóng gói chuỗi bitstring Posit: 1 chu kỳ (`PIPE_PACK = 1` với TRUNC) hoặc 2 chu kỳ (`PIPE_PACK = 2` với RNE) | 1 hoặc 2 |

Ngân sách H = 2 (Parse) + 1 (OPS) + (q+2) (Core) + 1 (Norm/Round) + 3 (Adder) + PIPE_PACK = q+10 (TRUNC) hoặc q+11 (RNE). Bảng T phía trên minh họa n>=1 và đánh số lần chốt bắt đầu T1=E0; Tj tương ứng E(j-1), không phải Ej. Với n=0 dùng token init_only và q=1. L_valid=H-1, L_handshake=H theo §5.1; số đo RTL có bubble phải báo thêm bubble, không đổi quy ước cạnh để khớp công thức.

| MAC v1 không bypass/stall/bubble | OPS launch | core_done | TRUNC: H / valid / handshake | RNE: H / valid / handshake |
| --- | --- | --- | --- | --- |
| n=0, init_only | E2 | sau E5 | 11 / sau E10 / E11 | 12 / sau E11 / E12 |
| n=1 | E2 | sau E5 | 11 / sau E10 / E11 | 12 / sau E11 / E12 |
| n=2 (hoặc dừng sớm sau hai token) | E2 | sau E6 | 12 / sau E11 / E12 | 13 / sau E12 / E13 |

Bảng là kiểm tay lịch mục tiêu. Gate2/3 phải xác nhận bằng TB; nếu norm/round hoặc packer cần thêm tầng để đạt timing thì cập nhật H và mọi cạnh sau đó, giữ nguyên E0.

#### C. Tối ưu sau baseline

Áp dụng bypass (§5.3), round_unpacked (§5.9-C), chồng lấn và credit (§5.11-A) theo từng bước có regression. Trên FPGA dùng Clock Enable của thanh ghi, không dùng LUT để gate clock. CE giảm hoạt động thanh ghi được khóa; muốn kết luận công suất toàn khối phải đo theo §7.1.

#### D. Kiểm chứng pipeline

SVA tập trung ở §6.6. Bổ sung ít nhất 10^6 giao dịch back-to-back với n thay đổi, n=0, Zero/NaR, acc_mode/acc_clr và out_ready ngẫu nhiên/kéo thấp dài; scoreboard kiểm thứ tự, không mất/nhân đôi giao dịch. Đo riêng II khi không stalled để đánh giá mục tiêu throughput; backpressure có thể làm II lớn hơn. Không bắt in_ready trở lại đúng một khoảng cố định khi FIFO đang đầy.

### 5.12 MAC v2 fused (MAY, ngoài đường găng)

V2 tích lũy C và các số hạng tích trước Packer cuối. Không có bước làm tròn tích về lưới Posit như v1; tuy nhiên cắt fraction/căn chỉnh trong cửa sổ approx vẫn gây sai số. Vì vậy approx chỉ khớp L1, không được tuyên bố khớp p32_mulAdd.

**Trạng thái thiết kế:** phần chọn mốc và hai vector không mất bit dưới đây đủ làm mô hình toán học khởi đầu. Chính sách đuôi có dấu qua nhiều phép cộng/trừ và triệt tiêu sâu (§5.12-c) chưa được chốt để viết RTL v2. Hoàn tất L1 và kiểm chứng độc lập chính sách đó là điều kiện trước triển khai mở rộng này.

#### a. Căn chỉnh Scale Factor và Chọn Mốc (Scale Alignment & Anchor Selection)
Đặt $sf_P = sf_A + sf_B$ là scale factor của tích trước khi chuẩn hóa (tích mantissa nằm trong khoảng $[1.0, 4.0)$). Chênh lệch scale factor được xác định bởi:
$$\Delta SF = sf_P - sf_C$$

Căn cứ vào giá trị $\Delta SF$, mạch điều khiển xác định toán hạng làm mốc (Anchor) và cấu hình lượng dịch:

| Điều kiện | Mốc Scale Factor ($sf_{\text{base}}$) | Căn chỉnh toán hạng $C'$ nạp vào Accumulator | Lượng dịch thêm cho số hạng tích (`shift_extra`) |
| :--- | :---: | :--- | :---: |
| $\Delta SF \ge 0$ | **Tích** ($sf_{\text{base}} = sf_P$) | $C' = C \gg \Delta SF$ | $0$ |
| $\Delta SF < 0$ | **C** ($sf_{\text{base}} = sf_C$) | $C' = C$ (giữ nguyên vị trí) | $-\Delta SF$ |
| $\Delta SF > \text{FRAC\_MAX} + 2$ | **Tích** ($sf_{\text{base}} = sf_P$) | $C$ chỉ còn `sticky` (bỏ phép dịch căn chỉnh) | $0$ |
| $-\Delta SF > \text{FRAC\_MAX} + 2$ | **C** ($sf_{\text{base}} = sf_C$) | $C' = C$ | Tích chỉ còn `sticky`: FSM có thể bỏ hẳn vòng lặp |

#### b. Hậu xử lý

Sau khi xả đủ số hạng, lấy độ lớn mag=abs(acc) và xác định dấu. Xử lý zero/phần dư theo §5.12-c trước khi gọi LZC. Đặt Q=FRAC_MAX+2 (vị trí hidden bit trong cửa sổ số học), h là vị trí bit 1 cao nhất của mag. Dịch về h=Q và cập nhật sf_final=sf_base+(h-Q); dịch phải phải giữ phần bị mất theo hợp đồng phần dư. Không lấy số leading-zero của toàn vector làm lượng giảm sf trực tiếp vì vector còn bit dấu và các bit nguyên dự phòng.

Sau chuẩn hóa, Packer làm tròn theo §5.9. Phần dư phải được chuyển sang thông tin G/R/S của độ lớn theo chính sách có dấu đã kiểm chứng; không gắn một sticky OR chung vào tổng khác dấu rồi tuyên bố RNE exact.

#### c. Phần dư có dấu và điều kiện exact

Viết mỗi số hạng magnitude y=y_trunc+δ, với 0≤δ<2^-Q; sticky chỉ cho biết δ khác 0, không phải δ=2^-Q. Với số hạng âm: -y=-y_trunc-δ. Do đó không OR đuôi rồi coi tất cả là phần dư dương, cũng không trừ một LSB tùy tiện ở mọi vòng. Tổng nhiều δ có thể tạo carry và triệt tiêu có thể đưa đuôi trở thành bit có nghĩa.

Trước khi code v2, L1 phải quy định điểm cắt, cách jam/borrow theo dấu, cập nhật phần dư qua các vòng và xử lý acc=0 nhưng đuôi khác 0. So với số học hữu tỉ trên các ca cùng/khác dấu, hòa RNE, near-cancellation và ΔSF lớn; ghi giới hạn accuracy của profile approx. Một cờ sticky riêng không đủ chứng minh exact fused.

Đối với exact fused, dùng số nguyên rộng hoặc Fraction làm oracle và giữ đủ toàn bộ tích/tổng trước RNE. Một lựa chọn tham chiếu an toàn là lưới cố định 2^(-2·SF_MAX) với số nguyên có dấu rộng 4·SF_MAX+3 bit (27 bit posit8, 115 bit posit16); đây là độ rộng bảo thủ, không phải yêu cầu phải dùng quire cho RTL. Thiết kế dùng cửa sổ hẹp hơn phải chứng minh cùng kết quả trên miền nghiệm thu. Công thức gần 3·(FRAC_MAX+1) không bao quát tự động chênh scale và triệt tiêu toàn miền.

#### d. Các Trường hợp Đặc biệt (Special Corner Cases)
- **$C_eff = 0$**: có thể dùng đường nhân với cùng profile chính xác và dấu; lịch vòng hidden bit/độ trễ phải ghi rõ.
- **Tích bằng 0 ($A = 0$ hoặc $B = 0$)**: kết quả C_eff nếu không có NaR; bypass và ngân sách cạnh theo §5.3, chưa đo v2 RTL.
- **NaR**: A/B/C_eff là NaR thì xuất NaR ưu tiên; latency bypass theo §5.3, không ấn định hai chu kỳ valid cho mọi cấu trúc.
- **Triệt tiêu**: zero của kết quả nội bộ phải xét cả phần dư theo §5.12-c. Approx không được suy ra đã triệt tiêu chính xác tích thật chỉ từ acc=0.

#### e. Máy trạng thái điều khiển (FSM) của MAC v2
`IDLE → PARSE (2 cyc) → INIT (1 cyc: tính ΔSF, chọn mốc, căn C' song song) → ITER/DRAIN (n+1 số hạng, cộng thêm 2 chu kỳ xả pipeline) → ABS_NORM (1 cyc) → PACK (1-2 cyc) → DONE`.

#### f. Hai Ví dụ Số Kiểm Chứng Chi Tiết (Golden Test Vectors)
1. **TV-FUSE-01 (Mốc Tích, $\Delta SF \ge 0$)**:
   - $A = 10 = 1.25 \times 2^3$ ($sf_A = 3, m_A = 1.01_2$); $B = 0.34375 = 1.375 \times 2^{-2}$ ($sf_B = -2, m_B = 1.011_2$).
   - $sf_P = 3 + (-2) = 1$. $C = 0.5 = 1.0 \times 2^{-1}$ ($sf_C = -1, m_C = 1.0_2$).
   - $\Delta SF = 1 - (-1) = 2 \ge 0 \implies$ Mốc = Tích ($sf_{\text{base}} = 1$), $\text{shift\_extra} = 0$.
   - $C$ căn chỉnh: $C' = 1.0 \gg 2 = 0.25$.
   - Khởi tạo: $\text{acc} = C' = 0.25$.
   - Vòng 0 (hidden bit của $X$): $\text{acc} += 1.375 \implies \text{acc} = 1.625$.
   - Vòng 1 (bit 1 tại vị trí 2 của $X$): $S = 2 \implies \text{acc} += (1.375 \gg 2) = 0.34375 \implies \text{acc} = 1.96875$.
   - Vì $\text{acc} = 1.96875 \in [1, 2)$, không cần dịch chuẩn hóa. Giá trị kết quả: $1.96875 \times 2^1 = \mathbf{3.9375}$.
2. **TV-FUSE-02 (Mốc C, $\Delta SF < 0$)**:
   - Cùng $A, B \implies sf_P = 1$. $C = -8 = -1.0 \times 2^3$ ($sf_C = 3, s_C = 1, m_C = 1.0$).
   - $\Delta SF = 1 - 3 = -2 < 0 \implies$ Mốc = $C$ ($sf_{\text{base}} = 3$). Lượng dịch thêm: $\text{shift\_extra} = -\Delta SF = 2$.
   - Khởi tạo: $\text{acc} = C' = -1.0$ (dấu âm).
   - Vòng 0 (hidden bit của $X$): $\text{acc} += (1.375 \gg 2) = 0.34375 \implies \text{acc} = -1.0 + 0.34375 = -0.65625$.
   - Vòng 1 (bit 1 tại vị trí 2 của $X$): $S = 2 \implies S' = 2 + 2 = 4$. $\text{acc} += (1.375 \gg 4) = 0.0859375 \implies \text{acc} = -0.65625 + 0.0859375 = -0.5703125$.
   - Hậu xử lý: $\text{acc} < 0 \implies sign = 1, |\text{acc}| = 0.5703125 = 1.140625 \times 2^{-1}$ (LZC = 1).
   - Chuẩn hóa: dịch trái 1 bit $\implies 1.140625$, cập nhật scale factor: $sf_{\text{final}} = 3 - 1 = 2$.
   - Kết quả: $-1.140625 \times 2^2 = \mathbf{-4.5625}$.

### 5.13 MAC top và điều khiển

Đường v0/v1/v2 theo §5.1; v2 là MAY. FSM v1:
IDLE → PARSE → INIT → ITER/DRAIN → NORM_ROUND → ADD_A1 → ADD_A2 → ADD_A3 → PACK → HOLD_OUTPUT.
NORM_ROUND là một tầng mục tiêu, không hai chu kỳ NORM và ROUND riêng. HOLD_OUTPUT giữ kết quả đến khi có nơi lưu đầu ra; không tự thêm một chu kỳ nếu kết quả đã chốt hợp lệ.

Nhánh ngoại lệ theo §5.3; thứ tự và sức chứa đầu ra theo §5.11. Thanh ghi đầu ra hay skid buffer phải được tính trong lịch pipeline đo thực tế. Skid buffer hữu hạn không bảo đảm pipeline chạy mãi khi out_ready=0, cũng không tự chứng minh không deadlock.

---

## 6. Golden model và kiểm chứng

### 6.1 Ba tầng đối chiếu

| Tầng | Vai trò | So với RTL |
| --- | --- | --- |
| **L0** | SoftPosit (`p8_*`, `p16_*`, `p32_*`, các hàm `convertDoubleToP32`, `convertP32ToDouble`, `p32_mul`, `p32_add`, `p32_mulAdd`) | Chế độ exact: bit-exact. Chế độ approx: thống kê sai số (Err, MSE) |
| **L1** | Mô hình C++ tự viết của **chính thuật toán** (parser, OPS, SAC, SBM, normalize, round, add, pack; hàm `l1_mac_fused` bit-exact tại cửa sổ `ACC_WIN`, sticky và chọn mốc), tham số hóa `NB, ES, FRAC_W, n, ops` | **Bit-exact 100%** với RTL ở mọi cấu hình |
| **Ideal** | Tích/tổng chính xác của hai giá trị thực bằng số nguyên rộng (`unsigned __int128` cho mantissa, hoặc Python `fractions.Fraction`) | Dùng để tính Err theo định nghĩa của [P] |

Lý do cần tầng Ideal riêng: tích của hai mantissa 27 bit dài 54 bit, vượt độ chính xác 53 bit của `double`, nên không được dùng `double` làm chuẩn ở posit32.

**Nguyên tắc độc lập và thẩm định L1 trước khi kiểm chứng RTL**:

- Do mô hình thuật toán L1 (C++) và mã nguồn RTL (SystemVerilog) đều do cùng một tác giả xây dựng, rủi ro lớn nhất là **sai lệch nhận thức hệ thống (systematic common-mode bias)**: tác giả hiểu sai thuật toán từ lý thuyết và hiện thực cái sai đó lên cả C++ lẫn SystemVerilog. Khi đó, tiêu chí AC-01 (RTL khớp L1 100%) vẫn có thể đạt được dễ dàng nhưng cả hai thiết kế đều sai lệch so với chuẩn toán học Posit.
- **Quy định bắt buộc (Mandatory Prerequisite Gates)**: Mô hình L1 không được phép tự động coi là thước đo chuẩn cho RTL nếu chưa qua kiểm định chéo với L0 (SoftPosit). Quy trình nghiệm thu L1 được chia thành hai mốc thực tế:
  - **Gate 1 (Tuần 3 — Parser, Packer và L1 Multiplier Exact)**: L1 parser/packer và bộ nhân ở chế độ exact bắt buộc phải pass 100% không sai lệch (0 mismatch) so với L0:
    - Vòng khép kín Parser $\rightarrow$ Packer: là phép đồng nhất 100% trên toàn bộ chuỗi bit hợp lệ của `posit8` ($2^8$) và `posit16` ($2^{16}$).
    - Nhân exact (`l1_mul` vs `p<N>_mul`): $2^{16}$ cặp nhân `posit8`, $2^{32}$ cặp nhân `posit16`, toàn bộ corner list (§6.4) và $\ge 10^7$ vector ngẫu nhiên phân tầng `posit32`.
  - **Gate 1B (Tuần 6 — L1 Adder và Full MAC Suite)**: Hoàn tất L1 Adder và MAC, đối chiếu bit-exact 100% với SoftPosit trước khi bắt đầu chuyển sang code RTL:
    - Cộng exact (`l1_add` vs `p<N>_add`): $2^{16}$ cặp cộng `posit8`, $2^{32}$ cặp cộng `posit16`, corner list và $\ge 10^7$ vector phân tầng `posit32`.
    - MAC exact (`l1_mac` vs `p<N>_add(p<N>_mul(a,b), c)`): $2^{24}$ bộ ba MAC `posit8`, corner list và $\ge 10^7$ vector phân tầng `posit32` (cho cả MAC non-fused và `acc_mode`).

### 6.2 Lưu ý khớp SoftPosit

- SoftPosit dùng `posit8: ES=0`, `posit16: ES=1`, `posit32: ES=2`. Vì vậy chỉ ba cấu hình này đối chiếu trực tiếp được. Với `ES=3` (paper) bắt buộc dùng L1 do bạn viết, và L1 phải được kiểm tra chéo với SoftPosit bằng cách chạy L1 ở `ES=2` để chứng minh L1 đúng.
- Cần kiểm tra phiên bản SoftPosit đang dùng (kiểu `ES` của p16) và ghi vào log; nếu thư viện cập nhật theo chuẩn mới (mọi kích thước dùng `ES=2`) thì chỉnh bảng cấu hình tương ứng.
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
4. **Kích hoạt đường triệt tiêu (chỉ suite Adder/MAC)**: Bổ sung tối thiểu 30% vector có $sf(C)$ gần $sf(A \times B)$ ($|\Delta sf| \le 4$) và trái dấu để kiểm tra toàn diện bộ trừ mantissa, bộ dò LZC và cơ chế kẹp cứng alignment shifter.

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

**Đường A (nhanh, chính thức cho AC-01/02)**: Verilator + harness C++. C++ gọi trực tiếp SoftPosit và L1, so sánh từng giao dịch, ghi CSV. Mục tiêu 10^7 đến 10^9 vector.

**Đường B (UVM-lite, minh họa phương pháp)**: testbench SystemVerilog dạng lớp (class) gồm: `sequence_item` (a, b, c, cfg), `generator` (ràng buộc ngẫu nhiên theo §6.3), `driver` (bắt tay valid/ready), `monitor`, `scoreboard` (gọi L0/L1 qua **DPI-C**), `coverage collector` (covergroup). Chạy trên trình mô phỏng hỗ trợ class và covergroup đầy đủ (Questa/VCS/Xcelium nếu trường có; xsim hỗ trợ hạn chế, phải kiểm tra). Nếu chỉ có Verilator thì đường B chỉ dùng phần class được hỗ trợ và coverage lấy từ đường A.

Nguyên mẫu DPI-C:

```systemverilog
import "DPI-C" function int unsigned l0_p32_mul   (input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned l0_p32_add   (input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned l0_p32_mulAdd(input int unsigned a, input int unsigned b, input int unsigned c);
// API scalar exact RNE đã triển khai ở tuần6:
import "DPI-C" function int unsigned l1_p32_mul   (input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned l1_p32_mac   (input int unsigned a, input int unsigned b, input int unsigned c);
// API fused dưới đây là dự kiến cho giai đoạn mở rộng, chưa triển khai:
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
| A-05 | Đầu ra NaR ⇔ A/B/C_eff là NaR; xét acc_nar_q và acc_clr theo giao dịch, ưu tiên NaR hơn Zero |
| A-06 | Đầu ra là zero chỉ khi (có `A=0` hoặc `B=0` với C=0) hoặc triệt tiêu chính xác |
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
| v2 approx posit32 (MAY) | (32,2) | 12 | n ∈ {1,2,3,4} | 0,1 | ≥ 10^7 mỗi n/OPS nếu triển khai | L1 fused sau khi chốt §5.12-c; p32_mulAdd thống kê |
| v2 exact posit8 (MAY) | (8,0) | 5 | exact | 0 | exhaustive (2^24) nếu triển khai | p8_mulAdd bit-exact, oracle đủ rộng |
| Quét FRAC_W (MAY) | (32,2) hoặc (32,3) | 8, 12, 16, 23 | n = 3 | 1 | ≥ 10^6 | Cho EXT-B |

Ma trận final khác ngưỡng Gate 1/1B ở §6.1. Profile bắt buộc: exact/RNE; approx/RNE+STICKY_ACC; tái hiện [P] dùng TRUNC+FLOOR cho (32,3), FRAC_W=12. Chạy từng OPS và n đã liệt kê; tổ hợp ROUND_MODE/SCHEME khác là MAY và phải có regression nếu công bố hỗ trợ. n=0 luôn có test đơn vị/corner cho mọi profile, dù không phải mỗi hàng đều chạy 10 triệu mẫu ở n=0.

### 6.8 Chỉ số sai số

Gọi `y` là kết quả xấp xỉ (giải mã sang số thực chính xác), `r` là chuẩn (Ideal hoặc L0 tùy bảng).

```
Err(%)        = |r - y| / |r| × 100                       // theo [P]/[15]/[18]
CorrectRate(θ)= tỉ lệ vector có Err < θ, θ ∈ {0.1, 0.5, 1.0, 5.0} (%)
NMSE          = (1/N) Σ ((r - y)/r)^2                     // MSE tương đối, ghi chú bên dưới
MaxErr        = max Err
ULP-distance  = |signed_code(y) - signed_code(r)|        // số bậc Posit giữa hai mã cùng NB/ES
```

Loại NaR khỏi các chỉ số số thực và báo riêng số lượng ngoại lệ. Khi r=0, không chia cho r: nếu y=0 ghi zero-match, nếu y≠0 báo số ca sai và sai số tuyệt đối riêng. N trong Err/NMSE là số mẫu hữu hạn có r≠0; không tính NaR/zero bị loại như mẫu đạt. signed_code là mã Posit diễn giải bù hai, tính hiệu bằng số nguyên đủ rộng; ULP-distance là khoảng cách mã, không phải độ dài ULP cố định trên toàn dải.

ES=3 có dải xấp xỉ 10^±72, ES=2 xấp xỉ 10^±36; MSE tuyệt đối dễ bị các giá trị lớn chi phối. Báo cáo cửa sổ/miền và phân bố mẫu. Table I dùng Ideal theo Fig. 6(a). Table II của [P] dùng posit exact ES=3, nên p32 SoftPosit ES=2 không dùng trực tiếp; cần oracle Posit (32,3) độc lập đủ chính xác.

**Độ tin cậy thống kê** (khoảng tin cậy 95% của một tỉ lệ `p`, `±1.96·√(p(1-p)/N)`):

| N | p = 0.50 | p = 0.95 |
| --- | --- | --- |
| 10^6 | ±0.098% | ±0.043% |
| 10^7 | ±0.031% | ±0.0135% |
| 10^8 | ±0.0098% | ±0.0043% |

Với sai khác giữa "Proposed" và "Kim" ở Table I chỉ 0.0 đến 0.8 điểm phần trăm, N = 10^7 là mức tối thiểu để kết luận có ý nghĩa.

Công thức khoảng tin cậy trên giả định mẫu Bernoulli độc lập cùng phân phối. Khi ép các tầng có trọng số khác nhau, báo cáo theo từng tầng hoặc dùng ước lượng có trọng số; không suy rộng tỷ lệ gộp 256 ô cân bằng thành tỷ lệ của dữ liệu ứng dụng.

### 6.9 Quy trình hồi quy và tiêu chí đạt/hỏng

1. `make lint` → không lỗi.
2. `make smoke` (≈ 10^5 vector, corner list, vài giây) chạy trên mọi commit.
3. `make regress` (toàn bộ §6.7) tạo `results/*.csv` và `results/summary.md`.
4. `make cov` tạo báo cáo line/branch/toggle và functional coverage.
5. **Hỏng** nếu có bất kỳ mismatch RTL↔L1, hoặc mismatch exact↔L0. Mỗi mismatch phải tự ghi lại `(a, b, c, cfg, got, exp)` vào `results/fail_*.log` và tự sinh test regression cố định.

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
| Đề tài | (1) **Posit MAC v1** (Non-fused): `(32,2)` và `(32,3)`; `FRAC_W ∈ {8, 12, 16}`; `EXACT_EN ∈ {0,1}`.<br>(2) **Posit MAC v2** (MAY): FUSED=1, ACC_WIN theo NB/ES của §4.1; chỉ đo sau khi chốt L1 fused. So sánh trực tiếp v1 vs v2 theo: số lượng LUT, $f_{\max}$, độ trễ chu kỳ, và sai số (NMSE so với Ideal, do v2 chỉ làm tròn một lần). *(Lưu ý: Không đặt trước ngưỡng $f_{\max}$ tiên nghiệm cho vòng cộng dồn 33 bit có dấu trước khi tổng hợp thử nghiệm thực tế)*. |
| Baseline posit | PACoGen multiplier ([23], mã nguồn [24]) sinh ra cho **cùng** `(NB, ES)` với thiết kế của bạn, DSP thay bằng LUT |
| Baseline FP32/FP16 | (B1) Xilinx Floating-Point Operator IP: bộ nhân + bộ cộng, không dùng DSP, độ trễ chọn để fmax gần nhất với thiết kế của bạn; (B2, MAY) bộ FP sinh bởi FloPoCo hoặc tự viết |
| Đối chiếu bài báo | Multiplier riêng lẻ (không adder), `(32,3)`, `FRAC_W=12` để so với 698 LUT / 289 FF / 575 MHz của [P] (so tuyệt đối chỉ khi ở bậc D0; nếu không thì so tỉ lệ theo §7.6) |

Lưu ý: [P] ghi so sánh với PACoGen dùng `es=6` mặc định, trong khi thiết kế của [P] dùng `es=3`. Phải so sánh cùng `ES` và ghi chú sự khác biệt này.

### 7.3 Chỉ số báo cáo

LUT, FF, CARRY8, DSP, BRAM, WNS, fmax, độ trễ (chu kỳ, cố định + n), tích Diện tích×Trễ, số phép/giây, phép/giây trên mỗi LUT, (nếu có SAIF) năng lượng/phép.

### 7.4 Chỉ số công bằng (phân tích trung thực)

Phép nhân lặp không xuất kết quả mỗi chu kỳ. Khi đánh giá hiệu năng trên diện tích (throughput / LUT), cần phân biệt rõ hai chế độ vận hành:

#### A. Chế độ đơn lẻ cô lập (Isolated mode — Cận dưới worst-case)

Với giả định bảo thủ khi xử lý từng giao dịch rời rạc, khoảng cách khởi phát bằng toàn bộ độ trễ pipeline ($\text{II} = \text{độ trễ}$):

| Thiết kế | fmax | Độ trễ / II | Phép/giây | LUT | Phép/giây/LUT |
| --- | --- | --- | --- | --- | --- |
| [P], n = 3 | 575 MHz | 9 chu kỳ (n+6) | 63.9 M | 698 | 0.092 M |
| [P], n = 1 | 575 MHz | 7 chu kỳ | 82.1 M | 698 | 0.118 M |
| PACoGen pipelined | 380 MHz | II = 1 (độ trễ 5) | 380 M | 1247 | 0.305 M |

(Số liệu từ Table III của [P]; phép tính là giả định minh họa.) Theo thước đo đơn lẻ này, PACoGen cao hơn khoảng 2.6 đến 3.3 lần về phép/giây/LUT cho một lõi độc lập. Bảng này đóng vai trò là **cận dưới (worst-case lower bound)** khi hệ thống không thực hiện nạp liên tục.

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

Script `scripts/collect_ppa.py` đọc các báo cáo Vivado (và Yosys/OpenROAD nếu dùng §7.6) rồi xuất `results/ppa.csv`, `results/ppa.md`. Mọi con số trong báo cáo sinh từ file này.

### 7.6 Chính sách thiết bị và phương án khi không có xcvu9p

Chọn part mà phiên bản Vivado và license hiện có hỗ trợ; ghi kết quả kiểm tra part/license vào log trước khi chốt nền tảng. Không cần board vật lý để tổng hợp/P&R. D0 dùng cùng device family như [P]; các bậc khác chỉ so trong cùng nền tảng và ghi rõ giới hạn đối chiếu. Không cố định tên gói miễn phí hay công nghệ chế tạo cho cả họ thiết bị vì hỗ trợ thay đổi theo part/phiên bản.

**Các bậc nền tảng**

| Bậc | Nền tảng | Điều kiện | Số liệu thu được | Giá trị so với [P] |
| --- | --- | --- | --- | --- |
| D0 | Vivado + `xcvu9p` | Phiên bản và license hỗ trợ part đã chọn | LUT/FF/fmax tuyệt đối | So trực tiếp |
| D1 | Vivado + UltraScale+ được bản cài/license hỗ trợ | Xác nhận theo part | LUT/FF/CARRY8, timing đo riêng | Chỉ so tỉ lệ đo cùng nền tảng |
| D2 | Vivado + 7-series (Artix-7 `xc7a100t`, Zynq-7000 `xc7z020`) | Xác nhận part trong bản đã cài | LUT6/CARRY4; timing phải đo riêng | Chỉ so tỉ lệ |
| D3 | Yosys `synth_xilinx` (không cần Vivado; chọn family theo phiên bản Yosys) + số tầng LUT trên đường dài nhất (`ltp`) | Mã nguồn mở | LUT/FF/CARRY, độ sâu logic làm đại lượng thay cho fmax | Bằng chứng chéo, chỉ tỉ lệ |
| D4 | Yosys + OpenROAD (EXT-A), Nangate45 hoặc SKY130HD | Mã nguồn mở | Diện tích µm², WNS, fmax, công suất ước tính | Không so số của [P]; so xu hướng và tỉ lệ |

**Quy tắc để kết quả vẫn có giá trị**

1. **Cùng điều kiện.** Mọi thiết kế được so sánh (posit, PACoGen, FP32, FP16) dùng cùng công cụ, phiên bản, thiết bị, ràng buộc, chế độ out-of-context, không DSP.
2. **Báo cáo tỉ lệ** `R_LUT = LUT_đề_tài / LUT_baseline`, `R_FF`, `R_fmax = fmax_đề_tài / fmax_baseline`. Mốc của [P] với PACoGen: `R_LUT = 698/1247 = 0.56`, `R_fmax = 575/380 = 1.51`.
3. **Kiểm chéo hai nền tảng khác bậc** (ví dụ D1 hoặc D2 cùng D3 hoặc D4). Một khẳng định về thứ hạng hay tỉ lệ chỉ được đưa vào kết luận nếu giữ nguyên trên cả hai; nếu chỉ đúng trên một nền tảng thì ghi rõ là phụ thuộc nền tảng.
4. **Phân rã theo module** (parser, packer, nhân, cộng) bằng `report_utilization -hierarchical`. Tỉ lệ đóng góp của từng module ổn định hơn số tuyệt đối; [P] nói phần lớn tài nguyên nằm ở parser/packer, nên đây là điểm dễ kiểm chứng.
5. **Độ nhạy.** ≥ 3 seed/chiến lược; nếu fmax giữa các seed chênh quá 10% thì coi là nhiễu và báo cáo khoảng min–max, không báo cáo một điểm.
6. **Dùng từ đúng.** Chỉ viết "tái hiện Table III" khi ở D0; ở các bậc còn lại viết "tái hiện xu hướng và tỉ lệ".

**Ví dụ số (giả định minh họa, không phải số đo thật).** Ở D2, PACoGen ra 1,410 LUT / 210 MHz, thiết kế của bạn ra 790 LUT / 330 MHz. Khi đó `R_LUT = 790/1410 = 0.560` (trùng mốc 0.56) và `R_fmax = 330/210 = 1.571`, lệch +3.8% so với mốc 1.513. Đây là kết quả tái hiện xu hướng tốt dù số tuyệt đối khác hẳn [P].

**Ngưỡng NFR quy đổi sang tỉ lệ** (quy từ NFR-02/03 với baseline 1247 LUT / 380 MHz):

| Mức | NFR-02 (tuyệt đối → `R_LUT`) | NFR-03 (tuyệt đối → `R_fmax`) |
| --- | --- | --- |
| Tối thiểu | ≤ 1000 LUT → ≤ 0.80 | ≥ 350 MHz → ≥ 0.92 |
| Mục tiêu | ≤ 800 LUT → ≤ 0.64 | ≥ 450 MHz → ≥ 1.18 |
| Xuất sắc | ≤ 700 LUT → ≤ 0.56 | ≥ 575 MHz → ≥ 1.51 |

Ngoài D0, dùng cột tỉ lệ. **Tiêu chí AC-05/AC-06 khi không có D0**: đạt nếu có ≥ 1 bậc Vivado (D1 hoặc D2) và ≥ 1 bậc kiểm chéo (D3 hoặc D4), `R_LUT` và `R_fmax` nằm trong ±20% mốc của [P] hoặc có giải thích định lượng cho phần chênh (đề xuất, chốt với GVHD).

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
| 4 | L1: OPS, SAC, SBM approx; tái hiện TV-ITER-01, TV-PAPER-01, Table I bằng L1 | L1 approx multiplier | Tái hiện Fig. 4 và Table I (sai lệch $\le 1.0$ điểm) |
| 5 | L1: Posit Adder (`l1_add`); kiểm tra bit-exact với SoftPosit `p<N>_add` | L1 adder | L1 adder = L0 ($2^{16}$ posit8, $2^{32}$ posit16, corner list + $\ge 10^7$ posit32) |
| 6 | L1: Posit MAC non-fused (`l1_mac`), `round_unpacked`, `acc_mode` | L1 mac hoàn chỉnh | **Gate 1B**: L1 MAC = L0 ($2^{24}$ posit8, corner list + $\ge 10^7$ posit32) trước khi code RTL |
| 7 | RTL parser + LOD/LZD + barrel shifter + testbench đơn vị | `posit_parser` | Exhaustive posit8/16 |
| 8 | RTL packer + RNE + pre-clamping; kiểm parser→packer đồng nhất | `posit_pack` | Corner list, exhaustive posit8/16 |
| 9 | RTL OPS + SAC + SBM + `iter_ctrl`; multiplier top | `posit_mul_iter` | **Gate 2**: RTL Multiplier = L1, $10^7$ vector, mọi n; exact mode khớp L0 |
| 10 | RTL adder (Stages A1, A2, A3); exhaustive posit8/16 | `posit_add` | Adder = L0 bit-exact |
| 11 | RTL MAC Top v0 & v1 (`round_unpacked`), Operand C FIFO, credit counter, `acc_mode`, flags; Khởi động L1 Fused MAC (`l1_mac_fused`, Tier 3) | `posit_mac_top`, L1 fused | **Gate 3**: MAC RTL (v1) = L1; exact = L0; tổng hợp sơ bộ v1 |
| 12 | Testbench đường A hoàn chỉnh, hồi quy toàn bộ §6.7; hoàn thiện L1 Fused MAC vs `p<N>_mulAdd` | `results/` đầy đủ, L1 fused suite | AC-01, AC-02, AC-04 cho v1 |
| 13 | Tổng hợp/P&R Vivado (v1 baseline); RTL MAC v2 Fused (Tier 3, sau Gate 3); baseline PACoGen và FP32/FP16 | `ppa.csv`, RTL MAC v2 | AC-05, AC-06; So sánh v1 vs v2 PPA |
| 14 | Mở rộng đã chọn (EXT-A/B/C và hoàn tất kiểm thử RTL v2 Fused) | Số liệu mở rộng & RTL v2 | **Gate 4**: đủ số liệu cho báo cáo |
| 15 | Viết báo cáo, rà soát ma trận truy vết (Phụ lục D), chạy `make all` từ repo sạch | Bản thảo báo cáo | AC-07, AC-08 |
| 16 | Đệm, sửa theo phản hồi, slide, demo, tập bảo vệ | Báo cáo cuối, slide | Sẵn sàng bảo vệ |

**Phân cấp lộ trình và quản lý rủi ro tiến độ**:
- **Đường găng dự án (Critical Path - Bắt buộc)**: Gate 1 (Tuần 3) $\rightarrow$ Gate 1B (Tuần 6) $\rightarrow$ Gate 2 (Tuần 9) $\rightarrow$ Gate 3 (Tuần 11) đều chỉ tập trung vào bộ nhân lặp và **MAC v1 Non-fused** để bảo đảm tiến độ tốt nghiệp vững chắc.
- **Tính năng mở rộng Fused MAC v2 (Tier 3, FR-11)**: Tuyệt đối không đưa vào đường găng của Gate 1..Gate 3. L1 Fused được phát triển độc lập ở Tuần 11–12; RTL MAC v2 được triển khai sau Gate 3 ở Tuần 13–14 như một hạng mục nâng cấp xuất sắc.
- Nếu chậm tiến độ: Cắt theo thứ tự (1) EXT-C, (2) RTL MAC v2 FUSED, (3) đường B của testbench, (4) EXT-B; không cắt AC-01/02 và MAC v1.

---

## 10. Repo, chuẩn code, công cụ

```
posit_mac/
├── docs/            spec, ambiguity.md, báo cáo, nhật ký quyết định thiết kế
├── l0/              wrapper SoftPosit (C++/Python)
├── l1/              mô hình thuật toán C++ (header-only, template NB, ES)
├── rtl/             SystemVerilog (parser, pack, ops, sac, sbm, add, mac_top)
├── tb/
│   ├── verilator/   harness C++, sinh vector, so sánh
│   └── uvm_lite/    class-based TB, covergroup, DPI-C
├── tests/           corner list, TV-*, regression cố định
├── syn/             script Vivado, ràng buộc, baseline
├── asic/            (EXT-A) config ORFS
├── scripts/         thu thập kết quả, vẽ đồ thị Pareto/lỗi
├── results/         CSV, summary.md (sinh tự động)
└── Makefile
```

- Quy ước RTL: một module một file; tên tín hiệu `snake_case`; hậu tố `_q` cho thanh ghi, `_d` cho giá trị kế; `always_ff`/`always_comb`; không dùng `initial` để khởi tạo phần cứng; tham số qua `parameter`/`localparam`; kiểm tra tham số bằng `$error` trong khối `generate`.
- Git: nhánh theo khối, commit nhỏ, thẻ tag ở mỗi Gate; tệp log ghi phiên bản Vivado, Verilator, SoftPosit, seed.
- Mục tiêu Makefile: `lint`, `smoke`, `regress`, `cov`, `syn`, `ppa`, `asic`, `report`, `all`.

---

## 11. Quyết định, rủi ro và điều kiện triển khai

Cập nhật 08/10/2026. SPEC là hợp đồng; kết quả nghiệm thu phải dẫn tới log/summary. “Đã chốt” không đồng nghĩa đã triển khai RTL. Nội dung normative ở §4–§6 có ưu tiên hơn nhật ký thí nghiệm lịch sử trong phụ lục.

### 11.1 Điểm mơ hồ và quyết định hiện hành

| # | Vấn đề | Quyết định / hợp đồng | Trạng thái và phần còn lại |
| --- | --- | --- | --- |
| 1 | OPS, recurrence và rounding của [15]/[P] | RTL baseline dùng cfg_ops=0/1 và profile normative §5.4–§5.6. Predictor n=2/7-bit, RND/complement và paper_source_config là nghiên cứu riêng | PT2 PASS128 prefix dưới giả định đệm Q12; LUT/tie gốc còn mở. README L1 mục20 loại source Q24 không cut khỏi baseline bit-exact2021 bằng output Fig.4; muốn đưa profile paper vào RTL phải bổ sung contract/API và oracle riêng |
| 2 | Phân bố, seed và ngoại lệ Table I/II | Table I tái dựng dùng grid24 [0,1), FP32 RNE Ideal, seed271828, 200 triệu accepted. Generator/seed/filter là giả định dự án; phân tầng dùng coverage, không thay corpus paper | Source lịch sử đạt max0,984213 điểm % nhưng không khớp output Fig.4; không dùng kết quả này để nghiệm thu baseline gốc. Đối chiếu profile cut12 ở README L1 mục20; generator gốc và Table II còn mở |
| 3 | Cut/sticky trong SBM | ROUND_SCHEME=0 cắt ở FRAC_W; =1 giữ G/R và OR đuôi vào sticky riêng, theo §5.6. Sticky không tái tạo carry của tổng phần dư | Hợp đồng và L1 đã có; cần test RTL đúng điểm cắt, không gọi STICKY_ACC là exact |
| 4 | Độ rộng accumulator | Approx normative ACC_W=FRAC_W+4 là lựa chọn dự án; exact 2*FRAC_MAX+2. Research `fig3` giữ fraction12/payload13+carry/guard0; source guard12 giữ riêng làm control | README L1 mục19/20: fig3 chức năng PASS, TableI max1,2923195 điểm %; guard12/cut12 khớp output Fig.4 nhưng max1,338773, chưa đạt. Fig.5 hỗ trợ fraction đầu ra12, không xác minh guard hay mã hóa cờ nội bộ |
| 5 | m của hai toán hạng Table II | Giả định cả hai thuộc nhóm khảo sát; ideal là posit32 ES3 exact, không dùng L0 ES2 thay thế (§6.3) | Cần corpus, seed, conversion/filter và oracle ES3 trong báo cáo Table II |
| 6 | Baseline PACoGen/FP32/FP16 | Cùng ES, part, ràng buộc và tài nguyên khi so trực tiếp; khác thiết bị thì báo riêng theo §7.6 | PPA toàn MAC chưa đo; OPS riêng không thay cho Gate4 |
| 7 | TRUNC và RNE | ROUND_MODE là đóng gói; ROUND_SCHEME là cut/sticky nội bộ. TRUNC cắt độ lớn về 0; lỗi có dấu phụ thuộc dấu toán hạng | L1/round_unpacked và packer RTL RNE/TRUNC đã nghiệm thu đơn vị07/10; results/packer/summary.json |
| 8 | Số tầng và latency | Parser hai hạng đã kiểm. H, L_valid, L_handshake theo §5.1; packer RNE hai hạng là ngân sách mục tiêu, không phải tối thiểu đã đo STA | Parser E0→valid E1→handshake E2, II=1 đã kiểm; packer RNE P1/P2 đã kiểm latency/II/reset/stall ở đơn vị; sau tối ưu P2, khảo sát Quartus RNE fmax122,50–124,42MHz, ba seed đạt100MHz; các công thức toàn MAC chưa đo |
| 9 | Ý nghĩa n | cfg_n normative đếm fraction, hidden riêng; n_terms=n_fraction+1 chỉ chuyển bộ đếm của cùng chuỗi khai triển (§5.5/PB-04) | Đã khóa profile RTL. Khác recurrence/cut/OPS không được coi tương đương chỉ nhờ đổi n |
| 10 | Reset và lịch core | Reset bridge/startup barrier §4.2; n=0/init_only, first/last và drain theo §5.5. Baseline giữ một giao dịch, dự trữ một slot đầu ra | Hợp đồng đã chốt; bridge, core và tích hợp chưa có RTL/TB nghiệm thu |

### 11.2 Rủi ro hiện tại

| Rủi ro | Ảnh hưởng | Cách xử lý / điều kiện đóng |
| --- | --- | --- |
| Packer hoặc Adder RTL lệch L1 tại ties/clamp/cancellation | Cao | Packer tuần8 kiểm parser→packer và round; Adder RTL đối chiếu L1 đã qua Gate1B. L1 đúng không thay nghiệm thu RTL |
| Lệch một cạnh khi cộng số tầng | Cao | TB dùng E0, H, L_valid, L_handshake; kiểm n=0/1/2, early termination, bypass và bubble; không ép số đo vào công thức cũ |
| A/B/C hoặc metadata nhả reset/nhận giao dịch khác nhau | Cao | Reset bridge và startup barrier; nhận A/B/C nguyên tử; test reset rỗng, đang tính và output stall |
| Core_done sớm, khởi tạo hai lần hoặc mất token khi drain | Cao | Kiểm lịch §5.5; done chỉ sau last tại accumulator, init_only n=0 không cộng Y hai lần |
| Chồng lấn ghi đè accumulator, FIFO thiếu chỗ hoặc đọc C cũ | Cao | Baseline một giao dịch trước; sau đó chứng minh credit/capacity, ordering và hồi tiếp. Không ấn định FIFO6–8 hoặc II=max(1,n) như bảo đảm |
| Table I khớp corpus nhưng thiếu provenance/độ ổn định | Trung bình | Giữ nhãn tái dựng, công bố seed/profile và sensitivity; không chọn seed/width chỉ để ép khớp |
| Vivado không chạy tổng hợp/STA vì thiếu license | Cao đối với PPA | ModelSim dùng kiểm chức năng; Vivado compile/elaborate đã chạy cho parser nhưng không thay STA. Khôi phục license hoặc dùng luồng §7.6 và ghi rõ thiết bị/công cụ |
| Hết thời gian hoặc so PPA thiếu công bằng | Cao | Ưu tiên MAC v1/Gate2/3; cắt mở rộng theo §9; so cùng điều kiện và phân biệt OPS riêng với toàn MAC |
| Fused v2 mất đuôi có dấu/triệt tiêu sâu, ABS/LZC hoặc carry dài | Cao cho mở rộng | Chốt oracle/hợp đồng §5.12-c trước RTL v2; đo STA nếu triển khai. Giữ ngoài đường găng Gate1..3 |

### 11.3 Điều kiện sẵn sàng và thứ tự thực hiện

1. **Đã nghiệm thu mô hình số học:** Gate1, round_unpacked tương đương parse(pack(u)), Adder và MAC L1 v0/v1 Gate1B. Bằng chứng tại README L1 mục15 và results/week6_*; ES3 dùng oracle riêng, không gọi là L0 SoftPosit ES3.
2. **Đã nghiệm thu parser RTL đơn vị:** comb và pipeline bốn format, 2.465.812 fixture, 0 mismatch; reset/stall/ordering/II được kiểm ở parser. Bằng chứng results/parser_comb/, results/parser_pipeline/ và rtl/README.md mục5. Không suy thành Gate2/3 toàn MAC.
3. **Đã nghiệm thu packer RTL tuần8:** tổ hợp/pipeline RNE2/TRUNC1 và parser→packer đạt0 mismatch trên bốn format; F_IN/adapter theo §5.9-D. Tuần9 đã chốt giao diện §5.5-A và kiểm OPS/SAC tổ hợp327.440 vector ModelSim,0 mismatch; SBM/core/top standalone đã triển khai và kiểm pilot 09/10; Gate2 đã đạt lượt lớn/coverage chức năng, còn lint/harness chính thức theo PLAN L1 mục7. Paper RTL843 commit/Fig.4 đạt trong profile tái dựng, không xác nhận baseline gốc. Sau tối ưu P2, packer benchmark riêng đạt setup100MHz ở ba seed mỗi mode; tiếp tục STA khi tích hợp, không gọi là Gate4 hoặc fmax toàn MAC.
4. **Trước nghiệm thu tích hợp:** thực hiện reset bridge, startup barrier và lịch core §4.2/§5.5; TB đối chiếu cạnh, config, flags, metadata và slot output. Multiplier standalone đã có reset bridge, startup barrier và kiểm pilot; RTL MAC và nghiệm thu lớn/lint còn theo Gate2/3.
5. **Chồng lấn sau baseline:** thêm FIFO/credit và chứng minh lịch first/last, n=0/drain, acc feedback trước khi kết luận II/throughput. Sức chứa phải suy ra, không dùng skid2 để bảo đảm mọi giao dịch đang bay.
6. **Tái hiện/PPA và v2:** provenance Table I, corpus Table II và PPA toàn khối còn mở; ghi đúng giới hạn. Fused v2 là mở rộng, không chặn tuần8 hoặc baseline MAC v1.

---

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

## 12. Báo cáo và bảo vệ

**Cấu trúc báo cáo đề xuất**

1. Mở đầu: động lực, bài toán, đóng góp (C1..C5).
2. Cơ sở lý thuyết: posit, Mitchell/Babic, nhân lặp, các công trình liên quan.
3. Thiết kế: kiến trúc từng khối (theo §5), quyết định thiết kế và lý do.
4. Kiểm chứng: golden model 3 tầng, testbench, kết quả AC-01..AC-04, thống kê sai số.
5. Kết quả tổng hợp: PPA FPGA, so sánh baseline, phân tích §7.4, (EXT-A ASIC).
6. Thảo luận: sai khác so với paper, hạn chế, hướng phát triển (quire, fused, homomorphic encryption như [P] gợi ý).
7. Kết luận. Phụ lục theo SPEC: A (số liệu gốc [P]), B (giả định vector), C (kết quả tái hiện), D (truy vết), E (thuật ngữ); giao diện và log công cụ là phụ lục bổ sung của báo cáo.

**Bảng và đồ thị dữ liệu cần xuất từ script**: Correct Rate và Err theo n và nhóm regime; NMSE theo n; phân bố số vòng lặp thực tế; bảng PPA; Pareto (EXT-B); bảng tài nguyên theo module (hierarchical).

**Kịch bản demo 5 phút**: (1) `make demo` in một phép nhân mẫu qua các `n = 0,1,2,3,∞` với kết quả và Err; (2) chạy `make smoke`; (3) mở `results/summary.md`; (4) trình bày bảng PPA và cấu hình khuyến nghị.

---

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

## Phụ lục D. Ma trận truy vết

| Yêu cầu | Test case | Kết quả / bằng chứng |
| --- | --- | --- |
| FR-01 | TC-CFG-* | `results/regress_cfg.csv` |
| FR-02 | TC-CORNER-01..n | `results/corner.log` |
| FR-03 | TC-PARSE-EXH8, EXH16 | `results/parse.log` |
| FR-04 | TC-RND-*, TC-SAT-* | `results/pack.log` |
| FR-05 | TC-MUL-EXACT-* | `results/mul_exact.csv` |
| FR-06, FR-07 | TC-MUL-APPROX-*, TC-ITER-* | `results/mul_approx.csv` |
| FR-08 | TC-OPS-* | `results/ops.csv` |
| FR-09 | TC-ADD-EXH8, EXH16, RAND32 | `results/add.csv` |
| FR-10 | TC-MAC-* | `results/mac.csv` |
| FR-11 | TC-FUSED-* (nếu làm) | `results/fused.csv` |
| FR-12..FR-16 | TC-PROTO-*, TC-PIPE-*, SVA A-01..A-09 | `results/proto.log, results/pipe.csv` |
| NFR-02..05 | Báo cáo Vivado | `results/ppa.csv` |

(Cột giữa và cột phải cập nhật khi test được viết; mỗi hàng trống ở thời điểm nộp là một điểm trừ.)

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
