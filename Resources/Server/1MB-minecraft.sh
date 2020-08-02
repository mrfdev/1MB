#!/bin/bash

# @Filename: 1MB-minecraft.sh
# @Version: 2.0, build 027 for Spigot 1.16.1 (java 11)
# @Release: August 2nd, 2020
# @Description: Helps us start a Minecraft Spigot 1.16.1 server.
# @Contact:	I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-minecraft.sh
# @Syntax: ./1MB-minecraft.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

#todo toggle for eula?

### CONFIGURATION
#
# Stuff here you COULD change, but ONLY if you really really have to
#
###

# Which version are we running?
_minecraftVersion="1.16.1"

# Override auto engine jar detection; only use this if you have issues
_engine=""
# "" assumes auto detection for <engine>-1.16.1.jar 
# "spigot" assumes to look for spigot-1.16.1.jar
# "paper" assumes to look for paper-1.16.1.jar

_engineParams=""
# 	!! Use only if you know you need this !!
#	Leave empty! (for every day running)
# 	--forceUpgrade (one time convert chunks to new engine)
# 	--eraseCache (removing caches, lightning fix)

#JAVA_VERSION="11.0"
_minJavaVersion=11.0
#	11.0 = java 11, can be used for Minecraft 1.13.x and up.
#	1.8 = java 8, required for Minecraft 1.12.x and up.

_javaBin=""
# Leave empty for auto-discovery of java path, if 
# this fails, you could hard code the path, as below
# 08 (if you want to make spigot for 1.12.2 or 1.13.2)
# _javaBin="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
# 11 (if you want to make spigot for 1.13.2 - 1.16.1)
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"

_javaMemory=""
#	"" = uses the default
#	"-Xmx2G" = maximum memory allocation pool of memory for JVM.
#	"-Xms1G" = initial memory allocation pool of memory for JVM.
# For Spigot servers we recommend -Xms10G -Xmx10G for 16GB systems.
# More details here: https://stackoverflow.com/questions/14763079/

_javaParams="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
# 	-Dhttps.protocols=TLSv1 (temp fix for discordsrv)
#	-Dcom.mojang.eula.agree=true (Mojang EULA agreement)
#	-Dfile.encoding=UTF-8 (ensure that all UTF-8 chars are being saved properly)
#	-Dapple.awt.UIElement=true (helps on macOS to not show icon in cmd-tab)

_noGui="--nogui" # leave "" if you want the 1.16.1 server-gui

# Debug mode on or off?
_debug=true
# Default: true (that means it spits out progress))
#######################################################
#### !You're done, stop editing beyond this point! ####
#######################################################

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

#prerequisites

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"
Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

function binExists() { type "$1">/dev/null 2>&1; }

function binDetails() { 
    _cmd="$_"; _cmd="$_cmd";
    _cmdpath=$(command -V "$_cmd" | awk '{print $3}')
	_cmdversion=$($_cmd -version 2>&1 | awk -F '"' '/version/ {print $2}')
    # _output debug "Trying to find $_cmd, possibly here: $_cmdpath, version: $_cmdversion"
}

function version_gt() { test "$(printf '%s\n' "$@"|sort -V|head -n 1)" != "$1"; }

if binExists "java"; then
    binDetails "$_"
    if version_gt "$_cmdversion" "$_minJavaVersion"; then
        if [ -z "$_javaBin" ]; then
            # if _javaBin is empty, we want to auto discover, lets try
            _output debug "_javaBin is empty, trying to auto discover java .."
            if [ -z "$_cmdpath" ]; then
                # if cmdpath is empty, we are in trouble, quit script
                _output oops "Path to java bin was found empty, maybe set _javaBin"
            else
                # else cmdpath is not empty, we could use that path, set it
                _output debug "Path to java ($_cmdversion) auto discovered: $_cmdpath"
                _javaBin="$_cmdpath"
            fi
        else
            # else _javaBin is not empty, we want to use this instead of cmdpath, set it
            _output debug "Path to java was set in _javaBin, using this instead of auto discovery."
            # todo CONFIRM IF _javaBin IS ACTUALLY THERE else oops out
        fi
        _output debug "Installed $_cmd version $_cmdversion is newer than $_minJavaVersion (this is great)!"
    else
        _output oops "Installed $_cmd version $_cmdversion is NOT newer \\n -> Please upgrade to he minimal required version: $_minJavaVersion "
    fi
else
    _output oops "$_ was not found, please install it for this operating system \\n -> https://www.digitalocean.com/community/tutorials?q=install+java"
fi

# before we continue, let's figure out if we have spigot or paper
if [ -n "$_engine" ]; then
	# It's not empty, let's use what they have and try to find that jar.
	_serverJar="$_engine-$_minecraftVersion.jar"
	if [[ -f "$_serverJar" ]]; then
		# we found it, set it and continue the script. todo: we can simplify this logic
		_engineJar="$_serverJar"
	else
		# we did not find it, time to complain and bail out.
		_output oops "Oops, we did not find $_serverJar, please check your configuration."
	fi
else
	# it's empty - let's figure out if there's a spigot or paper jar
	_serverJar="paper-$_minecraftVersion.jar"
	if [[ -f "$_serverJar" ]]; then
		# we found paper, set it and continue the script. 
		_engineJar="$_serverJar"
	else
		# we did not find paper, but maybe there's a spigot jar
		_serverJar="spigot-$_minecraftVersion.jar"
		if [[ -f "$_serverJar" ]]; then
			# found spigot, set it and continue the script.
			_engineJar="$_serverJar"
		else
			# we did not find paper, and now also not spigot, time to bail out.
			_output oops "Oops, we did not find a paper or spigot, please read a manual."
		fi
	fi
fi

# Below is your java start up line for the server, edit accordingly.
_startJVM="$_javaBin $_javaMemory $_javaParams -jar $_engineJar $_engineParams $_noGui"
$_startJVM || _output oops "Failed to start the jvm for some reason."

#EOF (c)2011-2020 Floris Fiedeldij Dop