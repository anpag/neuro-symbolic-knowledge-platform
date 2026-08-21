.PHONY: help init init-all update lint test test-e2e build clean deploy-infra test-agents test-reasoner compile-dataform build-ui serve-ui

PYTHON_EXTRACTION := .venv/bin/python3
PYTEST_EXTRACTION := .venv/bin/pytest
PYTHON_REASONING  := .venv/bin/python3
PYTEST_REASONING  := .venv/bin/pytest
TERRAFORM         := PATH=$$HOME/.local/bin:$$PATH terraform

help:
	@echo "=========================================================================="
	@echo " Neuro-Symbolic Knowledge Platform - Production Developer Commands"
	@echo "=========================================================================="
	@echo "  make init-all          - Initialize submodules, virtualenvs, npm, and build Rust"
	@echo "  make lint              - Run static analysis and linting across all submodules"
	@echo "  make test              - Run all unit and integration test suites"
	@echo "  make test-e2e          - Run cross-stack platform end-to-end certification"
	@echo "  make build             - Compile release Rust binary and Angular UI bundle"
	@echo "  make compile-dataform  - Validate and compile BigQuery Dataform SHACL models"
	@echo "  make validate-infra    - Validate Terraform infrastructure declarations"
	@echo "  make serve-ui          - Launch Angular 18 ontology visualizer locally"
	@echo "  make clean             - Remove build caches and transient artifacts"
	@echo "=========================================================================="

init:
	git submodule update --init --recursive

init-all: init
	@echo "==> Setting up Extraction Agents virtualenv..."
	cd extraction-agents && (test -d .venv || python3 -m venv .venv) && .venv/bin/pip install -q -r requirements.txt
	@echo "==> Setting up Reasoning Engine virtualenv..."
	cd reasoning-engine && (test -d .venv || python3 -m venv .venv) && .venv/bin/pip install -q -r requirements.txt
	@echo "==> Compiling native Rust GEB engine..."
	cd reasoning-engine/rust_engine && cargo build --release
	@echo "==> Installing UI dependencies..."
	cd ontology-ui && npm install
	@echo "==> Initializing Terraform..."
	cd infrastructure && $(TERRAFORM) init -backend=false

lint:
	@echo "==> Linting Rust GEB Engine..."
	cd reasoning-engine/rust_engine && cargo check
	@echo "==> Checking Dataform syntax..."
	cd dataform-pipeline && npx --yes @dataform/cli compile
	@echo "==> Validating Terraform infrastructure..."
	cd infrastructure && $(TERRAFORM) validate

test: test-agents test-reasoner compile-dataform validate-infra test-e2e
	@echo "==> All unit, integration, and E2E test suites passed!"

test-agents:
	@echo "==> Testing Extraction Agents (LangGraph + Multimodal)..."
	cd extraction-agents && $(PYTEST_EXTRACTION) -v

test-reasoner:
	@echo "==> Testing Rust Reasoning Engine (cargo test)..."
	cd reasoning-engine/rust_engine && cargo test
	@echo "==> Testing Reasoning Engine Python FastAPI..."
	cd reasoning-engine && $(PYTEST_REASONING) -v tests/test_reasoner.py tests/test_api.py tests/test_loader.py

compile-dataform:
	@echo "==> Compiling Dataform SHACL pipeline actions..."
	cd dataform-pipeline && npx --yes @dataform/cli compile

validate-infra:
	@echo "==> Validating Terraform infrastructure..."
	cd infrastructure && $(TERRAFORM) init -backend=false && $(TERRAFORM) validate

test-e2e:
	@echo "==> Running Full Monorepo End-to-End Verification Pipeline..."
	./tests/run_e2e_verification.py

build:
	@echo "==> Building Rust release binary..."
	cd reasoning-engine/rust_engine && cargo build --release
	@echo "==> Building Angular 18 production UI bundle..."
	cd ontology-ui && npm run build

serve-ui:
	@echo "==> Serving Semantic Ontology Visualizer..."
	cd ontology-ui && npm start

clean:
	@echo "==> Cleaning transient artifacts..."
	rm -rf .pytest_cache
	rm -rf extraction-agents/.pytest_cache
	rm -rf reasoning-engine/.pytest_cache
	rm -rf reasoning-engine/rust_engine/target/debug
	rm -rf ontology-ui/dist
