#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-LatestBuild.sh  v0.1.1 (build 004)
# Query PaperMC Fill v3 API for the *latest* build of a version.
# - Uses the /builds/latest endpoint for the given version.
# - Shows ALL commits by default.
# - Prints primary artifact details (server:default): name, size, sha256, url.
# - Falls back to the first available artifact if server:default is missing.
# - Optional response headers (-headers).
# - Baseline comparison using builds list (optionally filtered by -channel, default STABLE).
# - NEW: Download support with safe backup/rename and SHA-256 verification.
#
# Cache file: .paper-latestbuild-cache.json
#
# examples:
# Ask Y/n if newer:
# ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.10
# Auto-download if newer (no prompt):
# ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.10 -download

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
DEFAULT_VERSION="1.21.10"
DEFAULT_CHANNEL="STABLE"  # used for baseline comparisons via the builds listing

# Presentation:
COMMITS_SHOWN_DEFAULT=-1  # -1 = ALL commits by default

# Downloads:
DOWNLOAD_IF_NEW=false     # true/false: auto-download when a newer build is recommended. If false, ask Y/n.
DOWNLOAD_FORCE=false      # NEW: if true (+ -download), always download (bypass newer-check)

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

  -download             Auto-download if newer is recommended (overrides config DOWNLOAD_IF_NEW=false)
  -force                Enable force mode (bypass newer-check). Pair with -download to skip prompt.
  -forcedownload        Convenience flag: same as -force -download


  -h, --help            Show this help

Examples:
  ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8
  ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8 -c STABLE -download
  ./1MB-Paper-API-Query-LatestBuild.sh -v 1.21.8 -forcedownload
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
AUTO_DOWNLOAD="$DOWNLOAD_IF_NEW"
FORCE_DOWNLOAD="$DOWNLOAD_FORCE"


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

    -download|--download) AUTO_DOWNLOAD="true"; shift ;;

    -force|--force) FORCE_DOWNLOAD="true"; shift ;;
    -forcedownload|--forcedownload) FORCE_DOWNLOAD="true"; AUTO_DOWNLOAD="true"; shift ;;

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
    case "$line" in *$'\r') line="${line%$'\r'}";; esac
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

RECOMMEND_DL="unknown"
if is_int "$CHANNEL_LATEST_ID"; then
  if ! is_int "$CACHED_BUILD"; then
    echo "  Newer build since cache? Yes (channel latest: $CHANNEL_LATEST_ID — cached: none)"
    RECOMMEND_DL="yes"
  elif (( CHANNEL_LATEST_ID > CACHED_BUILD )); then
    echo "  Newer build since cache? Yes (channel latest: $CHANNEL_LATEST_ID — cached: $CACHED_BUILD)"
    RECOMMEND_DL="yes"
  else
    echo "  Newer build since cache? No (channel latest: $CHANNEL_LATEST_ID — cached: $CACHED_BUILD)"
    RECOMMEND_DL="no"
  fi
else
  # Fall back to endpoint id if channel latest is unknown
  if is_int "$ENDPOINT_LATEST_ID"; then
    if ! is_int "$CACHED_BUILD" || (( ENDPOINT_LATEST_ID > CACHED_BUILD )); then
      echo "  Newer build since cache? Yes (endpoint latest vs cache)"
      RECOMMEND_DL="yes"
    else
      echo "  Newer build since cache? No (endpoint latest vs cache)"
      RECOMMEND_DL="no"
    fi
  else
    echo "  Newer build since cache? (n/a) — unable to determine latest id."
    RECOMMEND_DL="no"
  fi
fi

if is_int "$CHANNEL_LATEST_ID" && is_int "$ENDPOINT_LATEST_ID" && (( ENDPOINT_LATEST_ID != CHANNEL_LATEST_ID )); then
  echo "  Note: endpoint latest ($ENDPOINT_LATEST_ID, ${ENDPOINT_LATEST_CHANNEL}) differs from baseline by channel ($CHANNEL_LATEST_ID)."
fi

if [[ "$RECOMMEND_DL" == "yes" ]]; then
  echo "  Should download? Yes — newer than cache or no cache."
else
  echo "  Should download? No — nothing newer than cached."
