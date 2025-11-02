#!/usr/bin/env bash
# 1MB-MissingDoors.sh (v6)
# - Per-player missing-door report with count summary + colorized output
# - General list mode: -list:N (0..TOTAL)
# - NEW: --world <name> (default: halloween). Scopes *everything* to that world:
#        totals, found counts, and missing-door lists.
#
# Usage:
#   1MB-MissingDoors.v6.sh <PlayerName> [path/to/database.db] [--world <name>]
#   1MB-MissingDoors.v6.sh -list:<N>   [path/to/database.db] [--world <name>]
#
# Examples:
#   ./1MB-MissingDoors.v6.sh LayKam --world halloween
#   ./1MB-MissingDoors.v6.sh -list:59 ./totdatabase.db --world halloween
#
# Requirements: sqlite3 CLI
#
set -euo pipefail

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "Error: sqlite3 CLI is required but not found. Install it and retry." >&2
  exit 1
fi

# -------- Colors (auto-disable if not a TTY) --------
use_color=0
if [[ -t 1 ]] && tput colors >/dev/null 2>&1; then
  use_color=1
fi
if [[ ${NO_COLOR:-} != "" ]]; then
  use_color=0
fi

if [[ $use_color -eq 1 ]]; then
  C_HI=$(tput bold)
  C_DIM=$(tput dim)
  C_RED=$(tput setaf 1)
  C_GRN=$(tput setaf 2)
  C_YEL=$(tput setaf 3)
  C_BLU=$(tput setaf 4)
  C_CYN=$(tput setaf 6)
  C_RST=$(tput sgr0)
else
  C_HI=""; C_DIM=""; C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_CYN=""; C_RST=""
fi

# -------- Arg parsing --------
MODE=""
DB_PATH="./totdatabase.db"
WORLD="halloween"

if [[ $# -lt 1 ]]; then
  echo "Usage:"
  echo "  $0 <PlayerName> [path/to/database.db] [--world <name>]"
  echo "  $0 -list:<N>   [path/to/database.db] [--world <name>]"
  exit 2
fi

# We accept args in any order: first non-flag becomes MODE, next non-flag becomes DB.
i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --world)
      j=$((i+1))
      if [[ $j -le $# ]]; then
        WORLD="${!j}"
        i=$((i+2))
        continue
      else
        echo "Error: --world requires a value." >&2
        exit 2
      fi
      ;;
    --world=*)
      WORLD="${arg#--world=}"
      i=$((i+1))
      continue
      ;;
    -*)
      # Could be -list:N
      if [[ -z "$MODE" ]]; then
        MODE="$arg"
      else
        echo "Error: unexpected flag '$arg'." >&2
        exit 2
      fi
      i=$((i+1))
      ;;
    *)
      # Non-flag: assign to MODE or DB depending on what's already set.
      if [[ -z "$MODE" ]]; then
        MODE="$arg"
      elif [[ "$DB_PATH" == "./totdatabase.db" ]]; then
        DB_PATH="$arg"
      else
        echo "Error: unexpected positional argument '$arg'." >&2
        exit 2
      fi
      i=$((i+1))
      ;;
  esac
done

if [[ ! -f "$DB_PATH" ]]; then
  echo "Error: database file not found: $DB_PATH" >&2
  exit 3
fi

