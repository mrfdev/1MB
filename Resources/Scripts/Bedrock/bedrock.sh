#!/usr/bin/env bash
#
# bedrock.sh - Look up Minecraft: Bedrock Edition player info using GeyserMC + MCProfile APIs
#
# This script was created for and tested on:
#   - Minecraft server: 1MoreBlock.com
#   - macOS Tahoe 26.1
# It should also work on most modern Linux distributions (e.g. Ubuntu 20.04+).
#
# Features:
#   - Accepts either a Bedrock gamertag or XUID (decimal)
#   - Resolves gamertag <-> XUID using GeyserMC / MCProfile
#   - Fetches full JSON info from both APIs and caches it locally
#   - Full, summary, short, and JSON output modes
#   - Optional verbose debugging (URLs, timings, raw JSON to stderr)
#
# APIs used:
#   - GeyserMC:    https://api.geysermc.org
#   - MCProfile:   https://mcprofile.io
#
# Author:   Floris (mrfloris)
# Assistant: ChatGPT (OpenAI)


# Exit on error, unset variable usage, or pipefail
set -euo pipefail

# ----- Global flags / defaults -----

MODE="full"           # Output mode: full | short | summary | json
USE_CACHE=1           # Whether to read/write cache
REFRESH_CACHE=0       # Force re-fetch even if cache exists
CLEAR_CACHE=0         # Clear cache and exit
USE_GEYSER=1          # Use GeyserMC APIs
USE_MCPROFILE=1       # Use MCProfile APIs
NETWORK_ERROR=0       # Track if any network error occurred
VERBOSE=0             # Verbose/debug logging flag

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [--short|--summary|--json] [--no-cache|--refresh|--clear-cache] [--geyser-only|--mcprofile-only] [-v|--verbose] <gamertag|xuid-decimal>" >&2
  exit 1
fi

# -------- Option parsing --------
# We parse all flags first and keep the final non-flag as the QUERY.

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --short)   MODE="short"; shift ;;
    --summary) MODE="summary"; shift ;;
    --json)    MODE="json"; shift ;;
    --no-cache)
      USE_CACHE=0
      REFRESH_CACHE=0
      shift
      ;;
    --refresh)
      USE_CACHE=1
      REFRESH_CACHE=1
      shift
      ;;
    --clear-cache)
      CLEAR_CACHE=1
      shift
      ;;
    --geyser-only)
      USE_GEYSER=1
      USE_MCPROFILE=0
      shift
      ;;
    --mcprofile-only)
      USE_GEYSER=0
      USE_MCPROFILE=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    --help)
      echo "Usage: $0 [--short|--summary|--json] [--no-cache|--refresh|--clear-cache] [--geyser-only|--mcprofile-only] [-v|--verbose] <gamertag|xuid-decimal>"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      # First non-flag is considered the query (gamertag or XUID)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Collect any remaining positional arguments (should usually be empty)
