#!/usr/bin/env bash
# Run only when Verilator is already available. Never installs tools.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_dir"
command -v verilator >/dev/null || { echo 'BLOCKED: Verilator not installed; Gate2 cannot be accepted'; exit 2; }
result_dir="$project_dir/results/week9_multiplier/verilator"
mkdir -p -- "$result_dir/tmp"
export TMPDIR="$result_dir/tmp"
verilator --version > "$result_dir/version.log"
sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser ops_sel_comb
    sac_step_comb sbm_shift_comb sbm_accum_comb iter_ctrl sbm_accum mul_iter_core
    mul_norm_comb posit_pack_prepare posit_pack_finish posit_pack mul_iter_wrapper posit_mul_iter)
rtl=()
for source in "${sources[@]}"; do rtl+=("$project_dir/rtl/$source.sv"); done
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    for scheme in 0 1; do
        for rounding in 0 1; do
            round=RNE
            if [[ "$rounding" == 1 ]]; then round=TRUNC; fi
            run_dir="$result_dir/${nb}_${es}_${scheme}_${rounding}"
            mkdir -p -- "$run_dir"
            # Warnings are retained in build.log. This functional build does not
            # replace a separate reviewed strict lint run.
            verilator --cc --exe --build --no-timing -Wall -Wno-fatal \
                --top-module posit_mul_iter "-I$project_dir/rtl" \
                "-GNB=$nb" "-GES=$es" "-GFRAC_W=$((nb-3-es<12?nb-3-es:12))" \
                "-GROUND_SCHEME=$scheme" "-GROUND_MODE=\"$round\"" \
                --Mdir "$run_dir/obj_dir" -CFLAGS "-O3 -DPROFILE_ROUNDING=$rounding" \
                "${rtl[@]}" "$project_dir/tb/week9_multiplier_harness.cpp" \
                > "$run_dir/build.log" 2>&1
            "$run_dir/obj_dir/Vposit_mul_iter" \
                "$project_dir/results/week9_multiplier/acceptance_corpus/mul_${nb}_${es}_${scheme}_${rounding}.txt" \
                | tee "$run_dir/run.log"
        done
    done
done
echo 'Functional runs finished. Review count/coverage/lint before accepting Gate2.'
