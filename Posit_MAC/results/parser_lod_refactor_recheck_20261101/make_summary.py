import csv
import hashlib
import json
import re
from pathlib import Path

run = Path(__file__).resolve().parent
root = run.parent.parent
base = root / 'results/readme_refactor_recheck_20261101'
old_summary = json.loads((base / 'summary.json').read_text(encoding='utf-8-sig'))

def stages(path):
    return {r['group']: r for r in csv.DictReader(path.open(encoding='utf-8-sig'))
            if r['target_kind'] == ('D_CE' if r['group'] == 'whole_f2f' else 'D')}

def metrics(variant):
    folder = run / f'synth_{variant}_final'
    util = (folder / 'synthesis_utilization.rpt').read_text()
    timing = (folder / 'synthesis_timing.rpt').read_text()
    lut = int(re.search(r'\| Slice LUTs\*\s*\|\s*(\d+)', util)[1])
    ff = int(re.search(r'\| Slice Registers\s*\|\s*(\d+)', util)[1])
    header = timing.index('WNS(ns)')
    numbers = re.search(r'^\s*(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s+(-?\d+\.\d+)', timing[header:], re.M)
    return dict(LUT=lut, FF=ff, DSP=0, BRAM=0, WNS_ns=float(numbers[1]), WHS_ns=float(numbers[5]))

verification = {}
for label in ['adder','packer','nf','f']:
    body = (run / 'verify' / f'{label}.log').read_text()
    verification[label] = re.search(r'^# (.*_PASS[^\n]*)', body, re.M)[1].strip()
body = (run / 'verify_parser_lod/parser_lod.log').read_text()
verification['parser_lod'] = re.findall(r'^# (.*_PASS[^\n]*)', body, re.M)

manifest = json.loads((run / 'manifest.json').read_text(encoding='utf-8-sig'))
changed = []
for path, expected in manifest['sha256'].items():
    assert hashlib.sha256((run/'source'/path).read_bytes()).hexdigest().upper() == expected
    if path.startswith('rtl/'):
        assert hashlib.sha256((root/path).read_bytes()).hexdigest().upper() == expected, path
        previous = base / 'source' / path
        if not previous.exists() or hashlib.sha256(previous.read_bytes()).hexdigest().upper() != expected:
            changed.append(path)

lines = ['# Đo lại MAC NF/F sau refactor Parser và LOD — 01/11/2026', '',
         'Kết luận: các suite chức năng đã chạy đều PASS, nhưng refactor chưa tốt hơn về F2F tổng: NF giữ 7.334 ns; F tăng 6.602 → 7.697 ns (+16.59%). LUT tăng ở cả hai top. Bộ cộng S4 cải thiện, nhưng điểm nghẽn toàn MAC chưa được giải quyết.', '',
         'Baseline: ../readme_refactor_recheck_20261101. Nguồn mới được khóa tại source/ và manifest.json; toàn bộ hash RTL đang làm việc vẫn trùng snapshot đã verify/synthesis. Không sửa RTL trong lượt đo này.', '',
         'Hai file thay đổi so với baseline: ' + ', '.join(f'`{p}`' for p in changed) + '.', '',
         '## Điều kiện đo', '',
         'Vivado 2026.1; Artix-7 xc7a35tcpg236-1; OOC synthesis; clock 10 ns, uncertainty 0.1 ns; input min=max 2.5 ns; output min 0/max 0.5 ns; flatten_hierarchy rebuilt; DSP/BRAM=0. Cùng recipe với baseline. Không chạy opt/place/route/bitstream.', '',
         '## Verification', '']
for k,v in verification.items():
    for value in (v if isinstance(v,list) else [v]):
        lines.append('- ' + value)
lines += ['', 'MAC so d/5 flags với golden Python integer độc lập cho Posit(32,3), FLOOR/Q12 hiện hành: NF n=0..8, F n=0..12, OPS0/1, cfg_mode=1; có accumulation/clear, thay context, reset và backpressure. 299 giao dịch/top bị reset hủy có chủ đích và được hạch toán.', '',
          'Kiểm bổ sung dùng trực tiếp magnitude nội bộ của parser mới đối chiếu phép bù hai trên 4 triệu vector; LOD mới so với oracle quét bit tuần tự trên 500.063 vector; parser đầy đủ so với snapshot baseline, gồm data, ready/valid, stall/reset. Reference parser và LOD cũ chỉ đổi tên module trong verify_parser_lod/source/ để cùng biên dịch. Test tb_parser_mag_equiv hiện có chỉ tự tính lại công thức; vì vậy không dùng nó làm bằng chứng duy nhất cho RTL. Không dùng candidate LOD làm golden thay cho oracle.', '',
          'Đây là regression theo RTL FLOOR hiện tại; chưa là nghiệm thu FULL_TERM26/Q24 hoặc toàn bộ ma trận 52 điểm/520 triệu completed của SPEC.', '',
          '## Synthesis và F2F', '',
          '| Top | LUT cũ → mới | FF cũ → mới | WNS cũ → mới (ns) | F2F cũ → mới (ns) | Giảm F2F |',
          '| --- | ---: | ---: | ---: | ---: | ---: |']
