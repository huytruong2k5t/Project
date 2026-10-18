"""Synchronize the current release notice; keep historical trial evidence intact."""
from pathlib import Path
import json

R = Path(__file__).resolve().parents[1]


def edit(path, transform):
    raw = path.read_bytes()
    newline = '\r\n' if b'\r\n' in raw else '\n'
    text = raw.decode('utf-8').replace('\r\n', '\n')
    path.write_bytes(transform(text).replace('\n', newline).encode('utf-8'))


banner = '''**Production hiện hành18/10:** đã chọn và promote OPT-12 negate, khóa release
`POSIT_MAC_RTL_20261018_OPT12_120` (`LOCKED_FOR_W14`),38 module trong `rtl/production.f`.
A35T `xc7a35tcpg236-1`, Explore,8,3ns≈120,48MHz: NF WNS/WHS +0,227/+0,053ns;
F +0,093/+0,040ns. Input min=max2,5ns, output min0/max0,5ns, uncertainty0,1ns giữ nguyên.
Gói OPT-02c/05/09/10A + OPT-12; không đổi I/O, precision, latency hoặc L1/oracle.

Trước build W14: `python scripts/audit_rtl_release.py --self-test`.
Recipe120MHz: `syn/opt12_120mhz_release.json`, clock `syn/constraints/a35t_clock_120mhz.xdc`;
XDC100MHz vẫn giữ cho replay lịch sử, không phải clock nghiệm thu120MHz.
870 profile lint parser, equivalence/decoder,10M NF+10M F đều0 mismatch; ModelSim NF/F đạt.
Hai file production là đúng byte đã kiểm, không chạy lại regression lớn khi promote.
Đây là OOC theo profile công bố, chưa board signoff, final per-n/AC04 W14 hoặc paired NF/F PPA.
Old lock OPT02C giữ trong `results/opt120_20261018/reference_freeze.json` và `reference_source.zip`.
Chi tiết Optimization8.31.8; trial8.31.7 và các trạng thái chưa promote trước đó là lịch sử.
Producer lịch sử không dùng để refreeze/ghi đè release mới; W14 chưa thực thi.

'''


