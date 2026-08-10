.PHONY: init update deploy-infra test-agents serve-ui compile-dataform help

help:
	@echo "Semantic Knowledge Hub (SKH) - Developer Commands:"
	@echo "  make init               - Initialize and update all git submodules"
	@echo "  make update             - Pull latest changes across all submodules"
	@echo "  make deploy-infra       - Apply Terraform infrastructure"
	@echo "  make test-agents        - Run LangGraph extraction pipeline tests"
	@echo "  make compile-dataform   - Validate Dataform SHACL models"
	@echo "  make serve-ui           - Launch Angular ontology visualizer locally"

init:
	git submodule update --init --recursive

update:
	git submodule update --remote --merge

deploy-infra:
	@echo "==> Deploying GCP Infrastructure..."
	cd infrastructure && terraform init && terraform apply

test-agents:
	@echo "==> Testing Extraction Agents..."
	cd extraction-agents && python3 -m pytest

compile-dataform:
	@echo "==> Compiling Dataform SHACL pipeline..."
	cd dataform-pipeline && npx @dataform/cli compile

serve-ui:
	@echo "==> Serving Semantic Ontology Visualizer..."
	cd ontology-ui && npm install && npm start
