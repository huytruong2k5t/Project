# Checkpoint Posit MAC — 11/11/2026

## 1. Mục tiêu kỹ thuật

Hoàn thiện ba lõi Posit(32,3) trong cây `C:/HCMUT/HK261/Do an 2/Posit_MAC`. MAC-NF là baseline nội bộ để so sánh MAC-F về sai số, tài nguyên và timing. MAC-quire tích lũy chính xác các tích xấp xỉ và làm tròn khi READ. [SPEC v1.29](SPEC_Posit_MAC_IP.md)

## 2. Ràng buộc

- Chỉ hỗ trợ Posit(32,3), fraction nhân 12 bit và FULL_TERM26/Q24. Giữ đủ từng số hạng dịch, bỏ FLOOR từng vòng và dùng RNE khi pack. Driver mặc định OPS=1, n=12. Runtime hỗ trợ OPS 0/1 và n=0…12, dừng sớm khi hết bit 1.
- Chốt payload tại handshake đầu vào, giữ response ổn định khi stall và xóa giao dịch đang chờ khi reset. Đối chiếu kết quả cùng năm cờ với oracle số nguyên độc lập ES3. Gắn bằng chứng nghiệm thu với SHA-256 của nguồn đã kiểm. [Golden model](GOLDEN_MODEL_POSIT32_ES3.md)
- Mỗi file RTL chứa một module, nối cổng theo tên và tuân thủ Digital Design Guidelines. Giữ bộ kiểm chứng tái lập, báo cáo đối chứng, build và log trong dự án khi dùng WSL/ModelSim. [Digital Design Guidelines](Digital_Design_Guidelines.md) · [Hướng dẫn chạy](HUONG_DAN_CHAY_WSL_MODELSIM.md)

## 3. Kiến trúc và giao diện

**NF/F.** `posit_mac_nf` và `posit_mac_f` nhận `a/b/c[31:0]`, `cfg_n[3:0]`, `cfg_ops[1:0]`, `clk/rst_n` và valid/ready ở cả hai phía. Response gồm `d[31:0]` và `flags[4:0]` theo thứ tự `{nar,sat_max,sat_min,inexact,approx_cut}`. Hai lõi dùng chung parser `posit_parser_mul` hai tầng, core nhân lặp, `posit_add` năm tầng và Packer hai tầng. A/B dùng 12 bit cao của fraction và `tail_cut`. C giữ đủ 26 bit fraction. NF pack RNE tích trước khi cộng. F đưa tích chưa làm tròn vào adder. Khi cần tích lũy Posit32, bên ngoài hồi tiếp `d` đã retire vào `c`. [Bản đồ RTL](../rtl/README.md) · [File list 30 module](../rtl/mac_active.f)

**Quire.** `posit_mac_quire` nhận A/B và cấu hình nhân. `q_cmd[1:0]` mã hóa CLEAR `00`, MAC `01`, READ `10`. Mỗi lệnh hợp lệ trả một response theo thứ tự gồm `out_cmd`, `d`, `flags` và `q_overflow`. Chỉ có một lệnh outstanding. CLEAR/MAC trả `d=0`. READ trả kết quả RNE và giữ Q. Q signed rộng 972 bit, lưới 2⁻⁴⁸⁰ và giới hạn 1.024 MAC giữa hai CLEAR. Bank cộng theo 27 word 36 bit và commit một lần. READ quét tổng để tạo fraction 53 bit và sticky trước Packer. [Top quire](../rtl/mac_quire/posit_mac_quire.sv) · [File list 19 module](../rtl/quire_active.f)

## 4. Thay đổi đã kiểm chứng

- **NF/F.** Đã bỏ thanh ghi `accumulator_q`, MUX hồi tiếp và cổng `acc_mode/acc_clr` để loại đường hồi tiếp gây nghẽn timing vào Parser C. Hai lõi nhận C trực tiếp. Hồi quy 07/11 hoàn tất 100.000 giao dịch mỗi lõi, 0 mismatch, đủ 26 tổ hợp OPS×n. Ngày 11/11, cả 61 đầu vào trong manifest build của mỗi lõi đều khớp SHA-256 với cây làm việc. [Báo cáo 07/11](../results/shared_parser_mul_20261107/summary.md) · [Manifest NF](../results/shared_parser_mul_20261107/build_nf.json) · [Manifest F](../results/shared_parser_mul_20261107/build_f.json)
- **Quire.** Backend dùng hệ số 27 bit, chỉ số word và offset để dựng từng word cục bộ, thay shifter 972 bit. Bản tối ưu 04/11 qua ModelSim và hồi quy 1,1 triệu MAC với 0 mismatch. Synthesis 100 MHz đạt setup WNS **+0,170 ns** và hold WHS **−0,055 ns** trên bản này. [Báo cáo 04/11](../results/quire_opt_20261104/summary.md) · [Manifest build](../results/quire_opt_20261104/build_rtl_opt.json) · [Đối chứng synthesis](../results/quire_opt_20261104/comparison.csv)

## 5. Hạng mục nghiệm thu còn mở

- **NF/F.** Gói khóa 05/11 qua audit `--frozen-only` ngày 11/11. Audit xác nhận 29 module NF và 27 module F trong gói. Cây làm việc khác SHA-256 ở 6 đường dẫn RTL so với chỉ mục nguồn khóa. Còn ma trận **52 × 10 triệu**, quota regime, xác nhận coverage trên nguồn nghiệm thu, paired accuracy và timing sau route. [Gói khóa và SHA-256](../releases/current.json) · [Chỉ mục nguồn khóa](../releases/nf_f_20261105/source.sha256.json)
- **Quire.** Còn chạy route và kiểm lại trên nguồn nghiệm thu. So với manifest bản 04/11, bốn dependency RTL có SHA-256 khác trên cây làm việc. Kết quả 10 triệu MAC thuộc snapshot 03/11. Trạng thái `MAC_Q12_VERIFIED` vẫn mở. [Bằng chứng 10 triệu MAC](../results/quire_20261103/main_final_summary.json) · [Manifest bản 03/11](../results/quire_20261103/build_rtl_final.json)
  - [`rtl/common/lod_lzd_core_fixed4.sv`](../rtl/common/lod_lzd_core_fixed4.sv)
  - [`rtl/packer/posit_pack.sv`](../rtl/packer/posit_pack.sv)
  - [`rtl/packer/posit_pack_finish.sv`](../rtl/packer/posit_pack_finish.sv)
  - [`rtl/parser/posit_parser_f_regime_lod.sv`](../rtl/parser/posit_parser_f_regime_lod.sv)
