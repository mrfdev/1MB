#!/bin/bash

# @Filename: 1MB-ChristmasPlusAll.sh
# @Version: 0.0.1, build 001
# @Release: June 23, 2024
# @Description: Runs 1MB-ChristmasPlus.sh in a loop to get some player data from ChristmasPlus database.db
# @Contact: I am #momshroom on Discord, and Momshroom in MineCraft.
# @Discord: @momshroom on https://discord.gg/ySRPTYTtKf
# @Install: chmod u+x 1MB-ChristmasPlusAll.sh
# @Syntax: ./1MB-ChristmasPlusAll.sh 
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# All other configuration should be done in the 1MB-ChristmasPlus.sh file from floris
# All this file does is run floris' script in a loop.
#

# SQLite3 ChristmasPlus 2.32.2 database.db file is expected,
# if you have renamed it, change that here obviously.
# you can also set a full path like /full/path/to/database.db
_databaseFile="./database.db"

###



# Function for handling errors
handle_error() {
    local message="$1"
    echo "Error: $message"
    exit 1
}

# Lets exit if jq is not found, since we depend on it
if ! command -v jq &> /dev/null; then
    printf "Could not find 'jq' installed. Install 'jq' to proceed. 'brew install jq' on macOS or 'apt install jq' on Ubuntu\n"
    exit 1
fi

# Does the expected database.db file exist in the same directory?
if [ ! -f "$_databaseFile" ]; then
    echo "Error: '$_databaseFile' not found in the current directory."
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


# The query we need to retrieve the list of players who have claimed at least one gift
query="select name from players where claimedGifts LIKE '%true%';"

# Now that we know the database.db fle exists, and the query to run, lets connect and build a result
result=$(sqlite3 "$_databaseFile" "$query")

# Check if there is a result to work with
if [ -n "$result" ]; then
    for name [ [in ["$result"] ] ; ] do echo name; done

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
