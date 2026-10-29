## Cây MAC sau lưu trữ — 29/10/2026

> **Phân biệt nguồn trước khi replay:** đối chiếu Git ngày29/10 phát hiện51/54 file RTL
> và manifest tại máy đã khác commit `c4fe1f7` trước phiên đóng gói;ví dụ F đổi N_MAX8→12.
> Hash manifest hiện tại không trùng hash trong summary release cũ.Vì vậy số10M/0 mismatch
> lịch sử chỉ áp dụng checkpoint Git gốc,không tự áp dụng nguồn hiện tại.
> `manage_rtl_support_archive.py restore` phục hồi các file của **snapshot hiện tại**,không rollback
> mã của bạn về bản gốc.Bản gốc được giữ riêng trong `archive/rtl_release_git_c4fe1f7_20261029.zip`;
> muốn replay đúng bản đã nghiệm thu,cần giải nén checkpoint đó vào thư mục mới và cung cấp
> đúng runtime/dependency theo hướng dẫn lịch sử.Audit hash không thay mô phỏng chức năng.

Gói mới: [`rtl_support_20261029.zip`](rtl_support_20261029.zip),994.621 byte.
Biên bản: [`rtl_support_20261029.json`](rtl_support_20261029.json).
SHA256 ZIP:`72bd88e6de2cd4d7ccd30ff708fdb485517079f5d4a348a10cb69083a38e035f`.

Đã chuyển54 đường dẫn ra khỏi cây nguồn đang làm việc:

| Nhóm | Số file | Xử lý |
| --- | ---: | --- |
| Standalone/reference trong release | 8 | Nén rồi gỡ bản rời khỏi rtl |
| Candidate/research/benchmark | 30 SV +4 phụ trợ | Nén rồi gỡ các thư mục tương ứng khỏi rtl |
| Testbench/checker lịch sử | 12 | Nén rồi gỡ bản rời khỏi tb |

8 module gồm `posit_mul_iter`,`mul_iter_wrapper`,`mul_norm_comb`,`posit_add_comb`,
`round_unpacked_comb`,`posit_pack_comb`,`posit_parser_comb`,`dyn_left_shifter_fixed4`.
Không gọi chúng là lỗi hoặc chưa từng kiểm:7 module đã ở ngoài cây MAC của release18/10;
fixed4 vẫn có kiểm riêng trong testbench unit dùng chung.

ZIP có510 entry dữ liệu cùng `ARCHIVE_INDEX.json`:snapshot toàn RTL/TB/scripts,
model/reference header và các đầu vào/report đã khóa cần cho audit.
Bản sao46 module MAC và testbench dùng chung có trong ZIP để khôi phục checkpoint;
bản rời của chúng vẫn giữ nguyên.Snapshot không kèm toàn bộ runtime,SoftPosit binary,
corpus lớn hoặc tất cả dữ liệu của mọi thí nghiệm lịch sử;replay vẫn cần đúng dependency.
Các report,dataset,wave/binary bên ngoài phạm vi đóng gói không bị xóa trong lần này.

**Hai danh sách nguồn:**

- `rtl/mac_active.f`:46 module hiện hữu cho hai top MAC;dùng lint/synthesis MAC.
- `rtl/production.f`:54 module của release `POSIT_MAC_RTL_20261022_FIXED32_3`,giữ nguyên byte;
  phải restore trước các runner/Makefile/audit release cũ.

Từ gốc Posit_MAC:

```bash
python3 -B scripts/manage_rtl_support_archive.py audit
python3 -B scripts/manage_rtl_support_archive.py self-test
# Khi cần standalone hoặc replay đầy đủ release54:
python3 -B scripts/manage_rtl_support_archive.py restore
python3 -B scripts/audit_rtl_release.py --self-test
```

Windows CMD dùng `python` thay `python3`. `restore` chỉ khôi phục54 đường dẫn đã gỡ,
kiểm SHA256 và từ chối ghi đè file khác nội dung.Nó không ghi đè46 module MAC hiện hành,
manifest,file list hoặc testbench dùng chung.Không giải nén toàn ZIP đè lên cây đang sửa.
`self-test` giải nén snapshot vào scratch của dự án,chạy audit release54 gốc rồi gỡ
đúng dữ liệu tạm đã kiểm;không phục hồi file vào cây RTL đang làm việc.
Không chạy lại `pack` để ghi đè ZIP;đây là gói một lần có dấu vết hash riêng.

