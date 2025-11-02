#!/usr/bin/env bash
# 1MB-Ghosts.sh (v9) — UUID→name via Mojang SessionServer, fallback to PlayerDB + NameMC
#
# Usage:
#   1MB-Ghosts.sh <uuid> [data.yml] [--world <name>] [--name-lookup]
#   1MB-Ghosts.sh -list:<N> [data.yml] [--world <name>] [--name-lookup]
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

if [[ $# -lt 1 ]]; then
  echo "Usage:"
  echo "  $0 <uuid> [data.yml] [--world <name>] [--name-lookup]"
  echo "  $0 -list:<N> [data.yml] [--world <name>] [--name-lookup]"
  exit 2
fi

# Args
i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --name-lookup) NAME_LOOKUP=1; i=$((i+1));;
    --world) j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --world requires a value." >&2; exit 2; }
             WORLD="${!j}"; i=$((i+2));;
    --world=*) WORLD="${arg#--world=}"; i=$((i+1));;
    -*)
      if [[ -z "$MODE" ]]; then MODE="$arg"; else echo "Error: unexpected flag '$arg'." >&2; exit 2; fi
      i=$((i+1));;
    *)
      if [[ -z "$MODE" ]]; then MODE="$arg"
      elif [[ "$YAML" == "./data.yml" ]]; then YAML="$arg"
      else echo "Error: unexpected positional argument '$arg'." >&2; exit 2; fi
      i=$((i+1));;
  esac
done

[[ -f "$YAML" ]] || { echo "Error: data.yml not found at: $YAML" >&2; exit 3; }
WORLD_LC="$(printf "%s" "$WORLD" | tr '[:upper:]' '[:lower:]')"

TMPDIR="${TMPDIR:-/tmp}"
UUIDS_FILE="$(mktemp "$TMPDIR/uuids.XXXXXX")"
MAP_FILE="$(mktemp "$TMPDIR/map.XXXXXX")"
trap 'rm -f "$UUIDS_FILE" "$MAP_FILE" 2>/dev/null || true' EXIT

# Extract all UUIDs found in claimed lists
awk '
  BEGIN{cur=""; in_claim=0}
  /^[0-9a-fA-F-]{36}:[[:space:]]*$/ { cur=$0; sub(/:.*/,"",cur); in_claim=0; next }
  /^[[:space:]]+claimed:[[:space:]]*$/ { in_claim=1; next }
  /^[[:space:]]+-[[:space:]]+[0-9a-fA-F-]{36}[[:space:]]*$/ {
    if(in_claim){
      u=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",u); print u
    }
  }
' "$YAML" | LC_ALL=C sort -u > "$UUIDS_FILE"

# --- Optional UUID -> name mapping using Mojang + fallback ---
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
CURL_BASE=(curl -sS -L --connect-timeout 2 --max-time 3 -A "$UA")

is_valid_name() { [[ "$1" =~ ^[A-Za-z0-9_]{3,16}$ ]]; }
strip_dashes() { echo "${1//-/}"; }

lookup_mojang() {
  local uuid_no_dash name json
  uuid_no_dash="$(strip_dashes "$1")"
  # Mojang SessionServer returns JSON like: {"id":"<uuid>","name":"PlayerName",...}
  json="$("${CURL_BASE[@]}" "https://sessionserver.mojang.com/session/minecraft/profile/${uuid_no_dash}" || true)"
  name="$(printf "%s" "$json" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  if is_valid_name "$name"; then echo "$name"; return 0; fi
  return 1
}

lookup_playerdb() {
  local json name
  json="$("${CURL_BASE[@]}" "https://playerdb.co/api/player/minecraft/$1" || true)"
  # {"code":"player.found","data":{"player":{"username":"mrfloris",...}}}
  name="$(printf "%s" "$json" | sed -n 's/.*"username"[[:space:]]*":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  if is_valid_name "$name"; then echo "$name"; return 0; fi
  return 1
}