while [[ $# -gt 0 ]]; do
  ARGS+=("$1")
  shift
done

# ----- Clear cache and exit if requested -----

if [[ "$CLEAR_CACHE" -eq 1 ]]; then
  DEFAULT_CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}"
  CACHE_DIR="${BEDROCK_CACHE_DIR:-$DEFAULT_CACHE_BASE/bedrock_lookup}"
  if [[ -d "$CACHE_DIR" ]]; then
    rm -rf "$CACHE_DIR"
    echo "Cache cleared: $CACHE_DIR"
  else
    echo "No cache directory to clear: $CACHE_DIR"
  fi
  exit 0
fi

# We expect exactly one positional argument: the query
if [[ "${#ARGS[@]}" -ne 1 ]]; then
  echo "Usage: $0 [--short|--summary|--json] [--no-cache|--refresh|--clear-cache] [--geyser-only|--mcprofile-only] [-v|--verbose] <gamertag|xuid-decimal>" >&2
  exit 1
fi

QUERY="${ARGS[0]}"

# ----- Tool availability and cache setup -----

# jq is optional but required for:
#   - --json mode
#   - caching (we store JSON structures in the cache)
have_jq=1
if ! command -v jq >/dev/null 2>&1; then
  have_jq=0
fi

if [[ "$MODE" == "json" && "$have_jq" -ne 1 ]]; then
  echo "[ERROR] --json mode requires 'jq' to be installed." >&2
  exit 1
fi

# If caching is enabled but jq is missing, we silently disable caching
if [[ "$USE_CACHE" -eq 1 && "$have_jq" -ne 1 ]]; then
  USE_CACHE=0
fi

# Cache directory:
#   - default: ~/.cache/bedrock_lookup
#   - can be overridden via BEDROCK_CACHE_DIR env var
DEFAULT_CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="${BEDROCK_CACHE_DIR:-$DEFAULT_CACHE_BASE/bedrock_lookup}"

# ----- Terminal color handling -----

USE_COLOR=0
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  USE_COLOR=1
fi

if [[ "$USE_COLOR" -eq 1 ]]; then
  RED="\033[31m"
  YELLOW="\033[33m"
  CYAN="\033[36m"
  BOLD="\033[1m"
  DIM="\033[2m"
  RESET="\033[0m"
else
  RED=""; YELLOW=""; CYAN=""; BOLD=""; DIM=""; RESET=""
fi

error() { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

divider() {
  # Only show pretty dividers in full mode
  if [[ "$MODE" == "full" ]]; then
    printf '\n========================================\n\n'
  fi
}

log() {
  # Full mode gets ChatGPT-style narration, other modes are quiet
  if [[ "$MODE" == "full" ]]; then
    echo -e "$@"
  fi
}

debug() {
  # Verbose/debug logs always go to stderr so they don't pollute JSON/pipes
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo -e "$@" >&2
  fi
}

# curl_json:
#   - Performs a GET to the provided URL.
#   - On success, prints JSON to stdout and returns 0.
#   - On failure, sets NETWORK_ERROR=1 and returns non-zero.
#   - In verbose mode, logs timings and raw JSON to stderr.
curl_json() {
  local url="$1"
  local out
  local start=0
  if [[ "$VERBOSE" -eq 1 ]]; then
    start=$SECONDS
    debug "[DEBUG] HTTP GET $url"
  fi
  if ! out=$(curl -fsS "$url" 2>/dev/null); then
    NETWORK_ERROR=1
    log "${YELLOW}[WARN]${RESET} Network/API error for: $url"
    debug "[DEBUG] curl failed for $url"
    return 1
  fi
  if [[ "$VERBOSE" -eq 1 ]]; then
    local dur=$((SECONDS-start))
    debug "[DEBUG] Response from $url in ${dur}s"
    if [[ "$have_jq" -eq 1 ]]; then
      debug "[DEBUG] Raw JSON from $url:"
      printf '%s' "$out" | jq . >&2 || debug "[DEBUG] (jq failed, raw body above)"
    else
      debug "[DEBUG] Raw JSON from $url:"
      debug "$out"
    fi
  fi
  printf '%s' "$out"
  return 0
}

# urlencode:
#   - URL-encodes a string, using jq when available or a simple fallback
urlencode() {
  local s="$1"
  if [[ "$have_jq" -eq 1 ]]; then
    printf '%s' "$s" | jq -sRr @uri
  else
    s="${s// /%20}"
    printf '%s' "$s"
  fi
}

# ----- Data fields -----
# These are populated either from cache or from live API calls.

XUID_DEC=""           # XUID in decimal form
XUID_HEX=""           # XUID in hexadecimal
GAMERTAG=""           # Original gamertag query (if that's what was passed)
GLOBAL_GAMERTAG=""    # Normalized gamertag from API
texture_id=""         # Skin texture ID
SKIN_URL=""           # Skin URL (textures.minecraft.net)
XBOX_URL=""           # Web profile URL
FROM_CACHE=0          # Whether we loaded from cache
CACHED_FILE=""        # Path to the cache file we used

# Raw JSON blobs as returned by APIs (for full-mode cache replay)
GEYSER_GAMERTAG_JSON=""
GEYSER_SKIN_JSON=""
MCPROFILE_JSON=""

# ----- Cache helpers -----

cache_path_for_xuid() {
  local x="$1"
  printf '%s/xuid_%s.json' "$CACHE_DIR" "$x"
}

cache_path_for_gamertag() {
  local gt="$1"
  local lower
  lower="$(echo "$gt" | tr '[:upper:]' '[:lower:]')"
  lower="${lower// /_}"
  printf '%s/gamertag_%s.json' "$CACHE_DIR" "$lower"
}

# load_cache:
#   - kind: "xuid" or "gamertag"
#   - key:  xuid decimal OR gamertag string
#   - populates GLOBAL_GAMERTAG, XUID_DEC, XUID_HEX, texture_id, SKIN_URL,
#     XBOX_URL and raw JSON blobs if present.
load_cache() {
  local kind="$1"
  local key="$2"
  local path

  # Cache disabled or refresh requested or jq unavailable -> skip
  if [[ "$USE_CACHE" -eq 0 || "$REFRESH_CACHE" -eq 1 || "$have_jq" -eq 0 ]]; then
    return 1
  fi

  if [[ "$kind" == "xuid" ]]; then
    path="$(cache_path_for_xuid "$key")"
  else
    path="$(cache_path_for_gamertag "$key")"
  fi
  if [[ ! -f "$path" ]]; then
    return 1
  fi

  debug "[DEBUG] Loading cache from $path"

  GLOBAL_GAMERTAG="$(jq -r '.gamertag // empty' "$path")"
  XUID_DEC="$(jq -r '.xuid_decimal // empty' "$path")"
  XUID_HEX="$(jq -r '.xuid_hex // empty' "$path")"
  texture_id="$(jq -r '.skin_texture_id // empty' "$path")"
  SKIN_URL="$(jq -r '.skin_url // empty' "$path")"
  XBOX_URL="$(jq -r '.xbox_profile_url // empty' "$path")"

  # raw JSON blobs (may be absent in older cache versions)
  local tmp
  tmp="$(jq -c '.raw.geyser_gamertag // empty' "$path")"
  [[ -n "$tmp" && "$tmp" != "null" ]] && GEYSER_GAMERTAG_JSON="$tmp"
  tmp="$(jq -c '.raw.geyser_skin // empty' "$path")"
  [[ -n "$tmp" && "$tmp" != "null" ]] && GEYSER_SKIN_JSON="$tmp"
  tmp="$(jq -c '.raw.mcprofile_xuid // empty' "$path")"
  [[ -n "$tmp" && "$tmp" != "null" ]] && MCPROFILE_JSON="$tmp"

  if [[ -z "$XUID_DEC" && "$kind" == "xuid" ]]; then
    XUID_DEC="$key"
  fi

  FROM_CACHE=1
  CACHED_FILE="$path"
  log "${CYAN}[INFO]${RESET} Loaded from cache: $path"
  return 0
}

# build_summary_json:
#   - Builds the combined cache JSON document containing:
#     * summary fields (gamertag, xuid, skin, etc.)
#     * raw JSON blobs from each API (under .raw.*)
build_summary_json() {
  local gg="${GEYSER_GAMERTAG_JSON:-}"
  local gs="${GEYSER_SKIN_JSON:-}"
  local mp="${MCPROFILE_JSON:-}"
  [[ -z "$gg" ]] && gg="null"
  [[ -z "$gs" ]] && gs="null"
  [[ -z "$mp" ]] && mp="null"

  jq -n \
    --arg gamertag "${GLOBAL_GAMERTAG}" \
    --arg xuid_decimal "${XUID_DEC}" \
    --arg xuid_hex "${XUID_HEX}" \
    --arg skin_texture_id "${texture_id}" \
    --arg skin_url "${SKIN_URL}" \
    --arg xbox_profile_url "${XBOX_URL}" \
    --argjson geyser_gamertag "$gg" \
    --argjson geyser_skin "$gs" \
    --argjson mcprofile_xuid "$mp" \
    '{
      gamertag: $gamertag,
      xuid_decimal: $xuid_decimal,
      xuid_hex: $xuid_hex,
      skin_texture_id: $skin_texture_id,
      skin_url: $skin_url,
      xbox_profile_url: $xbox_profile_url,
      raw: {
        geyser_gamertag: $geyser_gamertag,
        geyser_skin: $geyser_skin,
        mcprofile_xuid: $mcprofile_xuid
      }
    }'
}

# save_cache:
#   - Writes the combined JSON document under:
#       xuid_<XUID>.json
#       gamertag_<gamertag>.json
save_cache() {
  if [[ "$USE_CACHE" -eq 0 || "$have_jq" -eq 0 ]]; then
    return 0
  fi
  if [[ -z "$XUID_DEC" && -z "$GLOBAL_GAMERTAG" ]]; then
    return 0
  fi

  mkdir -p "$CACHE_DIR"
  local json; json="$(build_summary_json)"

  if [[ -n "$XUID_DEC" ]]; then
    local xpath; xpath="$(cache_path_for_xuid "$XUID_DEC")"
    printf '%s\n' "$json" > "$xpath"
    log "${CYAN}[INFO]${RESET} Cached to: $xpath"
    debug "[DEBUG] Wrote cache file $xpath"
  fi

  if [[ -n "$GLOBAL_GAMERTAG" ]]; then
    local gtpath; gtpath="$(cache_path_for_gamertag "$GLOBAL_GAMERTAG")"
    printf '%s\n' "$json" > "$gtpath"
    log "${CYAN}[INFO]${RESET} Cached to: $gtpath"
    debug "[DEBUG] Wrote cache file $gtpath"
  fi
}

# print_full_from_cache:
#   - Replays a "full" view using cached data.
#   - If raw JSON blobs are present, they are printed exactly as jq prettified
#     JSON (same as live API calls). Otherwise we fall back to minimal objects.
print_full_from_cache() {
  echo "Bedrock lookup for: ${QUERY}"
  if [[ "$QUERY" =~ ^[0-9]+$ ]]; then
    echo "Detected input type: XUID (decimal)"
  else
    echo "Detected input type: Gamertag"
  fi

  divider
  echo "Using XUID (decimal): ${XUID_DEC}"

  # GeyserMC – gamertag
  if [[ "$USE_GEYSER" -eq 1 ]]; then
    divider
    echo "GeyserMC – gamertag lookup"
    echo "Endpoint: https://api.geysermc.org/v2/xbox/gamertag/${XUID_DEC}"
    echo
    echo "[INFO] Using cached data (refresh with: ./bedrock.sh --refresh ${QUERY})"
    echo

    if [[ -n "$GEYSER_GAMERTAG_JSON" ]]; then
      if [[ "$have_jq" -eq 1 ]]; then
        echo "$GEYSER_GAMERTAG_JSON" | jq .
      else
        echo "$GEYSER_GAMERTAG_JSON"
      fi
    elif [[ -n "${GLOBAL_GAMERTAG}" ]]; then
      # Fallback: small JSON
      if [[ "$have_jq" -eq 1 ]]; then
        jq -n --arg gamertag "$GLOBAL_GAMERTAG" '{gamertag:$gamertag}'
      else
        echo "{ \"gamertag\": \"${GLOBAL_GAMERTAG}\" }"
      fi
    else
      echo "{}"
    fi
  fi

  # GeyserMC – skin
  if [[ "$USE_GEYSER" -eq 1 ]]; then
    divider
    echo "GeyserMC – skin lookup"
    echo "Endpoint: https://api.geysermc.org/v2/skin/${XUID_DEC}"
    echo
    echo "[INFO] Using cached data (refresh with: ./bedrock.sh --refresh ${QUERY})"
    echo

    if [[ -n "$GEYSER_SKIN_JSON" ]]; then
      if [[ "$have_jq" -eq 1 ]]; then
        echo "$GEYSER_SKIN_JSON" | jq .
      else
        echo "$GEYSER_SKIN_JSON"
      fi
    else
      # Fallback: minimal skin-only JSON
      if [[ "$have_jq" -eq 1 ]]; then
        jq -n \
          --arg texture_id "${texture_id:-}" \
          --arg skin "${SKIN_URL:-}" \
          '{
            texture_id: ($texture_id | select(. != "")),
            skin:       ($skin       | select(. != ""))
          } | with_entries(select(.value != null))'
      else
        if [[ -n "${texture_id}" || -n "${SKIN_URL}" ]]; then
          echo "{"
          [[ -n "${texture_id}" ]] && echo "  \"texture_id\": \"${texture_id}\","
          [[ -n "${SKIN_URL}" ]] && echo "  \"skin\": \"${SKIN_URL}\""
          echo "}"
        else
          echo "{}"
        fi
      fi
    fi
  fi

  # MCProfile – Bedrock profile
  if [[ "$USE_MCPROFILE" -eq 1 ]]; then
    divider
    echo "MCProfile – Bedrock profile lookup"
    echo "Endpoint: https://mcprofile.io/api/v1/bedrock/xuid/${XUID_DEC}"
    echo
    echo "[INFO] Using cached data (refresh with: ./bedrock.sh --refresh ${QUERY})"
    echo

    if [[ -n "$MCPROFILE_JSON" ]]; then
      if [[ "$have_jq" -eq 1 ]]; then
        echo "$MCPROFILE_JSON" | jq .
      else
        echo "$MCPROFILE_JSON"
      fi
    else
      # Fallback: minimal subset
      if [[ "$have_jq" -eq 1 ]]; then
        jq -n \
          --arg gamertag "${GLOBAL_GAMERTAG:-}" \
          --arg xuid "${XUID_DEC:-}" \
          --arg textureid "${texture_id:-}" \
          --arg skin "${SKIN_URL:-}" \
          '{
            gamertag:  ($gamertag  | select(. != "")),
            xuid:      ($xuid      | select(. != "")),
            textureid: ($textureid | select(. != "")),
            skin:      ($skin      | select(. != ""))
          } | with_entries(select(.value != null))'
      else
        echo "{"
        [[ -n "${GLOBAL_GAMERTAG}" ]] && echo "  \"gamertag\": \"${GLOBAL_GAMERTAG}\","
        [[ -n "${XUID_DEC}" ]] && echo "  \"xuid\": \"${XUID_DEC}\","
        [[ -n "${texture_id}" ]] && echo "  \"textureid\": \"${texture_id}\","
        [[ -n "${SKIN_URL}" ]] && echo "  \"skin\": \"${SKIN_URL}\""
        echo "}"
      fi
    fi
  fi

  # Xbox.com profile link
  if [[ -n "${GLOBAL_GAMERTAG}" ]]; then
    divider
    echo "Xbox.com profile URL:"
    echo "${XBOX_URL}"
  fi

  echo
  echo "Done."
}

