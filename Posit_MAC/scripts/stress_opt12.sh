#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
variant="${1:-sentinel}"
top="${2:-nf}"
goal="${3:-10000000}"
[[ "$variant" == adjacent || "$variant" == sentinel || "$variant" == negate ]] || exit 2
[[ "$top" == nf || "$top" == f ]] || exit 2
[[ "$goal" =~ ^[1-9][0-9]*$ ]] || exit 2
study="$PWD/results/opt120_20261018"
if [[ "$top" == nf ]]; then
  run="$study/verify/$variant/nf/32_3"
  exe=./obj_fast/Vposit_mac_nf
else
  run="$study/fused/$variant"
  exe=./obj_fast/Vweek13_fused_tb
fi
cd "$run"
[[ -x "$exe" && ! -e "stress_${goal}.log" ]] || exit 2
export TMPDIR="$PWD/tmp"
export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
TIMEFORMAT='wall_seconds=%R user_seconds=%U system_seconds=%S'
{ time "$exe" "$goal" "stress_$goal" > "stress_${goal}.log"; } 2> "stress_${goal}_time.txt"
tail -n 1 "stress_${goal}.log"
cat "stress_${goal}_time.txt"
echo COMPLETE > "stress_${goal}_status.txt"
