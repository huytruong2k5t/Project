"""Save the one-run findings in existing docs and a compact proof archive."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

R=Path(__file__).resolve().parents[1]
O=R/'results/single_a35_packer_20261017'
D=json.loads((O/'summary.json').read_text())
assert D['status']=='PASS_REQUESTED_SCOPE'
assert not (O/'evidence.zip').exists()
body='''
### 8.22. Một lượt STA A35T: hai tầng kề product P1 — 17/10/2026

Theo yêu cầu sinh viên, chỉ chạy **một synth_design, một place_design Default, một route_design Default** của toàn NF32/3 FW12 EXACT_EN1 OPS_EN1 trên xc7a35tcpg236-1, Vivado2026.1 build6511674. OOC wrapper chỉ BUFG, clock10ns/uncertainty0,1ns; inputmin=max2,5ns,outputmax0,5ns/min0. Không sửa RTL, không mô phỏng hoặc sweep. Toàn36 SV+header giống byte với OPT-03 đã kiểm; source/driver snapshot và SHA tại results/single_a35_packer_20261017.

| Đoạn vào bank | Setup slack ns | Hold slack ns | Data delay ns | Register đích |
| --- | --- | --- | --- | --- |
| Trước P1: cộng tích lũy → ACC | +3,831 | +0,148 | 6,042 | 54 |
| ACC → normalize/encode/GRS → P1 | +0,301 | +0,137 | 9,527 | 43 |
| Sau P1: RNE/sign → P2, gồm data/flags/valid | +3,467 | +0,182 | 6,391 | 38 |
| P2 → parse/product bank | −0,327 | +0,130 | 10,203 | 44 |

Worst path trước P1: t2_first_reg→acc_reg[53], qua chọn first và cộng term/acc. P1: acc_reg[15]→p1_sticky_bit_q_reg. P2: p1_mag_trunc_q_reg[25]→d_q_reg[18]. Đây là worst setup của mọi launch register tới từng nhóm đích (bao gồm đường điều khiển tới D/CE nếu có), không dùng slack SAC làm thay thế accumulator hoặc chỉ lấy một cặp bit thuận lợi. Danh sách register, top10 setup/top5 hold từng nhóm giữ trong report.

Hai tầng kề P1 đều có slack dương ở chính lượt A35T này; P1 chỉ dư0,301ns. Có cơ sở khảo sát cân bằng logic, ưu tiên phần sticky/inexact sang P2; không cộng/trừ slack giữa tầng như ngân sách cố định vì routing/CE/FF thay đổi. Chuyển về phía ACC cần giữ raw accumulator và quan hệ hồi tiếp từng term, không chuẩn hóa lại trạng thái mỗi vòng. Chưa chốt retiming hoặc thêm stage.

Toàn MAC: WNS R2R−2,887ns,hold+0,056ns,2462LUT/930FF,ước lượng STA77,60MHz; critical c_sf_q[2]→A1.y[0],chưa đạt100MHz. Một run không thay median OPT-03 hoặc Gate4/board signoff. Phần parse sau P2 vẫn thiếu timing.

**Giới hạn runner:** P&R và cả5 nhóm báo cáo yêu cầu đã xuất đầy đủ. Sau đó, truy vấn phụ ngoài phạm vi tới bank A3 của packer tổng dùng sai tên `a3_q` (RTL thực dùng các output register riêng), làm batch exit1. Không chạy lại P&R. Collector chỉ nghiệm thu PASS_REQUESTED_SCOPE, ghi nguyên lỗi phụ trong summary; giữ driver thực thi và log gốc. Script canonical đã bỏ truy vấn phụ để tránh lặp lại lỗi; không tuyên bố toàn batch cũ exit0. Không có lỗi sửa RTL hoặc kiểm chức năng trong phiên này.

Lệnh đã chạy: PowerShell `./scripts/run_single_a35_packer_sta.ps1`; kiểm lại bằng `python scripts/collect_single_a35_packer.py`. Runner từ chối output đã tồn tại, không tự chạy thêm lượt. Dữ liệu gọn trong evidence.zip + archive_manifest.json, stages.csv và summary.json; giữ raw report quan trọng. Nhật ký Git sao lưu gồm nguồn/script/bằng chứng/tài liệu, không binary, checkpoint hoặc cache.
'''
p=R/'l1/PLAN.md';s=p.read_text(encoding='utf-8')
assert '### 8.22.' not in s
p.write_text(s.rstrip()+'\n\n'+body.strip()+'\n',encoding='utf-8')
p=R/'docs/TIEN_DO_DO_AN.md';s=p.read_text(encoding='utf-8')
marker='<!-- OPT03_REPORT_END:docs/TIEN_DO_DO_AN.md -->'
row='| 2 | Đo một lượt toàn NF A35T, kiểm hai tầng kề P1 | ACC/P1/P2 có setup slack +3,831/+0,301/+3,467ns ở100MHz; hold dương. Chỉ một P&R, không sửa RTL/mô phỏng. Toàn MAC còn WNS−2,887ns tại A1; lỗi truy vấn phụ sau đủ báo cáo được ghi rõ trong PLAN8.22 | ✅ |\n'
assert row not in s
s=s.replace(marker,row+marker)
p.write_text(s,encoding='utf-8')
for name in ['scripts/collect_single_a35_packer.py','scripts/single_a35_packer_sta.tcl','scripts/run_single_a35_packer_sta.ps1','scripts/save_single_a35_packer_report.py']:
    dst=O/'analysis_driver'/Path(name).name
    dst.parent.mkdir(exist_ok=True)
    shutil.copyfile(R/name,dst)
(O/'scope_status.txt').write_text('PASS_REQUESTED_SCOPE; auxiliary query failed after required reports; no P&R rerun\n')
skip={'tmp','appdata','localappdata','.Xil'}
suffix={'.sv','.vh','.tcl','.ps1','.py','.json','.csv','.rpt','.log','.txt'}
manifest={}
with zipfile.ZipFile(O/'evidence.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in sorted(O.rglob('*')):
        if not p.is_file() or skip.intersection(p.relative_to(O).parts) or p.suffix not in suffix:continue
        raw=p.read_bytes();name=p.relative_to(O).as_posix()
        manifest[name]=hashlib.sha256(raw).hexdigest();z.writestr(name,raw)
with zipfile.ZipFile(O/'evidence.zip') as z:
    assert z.testzip() is None
    assert all(hashlib.sha256(z.read(k)).hexdigest()==v for k,v in manifest.items())
(O/'archive_manifest.json').write_text(json.dumps(dict(files=manifest,archive_sha256=hashlib.sha256((O/'evidence.zip').read_bytes()).hexdigest()),indent=2)+'\n')
# Only runtime/cache directories of this completed measurement are removed.
removed=0
for p in sorted(O.rglob('*'),key=lambda p:len(p.parts)):
    if not p.exists() or not p.is_dir() or p.name not in skip:continue
    resolved=p.resolve();assert resolved.is_relative_to(O.resolve()) and resolved!=O.resolve()
    assert not any((O/name).resolve().is_relative_to(resolved) for name in manifest)
    removed+=sum(q.stat().st_size for q in p.rglob('*') if q.is_file())
    shutil.rmtree(resolved)
for name,digest in manifest.items():assert hashlib.sha256((O/name).read_bytes()).hexdigest()==digest
(O/'retention.json').write_text(json.dumps(dict(archive_bytes=(O/'evidence.zip').stat().st_size,removed_cache_bytes=removed,preserved_files=len(manifest)),indent=2)+'\n')
print('SINGLE_A35_REPORT_SAVED',len(manifest),(O/'evidence.zip').stat().st_size)
