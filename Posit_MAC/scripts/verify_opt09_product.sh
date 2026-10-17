#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out=results/opt09_20261018/product
[[ ! -e "$out" ]] || exit 2
mkdir -p "$out/source" "$out/tmp"
export TMPDIR="$PWD/$out/tmp"
cp results/opt09_20261018/source/magnitude/* "$out/source/"
cp tb/opt09_product_checker.sv tb/tb_opt09_product.sv "$out/source/"
(
 cd "$out"
 sha256sum source/* > source.sha256
 verilator --cc --exe --main --timing --timescale 1ns/1ps -Wall -Wno-fatal \
   --top-module tb_opt09_product -Isource --Mdir obj source/*.sv > build.log 2>&1
 make -C obj -f Vtb_opt09_product.mk CURDIR=. -j4 >> build.log 2>&1
 ./obj/Vtb_opt09_product > simulate.log
 grep 'PRODUCT MATRIX PASS' simulate.log
 echo COMPLETE > status.txt
)
