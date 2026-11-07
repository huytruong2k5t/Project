# SPEC lõi IP Posit MAC xấp xỉ dạng lặp

**v1.29 — 04/11/2026.** Sinh viên: Đan Huy. Giữ hợp đồng approximate12/FULL_TERM của NF/F; **chốt phương án A cho NF/F**: hai lõi `posit_mac_nf` và `posit_mac_f` mục tiêu là lõi nhân–cộng thuần túy feed-forward (`D = A × B + C`), gỡ thanh ghi hồi tiếp nội bộ `accumulator_q` cùng `acc_mode`/`acc_clr` khỏi top IP để loại nút thắt F2F `accumulator_q → Parser C` (việc tích lũy lặp Posit32 nếu cần được đặt ở thanh ghi/harness bên ngoài cấp vào cổng `c`). Khóa quire Q12-1024 (W972/grid2^-480), hiện thực và kiểm chức năng. Không hạ ngưỡng nghiệm thu. Quire10M MAC/0 mismatch; timing100MHz chưa đạt, chưa gắn nhãn MAC_Q12_VERIFIED. Nhật ký, số đo và PASS riêng từng snapshot ở `results/`, [tiến độ](docs/TIEN_DO_DO_AN.md) và [Optimization](../doc/Optimization.md).

## 1. Mục tiêu và phạm vi

Thiết kế bằng SystemVerilog hai lõi nhân–cộng **non-fused (NF)** và **fused (F)** cho duy nhất **Posit(32,3)**. Cả hai dùng bộ nhân dịch–cộng approximate, giữ 12 bit fraction đầu vào, tích FULL_TERM 26 bit/Q24 và tối đa 12 vòng fraction để tính `D = A × B + C` theo luồng thẳng (feed-forward). NF/F khác vị trí làm tròn tích, không phải hai chế độ exact/approximate.

- Bắt buộc: Parser, OPS, SAC/SBM/core, bộ cộng, Packer RNE, valid/ready, reset, cờ trạng thái và kiểm chứng tự động (gồm cả giao dịch độc lập lẫn chuỗi tích lũy qua hồi tiếp ngoại vi `C_k = D_(k-1)`).
- Không có nhân exact phần cứng, `cfg_mode`, `EXACT_EN`, TRUNC hoặc lựa chọn FLOOR/STICKY_ACC trong cấu hình nghiệm thu. Lõi NF/F mục tiêu không giữ thanh ghi hồi tiếp Posit32 `accumulator_q` (`acc_mode`, `acc_clr`) nội bộ; đường hồi tiếp tích lũy Posit32 được đưa ra ngoài lõi IP (cấp qua cổng `c`), còn tích lũy độ chính xác rộng dùng riêng top mở rộng `posit_mac_quire` (§9). Độ rộng cố định; top không có public parameter đổi format/feature.
- NF/F là phạm vi nghiệm thu chính. Giao diện tích trước pack MUST cho phép mở rộng MAC quire theo §4.5; hợp đồng phần mở rộng ở §9. Chia/căn, chuyển đổi FP bằng phần cứng, ASIC và tái hiện toàn bộ số liệu bài báo ngoài mục tiêu. Chồng lấn giao dịch/đối chứng FP là mở rộng; baseline chỉ có một giao dịch đang xử lý.
- Oracle tính chính xác bằng phần mềm vẫn bắt buộc để kiểm thiết kế approximate và đo sai số; không tạo thêm mode của DUT.

**Profile mặc định MUST:** `cfg_ops=1`, `cfg_n=12`, approximate-only. Giữ lựa chọn runtime OPS0 và n0..11 để kiểm/đánh giá đánh đổi; đây không phải mode exact. n giới hạn số số hạng fraction, không giới hạn chiều dài chuỗi MAC. Early-stop khi hết bit 1 vẫn bắt buộc; không phát đủ 12 vòng rỗng chỉ để đạt số đếm.

**Quan hệ với bài báo:** Norris–Kim2021 §III-A/B/D chọn nb32/es3 và 12 bit fraction cao (không tính hidden), fraction thiếu được đệm 0. Đồ án kế thừa phạm vi này và kiến trúc dịch–cộng. FULL_TERM26/Q24 không cắt từng term, OPS min-popcount, RNE và NF/F/quire là hợp đồng được chốt của đồ án; không suy chúng là RTL gốc hoặc đã tái hiện Table I. Packer paper mô tả ghép 12 fraction; Packer đồ án dùng đầy đủ dữ liệu trước pack và RNE theo §2.

Nguồn checkpoint ngày02/11/2026 đã triển khai FULL_TERM dùng chung cho NF/F (lúc còn `acc_mode`/`acc_clr` nội bộ). Ngày04/11 đã hiện thực feed-forward theo v1.29, cập nhật TB/driver và kiểm lại: mỗi NF/F100k completed Verilator,49701 completed +299 reset-aborted ModelSim,0 mismatch. Matched synthesis F2F trước/sau: F6.777→5.340ns,NF9.344→8.945ns. [Bằng chứng và giới hạn](results/feedforward_a_20261104/summary.md). Chưa là release nghiệm thu52×10M/coverage hoặc timing sau route; không chuyển PASS/STA cũ sang nguồn mới.

## 2. Định dạng số

Đây là cấu hình tổng quát `n=32, es=3`, không đồng nhất với posit32 exponent hai bit của Posit Standard 2022. Với hữu hạn khác 0, giải mã **mã độ lớn** sau bù hai nếu đầu vào âm:

```text
X = (-1)^s × (1+f) × 2^sf; sf = 8k+e; useed = 256
k = run-1 nếu regime bắt đầu bằng 1; k = -run nếu bắt đầu bằng 0
```

`run` không tính terminator. Exponent tối đa 3 bit, thiếu thì đệm 0 phía thấp; fraction tối đa 26 bit, căn Q26. Scale đầu vào thuộc [-240,240], tổng scale tích thuộc [-480,480], giữ bằng signed11; hiệu scale mở rộng dấu trước phép trừ.

| Giá trị | Mã 32 bit |
| --- | --- |
| Zero / NaR | `0x00000000` / `0x80000000` |
| +1 / -1 | `0x40000000` / `0xC0000000` |
| minpos / -minpos; minpos=2^-240 | `0x00000001` / `0xFFFFFFFF` |
| maxpos / -maxpos; maxpos=2^240 | `0x7FFFFFFF` / `0x80000001` |

`R(x)` là chuẩn hóa và mã hóa Posit(32,3), tạo regime/exponent/fraction, RNE theo dòng bit G/R/S rồi bù hai nếu âm. Điều kiện tăng mã độ lớn: `G && (LSB || R || S)`. Hữu hạn vượt dải kẹp ±maxpos, khác 0 dưới minpos kẹp ±minpos; zero thật giữ Zero. Carry làm tròn không sinh NaR. Oracle phải xét cả bit regime/exponent bị loại ở biên, không chỉ fraction hoặc khoảng cách cố định quanh 1.

## 3. Yêu cầu chức năng

Các yêu cầu sau bắt buộc khi nghiệm thu. Giữ ID để truy vết báo cáo cũ.

| ID | Yêu cầu |
| --- | --- |
| FR-01, FR-03 | Cố định (32,3); Parser trả dấu, Zero/NaR, sf signed11 và fraction Q26 đúng mọi mã. |
| FR-02, FR-04 | NaR ưu tiên Zero; Packer RNE/kẹp biên theo §2. |
| FR-05, FR-06 | Chỉ approximate FULL_TERM §4.3; không đường exact hay cắt từng term. |
| FR-07, FR-08 | Early-stop; OPS0/1; hòa popcount chọn A. |
| FR-09 | Adder/adapter khớp oracle (32,3), kể cả carry, cancellation, phần dư và cờ. |
| FR-10, FR-11 | NF/F theo §4.4, cùng P_hat. |
| FR-12, FR-14 | FR-12: Toán hạng cộng `C` nhận trực tiếp từ cổng `c` (gỡ thanh ghi hồi tiếp nội bộ `accumulator_q` và `acc_mode`/`acc_clr` khỏi lõi NF/F mục tiêu; chuỗi tích lũy do bên ngoài/harness hồi tiếp `D_(k-1)` vào `c`). FR-14: Đủ 5 cờ theo §4.2/§4.4. |
| FR-13, FR-15 | Valid/ready, giữ output khi stall, reset flush/startup an toàn. |
| FR-16 | Nếu chồng lấn: kiểm thêm thứ tự, capacity, cô lập trạng thái giữa các giao dịch; không mặc định II=n. |
| FR-17 | Prepack có định nghĩa giá trị/width/Q, không product RNE; nối được NF, F và quire theo §4.5. |
| FR-18 | Wrapper tích hợp/driver/model/TB mặc định OPS1/n12; cổng cấu hình phải được lái hợp lệ, không dựa vào X/Z. |
| EXT-Q | Khi triển khai MAC quire: tổng không làm tròn mỗi MAC, một RNE tại READ, có bounds/reset/NaR/overflow và kiểm riêng §9. Không thay điều kiện đạt NF/F. |

## 4. Cấu hình và hợp đồng số học

### 4.1 Hằng số thiết kế