# ----- Main flow -----

log "Bedrock lookup for: ${BOLD}${QUERY}${RESET}"

# Detect input type: pure digits = XUID, otherwise treat as gamertag
if [[ "$QUERY" =~ ^[0-9]+$ ]]; then
  XUID_DEC="$QUERY"
  log "${DIM}Detected input type:${RESET} XUID (decimal)"
else
  GAMERTAG="$QUERY"
  GLOBAL_GAMERTAG="$QUERY"
  log "${DIM}Detected input type:${RESET} Gamertag"
fi

# Try loading from cache based on what we know (gamertag or XUID)
if [[ -n "$GAMERTAG" ]]; then
  load_cache "gamertag" "$GAMERTAG" || true
elif [[ -n "$XUID_DEC" ]]; then
  load_cache "xuid" "$XUID_DEC" || true
fi

# If cache was a hit, we can answer without touching the network
if [[ "$FROM_CACHE" -eq 1 ]]; then
  # Ensure we always have XUID_HEX if we have XUID_DEC
  if [[ -z "$XUID_HEX" && -n "$XUID_DEC" ]]; then
    XUID_HEX="$(printf '%016X' "${XUID_DEC}" 2>/dev/null || true)"
  fi

  # JSON mode: just dump the raw cache object
  if [[ "$MODE" == "json" && -n "$CACHED_FILE" ]]; then
    cat "$CACHED_FILE"
    exit 0
  fi

  # Short one-liner
  if [[ "$MODE" == "short" ]]; then
    echo "${GLOBAL_GAMERTAG:-unknown} | XUID: ${XUID_DEC:-unknown}"
    exit 0
  fi

  # Human-readable summary
  if [[ "$MODE" == "summary" ]]; then
    echo -e "${BOLD}Gamertag:${RESET}  ${GLOBAL_GAMERTAG:-unknown}"
    echo -e "${BOLD}XUID:${RESET}      ${XUID_DEC:-unknown}"
    [[ -n "${XUID_HEX}" ]] && echo -e "${BOLD}XUID HEX:${RESET}  ${XUID_HEX}"
    [[ -n "${SKIN_URL}" ]] && echo -e "${BOLD}Skin:${RESET}      ${SKIN_URL}"
    [[ -n "${XBOX_URL}" ]] && echo -e "${BOLD}Xbox URL:${RESET}  ${XBOX_URL}"
    exit 0
  fi

  # Full, pretty cache replay
  print_full_from_cache
  exit 0
