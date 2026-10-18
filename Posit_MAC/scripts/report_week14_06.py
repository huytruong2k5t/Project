"""Audit W14 through F final, document measured results; do not close later gates."""
from pathlib import Path
from collections import defaultdict
import json
import re
from audit_week14 import inputs,load,sha,O,R,validate_result
from audit_rtl_release import validate


def dump(path,value):
    path.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf-8',newline='\n')


def edit(path,transform):
    raw=path.read_bytes();newline='\r\n' if b'\r\n' in raw else '\n'
    text=raw.decode('utf-8').replace('\r\n','\n')
    path.write_bytes(transform(text).replace('\n',newline).encode('utf-8'))


def structural(paths):
    points=defaultdict(dict)
    for path in paths:
        for line in path.read_text().splitlines():
            if not line.startswith('C '):continue
            raw,hits=line[3:].rsplit("' ",1)
            fields=dict(v.split('\x02',1) for v in raw.split('\x01')[1:])
            if not fields['f'].startswith('src/rtl/'):continue
            kind=fields['page'].split('/')[0]
            key=tuple(sorted(fields.items()))
            points[kind][key]=points[kind].get(key,0)+int(hits)
    return {kind:dict(hit=sum(n>0 for n in p.values()),total=len(p),
                     percent=100*sum(n>0 for n in p.values())/len(p)) for kind,p in points.items()}


