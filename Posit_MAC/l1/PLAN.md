# Xây dựng L1, baseline nội bộ và MAC non-fused/fused

**Cập nhật:** 17/10/2026 — tài liệu kiến trúc, mapping và build; không còn là nhật ký tối ưu hoặc lịch nghiệm thu theo tuần.

- [SPEC hiện hành](../SPEC_Posit_MAC_IP.md): nguồn quy định chính về số học, width, flags và giao dịch.
- [Optimization.md](../../doc/Optimization.md): phương án tối ưu RTL và mọi báo cáo kiểm chứng/synthesis/STA đã chuyển từ PLAN cũ.
- [Tiến độ đồ án](../docs/TIEN_DO_DO_AN.md): các việc chưa làm/processing, kế hoạch tuần và mốc đã hoàn thành.
- [README L1](README.md), [README RTL](../rtl/README.md), [hướng dẫn chạy](../docs/HUONG_DAN_CHAY_WSL_MODELSIM.md): lệnh và bản đồ mã nguồn.

## 1. Mục tiêu và phạm vi mô hình

Baseline chính của đồ án là MAC NF normative; biến thể so sánh là MAC fused trên cùng hợp đồng nhân xấp xỉ. Nhánh paper là nghiên cứu tái dựng, không phải RTL tác giả và không chặn NF/F. L1 mô tả số học/state theo giao dịch; đúng L1 không tự chứng minh RTL đúng timing, reset/stall hoặc mọi cấu hình.

| Nhánh | Profile / vai trò | Nguồn chính |
| --- | --- | --- |
| Exact bổ trợ | Posit8/ES0,16/ES1,32/ES2 đối chiếu SoftPosit đúng format | parser/packer, l1_multiplier_exact, posit_adder |
| Nhân lặp normative | NB/ES theo miền đã công bố; profile so sánh32/3,FW12,FLOOR/RNE,OPS1,n0..8 | l1_multiplier_iter.hpp, floor_rne_profile.hpp |
| NF legacy | MAC v0/v1 và API cũ giữ nguyên checkpoint | posit_mac.hpp, l1_api.h/src/l1_api.cpp |
| NF so sánh | Bảo toàn P_hat rồi làm tròn tích trước cộng C_eff | exporter prepack, tb/week11_model.hpp, RTL mac_nf |
| F profile chính |32/3,FW12,W32/Q29, approximate-only; signed residual/borrow và RNE cuối | posit_fused_window.hpp, RTL mac_f |
| Paper | Predictor/source/relative/fig3 là các profile nghiên cứu có tên riêng | paper_ops, paper_multiplier, paper_measurement, paper_fig3_accumulator |

SoftPosit chuẩn không cung cấp oracle32/ES3. ES3 phải dùng integer/dyadic/full-grid độc lập; không suy đúng ES3 chỉ từ kết quả ES2 hoặc dùng SoftPosit ES2 làm oracle. Exact fused rộng, format phụ, quire và nhiều giao dịch chồng lấn không tự thuộc profile chính.

## 2. Nền tảng L1 và các module

L1 là thư viện C++17 header-only trong `l1/include`; wrapper C trong `l1/include/l1_api.h` và `l1/src/l1_api.cpp`. Không sửa mặc định legacy để chọn profile nghiên cứu hoặc profile so sánh mới.

### 2.1. Biểu diễn và parser

`posit_unpacked<NB,ES>` gồm sign, is_zero, is_nar, int32_t sf, uint64_t frac và exact. Hidden bit của L1 nằm ở bit63 của frac; RTL parser xuất fraction không hidden nên scoreboard phải quy đổi. exact chỉ phản ánh đuôi số học, không thay input_cut/iteration_cut/term_cut.

Parser: nhận diện zero/NaR; lấy magnitude bằng bù hai nếu âm; đọc bit regime đầu r; đếm phần còn lại giống r. Với cnt không gồm bit đầu, k=cnt khi r1, k=-(cnt+1) khi r0. Bỏ regime/terminator rồi lấy exponent và fraction; sf=k*2^ES+e. C++ dùng phép nhân cho k âm. Không có terminator thì cnt=NB-2, payload0; không lấy trực tiếp K0 của detector invalid.

L1 có thể dùng cách căn payload khác RTL nhưng phải cùng giá trị. RTL hiện dùng XOR tail và một detector; chi tiết tối ưu/kiểm nằm ở Optimization, không đổi hợp đồng giải mã.

### 2.2. Packer và round_unpacked

RNE: xử lý special, pre-clamp đúng biên, mã hóa regime/exponent, dịch và tách retained/G/R/S. round_up=G&(LSB|R|S). Kẹp sớm minpos chỉ khi sf<-SF_MAX; tại sf=-SF_MAX vẫn mã hóa/RNE. Áp dấu sau xử lý magnitude theo hợp đồng. TRUNC là profile riêng, không mặc định tái dựng paper.

