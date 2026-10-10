#!/usr/bin/env bash
# Strict lint for the normative multiplier. Research/PPA tops have separate scope.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
command -v verilator >/dev/null || { echo 'BLOCKED: Verilator unavailable'; exit 2; }
mkdir -p results/week9_implementation/lint_gate2
verilator --version > results/week9_implementation/lint_gate2/version.log
sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser ops_sel_comb
    sac_step_comb sbm_shift_comb sbm_accum_comb iter_ctrl sbm_accum mul_iter_core
    mul_norm_comb posit_pack_prepare posit_pack_finish posit_pack mul_iter_wrapper posit_mul_iter)
rtl=()
for source in "${sources[@]}"; do rtl+=("rtl/$source.sv"); done
sha256sum "${rtl[@]}" rtl/posit_mac.vh > results/week9_implementation/lint_gate2/source.sha256
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    for scheme in 0 1; do
        for rounding in RNE TRUNC; do
            profile="${nb}_${es}_${scheme}_${rounding}"
            verilator --lint-only --timing -Wall --top-module posit_mul_iter -Irtl \
                "-GNB=$nb" "-GES=$es" "-GFRAC_W=$((nb-3-es<12?nb-3-es:12))" \
                "-GROUND_SCHEME=$scheme" "-GROUND_MODE=\"$rounding\"" \
                "${rtl[@]}" > "results/week9_implementation/lint_gate2/$profile.log" 2>&1
            echo "STRICT LINT PASS $profile"
        done
    done
done
