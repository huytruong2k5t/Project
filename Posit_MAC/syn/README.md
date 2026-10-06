# Thư mục Tổng hợp FPGA (`syn/`)

Thư mục này chứa toàn bộ kịch bản TCL, file ràng buộc timing/vật lý XDC, và các thiết kế baseline phục vụ đánh giá PPA (Power - Performance - Area) trên FPGA theo §7 của [SPEC_Posit_MAC_IP.md](../SPEC_Posit_MAC_IP.md).

---

## 1. Chính sách Thiết bị Bậc thang (§7.6 SPEC)

Do thiết bị `xcvu9p` (Virtex UltraScale+) trong bài báo [P] yêu cầu gói bản quyền trả phí, đồ án áp dụng chính sách bậc thang 5 cấp độ để bảo đảm kết quả PPA luôn khách quan, trung thực và có giá trị khoa học dựa trên **tỉ lệ tương đối** ($R_{\text{LUT}}, R_{f_{\max}}$):

| Bậc | Nền tảng Công cụ | Thiết bị đại diện | Đặc điểm kỹ thuật | Mức độ so sánh |
|:---:|:---|:---|:---|:---|
| **D0** | Vivado (Bản quyền) | `xcvu9p-flgb2104-2-i` | Virtex UltraScale+ 16nm | Tái hiện trực tiếp số liệu tuyệt đối của [P] |
| **D1** | **Vivado ML Standard (Miễn phí)** | **`xcau15p-ffvb676-2-e`** hoặc **`xczu3eg-sbva484-1-e`** | **Artix / Zynq UltraScale+ (16nm)**, cùng kiến trúc CLB (**8 LUT6 + CARRY8**) như D0 | **Khuyến nghị chính**: Tỉ lệ $R_{\text{LUT}}$ và $R_{f_{\max}}$ đáng tin cậy cao |
| **D2** | Vivado ML Standard (Miễn phí) | `xc7a100tcsg324-1` | Artix-7 (28nm), chuỗi nhớ CARRY4 | So sánh tỉ lệ tương đối trên chip sinh viên phổ thông |
| **D3** | Yosys `synth_xilinx` | Family Xilinx 7-Series | Hoàn toàn mã nguồn mở | Bằng chứng kiểm chéo thứ cấp |
| **D4** | Yosys + OpenROAD (EXT-A) | Nangate45 / SKY130HD | ASIC Standard Cell | Đo diện tích thực $\mu\text{m}^2$ và công suất |

---

## 2. Quy chuẩn Tổng hợp Out-of-Context (OOC)

- **Cấu hình ràng buộc**:
  - Chế độ Out-of-Context: tổng hợp độc lập không chèn I/O buffers (`synth_design -mode out_of_context`).
  - **Triệt tiêu DSP và BRAM**: `-max_dsp 0`, không sử dụng BRAM để đối chiếu công bằng với bài báo [P] và PACoGen.
  - Quét chu kỳ xung nhịp đích: $1.6\text{ ns}$ (625 MHz), $2.0\text{ ns}$ (500 MHz), $2.5\text{ ns}$ (400 MHz), $3.3\text{ ns}$ (300 MHz).
  - Độ nhạy: Chạy tối thiểu $\ge 3$ seed/chiến lược implementation để lấy trung vị (median).

---

## 3. Cấu trúc Thư mục

- `syn_posit_mac.tcl`: Kịch bản điều khiển chạy tổng hợp, tối ưu hóa logic, và routing tự động.
- `constraints.xdc`: File ràng buộc xung nhịp `create_clock` và các ràng buộc độ trễ I/O.
- `baseline/`:
  - `pacogen/`: Mã nguồn bộ nhân Posit PACoGen cùng cấu hình `(NB, ES)`.
  - `fp_baseline/`: Mã nguồn Floating-Point MAC IEEE-754 (FP32/FP16) tạo bởi Vivado IP Catalog (không DSP) để so sánh PPA đối chứng.