Kiểm chứng29/10:ZIP CRC/SHA từng entry đạt,108 hash đầu vào đã khóa và hash các report
đạt,thử khôi phục510 file và audit manifest hiện tại54 module/anti-tamper4/4 đạt.
Checkpoint Git gốc có gói riêng186.301 byte,khớp hash manifest trong summary cũ và
cũng thử giải nén/audit54 module đạt.Lint NF/F với46 module
đạt trên Verilator5.032.Không chạy lại mô phỏng chính,STA hoặc PPA;không claim FULL_TERM.
Các mục19/10 bên dưới giữ nguyên ý nghĩa lịch sử.

---

# Kho ứng viên RTL đã ngừng dùng

Cập nhật: 19/10/2026. Chỉ sắp xếp thư mục và dọn sản phẩm sinh tự động; không phân tích hoặc sửa nội dung mã nguồn. Không chạy regression, synthesis, STA hoặc Git push.

## 1. Phân loại

| Nhóm | Vị trí |
| --- | --- |
| RTL production 120 MHz đã khóa | `../rtl/`, build bằng `../rtl/production.f` |
| Snapshot gói đã chọn | `../rtl/candidates/adder/opt02c/`, `multiplier/opt05/abc_tree/`, `mac_nf/opt09/`, `packer/opt10a/`, `parser/opt12/` |
| 23 file ứng viên cũ đã bỏ khỏi cây làm việc | `rtl_candidates_pre120_20261019.zip` |
| Bằng chứng đo và kiểm của các ứng viên cũ | Giữ nguyên đường dẫn trong `../results/` |

Các bản cũ gồm align ban đầu/OPT-02b, normalization shared/zero, prepack OPT-01, SAC a/ab/abc_sub và các phương án primitive thử nghiệm. Đây là các phương án đã được thay thế hoặc không chọn trong gói production; không khẳng định từng module riêng lẻ đều đã đo dưới 120 MHz. Không loại bằng chứng theo một ngưỡng tần số vì điều kiện đo lịch sử khác nhau.

## 2. Phục hồi thí nghiệm cũ

Archive giữ nguyên đường dẫn tương đối tính từ gốc Posit_MAC. Chỉ phục hồi khi cần replay các script cũ tham chiếu những file đã lưu trữ. Các runner lịch sử không được sửa trong lần dọn này.

```powershell
cd "C:\HCMUT\HK261\Do an 2\Posit_MAC"
Expand-Archive -LiteralPath ".\archive\rtl_candidates_pre120_20261019.zip" -DestinationPath "."
```

Không dùng `-Force`: nếu đã có file cùng tên, kiểm tra trước khi phục hồi. Không compile glob toàn bộ RTL sau khi giải nén; các ứng viên có thể trùng tên module.

## 3. Kiểm toàn vẹn kho nén

SHA256: `6d9aa34941966c2aa0d46a723773c6c4de760e1438b8bd8fb04033783075d5ba`.

Đã đối chiếu SHA256 từng entry với file gốc trước khi gỡ bản rời. Không thay đổi byte bên trong file.

