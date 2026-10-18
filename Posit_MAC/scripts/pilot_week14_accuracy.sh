#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")/.."
run="$PWD/results/week14/accuracy"
[[ ! -e "$run" ]] || exit 2
mkdir -p "$run/src/tb" "$run/src/l1/include" "$run/tmp"
export TMPDIR="$run/tmp"
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
cp tb/week14_accuracy.cpp tb/week11_model.hpp tb/week10_add_reference.hpp \
   tb/week9_exact_reference.hpp tb/week12_fused_reference.hpp "$run/src/tb/"
cp l1/include/*.hpp "$run/src/l1/include/"
cp scripts/check_week14_accuracy.py "$run/checker_source.py"
sha256sum "$run/src/tb/"* "$run/src/l1/include/"* "$run/checker_source.py" > "$run/source.sha256"
g++ -O3 -std=c++17 -I"$run/src/tb" -I"$run/src/l1/include" \
    "$run/src/tb/week14_accuracy.cpp" -o "$run/collector" > "$run/build.log" 2>&1
for n in {0..8}; do
  "$run/collector" "$n" 100000 "$run/n$n" "$((2026101900+n))" > "$run/n$n.log" 2>&1
done
python3 scripts/check_week14_accuracy.py > "$run/python_check.log" 2>&1
cat "$run/python_check.log"
echo COMPLETE > "$run/status.txt"
