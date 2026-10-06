#include "paper_anchor_study.hpp"
#include <fstream>
uint64_t checks=0;
void check(bool condition,const char* what) {++checks;if(!condition) throw std::runtime_error(what);}
// Q23 signed residual oracle, directly subtract powers; no PaperSac normalization.
int pattern_approx(unsigned fraction,unsigned n,unsigned* flags=nullptr) {
    int residual=int((1u<<23)+fraction),sum=0,sign=1;unsigned mask=0;
    for(unsigned j=0;j<n && residual;++j) {
        unsigned leading=0;for(int v=residual;v>>=1;) ++leading;
        bool up=leading && residual>=int(3u<<(leading-1));mask=(mask<<1)|up;
        int power=1<<(leading+int(up));sum+=sign*power;
        if(up) {residual=power-residual-1;sign=-sign;} else residual-=power;
    }
    if(flags) *flags=mask;
    return sum;
}
bool fp32_below(uint32_t approximate,uint32_t ideal,unsigned d) {
    int ea=int(approximate>>23),ei=int(ideal>>23),delta=ea-ei;
    if(delta<=-2 || delta>=2) return false;
    uint64_t a=(approximate&0x7fffff)|0x800000,i=(ideal&0x7fffff)|0x800000;
    if(delta>=0) a<<=delta;else i<<=-delta;
    return (a>i?a-i:i-a)*d<i;
}
int main(int argc,char**argv) try {
    uint64_t samples=argc>1?std::stoull(argv[1]):1000000;
    uint64_t seed=argc>2?std::stoull(argv[2]):314159;
    bool source_only=argc==4 && std::string(argv[3])=="source";
    if(!samples || argc>4 || (argc==4 && !source_only)) throw std::invalid_argument("samples seed [source]");
    paper_init_fp32_rne();
    // Representative no-extra-zero-run fixtures from every row of Table 2 [15].
    const unsigned in[]={0b010010,0b010011,0b011101,0b011100,0b101101,0b101100,0b100010,0b100011};
    const unsigned out[]={0b010010,0b010100,0b011110,0b011100,0b101110,0b101100,0b100010,0b100100};
    for(unsigned row=0;row<8;++row) for(unsigned tail=0;tail<(1u<<17);++tail) {
        unsigned flags=0;
        check(pattern_approx((in[row]<<17)|tail,3,&flags)==int((1u<<23)+(out[row]<<17)),"published pattern output");
        check(flags==row,"published pattern f1/f2/f3");
    }
    // Predictor prefix zero-extension: independently compute at original FP32 width.
    unsigned different_lut=0;
    for(unsigned prefix=0;prefix<128;++prefix) {
        unsigned f=prefix<<16;
        unsigned expected=unsigned(std::abs(int((1u<<23)+f)-pattern_approx(f,2)))>>11;
        check(prediction_prefix12(prefix)==expected,"Q23 prefix predictor oracle");
        if(expected!=paper_prediction_lut()[prefix]*32) {
            ++different_lut;
            std::cout<<"LUT_DIFFERENCE prefix="<<prefix<<" current_Q12="<<paper_prediction_lut()[prefix]*32<<" prefix_extended_Q12="<<expected<<'\n';
        }
    }
    const float examples[]={0.4656868f,0.3361206f};
    const unsigned expected[]={0b1101110,0b0110000};
    for(unsigned j=0;j<2;++j) check(pattern_approx(float_bits(examples[j])&0x7fffff,3)==int((1u<<23)+(expected[j]<<16)),"Fig2 prediction examples");
    const Profile profiles[]={Profile::Baseline,Profile::Anchor0,Profile::Anchor12,Profile::Prefix12,Profile::Prefix12Anchor};
    const char* labels[]={"baseline","anchor0","anchor12","prefix12","prefix12_anchor"};
    const unsigned den[]={1000,200,100,20};
    uint64_t fp_counts[5][3][4]={},posit_counts[5][3][4]={},conversion_changed=0,cut_changed=0,output_changed[5][3]={};
    PaperGenerator generator(seed,PaperDistribution::UniformValue);PaperCounters counters;PaperFingerprint hash;
    while(counters.accepted<samples) {
        uint32_t a=generator.next_bits(),b=generator.next_bits();auto pair=paper_evaluate_pair(a,b);
        counters.record(pair.reason);hash.add(a);hash.add(b);hash.add(uint32_t(pair.reason));hash.add(pair.ideal_bits);
        if(pair.reason!=PaperReject::Accepted) continue;
        auto ua=parse<32,3>(pair.posit_a),ub=parse<32,3>(pair.posit_b);
        unsigned ma=((a&0x7fffff)|0x800000)>>11,mb=((b&0x7fffff)|0x800000)>>11;
        int sa=int(a>>23)-127,sb=int(b>>23)-127;
        conversion_changed+=value(pair.posit_a)!=from_bits(a) || value(pair.posit_b)!=from_bits(b);
        cut_changed+=ua.frac>>51!=ma || ub.frac>>51!=mb || ua.sf!=sa || ub.sf!=sb;
        for(unsigned v=0;v<5;++v) for(unsigned row=0;row<3;++row) {
            if(source_only && v!=4) continue;
            auto fp=experimental_mantissa(ma,mb,sa,sb,row+2,profiles[v],true);
            auto posit=experimental(pair.posit_a,pair.posit_b,row+2,profiles[v]);
            output_changed[v][row]+=value(posit)!=from_bits(fp);
            auto error=paper_error_fraction(posit,pair.ideal_bits);
            for(unsigned t=0;t<4;++t) {
                fp_counts[v][row][t]+=fp32_below(fp,pair.ideal_bits,den[t]);
                posit_counts[v][row][t]+=error.below(den[t]);
            }
        }
    }
    const double kim[3][4]={{9.30,32.12,50.01,95.58},{43.94,83.01,95.03,100},{86.69,99.81,100,100}};
    const double proposed[3][4]={{9.87,32.19,50.03,95.57},{44.69,83.17,95.05,99.99},{87.09,99.79,99.99,99.99}};
    std::cout<<"SOURCE_PATTERNS PASS checks="<<checks<<" different_prefix_lut_entries="<<different_lut<<"\n";
    std::cout<<"profile,n,threshold_percent,FP32_percent,delta_Kim_pp,Posit_percent,delta_Proposed_pp,FP32_Posit_output_differences\n"<<std::fixed<<std::setprecision(6);
    for(unsigned v=0;v<5;++v) for(unsigned row=0;row<3;++row) for(unsigned t=0;t<4;++t) {
        if(source_only && v!=4) continue;
        double fp=100.*fp_counts[v][row][t]/samples,ps=100.*posit_counts[v][row][t]/samples;
        std::cout<<labels[v]<<','<<row+2<<','<<100./den[t]<<','<<fp<<','<<fp-kim[row][t]<<','<<ps<<','<<ps-proposed[row][t]<<','<<output_changed[v][row]<<'\n';
    }
    std::cout<<"samples="<<samples<<" seed="<<seed<<" conversion_changed="<<conversion_changed<<" input_cut_changed="<<cut_changed
             <<" attempted="<<counters.attempted<<" accepted="<<counters.accepted<<" draws="<<generator.draws<<" fingerprint="<<std::hex<<hash.hash<<std::dec<<"\n";
    return 0;
} catch(const std::exception&e) {std::cerr<<e.what()<<'\n';return 2;}