| Thành phần | Giá trị cố định |
| --- | --- |
| Format / fraction giải mã | NB=32, ES=3, FRAC_MAX=26 |
| Nhân approximate | FRAC_W=12, N_MAX=12, APP_ACC_W=26, APP_Q=24 |
| Cấu hình mặc định | OPS_DEFAULT=1, N_DEFAULT=12; không EXACT_EN/cfg_mode trong top mục tiêu |
| Scale / tổng dịch / số vòng | signed11 / unsigned4 / unsigned4 |
| Fraction chuẩn hóa tới Packer | 53 bit, không hidden; đệm 0 không tăng precision |
| Adder dùng chung NF/F | Độ lớn 31 bit/Q29: carry1, hidden1, fraction26, ba vị trí thấp; chênh scale signed12 |
| F adapter tới adder | Fraction26 không hidden, scale signed11; giữ đủ tối đa25 fraction của tích FULL_TERM chuẩn hóa |
| Pipeline mục tiêu | Parser2; core context/OPS + SAC/shift/accumulator; adder5; Packer RNE2 tầng |

Độ rộng và pipeline là lựa chọn phần cứng, không thay golden full-grid. Bộ cộng F W32/Q29 và F1–F5 riêng trong các checkpoint cũ không còn là kiến trúc bắt buộc: mục tiêu hiện dùng chung `posit_add`5 tầng với adapter không suy hao. Nếu residual/jam khi cộng làm khác oracle, sửa datapath thay vì đổi expected. Quire có tổng rộng riêng, không dùng cửa sổ31/Q29 làm state.

### 4.2 Cổng và giao thức

Hai top riêng `posit_mac_nf`, `posit_mac_f` có cùng giao diện mục tiêu:

| Cổng | Hướng | Bit | Ý nghĩa |
| --- | --- | --- | --- |
| clk, rst_n | in | 1,1 | Clock; reset đồng bộ tích cực thấp tại top |
| in_valid, in_ready | in,out | 1,1 | Nhận tại cạnh lên khi cùng bằng 1 |
| a, b, c | in | 32 mỗi cổng | Hai thừa số và số hạng cộng |
| cfg_n | in | 4 | 0..12 số hạng fraction; mặc định12; hidden khởi tạo riêng |
| cfg_ops | in | 2 | Mặc định1: min-popcount fraction12, hòa chọn A; 0: X=A |

| out_valid, out_ready | out,in | 1,1 | Trả tại cạnh lên khi cùng bằng 1 |
| d, flags | out | 32,5 | Mã kết quả; {nar,sat_max,sat_min,inexact,approx_cut} |

- Chốt đồng thời toán hạng `a, b, c` và cấu hình tại accept. Nguồn giữ payload/config khi `in_valid && !in_ready`; DUT giữ d/flags/out_valid khi `out_valid && !out_ready`, tới handshake hoặc reset.
- Invalid gồm n13..15 hoặc OPS2/3: in_ready=0, không accept, không phát kết quả thay thế.
- **Lõi nhân–cộng feed-forward (Phương án A):** Lõi NF/F mục tiêu nhận trực tiếp số hạng cộng từ cổng `c` (`C = c`), không có thanh ghi hồi tiếp `accumulator_q`, `acc_mode`, `acc_clr` hay bộ chọn `c_eff` nội bộ. Khi chạy chuỗi tích lũy Posit32 (`C_k = D_(k-1)`, hoặc `C_0 = 0` khi khởi tạo chuỗi mới), phần cứng gọi lõi / thanh ghi ngoài / testbench driver chịu trách nhiệm đưa kết quả `d` đã retire ở giao dịch trước (hoặc `0`) vào cổng `c` của giao dịch kế tiếp. Để tương thích biểu thức với các tài liệu/model cũ, ký hiệu `C_eff` trong §4.4–§6 được hiểu là giá trị thực tế cấp vào cổng `c` tại thời điểm accept (`C_eff = c`).
- Trong kịch bản chuỗi tích lũy điều khiển từ bên ngoài, trạng thái chuỗi `S` ở driver/scoreboard chỉ cập nhật đúng một lần khi giao dịch retire; stall không làm cộng lặp và chuỗi không bị giới hạn 12 giao dịch (`S` là mã Posit32 làm tròn sau từng giao dịch, không phải quire). Lưu ý: các snapshot lịch sử tới ngày 02/11/2026 (§8) vẫn còn cổng `acc_mode`/`acc_clr` và `accumulator_q` nội bộ trước khi áp dụng bước dọn RTL Phương án A.
- Cạnh lấy mẫu rst_n=0 không có handshake; xóa toàn bộ valid/pending trong pipeline (và xóa `S` của chuỗi tại harness). Reset bridge và startup barrier giữ in_ready=out_valid=0 tới khi mọi leaf sẵn sàng, không trả lại giao dịch trước reset. Leaf giữ hợp đồng reset theo guideline.
- Adapter legacy nếu cần chỉ nhận cfg_mode=1 và từ chối 0; tách khỏi top approximate-only, không giữ nhánh exact trong lõi nghiệm thu.
- cfg_ops và cfg_n là đầu vào, không tự nhận giá trị reset từ DUT. Wrapper cố định/CSR reset và driver/TB MUST đặt OPS1/n12; API/model mới có cùng default. Giữ top cfg_ops2 bit để kiểm reserved2/3, leaf OPS có thể dùng1 bit đã được wrapper kiểm. Không thả nổi cfg hoặc âm thầm thay request invalid bằng default.

<a id="full-term-contract"></a>

### 4.3 Nhân approximate FULL_TERM

Với A/B hữu hạn khác 0, lấy F_A=frac_A[25:14], F_B=frac_B[25:14]; input_cut=OR các bit [13:0] bị bỏ. OPS chọn X/Y theo §4.2; Y=4096+F_Y, sign=s_A XOR s_B, b=sf_A+sf_B. SAC xử lý các bit 1 của F_X từ cao xuống thấp; S_i là vị trí sau dấu chấm, thuộc 1..12. Số vòng thực tế t=min(popcount(F_X),cfg_n).

```text
Y_base = Y << 12                    // mở rộng 26 bit, Q24
M_0 = Y_base                        // đóng góp hidden, không tính vào t
term_i = Y_base >> S_i
M_i = M_(i-1) + term_i
P_hat = (-1)^sign × M_t × 2^(b-24)
```

Y_base có 12 bit 0 thấp nên dịch S_i≤12 không mất bit số học. M có 2 bit nguyên/24 fraction; M≤8191²=67,092,481<2²⁶. Cộng mở rộng 27 bit để kiểm tràn; bit25 là carry chuẩn hóa hợp lệ. Không clear bit thấp, FLOOR/JAM/RNE trong vòng; term_tail/numerical_tail luôn 0 trên miền hợp lệ.

n0 vẫn cho M_0; dừng khi hết bit 1 hoặc đạt n. iteration_cut/approx_cut chỉ đúng khi còn bit 1 chưa xử lý. n12 cho tích đầy đủ của hai significand **đã giữ 12 fraction**, không phục hồi 14 bit đầu vào bị cắt.

Không FLOOR từng term khác với việc chọn 12 bit fraction đầu vào: việc bỏ `frac[13:0]` vẫn là xấp xỉ được yêu cầu. Không gọi n12 là phép nhân exact của toàn bộ Posit32. Với OPS1 và n12, tích cuối không phụ thuộc vai X/Y; với n nhỏ hơn, đổi vai có thể đổi P_hat. Từng magnitude checkpoint phải không giảm trên đường hữu hạn, nhưng không bắt buộc sai số MAC sau cancellation giảm đơn điệu theo n.

```text
carry = M[25]; sf_norm = b+carry
NF carry=0: frac_norm[52:0] = {M[23:0],29'b0}
NF carry=1: frac_norm[52:0] = {M[24:0],28'b0}
```

F nhận magnitude26/Q24, base scale signed11, dấu và cờ trước product RNE. Không dùng acc[15:2]/magnitude14 của FLOOR cũ thay FULL_TERM.

### 4.4 NF/F, ngoại lệ và cờ

```text
NF: D = R(R(P_hat) + C_eff)
F : D = R(P_hat + C_eff)
```

NF có hai lần RNE; F giữ tích approximate tới phép cộng rồi RNE cuối, không phải FMA của A×B đầy đủ. NF/F không bắt buộc cùng kết quả.

NaR của A/B/C_eff ưu tiên mọi bypass, kể cả 0×NaR: d=NaR, flags=10000. Nếu không NaR và A hoặc B=0, trả C_eff với cờ 0. Triệt tiêu đúng hai số hạng của từng profile trả Zero; phần dư căn chỉnh phải xét dấu/borrow, không chỉ OR sticky vào phép trừ.

| Cờ | Ngữ nghĩa trong một giao dịch |
| --- | --- |
| nar | NaR ở toán hạng thực sự tham gia, xóa 4 cờ còn lại |
| sat_max, sat_min | Kẹp hữu hạn tại biên; NF OR qua product pack và final pack |
| inexact | input_cut hoặc iteration_cut hoặc mất thông tin ở cộng/pack; NF OR qua hai lần làm tròn |
| approx_cut | Còn bit 1 của fraction12 khi đạt n; n12 hợp lệ luôn bằng 0 |

