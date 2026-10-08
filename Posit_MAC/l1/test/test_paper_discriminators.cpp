#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <set>
#include <sstream>
#include <string>

#include "paper_discriminator_study.hpp"

using namespace discriminator;
uint64_t checks = 0;

void check(bool condition, const char* message) {
    ++checks;
    if (!condition) { throw std::runtime_error(message); }
}

std::string hex_word(uint64_t value) {
    std::ostringstream output;
    output << "0x" << std::hex << value;
    return output.str();
}

std::string wide_hex(SignedWide value) {
    if (value < 0) { throw std::runtime_error("negative extended accumulator"); }
    const Wide magnitude = Wide(value);
    std::ostringstream output;
    output << "0x" << std::hex << uint64_t(magnitude >> 64)
           << std::setfill('0') << std::setw(16) << uint64_t(magnitude);
    return output.str();
}

struct Vector {
    std::string category;
    uint32_t a, b;
    unsigned n;
    bool force_a = false;
};

uint32_t unit_posit(unsigned significand) {
    return 0x40000000 | ((significand - 4096) << 14);
}

void verify_evaluation(const Vector& vector, Candidate candidate, const Evaluation& value) {
    check(verify_trace(vector.a, vector.b, vector.n, candidate, value), "independent Q96 trace/output");
    const auto a = parse<32, 3>(vector.a), b = parse<32, 3>(vector.b);
    if (a.is_zero || b.is_zero || a.is_nar || b.is_nar) { return; }
    const unsigned fa = unsigned(a.frac >> 51) - 4096;
    const unsigned fb = unsigned(b.frac >> 51) - 4096;
    const unsigned score_a = candidate == Candidate::Legacy7
        ? paper_prediction_error(fa >> 5) : paper_pattern_prediction_error(fa >> 5);
    const unsigned score_b = candidate == Candidate::Legacy7
        ? paper_prediction_error(fb >> 5) : paper_pattern_prediction_error(fb >> 5);
    const bool expected_swap = !vector.force_a && (score_b < score_a ||
        (candidate == Candidate::TieB && score_a == score_b));
    check(value.result.swapped == expected_swap, "selection and tie policy");
}

void source_fixture(const std::string& directory) {
    std::ofstream output(directory + "/source_fixture.csv");
    output << "candidate,expected_bits,actual_bits,packed_match,projected_trace_match,scope\n";
    const Vector figure = {"published_fig4", 0x1c900000, 0x3c820000, 3, true};
    const int expected_acc[] = {4616, 5770, 5914};
    const int expected_power[] = {0, -2, -5};
    for (unsigned index = 0; index < candidate_count; ++index) {
        const auto candidate = Candidate(index);
        const auto value = evaluate(figure.a, figure.b, figure.n, candidate, true);
        verify_evaluation(figure, candidate, value);
        bool trace_match = value.steps.size() == 3;
        for (unsigned k = 0; k < value.steps.size(); ++k) {
            const auto& step = value.steps[k];
            trace_match &= step.power == expected_power[k] && step.coefficient == 1 &&
                (step.accumulator >> (value.accumulator_fraction - 12)) == expected_acc[k];
        }
        const bool packed_match = value.result.bits == 0x1ae34000;
        // Strong source discriminator: guard12 low bits reach output unless cut.
        if (candidate == Candidate::SourceUncut) {
            check(!packed_match && value.result.bits == 0x1ae34800, "source uncut contradicts published output");
        } else {
            check(packed_match && trace_match, "published Fig4 output/projected trace");
        }
        output << names[index] << ',' << hex_word(0x1ae34000) << ','
               << hex_word(value.result.bits) << ',' << packed_match << ',' << trace_match
               << ",force_X_as_in_paper_not_an_OPS_tie_fixture\n";
    }
    output.close();
    check(bool(output), "source fixture write");
}

