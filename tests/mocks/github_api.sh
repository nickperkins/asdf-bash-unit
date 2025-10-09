#!/usr/bin/env bash
set -euo pipefail

# GitHub API Mock Utilities for asdf-bash-unit-plugin tests
# Provides a mock 'curl' to simulate:
#  - GET https://api.github.com/repos/bash-unit/bash_unit/releases
#  - GET https://api.github.com/repos/bash-unit/bash_unit/releases/latest
#  - GET https://raw.githubusercontent.com/bash-unit/bash_unit/vX.Y.Z/bash_unit (optional for download tests)
#
# Usage in tests:
#   . "$(dirname "${BASH_SOURCE[0]}")/github_api.sh"
#   enable_github_api_mocks            # default: success mode (HTTP 200)
#   enable_github_api_mocks http_500   # to simulate HTTP 500
#   enable_github_api_mocks network_error   # to simulate network failure (curl non-zero)
#   ... run script under test ...
#   disable_github_api_mocks
#
# Environment variables honored:
#   - TEST_TMP_ROOT: base temp directory for tests (created by tests/test_helpers.sh)
#   - GITHUB_API_MOCK_MODE: success | http_500 | network_error
#   - BASH_UNIT_MOCK_MODE: exported to indicate mocks are active
#
# This file satisfies Tasks 9.3 validation:
#   - Provides mock curl function via PATH shim
#   - Mock responses match GitHub API JSON shapes
#   - Supports success and error scenarios

# Internal: produce a JSON body for a given URL and set HTTP code
_github_api_mock_resolve() {
  local url="${1:-}"
  local mode="${GITHUB_API_MOCK_MODE:-success}"
  local http_code=200
  local body

  case "$mode" in
    network_error)
      # Signal curl transport failure by returning a special code
      echo "__NETWORK_ERROR__"
      return 7
      ;;
    http_500)
      http_code=500
      ;;
    *)
      http_code=200
      ;;
  esac

  if [[ "$url" =~ /releases/latest($|\?) ]]; then
    body='{"tag_name":"v2.3.3"}'
  elif [[ "$url" =~ /releases($|\?) ]]; then
    body='[{"tag_name":"v2.3.3"},{"tag_name":"v2.3.2"},{"tag_name":"v2.3.1"}]'
  elif [[ "$url" =~ ^https://raw\.githubusercontent\.com/bash-unit/bash_unit/v([0-9]+\.[0-9]+\.[0-9]+)/bash_unit$ ]]; then
    # Minimal but valid script with bash shebang for download tests
    local ver
    ver="${BASH_REMATCH[1]}"
    body='#!/usr/bin/env bash
echo "bash_unit '"$ver"'"'
  else
    body='{}'
  fi

  printf '%s\n' "$http_code"
  printf '%s' "$body"
  return 0
}

# Generate the mock curl script content to be placed early in PATH.
_generate_mock_curl_script() {
  cat << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Log raw argv for assertions; keep quiet on stdout/stderr
if [[ -n "${TEST_TMP_ROOT:-}" ]]; then
  mkdir -p "$TEST_TMP_ROOT/mockbin"
  printf '%s\n' "$*" >> "$TEST_TMP_ROOT/mockbin/curl_argv.log"
fi
# Lightweight mock of curl used by tests.
# Supports subset of options used by plugin scripts:
#   -s -S -L -f (ignored), -H (ignored), -I (ignored), --max-time N (ignored), -w '%{http_code}', -o <file>, URL

http_code_fmt=""
out_file=""
url=""
seen_head=0

# parse args
while [[ $# -gt 0 ]]; do
  arg="${1:-}"
  case "$arg" in
    -w)
      shift || true
      http_code_fmt="${1:-}"
      ;;
    -o)
      shift || true
      out_file="${1:-}"
      ;;
    -H)
      # consume the header argument to avoid treating it as the URL
      shift || true
      : "${1:-}" # header value ignored
      ;;
    --max-time)
      # ignore timeout option and consume its numeric argument
      shift || true
      ;;
    --*)
      # ignore other long options
      ;;
    -*)
      # handle any cluster of short flags like -sSL, -fsI, etc.
      if [[ "$arg" == *I* ]]; then
        seen_head=1
      fi
      ;;
    *)
      if [[ -z "${url:-}" ]]; then
        url="$arg"
      fi
      ;;
  esac
  shift || true
done

mode="${GITHUB_API_MOCK_MODE:-success}"

# Debug: log parsed values for investigation
if [[ -n "${TEST_TMP_ROOT:-}" ]]; then
  mkdir -p "$TEST_TMP_ROOT/mockbin"
  printf 'mode=%s url=%q http_code_fmt=%q out_file=%q seen_head=%s\n' "$mode" "${url:-}" "${http_code_fmt:-}" "${out_file:-}" "${seen_head:-0}" >> "$TEST_TMP_ROOT/mockbin/curl_debug.log"