Loss do xấp xỉ là metadata, không OR input_cut/iteration_cut vào numerical sticky để đổi P_hat. Cờ thuộc từng giao dịch độc lập, không tự OR dồn qua cả chuỗi; khi chạy chuỗi tích lũy bằng hồi tiếp ngoại vi thì giá trị đưa lại cổng `c` là mã Posit32 `d` (`S` của chuỗi). Luôn so cả d và đủ 5 cờ.

<a id="prepack-interface"></a>

### 4.5 Giao diện tích dùng chung và khả năng nối quire

`mul_iter_core` mục tiêu xuất một token nội bộ cùng context, giữ đến khi downstream nhận. Giao diện logic có thể dùng tên khác nếu mapping được ghi trong manifest:

| Trường | Width / giá trị | Hợp đồng |
| --- | --- | --- |
| pre_valid/pre_ready | 1/1 | Truyền đúng một lần; payload ổn định khi stalled |
| magnitude | unsigned26 | M_t của §4.3, chưa pack/RNE/kẹp theo dải Posit |
| base_scale | signed11 | b=sf_A+sf_B, [-480,480]; chưa cộng carry chuẩn hóa |
| sign, is_zero, is_nar | 1 mỗi trường | NaR ưu tiên; Zero/NaR canonical magnitude0,base_scale0 |
| input_cut, iteration_cut | 1 mỗi trường | Loss metadata, không cộng vào magnitude/sticky số học |
| iterations | unsigned4 | t thực tế0..12; hidden không tính một vòng fraction |
| Q | Hằng24 | Không cần port/FF riêng; giá trị hữu hạn=(-1)^sign×magnitude×2^(base_scale-24) |

Đây là token trước cộng C; NaR/Zero của C_eff do MAC wrapper xử lý. Metadata bypass không được làm mất nguồn gốc hoặc sai thứ tự giao dịch. Nếu fanout nhiều consumer phải có phân phối/slot rõ ràng; không nối ready tùy tiện để một consumer làm mất token của consumer khác. Không bắt buộc thêm cổng prepack lên public top NF/F; quire là top riêng sử dụng lại core.

Adapter F chuẩn hóa không suy hao vào `posit_add`:

```text
carry = magnitude[25]
product_sf = base_scale + carry
carry=0: product_frac[25:0] = {magnitude[23:0],2'b0}
carry=1: product_frac[25:0] = {magnitude[24:0],1'b0}
```

Sau chuẩn hóa chỉ cần tối đa25 fraction, vừa bus26. Phải giữ bit thấp nhất trong cả hai nhánh; không lấy 12 fraction để pack lại và không RNE ở adapter F. Kiểm giá trị trước/sau bằng số nguyên chính xác. Quire tiêu thụ magnitude26/base_scale gốc; không tiêu thụ mã Posit đã RNE hoặc sticky-only thay số hạng.

## 5. Tổ chức RTL

### 5.1 Parser và tín hiệu đặc biệt

Parser nhận Posit32, xuất sign/Zero/NaR, sf signed11 và frac26/Q26 không hidden. P1 nhận biết Zero/NaR, tạo magnitude không dấu, phát hiện run regime và lưu bundle. P2 bỏ regime/terminator, lấy exponent tối đa3 bit, đệm exponent thiếu ở phía thấp và fraction ở phía thấp, tính sf=8k+e. Regime dài/no terminator phải có kết quả xác định; không dùng vị trí detector invalid làm shift tùy ý. Zero/NaR có sf/frac0; NaR sign1, Zero sign0.

Hai tầng có valid/ready và giữ toàn bộ bundle khi stall. NF và F dùng chung `posit_parser_mul` cho cả `A`, `B` và `C`. P1 dùng phép bù hai qua carry chain và `posit_parser_f_regime_lod`. P2 chốt 12 bit fraction cao `frac`, 14 bit thấp `frac_lo` và `tail_cut = |payload[13:0]`. Đường nhân chỉ lấy `frac` và `tail_cut` của A/B. Đường cộng lấy đủ 26 bit `{frac, frac_lo}` của C từ cổng `c`. Các ngõ ra không được tiêu thụ có thể được lược bỏ khi tổng hợp.

### 5.2 OPS và khởi tạo context

Sau Parser, chọn 12 fraction cao; phần thiếu thực tế đã được Parser đệm0. `input_cut=|(frac_A[13:0] | frac_B[13:0])` được tính tại biên cắt, không bắt buộc trong leaf OPS. OPS nhận hai frac12, trả X12 không hidden, Y13 có hidden, dấu XOR và tổng scale. OPS1 so popcount của12 bit, hòa giữ A; OPS0 không swap. Chuẩn bị hai ứng viên X/Y và hidden song song rồi chọn bằng MUX. Không dùng predictor E/M/prefix của nhánh paper thay min-popcount mà không có revision hợp đồng.

Context lưu Y, sign, b, input_cut, cfg_n và vai OPS tại launch; không đổi trong vòng nhân. Có thể tính trước b+1 để giảm carry-chain ở adapter, nhưng token vẫn mang b đúng định nghĩa §4.5. Không nhân đôi register chỉ để debug; checker dùng tap/bind hoặc trace phù hợp tool.

### 5.3 SAC và phát số hạng

SAC nhận fraction còn lại fx12 và tổng dịch S4. Với fx khác0, detector trả số0 đầu c, tạo sa=c+1, S_next=S+sa và fx_next=(fx<<sa) trên12 bit. Shift cập nhật có thể tách nối dây <<1 và barrel shift <<c. Cây kiểm zero/single-one hoặc `(fx & (fx-1))==0` được phép; fx0 phải được phân biệt với một term thật.

Điều khiển xử lý hidden riêng, phát tối đa cfg_n số hạng fraction; dừng khi fx cạn hoặc đạt giới hạn. Nếu n0/fx0, phát một token init_only mang hidden, không giả lập một vòng fraction. Mỗi token giữ first/last/init_only, S_i, iterations và loss của đúng giao dịch. Không phát S>12; state_error là lỗi invariant/checker, không tạo sản phẩm gần đúng tùy ý. approx_cut phản ánh fx còn lại tại điểm dừng, không đồng nghĩa đã có input_cut.

### 5.4 SBM và accumulator FULL_TERM

SBM tạo Y_base={1'b0,Y13,12'b0} rộng26; dịch phải logical theo S_i4, không xóa bit thấp. init_only làm term=0, hidden vẫn đi vào accumulator. Mỗi S hợp lệ1..12 phải có `(Y_base & ((1<<S)-1))==0`; vì vậy term_tail=0. Không dùng term16 hay `{shifted[15:2],2'b00}` của FLOOR cũ.

Accumulator26 lưu M. Token first ghi Y_base+term; token tiếp theo ghi M+term; init_only chỉ ghi Y_base. Adder tạm27 bit kiểm bit26 tràn; bit25 là carry normalization hợp lệ. Có thể hợp nhất controller/register vào parent sequential, giữ các leaf SAC/shift/accum tổ hợp. Parent phải truyền t1/t2 metadata cùng term, không bỏ/nhân đôi first/last. core_done chỉ khi token last được cộng và commit; không sớm hơn kết quả cuối.

Khi core không có stall giữa các term, wrapper MUST dự trữ slot downstream trước launch và giữ result/context tới release. Nếu thêm elastic stall nội bộ phải kiểm lại first/last/counters, không dùng enable làm term được cộng hai lần.

### 5.5 Hai nhánh NF/F và bộ cộng dùng chung

| Nhánh | Đường dữ liệu mục tiêu |
| --- | --- |
| NF | Prepack26/Q24 → normalize53 → product Packer RNE2 tầng → magnitude decode → `posit_add`5 tầng với C_eff → Packer RNE2 tầng |
| F | Prepack26/Q24 → adapter lossless frac26/sf theo §4.5 → cùng `posit_add`5 tầng với C_eff → Packer RNE2 tầng |
| Quire mở rộng | Prepack26/Q24 → đổi lưới số nguyên không mất bit → cộng vào state rộng → chỉ normalize/Packer khi READ (§9) |

NF không được bỏ product RNE dù tích nội bộ có thể vừa một số mã Posit. F không có product RNE, saturation/clamp trước cộng; ví dụ tích vượt maxpos vẫn phải được cộng với C_eff trước khi quyết định kẹp cuối. Dấu/Zero/NaR và flags đi cùng magnitude. Dùng chung module không có nghĩa NF/F cùng netlist instance hoặc cùng kết quả.

| Tầng `posit_add` | Phần cứng/chức năng bắt buộc |
| --- | --- |
| A1 Prepare | Hiệu scale mở rộng signed12, so sf rồi fraction khi hòa, MUX magnitude lớn/nhỏ, chọn dấu/scale cơ sở và subtract; NaR có ưu tiên |
| A2 Align | Dịch phải31 bit và jam/tail. Δsf≤28 xử lý đúng phần giữ/phần bị loại; Δsf≥29 trả small=1 dạng jam với tail1 cho hai số khác0, không để lượng dịch wrap modulo32 |
| A3 Arithmetic | X±Y unsigned31, giữ carry; tính trước sf_inc=sf_base+1 nếu dùng đường timing hiện tại |
| A4 LOD | Detector trên magnitude31, chuẩn bị norm_seed/count và lost_carry; giữ đúng thông tin triệt tiêu |
| A5 Normalize | Shift chuẩn hóa, sf=sf_inc-count, ghi dấu/Zero/NaR; xuất frac53 bằng dữ liệu thật và nối0, sticky không bị mất |

