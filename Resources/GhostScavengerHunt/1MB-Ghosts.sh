#!/usr/bin/env bash
# 1MB-Ghosts.sh (v12)
# Features
# - YAML→AWK core (BSD awk compatible)
# - Per-UUID report (positional <uuid|name>), cache-only name resolution by default
# - --player <uuid|name>  (equivalent to positional)
# - --ghost <ghost_uuid>  (list players who found that ghost)
# - --top, --top:N, --top:all (leaderboard). With --name-lookup: ONLY look up first 5 missing names.
# - --stats (global stats)
# - --summary (writes ./ghost-event-summer.md with stats + top 10)
# - --world <name> (default: halloween)
# - --name-lookup (enables network lookups per strategy above; otherwise cache-only)
# - Persistent cache at ~/.1mb-namecache.tsv (uuid<TAB>name)
# - Ignores ZERO UUID 00000000-0000-0000-0000-000000000000
#
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

if [[ $# -lt 1 ]]; then
  echo "Usage:"
  echo "  $0 <uuid|playername> [data.yml] [--world <name>] [--name-lookup]"
  echo "  $0 --player <uuid|playername> [data.yml] [--world <name>] [--name-lookup]"
  echo "  $0 --ghost <ghost_uuid> [data.yml] [--world <name>] [--name-lookup]"
  echo "  $0 --top[(:N|:all)] [data.yml] [--world <name>] [--name-lookup]"
  echo "  $0 --stats [data.yml] [--world <name>]"
  echo "  $0 --summary [data.yml] [--world <name>]"
  exit 2
fi

# Args
TOP_ARG=""
GHOST_ARG=""
PLAYER_ARG=""
i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --name-lookup) NAME_LOOKUP=1; i=$((i+1));;
    --world) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --world requires a value." >&2; exit 2; }
             WORLD="${!j}"; i=$((i+2));;
    --world=*) WORLD="${arg#--world=}"; i=$((i+1));;
    --ghost) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --ghost requires a ghost UUID." >&2; exit 2; }
             MODE="--ghost"; GHOST_ARG="${!j}"; i=$((i+2));;
    --player) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --player requires a uuid or playername." >&2; exit 2; }
             MODE="--player"; PLAYER_ARG="${!j}"; i=$((i+2));;
    --top|--top:*)
             MODE="--top"; TOP_ARG="$arg"; i=$((i+1));;
    --stats) MODE="--stats"; i=$((i+1));;
    --summary) MODE="--summary"; i=$((i+1));;
    -*)
      echo "Error: unexpected flag '$arg'." >&2; exit 2;;
    *)
      if [[ -z "$MODE" ]]; then MODE="$arg"
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

