#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
run=results/primitive_v2_20261016
mkdir -p "$run/lint" "$run/tmp"
export TMPDIR="$PWD/$run/tmp"
verilator --version > "$run/lint/version.txt"
date -u +%FT%TZ > "$run/lint/start_utc.txt"
sha256sum "$run"/source/*/*.sv > "$run/lint/source.sha256"
count=0
for variant in group4 reverse radix4 native selected; do
  [[ -f "$run/source/$variant/dyn_left_shifter.sv" ]] || continue
  for n in 1 2 3 5 8 12 26 27 29 30 31 32 33 59 60 64; do
    s=0; p=1; while ((p<n)); do p=$((p*2));s=$((s+1));done
    ((s>0)) || s=1
    for w in "$s" "$((s+1))"; do
      for top in dyn_left_shifter dyn_right_shifter; do
        args=(-GN="$n" -GSHIFT_W="$w")
        if [[ "$top" == dyn_right_shifter ]]; then args+=(-GARITH=0); fi
        verilator --lint-only --timing -Wall --top-module "$top" "${args[@]}" \
          "$run/source/$variant/$top.sv" > "$run/lint/${variant}_${top}_${n}_${w}.log" 2>&1
        count=$((count+1))
      done
    done
  done
done
for variant in group4 group4_mixed selected; do
[[ -f "$run/source/$variant/lod_lzd_core.sv" ]] || continue
for n in 2 3 5 8 12 26 27 29 30 31 32 33 53 54 59 60 64; do
  s=0;p=1;while ((p<n));do p=$((p*2));s=$((s+1));done
  for mode in 0 1; do
    for w in "$s" "$((s+1))"; do
      verilator --lint-only --timing -Wall --top-module lod_lzd_core -GN="$n" -GS="$w" -GMODE="$mode" \
        "$run/source/$variant/lod_lzd_core.sv" > "$run/lint/${variant}_lod_${n}_${w}_${mode}.log" 2>&1
      count=$((count+1))
    done
  done
done
done
echo "V2_STRICT_LINT_PASS invocations=$count" | tee "$run/lint/summary.txt"
date -u +%FT%TZ > "$run/lint/end_utc.txt"
