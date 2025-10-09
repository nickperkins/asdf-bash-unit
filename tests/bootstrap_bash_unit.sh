#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." > /dev/null 2>&1 && pwd)"

BASH_UNIT_VERSION="${BASH_UNIT_VERSION:-2.3.3}"
BASH_UNIT_VENDOR_DIR="${BASH_UNIT_VENDOR_DIR:-"$ROOT_DIR/tests/vendor"}"
BASH_UNIT_OFFLINE="${BASH_UNIT_OFFLINE:-1}"

VENDORED_PATH="$BASH_UNIT_VENDOR_DIR/bash_unit-$BASH_UNIT_VERSION"
mkdir -p "$BASH_UNIT_VENDOR_DIR"

if [ -x "$VENDORED_PATH" ]; then
  printf '%s\n' "$VENDORED_PATH"
  exit 0
fi

if [ "$BASH_UNIT_OFFLINE" != "0" ]; then
  echo "bootstrap_bash_unit: vendored bash_unit not found for version ${BASH_UNIT_VERSION} and offline mode is enabled. Expected at: ${VENDORED_PATH}" >&2
  exit 1
fi

TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/bash_unit.XXXXXX")"
cleanup() { rm -f "$TMP_FILE"; }
trap cleanup EXIT

URL="https://raw.githubusercontent.com/bash-unit/bash_unit/v${BASH_UNIT_VERSION}/bash_unit"
if ! curl -fsSL "$URL" -o "$TMP_FILE"; then
  echo "bootstrap_bash_unit: failed to download bash_unit from ${URL}" >&2
  exit 2
fi

if ! head -n1 "$TMP_FILE" | grep -qE '^#!'; then
  echo "bootstrap_bash_unit: downloaded file missing shebang" >&2
  exit 1
fi

mv "$TMP_FILE" "$VENDORED_PATH"
chmod 755 "$VENDORED_PATH"
printf '%s\n' "$VENDORED_PATH"