fi

# HEAD requests: allow success; http_code determined by mode below
if [[ "$mode" == "http_500" && "${seen_head:-0}" -eq 1 ]]; then
  : # no-op; do not fail HEAD, status code handled via http_code below
fi
# (end HEAD handling)

# Handle network error mode: simulate curl transport failure
if [[ "$mode" == "network_error" ]]; then
  exit 7
fi

http_code=200
body=""

if [[ "$mode" == "http_500" ]]; then
  http_code=500
fi

# In http_500 mode, if caller did not request HTTP code via -w and this is not a HEAD request,
# simulate curl failure (exit 22) so scripts that don't capture status (e.g., latest-stable) error out.
if [[ "$mode" == "http_500" && -z "${http_code_fmt:-}" && "${seen_head:-0}" -eq 0 ]]; then
  exit 22
fi

if [[ "$url" =~ /releases/latest($|\?) ]]; then
  # latest endpoint: keep success shape unless a specific malformed_latest mode is added
  body='{"tag_name":"v2.3.3"}'
elif [[ "$url" =~ /releases($|\?) ]]; then
  # list-all endpoint: allow malformed_json mode to simulate missing tag_name with HTTP 200
  if [[ "$mode" == "malformed_json" ]]; then
    body='[{"no_tag":"v2.3.3"}]'
  else
    body='[{"tag_name":"v2.3.1"},{"tag_name":"v2.3.2"},{"tag_name":"v2.3.3"}]'
  fi
elif [[ "$url" =~ ^https://raw\.githubusercontent\.com/bash-unit/bash_unit/v([0-9]+\.[0-9]+\.[0-9]+)/bash_unit$ ]]; then
  ver="${BASH_REMATCH[1]}"
  if [[ "$mode" == "corrupt_raw" ]]; then
    # Return content that intentionally lacks a bash shebang
    body='this is not a bash script'
  else
    body='#!/usr/bin/env bash
# mock bash_unit
echo "ok"'
  fi
else
  body='{}'
fi

# Write body either to file or stdout
if [[ -n "${out_file:-}" ]]; then
  printf '%s' "$body" > "$out_file"
else
  printf '%s' "$body"
fi

# If -w '%{http_code}' present, print HTTP code to stdout (caller may redirect)
if [[ -n "${http_code_fmt:-}" ]]; then
  # Only %{http_code} is expected by tests/scripts; print numeric code
  printf '%s' "$http_code"
fi

exit 0
EOF
}

# Public: enable mocks by placing a mock 'curl' early in PATH.
enable_github_api_mocks() {
  local mode="${1:-success}"
  export GITHUB_API_MOCK_MODE="$mode"
  export BASH_UNIT_MOCK_MODE=1

  # Determine mock bin dir under test temp root
  local base="${TEST_TMP_ROOT:-$(mktemp -d)}"
  local mock_bin="$base/mockbin"
  mkdir -p "$mock_bin"

  # Install mock curl
  local curl_mock="$mock_bin/curl"
  _generate_mock_curl_script > "$curl_mock"
  chmod +x "$curl_mock"

  # Preserve original PATH once
  if [ -z "${ORIGINAL_PATH_FOR_GITHUB_API_MOCKS:-}" ]; then
    export ORIGINAL_PATH_FOR_GITHUB_API_MOCKS="$PATH"
  fi
  export PATH="$mock_bin:$PATH"

  # Export path for teardown
  export GITHUB_API_MOCK_BIN_DIR="$mock_bin"
}

# Public: disable mocks and restore PATH.
disable_github_api_mocks() {
  if [ -n "${ORIGINAL_PATH_FOR_GITHUB_API_MOCKS:-}" ]; then
    export PATH="$ORIGINAL_PATH_FOR_GITHUB_API_MOCKS"
    unset ORIGINAL_PATH_FOR_GITHUB_API_MOCKS
  fi
  if [ -n "${GITHUB_API_MOCK_BIN_DIR:-}" ] && [ -d "$GITHUB_API_MOCK_BIN_DIR" ]; then
    rm -rf "$GITHUB_API_MOCK_BIN_DIR" || true
  fi
  unset GITHUB_API_MOCK_MODE
  unset BASH_UNIT_MOCK_MODE
  unset GITHUB_API_MOCK_BIN_DIR
}

# Public: run a command with mocks enabled for the duration.
with_github_api_mocks() {
  local mode="${1:-success}"
  shift || true
  enable_github_api_mocks "$mode"
  # shellcheck disable=SC2068
  "$@"
  local rc=$?
  disable_github_api_mocks
  return $rc
}

export -f enable_github_api_mocks disable_github_api_mocks with_github_api_mocks
# End of mocks
