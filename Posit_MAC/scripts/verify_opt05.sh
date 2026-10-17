#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
variant="${1:?baseline|a|ab|abc_sub|abc_tree}"
case "$variant" in baseline|a|ab|abc_sub|abc_tree) ;; *) exit 2;; esac
study=results/opt05_20261017
out="$study/verify/$variant"
[[ ! -e "$out" ]] || { echo 'Preserve existing evidence'; exit 2; }
mkdir -p "$out/lint" "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
verilator --version > "$out/verilator.txt"
g++ --version > "$out/compiler.txt"
for w in $(seq 1 27); do
    s=0; while (( (1<<s) < w+1 )); do s=$((s+1)); done
    for sw in "$s" "$((s+2))"; do
        verilator --lint-only --timing -Wall --top-module sac_step_comb -GW_X="$w" -GS_W="$sw" \
            "$study/source/$variant/sac_step_comb.sv" "$study/source/$variant/dyn_left_shifter.sv" \
            "$study/source/$variant/lod_lzd_core.sv" > "$out/lint/${w}_${sw}.log" 2>&1
    done
done
echo '54 SAC strict lint configurations PASS'
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    fw=$((nb-3-es<12?nb-3-es:12))
    run="$out/nf/${nb}_${es}"
    mkdir -p "$run/src/l1" "$run/tmp"
    cp "$study/source/$variant/"* "$run/src/"
    cp tb/nf_coverage_harness.cpp tb/nf_coverage_corpus.hpp tb/nf_coverage.vlt tb/week11_model.hpp \
       tb/week10_add_reference.hpp tb/week9_exact_reference.hpp l0/softposit_api.h l0/libsoftposit.so "$run/src/"
    cp l1/include/*.hpp "$run/src/l1/"
    (
        cd "$run"
        export TMPDIR="$PWD/tmp"
        export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        sha256sum src/*sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.vlt src/*.so src/l1/*.hpp > source.sha256
        verilator --lint-only --timing -Wall --top-module posit_mac_nf -Isrc \
            -GNB="$nb" -GES="$es" -GFRAC_W="$fw" src/*.sv > lint.log 2>&1
        verilator --cc --exe --no-timing --coverage-line -Wall -Wno-fatal --top-module posit_mac_nf \
            -Isrc -GNB="$nb" -GES="$es" -GFRAC_W="$fw" --Mdir obj_fast \
            -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
            -LDFLAGS '-L../src -lsoftposit' src/nf_coverage.vlt src/*.sv src/nf_coverage_harness.cpp > build.log 2>&1
        make -C obj_fast -f Vposit_mac_nf.mk CURDIR=. -j4 >> build.log 2>&1
        sha256sum obj_fast/Vposit_mac_nf > binary.sha256
        ./obj_fast/Vposit_mac_nf 20000 pilot > pilot.log
        tail -n 1 pilot.log
    )
done
echo COMPLETE > "$out/status.txt"
