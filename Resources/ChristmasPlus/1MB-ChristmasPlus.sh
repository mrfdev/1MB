#!/bin/bash

# @Filename: 1MB-ChristmasPlus.sh
# @Version: 0.0.1, build 002
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
_databaseFile="database.db"

# If no param is provided, we fall back to a default username
# TODO: support UUID for obvious reasons
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

Y="\e[33m"; C="\e[36m"; PB="\e[38;5;153m"; B="\e[1m" R="\e[0m" # theme

### END OF CONFIGURATION
#
# Stop configuring things
# beyond this point. I mean it.
#
###

