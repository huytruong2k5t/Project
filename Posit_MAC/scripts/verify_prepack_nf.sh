#!/usr/bin/env bash
# Existing coverage corpus/oracles, isolated outputs and frozen RTL snapshots.
set -euo pipefail
cd "$(dirname "$0")/.."
out="${PREPACK_RESULTS_DIR:-results/prepack_refactor_20261016}"
[[ "$out" =~ ^results/[a-zA-Z0-9_/-]+$ && "$out" != *..* ]] || exit 2
[[ ! -f "$out/summary.json" ]] || { echo 'Choose a fresh PREPACK_RESULTS_DIR'; exit 2; }
grep -q 'PREPACK ALL PASS' "$out/leaf/simulate.log"
for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    fw=$((nb-3-es<12?nb-3-es:12))
    run="$out/nf/${nb}_${es}"
    if [[ -f "$run/pilot.log" ]] && grep -q 'NF COVERAGE HARNESS PASS' "$run/pilot.log"; then
        (cd "$run"; sha256sum --check source.sha256 > resume_hash_check.log)
        cmp "$run/src/mul_prepack_norm_comb.sv" "$out/source/candidate/mul_prepack_norm_comb.sv"
        echo "REUSE_VERIFIED_PILOT $nb/$es"
        continue
    fi
    mkdir -p "$run/src/l1" "$run/tmp"
    cp "$out"/source/baseline/* "$run/src/"
    cp "$out"/source/candidate/mul_prepack_norm_comb.sv "$run/src/"
    cp tb/nf_coverage_harness.cpp tb/nf_coverage_corpus.hpp tb/nf_coverage.vlt tb/week11_model.hpp \
       tb/week10_add_reference.hpp tb/week9_exact_reference.hpp l0/softposit_api.h l0/libsoftposit.so "$run/src/"
    cp l1/include/*.hpp "$run/src/l1/"
    (
        cd "$run"
        export TMPDIR="$PWD/tmp"
        export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        sha256sum src/*sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.vlt src/*.so src/l1/*.hpp > source.sha256
        # Main accepted NF is EXACT_EN=1. Disabled feature is checked at leaf;
        # whole-NF32 disabled has a pre-existing sbm_shift unused-upper-bits warning.
        for en in 1; do
            verilator --lint-only --timing -Wall --top-module posit_mac_nf -Isrc \
                -GNB="$nb" -GES="$es" -GFRAC_W="$fw" "-GEXACT_EN=1'b$en" src/*.sv > "lint_en${en}.log" 2>&1
        done
        verilator --cc --exe --no-timing --coverage-line -Wall -Wno-fatal --top-module posit_mac_nf \
            -Isrc -GNB="$nb" -GES="$es" -GFRAC_W="$fw" --Mdir obj_fast \
            -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=$nb -DPROFILE_ES=$es" \
            -LDFLAGS '-L../src -lsoftposit' src/nf_coverage.vlt src/*.sv src/nf_coverage_harness.cpp > build.log 2>&1
        make -C obj_fast -f Vposit_mac_nf.mk CURDIR=. -j4 >> build.log 2>&1
        sha256sum obj_fast/Vposit_mac_nf > binary.sha256
        goal=20000
        if [[ "$nb $es" == '32 3' ]]; then goal=100000; fi
        ./obj_fast/Vposit_mac_nf "$goal" pilot > pilot.log
        tail -n 1 pilot.log
    )
done
echo COMPLETE > "$out/pilot_status.txt"
echo PREPACK_NF_PILOTS_ALL_PASS
(
    cd "$out/nf/32_3"
    export TMPDIR="$PWD/tmp"
    export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ./obj_fast/Vposit_mac_nf 10000000 acceptance > acceptance.log
    tail -n 1 acceptance.log
)
echo COMPLETE > "$out/large_status.txt"
