#!/usr/bin/env bash

# @Filename: 1MB-parse-logins.sh
# @Version: 0.0.1, build 001
# @Release: April 12th, 2025
# @Description: Helps us find alt accounts from /logs/
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-parse-logins.sh
# @Syntax: ./1MB-parse-logins.sh
# TODO:  <playername | ip | uuid> params?
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

# @info:
# - Tailored to work on macOS / Ubuntu
# - Recursively processes .log and .log.gz files in the /logs/ directory.
# - Extracts playernames and IPs from lines like: "PlayerName[/IP:PORT] logged in ..."
# - Logs raw data into a timestamped file like "2025-04-12.log", for use in other .sh scripts.
# - Generates a second file "2025-04-12-completed.log" showing which usernames share the same IP
# - Blacklist for <playername> and <ip> to filter out knowns/falsepositives

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

LOG_DIR="./logs"
TIMESTAMP=$(date +%Y-%m-%d)
RAW_LOG="${TIMESTAMP}.log"
FINAL_LOG="${TIMESTAMP}-completed.log"
BLACKLIST_USERS="./blacklist_users.txt"
BLACKLIST_IPS="./blacklist_ips.txt"

# TODO
# - create blacklist_users.txt looking like
# Notch
# mrfloris
# - create blacklist_ips.txt looking like
# 127.0.0.1
# 192.168.0.1


### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# Ensure output files are empty
> "$RAW_LOG"
> "$FINAL_LOG"
# might need to figure this out later for automated crontabbing

# TODO
# echo the output so we know we've started
# Find and process log files (plain and gzipped)
# Check blacklists
# Sort and deduplicate
# Group usernames by IP with awk?
# echo the output so we know we're done


#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com