#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
variant="${1:-sentinel}"
[[ "$variant" == adjacent || "$variant" == sentinel || "$variant" == negate ]] || exit 2
study=results/opt120_20261018
run="$study/fused/$variant"
[[ ! -e "$run" ]] || exit 2
mkdir -p "$run/src/rtl" "$run/src/tb" "$run/src/l1/include" "$run/tmp"
find "$study/source/$variant/rtl" -type f \( -name "*.sv" -o -name "*.vh" \) -exec cp {} "$run/src/rtl/" \;
cp tb/*.hpp tb/week13_fused_harness.cpp tb/week13_fused_tb.sv "$run/src/tb/"
cp l1/include/*.hpp "$run/src/l1/include/"
(
 cd "$run"
 export TMPDIR="$PWD/tmp"
 verilator --version > verilator.txt
 g++ --version > compiler.txt
 sha256sum src/rtl/* src/tb/* src/l1/include/* > source.sha256
 verilator --lint-only --timing --assert -Wall --top-module posit_mac_f -Isrc/rtl src/rtl/*.sv > lint.log 2>&1
 verilator --cc --exe --no-timing --assert --coverage-line -Wall -Wno-fatal \
   --top-module week13_fused_tb -Isrc/rtl --Mdir obj_fast \
   -CFLAGS '-O3 -std=c++17 -I../src/l1/include -I../src/tb' \
   src/rtl/*.sv src/tb/week13_fused_tb.sv src/tb/week13_fused_harness.cpp > build.log 2>&1
 make -C obj_fast -f Vweek13_fused_tb.mk CURDIR=. -j4 >> build.log 2>&1
 sha256sum obj_fast/Vweek13_fused_tb > binary.sha256
 ./obj_fast/Vweek13_fused_tb 100000 pilot > pilot.log
 tail -n 1 pilot.log


 echo COMPLETE > status.txt
)
