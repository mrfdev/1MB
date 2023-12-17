#!/bin/bash

# @Filename: 1MB-ChristmasPlus.sh
# @Version: 0.2.1, build 012
# @Release: December 18th, 2023
# @Description: Helps us get some player data from ChristmasPlus database.db
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-ChristmasPlus.sh
# @Syntax: ./1MB-ChristmasPlus.sh username
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# SQLite3 ChristmasPlus 2.32.2 database.db file is expected,
# if you have renamed it, change that here obviously.
# you can also set a full path like /full/path/to/database.db
_databaseFile="./database.db"

# If no param is provided, we fall back to a default username
# can be uuid
_userName="FumbleHead"

# output to a log file?
_log="false"
_logFile="christmasplus-results-$_userName-.log"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if needed.
#
###

_debug=true # Set to false to minimize output.

# TODO at some point get my printf function stuff so i can hide debug and print results a little nicer
Y="\e[33m"; C="\e[36m"; PB="\e[38;5;153m"; B="\e[1m" R="\e[0m" # theme

### END OF CONFIGURATION
#
# Stop configuring things
# beyond this point. I mean it.
#
###

# Lets exit if jq is not found, since we depend on it
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. I cannot continue. Please install 'jq' to proceed ('brew install jq' on macOS)."
    exit 1
fi

# Check if a username is provided, if not, use the configured _userName
# And based on length of username, assume uuid or username, and update query accordingly.
if [ -n "$1" ]; then
    _userName="$1"
else
    _userName="$_userName"
fi

# Check param length, 
# if it is longer than 16 characters, use uuid column, else name column
if [ ${#_userName} -gt 16 ]; then
    _columnName="uuid"
else
    _columnName="name"
fi

# does expected .db file exist in the same directory?
if [ ! -f "$_databaseFile" ]; then
    echo "Error: '$_databaseFile' not found in the current directory."
    exit 1
fi

# The query we need to retrieve the data from field claimedGifts (for given username)
query="SELECT claimedGifts FROM players WHERE $_columnName='$_userName';"

# Now that we know the database.db fle exists, and the query to run, 
# lets connect and build a result
result=$(sqlite3 "$_databaseFile" "$query")

# Before we do anything, some debug data to compare against
# if [ -n "$result" ]; then
#     echo "Claimed-gifts results for $_userName: $result"
# else
#     echo "No claimed gifts found for $_userName."
# fi

# Check if there is a result to work with
if [ -n "$result" ]; then
    # Split result into array and use jq to figure it out for me
    true_claimed=($(echo "$result" | jq -r 'to_entries[] | select(.value == true) | .key'))
    false_unclaimed=($(echo "$result" | jq -r 'to_entries[] | select(.value == false) | .key'))
    
    # Spit out the sorted results:
    echo "Gifts claimed (true): ${true_claimed[@]}"
    echo "Gifts unclaimed (false): ${false_unclaimed[@]}"
else
	# worst case scenario we have no data
    echo "Oops, no gifts found for $_userName."
fi