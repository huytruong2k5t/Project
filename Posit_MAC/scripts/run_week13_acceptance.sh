#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_week13_fused.sh 100000 pilot all
bash scripts/verify_week13_fused.sh 10000000 main line
