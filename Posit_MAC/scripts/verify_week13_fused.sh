#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out="${W13_RESULTS_DIR:-results/week13}"
[[ "$out" =~ ^results/[a-zA-Z0-9_/-]+$ && "$out" != *..* ]] || exit 2
mkdir -p "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
export VERILATOR_CACHE_REPORT=0
mapfile -t rtl < scripts/week13_sources.txt
verilator --version > "$out/verilator_version.txt"
g++ --version > "$out/compiler.txt"
verilator --lint-only --timing --assert -Wall --top-module posit_mac_f -Irtl "${rtl[@]}" > "$out/lint.log" 2>&1
printf 'W13 STRICT LINT PASS\n'
run="$out/verilator"
mkdir -p "$run/src/rtl" "$run/src/tb" "$run/src/l1/include" "$run/tmp"
export TMPDIR="$PWD/$run/tmp"
for f in "${rtl[@]}"; do cp -- "$f" "$run/src/rtl/"; done
cp rtl/posit_mac.vh "$run/src/rtl/"
cp tb/*.hpp tb/week13_fused_harness.cpp tb/week13_fused_tb.sv "$run/src/tb/"
cp l1/include/*.hpp "$run/src/l1/include/"
(
 cd "$run"
 sha256sum src/rtl/* src/tb/* src/l1/include/* > source.sha256
 args=(); for f in src/rtl/*.sv; do args+=("$f"); done
 cov=--coverage; obj=obj_dir
 if [[ "${3:-all}" == line ]]; then cov=--coverage-line; obj=obj_fast; fi
 verilator --cc --exe --no-timing --assert "$cov" -Wall -Wno-fatal \
   --top-module week13_fused_tb -Isrc/rtl --Mdir "$obj" \
   -CFLAGS '-O3 -std=c++17 -I../src/l1/include -I../src/tb' \
   "${args[@]}" src/tb/week13_fused_tb.sv src/tb/week13_fused_harness.cpp > build.log 2>&1
 make -C "$obj" -f Vweek13_fused_tb.mk CURDIR=. -j4 >> build.log 2>&1
 sha256sum "$obj/Vweek13_fused_tb" > binary.sha256
 "./$obj/Vweek13_fused_tb" "${1:-100000}" "${2:-pilot}" | tee "${2:-pilot}.log"
)