lookup_namemc() {
  local html name
  html="$("${CURL_BASE[@]}" "https://namemc.com/profile/$1" || true)"
  name="$(printf "%s" "$html" | sed -n 's/.*property="og:title" content="\([^"]*\)".*/\1/p' | head -1 | sed 's/ - .*$//' | awk '{print $1}')"
  if is_valid_name "$name"; then echo "$name"; return 0; fi
  return 1
}

resolve_name() {
  local uuid="$1" name=""
  lookup_mojang "$uuid" && return 0 || true
  name="$(lookup_mojang "$uuid")"; if is_valid_name "$name"; then echo "$name"; return; fi
  name="$(lookup_playerdb "$uuid")"; if is_valid_name "$name"; then echo "$name"; return; fi
  name="$(lookup_namemc "$uuid")"; if is_valid_name "$name"; then echo "$name"; return; fi
  echo ""
}

if [[ "$NAME_LOOKUP" -eq 1 ]]; then
  while IFS= read -r u; do
    n="$(resolve_name "$u")"
    if [[ -n "$n" ]]; then printf "%s\t%s\n" "$u" "$n" >> "$MAP_FILE"; fi
  done < "$UUIDS_FILE"
fi

# --- Main AWK core (BSD awk) ---
awk -v MODE="$MODE" -v WORLD="$WORLD" -v WL="$WORLD_LC" -v MAP="$MAP_FILE" \
    -v HI="$C_HI" -v DIM="$C_DIM" -v RED="$C_RED" -v GRN="$C_GRN" -v CYN="$C_CYN" -v RST="$C_RST" '
  function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
  function label(u){ return (u in map ? map[u] " (" u ")" : u) }
  BEGIN{
    cur=""; in_claim=0; total=0;
    if(MAP!="" && (getline test < MAP)>0){
      close(MAP);
      while((getline < MAP)>0){ split($0,a,"\t"); map[a[1]]=a[2] }
      close(MAP)
    } else if(MAP!=""){ close(MAP) }
  }
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
      u=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",u); seen[u]=1; claims[u SUBSEP cur]=1
    }
    next
  }
  /^[^[:space:]-]/ { in_claim=0 }
  END{
    for(g in g_w){ if(g_w[g]==WL){ ghosts[g]=1; total++ } }
    if(total==0){ printf("%sNo ghosts found in world \x27%s\x27.%s\n", RED, WORLD, RST); exit 4 }

    if(MODE ~ /^-list:[0-9]+$/){
      split(MODE,a,":"); target=a[2]+0
      if(target>total){ printf("%s-list:%d exceeds total ghosts (%d) in world \x27%s\x27.%s\n", RED, target, total, WORLD, RST); exit 5 }
      miss=total-target
      if(target==total){
        printf("%s%sUUIDs with ALL ghosts%s %s(world: %s)%s\n", HI,CYN,RST,DIM,WORLD,RST)
      } else {
        printf("%s%sUUIDs with %d ghosts (missing exactly %d)%s %s(world: %s)%s\n", HI,CYN,target,miss,RST,DIM,WORLD,RST)
      }
      print "-----------------------------------------------"
      count=0
      for(u in seen){
        have=0
        for(g in ghosts){ if((u SUBSEP g) in claims) have++ }
        if(have==target){
          if(target==total){
            printf("• %s\n", label(u))
          } else {
            printf("%s%s%s\n", HI, label(u), RST)
            for(g in ghosts){
              if(!((u SUBSEP g) in claims)){
                printf("  %smissing ghost %-36s%s -> %s/tppos %s %s %s %s%s\n", DIM, g, RST, GRN, g_x[g], g_y[g], g_z[g], g_wo[g], RST)
              }
            }
            print ""
          }
          count++
        }
      }
      print ""
      if(target==total){
        printf("%sTotal UUIDs with all ghosts: %d.%s\n", DIM, count, RST)
      } else {
        printf("%sTotal UUIDs at %d/%d: %d.%s\n", DIM, target, total, count, RST)
      }
      exit 0
    }

    # per-uuid
    u=MODE
    have=0; for(g in ghosts){ if((u SUBSEP g) in claims) have++ }
    miss=total-have
    printf("%s%sMissing ghosts for %s%s %s(world: %s)%s\n", HI,CYN,label(u),RST,DIM,WORLD,RST)
    print "-----------------------------------------------"
    if(miss==0){ printf("%sThis UUID has all %d ghosts.%s\n", GRN, total, RST); exit 0 }
    for(g in ghosts){
      if(!((u SUBSEP g) in claims)){
        printf("%sghost %-36s%s -> %s/tppos %s %s %s %s%s\n", HI, g, RST, GRN, g_x[g], g_y[g], g_z[g], g_wo[g], RST)
      }
    }
    print ""
    printf("%sUUID has %d of %d ghosts (%d missing).%s\n", DIM, have, total, miss, RST)
  }
' "$YAML"
