#!/usr/bin/env bash
#
# 1MB-Paper-API-Query-Builds.sh  v0.1.0 (build 003)
# Query PaperMC Fill v3 API for build details of a single Paper version.
# - Supports default channel filter (STABLE) and CLI override (-channel:stable).
# - Pretty output (requires jq).
# - Caches the response in .paper-builds-cache.json and reports if a newer build
#   exists since the last run (for the same project/version/channel).
#
# Cache file: .paper-builds-cache.json
#
# Show all commits per build for the newest 10 builds:
# ./1MB-Paper-API-Query-Builds.sh -commits:-1
# Show 30 newest builds with the first 3 commits each:
# ./1MB-Paper-API-Query-Builds.sh -limit:30 -commits:3

set -euo pipefail

# -------------------------
# Config (edit these)
# -------------------------
CACHE_FILE=".paper-builds-cache.json"
API_BASE="https://fill.papermc.io/v3"
USER_AGENT="1MB-paper-scripts/0.1 (+https://github.com/mrfdev/1MB)"
TIMEOUT_SECS=20

DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.8"
# Common channels seen: RECOMMENDED, STABLE, ALPHA, BETA (Use "ALL" (or empty) to fetch all channels).
DEFAULT_CHANNEL="STABLE"

# Presentation
BUILDS_SHOWN=12   # How many newest builds to list (-1 for all)
COMMITS_SHOWN=5   # How many commit messages per build (0 hide, -1 show ALL)
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

is_valid_json() { [[ -n "${1:-}" ]] && jq -e . >/dev/null 2>&1 <<<"$1"; }

# Cache helpers (we store meta + builds array so we can compare safely)
save_cache() {
  local project="$1" version="$2" channel="$3" payload="$4"
  local ts; ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  jq -c --arg p "$project" --arg v "$version" --arg c "$channel" --arg ts "$ts" '
    { _meta: {project:$p, version:$v, channel:$c, fetched_at:$ts}, builds: . }
  ' <<<"$payload" > "$CACHE_FILE"
}

load_cache() { [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE" || true; }

print_help() {
  cat <<'EOF'
Usage: 1MB-Paper-API-Query-Builds.sh [options]

Options (multiple forms supported):
  -channel:VALUE        Set channel (e.g. stable, alpha, beta, snapshot, all)
  -channel VALUE
  --channel=VALUE
  -c VALUE

  -version:VALUE        Set version (e.g. 1.21.8)
  -version VALUE
  --version=VALUE
  -v VALUE

  -project:VALUE        Set project (default: paper)
  -project VALUE
  --project=VALUE
  -p VALUE

  -limit:N              Limit number of builds shown (default: 10; -1 for all)
  --limit=N

  -commits:N            Number of commit lines per build (default: 1; 0 hides; -1 = ALL)
  --commits=N
  -m N

  -h, --help            Show this help

Examples:
  ./1MB-Paper-API-Query-Builds.sh
  ./1MB-Paper-API-Query-Builds.sh -channel:stable -commits:3
  ./1MB-Paper-API-Query-Builds.sh -channel ALL -limit:-1 -commits:-1
EOF
}

# -------------------------
# CLI parsing
# -------------------------
PROJECT="$DEFAULT_PROJECT"
VERSION="$DEFAULT_VERSION"
CHANNEL="$DEFAULT_CHANNEL"
LIMIT="$BUILDS_SHOWN"
COMMITS="$COMMITS_SHOWN"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) print_help; exit 0 ;;
    -channel:*) CHANNEL="${1#*:}"; shift ;;
    --channel=*) CHANNEL="${1#*=}"; shift ;;
    -channel|-c) CHANNEL="${2:-}"; shift 2 ;;
    channel=*|-C=* ) CHANNEL="${1#*=}"; shift ;;

    -version:*) VERSION="${1#*:}"; shift ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    -version|-v) VERSION="${2:-}"; shift 2 ;;
    version=* ) VERSION="${1#*=}"; shift ;;

    -project:*) PROJECT="${1#*:}"; shift ;;
    --project=*) PROJECT="${1#*=}"; shift ;;
    -project|-p) PROJECT="${2:-}"; shift 2 ;;
    project=* ) PROJECT="${1#*=}"; shift ;;

    -limit:*) LIMIT="${1#*:}"; shift ;;
    --limit=*) LIMIT="${1#*=}"; shift ;;
    -limit) LIMIT="${2:-}"; shift 2 ;;

    -commits:*) COMMITS="${1#*:}"; shift ;;
    --commits=*) COMMITS="${1#*=}"; shift ;;
    -commits|-m) COMMITS="${2:-}"; shift 2 ;;

    *) echo "Unknown option: $1" >&2; print_help; exit 64 ;;
  esac
done

# Normalize channel
CHANNEL_UP="$(tr '[:lower:]' '[:upper:]' <<< "${CHANNEL:-}")"
[[ "$CHANNEL_UP" == "ALL" ]] && CHANNEL_UP=""
CHANNEL_PRINT="${CHANNEL_UP:-ALL}"

# -------------------------
# Preconditions
# -------------------------
if ! have jq; then
  echo "Error: 'jq' is required. Please install jq and retry." >&2
  exit 2
