#!/usr/bin/env bash
# Rebuild the checked-in L0/L1 sources using existing Linux + MinGW tools.
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
run_id="$(TZ=Asia/Ho_Chi_Minh date +%Y%m%d_%H%M%S)"
results_dir="$project_dir/results/rebuild_l0_l1/$run_id"
mkdir -p "$results_dir"
exec > >(tee "$results_dir/run.log") 2>&1

run() {
    printf '\nCOMMAND:'
    printf ' %q' "$@"
    printf '\n'
    "$@"
}

printf 'Date (Vietnam): %s\nProject: %s\n' "$(TZ=Asia/Ho_Chi_Minh date --iso-8601=seconds)" "$project_dir"
run uname -a
for tool in gcc g++ make x86_64-w64-mingw32-gcc x86_64-w64-mingw32-g++ python3; do
    run command -v "$tool"
    run "$tool" --version
done
printf '\nSoftPosit version metadata (vendored copy):\n'
run cat l0/SoftPosit_src/CITATION.cff
if [[ -e l0/SoftPosit_src/.git ]]; then
    run git -C l0/SoftPosit_src rev-parse HEAD
else
    printf 'No vendor .git metadata; upstream commit cannot be verified. Source SHA256 manifest identifies this copy.\n'
fi
printf '\nSeeds: identity posit32=1337; mul posit16=2026; mul posit32=314159; round base=20261003.\n'
printf 'L0 corner and posit8/16 identity / posit8 exhaustive mul are deterministic (no random seed).\n'
printf 'Default tests are smoke only: 1e6 random posit16 pairs and 1e6 stratified posit32 pairs.\n'
printf 'For full Gate 1 acceptance, run: make -C l1 gate1 (exhaustive posit16 + 1e7 stratified posit32).\n'
find l0/SoftPosit_src/source l0/SoftPosit_src/build/Linux-x86_64-GCC l1/include l1/src l1/test \
    -type f \( -name '*.c' -o -name '*.h' -o -name '*.hpp' -o -name '*.cpp' -o -name '*.py' -o -name 'Makefile' \) -print0 \
    | sort -z | xargs -0 sha256sum > "$results_dir/sources.sha256"
sha256sum l0/softposit_api.c l0/softposit_api.h l0/softposit_cli.c l0/softposit.py \
    l0/test_softposit_corners.py l0/Makefile l1/Makefile scripts/rebuild_l0_l1.sh >> "$results_dir/sources.sha256"

# -B forces recompilation rather than relying on pre-existing binary timestamps.
run make -B -C l0 linux windows
run make -B -C l1 linux windows
run python3 l0/test_softposit_corners.py
run bash -c 'cd l1 && ./test_mac_gate1b && ./test_l1_api_c && python3 test/test_l1_api.py && ./test_identity && ./test_adder && ./test_mul_exact && ./test_round_unpacked && ./test_tv_paper && ./test_paper_baseline && ./test_paper_ops && ./test_paper_measurement && ./test_paper_relative_ops && ./test_paper_sensitivity --self-test && ./test_paper_anchor --self-test && ./test_paper_source_profile && ./test_paper_source_audit 100000 314159 && ./test_paper_babic 100000 314159 && ./test_paper_table1 --samples 100000 --seed 314159'
sha256sum l0/libsoftposit.so l0/softposit.dll l0/softposit_cli l0/softposit_cli.exe \
    l1/test_mac_gate1b l1/test_mac_gate1b.exe l1/libposit_l1.so l1/posit_l1.dll l1/test_l1_api_c l1/test_l1_api_c.exe \
    l1/test_adder l1/test_adder.exe l1/test_identity l1/test_identity.exe l1/test_mul_exact l1/test_mul_exact.exe \
    l1/test_round_unpacked l1/test_round_unpacked.exe l1/test_tv_paper l1/test_tv_paper.exe \
    l1/test_table1_reproduce l1/test_table1_reproduce.exe l1/test_paper_baseline l1/test_paper_baseline.exe \
    l1/test_paper_table1 l1/test_paper_table1.exe l1/test_paper_ops l1/test_paper_ops.exe l1/test_paper_relative_ops l1/test_paper_relative_ops.exe l1/test_paper_sensitivity l1/test_paper_sensitivity.exe l1/test_paper_measurement l1/test_paper_measurement.exe l1/softposit.dll \
    l1/test_paper_anchor l1/test_paper_anchor.exe l1/test_paper_source_profile l1/test_paper_source_profile.exe \
    l1/test_paper_source_audit l1/test_paper_source_audit.exe l1/test_paper_babic l1/test_paper_babic.exe \
    > "$results_dir/binaries.sha256"
run sha256sum -c "$results_dir/sources.sha256"
printf '\nREBUILD AND LINUX TESTS PASSED\nLogs: %s\n' "$results_dir"
