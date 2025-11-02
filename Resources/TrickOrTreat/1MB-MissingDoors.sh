#!/usr/bin/env bash
# 1MB-MissingDoors.sh (v3 - simple & robust)
# Find which registered doors a player has NOT interacted with.
# Usage:
#   1MB-MissingDoors.sh <PlayerName> [path/to/database.db]
#
# Examples:
#   1MB-MissingDoors.sh LayKam
#   1MB-MissingDoors.sh LayKam ./totdatabase.db
#
# Requirements:
#   - sqlite3 CLI installed (macOS or Ubuntu).
#
# Behavior:
#   - Case-insensitive match on player name (COLLATE NOCASE).
#   - Uses door1* coordinates; falls back to door2* via COALESCE.
#   - Prints one-liners: door_id -> /tppos x y z world
#
set -euo pipefail

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "Error: sqlite3 CLI is required but not found. Install it and retry." >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <PlayerName> [path/to/database.db]" >&2
  exit 2
fi

PLAYER_INPUT=$1
DB_PATH=${2:-"./totdatabase.db"}

if [[ ! -f "$DB_PATH" ]]; then
  echo "Error: database file not found: $DB_PATH" >&2
  exit 3
fi

# Escape single quotes for safe SQL literal
PLAYER_ESC=${PLAYER_INPUT//\'/\'\'}

# Query with fully-qualified columns to avoid ambiguity.
SQL_PIPED="
  SELECT rd.door_id,
         COALESCE(rd.door1x, rd.door2x),
         COALESCE(rd.door1yt, rd.door2yt),
         COALESCE(rd.door1z, rd.door2z),
         rd.door_world
  FROM registered_doors rd
  LEFT JOIN (
    SELECT DISTINCT i.door_id
    FROM interactions i
    WHERE i.player_name = '$PLAYER_ESC' COLLATE NOCASE
  ) found ON found.door_id = rd.door_id
  WHERE found.door_id IS NULL
  ORDER BY rd.door_id;
"

RESULTS=$(sqlite3 -separator '|' -noheader "$DB_PATH" "$SQL_PIPED")

echo "Missing doors for player '$PLAYER_INPUT' (DB: $DB_PATH)"
echo "-----------------------------------------------"

if [[ -z "$RESULTS" ]]; then
  TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM registered_doors;")
  HAVE=$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT door_id) FROM interactions WHERE player_name = '$PLAYER_ESC' COLLATE NOCASE;")
  if [[ "$HAVE" -eq "$TOTAL" ]]; then
    echo "Player has all $TOTAL doors. Nothing missing."
  else
    echo "No missing-door rows returned, but player does not have all doors."
    echo "Player has $HAVE of $TOTAL doors."
  fi
  exit 0
fi

# Print formatted output
while IFS='|' read -r id x y z world; do
  [[ -z "$id" ]] && continue
  printf "door_id %-3s  ->  /tppos %s %s %s %s\n" "$id" "$x" "$y" "$z" "$world"
done <<< "$RESULTS"
