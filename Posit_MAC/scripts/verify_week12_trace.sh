#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/week12/window"
export TMPDIR="$run/tmp"
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/export_week12_trace.cpp \
    -o "$run/bin/export_trace" > "$run/trace_build.log" 2>&1
"$run/bin/export_trace" "$run/fixtures/main.bin" "$run/complete_trace.jsonl" > "$run/trace_export.log"
python3 scripts/check_week12_trace.py | tee "$run/python_trace.log"
sha256sum l1/test/export_week12_trace.cpp scripts/check_week12_trace.py \
    scripts/verify_week12_trace.sh l1/include/posit_fused_window.hpp > "$run/trace_source.sha256"
