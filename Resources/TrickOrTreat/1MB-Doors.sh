#!/usr/bin/env bash

# @Filename: 1MB-Doors.sh
# @Version: 1.0.1, build 004
# @Release: June 7th, 2023
# @Description: Shell script for Trick or Treat v 2.4, count doors players have found
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-Doors.sh (put this file in ~/plugins/TrickOrTreatV2/)
# @Syntax: ./1MB-Doors.sh <player>
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# Resource https://www.spigotmc.org/resources/halloween-trick-or-treating.48699/

# Database name in case you want to test on some copy first
_databaseFile="totdatabase.db"

# Could be /full/path (i.e. /usr/bin/sqlite3)
_database="sqlite3"

### END OF CONFIGURATION
#
# Really stop configuring things
# beyond this point. I mean it.
#
###

_output="Syntax: ./1MB-Doors.sh <player>" #something to start with

# We require a name of a player
if [ -z "$1" ]; then
    echo "$_output"
    exit 0
fi

# lets see what we can find, if anything
if [ -f "$_databaseFile" ]; then
    _databaseQuery=$($_database "$_databaseFile" "SELECT COUNT(*) FROM interactions WHERE player_name=='$1';")
    _output="$1 $_databaseQuery"
else
    _output="Found no database named: '$_databaseFile', .."    
fi

# spit out what we found
echo "$_output"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com