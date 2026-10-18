#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
variant="${1:-sentinel}"
[[ "$variant" == adjacent || "$variant" == sentinel || "$variant" == negate ]] || exit 2
study=results/opt120_20261018
src="$study/source/$variant"
out="$study/unit/$variant"
[[ ! -e "$out" ]] || { echo 'Preserve existing evidence'; exit 2; }
mkdir -p "$out/lint" "$out/tmp" "$out/tb"
export TMPDIR="$PWD/$out/tmp"
verilator --version > "$out/verilator.txt"
g++ --version > "$out/compiler.txt"
sha256sum "$src"/rtl/parser/*.sv "$src"/rtl/common/*.sv "$src/rtl/posit_mac.vh" \
  tb/opt12_parser_checker.sv tb/tb_opt12_parser.sv > "$out/inputs.sha256"
for nb in $(seq 4 32); do
  for es in $(seq 0 $((nb-4))); do
    for top in posit_parser posit_parser_comb; do
      verilator --lint-only --timing -Wall --top-module "$top" -I"$src/rtl" \
        -GNB="$nb" -GES="$es" "$src"/rtl/common/{lod_lzd_core,dyn_left_shifter}.sv \
        "$src/rtl/parser/$top.sv" > "$out/lint/${top}_${nb}_${es}.log" 2>&1
    done
  done
done
echo "OPT12 STRICT LINT PASS $variant profiles=870"
sed 's/module posit_parser #(/module posit_parser_before #(/' \
  "$study/source/reference/rtl/parser/posit_parser.sv" > "$out/tb/posit_parser_before.sv"
verilator --cc --exe --main --timing --assert -Wno-fatal --top-module tb_opt12_parser \
  -I"$src/rtl" --Mdir "$out/obj" \
  "$src"/rtl/common/{lod_lzd_core,dyn_left_shifter}.sv "$src"/rtl/parser/*.sv \
  "$out/tb/posit_parser_before.sv" tb/opt12_parser_checker.sv tb/tb_opt12_parser.sv > "$out/build.log" 2>&1
make -C "$out/obj" -f Vtb_opt12_parser.mk CURDIR=. -j4 >> "$out/build.log" 2>&1
sha256sum "$out/obj/Vtb_opt12_parser" > "$out/binary.sha256"
"$out/obj/Vtb_opt12_parser" > "$out/simulate.log"
grep 'OPT12 PARSER MATRIX PASS' "$out/simulate.log"
echo COMPLETE > "$out/status.txt"
