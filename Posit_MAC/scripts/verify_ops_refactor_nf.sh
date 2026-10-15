#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/rtl_paths.sh"
set -euo pipefail
cd "$(dirname "$0")/.."
project_dir="$PWD"
export LD_LIBRARY_PATH="$project_dir/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p results/ops_refactor_20261014/nf
printf RUNNING > "results/ops_refactor_20261014/nf/${1:-pilot}_status.txt"
sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser posit_parser_comb
         ops_sel_comb sac_step_comb sbm_shift_comb sbm_accum_comb iter_ctrl sbm_accum
         mul_iter_core mul_prepack_norm_comb posit_pack_prepare posit_pack_finish
         posit_pack_comb round_unpacked_comb posit_add_align posit_add_arith
         posit_add_normalize posit_add posit_pack mac_nf_wrapper posit_mac_nf)
verilator --version > results/ops_refactor_20261014/nf/verilator_version.log
g++ --version > results/ops_refactor_20261014/nf/compiler.log
stage="${1:-pilot}"
if [[ "$stage" == acceptance ]]; then
    python3 scripts/audit_ops_refactor_nf.py preflight
elif [[ "$stage" != pilot ]]; then
    echo 'Expected pilot or acceptance' >&2
    exit 1
fi
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    if [[ "$stage" == acceptance && "$format" != '32 3' ]]; then
        continue
    fi
    fw=$((nb-3-es<12?nb-3-es:12))
    run_dir="$project_dir/results/ops_refactor_20261014/nf/${nb}_${es}"
    mkdir -p "$run_dir/src/l1" "$run_dir/tmp"
    export TMPDIR="$run_dir/tmp"
    rtl=()
    for module in "${sources[@]}"; do
        cp -- "$(rtl_path "$module")" "$run_dir/src/"
        rtl+=("src/$module.sv")
    done
    cp -- rtl/posit_mac.vh tb/nf_coverage_harness.cpp tb/nf_coverage_corpus.hpp tb/nf_coverage.vlt tb/week11_model.hpp \
          tb/week10_add_reference.hpp tb/week9_exact_reference.hpp \
          l0/softposit_api.h l0/libsoftposit.so "$run_dir/src/"
    cp -- l1/include/*.hpp "$run_dir/src/l1/"
    (
        cd "$run_dir"
        sha256sum src/*.sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.vlt src/*.so src/l1/*.hpp > source.sha256
        verilator --lint-only --timing -Wall --top-module posit_mac_nf -Isrc \
            "-GNB=$nb" "-GES=$es" "-GFRAC_W=$fw" "${rtl[@]}" > lint.log 2>&1
        if [[ "$stage" == pilot ]]; then
        verilator --cc --exe --no-timing --coverage -Wall -Wno-fatal \
            --top-module posit_mac_nf -Isrc "-GNB=$nb" "-GES=$es" "-GFRAC_W=$fw" \
            --Mdir obj_dir \
            -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
            -LDFLAGS "-L../src -lsoftposit" src/nf_coverage.vlt "${rtl[@]}" src/nf_coverage_harness.cpp > build.log 2>&1
        make -C obj_dir -f Vposit_mac_nf.mk CURDIR=. -j2 >> build.log 2>&1
        sha256sum obj_dir/Vposit_mac_nf > binary.sha256
        ./obj_dir/Vposit_mac_nf 20000 pilot | tee pilot.log
        fi
        if [[ "$stage" == acceptance && "$nb" == 32 && "$es" == 3 ]]; then
            # Full toggle instrumentation is retained in the pilot binary.
            # The large run keeps line/branch and explicit functional bins.
            verilator --cc --exe --no-timing --coverage-line -Wall -Wno-fatal \
                --top-module posit_mac_nf -Isrc "-GNB=$nb" "-GES=$es" "-GFRAC_W=$fw" \
                --Mdir obj_fast \
                -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
                -LDFLAGS "-L../src -lsoftposit" src/nf_coverage.vlt "${rtl[@]}" src/nf_coverage_harness.cpp > build_fast.log 2>&1
            make -C obj_fast -f Vposit_mac_nf.mk CURDIR=. -j2 >> build_fast.log 2>&1
            sha256sum obj_fast/Vposit_mac_nf > binary_fast.sha256
            ./obj_fast/Vposit_mac_nf 10000000 acceptance | tee acceptance.log
        fi
    )
    echo "PROFILE FINISHED $nb/$es"
done
printf COMPLETE > "results/ops_refactor_20261014/nf/${stage}_status.txt"
