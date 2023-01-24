#!/bin/bash

# @Filename: 1MB-CheckPort.sh
# @Version: 2.0.1, build 015
# @Release: January 24th, 2023
# @Description: Spits out if java proc (Minecraft server) is running on (provided) port or not.
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

_debug=true # Set to false to minimize output.

Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

### END OF CONFIGURATION
#
# Really stop configuring things
# beyond this point. I mean it.
#
###

# Function that we use to handle the output to the screen
function _output {
    case "$1" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        printf "\n%b" "$B$Y$_prefix $X $_args $R" >&2; exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        printf "\n%b" "$B$Y$_prefix $C $_args $R" >&2; exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        [[ "$_debug" == true ]] && printf "%b\n" "$Y$_prefix$C $_args $R" >&2
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        printf "%b\n" "$Y$_prefix$C $_args $R"
    ;;
    esac
}

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!" # You should only use this script as a regular user

# check if the startup parameter --help is provided, and if so, display synopsis
if [[ $1 == "--help" ]]; then
    _output "This script checks if the provided port number is in use by a java process"
    _output "If a port number is not provided, it will default to the one set for _proc,"
    _output "but if then server.properties is found, it will extract the port number from there."
    _output okay "Usage: ./1MB-CheckPort.sh [port_number] \\n"
fi

# Check if user provided a port number
if [ -n "$1" ]; then
    _port="$1"
    _output debug "We found user input for port: '$_port', we are going to skip checking for server.properties, and try this port number right away"
    PORT="$_port"
else
    # user did not provide a port number, for now, lets default to the config of _port, but since we're not looking for a user provided port, lets check if server.properties exists and if we can get its defined port number, otherwise fall back to the config's default 
    # _port="$_port"
    # check if the server.properties file is in this working directory, and if so, extract the port number from it, then we will use that, instead defaulting to one set at the start.
    if [ -f "$_file" ]; then
      PORT=$(grep "server-port" server.properties | cut -d'=' -f2)
      _output debug "server-port value is $PORT"
    else
      _output debug "The file '$_file' not found in current directory, we will assume we need to check for the default server port, which is $_port"
      PORT="$_port"
    fi
fi

# We now know which port number we want to work with, but, is it really a number?
# check if the provided input is a number
if ! [[ $PORT =~ ^[0-9]+$ ]] ; then
   _output oops "Error: Port should be a number."
fi

# Check if port $PORT number is in use
if lsof -i :$PORT > /dev/null; then
    # Check if $PORT number is the process we're looking for (as extra bit of info, also gives proc id)
    if lsof -iTCP -sTCP:LISTEN -n -P |grep "$_proc.*:$PORT"; then
      _output debug "A $_proc process is running on port $PORT"
      # ps aux | grep "$_proc"
    else
      _output debug "No $_proc process found running on port $PORT"
    fi
    # report back and exit
    _output oops "Port $PORT seems to be in use, we cannot continue."
else
  _output debug "Port $PORT does not seem to be in use, we can start a server"
fi

_output okay "Done checking for '$_proc/:$PORT.'"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com