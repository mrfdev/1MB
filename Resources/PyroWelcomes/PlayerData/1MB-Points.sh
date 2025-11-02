#!/bin/bash
# 1MB-Points.sh
# Scan playerdata/*.yml for "Points:" and show the highest (default) or Top 10 (--top).
# Default behavior: resolve and cache names for the highest and Top 10 only.
# Cache format and path match your Ghosts tool: ~/.1mb-namecache.tsv

# chmod +x 1MB-Points.sh
# ./1MB-Points.sh              # highest, with name lookup + cache
# ./1MB-Points.sh --top        # Top 10, with name lookup + cache
# ./1MB-Points.sh --top:25     # Top 25
# ./1MB-Points.sh --dir PATH   # scan a different folder

set -euo pipefail

# -------- Config --------
DATA_DIR="playerdata"
TOP_MODE=0
TOP_N=10

# Colors (optional)
use_color=0
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then use_color=1; fi
[ "${NO_COLOR:-}" != "" ] && use_color=0
if [ $use_color -eq 1 ]; then
  C_HI=$(tput bold); C_DIM=$(tput dim); C_GRN=$(tput setaf 2); C_CYN=$(tput setaf 6); C_RST=$(tput sgr0)
else
  C_HI=""; C_DIM=""; C_GRN=""; C_CYN=""; C_RST=""
fi

# Args
if [ "${1-}" = "--top" ] || [[ "${1-}" =~ ^--top:[0-9]+$ ]]; then
  TOP_MODE=1
  if [[ "${1-}" =~ ^--top:([0-9]+)$ ]]; then TOP_N="${BASH_REMATCH[1]}"; fi
  shift || true
fi
# Optional: allow overriding dir via --dir PATH
if [ "${1-}" = "--dir" ]; then
  [ -n "${2-}" ] || { echo "Error: --dir requires a path" >&2; exit 2; }
  DATA_DIR="$2"; shift 2
fi

# If playerdata/ doesn't exist, use current dir
[ -d "$DATA_DIR" ] || DATA_DIR="."

# -------- Shared cache & lookups (mirrors your 1MB-Ghosts.sh) --------
CACHE="$HOME/.1mb-namecache.tsv"
mkdir -p "$(dirname "$CACHE")" 2>/dev/null || true
touch "$CACHE" 2>/dev/null || true

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
CURL_BASE=(curl -sS -L --connect-timeout 2 --max-time 3 -A "$UA")