def main():
    assert not (O/'summary.json').exists(),'Preserve final report'
    inputs();lock=load(R/'rtl/production_freeze.json');validate(lock)
    freeze=load(O/'matrix_freeze.json')
    for name,digest in freeze['input_sha256'].items():assert sha(R/name)==digest,name
    for name,digest in freeze['binary_sha256'].items():assert sha(R/name)==digest,name
    for paths in load(O/'w14_01_review.json')['evidence'].values():
        for name,digest in paths.items():assert sha(R/name)==digest
    qual=load(O/'pilot_qualification.json');assert len(qual['pilots'])==44
    rows=[];companions=[];coverage_paths=[]
    for job in freeze['jobs']:
        if job['top']!='f':continue
        for phase,goal in [('main',10000000),('coverage_final',20000)]:
            run=O/phase/job['id'];receipt=load(run/'execution.json');data=load(run/'result.json')
            assert receipt['exit_code']==0
            validate_result(data,job,goal,status=receipt['status'],log_exists=(run/'console.log').exists(),
                bound=sha(run/'result.json')==receipt['report_sha256'] and sha(run/'console.log')==receipt['log_sha256'])
            profile='f32_3_fast' if phase=='main' else 'f32_3'
            binary=f'results/week14/builds/{profile}/obj/Vweek13_fused_tb'
            assert receipt['binary_sha256']==freeze['binary_sha256'][binary]
            assert receipt['pilot_source_sha256']==sha(O/'pilot_source.json')
            functional=load(run/'result.functional.json')
            assert functional['completed']==data['completed']
            assert functional['near_before']==data['near'] and functional['near_after']==data['near_after']
            record=dict(n=job['n'],completed=data['completed'],accepted=data['accepted'],
                reset_aborted=data['reset_aborted'],mismatches=data['mismatches'],seed=data['seed'],
                near_before=data['near'],near_after=data['near_after'],
                near_before_percent=100*data['near']/data['completed'],near_after_percent=100*data['near_after']/data['completed'],
                stage_checks=data['stage_checks'],valid_latency_min=data['valid_latency_min'],valid_latency_max=data['valid_latency_max'],
                seconds=receipt['wall_seconds'],report=run.relative_to(R).as_posix()+'/result.json')
            (rows if phase=='main' else companions).append(record)
            if phase=='coverage_final':coverage_paths.append(run/'result.coverage.dat')
    assert len(rows)==len(companions)==9 and sum(row['completed'] for row in rows)==90000000
    assert (O/'corner/status.txt').read_text().strip()=='COMPLETE'
    corners=[]
    for n in range(9):
        row=load(O/f'corner/n{n}.json');assert row['mismatches']==0 and min(row['corner_hits'])>0
        corners.append(dict(n=n,completed=row['completed'],tag_hits=row['corner_hits']))
    assert 'TV-FUSE-01=3.9375 TV-FUSE-02=-4.5625 n1..8 PASS' in (O/'golden_check/result.log').read_text()
    event=[]
    assert (O/'event_protocol/status.txt').read_text().strip()=='COMPLETE'
    m=load(O/'event_protocol/manifest.json')
    assert m['source_sha256']==lock['rtl_sha256']
    assert sha(O/'event_protocol/source/tb/tb_week14_protocol.sv')==m['tb_sha256']
    for mode in (0,1):
        log=(O/f'event_protocol/mode{mode}.log').read_text()
        assert not re.search(r'\*\*\s+(Error|Fatal):',log)
        parsed=re.findall(r'W14_PROTOCOL_N_PASS NF_EX0=(\d) n=(\d) q=(\d) L=(\d+) H=(\d+) II=(\d+) completed=(\d+)',log)
        assert len(parsed)==9
        for values in parsed:
            nf,n,q,l,h,ii,count=map(int,values)
            assert q==max(1,n) and (l,h,ii,count)==(q+11+nf,q+12+nf,q+13+nf,16)
        event.append(dict(NF_EX0=mode,completed=144,mismatches=0,clock_ns=8,CK2Q_ns=1,per_n=parsed))
    coverage=structural(coverage_paths)
    assert all(coverage[k]['total']>0 for k in ('v_line','v_branch','v_toggle'))
    summary=dict(status='PASS_W14_01_THROUGH_06_ONLY',date_local='2026-10-18',release_id=lock['release_id'],
        release_sha256=sha(R/'rtl/production_freeze.json'),matrix_freeze_sha256=sha(O/'matrix_freeze.json'),
        producer_sha256=sha(Path(__file__)),milestones={f'W14-{n:02}':'PASS_SCOPED' for n in range(1,7)},
        fused_main=rows,total_f_completed=sum(r['completed'] for r in rows),
        total_f_reset_aborted=sum(r['reset_aborted'] for r in rows),mismatches=0,
        total_stage_checks=sum(r['stage_checks'] for r in rows),
        pilots=dict(full_count=35,fast_count=9,completed=880000),
        accuracy_pilot=load(O/'accuracy/python_check.json'),counter_microtest='PASS',
        audit_negative_tests=9,negative_failure_replay=load(O/'replay_test/summary.json'),
        corners=corners,event_protocol=event,full_coverage_companions=companions,
        preliminary_F_structural_coverage=coverage,
        tools=dict(verilator=(O/'verilator.txt').read_text().strip(),compiler=(O/'compiler.txt').read_text().splitlines()[0],
                   modelsim=(O/'event_protocol/version.log').read_bytes().decode('utf-16').strip()),
        issues=[
            'No RTL/L1/oracle/constraint modification; no numerical or protocol mismatch in acceptance jobs.',
            'NF EX0 has one scoped unused-port lint waiver, source-line18 sbm_shift_comb; raw strict warning retained, no coverage excluded.',
            'Harness repairs and collector failures retained: parameter literal width; declaration order; complete failure packet; NaR decoding; Python no-fraction decode; loss of tiny errors in floating subtraction corrected with exact integer error grid.',
            'Full structural companion runs kept separate from line-only numerical90M; AC04 closure not claimed.',
            'Functional candidate-bin reachability and 100percent closure remain W14-08; no unhit bin silently waived.',
        ],
        remaining=['W14-07 NF250M main','W14-08 AC04 closure NF/F','W14-09 final paired accuracy',
                   'W14-10 comparator10M','W14-11 final audit/handoff','W14-12 exact/AC02 separate'],
        limits='Correctness/protocol verification only; not all W14/Gate4, board signoff or new Fmax/STA measurement')
    dump(O/'summary.json',summary)
    table='\n'.join(f"| {r['n']} | {r['completed']:,} | {r['reset_aborted']:,} | 0 | {r['near_before_percent']:.5f}% | {r['near_after_percent']:.5f}% | {r['valid_latency_min']}–{r['valid_latency_max']} | {r['seconds']:.3f} |" for r in rows)
    section=f'''

### 8.33. Nghiệm thu W14-01 đến W14-06 — 18/10/2026

**Hoàn thành phạm vi W14-01..06; chưa hoàn thành toàn tuần14.** Sinh viên đã yêu cầu
thực hiện tuần tự đến W14-06 theo bảng TC hiện có. Release `{lock['release_id']}`,
38 module+header, L1/oracle và constraints giữ nguyên; audit release và matrix trước/sau main PASS.
Canonical `results/week14/summary.json`, `matrix_freeze.json`, `pilot_qualification.json`.

| Mốc | Bằng chứng / kết quả |
| --- | --- |
| W14-01 | Review clock/reset bridge/two-FF release/startup/CE/context/commit/reset-abort; same-hash routed CDC Safely Timed; XDCH-2 là I/O budget. Không gọi đây là formal RDC hoặc board signoff |
| W14-02 | Counter micro-tests và schema regime/sign, popcount, iteration/config, packer, delta/mode, fused anchor/sign/delta/LZC. Định nghĩa completed/abort/near riêng; reachability/100% closure tiếp tục W14-08 |
| W14-03 | Harness fixed n/OPS; failure có input/C_eff/config/state/expected/actual/flags; executable âm tính riêng bị bắt và replay đúng packet; audit từ chối9 lỗi metadata/count/status/log/hash |
| W14-04a | 35 full-instrumentation pilot×20k +9 F fast pilot×20k =880.000 completed,0 mismatch; comparator EX0 đã có pilot, chưa main |
| W14-04b | 9×100k accuracy samples, Python Fraction kiểm1024/n=9216 ca; kiểm reference RNE, error/threshold/ULP/bộ đếm. Directed128 tách random; chưa phải accuracy final W14-09 |
| W14-05 | Matrix freeze350M dự kiến gồmF90M+NF250M+comparator10M; khóa seed/source/model/harness/binary/tool/instrumentation/pilot provenance trước main |
| W14-06a | F32/3 FW12 W32 OPS1 FLOOR/RNE, mỗi n0..8 đúng10M completed; tổng90M,0 mismatch bits/flags/state so L1 và oracle full-grid độc lập |
| W14-06b | 64 tag corner/n,9n×20k=180k completed,0 mismatch; TV-FUSE01/02,delta±28/29,LZC>15,C=−A×B,zero/NaR. Model golden3,9375/−4,5625 xác nhận n1..8; n0 theo P_hat partial |
| W14-06c | Reset/stall/order/context/commit/invalid/latency kiểm mỗi job; ModelSim companion mới8ns/CK2Q1ns đo L/H/II không stall cho9n, F144 vàNF-EX0144 completed,0 mismatch; OPS2/3 đều bị chặn khi idle |

**F main riêng từng n:** accepted=completed+reset-aborted; mẫu abort không cộng vào10M
hoặc mẫu số near. Near-before/after tính trên C_eff thực tế, specials không vào tử số.

| n | Completed | Reset-abort | Mismatch | Near trước cut | Near sau cut | L_valid min–max | Wall seconds |
| --- | --- | --- | --- | --- | --- | --- | --- |
{table}

Tổng **90.000.000 completed / {summary['total_f_reset_aborted']:,} reset-abort /0 mismatch**;
{summary['total_stage_checks']:,} stage observations kiểm prepack/F1..F5.
PRNG mt19937_64, seed F main/pilot2026101800+n; mọi điểm NF/comparator và accuracy có seed
trong matrix. Tool: {summary['tools']['verilator']}; {summary['tools']['compiler']}; ModelSim10.1d.
Wall seconds là thời gian chạy mô phỏng phần mềm, không phải latency phần cứng hoặc phép đo throughput FPGA.

**Instrumentation và hiệu năng:** pilot full coverage khoảng4–5k completed/s, F line-only
pilot khoảng70–87k/s. Main số học dùng binary line-only đã pilot riêng, vẫn kiểm counters
chức năng và từng stage trên toàn90M. Sau freeze chạy companion full line/branch/toggle20k/n,
tổng180k completed,0 mismatch. Chỉ các companion full-instrumentation final được gộp để
đánh giá structural coverage; không dùng toggle pilot hoặc trộn binary line-only để nhận AC04.
Raw điểm coverage hiện có: `{json.dumps(coverage)}`. Đây là số điểm Verilator instrumented
toàn hierarchy RTL đang hoạt động; chưa phải closure AC04/functional100% của W14-08.

**Các lỗi công cụ kiểm thử đã sửa, giữ lịch sử:** raw CLI EXACT_EN truyền32bit làm lint
WIDTHTRUNC; đổi sang literal1bit, không sửa RTL. Comparator EXACT_EN0 prune y_mant[26:16]
tại sbm_shift_comb.sv:18: dùng waiver đúng warning/file/line cho riêng feature này;
raw warning và cấu hình được giữ, không tắt coverage. Build cycle dùng --no-timing nên
ASSIGNDLY của CK2Q được ghi là expected; strict lint --timing và mô phỏng4-state kiểm riêng.
Collector mới từng lỗi NaR/decoder không còn fraction và mất sai số khi trừ floating-point;
đã giữ các phiên lỗi trong repairs, tính hiệu và strict threshold bằng lưới số nguyên,
đối chuẩn Python Fraction đạt. Long double chỉ dùng biểu diễn metric/NMSE/percentile;
phân loại ngưỡng và thắng/thua/hòa dùng số nguyên, NaR/r=0 báo riêng.

Không sửa/reseed corpus sau khi thấy FAIL RTL; chưa có mismatch RTL. Các sửa harness diễn ra
trước matrix freeze, pilot chịu ảnh hưởng được chạy lại; binary/script main đã khóa hash.
Protocol/golden companion thêm sau freeze có manifest nguồn riêng, không sửa đầu vào main.

**Lệnh từ Posit_MAC (WSL bash --noprofile --norc):**

```bash
bash scripts/build_week14.sh
python3 scripts/run_week14_jobs.py pilot
python3 scripts/run_week14_jobs.py pilot_fast
bash scripts/pilot_week14_accuracy.sh
bash scripts/run_week14_corner.sh
bash scripts/check_week14_replay.sh
python3 scripts/freeze_week14.py
python3 scripts/run_week14_jobs.py main
python3 scripts/run_week14_jobs.py coverage_final
```

```powershell
python scripts/audit_rtl_release.py --self-test
powershell -NoProfile -File scripts/run_week14_protocol.ps1
```

Generator/snapshot phải chuẩn bị trước build; các producer từ chối root/attempt đã có.
Các lệnh trên ghi lại workflow đã chạy, không chạy lại vào evidence cũ. Khi tái lập dùng
snapshot nguồn và output mới/bản sao workspace; không sửa hash matrix cũ để ép replay PASS.
README hướng dẫn và archive chứa exact source/build/command/seed/log/raw counters;
binaries/cache/waves không đưa Git. Runtime/build/peak RSS/dung lượng output từng pilot
có trong execution.json; không đồng nhất peak RSS này với dung lượng Vivado/P&R.

**Còn lại:** W14-07 NF main250M; W14-08 coverage closure/reachability; W14-09 paired accuracy
final; W14-10 comparator10M; W14-11 audit/bàn giao. Exact/AC02/W14-12 vẫn riêng và chưa miễn.
RTL vẫn khóa120,48MHz A35T/Explore theo STA cũ; phiên này không chạy STA mới hoặc XCVU9P.
Không gọi hoàn thành toàn W14, paired PPA/Gate4 hoặc board signoff.
'''
    p=R.parent/'doc/Optimization.md';assert '### 8.33.' not in p.read_text(encoding='utf-8')
    edit(p,lambda text:text+section)
    def progress(text):
        text=text.replace('| 14 | Regression và accuracy paired NF/F | không |', '| 14 | Regression và accuracy paired NF/F | processing |')
        text=text.replace('09–15/11: nghiệm thu đúng riêng từng bản, coverage và corpus chung. Trình tự review → harness → pilot → freeze → main → closure tại mục3.2; chưa thực thi TC W14',
                          'Đã chạy sớm18/10: W14-01..06 đạt,F90M/0 mismatch. Còn NF main,AC04,paired accuracy,comparator và audit cuối; xem mục3.2/Optimization8.33')
        start='**Đầu vào tham chiếu:**'
        lines=text.splitlines()
        for i,line in enumerate(lines):
            if line.startswith(start):lines[i]='**Đầu vào hiện hành:** `POSIT_MAC_RTL_20261018_OPT12_120`; đã được sinh viên chỉ đạo chạy đến W14-06. Source/matrix/binary freeze và kiểm thử tại results/week14, chi tiết Optimization8.33. Không dùng checkpoint100MHz hoặc10M aggregate cũ thay final từng n.'
            if line.startswith('Mã W14-01..11 trùng'):lines[i]=line.replace('Tất cả mục dưới là kế hoạch, chưa ghi nhận hoàn thành.','W14-01..06 đã hoàn thành phạm vi ngày18/10; W14-07..12 còn mở.')
            if line.startswith('| ') and re.match(r'\| [1-6] \| W14-0[1-6] \|',line):
                lines[i]=line.rstrip()[:-1]+' **Đã đạt18/10**, evidence Optimization8.33/results/week14. |'
            if line.startswith('- **Hiện tại18/10:**'):lines[i]='- **Hiện tại18/10:** W14-01..06 PASS phạm vi đã chốt,F90M/0 mismatch, near trước/sau cut≥30% ở cả9n; bước kế tiếp W14-07. W14-08 AC04 và các bước cuối chưa đóng; toàn tuần14 giữ processing.'
        text='\n'.join(lines)+'\n'
        marker='### 4.18. Mẫu cập nhật tiếp theo'
        row='| 10 | Thực hiện W14-01 đến W14-06 | Review/counters/harness,pilot,accuracy calibration và matrix freeze đạt; MAC F90M/0 mismatch,corner/ModelSim đạt. Còn W14-07..12; chi tiết Optimization8.33 | ✅ |\n\n'
        return text.replace(marker,row+marker,1)
    edit(R/'docs/TIEN_DO_DO_AN.md',progress)
    # Update the short current workflow notices; historical promotion counts remain historical.
    for name in ('README.md','rtl/README.md','syn/README.md','scripts/README.md','docs/HUONG_DAN_CHAY_WSL_MODELSIM.md'):
        edit(R/name,lambda text:text.replace('Producer lịch sử không dùng để refreeze/ghi đè release mới; W14 chưa thực thi.',
            'Producer lịch sử không dùng để refreeze/ghi đè release mới. W14-01..06 đã đạt: F90M/0 mismatch, pilot/accuracy calibration/matrix freeze; W14-07..12 còn mở (Optimization8.33).'))
    edit(R/'l1/PLAN.md',lambda text:text.replace('W14 final per-n/AC04 chưa chạy.',
        'W14-01..06 đã đạt:F90M/0 mismatch và counters/pilot/accuracy calibration/matrix freeze; NF final/AC04/accuracy/comparator/audit cuối còn mở (Optimization8.33).'))
    edit(R/'SPEC_Posit_MAC_IP.md',lambda text:text.replace('W14 final per-n/AC04, paired accuracy/PPA và board signoff chưa hoàn thành.',
        'W14-01..06 đạt18/10 trên cùng release:F90M/0 mismatch,review/counters/harness/pilot/calibration/freeze; corner/ModelSim đạt. NF final,AC04,paired accuracy/comparator/audit cuối vẫn mở; chưa paired PPA/board signoff. Xem Optimization8.33 và results/week14/summary.json.'))
    print('W14-01..06 final audited:',summary['total_f_completed'],'completed,0 mismatch; later gates remain open')


if __name__=='__main__':main()
