#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/week12/coverage"
mkdir -p "$run/tmp" "$run/bin" "$run/fixtures"
export TMPDIR="$run/tmp"
printf RUNNING > "$run/status.txt"
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/week12_coverage.cpp \
    -o "$run/bin/coverage" > "$run/build.log" 2>&1
sha256sum results/week12/coverage_contract.json l1/test/week12_coverage.cpp \
    scripts/verify_week12_coverage.sh l1/include/posit_fused_window.hpp \
    tb/week12_fused_reference.hpp tb/nf_coverage_corpus.hpp > "$run/source.sha256"
"$run/bin/coverage" generate "$run/fixtures/main.bin" | tee "$run/generator.log"
sha256sum "$run/fixtures/main.bin" > "$run/corpus.sha256"
"$run/bin/coverage" monitor "$run/fixtures/main.bin" "$run/linux.json" | tee "$run/linux.log"
g++ -O1 -g -std=c++17 -Wall -Wextra -Werror -fsanitize=undefined -fno-sanitize-recover=all \
    -Il1/include l1/test/week12_coverage.cpp -o "$run/bin/coverage_ubsan" > "$run/ubsan_build.log" 2>&1
"$run/bin/coverage_ubsan" monitor "$run/fixtures/main.bin" "$run/ubsan.json" | tee "$run/ubsan.log"
x86_64-w64-mingw32-g++ -O3 -std=c++17 -Wall -Wextra -Werror -static -Il1/include \
    l1/test/week12_coverage.cpp -o "$run/bin/coverage.exe" > "$run/windows_build.log" 2>&1
printf COMPLETE > "$run/linux_status.txt"
