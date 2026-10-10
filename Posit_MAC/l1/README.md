# Tầng L1: Mô hình Thuật toán C++ (`l1/`)

**Hợp đồng tích hợp cập nhật 06/10/2026 — SPEC v1.4:** RTL baseline v0/v1 giữ profile L1 normative: cfg_ops=0/1, cfg_n đếm fraction, hidden khởi tạo riêng; paper_source_config/predictor7-bit là nghiên cứu riêng. H là ngân sách hạng thanh ghi; không bubble thì L_valid=H-1, L_handshake=H (E0 là input handshake). n=0 dùng token init_only; core_done=q+2 cạnh sau OPS launch, q=max(1,n), last chỉ hoàn tất ở accumulator. Top rst_n đồng bộ dùng reset bridge/startup barrier để phối hợp leaf reset_n và nhận A/B/C nguyên tử. Đây là hợp đồng triển khai, chưa nghiệm thu core/bridge/MAC RTL. Chi tiết và trạng thái tại [SPEC §4–§5 và §11](../SPEC_Posit_MAC_IP.md). Bước tiếp theo: packer tuần8, rồi core và tích hợp; chồng lấn sau baseline.

Thư mục này chứa mô hình thuật toán C++ tự phát triển (header-only, template tham số hóa theo `<int NB, int ES, int FRAC_W>`), tái hiện trung thực 100% từng bước biến đổi dữ liệu của kiến trúc phần cứng.

---

## 1. Cấu trúc Mô hình & Tiến độ Hiện tại

| Module | File Header | Trạng thái | Mô tả chức năng |
| :--- | :--- | :---: | :--- |
| **Kiểu dữ liệu** | [`posit_types.hpp`](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l1/include/posit_types.hpp) | ✅ Xong (Gate 1) | Cấu trúc `posit_unpacked<NB, ES>`, hằng số `SF_MAX`, `FRAC_MAX`, chế độ làm tròn `RNE`, `TRUNC`. |
| **`posit_parser`** | [`posit_parser.hpp`](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l1/include/posit_parser.hpp) | ✅ Xong (Gate 1) | Bù hai theo dấu, đếm LOD/LZD theo Fig. 5(a) của [P] (bỏ +1), căn chỉnh fraction chuẩn về bit 62/63. |
| **`posit_packer`** | [`posit_packer.hpp`](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l1/include/posit_packer.hpp) | ✅ Xong (Gate 1) | Đóng gói FloPoCo 10-step RNE với tiền kẹp `sf >= SF_MAX` (maxpos) và `sf < -SF_MAX` (minpos) + chế độ TRUNC. |
| **`round_unpacked`** | `include/round_unpacked.hpp` | ✅ Kiểm chứng riêng | Kết quả unpacked chuẩn tương đương parse(pack(u)) cho RNE/TRUNC; xét cả regime/exponent/fraction, canonicalize Zero/NaR và carry/bão hòa. |
| **`l1_multiplier_exact`** | [`l1_multiplier_exact.hpp`](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l1/include/l1_multiplier_exact.hpp) | ✅ Xong (Gate 1) | Nhân mantissa chính xác 128-bit, chuẩn hóa tích, kết hợp packer để đối chuẩn L0. |
| **`ops_sel`** | `include/ops_sel.hpp` | ✅ Kiểm chứng | cfg_ops=0 chọn X=A; cfg_ops=1 min-popcount fraction thực dùng, hòa chọn A; từ chối 2/3. |
| **`sac`** | `include/sac.hpp` | ✅ Kiểm chứng | LZD+1, tổng dịch S, mask fraction và early termination; n=0..N_MAX. |
| **`sbm`** | `include/sbm.hpp` | ✅ Kiểm chứng | FLOOR và STICKY_ACC; nhánh exact giữ 2*FRAC_MAX bit fraction. |
| **`mul_norm`** | `include/mul_norm.hpp` | ✅ Kiểm chứng | Dịch phải một bit khi acc>=2, tăng sf, gom bit mất vào sticky. |
| **Nhân lặp** | `include/l1_multiplier_iter.hpp` | ✅ Kiểm chứng chức năng | Trace từng bước, các cờ mất bit riêng; tái hiện Table I vẫn processing. |
| **`posit_add`** | `posit_add.hpp` | ⏳ Tuần 5 | Bộ cộng hai số unpacked với alignment shifter $\Delta sf \le \text{FRAC\_MAX} + 2$. |
| **`l1_mac`** | `posit_mac.hpp` | ⏳ Tuần 6 | MAC v0/v1 non-fused hai lần làm tròn; chưa triển khai. |
| **DPI-C Wrapper** | `dpi_c_mac.cpp` | ⏳ Tuần 6 | Wrapper xuất hàm C-linkage kết nối trực tiếp SystemVerilog testbench. |

---

## 2. Tiêu chí Nghiệm thu & Kết quả Kiểm định Gate 1 (§6.1 SPEC)

