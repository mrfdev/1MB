#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-Versions.sh  v0.0.1 (build 001)
# Query PaperMC Fill v3 API for all versions of a single project (paper)
# Pretty output via jq, semver sorting via gsort/sort -V fallback.
# Cache: .paper-versions-cache.json
#
# Usage: ./1MB-Paper-API-Query-Versions.sh

set -euo pipefail

# -------------------------
# Config (edit these)
# -------------------------
CACHE_FILE=".paper-versions-cache.json"          # Cache for versions endpoint
DEFAULT_PROJECT="paper"                          # Project id (assumed 'paper')
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"
TIMEOUT_SECS=15
# How many builds to show per version (set 0 for none, -1 for 'all' - not recommended)
BUILDS_SHOWN=10
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

USE_JQ="false"; have jq && USE_JQ="true"

# Semver-aware sorting
semver_sort_desc() {
  if have gsort; then gsort -Vr
  elif sort -V </dev/null >/dev/null 2>&1; then sort -Vr
  else cat
  fi
}
semver_sort_asc() {
  if have gsort; then gsort -V
  elif sort -V </dev/null >/dev/null 2>&1; then sort -V
  else sort
  fi
}

# Save / load cache (raw JSON)
save_cache() { printf "%s\n" "$1" > "$CACHE_FILE"; }
load_cache()  { [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }  # only if file exists AND non-empty

# Quick JSON validity
is_valid_json() { [[ -n "${1:-}" ]] && jq -e . >/dev/null 2>&1 <<<"$1"; }

# Join stdin lines with a delimiter (default: ", ")
join_lines() {
  local delim="${1:-, }"
  awk -v d="$delim" 'BEGIN{first=1} {if(!first) printf("%s",d); printf("%s",$0); first=0} END{if(!first) printf("\n")}'
}

# Normalize API JSON to flat objects:
# { id, support, java_min, flags[], builds[], latest_build, builds_count }
normalize_versions() {
  jq -c '
    # Handle either {"versions":[...]} or a raw array
    (.versions // .) 
    | map({
        id: (.version.id // "unknown"),
        support: (.version.support.status // "UNKNOWN"),
        java_min: (.version.java.version.minimum // null),
        flags: (.version.java.flags.recommended // []),
        builds: (.builds // [])
      })
    | map(. + {
        latest_build: (if (.builds|length)>0 then (.builds | max) else null end),
        builds_count: (.builds | length)
      })
  '
}

main() {
  local url="$API_BASE/projects/$DEFAULT_PROJECT/versions"
  local fresh_json
  if ! fresh_json="$(http_get "$url")"; then
    echo "Error: failed to fetch $url" >&2
    exit 1
  fi

  echo "== PaperMC Versions (from $API_BASE) =="
  echo "User-Agent: $USER_AGENT"
  echo "Project: $DEFAULT_PROJECT"
  echo

  if [[ "$USE_JQ" != "true" ]]; then
    echo "Error: 'jq' is required for this script. Please install jq (brew install jq) and retry." >&2
    exit 2
  fi

  # Normalize
  local norm
  norm="$(printf "%s" "$fresh_json" | normalize_versions)"

  # IDs sorted (desc semver)
  local ids_desc
  ids_desc="$(printf "%s" "$norm" | jq -r '.[].id' | semver_sort_desc)"

  if [[ -z "$ids_desc" ]]; then
    echo "No versions found."
    save_cache "$fresh_json"
    exit 3
  fi

  # Print per-version details
  while IFS= read -r vid; do
    [[ -z "$vid" ]] && continue
    local item
    item="$(printf "%s" "$norm" | jq -c --arg id "$vid" 'map(select(.id==$id))[0]')"
    [[ -z "$item" || "$item" == "null" ]] && continue

    local support java_min latest_build builds_count
    support="$(jq -r '.support // "UNKNOWN"' <<<"$item")"
    java_min="$(jq -r '.java_min // "?"' <<<"$item")"
    latest_build="$(jq -r '.latest_build // "?"' <<<"$item")"
    builds_count="$(jq -r '.builds_count' <<<"$item")"

    echo "$vid:"
    echo "  Support: $support"
    echo "  Java: ≥ $java_min"
    echo "  Latest build: ${latest_build} (total builds: ${builds_count})"

    # Recent builds
    if [[ "${BUILDS_SHOWN}" -ne 0 ]]; then
      local builds_line extra
      if [[ "${BUILDS_SHOWN}" -lt 0 ]]; then
        # all builds (sorted numeric desc)
        builds_line="$(jq -r '.builds | sort | reverse | .[]' <<<"$item" | join_lines ', ')"
        echo "  Builds: $builds_line"
      else
        builds_line="$(jq -r ".builds | sort | reverse | .[] | tostring" <<<"$item" | head -n "$BUILDS_SHOWN" | join_lines ', ')"
        extra=$(( builds_count - BUILDS_SHOWN ))
        if (( extra > 0 )); then
          echo "  Builds: $builds_line … (+$extra more)"
        else
          echo "  Builds: $builds_line"
        fi
      fi
    fi

    # Recommended flags (one per line)
    local flags_count
    flags_count="$(jq -r '.flags | length' <<<"$item")"
    if (( flags_count > 0 )); then
      echo "  Recommended flags:"
      jq -r '.flags[]' <<<"$item" | sed 's/^/    /'
    else
      echo "  Recommended flags: (none)"
    fi
    echo
  done <<< "$ids_desc"

  # Summary for latest version
  local latest_id latest_item latest_support latest_java latest_build flags_line
  latest_id="$(printf "%s\n" "$ids_desc" | head -n1)"
  latest_item="$(printf "%s" "$norm" | jq -c --arg id "$latest_id" 'map(select(.id==$id))[0]')"
  latest_support="$(jq -r '.support // "UNKNOWN"' <<<"$latest_item")"
  latest_java="$(jq -r '.java_min // "?"' <<<"$latest_item")"
  latest_build="$(jq -r '.latest_build // "?"' <<<"$latest_item")"
  flags_line="$(jq -r '.flags[]?' <<<"$latest_item" | join_lines ' ')"

  echo "Summary:"
  echo "  Latest version: $latest_id"
  echo "  Support status: $latest_support"
  echo "  Latest build:   $latest_build"
  echo "  Min Java:       $latest_java"
  if [[ -n "$flags_line" ]]; then
    echo "  Recommended flags:"
    # wrapped for easy copy-paste
    echo "    $flags_line"
  else
    echo "  Recommended flags: (none)"
  fi
  echo

  # Cache & diff
  local prev_json prev_norm ids_prev_asc ids_curr_asc added removed support_changes
  prev_json="$(load_cache || true)"
  save_cache "$fresh_json"

  if [[ -n "$prev_json" ]] && is_valid_json "$prev_json"; then
    prev_norm="$(printf "%s" "$prev_json" | normalize_versions)"

    ids_prev_asc="$(printf "%s" "$prev_norm" | jq -r '.[].id' | semver_sort_asc)"
    ids_curr_asc="$(printf "%s" "$norm"      | jq -r '.[].id' | semver_sort_asc)"

    added="$(comm -13 <(printf "%s\n" "$ids_prev_asc") <(printf "%s\n" "$ids_curr_asc") || true)"
    removed="$(comm -23 <(printf "%s\n" "$ids_prev_asc") <(printf "%s\n" "$ids_curr_asc") || true)"

    # Support status changes
    support_changes="$(
      jq -n \
        --argjson prev "$prev_norm" \
        --argjson curr "$norm" '
          ( $prev | map({id, support}) | INDEX(.id) ) as $P
          | [ $curr[]
              | select( ($P[.id]) and (.support != $P[.id].support) )
              | {id, from: $P[.id].support, to: .support}
            ]'
    )"

    echo "Changes since last cache:"
    if [[ -z "$added$removed" && "$(jq 'length' <<<"$support_changes")" -eq 0 ]]; then
      echo "  No version or support-status changes."
    else
      [[ -n "$added" ]]   && { echo "  New versions:";      printf '    + %s\n' $added; }
      [[ -n "$removed" ]] && { echo "  Removed versions:";  printf '    - %s\n' $removed; }
      if [[ "$(jq 'length' <<<"$support_changes")" -gt 0 ]]; then
        echo "  Support status changes:"
        jq -r '.[] | "    * \(.id): \(.from) -> \(.to)"' <<<"$support_changes"
      fi
    fi
  else
    echo "No previous valid cache found. Created/updated cache at: $CACHE_FILE"
  fi
}

main "$@"
