#!/bin/bash

# @Filename: 1MB-minecraft.sh
# @Version: 2.1, build 033 for Spigot 1.16.5 (java 11)
# @Release: January 16th, 2021
# @Description: Helps us start a Minecraft Spigot 1.16.5 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-minecraft.sh
# @Syntax: ./1MB-minecraft.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_minecraftVersion="1.16.5"
# Which version are we running?

_minJavaVersion=11.0
# 11.0 = java 11, can be used for Minecraft 1.13.x and up.
# 1.8 = java 8, required for Minecraft 1.12.x and up.

_javaMemory="-Xms4G -Xmx4G"
# "" = uses the default
# "-Xmx2G" = maximum memory allocation pool of memory for JVM.
# "-Xms1G" = initial memory allocation pool of memory for JVM.
# For Spigot / Paper servers we recommend -Xms10G -Xmx10G for 16GB systems.
# More details here: https://stackoverflow.com/questions/14763079/

# jvm startup parameters
_javaParams="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
# -Dfile.encoding=UTF-8 (UTF-8 characters will be saved properly in the log files, and should correctly display in the console.)
# -Dapple.awt.UIElement=true (Helps on macOS to not show icon in cmd-tab)
# -Dhttps.protocols=TLSv1 (Temporary fix for older discordsrv, you can ignore this one probably)

# Override auto engine jar detection; only use this if you have issues
_engine=""
# "" assumes auto detection for <engine>-1.16.5.jar 
# "spigot" assumes to look for spigot-1.16.5.jar
# "paper" assumes to look for paper-1.16.5.jar

_engineParams=""
# Leave empty for every day running, only edit when you need this!
# --forceUpgrade (One time converts world chunks to new engine version)
# --eraseCache (Removes caches. Cached data is used to store the skylight, blocklight and biomes, alongside other stuff)

# By changing the setting below to true you are indicating your agreement to Mojang's EULA 
# which is legally binding, and you should read it! https://account.mojang.com/documents/minecraft_eula
_eula=false

# leave "" if you want the 1.16.5 server-gui
_noGui="--nogui"

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

_javaBin=""
# Leave empty for auto-discovery of java path, and 
# if this fails, you could hard code the path, as below:
# _javaBin="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"

_debug=false
# Debug mode off or on? Default: false (true means it spits out progress)

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

function version_gt() { test "$(printf '%s\n' "$@"|sort -V|head -n 1)" != "$1"; }
function binExists() { type "$1">/dev/null 2>&1; }
function binDetails() { 
    _cmd="$_"; _cmd="$_cmd";
    _cmdpath=$(command -V "$_cmd" | awk '{print $3}')
    _cmdversion=$($_cmd -version 2>&1 | awk -F '"' '/version/ {print $2}')
}

if binExists "java"; then
    binDetails "$_"
    if version_gt "$_cmdversion" "$_minJavaVersion"; then
        if [ -z "$_javaBin" ]; then
            _output debug "_javaBin is empty, trying to auto discover java .."
            if [ -z "$_cmdpath" ]; then
                _output oops "Path to java bin was found empty, maybe set _javaBin manually"
            else
                _output debug "Path to java ($_cmdversion) auto discovered: $_cmdpath"
                _javaBin="$_cmdpath"
            fi
        else
            # todo: Reconsider how to approach this, if _javaBin is set, check that. If that fails, try auto discovery.
            if [[ -f "$_javaBin" ]]; then
        		_output debug "Path to java was set in _javaBin, found it and trying to use this instead of auto discovery."
    		else
    			_output oops "Could not find $_javaBin, leave _javaBin empty for auto discovery or install java properly."
    		fi
        fi
        _output debug "Installed $_cmd version $_cmdversion is newer than $_minJavaVersion (this is great)!"
    else
        _output oops "Installed $_cmd version $_cmdversion is NOT newer \\n -> Please upgrade to the minimal required version: $_minJavaVersion "
    fi
else
    _output oops "$_ was not found, please install it for this operating system \\n -> https://www.digitalocean.com/community/tutorials?q=install+java"
fi

# before we continue, let's figure out if we have spigot or paper
if [ -n "$_engine" ]; then
    # It's not empty, let's use what they have and try to find that jar.
    _serverJar="$_engine-$_minecraftVersion.jar"
    if [[ -f "$_serverJar" ]]; then
        _engineJar="$_serverJar"
    else
        _output oops "Oops, we did not find $_serverJar, please check your configuration."
    fi
else
    # it's empty - let's figure out if there's a paper (first) or spigot (fallback)
    _serverJar="paper-$_minecraftVersion.jar"
    if [[ -f "$_serverJar" ]]; then
        _engineJar="$_serverJar"
    else
        _serverJar="spigot-$_minecraftVersion.jar"
        if [[ -f "$_serverJar" ]]; then
            _engineJar="$_serverJar"
        else
            _output oops "Oops, we did not find a paper or spigot, please read a manual."
        fi
    fi
fi

[[ "$_eula" == true ]] && _javaParams="${_javaParams} -Dcom.mojang.eula.agree=true"

_startJVM="$_javaBin $_javaMemory $_javaParams -jar $_engineJar $_engineParams $_noGui"
$_startJVM || _output oops "Failed to start the jvm for some reason."

#EOF Copyright (c) 2011-2021 - Floris Fiedeldij Dop - https://scripts.1moreblock.com