| Đường dẫn gốc | Byte | SHA256 |
| --- | ---: | --- |
| `rtl/candidates/adder/posit_add_align_candidate.sv` | 4866 | `3d37b0d68d8000ceca77bff3e25c101e4ec4c0a40ad64bdbf79b9e491180fa20` |
| `rtl/candidates/adder/posit_add_normalize_shared.sv` | 4028 | `281d5508ea9a5fc1ecd65896bd46772d2d8d0c0872d63cce86001a9905df9963` |
| `rtl/candidates/adder/posit_add_normalize_zero.sv` | 3641 | `481d33566d04f2aae2a41b755a6b51947e397b6a60369139ef0993065b896c85` |
| `rtl/candidates/adder/opt02b/posit_add_align.sv` | 7046 | `91c6338729a985e227da481bfc889b7679bc7a613ae526b1eee3d265feeb6a3f` |
| `rtl/candidates/multiplier/mul_prepack_norm_comb.sv` | 4476 | `d2c5c4e5774af7a34f1c061630fb8e244090269b4f1b393b4ac34e7cb443c799` |
| `rtl/candidates/multiplier/opt05/a/sac_step_comb.sv` | 3909 | `cb50c74d2caaef234e12902b32e16b46300ad42868bff53b0a4fd51475c845a7` |
| `rtl/candidates/multiplier/opt05/ab/sac_step_comb.sv` | 3976 | `47896da257b1e26e8a98b4d4c551fd6a2ab3cd50d6181ed43e0cec8a640ecf48` |
| `rtl/candidates/multiplier/opt05/abc_sub/iter_ctrl.sv` | 4964 | `e299bca9f011e8b4a11021bf5398d9aca45b3a57a490e8ec09074ea9901bf23c` |
| `rtl/candidates/multiplier/opt05/abc_sub/sac_step_comb.sv` | 4163 | `3244c931037ee97efdcc882c7e22e7469e2002a3e5026c7039dfe1ccd4ac7828` |
| `rtl/candidates/primitives/dyn_left_shifter.sv` | 1919 | `a71fe2ca98286154c48979a04b877ecbafec7c2c4d0a5966c720439d2b526c37` |
| `rtl/candidates/primitives/dyn_right_shifter.sv` | 1913 | `1026a7d03a8316438ecdb5fdf6019a8cfec1d6c4700fee8c35732744fe8852f8` |
| `rtl/candidates/primitives/lod_lzd_core.sv` | 2568 | `abeabd6cec021a48b00648438996b97f86ed508dd127940cf3ff45cfca8a6596` |
| `rtl/candidates/primitives_v2/group4/lod_lzd_core.sv` | 2698 | `d457a7d4d9fdf354d762e3f16ba111113295dd03c2ae490c579e462df31c458b` |
| `rtl/candidates/primitives_v2/group4_mixed/lod_lzd_core.sv` | 3084 | `21c1837e3885192943f57be926648012f155c9d445ce4f1e64718c3b8ae4d4eb` |
| `rtl/candidates/primitives_v2/native/dyn_left_shifter.sv` | 851 | `dd231f90ad36c7d339963d6527f14908ae33b83f42ec92fd6b89fd2f0a1c94c8` |
| `rtl/candidates/primitives_v2/native/dyn_right_shifter.sv` | 1292 | `34988da234f4e750c4b272389f357b485befbf936b5a2f9eaf27057b6d00dcc3` |
| `rtl/candidates/primitives_v2/radix4/dyn_left_shifter.sv` | 3133 | `257a6a82f7e6a6c01da55c2a96563626d631f5f93514f7ccbb4ace35e97507c7` |
| `rtl/candidates/primitives_v2/radix4/dyn_right_shifter.sv` | 3251 | `9afca4a865ae7a9535f08c44bc3a9472df2a6f5a7a3484b57be6131a6d84b8f3` |
| `rtl/candidates/primitives_v2/reverse/dyn_left_shifter.sv` | 1713 | `ab52c56bf23275258fd832e8786f0245c7f13ea815f4f36e1ac4a8d25dc38669` |
| `rtl/candidates/primitives_v2/reverse/dyn_right_shifter.sv` | 1835 | `12b116c18fcd78985208f3f9f409b56b25568b3965707d0b1075d0da87810c7e` |
| `rtl/candidates/primitives_v2/selected/dyn_left_shifter.sv` | 3968 | `f3c8c98671bb06fa2d68ba5a522c848e7178e1c9691f4f05effd8f1734ac3129` |
| `rtl/candidates/primitives_v2/selected/dyn_right_shifter.sv` | 4261 | `89514601248f33eef173b113cbed062d2a777ec6f84d1f3b0fc66eacd946ef86` |
| `rtl/candidates/primitives_v2/selected/lod_lzd_core.sv` | 6372 | `13bea3038ece40ca3d77f5fbb2e4e45d082590fddad1fee40746af94b06bd62d` |

## 4. Cache được dọn

Tổng cộng 920 file, 1,204.85 MiB. Chỉ các nhóm sau:

- File `.gch`, `.o`, `.a`, `.d` trong các thư mục `results/week14/**/obj/`.
- Cache Python `results/week14/tmp/` và `scripts/__pycache__/`.
- Thư viện biên dịch ModelSim `results/week14/event_protocol/work/`.

Giữ nguồn snapshot, generated C++/header/makefile, raw coverage `.dat`, log, counter, fixture, hash, các ZIP bằng chứng và báo cáo timing. Binary mô phỏng còn lại không được coi là đã kiểm lại; trước lần replay tiếp theo cần build theo README/runner tương ứng. Không giải phóng bằng cách xóa corpus hoặc báo cáo thất bại.

## 5. Xác minh sau dọn

Kiểm metadata 32923 file được giữ nguyên: PASS (độ dài và thời điểm sửa). Kiểm SHA256 66 file RTL/header/file list/freeze còn lại: PASS. Đây là kiểm toàn vẹn file, không phải một lần chạy mô phỏng/STA mới.

Thư mục rỗng cũng đã gỡ: `-p`, `results/nf_all_stages_20261017/.Xil`, `results/nf_all_stages_20261017/tmp`.


## Chốt approximate-only — 30/10/2026

`spec_before_approx_only_20261030.zip` giữ nguyên SPEC trước quyết định v1.24.
Danh mục file exact-only/mixed/shared nằm ở SPEC §4.4.Chỉ chỉnh tài liệu,chưa gỡ file
hoặc sửa RTL/L1/TB/runner;577 file nguồn được đối chiếu hash không đổi.
Biên bản tính toàn vẹn:`approx_only_doc_guard_20261030.json`;không phải kết quả simulation.
