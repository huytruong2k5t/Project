#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export TMPDIR="$PWD/results/week14/tmp"
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
python3 scripts/prepare_week14_closure.py
run="$PWD/results/week14/closure"
link_driver() {
 local profile="$1" source="$2" out="$3" es="$4"
 local build="$PWD/results/week14/builds/$profile"
 local top=Vposit_mac_nf;[[ "$profile" != f32_3 ]] || top=Vweek13_fused_tb
 g++ -O3 -std=c++17 -DVM_COVERAGE=1 -DVM_TIMING=0 -DVM_SC=0 -DPROFILE_NB=32 -DPROFILE_ES="$es" \
  -I"$build/obj" -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd \
  -I"$build/src/tb" -I"$build/src/l1/include" -I"$build/src/l0" "$source" \
  "$build/obj/${top}__ALL.a" "$build/obj/verilated.o" "$build/obj/verilated_cov.o" \
  "$build/obj/verilated_threads.o" "$build/obj/verilated_dpi.o" -L"$build/src/l0" -lsoftposit \
  -pthread -latomic -o "$out" > "$out.build.log" 2>&1
}
link_driver f32_3 "$run/f_directed.cpp" "$run/f_directed" 3
for ops in 0 1; do
 "$run/f_directed" 30000 "$run/f_ops$ops" 3 "$ops" "$((2026102100+ops))" > "$run/f_ops$ops.log" 2>&1
done
for profile in nf32_3 nf32_2; do
 es=3;[[ "$profile" != nf32_2 ]] || es=2
 link_driver "$profile" "$run/nf_mixed.cpp" "$run/$profile" "$es"
 export LD_LIBRARY_PATH="$PWD/results/week14/builds/$profile/src/l0"
 "$run/$profile" 100000 "$run/$profile" > "$run/$profile.log" 2>&1
done
echo COMPLETE > "$run/status.txt"
echo 'COVERAGE DIRECTED/EXACT-MIXED SUITES COMPLETE'
