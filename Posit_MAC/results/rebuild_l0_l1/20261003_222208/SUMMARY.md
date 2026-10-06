# Hồ sơ build L0/L1 — 03/10/2026

**✅ Build cưỡng bức từ nguồn cho Linux/Windows thành công; bộ test hiện có đạt trên cả hai nền tảng, 0 mismatch.**

| Thành phần | Phiên bản |
| --- | --- |
| GCC/G++ Linux | GCC 15.2.0 (Ubuntu 15.2.0-16ubuntu1) |
| MinGW GCC/G++ Windows x64 | GCC 13-win32 |
| GNU Make | 4.4.1 |
| Python Linux / Windows | 3.14.4 / 3.12.14 |
| SoftPosit metadata CITATION.cff | 0.4.2, release 2020-03-13 |
| SoftPosit Git HEAD | 17d5628185b31828b10c1f910c9bf65737e83640 |

SoftPosit có thay đổi cục bộ từ trước trong `source/include/softposit_types.h`, `source/quire32_fdp_add.c`, `source/quire32_fdp_sub.c`. Commit và phiên bản metadata không đủ nhận diện nguồn build; xem [vendor_status.log](vendor_status.log) và [sources.sha256](sources.sha256). Đợt này không sửa mã số học L0/L1 hay SoftPosit.

## Lệnh đã chạy và tái lập

Từ thư mục gốc đồ án trong PowerShell:

```powershell
wsl -e bash '/mnt/c/HCMUT/HK261/Do an 2/Posit_MAC/scripts/rebuild_l0_l1.sh'
```

Script lưu log vào thư mục timestamp mới. Lệnh chính trong WSL, tại thư mục Posit_MAC:

```bash
make -B -C l0 linux windows
make -B -C l1 linux windows
python3 l0/test_softposit_corners.py
cd l1
./test_identity
./test_mul_exact
```

`-B` buộc biên dịch lại. L0 dùng `-O3 -DSOFTPOSIT_FAST_INT64 -DINLINE_LEVEL=5`; L1 dùng `-O3 -std=c++17 -Wall -Wextra`. Toàn bộ include/link flags, phiên bản và đường dẫn công cụ được ghi trong [run.log](run.log).

Sau build, chạy bản Windows mới từ thư mục gốc đồ án:

```powershell
& 'C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' Posit_MAC/l0/test_softposit_corners.py
./Posit_MAC/l1/test_identity.exe
./Posit_MAC/l1/test_mul_exact.exe
```

## Seed và kết quả

| Test | Phạm vi | Seed | Linux / Windows |
| --- | --- | --- | --- |
| L0 corner/RNE | 40 ca cố định | Không random | 40/40 đạt |
| Identity posit8 | 256 bit pattern vét cạn | Không random | 256/256 đạt |
| Identity posit16 | 65.536 bit pattern vét cạn | Không random | 65.536/65.536 đạt |
| Identity posit32 | 1.000.000 mẫu + 12 corner | 1337, mt19937_64 | 1.000.012/1.000.012 đạt |
| Mul posit8 | 65.536 cặp vét cạn | Không random | 65.536/65.536 đạt |
| Mul posit32 corner | 13 ca | Không random | 13/13 đạt |
| Mul posit16 | 1.000.000 cặp random | 2026, mt19937_64 | 1.000.000/1.000.000 đạt |
| Mul posit32 | 1.000.000 cặp random | 314159, mt19937_64 | 1.000.000/1.000.000 đạt |

## Bằng chứng và giới hạn

- [run.log](run.log): compiler/SoftPosit, lệnh, output build và test Linux; SHA-256 nguồn trước/sau build khớp.
- [windows_tests.log](windows_tests.log): phiên bản Python, lệnh và kết quả test trên Windows.
- [sources.sha256](sources.sha256), [binaries.sha256](binaries.sha256): nhận diện nguồn/header/Makefile được ghi nhận và binary mới build.
- Build có warning từ SoftPosit: hằng số lớn trong `p32_to_i64.c`, format printf trong chuyển đổi/quire helper và con trỏ debug `printBinary` không tương thích trong `p32_to_p16.c` trên MinGW. Đây không phải build sạch warning; các hàm ngoài phạm vi bộ test hiện có chưa được nghiệm thu.
- Hai test L1 chưa gọi `round_unpacked`; build/test thành công không xác nhận khối đó đúng.
- “GATE 1 PASSED” trong output chỉ phản ánh bộ test hiện có. Gate 1 theo SPEC vẫn thiếu vét cạn nhân posit16 và ≥ 10^7 mẫu posit32 phân tầng.
