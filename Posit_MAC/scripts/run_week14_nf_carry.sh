#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export TMPDIR="$PWD/results/week14/tmp"
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
python3 scripts/prepare_week14_nf_carry.py
run="$PWD/results/week14/nf_carry"
for es in 3 2; do
 build="$PWD/results/week14/builds/nf32_$es"
 top=Vposit_mac_nf
 g++ -O3 -std=c++17 -DVM_COVERAGE=1 -DVM_TIMING=0 -DVM_SC=0 -DPROFILE_NB=32 -DPROFILE_ES="$es" \
  -I"$build/obj" -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd \
  -I"$build/src/tb" -I"$build/src/l1/include" -I"$build/src/l0" "$run/nf_carry.cpp" \
  "$build/obj/${top}__ALL.a" "$build/obj/verilated.o" "$build/obj/verilated_cov.o" \
  "$build/obj/verilated_threads.o" "$build/obj/verilated_dpi.o" -L"$build/src/l0" -lsoftposit \
  -pthread -latomic -o "$run/nf32_$es" > "$run/build_$es.log" 2>&1
 export LD_LIBRARY_PATH="$build/src/l0"
 "$run/nf32_$es" 20000 "$run/nf32_$es" > "$run/nf32_$es.log" 2>&1
done
echo COMPLETE > "$run/status.txt"
