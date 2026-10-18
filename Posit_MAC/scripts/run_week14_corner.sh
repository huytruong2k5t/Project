#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
run="$PWD/results/week14/corner"
build="$PWD/results/week14/builds/f32_3"
[[ -e "$run/week14_corner.cpp" && ! -e "$run/corner" ]] || exit 2
export TMPDIR="$PWD/results/week14/tmp"
g++ -O3 -std=c++17 -DVM_COVERAGE=1 -DVM_TIMING=0 -DVM_SC=0 \
 -I"$build/obj" -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd \
 -I"$build/src/tb" -I"$build/src/l1/include" "$run/week14_corner.cpp" \
 "$build/obj/Vweek13_fused_tb__ALL.a" "$build/obj/verilated.o" \
 "$build/obj/verilated_cov.o" "$build/obj/verilated_threads.o" "$build/obj/verilated_dpi.o" \
 -pthread -latomic -o "$run/corner" > "$run/build.log" 2>&1
sha256sum "$run/week14_corner.cpp" "$run/corner" "$build/obj/Vweek13_fused_tb__ALL.a" > "$run/source_binary.sha256"
for n in {0..8}; do
  "$run/corner" 20000 "$run/n$n" "$n" 1 "$((2026102000+n))" > "$run/n$n.log" 2>&1
done
echo COMPLETE > "$run/status.txt"
echo 'W14 F CORNER ALL9 n PASS 180000 completed'
