#!/usr/bin/env bash

# Shared utility functions for asdf-bash-unit plugin
# Placeholder implementations to satisfy Task 1.3; real logic added in later tasks (7.x series).

validate_version_format() {
  # Validate semantic version format X.Y.Z where X,Y,Z are non-negative integers (no leading + sign)
  # Usage: validate_version_format "1.2.3"; returns 0 if valid, 1 if invalid
  local version="${1:-}"
  if [ -z "$version" ]; then
    return 1
  fi
  if echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    return 0
  fi
  return 1
}

get_releases_url() {
  # Return GitHub API URL for bash-unit releases.
  # Usage: get_releases_url            -> all releases endpoint
  #        get_releases_url latest     -> latest release endpoint
  local mode="${1:-}"
  local base="https://api.github.com/repos/bash-unit/bash_unit/releases"
  if [ "$mode" = "latest" ]; then
    printf '%s/latest' "$base"
  else
    printf '%s' "$base"
  fi
}

clean_version() {
  # Normalize a version string:
  #  - Trim surrounding whitespace
  #  - Remove leading 'v' or 'V'
  #  - Strip trailing newline
  #  - Echo cleaned value (no extra whitespace)
  # Usage: clean_version "v1.2.3" -> outputs 1.2.3
  local raw="${1:-}" cleaned
  # Trim whitespace using parameter expansion via printf
  # shellcheck disable=SC2001
  cleaned=$(printf '%s' "$raw" | sed -E 's/^ +//; s/ +$//; s/^[vV]//')
  printf '%s' "$cleaned"
}

check_network() {
  # Basic connectivity check to GitHub API. Returns 0 on success, 1 on failure.
  # Uses a fast HEAD request and short timeout.
  local url
  url=$(get_releases_url)
  if curl -s -I --max-time 5 "$url" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

log_error() {
  # Log an error message to stderr with contextual prefix.
  # Usage: log_error "message text"
  local msg="${1:-}"
  local ts
  ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  # Include script name if available
  local script_name
  script_name="${0##*/}"
  >&2 printf '[%s] %s ERROR: %s\n' "$ts" "$script_name" "$msg"
}
