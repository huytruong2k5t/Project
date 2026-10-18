"""Prepare W14 tests around the locked release. No RTL/model edits or refreeze."""
from pathlib import Path
import hashlib
import json
import re
import shutil
from audit_rtl_release import validate

R=Path(__file__).resolve().parents[1]
O=R/'results/week14'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8',newline='\n')


def replace(text, old, new):
    assert text.count(old)==1,old
    return text.replace(old,new,1)


def generate():
    f=(R/'tb/week13_fused_harness.cpp').read_text()
    f=replace(f,'constexpr uint64_t SEED = 20261015;',
              'uint64_t SEED=20261018; unsigned FIXED_N=0,FIXED_OPS=1;\n#include "week14_counters.hpp"')
    f=replace(f,'uint32_t(rng()),unsigned(i%9),unsigned((i/9)%2),bool((i/4)%2),false};',
              'uint32_t(rng()),FIXED_N,FIXED_OPS,bool((i/4)%2),false};')
    f=replace(f,'check(argc==3,"usage: harness completed_count output_prefix");',
              'check(argc==6,"usage: harness count prefix n ops seed");\n'
              '    FIXED_N=std::stoul(argv[3]); FIXED_OPS=std::stoul(argv[4]); SEED=std::stoull(argv[5]);\n'
              '    check(FIXED_N<=8&&FIXED_OPS<=1,"fixed configuration");\n'
              '    week14::Counters functional;')
    f=replace(f,'std::array<uint64_t,9> n_hits{},iteration_hits{};',
              'std::array<uint64_t,9> n_hits{},iteration_hits{};\n'
              '    Input failure_row{}; uint32_t failure_ceff=0; uint64_t failure_serial=0;\n'
              '    auto save_failure=[&](const char* reason) {std::ofstream out(prefix+".failure.json");\n'
              '        out<<"{\\\"reason\\\":\\\""<<reason<<"\\\",\\\"seed\\\":"<<SEED<<",\\\"serial\\\":"<<failure_serial\n'
              '           <<",\\\"a\\\":"<<failure_row.a<<",\\\"b\\\":"<<failure_row.b<<",\\\"c_port\\\":"<<failure_row.c\n'
              '           <<",\\\"c_eff\\\":"<<failure_ceff<<",\\\"n\\\":"<<FIXED_N<<",\\\"ops\\\":"<<FIXED_OPS<<"}\\n";};')
    f=replace(f,'const auto mul=Mul::mul(row.a,row.b,config(row));',
              'failure_row=row;failure_ceff=ceff;failure_serial=accepted;save_failure("RUNNING_CONTEXT");\n'
              '        const auto mul=Mul::mul(row.a,row.b,config(row));')
    # Keep only one compact failure context in memory/files at checkpoints, not one I/O per vector.
    f=f.replace('failure_serial=accepted;save_failure("RUNNING_CONTEXT");',
                'failure_serial=accepted; if(accepted%100000==0)save_failure("CHECKPOINT_CONTEXT");')
    f=replace(f,'++completed;++n_hits[row.n];++configs[row.n+9*row.ops+18*row.mode];',
              '++completed;++n_hits[row.n];++configs[row.n+9*row.ops+18*row.mode];\n'
              '                const auto& tr=exp.trace; const bool finite=!(exp.flags&16)&&!p.is_zero&&ceff;\n'
              '                const unsigned db=finite?unsigned(std::abs(tr.p_sf-tr.c_sf)):0;\n'
              '                const unsigned da=(tr.p_retained&&tr.c_retained)?unsigned(std::abs(int(Model::top(tr.p_retained))-int(Model::top(tr.c_retained)))):0;\n'
              '                functional.sample(finite,tr.near_before,tr.near_after,row.mode,std::min(4u,db),std::min(4u,da),\n'
              '                    tr.c_sf>tr.p_sf,p.sign!=bool(ceff>>31),week14::Counters::delta_bucket(db,26),\n'
              '                    week14::Counters::lzc_bucket(tr.left_normalize),tr.zero);')
    start=f.index('    for(auto x:n_hits) check(x>0,"missing n");')
    end=f.index('    std::cout<<"COVERAGE tail=',start)
    f=f[:start]+'    check(n_hits[FIXED_N]==completed,"mixed fixed-n run");\n'+f[end:]
    f=f.replace('check(tails&&borrows&&reset_busy&&reset_stall&&invalid&&commits&&clears,"coverage hole");',
                'check(reset_busy&&reset_stall&&invalid&&commits&&clears,"protocol coverage hole");\n'
                '    functional.write(prefix+".functional.json");')
    f=replace(f,'out<<"{\\n\\\"status\\\":\\\"PASS\\\",\\\"seed\\\":"<<SEED',
              'out<<"{\\n\\\"fixed_n\\\":"<<FIXED_N<<",\\\"fixed_ops\\\":"<<FIXED_OPS<<",\\\"status\\\":\\\"PASS\\\",\\\"seed\\\":"<<SEED')
    # Event fixture generation belongs to a separate corner/protocol job, not every 10M run.
    start=f.index('    // Event-simulator vectors use own sequential accumulator')
    end=f.index('    std::cout<<"W13 PASS',start)
    f=f[:start]+f[end:]
    # Preserve exact failing transaction for every assertion/protocol exception.
    f=replace(f,'    while(completed<goal) {','    try {\n    while(completed<goal) {')
    f=replace(f,'    check(accepted==completed+aborted,"accounting");',
              '    } catch(...) {save_failure("ASSERTION_OR_MISMATCH"); throw;}\n'
              '    check(accepted==completed+aborted,"accounting");')
    (R/'tb/week14_fused_harness.cpp').write_text(f,encoding='utf-8',newline='\n')

    nf=(R/'tb/nf_coverage_harness.cpp').read_text()
    nf=replace(nf,'#include "softposit_api.h"',
               '#include "softposit_api.h"\nunsigned FIXED_N=0,FIXED_OPS=1; uint64_t W14_SEED=20261018;')
    nf=replace(nf,'if (argc != 3) throw std::invalid_argument("harness completed_goal output_prefix");',
               'if(argc!=6)throw std::invalid_argument("harness count prefix n ops seed");\n'
               '    FIXED_N=std::stoul(argv[3]);FIXED_OPS=std::stoul(argv[4]);W14_SEED=std::stoull(argv[5]);\n'
               '    require(FIXED_N<=8&&FIXED_OPS<=1,"fixed config");')
    nf=replace(nf,'const uint64_t seed = 20261014 + 100*NB + ES;', 'const uint64_t seed=W14_SEED;')
    nf=nf.replace('dut.cfg_n=v.n; dut.cfg_ops=v.ops; dut.cfg_mode=v.mode;',
                  'dut.cfg_n=FIXED_N; dut.cfg_ops=FIXED_OPS; dut.cfg_mode=1;')
    nf=replace(nf,'for (auto count:bins) require(count>0,"missing config/control bin");',
               'require(bins[FIXED_N+9*FIXED_OPS+18]+bins[FIXED_N+9*FIXED_OPS+18+36]==completed,"mixed config");')
    nf=replace(nf,'report<<"{\\\"NB\\\":"<<NB',
               'report<<"{\\\"fixed_n\\\":"<<FIXED_N<<",\\\"fixed_ops\\\":"<<FIXED_OPS<<",\\\"NB\\\":"<<NB')
    (R/'tb/week14_nf_harness.cpp').write_text(nf,encoding='utf-8',newline='\n')
    corpus=(R/'tb/nf_coverage_corpus.hpp').read_text()
    corpus=replace(corpus,'        v.acc_clr = v.acc_mode && (serial / 72) % 11 == 0;',
                   '        v.n=FIXED_N;v.ops=FIXED_OPS;v.mode=1;\n'
                   '        v.acc_clr = v.acc_mode && (serial / 72) % 11 == 0;')
    corpus=corpus.replace('v.mode=0;', 'v.mode=1;')
    (R/'tb/week14_nf_corpus.hpp').write_text(corpus,encoding='utf-8',newline='\n')
    # The W14 copy has its own include; the frozen original corpus/header is untouched.
    p=R/'tb/week14_nf_harness.cpp'
    p.write_text(nf.replace('#include "nf_coverage_corpus.hpp"','#include "week14_nf_corpus.hpp"'),encoding='utf-8',newline='\n')


