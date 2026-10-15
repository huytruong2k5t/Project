#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/rtl_paths.sh"
set -euo pipefail
cd "$(dirname "$0")/.."
project="$PWD"
run="$project/results/normalize_refactor_20261015"
mkdir -p "$run/lint" "$run/integration"
verilator --version > "$run/lint/version.log"
g++ --version > "$run/integration/compiler.log"
printf RUNNING > "$run/lint/status.txt"
for variant in zero shared; do
    for format in '8 0' '16 1' '32 2' '32 3' '5 0' '6 1' '7 1' '16 10' '32 27'; do
        read -r nb es <<< "$format"
        verilator --lint-only --timing -Wall --top-module "posit_add_normalize_$variant" \
            "-GNB=$nb" "-GES=$es" "rtl/candidates/adder/posit_add_normalize_$variant.sv" \
            rtl/common/lod_lzd_core.sv rtl/common/dyn_left_shifter.sv \
            > "$run/lint/${variant}_${nb}_${es}.log" 2>&1
    done
    for format in '32 3 13' '32 2 12'; do
        read -r nb es sw <<< "$format"
        verilator --lint-only --timing -Wall --top-module "posit_add_normalize_$variant" \
            "-GNB=$nb" "-GES=$es" "-GSF_W=$sw" "rtl/candidates/adder/posit_add_normalize_$variant.sv" \
            rtl/common/lod_lzd_core.sv rtl/common/dyn_left_shifter.sv \
            > "$run/lint/${variant}_${nb}_${es}_${sw}.log" 2>&1
    done
done
printf COMPLETE > "$run/lint/status.txt"
printf RUNNING > "$run/integration/status.txt"
export LD_LIBRARY_PATH="$project/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
for variant in zero shared; do
    for format in '8 0' '16 1' '32 2' '32 3'; do
        read -r nb es <<< "$format"
        folder="$run/integration/$variant/${nb}_${es}"
        mkdir -p "$folder/src/l1" "$folder/tmp"
        export TMPDIR="$folder/tmp"
        sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser_comb
            posit_add_align posit_add_arith posit_add posit_pack_prepare posit_pack_finish posit_pack_comb)
        rtl=()
        for module in "${sources[@]}"; do
            cp -- "$(rtl_path "$module")" "$folder/src/"
            rtl+=("src/$module.sv")
        done
        # Only normalization is substituted; alignment and pipeline stay production RTL.
        sed "s/module posit_add_normalize_$variant #(/module posit_add_normalize #(/" \
            "rtl/candidates/adder/posit_add_normalize_$variant.sv" > "$folder/src/posit_add_normalize.sv"
        rtl+=(src/posit_add_normalize.sv)
        cp -- rtl/posit_mac.vh tb/adder_verification_top.sv tb/week10_adder_harness.cpp \
            tb/week10_add_reference.hpp l0/softposit_api.h l0/libsoftposit.so "$folder/src/"
        cp -- l1/include/*.hpp "$folder/src/l1/"
        rtl+=(src/adder_verification_top.sv)
        (
            cd "$folder"
            sha256sum src/*.sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.so src/l1/*.hpp > source.sha256
            verilator --lint-only --timing -Wall --top-module adder_verification_top -Isrc \
                "-GNB=$nb" "-GES=$es" "${rtl[@]}" > lint.log 2>&1
            # Untimed cycle harness ignores CK2Q only. Strict timing lint above has no waiver.
            verilator --cc --exe --no-timing --coverage -Wall -Wno-ASSIGNDLY \
                --top-module adder_verification_top -Isrc "-GNB=$nb" "-GES=$es" --Mdir obj_dir \
                -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
                -LDFLAGS "-L../src -lsoftposit" "${rtl[@]}" src/week10_adder_harness.cpp > build.log 2>&1
            make -C obj_dir -f Vadder_verification_top.mk CURDIR=. -j2 >> build.log 2>&1
            sha256sum obj_dir/Vadder_verification_top > binary.sha256
            ./obj_dir/Vadder_verification_top 50000 pilot | tee pilot.log
            if [[ "$nb" == 32 && "$es" == 3 ]]; then
                ./obj_dir/Vadder_verification_top 1000000 trial | tee trial.log
            fi
        )
    done
done
printf COMPLETE > "$run/integration/status.txt"
