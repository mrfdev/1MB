#!/usr/bin/env bash

# @Filename: 1MB-start.sh
# @Version: 2.15.6, build 067 for Minecraft 1.21.6 (Java 23.0.2, 64bit)
# @Release: June 17th, 2025
# @Description: Helps us start and fork a Minecraft 1.21.6 server session.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-start.sh
# @Syntax: ./1MB-start.sh (name)
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_serverName="mcserver"
# Keep the name short, simple, and lowercase (no numbers or weird characters).
# The name makes it easier to recognize the session in 'tmux ls', you can
# re-attach to the forked sessions with 'tmux attach -t (name)'.

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_sibling="1MB-minecraft.sh"
_debug=true # Set to false to minimize output.

Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
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
        [[ "$_debug" == true ]] && echo -e "$Y$_prefix$C $_args $R"
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
    if [[ "$_input" =~ ^[a-z]+$ ]]; then
        _serverName="$_input"
    else
        _output oops "Provided input is invalid! Input is for a unique '_serverName'. Do not use numbers, spaces or weird chars. Keep it short, and a-z characters only."
    fi
fi

_output debug "Attempting to start your Minecraft '$_serverName' server ... "

if type "tmux" >/dev/null 2>&1; then
    _output debug "Found 'tmux', attempting to create and fork a new tmux session into background ..."
    tmux new -d -s "$_serverName" 2>/dev/null || return 1
    tmux send-keys -t "$_serverName" "./$_sibling" ENTER
    [[ "$_debug" == true ]] && tmux ls; _output debug "To re-attach: tmux attach -t $_serverName"
elif type "screen" >/dev/null 2>&1; then
    _output debug "Could not find 'tmux' (preferred), but found 'screen', attempting to create and fork a new screen session into background ..."
    screen -dmS "$_serverName" bash "$_sibling"
    [[ "$_debug" == true ]] && screen -ls; _output debug "To re-attach: screen -r $_serverName"
else
    _output debug "Oops, 'tmux' (preferred), nor 'screen' seems to be installed. Try installing either. \\n -> macOS: brew install tmux, Ubuntu: apt install screen \\n -> Can't fork session, trying '$_sibling' directly ..."
    sleep 4
    bash "$_sibling" || _output oops "Something is wrong, I could not start your server."
fi

_output debug "Done."

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com