#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP_ROOT="${TEST_TMP_ROOT:-$(mktemp -d)}"
export TEST_TMP_ROOT
export ASDF_DOWNLOAD_PATH="$TEST_TMP_ROOT/download"
export ASDF_INSTALL_PATH="$TEST_TMP_ROOT/install"
mkdir -p "$ASDF_DOWNLOAD_PATH" "$ASDF_INSTALL_PATH"

# Helper to reset install/download dirs per test if needed
reset_paths() {
  rm -rf "$ASDF_DOWNLOAD_PATH" "$ASDF_INSTALL_PATH"
  mkdir -p "$ASDF_DOWNLOAD_PATH" "$ASDF_INSTALL_PATH"
}

# Test data generation
gen_releases_json() {
  printf '[{"tag_name":"v2.3.3"},{"tag_name":"v2.3.2"},{"tag_name":"v2.3.1"}]'
}
gen_latest_json() { printf '{"tag_name":"v2.3.3"}'; }
gen_bash_script() {
  local content="${1:-echo ok}"
  printf '#!/usr/bin/env bash\n%s\n' "$content"
}

# bash-unit lifecycle: cleanup tmp on suite end
teardown_suite() {
  rm -rf "$TEST_TMP_ROOT" || true
}

export ROOT_DIR TEST_TMP_ROOT ASDF_DOWNLOAD_PATH ASDF_INSTALL_PATH
export -f reset_paths gen_releases_json gen_latest_json gen_bash_script
