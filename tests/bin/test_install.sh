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

# Success path (primary path using ASDF_DOWNLOAD_PATH), stdout silent
test_install_from_download_path_success_silent() {
  local downloaded_file="$ASDF_DOWNLOAD_PATH/bash_unit"
  gen_bash_script 'echo ok' > "$downloaded_file"
  chmod +x "$downloaded_file"

  export ASDF_INSTALL_TYPE=version
  export ASDF_INSTALL_VERSION=2.3.3

  local rc=0 out
  out="$(bash "$ROOT_DIR/bin/install" 2> /dev/null)" || rc=$?
  assert_equals 0 "$rc" "install should exit 0 on success"
  assert_equals "" "$out" "install should be silent on stdout"

  local target_file="$ASDF_INSTALL_PATH/bin/bash_unit"
  assert "test -f \"$target_file\"" "installed file should exist at $target_file"
  assert "test -x \"$target_file\"" "installed file should be executable"
}

# Negative: Missing ASDF_INSTALL_PATH -> exit 3 with diagnostic
test_install_missing_install_path_errors() {
  local saved_install_path="${ASDF_INSTALL_PATH}"
  unset ASDF_INSTALL_PATH || true
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/install" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 3 "$rc" "missing ASDF_INSTALL_PATH should exit 3"
  assert 'printf "%s" "$err" | grep -qi "ASDF_INSTALL_PATH is not set"' "stderr should mention missing ASDF_INSTALL_PATH"
  export ASDF_INSTALL_PATH="$saved_install_path"
}

# Negative: ASDF_INSTALL_TYPE=ref -> exit 3 with diagnostic
test_install_rejects_ref_type() {
  export ASDF_INSTALL_TYPE=ref
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/install" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 3 "$rc" "ASDF_INSTALL_TYPE=ref should exit 3 (unsupported)"
  assert 'printf "%s" "$err" | grep -qi "ref installs unsupported"' "stderr should mention unsupported ref"
}

# Legacy fallback: when ASDF_DOWNLOAD_PATH unset, install downloads itself (using mocks)
test_install_legacy_fallback_when_no_download_path() {
  enable_github_api_mocks success
  unset ASDF_DOWNLOAD_PATH || true
  export ASDF_INSTALL_TYPE=version
  export ASDF_INSTALL_VERSION="v2.3.3"

  local rc=0 out
  out="$(bash "$ROOT_DIR/bin/install" 2> /dev/null)" || rc=$?
  assert_equals 0 "$rc" "install should succeed via legacy fallback"
  assert_equals "" "$out" "install should be silent on success"

  local target_file="$ASDF_INSTALL_PATH/bin/bash_unit"
  assert "test -f \"$target_file\"" "installed file should exist at $target_file"
  assert "test -x \"$target_file\"" "installed file should be executable"
}

# Permission failure: make parent of ASDF_INSTALL_PATH unwritable and ensure no partial install
test_install_permission_failure_has_no_partial() {
  # Prepare a downloaded artifact so install attempts to copy
  local downloaded_file="$ASDF_DOWNLOAD_PATH/bash_unit"
  gen_bash_script 'echo ok' > "$downloaded_file"
  chmod +x "$downloaded_file"

  # Create unwritable parent directory
  local nowrite="$TEST_TMP_ROOT/unwritable_parent"
  mkdir -p "$nowrite"
  chmod -w "$nowrite"

  export ASDF_INSTALL_PATH="$nowrite/subdir"
  local rc=0
  bash "$ROOT_DIR/bin/install" 1> /dev/null 2> /dev/null || rc=$?
  assert "test $rc -ne 0" "install should fail when parent is unwritable"
  assert "test ! -f \"$ASDF_INSTALL_PATH/bin/bash_unit\"" "no partial install should remain on failure"

  # Restore permissions for cleanup and reset path
  chmod +w "$nowrite" || true
  export ASDF_INSTALL_PATH="$TEST_TMP_ROOT/install"
}
