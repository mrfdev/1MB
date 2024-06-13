#!/usr/bin/env bash

# @Filename: 1MB-minecraft.sh
# @Version: 2.18.0, build 069 for Minecraft 1.21 (Java 22.0.1, 64bit)
# @Release: June 13th, 2024
# @Description: Helps us start a Spigot or Paper 1.21 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-minecraft.sh
# @Syntax: ./1MB-minecraft.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_minecraftVersion="1.21"
# Which version are we running?

_minJavaVersion=22
# use 22 for java 22.0.1 which can be used with Minecraft 1.20.6 and 1.21
# use 21 for java 21.0.2 or 22.0.1 which can be used with Minecraft 1.19.x and 1.20.6
# use 20.0 for java 20.0.2 which can be used with Minecraft 1.19.x and 1.20+
# use 18.0, 19.0 for java 18.0.2.1+ which can be used with Minecraft 1.19+
# use 17.0 for java 17.0.5 which can be used for Minecraft 1.17.x

_javaMemory="-Xms4G -Xmx4G"
# "" = uses the default
# "-Xmx2G" = maximum memory allocation pool of memory for JVM.
# "-Xms1G" = initial memory allocation pool of memory for JVM.
# More details here: https://stackoverflow.com/questions/14763079/
# Example: (16GB host for dedicated Paper 1.20.2 server with custom flags, using 10GB ram, etc.)
# _javaMemory="-Xms10G -Xmx10G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
# _javaMemory="-Xms10240M -Xmx10240M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20"
# Figure out optimal flags for your configuration here: https://flags.sh/

# jvm startup parameters
_javaParams="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
# -Dfile.encoding=UTF-8 (UTF-8 characters will be saved properly in the log files, and should correctly display in the console.)
# -Dapple.awt.UIElement=true (Helps on macOS to not show icon in cmd-tab)
# -Dhttps.protocols=TLSv1 (Temporary fix for older discordsrv, you can ignore this one probably)
# -Dterminal.ansi=false (Temporary fix for older screen sessions that have hex-issues)
# --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.security=ALL-UNNAMED (Temporary fix for asyncworldedit and java16)
# and --add-opens java.desktop/java.awt=ALL-UNNAMED
# and --add-opens java.desktop/java.awt.color=ALL-UNNAMED
# --illegal-access=permit (Temporary fix to get outdated plugins to work on 1.17.1)
# -Dlog4j2.formatMsgNoLookups=true (Temporary fix to help address log4j2 issue for pre 1.18.2 servers)
# -Dpaper.useLegacyPluginLoading=true (Temporary fix circular plugin loading issue)

# Override auto engine jar detection; only use this if you have issues
_engine="spigot"
# spigot until paper jar is out
# "" assumes auto detection for <engine>-1.21.jar 
# "spigot" assumes to look for spigot-1.21.jar
# "paper" assumes to look for paper-1.21.jar

_engineParams=""
# Leave empty for every day running, only edit when you need this!
# --forceUpgrade (One time converts world chunks to new engine version) (Note: Do not use Paper's forceUpgrade, it will ruin your worlds)
# --eraseCache (Removes caches. Cached data is used to store the skylight, blocklight and biomes, alongside other stuff) (Note: Do not use Paper's eraseCache, it will ruin your worlds)
# --recreateRegionFiles (trigger world optimization similar to forceUpgrade, but will also rewrite all the chunks independentlyof whether they have been upgraded) (change region-file-compression first)

# By changing the setting below to true you are indicating your agreement to Mojang's EULA 
# which is legally binding, and you should read it! https://account.mojang.com/documents/minecraft_eula
_eula=false

# leave "" if you want the 1.20.6 server-gui
_noGui="--nogui"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_javaBin=""
# Leave empty for auto-discovery of java path, and 
# if this fails, you could hard code the path, as exampled below:
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-22.0.1.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-20.0.2.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-19.0.2.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-18.0.2.1.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-17.0.5.jdk/Contents/Home/bin/java"

_debug=true
# Debug mode off or on? Default: false (true means it spits out progress)

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
Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

# 'better comparing' fix to replace: function version_gt() { test "$(printf '%s\n' "$@"|sort -V|head -n 1)" -ge "$1"; }
function version_gt() {
    local result="$1"
    local value="$2"

    # When the versions (strings) has fewer components we need to properly split the version strings into arrays
    IFS='.' read -ra result_parts <<< "$result"
    IFS='.' read -ra value_parts <<< "$value"

    # So we can then compare each part of the version (using 0 for missing parts).
    for ((i = 0; i < ${#value_parts[@]}; i++)); do
        result_part="${result_parts[i]:-0}"
        value_part="${value_parts[i]}"
        
        if [[ "$result_part" -gt "$value_part" ]]; then
            # true
            return 0
        elif [[ "$result_part" -lt "$value_part" ]]; then
            # false
            return 1
        fi
    done

    # return true when they're equal or have fewer components.
    return 0
}

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

#EOF Copyright (c) 1977-2024 - Floris Fiedeldij Dop - https://scripts.1moreblock.com