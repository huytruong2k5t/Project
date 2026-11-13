# Posit MAC — NF và F

Hai phiên bản nguồn hiện tại đã khóa ngày05/11/2026:

| Lõi | ID | RTL | Manifest |
|---|---|---:|---|
| NF | MAC_NF_POSIT32_ES3_FULLTERM_20261105 |29 module|[nf.lock.json](releases/nf_f_20261105/nf.lock.json)|
| F | MAC_F_POSIT32_ES3_FULLTERM_20261105 |27 module|[f.lock.json](releases/nf_f_20261105/f.lock.json)|

Cấu hình Posit(32,3), fraction đầu vào12 bit, FULL_TERM26/Q24, OPS0/1, n0..12, RNE. Hai lõi nhận trực tiếp A/B/C; NF làm tròn tích trước cộng, F giữ tích tới phép cộng cuối. Tích lũy Posit32 do driver/thanh ghi ngoài quản lý sau retire.

## Phạm vi khóa

Nguồn đã qua strict lint31 module/68 instance, unit143934016 kiểm tra thành phần và mỗi NF/F100000 completed/0 mismatch với golden độc lập. ModelSim mỗi bản9940 completed +60 reset-aborted; kiểm reset/stall/chuỗi ngoài, adder, packer và core đều đạt.

Đây là **khóa phiên bản nguồn đã regression**, chưa là nghiệm thu52×10M, coverage mới hoặc timing sau route. Không kế thừa PASS/PPA của một nguồn khác. [Gói nguồn và cách dùng](releases/nf_f_20261105/README.md).

```sh
python3 -B scripts/audit_current_locks.py
```

Audit kiểm hash snapshot, nguồn RTL đang làm việc và bằng chứng verification. Khi sửa RTL, cần kiểm lại và tạo phiên bản mới; không sửa manifest để làm audit qua.

## Tài liệu và kiểm chứng

Bộ testbench coverage NF/F mới: [kế hoạch và lệnh chạy](tests/nf_f_coverage.md).
Kết quả [coverage](results/nf_f_coverage_20261105_r2/README.md) ghi riêng raw,
reviewed, các điểm loại và pilot; không thay điều kiện nghiệm thu52x10M.

- [SPEC](docs/SPEC_Posit_MAC_IP.md), [golden32/es3](docs/GOLDEN_MODEL_POSIT32_ES3.md), [hướng dẫn WSL/ModelSim](docs/HUONG_DAN_CHAY_WSL_MODELSIM.md).
- [RTL](rtl/README.md), [runner](scripts/README.md), [constraints/synthesis](syn/README.md).
- [Kết quả được giữ](results/README.md), [Optimization](../doc/Optimization.md).
- [Nguồn đã khóa](releases/current.json), [verification05/11](results/nf_f_lock_20261105/).

Bài báo PDF giữ trên máy, không đưa vào GitHub. Slide đã được đưa ra ngoài Posit_MAC; thư mục presentation không còn nằm trong dự án.

## Nguồn lịch sử và quire

Theo yêu cầu05/11, các snapshot RTL, gói source và manifest khóa cũ đã được gỡ; báo cáo/log/vector được giữ để đối chiếu. Các số đo trong báo cáo cũ chỉ mô tả nguồn tại ngày đo, không là nghiệm thu hai bản khóa mới và không còn đầy đủ source để replay.

MAC-quire vẫn là top riêng trong rtl/mac_quire, file list rtl/quire_active.f19 module. Backend tối ưu đã kiểm1.1M MAC/0 mismatch; synthesis2888 LUT/2636FF, F2F9.579ns, setup+0.170ns,hold−0.055ns. Chưa route/signoff và không nằm trong hai bản khóa NF/F lần này. [Báo cáo](results/quire_opt_20261104/summary.md).
