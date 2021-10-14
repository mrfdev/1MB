#!/usr/bin/env bash

# @Filename: 1MB-CheckPort.sh
# @Version: 1.2, build 009
# @Release: October 15th, 2021
# @Description: Spits out if proc is running on port or not.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/floris
# @Install: chmod a+x 1MB-CheckPort.sh
# @Syntax: ./1MB-CheckPort.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_file="server.properties" # default server properties file
_port="25565" # default port
_proc="java" # default process to check for

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_check="$_proc" # default for when all checks fail (lets just print all listening procs) 
_debug=true # default spit out any output?

### END OF CONFIGURATION
#
# Really stop configuring things
# beyond this point. I mean it.
#
###

function _output {
    case "$1" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        echo -e "\\n$B$Y$_prefix$X $_args $R" >&2; exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R" >&2; exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        [[ "$_debug" == true ]] && echo -e "\\n$Y$_prefix$C $_args $R"
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        echo -e "\\n$_prefix $_args"
    ;;
    esac
}

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"
Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

_netfind() {
    if [ $# -eq 0 ]; then
        lsof -iTCP -sTCP:LISTEN -n -P || _output debug "Nope, found nothing listening"
    elif [ $# -eq 1 ]; then
        lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color "$1" || _output debug "Nope, found nothing listening"
    else
        _output oops "Something went wrong."
    fi
}


# Check if we have _file, if so, if we can find _port and show _proc, otherwise try to list all _proc
if [[ -f "$_file" ]]; then
    _checkFile=$(grep "^server-port=" $_file)
    if [ -z "$_checkFile" ]
        then
        _output debug "We found the '$_file' file, but it has no port defined (check the file!) \n Defaulting to checking for all instances of '$_proc' instead:"
    else
        _port=$(grep "^server-port=" $_file | awk -F= '{print $2}')
        _output debug "We found the '$_file' file with a defined port \n lets find the running proc '$_proc' on port '$_port':"
        _check="$_port"
    fi
else
    _output debug "Could not find the '$_file' file, checking for all instances of '$_proc' instead:"
fi

# And finally do the check
_netfind "$_check"

#EOF Copyright (c) 2011-2021 - Floris Fiedeldij Dop - https://scripts.1moreblock.com