#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/nf_corners_20261014"
mkdir -p "$run/tmp" "$run/fixtures"
export TMPDIR="$run/tmp"
export LD_LIBRARY_PATH="$PWD/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
g++ -O3 -std=c++17 -Il1/include l1/test/gen_nf_corners.cpp -Ll0 -lsoftposit \
    -o "$run/gen_vectors" > "$run/generator_build.log" 2>&1
"$run/gen_vectors" > "$run/generator.log"
sha256sum results/nf_corners_20261014/fixtures/*.txt > "$run/fixtures.sha256"
sha256sum l1/test/gen_nf_corners.cpp tb/nf_coverage_corpus.hpp tb/week11_model.hpp \
    scripts/prepare_nf_corners.sh > "$run/generator_source.sha256"
cat "$run/generator.log"
