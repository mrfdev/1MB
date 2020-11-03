#!/bin/bash

# @Filename: 1MB-start.sh
# @Version: 2.0, build 031 for Spigot 1.16.4 (java 11)
# @Release: November 3rd, 2020
# @Description: Helps us start and fork a Minecraft 1.16.4 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-start.sh
# @Syntax: ./1MB-start.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_serverName="mcserver"
# This name makes it easier to spot in 'screen -ls'
# Keep this lowercase, short, simple, no weird characters

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

_sibling="1MB-minecraft.sh"
_debug=true # Set to false to minimize output.

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
        [[ "$_debug" == true ]] && echo -e "\\n$Y$_prefix$C $_args $R"
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        echo -e "\\n$_prefix $_args"
    ;;
    esac
}

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"
[ ! -x "$_sibling" ] && _output oops "This '$0' script requires '$_sibling' to work and be executable. Correct the permissions, or download it from https://scripts.1moreblock.com/ "

if [ -n "$1" ]; then
    _input=$(echo "$1" | awk '{ print tolower($1) }'); _input=$(echo "${_input}" | awk '{print substr ($0, 0, 16)}');
    [[ "$_input" =~ ^[a-z]+$ ]] && _serverName="$_input" || _output oops "Provided input is invalid! Input is for a unique '_serverName'. Do not use numbers, spaces or weird chars. Keep it short, and a-z characters only."
fi

_output debug "Attempting to start your Minecraft '$_serverName' server ... "

if type "screen" >/dev/null 2>&1; then
    _output debug "Found 'screen', attempting to fork session into background ..."
    screen -dmS $_serverName bash "$_sibling"
    [[ "$_debug" == true ]] && screen -ls
elif type "tmux" >/dev/null 2>&1; then
    _output debug "Could not find 'screen', but found 'tmux', attempting to fork session into background ..."
    tmux new -d -s "$_serverName" 2>/dev/null || return 1
    tmux send-keys -t "$_serverName" "./$_sibling" ENTER
    [[ "$_debug" == true ]] && tmus ls && _output debug "To re-attach: tmux attach -t $_serverName"
else
    _output debug "Oops, 'screen', nor 'tmux' seems to be installed. Try installing either. \\n -> macOS: brew install tmux, Ubuntu: apt install screen \\n -> Can't fork session, trying '$_sibling' directly ..."
    sleep 4
    bash "$_sibling" || _output oops "Something is wrong, I could not start your server."
fi

_output debug "Done."

#EOF (c)2011-2020 Floris Fiedeldij Dop