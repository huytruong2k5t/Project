#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
export TMPDIR="$PWD/results/week14/tmp"
python3 scripts/audit_week14.py --self-test
study="$PWD/results/week14"
mkdir -p "$study/builds" "$study/micro"
verilator --version > "$study/verilator.txt"
g++ --version > "$study/compiler.txt"
verilator_coverage --help > "$study/coverage_help.txt" 2>&1 || true
g++ -O2 -std=c++17 -Itb tb/week14_counter_test.cpp -o "$study/micro/counters"
"$study/micro/counters" > "$study/micro/counters.log" 2>&1
echo PASS > "$study/micro/status.txt"
for profile in f32_3 f32_3_fast nf32_3 nf32_2 nf32_3_ex0; do
  run="$study/builds/$profile"
  if [[ -e "$run/status.txt" && "$(cat "$run/status.txt")" == COMPLETE ]]; then
    echo "W14 BUILD ALREADY COMPLETE $profile"; continue
  fi
  [[ ! -e "$run" ]] || { echo "Preserve existing build $run"; exit 2; }
  mkdir -p "$run/src/tb" "$run/src/rtl" "$run/src/l1/include" "$run/src/l0" "$run/tmp"
  cp -r "$study/source/l1/include/." "$run/src/l1/include/"
  cp "$study/source/tb/"*.hpp "$run/src/tb/"
  cp "$study/source/l0/"* "$run/src/l0/"
  while IFS= read -r name; do
    name="${name%$'\r'}"; [[ -n "$name" ]] || continue
    cp "$study/source/$name" "$run/src/rtl/"
  done < "$study/source/rtl/production.f"
  cp "$study/source/rtl/posit_mac.vh" "$run/src/rtl/"
  lint_config=()
  if [[ "$profile" == f32_3* ]]; then
    top=week13_fused_tb; harness=week14_fused_harness.cpp
    cp "$study/source/tb/week13_fused_tb.sv" "$run/src/tb/"
    args=()
  else
    top=posit_mac_nf; harness=week14_nf_harness.cpp
    es=3; [[ "$profile" != nf32_2 ]] || es=2
    exact=1; [[ "$profile" != nf32_3_ex0 ]] || exact=0
    args=(-GNB=32 -GES="$es" -GFRAC_W=12 "-GEXACT_EN=1'b$exact")
    if [[ "$exact" == 0 ]]; then
      cp "$study/source/tb/week14_ex0_lint.vlt" "$run/src/tb/"
      lint_config=(src/tb/week14_ex0_lint.vlt)
    fi
    cp "$study/source/tb/nf_coverage.vlt" "$run/src/tb/"
    sed -n '/-module "posit_pack"/s/-module "posit_pack"/-module "posit_product_pack"/p' \
      "$study/source/tb/nf_coverage.vlt" >> "$run/src/tb/nf_coverage.vlt"
  fi
  cp "$study/source/tb/$harness" "$run/src/tb/"
  (
    cd "$run"; export TMPDIR="$PWD/tmp"; export LD_LIBRARY_PATH="$PWD/src/l0"
    if [[ "$profile" == f32_3* ]]; then
      verilator --lint-only --timing --assert -Wall --top-module posit_mac_f -Isrc/rtl src/rtl/*.sv > lint.log 2>&1
      extra=(src/tb/week13_fused_tb.sv); defs=()
    else
      verilator --lint-only --timing --assert -Wall --top-module posit_mac_nf -Isrc/rtl "${args[@]}" "${lint_config[@]}" src/rtl/*.sv > lint.log 2>&1
      extra=(src/tb/nf_coverage.vlt); defs=(-DPROFILE_NB=32 -DPROFILE_ES="$es")
    fi
    coverage=--coverage; [[ "$profile" != f32_3_fast ]] || coverage=--coverage-line
    verilator --cc --exe --no-timing --assert "$coverage" -Wall -Wno-fatal \
      --top-module "$top" -Isrc/rtl "${args[@]}" --Mdir obj \
      -CFLAGS "-O3 -std=c++17 -I../src/l1/include -I../src/tb -I../src/l0 ${defs[*]}" \
      -LDFLAGS '-L../src/l0 -lsoftposit' "${lint_config[@]}" src/rtl/*.sv "${extra[@]}" "src/tb/$harness" > build.log 2>&1
    make -C obj -f "V$top.mk" CURDIR=. -j2 >> build.log 2>&1
    sha256sum "obj/V$top" > binary.sha256
    echo COMPLETE > status.txt
  )
  echo "W14 BUILD COMPLETE $profile"
done
