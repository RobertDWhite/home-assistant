#!/bin/sh
# ha-lock.sh — write a git-friendly lockfile of everything installed on this HA box.
#
# Sources:
#   core   -> /config/.HA_VERSION            (+ `ha os/supervisor info` when available)
#   hacs   -> /config/.storage/hacs.repositories
#   addons -> `ha addons --raw-json`          (HAOS / Supervised only)
#
# Run from the Terminal & SSH / Advanced SSH add-on:
#   ./ha-lock.sh                # writes /config/ha-lock.json
#   ./ha-lock.sh /path/out.json
#
# Output is sorted and has no timestamps, so a re-run with nothing changed
# produces a byte-identical file (clean `git diff`).
set -eu

CONFIG="${HA_CONFIG:-/config}"
OUT="${1:-$CONFIG/ha-lock.json}"
TMP="$(mktemp)"
trap 'rm -f "$TMP" "$TMP.core" "$TMP.hacs" "$TMP.addons"' EXIT

command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }

# --- core -------------------------------------------------------------------
CORE_VERSION="$(tr -d '[:space:]' < "$CONFIG/.HA_VERSION" 2>/dev/null || echo unknown)"
OS_VERSION=null; SUP_VERSION=null; BOARD=null
if command -v ha >/dev/null; then
  OS_VERSION="$(ha os info --raw-json 2>/dev/null | jq '.data.version // null')" || OS_VERSION=null
  BOARD="$(ha os info --raw-json 2>/dev/null | jq '.data.board // null')" || BOARD=null
  SUP_VERSION="$(ha supervisor info --raw-json 2>/dev/null | jq '.data.version // null')" || SUP_VERSION=null
fi
jq -n --arg v "$CORE_VERSION" \
      --argjson os "${OS_VERSION:-null}" --argjson board "${BOARD:-null}" --argjson sup "${SUP_VERSION:-null}" \
  '{version:$v} + (if $os then {os:$os, board:$board} else {} end) + (if $sup then {supervisor:$sup} else {} end)' \
  > "$TMP.core"

# --- hacs -------------------------------------------------------------------
HACS_STORE="$CONFIG/.storage/hacs.repositories"
if [ -f "$HACS_STORE" ]; then
  jq '[ .data | to_entries[] | .value
        | select(.installed == true)
        | { repo: .full_name,
            category: .category,
            version: (.version_installed // .installed_commit // null) }
          + (if .domain then {domain: .domain} else {} end) ]
      | sort_by(.repo | ascii_downcase)' "$HACS_STORE" > "$TMP.hacs"
else
  echo '[]' > "$TMP.hacs"
fi

# --- add-ons ----------------------------------------------------------------
if command -v ha >/dev/null && ha addons --raw-json >/dev/null 2>&1; then
  # Resolve repository hash -> URL from the store listing when possible.
  ha store --raw-json 2>/dev/null | jq '.data.repositories // [] | map({key: .slug, value: .url}) | from_entries' > "$TMP.repos" 2>/dev/null || echo '{}' > "$TMP.repos"
  ha addons --raw-json | jq --slurpfile repos "$TMP.repos" '
      [ .data.addons[]
        | { slug: .slug, name: .name, version: .version, repository: .repository }
          + (if $repos[0][.repository] then {repository_url: $repos[0][.repository]} else {} end) ]
      | sort_by(.slug)' > "$TMP.addons"
  rm -f "$TMP.repos"
else
  echo '[]' > "$TMP.addons"
fi

# --- assemble ---------------------------------------------------------------
jq -n --slurpfile core "$TMP.core" --slurpfile hacs "$TMP.hacs" --slurpfile addons "$TMP.addons" \
  '{core: $core[0], hacs: $hacs[0], addons: $addons[0]}' > "$TMP"

if [ -f "$OUT" ] && cmp -s "$TMP" "$OUT"; then
  echo "unchanged: $OUT"
else
  mv "$TMP" "$OUT"; trap - EXIT
  echo "wrote: $OUT  ($(jq '.hacs|length' "$OUT") hacs, $(jq '.addons|length' "$OUT") add-ons, core $(jq -r .core.version "$OUT"))"
fi
