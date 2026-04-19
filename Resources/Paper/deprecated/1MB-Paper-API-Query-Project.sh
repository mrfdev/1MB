#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-Project.sh  v0.1.1 (build 004)
# Queries PaperMC Fill v3 API for a single project (paper)
# Cache: .paper-project-cache.json

set -euo pipefail

# -------------------------
# Config (edit these)
# -------------------------
CACHE_FILE=".paper-project-cache.json"
DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.10"
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"
TIMEOUT_SECS=15
MAJOR_FILTER=""
# -------------------------

have() { command -v "$1" >/dev/null 2>&1; }

HTTP_CLIENT=""
if have curl; then HTTP_CLIENT="curl"
elif have wget; then HTTP_CLIENT="wget"
else echo "Error: neither curl nor wget is available." >&2; exit 127; fi

http_get() {
  local url="$1"
  if [[ "$HTTP_CLIENT" == "curl" ]]; then
    curl -fLsS -A "$USER_AGENT" -H 'accept: application/json' --max-time "$TIMEOUT_SECS" "$url"
  else
    wget -qO- --user-agent="$USER_AGENT" --header='accept: application/json' --timeout="$TIMEOUT_SECS" "$url"
  fi
}

USE_JQ="false"; have jq && USE_JQ="true"

semver_sort_desc() {
  if have gsort; then gsort -Vr
  elif sort -V </dev/null >/dev/null 2>&1; then sort -Vr
  else cat
  fi
}

save_cache() { printf "%s\n" "$1" > "$CACHE_FILE"; }
load_cache()  { [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }
is_valid_json(){ [[ -n "${1:-}" ]] && jq -e . >/dev/null 2>&1 <<<"$1"; }

extract_majors() { jq -r '.versions | keys[]'; }
extract_releases_for_major() { local m="$1"; jq -r --arg m "$m" '.versions[$m][]'; }

# Return 0 iff a < b (strict); equal -> 1.
ver_lt() {
  local a="$1" b="$2"
  [[ "$a" == "$b" ]] && return 1
  printf "%s\n%s\n" "$a" "$b" | semver_sort_desc | tail -n1 | grep -qx "$a"
}

main() {
  local url="$API_BASE/projects/$DEFAULT_PROJECT"
  local fresh_json; fresh_json="$(http_get "$url")" || { echo "Error: fetch failed"; exit 1; }

  echo "== PaperMC Single Project (from $API_BASE) =="
  echo "User-Agent: $USER_AGENT"
  echo "Project: $DEFAULT_PROJECT"
  echo

  if [[ "$USE_JQ" != "true" ]]; then
    echo "Warning: 'jq' not found. Caching raw JSON."; save_cache "$fresh_json"; exit 0
  fi

  local majors; majors="$(printf "%s" "$fresh_json" | extract_majors | semver_sort_desc)"
  [[ -n "$MAJOR_FILTER" ]] && majors="$(printf "%s\n" "$majors" | grep -Fx "$MAJOR_FILTER" || true)"
  [[ -z "$majors" ]] && { echo "No majors found."; save_cache "$fresh_json"; exit 2; }

  local latest_major latest_of_latest_major
  latest_major="$(printf "%s\n" "$majors" | head -n1)"
  latest_of_latest_major="$(printf "%s" "$fresh_json" | extract_releases_for_major "$latest_major" | semver_sort_desc | head -n1)"

  while IFS= read -r major; do
    [[ -z "$major" ]] && continue
    echo "$major:"
    printf "%s" "$fresh_json" | extract_releases_for_major "$major" | semver_sort_desc | sed 's/^/  /'
    echo
  done <<< "$majors"

  echo "Summary:"
  echo "  Latest major: $latest_major"
  echo "  Latest $latest_major release: $latest_of_latest_major"

  if [[ -n "$DEFAULT_VERSION" ]]; then
    def_major="${DEFAULT_VERSION%.*}"
    if printf "%s\n" "$majors" | grep -Fxq "$def_major"; then
      def_latest="$(printf "%s" "$fresh_json" | extract_releases_for_major "$def_major" | semver_sort_desc | head -n1)"
      echo "  Your current: $DEFAULT_VERSION  (major $def_major)"
      if ver_lt "$DEFAULT_VERSION" "$def_latest"; then
        echo "  Newer patch in $def_major? Yes (latest: $def_latest — you have $DEFAULT_VERSION)"
      else
        if [[ "$DEFAULT_VERSION" == "$def_latest" ]]; then
          echo "  Newer patch in $def_major? No (latest: $def_latest — you have $DEFAULT_VERSION)"
        else
          echo "  Newer patch in $def_major? No (latest: $def_latest < your $DEFAULT_VERSION)"
        fi
      fi
      newer_major="No"; [[ "$def_major" != "$latest_major" ]] && newer_major="Yes"
      echo "  Newer major available? $newer_major (latest major: $latest_major)"
    else
      echo "  Your current: $DEFAULT_VERSION (unknown major: $def_major)"
      echo "  Newer major available? Yes (latest major: $latest_major)"
    fi
  fi
  echo

  local prev_json prev_majors added removed
  prev_json="$(load_cache || true)"
  save_cache "$fresh_json"

  if [[ -n "$prev_json" ]] && is_valid_json "$prev_json"; then
    prev_majors="$(printf "%s" "$prev_json" | extract_majors | semver_sort_desc || true)"
    added="$(comm -13 <(printf "%s\n" "$prev_majors") <(printf "%s\n" "$majors") || true)"
    removed="$(comm -23 <(printf "%s\n" "$prev_majors") <(printf "%s\n" "$majors") || true)"
    echo "Changes since last cache (majors):"
    if [[ -z "$added" && -z "$removed" ]]; then
      echo "  No major changes."
    else
      [[ -n "$added" ]] && { echo "  New majors:";   printf '    + %s\n' $added; }
      [[ -n "$removed" ]] && { echo "  Removed majors:"; printf '    - %s\n' $removed; }
    fi
  else
    echo "No previous valid cache found. Created/updated cache at: $CACHE_FILE"
  fi
}

main "$@"