lookup_playerdb() {
  local json name
  json="$("${CURL_BASE[@]}" "https://playerdb.co/api/player/minecraft/$1" || true)"
  name="$(printf "%s" "$json" | sed -n 's/.*\"username\"[[:space:]]*:[[:space:]]*\"\([^"]*\)\".*/\1/p' | head -1)"
  if is_valid_name "$name"; then echo "$name"; return 0; fi
  return 1
}
parse_og_title() { sed -n 's/.*property="og:title" content="\([^"]*\)".*/\1/p' | head -1 | sed 's/ - .*$//' | awk "{print \$1}"; }
lookup_namemc() { local html name; html="$("${CURL_BASE[@]}" "https://namemc.com/profile/$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; if is_valid_name "$name"; then echo "$name"; return 0; fi; return 1; }
lookup_laby() { local html name; html="$("${CURL_BASE[@]}" "https://laby.net/@$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; if is_valid_name "$name"; then echo "$name"; return 0; fi; return 1; }
lookup_crafty() { local html name; html="$("${CURL_BASE[@]}" "https://crafty.gg/@$1" || true)"; name="$(printf "%s" "$html" | parse_og_title)"; if is_valid_name "$name"; then echo "$name"; return 0; fi; return 1; }

cache_get_name() { awk -v U="$1" -F'\t' 'tolower($1)==tolower(U){print $2; exit 0} END{exit 1}' "$CACHE"; }
cache_get_uuid_by_name() { awk -v N="$1" -F'\t' 'tolower($2)==tolower(N){print $1; exit 0} END{exit 1}' "$CACHE"; }
cache_put() {
  local uuid="$1" name="$2"
  grep -vi "^$uuid\t" "$CACHE" > "$CACHE.tmp" 2>/dev/null || true
  printf "%s\t%s\n" "$uuid" "$name" >> "$CACHE.tmp"
  mv "$CACHE.tmp" "$CACHE"
}

resolve_name_cached_only() {
  local uuid="$1" name=""
  [[ "$uuid" == "$ZERO_UUID" ]] && echo "" && return 0
  if name="$(cache_get_name "$uuid" 2>/dev/null)"; then echo "$name"; return 0; fi
  echo ""
}

resolve_name_network_chain() {
  local uuid="$1" name=""
  [[ "$uuid" == "$ZERO_UUID" ]] && echo "" && return 0
  if name="$(cache_get_name "$uuid" 2>/dev/null)"; then echo "$name"; return 0; fi
  name="$(lookup_playerdb "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  name="$(lookup_namemc "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  name="$(lookup_laby "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  name="$(lookup_crafty "$uuid" || true)"; if is_valid_name "$name"; then cache_put "$uuid" "$name"; echo "$name"; return 0; fi
  echo ""
}

# YAML → temp TSVs via AWK one-pass
TMPDIR="${TMPDIR:-/tmp}"
WORLD_GHOSTS="$(mktemp "$TMPDIR/world_ghosts.XXXXXX")"   # ghost_id\tworld\tx\ty\tz
COUNTS_UUID="$(mktemp "$TMPDIR/counts_uuid.XXXXXX")"     # uuid\tcount
COUNTS_GHOST="$(mktemp "$TMPDIR/counts_ghost.XXXXXX")"   # ghost\tcount
UUID_LIST="$(mktemp "$TMPDIR/uuid_list.XXXXXX")"         # uuid
trap 'rm -f "$WORLD_GHOSTS" "$COUNTS_UUID" "$COUNTS_GHOST" "$UUID_LIST" 2>/dev/null || true' EXIT

awk -v WL="$WORLD_LC" -v ZERO="$ZERO_UUID" -v OUT_W="$WORLD_GHOSTS" -v OUT_U="$COUNTS_UUID" -v OUT_G="$COUNTS_GHOST" -v OUT_L="$UUID_LIST" '
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
      if(u!=ZERO){ seen[u]=1; has[u SUBSEP cur]=1 }
    }
    next
  }
  /^[^[:space:]-]/ { in_claim=0 }
  END{
    # emit world ghosts
    total=0
    for(g in g_w){
      if(g_w[g]==WL){
        print g "\t" g_wo[g] "\t" g_x[g] "\t" g_y[g] "\t" g_z[g] > OUT_W
        ghosts[g]=1; total++
      }
    }
    # count per uuid within world, and per ghost
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
    # also expose total via /dev/stderr line (captured in shell if needed)
    # but we wont parse stderr now; we can recompute as wc -l on OUT_W
  }
' "$YAML"

TOTAL=$(wc -l < "$WORLD_GHOSTS" | tr -d '[:space:]')

# Helpers
label_uuid_cache_only() {
  local u="$1" n
  n="$(resolve_name_cached_only "$u")"
  if [[ -n "$n" ]]; then printf "%s (%s)" "$n" "$u"; else printf "%s" "$u"; fi
}
label_uuid_network_if_allowed() {
  local u="$1" n
  if [[ $NAME_LOOKUP -eq 1 ]]; then
    n="$(resolve_name_network_chain "$u")"
  else
    n="$(resolve_name_cached_only "$u")"
  fi
  if [[ -n "$n" ]]; then printf "%s (%s)" "$n" "$u"; else printf "%s" "$u"; fi
}

# Resolve name or UUID from cache for user-provided <uuid|name> tokens
resolve_token_to_uuid_cache_only() {
  local tok="$1"
  if [[ "$tok" =~ ^[0-9a-fA-F-]{36}$ ]]; then echo "$tok"; return 0; fi
  # try name -> uuid via cache
  local uid
  if uid="$(cache_get_uuid_by_name "$tok" 2>/dev/null)"; then echo "$uid"; return 0; fi
  return 1
}

# -------- Modes --------

if [[ "$MODE" == "--stats" ]]; then
  # totals
  UNIQUE=$(wc -l < "$UUID_LIST" | tr -d '[:space:]')
  ALLCNT=$(awk -v T="$TOTAL" '$2==T{c++} END{print c+0}' "$COUNTS_UUID")
  GTE40=$(awk '$2>=40{c++} END{print c+0}' "$COUNTS_UUID")
  AVG=$(awk '{sum+=$2; n++} END{ if(n>0) printf "%.1f", (sum/n); else print "0.0"}' "$COUNTS_UUID")
  # least found ghost
  # get min count, then pick first with that min
  MINREC=$(awk 'NR==1{min=$2} $2<min{min=$2} END{print (min==""?0:min)}' "$COUNTS_GHOST")
  LGHOST=$(awk -v M="$MINREC" '$2==M{print $1; exit}' "$COUNTS_GHOST")
  # coords
  read -r _w _x _y _z <<<"$(awk -v G="$LGHOST" -F'\t' '$1==G{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"

  echo -e "${C_HI}${C_CYN}Ghost Hunt Statistics${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"
  echo "• Total ghosts: $TOTAL"
  echo "• Total unique players: $UNIQUE"
  echo "• Players with all ghosts: $ALLCNT"
  echo "• Players with ≥ 40 ghosts: $GTE40"
  echo "• Average ghosts found: $AVG"
  if [[ -n "$LGHOST" ]]; then
    echo "• Least found ghost: $LGHOST"
    echo "  (/tppos $_x $_y $_z $_w) — found by $MINREC player(s)"
  fi
  exit 0
fi

if [[ "$MODE" == "--top" ]]; then
  LIMIT="$TOTAL" # default show all
  if [[ "$TOP_ARG" =~ ^--top:([0-9]+)$ ]]; then
    LIMIT="${BASH_REMATCH[1]}"
  elif [[ "$TOP_ARG" == "--top:all" || -z "$TOP_ARG" || "$TOP_ARG" == "--top" ]]; then
    LIMIT="all"
  fi

  echo -e "${C_HI}${C_CYN}Top Players${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"

  # Sort counts desc and print
  # Format: rank. label – X/TOTAL ghosts
  # Use cache-only for names. If --name-lookup is set, fill in at most first 5 unknowns.
  # Build sorted list
  SORTED="$(mktemp "$TMPDIR/sorted.XXXXXX")"
  LC_ALL=C sort -t$'\t' -k2,2nr -k1,1 "$COUNTS_UUID" > "$SORTED"

  # collect first N unknowns to lookup if requested
  UNKNOWN_DONE=0
  MAX_ONLINE_LOOKUPS=5
  RANK=0
  while IFS=$'\t' read -r U C; do
    RANK=$((RANK+1))
    if [[ "$LIMIT" != "all" && $RANK -gt $LIMIT ]]; then break; fi

    NAME="$(resolve_name_cached_only "$U")"
    if [[ -z "$NAME" && $NAME_LOOKUP -eq 1 && $UNKNOWN_DONE -lt $MAX_ONLINE_LOOKUPS ]]; then
      NAME="$(resolve_name_network_chain "$U")"
      if [[ -n "$NAME" ]]; then UNKNOWN_DONE=$((UNKNOWN_DONE+1)); fi
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

if [[ "$MODE" == "--ghost" ]]; then
  GID="$GHOST_ARG"
  if ! [[ "$GID" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    echo "Error: --ghost expects a ghost UUID." >&2
    exit 2
  fi

  echo -e "${C_HI}${C_CYN}Players who found ghost ${GID}${C_RST} ${C_DIM}(world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"

  # Find all uuids whose count includes this ghost
  # Build set of uuids who have this ghost
  TMPU="$(mktemp "$TMPDIR/gh.XXXXXX")"
  awk -v G="$GID" -v WL="$WORLD_LC" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    BEGIN{ cur=""; in_claim=0 }
    /^[0-9a-fA-F-]{36}:[[:space:]]*$/ { cur=$0; sub(/:.*/,"",cur); in_claim=0; next }
    /^[[:space:]]+location:/{
      loc=$0; sub(/^[[:space:]]+location:[[:space:]]*/,"",loc)
      split(loc,p,"@"); w=tolower(trim(p[1])); cur_w=w; next
    }
    /^[[:space:]]+claimed:[[:space:]]*$/ { in_claim=1; next }
    /^[[:space:]]+-[[:space:]]+[0-9a-fA-F-]{36}[[:space:]]*$/ {
      if(in_claim && cur==G && cur_w==WL){
        u=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",u);
        if(u!="'$ZERO_UUID'") print u
      }
      next
    }
    /^[^[:space:]-]/ { in_claim=0 }
  ' "$YAML" | LC_ALL=C sort -u > "$TMPU"

  COUNT=$(wc -l < "$TMPU" | tr -d '[:space:]')
  if [[ "$COUNT" -eq 0 ]]; then
    echo "No players found this ghost yet."
    exit 0
  fi

  N=0
  while IFS= read -r U; do
    N=$((N+1))
    NAME="$(resolve_name_cached_only "$U")"
    if [[ -n "$NAME" ]]; then
      printf "%d. %s (%s)\n" "$N" "$NAME" "$U"
    else
      printf "%d. %s\n" "$N" "$U"
    fi
  done < "$TMPU"
  exit 0
fi

if [[ "$MODE" == "--summary" ]]; then
  OUTFILE="./ghost-event-summer.md"
  UNIQUE=$(wc -l < "$UUID_LIST" | tr -d '[:space:]')
  ALLCNT=$(awk -v T="$TOTAL" '$2==T{c++} END{print c+0}' "$COUNTS_UUID")
  GTE40=$(awk '$2>=40{c++} END{print c+0}' "$COUNTS_UUID")
  AVG=$(awk '{sum+=$2; n++} END{ if(n>0) printf "%.1f", (sum/n); else print "0.0"}' "$COUNTS_UUID")

  # least found ghost
  MINREC=$(awk 'NR==1{min=$2} $2<min{min=$2} END{print (min==""?0:min)}' "$COUNTS_GHOST")
  LGHOST=$(awk -v M="$MINREC" '$2==M{print $1; exit}' "$COUNTS_GHOST")
  read -r _w _x _y _z <<<"$(awk -v G="$LGHOST" -F'\t' '$1==G{print $2" "$3" "$4" "$5; exit}' "$WORLD_GHOSTS")"

  # build top 10 lines
  SORTED="$(mktemp "$TMPDIR/sorted.XXXXXX")"
  LC_ALL=C sort -t$'\t' -k2,2nr -k1,1 "$COUNTS_UUID" > "$SORTED"
  TOP_LINES=""
  RANK=0
  while IFS=$'\t' read -r U C; do
    RANK=$((RANK+1)); [[ $RANK -le 10 ]] || break
    NAME="$(resolve_name_cached_only "$U")"
    if [[ -n "$NAME" ]]; then
      TOP_LINES+="$RANK. $NAME — $C/$TOTAL ghosts"$'\n'
    else
      TOP_LINES+="$RANK. $U — $C/$TOTAL ghosts"$'\n'
    fi
  done < "$SORTED"

  {
    echo "# Ghost Hunt Summary (${WORLD})"
    echo
    echo "- **Total ghosts:** $TOTAL"
    echo "- **Total unique players:** $UNIQUE"
    echo "- **Players with all ghosts:** $ALLCNT"
    echo "- **Players with ≥ 40 ghosts:** $GTE40"
    echo "- **Average ghosts found:** $AVG"
    if [[ -n "$LGHOST" ]]; then
      echo "- **Least found ghost:** \`$LGHOST\` — found by $MINREC player(s)"
      echo "  - Teleport: \`/tppos $_x $_y $_z $_w\`"
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

# --player maps to single UUID mode; positional default mode is also single UUID
if [[ "$MODE" == "--player" ]]; then
  TOKEN="$PLAYER_ARG"
else
  TOKEN="$MODE"
fi

# Resolve TOKEN via cache only (no network)
UUID="$TOKEN"
if ! [[ "$UUID" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  if ! UUID="$(resolve_token_to_uuid_cache_only "$TOKEN")"; then
    echo "Error: '$TOKEN' is not a UUID and not found in cache. Add --name-lookup once to cache it."
    exit 2
  fi
fi

# Per-UUID report using AWK again (parse YAML once more for simplicity)
awk -v U="$UUID" -v WL="$WORLD_LC" -v WORLD="$WORLD" \
    -v HI="$C_HI" -v DIM="$C_DIM" -v GRN="$C_GRN" -v CYN="$C_CYN" -v RST="$C_RST" '
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
    # Header
    printf("%s%sMissing ghosts for %s%s %s(world: %s)%s\n", HI,CYN,U,RST,DIM,WORLD,RST)
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
