#!/usr/bin/env bash
# Replay mandatory corners with the exact binary qualified by the stratified run.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
project_dir="$PWD"
base="$project_dir/results/week9_multiplier/verilator/gate2_stratified"
[[ -s "$base/summary.json" ]] || { echo 'Stratified acceptance not complete'; exit 2; }
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    for scheme in 0 1; do
        for rounding in 0 1; do
            folder="$base/${nb}_${es}_${scheme}_${rounding}"
            fixture="$project_dir/results/week9_multiplier/gate2_cornercorpus/mul_${nb}_${es}_${scheme}_${rounding}.txt"
            LD_LIBRARY_PATH="$folder/src" "$folder/obj_dir/Vposit_mul_iter" \
                "$fixture" "$folder/corner_coverage.dat" | tee "$folder/corner_run.log"
        done
    done
done
