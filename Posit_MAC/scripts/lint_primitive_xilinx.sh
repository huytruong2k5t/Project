#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out=results/primitive_xilinx_20261015
mkdir -p "$out/lint" "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
verilator --version > "$out/lint/version.txt"
exec > "$out/lint/lint.log" 2>&1
checks=0
for n in 1 2 3 5 8 12 26 27 29 31 32 33 64; do
    s=1
    while (( (1 << s) < n )); do s=$((s+1)); done
    short=$((s>1 ? s-1 : 1))
    for w in "$short" "$s" "$((s+1))"; do
        for arith in 0 1; do
            verilator --lint-only --timing -Wall --top-module dyn_right_shifter \
                -GN="$n" -GSHIFT_W="$w" "-GARITH=1'b$arith" \
                rtl/candidates/primitives/dyn_right_shifter.sv
            checks=$((checks+1))
        done
        verilator --lint-only --timing -Wall --top-module dyn_left_shifter \
            -GN="$n" -GSHIFT_W="$w" rtl/candidates/primitives/dyn_left_shifter.sv
        checks=$((checks+1))
    done
done
for n in 2 3 4 5 6 7 8 9 10 11 12 26 27 29 31 32 33 53 54 64; do
    s=1
    while (( (1 << s) < n )); do s=$((s+1)); done
    for width in "$s" "$((s+1))"; do
        for mode in 0 1; do
            verilator --lint-only --timing -Wall --top-module lod_lzd_core \
                -GN="$n" -GS="$width" -GMODE="$mode" \
                rtl/candidates/primitives/lod_lzd_core.sv
            checks=$((checks+1))
        done
    done
done
printf 'STRICT_LINT_PASS invocations=%d\n' "$checks"
