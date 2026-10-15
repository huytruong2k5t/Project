#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/rtl_paths.sh"
set -euo pipefail
cd "$(dirname "$0")/.."
run="${W13_RESULTS_DIR:-results/week13}/pipe"
[[ "$run" =~ ^results/[a-zA-Z0-9_/-]+$ && "$run" != *..* ]] || exit 2
mkdir -p "$run/src/rtl" "$run/src/tb" "$run/src/l1/include" "$run/tmp"
export TMPDIR="$PWD/$run/tmp"
for n in lod_lzd_core fused_prepare_comb fused_align_comb fused_arith_comb fused_abs_borrow_comb fused_norm_comb fused_add_pipe; do cp "$(rtl_path "$n")" "$run/src/rtl/"; done
cp rtl/posit_mac.vh "$run/src/rtl/"
cp tb/week13_pipe_harness.cpp tb/week12_fused_reference.hpp "$run/src/tb/"
cp l1/include/*.hpp "$run/src/l1/include/"
cd "$run"
sha256sum src/rtl/* src/tb/* src/l1/include/* > source.sha256
verilator --cc --exe --no-timing --assert --coverage -Wall -Wno-fatal --top-module fused_add_pipe -Isrc/rtl --Mdir obj_dir -CFLAGS '-O3 -std=c++17 -I../src/l1/include -I../src/tb' src/rtl/*.sv src/tb/week13_pipe_harness.cpp > build.log 2>&1
make -C obj_dir -f Vfused_add_pipe.mk CURDIR=. -j4 >> build.log 2>&1
./obj_dir/Vfused_add_pipe | tee pipe.log
