#!/usr/bin/env bash
# 1MB-Ghosts.sh — Simple, portable, macOS-compatible
# Read data.yml with 50 ghosts:
# <ghost_uid>:
#   location: world@x@y@z@yaw@pitch
#   claimed:
#   - <player-uuid>
#
# Usage:
#   1MB-Ghosts.sh <uuid> [data.yml] [--world <name>]
#   1MB-Ghosts.sh -list:<N> [data.yml] [--world <name>]
#
set -euo pipefail

# -------- Colors (auto) --------
use_color=0
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
  use_color=1
fi
if [[ ${NO_COLOR:-} != "" ]]; then use_color=0; fi
if [[ $use_color -eq 1 ]]; then
  C_HI=$(tput bold); C_DIM=$(tput dim); C_RED=$(tput setaf 1); C_GRN=$(tput setaf 2); C_CYN=$(tput setaf 6); C_RST=$(tput sgr0)
else
  C_HI=""; C_DIM=""; C_RED=""; C_GRN=""; C_CYN=""; C_RST=""
fi

MODE=""
YAML="./data.yml"
WORLD="halloween"

if [[ $# -lt 1 ]]; then
  echo "Usage:"
  echo "  $0 <uuid> [data.yml] [--world <name>]"
  echo "  $0 -list:<N> [data.yml] [--world <name>]"
  exit 2
fi

# Parse args
i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --world)
      j=$((i+1)); [[ $j -le $# ]] || { echo "Error: --world requires a value." >&2; exit 2; }
      WORLD="${!j}"; i=$((i+2));;
    --world=*)
      WORLD="${arg#--world=}"; i=$((i+1));;
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

# Run a single AWK program to parse and compute.
awk -v MODE="$MODE" -v WORLD="$WORLD" -v WL="$WORLD_LC" \
    -v HI="$C_HI" -v DIM="$C_DIM" -v RED="$C_RED" -v GRN="$C_GRN" -v CYN="$C_CYN" -v RST="$C_RST" '
  function ltrim(s){ sub(/^[ \t]+/, "", s); return s }
  function rtrim(s){ sub(/[ \t]+$/, "", s); return s }
  function trim(s){ return rtrim(ltrim(s)) }
  BEGIN{
    cur=""; in_claim=0;
  }
  # New ghost UUID key (top-level)
  /^[0-9a-fA-F-]{36}:[[:space:]]*$/{
    cur=$0; sub(/:.*$/,"",cur);
    in_claim=0;
    ghost_ids[cur]=1;
    next
  }
  # location line
  /^[[:space:]]+location:[[:space:]]*/{
    loc=$0; sub(/^[[:space:]]+location:[[:space:]]*/,"",loc);
    split(loc, p, "@");
    w=tolower(trim(p[1]));
    x=p[2]; y=p[3]; z=p[4];
    sub(/\..*$/,"",x); sub(/\..*$/,"",y); sub(/\..*$/,"",z);
    g_world[cur]=w; g_w_out[cur]=trim(p[1]); g_x[cur]=x; g_y[cur]=y; g_z[cur]=z;
    next
  }
  # start of claimed list
  /^[[:space:]]+claimed:[[:space:]]*$/{
    in_claim=1; next
  }
  # claimed entries
  /^[[:space:]]+-[[:space:]]+[0-9a-fA-F-]{36}[[:space:]]*$/{
    if(in_claim && cur!=""){
      u=$0; sub(/^[[:space:]]+-[[:space:]]+/,"",u); u=trim(u);
      claims[u SUBSEP cur]=1;
      seen_uuid[u]=1;
    }
    next
  }
  # safety: if we hit a non-claimed block line, stop claim mode
  /^[^[:space:]-]/ { in_claim=0 }

  END{
    total=0
    # Build world ghost set
    for(g in ghost_ids){
      if(g_world[g]==WL){
        ghosts[g]=1; total++
      }
    }
    if(total==0){
      printf("%sNo ghosts found in world \x27%s\x27.%s\n", RED, WORLD, RST)
      exit 4
    }

    if(MODE ~ /^-list:[0-9]+$/){
      split(MODE,a,":"); target=a[2]+0
      if(target>total){
        printf("%s-list:%d exceeds total ghosts (%d) in world \x27%s\x27.%s\n", RED, target, total, WORLD, RST); exit 5
      }
      miss=total-target
      if(target==total){
        printf("%s%sUUIDs with ALL ghosts%s %s(world: %s)%s\n", HI,CYN,RST,DIM,WORLD,RST)
      } else {
        printf("%s%sUUIDs with %d ghosts (missing exactly %d)%s %s(world: %s)%s\n", HI,CYN,target,miss,RST,DIM,WORLD,RST)
      }
      print "-----------------------------------------------"
      count=0
      for(u in seen_uuid){
        have=0
        for(g in ghosts){
          if((u SUBSEP g) in claims) have++
        }
        if(have==target){
          if(target==total){
            printf("• %s\n", u)
          } else {
            printf("%s%s%s\n", HI,u,RST)
            for(g in ghosts){
              if(!((u SUBSEP g) in claims)){
                printf("  %smissing ghost %-36s%s -> %s/tppos %s %s %s %s%s\n", DIM, g, RST, GRN, g_x[g], g_y[g], g_z[g], g_w_out[g], RST)
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

    # Per-UUID mode
    u=MODE
    printf("%s%sMissing ghosts for UUID \x27%s\x27%s %s(world: %s)%s\n", HI,CYN,u,RST,DIM,WORLD,RST)
    print "-----------------------------------------------"
    have=0
    for(g in ghosts){
      if((u SUBSEP g) in claims) have++
    }
    miss=total-have
    if(miss==0){
      printf("%sThis UUID has all %d ghosts.%s\n", GRN, total, RST); exit 0
    }
    for(g in ghosts){
      if(!((u SUBSEP g) in claims)){
        printf("%sghost %-36s%s -> %s/tppos %s %s %s %s%s\n", HI, g, RST, GRN, g_x[g], g_y[g], g_z[g], g_w_out[g], RST)
      }
    }
    print ""
    printf("%sUUID has %d of %d ghosts (%d missing).%s\n", DIM, have, total, miss, RST)
  }
' "$YAML"
