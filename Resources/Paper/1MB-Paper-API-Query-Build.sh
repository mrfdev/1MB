#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-Build.sh  v0.2.1 (build 010)
# Query PaperMC Fill v3 API for a single build of a version (e.g. build 56 of 1.21.8).
# - Shows ALL commits by default.
# - Prints primary artifact details (server:default): name, size, sha256, url.
# - Falls back to the first available artifact if server:default is missing.
# - Can optionally show response headers (-headers).
# - Supports resolving "latest" build number via the builds listing (with optional -channel).
# - Caches the response in .paper-build-cache.json for basic change detection.
#
# Cache file: .paper-build-cache.json
#
# exact build
# ./1MB-Paper-API-Query-Build.sh -v 1.21.8 -b 56
#
# latest STABLE for that version
# ./1MB-Paper-API-Query-Build.sh -v 1.21.8 -b latest
#
# latest ALPHA and show headers
# ./1MB-Paper-API-Query-Build.sh -v 1.21.8 -b latest -c ALPHA -headers

set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Config (edit defaults)
# -------------------------
CACHE_FILE=".paper-build-cache.json"
API_BASE="https://fill.papermc.io/v3"
USER_AGENT="1MB-paper-scripts/0.1 (+https://github.com/mrfdev/1MB)"
TIMEOUT_SECS=20

DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.8"
DEFAULT_BUILD="53"          # leave empty to force CLI; or set to a number. Supports "latest"
DEFAULT_CHANNEL="STABLE"  # only used when resolving latest via builds endpoint

# Presentation:
COMMITS_SHOWN_DEFAULT=-1  # -1 = ALL commits by default for single build
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

http_head() {
  # Prefer HEAD, fall back to GET with headers if HEAD not supported.
  local url="$1"
  if [[ "$HTTP_CLIENT" == "curl" ]]; then
    if curl -fsSI -A "$USER_AGENT" --max-time "$TIMEOUT_SECS" "$url" 2>/dev/null; then
      return 0
    else
      curl -fLsS -A "$USER_AGENT" --max-time "$TIMEOUT_SECS" -D - -o /dev/null "$url"
    fi
  else
    # wget HEAD
    if wget -qS --spider --user-agent="$USER_AGENT" --timeout="$TIMEOUT_SECS" "$url" 2>&1; then
      return 0
    else
      wget -qS -O /dev/null --user-agent="$USER_AGENT" --timeout="$TIMEOUT_SECS" "$url" 2>&1
    fi
  fi
}

is_valid_json() { [[ -n "${1:-}" ]] && jq -e . >/dev/null 2>&1 <<<"$1"; }

print_help() {
  cat <<'EOF'
Usage: 1MB-Paper-API-Query-Build.sh [options]

Target a single build of a Paper version and print detailed info.

Options (multiple forms supported):
  -project:VALUE        Set project (default: paper)
  -project VALUE
  --project=VALUE
  -p VALUE

  -version:VALUE        Set version (e.g. 1.21.8)
  -version VALUE
  --version=VALUE
  -v VALUE

  -build:N              Set build number (e.g. 56), or "latest" to auto-resolve
  --build=N|latest
  -b N|latest

  -channel:VALUE        Channel used to resolve "latest" (STABLE|ALPHA|BETA|SNAPSHOT|ALL)
  --channel=VALUE
  -c VALUE

  -commits:N            Number of commits to show (default: -1 = ALL)
                        (0 hides; -1 = ALL; N = first N)
  --commits=N
  -m N

  -headers              Print response headers for the build request
  --headers

  -h, --help            Show this help

Examples:
  ./1MB-Paper-API-Query-Build.sh -v 1.21.8 -b 56
  ./1MB-Paper-API-Query-Build.sh -v 1.21.8 -b latest -c stable
  ./1MB-Paper-API-Query-Build.sh -v 1.21.8 -b 56 -headers
EOF
}

# -------------------------
# CLI parsing
# -------------------------
PROJECT="$DEFAULT_PROJECT"
VERSION="$DEFAULT_VERSION"
BUILD="$DEFAULT_BUILD"
CHANNEL="$DEFAULT_CHANNEL"
COMMITS_SHOWN="$COMMITS_SHOWN_DEFAULT"
SHOW_HEADERS="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) print_help; exit 0 ;;
    -project:*) PROJECT="${1#*:}"; shift ;;
    --project=*) PROJECT="${1#*=}"; shift ;;
    -project|-p) PROJECT="${2:-}"; shift 2 ;;
    project=* ) PROJECT="${1#*=}"; shift ;;

    -version:*) VERSION="${1#*:}"; shift ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    -version|-v) VERSION="${2:-}"; shift 2 ;;
    version=* ) VERSION="${1#*=}"; shift ;;

    -build:*) BUILD="${1#*:}"; shift ;;
    --build=*) BUILD="${1#*=}"; shift ;;
    -build|-b) BUILD="${2:-}"; shift 2 ;;

    -channel:*) CHANNEL="${1#*:}"; shift ;;
    --channel=*) CHANNEL="${1#*=}"; shift ;;
    -channel|-c) CHANNEL="${2:-}"; shift 2 ;;

    -commits:*) COMMITS_SHOWN="${1#*:}"; shift ;;
    --commits=*) COMMITS_SHOWN="${1#*=}"; shift ;;
    -commits|-m) COMMITS_SHOWN="${2:-}"; shift 2 ;;

    -headers|--headers) SHOW_HEADERS="1"; shift ;;

    *) echo "Unknown option: $1" >&2; print_help; exit 64 ;;
  esac
