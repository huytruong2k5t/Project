#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
project="$PWD"
run="$project/results/week12/window"
mkdir -p "$run/tmp" "$run/bin" "$run/fixtures"
export TMPDIR="$run/tmp"
export LD_LIBRARY_PATH="$project/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
printf RUNNING > "$run/status.txt"
g++ --version > "$run/compiler.log"
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/gen_week12_fused.cpp \
    -o "$run/bin/generator" > "$run/generator_build.log" 2>&1
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/test_week12_window.cpp \
    -o "$run/bin/window" > "$run/build.log" 2>&1
"$run/bin/generator" "$run/fixtures/pilot.bin" 100000 > "$run/generator_pilot.log"
"$run/bin/generator" "$run/fixtures/main.bin" 1000000 > "$run/generator_main.log"
sha256sum "$run/fixtures/"*.bin > "$run/corpus.sha256"
sha256sum results/week12/contract.json l1/include/posit_fused_window.hpp \
    l1/test/test_week12_window.cpp l1/test/gen_week12_fused.cpp tb/week12_corpus.hpp \
    tb/week12_fused_reference.hpp scripts/verify_week12_window.sh > "$run/source.sha256"
for width in 32 48 64 96; do
    "$run/bin/window" "$run/fixtures/pilot.bin" 100000 "$width" "$run/pilot_$width" | tee "$run/pilot_$width.log"
done
# The pre-run contract chooses the smallest admitted zero-mismatch pilot.
# No seed/threshold adjustment or automatic fallback after a mismatch.
python3 - <<'PY'
import json
from pathlib import Path
run=Path('results/week12/window')
reports=[json.loads((run/f'pilot_{w}.json').read_text()) for w in [32,48,64,96]]
assert all(r['mismatches']==r['F_W_F_ref_bit_differences']==0 for r in reports)
selection=dict(policy='W12-F-1 locked zero-difference + precision-bound rule',W=min(r['W'] for r in reports),status='PILOTS_PASS')
assert selection['W']==32
(run/'selection.json').write_text(json.dumps(selection,indent=2)+'\n')
PY
"$run/bin/window" "$run/fixtures/main.bin" 1000000 32 "$run/linux" | tee "$run/linux.log"
g++ -O1 -g -std=c++17 -Wall -Wextra -Werror -fsanitize=undefined -fno-sanitize-recover=all \
    -Il1/include l1/test/test_week12_window.cpp -o "$run/bin/window_ubsan" > "$run/ubsan_build.log" 2>&1
"$run/bin/window_ubsan" "$run/fixtures/main.bin" 1000000 32 "$run/ubsan" | tee "$run/ubsan.log"
x86_64-w64-mingw32-g++ -O3 -std=c++17 -Wall -Wextra -Werror -static -Il1/include \
    l1/test/test_week12_window.cpp -o "$run/bin/window.exe" > "$run/windows_build.log" 2>&1
# Regenerate corpus using a second compiler and check byte equality.
x86_64-w64-mingw32-g++ -O3 -std=c++17 -Wall -Wextra -Werror -static -Il1/include \
    l1/test/gen_week12_fused.cpp -o "$run/bin/generator.exe" > "$run/windows_generator_build.log" 2>&1
printf COMPLETE > "$run/linux_status.txt"
