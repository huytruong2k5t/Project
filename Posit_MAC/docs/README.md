# Thư mục Tài liệu Kỹ thuật (`docs/`)

Thư mục này chứa toàn bộ tài liệu kiến trúc, đặc tả chi tiết, nhật ký quyết định thiết kế và hướng dẫn quy chuẩn của đồ án:

**Chốt29/10:** hợp đồng mới là approximate FULL_TERM M26/Q24,n0..12,RNE theo SPEC v1.23 §4.3.
RTL,L1 thực thi,testbench và mọi PASS cũ vẫn là profile được khóa trước đó;chưa có kiểm mới.

---

## 1. Danh mục Tài liệu Cốt lõi

| Tên Tài liệu | Mô tả chi tiết nội dung | Vị trí liên kết |
| :--- | :--- | :---: |
| **Đặc tả Lõi IP Posit MAC** | v1.23:FULL_TERM không FLOOR,26 bit/Q24,n0..12;phân biệt hợp đồng mới với RTL/L1/TB chưa chuyển.FR/NFR,vi kiến trúc,oracle/coverage và PPA giữ truy vết | [`SPEC_Posit_MAC_IP.md`](../SPEC_Posit_MAC_IP.md) |
| **Nhật ký Điểm mơ hồ & Quyết định** | Tóm tắt hợp đồng profile/n, latency, reset bridge và lịch core; dẫn SPEC §11 cho trạng thái, provenance và rủi ro, tránh sao chép thuật toán packer. | [`ambiguity.md`](ambiguity.md) |
| **Digital Design Guidelines** | Quy chuẩn thiết kế RTL số chuẩn công nghiệp: quy ước đặt tên file/module, clocking, reset leaf tích cực thấp assert bất đồng bộ/deassert đồng bộ, Little-Endian, coding style không latch, xử lý CDC/RDC, và tiêu chuẩn hóa linting. | [`Digital_Design_Guidelines.md`](../Digital_Design_Guidelines.md) |
| **Tiến độ đồ án** | Mốc công việc, kế hoạch tuần và nhật ký cập nhật theo ngày. | [TIEN_DO_DO_AN.md](TIEN_DO_DO_AN.md) |
| **Hướng dẫn chạy** | Build và kiểm chứng bằng WSL hoặc ModelSim từ Windows CMD; đã cập nhật cấu trúc RTL mới. | [HUONG_DAN_CHAY_WSL_MODELSIM.md](HUONG_DAN_CHAY_WSL_MODELSIM.md) |
| **Bản đồ RTL** | Vị trí module chính, candidate, nghiên cứu và file list build. | [rtl/README.md](../rtl/README.md) |

---

## 2. Tài liệu Tham chiếu Chính (Literature References)

- **[P] Norris & Kim (ISCAS 2021)**: *An Approximate and Iterative Posit Multiplier Architecture for FPGAs* (Bài báo nền tảng cho khối nhân lặp dịch-cộng).
- **[19] Murillo et al. (FPL 2020)**: *Customized Posit Adders and Multipliers using the FloPoCo Core Generator* (Quy chuẩn thuật toán làm tròn RNE 10 bước của FloPoCo / de Dinechin et al.).
- **[23] Jaiswal & So (IEEE Access 2019)**: *PACoGen: A Hardware Posit Arithmetic Core Generator* (Tham chiếu baseline PPA và cơ chế bypass Zero/NaR; lưu ý phân biệt với bài báo DATE 2018 cùng tác giả).
- **[15] Kim & Rutenbar (GLSVLSI 2019)**: *An Iterative SPFP Multiplier Architecture*.