fi

# ---------- No cache hit: network lookups ----------

# Step 1) If we started with a gamertag, resolve gamertag → XUID
if [[ -n "${GAMERTAG}" ]]; then
  divider
  log "Resolving gamertag → XUID"

  local_json=""

  # Try GeyserMC first
  if [[ "$USE_GEYSER" -eq 1 ]]; then
    log "GeyserMC endpoint: https://api.geysermc.org/v2/xbox/xuid/${GAMERTAG}"
    log
    if curl_out="$(curl_json "https://api.geysermc.org/v2/xbox/xuid/${GAMERTAG}")"; then
      local_json="$curl_out"
    fi
    if [[ -n "$local_json" ]]; then
      if [[ "$have_jq" -eq 1 ]]; then
        XUID_DEC="$(echo "$local_json" | jq -r '.xuid // empty' 2>/dev/null || true)"
      else
        XUID_DEC="$(echo "$local_json" | sed -n 's/.*\"xuid\"[[:space:]]*:[[:space:]]*\"\([0-9]\+\)\".*/\1/p' | head -n1 || true)"
      fi
      if [[ -n "$XUID_DEC" ]]; then
        log "${CYAN}[INFO]${RESET} GeyserMC resolved XUID: ${XUID_DEC}"
      fi
    fi
  fi

  # If that failed, fall back to MCProfile's gamertag endpoint
  if [[ -z "$XUID_DEC" && "$USE_MCPROFILE" -eq 1 ]]; then
    divider
    log "Trying MCProfile gamertag → XUID"
    log "MCProfile endpoint: https://mcprofile.io/api/v1/bedrock/gamertag/${GAMERTAG}"
    log

    local_json=""
    if curl_out="$(curl_json "https://mcprofile.io/api/v1/bedrock/gamertag/${GAMERTAG}")"; then
      local_json="$curl_out"
    fi
    if [[ -n "$local_json" ]]; then
      if [[ "$have_jq" -eq 1 ]]; then
        XUID_DEC="$(echo "$local_json" | jq -r '.xuid // empty' 2>/dev/null || true)"
        resolved_gt="$(echo "$local_json" | jq -r '.gamertag // empty' 2>/dev/null || true)"
        if [[ -n "$resolved_gt" ]]; then
          GLOBAL_GAMERTAG="$resolved_gt"
        fi
      else
        XUID_DEC="$(echo "$local_json" | sed -n 's/.*\"xuid\"[[:space:]]*:[[:space:]]*\"\([0-9]\+\)\".*/\1/p' | head -n1 || true)"
      fi
      if [[ -n "$XUID_DEC" ]]; then
        log "${CYAN}[INFO]${RESET} MCProfile resolved XUID: ${XUID_DEC}"
      fi
    fi
  fi

  if [[ -z "$XUID_DEC" ]]; then
    if [[ "$NETWORK_ERROR" -eq 1 ]]; then
      error "Network/API error while resolving gamertag '${GAMERTAG}' with current API settings."
      exit 2
    else
      error "Could not resolve XUID for gamertag '${GAMERTAG}' with current API settings."
      exit 3
    fi
  fi