Kết quả MUST bằng R(P+C_eff) theo full-grid, kể cả dấu đối nhau, cancellation và tail. Chuỗi A1–A5 là kiến trúc mục tiêu theo nguồn hiện tại; không bắt buộc F4 Abs/Borrow riêng đã archive. Nếu chọn datapath signed/residual khác, phải đặc tả chiều phần dư/borrow và chứng minh bằng cùng golden. Không coi cờ input_cut/iteration_cut là phần dư số học để sửa giá trị P.

### 5.6 Packer và cờ

P1 prepare tái tạo regime từ signed sf, ghép exponent/fraction, dịch mã hóa và tạo G/R/S theo đúng vị trí cắt; tính trường hợp Zero/NaR/min/max. P2 finish quyết định RNE bằng G&&(LSB||R||S), xử lý carry/kẹp và bù hai nếu âm. Cho phép gộp rounding/two's-complement trong carry-chain; giá trị và flags phải bằng golden.

Flags mất thông tin được OR qua các bước của một giao dịch theo §4.4, nhưng không OR vào dữ liệu số. Product Packer của NF còn phải trả sign riêng nếu chỉ lưu magnitude; decode sau product RNE phải tương đương parse(pack(P)). Không giữ đồng thời nhiều bản mã tương đương nếu không phục vụ hợp đồng thực tế.

### 5.7 Top, pipeline và guideline

Top PNR chỉ nối named instances; wrapper/parent xử lý context, config và sức chứa pipeline (không giữ thanh ghi hồi tiếp `S` nội bộ ở NF/F mục tiêu). Mỗi file một module, cổng literal, localparam hằng rõ width/Q; công thức đặt trong chú thích. Tổ hợp có gán mặc định không latch, blocking; sequential non-blocking với CK2Q chung. Không delay trong logic tổ hợp, không clock gating tự phát, không reset data bằng clock domain khác. Leaf reset assert bất đồng bộ/deassert đồng bộ theo guideline; top synchronous rst_n nối qua reset bridge và barrier, không nối trực tiếp vào mọi async pin.

Mọi tầng mang dữ liệu và metadata đồng bộ, valid/ready giữ khi stall. Baseline một outstanding; nếu mở rộng credit/prefetch, phải giữ thứ tự, flush và cô lập trạng thái giữa các giao dịch (phụ thuộc chuỗi `C_k = D_(k-1)` do bộ lập lịch/harness bên ngoài quản lý). Không cần giữ các mode exact, port mode chết hoặc tham số format tùy ý để tái sử dụng.

Khi khóa RTL, ghi first-valid, retire và II không stall theo t, gồm n0/early-stop. Không lấy công thức pipeline cũ hoặc n+6 của paper áp cho MAC mới. Đổi số tầng phải kiểm lại lịch/metadata; số tầng không chứng minh Fmax.

## 6. Golden model và kiểm chứng Posit(32,3)

### 6.1 Golden, model và Ideal

| Thành phần | Nguồn và vai trò |
| --- | --- |
| **Golden độc lập** | [`opt17_reference::product/mac`](tb/opt17/full_term_reference.hpp) dùng [`week12_reference::Oracle<32,3>`](tb/week12_fused_reference.hpp): raw decoder, tích chọn bit dạng đóng, cộng/trừ full-grid và encoder RNE riêng. Tạo expected d/5flags của DUT. |
| **Model thuật toán L1** | [`full_term32::multiply/mac`](l1/include/posit_mac_full_term.hpp): recurrence SAC/SBM, checkpoint M, NF và cửa sổ F; phục vụ trace/debug, phải khớp golden trước sinh fixture. |
| **Ideal đo sai số** | `Oracle<32,3>::product(a,b)` rồi `Oracle::add(...,C_eff)`: giữ toàn bộ giá trị A/B để tính A×B+C_eff. Full-grid trước encode là chuẩn hữu tỉ; bits là chuẩn Posit đã RNE. Không làm expected bit-exact của DUT approximate. |
| **SoftPosit L0 hiện có** | [`softposit_api.c`](l0/softposit_api.c) gọi p8/es0, p16/es1, p32/es2. Chỉ hồi quy đúng format; l0_p32_*, ctypes và API L1 p32/es2 không là golden (32,3). |

Khi kiểm DUT, bắt buộc `full_term32::Config{true,n,ops}` (approximate=true); fused=false cho NF, true cho F. Nhánh approximate=false còn trong header chỉ là phần mềm hỗ trợ nghiên cứu, không là mode nghiệm thu RTL. Harness quản lý C_eff/S riêng từng kiến trúc; hàm mac() nhận C_eff, không tự quản lý chuỗi.

Golden tính M độc lập với vòng SAC: chọn tối đa n bit 1 cao nhất của F_X thành mask F_sel, rồi tính `M=(4096+F_sel)×(4096+F_Y)` bằng số nguyên. Với n0, F_sel=0; n12, F_sel=F_X. Từ M/Q24 và b, golden thực hiện đúng hai phương trình NF/F ở §4.4, gồm cả ngoại lệ và 5 cờ.

Golden có thể chung kiểu dữ liệu nhưng không gọi Parser/Packer/adder/recurrence L1 tạo expected. Full-grid hiện là số nguyên 1024 bit trên lưới 2^-532 cho (32,3), có kiểm bounds/tràn. Double/long double chỉ hiển thị/thống kê khi đủ miền, không quyết định tie, saturation, Zero hoặc cancellation. Python gọi lại cùng thư viện C không phải oracle độc lập thứ hai.

### 6.2 Kiểm model trước RTL

Đối chiếu dấu, sf, M/Q, t, loss metadata và d/5flags cho n0..12, OPS0/1, NF/F. Mỗi checkpoint i kiểm bằng tổng chọn i bit 1, không chỉ kết quả cuối. Decoder/encoder cần roundtrip raw32/3 và kiểm tay regime dài, dấu, G/R/S, biên.

| Vector | Đầu vào sau chọn vai X/Y | Expected FULL_TERM |
| --- | --- | --- |
| FT-01 | F_X=0,Y=4096,n bất kỳ | t0,M=16,777,216; không iteration_cut |
| FT-02 | F_X=1,Y=8191,n0 | M=33,550,336; iteration_cut=1 |
| FT-03 | F_X=1,Y=8191,n1 | S1=12,term=8191,M=33,558,527; carry25=1 |
| FT-04 | F_X=F_Y=4095,n12 | t12,M=67,092,481; không iteration_cut |
| FT-05 | A=0x1c900000,B=0x3c820000,C_eff=0,OPS0/1,n≥2 | t2,b=-11,M=24,224,768/Q24; NF/F d=0x1ae34800 |
| FT-06 | F_X=F_Y=4095,n12,base_scale0 | M=67,092,481; F adapter sf1,frac26=67,076,098; giữ bit thấp ở nhánh carry |

FT-01..04 là input nội bộ **sau OPS**, không áp lại min-popcount lên bảng. FT-05 phân biệt với trace FLOOR cũ 0x1ae34000; không sửa fixture lịch sử để đổi nhãn PASS.

<a id="verification-coverage"></a>

### 6.3 Phân tầng vector

Ngoài raw random/corner, chia run regime trên mã độ lớn thành `[1,3],[4,7],[8,11],[12,15],[16,17],[18,22],[23,27],[28,31]`. Mỗi điểm nghiệm thu phủ 256 ô group_A×group_B×sign_pair, ≥4,000 completed/ô. A/B hữu hạn khác 0; run0 dài31 là Zero, kiểm riêng. Mỗi polarity/run hữu hạn hợp lệ đạt ≥10,000 lượt toán hạng trong suite tổng hợp.

Phủ popcount fraction12: 0,1,2,3–4,5–8,9–12; từng n9/10/11/12; OPS hòa/swap; input_cut độc lập iteration_cut. ≥30% completed mỗi điểm MAC có hai số hạng cộng hữu hạn khác 0, trái dấu, |Δsf|≤4. NF đo R(P_hat)/C_eff; F đo P_hat chuẩn hóa/C_eff trước window cut. Lưu counters Δsf0..4, tách standalone/accumulation; reset-abort không tính completed. Tỷ lệ corpus phân tầng không mặc nhiên đại diện dữ liệu ứng dụng.

<a id="corner-cases"></a>

### 6.4 Corner bắt buộc

