#include <filesystem>
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include "paper_discriminator_study.hpp"
int main(int argc, char** argv) {
    if (argc != 3) return 2;
    std::filesystem::create_directories(argv[2]);
    std::ifstream corpus(argv[1]);
    if (!corpus) throw std::runtime_error("missing frozen corpus");
    std::ofstream out(std::filesystem::path(argv[2]) / "paper.txt");
    std::string line;
    std::getline(corpus,line);
    unsigned records=0, steps=0;
    std::set<std::string> unique;
    auto emit = [&](uint32_t a, uint32_t b, unsigned n, bool force) {
        const auto value=discriminator::evaluate(a,b,n,discriminator::Candidate::Fig3,force);
        if (!discriminator::verify_trace(a,b,n,discriminator::Candidate::Fig3,value))
            throw std::runtime_error("Q96 reference mismatch");
        const auto ua=l1::parse<32,3>(a), ub=l1::parse<32,3>(b);
        const unsigned ma=ua.frac>>51, mb=ub.frac>>51;
        int64_t acc=0;
        for (const auto& s:value.steps) {
            out << std::hex << a << ' ' << b << ' ' << force << ' '
                << value.result.swapped << ' ' << ma << ' ' << mb << ' '
                << value.selected_y << ' ' << value.score_a << ' ' << value.score_b << ' '
                << s.mantissa << ' ' << std::dec << s.exponent << ' ' << s.power << ' '
                << (s.coefficient<0) << ' ' << value.anchor << ' ' << std::hex << acc << ' '
                << s.next_mantissa << ' ' << std::dec << s.next_exponent << ' '
                << ((s.coefficient<0)^s.round_up) << ' ' << std::hex << s.accumulator << ' '
                << s.term_tail << ' ' << value.result.bits << ' '
                << (&s == &value.steps.back()) << '\n';
            acc=s.accumulator;
            ++steps;
        }
        ++records;
    };
    while(std::getline(corpus,line)) {
        std::istringstream row(line);
        std::string id,category,a,b,n,force;
        std::getline(row,id,','); std::getline(row,category,',');
        std::getline(row,a,','); std::getline(row,b,',');
        std::getline(row,n,','); std::getline(row,force,',');
        unique.insert(a+","+b+","+n+","+force);
        emit(std::stoul(a,nullptr,16),std::stoul(b,nullptr,16),std::stoul(n),std::stoul(force));
    }
    emit(0x1c900000,0x3c820000,3,true);
    if (discriminator::evaluate(0x1c900000,0x3c820000,3,discriminator::Candidate::Fig3,true).result.bits != 0x1ae34000)
        throw std::runtime_error("Fig4 mismatch");
    std::cout << "PAPER GENERATOR PASS records=" << records << " unique=" << unique.size()
              << " commits=" << steps << " Fig4=1ae34000\n";
}
