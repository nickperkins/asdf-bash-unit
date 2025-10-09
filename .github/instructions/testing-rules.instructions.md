---
applyTo: "tests/**"

---

## Principles
- Tests are written with Bash Unit; they run via [run_tests.sh](../../run_tests.sh) which bootstraps a vendored bash_unit binary from tests/vendor when offline.
- Use the GitHub API mock harness to decouple network: [tests/mocks/github_api.sh](../../tests/mocks/github_api.sh).

## Patterns
- Prefer with_github_api_mocks/enable_github_api_mocks to simulate success, http_500, network_error, and corrupt_raw modes.
- Ensure tmp roots are isolated per test via [tests/test_helpers.sh](../../tests/test_helpers.sh); never write outside TEST_TMP_ROOT.
- Validate both stdout content and exit codes; assert cleanup of temp artifacts.

## Example
```bash
enable_github_api_mocks success
export ASDF_INSTALL_VERSION="v2.3.3"
out="$(bash "$ROOT_DIR/bin/download" 2>/dev/null)" || rc=$?
assert_equals 0 "$rc"
assert_equals "" "$out"
assert "test -x \"$ASDF_DOWNLOAD_PATH/bash_unit\""
```