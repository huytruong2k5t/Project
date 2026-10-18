#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -f rtl/production_freeze.json ]]; then python3 scripts/audit_rtl_release.py; fi
out="${1:-results/opt02c_20261018/active_checks}"
[[ "$out" =~ ^results/[a-zA-Z0-9_/-]+$ && "$out" != *..* ]] || exit 2
[[ ! -e "$out" ]] || { echo 'Preserve existing evidence'; exit 2; }
mkdir -p "$out/source/rtl" "$out/lint" "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
logroot="$PWD/$out"
mapfile -t paths < rtl/production.f
for path in "${paths[@]}"; do
    mkdir -p "$out/source/$(dirname "$path")"
    cp "$path" "$out/source/$path"
done
cp rtl/production.f rtl/posit_mac.vh "$out/source/rtl/"
verilator --version > "$out/verilator.txt"
g++ --version > "$out/compiler.txt"
(
 cd "$out/source"
 sha256sum "${paths[@]}" rtl/posit_mac.vh rtl/production.f > "$logroot/source.sha256"
 for format in '8 0' '16 1' '32 2' '32 3'; do
    read -r nb es <<< "$format"
    fw=$((nb-3-es<12?nb-3-es:12))
    for top in posit_mac_nf posit_add_comb posit_add; do
        args=("-GNB=$nb" "-GES=$es")
        if [[ "$top" == posit_mac_nf ]]; then args+=("-GFRAC_W=$fw"); fi
        verilator --lint-only --timing --assert -Wall --top-module "$top" -Irtl \
            "${args[@]}" -f rtl/production.f > "$logroot/lint/${top}_${nb}_${es}.log" 2>&1
    done
    for scheme in 0 1; do
      for rounding in RNE TRUNC; do
        verilator --lint-only --timing --assert -Wall --top-module posit_mul_iter -Irtl \
          "-GNB=$nb" "-GES=$es" "-GFRAC_W=$fw" "-GROUND_SCHEME=$scheme" "-GROUND_MODE=\"$rounding\"" \
          -f rtl/production.f > "$logroot/lint/mul_${nb}_${es}_${scheme}_${rounding}.log" 2>&1
      done
    done
    for rounding in RNE TRUNC; do
        verilator --lint-only --timing --assert -Wall --top-module posit_product_pack -Irtl \
          "-GNB=$nb" "-GES=$es" "-GROUND_MODE=\"$rounding\"" -f rtl/production.f \
          > "$logroot/lint/product_${nb}_${es}_${rounding}.log" 2>&1
    done
 done
 verilator --lint-only --timing --assert -Wall --top-module posit_mac_f -Irtl \
   -GNB=32 -GES=3 -GFRAC_W=12 -f rtl/production.f > "$logroot/lint/posit_mac_f_32_3.log" 2>&1
)
printf 'ACTIVE RELEASE STRICT LINT 37 PASS\n'
run="$out/nf_smoke"
mkdir -p "$run/src/l1" "$run/tmp"
for path in "${paths[@]}"; do cp "$path" "$run/src/"; done
cp rtl/posit_mac.vh tb/nf_coverage_harness.cpp tb/nf_coverage_corpus.hpp tb/nf_coverage.vlt \
  tb/week11_model.hpp tb/week10_add_reference.hpp tb/week9_exact_reference.hpp \
  l0/softposit_api.h l0/libsoftposit.so "$run/src/"
cp l1/include/*.hpp "$run/src/l1/"
sed -n '/-module "posit_pack"/s/-module "posit_pack"/-module "posit_product_pack"/p' \
  tb/nf_coverage.vlt >> "$run/src/nf_coverage.vlt"
(
 cd "$run"
 export TMPDIR="$PWD/tmp"
 export LD_LIBRARY_PATH="$PWD/src${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
 sha256sum src/*.sv src/*.vh src/*.cpp src/*.hpp src/*.vlt src/*.h src/*.so src/l1/*.hpp > source.sha256
 verilator --cc --exe --no-timing --coverage-line -Wall -Wno-fatal --top-module posit_mac_nf \
    -Isrc -GNB=32 -GES=3 -GFRAC_W=12 --Mdir obj \
    -CFLAGS '-O3 -std=c++17 -I../src/l1 -I../src -DPROFILE_NB=32 -DPROFILE_ES=3' \
    -LDFLAGS '-L../src -lsoftposit' src/nf_coverage.vlt src/*.sv src/nf_coverage_harness.cpp > build.log 2>&1
 make -C obj -f Vposit_mac_nf.mk CURDIR=. -j4 >> build.log 2>&1
 ./obj/Vposit_mac_nf 20000 pilot > pilot.log
 tail -n 1 pilot.log
)
echo COMPLETE > "$out/status.txt"
