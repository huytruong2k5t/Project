## Phạm vi sau khi cố định32/3 — 23/10/2026

Production đã chuyển sang `POSIT_MAC_RTL_20261022_FIXED32_3` với54 module fixed.
Candidate OPT15/16 và các snapshot tham số hóa ở đây được giữ nguyên để bảo toàn
bằng chứng. Chúng cần rebase và kiểm riêng trước khi dùng với file list fixed mới.
Không compile chung candidate cũ với module fixed hoặc gán số đo cũ cho release mới.
Nguồn production trước chuyển đổi lưu tại results/fixed32_3_20261022/reference_source.zip.

---

# Snapshot RTL của gói đã chọn

Cập nhật 20/10/2026. Có 9 file `.sv` dùng đối chiếu nguồn của
gói production `POSIT_MAC_RTL_20261018_OPT12_120` và ứng viên OPT-15 riêng bên dưới.

| Thư mục | File `.sv` | Vai trò |
| --- | ---: | --- |
| `adder/opt02c/` | 1 | Snapshot A1 align đã chọn |
| `multiplier/opt05/abc_tree/` | 2 | Snapshot SAC/control đã chọn |
| `mac_nf/opt09/` | 3 | Snapshot product pack/parser/wrapper NF |
| `packer/opt10a/` | 1 | Snapshot chuẩn bị pack |
| `parser/opt12/` | 2 | Snapshot parser của lượt 120 MHz |

`mac_nf/opt15/` là thí nghiệm mới giảm LUT: hai wrapper ứng viên (`parser2`,
`combined`) và helper `posit_nf_shared_pack.sv`. Các file này chưa được promote,
không nằm trong `rtl/production.f`; xem Optimization §8.35 và
`results/opt15_share_20261019/`. Hai parser được tính ở đây là parser đầu vào;
`posit_magnitude_parse` của tích vẫn giữ riêng trong NF.

**Nền phát triển đã chọn:** dùng NF `mac_nf/opt15/combined/` và helper chung của
study làm điểm xuất phát cho các tối ưu sau. F đã có lane parser A/C–B và
packer cuối duy nhất tại `mac_f/opt15/parser2/`;`mac_f/opt16/shared_nf_add/` thay
F1–F5 bằng bộ cộng NF ba tầng và adapter không làm tròn tích. Cả hai đã kiểm/đo
theo Optimization8.36,chưa promote. Từng thư mục có `production.f` riêng;
`opt15_sources.json` cung cấp đường dẫn đầy đủ và trạng thái.
Mỗi bước tiếp tạo revision mới để giữ nguyên snapshot/hash đã nghiệm thu trong study cũ.

Mã chạy chính nằm trong các thư mục chức năng của `rtl/`, được chọn bằng
[`../production.f`](../production.f). Không thêm các snapshot này vào cùng file list
với production vì có thể trùng tên module.

23 file thuộc các phương án cũ đã được gom vào
[`../../archive/rtl_candidates_pre120_20261019.zip`](../../archive/rtl_candidates_pre120_20261019.zip).
Danh mục SHA256 và cách phục hồi đường dẫn cũ ở
[`../../archive/README.md`](../../archive/README.md).
Phải phục hồi trước khi chạy các runner lịch sử cần những ứng viên đó.
Không thay đổi nội dung các file RTL trong phiên dọn này.
