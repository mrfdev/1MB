#!/usr/bin/env bash

# @Filename: 1MB-ChristmasPlus.sh
# @Version: 2.0.1, build 033
# @Release: December 1st, 2025
# @Description: Helps us query advent progress and generate stats from ChristmasPlus database.db
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Contributions from: @momshroom on https://discord.gg/ySRPTYTtKf
# @Install: chmod +x 1MB-ChristmasPlus.sh
# @Syntax: (see below)
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/
# 
# Requires: sqlite3, jq
#
# Usage:
#   ./1MB-ChristmasPlus.sh <day 1-24> [--uuid]
#   ./1MB-ChristmasPlus.sh <playername|uuid> [--uuid]
#   ./1MB-ChristmasPlus.sh all [--uuid]
#   ./1MB-ChristmasPlus.sh complete [--uuid]
#   ./1MB-ChristmasPlus.sh allnames [minDays] [--uuid]
#   ./1MB-ChristmasPlus.sh stats
#
# Examples:
#   ./1MB-ChristmasPlus.sh 1                                       # Who claimed Advent Day 1
#   ./1MB-ChristmasPlus.sh 5 --uuid                                # Who claimed Day 5, but also show UUIDs
#   ./1MB-ChristmasPlus.sh mrfloris                                # Show breakdown of days claimed & missed
#   ./1MB-ChristmasPlus.sh mrfloris --uuid                         # Same breakdown, with UUID displayed
#   ./1MB-ChristmasPlus.sh 631e3896-da2a-4077-974b-d047859d76bc    # Lookup by UUID instead of name
#   ./1MB-ChristmasPlus.sh 631e3896-da2a-4077-974b-d047859d76bc --uuid # UUID lookup with UUID also shown
#   ./1MB-ChristmasPlus.sh all                                     # Show players who claimed 24, 23 & 22 days
#   ./1MB-ChristmasPlus.sh complete                                # Show above + full per-day breakdown 1–24
#   ./1MB-ChristmasPlus.sh complete --uuid                         # Same full breakdown, but with UUIDs
#   ./1MB-ChristmasPlus.sh allnames                                # List all players sorted by total claimed days
#   ./1MB-ChristmasPlus.sh allnames --uuid                         # Same, but append UUID per player
#   ./1MB-ChristmasPlus.sh allnames 5                              # Only players with ≥5 claimed days shown
#   ./1MB-ChristmasPlus.sh allnames 5 --uuid                       # ≥5 days + UUID display
#   ./1MB-ChristmasPlus.sh stats > stats.md                        # Generate full Markdown export summary
# 
#
# @Changelog: v2.0.x is a full merge of my private version, the public script, and Momshroom’s contributions, refined and rewritten with assistance from ChatGPT. Codebase has been cleaned, updated, and optimized for Paper 1.21.10+ and the current Christmas+ plugin.

set -u
IFS=$'\n\t'

DB="${DB_PATH:-$(cd "$(dirname "$0")" && pwd)/database.db}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <day 1-24> [--uuid]
  $(basename "$0") <playername|uuid> [--uuid]
  $(basename "$0") all [--uuid]
  $(basename "$0") complete [--uuid]
  $(basename "$0") allnames [minDays] [--uuid]
  $(basename "$0") stats > [filename.md]

Examples:
  $(basename "$0") 1                                       # Who claimed Advent Day 1
  $(basename "$0") 5 --uuid                                # Claim list + UUID column
  $(basename "$0") mrfloris                                # Claim/miss breakdown for player
  $(basename "$0") mrfloris --uuid                         # Same breakdown but with UUID
  $(basename "$0") 631e3896-da2a-4077-974b-d047859d76bc    # Lookup player by UUID
  $(basename "$0") 631e3896-da2a-4077-974b-d047859d76bc --uuid # UUID lookup + UUID shown
  $(basename "$0") all                                     # Show 24-day completers + 23/22 nearly complete
  $(basename "$0") complete                                # Same as all + full per-day lists
  $(basename "$0") complete --uuid                         # Full detailed breakdown including UUIDs
  $(basename "$0") allnames                                # Sorted by claimed total (desc)
  $(basename "$0") allnames --uuid                         # Same, but with UUID appended
  $(basename "$0") allnames 5                              # Only players with ≥5 claimed days
  $(basename "$0") allnames 5 --uuid                       # Filter + UUID output
  $(basename "$0") stats > advent-overview.md              # Markdown stats file export for Discord/GitHub

