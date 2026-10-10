#!/usr/bin/env bash
# Run only when Verilator is already available. Never installs tools.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_dir"
command -v verilator >/dev/null || { echo 'BLOCKED: Verilator not installed; Gate2 cannot be accepted'; exit 2; }
fixture_run="${1:-final_pilot}"
[[ "$fixture_run" =~ ^[a-z0-9_-]+$ ]] || { echo 'Invalid fixture run'; exit 2; }
fixture_dir="$project_dir/results/week9_multiplier/$fixture_run"
[[ -d "$fixture_dir" ]] || { echo 'Missing frozen fixture directory'; exit 2; }
# Fail before building if any of the sixteen frozen fixtures is missing.
for nb_es in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$nb_es"
    for scheme in 0 1; do
        for rounding in 0 1; do
            [[ -s "$fixture_dir/mul_${nb}_${es}_${scheme}_${rounding}.txt" ]] || {
                echo "Missing fixture: mul_${nb}_${es}_${scheme}_${rounding}.txt"; exit 2;
            }
        done
    done
done
# Run the default pilot first and compare to ModelSim before requesting the
# full stratified corpus. Merely building this harness is not acceptance.
result_dir="$project_dir/results/week9_multiplier/verilator/$fixture_run"
mkdir -p -- "$result_dir/tmp"
export TMPDIR="$result_dir/tmp"
verilator --version > "$result_dir/version.log"
g++ --version > "$result_dir/compiler.log"
make --version > "$result_dir/make_version.log"
sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser ops_sel_comb
    sac_step_comb sbm_shift_comb sbm_accum_comb iter_ctrl sbm_accum mul_iter_core
    mul_norm_comb posit_pack_prepare posit_pack_finish posit_pack mul_iter_wrapper posit_mul_iter)
rtl=()
for source in "${sources[@]}"; do rtl+=("src/$source.sv"); done
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    for scheme in 0 1; do
        for rounding in 0 1; do
            round=RNE
            if [[ "$rounding" == 1 ]]; then round=TRUNC; fi
            run_dir="$result_dir/${nb}_${es}_${scheme}_${rounding}"
            mkdir -p -- "$run_dir/src"
            # Generated makefiles must use relative, space-free source paths.
            # Keep every snapshot/build product inside the project run directory.
            for source in "${sources[@]}"; do
                cp -- "$project_dir/rtl/$source.sv" "$run_dir/src/"
            done
            cp -- "$project_dir/rtl/posit_mac.vh" "$run_dir/src/"
            cp -- "$project_dir/tb/week9_multiplier_harness.cpp" "$run_dir/src/"
            sha256sum "$fixture_dir/mul_${nb}_${es}_${scheme}_${rounding}.txt" > "$run_dir/fixture.sha256"
            (cd -- "$run_dir" && sha256sum src/*) > "$run_dir/source.sha256"
            (cd -- "$run_dir"
            # Warnings are retained in build.log. This functional build does not
            # replace a separate reviewed strict lint run.
            verilator --cc --exe --no-timing -Wall -Wno-fatal \
                --top-module posit_mul_iter -Isrc \
                "-GNB=$nb" "-GES=$es" "-GFRAC_W=$((nb-3-es<12?nb-3-es:12))" \
                "-GROUND_SCHEME=$scheme" "-GROUND_MODE=\"$round\"" \
                --Mdir obj_dir -CFLAGS "-O3 -DPROFILE_ROUNDING=$rounding" \
                "${rtl[@]}" src/week9_multiplier_harness.cpp \
                > build.log 2>&1
                # All generated/source paths are relative. CURDIR=. represents
                # the actual make working directory without an absolute space path.
                make -C obj_dir -f Vposit_mul_iter.mk CURDIR=. -j2 >> build.log 2>&1)
            "$run_dir/obj_dir/Vposit_mul_iter" \
                "$fixture_dir/mul_${nb}_${es}_${scheme}_${rounding}.txt" \
                | tee "$run_dir/run.log"
        done
    done
done
if [[ "$fixture_run" == final_pilot ]]; then
    python3 "$project_dir/scripts/audit_week9_verilator.py" "$fixture_run"
fi
echo 'Functional runs finished. Review count/coverage/lint before accepting Gate2.'
