#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/week12/accuracy"
mkdir -p "$run/tmp"
export TMPDIR="$run/tmp"
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/test_week12_accuracy.cpp \
    -o "$run/test_accuracy" > "$run/build.log" 2>&1
"$run/test_accuracy" results/week12/window/fixtures/main.bin 1000000 "$run/summary.json" | tee "$run/run.log"
sha256sum l1/test/test_week12_accuracy.cpp scripts/verify_week12_accuracy.sh \
    l1/include/posit_fused_window.hpp tb/week12_fused_reference.hpp > "$run/source.sha256"
