#-----------------------------------------------------------------------------
# File          : Makefile
# Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
# Description   : Top-level build and orchestration Makefile
# Targets       : lint, smoke, regress, cov, syn, ppa, asic, report, all, clean
#-----------------------------------------------------------------------------

SHELL := bash
PYTHON ?= python3
VERILATOR ?= verilator
VIVADO ?= vivado

# Directories
DOCS_DIR    := docs
L0_DIR      := l0
L1_DIR      := l1
RTL_DIR     := rtl
TB_DIR      := tb
TESTS_DIR   := tests
SYN_DIR     := syn
ASIC_DIR    := asic
SCRIPTS_DIR := scripts
RESULTS_DIR := results

.PHONY: all help build lint smoke regress cov syn ppa asic report clean quire-build quire-lint quire-smoke quire-main quire-summary

FIXED_RUN ?= manual
SHARED_COUNT ?= 100000
NF_F_COV_ROOT ?= results/nf_f_coverage_$(FIXED_RUN)
NF_F_CODE_COUNT ?= 5000
SHARED_RESULTS_ROOT ?= results/nf_f_lock_20261105
export SHARED_RESULTS_ROOT
QUIRE_TAG ?= manual

all: lint smoke ## Current shared FULL_TERM flow; build first, run matrix explicitly

help: ## Show this help message
	@echo "Posit MAC IP Makefile Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

build: ## Build current unit/NF/F harnesses; choose a fresh SHARED_BUILD_TAG
	$(PYTHON) $(SCRIPTS_DIR)/verify_shared_multiplier.py build units
	$(PYTHON) $(SCRIPTS_DIR)/verify_shared_multiplier.py build nf
	$(PYTHON) $(SCRIPTS_DIR)/verify_shared_multiplier.py build f

lint: ## Active hierarchy, full named ports and per-module strict lint
	$(PYTHON) $(SCRIPTS_DIR)/audit_shared_multiplier.py

smoke: ## Shared FULL_TERM NF/F smoke with n/OPS variation; build first
	$(PYTHON) $(SCRIPTS_DIR)/verify_shared_multiplier.py run nf 10000 smoke_$(FIXED_RUN) -1 -1
	$(PYTHON) $(SCRIPTS_DIR)/verify_shared_multiplier.py run f 10000 smoke_$(FIXED_RUN) -1 -1


regress: ## 52-point matrix; pilot100k default, main uses SHARED_COUNT=10000000
	$(PYTHON) $(SCRIPTS_DIR)/run_shared_multiplier_matrix.py --count $(SHARED_COUNT) --label matrix_$(FIXED_RUN)


cov: ## Fresh NF/F pilot + structural coverage; no synthesis or old evidence reuse
	$(PYTHON) $(SCRIPTS_DIR)/verify_nf_f_coverage.py --out $(NF_F_COV_ROOT) --stage build
	$(PYTHON) $(SCRIPTS_DIR)/verify_nf_f_coverage.py --out $(NF_F_COV_ROOT) --stage build --engine fast
	$(PYTHON) $(SCRIPTS_DIR)/verify_nf_f_coverage.py --out $(NF_F_COV_ROOT) --stage run --count $(NF_F_CODE_COUNT) --label coverage
	$(PYTHON) $(SCRIPTS_DIR)/verify_nf_f_coverage.py --out $(NF_F_COV_ROOT) --stage run --engine fast --count $(SHARED_COUNT) --label pilot
	$(PYTHON) $(SCRIPTS_DIR)/verify_nf_f_coverage.py --out $(NF_F_COV_ROOT) --stage report --count $(NF_F_CODE_COUNT) --label coverage --pilot-label pilot --pilot-count $(SHARED_COUNT)

quire-lint: ## Audit current19-module quire hierarchy and strict lint
	$(PYTHON) $(SCRIPTS_DIR)/audit_quire.py

quire-build: ## Build quire; choose a fresh QUIRE_TAG
	$(PYTHON) $(SCRIPTS_DIR)/verify_quire.py build --tag $(QUIRE_TAG)

quire-smoke: ## Quire smoke with directed/state tests plus10k mixed MACs
	$(PYTHON) $(SCRIPTS_DIR)/verify_quire.py run --tag $(QUIRE_TAG) --label smoke_$(FIXED_RUN) --count 10000

quire-main: ## Default-only10M retired MAC,4 independent-seed shards; build first
	$(PYTHON) $(SCRIPTS_DIR)/run_quire_main.py --tag $(QUIRE_TAG) --label main_$(FIXED_RUN) --total 10000000 --shards 4

quire-summary: ## Validate recorded03/11 quire evidence; timing remains separate
	$(PYTHON) $(SCRIPTS_DIR)/summarize_quire.py

syn: ## Run FPGA synthesis and implementation via Vivado / Yosys
	@echo "==> Running FPGA synthesis..."

ppa: ## Collect PPA metrics into CSV and Markdown
	@echo "==> Collecting PPA results..."
	@if [ -f $(SCRIPTS_DIR)/collect_ppa.py ]; then \
		$(PYTHON) $(SCRIPTS_DIR)/collect_ppa.py; \
	fi

asic: ## Run ASIC RTL-to-GDS flow (OpenROAD / Yosys)
	@echo "==> Running ASIC flow..."

report: ## Generate summary report and documentation
	@echo "==> Generating report and documentation..."

clean: ## Clean build and simulation artifacts
	@echo "==> Cleaning artifacts..."
	@rm -rf obj_dir *.log *.jou *.pb *.dcp .Xil
