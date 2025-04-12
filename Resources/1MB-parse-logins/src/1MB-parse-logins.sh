#!/usr/bin/env bash

# @Filename: 1MB-parse-logins.sh
# @Version: 0.3.2 build 032
# @Release: April 12th, 2025
# @Description: Helps us find alt accounts from /logs/
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-parse-logins.sh
# @Syntax: ./1MB-parse-logins.sh
# cd /server-directory/
# ./1MB-parse-logins.sh Normal mode, generate log and IP sharing report
# ./1MB-parse-logins.sh --search-user mrfloris
# ./1MB-parse-logins.sh --search-ip 127.0.0.1
# ./1MB-parse-logins.sh --search-uuid 631e3896-da2a-4077-974b-d047859d76bc

# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

# @info:
# - Tailored to work on macOS / Ubuntu
# - Recursively processes .log and .log.gz files in the /logs/ directory.
# - Extracts playernames and IPs from lines like: "PlayerName[/IP:PORT] logged in ..."
# - Logs raw data into a timestamped file like "2025-04-12.log", for use in other .sh scripts.
# - Generates a second file "2025-04-12-completed.log" showing which usernames share the same IP
# - Blacklist for <playername> and <ip> to filter out knowns/falsepositives

### YOUR CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. 
#
###

LOG_DIR="./logs"
TIMESTAMP=$(date +%Y-%m-%d)
RAW_LOG="${TIMESTAMP}.log"
FINAL_LOG="${TIMESTAMP}-completed.log"

BLACKLIST_USERS="./blacklist_users.txt"
BLACKLIST_IPS="./blacklist_ips.txt"
BLACKLIST_UUIDS="./blacklist_uuids.txt"

### OPTIONAL INTERNAL CONFIGURATION
#
# Declarations here that you don't have to think about
#
###

SEARCH_USER=""
SEARCH_IP=""
SEARCH_UUID=""

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

echo "Starting..."

# Handy helper that we can use later
is_blacklisted() {
  local item="$1"
  local file="$2"
  grep -q -x "$item" "$file" 2>/dev/null
}

# Check or create blacklist files
check_or_create_blacklist() {
  local file="$1"
  local name="$2"
  if [[ -f "$file" ]]; then
    if [[ $YES_MODE -eq 1 ]]; then
      echo "$name exists. Skipping prompt due to --yes flag."
    else
      echo "$name exists. Overwrite? (y/n)"
      read -r answer
      if [[ "$answer" == "y" ]]; then
        > "$file"
        echo "$name has been cleared."
      else
        echo "Keeping existing $name."
      fi
    fi
  else
    echo "$name does not exist. Creating..."
    > "$file"
  fi
}

# default no --yes mode
YES_MODE=0

# Before we make some temp files, let's identify what type of search we're trying to do
# Are we querying for a playername, playerip, or playeruuid, else report the param syntax is invalid, else skip this whole thing and do everything.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --search-user)
      SEARCH_USER="$2"
      shift 2
      ;;
    --search-ip)
      SEARCH_IP="$2"
      shift 2
      ;;
    --search-uuid)
      SEARCH_UUID="$2"
      shift 2
      ;;
    --yes)
      YES_MODE=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--search-user USERNAME] [--search-ip IP] [--search-uuid UUID] [--yes]"
      exit 1
      ;;
  esac
done

check_or_create_blacklist "$BLACKLIST_USERS" "User blacklist"
check_or_create_blacklist "$BLACKLIST_IPS" "IP blacklist"
check_or_create_blacklist "$BLACKLIST_UUIDS" "UUID blacklist"

# Okay, now we need to deal with some temp files
# Verify logs directory exists
if [[ ! -d "$LOG_DIR" ]]; then
  echo "Error: '$LOG_DIR' directory not found. Please make sure logs are located at ./logs/"
  exit 1
fi

# Temp files
TMP_LOG=$(mktemp)
UUID_LOG=$(mktemp)

# Parse the log files, so we have something to work with
find "$LOG_DIR" -type f \( -name "*.log" -o -name "*.log.gz" \) -print0 | while IFS= read -r -d '' file; do
  echo "Processing: $file: ..."

  case "$file" in
    *.gz)
      echo "debug: $file with zgrep"
      zgrep -ai 'logged in' -- "$file"
      ;;
    *)
      echo "debug: $file with grep"
      grep -ai 'logged in' -- "$file"
      ;;
  esac | while IFS= read -r line; do
    echo "  Debug line: $line"  # for debug, remove later

    if [[ "$line" =~ ^.*\[Server\ thread/INFO\]:\ ([^[:space:]]+)\[/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
      user="${BASH_REMATCH[1]}"
      ip="${BASH_REMATCH[2]}"
      if is_blacklisted "$user" "$BLACKLIST_USERS"; then continue; fi
      if is_blacklisted "$ip" "$BLACKLIST_IPS"; then continue; fi
      echo "$user $ip" >> "$TMP_LOG"
    fi

    if [[ "$line" =~ UUID\ of\ player\ ([^[:space:]]+)\ is\ ([a-f0-9\-]+) ]]; then
      user="${BASH_REMATCH[1]}"
      uuid="${BASH_REMATCH[2]}"
      if is_blacklisted "$uuid" "$BLACKLIST_UUIDS"; then continue; fi
      echo "$user $uuid" >> "$UUID_LOG"
    fi
  done
done


# Do the particular query type
if [[ -n "$SEARCH_USER" ]]; then
  echo "Searching for username: $SEARCH_USER"
  grep -i "^$SEARCH_USER " "$TMP_LOG"
  grep -i "^$SEARCH_USER " "$UUID_LOG"
  exit 0
fi

if [[ -n "$SEARCH_IP" ]]; then
  echo "Searching for IP: $SEARCH_IP"
  grep -i " $SEARCH_IP$" "$TMP_LOG"
  exit 0
fi

if [[ -n "$SEARCH_UUID" ]]; then
  echo "Searching for UUID: $SEARCH_UUID"
  grep -i " $SEARCH_UUID$" "$UUID_LOG"
  exit 0
fi

# Then sort the results, regardless of type!
sort "$TMP_LOG" | uniq > "$RAW_LOG"
sort "$UUID_LOG" | uniq > "${RAW_LOG/.log/-uuids.log}"

# The magic awk magic goes here probably.. gosh, i hope i can figure that out
# disclaimer: What I tried kept failing, especially on macOS, so asked ChatGPT to review my code
# and as it turned out, I approached this wrong and so we're trying this instead now. 
# split(users_by_ip[ip], arr, ", ") within {.{.}.}

awk '
{
  user = $1
  ip = $2
  users_by_ip[ip] = (users_by_ip[ip] ? users_by_ip[ip] ", " : "") user
}
END {
  for (ip in users_by_ip) {
    split(users_by_ip[ip], arr, ", ")
    if (length(arr) > 1)
      printf "IP %s is shared by: %s\n", ip, users_by_ip[ip]
  }
}
' "$RAW_LOG" > "$FINAL_LOG"

# Output results
echo "Done."
echo "- Logins: $RAW_LOG"
echo "- Shared IP report: $FINAL_LOG"
echo "- UUIDs: ${RAW_LOG/.log/-uuids.log}"

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com