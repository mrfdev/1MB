#!/bin/bash

# @Filename: 1MB-ChristmasPlus.sh
# @Version: 0.2.2, build 017
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
_user="FumbleHead"

# output to a log file?
_log=true
_logFile="christmasplus-results.log"

### END OF CONFIGURATION
#
# Stop configuring things
# beyond this point. I mean it.
#
###

# Lets exit if jq is not found, since we depend on it
if ! command -v jq &> /dev/null; then
    printf "Error: 'jq' is not installed. Please install 'jq' to proceed.\n"
    exit 1
fi

# Check if a username is provided, if not, use the configured _userName
# And based on length of username, assume uuid or username, and update query accordingly.
if [ -n "$1" ]; then
    _userName="$1"
else
    _userName="$_user"
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

# Check if there is a result to work with
if [ -n "$result" ]; then
    # Split result into array and use jq to figure it out for me
    true_claimed=($(echo "$result" | jq -r 'to_entries[] | select(.value == true) | .key | @sh'))
    false_unclaimed=($(echo "$result" | jq -r 'to_entries[] | select(.value == false) | .key | @sh'))

    # Spit out the sorted results:
    printf "\n%s:\n" "$_userName"
    printf "Gifts claimed (true): %s\n" "${true_claimed[*]}"
    printf "Gifts unclaimed (false): %s\n\n" "${false_unclaimed[*]}"
else
	# worst case scenario we have no data
    printf "Oops, no gifts found for %s.\n" "$_userName"
fi

# Deal with writing results to .log file
# Only if we want to; create the file if it does not exist
if $_log; then
    if [ -f "$_logFile" ]; then
        # The file exists, we can append to the end
        echo "Log file '$_logFile' already exists."
    else
        # We could not find it, it does not seem to exist
        # Let's create it first before we write to it
        echo "Log file '$_logFile' does not exist."
        touch "$_logFile"  # Create the log file since we want to use it
        if [ $? -eq 0 ]; then
            echo "Log file '$_logFile' newly created successfully."
        else
            # report back if there's some sort of issue
            echo "Failed to create log file '$_logFile'. Exiting."
            exit 1
        fi
    fi
    # Now that we know we have a file, we can append data to it.
    currentDateTime=$(date +'%B %d, %Y @ %H:%M') # timestamp to prefix log entry with
    printf "\n%s: (Logged at %s)\n" "$_userName" "$currentDateTime" >> "$_logFile"
    printf "Gifts claimed (true): %s\n" "${true_claimed[*]}" >> "$_logFile"
    printf "Gifts unclaimed (false): %s\n\n" "${false_unclaimed[*]}" >> "$_logFile"
    printf ".. Done, results for '%s' written to '%s'.\n" "$_userName" "$_logFile"

fi