- Mã §2, NaR×0/0×NaR, NaR của `C_eff` (cổng `c`, gồm cả `S` hồi tiếp từ bên ngoài); tích Zero với `C_eff` khác 0.
- Hai dấu, min/maxpos và lân cận, fraction 0/1/xen kẽ, carry, regime đổi độ dài/exponent thiếu bit.
- n0, early-stop, hết n, đủ 12 bước; invalid n13..15/OPS2..3.
- RNE up/down, tie-even/odd, sticky-only, carry làm tròn, kẹp min/max; roundtrip parser→packer.
- Triệt tiêu đúng số hạng của từng profile, near-cancellation, hai mốc căn chỉnh, hai phía ngưỡng dịch 28/29, phần giữ bằng 0 nhưng residual khác 0.
- Chuỗi >12 giao dịch (hồi tiếp `d` về cổng `c`), clear chuỗi (`c=0`) giữa chuỗi/NaR trong `S` rồi clear, standalone xen kẽ, bubble/stall dài/reset khi rỗng/đang tính/giữ output.

### 6.5 Scoreboard và bằng chứng

Chụp input/config tại accept, tạo expected bằng golden, so d/flags tại retire. Trong kịch bản chuỗi tích lũy, model state `S` ở harness/scoreboard cập nhật đúng một lần theo giao dịch tích lũy khi retire để cấp lại cho cổng `c` (NF/F có `S` riêng). Reset hủy pending trong DUT và xóa `S` của chuỗi tại harness. Cuối suite: accepted=completed+reset_aborted, queue rỗng, không output dư. Kiểm ổn định payload/valid khi stall, timeout/deadlock và done sau last commit.

Thứ tự: model/oracle → unit/fixture → pilot ≥10^5 completed/điểm → main §6.7 → audit. Verilator/C++ chạy lượt lớn; ModelSim replay fixture đã được oracle kiểm và kiểm 4-state/CK2Q/reset/stall. So comb RTL với pipeline RTL chỉ xác nhận refactor, không thay golden độc lập.

Mỗi kết quả kèm file list, SHA256 RTL/model/oracle/harness/fixture, config/seed, tool version, lệnh/exit code, counts, coverage và raw log. Thiếu bằng chứng, RUNNING, mismatch, timeout hoặc mất/nhân đôi giao dịch đều FAIL. Không cộng mẫu giữa các snapshot/profile; không mặc định make regress hoặc runner legacy đã bao đủ ma trận mới.

### 6.6 Assertion và coverage

Assertion tối thiểu: output không X sau startup; giữ payload/valid khi stall; invalid không accept; t≤n≤12; term không mất bit/overflow; done sau last commit; NaR/Zero/flags theo golden; mỗi accept có một retire hoặc reset-abort; không rò rỉ trạng thái giao dịch cũ sau retire/reset; occupancy không vượt capacity.

Functional coverage 100% bin hợp lệ của §6.3–6.4: n/OPS/t/cut, dấu/mốc/Δsf/LOD, carry/RNE/biên, kịch bản standalone và chuỗi hồi tiếp ngoại vi (kể cả khởi tạo lại chuỗi `c=0`), reset/stall. Structural coverage trên **nguồn approximate-only nghiệm thu**: line≥95%, branch≥90%, toggle≥85%. Unreachable chỉ loại bằng giải thích gắn nguồn; không dùng exact còn sót để giảm mẫu số hoặc miễn n9..12.

<a id="acceptance-matrix"></a>

### 6.7 Ma trận nghiệm thu

Chỉ profile `(32,3), FW12, FULL_TERM26/Q24, RNE`; bỏ các trục exact, format khác, TRUNC và ROUND_SCHEME tùy chọn.

| Nhóm | Cấu hình | Ngưỡng/kiểm tra |
| --- | --- | --- |
| AC-01 bit-exact | NF/F × OPS0/1 × từng n0..12: **52 điểm** | ≥10^7 completed/điểm, 0 mismatch d/5flags; ≥520 triệu completed toàn ma trận, không đếm pilot hai lần |
| Control trong mỗi điểm AC-01 | Standalone và chuỗi tích lũy (hồi tiếp ngoại vi `c = D_(k-1)`) | Mỗi loại ≥10% completed; đủ corner, input/output stall, reset-abort; counters riêng |
| Unit/4-state | Parser, OPS/SAC/SBM, adder, Packer, hai top | Đạt kiểm tay/fixture/assertion; không áp 10^7 cho từng invalid hay từng unit |
| AC-03 paired accuracy | OPS1, từng n0..12, NF/F cùng A/B/C_eff | Pilot≥10^5 rồi main≥10^6 triple/n trên corpus đóng băng; báo cả trường hợp F kém NF |

OPS1 là cấu hình so sánh chính; OPS0 vẫn kiểm chức năng bắt buộc. Standalone/accumulation nằm trong số đếm mỗi điểm, không nhân đôi thành 104 điểm. Với accuracy chuỗi, S_NF/S_F có thể phân kỳ: báo suite riêng và quy tắc Ideal state; không gọi C_eff của hai DUT giống nhau sau phân kỳ.

### 6.8 Sai số

Với paired standalone, dùng cùng corpus/P_hat; r=A×B+C_eff là giá trị hữu tỉ từ toàn bộ đầu vào, y=decode(d):

```text
Err(%) = 100 × |y-r|/|r|
Relative MSE = mean(((y-r)/r)^2)
Code-distance = |signed_code(d)-signed_code(R(r))|
```

Báo tỷ lệ Err<0.1/0.5/1/5%, Relative MSE, max error, code-distance và số mẫu mỗi miền. r=0 báo zero-match/sai số tuyệt đối riêng; NaR tách riêng. Hiệu mã dùng số nguyên đủ rộng, không gọi là ULP có độ dài cố định. Giữ seed/phân bố, độ biến thiên và kết quả bất lợi; không yêu cầu F tốt hơn NF trên mọi vector. Ideal không làm tròn hồi tiếp của chuỗi cần số hữu tỉ/độ rộng được chứng minh đủ cho chiều dài chuỗi.

### 6.9 Cấu trúc testbench và lộ trình chạy

Testbench mới tách rõ sáu thành phần; không yêu cầu UVM nếu driver/monitor/scoreboard hiện tại đã đáp ứng:

| Thành phần | Nhiệm vụ |
| --- | --- |
| Config/corpus | Manifest format/profile/default OPS1/n12, seed cố định, danh sách bin và expected số completed trước chạy |
| Driver | Phát theo valid/ready; giữ payload/config khi stall; thay C/config sau accept để kiểm DUT đã chốt context; invalid kiểm riêng |
| Input monitor | Chụp a/b/c_eff/config đúng accept, gắn transaction ID ở TB, phân loại bins; không lấy tín hiệu đã đổi sau accept |
| Oracle/scoreboard | Golden độc lập tạo d/5flags, pending queue, model S riêng NF/F, xử lý abort theo reset epoch |
| Trace checker | Đối chiếu vai OPS, mỗi S_i/M_i, t/cut, token last, prepack, adapter F và input/output của adder; trace sai không được bỏ qua dù d cuối trùng |
| Output/assertion/coverage monitor | So đúng retire, đồng thời kiểm stable lúc valid stall, unknown4-state, latency/II, counts, coverage và timeout |

`S` của scoreboard được cập nhật theo retire trong baseline một outstanding rồi driver cấp lại vào cổng `c` ở giao dịch tích lũy tiếp theo. Nếu mở rộng probe/credit cho phép accept sớm cho các giao dịch độc lập, phải model đúng thứ tự retire và dependency của chuỗi ở bộ lập lịch ngoài, không đổi expected bằng output DUT. Reset chỉ hủy pending của epoch cũ; output sau reset không được khớp nhầm request cũ.

**Unit:** Parser roundtrip/raw/corner; OPS popcount/swap/tie và bit cắt; SAC quét đủ4096 fx và trạng thái scale hợp lệ; SBM toàn bộ Y13=4096..8191 với S0..12/init_only; accumulator first/middle/last/carry và overflow invariant; adapter lossless hai nhánh carry; adder/Packer G/R/S, cancellation và stall. OPS có thể exhaustive16,777,216 cặp12 bit; nếu chưa chạy phải ghi scope thực tế, không ghi exhaustive. Legacy reference đã chuyển vào `tb/reference/rtl/files.f` chỉ là đối chiếu implementation, không thay golden32/3.

**Integration:** NF/F chạy cùng nguồn/corpus cho paired standalone, scoreboard state `S` riêng cho chuỗi hồi tiếp ngoại vi. Đủ early-stop/n0/n12, cfg mặc định, raw đặc biệt, run dài, magnitude max, n13..15/OPS2..3 bị từ chối, khởi tạo lại chuỗi (`c=0`)/reset lúc mọi vị trí pipeline và output đang stalled. Source vi phạm giao thức input được kiểm ở suite assertion riêng, không tính thành dữ liệu hợp lệ.

**Trình tự bắt buộc:** review contract/manifest → kiểm golden và L1 → unit/FT-01..06 → smoke default OPS1/n12 → pilot≥10^5 completed cho52 điểm → freeze → main52×10^7 → accuracy/coverage → PPA. Nếu n0 hoặc early-stop không nhận đủ completed vì timeout, đó là FAIL, không tự tăng timeout mà bỏ điều tra. Main dùng seed đã công bố trước; đổi RTL/model/golden/harness có ảnh hưởng phải tái chạy phạm vi bị tác động, không cộng counts snapshot cũ.