def main():
    manifest = json.loads((R/'rtl/production_freeze.json').read_text())
    assert manifest['release_id'] == 'POSIT_MAC_RTL_20261018_OPT12_120'
    for name in ('README.md', 'rtl/README.md', 'scripts/README.md', 'syn/README.md',
                 'docs/HUONG_DAN_CHAY_WSL_MODELSIM.md'):
        def replace_banner(text):
            start = text.index('**Workflow cập nhật18/10:**')
            marker = 'Producer/audit kiểm hash checkpoint cũ phải dùng snapshot cũ, không sửa hash lịch sử để nhận PASS.'
            end = text.index(marker, start)+len(marker)
            return text[:start]+banner+text[end:]
        edit(R/name, replace_banner)
    def plan(text):
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if line.startswith('RTL production đã khóa tại'):
                lines[i] = ('RTL production đã khóa tại `rtl/production_freeze.json` '
                            '(release `POSIT_MAC_RTL_20261018_OPT12_120`). Chạy '
                            '`python scripts/audit_rtl_release.py --self-test` trước tuần14. '
                            'Manifest38 module giữ nguyên; L1/oracle không đổi. Optimization8.31.8 lưu khóa mới.')
            if line.startswith('Workflow18/10:'):
                lines[i] = ('Workflow18/10: đã promote OPT-12 negate theo lựa chọn của sinh viên; '
                            'A35T Explore8,3ns≈120,48MHz NF/F setup/hold đạt. '
                            'Recipe syn/opt12_120mhz_release.json khóa I/O2,5ns input,0/0,5ns output. '
                            '10M NF+10M F/0 mismatch và ModelSim là bằng chứng refactor; '
                            'W14 final per-n/AC04 chưa chạy. OPT02C100MHz giữ lịch sử riêng.')
        return '\n'.join(lines)+'\n'
    edit(R/'l1/PLAN.md', plan)
    def spec(text):
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if line.startswith('**Workflow sau thử candidate18/10:**'):
                lines[i] = ('**Workflow khóa120MHz18/10:** theo lựa chọn sinh viên, đã promote đúng byte '
                            'OPT-12 negate vào production và khóa `POSIT_MAC_RTL_20261018_OPT12_120`. '
                            'A35T/Explore8,3ns≈120,48MHz, NF WNS/WHS+0,227/+0,053ns, '
                            'F+0,093/+0,040ns; giữ I/O và uncertainty. '
                            'Recipe `syn/opt12_120mhz_release.json`, clock120MHz riêng; '
                            'XDC100MHz và lock OPT02C lưu làm lịch sử. '
                            '10M NF+10M F/0 mismatch, ModelSim và hash nguồn tại Optimization8.31.8. '
                            'Hợp đồng số học/I/O/precision/latency không đổi. '
                            'W14 final per-n/AC04, paired accuracy/PPA và board signoff chưa hoàn thành.')
        return '\n'.join(lines)+'\n'
    edit(R/'SPEC_Posit_MAC_IP.md', spec)
    def progress(text):
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if line.startswith('**Trạng thái tối ưu:**'):
                lines[i] = ('**Trạng thái tối ưu:** đã promote và khóa OPT-12 negate, release '
                            '`POSIT_MAC_RTL_20261018_OPT12_120`, A35T Explore120,48MHz NF/F setup/hold đạt; '
                            'OPT02C100MHz giữ lịch sử. Fraction12/W32, L1/oracle/latency và I/O budget giữ nguyên. '
                            'Xem Optimization8.31.8. Tiếp theo W14-01→W14-12 theo kế hoạch; chưa chạy W14. '
                            'Hạn chính29/11, đệm30/11–04/12, hoàn thành trước05/12/2026.')
            if line.startswith('- **Hiện tại18/10:**'):
                lines[i] = ('- **Hiện tại18/10:** release OPT12_120 đã khóa và audit PASS; '
                            'có thể bắt đầu W14-01. Chưa triển khai/chạy TC W14, chưa có matrix_freeze '
                            'hoặc final report; không dùng10M refactor thay final per-n/AC04.')
            if line.startswith('Đợt promote100MHz đã hoàn tất;'):
                lines[i] = ('Đợt100MHz đã lưu lịch sử; study `results/opt120_20261018` đã thử, '
                            'được sinh viên chọn và promote thành release OPT12_120 riêng. '
                            'L1/oracle, constraints100MHz và qualification trial giữ nguyên; '
                            'promotion.json/reference_freeze.json lưu chuyển tiếp. Chưa chạy W14.')
            if line.startswith('### 3.3.3. Candidate trên120MHz'):
                lines[i] = '### 3.3.3. Khóa production120MHz — 18/10'
            if line.startswith('| Chọn/promote/khóa lại |'):
                lines[i] = ('| Chọn/promote/khóa lại | Đã chọn negate/Explore8,3ns và promote đúng byte; '
                            'khóa OPT12_120, audit PASS, giữ lock100MHz lịch sử. '
                            'W14 chưa chạy; OPT-13/14 không triển khai | ✅ |')
        text = '\n'.join(lines)+'\n'
        row = '| 8 | Khóa RTL120MHz trước W14 | Promote đúng hai parser OPT-12 negate; Explore8,3ns NF/F setup/hold đạt; audit và backup. Không chạy lại regression lớn hoặc W14 | ✅ |\n\n'
        marker = '### 4.18. Mẫu cập nhật tiếp theo'
        assert marker in text
        return text.replace(marker, row+marker, 1)
    edit(R/'docs/TIEN_DO_DO_AN.md', progress)
    addition = '''

#### 8.31.8. Promote và khóa RTL120MHz theo lựa chọn sinh viên — 18/10/2026

**Đã khóa `POSIT_MAC_RTL_20261018_OPT12_120` (`LOCKED_FOR_W14`).** Sinh viên yêu cầu
chốt ứng viên đạt120MHz trước tuần14. Production thay đúng hai file
`rtl/parser/posit_parser.sv` và `posit_parser_comb.sv` bằng byte của candidate `negate`
đã kiểm tại8.31.7. Không sửa RTL khác, parameter, I/O, precision, FF, latency hoặc L1/oracle.
Header cũ của parser giữ nguyên để byte-identical với bằng chứng; provenance OPT-12 nằm ở manifest này.

| Top/profile đo | Clock/strategy | Setup WNS | Hold WHS | LUT/FF |
| --- | --- | --- | --- | --- |
| NF32/3 FW12 EXACT_EN1 OPS_EN1 | 8,3ns / Explore | +0,227ns | +0,053ns | 2424/931 |
| F32/3 FW12 W32 EXACT_EN0 OPS_EN1 | 8,3ns / Explore | +0,093ns | +0,040ns | 1362/815 |

Tần số công bố120,48MHz là kết quả OOC post-route theo profile/flow trên, không phải
maximumFmax hoặc board signoff. Các strategy FAIL tại8.31.7 vẫn giữ nguyên.
NF EXACT_EN1/F EXACT_EN0 chưa tạo cặp PPA công bằng; W15 cần comparator theo plan.

Recipe khóa: `syn/opt12_120mhz_release.json`; clock riêng
`syn/constraints/a35t_clock_120mhz.xdc`. Input min=max2,5ns, output min0/max0,5ns,
uncertainty setup/hold0,1ns; đọc XDC trước synthesis, không thêm exception.
Hai XDC100MHz gốc giữ nguyên để replay lịch sử. Không dùng script100MHz mặc định để
gọi đó là phép đo120MHz; replay dùng run_opt12_ppa với `-Period 8.300 -Strategy Explore`
và `-Attempt` mới cho từng `-Top nf`/`-Top f`.

Nguồn38 module+header được đối chiếu toàn bộ hash với snapshot negate đã chạy.
Kế thừa đúng bằng chứng đã thực thi: parser870 profile lint,84.272 cyclechecks,
66.480 exhaustive checks; NF10M và F10M đều0 mismatch; ModelSim NF111.456/F8.192
completed, reset-abort288/24,0 mismatch tại8ns. Không chạy lại regression lớn trong phiên promote.
Audit mới ràng buộc recipe/clock, summary/qualification, toàn bộ nguồn và L1/build;
self-test từ chối4/4 mutation. Historical OPT12 audit vẫn kiểm11PPA và3unitvariant,
không sửa summary hoặc qualification cũ để nhận PASS.

Lock100MHz gốc được lưu nguyên byte ở `results/opt120_20261018/reference_freeze.json`,
đồng thời vẫn nằm trong `reference_source.zip`. Lock hiện hành ở `rtl/production_freeze.json`;
receipt chuyển tiếp `results/opt120_20261018/promotion.json` ghi hash hai lock và đúng2file thay đổi.

**Bước kế tiếp: W14-01 rồi tuần tự kế hoạch W14.** Chưa chạy W14-01..12,
chưa final per-n/AC04/AC02, chưa paired accuracy/PPA hoặc Gate4. Bất kỳ sửa RTL/L1/
constraint đã khóa nào tiếp theo phải mở change review và release mới, giữ evidence FAIL.
Các đoạn8.31.6/7 ghi chưa promote là trạng thái lịch sử, không còn là workflow hiện hành.
'''
    path = R.parent/'doc/Optimization.md'
    assert '#### 8.31.8.' not in path.read_text(encoding='utf-8')
    edit(path, lambda text: text+addition)
    print('Release documentation synchronized; historical trial retained')


if __name__ == '__main__':
    main()
