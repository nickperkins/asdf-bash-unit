---
applyTo: "bin/**, lib/**"
---

## Rules
- Use set -euo pipefail and strict quoting everywhere.
- Keep dependencies minimal: only coreutils + curl + grep + sed; no jq.
- HTTP
  - For list endpoints, prefer GET with -sSL and capture status: [bin/list-all](../../bin/list-all).
  - For single latest endpoint, allow simple GET with mktemp + trap: [bin/latest-stable](../../bin/latest-stable).
- Sorting versions: use padded numeric lexicographic sort as in [bin/list-all](../../bin/list-all).
- Temp files: create with mktemp; delete in trap; never leave residues.
- Errors: print only diagnostics to stderr via [bash.log_error()](../../lib/utils.sh); stdout is reserved for protocol outputs (e.g., versions).
- Tests must drive behavior; keep scripts silent on success unless required output.

## Reusable utilities
- Version normalization: [bash.clean_version()](../../lib/utils.sh)
- Version validation: [bash.validate_version_format()](../../lib/utils.sh)
- GitHub releases URL: [bash.get_releases_url()](../../lib/utils.sh)
- Connectivity check: [bash.check_network()](../../lib/utils.sh)
- Error logging: [bash.log_error()](../../lib/utils.sh)

## Example snippet (pattern)
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$ROOT_DIR/lib/utils.sh"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
url="$(get_releases_url latest)"
CURL_OPTS=(-sSL); [ -n "${GITHUB_API_TOKEN:-}" ] && CURL_OPTS+=(-H "Authorization: Bearer $GITHUB_API_TOKEN")
curl "${CURL_OPTS[@]}" "$url" -o "$tmp"
tag="$(sed -n -E 's/.*"tag_name" *: *"([^"]+)".*/\1/p' "$tmp" | head -n1)"
v="$(clean_version "$tag")"; validate_version_format "$v" || { log_error "invalid"; exit 3; }
printf '%s\n' "$v"
```