- **Kế hoạch chi tiết**: Xem [l1/PLAN.md](file:///c:/HCMUT/HK261/Đồ%20án%202/Posit_MAC/l1/PLAN.md).
- **Kết quả nghiệm thu Gate 1 (Tuần 3)**:
  - **Roundtrip Identity (`pack(parse(p)) == p`)**:
    - Posit8 ($ES=0$): **256 / 256** (100% Khớp bit-exact, 0 mismatch).
    - Posit16 ($ES=1$): **65,536 / 65,536** (100% Khớp bit-exact, 0 mismatch).
    - Posit32 ($ES=2$): **1,000,012 / 1,000,012** (100% Khớp bit-exact, 0 mismatch).
  - **L1 Multiplier Exact vs SoftPosit L0**:
    - Posit8 ($ES=0$): **65,536 / 65,536** cặp vét cạn (100% Khớp bit-exact, 0 mismatch).
    - Posit32 Corner List (§6.4): **13 / 13** vector (100% Khớp bit-exact).
    - Posit16 ($ES=1$): chế độ nghiệm thu vét cạn **4,294,967,296** cặp; chế độ smoke chỉ lấy mẫu 1,000,000 cặp.
    - Posit32 ($ES=2$): chế độ nghiệm thu **10,000,000** cặp phân tầng, seed **314159**; 256 ô nhóm regime × nhóm regime × cặp dấu, mỗi ô ≥ 4000 cặp; mọi độ dài regime hữu hạn được kích hoạt ≥ 10,000 lần. Có kiểm tra mật độ fraction, polarity regime và identity trên toán hạng phân tầng.
  - **Bằng chứng nghiệm thu hiện tại**: xem [`gate1_acceptance.log`](../results/gate1_acceptance.log) và [`gate1_build.log`](../results/gate1_build.log). Log cũ `gate1.log` chỉ ghi bộ test lấy mẫu trước đây.
  - **Kết quả**: ✅ Gate 1 theo SPEC §6.1; 0 mismatch. Linux vét cạn toàn miền posit16 trong 87,08 giây, 10 triệu posit32 trong 2,69 giây; identity posit8/16 vét cạn và posit32 lấy mẫu đạt. Linux/Windows đều đạt identity trên 20 triệu lượt toán hạng posit32 phân tầng. Windows đã chạy 10 triệu cặp posit32 và hai lô posit16; xem [`gate1_windows_verified.log`](../results/gate1_windows_verified.log).
  - **`round_unpacked` kiểm chứng riêng:** 4.954.184 đối chiếu trên Linux và Windows, 0 mismatch; UndefinedBehaviorSanitizer cũng đạt. Test so toàn bộ sáu trường unpacked và tính idempotent, phủ posit8/16 toàn miền bitstring, mọi sf trong/giáp biên với mẫu tie/carry, 700.000 unpacked ngẫu nhiên cho (8,0)/(16,1)/(32,2)/(32,3), cả RNE/TRUNC và exact/sticky. Có ca exponent thiếu bit, Zero/NaR với payload bẩn và sf INT32_MIN/MAX. Kiểm sản phẩm đã round với SoftPosit: posit8 vét cạn, posit16/32 mỗi cấu hình 100.000 cặp; seed cơ sở 20261003, seed unpacked = cơ sở + NB×16 + ES, seed product = cơ sở + NB. Xem `results/round_unpacked_verified.log`, `round_unpacked_windows.log`, `round_unpacked_ubsan.log`.
  - Hàm mới dùng luồng bit hữu hạn rồi khôi phục sf/fraction chuẩn, không gọi pack/parse bên trong và không dịch 64 bit. Đây là mô hình C++ đúng chức năng, chưa chứng minh độ trễ một chu kỳ hoặc PPA cho RTL round_unpacked. `out.exact=true` nghĩa là đầu ra không còn đuôi số học; cờ inexact giao dịch cần lưu riêng khi triển khai MAC.
  - Regression sau sửa parser/round: `results/gate1_after_round_unpacked.log`, identity và toàn bộ Gate 1 đạt; posit16 vét cạn 4.294.967.296 cặp trong 130,59 giây, posit32 phân tầng 10 triệu cặp trong 3,71 giây, 0 mismatch. Tuần 3 hoàn thành; chưa có Adder hay MAC tích hợp.

---

## 3. Hướng dẫn Biên dịch & Chạy Kiểm thử

### Trên Linux / WSL
```bash
cd l1
make linux       # Build toàn bộ bộ kiểm thử L1 hiện có
make test        # Smoke: 1 triệu cặp posit16/32, không chốt Gate 1
make gate1       # Identity + mul posit8/16 vét cạn + 10 triệu posit32
make gate1-p32   # Chỉ corner và 10 triệu cặp posit32 phân tầng
make gate1-p16-range P16_START=0 P16_END=4096  # A=[0,4096), B=[0,65536)
make test-round  # Bộ test tương đương round_unpacked
make test-round-ubsan # Cùng bộ test, phát hiện undefined behavior, lỗi trả code khác 0
make test-week4 # TV-ITER/TV-PAPER, oracle approximate và iterative exact
make test_table1 # 10 triệu cặp/n; trả code 1 khi Table I chưa đạt
./test_table1_reproduce --samples 10000000 --seed 314159 --ops 1 --scheme floor --ideal fp32
./test_table1_reproduce --samples 10000000 --seed 314159 --ops 1 --scheme floor --distribution stratified --ideal posit
```

Test posit16 in `CHECKPOINT next_A=...` sau mỗi 256 giá trị A. Nếu bị gián đoạn, chạy tiếp từ `P16_START=next_A`; giữ log cũ và bảo đảm các khoảng A hợp lại phủ `[0,65536)` không có khoảng trống. Chỉ các checkpoint có `failures=0` mới xác nhận phần đã chạy. Một lô riêng luôn in `SELECTED TESTS PASSED`, không được xem là nghiệm thu toàn Gate 1.

Có thể thay seed bằng `P32_SEED=...`. Generator dùng `mt19937_64`, chu kỳ nhóm/dấu xác định và fraction/exponent ngẫu nhiên; các mẫu fraction ép gồm toàn 0, toàn 1, xen kẽ và popcount thấp. Mật độ fraction được đo bằng quét bit độc lập parser; nhóm 0..5 lần lượt là 0, 1, 2, 3–4, 5–8, >8 bit 1. `rc=0,m=31` là zero, không thể sinh như số hữu hạn khác 0; zero được kiểm trong corner suite. Phân tầng phục vụ kiểm chứng cấu trúc, không đại diện phân bố dữ liệu ứng dụng để tính Err/MSE.

### Trên Windows (PowerShell / CMD)
```powershell
cd l1
# Sử dụng trực tiếp các file thực thi đã biên dịch sẵn:
.\test_identity.exe
.\test_mul_exact.exe
.\test_mul_exact.exe --gate1 --seed 314159
.\test_mul_exact.exe --p32-only --samples 10000000 --seed 314159
.\test_mul_exact.exe --p16-start 4096 --p16-end 8192
.\test_round_unpacked.exe
.\test_tv_paper.exe
```

Hoặc biên dịch chéo từ WSL:
```bash
make windows     # Sinh test_identity.exe và test_mul_exact.exe (statically linked)
```

## 4. Kết quả tuần 4 — 04/10/2026

API: `L1MultiplierIter<NB,ES,FRAC_W,N_MAX,EXACT_EN,OPS_EN>::mul(a,b,cfg,&trace)` trả `IterResult`. Cấu hình chuẩn được kiểm: (8,0), (16,1), (32,2), (32,3). `IterConfig` mặc định approximate, n=2, OPS=0, FLOOR, TRUNC; nhánh exact cần đặt exact=true và rounding=RNE khi đối chuẩn L0. n chỉ giới hạn approximate, không chặn 27 bước của exact posit32 ES2. Profile FLOOR dùng Q=FRAC_W; hai vị trí G/R trong biểu diễn phần cứng tương đương bằng 0. Trace acc là số nguyên theo Q này; STICKY_ACC dùng Q=FRAC_W+2, exact dùng Q=2*FRAC_MAX.

`unpacked.exact` chỉ điều khiển sticky số học khi pack. Mất input do cắt FRAC_W và bỏ các số hạng do giới hạn n được ghi `input_cut/approx_cut/inexact`, không tự đưa lại phần đã bỏ vào phép làm tròn profile. Hoàn tất SAC không bảo đảm tích toán học chính xác. Mô hình chưa mô phỏng handshake, backpressure hoặc độ trễ chu kỳ RTL.

Kiểm chứng Linux/Windows và UBSan: **5.940.303 đối chiếu**, seed 314159, 0 mismatch. Bao gồm hai TV, oracle cộng các vị trí bit độc lập (vét cạn fraction 4 bit và 200.000 cặp cho mỗi cấu hình), cả OPS/scheme/RNE/TRUNC, cờ input_cut/approx_cut/inexact, bypass NaR/Zero, saturation, cấu hình bị từ chối và exact vượt N_MAX. Iterative exact: posit8 65.536 cặp vét cạn; posit16 và posit32 ES2 mỗi cấu hình một triệu cặp so L0 và nhân rộng; posit32 ES3 một triệu cặp so nhân rộng, **không dùng SoftPosit ES2 làm oracle ES3**. Phạm vi này không thay thế nghiệm thu Gate 1 đầy đủ của bộ nhân exact cũ.

Log: `results/week4_verified.log`, `week4_windows.log`, `week4_ubsan.log`; compiler/SoftPosit/lệnh/hash tại `week4_build.log`, `week4_metadata.log`, `week4_sources.sha256`, `week4_binaries.sha256`.

Table I: NB=32, ES=3, FRAC_W=12, n=1..6, seed 314159; **10 triệu cặp cho mỗi hàng** và cùng cặp đầu vào giữa các n. Err=abs(result-Ideal)/abs(Ideal), xét nghiêm ngặt Err<0.1/0.5/1/5%. Input dương khác 0:

- FP32: sf đều [-120,119], fraction 23 bit đều, đổi sang posit bằng RNE, loại m>15; Ideal là tích toán học chưa làm tròn của FP32 gốc. Không loại theo scale của tích.
- Phân tầng posit: 900 ô mA,mB=1..15 × hai polarity regime mỗi toán hạng, 11.111–11.112 cặp/ô; exponent/fraction ngẫu nhiên; Ideal là tích toán học chưa làm tròn của posit đã giải mã. Đây là phép đo độ nhạy, không khẳng định tái tạo bộ dữ liệu gốc [P].

| Profile | Sai lệch tối đa n=2..4 so Proposed (điểm %) | Kết quả |
| --- | ---: | --- |
| FP32, OPS=0, FLOOR/TRUNC | 56,825780 | Chưa đạt |
| FP32, OPS=1, FLOOR/TRUNC | 39,759950 | Chưa đạt |
| Phân tầng, OPS=1, FLOOR/TRUNC | 39,766460 | Chưa đạt |
| FP32, OPS=1, STICKY_ACC/TRUNC | 34,582500 | Chưa đạt; scheme riêng của đề tài |

Xem `results/week4_table1_floor.log`, `week4_table1_ops1.log`, `week4_table1_stratified.log`, `week4_table1_sticky.log`. **Tuần 4 vẫn processing** vì ngưỡng ≤1 điểm % chưa đạt. Chưa xác định nguyên nhân đủ để sửa thuật toán: cần đối chiếu chính sách OPS/rounding của [15], phân bố và điều kiện dải SPFP áp dụng cho tích, độ rộng accumulator thực nghiệm. Không suy từ sai khác rằng chỉ phân bố là nguyên nhân. Công cụ có `--require-match` để biến thiếu mẫu hoặc sai lệch thành exit code khác 0; mặc định exit 0 chỉ nghĩa thí nghiệm đã hoàn tất.

## 5. Đọc lại tài liệu [15] — phương pháp đo và công thức (04/10/2026)

Nguồn: Kim & Rutenbar, *An Area-Efficient Iterative Single-Precision Floating-Point Multiplier Architecture for FPGA*, GLSVLSI 2019; file PDF cùng thư mục dự án. Đã đọc đủ sáu trang, đặc biệt Algorithm 1, §3.1–3.3 và §4.1. Mục này ghi nhận tài liệu, chưa thay hợp đồng FLOOR/STICKY_ACC của SPEC và chưa sửa mã nguồn.

### 5.1 Dữ liệu, seed và trường hợp đặc biệt

- §4.1 (trang PDF 5 / trang in 91): đánh giá **200 triệu phép nhân trên các số SPFP ngẫu nhiên trong khoảng 0 đến 1**. Paper không nói rõ phân bố đều theo giá trị, đều theo bit hay phân bố exponent; không công bố PRNG, seed, cách ghép cặp hoặc quy tắc lấy các đầu mút. Vì vậy không được ghi “uniform(0,1)” như một thông tin đã được paper xác nhận.
- Table 3 của [15] có các dòng BASE, BASE+RND, BASE+RND+TRNC+SEL. Dòng cuối đúng các số của Kim [15] trong Table I bài posit: n=2: 9,30/32,12/50,01/95,58; n=3: 43,94/83,01/95,03/100; n=4: 86,69/99,81/100/100. Vì thế cột Kim đối chiếu là **đầy đủ rounding + truncation + operand selection**, không phải BASE.
- §3.3 (trang PDF 4 / trang in 90) nêu zero flag khi input bằng 0, break flag khi mantissa phần dư bằng 0 và overflow flag của adder/subtractor mantissa. Overflow này phục vụ chuẩn hóa exponent/mantissa, không đủ để kết luận về xử lý IEEE Inf/NaN/overflow/underflow.
- Không thấy công bố đầy đủ chính sách NaN, Inf, subnormal, signed zero, denominator bằng 0 trong thống kê Err hoặc cách lọc overflow/underflow đầu ra. Đánh giá 0..1 không kích hoạt toàn bộ miền FP32. Zero có xử lý trong datapath nhưng cách đếm trường hợp Ideal=0 trong correct rate chưa được mô tả.
- Bài posit [P] bổ sung điều kiện m<=15 khi chuyển SPFP sang posit32 ES3. Không có câu xác nhận tường minh rằng bộ vector/seeds của [P] trùng hoàn toàn [15]; khoảng 0..1 của [15] là căn cứ quan trọng để khảo sát lại, không tự biến thành generator gốc đã được phục hồi.
- Seed 314159 và phân bố sf [-120,119] trong log tuần 4 là lựa chọn của dự án; đặc biệt phân bố này có nhiều input >1, nên **không tái tạo miền đánh giá 0..1 của [15]**.

### 5.2 Số FP32 và xấp xỉ BASE

Với số FP32 normal (không áp dụng trực tiếp cho zero/subnormal/NaN/Inf), đặt E là exponent lưu trữ, F là fraction:

\[
x=(-1)^s(1+F)2^{E-127},\qquad F=\sum_{j=1}^{23}b_j2^{-j}.
\]

Viết lại Eq. (8)–(9) bằng phần dư để tránh nhầm chỉ số:

\[
r_0=|x|,\quad a_0=0,\quad
\ell_i=\lfloor\log_2 r_{i-1}\rfloor,\quad
a_i=a_{i-1}+2^{\ell_i},\quad
r_i=r_{i-1}-2^{\ell_i}.
\]

Nếu r=0 thì dừng. AP_n(x)=sign(x)*a_n. **n của Algorithm 1 là tổng số số hạng lũy thừa hai, gồm cả số hạng đầu tiên**, không mặc định là n bit fraction cộng thêm hidden bit. L1 hiện nạp Y trước rồi chạy n số hạng fraction, nên cần đối chiếu lại cách ánh xạ n trước khi so Table I; không suy rằng Fig. 4 của [P] tự giải quyết toàn bộ khác biệt chỉ số này.

### 5.3 Rounding Scheme — Algorithm 1

Công thức toán học trong Algorithm 1 chọn lũy thừa bằng cách làm tròn log2 của độ lớn phần dư, rồi có thể cộng **hoặc trừ**:

\[
r_0=|x|,\quad a_0=0,\quad
q_i=\log_2|r_{i-1}|,\quad
f_i=\operatorname{round}(q_i-\lfloor q_i\rfloor),\quad
\ell_i=\lfloor q_i\rfloor+f_i,
\]
\[
\sigma_i=\operatorname{sign}(r_{i-1}),\qquad
a_i=a_{i-1}+\sigma_i2^{\ell_i},\qquad
r_i=r_{i-1}-\sigma_i2^{\ell_i},\qquad
AP_n(x)=\operatorname{sign}(x)a_n.
\]

Dừng trước khi tính log nếu phần dư bằng 0. f=1 có thể làm phần dư đổi dấu. Đây là **rounding của quá trình xấp xỉ toán hạng**, khác với RNE cuối packer hoặc giữ sticky khi dịch SBM.

Mô tả phần cứng §3.1 đơn giản hóa việc chọn f: ngưỡng toán học sqrt(2) đối với mantissa được thay bằng 1,5; f chính là bit fraction cao nhất (bit thứ 22 tính từ LSB của trường 23-bit). Do đó, với phần dư normal có exponent E_i:

\[
f_i=\begin{cases}0,&1\le M_i<1.5\\1,&1.5\le M_i<2\end{cases},
\qquad
\ell_i=\begin{cases}E_i-127,&f_i=0\\E_i-126,&f_i=1\end{cases}.
\]

Eq. (11)–(12) chuẩn hóa phần dư tiếp theo:

\[
M_{i+1}=t_i2^{z_i+1},\qquad E_{i+1}=E_i-z_i-1.
\]

z_i là số bit 0 trước bit 1 đầu tiên của t_i. Khi f=0, t lấy mantissa với hidden bit bỏ đi; khi f=1, paper hình thành t từ mantissa âm và dùng complement operator để xấp xỉ phép phủ định. Cần mô hình hóa đúng độ rộng/complement của phần cứng trước khi tuyên bố bit-exact; công thức phần dư số thực ở trên chỉ giải thích Algorithm 1.

Ví dụ Table 1 [15]: x=0,4656868; n=3:
\[
AP_3(x)=2^{-1}-2^{-5}-2^{-8}=0.46484375.
\]
BASE ở cùng n:
\[
AP^{BASE}_3(x)=2^{-2}+2^{-3}+2^{-4}=0.4375.
\]
Ví dụ này cho thấy thiếu cộng/trừ theo phần dư có thể tạo sai khác lớn dù SAC quét bit và SBM floor đúng hợp đồng hiện tại.

### 5.4 Operand Selection và truncation

§3.2 chọn toán hạng có **sai số xấp xỉ dự đoán nhỏ hơn**, sử dụng bảng dự đoán mẫu mantissa; **không phải min-popcount**. Theo cách biểu diễn mantissa chuẩn hóa trong paper, có thể ghi lại nguyên tắc dưới dạng:

\[
\widehat\epsilon_X=|M_X-\widehat{AP}(M_X)|,\qquad
\widehat\epsilon_Y=|M_Y-\widehat{AP}(M_Y)|,
\qquad X_{selected}=\arg\min_{X,Y}\widehat\epsilon.
\]

Đây là ký hiệu tổng quát diễn giải nguyên tắc dự đoán, không phải công thức đóng thay cho bảng bit-pattern của paper; không khẳng định nó tối ưu sai số tương đối cho mọi cặp. Quy tắc tie không được công bố rõ.

Profile triển khai dùng **một bảng dự đoán cho n=2** ngay cả khi chạy n=3/4. Hai input bỏ 11 bit fraction thấp (23 còn 12). Đường dự đoán bỏ thêm 5 bit, chỉ dùng **7 bit fraction cao**. Table 2 minh họa bảng n=3; không được lấy bảng minh họa đó làm cấu hình thực nghiệm cuối. Table 4 xác nhận lựa chọn bảng n=2/input size=7.

Công thức cắt fraction có thể viết:
\[
F_{12}=\frac{\lfloor 2^{12}F\rfloor}{2^{12}},
\qquad F_{7}=\frac{\lfloor 2^7F\rfloor}{2^7}.
\]

Nhân một toán hạng đã xấp xỉ:
\[
\widetilde P_n=Y\cdot AP_n(X)
=\operatorname{sign}(X)\sum_{i=1}^{n}\sigma_iY2^{\ell_i}.
\]
Đây là biểu diễn số học; phần cứng còn cắt bit, align exponent, normalize và xử lý dấu hai toán hạng.

### 5.5 Công thức đo accuracy

Table 3 [15] in:
\[
Err_j(\%)=100\frac{|Ideal_j-Approx_j|}{Ideal_j}.
\]
Đánh giá dùng input 0..1 nên Ideal không âm; công thức chưa xác định cách xử lý Ideal=0.

Với N=200.000.000 phép nhân hợp lệ và ngưỡng tau theo đơn vị phần trăm, công thức correct rate diễn giải từ mô tả paper:
\[
CorrectRate(\tau)=\frac{100}{N}\sum_{j=1}^{N}
\mathbf 1\{Err_j(\%)<\tau\}.
\]
Table 3 [15] dùng tau=0,1/0,5/1/5/10%; Table I [P] dùng bốn ngưỡng đầu. Figure 3 [15] dùng normalized accuracy = correct rate khi truncation / correct rate khi không truncation, cùng ngưỡng Err<0,1%.

Theo Figure 6(a) [P], Ideal là **kết quả bộ nhân SPFP thông thường trên input FP32 gốc**; cần mô phỏng làm tròn FP32 thay cho tích số thực chưa làm tròn đang dùng trong tool tuần 4.

### 5.6 Những việc cần sửa trước phép tái hiện tiếp theo

1. Chọn và ghi rõ generator 0..1; không gán seed/phân bố cụ thể cho paper khi chưa có nguồn.
2. Sửa oracle FP32, quy tắc Ideal=0/subnormal và miền đếm N; đây là quyết định của dự án cần tách khỏi điều paper công bố.
3. Thêm profile paper RND với số hạng có dấu và OPS bảng dự đoán n=2/7-bit; giữ FLOOR/STICKY_ACC đã kiểm chứng như các profile riêng.
4. Xác minh cách đếm n giữa Algorithm 1 [15], Fig. 4 [P] và API L1; kiểm ví dụ 0,4656868 trước khi chạy thống kê.
5. Chỉ chạy 200 triệu phép nhân để nghiệm thu sau khi đối chiếu các điểm thuật toán trên. Tăng số mẫu đơn thuần không sửa được thiếu RND/SEL.


## 6. Baseline RND/SEL và ứng viên cải tiến đã kiểm chứng — 04/10/2026

**Kết luận:** đã triển khai baseline thuật toán theo [15] với các giả định minh bạch, giữ profile FLOOR/STICKY_ACC cũ riêng. Cột Kim [15] đạt sai lệch tối đa 0,942710 điểm % trong thí nghiệm chính; cột Proposed [P] còn lệch tối đa 1,352910 điểm %, chưa đạt ngưỡng tuần 4 <=1 điểm %. Không gọi baseline này là bản sao bit-exact của RTL gốc, vì paper chưa công bố toàn bộ LUT dự đoán/accumulator và bộ dữ liệu.

### 6.1 Profile và kiểm chứng

- Header mới: `include/paper_multiplier.hpp`. `PaperMultiplier<32,3,12>::mul(a,b,cfg,&trace)`; n=1..8 đếm tổng số số hạng, không cộng hidden bit riêng ngoài n.
- SAC dùng ngưỡng 1,5, số hạng có dấu và complement fraction ở độ rộng 12. Có tùy chọn complement=false để kiểm mô hình phần dư toán học; thống kê chính dùng complement=true.
- PaperOps và POLICY của khối khảo sát không thay thế ngữ nghĩa cfg_ops hiện có trong SPEC; mapping kiến trúc sẽ được khóa sau.
- Baseline OPS là LUT 128 phần tử được tái dựng bằng hai bước RND trên bảy bit fraction. Tie chọn A. Đây là lựa chọn tái dựng được kiểm chứng, không phải LUT nguyên bản do tác giả cung cấp.
- Accumulator giữ 12 bit fraction; mỗi số hạng dịch được FLOOR rồi cộng/trừ, normalize và pack TRUNC. Độ rộng/cut này là giả định của dự án. Không tự thêm residual đã bỏ thành sticky cuối pack.
- Variant chỉ đổi OPS sang min-popcount trên 12 bit fraction; mọi quy tắc RND/complement/cut/n/pack và input giữ nguyên.
- `test/test_paper_baseline.cpp`: **531.039 đối chiếu** trên Linux/Windows/UBSan, seed 314159, 0 mismatch. Vét cạn 4096 fraction, n=1..8, cả complement/ideal residual; đối chiếu grid Q96 độc lập, toàn bộ 128 entry OPS và 100.000 cặp SBM. Có bypass, dấu, saturation, early stop, cấu hình lỗi.
- Ví dụ [15] AP3(0,4656868)=0,46484375 khớp. Fig.4 [P] cũng khớp packed output: hai bước fraction + hidden term = ba tổng số hạng của API mới, trace power tương đối 0/-2/-5. Trace power lưu tương đối với sf của X; khi so Eq.10 phải cộng sfX.
- Oracle FP32 có 8 ca biết trước: ties RNE lên/xuống, normal/subnormal, minsub về zero, zero và dấu. 100.000 phép FP32->posit identity cho generator uniform-value đạt (seed 20261004).

Lệnh từ `Posit_MAC/l1`:
~~~bash
make test-paper
make test_paper_baseline_ubsan
./test_paper_baseline_ubsan
make test_paper_table1
./test_paper_table1 --samples 200000000 --seed 314159 --require-match
~~~
Lệnh cuối hiện trả **exit 1** vì Table I Proposed chưa đạt; `make paper-table1` cũng kiểm điều kiện đó. Tool cũ `test_table1_reproduce` giữ để tái lập log lịch sử, không còn là phép đo baseline mới.

### 6.2 Phương pháp đo đã sửa

Generator chính: lấy 24 bit ngẫu nhiên bằng mt19937_64, x=k/2^24 trong [0,1); đây là giả định uniform theo giá trị trên grid, **không phải phân bố/seed được paper công bố**. Chuyển input sang posit32 ES3 bằng RNE, yêu cầu m<=15. Ideal là nhân FP32 thực sự (volatile float, FE_TONEAREST), không còn dùng tích số thực chưa làm tròn.

N đếm cặp hợp lệ; loại input zero hoặc FP32 Ideal=0 để tránh chia 0, ghi riêng số loại. **200.000.000 cặp/hàng**, cùng dữ liệu cho n=2/3/4 và hai OPS; 200.000.023 cặp thử, 23 cặp input zero bị loại, không loại m hoặc Ideal=0 trong thí nghiệm chính. Error và correct rate dùng strict <.

| n | Baseline: <0,1 / <0,5 / <1 / <5% | Min-popcount: <0,1 / <0,5 / <1 / <5% | Max lệch Proposed, baseline (điểm %) |
| --- | --- | --- | ---: |
| 2 | 8,714937 / 31,177290 / 49,285731 / 95,463330 | 4,076841 / 16,169171 / 27,776557 / 78,862271 | 1,155063 |
| 3 | 43,337090 / 82,859994 / 94,981795 / 100 | 26,717347 / 64,894407 / 84,324390 / 100 | 1,352910 |
| 4 | 86,286286 / 99,797782 / 100 / 100 | 72,468581 / 99,273909 / 100 / 100 | 0,803714 |

Số vòng trung bình baseline/minpop: n=2: 1,999128/1,999511; n=3: 2,988699/2,993647; n=4: 3,941820/3,965809. Min-popcount không giảm số bước RND trung bình trong bộ dữ liệu này.

Độ nhạy: `--distribution uniform-bits` chọn bit pattern FP32 trong [0,1), rồi lọc m và Ideal=0. Chạy một triệu cặp hợp lệ: baseline lệch tối đa **9,084900 điểm %**; 166.271 cặp bị loại m, 390.972 cặp bị loại Ideal=0. Đây chỉ là khảo sát phân bố, không đủ số mẫu nghiệm thu. Khác biệt xác nhận generator ảnh hưởng đáng kể; không chứng minh nó là nguyên nhân duy nhất của sai lệch.

Log: `results/paper_table1_200m.log`, `paper_table1_sensitivity.log`, `paper_table1_windows.log`, `paper_baseline_verified.log`, `paper_baseline_windows.log`, `paper_baseline_ubsan.log`, `paper_baseline_regression.log`.

### 6.3 Đo phần cứng riêng OPS

`rtl/ops_compare_top.sv` có hai policy trên cùng ranh giới register; min-popcount dùng cây cộng cân bằng. `tb/tb_ops_compare.sv` kiểm 116.384 cặp bằng ModelSim 10.1d: toàn bộ 128x128 cặp prefix và 100.000 cặp fraction 12 bit (xorshift32, seed 314159). Cả hai policy đạt, kể cả reset/tie.

Quartus II 13.0.1 Web Edition, Cyclone IV E **EP4CE22F17C6**, clock 10 ns, seed 1/2/3, model Slow 1200mV 85C:

| OPS | Combinational functions (LUT4) | Registers | Fmax seed 1/2/3 (MHz) |
| --- | ---: | ---: | --- |
| Predictor n=2, 7 bit | 73 | 15 | 198,18 / 206,06 / 204,67 |
| Min-popcount 12 bit, cây cân bằng | 63 | 25 | 220,90 / 200,72 / 200,40 |

Min-popcount giảm **13,70% LUT4**, tăng 10 FF trong khối độc lập. Khoảng fmax chồng lấn và variant dao động trên 10% giữa seed; **không kết luận luôn nhanh hơn**. Số FF baseline thấp hơn vì synthesis loại các bit input không dùng; khi tích hợp vào MAC, register fraction có thể được dùng chung nên không suy nguyên chênh lệch FF này sang full MAC.

Đây là khảo sát **OPS đơn vị**, không phải RTL nhân/MAC hoàn chỉnh hay Gate 2. LUT4 Cyclone IV không đồng nhất LUT6 Virtex của paper. Clock chỉ ràng buộc domain register-register; pin tự gán và timing I/O chưa ràng buộc cho board thật. Fmax là thước đo nội bộ khảo sát, chưa là sign-off của hệ thống. DSP/memory=0 ở cả hai.

Chạy lại:
~~~powershell
./Posit_MAC/scripts/run_ops_compare.ps1
~~~
CSV: `results/ops_ppa_summary.csv`; report và QSF/SDC từng seed: `results/ops_ppa/`. Bản popcount chuỗi cộng ban đầu dùng 75 LUT4, đã thay bằng cây cân bằng và chạy lại simulation/sáu fit; số trong bảng là bản cuối.

### 6.4 Quyết định cho đồ án

Có thể trình bày variant như **đánh đổi giảm LUT**, không phải tăng độ chính xác hay tốc độ ở mọi trường hợp. Ở n=4, ngưỡng Err<1%, cả hai đạt 100% trên 200 triệu mẫu; nhưng Err<0,1% giảm từ 86,286286% xuống 72,468581%. Ở n=3, Err<5% đều 100%, còn Err<1% giảm rõ. Đây là số đo trên bộ mẫu, không phải bảo đảm toán học cho mọi đầu vào.

Baseline và ứng viên cải tiến đã có code/test/đo riêng. Tuần 4 vẫn **processing** do tiêu chí Proposed Table I <=1 điểm % chưa đạt và còn các giả định tái dựng. Việc tiếp theo: xác minh predictor/cut và cách đếm n theo bản RTL gốc nếu có, khóa profile chính thức trước khi triển khai full multiplier/adder/MAC. Không thay đổi tham số chỉ để ép số liệu khớp.

## 7. Hoàn thiện riêng bước 2 OPS — 04/10/2026

OPS đã tồn tại trong baseline mục 6; đợt này tách thành `include/paper_ops.hpp`, dùng lại trong `paper_multiplier.hpp` và bổ sung giao diện FP32/kiểm chứng vét cạn.

Hợp đồng cố định:
- Fraction FP32 normal có 23 bit: giữ `fraction[22:11]` (12 bit), cắt đúng `fraction[10:0]` (11 bit); giữ nguyên sign/exponent.
- Predictor lấy `fraction[22:16]`, tương đương 7 bit cao của fraction12; 5 bit thấp còn lại không ảnh hưởng quyết định.
- Bảng có 128 entry, luôn dự đoán **n=2**, độc lập n=1..8 của multiplier.
- So sánh error dự đoán, chọn B làm X chỉ khi errorB<errorA; hòa giữ A. LUT vẫn là tái dựng bảy-bit complement, tie-A là giả định dự án đã ghi, không tuyên bố LUT gốc của tác giả.

API:
~~~cpp
auto selection = l1::paper_ops_select<12>(fraction_a12, fraction_b12);
auto prepared  = l1::paper_prepare_fp32(raw_fp32_bits);
auto decision  = l1::paper_ops_fp32(raw_a_bits, raw_b_bits);
~~~
`selection` trả index/error của A/B, swapped/tie. `prepared` trả bitstring gốc, bitstring đã cắt, fraction12/prediction7 và phân loại. Zero/subnormal/Inf/NaN được báo bypass, giữ nguyên bit/payload; **đây không phải hiện thực đầy đủ phép nhân IEEE hoặc quy tắc xử lý các giá trị đó trong paper**.

Tool Table I tiếp tục dùng FP32 gốc cho Ideal và chuyển định dạng trước khi cắt fraction của posit. Self-test đã đối chiếu rằng trên generator uniform-value, fraction12 sau parse posit bằng fraction FP32 sau cắt 11 bit; không cắt đầu vào của oracle.

`test/test_paper_ops.cpp` đạt **33.587.337 đối chiếu/nền tảng** trên Linux/Windows/UBSan, 0 mismatch:
- Oracle phần dư Q24 độc lập cho toàn bộ 128 LUT entry.
- Toàn bộ 4096x4096 cặp fraction12: quyết định, tie và bất biến đối với 5 bit thấp.
- Toàn bộ 2^23 mẫu fraction FP32: cắt 11 bit, giữ sign/exponent và quyết định FP32 OPS; đại diện nhiều exponent normal/cả dấu.
- Special-class bypass/payload; kiểm predictor luôn n=2 qua 4096 input x n=1..8; chặn fraction12 vượt miền.
- Baseline regression 531.039 đối chiếu đạt. Smoke Table I 100.000 cặp dùng seed 314159 cho cùng tỷ lệ như trước khi tách module.

Chạy:
~~~bash
make test-paper-ops
make test_paper_ops_ubsan
./test_paper_ops_ubsan
~~~
Bộ mới đã vào `make test`/`make test-paper`, build Linux/Windows và script rebuild.
Log: `results/paper_ops_step2_verified.log`, `paper_ops_step2_windows.log`, `paper_ops_step2_ubsan.log`, `paper_ops_step2_regression.log`, `paper_ops_step2_table1_smoke.log`; compiler/lệnh/hash tại `paper_ops_step2_metadata.log` và manifests.

Đợt này không đổi LUT truth table, RND/SBM hoặc RTL; kết quả 200 triệu/PPA mục 6 là bằng chứng lịch sử của cùng thuật toán, không phải lượt chạy lại mới. Bước 2 kiểm chứng chức năng hoàn thành; tuần 4 vẫn processing vì Proposed Table I còn lệch 1,352910 điểm %.

## 8. Bước 3 — bộ đo FP32 và chính sách mẫu (04/10/2026)

`include/paper_measurement.hpp` tập trung generator, oracle, bộ lọc, counters và phép so ngưỡng. Seed mặc định 314159, PRNG `std::mt19937_64`:
- `uniform-value`: x = (rng() & 0xffffff) / 2^24, grid đều trên [0,1); đây là giả định của đồ án vì paper không công bố PRNG/seed/phân bố chi tiết.
- `uniform-bits`: lấy 30 bit thấp, loại raw >= 0x3f800000; dùng khảo sát độ nhạy, không đồng nghĩa phân bố đều theo giá trị.
- Ideal = RN-even_FP32(x*y), dùng đầu vào FP32 gốc trước cắt 11 bit. Khởi tạo FE_TONEAREST; không build với fast-math.

Bộ lọc theo thứ tự: ngoài miền (âm, >=1, Inf/NaN) -> input ±0 -> regime posit m>15 -> Ideal ±0 -> Ideal không hữu hạn. Tích subnormal khác 0 vẫn được nhận. Guard Ideal không hữu hạn không thể xảy ra với đầu vào hợp lệ [0,1), nhưng được báo riêng. N là số cặp được nhận, cùng corpus cho cả hai OPS và n=2..4. Luôn kiểm attempted = accepted + tổng các nhóm loại; generator_draws đếm cả lần loại raw nội bộ.

Err = abs(Approx-Ideal)/Ideal; tỷ lệ = 100*count(Err<tau)/N với tau = 1/1000, 1/200, 1/100, 1/20. So sánh bằng số nguyên chính xác trên significand đã căn scale: difference*denominator < ideal, tránh sai số long double ở đúng ngưỡng. Mẫu bằng ngưỡng không được tính. fingerprint FNV-1a64 hash mỗi attempted pair theo thứ tự rawA, rawB, reason, Ideal bits, mỗi word theo byte little-endian; dùng nhận diện corpus, không phải hash bảo mật.

`test_paper_measurement` đạt **1.900.058 đối chiếu trên Linux/Windows/UBSan**: một triệu tích đối chiếu oracle số nguyên IEEE RNE độc lập, directed ties/underflow, replay/domain/grid, chính sách loại, subnormal và các điểm đúng ngưỡng. Hai lượt Linux và Windows cho cùng rows/counters/fingerprint:
- 100.000 cặp uniform-value: attempted=100.000, draws=200.000, fingerprint=36a18bd492e6b0cf.
- 100.000 cặp uniform-bits: attempted=155.595, loại m=16.550, Ideal=0: 39.045; draws=313.678, fingerprint=4c87d984a4529545.
- Baseline regression 531.039 đối chiếu đạt. Tỷ lệ smoke uniform-value không đổi so bước 2.

Chạy:
~~~bash
make test-paper-measurement
make test_paper_measurement_ubsan
./test_paper_measurement_ubsan
./test_paper_table1 --samples 100000 --seed 314159
./test_paper_table1 --samples 100000 --seed 314159 --distribution uniform-bits
~~~
Suite được tích hợp build Linux/Windows, make test/test-paper và script rebuild. Log/lệnh/compiler/hash: `results/paper_measurement_step3_*.log` và manifests. Không chạy lại 200 triệu ở bước 3; kết quả mục 6 là lịch sử. Cần chạy lại bộ đo mới cho nghiệm thu đầy đủ; tuần 4 vẫn processing.

## 9. Bước 4 — chạy lại 200 triệu cặp bằng bộ đo mới (04/10/2026)

Lệnh: `./test_paper_table1 --samples 200000000 --seed 314159 --distribution uniform-value --require-match`. SHA256 binary bước 3 được kiểm trước chạy. Cả baseline/variant n=2..4 dùng cùng 200.000.000 cặp được nhận; attempted=200.000.023, loại input zero=23, các nhóm loại khác=0; draws=400.000.046. Fingerprint= b4c229e09c0ec0ba; thời gian 91,602213 giây.

| n | Baseline Err<0,1% | Err<0,5% | Err<1% | Err<5% | Max lệch Proposed (điểm %) | Max lệch Kim (điểm %) |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | 8,714937% | 31,177290% | 49,285731% | 95,463330% | 1,155063 | 0,942710 |
| 3 | 43,337090% | 82,859994% | 94,981795% | 100,000000% | 1,352910 | 0,602910 |
| 4 | 86,286286% | 99,797782% | 100,000000% | 100,000000% | 0,803714 | 0,403714 |

Cả sáu hàng baseline/minpop trùng log lịch sử ở độ chính xác in sáu chữ số thập phân. Bộ đo mới không làm mất sai lệch: max Proposed=1,352910 điểm % (n=3, Err<0,1%; paper 44,69%, đo 43,337090%). **NOT_REPRODUCED**, exit=1 vì chưa đạt <=1 điểm %; đây là kết quả nghiệm thu số học, phép chạy đã hoàn tất. Cột Kim có max lệch 0,942710 điểm %, nhưng không chứng minh mô hình bit-exact với RTL gốc. Minpop n=4 chỉ đạt 72,468581% ở Err<0,1%, so baseline 86,286286%; đánh đổi accuracy vẫn tồn tại.

Bảng đối chiếu từng ô cả hai profile: `results/paper_table1_step4_comparison.csv`; log đầy đủ: `paper_table1_step4_200m.log`; provenance/lệnh/hash: `paper_table1_step4_metadata.log`, `paper_table1_step4_integrity.log`, `paper_table1_step4_artifacts.sha256`. Chưa chạy lại full Windows/RTL/PPA trong đợt này. Tuần 4 giữ processing; tiếp theo cần khảo sát có kiểm soát các giả định predictor/tie/accumulator và độ nhạy seed để giải trình sai lệch, không thay thuật toán chỉ để ép tỷ lệ.

## 10. Khảo sát seed và giả định tái dựng — 04/10/2026

Công cụ riêng `test/test_paper_sensitivity.cpp` giữ nguyên baseline và RTL. Mỗi biến thể chỉ đổi một yếu tố, giữ input FP32/cắt 11 bit, SAC fraction12, predictor n=2/7-bit và bộ đo bước 3, trừ đúng yếu tố đang khảo sát. Chạy 10 triệu accepted mỗi seed với 314159, 314160, 2026, 20261004, 42; tổng 50 triệu mỗi profile/hàng, cùng corpus trong mỗi seed.

| Profile | Thay đổi duy nhất | Max lệch Proposed qua 5 seed (điểm %) | n=3 Err<0,1% gộp (%) |
| --- | --- | --- | --- |
| baseline | Không đổi | 1,337120–1,372450 | 43,340444 |
| tie_b | Chọn B khi predictor bằng nhau | 1,335260–1,361520 | 43,342390 |
| relative_prediction | So sai số predictor tương đối | 0,967490–0,999170 | 43,711870 |
| exact_prediction_residual | Predictor dùng phần dư toán học thay complement | 1,243710–1,276780 | 43,434458 |
| acc_guard12 | Accumulator Q24 thêm 12 guard bits; input/SAC Q12 giữ nguyên | 1,108250–1,133380 | 43,612288 |
| exact_sac_residual | Chỉ SAC dùng phần dư toán học thay complement | 1,643670–1,678840 | 43,034788 |
| pack_rne | Chỉ pack RNE thay TRUNC | 1,337120–1,372450 | 43,340444 |

Baseline n3 Err<0,1% gộp 43,340444%, khoảng tin cậy lấy mẫu xấp xỉ 95% là ±0,013736 điểm %. Khoảng lệch với Proposed 44,69% lớn hơn nhiều biến động theo seed trong khảo sát này; không thể quy toàn bộ khoảng lệch cho seed. Tie không giải quyết khoảng lệch; guard bits có ảnh hưởng rõ, nhưng một mình vẫn chưa đạt. Pack RNE không đổi outputs trên corpus này, không khẳng định điều đó trên mọi input.

Với mantissa proxy M=128+index7, biến thể relative_prediction dùng score E/M, so chính xác bằng E_B*M_A < E_A*M_B; tie vẫn A. Cơ sở số học: nếu chỉ xấp xỉ X, |Y*AP(X)-Y*X|/(Y*X) = |AP(X)-X|/X đối với X,Y dương. Đây là biến thể nghiên cứu hợp lý theo mục tiêu sai số tương đối, **không phải xác nhận LUT gốc của tác giả**; predictor vẫn là tái dựng 7-bit.

Sau khảo sát, xác nhận riêng bằng seed mới 271828 và 200 triệu accepted cùng corpus cho baseline/relative_prediction:

| n | Relative Err<0,1% | Err<0,5% | Err<1% | Err<5% | Max lệch Proposed (điểm %) |
| --- | --- | --- | --- | --- | --- |
| 2 | 8,9005105% | 31,4929195% | 49,6681080% | 95,6556115% | 0,9694895 |
| 3 | 43,7133040% | 83,3727560% | 95,3830630% | 100% | 0,9766960 |
| 4 | 86,6811110% | 99,8495030% | 100% | 100% | 0,4088890 |

Biến thể đạt tiêu chí số học <=1 điểm % trên 12 ô của lượt xác nhận; baseline cùng corpus vẫn lệch 1,347652 điểm %. Ở n3 Err<0,1%, tăng 0,370956 điểm % so baseline, paired SE=0,000862 điểm %. Attempted=200.000.021, input zero loại 21, nhóm m/Ideal-zero=0, draws=400.000.042; fingerprint=04478e811a897da7, thời gian 104,360097 giây. Chỉ xác nhận độ chính xác theo phân bố địa phương; chưa biết predictor paper có dùng score này và chưa đo PPA của comparator mới. Không tự đổi baseline hoặc đánh dấu tuần 4 hoàn thành từ kết quả của biến thể.

Self-test 1.500.128 đối chiếu Linux/Windows/UBSan gồm baseline differential, tie, SAC exact, pack RNE, accumulator guard so oracle dyadic Q24 và predictor residual 128 entries. Smoke 100.000 corpus Linux/Windows khớp rows/counters/fingerprint. Lệnh:
~~~bash
make test-paper-sensitivity
./test_paper_sensitivity --samples 10000000 --seed 314159
./test_paper_sensitivity --samples 200000000 --seed 271828 --profile relative_prediction
~~~
Self-test được tích hợp make test/test-paper và rebuild; không tự chạy khảo sát dài trong regression. Log/counters/counts/paired SE: `results/paper_sensitivity_seed_*.log`, `paper_sensitivity_holdout_200m.log`. CSV: `paper_sensitivity_all_seeds.csv`, `paper_sensitivity_summary.csv`, `paper_sensitivity_holdout.csv`; nghiệm thu nghiên cứu: `paper_sensitivity_acceptance.log`; metadata/hash: `paper_sensitivity_metadata.log` và manifests. CI xấp xỉ chỉ biểu diễn bất định lấy mẫu với generator đã chọn, không bao gồm bất định mô hình; chưa thử tổ hợp nhiều thay đổi.

## 11. Tích hợp predictor tương đối và nghiệm thu L1 — 04/10/2026

`paper_ops_select_relative<W>` dùng cùng LUT n=2/7-bit, so score E/(128+index7) bằng nhân chéo nguyên, tie chọn A. `PaperOps::PredictN2Relative` được thêm cuối enum, giữ các giá trị cũ và mặc định PredictN2. Không đổi SAC/SBM, cắt 11 bit, accumulator, pack hay mapping normative cfg_ops; đây là tùy chọn nghiên cứu của PaperMultiplier, không tự gán cfg_ops=3 cho RTL.

~~~cpp
l1::PaperConfig cfg;
cfg.n = 3;
cfg.ops = l1::PaperOps::PredictN2Relative;
auto result = l1::PaperMultiplier<32,3,12>::mul(a, b, cfg);
auto selection = l1::paper_ops_select_relative<12>(fraction_a12, fraction_b12);
~~~

`test_paper_relative_ops` đạt **35.503.586 đối chiếu/nền tảng Linux/Windows/UBSan**:
- Oracle Q24 độc lập cho lỗi predictor; score rational/tie chuẩn hóa bằng gcd cho 128x128 prefix.
- Vét cạn 4096x4096 fraction12, kiểm bất biến 5 bit thấp và quyết định/tie; kiểm độ rộng W=7/27 và ngoài miền.
- 100.000 cặp bitstring posit x n=1..8, gồm dấu/special và cả RNE/TRUNC, complement/exact residual; đối chiếu phép chọn với FixedA và metadata.
- 100.000 cặp generator x n=2..4: kết quả tích hợp bằng công cụ khảo sát độc lập.
- 904 cặp prefix đổi hướng chọn so predictor tuyệt đối; 292 cặp có score rational bằng nhau.

Regression `make test` đạt tất cả suite L1 hiện có. Smoke relative 100.000 cặp Linux/Windows khớp rows/counters/fingerprint; default baseline/minpop cho cùng tỷ lệ như trước tích hợp. CLI từ chối profile không hợp lệ và require-match dưới 200 triệu bằng exit=2.

Bộ đo chính thức thêm `--profile baseline|relative` (default baseline). Khi chọn relative, cả baseline/minpop/relative đều chạy chung corpus; `--require-match` đánh giá riêng profile được chọn. Nghiệm thu integrated relative bằng 200 triệu accepted, seed271828, đạt **PASS, max Proposed=0,976696 điểm %, exit=0**. Cả 24 ô baseline/relative được in khớp công cụ khảo sát cùng seed; fingerprint=04478e811a897da7. Attempted=200.000.021, zero loại21, nhóm khác0, draws=400.000.042, thời gian190,051713 giây. Relative n3 Err<0,1%=43,713304%; baseline cùng corpus43,342348%. Kết quả đầy đủ cả ba profile trong `results/paper_relative_integration_table1.csv`.

~~~bash
make test-paper-relative
make test_paper_relative_ops_ubsan
./test_paper_relative_ops_ubsan
make paper-table1-relative
# tương đương:
./test_paper_table1 --samples 200000000 --seed 271828 --profile relative --require-match
~~~

Tích hợp build Linux/Windows, make test/test-paper và script rebuild. Log `paper_relative_integration_verified/windows/ubsan/regression/200m.log`, metadata/lệnh/hash trong `paper_relative_integration_metadata.log` và manifests. Script rebuild đã cập nhật, chưa chạy lại toàn L0 trong đợt này.

**Phạm vi nghiệm thu:** tùy chọn E/M trong L1 đã đạt chức năng và tiêu chí số học Table I theo generator địa phương. Đây chưa là chứng minh thuật toán/LUT gốc của paper. Baseline mặc định vẫn chưa đạt tái hiện Proposed; tuần4 giữ processing theo yêu cầu baseline hiện hành. PPA của E/M chưa đo và không phải điều kiện bắt buộc để nghiệm thu chức năng L1; cần đo trước khi chọn cải tiến phần cứng cuối.

## 12. Tuần 5 — bộ cộng Posit L1 đã nghiệm thu (04/10/2026)

`include/posit_adder.hpp` cung cấp `PositAdder<NB,ES>`, `l1_add`, `l1_add_unpacked` và `AdderTrace`. Theo SPEC §5.8: chọn toán hạng lớn theo (sf,m), căn chỉnh kẹp d<=F+2 (F=FRAC_MAX), phần bị mất được jam vào sticky; nếu d>F+2 thì bỏ qua barrel shift và đưa mantissa nhỏ vào sticky. Cửa sổ hidden tại Q=F+3 giữ fraction+G/R/S. Cộng cùng dấu, trừ theo độ lớn khi khác dấu, rồi chuẩn hóa carry/LZC và pack.

Đường trừ xử lý borrow của đuôi bằng right-jam; triệt tiêu sâu chỉ xảy ra khi các bit căn chỉnh còn giữ chính xác. Oracle số nguyên rộng trong test giữ toàn bộ tổng trước làm tròn để kiểm điều này trên RNE/TRUNC, near-cancellation và clamp. Trace trả d, lượng dịch đã kẹp, tail, đổi thứ tự, cộng/trừ, carry, LZC, zero và G/R/S của cửa sổ F tối đa; packer tính vị trí làm tròn thực tế theo regime/exponent.

~~~cpp
auto bits = l1::l1_add<32,2>(a, b); // RNE mặc định
l1::AdderTrace trace;
auto unpacked = l1::l1_add_unpacked<32,2>(
    l1::parse<32,2>(a), l1::parse<32,2>(b), &trace);
auto rounded = l1::pack<32,2>(unpacked, l1::RoundMode::RNE);
~~~

Ngõ vào unpacked phải normalized, exact, có tối đa F bit fraction và sf trong dải Posit; ngõ ra chưa làm tròn. Để ghép MAC v1, phải dùng round_unpacked(product) trước khi gọi adder. Đầu vào còn sticky hoặc chứa fraction vượt độ chính xác bị từ chối, không giả định một sticky đủ giữ chính xác khi triệt tiêu. NaR ưu tiên zero, triệt tiêu chính xác trả0, saturation do packer hiện có. RNE là chế độ đối chuẩn SoftPosit; TRUNC được kiểm thêm bằng oracle rộng.

| Cấu hình | Nghiệm thu | Chuẩn | Kết quả |
| --- | --- | --- | --- |
| (8,0) | Vét cạn 65.536 cặp | SoftPosit p8_add | 0 mismatch |
| (16,1) | Vét cạn 4.294.967.296 cặp | SoftPosit p16_add | 0 mismatch; 81,4565 giây |
| (32,2) | 10.000.000 vector phân tầng | SoftPosit p32_add | 0 mismatch |
| (32,3) | 10.000.000 vector phân tầng | Oracle số nguyên rộng | 0 mismatch; chưa là đối chuẩn SoftPosit ES3 |

Vét cạn posit16 cache kết quả parse của toàn bộ65.536 bitstring để tăng tốc, chạy cùng add_unpacked+pack core với public API; public l1_add cũng được kiểm một triệu cặp posit16 và corners. Oracle rộng dùng lưới2^(-SF_MAX-F), đủ chứa chính xác toàn bộ phép cộng/trừ, không dùng clamp/jam của adder; parser/packer đã nghiệm thu được dùng ở hai đầu.

Full suite Linux đạt **4.316.435.339 đối chiếu**, gồm hai bộ10 triệu ES2/ES3, exhaustive, corners, directed ties even/odd, d=F+1/F+2/F+3 và100.000 cặp raw mỗi ES đối chiếu RNE/TRUNC. Coverage ES2 có4.157.566 cặp trái dấu |d|<=4 (41,57566%), ES3 có4.093.783 (40,93783%). Mỗi polarity/run hữu hạn có ít nhất149.936 lượt toán hạng, vượt yêu cầu10.000; có cả4 nhóm dấu,6 density buckets,5 delta buckets, carry, clamp, triệt tiêu chính xác và LZC>15.

Smoke Linux/Windows/UBSan đạt **3.468.043 đối chiếu/nền tảng**. Windows chạy thêm 10 triệu mỗi cấu hình ES2/ES3, khớp dữ liệu/coverage với Linux và kiểm chế độ range posit16; không chạy lại full4 tỷ trên Windows. Regression make test đạt; script rebuild cập nhật và kiểm syntax, chưa chạy lại toàn L0.

~~~bash
make test-week5
make test_adder_ubsan
./test_adder_ubsan
make test-adder-acceptance
# tương đương:
./test_adder --acceptance --samples 10000000 --seed 314159
# tiếp tục một khoảng posit16 [start,end):
make test-adder-p16-range P16_START=0 P16_END=256
~~~

CLI require đủ10 triệu khi --acceptance; chỉ ghi WEEK5_ADDER_ACCEPTANCE PASS khi đã chạy toàn range posit16. Gộp các log range phải bảo đảm phủ [0,65536) không hở; checkpoint next_A là điểm tiếp tục.

Log: `results/week5_adder_acceptance.log`, `week5_adder_verified.log`, `week5_adder_windows.log`, `week5_adder_windows_10m.log`, `week5_adder_ubsan.log`, `week5_adder_regression.log`; coverage CSV, compiler/seed/lệnh và hashes tại `week5_adder_coverage.csv`, `week5_adder_metadata.log`, `week5_adder_*.sha256`.

**Tuần 5 hoàn thành phần L1 adder theo PLAN.** Chưa có MAC v0/v1 hoặc acc_mode; Gate 1B chưa đạt cho đến khi hoàn thành tuần 6. Kết quả tuần4 được giữ riêng.


## 13. Đối chiếu nguồn [18] với [15]/[P] — 04/10/2026

### Phiên bản và vai trò từng nguồn

File mới `../An_iterative_logarithmic_multiplier.pdf` là Babić/Avramović/Bulić, *Elektrotehniški vestnik* 77(1):25–30 (2010), 6 trang. [P] reference [18] và [15] reference [6] dẫn bản *Microprocessors and Microsystems* 35(1):23–33 (2011), DOI 10.1016/j.micpro.2010.07.001. Thông tin phiên bản 2011 đã đối chiếu trang nhà xuất bản: https://www.sciencedirect.com/science/article/abs/pii/S0141933110000438 . Chưa đọc toàn văn bản 2011; không giả định hai bản có toàn bộ thuật toán/bảng giống nhau.

| Nguồn | Căn cứ có thể ghép nối | Giới hạn |
| --- | --- | --- |
| Babić 2010 vừa tải | Phân rã tích, phần dư, số correction term, oracle số nguyên và điều kiện dừng | Không cung cấp OPS 7-bit, RND complement của Kim, seed/phân bố FP32 hoặc accumulator Posit |
| [15] Kim 2019 | Nhánh chỉ xấp xỉ một toán hạng; RND/SAC/SBM/OPS; cắt 11 bit FP32; căn exponent khi cộng | LUT n=2 đầy đủ/tie và độ rộng accumulator vẫn chưa được chốt từ tài liệu |
| [P] Posit 2021 | Chuyển decode/encode sang Posit; Fig.4; Table I/III và baseline so sánh | Table I cần ghi riêng Babic/Kim/Proposed; đạt ngưỡng thống kê chưa chứng minh thuật toán gốc |

[P] §II-B phát triển multiplier dựa trên [15]. Cột Babic trong Table I là thuật toán được mở rộng sang single precision theo [15]; số PPA Babic trong Table III cũng lấy từ [15]. Không ghép trực tiếp lõi hai-toán-hạng Babic vào lõi một-toán-hạng Kim rồi gọi kết quả là Proposed gốc.

### Công thức Babić 2010 và kiểm tra độc lập

Theo Eq.(7)–(15), trang in 27–28, với A_j,B_j nguyên dương:

~~~text
hA_j = 2^floor(log2(A_j)); hB_j = 2^floor(log2(B_j))
A_(j+1) = A_j - hA_j; B_(j+1) = B_j - hB_j
P_j = hA_j*hB_j + A_(j+1)*hB_j + B_(j+1)*hA_j
A_0*B_0 = sum(P_j, j=0..n-1) + A_n*B_n
~~~

Sai số phần dư luôn không âm; dừng chính xác khi một phần dư bằng 0. Số stage cần để chính xác là min(popcount(A),popcount(B)). Basic=1 stage; +1CT/+2CT/+3CT tương ứng 2/3/4 stage, không phải n=1/2/3. Basic của phép phân rã là Eq.(8), không tự thay bằng cả hai nhánh Mitchell Eq.(4). Algorithm 2 bước 9(a) in hai lần N1; phép gán thứ hai phải là N2 theo công thức phần dư — đây là hiệu chỉnh suy ra từ đẳng thức, không chép nguyên lỗi in.

Audit command-line Python số nguyên ngày 04/10/2026, toàn bộ 255²=65.025 cặp dương 8-bit, kiểm identity phần dư ở cả 4 stage. AE% lần lượt 8,9131 / 0,8337 / 0,0708 / 0,0048, khớp Table 4. Tỷ lệ Err<0,1% / <0,5% / <1% ở 2 stage: 32,9 / 54,8 / 70,0%; 3 stage: 79,9 / 96,9 / 99,6%; 4 stage: 99,0 / 100 / 100%. Table 3 in 69,9% tại 2 stage/<1%: còn chênh 0,1 điểm %, không tuyên bố tái hiện hoàn toàn bảng này. Ngưỡng audit so bằng số nguyên nghiêm ngặt; AE dùng float để tổng hợp. Đây là kiểm tra recurrence, chưa kiểm comparator Babic FP32 trong Table I [P].

§5 dùng vét cạn số nguyên dương 1..2^W−1; không có PRNG/seed. Không chuyển quy trình này thành bằng chứng về phân bố FP32 của [P].

### Phát hiện cần kiểm tra trước khi khóa baseline hiện tại

[15] §3.3, trang in 90–91: giữ exponent số hạng đầu l1, căn số hạng sau bằng l1−ln. Với các power tương đối p_j của PaperSac và mantissa MY_Q12, cách dựng tương ứng nếu cắt từng số hạng ở Q12 là:

~~~text
anchor = p_1
acc_anchor = sum(sign_j * floor(MY_Q12 * 2^(p_j-anchor)))
sf_anchor = sf_A + sf_B + anchor
~~~

Hiện `paper_multiplier.hpp` dùng sum(sign_j*floor(MY_Q12*2^p_j)), sf_A+sf_B, rồi normalize. Hai cách có thể khác khi p1=1. Fixture với FixedA/complement/n=3: MX_Q12=6144, MY_Q12=4096, terms=(power,sign) [(1,+1),(-1,-1),(-12,+1)]. Cách hiện tại acc=6145; cách anchor-first acc=3072 tại scale+1, tương đương 6144 tại scale gốc. Đây là phép thử số nguyên về vị trí cắt, chưa chứng minh độ rộng/cắt Q12 của paper hoặc nguyên nhân sai lệch 1,352910 điểm % của Table I. Fig.4 có p1=0 nên chưa kiểm nhánh khác biệt này.

[15] §3.2 mô tả so lỗi tuyệt đối để chọn toán hạng. Predictor E/M vẫn là cải tiến nghiên cứu, không trở thành thuật toán gốc nhờ đạt Table I. [18] không bổ sung LUT n=2/7-bit hoặc tie-break còn thiếu. Giữ baseline/default/RTL hiện hành; ưu tiên khảo sát riêng anchor-first, kiểm cả p1=0/1 và độ rộng accumulator, rồi chạy cùng corpus để tách ảnh hưởng. Chỉ cập nhật baseline khi có kiểm chứng và provenance; tuần4 vẫn processing.


## 14. Baseline tái dựng theo nguồn: đạt ngưỡng Table I — 04/10/2026

**Đính chính từ kiểm chứng ngày08/10 (§20):** nghiệm thu dưới đây chỉ là kết quả thống kê lịch sử. Profile `source` giữ Q24 đến pack trả `0x1ae34800` cho ví dụ Fig.4, khác output `0x1ae34000` của bài báo2021; vì vậy không còn là ứng viên baseline bit-exact gốc. Giữ API/log để đối chứng, không tự chuyển default hoặc RTL sang profile này.

Đã thực hiện tuần tự ưu tiên PLAN: khảo sát anchor-first; guard/cut; predictor theo pattern; đường FP32/Posit; pilot và holdout; truy tìm nguồn; comparator Babic riêng. Kết quả **nghiệm thu số học đạt**, nhưng chưa khẳng định bit-exact với mã nguồn paper vì LUT n2/tie, độ rộng accumulator và generator gốc chưa đầy đủ.

### Khảo sát và căn cứ lựa chọn

- `test_paper_anchor` giữ baseline làm control, thêm anchor-first guard0/1/2/12 và cắt sau tổng. Anchor/guard giữ nguyên OPS/SAC/cut11/pack. Anchor0 không giải quyết gap; anchor12 trên hai seed10 triệu còn lệch1,108640/1,108250 điểm %. Cắt sau tổng Q12 cũng không giải quyết: pilot1 triệu lệch tối đa1,413600 (input scale) /1,425700 (first anchor). Oracle anchor dùng dyadic độc lập; post-cut dùng signed remainder Q96 và tổng Q64. Đây là khảo sát vị trí cắt, không thay chính sách normative của SPEC.
- `test_paper_source_audit` kiểm tám fixture đại diện Table2 [15], mỗi fixture toàn bộ2^17 đuôi don't-care, cả output và f1/f2/f3; thêm128 prefix và hai ví dụ Fig2. Tổng2.097.282 đối chiếu đạt. Không suy rộng các fixture đại diện thành toàn bộ zero-run pattern hoặc full LUT n2 được tác giả công bố.
- Predictor tái dựng mới mở rộng prefix7 về Q12 trước complement, so **lỗi tuyệt đối**, tie-A. Oracle độc lập Q23 trên128 prefix khớp. Hai entry126/127 thay lỗiQ12 từ32 thành0. Đây là diễn giải có căn cứ pattern, chưa chứng minh n2 LUT/precision gốc; không dùng score E/M.
- Source candidate kết hợp predictor trên với anchor-first và guard12 (accumulator Q24 trước normalization), giữ inputfraction12/complement/TRUNC. Guard12 là độ rộng khảo sát có kiểm chứng, chưa phải width paper công bố. Chỉ ứng viên đã kiểm chứng mới được chạy holdout.

### API và bộ đo

`PaperOps::PredictN2Pattern` được thêm cuối enum; `PaperConfig` thêm `anchor_first` và `accumulator_guard` (0..12, W+guard<=39). Giá trị/mặc định cũ giữ nguyên. `paper_source_config()` tạo cấu hình ứng viên, n mặc định3; không ánh xạ cfg_ops RTL và không thay normative profile của SPEC.

~~~cpp
auto cfg = l1::paper_source_config();
cfg.n = 3;
auto result = l1::PaperMultiplier<32,3,12>::mul(a,b,cfg);
~~~

Bộ đo chính thức thêm `--profile source`: baseline/minpop/relative/source dùng cùng cặp; require-match đánh giá source. Baseline/relative vẫn có kết quả cũ. Target mới:

~~~bash
make test-paper-source
make test_paper_source_profile_ubsan
./test_paper_source_profile_ubsan
make paper-table1-source
# ./test_paper_table1 --samples 200000000 --seed 271828 --profile source --require-match
make paper-table1-babic
# ./test_paper_babic 200000000 271828
~~~

### Table I: source candidate 200 triệu accepted

| n | Err<0,1% | Err<0,5% | Err<1% | Err<5% | Max lệch Proposed, điểm % |
| --- | --- | --- | --- | --- | --- |
| 2 | 8,959513% | 31,318030% | 49,327373% | 95,467513% | 0,910487 |
| 3 | 43,705787% | 82,908723% | 95,001601% | 100,000000% | 0,984213 |
| 4 | 86,679951% | 99,807305% | 100,000000% | 100,000000% | 0,410049 |

**PASS/exit0**, max0,984213 điểm %, seed271828, uniform-value grid24/std::mt19937_64, FP32_RNE Ideal trước cut11, ngưỡng nghiêm ngặt bằng số nguyên. Attempted200.000.021, loại zero21, các nhóm khác0; draws400.000.042; fingerprint04478e811a897da7. Bộ đo tích hợp176,297389 giây; nghiên cứu116,246325 giây. Cả12 ô source khớp nghiên cứu ở độ chính xác log;24 ô legacy baseline/relative không đổi so log nghiệm thu trước. Baseline trên cùng corpus max1,347652; E/M max0,976696, giữ vai trò cải tiến riêng.

Pilot5 seed x10 triệu cho source: max0,970200–1,006150 điểm %. Seed314159=1,000560 và20261004=1,006150 vượt1; ba seed khác đạt. Không che giấu các pilot chưa đạt và không tuyên bố đã đạt mọi seed/phân bố. Holdout271828 đã dùng trong các nghiên cứu trước của dự án, là xác nhận ngoài năm seed pilot này, không gọi là corpus chưa từng được quan sát.

Đối chiếu FP32/Posit cùng200 triệu cho source: conversion_changed=0, input_cut_changed=0;12 tỷ lệ khớp ở6 chữ số sau dấu phẩy. Bit/giá trị output khác138.369 /3.020.854 /21.320.955 cặp tại n2/3/4 do độ chính xác output, nhưng không tạo chênh tỷ lệ ở độ chính xác log. Max so Kim=0,801969 điểm %. Đường FP32 của audit xuất TRUNC sau normalize; đây là comparator địa phương, chưa full IEEE special implementation. Việc khớp thống kê không xác nhận generator của tác giả.

### Kiểm chứng và comparator Babic

`test_paper_source_profile`: **29.878.945 đối chiếu/nền tảng Linux/Windows/UBSan**, gồm toàn4096²selection/tie/low5,128 LUT, corners/NaR/zero/dấu/biên1,5,100.000 raw x n1..8 x guard0/1/2/12 x anchorfalse/true x round luân phiên, oracle signed remainder Q96 độc lập và100.000 corpus x n2..4 differential tích hợp. Các trường unpacked cũng được đối chiếu. Test chặn guard13 và CLI chặn nghiệm thu thiếu200 triệu. Regression L1 đạt; Linux/Windows smoke khớp rows/counters/fingerprint. Script rebuild kiểm syntax; không chạy lại full L0 hay full nghiệm thu adder4 tỷ trong đợt này.

`paper_babic.hpp` triển khai riêng recurrence integer [18]2010. Audit8-bit có260.100 identity checks (65.025 cặp x4stage), AE khớp Table4. Comparator FP32 địa phương dùng significand đầy đủ24 bit (fraction23), không cut11; sum partial product integer <=48bit, output FP32_RNE. Không dùng hai nhánh Mitchell thay basic decomposition. Trên cùng200 triệu/seed271828:

| n | Err<0,1% | Err<0,5% | Err<1% | Err<5% |
| --- | --- | --- | --- | --- |
| 2 | 19,146617% | 47,374851% | 65,139091% | 99,127540% |
| 3 | 70,515828% | 95,521034% | 99,428855% | 100,000000% |
| 4 | 98,030289% | 100,000000% | 100,000000% | 100,000000% |

Max so cột Babic TableI=**0,009091 điểm %**, PASS số học; fingerprint/counters cùng source. Đây là mở rộng FP32 được dự án kiểm chứng, chưa là xác nhận source2011/implementation [15] bit-exact. Linux/Windows/UBSan smoke comparator đạt.

### Provenance và phần còn mở

Truy tìm bản2011 qua trang tác giả ResearchGate, link PDF trảHTTP403, file tạm là HTML và không được dùng làm nguồn PDF. Trang publications của Sunwoong Kim: https://sites.google.com/view/sunwoong/publications . Tìm thấy bài journal tiếp nối2024, DOI10.1109/TVLSI.2024.3354726, có thể đối chiếu sau; chưa đọc toàn văn, không đưa nội dung thứ cấp hoặc thông số bản2024 vào baseline2021. Chưa tìm được LUT/code/generator gốc trong các nguồn đã kiểm; không kết luận chúng không tồn tại.

Ưu tiên còn lại là xác minh n2 LUT/tie và width/cut từ nguồn gốc; đánh giá độ nhạy gần ngưỡng1 điểm % trước khi chọn profile RTL. **Table I của baseline tái dựng đã đạt tiêu chí dự án; việc khẳng định baseline gốc đầy đủ vẫn processing.** Tuần5/Gate1B giữ trạng thái riêng. Không tự chuyển default sang source và không dùng kết quả số học làm bằng chứng PPA.

Logs/CSV: `results/paper_source_integration_200m.log`, `paper_source_candidate_holdout_200m.log`, `paper_source_FP32_Posit_200m.log`, `paper_source_table1.csv`, `paper_source_pilot_summary.csv`, `paper_source_acceptance.log`, `paper_babic_200m.log`. Tests/build/regression/compiler/seed/lệnh/hash tại `paper_source_*`, `paper_anchor_*`, `paper_babic_*` và metadata/manifests.

## 15. MAC L1 và Gate 1B — tuần6, 04/10/2026

`posit_mac.hpp` ghép MAC **non-fused**: v0 làm `mul → pack → parse → add → pack`; v1 thay bước pack/parse tích bằng `round_unpacked`, giữ giá trị Posit đã làm tròn trước phép cộng. Khi C=0, tích vẫn phải pack ra kết quả. Exact mặc định RNE; approximate dùng `L1MultiplierIter`, Q12, n=0..8, ops=0/1, FLOOR/STICKY_ACC và RNE/TRUNC. Cấu hình nghiên cứu TableI/source/E/M giữ riêng.

Flags bits `[4:0]={nar,sat_max,sat_min,inexact,approx_cut}`: OR cờ làm tròn/bão hòa từ tích và tổng; NaR ghi đè thành16. `approx_cut` báo còn số hạng khi dừng vòng lặp; mất precision đầu vào được ghi vào `inexact`. Triệt tiêu về0 không tự tạo underflow, nhưng giữ cờ bão hòa của bước nhân trước đó. Metadata không chuyển phần dư của tích chưa làm tròn sang adder.

`MacAccumulator::step` xử lý một giao dịch nguyên tử: acc_mode bỏ qua C ngoài; acc_clr chỉ hợp lệ khi acc_mode và dùng C_eff=0 cho chính giao dịch đó. NaR tồn tại trong trạng thái đến clear/reset; regular MAC không sửa trạng thái. Config sai bị từ chối trước commit. L1 chưa mô phỏng chu kỳ, valid/ready, pending result hoặc backpressure; II/latency và commit khi stall là phần nghiệm thu RTL.

### Kết quả kiểm chứng

| Phạm vi | Kết quả |
| --- | --- |
| Posit8 ES0 exact RNE | Vét cạn 16.777.216 bộ ba, v0/v1 khớp `l0_add(l0_mul(a,b),c)` |
| Posit32 ES2 exact RNE | 10.000.000 bộ ba phân tầng, v0/v1 khớp SoftPosit non-fused |
| Posit32 ES3 exact RNE | 10.000.000 bộ ba; oracle tích significand nguyên và cộng integer rộng, dùng parser/packer đã kiểm chứng; không phải L0 ES3 |
| Coverage ES2 / ES3 | Near-opposite 4.124.235 / 4.065.558; mỗi ô A/B/sign ít nhất39.056; mỗi polarity/run trên từng toán hạng ít nhất22.070 /22.160; đủ6 nhóm mật độ fraction |
| Corner/state | Cả8/0,16/1,32/2,32/3; exact/approx, RNE/TRUNC, Zero/NaR, saturation, cancellation, 10.000 giao dịch tích lũy và lỗi config/clear |
| Linux và Windows | **36.841.216 đối chiếu/nền tảng, 0 mismatch; Gate1B PASS** |
| UBSan MAC | Smoke 264.000 đối chiếu đạt; không phải lượt vét cạn UBSan |
| C API | 130.008 đối chiếu ctypes trên Linux/Windows/UBSan, client biên dịch C11 đạt; regression `make test` đạt |

Oracle approximate ghép kết quả bộ nhân đã nghiệm thu với oracle cộng integer rộng; không tuyên bố đây là oracle nhân approximate độc lập mới. Các lượt đầu phát hiện thiếu coverage do cách tăng serial bỏ qua4 độ dài run của B; bộ sinh đã sửa sang offset cố định và nghiệm thu cuối phủ đủ. Seed cấu trúc/state=314159; ctypes approximate dùng thêm20261004. Generator dùng mt19937_64 cho C++, Python random.Random chỉ ở suite ABI.

### API và tái chạy

`include/l1_api.h`, `src/l1_api.cpp` xuất `l1_p32_mul` và `l1_p32_mac` scalar exact RNE cho DPI-C; `l1_mac_eval` và handle `l1_acc_*` cho ctypes/C, đủ4 format. NULL config chọn v1/exact/RNE. Cấu hình và kết quả dùng uint32, mã trả0=thành công,1=đối số/config sai,2=lỗi nội bộ; lỗi không thay output/state. FRAC_W API hiện cố định12. Caller sở hữu handle và phải tuần tự hóa truy cập một handle. Header ghi rõ enum/flags; không truyền exception qua API có status. Chưa chạy harness DPI trong ModelSim, chưa nghiệm thu handshake RTL.

```sh
cd Posit_MAC/l1
make test_mac_gate1b test_mac_gate1b.exe libposit_l1.so posit_l1.dll test_l1_api_c test_l1_api_c.exe
make gate1b P32_SEED=314159
# Windows PowerShell tại cùng thư mục:
# .\test_mac_gate1b.exe --acceptance --samples 10000000 --seed 314159
make test-week6
make test_mac_gate1b_ubsan libposit_l1_ubsan.so
./test_mac_gate1b_ubsan
python3 test/test_l1_api.py libposit_l1_ubsan.so
make test
```

Linux build g++15.2.0; Windows cross-build MinGW GCC13-win32, thư viện `posit_l1.dll` 64-bit. SoftPosit0.4.2/vendor commit17d5628185b31828b10c1f910c9bf65737e83640. L0 dùng bản đã rebuild/đối chuẩn, không đổi mã. Log, lệnh, phiên bản và SHA256 ở `results/week6_mac_metadata.log`, `week6_mac_sources.sha256`, `week6_mac_binaries.sha256`, `week6_mac_gate1b_{linux,windows}.log`, `week6_mac_ubsan.log`, `week6_*api*.log`, `week6_regression.log`. `scripts/rebuild_l0_l1.sh` đã bổ sung MAC/API vào build và smoke.

**Tuần6/Gate1B hoàn thành.** Bước kế tiếp là tuần7 parser RTL và mô phỏng các shifter còn thiếu. Provenance baseline tuần4 vẫn processing, không ảnh hưởng kết luận exact non-fused ở đây.

## 16. Kiểm hai shifter bằng Vivado — 04/10/2026

Vivado/XSim2026.1 64-bit, SW Build6511674 tại `C:/AMDDesignTools/2026.1/Vivado/bin`. `xvlog --sv` và `xelab` đã thành công cho hai testbench hiện có và ma trận tham số bổ sung; không có ERROR/WARNING trong compile/elaborate cuối. **Chưa chạy vector:** XSim báo `Could not obtain the necessary license for Simulator` và `Simtcl 6-50`, cả trong/ngoài sandbox. Exit code XSim có thể là0 khi engine không khởi động; runner bắt buộc kiểm marker PASS và lỗi trong log, không coi exit0 là đạt.

Đã sửa RTL: bỏ generate/endgenerate lồng không hợp lệ; tránh truy cập b[S-1:0] ngoài miền khi SHIFT_W<S ở N không phải lũy thừa2. Với SHIFT_W<S, mọi giá trị b biểu diễn được đều<N nên không có overflow. Sửa testbench: khai báo biến trước câu lệnh, seed tái lập mặc định20261004/plusarg SEED, dùng fatal khi lỗi. Testbench cũ giữ exhaustive8-bit, N27, N32, walking bits, shift>=N, right logical/arithmetic/custom fill. `tb_dyn_shifter_parameters.sv` bổ sung oracle từng bit, 27 cấu hình N=1/2/3/8/27/31/32/33/64 với SHIFT_W nhỏ/bằng/lớn hơn mặc định, fill0/1 và ARITH bỏ qua fill_val. N<=8 được thiết kế vét cạn khi chạy; **chưa công bố functional PASS cho các sửa đổi này**.

Đã tìm license trong Downloads (cả file ẩn/subfolder và mục license trong ZIP), chưa thấy file license Vivado/XSim. `xilinx-master-signing-key.asc` là khóa ký, không phải license. Không dùng file đó hoặc chạy installer như license. Lưu log ở `results/vivado_shifters/`; `compile_initial.log` ghi lỗi RTL trước sửa, `compile.log`, `elaborate_{left,right,parameters}.log`, `simulate_*` ghi kết quả cuối. Tuần7 và mốc hai shifter giữ **processing**.

```powershell
# Từ root đồ án, chạy lại sau khi có license hợp lệ:
.\Posit_MAC\scripts\verify_shifters_vivado.ps1
# Hoặc chỉ định file license, áp dụng riêng cho tiến trình chạy script:
.\Posit_MAC\scripts\verify_shifters_vivado.ps1 -LicenseFile 'C:\path\Xilinx.lic' -Seed 20261004
```

Script compile/elaborate/xsim đủ3 top, ghi log/summary.json, và trả lỗi nếu mô phỏng bị chặn. API/tiến độ L1 tuần6 giữ nguyên; compile/elaborate shifter không tương đương Gate2/3 hoặc PPA.

## 17. Hai shifter RTL nghiệm thu ModelSim — 04/10/2026

**Mô phỏng chức năng đã PASS** trên ModelSim ALTERA10.1d, compiler2012.11, `C:/altera/13.0sp1/modelsim_ase/win32aloem`. Seed cơ sở20261004; ma trận dùng seed riêng = base+N*100+SHIFT_W. Kết quả cuối:

| Testbench | Đối chiếu | Kết quả |
| --- | ---: | --- |
| tb_dyn_left_shifter | 34.832 | PASS, 0 mismatch |
| tb_dyn_right_shifter | 110.304 | PASS, 0 mismatch; logical, arithmetic, custom fill |
| tb_dyn_shifter_parameters | 3.194.624 | PASS; 27 instance kiểm thử, 25 cặp N/SHIFT_W khác nhau |
| Tổng | **3.339.760** | **PASS** |

Ma trận kiểm N=1/2/3/8/27/31/32/33/64; SHIFT_W nhỏ/bằng/lớn hơn mặc định, bao gồm shift0, N−1, N và vượtN khi biểu diễn được; fill0/1, ARITH bỏ qua fill_val, exhaustiveN<=8 và pattern/random độ rộng lớn. N1/N2 có hai instance SHIFT_W=1 trùng nhau do độ rộng tối thiểu1. Oracle từng bit không dùng cùng thuật toán MUX cascade của RTL. Bộ kiểm cũ tiếp tục exhaustiveN8, N27, N32/walking bits/random. Số đối chiếu tính từng ngõ ra, không đồng nghĩa toàn bộ không gian dữ liệu64-bit đã vét cạn.

Sửa tương thích bổ sung: parameter guard dùng `initial $fatal` thay elaboration `$error` mà ModelSim10.1d không parse; bỏ initializer trên input logic fill_val vì simulator báo continuous/procedural multi-driver (vsim-3838). **Caller phải nối fill_val rõ ràng**, dùng1'b0 cho logical zero-fill; ARITH vẫn bỏ qua cổng này. Mọi instance hiện có đều đã nối. Mã cuối compile lại bằng Vivado2026.1 cũng đạt (`compile_modelsim_compat.log`); chưa chạy lại elaborate/runtime Vivado cho bản cuối, tình trạng license vẫn mở. Kết quả ModelSim không được gán thành XSim PASS.

```powershell
# Từ root đồ án:
.\Posit_MAC\scripts\verify_shifters_modelsim.ps1 -Seed 20261004
```

Runner vlib/vlog/vsim có macro run.do xử lý lỗi, kiểm marker PASS và Error/Fatal trong transcript, ghi summary.json và SHA256. Logs tại `results/modelsim_shifters/{compile,simulate_left,simulate_right,simulate_parameters}.log`, `version.log`, `sources.sha256`; lệnh và đường dẫn tool trong script. Hai shifter đã hoàn thành mốc mô phỏng RTL; tuần7 giữ processing vì parser RTL chưa hoàn thành. Gate2/3/PPA chưa nghiệm thu.

## 16. Fixture packer RTL tuần8 — 07/10/2026

l1/test/gen_packer_vectors.cpp sinh đầu vào normalized với fraction không hidden, F_IN=2*FRAC_MAX+1, sf signed, sticky và flags trước đó. Oracle kết quả là pack(u,RNE/TRUNC) của L1 đã nghiệm thu; một encoder bit-list độc lập kiểm chéo mọi dòng. Flags đối chiếu giá trị decode sau pack với đầu vào, kiểm range/inexact và OR flags; NaR ưu tiên. Không gọi bộ fixture này là đối chuẩn SoftPosit mới hoặc mô hình timing L1.

Build từ Posit_MAC: make -C l1 gen_packer_vectors.exe (MinGW/WSL) hoặc make -C l1 gen_packer_vectors (Linux). Sau đó gen_packer_vectors.exe results/packer; compiler/command/seed tại results/packer/build.json. Corpus gồm identity p8/p16 vét cạn, p32 lấy1.200.010 mẫu/format từ parser đã nghiệm thu, toàn miền sf, fraction patterns/sticky, ties quanh mọi độ chính xác fraction khả dụng, NaR/Zero/flags và100.000 vector phụ/format. Seed20261006, tổng2.973.524 dòng; mỗi dòng có cả expected RNE/TRUNC. Script scripts/verify_packer_modelsim.ps1 kiểm hash nguồn/fixture và chạy wrapper tổ hợp, pipeline, chuỗi parser→packer.

Giao diện rộng mặc định giữ đủ tích exact sau chuẩn hóa: p32 ES2 fraction55, ES3 fraction53. L1 hidden ở bit63; fraction RTL lấy các bit kế, sticky là !u.exact OR bit thấp bị bỏ. Packer không tự normalize hoặc xử lý residual có dấu của fused. Pre-clamping minpos phải dùng sf<-SF_MAX theo L1, không dùng <=; ties tại đúng biên được kiểm riêng. Kết quả nghiệm thu cuối cùng theo summary.json PASS; PPA packer benchmark nằm riêng results/packer_ppa/, chưa phải full MAC/Gate4.

Nghiệm thu07/10: summary.json PASS,5.947.048 packer và4.931.624 chain checks,0 mismatch trên ModelSim; đối chuẩn từng field/flags, hai mode/bốn format. Phạm vi đơn vị tuần8, không phải MAC handshake/Gate2/3. PPA packer riêng RNE thêm29 LUT4/44FF so TRUNC trên EP4CE22; fmax ranges chồng lấn và100MHz chưa đạt mọi seed.

## 18. Đối chiếu journal 2024 để xác minh baseline — 08/10/2026

Đã đọc toàn văn *Area-Efficient Iterative Logarithmic Approximate Multipliers for IEEE 754 and Posit Numbers*, TVLSI32(3):455–467, DOI [10.1109/TVLSI.2024.3354726](https://doi.org/10.1109/TVLSI.2024.3354726). [Trang tác giả](https://sites.google.com/view/sunwoong/publications) xác nhận publication; toàn văn đọc từ [bản công khai trên Scribd](https://www.scribd.com/document/818436812/Area-Efficient-Iterative-Logarithmic-Approximate-Multipliers-for-IEEE-754-and-Posit-Numbers). IEEE PDF trả HTTP418; chưa lưu PDF2024 cục bộ. Đã kiểm hình/bảng trực quan, không dùng mô tả AI của trang đăng lại.

| Đối chiếu nguồn | Kết luận cho ứng viên `source` |
| --- | --- |
| §III-A, tr.458: RND ngưỡng1,5, complement không cộng1 | Củng cố recurrence nghiên cứu; không đổi profile normative |
| Algorithm2/TableIV, tr.459; §VI-B, tr.462: PT2, cut11 và cut5 bổ sung | Đủ căn cứ kiểm predictor n2/7-bit theo pattern; cách đệm Q12 vẫn là giả định |
| Fig.3/§III-C, tr.460: shift=l1−lk, exponent dùng l1 | Củng cố `anchor_first` |
| Fig.3 và §V: mb=12, nhãn adder13 bit khi tb1=11 | Chưa xác nhận guard12 của ứng viên; cần hợp đồng hidden/sign/carry/cut đầy đủ |
| §V/VI-A: posit32 ES2, oracle posit exact; 200M random, bốn ngưỡng nghiêm ngặt | Khác phép đo ES3/FP32 của TableI2021; chưa tìm được seed/PRNG/phân bố/filter đủ để tái lập |

TableI2024 là ví dụ −7,89; kết quả độ chính xác nằm ở Fig.7–9. Không dùng bảng này thay TableI2021.

### Kiểm PT2 độc lập

`test/test_journal2024_pt2.cpp` diễn giải các run bit của TableIV trực tiếp, không gọi SAC hoặc recurrence complement trong reference. Miền kiểm là **toàn bộ128 prefix7, đệm5 bit0 thành Q12**, zero bypass; so lỗi tuyệt đối với `paper_pattern_prediction_error`. Đây là kiểm diễn giải của dự án, chưa phải đối chiếu LUT nguyên bản tác giả.

**PASS:128 entry,0 mismatch.** Hai entry126/127 khác LUT legacy: source/table error=0, legacy error=32 đơn vị Q12. Kiểm này không xác nhận tie-A, score E/M, low5 thực tế hoặc accumulator_guard=12.

```powershell
# Từ thư mục Posit_MAC; MinGW GCC13-win32 trong WSL:
wsl.exe bash -lc "cd '/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC' && x86_64-w64-mingw32-g++ -O2 -std=c++17 -Wall -Wextra -Werror -static-libgcc -static-libstdc++ -Il1/include l1/test/test_journal2024_pt2.cpp -o l1/test_journal2024_pt2.exe"
.\l1\test_journal2024_pt2.exe results/paper_journal2024/pt2_comparison.csv
```

Kiểm deterministic, không dùng seed/SoftPosit. CSV, log, compiler/lệnh, hash và giới hạn ở `results/paper_journal2024/{pt2_comparison.csv,pt2_check.log,summary.json}`.

**Phương án1 đạt một phần:** đã tăng căn cứ cho predictor và anchor; chưa xác minh baseline gốc hoàn chỉnh. Tie policy, guard/cut và generator gốc còn mở. Tuần4/provenance giữ **processing**; không đổi L1 production/RTL, không chạy lại200M hoặc PPA trong đợt này. Max lệch0,984213 điểm % là nghiệm thu corpus trước đây (§14), không phải kết quả đo mới từ journal2024. Bước tiếp theo là đối chiếu width/cut của Fig.3 bằng profile riêng trước khi cân nhắc đo lại TableI.

## 19. Chốt và kiểm width/cut theo Fig.3 — 08/10/2026

Đã kiểm lại Fig.3 tr.460/§III-C của journal2024 (§18). Nhãn đường fraction là `22−tb1+1=12`; đường cộng/thanh ghi kết quả là `22−tb1+2=13` khi tb1=11. Paper lược bỏ logic cờ và chưa công bố mã hóa hidden/carry đầy đủ. Hợp đồng dưới đây là **baseline L1 tái dựng hữu hạn có kiểm chứng**, chưa chứng minh bố trí thanh ghi nguyên bản của tác giả. Không thay width của RTL normative §5.6.

### Hợp đồng profile `fig3`

| Thành phần | Hợp đồng đã chốt |
| --- | --- |
| Đầu vào | W=12 fraction sau cut11; significand nguyên Y=4096+fraction, đủ13 bit kể cả hidden |
| Predictor/recurrence | Giữ PT2 prefix7 đệmQ12, tie-A, complement; n đếm tổng số hạng. Hai giả định PT2 padding/tie vẫn được công bố |
| Mốc căn | p1 là power đầu tiên, tương đối0/1; dk=p1−pk>=0, sf ban đầu=sfX+sfY+p1 |
| Cắt số hạng | Tk=floor(Y/2^dk), dịch logical; dk>=13 trả0. Cắt độ lớn dương trước khi áp coefficient ±1 |
| Accumulator | A0=0; Ak=Ak−1+ck*Tk. Payload13 bit và cờ carry riêng; A=payload+(carry<<13), tổng độ lớn Q2.12 đủ14 bit, **guard thấp=0** |
| Tràn/borrow | Carry phải đi cùng feedback, có thể được xóa bởi phép trừ sau đó. Reject borrow/tràn ngoài14 bit; không wrap hoặc saturate nội bộ |
| Chuẩn hóa/cuối vòng | Giữ mốc Q12 cố định trong feedback; normalize khi kết thúc: A>=8192 thì dịch phải và tăng sf, A<4096 thì dịch trái và giảm sf. Fraction đầu ra12 bit |
| Output/ngoại lệ | TableI dùng packTRUNC; suite kiểm cả RNE. Zero/NaR/dấu/saturation giữ hợp đồng PaperMultiplier. Đuôi từng term/phần dư bỏ không được phục hồi thành sticky tổng |

13 bit payload + carry là cách biểu diễn địa phương cho phần cờ bị lược khỏi hình. Không gọi toàn bộ accumulator là13 bit, không gọi carry là fractional guard, không suy rằng Fig.3 xác nhận guard12. `source` cũ giữ Q24 đến pack; `fig3` giữ Q12. Cả width nội bộ và độ chính xác đầu ra vì thế được ghi rõ theo profile.

Ví dụ X=6143,Y=8191: hai term đầu cho A=8191+4095=12286; payload13=4094,carry=1. Bỏ carry sẽ mất kết quả. Với X=6144,Y=4097: term âm thứ hai là−floor(4097/4)=−1024, A=3073; cần normalize trái. Arithmetic-shift trực tiếp số âm sẽ cho−1025, sai vị trí cắt. Trace đủ vòng ở `results/paper_fig3/trace_{windows,linux}.csv`.

### Kiểm chức năng

`include/paper_fig3_accumulator.hpp` thực thi payload/carry có giới hạn; `paper_fig3_config()` chọn guard0/anchor-first và OPS source. Nhánh anchor-first/guard0 của PaperMultiplier dùng accumulator này. `paper_source_config()` guard12 và mặc định legacy giữ nguyên. CLI bộ đo thêm `--profile fig3`.

`test/test_paper_fig3.cpp` dùng signed residual Q96 độc lập, phép chia nguyên kiểm cut và kiểm từng trạng thái. **Windows/Linux/UBSan đều PASS509.407.337 đối chiếu/lượt**: vét cạn16.777.216 cặp mantissa Q12, các prefix đến n8;100.100 cặp raw/corner x n1..8, hai mode xen kẽ, fixture Fig.4 năm2021 và ma trận width/dịch. Max A=12286<16384;21.294.248 trạng thái carry,224.735 lần carry được xóa,45.400.064 term dịch>=13. Đếm đối chiếu gồm nhiều điều kiện trên cùng một vector, không phải509 triệu đầu vào độc lập.

Trace Windows/Linux và smoke1M seed271828 khớp rows/counters/fingerprint. Regression liên quan PASS: source29.878.945, anchor self-test3.300.128, legacy531.039. Không chạy lại SoftPosit/RTL/PPA vì thuật toán normative và RTL không đổi.

### TableI: width/cut đúng chức năng, chưa đạt tiêu chí số học

N=200.000.000 accepted, seed271828, grid24/std::mt19937_64, oracle FP32_RNE trước cut11, packTRUNC, ngưỡng `<` bằng số nguyên. Attempted200.000.021, loại zero21, draws400.000.042; fingerprint `04478e811a897da7`. Cùng lượt chạy giữ baseline/minpop/relative/source làm control;12 ô source và các control baseline/relative khớp log trước ở độ chính xác hiển thị.

| n | Err<0,1% | Err<0,5% | Err<1% | Err<5% | Max lệch Proposed (điểm %) |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2 | 8,955743% | 31,320320% | 49,328132% | 95,467135% | 0,914257 |
| 3 | 43,397680% | 82,852613% | 94,982466% | 100,000000% | 1,292319 |
| 4 | 86,183853% | 99,797454% | 100,000000% | 100,000000% | 0,906148 |

**NOT_REPRODUCED/exit1**, max khoảng1,2923 điểm %, vượt yêu cầu<=1. Đây là lệch tỷ lệ đạt ngưỡng của bảng, không phải sai số của từng tích. Source guard12 cùng lượt giữ max0,984213. Tỷ lệ/gap in6 chữ số có thể chênh1 đơn vị cuối do làm tròn. Năm pilot10M seed314159/314160/42/2026/20261004 đều vượt1: max1,281240–1,316300 điểm %. Không chọn lại seed hoặc tăng guard để ép đạt.

```powershell
# Từ thư mục Posit_MAC:
wsl.exe bash -lc "cd '/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC' && make -C l1 test_paper_fig3 test_paper_fig3.exe test_paper_fig3_ubsan test_paper_table1.exe"
.\l1\test_paper_fig3.exe results/paper_fig3/trace_windows.csv
.\l1\test_paper_table1.exe --samples 200000000 --seed 271828 --profile fig3 --require-match
# Linux: make -C l1 test-paper-fig3; make -C l1 paper-table1-fig3
```

Compiler Linux g++15.2.0, Windows MinGW GCC13-win32; SoftPosit không dùng trong bộ kiểm/đo này. Build/regression/pilot/200M/CSV/hash và lệnh ở `results/paper_fig3/summary.json` cùng các log. `make test-paper-source` bổ sung suite Fig3.

**Mốc width/cut L1 hoàn thành; baseline TableI chưa nghiệm thu, tuần4 giữ processing.** Đã có baseline hữu hạn tái dựng để review/đối chuẩn sau này. Còn cần xác minh tie/PT2 padding, nguồn generator và logic normalize/cờ tác giả trước khi khẳng định nguyên nhân gap hay bit-exact gốc. Chưa lấy profile fig3 thay RTL normative hoặc dùng guard12 đạt bảng làm bằng chứng width paper.

## 20. Phương án3 — kiểm các ứng viên bằng vector phân biệt — 08/10/2026

### Bước1: tìm vector cho kết quả khác nhau

`test/paper_discriminator_study.hpp` và `test/test_paper_discriminators.cpp` là harness nghiên cứu riêng. Có10 ứng viên: fig3, tie-B, legacy7, input-anchor, exact-residual, guard1/cut12, guard12/cut12, source-uncut, post-sum/cut12 và signed-floor. Mỗi ứng viên thay một yếu tố so fig3; riêng so guard12/cut12 với source-uncut tách điểm cắt đầu ra. Không thay API/mặc định L1 hoặc RTL normative.

Tìm kiếm có thứ tự trên199.800 cặp `(A,B,n)` chọn292 bản ghi:32 mỗi nhóm prefix126/127, tie, ngưỡng1,5, anchor, cut từng term, guard, width đầu ra, cut sau tổng và đuôi âm; thêm4 fixture trực tiếp. Gộp trùng theo `(A,B,n,force_A)` còn206 trường hợp. Xem [vector tiêu biểu](../results/paper_discriminators/representative_vectors.csv) và `windows/vectors.csv` để tái chạy.

### Bước2: xuất và kiểm trace từng vòng

Các file `traces.csv`, `outputs.csv`, `first_differences.csv` trong từng thư mục Windows/Linux/UBSan ghi operand chọn, prefix/score/tie, mantissa/exponent trước và sau SAC, power/coefficient, anchor/shift, term/tail, accumulator/precision và output. `acc_fraction_bits` xác định đơn vị của số nguyên accumulator; cột Q12 chỉ là phép chiếu xuống, không chứng minh các guard thấp bằng0. Với post-sum, `exact_sum_Q96_hex` giữ tổng chính xác, còn term-magnitude là phép chiếu trên lưới báo cáo. Shift âm của input-anchor biểu thị dịch trái.

**PASS205.882 đối chiếu/nền tảng** trên Windows, Linux và Linux UBSan. Oracle signed-residual Q96 và chia số nguyên kiểm powers/coefficient, các accumulator và output; thêm10.000 cặp raw seed20261008, n1..8, cả10 ứng viên. Parser/packer và predictor đã kiểm trước được dùng chung; đây là kiểm tính nhất quán của các giả thuyết địa phương, không phải oracle RTL tác giả. Toàn bộ CSV ở ba nền tảng khớp về nội dung; pilot1M Windows/Linux khớp exact counts/counters/fingerprint.

### Bước3: đối chiếu nguồn và loại giả thuyết có bằng chứng

Đọc lại hình gốc2021, Fig.4/5 trên trang PDF4; bản render ở `results/paper_discriminators/paper2021_page3.png`. InputX=`0x1c900000` (Q12=5248,sf=-10), inputY=`0x3c820000` (Q12=4616,sf=-1). Hình chọn X để xấp xỉ và không thể hiện OPS, nên fixture ép X; **không dùng nó để quyết định tie-A/tie-B**. Ba số hạng gồm hidden và hai vòng fraction: powers0,-2,-5, coefficients+,+,+; accumulator Q12 lần lượt4616,5770,5914. Term cuối4616/32=144,25, phần hiển thị12 bit giữ144; fraction cuối`0x71a`.

| Đối chiếu | Kết quả | Kết luận |
| --- | --- | --- |
| Output Fig.4 và Fig.5 concat exponent3+fraction12+zero14 | `0x1ae34000` | Căn cứ trực tiếp cho fraction đầu ra12 bit của cấu hình hình vẽ |
| source-uncut giữ Q24 đến pack | `0x1ae34800` | **Loại khỏi baseline bit-exact2021**; chỉ giữ làm control thống kê lịch sử |
| guard12/cut12 và8 ứng viên còn lại | `0x1ae34000`, trace chiếu Q12 khớp | Chưa xác định được precision nội bộ, tie hay nhánh p1=1 từ fixture này |

`hypotheses.csv` tách bằng chứng trực tiếp, bất đồng với hợp đồng đọc từ2024 và phần chưa xác minh. Fig.3/§III-C hỗ trợ anchor=l1 và logical-shift magnitude trước add/sub; §III-A mô tả complement không+1. Input-anchor, exact-residual và signed-floor là control khác hợp đồng đó; không gọi việc loại theo hợp đồng là đối chiếu với trace tác giả chưa được công bố. Prefix126/127 còn phụ thuộc giả định đệm prefix7 lênQ12. Chưa có trace nguồn riêng cho tie, guard hoặc đuôi âm để chọn duy nhất một ứng viên.

### Bước4: đo xác nhận cùng corpus sau khi đối chiếu nguồn

Chỉ đưa thay đổi có căn cứ mới là **cắt fraction đầu ra về12 bit** vào phép đo; giữ fig3 và source-uncut làm paired controls. Guard12 bên trong vẫn là giả thuyết, không trở thành width tác giả vì output khớp. Pilot1M seed271828 cho max gap fig3=1,241000, guard12/cut12=1,292000, source-uncut=0,936500 điểm %; pilot không đủ mẫu nghiệm thu.

Lệnh tái chạy từ thư mục dự án (build bằng WSL):

```sh
make -C l1 test_paper_discriminators test_paper_discriminators.exe test_paper_discriminators_ubsan
./l1/test_paper_discriminators results/paper_discriminators/linux
./l1/test_paper_discriminators_ubsan results/paper_discriminators/ubsan
./l1/test_paper_discriminators --measure results/paper_discriminators/acceptance 200000000 271828
python scripts/summarize_paper_discriminators.py
```

Các thư mục output phải tồn tại. Trên PowerShell dùng `./l1/test_paper_discriminators.exe results/paper_discriminators/windows`. Linux g++15.2.0/Windows MinGW GCC13, cờO3/C++17/Wall/Wextra/Werror; UBSanO1/no-recover. Không dùng SoftPosit trực tiếp cho phép đo nghiên cứu này; oracle FP32_RNE đã được kiểm trước bằng số nguyên. Compiler, seed, lệnh, hash source/binary/log/corpus và matrix bằng chứng ở `results/paper_discriminators/summary.json`.

`--measure` trả0 khi đo/xuất dữ liệu thành công, **không phải exit nghiệm thu TableI**. Điều kiện số học được ghi riêng:200M accepted và maxgap<=1 điểm %; baseline gốc còn yêu cầu khớp nguồn/provenance. Không đổi seed/OPS/guard để ép bảng, không lấy kết quả phép đo làm bằng chứng PPA.

**Kết quả200M accepted, seed271828:** cả ba profile dùng chung attempted200.000.021, loại zero21, draws400.000.042, fingerprint`04478e811a897da7`. Các nhóm loại khác0. Oracle là tích FP32_RNE của input gốc trước cut11, posit32ES3, grid24/std::mt19937_64, ngưỡng nghiêm ngặt bằng số nguyên; không thay các giả định để chọn ứng viên thắng. Đã kiểm đủ36 ô từ exact counts; fig3/source khớp kết quả200M trước ở độ chính xác log.

| Profile | Max lệch TableI (điểm %) | Khớp output Fig.4 | Kết luận |
| --- | --- | --- | --- |
| fig3 | 1,2923195 | Có | Chưa đạt ngưỡng thống kê |
| guard12_pack12 | 1,3387730 | Có | Chưa đạt ngưỡng thống kê; guard nội bộ chưa xác minh |
| source_uncut | 0,9842130 | Không | Đạt ngưỡng thống kê riêng, bị loại khỏi baseline bit-exact2021 |

Tỷ lệ guard12/cut12 theo thứ tự Err<0,1 / <0,5 / <1 / <5%:

| n | Tỷ lệ đo (%) | Max gap hàng (điểm %) |
| --- | --- | --- |
| 2 | 8,8971365 / 31,3000725 / 49,3159020 / 95,4660355 | 0,9728635 |
| 3 | 43,3512270 / 82,8938590 / 94,9924150 / 100 | 1,3387730 |
| 4 | 86,3007185 / 99,7994460 / 100 / 100 | 0,7892815 |

Chi tiết36 ô/counts/gap: [measurement.csv](../results/paper_discriminators/acceptance/measurement.csv); kiểm tổng hợp và hash: [summary.json](../results/paper_discriminators/summary.json). Suite/harness và cả bốn bước **hoàn thành**, nhưng **chưa có ứng viên được nghiệm thu baseline gốc**. Tuần4 giữ processing. Bước có căn cứ tiếp theo là tìm trace/LUT tác giả cho equal-score/prefix126–127/đuôi âm và normalize/cờ, đồng thời làm rõ generator; không quét thêm tham số chỉ để ép TableI.

## 21. Khởi động tuần9 và kế hoạch thực thi — 08/10/2026

Đã chốt giao diện/context/token và lịch drain tại SPEC §5.5-A; làm rõ normalization FLOOR trên Q(FRAC_W) tại §5.7 để giữ tương đương `mul_norm.hpp`. Không đổi mô hình L1 đã nghiệm thu, n normative hoặc cfg_ops. Kế hoạch tuần9 với mốc/điều kiện chuyển bước nằm trong [PLAN mục7](PLAN.md#7-kế-hoạch-thực-thi-tuần9--lõi-nhân-rtl-và-đối-chiếu-paper).

Đã hiện thực OPS/SAC tổ hợp normative và generator `test/gen_week9_frontend.cpp` dùng ops_swap/SacState + oracle scalar độc lập. ModelSim159.820 OPS +167.620 SAC,0 mismatch; generator Linux/Windows/UBSan và fixture cross-platform khớp, seed20261008. Build GCC15.2.0/MinGW GCC13 với Werror; UBSan không lỗi. Chi tiết cổng/lệnh/scope ở README RTL mục7 và `results/week9_frontend/summary.json`.

Tuần9 **processing**: mới hoàn thành W9-01/02; SBM/normalize, core tuần tự, multiplier top và Gate2 còn triển khai. Lõi paper tối thiểu là mốc nghiên cứu riêng; chức năng OPS/SAC normative không chứng minh baseline gốc hoặc khớp TableI.

## 22. RTL multiplier tuần9 — 09/10/2026

W9-03 đã kiểm shifter, cộng tổ hợp, normalize/adapter:252.455 commit trên width1/5/12/26/27, hai scheme,0 mismatch. Bank `sbm_accum` được kiểm trong core; FLOOR bỏ padding trước normalize, không đưa input_cut vào numerical sticky.

W9-R1 chốt interface `paper_ops_comb`/`paper_step_comb`: Q12/prefix7 đệm0, tie-A, anchor số hạng đầu và payload13+carry1 là giả định tái dựng; RND/complement, coefficient âm và cut trước cộng/trừ ghi riêng. W9-R2 đạt843 commit,293 bản ghi (292 bản ghi corpus/206 trường hợp phân biệt + một fixture Fig.4),0 mismatch. Output force-X=0x1ae34000; kiểm thêm đủ128 entry PT2 và tie-A đạt. Không có bằng chứng mới để chạy R3 hoặc xác nhận RTL tác giả.

W9-04 đạt39.580 giao dịch hoàn tất và420 lượt reset hủy; width1/5/12/26/27, exact vượt N_MAX, n=0/early-stop, done=t+2 hoặc3, drain và context cố định đều được kiểm. W9-05 tích hợp parser A/B → M0/core → norm → packer với một slot dự trữ; pilot bản cuối31.840 giao dịch +160 reset hủy,0 mismatch. Reset bridge lấy mẫu rst_n; out_valid bị chặn tại cạnh reset, mỗi leaf nhả qua hai FF. RNE: L_valid=max(1,t)+7, TRUNC:max(1,t)+6; handshake khi không stall sau đó một cạnh. Thử config reserved/n>N_MAX, NaR/zero, stall dài, cạnh reset và giữ thứ tự.

ModelSim đối chiếu 16.815.920 giao dịch, hủy 80.080 giao dịch bằng reset,0 mismatch.

Corpus random-bit10.080.000 dòng chỉ kiểm số học, không đủ coverage regime dài. Đã bổ sung corpus phân tầng16.896.000 dòng/16 profile, có36 ô mode/ops/n, nhóm regime–dấu và fraction đặc thù theo §6.3. Generator phân tầng kiểm3.168.256 exact/RNE với L0 và1.056.256 với oracle ES3 độc lập; chỉ số này chưa thay kiểm RTL. Chạy riêng từng profile bằng verify_week9_multiplier_parallel.ps1; pilot đối chuẩn cùng checker đạt31.840 giao dịch/0 mismatch. Lượt16-DUT cũ đã dừng và không được tính nghiệm thu. Generator/fixture không thay nghiệm thu RTL. Verilator chưa có; `make lint` hiện trả lỗi khi thiếu công cụ thay vì skip rồi báo thành công. Harness C++ và `scripts/verify_week9_verilator.sh` đã chuẩn bị nhưng chưa build/chạy, cần đối chuẩn pilot khi có công cụ. Không tự cài công cụ ngoài quyền đã cấp.

Quartus13 phân tích/tổng hợp NB32/ES2/FLOOR/RNE đạt0 lỗi,14 warning đã phân loại (license parallel, attribute ASYNC_REG của Xilinx và constant resize có giới hạn); không có cảnh báo latch. Đây không thay strict lint, STA, CDC, PPA hay Gate4. Chỉ đổi generate/genvar để hỗ trợ compiler cũ trong hai shifter/OPS, không đổi phương trình; đã chạy lại327.440 frontend vector và843 paper commit đạt.

Bằng chứng, compiler, seed20261009, SoftPosit library hash, lệnh và SHA256: `results/week9_implementation/summary.json`; các log ở `results/week9_arithmetic`, `week9_paper`, `week9_core`, `week9_multiplier`. Gate2/tuần9 vẫn processing do lint/harness chính thức còn thiếu (coverage chức năng phân tầng đã đạt); tuần4/provenance paper giữ processing. GitHub đã push checkpoint 0ae39c4 lên main bằng checkout riêng trong Posit_MAC; kết quả lượt lớn được bổ sung cuối phiên.

Build generator bằng các target `gen_week9_arithmetic`, `gen_week9_core`, `gen_week9_paper`, `gen_week9_multiplier` trong Makefile L1, cùng hậu tố `.exe` và `_ubsan`. `gen_week9_paper` dùng corpus có sẵn, không đổi vector/seed. ES3 exact/RNE dùng decode + product nguyên + encoder bit-list độc lập, không gọi parser/packer L1. SoftPosit chỉ dùng ở ES0/1/2.

## 23. Top paper hồi tiếp tự động — 09/10/2026

`paper_mul_iter` là top structural riêng, logic trong `paper_mul_wrapper` và `paper_norm_comb`; cố định posit32/ES3, fraction12, PT2 prefix7 đệm0/tie-A, complement/RND, anchor số hạng đầu, accumulator Q2.12/14 bit và per-term FLOOR trước áp dấu, output cut12/TRUNC. Các lựa chọn tái dựng giữ nguyên; không đổi hợp đồng normative. `n_terms=1..8` đếm cả số hạng đầu, khác `cfg_n` normative; 0 và9..15 không được nhận. `force_a` phục vụ fixture/so fixed-A, bình thường0. NaR ưu tiên Zero.

E0 nhận A/B/n/force nguyên tử qua valid/ready; chốt X/Y, sign, sf_base, anchor và limit. Mỗi cạnh tiếp theo tự cập nhật một term cùng mantissa/exponent/coefficient/accumulator; dừng khi residual0 hoặc đủ n_terms. Sau t commit, cạnh E(t+1) chốt kết quả normalize→packer và phát out_valid; special t=0. Một slot giữ kết quả tới retire, không nhận thêm khi busy/stalled. `reset_n` assert bất đồng bộ, deassert qua hai FF tại wrapper; reset hủy giao dịch và chặn valid/ready/trace. Đây là lịch research địa phương, chưa xác nhận pipeline/timing của tác giả.

ModelSim10.1d đạt **17.181 giao dịch hoàn tất /65.710 commit,0 mismatch**. Bao gồm292 bản ghi corpus phân biệt cũ + fixture Fig.4, toàn4096 fraction A Q12 ở n1/3/8,100 cặp corner x3 giá trị n x2 policy force,500 cặp random x n1..8; seed20261009. Đối chiếu thụ động trace trước/sau từng vòng và output; không cấp lại trạng thái, không hierarchical force/write. Audit xác nhận843 commit cũ giống hoàn toàn, Linux/Windows/UBSan fixture MATCH; reference residual Q96 độc lập kiểm power/coefficient/accumulator/pack.

Fig.4 force-X: accumulator4616→5770→5914, output **0x1ae34000**. Kiểm216 special,24.036 term âm,14.199 term0,45.468 term có tail,1.082 dừng sớm,178 stall96 chu kỳ và4 reset hủy (sau capture, giữa vòng, PACK, HOLD) đạt; config/context đổi khi busy không ảnh hưởng giao dịch đang sở hữu. Không nghiệm thu flags riêng của paper, code coverage, lint, STA/PPA hoặc Gate2 bằng suite này.

Bằng chứng: `results/paper_top/windows/summary.json`, `results/paper_top/audit.json`; lệnh `make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan`, `scripts/verify_paper_top_modelsim.ps1`, `scripts/audit_paper_top.py`. Compiler/seed/lệnh/hash được lưu cùng kết quả. Không có thay đổi số học hoặc bằng chứng nguồn mới: **không chạy pilot TableI**, baseline gốc và tuần4 tiếp tục processing; Gate2 normative giữ trạng thái trước đó.

## 24. Rà soát SAC/n và packer theo nguồn — 09/10/2026

Đọc trực quan PDF2019 p2–5 (Algorithm1, Eq10–12, Table1/3/4, Fig4) và PDF2021 p3–4 (Fig3–6, TableI–III). RND/complement của2019 có căn cứ trực tiếp và fixtureTable1 tái lập powers−1/−5/−8, coefficients+/−/−. Tuy nhiên mô tả2021 III-C/Fig4 quét bit1 và n1/2 là hai lần cập nhật fraction sau khởi tạoY. Ví dụ này chỉ có term dương, nên không chứng minh nhánh round-up/term âm của RND. Không áp dụng tự động mọi chi tiết2024 cho2021.

Nghiên cứu deterministic163.840 cặp `(X_Q12,Y_Q12,n)` (4096 X,5 Y,n1..8,force-A để tách OPS) cho thấy RND và literal bit-scan không tương đương, cả khi cùng tổng số hạng hoặc khi scan tính fraction riêng. Ví dụ X6144,Y4097,n_total2: RND0x42008000, scan0x42004000. Đây là vector phân biệt giữa mô hình, chưa có output tác giả cho vector này. Fig4 force-X: n_fraction2/n_total3 cho0x1ae34000; n_total2 chỉ cho0x1ad14000. Mười hai ô Kim2019 được chép nguyên sang cột Kim2021 hỗ trợ nhãn comparator, nhưng chưa khóa ngữ nghĩa SAC/n của Proposed TableI. Giữ `n_terms` API địa phương; không tự đổi TableI thành n+1.

Reference packer C++ độc lập diễn giải đúng cổng Fig5(b): m=Rgm[4:0] XOR {5{Rgm[5]}}; hai bit đầu là XNOR/XOR Rgm[5] với sign, payload29 XOR sign; dịch phải arithmetic trên31 bit rồi cộng sign và ghép Out[31]. Không gọi parser/packer L1 để tạo expected. Kiểm3.940.352 trường hợp sf−240..240 ×4096 fraction ×2 dấu với L1 đạt; ModelSim10.1d kiểm155.648 trường hợp với RTL TRUNC đạt0 mismatch. Linux/Windows/UBSan fixture MATCH, không dùng PRNG. Có8.448 raw/clamped differences ngoài miền sf−240..240 (underflow/điều khiển regime6bit wrap): clamp là chính sách đồ án, hình lược bỏ cờ/range handling; không tính các khác biệt này là lỗi RTL hoặc khẳng định tác giả dùng clamp đó.

Có thể loại khác biệt mã hóa packer trên miền Q12/scale đã kiểm; chưa loại normalize/cut nội bộ, OPS, generator hoặc khác biệt recurrence/n. Không sửa normative hay top RND đã đóng băng; không chạy pilotTableI vì chưa chọn được thay đổi số học có xác nhận nguồn duy nhất. Audit đã hoàn thành, baseline gốc/tuần4 và Gate2 vẫn processing. Bước tiếp theo cần trace/code hoặc xác nhận tác giả cho SAC/n2021 ở vector round-up, tie/prefix và internal cut; không dò seed/tham số.

Bằng chứng: results/paper_contract_audit/{summary.json,windows/summary.json,windows/source2019_trace.csv,windows/source2021_count.csv,windows/divergent.csv,windows/sac_counts.csv}; PDF/RTL/fixture SHA256, compiler và lệnh trong summary. Build `make -C l1 test_paper_contract_audit test_paper_contract_audit.exe test_paper_contract_audit_ubsan`; chạy `scripts/verify_paper_contract_modelsim.ps1` rồi `scripts/summarize_paper_contract_audit.py`.

## 25. Pilot tái hiện Posit của journal2024 — 09/10/2026

Đối chiếu §III-A/C, §V, §VI-A/D, TableVI tr.462 và Fig9 tr.463 của DOI10.1109/TVLSI.2024.3354726 qua [toàn văn công khai](https://www.scribd.com/document/818436812/Area-Efficient-Iterative-Logarithmic-Approximate-Multipliers-for-IEEE-754-and-Posit-Numbers). Đây là kiểm **nhánh Proposed Posit của Fig9**, không phải triển khai đủ các comparator FP32/FP64 hoặc riêng đường B trong Fig7. B/C/S/T của journal lần lượt là baseline biểu diễn lũy thừa, hội tụ sai số, chọn toán hạng và truncation; không đồng nhất chữ B với tên profile `baseline` lịch sử của dự án.

`test/test_journal2024_measurement.cpp` dùng `PaperMultiplier<32,2>`: Q12, RND/complement không+1, PT2 sai số tuyệt đối prefix7 đệm0, tie-A, anchor số hạng đầu, cut từng term FLOOR trước áp dấu, outputcut12/TRUNC. **n đếm tổng số hạng**, không đổi n+1 để khớp biểu đồ. Oracle là **SoftPosit0.4.1 `l0_p32_mul` ES2**, khác FP32_RNE/ES3 của TableI2021. Không sửa arithmetic/header/RTL normative hoặc top paper ES3 đã đóng băng.

### Kiểm chức năng và ví dụ nguồn

Linux/Windows/UBSan mỗi lượt self-test PASS **600.127 đối chiếu,0 mismatch**: L1 exact/L0 trên100 corner và100.000 random; comparator ngưỡng bằng số nguyên đối chiếu decode SoftPosit, kiểm tie nghiêm ngặt và dấu;100.000 phép conversion; trace TableVI. CSV/trace/counters/fingerprint của hai smoke1M Linux/Windows MATCH; UBSan10.000 cặp PASS.

TableVI ép X theo nguồn: X=`0x1d200000`,Y=`0x31040000`; mantissaQ12 là5248/4616. Với n_total2, accumulator4616→5770 và output**`0x15a28000`**, khớp fraction `(1).011010001010` được in. Nhưng SAC còn mantissa chuẩn hóa4096/phần dư khác0; chính bảng in `t2=(0).001...`, trong khi đoạn văn nói `t2=0` và dừng. Với n_total3, accumulator thêm5914, output`0x15c68000`, phần dư mới hết. **Đây là bất nhất bảng–đoạn văn có thể xác minh, chưa chứng minh số liệu Fig9 sai.** Output n2 được giải thích bằng hết ngân sách hai số hạng, không phải early-stop do dư0.

### Pilot thống kê

Chốt trước seed271828, `std::mt19937_64`, hai phân bố địa phương: uint32 rawPosit toàn miền dấu và uniform-value grid24[0,1) chuyển Posit bằng L0. Loại inputZero/NaR với counters, giữ finite saturation trong corpus; oracle dùng input trước cut. Đo strict `100*|O-I|/|I| < threshold` bằng số nguyên, denominator dùng độ lớn để hỗ trợ số âm. Paper chưa công bố generator/seed/filter đủ để gọi hai phân bố này là corpus tác giả.

| n_total | RawPosit10M: Err<0,1 /0,5 /1 /5% | Value[0,1)10M: cùng ngưỡng | Fig9 Err<0,1% đọc trực quan |
| --- | --- | --- | --- |
| 2 | 8,954950 /31,354780 /49,354220 /95,469770 | 8,963250 /31,342550 /49,349190 /95,470840 | Khoảng53–57% |
| 3 | 43,435180 /82,879220 /94,984660 /99,999980 | 43,430780 /82,884860 /94,996880 /100 | Khoảng70–74% |
| 4 | 86,202990 /99,797000 /99,999840 /99,999980 | 86,197840 /99,795980 /100 /100 | Khoảng91–95% |
| 5 | 99,530540 /99,999680 /99,999840 /99,999980 | 99,531590 /100 /100 /100 | Khoảng99–100% |

Các khoảng Fig9 là **ước lượng thô từ biểu đồ**, không phải bảng số liệu gốc hoặc phép số hóa đủ chính xác để nghiệm thu≤1điểm%. Ngay với khoảng rộng này, rawPosit n2 cách ít nhất44,04505điểm%. Sai số lấy mẫu95% xấp xỉ tối đa±0,031điểm% trên10M với giả định mẫu độc lập; tăng lên200M không giải quyết được gap hiện tại. Không chạy full200M trong phiên.

Đối chứng OPS lý tưởng kiểm cả hướng ép A/ép B, lấy hướng đạt từng ngưỡng: cận trên Err<0,1% của n2 là**9,667460%**, n3=49,179190%, n4=92,982680%, n5=99,972790%. Cận này **chỉ áp trong cùng corpus/recurrence/width/cut/output**, không áp cho mọi kiến trúc khả dĩ của tác giả. Nó cho thấy chỉ đổi selector trong hợp đồng hiện tại không đủ giải thích gap n2; không dùng selector oracle làm cải tiến có thể triển khai.

**Kết quả:** kiểm chức năng/trace/pilot hoàn thành; baseline gốc2024 **NOT_REPRODUCED/processing**. Chưa có căn cứ kết luận TableI2021 hoặc Fig9 sai thống kê. Cần numeric data Fig9, quy ước n khi đo, generator/phân bố/filter và sourceRTL/LUT/cut/cờ tác giả. Không dò seed, n, guard hoặc dùng E/M để ép khớp. Chưa chạy RTL ES2/ModelSim trong audit này; Gate2 và tuần4 giữ trạng thái hiện hành.

Lệnh từ thư mục Posit_MAC, WSL `bash --noprofile --norc`, TMPDIR trong `results/paper_journal2024/measurement/tmp`:

```text
make -C l1 test_journal2024_measurement test_journal2024_measurement.exe test_journal2024_measurement_ubsan
./l1/test_journal2024_measurement 10000000 271828 raw-posit results/paper_journal2024/measurement/pilot_raw
./l1/test_journal2024_measurement 10000000 271828 value01 results/paper_journal2024/measurement/pilot_value
python scripts/audit_journal2024_measurement.py
```

GCC Linux15.2.0, MinGW13-win32, SoftPosit0.4.1; binary/source/hash/counters/fingerprint, compiler và lệnh tại `results/paper_journal2024/measurement/summary.json`. Hai CSV pilot giữ đủ16ô mỗi phân bố và cận OPS lý tưởng; trace nguồn tại `pilot_raw/table_vi_trace.csv`. Không coi exit0 của bộ đo là nghiệm thu Fig9.

## 26. Scoreboard trực tiếp và Gate2 — 10/10/2026


Gate2 multiplier **✅** theo mốc tuần9 (10/10/2026):16.815.920 giao dịch phân tầng/0 mismatch; scoreboard trực tiếp L1/L0 và oracle ES3; strict lint16/16 sạch; corner114.656/0 mismatch trên ModelSim và Verilator. Seed20261009, SoftPosit0.4.1, GCC15.2.0, Verilator5.032 và ModelSim10.1d; lệnh/hash/phiên bản lưu với bằng chứng.

Coverage chức năng đạt256/256 bin posit32, min4104 mẫu/bin,26241 operands/run/polarity và36 ô config/profile; structural coverage sau ghép corner: line 91.67–96.23%; branch 91.84–94.79%; toggle 73.10–87.33%, giữ các điểm chưa hit. Mốc này không quy định ngưỡng phần trăm structural coverage và không phải coverage100% hoặc signoff vật lý.

Trạng thái canonical tại `results/week9_implementation/gate2_acceptance.json`; hướng dẫn tái lập và giải thích phạm vi tại PLAN L1 mục7.11. Những mục processing trước đây là lịch sử. Ma trận cuối SPEC§6.7, tuần10 adder/tuần11 MAC-Gate3 và PPA/Gate4 còn mở; provenance/TableI giữ processing, không chạy lại TableI trong phiên này.

