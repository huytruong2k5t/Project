# Thư mục Tài liệu Kỹ thuật (`docs/`)

Thư mục này chứa toàn bộ tài liệu kiến trúc, đặc tả chi tiết, nhật ký quyết định thiết kế và hướng dẫn quy chuẩn của đồ án:

---

## 1. Danh mục Tài liệu Cốt lõi

| Tên Tài liệu | Mô tả chi tiết nội dung | Vị trí liên kết |
| :--- | :--- | :---: |
| **Đặc tả Lõi IP Posit MAC** | Tài liệu đặc tả kỹ thuật chi tiết nhất (v1.4) bao gồm: cơ sở toán học Posit, yêu cầu chức năng (FR-01..16), phi chức năng (NFR-01..06), vi kiến trúc từng khối (§5.1..12), đối chiếu Fig. 3 của [P], Golden model 3 tầng (§6), chính sách bậc thang PPA (§7.6), và kế hoạch 16 tuần. | [`SPEC_Posit_MAC_IP.md`](../SPEC_Posit_MAC_IP.md) |
| **Nhật ký Điểm mơ hồ & Quyết định** | Tóm tắt hợp đồng profile/n, latency, reset bridge và lịch core; dẫn SPEC §11 cho trạng thái, provenance và rủi ro, tránh sao chép thuật toán packer. | [`ambiguity.md`](ambiguity.md) |
| **Digital Design Guidelines** | Quy chuẩn thiết kế RTL số chuẩn công nghiệp: quy ước đặt tên file/module, clocking, reset leaf tích cực thấp assert bất đồng bộ/deassert đồng bộ, Little-Endian, coding style không latch, xử lý CDC/RDC, và tiêu chuẩn hóa linting. | [`Digital_Design_Guidelines.md`](../Digital_Design_Guidelines.md) |

---

## 2. Tài liệu Tham chiếu Chính (Literature References)

- **[P] Norris & Kim (ISCAS 2021)**: *An Approximate and Iterative Posit Multiplier Architecture for FPGAs* (Bài báo nền tảng cho khối nhân lặp dịch-cộng).
- **[19] Murillo et al. (FPL 2020)**: *Customized Posit Adders and Multipliers using the FloPoCo Core Generator* (Quy chuẩn thuật toán làm tròn RNE 10 bước của FloPoCo / de Dinechin et al.).
- **[23] Jaiswal & So (IEEE Access 2019)**: *PACoGen: A Hardware Posit Arithmetic Core Generator* (Tham chiếu baseline PPA và cơ chế bypass Zero/NaR; lưu ý phân biệt với bài báo DATE 2018 cùng tác giả).
- **[15] Kim & Rutenbar (GLSVLSI 2019)**: *An Iterative SPFP Multiplier Architecture*.
