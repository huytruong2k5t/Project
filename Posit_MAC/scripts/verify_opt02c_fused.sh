#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
study=results/opt02c_20261018
run="$study/fused"
[[ ! -e "$run" ]] || exit 2
mkdir -p "$run/src/rtl" "$run/src/tb" "$run/src/l1/include" "$run/tmp"
cp "$study/source/candidate/"* "$run/src/rtl/"
cp tb/*.hpp tb/week13_fused_harness.cpp tb/week13_fused_tb.sv "$run/src/tb/"
cp l1/include/*.hpp "$run/src/l1/include/"
(
 cd "$run"
 export TMPDIR="$PWD/tmp"
 verilator --version > verilator.txt
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