void write_vectors(const std::string& directory, const std::vector<Vector>& vectors) {
    std::ofstream corpus(directory + "/vectors.csv");
    std::ofstream trace(directory + "/traces.csv");
    std::ofstream results(directory + "/outputs.csv");
    std::ofstream differences(directory + "/first_differences.csv");
    corpus << "case_id,category,a_hex,b_hex,n,force_a\n";
    trace << "case_id,category,candidate,selected_operand,index_a,index_b,score_a_Q12,score_b_Q12,tie,"
             "k,mantissa,exponent,power,coefficient,anchor,shift_right,acc_fraction_bits,term_magnitude,"
             "tail,accumulator_integer,accumulator_Q12_projection,next_mantissa,next_exponent,exact_sum_Q96_hex\n";
    results << "case_id,category,candidate,bits_hex,sf,frac_hex,iterations,swapped\n";
    differences << "case_id,category,reference,candidate,first_field,term_k,packed_different\n";
    for (unsigned id = 0; id < vectors.size(); ++id) {
        const auto& vector = vectors[id];
        corpus << id << ',' << vector.category << ',' << hex_word(vector.a) << ','
               << hex_word(vector.b) << ',' << vector.n << ',' << vector.force_a << '\n';
        std::array<Evaluation, candidate_count> values;
        for (unsigned index = 0; index < candidate_count; ++index) {
            values[index] = evaluate(vector.a, vector.b, vector.n, Candidate(index), vector.force_a);
            const auto& value = values[index];
            verify_evaluation(vector, Candidate(index), value);
            results << id << ',' << vector.category << ',' << names[index] << ','
                    << hex_word(value.result.bits) << ',' << value.result.unpacked.sf << ','
                    << hex_word(value.result.unpacked.frac) << ',' << value.result.iterations
                    << ',' << value.result.swapped << '\n';
            for (const auto& step : value.steps) {
                const int shift = value.anchor - step.power;
                const int aligned = -shift + int(value.accumulator_fraction - 12);
                const uint64_t term = aligned >= 0 ? uint64_t(value.selected_y) << aligned
                    : aligned <= -64 ? 0 : value.selected_y >> (-aligned);
                trace << id << ',' << vector.category << ',' << names[index] << ','
                      << (value.result.swapped ? 'B' : 'A') << ',' << value.index_a << ','
                      << value.index_b << ',' << value.score_a << ',' << value.score_b << ','
                      << value.tie << ',' << step.iteration << ',' << step.mantissa << ','
                      << step.exponent << ',' << step.power << ',' << step.coefficient << ','
                      << value.anchor << ',' << shift << ',' << value.accumulator_fraction << ','
                      << term << ',' << step.term_tail << ',' << step.accumulator << ','
                      << (step.accumulator >> (value.accumulator_fraction - 12)) << ','
                      << step.next_mantissa << ',' << step.next_exponent << ',';
                if (!value.extended_accumulators.empty()) {
                    trace << wide_hex(value.extended_accumulators[step.iteration - 1]);
                }
                trace << '\n';
            }
        }
        for (unsigned index = 1; index < candidate_count; ++index) {
            const auto& reference = values[0];
            const auto& compared = values[index];
            std::string field;
            unsigned k = 0;
            if (reference.result.swapped != compared.result.swapped) { field = "selected_operand"; }
            else if (reference.anchor != compared.anchor) { field = "anchor"; }
            else if (reference.accumulator_fraction != compared.accumulator_fraction) { field = "accumulator_grid"; }
            else {
                const auto length = std::min(reference.steps.size(), compared.steps.size());
                for (unsigned j = 0; j < length && field.empty(); ++j) {
                    const auto& a = reference.steps[j];
                    const auto& b = compared.steps[j];
                    if (a.next_mantissa != b.next_mantissa || a.next_exponent != b.next_exponent) {
                        field = "residual"; k = j + 1;
                    } else if (a.accumulator != b.accumulator) {
                        field = "accumulator"; k = j + 1;
                    }
                }
                if (field.empty() && reference.steps.size() != compared.steps.size()) { field = "early_stop"; }
                if (field.empty() && reference.result.bits != compared.result.bits) { field = "final_pack"; }
            }
            if (!field.empty()) {
                differences << id << ',' << vector.category << ",fig3," << names[index] << ','
                            << field << ',' << k << ','
                            << (reference.result.bits != compared.result.bits) << '\n';
            }
        }
    }
    corpus.close(); trace.close(); results.close(); differences.close();
    check(corpus && trace && results && differences, "CSV write");
}

