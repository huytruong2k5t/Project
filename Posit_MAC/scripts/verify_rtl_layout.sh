#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/rtl_paths.sh"
cd "$_rtl_project"
out="${LAYOUT_RESULTS_DIR:-results/layout_cleanup_20261015}"
[[ "$out" =~ ^results/[a-zA-Z0-9_/-]+$ && "$out" != *..* ]] || exit 2
mkdir -p "$out/lint" "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
verilator --version > "$out/version.txt"
g++ --version > "$out/compiler.txt"
for f in scripts/*.sh; do bash -n "$f"; done
mapfile -t rtl < rtl/production.f
for f in "${rtl[@]}"; do
    [[ -f "$f" && "$(rtl_path "$(basename "$f")")" == "$PWD/$f" ]] || exit 2
done
for profile in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$profile"
    fw=$((nb-3-es<12?nb-3-es:12))
    for top in posit_mul_iter posit_mac_nf posit_add posit_add_comb; do
        args=("-GNB=$nb" "-GES=$es")
        if [[ "$top" != posit_add* ]]; then args+=("-GFRAC_W=$fw"); fi
        verilator --lint-only --timing --assert -Wall -Irtl --top-module "$top" \
            "${args[@]}" "${rtl[@]}" > "$out/lint/${top}_${nb}_${es}.log" 2>&1
    done
done
echo 'LAYOUT_LINT_PASS 16 profiles'
# Run the actual relocated F runner, keeping prior W13 evidence untouched.
W13_RESULTS_DIR="$out/fused" bash scripts/verify_week13_fused.sh 10000 smoke line
# NF replay uses the existing independent oracle/harness in a fresh snapshot.
for profile_es in ${LAYOUT_NF_ES_LIST:-3}; do
[[ "$profile_es" == 2 || "$profile_es" == 3 ]] || exit 2
run="$out/nf"
if [[ "${LAYOUT_NF_ES_LIST:-3}" != 3 ]]; then run="$out/nf_es${profile_es}"; fi
mkdir -p "$run/src/l1" "$run/tmp"
for file in "${rtl[@]}"; do cp -- "$file" "$run/src/"; done
cp rtl/posit_mac.vh tb/week11_mac_harness.cpp tb/week11_model.hpp \
    tb/week10_add_reference.hpp tb/week9_exact_reference.hpp \
    l0/softposit_api.h l0/libsoftposit.so "$run/src/"
cp l1/include/*.hpp "$run/src/l1/"
(
 cd "$run"
 export TMPDIR="$PWD/tmp"
 export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
 sha256sum src/*.sv src/*.vh src/*.cpp src/*.hpp src/*.h src/*.so src/l1/*.hpp > source.sha256
 verilator --cc --exe --no-timing --coverage-line -Wall -Wno-fatal \
     --top-module posit_mac_nf -Isrc -GNB=32 -GES="$profile_es" -GFRAC_W=12 --Mdir obj_dir \
     -CFLAGS "-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=32 -DPROFILE_ES=$profile_es" \
     -LDFLAGS '-L../src -lsoftposit' src/*.sv src/week11_mac_harness.cpp > build.log 2>&1
 make -C obj_dir -f Vposit_mac_nf.mk CURDIR=. -j4 >> build.log 2>&1
 ./obj_dir/Vposit_mac_nf 10000 smoke | tee smoke.log
)
done
echo "LAYOUT_SMOKE_PASS NF=10000/profile ES=${LAYOUT_NF_ES_LIST:-3} F=10000"
