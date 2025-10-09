#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TEST_DIR="$ROOT_DIR/tests"

# Bootstrap bash_unit (prints path on stdout)
BASH_UNIT_BIN="$(bash "$TEST_DIR/bootstrap_bash_unit.sh")"

# Discover test files
TESTS="$(find "$TEST_DIR" -type f -name 'test_*.sh' ! -name 'test_helpers.sh' | LC_ALL=C sort || true)"

if [ -z "${TESTS}" ]; then
  echo "No tests found under $TEST_DIR" >&2
  exit 1
fi

# shellcheck disable=SC2086 # intentional word splitting for test list
"$BASH_UNIT_BIN" "$@" ${TESTS}