done

# Keep the raw value the user asked for (so we can compare "latest vs requested")
REQUESTED_BUILD_RAW="$BUILD"

# Normalize channel (for latest resolution / comparisons)
CHANNEL_UP="$(tr '[:lower:]' '[:upper:]' <<< "${CHANNEL:-}")"
[[ "$CHANNEL_UP" == "ALL" ]] && CHANNEL_UP=""

if ! have jq; then
  echo "Error: 'jq' is required. Please install jq and retry." >&2
  exit 2
fi

if [[ -z "${BUILD:-}" ]]; then
  echo "Error: -build is required (number or 'latest')." >&2
  exit 64
fi

# If build == latest, resolve via builds listing (optionally filtering by channel).
LIST_JSON_FOR_COMPARE=""
LATEST_FOR_COMPARE=""
if [[ "$BUILD" == "latest" || "$BUILD" == "LATEST" ]]; then
  BASE_LIST_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds"
  LIST_URL="$BASE_LIST_URL"
  if [[ -n "$CHANNEL_UP" ]]; then
    LIST_URL="$BASE_LIST_URL?channel=$CHANNEL_UP"
  fi
  LIST_JSON="$(http_get "$LIST_URL")" || { echo "Error: failed to fetch $LIST_URL" >&2; exit 1; }
  is_valid_json "$LIST_JSON" || { echo "Error: invalid JSON from $LIST_URL" >&2; exit 1; }
  if [[ "$(jq -r 'type' <<<"$LIST_JSON")" != "array" ]]; then
    echo "Error: unexpected response resolving 'latest' (expected array)." >&2
    exit 1
  fi
  LATEST_ID="$(jq -r 'map(.id) | max? // empty' <<<"$LIST_JSON")"
  if [[ -z "$LATEST_ID" ]]; then
    echo "Error: could not resolve latest build id." >&2
    exit 1
  fi
  BUILD="$LATEST_ID"
  # keep for later comparisons so we don't refetch
  LIST_JSON_FOR_COMPARE="$LIST_JSON"
  LATEST_FOR_COMPARE="$LATEST_ID"
fi

BUILD_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds/$BUILD"

# Fetch the build JSON
JSON="$(http_get "$BUILD_URL")" || { echo "Error: failed to fetch $BUILD_URL" >&2; exit 1; }
is_valid_json "$JSON" || { echo "Error: API returned invalid JSON." >&2; exit 1; }
if [[ "$(jq -r 'type' <<<"$JSON")" != "object" ]]; then
  echo "Error: unexpected response (expected object for single build endpoint)." >&2
  exit 1
fi

# Optionally grab headers (best-effort)
if [[ "$SHOW_HEADERS" == "1" ]]; then
  echo "== Response Headers =="
  RAW_HEADERS="$(http_head "$BUILD_URL" || true)"
  while IFS= read -r line; do
    case "$line" in
      *$'\r') line="${line%$'\r'}" ;;
    esac
    if [[ "$line" =~ ^(HTTP/|date:|Date:|age:|Age:|cache-control:|Cache-Control:|etag:|ETag:|cf-cache-status:|CF-Cache-Status:|content-type:|Content-Type:|strict-transport-security:|Strict-Transport-Security:|x-content-type-options:|X-Content-Type-Options:|x-frame-options:|X-Frame-Options:|x-xss-protection:|X-XSS-Protection:|server:|Server:|vary:|Vary:) ]]; then
      echo "  $line"
    fi
  done <<< "$RAW_HEADERS"
  echo
fi

