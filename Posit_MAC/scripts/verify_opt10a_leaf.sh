#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out=results/opt10a_20261018/leaf
[[ ! -e "$out" ]] || exit 2
mkdir -p "$out/source" "$out/tmp" "$out/lint"
export TMPDIR="$PWD/$out/tmp"
cp results/opt10a_20261018/source/sticky/* "$out/source/"
sed 's/module posit_pack_prepare #(/module posit_pack_prepare_baseline #(/' \
    results/opt10a_20261018/source/baseline/posit_pack_prepare.sv > "$out/source/posit_pack_prepare_baseline.sv"
cp tb/opt10a_prepare_checker.sv tb/tb_opt10a_prepare.sv "$out/source/"
for nb in $(seq 4 32); do
 for es in $(seq 0 $((nb-4))); do
  fin=$((nb-1-es))
  verilator --lint-only --timing -Wall --top-module posit_pack_prepare \
    -GNB="$nb" -GES="$es" -GF_IN="$fin" "$out/source/posit_pack_prepare.sv" \
    "$out/source/dyn_right_shifter.sv" > "$out/lint/${nb}_${es}.log" 2>&1
 done
done
(
 cd "$out"
 sha256sum source/* > source.sha256
 verilator --cc --exe --main --timing --timescale 1ns/1ps -Wall -Wno-fatal \
   --top-module tb_opt10a_prepare -Isource --Mdir obj source/*.sv > build.log 2>&1
 make -C obj -f Vtb_opt10a_prepare.mk CURDIR=. -j4 >> build.log 2>&1
 ./obj/Vtb_opt10a_prepare > simulate.log
 grep 'PREPARE MATRIX PASS' simulate.log
 echo COMPLETE > status.txt
)