void run_suite(const std::string& directory) {
    std::vector<Vector> vectors;
    const char* categories[] = {"prefix126_127", "equal_score", "rnd_boundary", "anchor_cut",
        "term_cut", "guard_depth", "output_width", "post_sum_cut", "signed_cut"};
    unsigned counts[9] = {};
    uint64_t searched = 0;
    auto inspect = [&](unsigned x, unsigned y, unsigned n) {
        std::array<Evaluation, candidate_count> values;
        const uint32_t a = unit_posit(x), b = unit_posit(y);
        for (unsigned index = 0; index < candidate_count; ++index) {
            values[index] = evaluate(a, b, n, Candidate(index), false, false);
        }
        ++searched;
        auto different = [&](unsigned left, unsigned right) {
            return values[left].result.bits != values[right].result.bits;
        };
        const bool accepted[] = {
            ((x - 4096) >> 5 >= 126 || (y - 4096) >> 5 >= 126) && different(0, 2),
            values[0].tie && different(0, 1),
            (x >= 6143 && x <= 6145) && different(0, 4),
            different(0, 3), different(0, 6), different(5, 6), different(6, 7),
            different(0, 8), different(0, 9)
        };
        for (unsigned j = 0; j < 9; ++j) {
            if (accepted[j] && counts[j] < 32) {
                vectors.push_back({categories[j], a, b, n});
                ++counts[j];
            }
        }
    };
    // Required edges first; then a deterministic prefix/low-tail search.
    for (unsigned x : {4097u, 6143u, 6144u, 6145u, 8128u, 8159u, 8160u, 8191u}) {
        for (unsigned y = 4096; y < 8192; y += 31) {
            for (unsigned n : {2u, 3u, 4u}) { inspect(x, y, n); }
        }
    }
    const unsigned tails[] = {0, 1, 15, 31};
    for (unsigned pa = 0; pa < 128; ++pa) {
        for (unsigned pb = 0; pb < 128; ++pb) {
            for (unsigned j = 0; j < 4; ++j) {
                for (unsigned n : {2u, 3u, 4u}) {
                    inspect(4096 + (pa << 5) + tails[j], 4096 + (pb << 5) + tails[3 - j], n);
                }
            }
        }
    }
    for (unsigned j = 0; j < 9; ++j) { check(counts[j] == 32, "category lacks discriminating vectors"); }
    vectors.push_back({"published_fig4", 0x1c900000, 0x3c820000, 3, true});
    vectors.push_back({"carry_required", unit_posit(6143), unit_posit(8191), 3, true});
    vectors.push_back({"negative_term_floor", unit_posit(6144), unit_posit(4097), 3, true});
    vectors.push_back({"shift_cut_edge", unit_posit(4097), unit_posit(8191), 3, true});
    write_vectors(directory, vectors);
    source_fixture(directory);

    std::mt19937_64 generator(20261008);
    for (unsigned i = 0; i < 10000; ++i) {
        Vector vector{"raw_oracle", uint32_t(generator()), uint32_t(generator()), 1 + i % 8};
        for (unsigned index = 0; index < candidate_count; ++index) {
            const auto value = evaluate(vector.a, vector.b, vector.n, Candidate(index));
            verify_evaluation(vector, Candidate(index), value);
        }
    }
    std::ofstream coverage(directory + "/coverage.csv");
    coverage << "category,selected_vectors\n";
    for (unsigned j = 0; j < 9; ++j) { coverage << categories[j] << ',' << counts[j] << '\n'; }
    coverage.close();
    check(bool(coverage), "coverage write");
    std::cout << "DISCRIMINATORS PASS checks=" << checks << " searched_pairs_n=" << searched
              << " selected_vectors=" << vectors.size() << " candidates=" << candidate_count
              << " raw_seed=20261008\n";
}