`round_unpacked` phải tương đương parse(pack(u)) với cùng rounding, specials và metadata; không chỉ cắt fraction theo sf. Đây là phép biến đổi số học trong L1, không cam kết tiết kiệm số chu kỳ RTL. NF production OPT-03 hiện dùng product packer P1/P2 rồi parser tổ hợp và product bank riêng.

### 2.3. OPS, SAC và SBM

- OPS0 giữ X=A,Y=B. OPS1 đếm bit1 của fraction thực dùng; chọn ít bit1 hơn làm X, hòa giữ A. Approximate chỉ dùng FRAC_W bit cao; exact dùng FRAC_MAX. X không hidden; Y có hidden. cfg_ops2/3 bị từ chối theo top contract.
- SAC mỗi term: sa=clz(fx)+1, S+=sa, fx=(fx<<sa)&mask(W). Giữ width/carry khi kiểm lỗi scale. Dừng khi fx0 hoặc hết n; n đếm fraction, không tính hidden.
- SBM khởi tạo acc=1.fY cho hidden của X; n0 vẫn có token init_only. Cộng các term Y>>S. FLOOR cắt term theo profile; STICKY_ACC là scheme khác. Cut xấp xỉ là metadata, không tự biến thành numerical sticky.
- Exact dùng đủ fraction và precision đã công bố, không bị N_MAX giới hạn. iterations/remaining_fx/input_cut/approx_cut/inexact là các thông tin riêng; fx0 không đồng nghĩa kết quả toán học chính xác nếu đã cắt term/input.

### 2.4. Bộ cộng Posit

So độ lớn theo sf rồi fraction, chọn dấu/base; căn toán hạng nhỏ bằng right shift. Khi delta>FRAC_MAX+2, giữ đúng quy tắc y=1/tail, không dùng shifted_at_limit|1 tùy ý. Cộng/trừ dấu lượng; zero cancellation sign0; LZC/shift và sf phục hồi chuẩn hóa. Giữ tail/flags để packer RNE xử lý đúng. Không thay cờ inexact khi kết quả0 nếu hợp đồng yêu cầu giữ metadata.

## 3. Tích prepack và baseline NF

### 3.1. Hợp đồng P_hat

`PrepackProduct` trong `prepack_product.hpp` giữ magnitude, scale, fractional_bits, magnitude_bits, sign, zero/NaR, numerical_sticky và ba loại cut. Giá trị hữu hạn:

```text
P_hat = (-1)^sign * magnitude * 2^(scale - fractional_bits)
```

Exporter lấy trước normalize/pack. Profile so sánh gọi tường minh `floor_rne_profile(n)`; hàm khóa approximate/FLOOR/RNE/OPS1 và n<=8, không đổi IterConfig mặc định. `FloorRneMultiplier` là32/3/FW12/N_MAX8, feature exact/OPS còn theo template.

FLOOR cắt định nghĩa chính P_hat trên lưới hữu hạn; input_cut/iteration_cut/term_cut báo tổn thất so phép nhân lý tưởng. Không OR chúng vào numerical sticky để đổi P_hat. Normalize tích có carry phải bảo toàn giá trị trước RNE; không dùng legacy normalize như một giả định tương đương nếu chưa có hợp đồng phù hợp.

### 3.2. NF legacy và NF so sánh

`PositMac`/`MacAccumulator` là API legacy giao dịch, giữ checkpoint và default cũ. Harness NF prepack-preserving dùng `tb/week11_model.hpp` và oracle độc lập theo SPEC; không đổi model frozen legacy để ép khớp NF mới.

Với R là RNE về cùng Posit:

```text
NF(A,B,C_eff) = R(R(P_hat) + C_eff)
```

Round tích trước cộng, flags đi đúng hai bước. Acc_mode dùng accumulator NF riêng; acc_clr có hiệu lực tại request accepted. Mô hình giao dịch không mô tả ready/valid/CK2Q của RTL.

### 3.3. RTL NF và lịch hiện hành

```text
parser A/B/C_eff P1/P2 (song song)
→ OPS/M0 → SAC/L1 → SBM shift/L2 → accumulator/L3
→ normalize + product P1 → product P2 → parse/product bank
→ adder A1/A2/A3 → final packer P1/P2
```

NF có14 tầng datapath; core ba tầng lặp theo term. q=max(1,t thực tế); E0 nhận input, product P1 ở E(q+5), P2 ở E(q+6), product bank E(q+7), A1/A2/A3 ở E(q+8/9/10), final P1/P2 ở E(q+11/12). L_valid=q+12,H=q+13,II_min=q+14 khi không stall. Không cộng bank C/context/commit thành tầng số học mới. A1 production chưa áp OPT-02b candidate.

