#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-LatestBuild.sh  v0.1.0 (build 001)
# Query PaperMC Fill v3 API for the *latest* build of a version.
# - Uses the /builds/latest endpoint for the given version.
# - Shows ALL commits by default.
# - Prints primary artifact details (server:default): name, size, sha256, url.
# - Falls back to the first available artifact if server:default is missing.
# - Can optionally show response headers (-headers).
# - For baseline/compare, optionally fetches the builds listing filtered by -channel
#   (default STABLE) to compute "channel latest" and list builds newer than cache.
# - Caches the response in .paper-latestbuild-cache.json for change detection.
#
# Cache file: .paper-latestbuild-cache.json
#
# examples:
#   ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8
#   ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8 -headers
#   ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8 -c ALPHA
#

set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Config (edit defaults)
# -------------------------
CACHE_FILE=".paper-latestbuild-cache.json"
API_BASE="https://fill.papermc.io/v3"
USER_AGENT="1MB-paper-scripts/0.1 (+https://github.com/mrfdev/1MB)"
TIMEOUT_SECS=20

DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.8"
DEFAULT_CHANNEL="STABLE"  # used for baseline comparisons via the builds listing

# Presentation:
COMMITS_SHOWN_DEFAULT=-1  # -1 = ALL commits by default
DOWNLOAD_IF_NEW=false # true/false, automatically downloads the .jar file if we determined there's a newer jar
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
  local url="$1"
  if [[ "$HTTP_CLIENT" == "curl" ]]; then
    if curl -fsSI -A "$USER_AGENT" --max-time "$TIMEOUT_SECS" "$url" 2>/dev/null; then
      return 0
    else
      curl -fLsS -A "$USER_AGENT" --max-time "$TIMEOUT_SECS" -D - -o /dev/null "$url"
    fi
  else
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
Usage: 1MB-Paper-API-Query-LatestBuild.sh [options]

Fetch and print the latest Paper build for a version.

Options:
  -project:VALUE        Set project (default: paper)
  -project VALUE
  --project=VALUE
  -p VALUE

  -version:VALUE        Set version (e.g. 1.21.8)
  -version VALUE
  --version=VALUE
  -v VALUE

  -channel:VALUE        Baseline channel for comparisons (STABLE|ALPHA|BETA|SNAPSHOT|ALL)
                        (only used to compute "channel latest" via the builds listing)
  --channel=VALUE
  -c VALUE

  -commits:N            Number of commits to show (default: -1 = ALL)
                        (0 hides; -1 = ALL; N = first N)
  --commits=N
  -m N

  -headers              Print response headers for the latest request
  --headers

  -h, --help            Show this help

Examples:
  ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8
  ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8 -c stable -headers
EOF
}

# -------------------------
# CLI parsing
# -------------------------
PROJECT="$DEFAULT_PROJECT"
VERSION="$DEFAULT_VERSION"
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

if ! have jq; then
  echo "Error: 'jq' is required. Please install jq and retry." >&2
  exit 2
fi

CHANNEL_UP="$(tr '[:lower:]' '[:upper:]' <<< "${CHANNEL:-}")"
[[ "$CHANNEL_UP" == "ALL" ]] && CHANNEL_UP=""

LATEST_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds/latest"

# Fetch the latest build JSON (object)
JSON="$(http_get "$LATEST_URL")" || { echo "Error: failed to fetch $LATEST_URL" >&2; exit 1; }
is_valid_json "$JSON" || { echo "Error: API returned invalid JSON." >&2; exit 1; }
if [[ "$(jq -r 'type' <<<"$JSON")" != "object" ]]; then
  echo "Error: unexpected response (expected object for /builds/latest)." >&2
  exit 1
fi

# Optionally show headers
if [[ "$SHOW_HEADERS" == "1" ]]; then
  echo "== Response Headers =="
  RAW_HEADERS="$(http_head "$LATEST_URL" || true)"
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
| "== PaperMC Latest Build ==\n"
  + "  Project: '"$PROJECT"'\n"
  + "  Version: '"$VERSION"'\n"
  + "  Build: \($b.id)\n"
  + "  Channel: \($b.channel // "unknown")\n"
  + "  Time: \($b.time // "unknown")\n"
  + "  Endpoint: '"$LATEST_URL"'\n"
  + "\n"
  + "Primary artifact:\n"
  + "  name: \($d.name // "unknown")\n"
  + "  size: \($size) bytes (\($mb2) MB)\n"
  + "  sha256: \($d.checksums.sha256 // "unknown")\n"
  + "  url: \($d.url // "unknown")\n"
'
echo -e "$(jq -r "$JQ_PROG" <<<"$JSON")"

# Other downloads (if any)
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

# Commits (ALL by default)
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
# Cache & Baseline Comparison
# -------------------------

# For baseline we may fetch the builds listing (optionally filtered by channel)
BASE_LIST_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds"
LIST_URL="$BASE_LIST_URL"
if [[ -n "$CHANNEL_UP" ]]; then
  LIST_URL="$BASE_LIST_URL?channel=$CHANNEL_UP"
fi

LIST_JSON="$(http_get "$LIST_URL")" || { echo "Error: failed to fetch $LIST_URL" >&2; exit 1; }
is_valid_json "$LIST_JSON" || { echo "Error: invalid JSON from $LIST_URL" >&2; exit 1; }

CHANNEL_LATEST_ID="$(jq -r 'if type=="array" and length>0 then (map(.id)|max) else empty end' <<<"$LIST_JSON")"
ENDPOINT_LATEST_ID="$(jq -r '.id' <<<"$JSON")"
ENDPOINT_LATEST_CHANNEL="$(jq -r '.channel // "unknown"' <<<"$JSON")"

