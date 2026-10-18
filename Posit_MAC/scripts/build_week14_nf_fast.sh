#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PYTHONPYCACHEPREFIX="$PWD/results/week14/tmp/pycache"
export TMPDIR="$PWD/results/week14/tmp"
python3 scripts/audit_week14.py
for profile in nf32_3 nf32_2 nf32_3_ex0; do
 base="$PWD/results/week14/builds/$profile"
 run="$PWD/results/week14/nf_extension/builds/$profile"
 [[ ! -e "$run" ]] || exit 2
 mkdir -p "$run/tmp";cp -r "$base/src" "$run/src"
 es=3;[[ "$profile" != nf32_2 ]] || es=2
 exact=1;[[ "$profile" != nf32_3_ex0 ]] || exact=0
 (
  cd "$run";export TMPDIR="$PWD/tmp";export LD_LIBRARY_PATH="$PWD/src/l0"
  config=();[[ "$exact" != 0 ]] || config=(src/tb/week14_ex0_lint.vlt)
  verilator --cc --exe --no-timing --assert --coverage-line -Wall -Wno-fatal \
   --top-module posit_mac_nf -Isrc/rtl -GNB=32 -GES="$es" -GFRAC_W=12 "-GEXACT_EN=1'b$exact" --Mdir obj \
   -CFLAGS "-O3 -std=c++17 -I../src/l1/include -I../src/tb -I../src/l0 -DPROFILE_NB=32 -DPROFILE_ES=$es" \
   -LDFLAGS '-L../src/l0 -lsoftposit' "${config[@]}" src/rtl/*.sv src/tb/nf_coverage.vlt \
   src/tb/week14_nf_harness.cpp > build.log 2>&1
  make -C obj -f Vposit_mac_nf.mk CURDIR=. -j2 >> build.log 2>&1
  sha256sum obj/Vposit_mac_nf > binary.sha256
  echo COMPLETE > status.txt
 )
 echo "NF FAST BUILD COMPLETE $profile"
done
