#!/usr/bin/env bash

# @Filename: 1MB-template.sh
# @Version: 1.1.2, build 009
# @Release: February 2nd, 2025
# @Description: Helps us clone /template to /server
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-template.sh
# @Syntax: ./1MB-template.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

_debug=true # Set to false to minimize output.
_workingDir="/home/minecraft"

# port checking variables
_file="server.properties" # default server properties file
_port="25565" # default port
_proc="java" # default process to check for
# end port checking variables

Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

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
        [[ "$_debug" == true ]] && echo -e "$Y$_prefix$C $_args $R"
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        echo -e "\\n$_prefix $_args"
    ;;
    esac
}

# check if the startup parameter --help is provided, and if so, display synopsis
if [[ $1 == "--help" ]]; then
    _output okay "Usage: ./1MB-template.sh [port_number] \\n"
fi

_output debug "Okay, starting script.."

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"

_output debug "Setting unique timestamp.."
now=$(date +"%m_%d_%Y_%H%M%S")

_output debug "Changing to working dir.."
cd $_workingDir || _output oops "Something is wrong, I could not change to this directory."

_output debug "Attempting to check if the live /server/ is still running..."

PORT="$_port"
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

_output debug "Done checking for '$_proc/:$PORT.'"

# Check for active tmux sessions
active_sessions=$(tmux list-sessions)
if [ -n "$active_sessions" ]; then
  _output oops "Active tmux sessions:\\n $active_sessions \\n Please 'exit' those first."
else
  _output debug "No active tmux sessions, we can continue. It looks like the server was properly shut down."
fi

_output debug "Creating server-$now.tar.gz, this might take a moment.."
tar -cpzf $_workingDir/archive/server-"$now".tar.gz -C $_workingDir server

_output debug "Purging old /server/ dir.."
rm -rf $_workingDir/server/

_output debug "Attempting to update Paper jar"
cd "/home/minecraft/templates/server/"
bash "./1MB-UpdatePaper.sh"
cd $_workingDir

_output debug "Restoring /server/ from /templates/.."
cp -R $_workingDir/templates/server/ $_workingDir/server/

_output okay "Done. You can start the server if you want."

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com