echo "== Cache & Baseline Comparison =="
if [[ -n "$CHANNEL_UP" ]]; then
  echo "  Baseline channel: ${CHANNEL_UP}"
else
  echo "  Baseline channel: (ALL)"
fi
echo "  Endpoint latest id: ${ENDPOINT_LATEST_ID:-unknown} (channel: ${ENDPOINT_LATEST_CHANNEL})"
echo "  Channel latest id: ${CHANNEL_LATEST_ID:-unknown}"

# Load previous cache BEFORE overwriting
load_cache() { [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }
PREV="$(load_cache || true)"

CACHED_BUILD=""
CACHED_VERSION=""
CACHED_PROJECT=""
if [[ -n "$PREV" ]] && is_valid_json "$PREV"; then
  CACHED_BUILD="$(jq -r '._meta.build // empty' <<<"$PREV" 2>/dev/null || true)"
  CACHED_VERSION="$(jq -r '._meta.version // empty' <<<"$PREV" 2>/dev/null || true)"
  CACHED_PROJECT="$(jq -r '._meta.project // empty' <<<"$PREV" 2>/dev/null || true)"
fi

if [[ -n "$CACHED_BUILD" ]]; then
  echo "  Cached latest: $CACHED_BUILD (project=$CACHED_PROJECT, version=$CACHED_VERSION)"
else
  echo "  Cached latest: (none)"
fi

is_int() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

# Newer build since cache? (baseline channel latest vs cached)
if is_int "$CHANNEL_LATEST_ID" && is_int "$CACHED_BUILD"; then
  if (( CHANNEL_LATEST_ID > CACHED_BUILD )); then
    echo "  Newer build since cache? Yes (channel latest: $CHANNEL_LATEST_ID — cached: $CACHED_BUILD)"
    NEWERS="$(jq -r --argjson than "${CACHED_BUILD:-0}" '[ .[] | select(.id > $than) | .id ] | sort | join(", ")' <<<"$LIST_JSON")"
    [[ -n "$NEWERS" ]] && echo "  Builds newer than cache: $NEWERS"
  else
    echo "  Newer build since cache? No (channel latest: $CHANNEL_LATEST_ID — cached: $CACHED_BUILD)"
  fi
fi

# Endpoint vs baseline note (only if they differ)
if is_int "$CHANNEL_LATEST_ID" && is_int "$ENDPOINT_LATEST_ID" && (( ENDPOINT_LATEST_ID != CHANNEL_LATEST_ID )); then
  echo "  Note: endpoint latest ($ENDPOINT_LATEST_ID, ${ENDPOINT_LATEST_CHANNEL}) differs from baseline by channel ($CHANNEL_LATEST_ID)."
fi

# Simple recommendation
if is_int "$CHANNEL_LATEST_ID"; then
  if ! is_int "$CACHED_BUILD"; then
    echo "  Should download? Yes — no cache yet; baseline latest is $CHANNEL_LATEST_ID."
  elif (( CHANNEL_LATEST_ID > CACHED_BUILD )); then
    echo "  Should download? Yes — newer than cache ($CHANNEL_LATEST_ID > $CACHED_BUILD)."
  else
    echo "  Should download? No — nothing newer than cached."
  fi
else
  # Fall back to endpoint id if channel latest is unknown
  if is_int "$ENDPOINT_LATEST_ID"; then
    if ! is_int "$CACHED_BUILD" || (( ENDPOINT_LATEST_ID > CACHED_BUILD )); then
      echo "  Should download? Yes — endpoint latest is newer than cache or no cache."
    else
      echo "  Should download? No — endpoint latest not newer than cache."
    fi
  else
    echo "  Should download? (n/a) — unable to determine latest id."
  fi
fi

echo

# -------------------------
# Cache: remember this payload and detect changes
# -------------------------
save_cache() {
  local payload="$1"
  local sorted
  sorted="$(jq -S . <<<"$payload")"
  local ts; ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  jq -c --arg p "$PROJECT" --arg v "$VERSION" --arg b "$(jq -r '.id' <<<"$payload")" --arg ts "$ts" '
    { _meta: {project:$p, version:$v, build:$b, fetched_at:$ts},
      build: .,
      _sorted: ( . | tojson ) }
  ' <<<"$sorted" > "$CACHE_FILE"
}

if [[ -n "$PREV" ]] && is_valid_json "$PREV"; then
  SAME_TARGET="$(jq -r --arg p "$PROJECT" --arg v "$VERSION" '
    (._meta.project == $p) and (._meta.version == $v)
  ' <<<"$PREV" || echo "false")"

  if [[ "$SAME_TARGET" == "true" ]]; then
    PREV_SORTED="$(jq -r '._sorted' <<<"$PREV" 2>/dev/null || true)"
    CURR_SORTED="$(jq -S . <<<"$JSON" | jq -r 'tojson')"
    if [[ -n "$PREV_SORTED" && "$PREV_SORTED" == "$CURR_SORTED" ]]; then
      echo "Summary: (cache) Latest build unchanged since last fetch."
    else
      echo "Summary: Latest build changed since last cache (updating cache)."
    fi
  else
    echo "Summary: Cache belongs to different project/version (overwriting)."
  fi
else
  echo "Summary: No previous cache (creating one)."
fi

save_cache "$JSON"
echo "Cache updated: $CACHE_FILE"