fi

divider
log "${DIM}Using XUID (decimal):${RESET} ${XUID_DEC}"

# Step 2) GeyserMC – gamertag + skin lookups
if [[ "$USE_GEYSER" -eq 1 ]]; then
  # GeyserMC: gamertag by XUID
  divider
  log "GeyserMC – gamertag lookup"
  log "Endpoint: https://api.geysermc.org/v2/xbox/gamertag/${XUID_DEC}"
  log

  local_json=""
  if curl_out="$(curl_json "https://api.geysermc.org/v2/xbox/gamertag/${XUID_DEC}")"; then
    local_json="$curl_out"
  fi
  if [[ -n "$local_json" ]]; then
    GEYSER_GAMERTAG_JSON="$local_json"
    if [[ "$have_jq" -eq 1 ]]; then
      g_gt="$(echo "$local_json" | jq -r '.gamertag // empty' 2>/dev/null || true)"
      if [[ -n "$g_gt" ]]; then
        GLOBAL_GAMERTAG="$g_gt"
        log "${CYAN}[INFO]${RESET} Gamertag (from GeyserMC): ${GLOBAL_GAMERTAG}"
      fi
    else
      g_gt="$(echo "$local_json" | sed -n 's/.*\"gamertag\"[[:space:]]*:[[:space:]]*\"\([^"]*\)\".*/\1/p' | head -n1 || true)"
      if [[ -n "$g_gt" ]]; then
        GLOBAL_GAMERTAG="$g_gt"
        log "${CYAN}[INFO]${RESET} Gamertag (from GeyserMC): ${GLOBAL_GAMERTAG}"
      fi
    fi
    if [[ "$MODE" == "full" ]]; then
      echo
      if [[ "$have_jq" -eq 1 ]]; then
        echo "$local_json" | jq .
      else
        echo "$local_json"
      fi
    fi
  fi

  # GeyserMC: skin by XUID
  divider
  log "GeyserMC – skin lookup"
  log "Endpoint: https://api.geysermc.org/v2/skin/${XUID_DEC}"
  log

  local_json=""
  if curl_out="$(curl_json "https://api.geysermc.org/v2/skin/${XUID_DEC}")"; then
    local_json="$curl_out"
  fi
  if [[ -n "$local_json" ]]; then
    GEYSER_SKIN_JSON="$local_json"
    if [[ "$have_jq" -eq 1 ]]; then
      texture_id="$(echo "$local_json" | jq -r '.texture_id // empty' 2>/dev/null || true)"
    else
      texture_id="$(echo "$local_json" | sed -n 's/.*\"texture_id\"[[:space:]]*:[[:space:]]*\"\([^"]*\)\".*/\1/p' | head -n1 || true)"
    fi
    if [[ -n "$texture_id" ]]; then
      SKIN_URL="http://textures.minecraft.net/texture/${texture_id}"
      log "${CYAN}[INFO]${RESET} Skin texture_id: ${texture_id}"
      log "${CYAN}[INFO]${RESET} Texture URL: ${SKIN_URL}"
    fi
    if [[ "$MODE" == "full" ]]; then
      echo
      if [[ "$have_jq" -eq 1 ]]; then
        echo "$local_json" | jq .
      else
        echo "$local_json"
      fi
    fi
  fi
