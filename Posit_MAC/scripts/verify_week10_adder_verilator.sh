#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
project_dir="$PWD"
export LD_LIBRARY_PATH="$project_dir/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p results/week10_adder/verilator
printf RUNNING > results/week10_adder/verilator/run_status.txt
verilator --version > results/week10_adder/verilator_version.log
g++ --version > results/week10_adder/compiler.log
bash scripts/verify_week10_adder_lint.sh
sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser_comb
         posit_add_align posit_add_arith posit_add_normalize posit_add
         posit_pack_prepare posit_pack_finish posit_pack_comb)
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    run_dir="$project_dir/results/week10_adder/verilator/${nb}_${es}"
    mkdir -p "$run_dir/src/l1" "$run_dir/tmp"
    export TMPDIR="$run_dir/tmp"
    rtl=()
    for module in "${sources[@]}"; do
        cp -- "rtl/$module.sv" "$run_dir/src/"
        rtl+=("src/$module.sv")
    done
    cp -- rtl/posit_mac.vh tb/adder_verification_top.sv tb/week10_adder_harness.cpp tb/week10_add_reference.hpp l0/softposit_api.h l0/libsoftposit.so "$run_dir/src/"
    cp -- l1/include/*.hpp "$run_dir/src/l1/"
    rtl+=(src/adder_verification_top.sv)
    (
        cd "$run_dir"
        sha256sum src/*.sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.so src/l1/*.hpp > source.sha256
        verilator --cc --exe --no-timing --coverage -Wall -Wno-fatal \
            --top-module adder_verification_top -Isrc "-GNB=$nb" "-GES=$es" \
            --Mdir obj_dir \
            -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
            -LDFLAGS "-L../src -lsoftposit" \
            "${rtl[@]}" src/week10_adder_harness.cpp > build.log 2>&1
        make -C obj_dir -f Vadder_verification_top.mk CURDIR=. -j2 >> build.log 2>&1
        sha256sum obj_dir/Vadder_verification_top > binary.sha256
        ./obj_dir/Vadder_verification_top 50000 pilot | tee pilot.log
        if [[ "$nb" == 32 ]]; then
            ./obj_dir/Vadder_verification_top 10000000 acceptance | tee acceptance.log
        fi
    )
    echo "PROFILE FINISHED $nb/$es"
done
printf COMPLETE > results/week10_adder/verilator/run_status.txt
