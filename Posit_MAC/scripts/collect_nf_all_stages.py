"""Audit and publish full-bank STA from one frozen OPT-02b implementation."""
from pathlib import Path
import csv
import hashlib
import json
import re
import zipfile

R = Path(__file__).resolve().parents[1]
O = R / 'results/nf_all_stages_20261017'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
read = lambda name: (O / name).read_text(encoding='utf-8-sig', errors='replace')
assert read('status.txt').strip() == 'COMPLETE'
log = read('vivado.log')
assert 'NF_ALL_STAGES_COMPLETE' in log and not re.search(r'^ERROR:', log, re.M)
counts = {k: len(re.findall(r'^Command: ' + k + r'\b', log, re.M))
          for k in ['synth_design', 'place_design', 'route_design']}
assert all(v == 1 for v in counts.values()), counts
sources = {p.name: sha(p) for p in (O / 'source').iterdir() if p.is_file()}
assert len(sources) == 37
for name, digest in sources.items():
    assert digest == sha(R / 'results/opt02b_20261017/ppa/source' / name), name
for name in (R / 'rtl/production.f').read_text().splitlines() + ['rtl/posit_mac.vh']:
    if name.strip():
        p = R / name.strip()
        assert sha(p) == sha(R / 'results/opt02b_20261017/source/baseline' / p.name), name
assert sha(O / 'driver/prepack_nf_ppa_top.sv') == sha(R / 'tb/prepack_nf_ppa_top.sv')
rows = list(csv.DictReader(read('stages.csv').splitlines()))
assert len({r['group'] for r in rows}) == len(rows)
assert not any(r['group'] == 'unclassified' for r in rows)
cells = []
for row in rows:
    name = row['group']
    regs = read(name + '_registers.txt').splitlines()
    assert len(regs) == int(row['register_count'])
    if name != 'whole_data':
        cells.extend(regs)
    for kind, col in [('setup', 'setup_slack_ns'), ('hold', 'hold_slack_ns')]:
        value = row[col]
        if value != 'NA':
            report = read(name + '_' + kind + '.rpt')
            m = re.search(r'Slack \((?:MET|VIOLATED)\)\s*:\s*([-\d.]+)ns', report)
            assert m and abs(float(m[1]) - float(value)) < 0.00051, (name, kind)
    for key in ['register_count', 'levels']:
        if row[key] != 'NA': row[key] = int(row[key])
    for key in ['setup_slack_ns', 'hold_slack_ns', 'data_delay_ns', 'logic_delay_ns', 'route_delay_ns']:
        if row[key] != 'NA': row[key] = float(row[key])
assert len(cells) == len(set(cells)) == 930
assert 'latches=0' in read('structural.txt') and 'unrouted=0' in read('structural.txt')
assert 'unclassified=0' in read('structural.txt')
assert 'unconstrained_internal_endpoints (0)' in read('timing.rpt')
whole = next(r for r in rows if r['group'] == 'whole_data')
assert min(whole['setup_slack_ns'], whole['hold_slack_ns']) >= 0
output_slacks = {}
for kind in ['setup', 'hold']:
    m = re.search(r'Slack \((?:MET|VIOLATED)\)\s*:\s*([-\d.]+)ns', read('output_' + kind + '.rpt'))
    assert m
    output_slacks[kind + '_slack_ns'] = float(m[1])
summary = dict(status='PASS_FULL_BANK_REPORT', variant='OPT-02b candidate, not production',
               part='xc7a35tcpg236-1', NB=32, ES=3, FRAC_W=12, EXACT_EN=1, OPS_EN=1,
               clock_period_ns=10, uncertainty_ns=0.1, input_min_max_ns=2.5,
               output_min_ns=0, output_max_ns=0.5, directive='Default',
               seed='Vivado Default; no random seed override',
               command='PowerShell ./scripts/run_nf_all_stages_sta.ps1',
               collection_command='python scripts/collect_nf_all_stages.py',
               tool=read('tool.txt').strip(), phase_counts=counts,
               source_sha256=sources, unique_registers=len(cells), rows=rows, output_ports=output_slacks,
               scope='Worst data/CE setup and hold per destination bank, all timed launches including ports; reset recovery/removal excluded from bank rows and retained in timing.rpt. Hold and setup need not share a path. One OOC implementation, not board signoff or independent random trial.',
               io_limitation='OOC ports have no HD.PARTPIN_LOCS (Route 35-198); input/output paths are constraint estimates, not physically signed-off board I/O. See row startpoints and raw reports.',
               checkpoint='routed.dcp retained locally, excluded from Git/archive')