comparison = {}
for variant in ['nf','f']:
    new_stages, old_stages = stages(run/f'f2f_{variant}/stages.csv'), stages(base/f'f2f_{variant}/stages.csv')
    new = metrics(variant)
    new['F2F_ns'] = float(new_stages['whole_f2f']['data_delay_ns'])
    old = old_summary['comparison'][variant]['new']
    pct = 100*(old['F2F_ns']-new['F2F_ns'])/old['F2F_ns']
    comparison[variant] = dict(old=old,new=new,F2F_reduction_percent=round(pct,2),critical_path=new_stages['whole_f2f'])
    lines.append(f"| {variant.upper()} | {old['LUT']} → {new['LUT']} | {old['FF']} → {new['FF']} | {old['WNS_ns']:.3f} → {new['WNS_ns']:.3f} | {old['F2F_ns']:.3f} → {new['F2F_ns']:.3f} | {pct:.2f}% |")
lines += ['', 'Cả hai top synthesis hoàn tất với 0 errors, 0 critical warnings và 0 warnings trong synth_design. FF giữ nguyên, WHS cả hai vẫn −0.055 ns. LUT NF tăng 116 (+5.53%); F tăng 117 (+9.31%). Setup WNS tổng bao gồm cả I/O nên khác setup slack của đường F2F trích riêng.', '',
          'F2F là Data Path Delay của đường có setup slack xấu nhất từ FF đến chân D/CE; bảng từng bank dùng D. Gồm C→Q, logic và net ước lượng trước placement; không gồm setup/skew/uncertainty, không phải Fmax. Parser A/B P1 nhận data từ port nên F2F tới bank đó chủ yếu là control/valid, còn Parser C P1 có đường dữ liệu feedback từ accumulator.', '',
          'Đường Parser C P1 của F giữ cùng source/endpoint so với baseline: levels giảm 10→7, logic delay giảm 2.878→1.495 ns, nhưng net delay ước lượng tăng 3.724→6.202 ns. Vì vậy tổng tăng 1.095 ns. Fanout/cấu trúc kết nối sau ánh xạ cần được xem cùng logic depth; giảm CARRY4 không tự bảo đảm giảm tổng delay. Đây là kết quả của cả hai thay đổi cùng lúc, chưa tách riêng đóng góp prefix-OR và casez.', '',
          'NF Parser C P1 chỉ giảm 7.063→7.019 ns, trong khi đường Parser B P2→SAC state vẫn 7.334 ns nên toàn NF không đổi. Adder S4 dùng chung LOD mới giảm 3.922→3.450 ns ở cả NF/F, là cải thiện cục bộ có thể đo được. Chưa có cơ sở chọn toàn bộ refactor này làm bản tối ưu timing thay baseline; cần thử tách từng thay đổi nếu tiếp tục tối ưu.', '']
for variant in ['nf','f']:
    new_stages, old_stages = stages(run/f'f2f_{variant}/stages.csv'), stages(base/f'f2f_{variant}/stages.csv')
    whole = new_stages['whole_f2f']
    lines += ['', f'## F2F từng bank — {variant.upper()}', '',
              f"Critical path: `{whole['startpoint']}` → `{whole['endpoint']}`; {whole['data_delay_ns']} ns, logic {whole['logic_delay_ns']} ns, net {whole['net_delay_ns']} ns, {whole['levels']} levels; setup slack {whole['slack_ns']} ns.", '',
              '| Bank đích | Cũ (ns) | Mới (ns) | Δ mới−cũ (ns) | Levels cũ→mới |',
              '| --- | ---: | ---: | ---: | ---: |']
    for group,new_row in new_stages.items():
        old_row=old_stages.get(group)
        if group=='whole_f2f' or not old_row or 'NA' in (old_row['data_delay_ns'],new_row['data_delay_ns']): continue
        a,b=float(old_row['data_delay_ns']),float(new_row['data_delay_ns'])
        lines.append(f"| {group} | {a:.3f} | {b:.3f} | {b-a:+.3f} | {old_row['levels']}→{new_row['levels']} |")
lines += ['', '## Giới hạn', '',
          'WHS vẫn cần đọc cùng timing report; số synthesis chưa xác nhận setup/hold sau route hay hoạt động trên kit. DRC OOC CFGBVS-1 liên quan điện áp cấu hình board chưa khai báo trong benchmark. Không suy tốc độ 200 MHz từ số level LUT hoặc công thức RTL; casez/prefix-OR phải được đánh giá theo ánh xạ thực tế.', '',
          '## Tái chạy', '', 'Từ thư mục Posit_MAC, dùng RunRoot mới để giữ nguyên bằng chứng:', '', '```powershell',
          './scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot results/<run_moi> -VectorCount 50000',
          './scripts/run_parser_lod_recheck.ps1 -RunRoot results/<run_moi>',
          './scripts/run_refactored_mac.ps1 -Stage SynthNF -RunRoot results/<run_moi> -SynthSuffix _final',
          './scripts/run_refactored_mac.ps1 -Stage SynthF -RunRoot results/<run_moi> -SynthSuffix _final',
          './scripts/report_refactored_mac_f2f.ps1 -Variant nf -RunRoot results/<run_moi>',
          './scripts/report_refactored_mac_f2f.ps1 -Variant f -RunRoot results/<run_moi>', '```', '']
summary = dict(baseline=str(base),current=str(run),part='xc7a35tcpg236-1',period_ns=10,
               synthesis_only=True,rtl_unchanged_by_review=True,changed_rtl=changed,
               verification=verification,comparison=comparison)
(run/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(run/'summary.md').write_text('\n'.join(lines),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