fi

# Step 3) MCProfile – Bedrock profile by XUID
if [[ "$USE_MCPROFILE" -eq 1 ]]; then
  divider
  log "MCProfile – Bedrock profile lookup"
  log "Endpoint: https://mcprofile.io/api/v1/bedrock/xuid/${XUID_DEC}"
  log

  local_json=""
  if curl_out="$(curl_json "https://mcprofile.io/api/v1/bedrock/xuid/${XUID_DEC}")"; then
    local_json="$curl_out"
  fi

  if [[ -n "$local_json" ]]; then
    MCPROFILE_JSON="$local_json"
    if [[ "$have_jq" -eq 1 ]]; then
      mp_gt="$(echo "$local_json" | jq -r '.gamertag // empty' 2>/dev/null || true)"
      mp_xuid="$(echo "$local_json" | jq -r '.xuid // empty' 2>/dev/null || true)"
      mp_texid="$(echo "$local_json" | jq -r '.textureid // empty' 2>/dev/null || true)"
      mp_skin="$(echo "$local_json" | jq -r '.skin // empty' 2>/dev/null || true)"

      if [[ -n "$mp_gt" ]]; then
        GLOBAL_GAMERTAG="$mp_gt"
      fi
      if [[ -z "$XUID_DEC" && -n "$mp_xuid" ]]; then
        XUID_DEC="$mp_xuid"
      fi
      if [[ -z "$texture_id" && -n "$mp_texid" ]]; then
        texture_id="$mp_texid"
      fi
      if [[ -z "$SKIN_URL" && -n "$mp_skin" ]]; then
        SKIN_URL="$mp_skin"
      fi
    else
      mp_gt="$(echo "$local_json" | sed -n 's/.*\"gamertag\"[[:space:]]*:[[:space:]]*\"\([^"]*\)\".*/\1/p' | head -n1 || true)"
      if [[ -n "$mp_gt" ]]; then
        GLOBAL_GAMERTAG="$mp_gt"
      fi
    fi

    if [[ "$MODE" == "full" ]]; then
      if [[ "$have_jq" -eq 1 ]]; then
        echo "$local_json" | jq .
      else
        echo "$local_json"
      fi
    fi
  fi