normalize_uuid() {
  local raw="$1" u
  u="$(printf "%s" "$raw" | tr -d '-' | tr '[:upper:]' '[:lower:]')"
  if [ ${#u} -eq 32 ]; then
    printf "%s-%s-%s-%s-%s" "${u:0:8}" "${u:8:4}" "${u:12:4}" "${u:16:4}" "${u:20:12}"
  else
    printf "%s" "$raw" | tr '[:upper:]' '[:lower:]'
  fi
}

is_valid_name() { [[ "$1" =~ ^[A-Za-z0-9_]{3,16}$ ]]; }

cache_put() {
  local uuid name
  uuid="$(normalize_uuid "$1")"; name="$2"
  awk -v U="$uuid" -F'\t' 'tolower($1)!=tolower(U){print $0}' "$CACHE" > "$CACHE.tmp" 2>/dev/null || true
  printf "%s\t%s\n" "$uuid" "$name" >> "$CACHE.tmp"
  mv "$CACHE.tmp" "$CACHE"
}
cache_get_name() { awk -v U="$(normalize_uuid "$1")" -F'\t' 'tolower($1)==tolower(U){print $2; exit 0} END{exit 1}' "$CACHE"; }

# Primary: PlayerDB (fast JSON API). Fallbacks: NameMC/Laby/Crafty og:title (HTML).
playerdb_fetch() { "${CURL_BASE[@]}" "https://playerdb.co/api/player/minecraft/$1" || true; }
playerdb_name_from_json() { sed -n 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1; }

parse_og_title() { sed -n 's/.*property="og:title" content="\([^"]*\)".*/\1/p' | head -1 | sed 's/ - .*$//' | awk '{print $1}'; }
lookup_namemc_name_by_uuid() { local html name; html="$("${CURL_BASE[@]}" "https://namemc.com/profile/$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; is_valid_name "$name" && echo "$name"; }
lookup_laby_name_by_uuid()   { local html name; html="$("${CURL_BASE[@]}" "https://laby.net/@$1" || true)";   name="$(printf "%s" "$html" | parse_og_title)"; is_valid_name "$name" && echo "$name"; }
lookup_crafty_name_by_uuid() { local html name; html="$("${CURL_BASE[@]}" "https://crafty.gg/@$1" || true)";   name="$(printf "%s" "$html" | parse_og_title)"; is_valid_name "$name" && echo "$name"; }

resolve_name_cached_only() {
  local uuid="$(normalize_uuid "$1")" n
  n="$(cache_get_name "$uuid" 2>/dev/null || true)" || true
  printf "%s" "${n:-}"
}
resolve_name_network_chain() {
  local uuid="$(normalize_uuid "$1")" name json
  # Cache?
  name="$(resolve_name_cached_only "$uuid")"
  [ -n "$name" ] && { printf "%s" "$name"; return 0; }
  # PlayerDB
  json="$(playerdb_fetch "$uuid")"
  name="$(printf "%s" "$json" | playerdb_name_from_json | head -1)"
  if is_valid_name "$name"; then cache_put "$uuid" "$name"; printf "%s" "$name"; return 0; fi
  # Fallbacks (best effort)
  name="$(lookup_namemc_name_by_uuid "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; printf "%s" "$name"; return 0; fi
  name="$(lookup_laby_name_by_uuid "$uuid"   || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; printf "%s" "$name"; return 0; fi
  name="$(lookup_crafty_name_by_uuid "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; printf "%s" "$name"; return 0; fi
  printf ""
}

label_uuid_best_effort() {
  local u="$1" n
  n="$(resolve_name_cached_only "$u")"
  if [ -n "$n" ]; then printf "%s (%s)" "$n" "$u"; else printf "%s" "$u"; fi
}

# -------- Scan points from files --------
read_scores() {
  find "$DATA_DIR" -type f -name "*.yml" -print0 2>/dev/null | \
  while IFS= read -r -d '' f; do
    pts="$(awk '
      BEGIN{IGNORECASE=1}
      /^[[:space:]]*Points:[[:space:]]*[0-9]+/ {
        n=$0; sub(/.*Points:[[:space:]]*/,"",n);
        if (match(n, /^[0-9]+/)) { print substr(n, RSTART, RLENGTH); exit }
      }
    ' "$f")"
    if [ -n "$pts" ]; then
      uuid="$(basename "$f" .yml)"
      printf "%s\t%s\t%s\n" "$pts" "$uuid" "$f"
    fi
  done
}

RESULTS="$(read_scores | LC_ALL=C sort -rnk1,1)"
[ -n "$RESULTS" ] || { echo "No .yml with a valid 'Points:' in $DATA_DIR" >&2; exit 1; }

if [ $TOP_MODE -eq 1 ]; then
  echo -e "${C_HI}${C_CYN}Top ${TOP_N} by Points${C_RST} ${C_DIM}($DATA_DIR)${C_RST}"
  echo "--------------------------------"
  # Resolve names for Top N only (to avoid API stress)
  idx=0
  while IFS=$'\t' read -r P U F; do
    idx=$((idx+1)); [ $idx -le $TOP_N ] || break
    # Try cache first, then one network chain if missing
    name="$(resolve_name_cached_only "$U")"
    [ -n "$name" ] || name="$(resolve_name_network_chain "$U")" || true
    if [ -n "$name" ]; then
      printf "%2d. %s\t— %s points\n" "$idx" "$name" "$P"
    else
      printf "%2d. %s\t— %s points\n" "$idx" "$U" "$P"
    fi
  done <<< "$RESULTS"
  exit 0
fi

# Default: single highest
read -r TOP_P TOP_U TOP_F <<EOF
$(printf "%s\n" "$RESULTS" | head -n1)
EOF

name="$(resolve_name_cached_only "$TOP_U")"
[ -n "$name" ] || name="$(resolve_name_network_chain "$TOP_U")" || true

if [ -n "$name" ]; then
  echo -e "${C_GRN}Highest:${C_RST} $name — $TOP_P points"
else
  echo -e "${C_GRN}Highest:${C_RST} $TOP_U — $TOP_P points"
fi
echo "File: $TOP_F"
