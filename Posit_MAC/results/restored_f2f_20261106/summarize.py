from pathlib import Path
from collections import Counter
import csv
import hashlib
import json
import re

run = Path(__file__).resolve().parent
root = run.parents[1]
snapshot = run / 'candidate'
manifest = json.loads((snapshot / 'manifest.json').read_text())
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
for rel, digest in manifest['sha256'].items():
    assert sha(snapshot / 'source' / rel) == digest, rel
    assert sha(Path(manifest['source_origin'][rel])) == digest, ('Live drift', rel)
assert (snapshot / 'verify/status.txt').read_text().strip() == 'PASS'
verification = json.loads((snapshot / 'verify/evidence.json').read_text())
previous = json.loads((root / 'results/refactor_lut_20261106/summary.json').read_text())
records = []
combined = []
hashes = {}
for v in ['nf', 'f']:
    target = snapshot / ('synth_' + v)
    assert (target / 'status.txt').read_text().strip() == 'SYNTHESIS_COMPLETE'
    util = (target / 'synthesis_utilization.rpt').read_text()
    luts = int(re.search(r'\| Slice LUTs\*\s*\|\s*(\d+)', util)[1])
    ffs = int(re.search(r'\| Slice Registers\s*\|\s*(\d+)', util)[1])
    legacy = list(csv.DictReader((target / 'f2f_stages.csv').open()))
    full = list(csv.DictReader((target / 'f2f_full_stages.csv').open()))
    inventory = list(csv.DictReader((target / 'stage_register_inventory.csv').open()))
    assert len({r['register'] for r in inventory}) == len(inventory) == ffs
    counts = Counter(r['group'] for r in inventory)
    for row in full:
        assert int(row['register_count']) == counts[row['group'].removeprefix('full_')]
        combined.append({'variant': v, **row})
    whole = next(r for r in legacy if r['group'] == 'whole' and r['target_kind'] == 'D_CE')
    worst = next(r for r in legacy if r['group'] == 'whole_worst_setup')
    metrics = next(csv.DictReader((target / 'timing_metrics.csv').open()))
    before = next(r for r in previous['records'] if r['snapshot'] == 'candidate' and r['variant'] == v)
    record = {'variant': v, 'luts': luts, 'ffs': ffs, 'f2f_d_ce_ns': float(whole['data_delay_ns']),
              'logic_ns': float(whole['logic_delay_ns']), 'estimated_net_ns': float(whole['net_delay_ns']),
              'critical_start': whole['startpoint'], 'critical_end': whole['endpoint'],
              'wns_ns': float(metrics['wns_ns']), 'whs_ns': float(metrics['whs_ns']),
              'f2f_setup_estimate_mhz': 1000 / (10 - float(worst['slack_ns'])),
              'previous_luts': before['luts'], 'previous_f2f_ns': before['f2f_d_ce_ns'],
              'register_counts': dict(counts), 'stages': full, 'legacy_stages': legacy}
    records.append(record)
    for p in target.iterdir():
        if p.is_file() and p.suffix in ['.rpt', '.csv', '.json', '.tcl', '.dcp', '.xdc', '.txt']:
            hashes[p.relative_to(run).as_posix()] = sha(p)

