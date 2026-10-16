#!/usr/bin/env bash
# Frozen parser snapshots; fresh results, no overwrite of historical acceptance.
set -euo pipefail
cd "$(dirname "$0")/.."
out=results/parser_xor_20261016
mkdir -p "$out"/{tmp,parser_comb,parser_pipeline,lint}
export TMPDIR="$PWD/$out/tmp"
verilator --version > "$out/version.txt"
g++ --version > "$out/compiler.txt"
sha256sum rtl/parser/*.sv rtl/common/{lod_lzd_core,dyn_left_shifter}.sv \
    rtl/posit_mac.vh l1/test/gen_parser_vectors.cpp l1/include/*.hpp \
    tb/{tb_posit_parser,tb_posit_parser_comb,parser_pipeline_checker}.sv \
    scripts/verify_parser_xor.sh > "$out/verification_sources.sha256"
for profile in '8 0' '16 1' '32 2' '32 3' '4 0' '5 1' '9 5' '32 28'; do
    read -r nb es <<< "$profile"
    for top in posit_parser posit_parser_comb; do
        verilator --lint-only --timing -Wall -Irtl --top-module "$top" \
            -GNB="$nb" -GES="$es" rtl/common/{lod_lzd_core,dyn_left_shifter}.sv \
            rtl/parser/"$top".sv > "$out/lint/${top}_${nb}_${es}.log" 2>&1
    done
done
echo 'PARSER_XOR STRICT_LINT_PASS profiles=16'
g++ -O2 -std=c++17 -Il1/include l1/test/gen_parser_vectors.cpp -o "$out/gen_parser_vectors"
"$out/gen_parser_vectors" "$out/parser_comb" > "$out/generator.log"
sha256sum "$out"/parser_comb/parser_*.txt > "$out/vectors.sha256"
for kind in comb pipeline; do
    if [[ "$kind" == comb ]]; then
        top=tb_posit_parser_comb
        sources=(rtl/parser/posit_parser_comb.sv tb/tb_posit_parser_comb.sv)
    else
        top=tb_posit_parser
        sources=(rtl/parser/posit_parser.sv tb/parser_pipeline_checker.sv tb/tb_posit_parser.sv)
    fi
    run="$out/parser_$kind"
    verilator --cc --exe --main --timing --assert -Wno-fatal -Irtl \
        --top-module "$top" --Mdir "$run/obj_dir" \
        rtl/common/{lod_lzd_core,dyn_left_shifter}.sv "${sources[@]}" > "$run/build.log" 2>&1
    make -C "$run/obj_dir" -f "V$top.mk" CURDIR=. -j4 >> "$run/build.log" 2>&1
    (cd "$run"; "./obj_dir/V$top" > simulate.log)
    echo "PARSER_XOR $kind complete"
done
run="$out/params"
mkdir -p "$run"
sed 's/module posit_parser #(/module posit_parser_before #(/' \
    "$out/source/baseline/posit_parser.sv" > "$run/posit_parser_before.sv"
verilator --cc --exe --main --timing --assert -Wno-fatal -Irtl \
    --top-module tb_parser_xor_params --Mdir "$run/obj_dir" \
    rtl/common/{lod_lzd_core,dyn_left_shifter}.sv rtl/parser/*.sv \
    "$run/posit_parser_before.sv" tb/{parser_xor_param_checker,tb_parser_xor_params}.sv > "$run/build.log" 2>&1
make -C "$run/obj_dir" -f Vtb_parser_xor_params.mk CURDIR=. -j4 >> "$run/build.log" 2>&1
"$run/obj_dir/Vtb_parser_xor_params" > "$run/simulate.log"
echo 'PARSER_XOR ALL_COMPLETE'
