CXX ?= g++
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra -Iinclude -I../l0
WIN_CXX = x86_64-w64-mingw32-g++

L0_DIR = ../l0

.PHONY: all linux windows test test-round test-round-ubsan test-week4 test-paper test-paper-ops paper-table1 test_table1 gate1 gate1-p32 gate1-p16-range test_identity test_mul_exact clean

P16_START ?= 0
P16_END ?= 65536
P32_SEED ?= 314159

all: linux windows

linux: test_mac_gate1b libposit_l1.so test_l1_api_c
windows: test_mac_gate1b.exe posit_l1.dll test_l1_api_c.exe

test_l1_api_c: test/test_l1_api_c.c include/l1_api.h libposit_l1.so
	$(CC) -std=c11 -Wall -Wextra -Werror -Iinclude $< -L. -lposit_l1 -Wl,-rpath,. -o $@

test_l1_api_c.exe: test/test_l1_api_c.c include/l1_api.h posit_l1.dll
	x86_64-w64-mingw32-gcc -std=c11 -Wall -Wextra -Werror -Iinclude $< -L. -l:posit_l1.dll -o $@

test_mac_gate1b: test/test_mac_gate1b.cpp test/mac_oracle.hpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) $(CXXFLAGS) $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -o $@

test_mac_gate1b.exe: test/test_mac_gate1b.cpp test/mac_oracle.hpp include/*.hpp $(L0_DIR)/softposit.dll
	$(WIN_CXX) $(CXXFLAGS) -static-libgcc -static-libstdc++ $< -L$(L0_DIR) -l:softposit.dll -o $@
	cp -f $(L0_DIR)/softposit.dll ./

test_mac_gate1b_ubsan: test/test_mac_gate1b.cpp test/mac_oracle.hpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude -I../l0 $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -o $@

libposit_l1.so: src/l1_api.cpp include/l1_api.h include/*.hpp
	$(CXX) $(CXXFLAGS) -shared -fPIC $< -o $@

libposit_l1_ubsan.so: src/l1_api.cpp include/l1_api.h include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude -shared -fPIC $< -o $@

posit_l1.dll: src/l1_api.cpp include/l1_api.h include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -shared -static-libgcc -static-libstdc++ $< -o $@

.PHONY: test-week6 gate1b
test-week6: test_mac_gate1b libposit_l1.so test_l1_api_c
	./test_mac_gate1b
	./test_l1_api_c
	python3 test/test_l1_api.py

gate1b: test_mac_gate1b
	./test_mac_gate1b --acceptance --samples 10000000 --seed $(P32_SEED)

linux: test_paper_anchor test_paper_source_audit test_paper_source_profile test_paper_babic test_adder test_paper_relative_ops test_paper_sensitivity test_paper_measurement test_identity test_mul_exact test_round_unpacked test_tv_paper test_table1_reproduce test_paper_baseline test_paper_table1 test_paper_ops

windows: test_paper_anchor.exe test_paper_source_audit.exe test_paper_source_profile.exe test_paper_babic.exe test_adder.exe test_paper_relative_ops.exe test_paper_sensitivity.exe test_paper_measurement.exe test_identity.exe test_mul_exact.exe test_round_unpacked.exe test_tv_paper.exe test_table1_reproduce.exe test_paper_baseline.exe test_paper_table1.exe test_paper_ops.exe

test_paper_ops: test/test_paper_ops.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_ops.exe: test/test_paper_ops.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_ops_ubsan: test/test_paper_ops.cpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

test-paper-ops: test_paper_ops
	./test_paper_ops

test_paper_baseline: test/test_paper_baseline.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_baseline.exe: test/test_paper_baseline.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_table1: test/test_paper_table1.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_table1.exe: test/test_paper_table1.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_baseline_ubsan: test/test_paper_baseline.cpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

test-paper: test_paper_source_profile test_paper_source_audit test_paper_babic test_paper_relative_ops test_paper_sensitivity test_paper_measurement test_paper_baseline test_paper_ops
	./test_paper_source_profile
	./test_paper_source_audit 100000 314159
	./test_paper_babic 100000 314159
	./test_paper_relative_ops
	./test_paper_sensitivity --self-test
	./test_paper_measurement
	./test_paper_baseline
	./test_paper_ops

paper-table1: test_paper_table1
	./test_paper_table1 --samples 200000000 --seed 314159 --require-match

test_tv_paper: test/test_tv_paper.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) $(CXXFLAGS) $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -o $@

test_tv_paper.exe: test/test_tv_paper.cpp include/*.hpp $(L0_DIR)/softposit.dll
	$(WIN_CXX) $(CXXFLAGS) -static-libgcc -static-libstdc++ $< -L$(L0_DIR) -l:softposit.dll -o $@
	cp -f $(L0_DIR)/softposit.dll ./

test_table1_reproduce: test/test_table1_reproduce.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_table1_reproduce.exe: test/test_table1_reproduce.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test-week4: test_tv_paper
	./test_tv_paper

test_table1: test_table1_reproduce
	./test_table1_reproduce --samples 10000000 --seed 314159 --require-match

test_tv_paper_ubsan: test/test_tv_paper.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude -I../l0 $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -o $@

test_identity: test/test_identity.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) test/test_identity.cpp -o $@

test_mul_exact: test/test_mul_exact.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) $(CXXFLAGS) test/test_mul_exact.cpp -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -lm -o $@

test_identity.exe: test/test_identity.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ test/test_identity.cpp -o $@

test_mul_exact.exe: test/test_mul_exact.cpp include/*.hpp $(L0_DIR)/softposit.dll
	$(WIN_CXX) $(CXXFLAGS) -static-libgcc -static-libstdc++ test/test_mul_exact.cpp -L$(L0_DIR) -l:softposit.dll -o $@
	cp -f $(L0_DIR)/softposit.dll ./

test_round_unpacked: test/test_round_unpacked.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) $(CXXFLAGS) $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -lm -o $@

test_round_unpacked.exe: test/test_round_unpacked.cpp include/*.hpp $(L0_DIR)/softposit.dll
	$(WIN_CXX) $(CXXFLAGS) -static-libgcc -static-libstdc++ $< -L$(L0_DIR) -l:softposit.dll -o $@
	cp -f $(L0_DIR)/softposit.dll ./

test-round: test_round_unpacked
	./test_round_unpacked

test_round_unpacked_ubsan: test/test_round_unpacked.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude -I../l0 $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -lm -o $@

test-round-ubsan: test_round_unpacked_ubsan
	./test_round_unpacked_ubsan

test: linux
	./test_mac_gate1b
	./test_l1_api_c
	python3 test/test_l1_api.py
	./test_adder
	./test_paper_relative_ops
	./test_paper_sensitivity --self-test
	./test_paper_measurement
	@echo "--- Running Roundtrip Identity Test ---"
	./test_identity
	@echo "--- Running Exact Multiplier Smoke Test vs SoftPosit ---"
	./test_mul_exact
	./test_round_unpacked
	./test_tv_paper
	./test_paper_baseline
	./test_paper_ops

gate1: linux
	./test_identity
	./test_mul_exact --gate1 --seed $(P32_SEED)
	./test_round_unpacked

gate1-p32: test_mul_exact
	./test_mul_exact --p32-only --samples 10000000 --seed $(P32_SEED)

gate1-p16-range: test_mul_exact
	./test_mul_exact --p16-start $(P16_START) --p16-end $(P16_END) --seed $(P32_SEED)

gen_parser_vectors: test/gen_parser_vectors.cpp include/posit_parser.hpp include/posit_types.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

gen_parser_vectors.exe: test/gen_parser_vectors.cpp include/posit_parser.hpp include/posit_types.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

clean:
	rm -f test_paper_anchor test_paper_anchor.exe test_paper_anchor_ubsan test_paper_source_audit test_paper_source_audit.exe test_paper_source_audit_ubsan test_paper_source_profile test_paper_source_profile.exe test_paper_source_profile_ubsan test_paper_babic test_paper_babic.exe test_paper_babic_ubsan test_adder test_adder.exe test_adder_ubsan test_paper_relative_ops test_paper_relative_ops.exe test_paper_relative_ops_ubsan test_paper_sensitivity test_paper_sensitivity.exe test_paper_sensitivity_ubsan test_paper_measurement test_paper_measurement.exe test_paper_measurement_ubsan test_identity test_mul_exact test_round_unpacked test_round_unpacked_ubsan test_identity.exe test_mul_exact.exe test_round_unpacked.exe test_tv_paper test_tv_paper.exe test_tv_paper_ubsan test_table1_reproduce test_table1_reproduce.exe test_paper_baseline test_paper_baseline.exe test_paper_baseline_ubsan test_paper_table1 test_paper_table1.exe test_paper_ops test_paper_ops.exe test_paper_ops_ubsan *.o

test_paper_measurement: test/test_paper_measurement.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_measurement.exe: test/test_paper_measurement.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_measurement_ubsan: test/test_paper_measurement.cpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

.PHONY: test-paper-measurement
test-paper-measurement: test_paper_measurement
	./test_paper_measurement

test_paper_sensitivity: test/test_paper_sensitivity.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_sensitivity.exe: test/test_paper_sensitivity.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_sensitivity_ubsan: test/test_paper_sensitivity.cpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

.PHONY: test-paper-sensitivity
test-paper-sensitivity: test_paper_sensitivity
	./test_paper_sensitivity --self-test

test_paper_relative_ops: test/test_paper_relative_ops.cpp test/test_paper_sensitivity.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_relative_ops.exe: test/test_paper_relative_ops.cpp test/test_paper_sensitivity.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_relative_ops_ubsan: test/test_paper_relative_ops.cpp test/test_paper_sensitivity.cpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

.PHONY: test-paper-relative paper-table1-relative
test-paper-relative: test_paper_relative_ops
	./test_paper_relative_ops

paper-table1-relative: test_paper_table1
	./test_paper_table1 --samples 200000000 --seed 271828 --profile relative --require-match

test_adder: test/test_adder.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) $(CXXFLAGS) $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -o $@

test_adder.exe: test/test_adder.cpp include/*.hpp $(L0_DIR)/softposit.dll
	$(WIN_CXX) $(CXXFLAGS) -static-libgcc -static-libstdc++ $< -L$(L0_DIR) -l:softposit.dll -o $@
	cp -f $(L0_DIR)/softposit.dll ./

test_adder_ubsan: test/test_adder.cpp include/*.hpp $(L0_DIR)/libsoftposit.so
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude -I../l0 $< -L$(L0_DIR) -lsoftposit -Wl,-rpath,$(L0_DIR) -o $@

.PHONY: test-week5 test-adder-acceptance test-adder-p16-range
test-week5: test_adder
	./test_adder

test-adder-acceptance: test_adder
	./test_adder --acceptance --samples 10000000 --seed $(P32_SEED)

test-adder-p16-range: test_adder
	./test_adder --p16-start $(P16_START) --p16-end $(P16_END)

test_paper_anchor: test/test_paper_anchor.cpp test/paper_anchor_study.hpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_anchor.exe: test/test_paper_anchor.cpp test/paper_anchor_study.hpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_anchor_ubsan: test/test_paper_anchor.cpp test/paper_anchor_study.hpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

test_paper_source_audit: test/test_paper_source_audit.cpp test/paper_anchor_study.hpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_source_audit.exe: test/test_paper_source_audit.cpp test/paper_anchor_study.hpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_source_audit_ubsan: test/test_paper_source_audit.cpp test/paper_anchor_study.hpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

test_paper_source_profile: test/test_paper_source_profile.cpp test/paper_anchor_study.hpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_source_profile.exe: test/test_paper_source_profile.cpp test/paper_anchor_study.hpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_source_profile_ubsan: test/test_paper_source_profile.cpp test/paper_anchor_study.hpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

test_paper_babic: test/test_paper_babic.cpp include/*.hpp
	$(CXX) $(CXXFLAGS) $< -o $@

test_paper_babic.exe: test/test_paper_babic.cpp include/*.hpp
	$(WIN_CXX) $(CXXFLAGS) -static -static-libgcc -static-libstdc++ $< -o $@

test_paper_babic_ubsan: test/test_paper_babic.cpp include/*.hpp
	$(CXX) -O1 -g -std=c++17 -Wall -Wextra -fsanitize=undefined -fno-sanitize-recover=undefined -Iinclude $< -o $@

.PHONY: test-paper-source paper-table1-source paper-table1-babic
test-paper-source: test_paper_source_profile test_paper_source_audit test_paper_anchor test_paper_babic
	./test_paper_source_profile
	./test_paper_source_audit 100000 314159
	./test_paper_anchor --self-test
	./test_paper_babic 100000 314159

paper-table1-source: test_paper_table1
	./test_paper_table1 --samples 200000000 --seed 271828 --profile source --require-match

paper-table1-babic: test_paper_babic
	./test_paper_babic 200000000 271828
