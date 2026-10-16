#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out="${PREPACK_RESULTS_DIR:-results/prepack_refactor_20261016}"
[[ "$out" =~ ^results/[a-zA-Z0-9_/-]+$ && "$out" != *..* ]] || exit 2
[[ ! -f "$out/summary.json" ]] || { echo 'Choose a fresh PREPACK_RESULTS_DIR'; exit 2; }
mkdir -p "$out"/{tmp,leaf,lint}
export TMPDIR="$PWD/$out/tmp"
verilator --version > "$out/verilator.txt"
g++ --version > "$out/compiler.txt"
python3 scripts/prepare_prepack_refactor.py
python3 - <<'PY' > "$out/lint_cases.tsv"
import json,os
from pathlib import Path
for i, row in enumerate(json.load(open(Path(os.environ.get('PREPACK_RESULTS_DIR','results/prepack_refactor_20261016'))/'cases.json'))):
    print(i,*row,sep='\t')
PY
while IFS=$'\t' read -r id f fw en aw sw fin; do
    verilator --lint-only --timing -Wall --top-module mul_prepack_norm_comb \
        -GFRAC_MAX="$f" -GFRAC_W="$fw" "-GEXACT_EN=1'b$en" -GACC_W="$aw" -GSF_W="$sw" -GF_IN="$fin" \
        "$out/source/candidate/mul_prepack_norm_comb.sv" > "$out/lint/case_$id.log" 2>&1
done < "$out/lint_cases.tsv"
verilator --cc --exe --main --timing --assert -Wno-fatal --top-module tb_prepack_refactor \
    --Mdir "$out/leaf/obj_dir" "$out/source/candidate/mul_prepack_norm_comb.sv" \
    "$out/mul_prepack_norm_before.sv" tb/prepack_refactor_checker.sv "$out/tb_prepack_refactor.sv" > "$out/leaf/build.log" 2>&1
make -C "$out/leaf/obj_dir" -f Vtb_prepack_refactor.mk CURDIR=. -j4 >> "$out/leaf/build.log" 2>&1
"$out/leaf/obj_dir/Vtb_prepack_refactor" > "$out/leaf/simulate.log"
echo PREPACK_LEAF_COMPLETE
