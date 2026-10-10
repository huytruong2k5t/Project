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

.PHONY: all help lint smoke regress cov syn ppa asic report clean

all: lint smoke regress cov syn ppa report ## Run full flow: lint, test, synthesis, PPA collection, report

help: ## Show this help message
	@echo "Posit MAC IP Makefile Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

lint: ## Strict normative multiplier lint, all sixteen Gate2 profiles
	@bash $(SCRIPTS_DIR)/lint_gate2.sh

smoke: ## Run Gate2 pilot across all sixteen multiplier configurations
	@bash $(SCRIPTS_DIR)/verify_week9_verilator.sh final_pilot gate2_pilot


regress: ## Run Gate2 multiplier stratified matrix (requires regenerated frozen fixtures)
	@bash $(SCRIPTS_DIR)/verify_week9_verilator.sh stratified_corpus gate2_stratified


cov: ## Audit Gate2 functional and measured line/branch/toggle coverage
	$(PYTHON) $(SCRIPTS_DIR)/audit_week9_coverage.py results/week9_multiplier/stratified_corpus --rtl-summary results/week9_multiplier/verilator/gate2_stratified/summary.json --output results/week9_multiplier/verilator/gate2_stratified/functional_coverage.json
	$(PYTHON) $(SCRIPTS_DIR)/audit_gate2_structure.py

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