Verilator dùng `--timing` hoặc `--no-timing` phù hợp CK2Q và harness, khai báo rõ; không bỏ delay âm thầm. ModelSim10.1d chạy fixture có expected độc lập và checking 4-state; mọi compatibility cast chỉ đổi cú pháp, kèm hash gốc/bản biên dịch. Toàn bộ binary/work/wave/log/file tạm đặt trong dự án; không cần sửa cài đặt/license để đóng spec.

### 6.10 Bảng truy vết tối thiểu

| Test ID | FR liên quan | Điều kiện đạt |
| --- | --- | --- |
| TC-AP12-DEFAULT | FR-18 | Wrapper/driver/model mặc định OPS1/n12; request không lái không tạo giao dịch giả |
| TC-AP12-PARSE | FR-01/03 | Raw sign/regime/exponent thiếu/fraction26, Zero/NaR và metadata đúng |
| TC-AP12-CORE | FR-05..08 | Vai OPS/SAC/term/M/checkpoints/t/cut đúng golden; term_tail0, bit26 overflow0 |
| TC-AP12-PREPACK | FR-17 | M26/Q24 và adapter giá trị bằng nhau; cả carry0/1, không product RNE trên F |
| TC-AP12-NF, TC-AP12-F | FR-09..11 | d và5flags đúng hai công thức, kể cả cancellation/biên/RNE |
| TC-AP12-STATE | FR-12/14 | Cô lập trạng thái giao dịch, chuỗi hồi tiếp ngoại vi (`c = D_(k-1)`)/reset/clear chuỗi (`c=0`)/NaR đúng, không nhầm state NF/F |
| TC-AP12-PROTOCOL | FR-13/15/16 | Stable/abort/thứ tự/capacity/latency đúng manifest |
| TC-AP12-MATRIX | AC-01/03/04 | Đủ52 điểm, accuracy và bins/counts/coverage theo §6.3–6.8 |
| TC-Q-* | EXT-Q | Chỉ khi mở rộng quire; điều kiện riêng §9.5 |

Tên testcase cụ thể của runner được map vào bảng, không bắt buộc đổi tên mọi fixture cũ. Không ghi TC-Q PASS trước khi có model/RTL quire thực thi.

## 7. Điều kiện nghiệm thu và báo cáo

| ID | Điều kiện đạt |
| --- | --- |
| AC-01 | Đủ 52 điểm/số completed §6.7, 0 mismatch; protocol/control/unit đạt. |
| AC-02 | Retired: không nghiệm thu exact phần cứng; giữ ID để đọc báo cáo cũ. Oracle toán học vẫn bắt buộc. |
| AC-03 | Đủ paired accuracy §6.7–6.8; báo phân bố/ngoại lệ/seed/giới hạn. |
| AC-04 | Functional/structural coverage đạt §6.3/§6.6, đủ giải thích unreachable. |
| AC-05 | RTL không latch; lint không còn cảnh báo nghiêm trọng chưa giải thích; có tài nguyên/setup/hold post-route đúng nguồn khóa; DSP=0, BRAM=0. |
| AC-06 | Paired NF/F trên Artix-7 xc7a35tcpg236-1, cùng tool/constraints/profile, ≥3 run/cấu hình tĩnh; LUT/FF/CARRY/DSP/BRAM, clock đạt, latency/II/throughput đo thực tế. |
| AC-07, AC-08 | Tái lập và truy vết FR→testcase→log/count/coverage; manifest khóa đúng nguồn/model/fixture; PASS đúng phạm vi đã chạy. |

PPA là bước riêng sau kiểm chức năng. n là cấu hình runtime: không tổng hợp lặp cùng netlist cho 13 n; đo latency/II từng n và dùng n2/n4/n12 trình bày accuracy–throughput. Netlist chuyên biệt theo n phải khai báo và kiểm riêng.

Giữ profile A35T đã chọn: input min=max2.5ns, output min0/max0.5ns, uncertainty setup/hold0.1ns; khóa clock mục tiêu/constraints trước chạy. Clock công bố phải đạt setup/hold sau route; ước lượng từ slack không là Fmax đã sweep hay board signoff. Không lấy mốc 575MHz/698LUT của multiplier paper làm ngưỡng bắt buộc cho MAC A35T. Giữ raw report, min/median/max các run; power chỉ kết luận khi có phương pháp/activity phù hợp. Không phát sinh yêu cầu chạy PPA trong lần sửa tài liệu này.

## 8. Trạng thái nguồn và tham chiếu

Nguồn ngày 02/11/2026 đã chuyển sang bộ nhân approximate dùng chung; phiên ngày 04/11/2026 (v1.29) chốt tiếp Phương án A (gỡ `accumulator_q` và `acc_mode`/`acc_clr` nội bộ khỏi lõi NF/F mục tiêu để loại đường găng F2F `accumulator_q → Parser C`). [Summary có kiểm hash](results/shared_multiplier_20261102/summary.json) và checkpoint `rtl/shared_multiplier_checkpoint.json` ghi phạm vi pilot của nguồn ngày 02/11/2026 (lúc còn giữ `accumulator_q`); các số đo/PASS cũ vẫn theo snapshot riêng:

| Thành phần | Hiện trạng |
| --- | --- |
| NF/F wrappers và top | Cùng gọi `ops_sel_comb`, `mul_iter_core`, `mul_prepack_norm_comb`; không cfg_mode/exact/sticky nhân dư. N_MAX12, bank26/Q24. NF product RNE rồi cộng; F adapter26 không RNE trung gian. Đã gỡ `accumulator_q`/`acc_mode`/`acc_clr` ngày04/11 theo Phương án A (§4.2); C cấp trực tiếp từ cổng `c`, chuỗi tích lũy do driver ngoài quản lý sau retire. |
| Cây active | Từ ngày 07/11, NF/F có 30 module theo `rtl/mac_active.f`. Hai top cùng dùng `posit_parser_mul` cho A/B/C theo §5.1. Các bằng chứng ghi 31 module ở dưới thuộc phiên bản trước khi hợp nhất parser C. |
| L1/golden FULL_TERM §6.1 | Profile `full_term32::Config` mặc định approximate=true,n12,OPS1; 400k kiểm model/golden,806204 checkpoint,60k hàng fixture Python độc lập đều 0 mismatch. Nhánh phần mềm lịch sử không là chế độ DUT. |
| Kiểm khối và cổng | 143934016 so sánh đơn vị (các miền phân tách, accumulator lấy mẫu),31/31 strict lint;68 instance named-port và2 BUFG đầy đủ, không cổng trống/thiếu. Không là exhaustive toàn bộ MAC. |
| Kiểm tích hợp mới | Ma trận52 điểm×100k=5.2M completed; default OPS1/n12 thêm1M NF+1M F, tổng7.2M/0 mismatch. Đã thấy đủ10 mã cờ hợp lệ NF và8 mã F trên hợp các điểm. ModelSim cuối: mỗi NF/F29820 completed+180 reset-aborted; core53249 case/231437 checkpoint. |
| Coverage/nghiệm thu | Lượt20k mixed: NF line96.053%,branch89.130%,toggle93.674%; F line76.056%,branch89.744%,toggle93.110%. Chưa waiver RTL; branch/line chưa đủ. Main520M và quota≥4000/cell/điểm chưa chạy/đạt (pilot min188/189). Gate/AC04 vẫn mở. |
| mac_active.f, production.f, freeze/report cũ | Checkpoint mới chỉ khóa nguồn pilot. production.f/production_freeze.json giữ lịch sử; recipe54 không dùng trên cây31. PPA/paired accuracy FULL_TERM chưa chạy lại. |
| OPS1/n12 mặc định | Reset cấu hình wrapper và model/driver/TB dùng OPS1/n12; input ngoài vẫn phải được lái hợp lệ, không dựa vào X/Z. Runtime OPS0/n0..11 vẫn được kiểm. |
| MAC quire | Đã triển khai Q12-1024/W972 theo §9; model/unit/4-state và main10M MAC đạt0 mismatch. Coverage có3 loại trừ gắn nguồn theo §6.6. OOC route100MHz setup−12.016ns,hold+0.015ns: chưa nghiệm thu timing, không gắn nhãn MAC_Q12_VERIFIED. [Summary](results/quire_20261103/summary.json). |

Chỉ công bố release mới khi top, model/harness và ma trận cùng đúng hợp đồng. Thứ tự hiện thực: khóa golden/default và prepack → core26/Q24 + bỏ mode exact → adapter NF/F dùng chung adder → gỡ thanh ghi hồi tiếp `accumulator_q`/`acc_mode`/`acc_clr` khỏi lõi NF/F theo Phương án A → unit/pilot → freeze/main/coverage → accuracy/PPA → mở rộng quire. Không cần quire hoàn thành để nghiệm thu NF/F; không gọi NF/F là MAC quire.

Thiếu hụt kiểm chứng không là lý do hạ ngưỡng nghiệm thu. Giữ [bản trước rút gọn](archive/spec_v1_24_before_compact_20261101.zip), [snapshot trước v1.26](archive/spec_v1_25_before_approx12_quire_20261102.zip), [nguồn trước dùng chung](archive/shared_multiplier_before_20261102.zip) và [tài liệu trước cập nhật](archive/shared_multiplier_docs_before_20261102.zip) có SHA256. Không ghi đè bằng chứng lịch sử.