with (run / 'f2f_all_stages.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=list(combined[0]))
    writer.writeheader(); writer.writerows(combined)
summary = {'date': '2026-11-06', 'status': 'RESTORED_RTL_PILOT_VERIFIED_SYNTHESIS_MEASURED',
           'part': 'xc7a35tcpg236-1', 'vivado': '2026.1', 'period_ns': 10,
           'synthesis_runs': 2, 'implementation_run': False, 'bitstream_run': False,
           'restoration': 'Packer restored to 59-bit shifter and parallel thermometer sticky mask; S5 clear_val removal retained',
           'records': records, 'verification': verification,
           'limits': 'Post-synthesis unplaced estimates. Full groups cover payload/flags/valid and D/CE endpoints. Launch from all register C pins, not necessarily the adjacent stage. Async reset timing and input/output paths are not F2F. No exhaustive coverage or routed Fmax signoff.'}
(run / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
labels = {
    'parser_a_p1': 'Parser A P1', 'parser_a_p2': 'Parser A P2',
    'parser_b_p1': 'Parser B P1', 'parser_b_p2': 'Parser B P2',
    'parser_c_p1': 'Parser C P1', 'parser_c_p2': 'Parser C P2',
    'multiplier_context': 'Multiplier context', 'multiplier_sac': 'Multiplier SAC / control',
    'multiplier_t1': 'Multiplier T1', 'multiplier_t2': 'Multiplier T2',
    'multiplier_acc': 'Multiplier accumulator / result',
    'adder_s1': 'Adder S1', 'adder_s2': 'Adder S2', 'adder_s3': 'Adder S3',
    'adder_s4': 'Adder S4', 'adder_s5': 'Adder S5 (đầy đủ)',
    'final_pack_p1': 'Final Packer P1', 'final_pack_p2': 'Final Packer P2 (đầy đủ)',
    'product_pack_p1': 'Product Packer P1', 'product_pack_p2': 'Product Packer P2',
    'wrapper_control_context': 'Wrapper control / context', 'reset_sync': 'Reset synchronizers',
    'product_pack_other': 'Product Packer P2 — sign_q riêng',
}
for rec in records:
    for group in rec['register_counts']:
        labels.setdefault(group, group)
lines = ['# Synthesis và F2F sau phục hồi Packer — 06/11/2026', '',
         'Snapshot mới được tạo riêng từ RTL live, không sửa RTL hoặc ghi đè lần đo trước. Chỉ phục hồi Packer (bộ dịch 59 bit + thermometer sticky mask); tối ưu bỏ clear_val ở S5 vẫn được giữ.', '',
         'Vivado 2026.1, xc7a35tcpg236-1, OOC/flatten rebuilt, clock 10 ns, user uncertainty 0,1 ns, input delay 2,5 ns, output max/min 0,5/0 ns; max DSP/BRAM=0. Recipe synthesis và constraints giữ nguyên. Chỉ thêm báo cáo đầy đủ nhóm thanh ghi sau phần báo cáo cũ. Hai lượt synthesis NF/F; không implementation/place/route/bitstream.', '',
         '## Tổng quan so với lần đo refactor_lut_20261106/candidate', '',
         '| Lõi | LUT lần trước → phục hồi | FF mới | F2F D/CE lần trước → phục hồi (ns) | WNS toàn giao diện (ns) | WHS (ns) |',
         '|---|---:|---:|---:|---:|---:|']
for r in records:
    lines.append(f"| MAC-{r['variant'].upper()} | {r['previous_luts']} → {r['luts']} | {r['ffs']} | {r['previous_f2f_ns']:.3f} → {r['f2f_d_ce_ns']:.3f} | {r['wns_ns']:.3f} | {r['whs_ns']:.3f} |")
lines += ['', '## F2F đầy đủ theo nhóm thanh ghi đích', '',
          'Các số sau là độ trễ lớn nhất C→D/CE, tính từ mọi thanh ghi launch trong thiết kế tới nhóm thanh ghi đích. Bao gồm dữ liệu, metadata, flags, valid và clock enable; không đồng nghĩa chỉ đo từ tầng liền trước. CSV lưu riêng D-only và D/CE, logic/net delay, số tầng logic và hai đầu đường đi.', '',
          '| Nhóm đích | NF (ns) | F (ns) |', '|---|---:|---:|']
for group, label in labels.items():
    values = []
    for rec in records:
        row = next((r for r in rec['stages'] if r['group'] == 'full_' + group and r['target_kind'] == 'D_CE'), None)
        values.append('—' if row is None else f"{float(row['data_delay_ns']):.3f}")
    lines.append(f'| {label} | {values[0]} | {values[1]} |')
lines += ['', 'Không cộng các giá trị F2F giữa các tầng. Đây là các đường song song và có thể xuất phát từ tầng/control khác nhau. Nhóm reset_sync có đường FF→FF nếu tồn tại, không phải kiểm tra recovery/removal của chân reset bất đồng bộ.', '',
          'Riêng NF, bộ phân nhóm tách sign_q_reg của Product Packer thành product_pack_other; đây là metadata thuộc P2. Đường tới sign_q là 3,520 ns, nhỏ hơn cực đại P2 4,350 ns, nên gộp metadata này vào P2 không làm thay đổi con số cực đại P2. Inventory và báo cáo riêng vẫn giữ để kiểm lại.', '',
          '## Đường găng và kiểm tra độ đầy đủ', '']
for r in records:
    lines += [f"- MAC-{r['variant'].upper()}: `{r['critical_start']}` → `{r['critical_end']}`; tổng {r['f2f_d_ce_ns']:.3f} ns = logic {r['logic_ns']:.3f} + net ước lượng {r['estimated_net_ns']:.3f} ns.",
              f"- Inventory {r['variant'].upper()}: {r['ffs']} thanh ghi, mỗi cell được gán đúng một nhóm; {len(r['register_counts'])} nhóm. Đối chiếu stage_register_inventory.csv với register_count trong báo cáo từng nhóm."]
lines += ['',
          'Báo cáo cũ vẫn giữ nguyên f2f_stages.csv để so sánh cùng phạm vi với lần trước: adder_s5 cũ chỉ chọn frac_hi_q, final_pack_p2 cũ chỉ chọn d_q. Các nhóm đầy đủ trong f2f_full_stages.csv mới bao gồm sf/sticky/sign/tags/flags và valid tương ứng. Khi so sánh phải dùng cùng định nghĩa nhóm.', '',
          '## Kiểm chứng và dữ liệu lưu', '',
          '- Strict lint: 31 module, 68 instance, PASS. Golden mixed regression: 100.000 completed mỗi lõi, 0 mismatch, đủ 26 tổ hợp OPS0/1 × n0..12. Đây là pilot kiểm chứng snapshot, không phải full coverage signoff.',
          '- Chỉ Packer được phục hồi; hợp đồng raw payload Zero/NaR của adder sau bỏ clear_val vẫn khác bản khóa cũ. Lần này không chạy lại testbench raw-bus adder cũ; bằng chứng FAIL/raw và PASS/semantic của cùng adder được giữ ở results/refactor_lut_20261106.',
          '- f2f_all_stages.csv: bảng hợp nhất NF/F, cả D-only và D/CE; summary.json chứa số đo và đường găng đầy đủ.',
          '- candidate/synth_nf và candidate/synth_f: DCP, utilization, timing, CSV, báo cáo top 20 đường từng nhóm, inventory, constraints, execution receipt và log.',
          '- candidate/manifest.json + candidate/source: đầu vào có SHA-256; kiểm tra snapshot và source live trước khi lập báo cáo.',
          '- candidate/source/results/verification: log, build manifest và báo cáo golden/lint mới.',
          '- detailed_stages.tcl: định nghĩa nhóm thanh ghi; measure.py: recipe synthesis gốc chỉ bổ sung reporting; evidence.sha256.json: hash các kết quả để kiểm lại.', '',
          'Độ trễ net trong báo cáo là ước lượng chưa place/route. Không công bố các số này là Fmax thực tế trên kit; WHS âm vẫn cần xử lý trong luồng implementation nếu muốn signoff timing.',
]
(run / 'summary.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
for p in [snapshot / 'manifest.json', snapshot / 'verify/evidence.json', run / 'summary.json', run / 'f2f_all_stages.csv']:
    hashes[p.relative_to(run).as_posix()] = sha(p)
(run / 'evidence.sha256.json').write_text(json.dumps(hashes, indent=2) + '\n')
print('RESTORED_F2F_SUMMARY_PASS')
for r in records:
    print(r['variant'], r['luts'], r['ffs'], r['f2f_d_ce_ns'], r['register_counts'])
