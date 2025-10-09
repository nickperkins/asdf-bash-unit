# asdf-bash-unit

[![Build Status](https://img.shields.io/badge/build-CI-blue)](https://github.com/nickperkins/asdf-bash-unit/actions?query=workflow%3ACI)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![asdf Plugin](https://img.shields.io/badge/asdf-plugin-informational)](https://asdf-vm.com)

asdf-bash-unit is an asdf plugin for installing and managing versions of Bash Unit, a lightweight testing framework for Bash. It lets you install specific versions, set project-local or global versions, and keep Bash Unit consistent across environments.

## About The Project

Bash Unit is a handy way to write unit tests for shell scripts. This plugin integrates Bash Unit with asdf so you can:
- Install any released version quickly
- Pin a version per project for reproducible CI and local development
- Discover the latest available version and upgrade safely

The plugin follows asdf’s plugin interface conventions. Script entry points are provided via:
- [bin/list-all](bin/list-all)
- [bin/latest-stable](bin/latest-stable)
- [bin/download](bin/download)
- [bin/install](bin/install)

## Key Features

- Install specific versions of Bash Unit via asdf
- Pin global or per-project versions with shims
- List all available versions with [bin/list-all](bin/list-all)
- Resolve the latest stable version with [bin/latest-stable](bin/latest-stable)
- Optional GitHub API authentication to avoid rate limiting when listing versions

## Built With

- Bash (portable shell scripts)
- asdf (version manager)
  - GitHub Actions for CI ([.github/workflows/ci.yml](.github/workflows/ci.yml))
- ShellCheck for linting
- shfmt for formatting
  - pre-commit for consistent local checks ([.pre-commit-config.yaml](.pre-commit-config.yaml))
- Standard Unix tools (git, curl, sed, awk)

## Getting Started

Follow these steps to install and use the plugin.

### Prerequisites

- asdf installed (see https://asdf-vm.com/guide/getting-started.html)
- git and curl available in your shell
- Bash 4+ recommended

For development (optional):
- shellcheck, shfmt, pre-commit
  - macOS users can install via `make tools`

### Installation

1. Add the plugin
   ```bash
   asdf plugin add bash-unit https://github.com/nickperkins/asdf-bash-unit.git
   ```
2. Install a specific version
  ```bash
  asdf install bash-unit <version>
  ```
3. Set the version (choose one)
   ```bash
   # Project-local
   asdf local bash-unit <version>

   # Global (all shells)
   asdf global bash-unit <version>
   ```
4. Optional: avoid API rate limits for version discovery
   - Some commands (e.g., [bin/list-all](bin/list-all), [bin/latest-stable](bin/latest-stable)) may query GitHub.
   - If you hit rate limits, set a token in your environment before running:
     ```bash
     export GITHUB_API_TOKEN="your_token_here"
     ```

## Usage

- List all installable versions
  ```bash
  asdf list all bash-unit
  ```
- Show the latest stable version (and optionally install it)
  ```bash
  asdf latest bash-unit
  # or resolve and install the latest in one step
  asdf install bash-unit latest
  ```
- Switch versions
  ```bash
  asdf local bash-unit <version>   # in a project
  asdf global bash-unit <version>  # for your user
  ```
- Verify the shim and path
  ```bash
  asdf which bash_unit
  bash_unit --version
  ```

## Running Tests

Run the test suite locally:
```bash
make test
# or
./run_tests.sh
```

Development helpers (Make targets):

```bash
# Format shell scripts in-place
make fmt

# Check formatting (fails if reformat needed)
make fmt-check

# Lint scripts with ShellCheck
make lint

# Run the test suite (invokes ./run_tests.sh)
make test

# Run all pre-commit hooks on all files
make pre-commit

# Install git hooks for pre-commit
make pre-commit-install

# Update pre-commit hooks to latest compatible
make pre-commit-update

# Run fmt-check, lint, and tests (CI entrypoint)
make ci

# Auto-format code then run hooks
make fix

# Install developer tools via Homebrew (macOS)
make tools
```

Note: CI runs formatting, linting, and tests on each push/PR using GitHub Actions ([.github/workflows/ci.yml](.github/workflows/ci.yml)).

## Contributing

Contributions are welcome! Open an issue or submit a pull request with improvements or bug fixes.
- Install hooks: `make pre-commit-install`
- Run hooks manually: `make pre-commit`
- Hook configuration lives in [`.pre-commit-config.yaml`](.pre-commit-config.yaml)

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.