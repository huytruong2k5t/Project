# Constraint và luồng đo A35T

## Release production đã khóa — 18/10/2026

`POSIT_MAC_RTL_20261018_OPT02C` (`LOCKED_FOR_W14`),38 module trong `rtl/production.f`.
Gói hiện hành: OPT-02c + OPT-05 abc_tree + OPT-09 + OPT-10A; không đổi hợp đồng số học/latency.
NF thực hiện R(R(P_hat)+C_eff); F thực hiện R(P_hat+C_eff), với phạm vi/profile ở SPECv1.20.
Trước khi build/chạy W14, từ gốc Posit_MAC:

```powershell
python scripts/audit_rtl_release.py --self-test
```

37 profile strict lint và smoke ModelSim NF/F từ production đã đạt; NF acceptance10M/0 mismatch.
F10M được kế thừa theo hash nguồn của8.28 và có smoke mới; chưa chạy final per-n W14/Gate4.
Xem SPEC§11.17, `rtl/production_freeze.json` và Optimization§8.30.
Các câu “chưa promote” ở hồ sơ có ngày trước18/10 là trạng thái lịch sử.
Producer/audit kiểm hash checkpoint cũ phải dùng snapshot cũ, không sửa hash lịch sử để nhận PASS.


**Hiện hành: A35T-C2, cập nhật theo yêu cầu17/10/2026.** Mọi benchmark ở10,000ns (100MHz) giữ nguyên bộ constraint cũ. Chỉ dùng xc7a35tcpg236-1. C1 clock-only là kiểm tra đã lưu, không còn là mặc định cho mốc100MHz.

## 1. File constraint hiện hành

| File | Nội dung |
| --- | --- |
| constraints/a35t_clock.xdc | Clock10ns, uncertainty setup0,100ns và hold0,100ns |
| constraints/a35t_benchmark_100mhz.xdc | Input min=max2,500ns; output min0/max0,500ns cho benchmark100MHz |
| run_a35t.tcl | Đọc cả hai XDC trước synthesis; chỉ profile benchmark_100mhz |
| ../scripts/run_a35t_sta.ps1 | Runner NF/F, mặc định validate; snapshot nguồn/XDC/hash trong output mới |

Đây là budget giao tiếp giả định dùng thống nhất để so sánh benchmark, không phải số đo board. Không thay min/max riêng cho candidate hoặc giữa NF/F để làm slack đẹp hơn. Không đổi uncertainty, không thêm false-path/multicycle. Các script/results cũ giữ nguyên để tái lập checkpoint; không sửa hash lịch sử.

## 2. Mốc100MHz và quét Fmax

Ở10ns, luôn giữ bộ giá trị trên. Phân biệt setup/hold của đường I/O với Internal R2R (register-to-register, D/CE). Unconstrained endpoint nội bộ hoặc no_clock vẫn phải giải quyết. Wrappers hiện chỉ BUFG, không thêm I/O FF hoặc thay14 tầng NF/13 tầng F.

**Ngoại lệ đã được nêu:** khi quét chu kỳ cao hơn, ví dụ8ns/125MHz, có thể đọc riêng Internal R2R để đánh giá giới hạn nội bộ. Ưu tiên giữ I/O budget và báo I/O riêng. Nếu chọn giảm input delay theo tỷ lệ chu kỳ thì phải khóa thành profile sweep mới, áp giống baseline/candidate và báo rõ đây là đổi giả định giao tiếp, không phải tối ưu RTL.

Slack I/O âm dưới budget2,5ns không tự là âm giả: thiết kế chưa đạt điều kiện giao tiếp đó tại clock mới. Chỉ có thể nói đường I/O không quyết định kết luận R2R nếu phép đo đã giới hạn phạm vi. Không gọi R2R đạt125MHz là toàn giao tiếp/board đạt125MHz.

Sinh viên nói có hai ngoại lệ nhưng hiện mới mô tả ngoại lệ quét tần số; ngoại lệ thứ hai chưa được xác định, không tự bổ sung. Chưa chạy sweep hoặc tự giảm I/O. Runner hiện hành cố định100MHz; chỉ mở thêm chế độ quét khi có yêu cầu triển khai riêng.

## 3. Cách chạy từ gốc Posit_MAC

```powershell
./scripts/run_a35t_sta.ps1 -Variant nf -Action validate -RunRoot results/a35t_c2_new_validate_nf
./scripts/run_a35t_sta.ps1 -Variant f -Action validate -RunRoot results/a35t_c2_new_validate_f
```

validate chỉ đọc/elaborate RTL và XDC. Khi được yêu cầu synthesis hoặc đo post-route mới chọn Action synth hoặc implement, RunRoot mới; runner từ chối ghi đè. COMPLETE chỉ là chạy xong, không có nghĩa timing PASS.

Variant nf là production32/3 FW12 EXACT_EN1; F là32/3 FW12 W32 EXACT_EN0. Production18/10 đã ghép OPT-02c/05/09/10A; NF EXACT_EN1 vẫn không phải comparator approximate-only đã nghiệm thu. Cần nguồn/manifest và kiểm riêng trước kết luận paired PPA. Manifest/scope ghi hợp đồng C2; effective_constraints.xdc là bản xuất từng run, không phải file chỉnh chung.

## 4. Hồ sơ C1 và mẫu tích hợp

C1 đã kiểm nạp clock-only NF/F và mẫu tích hợp giả lập, chưa đo Fmax: results/a35t_c1_constraints_20261017/summary.json và evidence.zip. Nguồn C1 được giữ trong archive/Git; không dùng kết quả đó làm nghiệm thu C2. Các lượt thử lỗi nằm ở intermediate_not_acceptance.

constraints/a35t_io_template.xdc được giữ như tài liệu mẫu cần timing thật, không dùng mặc định cho benchmark100MHz và không tự coi là ngoại lệ thứ hai. Runner C2 không kích hoạt mẫu này. Pinout/IOSTANDARD/clock topology và timing nguồn/đích cần review khi thực sự tích hợp board.

XDC được đọc trước synthesis trong luồng mới; đây khác thứ tự nạp ở các producer cũ. Dù budget100MHz giữ nguyên, vẫn cần matched baseline/candidate mới trước kết luận PPA do synthesis/P&R có thể đổi. Chưa chạy lại synthesis/P&R hoặc xác nhận Fmax mới trong lần cập nhật chính sách C2.

Chi tiết: [Optimization](../../doc/Optimization.md), [PLAN](../l1/PLAN.md), [tiến độ](../docs/TIEN_DO_DO_AN.md).
