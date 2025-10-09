#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/tests/test_helpers.sh"
. "$ROOT_DIR/tests/mocks/github_api.sh"

setup() {
  disable_github_api_mocks || true
}

teardown() {
  disable_github_api_mocks || true
}

test_latest_stable_returns_expected_version() {
  enable_github_api_mocks success
  local v
  v=$(bash "$ROOT_DIR/bin/latest-stable")
  assert_equals "2.3.3" "$v"
  disable_github_api_mocks
}

test_latest_stable_accepts_optional_query_arg() {
  enable_github_api_mocks success
  local v
  v=$(bash "$ROOT_DIR/bin/latest-stable" "2")
  assert_equals "2.3.3" "$v"
  disable_github_api_mocks
}

test_latest_stable_handles_http_500() {
  enable_github_api_mocks http_500
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/latest-stable" 2>&1 1> /dev/null)" || rc=$?
  assert "test $rc -ne 0" "latest-stable should exit non-zero on HTTP 500"
  assert 'printf "%s" "$err" | grep -Eqi "500|HTTP|GitHub API|Failed to fetch|Network"' "stderr should mention HTTP error"
  disable_github_api_mocks
}

test_latest_stable_handles_network_error() {
  enable_github_api_mocks network_error
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/latest-stable" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 2 "$rc" "latest-stable should exit 2 on network error"
  assert 'printf "%s" "$err" | grep -Eqi "network|curl|Failed to fetch"' "stderr should mention network/curl"
  disable_github_api_mocks
}