# Escape values for SQL
WORLD_ESC=${WORLD//\'/\'\'}

# -------- Helpers (scoped by WORLD) --------
get_total() {
  sqlite3 "$DB_PATH" "
    SELECT COUNT(*) FROM registered_doors rd
    WHERE lower(rd.door_world) = lower('$WORLD_ESC');
  "
}

player_summary() {
  local player="$1"
  local player_esc="${player//\'/\'\'}"
  local total have
  total=$(get_total)
  have=$(sqlite3 "$DB_PATH" "
    SELECT COUNT(DISTINCT i.door_id)
    FROM interactions i
    JOIN registered_doors rd ON rd.door_id = i.door_id
    WHERE lower(i.player_name) = lower('$player_esc')
      AND lower(rd.door_world) = lower('$WORLD_ESC');
  ")
  local missing=$(( total - have ))
  echo "$have|$total|$missing"
}

print_player_missing() {
  local player="$1"
  local player_esc="${player//\'/\'\'}"

  local sql="
    SELECT rd.door_id,
           COALESCE(rd.door1x, rd.door2x),
           COALESCE(rd.door1yt, rd.door2yt),
           COALESCE(rd.door1z, rd.door2z),
           rd.door_world
    FROM registered_doors rd
    LEFT JOIN (
      SELECT DISTINCT i.door_id
      FROM interactions i
      JOIN registered_doors r2 ON r2.door_id = i.door_id
      WHERE lower(i.player_name) = lower('$player_esc')
        AND lower(r2.door_world) = lower('$WORLD_ESC')
    ) found ON found.door_id = rd.door_id
    WHERE lower(rd.door_world) = lower('$WORLD_ESC')
      AND found.door_id IS NULL
    ORDER BY rd.door_id;
  "
  local results
  results=$(sqlite3 -separator '|' -noheader "$DB_PATH" "$sql")

  echo -e "${C_HI}${C_CYN}Missing doors for player '${player}'${C_RST} ${C_DIM}(DB: $DB_PATH, world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"

  IFS='|' read -r have total missing <<<"$(player_summary "$player")"
  if [[ -z "$results" ]]; then
    if [[ "$missing" -eq 0 ]]; then
      echo -e "${C_GRN}Player has all ${total} doors in world '${WORLD}'. Nothing missing.${C_RST}"
    else
      echo -e "${C_YEL}No missing-door rows returned, but summary indicates ${missing} missing in '${WORLD}'.${C_RST}"
      echo -e "${C_DIM}Player has ${have} of ${total} doors (${missing} missing).${C_RST}"
    fi
    return 0
  fi

  while IFS='|' read -r id x y z world; do
    [[ -z "$id" ]] && continue
    printf "${C_HI}door_id %-3s${C_RST}  ->  ${C_GRN}/tppos %s %s %s %s${C_RST}\n" "$id" "$x" "$y" "$z" "$world"
  done <<< "$results"

  echo
  echo -e "${C_DIM}Player has ${have} of ${total} doors (${missing} missing) in '${WORLD}'.${C_RST}"
}

list_all_found_exact() {
  # $1 = N (exactly this many doors found) within WORLD
  local n="$1"
  local total
  total=$(get_total)

  if [[ "$n" -gt "$total" ]]; then
    echo -e "${C_RED}Requested -list:${n} exceeds total doors (${total}) in world '${WORLD}'.${C_RST}" >&2
    exit 4
  fi

  if [[ "$n" -eq "$total" ]]; then
    # Players with ALL doors in WORLD
    local sql="
      WITH pc AS (
        SELECT lower(i.player_name) AS norm,
               MAX(i.player_name)   AS display,
               COUNT(DISTINCT i.door_id) AS c
        FROM interactions i
        JOIN registered_doors rd ON rd.door_id = i.door_id
        WHERE lower(rd.door_world) = lower('$WORLD_ESC')
        GROUP BY norm
      )
      SELECT display
      FROM pc
      WHERE c = $n
      ORDER BY display COLLATE NOCASE;
    "
    local rows
    rows=$(sqlite3 -noheader "$DB_PATH" "$sql")

    echo -e "${C_HI}${C_CYN}Players with ALL doors${C_RST} ${C_DIM}(DB: $DB_PATH, world: ${WORLD})${C_RST}"
    echo "-----------------------------------------------"
    if [[ -z "$rows" ]]; then
      echo -e "${C_YEL}No players with complete set in '${WORLD}'.${C_RST}"
      return 0
    fi
    local count=0
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      echo "• $name"
      ((count++)) || true
    done <<< "$rows"
    echo
    echo -e "${C_DIM}Total players with all doors: ${count}.${C_RST}"
    return 0
  fi

  # Players with exactly N found; list which doors they are missing in WORLD.
  local sql="
    WITH pc AS (
      SELECT lower(i.player_name) AS norm,
             MAX(i.player_name)   AS display,
             COUNT(DISTINCT i.door_id) AS c
      FROM interactions i
      JOIN registered_doors rd ON rd.door_id = i.door_id
      WHERE lower(rd.door_world) = lower('$WORLD_ESC')
      GROUP BY norm
    ),
    eligible AS (
      SELECT pc.norm, pc.display
      FROM pc
      WHERE pc.c = $n
    ),
    missing AS (
      SELECT e.display AS player_name,
             rd.door_id AS door_id,
             COALESCE(rd.door1x, rd.door2x) AS x,
             COALESCE(rd.door1yt, rd.door2yt) AS y,
             COALESCE(rd.door1z, rd.door2z) AS z,
             rd.door_world AS world
      FROM registered_doors rd
      JOIN eligible e
      LEFT JOIN interactions i
        ON lower(i.player_name) = e.norm
       AND i.door_id = rd.door_id
      WHERE lower(rd.door_world) = lower('$WORLD_ESC')
        AND i.door_id IS NULL
    )
    SELECT player_name, door_id, x, y, z, world
    FROM missing
    ORDER BY lower(player_name), door_id;
  "
  local rows
  rows=$(sqlite3 -separator '|' -noheader "$DB_PATH" "$sql")

  echo -e "${C_HI}${C_CYN}Players with ${n} doors (missing exactly $(( total - n )))${C_RST} ${C_DIM}(DB: $DB_PATH, world: ${WORLD})${C_RST}"
  echo "-----------------------------------------------"
  if [[ -z "$rows" ]]; then
    echo -e "${C_YEL}No players at ${n}/${total} in '${WORLD}' right now.${C_RST}"
    return 0
  fi

  local current=""
  local count=0
  while IFS='|' read -r name id x y z world; do
    [[ -z "$name" ]] && continue
    if [[ "$name" != "$current" ]]; then
      [[ -n "$current" ]] && echo
      echo -e "${C_HI}$name${C_RST}"
      current="$name"
      ((count++)) || true
    fi
    printf "  ${C_DIM}missing door_id %-3s${C_RST} -> ${C_GRN}/tppos %s %s %s %s${C_RST}\n" "$id" "$x" "$y" "$z" "$world"
  done <<< "$rows"
  echo
  echo -e "${C_DIM}Total players at ${n}/${total}: ${count}.${C_RST}"
}

# -------- Mode dispatch --------
if [[ "$MODE" =~ ^-list:([0-9]+)$ ]]; then
  LNUM="${BASH_REMATCH[1]}"
  list_all_found_exact "$LNUM"
else
  print_player_missing "$MODE"
fi
