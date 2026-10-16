"""Collect OPT-01 proof, archive compact evidence, or package the scoped backup."""
from pathlib import Path
import csv
import hashlib
import json
import re
import shutil
import statistics
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/prepack_refactor_20261016'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(path):
    raw = (OUT/path).read_bytes()
    return raw.decode('utf-16' if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig', errors='replace')


def collect():
    leaf = read('leaf/simulate.log')
    assert 'PREPACK ALL PASS' in leaf
    suites = [list(map(int,m)) for m in re.findall(r'PREPACK PASS F=(\d+) FW=(\d+) EN=(\d+) AW=(\d+) SW=(\d+) FIN=(\d+) checks=(\d+)',leaf)]
    assert len(suites)==len(json.loads(read('cases.json')))==70
    lint = list((OUT/'lint').glob('case_*.log'))
    assert len(lint)==70 and all(not re.search(r'%Warning|%Error',p.read_text()) for p in lint)
    for name,digest in json.loads(read('source_sha256.json')).items():
        assert sha((ROOT/name).read_bytes())==digest, name
    for name,digest in json.loads(read('verification_inputs.json')).items():
        assert sha((ROOT/name).read_bytes())==digest, name
        assert sha((OUT/'verification_inputs'/Path(name).name).read_bytes())==digest
    for name,digest in json.loads(read('modelsim/fixture_sha256.json')).items():
        assert sha((OUT/'fixtures'/name).read_bytes())==digest
    original = read('source/baseline/mul_prepack_norm_comb.sv')
    current = (ROOT/'rtl/multiplier/mul_prepack_norm_comb.sv').read_text()
    header = lambda s:re.sub(r'\s+','',s[s.index('module mul_prepack_norm_comb #('):].split(');',1)[0])
    assert header(original)==header(current), 'Interface or public parameters changed'
    production=(ROOT/'rtl/multiplier/mul_prepack_norm_comb.sv').read_bytes()
    original_bytes=(OUT/'source/baseline/mul_prepack_norm_comb.sv').read_bytes()
    candidate_bytes=(OUT/'source/candidate/mul_prepack_norm_comb.sv').read_bytes()
    assert production in (original_bytes,candidate_bytes)
    production_variant='baseline' if production==original_bytes else 'candidate'
    candidate_path=ROOT/'rtl/candidates/multiplier/mul_prepack_norm_comb.sv'
    if candidate_path.exists():assert candidate_path.read_bytes()==candidate_bytes
    # Every other production RTL module/header is frozen, so no pipeline change.
    for line in (ROOT/'rtl/production.f').read_text().splitlines():
        if not line or line.endswith('/mul_prepack_norm_comb.sv'):continue
        assert (ROOT/line).read_bytes()==(OUT/'source/baseline'/Path(line).name).read_bytes(), line
    pilots=[]
    strict_main=0
    for nb,es,goal in [(8,0,20000),(16,1,20000),(32,2,20000),(32,3,100000)]:
        d=json.loads(read(f'nf/{nb}_{es}/pilot_summary.json'))
        assert d['completed']==goal and d['mismatches']==0
        assert d['reset_busy'] and d['reset_stalled'] and d['long_stalls'] and d['acc_commits'] and d['clears']
        assert min(d['bins'])>0
        log=read(f'nf/{nb}_{es}/lint_en1.log')
        assert not re.search(r'%Warning|%Error',log)
        strict_main+=1
        pilots.append(d)
    large=json.loads(read('nf/32_3/acceptance_summary.json'))
    assert large['completed']==10000000 and large['mismatches']==0
    old=json.loads(read('frozen_corpus_reference.json'))
    assert large==old, 'Frozen-corpus functional counters diverged'
    baseline_warning=read('baseline_disabled_lint.log')
    candidate_warning=read('nf/32_2/lint_en0.log')
    expected="Bits of signal are not used: 'y_mant'[27:16]"
    assert expected in baseline_warning and expected in candidate_warning
    assert 'sbm_shift_comb.sv' in baseline_warning and 'sbm_shift_comb.sv' in candidate_warning
    modelsim=[]
    for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
        log=read(f'modelsim/simulate_{nb}_{es}.log')
        assert not re.search(r'\*\*\s+(Error|Fatal):',log)
        m=re.search(r'W11 MODELSIM PASS NB=(\d+) ES=(\d+) rows=(\d+) completed=(\d+) aborted=(\d+) stalls=(\d+) mismatches=0',log)
        assert m and int(m[4])==20736
        modelsim.append(list(map(int,m.groups())))
    assert '41024 checks, 0 mismatches' in read('modelsim/lod_simulate.log')
    rows=[]
    for part in ['xc7a35tcpg236-1','xc7a100tcsg324-1']:
        assert 'PREPACK_PPA_COMPLETE' in read(f'ppa/{part}/console.log')
        lock=json.loads(read(f'ppa/{part}/driver_sha256.json'))
        for name,digest in lock.items():assert sha((ROOT/name).read_bytes())==digest
        with (OUT/'ppa'/part/'metrics.csv').open() as f:part_rows=list(csv.DictReader(f))
        assert len(part_rows)==6
        for d in part_rows:
            for k in ['lut','ff','carry4','dsp','bram','levels','latches','unrouted']:d[k]=int(d[k])
            for k in ['slack','hold','delay_ns','logic_ns','route_ns','norm_slack','norm_delay_ns']:d[k]=float(d[k])
            assert d['latches']==d['unrouted']==0
            d['part']=part
            d['sta_mhz']=1000/(10-d['slack'])
            d['norm_sta_mhz']=1000/(10-d['norm_slack'])
            d['r2r_meets_100MHz']=d['slack']>=0 and d['hold']>=0
            id_=d['variant']+'_'+d['strategy']
            d['endpoints']=read(f'ppa/{part}/{id_}/endpoints.txt').strip().splitlines()
            report=read(f'ppa/{part}/{id_}/timing.rpt')
            # Preserve all setup/hold/pulse statistics, including I/O caveats.
            block=report[report.index('WNS(ns)'):]
            number_line=next(l for l in block.splitlines()[1:] if re.match(r'^\s*-?\d+\.\d+\s',l))
            d['timing_summary_columns']=number_line.split()
            rows.append(d)
    comparison=[]
    for part in sorted({d['part'] for d in rows}):
        item=dict(part=part)
        for variant in ['baseline','candidate']:
            group=[d for d in rows if d['part']==part and d['variant']==variant]
            item[variant]={k:dict(min=min(d[k] for d in group),median=statistics.median(d[k] for d in group),max=max(d[k] for d in group))
                           for k in ['lut','ff','carry4','sta_mhz','norm_delay_ns','norm_slack','norm_sta_mhz']}
            item[variant]['r2r_100MHz_passes']=sum(d['r2r_meets_100MHz'] for d in group)
        item['sta_mhz_change_pct']=100*(item['candidate']['sta_mhz']['median']/item['baseline']['sta_mhz']['median']-1)
        item['lut_change_pct']=100*(item['candidate']['lut']['median']/item['baseline']['lut']['median']-1)
        item['paired_strategies']=[]
        for strategy in ['default','explore','runtime']:
            b=next(d for d in rows if d['part']==part and d['variant']=='baseline' and d['strategy']==strategy)
            a=next(d for d in rows if d['part']==part and d['variant']=='candidate' and d['strategy']==strategy)
            item['paired_strategies'].append(dict(strategy=strategy,sta_mhz_change_pct=100*(a['sta_mhz']/b['sta_mhz']-1),lut_change=a['lut']-b['lut'],ff_change=a['ff']-b['ff']))
        comparison.append(item)
    inputs={}
    for pattern in ['scripts/*prepack*','tb/*prepack*.sv']:
        for p in ROOT.glob(pattern):
            if p.is_file():inputs[p.relative_to(ROOT).as_posix()]=sha(p.read_bytes())
    inputs['rtl/multiplier/mul_prepack_norm_comb.sv']=sha(production)
    if candidate_path.exists():inputs[candidate_path.relative_to(ROOT).as_posix()]=sha(candidate_bytes)
    result=dict(status='PASS_OPT01_SCOPE',date='2026-10-16',scope='OPT-01 experiment only; no OPT-02/03 or pipeline change',production_variant=production_variant,
                decision='Retain production baseline; candidate is bit-exact but provides no consistent timing benefit across matched Artix7 runs.' if production_variant=='baseline' else 'Trial candidate; no final baseline/timing adoption claim.',
                timing_target_100MHz_met=all(d['r2r_meets_100MHz'] for d in rows),
                leaf_checks=sum(r[-1] for r in suites),leaf_suites=suites,leaf_strict_lint=70,main_nf_strict_lint=strict_main,
                pilots=pilots,main=large,main_matches_prior_corpus_counters=True,modelsim_checks=82944,modelsim_suites=modelsim,
                modelsim_compat='Private LOD typedef casts replace POS_W/S sized casts for ModelSim10.1d; 41024 LOD checks passed. Production LOD unchanged.',
                disabled_feature_note="Whole-NF32/2 EXACT_EN=0 has pre-existing sbm_shift y_mant[27:16] unused warning. Reproduced on both baseline and candidate; not fixed or accepted as a new NF profile. Leaf EXACT_EN=0 is verified in supported cfg_mode=1; cfg_mode=0 is rejected by parent and excluded from equivalence.",
                ppa_rows=rows,comparison=comparison,input_sha256=inputs,
                tools=dict(verilator=read('verilator.txt').strip(),compiler=read('compiler.txt').strip(),modelsim=read('modelsim/version.log').strip(),vivado=read('ppa/xc7a35tcpg236-1/tool.txt').strip()),
                conditions=dict(NB=32,ES=3,FRAC_W=12,EXACT_EN=1,OPS_EN=1,period_ns=10,uncertainty_ns=.1,input_min_max_ns=2.5,output_max_ns=.5,output_min_ns=0,
                                directives=['Default','Explore','RuntimeOptimized placement + Default routing']),
                limits='Binary valid-input equivalence, not formal X/Z equivalence. F_IN reduced-width tests only preserve legacy mapping and do not approve a new precision profile. Xilinx OOC/synthetic I/O; STA estimates are not board Fmax. Timing summary contains I/O/recovery/removal constraints; R2R100MHz label is not full board signoff. No fused/PPA paired-architecture comparison or next pipeline stage implemented.',
                commands=['bash --noprofile --norc scripts/verify_prepack_refactor.sh','bash --noprofile --norc scripts/verify_prepack_nf.sh',
                          'powershell -NoProfile -File scripts/verify_prepack_modelsim.ps1','powershell -NoProfile -File scripts/run_prepack_refactor_ppa.ps1 -Part <part>',
                          'python scripts/audit_prepack_refactor.py collect'])
    if (OUT/'summary.json').exists():
        assert json.loads(read('summary.json'))==result, 'Frozen summary differs; preserve original evidence'
    else:
        (OUT/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(dict(status=result['status'],leaf_checks=result['leaf_checks'],main_completed=large['completed'],comparison=comparison),indent=2))


def archive():
    assert json.loads(read('summary.json'))['status']=='PASS_OPT01_SCOPE'
    assert not (OUT/'evidence.zip').exists()
    skip={'obj_fast','obj_dir','work','tmp','.Xil','appdata','localappdata','__pycache__','-p'}
    suffix={'.sv','.vh','.hpp','.h','.cpp','.vlt','.tcl','.ps1','.py','.sh','.json','.txt','.rpt','.log','.csv','.sha256','.dat','.do'}
    files={}
    with zipfile.ZipFile(OUT/'evidence.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(OUT.rglob('*')):
            if not p.is_file() or skip.intersection(p.relative_to(OUT).parts) or p.suffix not in suffix:continue
            if p.name in {'archive_manifest.json'}:continue
            data=p.read_bytes();name=p.relative_to(OUT).as_posix();files[name]=sha(data);z.writestr(name,data)
    with zipfile.ZipFile(OUT/'evidence.zip') as z:
        assert z.testzip() is None and all(sha(z.read(k))==v for k,v in files.items())
    receipt=dict(status='PASS',archive_sha256=sha((OUT/'evidence.zip').read_bytes()),bytes=(OUT/'evidence.zip').stat().st_size,files=files)
    (OUT/'archive_manifest.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('ARCHIVE_PASS',len(files),receipt['bytes'])


def restore():
    receipt=json.loads(read('archive_manifest.json'))
    assert sha((OUT/'evidence.zip').read_bytes())==receipt['archive_sha256']
    with zipfile.ZipFile(OUT/'evidence.zip') as z:
        assert set(z.namelist())==set(receipt['files'])
        for name,digest in receipt['files'].items():
            path=OUT/name;assert path.resolve().is_relative_to(OUT.resolve())
            assert sha(z.read(name))==digest
            if path.exists():assert sha(path.read_bytes())==digest,f'Preserve different existing file: {name}'
        for name in receipt['files']:
            path=OUT/name
            if not path.exists():path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(name))
    print('RESTORE_PASS')


def package():
    b=ROOT/'scratch/github_week9_backup'
    def git(*args):return subprocess.run(['git',*args],cwd=b,check=True,capture_output=True).stdout
    assert Path(git('rev-parse','--show-toplevel').decode().strip()).resolve()==b.resolve()
    assert git('branch','--show-current').decode().strip()=='main'
    assert git('remote','get-url','origin').decode().strip()=='https://github.com/huytruong2k5t/Project.git'
    assert not git('status','--porcelain'),'Preserve user staging/local changes'
    assert json.loads(read('summary.json'))['status']=='PASS_OPT01_SCOPE'
    a=json.loads(read('archive_manifest.json'));assert sha((OUT/'evidence.zip').read_bytes())==a['archive_sha256']
    paths={'.gitattributes','SPEC_Posit_MAC_IP.md','l1/PLAN.md','rtl/README.md','scripts/README.md','docs/TIEN_DO_DO_AN.md','docs/HUONG_DAN_CHAY_WSL_MODELSIM.md','rtl/multiplier/mul_prepack_norm_comb.sv'}
    candidate=ROOT/'rtl/candidates/multiplier/mul_prepack_norm_comb.sv'
    if candidate.exists():paths.add(candidate.relative_to(ROOT).as_posix())
    for pattern in ['scripts/*prepack*','tb/*prepack*.sv']:
        paths.update(p.relative_to(ROOT).as_posix() for p in ROOT.glob(pattern) if p.is_file())
    paths.update(p.relative_to(ROOT).as_posix() for p in OUT.iterdir() if p.is_file() and p.suffix in {'.json','.zip','.sv','.sha256'})
    paths.update(p.relative_to(ROOT).as_posix() for p in (OUT/'source').rglob('*') if p.is_file())
    payload=[]
    for relative in sorted(paths):
        src=ROOT/relative;assert src.is_file() and src.resolve().is_relative_to(ROOT.resolve())
        if src.suffix=='.md':
            old=subprocess.run(['git','show','HEAD:Posit_MAC/'+relative],cwd=b,capture_output=True).stdout
            raw=src.read_bytes().replace(b'\r\n',b'\n')
            if old.count(b'\r\n')>old.count(b'\n')//2:raw=raw.replace(b'\n',b'\r\n')
            src.write_bytes(raw)
        dst=b/'Posit_MAC'/relative;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst);payload.append(dst.relative_to(b).as_posix())
    t=(ROOT/'docs/TIEN_DO_DO_AN.md').read_text(encoding='utf-8')
    for name in ['SPEC_Posit_MAC_IP.md','l1/PLAN.md','l1/README.md']:t=t.replace(f'(../{name})',f'(../Posit_MAC/{name})')
    t=t.replace('(HUONG_DAN_CHAY_WSL_MODELSIM.md)','(../Posit_MAC/docs/HUONG_DAN_CHAY_WSL_MODELSIM.md)')
    (b/'doc/TIEN_DO_DO_AN.md').write_text(t,encoding='utf-8');payload.append('doc/TIEN_DO_DO_AN.md')
    (ROOT/'scratch/prepack_git_paths.txt').write_text('\n'.join(payload)+'\n')
    print('PACKAGE_PASS',len(payload))


if __name__=='__main__':
    assert len(sys.argv)==2 and sys.argv[1] in {'collect','archive','restore','package'}
    globals()[sys.argv[1]]()