void measure(const std::string& directory, uint64_t samples, uint64_t seed) {
    check(samples != 0, "samples");
    paper_init_fp32_rne();
    // Source-based final-cut change only. Keep Fig3/source as paired controls.
    const Candidate measured[] = {Candidate::Fig3, Candidate::Guard12Pack12, Candidate::SourceUncut};
    const unsigned denominators[] = {1000, 200, 100, 20};
    const double paper[3][4] = {{9.87,32.19,50.03,95.57}, {44.69,83.17,95.05,99.99}, {87.09,99.79,99.99,99.99}};
    uint64_t counts[3][3][4] = {};
    PaperGenerator generator(seed, PaperDistribution::UniformValue);
    PaperCounters counters;
    PaperFingerprint fingerprint;
    while (counters.accepted < samples) {
        const uint32_t a = generator.next_bits(), b = generator.next_bits();
        const auto pair = paper_evaluate_pair(a, b);
        counters.record(pair.reason);
        fingerprint.add(a); fingerprint.add(b);
        fingerprint.add(uint32_t(pair.reason)); fingerprint.add(pair.ideal_bits);
        if (pair.reason != PaperReject::Accepted) { continue; }
        for (unsigned profile = 0; profile < 3; ++profile) {
            for (unsigned row = 0; row < 3; ++row) {
                const auto value = evaluate(pair.posit_a, pair.posit_b, row + 2, measured[profile], false, false);
                const auto error = paper_error_fraction(value.result.bits, pair.ideal_bits);
                for (unsigned j = 0; j < 4; ++j) { counts[profile][row][j] += error.below(denominators[j]); }
            }
        }
    }
    std::ofstream csv(directory + "/measurement.csv");
    csv << "profile,n,threshold_denominator,count,accepted,percent,paper_percent,delta_pp\n";
    csv << std::fixed << std::setprecision(9);
    double maximum[3] = {};
    for (unsigned profile = 0; profile < 3; ++profile) {
        for (unsigned row = 0; row < 3; ++row) {
            for (unsigned j = 0; j < 4; ++j) {
                const double percent = 100. * counts[profile][row][j] / samples;
                const double gap = percent - paper[row][j];
                maximum[profile] = std::max(maximum[profile], std::abs(gap));
                csv << names[unsigned(measured[profile])] << ',' << row + 2 << ',' << denominators[j]
                    << ',' << counts[profile][row][j] << ',' << samples << ',' << percent
                    << ',' << paper[row][j] << ',' << gap << '\n';
            }
        }
    }
    csv.close();
    check(bool(csv) && counters.consistent(), "measurement write/counters");
    std::cout << std::fixed << std::setprecision(9);
    for (unsigned profile = 0; profile < 3; ++profile) {
        std::cout << "MEASURE profile=" << names[unsigned(measured[profile])]
                  << " max_delta_pp=" << maximum[profile]
                  << " numeric=" << (samples >= 200000000 && maximum[profile] <= 1 ? "PASS" : "NOT_ACCEPTED") << '\n';
    }
    std::cout << "accepted=" << samples << " attempted=" << counters.attempted
              << " excluded_zero=" << counters.input_zero << " draws=" << generator.draws
              << " seed=" << seed << " fingerprint=" << std::hex << fingerprint.hash << std::dec << '\n';
}

int main(int argc, char** argv) try {
    if (argc == 5 && std::string(argv[1]) == "--measure") {
        measure(argv[2], std::stoull(argv[3]), std::stoull(argv[4]));
    } else if (argc == 2) {
        run_suite(argv[1]);
    } else {
        throw std::invalid_argument("OUTPUT_DIRECTORY or --measure OUTPUT_DIRECTORY SAMPLES SEED");
    }
    return 0;
} catch (const std::exception& error) {
    std::cerr << "DISCRIMINATORS FAIL " << error.what() << '\n';
    return 1;
}
