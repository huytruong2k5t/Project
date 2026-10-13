#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p results/week10_adder/tmp results/week10_adder/paired
export TMPDIR="$PWD/results/week10_adder/tmp"
export LD_LIBRARY_PATH="$PWD/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
g++ --version > results/week10_adder/compiler.log
g++ -O3 -std=c++17 -Wall -Wextra -Werror -I l1/include l1/test/gen_week10_adder.cpp -L l0 -lsoftposit -o results/week10_adder/gen_vectors > results/week10_adder/build_generator.log 2>&1
./results/week10_adder/gen_vectors results/week10_adder/pilot 20000 > results/week10_adder/generator.log
g++ -O1 -g -std=c++17 -Wall -Wextra -Werror -fsanitize=undefined -fno-sanitize-recover=undefined -I l1/include l1/test/gen_week10_adder.cpp -L l0 -lsoftposit -o results/week10_adder/gen_vectors_ubsan >> results/week10_adder/build_generator.log 2>&1
./results/week10_adder/gen_vectors_ubsan results/week10_adder/ubsan_vectors 1000 > results/week10_adder/generator_ubsan.log
g++ -O3 -std=c++17 -Wall -Wextra -Werror -I l1/include l1/test/gen_nf_f_corpus.cpp -o results/week10_adder/gen_paired > results/week10_adder/build_paired.log 2>&1
./results/week10_adder/gen_paired results/week10_adder/paired/pilot.txt 100000 > results/week10_adder/paired/generation.log
./results/week10_adder/gen_paired results/week10_adder/paired/replay.txt 100000 > results/week10_adder/paired/replay.log
cmp results/week10_adder/paired/pilot.txt results/week10_adder/paired/replay.txt
sha256sum results/week10_adder/paired/pilot.txt > results/week10_adder/paired/corpus.sha256
cat results/week10_adder/generator.log results/week10_adder/generator_ubsan.log results/week10_adder/paired/generation.log
