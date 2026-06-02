# rds-oracle-aurora-platform — operator shortcuts.
#
# The default workflow is FREE: init + validate + plan never create AWS resources.
# `apply` and `nuke` are the only targets that touch (and tear down) real infra.

ENV ?= dev
TFVARS := environments/$(ENV).tfvars

.PHONY: help init fmt validate plan apply nuke security docs

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

init: ## terraform init (no cost)
	terraform init

fmt: ## Format all .tf files
	terraform fmt -recursive

validate: init ## Validate configuration (no cost)
	terraform validate

plan: ## Plan against ENV (default dev) — no resources created (no cost)
	terraform plan -var-file=$(TFVARS)

security: ## Run tfsec + checkov static analysis (no cost)
	@command -v tfsec   >/dev/null && tfsec . || echo "tfsec not installed — skipping"
	@command -v checkov >/dev/null && checkov -d . --quiet || echo "checkov not installed — skipping"

apply: ## Apply ENV — CREATES REAL AWS RESOURCES (costs money)
	@echo ">>> This creates billable AWS resources for ENV=$(ENV). Ctrl-C to abort."
	terraform apply -var-file=$(TFVARS)

nuke: ## Destroy everything for ENV — the cost circuit breaker
	terraform destroy -var-file=$(TFVARS)

docs: ## Regenerate module docs (needs terraform-docs)
	terraform-docs markdown table --output-file README.md --output-mode inject .
