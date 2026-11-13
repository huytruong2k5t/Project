# Reference cho verification bộ cộng

Bảy file trong `rtl/` bên dưới được chuyển nguyên byte từ cây RTL cũ ngày02/11/2026. Chúng chỉ phục vụ `tb_posit_add_5stage_equiv`: bộ cộng tổ hợp tham chiếu và các helper của nó; không được instantiate bởi hai top MAC hiện hành.

- DUT5 tầng ở `../../rtl/adder/`, compile bằng `../../rtl/mac_active.f`.
- Danh sách tham chiếu: `tb/reference/rtl/files.f`; các đường dẫn bên trong tính từ gốc Posit_MAC.
- `scripts/run_refactored_mac.ps1` tự snapshot/compile reference tại đường dẫn mới; vẫn đọc được source snapshot lịch sử có đường dẫn cũ.

Không dùng bộ cộng reference làm DUT production. SHA/mapping trước và sau chuyển nằm tại `../../archive/cleanup_20261102/reference_migration.json`. Các thư viện compiled có thể build lại từ nguồn; bằng chứng F2F/snapshot lịch sử không bị sửa để đổi đường dẫn.
