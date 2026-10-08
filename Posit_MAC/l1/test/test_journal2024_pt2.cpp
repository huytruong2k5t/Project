#include "paper_ops.hpp"
#include <fstream>
#include <iostream>
#include <stdexcept>

// Independent bit-pattern interpretation of journal Table IV (PT2).
// Seven input bits are zero-extended to Q12: a reconstruction assumption.
// No PaperSac or residual/complement recurrence is used in this reference.
unsigned pt2_fraction(unsigned fraction12) {
    if (fraction12 == 0) return 0;
    if ((fraction12 & 2048u) == 0) {
        unsigned position = 11;
        while ((fraction12 & (1u << position)) == 0) --position;
        const bool round_group = position && (fraction12 & (1u << (position - 1)));
        return 1u << (position + unsigned(round_group));
    }
    unsigned ones = 0;
    while (ones < 12 && (fraction12 & (1u << (11 - ones)))) ++ones;
    if (ones == 12) throw std::runtime_error("outside zero-padded seven-bit domain");
    unsigned prediction = ((1u << ones) - 1) << (12 - ones);
    const unsigned zero_position = 11 - ones;
    if (zero_position && (fraction12 & (1u << (zero_position - 1))))
        prediction |= 1u << zero_position;
    return prediction;
}

int main(int argc, char** argv) {
    std::ofstream csv(argc > 1 ? argv[1] : "journal2024_pt2.csv");
    if (!csv) return 2;
    csv << "prefix7,fraction12,predicted_fraction12,table_error,source_error,legacy_error\n";
    unsigned mismatch = 0, changed = 0;
    for (unsigned i = 0; i < 128; ++i) {
        const unsigned fraction = i << 5;
        const unsigned prediction = pt2_fraction(fraction);
        const unsigned error = prediction > fraction ? prediction - fraction : fraction - prediction;
        const unsigned source = l1::paper_pattern_prediction_error(i);
        const unsigned legacy = l1::paper_prediction_error(i) << 5;
        mismatch += error != source;
        changed += error != legacy;
        csv << i << ',' << fraction << ',' << prediction << ',' << error << ','
            << source << ',' << legacy << '\n';
    }
    std::cout << "JOURNAL2024 PT2 " << (mismatch ? "FAIL" : "PASS")
              << " entries=128 mismatches=" << mismatch
              << " legacy_changed=" << changed << '\n';
    return mismatch ? 1 : 0;
}
