#include <fstream>
#include <iostream>
#include <stdexcept>
#include "posit_fused_window.hpp"
#include "../../tb/week12_corpus.hpp"
#include "../../tb/week12_fused_reference.hpp"
#include "../../tb/week11_model.hpp"

// Arithmetic separation only. This is not final week14 accuracy/distribution signoff.
int main(int argc,char**argv) try {
    if (argc!=4) throw std::invalid_argument("usage: test_week12_accuracy corpus samples report.json");
    using O=week12_reference::Oracle<32,3>;
    const uint64_t count=std::stoull(argv[2]);
    std::ifstream in(argv[1],std::ios::binary);
    if (!in || count<100000) throw std::runtime_error("accuracy corpus");
    l1::FusedWindowAccumulator<32,3,12,32> fused;
    uint32_t nf_state=0,ideal_state=0;
    uint64_t product_approx_differences=0,window_differences=0;
    uint64_t standalone=0,standalone_f_ideal=0,standalone_nf_ideal=0;
    uint64_t seq_f_ideal=0,seq_nf_ideal=0,acc_steps=0;
    for (uint64_t i=0;i<count;++i) {
        week12::Case row{};in.read(reinterpret_cast<char*>(&row),sizeof(row));
        if (!in) throw std::runtime_error("short accuracy corpus");
        const bool mode=row.control&1,clear=row.control&2;
        if (row.control&4) {fused.reset();nf_state=0;ideal_state=0;}
        const uint32_t ceff=mode?(clear?0:uint32_t(fused.value())):row.c;
        l1::IterConfig cfg;cfg.n=row.n;cfg.ops=row.ops;cfg.rounding=l1::RoundMode::RNE;
        const auto p=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,cfg).prepack;
        const unsigned incoming=p.is_zero||p.is_nar?0:
            ((p.input_cut||p.iteration_cut||p.term_cut)?2u:0u)|(p.iteration_cut?1u:0u);
        const auto ref=O::add(p,ceff,incoming);
        const auto ideal_p=O::product(row.a,row.b);
        const auto ideal_same_c=O::add(ideal_p,ceff);
        const auto actual=fused.step(row.a,row.b,row.c,mode,clear,cfg);
        window_differences+=actual.bits!=ref.bits;
        if (actual.bits!=ref.bits || actual.flags!=ref.flags) throw std::runtime_error("accuracy F correctness");
        product_approx_differences+=ref.bits!=ideal_same_c.bits;
        const uint32_t nf_c=mode?(clear?0:nf_state):row.c;
        const uint32_t ideal_c=mode?(clear?0:ideal_state):row.c;
        const auto nf=week11::Model<32,3,12>::mac(row.a,row.b,nf_c,false,row.n,row.ops);
        const auto ideal_sequence=O::add(ideal_p,ideal_c);
        if (mode) {
            ++acc_steps;seq_f_ideal+=actual.bits!=ideal_sequence.bits;seq_nf_ideal+=nf.bits!=ideal_sequence.bits;
            ideal_state=ideal_sequence.bits;nf_state=nf.bits;
        } else {
            ++standalone;standalone_f_ideal+=actual.bits!=ideal_sequence.bits;standalone_nf_ideal+=nf.bits!=ideal_sequence.bits;
        }
    }
    std::ofstream out(argv[3]);
    if (!out) throw std::runtime_error("accuracy report");
    out<<"{\n\"status\":\"PASS_ARITHMETIC_SEPARATION_ONLY\",\"cases\":"<<count
       <<",\"window_F_W_F_ref_bit_differences\":"<<window_differences
       <<",\"product_approx_F_ref_vs_Ideal_same_F_Ceff_bit_differences\":"<<product_approx_differences
       <<",\"standalone_common_inputs\":"<<standalone
       <<",\"standalone_F_vs_Ideal_bit_differences\":"<<standalone_f_ideal
       <<",\"standalone_NF_vs_Ideal_bit_differences\":"<<standalone_nf_ideal
       <<",\"acc_sequence_steps\":"<<acc_steps
       <<",\"acc_sequence_F_vs_own_Ideal_bit_differences\":"<<seq_f_ideal
       <<",\"acc_sequence_NF_vs_own_Ideal_bit_differences\":"<<seq_nf_ideal
       <<",\"limits\":\"Bit differences are not relative-error percentages. Final mean/P99/ULP, applications and RTL paired regression remain week14.\"}\n";
    std::cout<<"W12 ACCURACY SEPARATION PASS cases="<<count<<" window_differences="<<window_differences
             <<" product_approx_differences="<<product_approx_differences<<'\n';
} catch (const std::exception& error) {std::cerr<<"FAIL "<<error.what()<<'\n';return 1;}