def main():
    lock=json.loads((R/'rtl/production_freeze.json').read_text());validate(lock)
    assert not O.exists(),'Preserve W14 evidence'
    O.mkdir();(O/'tmp').mkdir()
    cdc={}
    paths={'nf':'ppa','f':'ppa_f'}
    for top,folder in paths.items():
        run=R/f'results/opt120_20261018/{folder}/negate/p8300/Explore_r1'
        assert 'All paths are Safely Timed.' in (run/'cdc.rpt').read_text()
        m=(run/'methodology.rpt').read_text()
        assert set(re.findall(r'^\| (\w+-\d+)\s*\|',m,re.M))=={'XDCH-2'}
        cdc[top]={str(p.relative_to(R)):sha(p) for p in [run/'cdc.rpt',run/'methodology.rpt',run/'drc.rpt']}
    dump(O/'w14_01_review.json',dict(status='PASS_SCOPED_REVIEW',release_id=lock['release_id'],
        release_sha256=sha(R/'rtl/production_freeze.json'),evidence=cdc,
        checklist={
            'clock':'single clk; BUFG in measurement wrappers; no fabric-gated clock',
            'reset':'SPEC4.2 synchronous rst_n sampled into bridge; local async assertion/two-FF release',
            'startup':'in_ready/out_valid gated by rst_n,meta_sync2 and leaf ready/barrier',
            'context':'pair_accept captures operands/config/C_eff; pair_retire uses all three parser valids',
            'ce_stall':'elastic valid/ready banks hold data; production event regression checked output hold and order',
            'commit':'committed_q prevents repeated accumulator update while output stalled; acc_clr at accept',
            'reset_abort':'reset flushes pending/context/accumulator; accepted=completed+aborted; W14 pilot rechecks',
            'guideline_mapping':'Xilinx ASYNC_REG 2FF implements synchronizer intent; no literal Marvell ASIC cell in FPGA',
            'methodology':'XDCH-2 explained by fixed equal min/max I/O benchmark; CFGBVS/PARTPIN OOC not board pinout'},
        event_evidence='results/opt120_20261018/summary.json events.negate: NF111456/F8192,0 mismatch,8ns CK2Q1ns',
        limits='RTL/source plus existing same-hash routed CDC and four-state evidence review; not formal RDC/metastability or board signoff'))
    generate()
    matrix=[]
    for n in range(9):matrix.append(dict(id=f'f32_3_ops1_n{n}',top='f',nb=32,es=3,exact_en=0,ops=1,n=n,main_goal=10000000))
    for ops,ns in [(1,range(9)),(0,[0,1,2,3,4,5,6,8])]:
        for n in ns:matrix.append(dict(id=f'nf32_3_ops{ops}_n{n}',top='nf',nb=32,es=3,exact_en=1,ops=ops,n=n,main_goal=10000000))
    for ops in (0,1):
        for n in range(1,5):matrix.append(dict(id=f'nf32_2_ops{ops}_n{n}',top='nf',nb=32,es=2,exact_en=1,ops=ops,n=n,main_goal=10000000))
    matrix.append(dict(id='nf32_3_ex0_ops1_n3',top='nf',nb=32,es=3,exact_en=0,ops=1,n=3,main_goal=10000000))
    for i,row in enumerate(matrix):row.update(seed=2026101800+i,pilot_goal=20000,scheme='FLOOR',rounding='RNE')
    dump(O/'matrix_draft.json',dict(release_id=lock['release_id'],jobs=matrix,
        authorization='User requested sequential W14-01..06 against existing TC scope on18/10/2026; no new TC approval needed'))
    schema=dict(status='DEFINED_NOT_COVERAGE_CLOSED',near_denominator='all completed incl specials, excluding reset aborts',
        near_before='both finite nonzero product/C_eff, different signs, abs(sf_product-sf_C)<=4',
        near_after='same test on retained leading positions, both retained nonzero; independent before/after counters',
        fused_cross=dict(shape=[2,2,5,5],anchor='P on scale tie; C only when c_sf>p_sf',
            signs=['same','different'],delta=[0,1,'2..7','8..FRAC_MAX+2','>FRAC_MAX+2'],lzc=[0,1,'2..4','5..15','>15'],
            specials='exclude zero operand/NaR from cross; exact zero sum separate counter',
            universe=100,structurally_impossible='same-sign with LZC>0:40 bins; no cancellation on positive-magnitude sum',
            unresolved='other60 bins retained pending reachability review at W14-08; unhit bins never silently waived'),
        other_bins=['regime/sign256 for32bit','run/polarity61','popcount6','iteration/mode','flags5','delta/mode10',
                    'NF adder70 candidate bins','packer7 each boundary','n/ops/acc_mode/config validity'],
        structural=dict(instrumentation='Verilator --coverage line+branch+toggle, full active top hierarchy; no coverage_off filters',
                        closure='W14-08 only: line>=95,branch>=90,toggle>=85; no requirement to hit every bin in pilot'))
    dump(O/'coverage_policy.json',schema)
    # Common immutable source snapshot for pilot. Main matrix will bind it only after all pilots pass.
    src=O/'source'
    names=set(lock['production_files'])|{'rtl/posit_mac.vh','rtl/production.f','rtl/production_freeze.json',
        'tb/week14_fused_harness.cpp','tb/week14_nf_harness.cpp','tb/week14_nf_corpus.hpp','tb/week14_counters.hpp',
        'tb/week13_fused_tb.sv','tb/nf_coverage.vlt','l0/softposit_api.h','l0/libsoftposit.so'}
    names.update(p.relative_to(R).as_posix() for p in (R/'tb').glob('*.hpp'))
    names.update(p.relative_to(R).as_posix() for p in (R/'l1/include').glob('*.hpp'))
    for name in sorted(names):
        dest=src/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(R/name,dest)
    dump(O/'pilot_source.json',dict(status='SNAPSHOT_BEFORE_BUILD_AND_PILOT',release_sha256=sha(R/'rtl/production_freeze.json'),
         source_sha256={p.relative_to(src).as_posix():sha(p) for p in src.rglob('*') if p.is_file()},
         matrix_sha256=sha(O/'matrix_draft.json'),coverage_policy_sha256=sha(O/'coverage_policy.json')))
    print('W14-01 scoped review PASS; W14-02/03 definitions and pilot snapshot prepared, execution not yet PASS')


if __name__=='__main__':main()