(O / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')

labels = {
    'parser_a_p1': 'Parser A — P1', 'parser_a_p2': 'Parser A — P2',
    'parser_b_p1': 'Parser B — P1', 'parser_b_p2': 'Parser B — P2',
    'parser_c_p1': 'Parser C_eff — P1', 'parser_c_p2': 'Parser C_eff — P2',
    'ops_m0_core_context': 'OPS → M0/context core', 'sac_state': 'SAC/controller — state feedback',
    'sac_token_l1': 'SAC/controller → token L1', 'sbm_shift_l2': 'SBM dịch → L2',
    'accumulator_l3': 'SBM tích lũy → L3', 'product_packer_p1': 'Normalize + pack tích — P1',
    'product_packer_p2': 'Pack tích — P2/RNE', 'product_parse_bank': 'Parse lại tích → product bank',
    'adder_a1': 'Adder — A1 align', 'adder_a2': 'Adder — A2 cộng/trừ',
    'adder_a3': 'Adder — A3 normalize', 'final_packer_p1': 'Packer tổng — P1',
    'final_packer_p2': 'Packer tổng — P2/RNE', 'c_context': 'C/context giữ giao dịch',
    'transaction_control': 'Điều khiển transaction', 'accumulator_feedback': 'Accumulator feedback/commit',
    'reset_sync': 'Reset bridge/synchronizer', 'whole_data': 'Toàn bộ bank dữ liệu/CE'}
assert set(labels) == {r['group'] for r in rows}, set(labels) ^ {r['group'] for r in rows}
order = list(labels)
table = ['| Bank / tầng đích | FF | Setup slack (ns) | Hold slack (ns) | Data delay worst setup (ns) |',
         '| --- | ---: | ---: | ---: | ---: |']
for name in order:
    row = next(r for r in rows if r['group'] == name)
    fmt = lambda key: f'{row[key]:+.3f}' if isinstance(row[key], (int, float)) else str(row[key])
    table.append(f"| {labels[name]} | {row['register_count']} | {fmt('setup_slack_ns')} | {fmt('hold_slack_ns')} | {row['data_delay_ns']} |")
section = '''### 8.24. Bảng STA đủ bank MAC NF candidate OPT-02b — 17/10/2026

Một lượt synth/place/route Default mới trên xc7a35tcpg236-1, Vivado2026.1 build6511674; nguồn37file giống byte checkpoint OPT-02b trước đó. NF32/3, FW12, EXACT_EN=OPS_EN1,100MHz/10ns, uncertainty0,1ns,inputmin=max2,5ns/outputmax0,5ns min0. Không sửa RTL, mô phỏng hoặc promote candidate; đây là đo lại cùng cấu hình, không tính là một directive/seed độc lập để nghiệm thu đa run.

Mỗi hàng lấy worst setup và worst hold của mọi đường được timing vào chân D/CE của bank đích; gồm launch từ register hoặc input port, và control/enable. Hai giá trị có thể thuộc hai đường khác nhau. Không gọi data delay là setup time của FF, không cộng slack các tầng. Các bank context/control/feedback không làm tăng số tầng số học. Parser A/B/C chạy song song; L1/L2/L3 lặp theo term.

''' + '\n'.join(table) + '''

Partition phủ toàn bộ930 FF, không trùng/thiếu bank; reset được tách riêng, recovery/removal còn trong timing.rpt. Báo cáo setup/hold từng nhóm giữ top3 đường và danh sách FF. Output port có worst setup+0,345ns (in_ready),hold+1,482ns (d[10]); đây không phải bank pipeline mới. Vivado cảnh báo Route35-198: port OOC chưa có HD.PARTPIN_LOCS; các đường launch từ input port (đặc biệt parser P1) hoặc tới output chỉ là ước lượng với constraint I/O, chưa có routing chân board chính xác. Phải xem startpoint trong CSV; không coi slack I/O này là signoff phần cứng. Đây là OOC STA, không board signoff hoặc paired NF/F. Production A1 chưa áp dụng OPT-02b; không gán bảng candidate này cho production. Giữ routed.dcp local để truy vấn thêm mà không phải P&R lại; checkpoint/cache không push Git. Evidence zip và manifest SHA giữ nguồn, driver, reports và summary gọn tại results/nf_all_stages_20261017. Lệnh: scripts/run_nf_all_stages_sta.ps1; python scripts/collect_nf_all_stages.py.
'''
p = R.parent / 'doc/Optimization.md'
s = p.read_text(encoding='utf-8')
start_marker = '<!-- NF_ALL_STAGES_REPORT_START -->'
end_marker = '<!-- NF_ALL_STAGES_REPORT_END -->'
assert s.count(start_marker) == s.count(end_marker) == 1, 'Missing bounded report slot'
start = s.index(start_marker) + len(start_marker)
end = s.index(end_marker, start)
# Update this report only; preserve the following optimization plan and progress.
p.write_text(s[:start] + '\n' + section.strip() + '\n' + s[end:], encoding='utf-8')

# Small proof bundle, with byte hashes; no implementation databases/checkpoints.
paths = sorted(p for p in O.rglob('*') if p.is_file() and
               ((p.parent == O and p.suffix in {'.rpt', '.csv', '.json', '.xdc', '.txt', '.log'})
                or p.parent.name in {'driver', 'source'}) and
               p.name not in {'archive_manifest.json', 'console.log'})
manifest = {p.relative_to(O).as_posix(): sha(p) for p in paths}
with zipfile.ZipFile(O / 'evidence.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for p in paths: z.write(p, p.relative_to(O).as_posix())
with zipfile.ZipFile(O / 'evidence.zip') as z:
    for name, digest in manifest.items(): assert hashlib.sha256(z.read(name)).hexdigest() == digest
(O / 'archive_manifest.json').write_text(json.dumps(dict(files=manifest, archive_sha256=sha(O / 'evidence.zip')), indent=2) + '\n')
print('PASS_FULL_BANK_REPORT', len(cells), len(rows), whole['setup_slack_ns'], whole['hold_slack_ns'])
print('\n'.join(table))
