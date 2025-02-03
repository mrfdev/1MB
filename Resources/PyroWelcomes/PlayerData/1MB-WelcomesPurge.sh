#!/usr/bin/env bash

# @Filename: 1MB-WelcomesPurge.sh
# @Version: 1.0.2, build 004 for PyroWelcomesPro v0.4.2
# @Release: February 2nd, 2025
# @Description: Helps us identify old files to purge for players with 0 points.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-WelcomesPurge.sh
# @Syntax: ./1MB-WelcomesPurge.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# This is used to try and find files older than x days. Default is 1000, meaning nearly 3 years.
_purgeTime="1000"

# This is used to only purge files older than x weeks, where `WelcomePoints: 0` (default is 0)
# If this is set to 1 or 2, it will only purge from the results, if it is exactly 1 or exactly 2.
_purgePoints="0"

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

_debug=true # Set to false to minimize output.

function _output {
    case "$1" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        echo -e "\\n$B$Y$_prefix$X $_args $R" >&2; exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R\\n" >&2; exit 1
    ;;
    info)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R" >&2
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        [[ "$_debug" == true ]] && echo -e "$Y$_prefix$I $_args $R"
    ;;
    *)
        _args="${*:1}"; _prefix="$C$B>$R";
        echo -e "$_prefix $_args"
    ;;
    esac
}

# [[ "$_debug" == true ]] && _mvParams="-fv" || _mvParams="-f"

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"
I="\\033[0;90m"; B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m" # theme

# todo : see if we have a backup dir to move yml files to

_output info "Starting..."
_output debug "Trying to find <uuid>.yml files older than $_purgeTime days, and moving the ones with $_purgePoints points to a backup directory.\\n"

for i in $(find . -maxdepth 1 -name '*.yml' -type f -mtime +${_purgeTime}); do
    grep -Fq "WelcomePoints: $_purgePoints" $i; 
    if [ $? -eq 0 ]; then
        _output debug "Found and moved  $i"
        mv -f $i ./backup
    else
        _output debug "Found and kept   $i"
    fi
done

_output okay "...Done!"

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com