<a id="mac-quire-extension"></a>

## 9. Hợp đồng mở rộng MAC quire

### 9.1 Phạm vi và phép toán

Tên profile mở rộng: **MAC_Q12_FULL_TERM**. Dùng cùng Parser/OPS1 mặc định/core12 FULL_TERM, nhận token §4.5. Với trạng thái rộng Q và chuỗi K tích:

```text
Q_0 = 0
Q_(k+1) = Q_k + P_hat_k       // không RNE, pack, saturation hoặc mất bit mỗi MAC
READ: D = R(Q_K)              // chỉ tại đây mới RNE/kẹp về Posit32/ES3
```

Đây là tích lũy chính xác **các tích approximate đã định nghĩa**, không phải exact dot-product của A/B nguyên vẹn26 fraction. Ở n12 hết iteration_cut nhưng input_cut vẫn có thể1. Giữ hai đối chứng riêng: oracle tổng các P_hat cho bit-exact; Ideal tổng A×B đầy đủ để đo sai số approximate. Không dùng kết quả NF/F đã RNE làm số hạng quire.

Chuỗi tích lũy qua NF/F (dù hồi tiếp nội bộ ở snapshot cũ hay hồi tiếp ngoại vi qua cổng `c` ở kiến trúc mục tiêu Phương án A) đều làm tròn Posit32 sau từng giao dịch và phải giải mã lại ở giao dịch kế tiếp. Ngược lại, `posit_mac_quire` bỏ hoàn toàn Packer/Parser khỏi vòng hồi tiếp nội bộ và giữ đúng toàn bộ tổng rộng `Q` trong suốt chuỗi MAC. Không tự bật đường exact26 fraction để phục vụ profile Q12.

### 9.2 Phân rã phần cứng

| Khối | Hợp đồng |
| --- | --- |
| Core/Prepack | Dùng lại token M26/Q24/sign/b; flags xấp xỉ tách khỏi dữ liệu |
| Quire alignment | Đổi P_hat sang lưới cố định, không jam/truncation; mọi bit rơi ra phải chứng minh bằng0 trên miền được hỗ trợ |
| Signed accumulator | Cộng/trừ vào thanh ghi Q rộng với carry/headroom, commit một lần, kiểm overflow |
| Context/status | Count, NaR/invalid và OR loss của chuỗi; giữ khi READ stalled |
| Read normalizer/Packer | Chỉ READ mới dò dấu/LOD/scale/fraction/GRS của toàn Q rồi RNE theo §2 |

Có thể dùng carry-propagate, carry-save hoặc cộng chia word nhiều chu kỳ nếu tương đương và công bố latency/throughput. Không bắt buộc một carry-chain gần1000 bit trong một clock. READ trên carry-save phải resolve carry trước khi pack; không làm tròn riêng hai vector rồi cộng.

Read adapter phải dò toàn bộ magnitude Q: giữ các bit cao cần cho frac53 và OR toàn phần thấp còn lại vào sticky **sau khi đã có tổng chính xác**. Scale READ tính bằng signed width đủ cho E_LSB và W/headroom; kiểm biên ±240 trước khi thu hẹp sang sf11, không cast làm wrap một tổng lớn thành số nhỏ. Không dùng sticky của từng MAC thay việc giữ bit trong Q.

### 9.3 Miền giá trị, lưới và headroom

Không lấy số bit của cửa sổ cộng F, 84 bit hoặc quire512 của chuẩn es2 áp trực tiếp cho (32,3). Release quire MUST ghi rõ miền đầu vào, `L_max` số MAC tối đa giữa CLEAR, lưới E_LSB và W thực tế. Chưa khóa L_max/W là blocker của phần mở rộng, không chặn NF/F.

Với **toàn miền Posit(32,3)**: minpos=2^-240,maxpos=2^240. Mọi toán hạng hữu hạn và bản fraction12/selected-bit của nó là bội nguyên của2^-240. Điều này cần chứng minh từ run regime/số bit fraction thực có, không suy chỉ từ sf_min và width26. Tích P_hat là bội2^-480, |P_hat|≤2^480. Chọn E_LSB=-480, U=Q×2^480 là signed integer.

Với H=ceil(log2(L_max)), một **cận đủ bảo thủ** là `W=962+H` bit signed, q_nar/q_overflow lưu riêng. Lý do: mỗi tích có hệ số nguyên độ lớn≤2^960; sau≤2^H tích, |U|≤2^(960+H), nằm trong signed W này. W962 đủ cho một tích; ví dụ L_max1024,H10 cần cận đủ972 bit. Đây là suy ra cho cấu hình đồ án, không là tuyên bố độ rộng quire chuẩn hay độ rộng tối thiểu đã tối ưu.

**Cấu hình hiện thực Q12-1024,03/11/2026:** khóa toàn miền Posit(32,3),
`L_max=1024`, `E_LSB=-480`, `W=972`, count11 bit. Hằng số literal, không public
parameter thay format/width. Bank dùng27 bước cộng word36 bit có carry37,
commit Q một lần sau word cuối; không cộng972 bit trong một clock. READ chuyển
trị tuyệt đối theo27 word, scan từ word cao, giữ53 fraction và sticky toàn
phần thấp; kiểm scale trước khi đưa về sf11 của Packer RNE2 tầng. Latency/II
đo từ mô phỏng, chưa là timing/STA. Đây là chốt kiến trúc triển khai, chưa
cấp nhãn MAC_Q12_VERIFIED.

Tổ chức nguồn: `rtl/quire_active.f`19 module, top structural `posit_mac_quire`,
`mac_quire_wrapper`, `quire_align_comb`, `quire_bank`, `quire_read`; dùng lại
Parser/core/Packer của NF/F nguyên hash. Align đổi dấu hệ số27 bit trước
sign-extension/dịch, không suy bộ cộng đổi dấu972 bit. Bank dùng thanh ghi
Q kiến trúc cùng hai thanh ghi làm việc; Q chỉ cập nhật sau word cuối.
READ dùng snapshot riêng nên không thay đổi Q hoặc count.

Quire alignment tính `u_term=(-1)^sign × M × 2^(b-24-E_LSB)`. Với E_LSB=-480, shift=b+456 có thể âm ở biên nhỏ; chỉ được dịch phải nếu các bit loại đều0 do ràng buộc mã Posit thực, phải assert/kiểm oracle. Không wrap lượng dịch hoặc OR sticky thay bit bị loại. Nếu muốn giao diện prepack tổng quát nhận mọi tuple M/b không có tương quan Posit, phải chọn lưới rộng hơn/chứng minh lại bounds.

Một quire hẹp theo **miền scale giới hạn** được phép là profile nghiên cứu riêng, phải công bố miền và hành vi từ chối ngoài miền; không gọi là quire toàn miền32/3. Fraction12 tự nó không làm mất nhu cầu dải scale rộng. Final output vẫn clamp theo Posit32, còn state Q không clamp theo maxpos của Posit mỗi MAC.

### 9.4 Giao thức đề xuất và ngoại lệ

Top mở rộng riêng `posit_mac_quire`, không thêm mode vào hai top NF/F. Lệnh dùng `q_cmd[1:0]`: 00=CLEAR,01=MAC,10=READ,11=reserved. Có in_valid/in_ready, clk/rst_n; A/B/cfg_n/cfg_ops có ý nghĩa trên MAC, defaults OPS1/n12. Không có toán hạng C trong profile này; khởi tạo bằng CLEAR. LOAD-C là mở rộng khác nếu cần, phải có hợp đồng riêng.

Mỗi lệnh hợp lệ nhận một response in-order qua out_valid/out_ready, trả `out_cmd`, d32, flags5 và q_overflow1. CLEAR/MAC là acknowledge với d=0, **không pack Q để trả ack**; READ trả R(Q). Ban đầu một lệnh outstanding: chỉ nhận lệnh tiếp theo khi response trước được retire; không đọc Q khi cộng chưa commit. READ không xóa Q; CLEAR xóa Q/count/NaR/overflow/loss. Reset flush mọi pending, Q/status về0 và startup như top chính. Dữ liệu/status response giữ ổn định khi stalled; MAC commit một lần trước ack và không lặp do out_valid kéo dài.

MAC đủ L_max thì từ chối nhận MAC tiếp theo bằng in_ready=0; CLEAR/READ vẫn được nhận khi slot rỗng. Reserved/invalid n/OPS chỉ từ chối, không hỏng Q. Count tính mọi MAC được commit, kể cả zero/NaR, không tính READ/CLEAR/reset-abort.

Nếu MAC đã commit nhưng ack chưa retire rồi reset, count/Q của epoch đó bị xóa; monitor vẫn ghi nhận commit nội bộ để debug, song giao dịch thuộc reset-aborted, không được cộng vào completed nghiệm thu. Luôn kiểm accepted_commands=retired_responses+reset_aborted, tách thống kê theo q_cmd.

