#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/tests/test_helpers.sh"
. "$ROOT_DIR/lib/utils.sh"
. "$ROOT_DIR/tests/mocks/github_api.sh"

setup() {
  disable_github_api_mocks || true
}

teardown() {
  disable_github_api_mocks || true
}

test_validate_version_format_accepts_good() {
  assert "validate_version_format 1.2.3"
}

test_validate_version_format_rejects_bad() {
  assert_fail validate_version_format 1.2 "should reject incomplete semver"
}

test_clean_version_strips_v_and_spaces() {
  local cleaned
  cleaned=$(clean_version ' v1.2.3 ')
  assert_equals 1.2.3 "$cleaned"
}

# Additional tests for utils.sh

test_log_error_writes_to_stderr_and_contains_message() {
  local tmp content
  tmp="$(mktemp)"
  # log_error writes to stderr; suppress stdout
  log_error "sample error message" 1> /dev/null 2> "$tmp"
  content="$(cat "$tmp")"
  rm -f "$tmp"

  assert "test -n \"$content\"" "log_error should write something to stderr"
  assert 'printf "%s" "$content" | grep -q "ERROR:"' "stderr should contain ERROR tag"
  assert 'printf "%s" "$content" | grep -q "sample error message"' "stderr should include provided message"
}

test_clean_version_handles_uppercase_V_and_newlines() {
  local cleaned
  cleaned=$(clean_version $' \tV2.3.4 \n')
  assert_equals 2.3.4 "$cleaned"
}

test_validate_version_format_rejects_prefixed_and_extra_segments() {
  assert_fail validate_version_format v1.2.3 "should reject versions with v prefix"
  assert_fail validate_version_format 1.2.3.4 "should reject versions with more than 3 segments"
  assert_fail validate_version_format "" "should reject empty version"
}

# New tests for check_network() using mocks
test_check_network_success_with_mocks() {
  enable_github_api_mocks success
  assert check_network
  disable_github_api_mocks
}

test_check_network_fails_with_network_error_mocks() {
  enable_github_api_mocks network_error
  assert_fail check_network "check_network should fail on network error"
  disable_github_api_mocks
}
