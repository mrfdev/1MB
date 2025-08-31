#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-Version.sh  v0.1.0 (build 003)
# Query PaperMC Fill v3 API for a single Paper version (DEFAULT_VERSION).
# Pretty output via jq, cache compare for newer build since last run.
# Cache: .paper-version-cache.json
#
# Usage: ./1MB-Paper-API-Query-Version.sh

set -euo pipefail

# -------------------------
# Config (edit these)
# -------------------------
CACHE_FILE=".paper-version-cache.json"           # Cache for single version endpoint
DEFAULT_PROJECT="paper"                          # Project id (assumed 'paper')
DEFAULT_VERSION="1.21.8"                         # Version to inspect (no build tag)
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"
TIMEOUT_SECS=15
# How many builds to show (0 = none, -1 = all)
BUILDS_SHOWN=15
# -------------------------

have() { command -v "$1" >/dev/null 2>&1; }

HTTP_CLIENT=""
if have curl; then
  HTTP_CLIENT="curl"
elif have wget; then
  HTTP_CLIENT="wget"
else
  echo "Error: neither curl nor wget is available. Please install one and retry." >&2
  exit 127
fi

http_get() {
  local url="$1"
  if [[ "$HTTP_CLIENT" == "curl" ]]; then
    curl -fLsS -A "$USER_AGENT" -H 'accept: application/json' --max-time "$TIMEOUT_SECS" "$url"
  else
    wget -qO- --user-agent="$USER_AGENT" --header='accept: application/json' --timeout="$TIMEOUT_SECS" "$url"
  fi
}

# Require jq
if ! have jq; then
  echo "Error: 'jq' is required. Please install jq (brew install jq) and retry." >&2
  exit 2
fi

# Save / load cache
save_cache() { printf "%s\n" "$1" > "$CACHE_FILE"; }
load_cache()  { [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }

# Quick JSON validity
is_valid_json() { [[ -n "${1:-}" ]] && jq -e . >/dev/null 2>&1 <<<"$1"; }

# Join stdin lines with a delimiter (default: ", ")
join_lines() {
  local delim="${1:-, }"
  awk -v d="$delim" 'BEGIN{first=1} {if(!first) printf("%s",d); printf("%s",$0); first=0} END{if(!first) printf("\n")}'
}

main() {
  local url="$API_BASE/projects/$DEFAULT_PROJECT/versions/$DEFAULT_VERSION"

  local fresh_json
  if ! fresh_json="$(http_get "$url")"; then
    echo "Error: failed to fetch $url" >&2
    exit 1
  fi

  echo "== PaperMC Single Version (from $API_BASE) =="
  echo "User-Agent: $USER_AGENT"
  echo "Project: $DEFAULT_PROJECT"
  echo "Version: $DEFAULT_VERSION"
  echo

  # Normalize payload to a compact object we can query easily
  # { id, support, java_min, flags[], builds[], latest_build, builds_count }
  local norm
  norm="$(jq -c '{
      id: (.version.id // "unknown"),
      support: (.version.support.status // "UNKNOWN"),
      java_min: (.version.java.version.minimum // null),
      flags: (.version.java.flags.recommended // []),
      builds: (.builds // [])
    } | . + {
      latest_build: (if (.builds|length)>0 then (.builds | max) else null end),
      builds_count: (.builds | length)
    }' <<<"$fresh_json")"

  # Extract fields
  local support java_min latest_build builds_count
  support="$(jq -r '.support' <<<"$norm")"
  java_min="$(jq -r '.java_min // "?"' <<<"$norm")"
  latest_build="$(jq -r '.latest_build // "?"' <<<"$norm")"
  builds_count="$(jq -r '.builds_count' <<<"$norm")"

  echo "Details:"
  echo "  Support: $support"
  echo "  Min Java: ≥ $java_min"

  # Recommended flags (one per line)
  local flags_count
  flags_count="$(jq -r '.flags | length' <<<"$norm")"
  if (( flags_count > 0 )); then
    echo "  Recommended flags:"
    jq -r '.flags[]' <<<"$norm" | sed 's/^/    /'
  else
    echo "  Recommended flags: (none)"
  fi

  # Builds
  if [[ "${BUILDS_SHOWN}" -ne 0 ]]; then
    echo
    echo "Builds (latest first):"
    if [[ "${BUILDS_SHOWN}" -lt 0 ]]; then
      jq -r '.builds | sort | reverse | .[] | tostring' <<<"$norm" | sed 's/^/  /'
    else
      local builds_line extra
      builds_line="$(jq -r '.builds | sort | reverse | .[] | tostring' <<<"$norm" | head -n "$BUILDS_SHOWN" | join_lines ', ')"
      extra=$(( builds_count - BUILDS_SHOWN ))
      if (( extra > 0 )); then
        echo "  $builds_line … (+$extra more)"
      else
        echo "  $builds_line"
      fi
    fi
  fi

  echo
  echo "Summary:"
  echo "  Latest build for $DEFAULT_VERSION: $latest_build"
  echo "  Support status: $support"
  echo "  Min Java:       $java_min"

  # Compare to previous cache (newer build since last time?)
  local prev_json have_prev_cache="false"
  prev_json="$(load_cache || true)"
  if [[ -n "$prev_json" ]] && is_valid_json "$prev_json"; then
    have_prev_cache="true"
    # Only compare if cached version id matches our DEFAULT_VERSION
    local prev_id prev_latest_build
    prev_id="$(jq -r '.version.id // empty' <<<"$prev_json")"
    if [[ "$prev_id" == "$DEFAULT_VERSION" ]]; then
      prev_latest_build="$(jq -r '(.builds // []) | if length>0 then (max|tostring) else empty end' <<<"$prev_json")"
      if [[ -n "$prev_latest_build" ]]; then
        if [[ "$latest_build" =~ ^[0-9]+$ && "$prev_latest_build" =~ ^[0-9]+$ ]]; then
          if (( latest_build > prev_latest_build )); then
            echo "  Newer build since cache? Yes (latest: $latest_build — cached: $prev_latest_build)"
          else
            echo "  Newer build since cache? No (latest: $latest_build — cached: $prev_latest_build)"
          fi
        else
          echo "  Newer build since cache? Unknown (non-numeric build data)"
        fi
      else
        echo "  Newer build since cache? Unknown (no cached build found)"
      fi
    else
      [[ -n "$prev_id" ]] && echo "  Note: cache was for a different version ($prev_id); not comparing builds."
    fi
  else
    echo "  Newer build since cache? Unknown (no previous cache)"
  fi

  # Write the fresh payload to cache (last step)
  save_cache "$fresh_json"
  echo
  echo "Cache updated at: $CACHE_FILE"
}

main "$@"
