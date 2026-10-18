#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export TMPDIR="$PWD/results/week14/tmp"
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
phase="${1:?pilot or main}"
run="$PWD/results/week14/accuracy_final"
if [[ "$phase" == pilot ]]; then
 python3 scripts/prepare_week14_accuracy_final.py
 g++ -O3 -std=c++17 -Itb -Il1/include "$run/collector.cpp" -o "$run/collector" > "$run/build.log" 2>&1
 mkdir "$run/pilot"
 for n in 2 4 8 0 1 3 5 6 7; do
  "$run/collector" "$n" 100000 "$run/pilot/n$n" "$((2026101900+n))" > "$run/pilot/n$n.log" 2>&1
 done
 python3 scripts/audit_week14_accuracy_final.py pilot
elif [[ "$phase" == main ]]; then
 python3 scripts/audit_week14_accuracy_final.py preflight
 mkdir "$run/main"
 for n in 2 4 8 0 1 3 5 6 7; do
  "$run/collector" "$n" 1000000 "$run/main/n$n" "$((2026101900+n))" > "$run/main/n$n.log" 2>&1
  echo "ACCURACY MAIN n=$n COMPLETE 1000000"
 done
 python3 scripts/audit_week14_accuracy_final.py main
else
 exit 2
fi
