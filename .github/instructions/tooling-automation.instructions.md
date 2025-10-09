---
applyTo: ".github/workflows/**, .pre-commit-config.yaml, Makefile"
---

## Pre-commit
- Keep shellcheck and shfmt versions pinned as in [.pre-commit-config.yaml](../../.pre-commit-config.yaml). Update via [make.pre-commit-update()](../../Makefile).
- Run hooks locally with [make.pre-commit()](../../Makefile). Install hooks with [make.pre-commit-install()](../../Makefile).

## CI
- GitHub Actions runs pre-commit on all files and then executes tests with [run_tests.sh](../../run_tests.sh). See [.github/workflows/ci.yml](../../.github/workflows/ci.yml).
- Keep CI steps minimal and aligned with Makefile targets to avoid drift.

## Makefile
- Add new developer tasks with a "##" description to auto-appear in [make.help()](../../Makefile).
- Respect current patterns for SHELLCHECK and SHFMT args. Use DIRS variable to scope analysis to bin lib tests.