#!/bin/bash

# @Filename: 1MB-ChristmasPlus.sh
# @Version: 0.3.3, build 027
# @Release: February 2nd, 2025
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
_user="mrfloris"

# output to a log file?
_log=true
_logFile="christmasplus-results.log"

### END OF CONFIGURATION
#
# Stop configuring things
# beyond this point. I mean it.
#
###

# Function for handling errors
handle_error() {
    local message="$1"
    echo "Error: $message"
    exit 1
}

# Lets exit if jq is not found, since we depend on it
if ! command -v jq &> /dev/null; then
    printf "Could not find 'jq' installed. Install 'jq' to proceed. 'brew install jq' on macOS\n"
    exit 1
fi

# Check if a username is provided, if not, use the configured _userName
# And based on length of username, assume uuid or username, and update query accordingly.
_paramUserName="${1:-$1}"
if [ -z "$_paramUserName" ]; then
    _userName="${_user//[^a-zA-Z0-9_\-]/}" # sanitize input
    printf "Syntax: %s <user|uuid>\n" "$0"
    printf "Description: Get player gift data from the ChristmasPlus '$_databaseFile' database.\n"
    printf "Description: You can use their Minecraft username or UUID.\n"
    printf "Example: We are going to try and gather the data for (default) '%s $_userName' ... \n" "$0"
else
    _userName="${_paramUserName//[^a-zA-Z0-9_\-]/}" # sanitize input
    printf "Attempting to find data for '%s $_userName' ... \n" "$0"
fi


# Check param length, 
# if it is longer than 16 characters, use uuid column, else name column
# Set the column name based on the username input
# We want to check case insensitive
_columnName="name COLLATE NOCASE"
_columnQueryFor="name" # only used visually
if [ ${#_userName} -gt 16 ]; then
    _columnName="uuid"
    _columnQueryFor="uuid" # only used visually
fi

# Does the expected database.db file exist in the same directory?
if [ ! -f "$_databaseFile" ]; then
    echo "Error: '$_databaseFile' not found in the current directory."
    exit 1
fi

# The query we need to retrieve the data from field claimedGifts (for given user or uuid)
query="SELECT claimedGifts FROM players WHERE $_columnName='$_userName';"

# Now that we know the database.db fle exists, and the query to run, lets connect and build a result
result=$(sqlite3 "$_databaseFile" "$query")

# Check if there is a result to work with
if [ -n "$result" ]; then
    # Split result into array and use jq to figure it out for me
    true_claimed=($(echo "$result" | jq -r 'to_entries[] | select(.value == true) | .key | @sh'))
    false_unclaimed=($(echo "$result" | jq -r 'to_entries[] | select(.value == false) | .key | @sh'))

    # Spit out the sorted results:
    printf "\n%s:\n" "$_userName"
    printf "Gifts claimed: %s\n" "${true_claimed[*]}"
    printf "Gifts unclaimed: %s\n\n" "${false_unclaimed[*]}"
else
	# worst case scenario we have no data
    printf "Oops, no gifts found for %s, check if the %s is valid.\n" "$_userName" "$_columnQueryFor"
    exit 1
fi

# Deal with writing results to .log file
# Only if we want to log (default is true)
if $_log; then
    # Append data to the log file
    currentDateTime=$(date +'%B %d, %Y @ %H:%M') # timestamp for log entry
    {
        printf "\n%s (Logged at %s)\n" "$_userName" "$currentDateTime"
        printf "Gifts claimed: %s\n" "${true_claimed[*]}"
        printf "Gifts unclaimed: %s\n\n" "${false_unclaimed[*]}"
    } >> "$_logFile" || handle_error "Failed to write to log file '$_logFile'. Exiting."
    printf ".. Done! The results for '%s' have been appended to '%s'.\n" "$_userName" "$_logFile"
fi

#EOF