fi

# -------------------------
# Fetch
# -------------------------
BASE_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds"
URL="$BASE_URL"
if [[ -n "$CHANNEL_UP" ]]; then
  URL="$BASE_URL?channel=$CHANNEL_UP"
fi

if ! JSON="$(http_get "$URL")"; then
  echo "Error: failed to fetch $URL" >&2
  exit 1
fi

if ! is_valid_json "$JSON"; then
  echo "Error: API returned invalid JSON." >&2
  exit 1
fi

# Ensure we have an array (the builds endpoint returns an array)
if [[ "$(jq -r 'type' <<<"$JSON")" != "array" ]]; then
  echo "Error: unexpected response (expected array from builds endpoint)." >&2
  exit 1
fi

# -------------------------
# Summaries
# -------------------------
TOTAL="$(jq 'length' <<<"$JSON")"
LATEST_ID="$(jq -r 'map(.id) | max? // empty' <<<"$JSON")"
LATEST_ID="${LATEST_ID:-?}"
CHANNELS_PRESENT="$(jq -r 'map(.channel) | unique | join(", ")' <<<"$JSON")"

echo "== PaperMC Builds =="
echo "  Project: $PROJECT"
echo "  Version: $VERSION"
echo "  Channel filter: $CHANNEL_PRINT"
echo "  Endpoint: $URL"
echo "  Total builds found: $TOTAL"
echo "  Channels present in response: ${CHANNELS_PRESENT:-unknown}"
echo

# -------------------------
# List builds
# -------------------------
# Helper jq: pick the primary download entry. Prefer "server:default", else first entry.
JQ_LIST_PROG='
  def primary_download:
    (.downloads["server:default"] //
     ( .downloads | to_entries | sort_by(.key) | (.[0].value // {})));

  . as $all
  | (if $limit < 0 then $all else ($all[0:$limit]) end)
  | .[]
  | . as $b
  | (primary_download) as $d
  | ($d.size // 0) as $size
  | ($size / 1048576) as $mb
  | ($mb*100 | floor / 100) as $mb2
  | "  #\($b.id) — \($b.time) — \($b.channel)\n"
    + "    jar: \($d.name // "unknown")\n"
    + "    size: \($size) bytes (\($mb2) MB)\n"
    + "    sha256: \($d.checksums.sha256 // "unknown")\n"
    + "    url: \($d.url // "unknown")\n"
    + (
        if ($b.commits|length) > 0 and $commits != 0 then
          "    commits:\n"
          + (
              ($b.commits | if $commits < 0 then . else .[0:$commits] end)
              | map(
                  "      - "
                  + ((.message // "commit") | split("\n")[0])
                  + " (" + ((.sha // "")[0:7]) + ")"
                )
              | join("\n")
            )
          + "\n"
        else "" end
      )
'

SORTED="$(jq -c 'sort_by(.id) | reverse' <<<"$JSON")"

if (( TOTAL == 0 )); then
  echo "No builds available for the selected filter."
else
  jq -r --argjson limit "$LIMIT" --argjson commits "$COMMITS" "$JQ_LIST_PROG" <<<"$SORTED"
  if (( LIMIT >= 0 )) && (( TOTAL > LIMIT )); then
    echo "  … (+$((TOTAL - LIMIT)) more)"
  fi
fi

# -------------------------
# Cache comparison
# -------------------------
PREV_JSON="$(load_cache || true)"
echo
echo "Summary:"
echo "  Latest $CHANNEL_PRINT build: $LATEST_ID"

if [[ -n "$PREV_JSON" ]] && is_valid_json "$PREV_JSON"; then
  META_MATCH="$(jq -r --arg p "$PROJECT" --arg v "$VERSION" --arg c "${CHANNEL_UP:-ALL}" '
      (._meta.project == $p) and
      (._meta.version == $v) and
      ((._meta.channel // "ALL") == $c)
    ' <<<"$PREV_JSON" || echo "false")"

  if [[ "$META_MATCH" == "true" ]]; then
    PREV_LATEST="$(jq -r '(.builds | map(.id) | max? // empty)' <<<"$PREV_JSON")"
    if [[ -n "$PREV_LATEST" && "$LATEST_ID" =~ ^[0-9]+$ && "$PREV_LATEST" =~ ^[0-9]+$ ]]; then
      if (( LATEST_ID > PREV_LATEST )); then
        echo "  Newer build since cache? Yes (latest: $LATEST_ID — cached: $PREV_LATEST)"
      else
        echo "  Newer build since cache? No (latest: $LATEST_ID — cached: $PREV_LATEST)"
      fi
    else
      echo "  Newer build since cache? Unknown (non-numeric or missing cached data)"
    fi
  else
    echo "  Newer build since cache? Not comparable (cache is for different project/version/channel)"
  fi
else
  echo "  Newer build since cache? Unknown (no previous cache)"
fi

# -------------------------
# Save cache
# -------------------------
save_cache "$PROJECT" "$VERSION" "${CHANNEL_UP:-ALL}" "$JSON"
echo
echo "Cache updated: $CACHE_FILE"
