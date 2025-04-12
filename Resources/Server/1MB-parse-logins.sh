#!/usr/bin/env bash

# @Filename: 1MB-parse-logins.sh
# @Version: 0.0.4, build 004
# @Release: April 12th, 2025
# @Description: Helps us find alt accounts from /logs/
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-parse-logins.sh
# @Syntax: ./1MB-parse-logins.sh
# ./parse-logins.sh Normal mode, generate log and IP sharing report
# ./parse-logins.sh --search-user Notch
# ./parse-logins.sh --search-ip 127.0.0.1
# ./parse-logins.sh --search-uuid 069a79f4-44e9-4726-a5be-fca90e38aaf5

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

#### TODO

# - create blacklist_users.txt looking like
# Notch
# mrfloris

# - create blacklist_ips.txt looking like
# 127.0.0.1
# 192.168.0.1

# - create blacklist_uuids.txt looking like
# 069a79f4-44e9-4726-a5be-fca90e38aaf5
# 631e3896-da2a-4077-974b-d047859d76bc

# echo the output so we know we've started
# echo the output so we know we're done


### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# Handy helper that we can use later
is_blacklisted() {
  local item="$1"
  local file="$2"
  grep -q -x "$item" "$file" 2>/dev/null
}

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
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--search-user USERNAME] [--search-ip IP] [--search-uuid UUID]"
      exit 1
      ;;
  esac
done

# Okay, now we need some temp files
TMP_LOG=$(mktemp)
UUID_LOG=$(mktemp)

# Parse the log files, so we have something to work with
find "$LOG_DIR" -type f \( -name "*.log" -o -name "*.log.gz" \) | while read -r file; do
  if [[ "$file" == *.gz ]]; then
    # cat wont work, testing with zcat?? otherwise zgrep is an option (and grep)
  else
    cat "$file"
  fi | while read -r line; do
    # Match login lines: username[/IP]
    # also
    # Match UUID lines
  done
done

# Do the particular query type
if [[ -n "$SEARCH_USER" ]]; then
# whatever
fi

if [[ -n "$SEARCH_IP" ]]; then
# whatever
fi

if [[ -n "$SEARCH_UUID" ]]; then
# whatever
fi

# Then sort the results, regardless of type!

# The magic awk magic goes here probably.. gosh, i hope i can figure that out

# Output results


#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com