EOF
  exit 1
}

require_tools() {
  if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "Error: sqlite3 is required but not found in PATH." >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not found in PATH." >&2
    exit 1
  fi
  if [[ ! -f "$DB" ]]; then
    echo "Error: database not found at: $DB" >&2
    exit 1
  fi
}

# Escape single quotes for SQL literal
sql_escape() {
  local s=$1
  s=${s//\'/\'\'}
  printf "%s" "$s"
}

# --- mode: per-day --------------------------------------------------------

show_day() {
  local day="$1"
  local show_uuid="$2"

  local total_players
  total_players=$(sqlite3 "$DB" "SELECT COUNT(*) FROM players;")

  local count=0
  local -a matches=()

  while IFS=$'\t' read -r uuid name claimed; do
    [[ -z "${uuid:-}" ]] && continue
    [[ -z "${claimed:-}" ]] && continue

    local has
    has=$(jq -r --arg d "$day" '.[$d] // false' <<<"$claimed" 2>/dev/null || echo "false")
    if [[ "$has" == "true" ]]; then
      ((count++))
      if (( show_uuid )); then
        matches+=("${name} (${uuid})")
      else
        matches+=("$name")
      fi
    fi
  done < <(sqlite3 -separator $'\t' "$DB" "SELECT uuid,name,claimedGifts FROM players;")

  echo "Players who have claimed advent day ${day}: (${count} players total out of ${total_players} logged)"
  if (( count == 0 )); then
    echo "(none)"
  else
    local m
    for m in "${matches[@]}"; do
      echo "$m"
    done
  fi
}

# --- mode: per-player -----------------------------------------------------

show_player() {
  local arg="$1"
  local show_uuid="$2"

  local esc
  esc=$(sql_escape "$arg")

  local found=0

  while IFS=$'\t' read -r uuid name claimed; do
    [[ -z "${uuid:-}" ]] && continue
    [[ -z "${claimed:-}" ]] && continue
    ((found++))

    local claimed_count claimed_list unclaimed_list unclaimed_count

    claimed_count=$(jq 'to_entries | map(select(.value==true)) | length' <<<"$claimed" 2>/dev/null || echo 0)

    claimed_list=$(jq -r 'to_entries
      | map(select(.value==true) | .key | tonumber)
      | sort
      | map(tostring)
      | join(", ")' <<<"$claimed" 2>/dev/null || echo "")

    unclaimed_list=$(jq -r 'to_entries
      | map(select(.value!=true) | .key | tonumber)
      | sort
      | map(tostring)
      | join(", ")' <<<"$claimed" 2>/dev/null || echo "")

    [[ -z "$claimed_list" ]] && claimed_list="none"

    if [[ "$claimed_count" =~ ^[0-9]+$ ]]; then
      unclaimed_count=$((24 - claimed_count))
    else
      claimed_count=0
      unclaimed_count=24
    fi
    [[ -z "$unclaimed_list" ]] && unclaimed_list="none"

    local all_flag="No"
    if [[ "$claimed_count" -eq 24 ]]; then
      all_flag="Yes"
    fi

    local label="$name"
    if (( show_uuid )); then
      label="${name} (${uuid})"
    fi

    echo "${label} claimed advent days (${claimed_count}): ${claimed_list}"
    echo "${label} has not claimed (${unclaimed_count}): ${unclaimed_list}"
    echo "${label} has claimed all 24 days: ${all_flag}"

    # "Got close" hint (22 or 23 days)
    if (( claimed_count >= 22 && claimed_count < 24 )); then
      echo "${label} got close to 24: yes, ${claimed_count} claimed"
    else
      echo "${label} got close to 24: no, only ${claimed_count} claimed"
    fi
    echo
  done < <(sqlite3 -separator $'\t' "$DB" "
    SELECT uuid,name,claimedGifts
    FROM players
    WHERE lower(name) = lower('$esc')
       OR uuid = '$esc';
  ")

  if (( found == 0 )); then
    echo "No player found matching '$arg'."
  fi
}

# --- mode: all / almost all ----------------------------------------------

show_all() {
  local show_uuid="$1"

  local total_players
  total_players=$(sqlite3 "$DB" "SELECT COUNT(*) FROM players;")

  local full_count=0 c23_count=0 c22_count=0
  local -a full_names=() near23=() near22=()

  while IFS=$'\t' read -r uuid name claimed; do
    [[ -z "${uuid:-}" ]] && continue
    [[ -z "${claimed:-}" ]] && continue

    local claimed_count
    claimed_count=$(jq 'to_entries | map(select(.value==true)) | length' <<<"$claimed" 2>/dev/null || echo 0)

    local label="$name"
    if (( show_uuid )); then
      label="${name} (${uuid})"
    fi

    case "$claimed_count" in
      24)
        ((full_count++))
        full_names+=("$label")
        ;;
      23)
        ((c23_count++))
        near23+=("$label")
        ;;
      22)
        ((c22_count++))
        near22+=("$label")
        ;;
    esac
  done < <(sqlite3 -separator $'\t' "$DB" "SELECT uuid,name,claimedGifts FROM players;")

  echo "Players who have claimed all 24 advent days: ${full_count} out of ${total_players} logged."
  if (( full_count == 0 )); then
    echo "(none)"
  else
    local p
    for p in "${full_names[@]}"; do
      echo "$p"
    done
  fi

  echo
  echo "Players who have claimed almost all 24:"

  echo "23 days: (${c23_count})"
  if (( c23_count == 0 )); then
    echo "(none)"
  else
    local p23
    for p23 in "${near23[@]}"; do
      echo "$p23"
    done
  fi

echo
echo "22 days: (${c22_count})"
if (( c22_count == 0 )); then
  echo "(none)"
else
  local p22
  for p22 in "${near22[@]}"; do
    echo "$p22"
  done
fi
}


# --- shared: per-day lists for "complete" ---------------------------------

declare -a DAY_COUNTS
declare -a DAY_NAMES

compute_day_lists() {
  local show_uuid="$1"
  local d

  for d in {1..24}; do
    DAY_COUNTS[$d]=0
    DAY_NAMES[$d]=""
  done

  while IFS=$'\t' read -r uuid name claimed; do
    [[ -z "${claimed:-}" ]] && continue

    local label="$name"
    if (( show_uuid )); then
      label="${name} (${uuid})"
    fi

    local days
    days=$(jq -r 'to_entries
      | map(select(.value==true) | .key | tonumber)
      | sort
      | .[]?' <<<"$claimed" 2>/dev/null || echo "")

    for d in $days; do
      if [[ "$d" =~ ^[0-9]+$ ]] && (( d >= 1 && d <= 24 )); then
        DAY_COUNTS[$d]=$(( ${DAY_COUNTS[$d]} + 1 ))
        if [[ -z "${DAY_NAMES[$d]}" ]]; then
          DAY_NAMES[$d]="$label"
        else
          DAY_NAMES[$d]="${DAY_NAMES[$d]}, $label"
        fi
      fi
    done
  done < <(sqlite3 -separator $'\t' "$DB" "SELECT uuid,name,claimedGifts FROM players;")
}

show_complete() {
  local show_uuid="$1"

  # First the same summary as "all"
  show_all "$show_uuid"
  echo
  echo "Per-day players:"
  echo

  compute_day_lists "$show_uuid"

  local d
  for d in {1..24}; do
    local count="${DAY_COUNTS[$d]}"
    local names="${DAY_NAMES[$d]}"
    echo "Day ${d} (${count} players),"
    if [[ -z "$names" ]]; then
      echo "(none)"
    else
      echo "$names"
    fi
    echo
  done
}

# --- mode: stats (Markdown overview, now includes allnames-style) --------

show_stats_markdown() {
  local total_players
  total_players=$(sqlite3 "$DB" "SELECT COUNT(*) FROM players;")

  local -a claimed_counts
  local -a names_by_day
  local -a all_lines  # for allnames-style sorting
  local d
  for d in {1..24}; do
    claimed_counts[$d]=0
    names_by_day[$d]=""
  done

  local full_count=0 c23_count=0 c22_count=0
  local -a full_names=() near23=() near22=()

  while IFS=$'\t' read -r uuid name claimed; do
    [[ -z "${claimed:-}" ]] && continue

    local claimed_count
    claimed_count=$(jq 'to_entries | map(select(.value==true)) | length' <<<"$claimed" 2>/dev/null || echo 0)

    # For 24/23/22 groups
    case "$claimed_count" in
      24)
        ((full_count++))
        full_names+=("$name")
        ;;
      23)
        ((c23_count++))
        near23+=("$name")
        ;;
      22)
        ((c22_count++))
        near22+=("$name")
        ;;
    esac

    # For per-day stats
    local days
    days=$(jq -r 'to_entries
      | map(select(.value==true) | .key | tonumber)
      | sort
      | .[]?' <<<"$claimed" 2>/dev/null || echo "")

    for d in $days; do
      if [[ "$d" =~ ^[0-9]+$ ]] && (( d >= 1 && d <= 24 )); then
        claimed_counts[$d]=$(( ${claimed_counts[$d]} + 1 ))
        if [[ -z "${names_by_day[$d]}" ]]; then
          names_by_day[$d]="$name"
        else
          names_by_day[$d]="${names_by_day[$d]}, $name"
        fi
      fi
    done

    # For allnames-style summary
    all_lines+=("${claimed_count}"$'\t'"${name}")
  done < <(sqlite3 -separator $'\t' "$DB" "SELECT uuid,name,claimedGifts FROM players;")

  echo "# Advent Day Summary"
  echo
  echo "- Total players logged: ${total_players}"
  echo
  echo "## Per-day counts"
  echo
  echo "| Day | Claimed | Not claimed |"
  echo "| --- | ------- | ----------- |"

  for d in {1..24}; do
    local claimed="${claimed_counts[$d]:-0}"
    local not_claimed=$(( total_players - claimed ))
    echo "| ${d} | ${claimed} | ${not_claimed} |"
  done

  echo
  echo "## Players who completed or almost completed"
  echo

  echo "### 24 days (all)"
  echo
  if (( full_count == 0 )); then
    echo "- (none)"
  else
    local p
    for p in "${full_names[@]}"; do
      echo "- ${p}"
    done
  fi

  echo
  echo "### 23 days"
  echo
  if (( c23_count == 0 )); then
    echo "- (none)"
  else
    local p23
    for p23 in "${near23[@]}"; do
      echo "- ${p23}"
    done
  fi

  echo
  echo "### 22 days"
  echo
  if (( c22_count == 0 )); then
    echo "- (none)"
  else
    local p22
    for p22 in "${near22[@]}"; do
      echo "- ${p22}"
    done
  fi

  echo
  echo "## Per-day player lists"
  echo

  for d in {1..24}; do
    local claimed="${claimed_counts[$d]:-0}"
    local names="${names_by_day[$d]}"
    echo "### Day ${d} (${claimed} players)"
    if [[ -z "$names" ]]; then
      echo "- (none)"
    else
      echo "- ${names}"
    fi
    echo
  done

  echo
  echo "## All players by days claimed (most to least)"
  echo

  if ((${#all_lines[@]} == 0)); then
    echo "- (none)"
  else
    local IFS=$'\n'
    local sorted=($(printf '%s\n' "${all_lines[@]}" | sort -rn -k1,1))
    unset IFS

    local entry count label
    for entry in "${sorted[@]}"; do
      count=${entry%%$'\t'*}
      label=${entry#*$'\t'}
      echo "- ${label}: ${count}"
    done
  fi
}

# --- mode: allnames (unique players sorted by claimed days, with min) ----

show_allnames() {
  local min_days="$1"
  local show_uuid="$2"

  local -a lines=()
  local total_players=0

  while IFS=$'\t' read -r uuid name claimed; do
    [[ -z "${uuid:-}" ]] && continue
    ((total_players++))

    local claimed_count=0
    if [[ -n "${claimed:-}" ]]; then
      claimed_count=$(jq 'to_entries | map(select(.value==true)) | length' <<<"$claimed" 2>/dev/null || echo 0)
    fi

    # apply min filter
    if (( claimed_count < min_days )); then
      continue
    fi

    local label="$name"
    if (( show_uuid )); then
      label="${name} (${uuid})"
    fi

    lines+=("${claimed_count}"$'\t'"${label}")
  done < <(sqlite3 -separator $'\t' "$DB" "SELECT uuid,name,claimedGifts FROM players;")

  if (( total_players == 0 )); then
    echo "No players found in database."
    return
  fi

  local IFS=$'\n'
  local sorted=($(printf '%s\n' "${lines[@]}" | sort -rn -k1,1))
  unset IFS

  echo "All tracked players (unique names) sorted by days claimed (most to least):"
  echo "(Total players in database: ${total_players}, shown with ≥ ${min_days} claimed days)"
  echo

  if ((${#sorted[@]} == 0)); then
    echo "(none match the filter)"
    return
  fi

  local entry count label
  for entry in "${sorted[@]}"; do
    count=${entry%%$'\t'*}
    label=${entry#*$'\t'}
    echo "${label}: ${count}"
  done
}

# --- main -----------------------------------------------------------------

require_tools

if [[ $# -lt 1 ]]; then
  usage
fi

ARG="$1"

# Integer day?
if [[ "$ARG" =~ ^[0-9]+$ ]]; then
  DAY=$ARG
  if (( DAY < 1 || DAY > 24 )); then
    echo "Error: day must be between 1 and 24." >&2
    exit 1
  fi
  UUID_MODE=0
  if [[ "${2-}" == "--uuid" ]]; then
    UUID_MODE=1
  fi
  show_day "$DAY" "$UUID_MODE"
  exit 0
fi

# "all" summary?
if [[ "$ARG" == "all" ]]; then
  UUID_MODE=0
  if [[ "${2-}" == "--uuid" ]]; then
    UUID_MODE=1
  fi
  show_all "$UUID_MODE"
  exit 0
fi

# "complete" (all + full per-day list)
if [[ "$ARG" == "complete" ]]; then
  UUID_MODE=0
  if [[ "${2-}" == "--uuid" ]]; then
    UUID_MODE=1
  fi
  show_complete "$UUID_MODE"
  exit 0
fi

# "allnames" (unique players sorted by claimed days, optional minDays + uuid)
if [[ "$ARG" == "allnames" ]]; then
  local_min=0
  local_uuid=0

  second="${2-}"
  third="${3-}"

  if [[ -n "$second" ]]; then
    if [[ "$second" =~ ^[0-9]+$ ]]; then
      local_min="$second"
      if [[ "$third" == "--uuid" ]]; then
        local_uuid=1
      fi
    elif [[ "$second" == "--uuid" ]]; then
      local_uuid=1
    fi
  fi

  show_allnames "$local_min" "$local_uuid"
  exit 0
fi

# "stats" markdown overview
if [[ "$ARG" == "stats" ]]; then
  show_stats_markdown
  exit 0
fi

# Otherwise: treat as playername or UUID (case-insensitive name)
UUID_MODE=0
if [[ "${2-}" == "--uuid" ]]; then
  UUID_MODE=1
fi
show_player "$ARG" "$UUID_MODE"
