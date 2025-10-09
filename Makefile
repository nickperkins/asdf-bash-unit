# Makefile for development tasks

SHELL := /bin/bash

DIRS := bin lib tests

SHELLCHECK := shellcheck
SHELLCHECK_ARGS := -x --severity=error --shell=bash

SHFMT := shfmt
SHFMT_ARGS := -i 2 -ci -sr

.DEFAULT_GOAL := help

.PHONY: help fmt fmt-check lint test pre-commit pre-commit-install pre-commit-update ci fix tools

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Available targets:\n"} /^[a-zA-Z0-9_\-]+:.*##/ { printf "  %-22s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

fmt: ## Format shell scripts with shfmt (in-place)
	@$(SHFMT) -w $(SHFMT_ARGS) $(DIRS)

fmt-check: ## Check formatting (fails if reformat needed)
	@$(SHFMT) -d $(SHFMT_ARGS) $(DIRS)

lint: ## Run shellcheck on scripts
	@find $(DIRS) -type f \( -name '*.sh' -o -perm -u+x \) -print0 | xargs -0 $(SHELLCHECK) $(SHELLCHECK_ARGS) || true

test: ## Run test suite
	@./run_tests.sh

pre-commit: ## Run all pre-commit hooks on all files
	@pre-commit run --all-files

pre-commit-install: ## Install git hooks for pre-commit
	@pre-commit install

pre-commit-update: ## Update hook versions to latest compatible
	@pre-commit autoupdate

ci: fmt-check lint test ## Run checks used in CI

fix: fmt ## Auto-fix issues (format), then run hooks
	@pre-commit run --all-files || true

tools: ## Install dev tools via Homebrew (macOS)
	@command -v brew >/dev/null 2>&1 && brew install pre-commit shellcheck shfmt || echo "Install tools manually: pre-commit, shellcheck, shfmt"