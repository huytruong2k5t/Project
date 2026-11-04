"""Summarize matched FULL_TERM baseline/Plan A synthesis; verify frozen inputs."""
from pathlib import Path
import csv
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'results/feedforward_a_20261104'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    records = []
    for label in ['baseline', 'candidate']:
        run = OUT/label
        manifest = json.loads((run/'manifest.json').read_text(encoding='utf-8-sig'))
        for rel, digest in manifest['sha256'].items():
            assert sha(run/'source'/rel).lower() == digest.lower(), rel
        assert (run/'verify/status.txt').read_text(encoding='utf-8-sig').strip() == 'PASS'
        for variant in ['nf', 'f']:
            syn = run/('synth_'+variant)
            reports = syn/'f2f_recheck' if label == 'baseline' and variant == 'nf' else syn
            rows = list(csv.DictReader((reports/'f2f_stages.csv').open()))
            delay = next(r for r in rows if r['group'] == 'whole' and r['target_kind'] == 'D_CE')
            setup = next(r for r in rows if r['group'] == 'whole_worst_setup')
            metrics = next(csv.DictReader((reports/'timing_metrics.csv').open()))
            util = (syn/'synthesis_utilization.rpt').read_text()
            def used(site):
                return int(re.search(r'\|\s*'+re.escape(site)+r'\s*\|\s*(\d+)', util)[1])
            wns, whs = float(metrics['wns_ns']), float(metrics['whs_ns'])
            period = 10-float(setup['slack_ns'])
            record = {'snapshot': label, 'variant': variant,
                      'f2f_d_ce_ns': float(delay['data_delay_ns']),
                      'f2f_d_only_ns': float(next(r for r in rows if r['group']=='whole' and r['target_kind']=='D')['data_delay_ns']),
                      'f2f_raw_reciprocal_mhz': 1000/float(delay['data_delay_ns']),
                      'f2f_setup_estimate_mhz': 1000/period,
                      'f2f_setup_min_period_ns': period,
                      'whole_interface_estimate_mhz': 1000/(10-wns),
                      'wns_ns': wns, 'whs_ns': whs,
                      'luts': used('Slice LUTs*'), 'ffs': used('Slice Registers'),
                      'feedback_registers': int(metrics['feedback_registers']),
                      'critical_start': delay['startpoint'], 'critical_end': delay['endpoint'],
                      'logic_ns': float(delay['logic_delay_ns']),
                      'estimated_net_ns': float(delay['net_delay_ns']),
                      'logic_levels': int(delay['levels']),
                      'reports': reports.relative_to(ROOT).as_posix()}
            assert record['feedback_registers'] == (32 if label=='baseline' else 0)
            records.append(record)
    verification = {}
    for variant in ['nf', 'f']:
        directory = OUT/'verification'
        build = json.loads((directory/f'build_{variant}.json').read_text())
        for rel, digest in build['source_sha256'].items():
            assert sha(directory/'source'/rel) == digest, rel
            assert sha(ROOT/rel) == digest, rel
        result = json.loads((directory/f'mixed_{variant}.json').read_text())
        assert result['status']=='PASS' and result['completed']==100000
        assert result['accepted']==result['completed']+result['reset_aborted']
        assert result['max_chain']>12 and result['mismatches']==0 and all(result['bins'])
        verification[variant] = {k: result[k] for k in [
            'completed', 'reset_aborted', 'mismatches', 'stage_checks',
            'accumulation', 'max_chain', 'long_chain_steps', 'invalid_checks']}
    active = [p for p in (ROOT/'rtl/mac_active.f').read_text().splitlines() if p.strip()]
    changed = []
    for rel in active:
        assert sha(ROOT/rel)==sha(OUT/'candidate/source'/rel), rel
        if sha(OUT/'baseline/source'/rel)!=sha(OUT/'candidate/source'/rel):
            changed.append(rel)
    assert len(changed)==4
    result = {'date':'2026-11-04', 'status':'IMPLEMENTED_PILOT_VERIFIED_SYNTHESIS_MEASURED',
              'profile':'POSIT32_ES3_APPROX12_FULL_TERM26_Q24_FEEDFORWARD',
              'part':'xc7a35tcpg236-1', 'period_ns':10,
              'clock_uncertainty_ns':0.1, 'input_delay_ns':2.5,
              'output_max_delay_ns':0.5, 'vivado':'2026.1',
              'synthesis_runs':4, 'implementation_run':False, 'bitstream_run':False,
              'records':records, 'verification':verification,
              'changed_active_rtl':changed,
              'arithmetic_parser_adder_packer_unchanged':True,
              'limits':'Post-synthesis UNPLACED estimated nets; raw 1000/F2F omits setup/skew/uncertainty. Setup estimate uses 10-WNS restricted to register C->D/CE. Not route/board Fmax; no full 520M matrix or structural coverage signoff.'}
    (OUT/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    with (OUT/'comparison.csv').open('w',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=list(records[0]))
        writer.writeheader();writer.writerows(records)
    lines=['# Phương án A NF/F — kết quả 04/11/2026', '',
           'Đã bỏ `accumulator_q`, `acc_mode`, `acc_clr` và MUX `c_eff` trong hai lõi NF/F. Cổng `c` nối thẳng vào Parser C. Chỉ bốn file top/wrapper RTL thay đổi; multiplier FULL_TERM26/Q24, parser, adder5 và packer giữ nguyên byte. Quire là IP riêng, giữ nguyên thanh ghi Q.', '',
           '## Đo đối chứng cùng FULL_TERM', '',
           'Vivado2026.1, xc7a35tcpg236-1, OOC synthesis, flatten rebuilt, clock10ns, setup/hold uncertainty0.1ns, input2.5ns, output max0.5ns. Mỗi NF/F đo trước/sau một lần, không place/route/bitstream. Baseline đã được kiểm trước khi chụp nguồn.', '',
           '| Lõi | Snapshot | F2F D/CE (ns) | 1000/F2F (MHz) | Fmax nội bộ có setup (MHz) | Fmax toàn giao diện (MHz) | LUT | FF | WNS/WHS (ns) |',
           '|---|---|---:|---:|---:|---:|---:|---:|---|']
    for r in records:
        lines.append(f"| {r['variant'].upper()} | {r['snapshot']} | {r['f2f_d_ce_ns']:.3f} | {r['f2f_raw_reciprocal_mhz']:.1f} | {r['f2f_setup_estimate_mhz']:.1f} | {r['whole_interface_estimate_mhz']:.1f} | {r['luts']} | {r['ffs']} | {r['wns_ns']:+.3f}/{r['whs_ns']:+.3f} |")
    lines += ['', '`1000/F2F` chỉ là nghịch đảo datapath. Ước lượng nội bộ có setup dùng `1000/(10 − slack_F2F_tệ_nhất)`; toàn giao diện dùng `1000/(10 − WNS_toàn_top)` với I/O budget giữ nguyên. Đây đều là ước lượng unplaced, chưa là Fmax đạt sau route. F2F bao gồm chân D và CE, không bỏ qua đường điều khiển.', '',
              '## Đường găng sau sửa', '']
    for r in records:
        if r['snapshot']!='candidate':continue
        lines += [f"- **{r['variant'].upper()}**: `{r['critical_start']}` → `{r['critical_end']}`; {r['logic_ns']:.3f}ns logic + {r['estimated_net_ns']:.3f}ns net ước lượng = {r['f2f_d_ce_ns']:.3f}ns, {r['logic_levels']} mức logic."]
    lines += ['', 'Đã kiểm netlist không còn 32 FF hồi tiếp ở cả NF/F; tổng FF mỗi lõi giảm34 (32 dữ liệu, một acc_mode, một committed). Việc bỏ vòng hồi tiếp làm mất đường accumulator→Parser C trong IP, nhưng đường vào c→Parser C vẫn phải đáp ứng ràng buộc hệ thống. Nếu thêm thanh ghi hồi tiếp ngoài IP, phải STA lại toàn hệ thống; không kế thừa Fmax nội bộ như Fmax vòng tích lũy.', '',
              'Con số5.243ns/~190MHz trong kế hoạch là dự đoán từ FLOOR cũ. Bảng này dùng baseline FULL_TERM hiện tại nên không áp trực tiếp con số lịch sử đó.', '',
              '## Verification và bằng chứng', '',
              '- Audit31 module,68 instance đủ cổng; strict lint từng module đạt.',
              '- ModelSim: adder39534 completed, packer10851, core53249 case/231437 checkpoint. Mỗi NF/F50000 request,49701 completed +299 reset-aborted,0 mismatch; external-feedback31077 completed, chuỗi dài nhất70. Kiểm hold output, thay live inputs sau accept, invalid n13..15/OPS2..3 và reset khi tính/khi giữ output.',
              '- Verilator + oracle integer độc lập: mỗi NF/F100000 completed,0 mismatch; kiểm magnitude/metadata từng vòng và26 tổ hợp n×OPS mỗi lõi trong corpus mixed.']
    for v,r in verification.items():
        lines += [f"- {v.upper()}: {r['stage_checks']} checkpoint vòng nhân, {r['accumulation']} giao dịch hồi tiếp ngoài, chuỗi dài nhất{r['max_chain']}, {r['reset_aborted']} reset-aborted."]
    lines += ['', 'Đây là regression của thay đổi giao diện, chưa là main52×10M, chưa đo coverage mới hoặc accuracy/PPA sau route. Các kết quả cũ vẫn thuộc snapshot riêng.', '',
              '[CSV đối chứng](comparison.csv) · [Summary/hash guards](summary.json) · [Nguồn trước sửa](baseline/source/rtl/mac_nf/mac_nf_wrapper.sv) · [Nguồn sau sửa](candidate/source/rtl/mac_nf/mac_nf_wrapper.sv) · [Audit](verification/ports_and_lint.json)', '',
              'Các thư mục baseline/candidate giữ manifest, source, vectors, log, DCP và báo cáo theo tầng `f2f_stages.csv`, `whole_D_CE.rpt`, `input_c_to_register.rpt`. Baseline NF synthesis đã hoàn tất ngay lượt đầu; helper báo cáo gặp property Vivado không hỗ trợ, nên chỉ đọc lại DCP vào `baseline/synth_nf/f2f_recheck`, không synthesis lần hai.', '']
    (OUT/'summary.md').write_text('\n'.join(lines),encoding='utf-8')
    print('FEEDFORWARD_SUMMARY_PASS',len(records),'measurements')


if __name__=='__main__':
    main()
