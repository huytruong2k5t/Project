#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run="$PWD/results/week14/replay_test";build="$PWD/results/week14/builds/f32_3"
export TMPDIR="$PWD/results/week14/tmp"
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
python3 scripts/prepare_week14_replay.py
g++ -O3 -std=c++17 -DVM_COVERAGE=1 -DVM_TIMING=0 -DVM_SC=0 \
 -I"$build/obj" -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd \
 -I"$build/src/tb" -I"$build/src/l1/include" "$run/injected.cpp" \
 "$build/obj/Vweek13_fused_tb__ALL.a" "$build/obj/verilated.o" \
 "$build/obj/verilated_cov.o" "$build/obj/verilated_threads.o" "$build/obj/verilated_dpi.o" \
 -pthread -latomic -o "$run/injected" > "$run/build.log" 2>&1
for attempt in first replay; do
  set +e
  "$run/injected" 20000 "$run/$attempt" 3 1 2026101803 > "$run/$attempt.log" 2>&1
  code=$?
  set -e
  [[ "$code" == 1 ]] || exit 2
done
python3 - <<'PY'
import json
from pathlib import Path
p=Path('results/week14/replay_test')
a=json.loads((p/'first.failure.json').read_text());b=json.loads((p/'replay.failure.json').read_text())
assert a==b and a['actual']^a['expected']==1
assert {'seed','serial','a','b','c_port','c_eff','acc_mode','acc_clr','state_before','state_actual','expected_flags','actual_flags'}<=a.keys()
(p/'summary.json').write_text(json.dumps(dict(status='PASS_NEGATIVE_TEST',injected_expected_error_rejected=True,replay_packet_identical=True,production_binary_modified=False))+'\n')
print('W14 NEGATIVE FAILURE/REPLAY PASS')
PY
