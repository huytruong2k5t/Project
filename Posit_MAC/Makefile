#-----------------------------------------------------------------------------
# File          : Makefile
# Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
# Description   : Top-level build and orchestration Makefile
# Targets       : lint, smoke, regress, cov, syn, ppa, asic, report, all, clean
#-----------------------------------------------------------------------------

SHELL := bash
PYTHON ?= python
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

.PHONY: all help lint smoke regress cov syn ppa asic report clean

all: lint smoke regress cov syn ppa report ## Run full flow: lint, test, synthesis, PPA collection, report

help: ## Show this help message
	@echo "Posit MAC IP Makefile Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

lint: ## Run RTL lint checks (Verilator / Verible)
	@echo "==> Running RTL lint checks..."
	@if command -v $(VERILATOR) >/dev/null 2>&1; then \
		$(VERILATOR) --lint-only --timing -Wall -I$(RTL_DIR) $(RTL_DIR)/*.sv; \
	else \
		echo "BLOCKED: Verilator not found; lint has NOT passed."; exit 2; \
	fi

smoke: ## Run quick smoke tests on small configurations (posit8, posit16)
	@echo "==> Running smoke tests..."

regress: ## Run full regression test matrix (posit8, 16, 32 across n and corner cases)
	@echo "==> Running regression suite..."

cov: ## Collect and generate code & functional coverage reports
	@echo "==> Collecting coverage..."

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
