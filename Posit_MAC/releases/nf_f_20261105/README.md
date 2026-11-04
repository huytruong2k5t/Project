# Hai bản nguồn MAC-NF/F đã khóa — 05/11/2026

| Bản | ID | Top | Module |
|---|---|---|---:|
| NF |MAC_NF_POSIT32_ES3_FULLTERM_20261105|posit_mac_nf|29|
| F |MAC_F_POSIT32_ES3_FULLTERM_20261105|posit_mac_f|27|

[nf.lock.json](nf.lock.json) và [f.lock.json](f.lock.json) có SHA-256 riêng cho RTL, header, file list và evidence. Một cây source dùng chung31 module tránh nhân bản dependency. [source.sha256.json](source.sha256.json) khóa toàn bộ gói89 đầu vào, gồm RTL, reference, golden/model, TB, runner và constraints.

Profile: Posit32/ES3, approximate12/FULL_TERM26/Q24, OPS0/1, n0..12, feed-forward A/B/C, RNE. NF là R(R(P_hat)+C); F là R(P_hat+C). Không quire hoặc hồi tiếp Posit32 trong hai top này.

## Kiểm chứng

Mỗi NF/F100000 completed/0 mismatch bằng Verilator + golden độc lập, tất cả26 n×OPS trong mixed corpus; ModelSim9940 completed +60 reset-aborted mỗi lõi; adder39534,packer10851,core53249 case đạt. Unit143934016 kiểm thành phần; strict lint31 module/68 instance.

Trạng thái **SOURCE_LOCKED_REGRESSION_VERIFIED**. Chưa là final acceptance52×10M/coverage/timing sau route. Matching synthesis nếu có được ghi riêng trong manifest; không kế thừa timing chỉ vì tên top giống nhau.

## Audit và replay

Từ gốc Posit_MAC:

```sh
python3 -B scripts/audit_current_locks.py
python3 -B scripts/audit_current_locks.py --frozen-only
```

Lệnh đầu kiểm thêm RTL live; lệnh thứ hai chỉ kiểm gói nguồn và evidence. Nếu live thay đổi, phải kiểm lại và tạo phiên bản mới; không sửa hash của gói này.

ModelSim runner có thể dùng -SourceRoot releases/nf_f_20261105/source và -RunRoot mới. Khi cần build độc lập, sao chép source sang thư mục làm việc riêng, rồi chạy runner với output/tag/label mới. Không ghi build/cache vào cây source đã khóa.

Các bản khóa/snapshot cũ đã gỡ theo yêu cầu; báo cáo/log/vector lịch sử được giữ riêng tại results để đối chiếu.