## 4. L1 và RTL fused W12-F-1

### 4.1. Cửa sổ và phần dư

L1 `FusedWindow<32,3,12,32>`/`FusedWindowAccumulator` dùng W32/Q29; W gồm sign và retained sum, residual sign/nonzero và flags ở ngoài. Không gọi W32 là đủ cho FMA exact toàn miền32/3. Mục tiêu số học là R(P_hat+C_eff), vẫn khác R(A*B+C_eff) do P_hat xấp xỉ.

Anchor lấy từ tích đã xét carry: e_P=scale+msb(magnitude)-fractional_bits; chọn max(e_P,e_C) khi hai toán hạng hữu hạn khác0. Căn retained operands theo anchor và Q, giữ residual có dấu của toán hạng nhỏ. Không dùng clamp FRAC_MAX+2 của adder NF cho align fused.

Cận precision của profile giữ toán hạng lớn chính xác và tối đa một residual. Nếu residual ngược dấu retained sum, đổi |Z|-delta thành (|Z|-1)+(1-delta); không jam dương trực tiếp. Zero retained với residual khác0 hoặc deep cancellation trái invariant phải bị phát hiện, không âm thầm trả0. Normalize magnitude, tính sf=anchor+msb(mag)-Q, chuyển tail đúng vị trí rồi pack RNE một lần. Sat/range từ tổng cuối; giữ zero/inexact và NaR flags theo SPEC.

F có accumulator riêng; mỗi giao dịch acc_mode vẫn RNE một lần khi commit, không phải quire hoặc fused dot-product cả chuỗi. NF/F/Ideal có thể có C_eff khác nhau sau nhiều giao dịch và phải được mô hình state riêng.

### 4.2. Mapping RTL hiện hành

| Tầng | Module / công việc |
| --- | --- |
| Parser/M0/core | Reuse parser và OPS/SAC/SBM theo profile approximate12 bit; không pack tích trước F |
| F1 | fused_prepare_comb: normalize carry P, anchor, seeds, delta/context |
| F2 | fused_align_comb: right-align và residual sign/nonzero |
| F3 | fused_arith_comb: cộng/trừ retained |
| F4 | fused_abs_borrow_comb: magnitude và hiệu chỉnh borrow |
| F5 | fused_norm_comb: LOD/shift/sf và adapter fraction/sticky |
| P1/P2 | posit_pack RNE: lần round Posit cuối |

Bank elastic nằm trong fused_add_pipe; mac_f_wrapper giữ C/config/accumulator và reset bridge; posit_mac_f chỉ instance. F hiện chặn tuple ngoài NB32/ES3/FW12/W32,N_MAX8,EXACT_EN0,OPS_EN1; không suy C++ template tổng quát đồng nghĩa RTL hỗ trợ mọi tuple.

F có13 tầng datapath; q=max(1,t), L_valid=q+11,H=q+12,II_min=q+13. Top một giao dịch, commit đúng một lần khi kết quả valid lần đầu rồi giữ output tới retire; không nhận mới trước retire. Leaf pipeline elastic có sức chứa riêng, không dùng II leaf làm II top.

## 5. Nhánh baseline paper và phép so sánh

Nhánh paper độc lập với normative: predictor n2/prefix7, source/relative E/M, accumulator fig3 và policy width/cut là các profile có tên. Tái dựng từ nguồn không đủ để xác nhận full LUT/tie/seed/generator hoặc RTL tác giả. Fig4 force-X phải cho0x1ae34000; khớp thống kê TableI không thay khớp trace/ví dụ. Không dò seed/width để ép bảng.

Paper code trong l1/include/paper_*.hpp và rtl/research/paper; commands và kết quả lịch sử tại README L1 và Optimization. Việc truy provenance còn mở được theo dõi trong tiến độ như nghiên cứu phụ, không chặn baseline nội bộ.

So NF/F cùng P_hat, precision/OPS/n, corpus seed đã khóa và oracle độc lập; không lấy NF làm chân lý của F. Accuracy xử lý zero/NaR/gần0 riêng, báo cả trường hợp F kém hơn NF. PPA cần comparator NF EXACT_EN0 đã kiểm/freeze, cùng part/tool/constraints/feature policy; không ép hai kiến trúc cùng số tầng hoặc so LUT4 với LUT6 trực tiếp. Chi tiết tối ưu/đo chuyển về Optimization; lịch và ma trận còn lại ở tiến độ.

## 6. Build, source list và tái lập

**Thiết bị khảo sát tiếp theo:** chỉ A35T `xc7a35tcpg236-1` cho mọi phép đo mới, baseline/candidate và paired NF/F. Không chạy A100T; số đo A100T trước17/10 giữ làm lịch sử trong Optimization. Khi runner cũ hỗ trợ nhiều part, chọn tường minh A35T; không sửa snapshot/hash cũ để bỏ bằng chứng.

