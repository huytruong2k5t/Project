#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
python3 - <<'PY'
from scripts.audit_week14 import R,O,sha
import json
p=O/'closure/ex0_final_plan.json'
assert not p.exists()
e=O/'builds/nf32_3_ex0/obj/Vposit_mac_nf'
p.write_text(json.dumps(dict(parent_sha256=sha(O/'matrix_freeze.json'),binary_sha256=sha(e),n=3,ops=1,goal=20000,seed=2026102203),indent=2)+'\n')
PY
export LD_LIBRARY_PATH="$PWD/results/week14/builds/nf32_3_ex0/src/l0"
results/week14/builds/nf32_3_ex0/obj/Vposit_mac_nf 20000 "$PWD/results/week14/closure/ex0_final" 3 1 2026102203 > results/week14/closure/ex0_final.log 2>&1
