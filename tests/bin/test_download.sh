#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/tests/test_helpers.sh"
. "$ROOT_DIR/tests/mocks/github_api.sh"

setup() {
  reset_paths
  disable_github_api_mocks || true
}

teardown() {
  disable_github_api_mocks || true
}

# Success: stdout is silent; file exists with shebang
test_download_fetches_file_silently() {
  enable_github_api_mocks success
  assert 'command -v curl | grep -q "$TEST_TMP_ROOT/mockbin/curl"' "mock curl should be on PATH"
  export ASDF_INSTALL_VERSION="v2.3.3"
  local rc=0 out
  out="$(bash "$ROOT_DIR/bin/download" 2> /dev/null)" || rc=$?
  assert_equals 0 "$rc" "download should exit 0 on success"
  assert_equals "" "$out" "download should be silent on stdout"
  assert "test -f \"$ASDF_DOWNLOAD_PATH/bash_unit\"" "downloaded file should exist at ASDF_DOWNLOAD_PATH/bash_unit"
  assert "head -n1 \"$ASDF_DOWNLOAD_PATH/bash_unit\" | grep -Eq '^#!'" "downloaded file should start with shebang"
}

# Negative: missing ASDF_INSTALL_VERSION -> exit 3
test_download_requires_version_env() {
  disable_github_api_mocks || true
  unset ASDF_INSTALL_VERSION || true
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/download" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 3 "$rc" "missing ASDF_INSTALL_VERSION should exit 3"
  assert 'printf "%s" "$err" | grep -q "ASDF_INSTALL_VERSION is not set"' "stderr should mention missing version"
  assert 'test -z "$(ls -A "$ASDF_DOWNLOAD_PATH")"' "no files should be left in ASDF_DOWNLOAD_PATH"
}

# Negative: invalid version format -> exit 3
test_download_rejects_invalid_version_format() {
  disable_github_api_mocks || true
  export ASDF_INSTALL_VERSION="invalid.version"
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/download" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 3 "$rc" "invalid version format should exit 3"
  assert 'printf "%s" "$err" | grep -qi "Invalid version format"' "stderr should mention invalid format"
  assert 'test -z "$(ls -A "$ASDF_DOWNLOAD_PATH")"' "no files should be left in ASDF_DOWNLOAD_PATH"
}

# Negative: missing ASDF_DOWNLOAD_PATH -> exit 3
test_download_requires_download_path_env() {
  enable_github_api_mocks success
  export ASDF_INSTALL_VERSION="v2.3.3"
  unset ASDF_DOWNLOAD_PATH || true
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/download" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 3 "$rc" "missing ASDF_DOWNLOAD_PATH should exit 3"
  assert 'printf "%s" "$err" | grep -q "ASDF_DOWNLOAD_PATH is not set"' "stderr should mention missing download path"
}

# Negative: ASDF_INSTALL_TYPE=ref unsupported -> exit 3
test_download_rejects_ref_installs() {
  disable_github_api_mocks || true
  export ASDF_INSTALL_TYPE=ref
  export ASDF_INSTALL_VERSION="v2.3.3"
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/download" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 3 "$rc" "ref installs should exit 3 (unsupported)"
  assert 'printf "%s" "$err" | grep -qi "ref installs unsupported"' "stderr should mention unsupported ref"
}

# Negative: network_error -> exit 2; partial cleaned
test_download_handles_network_error_and_cleans() {
  enable_github_api_mocks network_error
  assert 'command -v curl | grep -q "$TEST_TMP_ROOT/mockbin/curl"' "mock curl should be on PATH"
  export ASDF_INSTALL_VERSION="v2.3.3"
  local rc=0
  bash "$ROOT_DIR/bin/download" 1> /dev/null 2> /dev/null || rc=$?
  assert_equals 2 "$rc" "network error should exit 2"
  # No target or temp artifacts left behind
  assert "test ! -f \"$ASDF_DOWNLOAD_PATH/bash_unit\"" "target should not exist after failure"
  assert 'test -z "$(ls -A "$ASDF_DOWNLOAD_PATH")"' "no residual temp artifacts should remain"
}

# Negative: corrupt_raw -> non-zero; cleaned
test_download_detects_corrupted_file_and_cleans_up() {
  enable_github_api_mocks corrupt_raw
  assert 'command -v curl | grep -q "$TEST_TMP_ROOT/mockbin/curl"' "mock curl should be on PATH"
  export ASDF_INSTALL_VERSION="v2.3.3"
  local rc=0
  bash "$ROOT_DIR/bin/download" 1> /dev/null 2> /dev/null || rc=$?
  assert "test $rc -ne 0" "download should fail when file lacks bash shebang"
  assert "test ! -f \"$ASDF_DOWNLOAD_PATH/bash_unit\"" "target should not exist after failure"
  assert 'test -z "$(ls -A "$ASDF_DOWNLOAD_PATH")"' "no residual temp artifacts should remain"
}
