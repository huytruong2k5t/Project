#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/fraction_survey_20261015"
mkdir -p "$run/tmp"
export TMPDIR="$run/tmp"
printf RUNNING > "$run/status.txt"
g++ --version > "$run/compiler.log"
sha256sum l1/test/fraction_survey.cpp l1/include/*.hpp tb/week11_model.hpp \
    tb/week10_add_reference.hpp tb/week9_exact_reference.hpp scripts/run_fraction_survey.sh > "$run/source.sha256"
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/fraction_survey.cpp \
    -o "$run/survey" > "$run/build.log" 2>&1
"$run/survey" 1000 20261015 "$run/pilot.csv" | tee "$run/pilot.log"
g++ -O1 -g -std=c++17 -Wall -Wextra -Werror -fsanitize=undefined \
    -fno-sanitize-recover=undefined -Il1/include l1/test/fraction_survey.cpp \
    -o "$run/survey_ubsan" > "$run/build_ubsan.log" 2>&1
"$run/survey_ubsan" 1000 20261015 "$run/pilot_ubsan.csv" | tee "$run/pilot_ubsan.log"
cmp "$run/pilot.csv" "$run/pilot_ubsan.csv"
"$run/survey" 100000 20261015 "$run/accuracy.csv" | tee "$run/main.log"
sha256sum "$run/survey" "$run/survey_ubsan" "$run/accuracy.csv" > "$run/products.sha256"
printf COMPLETE > "$run/status.txt"
