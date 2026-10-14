#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/nf_coverage_20261014"
mkdir -p "$run/tmp" "$run/fixtures" "$run/fixtures_ubsan"
export TMPDIR="$run/tmp"
export LD_LIBRARY_PATH="$PWD/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
g++ --version > "$run/compiler.log"
g++ -O3 -std=c++17 -Il1/include l1/test/gen_nf_coverage.cpp -Ll0 -lsoftposit \
    -o "$run/gen_vectors" > "$run/generator_build.log" 2>&1
"$run/gen_vectors" "$run/fixtures" > "$run/generator.log"
g++ -O1 -g -std=c++17 -fsanitize=undefined -fno-sanitize-recover=all \
    -Il1/include l1/test/gen_nf_coverage.cpp -Ll0 -lsoftposit \
    -o "$run/gen_vectors_ubsan" > "$run/generator_ubsan_build.log" 2>&1
"$run/gen_vectors_ubsan" "$run/fixtures_ubsan" > "$run/generator_ubsan.log"
for format in 8_0 16_1 32_2 32_3; do
    cmp "$run/fixtures/mac_$format.txt" "$run/fixtures_ubsan/mac_$format.txt"
done
sha256sum results/nf_coverage_20261014/fixtures/*.txt > "$run/fixtures.sha256"
printf COMPLETE > "$run/fixture_status.txt"
cat "$run/generator.log"
