#!/bin/bash

# @Filename: 1MB-ChristmasPlusAll.sh
# @Version: 0.0.2, build 002
# @Release: February 2nd, 2025
# @Description: Runs 1MB-ChristmasPlus.sh in a loop to get some player data from ChristmasPlus database.db
# @Contact: I am #momshroom on Discord, and Momshroom in MineCraft.
# @Discord: @momshroom on https://discord.gg/ySRPTYTtKf
# @Install: chmod u+x 1MB-ChristmasPlusAll.sh
# @Syntax: ./1MB-ChristmasPlusAll.sh []
# Much copied from @floris 1MB-ChristmasPlus.sh which is also required to run this.
# @URL: Latest source, info, & support: https://github.com/Momshroom/1MB/tree/master/Resources/ChristmasPlus/1MB-ChristmasPlusAll.sh

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


# Check parameter for "complete" or "any"
# And based on length of username, assume uuid or username, and update query accordingly.
_paramParticpationLevel="${1:-$1}"
if [ -z "$_paramParticpationLevel" ]; then
# The query we need to retrieve the list of players who have claimed at least one gift
    query="SELECT name FROM players WHERE claimedGifts LIKE '%true%' ORDER BY upper(name);"
    printf "Syntax: %s <any|complete>\n" "$0"
    printf "Description: Get player gift data from the ChristmasPlus '$_databaseFile' database.\n"
    printf "Description: For either any participate or only those who missed no gifts.\n"
    printf "Example: We are going to gather output for those that collected any gifts."

elif [ "$_paramParticpationLevel" == "complete" ]; then
# The query we need to retrieve the list of players who have claimed at least one gift
    query="SELECT name FROM players WHERE claimedGifts NOT LIKE '%false%' ORDER BY upper(name);"
    printf "Processing only players that collected all gifts"
fi


# We want to check case insensitive
_columnName="name COLLATE NOCASE"
_columnQueryFor="name" # only used visually




# Now that we know the database.db fle exists, and the query to run, lets connect and build a result
result=$(sqlite3 "$_databaseFile" "$query")

# Check if there is a result to work with and, if so, run the script once per name found
if [ -n "$result" ]; then
    for name in $result ;  do ./1MB-ChristmasPlus.sh $name; done

else
	# worst case scenario we have no data
    printf "Oops, no players found that matched in that database."
    exit 1
fi

#EOF