Chạy từ gốc Posit_MAC; WSL dùng bash --noprofile --norc, tmp/build/log trong dự án. Không cài runtime toàn hệ thống hoặc sửa tool/license để tái lập. Đọc hướng dẫn chạy trước khi chọn runner vì nhiều runner từ chối output cũ; không chạy prepare/refreeze vào snapshot đã khóa.

| Mục đích | Build / nguồn / runner hiện có |
| --- | --- |
| L0 | make -C l0 all; dùng SoftPosit đúng format |
| L1 libraries và legacy model | make -C l1 linux windows; chọn target cụ thể khi không cần build cả nhóm nghiên cứu |
| Exporter prepack | make -C l1 test_prepack_product test_prepack_product.exe test_prepack_product_ubsan |
| L1 fused và oracle | scripts/verify_week12_oracle.sh, verify_week12_window.sh, verify_week12_coverage.sh, verify_week12_trace.sh; các script này build rồi kiểm, không phải build-only |
| NF model/harness | tb/week11_model.hpp, week11_mac_harness.cpp, nf_coverage_harness.cpp; runner theo checkpoint W11 hoặc OPT-03, không trộn lịch cũ/mới |
| F RTL/harness | scripts/run_week13_acceptance.sh, verify_week13_pipe.sh, run_week13_xilinx.ps1; đọc mode simulate/ppa trước chạy |
| RTL file list | rtl/production.f, header rtl/posit_mac.vh, resolver scripts/rtl_paths.{sh,ps1,py} |
| Baseline paper | Các target/CLI trong l1/Makefile và README L1; giữ profile và source manifest riêng |

Không compile glob đệ quy rtl/: candidate trùng tên module production. Candidate chỉ thay đúng file trong source list private; không compile đồng thời hai bản cùng tên.

Checkpoint nguồn/corpus cần đọc trước build: results/l1_floor_rne_freeze/summary.json; results/week12/freeze.json; results/week11/baseline_nf_manifest.json; results/opt03_20261017/summary.json; results/week13/summary.json. Binaries/caches có thể cần tái tạo, hash binary có thể khác compiler; không sửa hash lịch sử để gọi đó là cùng checkpoint. Receipt backup và log là chứng cứ lịch sử, không phải lệnh chạy.

## 7. Quy tắc kiểm và bảo toàn hợp đồng

Theo Digital Design Guidelines: một module/file, cổng rõ từng dòng/named mapping, signedness/width tường minh, always_comb đầy đủ, always_ff/nonblocking/CK2Q, không latch/gated clock LUT. Reset top/leaf và startup barrier theo SPEC, không thêm exception để che đường chức năng.

RTL so đúng model/oracle và checkpoint. Kiểm mọi output/flags, width/carry/cut/tail, reset/stall/order/commit, không chỉ kết quả cuối. Tách completed/reset-aborted và kiểm source/tool/corpus hashes. Strict lint và mô phỏng chu kỳ/event có phạm vi khác nhau; không xem synthesis-only là post-route Fmax. Ngưỡng và matrix final dùng SPEC; công việc chưa đạt được quản lý ở tiến độ, không đánh dấu lại bằng báo cáo cũ.

## 8. Bản đồ tài liệu sau sắp xếp

| Nội dung PLAN cũ | Nơi quản lý hiện nay |
| --- | --- |
| Thuật toán L1 và hợp đồng baseline/NF/F | PLAN này, mục1–7; SPEC và README giữ quy định chi tiết |
| Mục7.1,7.4–7.11;8.1,8.3,8.4,8.6,8.7,8.9,8.14,8.15.5–6 và thử baseline cũ | Optimization, phần hồ sơ kiểm chứng; giữ mã mục cũ |
| Mục8.10–8.13,8.16,8.18–8.25 | Optimization, phần tối ưu/RTL/STA và phương án tiếp theo |
| Lịch/checklist tuần đã hoàn thành | Gỡ khỏi PLAN; tiến độ giữ tóm tắt tuần/ngày và bằng chứng ở results/Optimization |
| W13-06/07 còn thiếu, W14–16, tối ưu chưa chạy và nghiên cứu phụ | Tiến độ mục2,3.1–3.4 |

Việc tách tài liệu không đổi số học, RTL, phiên bản SPEC, kết quả kiểm chứng hoặc trạng thái nghiệm thu. Không chạy lại mô phỏng/build/STA chỉ vì đổi nơi lưu tài liệu. Không chạy các script report/prepare lịch sử để tái chèn nhật ký vào PLAN; đọc README/snapshot của study và dùng collector hiện hành đúng vùng báo cáo.
