#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p results/week10_adder/lint
verilator --version > results/week10_adder/verilator_version.log
sources=(rtl/lod_lzd_core.sv rtl/dyn_left_shifter.sv rtl/dyn_right_shifter.sv rtl/posit_add_align.sv rtl/posit_add_arith.sv rtl/posit_add_normalize.sv rtl/posit_add_comb.sv rtl/posit_add.sv)
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    for top in posit_add_comb posit_add; do
        verilator --lint-only --timing -Wall -Irtl --top-module "$top" -GNB="$nb" -GES="$es" "${sources[@]}" > "results/week10_adder/lint/${top}_${nb}_${es}.log" 2>&1
        echo "W10 STRICT LINT PASS top=$top NB=$nb ES=$es"
    done
done
