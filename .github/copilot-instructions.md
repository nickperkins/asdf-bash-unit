# Global Copilot Instructions for asdf-bash-unit

# Project Overview
asdf-bash-unit is an asdf plugin that installs and manages versions of Bash Unit, a Bash testing framework. The repository is a single plugin (monorepo not applicable) organized around standard asdf plugin scripts in bin/, shared utilities in lib/, and tests in tests/.

Core architectural style: Small, composable Bash scripts with shared utilities, strict linting/formatting, and deterministic tests using vendored or mocked dependencies.

## Technology Stack
- Bash (POSIX-ish with bashisms). All scripts use set -euo pipefail and a Bash shebang.
- asdf plugin interface: required scripts bin/list-all, bin/download, bin/install; optional bin/latest-stable; help scripts.
- curl for HTTP; sed/grep for parsing JSON without jq.
- Tooling: shellcheck, shfmt, pre-commit, GitHub Actions, Makefile targets.

## Coding Standards & Conventions
- Mandatory headers
  - Shebang: exactly one of: #!/usr/bin/env bash or #!/bin/bash. Validate for downloaded artifacts.
  - Top-of-file safety flags: set -euo pipefail.
- Sourcing and paths
  - Compute ROOT_DIR relative to script and source shared utilities: [lib/utils.sh](../lib/utils.sh) via . "$ROOT_DIR/lib/utils.sh".
  - Do not call asdf from plugin scripts; follow "Golden Rules" from upstream docs.
- Exit codes
  - 0 success; 1 general failure; 2 network/HTTP error; 3 invalid input/unsupported mode. See [bin/download](../bin/download) and [bin/install](../bin/install).
- Networking
  - Always use curl -fsSL for direct downloads and -sSL -w '%{http_code}' when you must inspect the status code.
  - Add GitHub token when present: Authorization: Bearer "$GITHUB_API_TOKEN". See [bin/list-all](../bin/list-all).
  - Provide a fast HEAD connectivity check when appropriate using [bash.check_network()](../lib/utils.sh).
- JSON parsing without jq
  - Parse tag_name fields with grep/sed patterns identical to [bin/list-all](../bin/list-all) and [bin/latest-stable](../bin/latest-stable).
  - Never introduce jq as a dependency.
- Version handling
  - Normalize tags with [bash.clean_version()](../lib/utils.sh) and validate with [bash.validate_version_format()](../lib/utils.sh) before using.
  - Do not rely on sort -V; reproduce padded numeric sort used in [bin/list-all](../bin/list-all).
- Safety and hygiene
  - Use mktemp for transient files; always trap cleanup. See [bin/list-all](../bin/list-all) and [bin/latest-stable](../bin/latest-stable).
  - Quote all variable expansions; avoid eval; avoid unguarded word splitting (disable shellcheck SC2086 only when intentional as in [run_tests.sh](../run_tests.sh)).
  - Never leave partial files on failure; ensure cleanup of TMP_FILE and do atomic mv/cp.
- Naming and style
  - Functions: lower_snake_case, e.g., [bash.validate_version_format()](../lib/utils.sh).
  - Constants/env: UPPER_SNAKE_CASE (ASDF_INSTALL_PATH, ASDF_DOWNLOAD_PATH).
  - Files: kebab-case in bin/ (install, list-all, latest-stable), lower_snake_case functions in lib/.

## Build, Test, & Deployment
- Format: make fmt → [make.fmt()](../Makefile)
- Check format: make fmt-check → [make.fmt-check()](../Makefile)
- Lint: make lint → [make.lint()](../Makefile)
- Test: make test or ./run_tests.sh → [run_tests.sh](../run_tests.sh)
- Pre-commit install: make pre-commit-install → [make.pre-commit-install()](../Makefile)
- Run hooks: make pre-commit → [make.pre-commit()](../Makefile)
- CI entrypoint: make ci (locally) or GitHub Actions runs pre-commit + tests; see [.github/workflows/ci.yml](../.github/workflows/ci.yml)

## Operational Procedures
- Procedure: Add a new asdf plugin script (e.g., bin/exec-env)
  1. Create bin/<name> with Bash shebang and set -euo pipefail.
  2. Resolve ROOT_DIR and source lib/utils.sh. See pattern in [bin/list-all](../bin/list-all).
  3. Define exit code contract (0/1/2/3) and validate inputs early (e.g., required env vars).
  4. If doing HTTP, build curl args with optional Authorization header when $GITHUB_API_TOKEN is set, and use mktemp + trap cleanup.
  5. Parse results using the same grep/sed patterns as existing scripts; do not add new dependencies.
  6. Ensure no stdout on success unless the asdf calling convention requires output. Ensure helpful diagnostics on stderr via [bash.log_error()](../lib/utils.sh).
  7. Write tests under tests/bin/test_<name>.sh using the GitHub API mock harness [tests/mocks/github_api.sh](../tests/mocks/github_api.sh). Prefer enable_github_api_mocks to control scenarios.
  8. Run make test and make lint until green in CI and locally.
- Procedure: Add/update a network call
  1. Add a focused helper in lib/utils.sh if the URL or behavior is reused (e.g., [bash.get_releases_url()](../lib/utils.sh)).
  2. In the script, implement a connectivity check with [bash.check_network()](../lib/utils.sh).
  3. Build curl args respecting $GITHUB_API_TOKEN; capture HTTP status where needed (-w '%{http_code}').
  4. Validate and sanitize all inputs (clean_version + validate_version_format when handling tags/versions).
  5. Guarantee cleanup of temp files and avoid partial writes; use atomic mv for finalization.
  6. Extend mocks to cover new endpoints if required by enhancing [tests/mocks/github_api.sh](../tests/mocks/github_api.sh).
- Procedure: Implement version download/install
  1. download: write to $ASDF_DOWNLOAD_PATH/bash_unit via temp file, verify shebang, then mv; mirror [bin/download](../bin/download).
  2. install: copy from $ASDF_DOWNLOAD_PATH if present; otherwise legacy path downloads to temp then cp; set chmod 755; mirror [bin/install](../bin/install).

## Security & Compliance
- Never execute untrusted input; no eval; no source from remote.
- Always validate versions before use via [bash.validate_version_format()](../lib/utils.sh) after [bash.clean_version()](../lib/utils.sh).
- Use curl -fsSL for downloads; check for valid bash shebang on fetched scripts before installing.
- Support token-auth to avoid rate limits; do not log secrets. See [bin/list-all](../bin/list-all).
- Ensure accessibility/compliance for repo automation: enforce formatting and linting via pre-commit and CI; do not disable checks except with explicit rationale in-line.