# -------------------------
# Pretty print
# -------------------------
JQ_PROG='
def primary_download:
  (.downloads["server:default"] //
   ( .downloads | to_entries | sort_by(.key) | (.[0].value // {})));

. as $b
| (primary_download) as $d
| ($d.size // 0) as $size
| ($size / 1048576) as $mb
| ($mb*100 | floor / 100) as $mb2
| "== PaperMC Build ==\n"
  + "  Project: '"$PROJECT"'\n"
  + "  Version: '"$VERSION"'\n"
  + "  Build: \($b.id)\n"
  + "  Channel: \($b.channel // "unknown")\n"
  + "  Time: \($b.time // "unknown")\n"
  + "  Endpoint: '"$BUILD_URL"'\n"
  + "\n"
  + "Primary artifact:\n"
  + "  name: \($d.name // "unknown")\n"
  + "  size: \($size) bytes (\($mb2) MB)\n"
  + "  sha256: \($d.checksums.sha256 // "unknown")\n"
  + "  url: \($d.url // "unknown")\n"
'
echo -e "$(jq -r "$JQ_PROG" <<<"$JSON")"

# List other downloads (if any besides server:default)
OTHER_DL=$(jq -r '
  .downloads
  | to_entries
  | map(select(.key != "server:default"))
  | if length==0 then empty else . end
' <<<"$JSON" 2>/dev/null || true)

if [[ -n "$OTHER_DL" ]]; then
  echo "Other downloads:"
  jq -r '
    .downloads
    | to_entries
    | map(select(.key != "server:default"))
    | .[]
    | "  [" + .key + "] name: " + (.value.name // "unknown")
      + "\n    size: " + ((.value.size // 0) | tostring) + " bytes ("
      + (((.value.size // 0)/1048576) as $mb | (($mb*100|floor)/100 | tostring)) + " MB)"
      + "\n    sha256: " + (.value.checksums.sha256 // "unknown")
      + "\n    url: " + (.value.url // "unknown")
  ' <<<"$JSON"
  echo
fi

# Commits (show ALL by default; COMMITS_SHOWN can override via CLI)
if [[ "$(jq '(.commits|length) > 0' <<<"$JSON")" == "true" ]] && [[ "$COMMITS_SHOWN" != "0" ]]; then
  echo "Commits:"
  if [[ "$COMMITS_SHOWN" == "-1" ]]; then
    jq -r '
      .commits
      | .[]
      | "- " + ((.message // "commit") | split("\n")[0])
        + " (" + ((.sha // "")[0:7]) + ") @ " + (.time // "unknown")
    ' <<<"$JSON"
  else
    jq -r --argjson n "$COMMITS_SHOWN" '
      .commits
      | .[0:$n]
      | .[]
      | "- " + ((.message // "commit") | split("\n")[0])
        + " (" + ((.sha // "")[0:7]) + ") @ " + (.time // "unknown")
    ' <<<"$JSON"
  fi
  echo
fi

# -------------------------
# Latest & Cache comparisons
# -------------------------

# Get the builds list once for comparisons (reuse if we already fetched above)
if [[ -n "${LIST_JSON_FOR_COMPARE}" ]]; then
  LIST_JSON="$LIST_JSON_FOR_COMPARE"
  LATEST_ID="${LATEST_FOR_COMPARE}"
else
  BASE_LIST_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds"
  LIST_URL="$BASE_LIST_URL"
  if [[ -n "$CHANNEL_UP" ]]; then
    LIST_URL="$BASE_LIST_URL?channel=$CHANNEL_UP"
  fi
  LIST_JSON="$(http_get "$LIST_URL")" || { echo "Error: failed to fetch $LIST_URL" >&2; exit 1; }
  is_valid_json "$LIST_JSON" || { echo "Error: invalid JSON from $LIST_URL" >&2; exit 1; }
  LATEST_ID="$(jq -r 'if type=="array" and length>0 then (map(.id)|max) else empty end' <<<"$LIST_JSON")"
fi

echo "== Latest & Cache Comparison =="
if [[ -n "$CHANNEL_UP" ]]; then
  echo "  Channel filter for latest: $CHANNEL_UP"
else
  echo "  Channel filter for latest: (ALL)"
fi
echo "  Latest build id: ${LATEST_ID:-unknown}"

# Helper to test integers safely
is_int() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

# Load previous cache BEFORE overwriting it
load_cache() { [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }
PREV="$(load_cache || true)"

CACHED_PROJECT=""; CACHED_VERSION=""; CACHED_BUILD=""
if [[ -n "$PREV" ]] && is_valid_json "$PREV"; then
  CACHED_PROJECT="$(jq -r '._meta.project // empty' <<<"$PREV" 2>/dev/null || true)"
  CACHED_VERSION="$(jq -r '._meta.version // empty' <<<"$PREV" 2>/dev/null || true)"
  CACHED_BUILD="$(jq -r '._meta.build // empty' <<<"$PREV" 2>/dev/null || true)"
fi

if [[ -n "$CACHED_BUILD" ]]; then
  echo "  Cached build: $CACHED_BUILD (project=$CACHED_PROJECT, version=$CACHED_VERSION)"
else
  echo "  Cached build: (none)"
fi

# Newer build since cache? (latest vs cached)
if is_int "$LATEST_ID" && is_int "$CACHED_BUILD"; then
  if (( LATEST_ID > CACHED_BUILD )); then
    echo "  Newer build since cache? Yes (latest: $LATEST_ID — cached: $CACHED_BUILD)"
    # list the exact ids newer than cache
    NEWERS="$(jq -r --argjson than "${CACHED_BUILD:-0}" '[ .[] | select(.id > $than) | .id ] | sort | join(", ")' <<<"$LIST_JSON")"
    [[ -n "$NEWERS" ]] && echo "  Builds newer than cache: $NEWERS"
  else
    echo "  Newer build since cache? No (latest: $LATEST_ID — cached: $CACHED_BUILD)"
  fi
fi

# Newer than requested build? (latest vs what the user asked for)
if [[ "${REQUESTED_BUILD_RAW,,}" != "latest" ]] && is_int "$REQUESTED_BUILD_RAW" && is_int "$LATEST_ID"; then
  if (( LATEST_ID > REQUESTED_BUILD_RAW )); then
    echo "  Newer than requested build? Yes (latest: $LATEST_ID — requested: $REQUESTED_BUILD_RAW)"
  else
    echo "  Newer than requested build? No (latest: $LATEST_ID — requested: $REQUESTED_BUILD_RAW)"
  fi
fi

# Simple recommendation (handles no-cache + requested<latest properly)
if is_int "$LATEST_ID"; then
  if [[ "${REQUESTED_BUILD_RAW,,}" == "latest" ]]; then
    echo "  Should download? Yes — you requested latest ($LATEST_ID)."
  elif is_int "$REQUESTED_BUILD_RAW" && (( LATEST_ID > REQUESTED_BUILD_RAW )); then
    echo "  Should download? Yes — latest ($LATEST_ID) is newer than requested ($REQUESTED_BUILD_RAW)."
  elif is_int "$CACHED_BUILD" && (( LATEST_ID > CACHED_BUILD )); then
    echo "  Should download? Yes — newer build available ($LATEST_ID) than cached ($CACHED_BUILD)."
  elif is_int "$CACHED_BUILD" && is_int "$BUILD" && (( BUILD > CACHED_BUILD )); then
    echo "  Should download? Yes — requested build ($BUILD) is newer than cached ($CACHED_BUILD)."
  else
    # If no cache exists, fall back to comparing fetched vs latest
    if ! is_int "$CACHED_BUILD"; then
      if is_int "$BUILD" && (( LATEST_ID > BUILD )); then
        echo "  Should download? Yes — latest ($LATEST_ID) is newer than fetched build ($BUILD)."
      else
        echo "  Should download? No — nothing newer than requested/fetched."
      fi
    else
      echo "  Should download? No — nothing newer than cached."
    fi
  fi
else
  echo "  Should download? (n/a) — unable to determine latest id."
fi


echo

# -------------------------
# Cache: remember this build payload and detect changes
# -------------------------
save_cache() {
  local payload="$1"
  local sorted
  sorted="$(jq -S . <<<"$payload")"
  local ts; ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  jq -c --arg p "$PROJECT" --arg v "$VERSION" --arg b "$BUILD" --arg ts "$ts" '
    { _meta: {project:$p, version:$v, build:$b, fetched_at:$ts},
      build: .,
      _sorted: ( . | tojson ) }
  ' <<<"$sorted" > "$CACHE_FILE"
}

# Re-run the old “changed/unchanged/overwriting” summary (kept as-is)
if [[ -n "$PREV" ]] && is_valid_json "$PREV"; then
  SAME_TARGET="$(jq -r --arg p "$PROJECT" --arg v "$VERSION" --arg b "$BUILD" '
    (._meta.project == $p) and (._meta.version == $v) and (._meta.build == $b)
  ' <<<"$PREV" || echo "false")"

  if [[ "$SAME_TARGET" == "true" ]]; then
    PREV_SORTED="$(jq -r '._sorted' <<<"$PREV" 2>/dev/null || true)"
    CURR_SORTED="$(jq -S . <<<"$JSON" | jq -r 'tojson')"
    if [[ -n "$PREV_SORTED" && "$PREV_SORTED" == "$CURR_SORTED" ]]; then
      echo "Summary: (cache) Build unchanged since last fetch."
    else
      echo "Summary: Build changed since last cache (updating cache)."
    fi
  else
    echo "Summary: Cache belongs to different project/version/build (overwriting)."
  fi
else
  echo "Summary: No previous cache (creating one)."
fi

save_cache "$JSON"
echo "Cache updated: $CACHE_FILE"
