#!/usr/bin/env bash

# @Filename: 1MB-Parse-Logs-Scanners.sh
# @Version: 0.2.3, build 020 for Minecraft 1.21.x /logs/
# @Release: November 23rd, 2024
# @Description: Helps me parse /logs/ of Minecraft server scanners that should be firewalled.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-Parse-Logs-Scanners.sh, and move file to `~/serverdir/`
# @Syntax: .1MB-Parse-Logs-Scanners.sh (playername)
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

## Notes ##
# We are all getting hit quite a bit by these rather intrusive people that scan the IPv4 ranges to find Minecraft servers and surely do fantastic things with the results for whatever reason. 
# This little script is just a quick handy tool I use to point to the /logs/ directory's .log and .gz files, and help generate a separate .log file to hand over to abuse departments who request it.
# Secondly, to help yourself, filter out the intrusive poking, this will pull out the IPv4 addresses they've used, sort them uniqieuly and put them in a separate .txt file. You can then review that manually, or automatically add it to your firewall rules with a crontab.
# You do not have to have a (running) server, just the /logs/ directory. 

## TODO ##
# figure out what to do with the .log and .txt file if we run it again on the same username. 
# * solve issue of false positives, limit to this type of null disconnect msg: (failed disconnects are id=<null>)
# com.mojang.authlib.GameProfile@<random>[id=<null>,name=<playername>,properties={},legacy=false] (/<ip>:<port>) lost connection: Disconnected

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# who are we looking for: (playername) that we expect to find in the log files
# In case no ./sh playername was provided, we default to which one?
default_playername="cuute"

# what directory do we expect these files to reside in (~serverdirectory/logs/, but can be fullpath instead of ./logs/)
# Where are the expected /logs/ files? (can be full path)
path_logs_folder="./logs/"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

# process default username, unless one is provided
# Check if a command-line argument is provided
if [[ $# -gt 0 ]]; then
  find_playername=$1
else
  find_playername=$default_playername
fi

# what files are we outputting to? (playername.log) and (playername-iplist.txt)
# Output: What are the filenames we're trying to store the output into?
# .log is for the full parsed log
# .txt is for the uniquely sorted ip list based on parsed log results
results_player_logfile="results-$find_playername.log"
results_player_ipfile="results-$find_playername.txt"

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# use grep on any .log files, so we dont forget about latest.log or any unpacked ones or old backups we dumped in here
# Find occurrences of playername (case-insensitive) in any .log files where the sentence contains "id=<null>" and ends with "lost connection: Disconnected"
results_log_files=$(find "$path_logs_folder" -type f -name "*.log" -exec grep -Ei "id=<null>.*lost connection: Disconnected$" {} \;)
results_grep=$(echo "$results_log_files" | grep -i "$find_playername")

# Do the same for .gz (gzipped log files), using zgrep
results_gz_files=$(find "$path_logs_folder" -type f -name "*.gz" -exec zgrep -Ei "id=<null>.*lost connection: Disconnected$" {} \;)
results_zgrep=$(echo "$results_gz_files" | grep -i "$find_playername")

# echo results to output files .log and .txt for playername
echo "$results_grep" > "$results_player_logfile"
echo "$results_zgrep" >> "$results_player_logfile"

# Pull the IP addresses from the new .log file, and sort to uniques
results_ipv4_list=$(grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$results_player_logfile" | sort -u)
# And save the results to the .txt file (handy for crontab parsing later)
echo "$results_ipv4_list" > "$results_player_ipfile"


### output

# count up the totals of occurrences found in the grep and zgrep files
results_counting=$(echo "$results_grep" | wc -l)
results_counting=$((results_counting + $(echo "$results_zgrep" | wc -l)))

# print to screen the amount øf times we found occurrences of playername in the log files history
echo "Occurrences found for playername: '$find_playername': $results_counting"

# print list of sorted ips, handy for manual processing
echo "Uniques found: (ip addresses)"
cat "$results_player_ipfile"

#EOF Copyright (c) 1977-2024 - Floris Fiedeldij Dop - https://scripts.1moreblock.com