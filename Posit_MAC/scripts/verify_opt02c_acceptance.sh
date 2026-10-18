#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
study=results/opt02c_20261018
[[ $(cat "$study/verify/candidate/status.txt") == COMPLETE ]]
cd "$study/verify/candidate/nf/32_3"
[[ ! -e acceptance.log ]] || exit 2
export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
./obj_fast/Vposit_mac_nf 10000000 acceptance > acceptance.log
tail -n 1 acceptance.log