NaR của A/B ưu tiên 0; q_nar sticky tới CLEAR/reset. Nếu overflow nội bộ ngoài bound xảy ra, MUST set q_overflow/q_invalid, giữ trạng thái lỗi tới CLEAR/reset, READ trả NaR và flags10000; không silent wrap/saturate Q. Kiểm overflow bằng carry mở rộng/W+1 hoặc chứng minh tương đương, không dùng cờ sat_max của Posit thay q_overflow.

Loss của chuỗi OR input_cut/iteration_cut từng MAC. READ flags: nar ưu tiên; sat_max/min chỉ theo pack tổng cuối; inexact=chain_loss hoặc mất thông tin tại final pack; approx_cut=OR iteration_cut. CLEAR/MAC ack trả status/loss hiện tại, sat bits0; q_nar/q_invalid thì flags10000. Ngữ nghĩa OR cả chuỗi chỉ thuộc quire, không đổi flags từng giao dịch NF/F.

### 9.5 Testbench và nghiệm thu mở rộng

Golden Q dùng bigint/rational, cộng P_hat chọn bit độc lập từ raw Posit, không cửa sổ cố định nhỏ hoặc double. Scoreboard quản lý queue lệnh, count và Q/status ở commit/response; reset-abort không được cập nhật Q vào epoch sau. Probe so Q **mỗi MAC**, không chỉ d ở READ.

Oracle1024/grid2^-532 của MAC đơn lẻ không tự chứng minh đủ cho mọi L_max của quire. Phải chọn bigint không giới hạn hoặc kiểm lại cả lưới và carry/headroom cho oracle chuỗi, độc lập với width DUT.

| Test / Gate | Điều kiện đạt trước khi công bố quire |
| --- | --- |
| TC-Q-BOUND | Chứng minh E_LSB/W/L_max; đủ biên minpos²,maxpos², dấu và chuỗi cùng dấu L_max; không bit mất/overflow trên miền hợp lệ |
| TC-Q-STATE | CLEAR/MAC/READ/reset/stall, NaR persistent/clear, invalid và capacity, count/commit một lần; 0 lost/duplicate |
| TC-Q-NOROUND | Ví dụ tổng1 rồi ba tích2^-28: Q giữ1+3×2^-28, READ trả1+2^-26 (code0x40000001); không trả1 do RNE từng bước. Có thể tạo1 bằng MAC1×1 và phần nhỏ bằng2^-14×2^-14 với dữ liệu đúng32/3 |
| TC-Q-CANCEL | Số hạng lớn rồi phần nhỏ rồi số hạng lớn đối dấu; exact cancel, hoán vị thứ tự cùng tập P_hat; Q cuối phải giống khi không overflow |
| TC-Q-CONVERT | READ nhiều lần không đổi Q, sticky-only/tie-even/odd/biên min/max, cả dấu, shift âm nhưng suffix0 và mọi headroom boundary |
| Q-MODEL | L1 quire khớp golden mọi checkpoint/status và final RNE; giữ Ideal nguyên đầu vào riêng để đo sai số |
| Q-RTL | Pilot≥10^5 rồi main≥10^7 MAC committed và ack đã retire với OPS1/n12; ≥10^4 chuỗi có cả dài>12 và L_max trong corner; OPS0/n0..12 quét chức năng riêng, chưa gọi đây là ma trận52 điểm quire |
| Q-COVER/PPA | Functional bins100% hợp lệ, line≥95/branch≥90/toggle≥85; reset/stall4-state; báo LUT/FF/BRAM/DSP và post-route/latency thật của quire riêng, không mượn số NF/F |

Số MAC có thể bằng0 ở một chuỗi CLEAR→READ; scoreboard vẫn phải kiểm READ zero. Nếu L_max≤12 thì không thể đạt bin dài>12: chọn L_max≥13 cho release nghiên cứu này, không miễn bin âm thầm. Sequence permutations chỉ so khi từng product config/OPS giữ nguyên, không đổi vai/chọn bit giữa các thứ tự.

**Bằng chứng Q12-1024 ngày03/11:** proof447 hình học field/199809 cặp xác nhận
lưới và bounds; model94727 checkpoint/READ cùng4881 fixture Python bigint độc
lập; unit32768 align,21948 READ/normalization,1041 bank; pilot100k mixed và
main10M MAC retired OPS1/n12 trên4 seed đều0 mismatch. Main có19428 chuỗi>12,
38 chuỗi1024; không tính preamble mixed hoặc lượt dở vào10M. ModelSim4-state:
4881 accepted=4876 completed+5 reset-aborted,0 mismatch; giữ response lúc stall,
kiểm Q từng commit. Latency accept→first valid trước giữ output: CLEAR1,
MAC7..42,READ3..57 chu kỳ; phụ thuộc bypass/iteration/scan, không là Fmax/II.

Coverage hợp module-point cùng hash: thô line93.269%,branch95.122%,toggle97.050%;
sau3 loại trừ line có giải thích/source SHA theo §6.6: line96.040%; không
loại toggle/branch. [Review](results/quire_20261103/coverage_review.json) giữ
đầy đủ tỷ lệ thô, lý do và điểm chưa hit; không vay coverage NF/F.

A35T OOC route đơn10ns: LUT10339,FF4453,BRAM0,DSP0,setup−12.016ns,
hold+0.015ns. Đường găng core.sf_o→align/zero/error→bank.sum_work.CE,
delay21.575ns (route15.505ns),32 mức logic. **Không đạt100MHz**; chưa sweep
Fmax hoặc board. Trạng thái `FUNCTION_VERIFIED_TIMING_OPEN`; bước tiếp theo
là tách pipeline/giảm fanout đường align và điều khiển bank, kiểm lại phạm
vi bị tác động. Giữ nguồn đã kiểm trong `rtl/quire_checkpoint.json` và ZIP
bằng chứng; không đổi nhãn cũ hoặc xem synth/route exit0 là timing PASS.

Gate NF/F AC-01..08 giữ nguyên. Chỉ khi Q-MODEL/Q-RTL/Q-COVER và bounds đạt mới gắn nhãn MAC_Q12_VERIFIED; không đổi tên kết quả20M/350M hoặc fixture FLOOR thành bằng chứng quire.

## 10. Lịch sử revision và nguồn tham khảo

v1.29: chốt Phương án A cho hai lõi NF/F (`posit_mac_nf`, `posit_mac_f`) — chuyển lõi IP mục tiêu thành bộ nhân–cộng luồng thẳng `D = A × B + C` nhận trực tiếp cổng `c`, gỡ thanh ghi hồi tiếp `accumulator_q` cùng cổng `acc_mode`/`acc_clr` và MUX `c_eff` khỏi lõi NF/F để triệt tiêu đường găng F2F `accumulator_q → Parser C`; điều chỉnh đồng bộ §1, §3, §4.2, §4.4, §5, §6, §8, §9.1 mà không làm mâu thuẫn với bằng chứng snapshot ngày 02/11/2026 và giữ nguyên hợp đồng mở rộng `posit_mac_quire` (§9).


v1.28: triển khai Q12-1024 với signed972/grid2^-480, cộng27 word36, READ RNE;
bổ sung proof/bằng chứng model/unit/pilot/main10M/ModelSim/coverage và ghi rõ
setup100MHz chưa đạt. Dọn TB/runner cũ vào archive có hash; xóa cache/binary;
giữ bộ kiểm chứng tái lập, không đổi hợp đồng hay nghiệm thu NF/F.

v1.27: cập nhật trạng thái hiện thực31 module/core dùng chung, bỏ cfg_mode/exact, kết quả unit/pilot/ModelSim và coverage còn thiếu; giữ nguyên ngưỡng main/AC04, chưa cấp nghiệm thu cuối hoặc PPA mới.

v1.26: khóa mặc định OPS1/n12, phân biệt12 fraction với13 significand; mở rộng block contracts, prepack26/Q24 và adapter F không suy hao; đồng nhất adder5 tầng; bổ sung testbench/truy vết và hợp đồng MAC_Q12 với bounds/giao thức/nghiệm thu riêng. Phiên v1.26 chỉ sửa tài liệu.

Tham khảo chính:

- Norris, C. J. và Kim, S. (2021), *An Approximate and Iterative Posit Multiplier Architecture for FPGAs*, ISCAS: cơ sở kiến trúc dịch–cộng; [PDF local](An%20Approximate%20and%20Iterative%20Posit%20Multiplier%20Architecture%20for%20FPGAs.pdf).
- Murillo, R., Del Barrio, A. A. và Botella, G. (2020), *Customized Posit Adders and Multipliers using the FloPoCo Core Generator*, ISCAS: giải mã/cộng/đóng gói; [PDF local](Customized%20Posit%20Adders%20and%20Multipliers%20using%20the%20FloPoCo%20Core%20Generator.pdf).
- [Digital Design Guidelines](Digital_Design_Guidelines.md): quy tắc RTL/clock/reset. Spec hiện hành ưu tiên về format/profile/nghiệm thu so với các nhật ký có ngày cũ.
- [Posit Standard2022 §5.11](https://posithub.org/docs/posit_standard-2.pdf): tham khảo nguyên lý qMulAdd và qToP cho quire. Chuẩn2022 dùng exponent2 bit; ES3/Q12 và cận width ở §9 là cấu hình/mở rộng riêng của đồ án, không tuyên bố tuân thủ toàn chuẩn.
