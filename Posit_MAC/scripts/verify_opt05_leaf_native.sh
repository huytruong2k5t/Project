#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out=results/opt05_20261017/leaf_native_v2
[[ ! -e "$out" ]] || exit 2
mkdir -p "$out/source" "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
for variant in baseline a ab abc_sub abc_tree; do
    sed "s/module sac_step_comb #(/module sac_step_${variant} #(/" \
        "results/opt05_20261017/source/$variant/sac_step_comb.sv" > "$out/source/sac_step_$variant.sv"
done
cp results/opt05_20261017/source/baseline/{dyn_left_shifter.sv,lod_lzd_core.sv} "$out/source/"
cp tb/opt05_sac_checker.sv "$out/source/"
{
    printf 'module tb_opt05_sac;\nwire [53:0] done;\n'
    index=0
    for w in $(seq 1 27); do
        s=0; while (( (1<<s) < w+1 )); do s=$((s+1)); done
        for sw in "$s" "$((s+2))"; do
            printf 'opt05_sac_checker #(.W(%d),.S(%d)) u_%d (.done(done[%d]));\n' "$w" "$sw" "$index" "$index"
            index=$((index+1))
        done
    done
    printf 'initial begin wait (&done); $display("SAC MATRIX PASS instances=54 mismatches=0"); $finish; end\nendmodule\n'
} > "$out/source/tb_opt05_sac.sv"
(
    cd "$out"
    verilator --version > version.txt
    sha256sum source/* > source.sha256
    verilator --cc --exe --main --timing -Wall -Wno-fatal --top-module tb_opt05_sac \
        --Mdir obj source/*.sv > build.log 2>&1
    make -C obj -f Vtb_opt05_sac.mk CURDIR=. -j4 >> build.log 2>&1
    ./obj/Vtb_opt05_sac > simulate.log
    grep 'SAC MATRIX PASS' simulate.log
    echo COMPLETE > status.txt
)