fi
echo

# -------------------------
# Download logic (backup -> download -> verify)
# -------------------------
artifact_name="$(jq -r '.downloads["server:default"].name // ( .downloads | to_entries | sort_by(.key) | (.[0].value.name // empty) )' <<<"$JSON")"
artifact_url="$(jq -r '.downloads["server:default"].url  // ( .downloads | to_entries | sort_by(.key) | (.[0].value.url  // empty) )' <<<"$JSON")"
artifact_sha="$(jq -r '.downloads["server:default"].checksums.sha256 // ( .downloads | to_entries | sort_by(.key) | (.[0].value.checksums.sha256 // empty) )' <<<"$JSON")"

do_sha256() {
  local file="$1"
  if have sha256sum; then
    sha256sum "$file" | awk '{print $1}'
  elif have shasum; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo ""
  fi
}

download_file() {
  local url="$1"
  local out="$2"
  if [[ "$HTTP_CLIENT" == "curl" ]]; then
    curl -fL --progress-bar -A "$USER_AGENT" --max-time "$TIMEOUT_SECS" -o "$out" "$url"
  else
    wget --user-agent="$USER_AGENT" --timeout="$TIMEOUT_SECS" -O "$out" "$url"
  fi
}

maybe_download() {
  local name="$1" url="$2" sha="$3"
  if [[ -z "$name" || -z "$url" ]]; then
    echo "Download: No artifact name or URL available; skipping." >&2
    return 1
  fi

  # Backup if existing
  if [[ -f "$name" ]]; then
    local backup="_$name"
    if [[ -f "$backup" ]]; then
      echo "Removing existing backup: $backup"
      rm -f -- "$backup"
    fi
    echo "Backing up existing file: $name -> $backup"
    mv -f -- "$name" "$backup"
  fi

  echo "Downloading: $name"
  download_file "$url" "$name"

  if [[ ! -f "$name" ]]; then
    echo "Download failed: $name not found after download." >&2
    return 2
  fi

  # Verify SHA-256 if provided & tool available
  if [[ -n "$sha" ]]; then
    local have_hasher="false"
    if have sha256sum || have shasum; then have_hasher="true"; fi
    if [[ "$have_hasher" == "true" ]]; then
      local calc
      calc="$(do_sha256 "$name" || true)"
      if [[ -n "$calc" ]]; then
        if [[ "${calc,,}" == "${sha,,}" ]]; then
          echo "Checksum OK: $calc"
        else
          echo "WARNING: Checksum mismatch!"
          echo "  expected: $sha"
          echo "  got:      $calc"
          echo "Backup (if any) kept as _${name}. Investigate before deploying this jar."
        fi
      else
        echo "Checksum: tool not available to verify on this system."
      fi
    else
      echo "Checksum: verification skipped (no sha256sum/shasum)."
    fi
  else
    echo "Checksum: no SHA-256 provided by API; skipped."
  fi
}

proceed_download="no"

if [[ "$FORCE_DOWNLOAD" == "true" ]]; then
  # Force mode bypasses the “newer than cache” check.
  if [[ "$AUTO_DOWNLOAD" == "true" ]]; then
    echo "Force download enabled: bypassing newer-check."
    proceed_download="yes"
  else
    # Ask Y/n (default Y) but clarify it's a forced download
    read -r -p "Force download (bypass newer-check)? [Y/n] " ans
    ans="${ans:-Y}"
    case "$ans" in
      Y|y) proceed_download="yes" ;;
      *)   proceed_download="no" ;;
    esac
  fi

elif [[ "$RECOMMEND_DL" == "yes" ]]; then
  if [[ "$AUTO_DOWNLOAD" == "true" ]]; then
    proceed_download="yes"
  else
    # Ask Y/n (default Y)
    read -r -p "Download newer build now? [Y/n] " ans
    ans="${ans:-Y}"
    case "$ans" in
      Y|y) proceed_download="yes" ;;
      *)   proceed_download="no" ;;
    esac
  fi
fi

if [[ "$proceed_download" == "yes" ]]; then
  maybe_download "$artifact_name" "$artifact_url" "$artifact_sha"
  echo
fi

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