fi

# ----- Finalization and output modes -----

# Sanity check that we have at least one identifier
if [[ -z "${XUID_DEC}" && -z "${GLOBAL_GAMERTAG}" ]]; then
  if [[ "$NETWORK_ERROR" -eq 1 ]]; then
    error "Network/API error during lookup with current API settings."
    exit 2
  else
    error "No data returned from configured APIs."
    exit 3
  fi
fi

# Compute XUID hex representation
if [[ -n "$XUID_DEC" ]]; then
  XUID_HEX="$(printf '%016X' "${XUID_DEC}" 2>/dev/null || true)"
fi

# Compose Xbox.com profile URL if we have a gamertag
if [[ -n "${GLOBAL_GAMERTAG}" ]]; then
  encoded_gt="$(urlencode "${GLOBAL_GAMERTAG}")"
  XBOX_URL="https://www.xbox.com/en-US/play/user/${encoded_gt}"
fi

# Persist cache for future runs
save_cache

# Handle non-full modes
if [[ "$MODE" == "short" ]]; then
  echo "${GLOBAL_GAMERTAG:-unknown} | XUID: ${XUID_DEC:-unknown}"
  exit 0
fi

if [[ "$MODE" == "summary" ]]; then
  echo -e "${BOLD}Gamertag:${RESET}  ${GLOBAL_GAMERTAG:-unknown}"
  echo -e "${BOLD}XUID:${RESET}      ${XUID_DEC:-unknown}"
  [[ -n "${XUID_HEX}" ]] && echo -e "${BOLD}XUID HEX:${RESET}  ${XUID_HEX}"
  [[ -n "${SKIN_URL}" ]] && echo -e "${BOLD}Skin:${RESET}      ${SKIN_URL}"
  [[ -n "${XBOX_URL}" ]] && echo -e "${BOLD}Xbox URL:${RESET}  ${XBOX_URL}"
  exit 0
fi

if [[ "$MODE" == "json" ]]; then
  build_summary_json
  exit 0
fi

# Default: full mode, with raw JSON already printed above.
if [[ -n "${GLOBAL_GAMERTAG}" ]]; then
  divider
  echo "Xbox.com profile URL:"
  echo "${XBOX_URL}"
fi

echo
echo "Done."
