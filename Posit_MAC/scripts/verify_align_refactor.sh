#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
project="$PWD"
run="$project/results/align_refactor_20261015"
mkdir -p "$run/lint" "$run/integration"
verilator --version > "$run/lint/version.log"
g++ --version > "$run/integration/compiler.log"
printf RUNNING > "$run/lint/status.txt"
for format in '8 0' '16 1' '32 2' '32 3' '5 0' '6 1' '7 1' '16 10' '32 27'; do
    read -r nb es <<< "$format"
    verilator --lint-only --timing -Wall --top-module posit_add_align_candidate \
        "-GNB=$nb" "-GES=$es" rtl/posit_add_align_candidate.sv rtl/dyn_right_shifter.sv \
        > "$run/lint/leaf_${nb}_${es}.log" 2>&1
done
printf COMPLETE > "$run/lint/status.txt"
printf RUNNING > "$run/integration/status.txt"
export LD_LIBRARY_PATH="$project/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    folder="$run/integration/${nb}_${es}"
    mkdir -p "$folder/src/l1" "$folder/tmp"
    export TMPDIR="$folder/tmp"
    sources=(lod_lzd_core dyn_left_shifter dyn_right_shifter posit_parser_comb
        posit_add_arith posit_add_normalize posit_add posit_pack_prepare posit_pack_finish posit_pack_comb)
    rtl=()
    for module in "${sources[@]}"; do
        cp -- "rtl/$module.sv" "$folder/src/"
        rtl+=("src/$module.sv")
    done
    # Candidate substitutes only in the private integration source copy.
    sed 's/module posit_add_align_candidate #(/module posit_add_align #(/' \
        rtl/posit_add_align_candidate.sv > "$folder/src/posit_add_align.sv"
    rtl+=(src/posit_add_align.sv)
    cp -- rtl/posit_mac.vh tb/adder_verification_top.sv tb/week10_adder_harness.cpp \
        tb/week10_add_reference.hpp l0/softposit_api.h l0/libsoftposit.so "$folder/src/"
    cp -- l1/include/*.hpp "$folder/src/l1/"
    rtl+=(src/adder_verification_top.sv)
    (
        cd "$folder"
        sha256sum src/*.sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.so src/l1/*.hpp > source.sha256
        verilator --lint-only --timing -Wall --top-module adder_verification_top -Isrc \
            "-GNB=$nb" "-GES=$es" "${rtl[@]}" > lint.log 2>&1
        # Cycle harness has no time scheduler; only CK2Q assignment delays are intentionally ignored.
        # The preceding --timing strict lint checks the actual RTL without a warning waiver.
        verilator --cc --exe --no-timing --coverage -Wall -Wno-ASSIGNDLY --top-module adder_verification_top \
            -Isrc "-GNB=$nb" "-GES=$es" --Mdir obj_dir \
            -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
            -LDFLAGS "-L../src -lsoftposit" "${rtl[@]}" src/week10_adder_harness.cpp > build.log 2>&1
        make -C obj_dir -f Vadder_verification_top.mk CURDIR=. -j2 >> build.log 2>&1
        ./obj_dir/Vadder_verification_top 50000 pilot | tee pilot.log
        if [[ "$nb" == 32 && "$es" == 3 ]]; then
            ./obj_dir/Vadder_verification_top 1000000 trial | tee trial.log
        fi
    )
done
printf COMPLETE > "$run/integration/status.txt"
