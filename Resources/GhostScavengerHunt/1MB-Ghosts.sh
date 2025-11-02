#!/usr/bin/env bash
# 1MB-Ghosts.sh (v16)
# - macOS Bash 3.2 compatible
# - Robust NAME<->UUID caching (uses canonical username from PlayerDB on lookup)
# - New: --cache-show <uuid|name>
set -euo pipefail

# Colors
use_color=0
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then use_color=1; fi
if [[ ${NO_COLOR:-} != "" ]]; then use_color=0; fi
if [[ $use_color -eq 1 ]]; then
  C_HI=$(tput bold); C_DIM=$(tput dim); C_RED=$(tput setaf 1); C_GRN=$(tput setaf 2); C_CYN=$(tput setaf 6); C_RST=$(tput sgr0)
else
  C_HI=""; C_DIM=""; C_RED=""; C_GRN=""; C_CYN=""; C_RST=""
fi

MODE=""; YAML="./data.yml"; WORLD="halloween"; NAME_LOOKUP=0
ZERO_UUID="00000000-0000-0000-0000-000000000000"

trim() { printf "%s" "$1" | awk '{gsub(/^[ \t\r\n]+|[ \t\r\n]+$/,""); print}'; }

if [[ $# -lt 1 ]]; then
  cat <<USAGE
Usage:
  $0 <uuid|playername> [data.yml] [--world <name>] [--name-lookup]
  $0 --player <uuid|playername> [data.yml] [--world <name>] [--name-lookup]
  $0 --ghost <ghost_uuid> [data.yml] [--world <name>] [--name-lookup]
  $0 --top[(:N|:all)] [data.yml] [--world <name>] [--name-lookup]
  $0 --list:N   or   -list:N
  $0 --stats [data.yml] [--world <name>]
  $0 --summary [data.yml] [--world <name>] [--name-lookup]
  $0 --cache-show <uuid|name>
USAGE
  exit 2
fi

# Parse args
TOP_ARG=""
GHOST_ARG=""
PLAYER_ARG=""
LIST_N=""
CACHE_SHOW=""
i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --name-lookup) NAME_LOOKUP=1; i=$((i+1));;
    --world) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --world requires a value." >&2; exit 2; }
             WORLD="${!j}"; i=$((i+2));;
    --world=*) WORLD="${arg#--world=}"; i=$((i+1));;
    --ghost) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --ghost requires a ghost UUID." >&2; exit 2; }
             MODE="--ghost"; GHOST_ARG="$(trim "${!j}")"; i=$((i+2));;
    --player) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --player requires a uuid or playername." >&2; exit 2; }
             MODE="--player"; PLAYER_ARG="$(trim "${!j}")"; i=$((i+2));;
    --top|--top:*)
             MODE="--top"; TOP_ARG="$arg"; i=$((i+1));;
    --list:*|-list:*)
             MODE="--list"; LIST_N="${arg#*:}"; i=$((i+1));;
    --stats) MODE="--stats"; i=$((i+1));;
    --summary) MODE="--summary"; i=$((i+1));;
    --cache-show) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --cache-show requires a value." >&2; exit 2; }
             MODE="--cache-show"; CACHE_SHOW="$(trim "${!j}")"; i=$((i+2));;
    -*)
      echo "Error: unexpected flag '$arg'." >&2; exit 2;;
    *)
      if [[ -z "$MODE" ]]; then MODE="$(trim "$arg")"
      elif [[ "$YAML" == "./data.yml" ]]; then YAML="$arg"
      else echo "Error: unexpected positional argument '$arg'." >&2; exit 2; fi
      i=$((i+1));;
  esac
done

[[ -f "$YAML" ]] || { echo "Error: data.yml not found at: $YAML" >&2; exit 3; }
WORLD_LC="$(printf "%s" "$WORLD" | tr '[:upper:]' '[:lower:]')"

# Cache
CACHE="$HOME/.1mb-namecache.tsv"
mkdir -p "$(dirname "$CACHE")" 2>/dev/null || true
touch "$CACHE" 2>/dev/null || true

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
CURL_BASE=(curl -sS -L --connect-timeout 2 --max-time 3 -A "$UA")

