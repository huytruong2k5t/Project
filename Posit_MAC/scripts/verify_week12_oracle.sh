#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
project="$PWD"
run="$project/results/week12/oracle"
mkdir -p "$run/tmp" "$run/bin"
export TMPDIR="$run/tmp"
export LD_LIBRARY_PATH="$project/l0${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
printf RUNNING > "$run/status.txt"
g++ --version > "$run/compiler.log"
x86_64-w64-mingw32-g++ --version > "$run/windows_compiler.log"
g++ -O3 -std=c++17 -Wall -Wextra -Werror -Il1/include l1/test/test_week12_oracle.cpp \
    -Ll0 -lsoftposit -o "$run/bin/oracle" > "$run/build.log" 2>&1
"$run/bin/oracle" "$run/linux.json" 16777216 100000 | tee "$run/linux.log"
g++ -O1 -g -std=c++17 -Wall -Wextra -Werror -fsanitize=undefined -fno-sanitize-recover=all \
    -Il1/include l1/test/test_week12_oracle.cpp -Ll0 -lsoftposit -o "$run/bin/oracle_ubsan" > "$run/ubsan_build.log" 2>&1
"$run/bin/oracle_ubsan" "$run/ubsan.json" 100000 100000 | tee "$run/ubsan.log"
x86_64-w64-mingw32-g++ -O3 -std=c++17 -Wall -Wextra -Werror -static -Il1/include \
    l1/test/test_week12_oracle.cpp -Ll0 -l:softposit.dll -o "$run/bin/oracle.exe" > "$run/windows_build.log" 2>&1
cp -- l0/softposit.dll "$run/bin/"
sha256sum tb/week12_fused_reference.hpp l1/test/test_week12_oracle.cpp \
    scripts/verify_week12_oracle.sh l0/libsoftposit.so l0/softposit.dll \
    tb/week11_fused_model.hpp tb/week11_model.hpp tb/week10_add_reference.hpp \
    l1/include/*.hpp > "$run/source.sha256"
printf COMPLETE > "$run/linux_status.txt"
