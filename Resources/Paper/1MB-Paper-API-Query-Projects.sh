#!/usr/bin/env bash

# 1MB-Paper-API-Query-Projects.sh version 0.1.0, build 003, discord.gg/floris by @mrfloris for 1MoreBlock.com - August 31st, 2025
# Description: Helper script that queries the Paper v3 API endpoint to discover which /projects/ there are
# Installation: chmod +x 1MB-Paper-API-Query-Projects.sh (once), then (each time) run with: ./1MB-Paper-API-Query-Projects.sh
# TODO: oh so much..

set -euo pipefail

# -------------------------
# Config (edit these)
# -------------------------
CACHE_FILE=".paper-projects-cache.json"           # File to store the cache
DEFAULT_PROJECT="paper"                          # Project (usually 'paper')
DEFAULT_VERSION="1.21.8"                         # Desired Minecraft version (unused here)
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"           # PaperMC v3 API endpoint
TIMEOUT_SECS=15
# -------------------------

HAS_EXPECTED_PROJECT="false"

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
    curl -fLsS -A "$USER_AGENT" \
      -H 'accept: application/json' \
      --max-time "$TIMEOUT_SECS" \
      "$url"
  else
    wget -qO- \
      --user-agent="$USER_AGENT" \
      --header='accept: application/json' \
      --timeout="$TIMEOUT_SECS" \
      "$url"
  fi
}

USE_JQ="false"
if have jq; then USE_JQ="true"; fi

# semver-aware sort (desc): prefer gsort -V (Homebrew coreutils); else try BSD sort -V; else no-op
semver_sort_desc() {
  if have gsort; then
    gsort -Vr
  elif sort -V </dev/null >/dev/null 2>&1; then
    sort -Vr
  else
    cat
  fi
}

# Normalize to the inner array under .projects
normalize_to_array() {
  if [[ "$USE_JQ" == "true" ]]; then
    jq 'if type=="object" and has("projects") then .projects else . end'
  else
    # best-effort fallback; install jq for reliability
    awk '1' | sed -n '1h;1!H;${;g;s/^[\s\S]*"projects"[[:space:]]*:[[:space:]]*\[//;s/\][^]]*$//;p;}'
  fi
}

# Get project IDs as a sorted, unique list (expects normalized array on stdin)
json_to_id_list() {
  if [[ "$USE_JQ" == "true" ]]; then
    jq -r '.[].project.id' | LC_ALL=C sort -u
  else
    grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' | sed -E 's/.*:"([^"]+)".*/\1/' | LC_ALL=C sort -u
  fi
}

save_cache() { printf "%s\n" "$1" > "$CACHE_FILE"; }
load_cache_json() { [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }

print_human_readable() {
  local normalized="$1"

  if [[ "$USE_JQ" == "true" ]]; then
    # Clean comma+space list in a single jq pass (fixes earlier parse error)
    local ids
    ids="$(printf "%s" "$normalized" | jq -r '[.[].project.id] | unique | join(", ")')"
    echo "Found projects: $ids"
    echo

    # One header per project, versions semver-sorted (desc)
    while IFS= read -r item; do
      name="$(jq -r '.project.name' <<<"$item")"
      jq -r '.versions | to_entries | .[].value[]' <<<"$item" \
        | semver_sort_desc \
        | sed 's/^/  /' \
        | { echo "${name} versions:"; cat; echo; }
    done < <(printf "%s" "$normalized" | jq -c '.[]')
  else
    echo "Found projects (install 'jq' for nicer output):"
    printf "  - %s\n" $(printf "%s" "$normalized" | grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' | sed -E 's/.*:"([^"]+)".*/\1/')
    echo
  fi
}

main() {
  local url="$API_BASE/projects"

  local fresh_json
  if ! fresh_json="$(http_get "$url")"; then
    echo "Error: failed to fetch $url" >&2
    exit 1
  fi

  echo "== PaperMC Projects (from $API_BASE) =="
  echo "User-Agent: $USER_AGENT"
  echo

  local normalized
  if [[ "$USE_JQ" == "true" ]]; then
    normalized="$(printf "%s" "$fresh_json" | normalize_to_array)"
  else
    inner="$(printf "%s" "$fresh_json" | normalize_to_array || true)"
    normalized="$([[ -n "$inner" ]] && printf "[%s]" "$inner" || printf "%s" "$fresh_json")"
  fi

  local current_ids
  if ! current_ids="$(printf "%s" "$normalized" | json_to_id_list)"; then
    echo "Error: failed to parse project IDs." >&2
    exit 2
  fi

  if printf "%s\n" "$current_ids" | grep -Fxq "$DEFAULT_PROJECT"; then
    HAS_EXPECTED_PROJECT="true"
  else
    HAS_EXPECTED_PROJECT="false"
  fi

  local count
  count="$(printf "%s\n" "$current_ids" | grep -c . || true)"
  printf "Total projects: %s\n" "$count"
  printf "Expected project '%s': %s\n" "$DEFAULT_PROJECT" "$HAS_EXPECTED_PROJECT"
  echo

  print_human_readable "$normalized"

  local prev_json prev_norm prev_ids added removed
  prev_json="$(load_cache_json || true)"
  save_cache "$fresh_json"

  if [[ -n "$prev_json" ]]; then
    if [[ "$USE_JQ" == "true" ]]; then
      prev_norm="$(printf "%s" "$prev_json" | normalize_to_array)"
    else
      inner="$(printf "%s" "$prev_json" | normalize_to_array || true)"
      prev_norm="$([[ -n "$inner" ]] && printf "[%s]" "$inner" || printf "%s" "$prev_json")"
    fi

    prev_ids="$(printf "%s" "$prev_norm" | json_to_id_list || true)"

    added="$(comm -13 <(printf "%s\n" "$prev_ids") <(printf "%s\n" "$current_ids") || true)"
    removed="$(comm -23 <(printf "%s\n" "$prev_ids") <(printf "%s\n" "$current_ids") || true)"

    echo "Changes since last cache:"
    if [[ -z "$added" && -z "$removed" ]]; then
      echo "  No changes."
    else
      [[ -n "$added" ]] && { echo "  New:"; printf '    + %s\n' $added; }
      [[ -n "$removed" ]] && { echo "  Removed:"; printf '    - %s\n' $removed; }
    fi
  else
    echo "No previous cache found. Created new cache at: $CACHE_FILE"
  fi

  export HAS_EXPECTED_PROJECT
}

main "$@"
