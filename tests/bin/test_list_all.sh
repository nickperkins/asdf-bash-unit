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

test_list_all_success_outputs_sorted_single_line() {
  enable_github_api_mocks success
  local out last tmp
  tmp="$(mktemp)"
  bash "$ROOT_DIR/bin/list-all" > "$tmp"
  out="$(cat "$tmp")"
  assert "test -n \"$out\"" "list-all output should not be empty"
  assert_equals "2.3.1 2.3.2 2.3.3" "$out" "should equal expected space-separated semver list"
  last="${out##* }"
  assert_equals 2.3.3 "$last" "latest version should be 2.3.3 from mock data"
  # Newline-terminated single line: wc -l counts trailing newline, should be 1
  assert_equals 1 "$(wc -l < "$tmp" | tr -d ' ')" "output should be newline-terminated (single line)"
  # No 'v' prefixes after cleaning
  assert_fail "printf '%s' \"$out\" | grep -q 'v'" "versions should be cleaned without 'v' prefix"
  rm -f "$tmp"
  disable_github_api_mocks
}

test_list_all_handles_http_500() {
  enable_github_api_mocks http_500
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/list-all" 2>&1 1> /dev/null)" || rc=$?
  assert "test $rc -ne 0" "list-all should exit non-zero on HTTP 500"
  assert 'printf "%s" "$err" | grep -Eqi "500|HTTP|GitHub API"' "stderr should mention HTTP error"
  disable_github_api_mocks
}

test_list_all_handles_network_error() {
  enable_github_api_mocks network_error
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/list-all" 2>&1 1> /dev/null)" || rc=$?
  assert_equals 2 "$rc" "list-all should exit 2 on network error"
  assert 'printf "%s" "$err" | grep -Eqi "network|curl"' "stderr should mention network/curl"
  disable_github_api_mocks
}

test_list_all_outputs_semver_versions() {
  enable_github_api_mocks success
  local out
  out=$(bash "$ROOT_DIR/bin/list-all")
  assert 'printf "%s" "$out" | grep -Eq "^[0-9]+\.[0-9]+\.[0-9]+( [0-9]+\.[0-9]+\.[0-9]+)*$"' "output should be space-separated semver versions"
  disable_github_api_mocks
}

test_list_all_handles_malformed_json() {
  enable_github_api_mocks malformed_json
  local rc=0 err
  err="$(bash "$ROOT_DIR/bin/list-all" 2>&1 1> /dev/null)" || rc=$?
  assert "test $rc -ne 0" "list-all should fail on malformed JSON"
  assert 'printf "%s" "$err" | grep -Eqi "tag_name|malformed|parse"' "stderr should mention missing tag_name or parse error"
  disable_github_api_mocks
}

test_list_all_sends_auth_header_when_token_set() {
  export GITHUB_API_TOKEN=token123
  enable_github_api_mocks success
  # clear previous logs to ensure deterministic assertion
  rm -f "$TEST_TMP_ROOT/mockbin/curl_argv.log" || true
  # trigger a request
  bash "$ROOT_DIR/bin/list-all" > /dev/null 2>&1 || true
  # assert Authorization header was passed
  assert 'grep -q "Authorization: Bearer token123" "$TEST_TMP_ROOT/mockbin/curl_argv.log"' "should include Authorization header with token"
  disable_github_api_mocks
  unset GITHUB_API_TOKEN
}
