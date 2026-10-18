"""Record the unavailable-device trial without manufacturing timing results."""
from pathlib import Path
import hashlib
import json
import zipfile
from audit_rtl_release import validate

R = Path(__file__).resolve().parents[1]
O = R/'results/xcvu9p_trial_20261018'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def edit(path, transform):
    raw = path.read_bytes()
    newline = '\r\n' if b'\r\n' in raw else '\n'
    text = raw.decode('utf-8').replace('\r\n', '\n')
    path.write_bytes(transform(text).replace('\n', newline).encode('utf-8'))


def main():
    lock = json.loads((R/'rtl/production_freeze.json').read_text())
    validate(lock)
    assert 'XCVU9P_PARTS=\n' in (O/'probe/console.log').read_text()
    assert 'Device files unavailable: xcvu9p-flgb2104-2-i' in (O/'nf_p8300_Explore/vivado.log').read_text()
    for top in ('nf', 'f'):
        run = O/(top+'_p8300_Explore')
        manifest = json.loads((run/'manifest.json').read_text())
        for name, digest in manifest['source_sha256'].items():
            assert sha(run/'source'/name) == digest
        for name, digest in lock['rtl_sha256'].items():
            assert sha(run/'source'/name) == digest
        assert not (run/'synthesis.dcp').exists()
        assert not (run/'timing.rpt').exists()
    summary = dict(
        status='BLOCKED_DEVICE_SUPPORT_NOT_INSTALLED', date_local='2026-10-18',
        tool='Vivado 2026.1 build 6511674', part='xcvu9p-flgb2104-2-i',
        release_id=lock['release_id'], release_sha256=sha(R/'rtl/production_freeze.json'),
        paper='An Approximate and Iterative Posit Multiplier Architecture for FPGAs.pdf',
        paper_sha256=sha(R/'An Approximate and Iterative Posit Multiplier Architecture for FPGAs.pdf'),
        paper_page=4, paper_device='xcvu9p; package/speed grade unspecified; Vivado 2020.1',
        part_selection='SPEC example package/speed grade, not confirmed as the paper exact part',
        target_clock_ns=8.3, strategy='Explore', input_min_max_ns=[2.5,2.5],
        output_min_max_ns=[0.0,0.5], uncertainty_setup_hold_ns=[0.1,0.1],
        device_probe='get_parts -quiet xcvu9p* returned empty',
        nf='Attempted; stopped before synthesis: device files unavailable',
        f='Snapshot prepared; implementation not attempted after family availability probe failed',
        setup_wns_ns=None, hold_whs_ns=None, fmax_mhz=None, resources=None,
        license='Not tested: device availability failed first',
        production_unchanged=True, w14_execution='NOT_STARTED',
        required_external_action='Add Virtex UltraScale+ device support to the Vivado installation; license may then need verification',
        rerun_commands=[
            'powershell -NoProfile -File scripts/run_xcvu9p_trial.ps1 -Top nf -Attempt device_ready01',
            'powershell -NoProfile -File scripts/run_xcvu9p_trial.ps1 -Top f -Attempt device_ready01'],
        limits='No PPA measurement or performance conclusion available; no software installation or system/license changes performed')
    path = O/'summary.json'
    assert not path.exists()
    path.write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
    archive = O/'evidence.zip'
    assert not archive.exists()
    files = [p for p in O.rglob('*') if p.is_file()
             and ('source' in p.relative_to(O).parts or p.suffix in ('.log', '.jou') or p.name=='manifest.json')]
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in files:
            z.write(p, p.relative_to(O).as_posix())
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert all(hashlib.sha256(z.read(p.relative_to(O).as_posix())).hexdigest()==sha(p) for p in files)
    (O/'archive_manifest.json').write_text(json.dumps(dict(
        archive_sha256=sha(archive), archive_bytes=archive.stat().st_size,
        files={p.relative_to(O).as_posix():sha(p) for p in files}), indent=2)+'\n', encoding='utf-8')
    note = '''

### 8.32. Khảo sát riêng Virtex UltraScale+ XCVU9P — 18/10/2026

**Trạng thái: chưa chạy được synthesis/P&R vì Vivado chưa cài device support XCVU9P.**
Yêu cầu mới của sinh viên cho phép lượt thử riêng ngoài nền A35T chính. Không đổi release
`POSIT_MAC_RTL_20261018_OPT12_120`, không mở lại khóa, không tính lượt này vào tuần14/Gate4.

Bài báo *An Approximate and Iterative Posit Multiplier Architecture for FPGAs*, trang4,
phần Hardware Implementation Results/TableIII, ghi `xcvu9p` và Vivado2020.1, không ghi
package hoặc speed grade. Chọn `xcvu9p-flgb2104-2-i` theo ví dụ SPEC§7.5/7.6;
không tuyên bố đây là part đầy đủ chính xác của tác giả. Không so575MHz của bộ nhân
bài báo với toàn bộ MAC NF/F của đồ án để kết luận nhanh/chậm hơn.

| Hạng mục | Thiết lập / kết quả thực tế |
| --- | --- |
| Công cụ | Vivado2026.1 build6511674 |
| Nguồn | Snapshot đúng38 module+header của release OPT12_120; audit hash PASS |
| Profile NF | 32/3,FW12,EXACT_EN1,OPS_EN1; wrapper prepack_nf_ppa_top |
| Profile F | 32/3,FW12,W32,EXACT_EN0,OPS_EN1; wrapper week13_fused_ppa_top |
| Clock / strategy dự kiến | 8,3ns≈120,48MHz / Explore; đọc XDC trước synthesis |
| I/O / uncertainty | Input min=max2,5ns; output min0/max0,5ns; setup/hold0,1ns |
| Device probe đã chạy | `get_parts -quiet xcvu9p*` trả rỗng |
| NF đã thử chạy | Dừng trước synthesis: `Device files unavailable: xcvu9p-flgb2104-2-i` |
| F | Snapshot đã chuẩn bị; chưa gọi implementation sau khi probe xác nhận thiếu family |
| Setup / hold / tài nguyên / Fmax | Chưa có số đo; không ước lượng từ A35T hoặc từ tên dòng chip |
| License | Chưa kiểm được; device availability lỗi trước, không kết luận thiếu license |

Runner: `scripts/run_xcvu9p_trial.ps1`; chuẩn bị snapshot bằng
`scripts/prepare_xcvu9p_trial.py`; probe `scripts/probe_xcvu9p.tcl`.
Kết quả/log/source manifest và archive kiểm CRC/SHA ở `results/xcvu9p_trial_20261018`.
Chỉ giữ JSON và evidence.zip khi backup, không đưa cache/binary/wave vào Git.

Cần bổ sung gói device **Virtex UltraScale+** cho bản Vivado đang dùng; đây là thay đổi
cài đặt hệ thống, không thực hiện trong phạm vi phiên này. Khi part hiện ra, chạy từ Posit_MAC:

```powershell
powershell -NoProfile -File scripts/run_xcvu9p_trial.ps1 -Top nf -Attempt device_ready01
powershell -NoProfile -File scripts/run_xcvu9p_trial.ps1 -Top f -Attempt device_ready01
```

Runner giữ log cũ và từ chối ghi đè attempt. Cần kiểm WNS/WHS, R2R, timing I/O,
unconstrained paths và cảnh báo sau khi chạy; COMPLETE chỉ là thực thi xong.
Giữ cùng8,3ns để so trực tiếp với A35T trước khi mở lượt quét clock mới.
Kết quả OOC sau này chỉ dùng khảo sát thiết bị; chưa board signoff, paired NF/F PPA
(NF/F khác EXACT_EN) hoặc bằng chứng tái dựng baseline bài báo. Không chạy thêm mô phỏng:
RTL đúng byte đã kiểm, lượt này chỉ thay target part trong snapshot riêng.
'''
    target = R.parent/'doc/Optimization.md'
    assert '### 8.32.' not in target.read_text(encoding='utf-8')
    edit(target, lambda text:text+note)
    row = '| 9 | Thử XCVU9P ngoài nền A35T | Đã setup NF/F và thử NF; thiếu device support trong Vivado, chưa có timing/PPA. Giữ khóa120MHz; xem Optimization8.32 | processing |\n\n'
    edit(R/'docs/TIEN_DO_DO_AN.md', lambda text:text.replace('### 4.18. Mẫu cập nhật tiếp theo',row+'### 4.18. Mẫu cập nhật tiếp theo',1))
    edit(R/'scripts/README.md', lambda text:text+'\n\nKhảo sát XCVU9P riêng: prepare_xcvu9p_trial.py / run_xcvu9p_trial.ps1, fixed8,3ns Explore; hiện thiếu device support, xem Optimization8.32. Dùng -Attempt mới sau khi có device; không đổi production/A35T lock.\n')
    print('Blocked trial recorded; compact archive verified; production unchanged')


if __name__ == '__main__':
    main()