is_valid_name() { [[ "$1" =~ ^[A-Za-z0-9_]{3,16}$ ]]; }
normalize_uuid() {
  local raw="$1"
  local u
  u="$(printf "%s" "$raw" | tr -d '-' | tr '[:upper:]' '[:lower:]')"
  if [[ ${#u} -eq 32 ]]; then
    printf "%s-%s-%s-%s-%s" "${u:0:8}" "${u:8:4}" "${u:12:4}" "${u:16:4}" "${u:20:12}"
  else
    printf "%s" "$raw" | tr '[:upper:]' '[:lower:]'
  fi
}

# PlayerDB helpers (extract both uuid and canonical username from one request)
playerdb_fetch() {
  "${CURL_BASE[@]}" "https://playerdb.co/api/player/minecraft/$1" || true
}
playerdb_uuid_from_json() { sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1; }
playerdb_name_from_json() { sed -n 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1; }

parse_og_title() { sed -n 's/.*property="og:title" content="\([^"]*\)".*/\1/p' | head -1 | sed 's/ - .*$//' | awk '{print $1}'; }
lookup_namemc_name_by_uuid() { local html name; html="$("${CURL_BASE[@]}" "https://namemc.com/profile/$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; if is_valid_name "$name"; then echo "$name"; return 0; fi; return 1; }
lookup_laby_name_by_uuid() { local html name; html="$("${CURL_BASE[@]}" "https://laby.net/@$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; if is_valid_name "$name"; then echo "$name"; return 0; fi; return 1; }
lookup_crafty_name_by_uuid() { local html name; html="$("${CURL_BASE[@]}" "https://crafty.gg/@$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; if is_valid_name "$name"; then echo "$name"; return 0; fi; return 1; }

cache_put() {
  local uuid name
  uuid="$(normalize_uuid "$1")"; name="$2"
  awk -v U="$uuid" -F'\t' 'tolower($1)!=tolower(U){print $0}' "$CACHE" > "$CACHE.tmp" 2>/dev/null || true
  printf "%s\t%s\n" "$uuid" "$name" >> "$CACHE.tmp"
  mv "$CACHE.tmp" "$CACHE"
}
cache_get_name() { awk -v U="$(normalize_uuid "$1")" -F'\t' 'tolower($1)==tolower(U){print $2; exit 0} END{exit 1}' "$CACHE"; }
cache_get_uuid_by_name() { awk -v N="$1" -F'\t' 'tolower($2)==tolower(N){print $1; exit 0} END{exit 1}' "$CACHE"; }

resolve_name_cached_only() { local uuid; uuid="$(normalize_uuid "$1")"; [[ "$uuid" == "$ZERO_UUID" ]] && echo "" && return 0; if name="$(cache_get_name "$uuid" 2>/dev/null)"; then echo "$name"; return 0; fi; echo ""; }
resolve_name_network_chain() {
  local uuid name
  uuid="$(normalize_uuid "$1")"; [[ "$uuid" == "$ZERO_UUID" ]] && echo "" && return 0
  if name="$(cache_get_name "$uuid" 2>/dev/null)"; then echo "$name"; return 0; fi
  name="$(lookup_namemc_name_by_uuid "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  name="$(lookup_laby_name_by_uuid "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  name="$(lookup_crafty_name_by_uuid "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  echo ""
}

# Resolve token to UUID; when NAME_LOOKUP is set and a name is used, fetch both uuid and canonical username and cache
resolve_token_to_uuid() {
  local tok uid json canon
  tok="$(trim "$1")"
  if [[ "$tok" =~ ^[0-9A-Fa-f-]{32,36}$ ]]; then
    echo "$(normalize_uuid "$tok")"; return 0
  fi
  if uid="$(cache_get_uuid_by_name "$tok" 2>/dev/null)"; then
    echo "$(normalize_uuid "$uid")"; return 0
  fi
  if [[ $NAME_LOOKUP -eq 1 ]]; then
    json="$(playerdb_fetch "$tok")"
    uid="$(printf "%s" "$json" | playerdb_uuid_from_json | head -1)"
    canon="$(printf "%s" "$json" | playerdb_name_from_json | head -1)"
    uid="$(normalize_uuid "$uid")"
    if [[ "$uid" =~ ^[0-9A-Fa-f-]{36}$ && -n "$canon" ]]; then
      cache_put "$uid" "$canon"
      echo "$uid"; return 0
    fi
  fi
  return 1
}

# YAML → temp TSVs via AWK one-pass
TMPDIR="${TMPDIR:-/tmp}"
WORLD_GHOSTS="$(mktemp "$TMPDIR/world_ghosts.XXXXXX")"   # ghost_id\tworld\tx\ty\tz
COUNTS_UUID="$(mktemp "$TMPDIR/counts_uuid.XXXXXX")"     # uuid\tcount
COUNTS_GHOST="$(mktemp "$TMPDIR/counts_ghost.XXXXXX")"   # ghost\tcount
UUID_LIST="$(mktemp "$TMPDIR/uuid_list.XXXXXX")"         # uuid
CLAIMS_FILE="$(mktemp "$TMPDIR/claims.XXXXXX")"          # uuid\tghost
trap 'rm -f "$WORLD_GHOSTS" "$COUNTS_UUID" "$COUNTS_GHOST" "$UUID_LIST" "$CLAIMS_FILE" 2>/dev/null || true' EXIT

awk -v WL="$(printf "%s" "$WORLD" | tr "[:upper:]" "[:lower:]")" -v ZERO="$ZERO_UUID" -v OUT_W="$WORLD_GHOSTS" -v OUT_U="$COUNTS_UUID" -v OUT_G="$COUNTS_GHOST" -v OUT_L="$UUID_LIST" -v OUT_C="$CLAIMS_FILE" '
  function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
  BEGIN{ cur=""; in_claim=0 }
  /^[0-9a-fA-F-]{36}:[[:space:]]*$/ { cur=$0; sub(/:.*/,"",cur); in_claim=0; next }
  /^[[:space:]]+location:[[:space:]]*/{
    loc=$0; sub(/^[[:space:]]+location:[[:space:]]*/,"",loc)
    split(loc, p, "@")
    w=tolower(trim(p[1])); x=p[2]; y=p[3]; z=p[4]
    sub(/\..*$/,"",x); sub(/\..*$/,"",y); sub(/\..*$/,"",z)
    g_w[cur]=w; g_wo[cur]=trim(p[1]); g_x[cur]=x; g_y[cur]=y; g_z[cur]=z
    next
  }
  /^[[:space:]]+claimed:[[:space:]]*$/ { in_claim=1; next }
  /^[[:space:]]+-[[:space:]]+[0-9a-fA-F-]{36}[[:space:]]*$/ {
    if(in_claim && cur!=""){
      u=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",u)
      if(u!=ZERO){ seen[u]=1; has[u SUBSEP cur]=1; print u "\t" cur > OUT_C }
    }
    next
  }
  /^[^[:space:]-]/ { in_claim=0 }
  END{
    total=0
    for(g in g_w){
      if(g_w[g]==WL){
        print g "\t" g_wo[g] "\t" g_x[g] "\t" g_y[g] "\t" g_z[g] > OUT_W
        ghosts[g]=1; total++
      }
    }
    for(g in ghosts){
      cntg=0
      for(u in seen){ if((u SUBSEP g) in has){ cntg++ } }
      print g "\t" cntg > OUT_G
    }
    for(u in seen){
      cntu=0
      for(g in ghosts){ if((u SUBSEP g) in has){ cntu++ } }
      print u "\t" cntu > OUT_U
      print u > OUT_L
    }
  }
' "$YAML"

TOTAL=$(wc -l < "$WORLD_GHOSTS" | tr -d '[:space:]')

# Helpers
label_uuid_cache_only() {
  local u n
  u="$(normalize_uuid "$1")"
  n="$(resolve_name_cached_only "$u")"
  if [[ -n "$n" ]]; then printf "%s (%s)" "$n" "$u"; else printf "%s" "$u"; fi
}

# -------- Modes --------

if [[ "$MODE" == "--cache-show" ]]; then
  KEY="$CACHE_SHOW"
  if [[ "$KEY" =~ ^[0-9A-Fa-f-]{32,36}$ ]]; then
    KEY="$(normalize_uuid "$KEY")"
    printf "%s\n" "$(awk -v U="$KEY" -F'\t' 'tolower($1)==tolower(U){print $0}' "$CACHE")"
  else
    printf "%s\n" "$(awk -v N="$KEY" -F'\t' 'tolower($2)==tolower(N){print $0}' "$CACHE")"
  fi
  exit 0
fi

if [[ "$MODE" == "--stats" ]]; then
  UNIQUE=$(wc -l < "$UUID_LIST" | tr -d '[:space:]')
  ALLCNT=$(awk -v T="$TOTAL" '$2==T{c++} END{print c+0}' "$COUNTS_UUID")
  GTE40=$(awk '$2>=40{c++} END{print c+0}' "$COUNTS_UUID")
  AVG=$(awk '{sum+=$2; n++} END{ if(n>0) printf "%.1f", (sum/n); else print "0.0"}' "$COUNTS_UUID")

  MINREC=$(awk 'NR==1{min=$2} $2<min{min=$2} END{print (min==""?0:min)}' "$COUNTS_GHOST")
  MAXREC=$(awk 'NR==1{max=$2} $2>max{max=$2} END{print (max==""?0:max)}' "$COUNTS_GHOST")
  LGHOST=$(awk -v M="$MINREC" '$2==M{print $1; exit}' "$COUNTS_GHOST")
  MGHOST=$(awk -v M="$MAXREC" '$2==M{print $1; exit}' "$COUNTS_GHOST")
  read -r l_w l_x l_y l_z <<<"$(awk -v G="$LGHOST" -F'\t' '$1==G{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"
  read -r m_w m_x m_y m_z <<<"$(awk -v G="$MGHOST" -F'\t' '$1==G{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"

  echo -e "${C_HI}${C_CYN}Ghost Hunt Statistics${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"
  echo "• Total ghosts: $TOTAL"
  echo "• Total unique players: $UNIQUE"
  echo "• Players with all ghosts: $ALLCNT"
  echo "• Players with ≥ 40 ghosts: $GTE40"
  echo "• Average ghosts found: $AVG"
  if [[ -n "$MGHOST" ]]; then
    echo "• Most found ghost: $MGHOST"
    echo "  (/tppos $m_x $m_y $m_z $m_w) — found by $MAXREC player(s)"
  fi
  if [[ -n "$LGHOST" ]]; then
    echo "• Least found ghost: $LGHOST"
    echo "  (/tppos $l_x $l_y $l_z $l_w) — found by $MINREC player(s)"
  fi
  exit 0
fi

if [[ "$MODE" == "--top" ]]; then
  LIMIT="$TOTAL"
  if [[ "$TOP_ARG" =~ ^--top:([0-9]+)$ ]]; then
    LIMIT="${BASH_REMATCH[1]}"
  elif [[ "$TOP_ARG" == "--top:all" || -z "$TOP_ARG" || "$TOP_ARG" == "--top" ]]; then
    LIMIT="all"
  fi

  echo -e "${C_HI}${C_CYN}Top Players${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"

  SORTED="$(mktemp "$TMPDIR/sorted.XXXXXX")"
  LC_ALL=C sort -t$'\t' -k2,2nr -k1,1 "$COUNTS_UUID" > "$SORTED"

  MAX_ONLINE_LOOKUPS=0
  if [[ $NAME_LOOKUP -eq 1 ]]; then
    if [[ "$LIMIT" == "all" ]]; then MAX_ONLINE_LOOKUPS=10; else MAX_ONLINE_LOOKUPS="$LIMIT"; fi
  fi

  UNKNOWN_DONE=0
  RANK=0
  while IFS=$'\t' read -r U C; do
    RANK=$((RANK+1))
    if [[ "$LIMIT" != "all" && $RANK -gt $LIMIT ]]; then break; fi

    NAME="$(resolve_name_cached_only "$U")"
    if [[ -z "$NAME" && $UNKNOWN_DONE -lt $MAX_ONLINE_LOOKUPS ]]; then
      # Try PlayerDB once here for convenience
      json="$(playerdb_fetch "$U")"
      canon="$(printf "%s" "$json" | playerdb_name_from_json | head -1)"
      if is_valid_name "$canon"; then cache_put "$U" "$canon"; NAME="$canon"; UNKNOWN_DONE=$((UNKNOWN_DONE+1)); fi
    fi

    if [[ -n "$NAME" ]]; then
      printf "%d. %s\t– %d/%d ghosts\n" "$RANK" "$NAME" "$C" "$TOTAL"
    else
      printf "%d. %s\t– %d/%d ghosts\n" "$RANK" "$U" "$C" "$TOTAL"
    fi
  done < "$SORTED"

  AVG=$(awk '{sum+=$2; n++} END{ if(n>0) printf "%.1f", (sum/n); else print "0.0"}' "$COUNTS_UUID")
  echo "-----------------------------------------------"
  echo -e "${C_DIM}Average completion: ${AVG} ghosts per player${C_RST}"
  exit 0
fi

if [[ "$MODE" == "--list" ]]; then
  [[ -n "$LIST_N" ]] || { echo "Error: --list:N expects a number."; exit 2; }
  if ! [[ "$LIST_N" =~ ^[0-9]+$ ]]; then echo "Error: --list:N expects a number."; exit 2; fi
  if (( LIST_N < 0 )); then echo "Error: --list:N must be >= 0"; exit 2; fi

  echo -e "${C_HI}${C_CYN}Players with ${LIST_N} ghosts${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"

  GSET="$(mktemp "$TMPDIR/gset.XXXXXX")"
  awk -F'\t' '{print $1}' "$WORLD_GHOSTS" > "$GSET"

  while IFS=$'\t' read -r U C; do
    if (( C == LIST_N )); then
      NAME="$(resolve_name_cached_only "$U")"
      if [[ -z "$NAME" && $NAME_LOOKUP -eq 1 ]]; then
        json="$(playerdb_fetch "$U")"
        canon="$(printf "%s" "$json" | playerdb_name_from_json | head -1)"
        if is_valid_name "$canon"; then cache_put "$U" "$canon"; NAME="$canon"; fi
      fi
      if [[ -n "$NAME" ]]; then printf "%s%s (%s)%s\n" "$C_HI" "$NAME" "$U" "$C_RST"
      else                     printf "%s%s%s\n" "$C_HI" "$U" "$C_RST"; fi

      while read -r G; do
        if ! grep -q -E "^${U}[[:space:]]+${G}$" "$CLAIMS_FILE"; then
          read -r _gw _gx _gy _gz <<<"$(awk -v GG="$G" -F'\t' '$1==GG{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"
          printf "  %smissing ghost %-36s%s -> %s/tppos %s %s %s %s%s\n" "$C_DIM" "$G" "$C_RST" "$C_GRN" "$_gx" "$_gy" "$_gz" "$_gw" "$C_RST"
        fi
      done < "$GSET"
      echo ""
    fi
  done < "$COUNTS_UUID"
  exit 0
fi

if [[ "$MODE" == "--ghost" ]]; then
  GID="$(normalize_uuid "$GHOST_ARG")"
  if ! [[ "$GID" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    echo "Error: --ghost expects a ghost UUID." >&2
    exit 2
  fi
  echo -e "${C_HI}${C_CYN}Players who found ghost ${GID}${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"
  TMPU="$(mktemp "$TMPDIR/gh.XXXXXX")"
  awk -v G="$GID" -v WL="$(printf "%s" "$WORLD" | tr "[:upper:]" "[:lower:]")" -v ZERO="$ZERO_UUID" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    BEGIN{ cur=""; in_claim=0; cur_w="" }
    /^[0-9a-fA-F-]{36}:[[:space:]]*$/ { cur=$0; sub(/:.*/,"",cur); in_claim=0; next }
    /^[[:space:]]+location:/{
      loc=$0; sub(/^[[:space:]]+location:[[:space:]]*/,"",loc)
      split(loc,p,"@"); w=tolower(trim(p[1])); cur_w=w; next
    }
    /^[[:space:]]+claimed:[[:space:]]*$/ { in_claim=1; next }
    /^[[:space:]]+-[[:space:]]+[0-9a-fA-F-]{36}[[:space:]]*$/ {
      if(in_claim && cur==G && cur_w==WL){
        u=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",u); if(u!="'$ZERO_UUID'") print u
      }
      next
    }
    /^[^[:space:]-]/ { in_claim=0 }
  ' "$YAML" | LC_ALL=C sort -u > "$TMPU"
  COUNT=$(wc -l < "$TMPU" | tr -d '[:space:]')
  if [[ "$COUNT" -eq 0 ]]; then echo "No players found this ghost yet."; exit 0; fi
  N=0
  while IFS= read -r U; do
    N=$((N+1)); NAME="$(resolve_name_cached_only "$U")"
    if [[ -n "$NAME" ]]; then printf "%d. %s (%s)\n" "$N" "$NAME" "$U"; else printf "%d. %s\n" "$N" "$U"; fi
  done < "$TMPU"
  exit 0
fi

if [[ "$MODE" == "--summary" ]]; then
  OUTFILE="./ghost-event-summary.md"
  UNIQUE=$(wc -l < "$UUID_LIST" | tr -d '[:space:]')
  ALLCNT=$(awk -v T="$TOTAL" '$2==T{c++} END{print c+0}' "$COUNTS_UUID")
  GTE40=$(awk '$2>=40{c++} END{print c+0}' "$COUNTS_UUID")
  AVG=$(awk '{sum+=$2; n++} END{ if(n>0) printf "%.1f", (sum/n); else print "0.0"}' "$COUNTS_UUID")
  MINREC=$(awk 'NR==1{min=$2} $2<min{min=$2} END{print (min==""?0:min)}' "$COUNTS_GHOST")
  MAXREC=$(awk 'NR==1{max=$2} $2>max{max=$2} END{print (max==""?0:max)}' "$COUNTS_GHOST")
  LGHOST=$(awk -v M="$MINREC" '$2==M{print $1; exit}' "$COUNTS_GHOST")
  MGHOST=$(awk -v M="$MAXREC" '$2==M{print $1; exit}' "$COUNTS_GHOST")
  read -r l_w l_x l_y l_z <<<"$(awk -v G="$LGHOST" -F'\t' '$1==G{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"
  read -r m_w m_x m_y m_z <<<"$(awk -v G="$MGHOST" -F'\t' '$1==G{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"

  SORTED="$(mktemp "$TMPDIR/sorted.XXXXXX")"
  LC_ALL=C sort -t$'\t' -k2,2nr -k1,1 "$COUNTS_UUID" > "$SORTED"

  # Optionally resolve Top 10 names prior to writing
  if [[ $NAME_LOOKUP -eq 1 ]]; then
    R=0
    while IFS=$'\t' read -r U C; do
      R=$((R+1)); [[ $R -le 10 ]] || break
      NAME="$(resolve_name_cached_only "$U")"
      if [[ -z "$NAME" ]]; then
        json="$(playerdb_fetch "$U")"
        canon="$(printf "%s" "$json" | playerdb_name_from_json | head -1)"
        if is_valid_name "$canon"; then cache_put "$U" "$canon"; fi
      fi
    done < "$SORTED"
  fi

  TOP_LINES=""; RANK=0
  while IFS=$'\t' read -r U C; do
    RANK=$((RANK+1)); [[ $RANK -le 10 ]] || break
    NAME="$(resolve_name_cached_only "$U")"
    if [[ -n "$NAME" ]]; then TOP_LINES+="$RANK. $NAME — $C/$TOTAL ghosts"$'\n'
    else TOP_LINES+="$RANK. $U — $C/$TOTAL ghosts"$'\n'; fi
  done < "$SORTED"

  {
    echo "# Ghost Hunt Summary (${WORLD})"
    echo
    echo "- **Total ghosts:** $TOTAL"
    echo "- **Total unique players:** $UNIQUE"
    echo "- **Players with all ghosts:** $ALLCNT"
    echo "- **Players with ≥ 40 ghosts:** $GTE40"
    echo "- **Average ghosts found:** $AVG"
    if [[ -n "$MGHOST" ]]; then
      echo "- **Most found ghost:** \`$MGHOST\` — found by $MAXREC player(s)"
      echo "  - Teleport: \`/tppos $m_x $m_y $m_z $m_w\`"
    fi
    if [[ -n "$LGHOST" ]]; then
      echo "- **Least found ghost:** \`$LGHOST\` — found by $MINREC player(s)"
      echo "  - Teleport: \`/tppos $l_x $l_y $l_z $l_w\`"
    fi
    echo
    echo "## Top 10 Players"
    echo '```'
    printf "%s" "$TOP_LINES"
    echo '```'
  } > "$OUTFILE"

  echo -e "${C_GRN}Wrote summary:${C_RST} ${OUTFILE}"
  exit 0
fi

# Default / --player mode
TOKEN="$MODE"
if [[ "$MODE" == "--player" ]]; then TOKEN="$PLAYER_ARG"; fi
if ! UUID="$(resolve_token_to_uuid "$TOKEN")"; then
  echo "Error: '$TOKEN' is not a UUID and not found in cache. Add --name-lookup once to cache it."
  exit 2
fi

# Per-UUID report (header uses cache name if present)
NAMEHDR="$(resolve_name_cached_only "$UUID")"
if [[ -n "$NAMEHDR" ]]; then
  HDR="${NAMEHDR} (${UUID})"
else
  HDR="${UUID}"
fi

awk -v U="$(normalize_uuid "$UUID")" -v WL="$(printf "%s" "$WORLD" | tr "[:upper:]" "[:lower:]")" -v WORLD="$WORLD" \
    -v HI="$C_HI" -v DIM="$C_DIM" -v GRN="$C_GRN" -v CYN="$C_CYN" -v RST="$C_RST" -v HDR="$HDR" '
  function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
  BEGIN{ cur=""; in_claim=0 }
  /^[0-9a-fA-F-]{36}:[[:space:]]*$/ { cur=$0; sub(/:.*/,"",cur); in_claim=0; next }
  /^[[:space:]]+location:[[:space:]]*/{
    loc=$0; sub(/^[[:space:]]+location:[[:space:]]*/,"",loc)
    split(loc, p, "@")
    w=tolower(trim(p[1])); x=p[2]; y=p[3]; z=p[4]
    sub(/\..*$/,"",x); sub(/\..*$/,"",y); sub(/\..*$/,"",z)
    g_w[cur]=w; g_wo[cur]=trim(p[1]); g_x[cur]=x; g_y[cur]=y; g_z[cur]=z
    next
  }
  /^[[:space:]]+claimed:[[:space:]]*$/ { in_claim=1; next }
  /^[[:space:]]+-[[:space:]]+[0-9a-fA-F-]{36}[[:space:]]*$/ {
    if(in_claim && cur!=""){
      uuid=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",uuid);
      if(uuid==U){ has[cur]=1 }
    }
    next
  }
  /^[^[:space:]-]/ { in_claim=0 }
  END{
    total=0; have=0
    for(g in g_w){
      if(g_w[g]==WL){
        total++
        if(g in has) have++
      }
    }
    printf("%s%sMissing ghosts for %s%s %s(world: %s)%s\n", HI,CYN,HDR,RST,DIM,WORLD,RST)
    print "-----------------------------------------------"
    if(have==total){
      printf("%sThis UUID has all %d ghosts.%s\n", GRN, total, RST); exit 0
    }
    for(g in g_w){
      if(g_w[g]==WL && !(g in has)){
        printf("ghost %-36s -> /tppos %s %s %s %s\n", g, g_x[g], g_y[g], g_z[g], g_wo[g])
      }
    }
    print ""
    printf("%sUUID has %d of %d ghosts (%d missing).%s\n", DIM, have, total, total-have, RST)
  }
' "$YAML"
