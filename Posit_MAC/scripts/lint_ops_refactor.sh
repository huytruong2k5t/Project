#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/ops_refactor_20261014/lint"
mkdir -p "$run/tmp"
export TMPDIR="$run/tmp"
printf RUNNING > "$run/status.txt"
verilator --version > "$run/version.log"
sha256sum rtl/multiplier/ops_sel_comb.sv > "$run/source.sha256"
for full in $(seq 1 27); do
    for narrow in $(seq 1 "$full"); do
        verilator --lint-only --timing -Wall --top-module ops_sel_comb \
            "-GFRAC_MAX=$full" "-GFRAC_W=$narrow" rtl/multiplier/ops_sel_comb.sv \
            > "$run/${full}_${narrow}.log" 2>&1
    done
done
for full in 1 5 12 26 27; do
    narrow=$((full<12?full:12))
    for exact in 0 1; do
        for ops in 0 1; do
            verilator --lint-only --timing -Wall --top-module ops_sel_comb \
                "-GFRAC_MAX=$full" "-GFRAC_W=$narrow" -GSF_W=2 -GWIDTH_W=8 \
                "-GEXACT_EN=1'b$exact" "-GOPS_EN=1'b$ops" rtl/multiplier/ops_sel_comb.sv \
                > "$run/feature_${full}_${exact}_${ops}.log" 2>&1
        done
    done
done
printf COMPLETE > "$run/status.txt"
echo 'OPS STRICT LINT PASS width_pairs=378 feature_width_profiles=20 warning=0'
