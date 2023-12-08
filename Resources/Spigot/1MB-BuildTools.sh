#!/usr/bin/env bash

# @Filename: 1MB-BuildTools.sh
# @Version: 2.15.2, build 089
# @Release: December 8th, 2023
# @Description: Helps us make a Minecraft Spigot 1.20.4 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-BuildTools.sh
# @Syntax: ./1MB-BuildTools.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_minecraftVersion="1.20.4"
# Which version are we running?

_minJavaVersion=21
# use 21 for java 21 which can be used with Minecraft 1.19.x and 1.20.4
# use 20.0 for java 20.0.2 which can be used with Minecraft 1.19.x and 1.20.1
# use 19.0 for java 19.0.2 which can be used with Minecraft 1.19.3 and 1.19.4
# use 18.0 for java 18.0.2.1 which can be used with Minecraft 1.19.2 and up
# use 17.0 for java 17.0.5 or newer which can be used for Minecraft 1.17.1 and up.
# use 16.0 for java 16 which is required for Minecraft 1.17.1 and up.
# use 16.0 for java 16 which can be used for Minecraft 1.16.5 and up.
# use 11.0 for java 11 which can be used for Minecraft 1.13.x and up to 1.16.5
# use 1.8 for java 8 which can be used for Minecraft 1.12.x and up to 1.16.5

_jarBuildtools="BuildTools.jar"
# https://hub.spigotmc.org/jenkins/job/BuildTools/

_javaMemory=""
# "" = uses the default
# "-Xmx2G" = maximum memory allocation pool of memory for JVM.
# "-Xms1G" = initial memory allocation pool of memory for JVM.
# For Spigot / Paper servers we recommend -Xms10G -Xmx10G for 16GB systems.
# More details here: https://stackoverflow.com/questions/14763079/

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# What to call the cache-file (default: cache.txt)
_cacheFile="cachespigot.txt"

# What to call the output jar file
_jarSpigot="spigot-$_minecraftVersion.jar"
# 1MB-start.sh defaults to spigot-1.20.2.jar
_jarSpigotBackup="spigot-$_minecraftVersion._jar"
# And the backup file we create

_javaBin=""
# Leave empty for auto-discovery of java path, and 
# if this fails, you could hard code the path, as exampled below:
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-21.0.1.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-20.0.2.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-19.0.2.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-18.0.2.1.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-17.0.5.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/adoptopenjdk-16.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"

_dirScript="" #leave empty for auto discovery
# example: _dirScript="/Users/floris/MinecraftServer/_development"

_verboseOutput=false
# true: The output of the JVE will be visible, else it will try to be hidden

# jvm startup parameters
_javaParams="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
# -Dfile.encoding=UTF-8 (UTF-8 characters will be saved properly in the log files, and should correctly display in the console.)
# -Dapple.awt.UIElement=true (Helps on macOS to not show icon in cmd-tab)
# -Dhttps.protocols=TLSv1 (Temporary fix for older discordsrv, you can ignore this one probably)
# --compile craftbukkit (In case you have a reason to build craftbukkit)

_urlBase="https://hub.spigotmc.org"
_jsonMcUrl="$_urlBase/stash/projects/SPIGOT/repos/builddata/raw/info.json"
_jsonSpUrl="$_urlBase/versions/$_minecraftVersion.json"
_jsonBtUrl="$_urlBase/jenkins/job/BuildTools/lastSuccessfulBuild/buildNumber"
_jarBtUrl="$_urlBase/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/$_jarBuildtools"

_debug=true
# Debug mode off or on? Default: true (means it spits out progress)

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# some code to help us

# theme
B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m"

if [ -z "$_dirScript" ]; then
    _shellSource="${BASH_SOURCE[0]}"
    while [ -h "$_shellSource" ]; do
        _shellTarget="$(readlink "$_shellSource")"
        if [[ $_shellTarget == /* ]]; then
            _shellSource="$_shellTarget"
        else
            _dirBase="$( dirname "$_shellSource" )"
            _shellSource="$_dirBase/$_shellTarget"
        fi
    done
    _dirBase="$( cd -P "$( dirname "$_shellSource" )" && pwd )"
else
    _dirBase="$_dirScript"
fi

_cacheFile="$_dirBase/$_cacheFile"
_dirBuildtools="$_dirBase/BuildTools/"

### FUNCTIONS

# oops = spit out failure and exit script
#   $1 <- the msg
# okay = spit out success and exit script
#   $1 <- the msg
# debug = echo out debug information or a command
#   1=cmd <- $2, $3 else: the msg
# cache = updates cache last-run state and msg
#   $1 <- true|false, $2 <- msg

function _output {
    case "$1" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        echo -e "\\n$B$Y$_prefix$X $_args $R" >&2
        cache false "$_prefix $_args" # Updating _cacheFile
        rm -f "$_cacheFile.tmp" # Clean up; removing temp _cacheFile.
        exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R" >&2
        cache true "$_prefix $_args"
        rm -f "$_cacheFile.tmp" # Clean up; removing temp _cacheFile.
        exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        if [ "$_debug" == true ]; then
            if [ "$2" != 1 ]; then
                echo -e "$Y$_prefix$C $_args $R"
                cache true "$_prefix $_args"
            else
                echo -e "\\n------------------\\n$C$($3)$R\\n------------------"
            fi
        else
            cache true "$_prefix $_args"
        fi
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        echo -e "\\n$B $_prefix $_args $R"
        cache true "$_prefix $_args"
    ;;
    esac
}

function cache {
    # Write given msg true/false to _cacheFile
    sed -i.tmp "4s#.*#${1}#" "$_cacheFile"
    sed -i.tmp "5s#.*#${2}#" "$_cacheFile"
    # debug "_cacheFile: $1, msg: $2."
    # debug 1 "cat $_cacheFile"
}

### CACHE LEGEND / HANDLER
#
# line 1 : Minecraft version (example: 1.20.2)
# line 2 : Spigot nightly build version (example: 3875)
# line 3 : BuildTools build version (example: 162)
# line 4 : Shell script last-run state (example: true|false)
# line 5 : Shell script state message (example: Build successful)
#
# At any time the cache txt file can be renamed,
# or deleted. If it's not found it will create one.
# The 'default' values are for Spigot 1.20.2,
# but you can change this obviously.
# The other values are 'old' on purpose, so when you
# delete the cache txt file, it also forces a rebuild,
# of both buildtools and spigot jar files.
#
###

if [ -f "$_cacheFile" ]; then
    # success
    # There's an existing cache
    _output debug "Found an existing _cacheFile '$_cacheFile'."
    _output debug 1 "cat $_cacheFile"
else
    # failure
    # File was never made, or manually deleted. Let's create a new one.
cat <<- EOF > $_cacheFile
$_minecraftVersion
0
0
true
Never
EOF
    _output debug "Found no existing cache: '$_cacheFile', created with defaults:"
    _output debug 1 "cat $_cacheFile"
fi

# At this point we have an old or a new cache file, adding them to variables
# debug: https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
# debug: sed 'NUMq;d' file // sed "${NUM}q;d" file

_cacheMcBuild=$(sed '1q;d' $_cacheFile) #line1
_cacheSpBuild=$(sed '2q;d' $_cacheFile) #line2
_cacheBtBuild=$(sed '3q;d' $_cacheFile) #line3
_cacheShState=$(sed '4q;d' $_cacheFile) #line4
_cacheShStMsg=$(sed '5q;d' $_cacheFile) #line5

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
    if [ "$_cmd" == "java" ]; then
        _cmdversion=$($_cmd -version 2>&1 | awk -F '"' '/version/ {print $2}')
    else
        _cmdversion=$($_cmd --version | perl -pe 'if(($v)=/([0-9]+([.][0-9]+)+)/){print"$v\n";exit}$_=""')
    fi
    _output debug "cmd: $_cmd, path: $_cmdpath, version: $_cmdversion"
}

#prerequisites

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"

if binExists "perl"; then
    binDetails "$_"
else
    _output oops "$_ was not found, .. please install it properly."
fi

if binExists "java"; then
    binDetails "$_"
    _output debug "Gathering Java information. Found: $_cmdversion Minimum required: $_minJavaVersion"
    if version_gt "$_cmdversion" "$_minJavaVersion"; then
        _output debug "Installed $_cmd version $_cmdversion is newer than $_minJavaVersion (this is great)!"
        if [ -z "$_javaBin" ]; then
            # if _javaBin is empty, we want to auto discover, lets try
            _output debug "_javaBin is empty, trying to auto discover java path"
            if [ -z "$_cmdpath" ]; then
                # if cmdpath is empty, we are in trouble, quit script
                _output oops "Path to java bin was found empty, maybe set _javaBin"
            else
                # else cmdpath is not empty, we could use that path, set it
                _javaBin="$_cmdpath"
                _output debug "Path to java auto discovered: $_javaBin"
            fi
        else
            # else _javaBin is not empty, we want to use this instead of cmdpath, set it
            _output debug "Path to java was set in _javaBin, using this instead of auto discovery."
        fi
    else
        _output oops "Installed $_cmd version $_cmdversion is NOT newer \\n -> Please upgrade to he minimal required version: $_minJavaVersion "
    fi
else
    _output oops "$_ was not found, please install it for this operating system \\n -> https://www.digitalocean.com/community/tutorials?q=install+java"
fi

if binExists "git"; then
    binDetails "$_"
else
    _output oops "$_ was not found, please install it for this operating system \\n -> https://www.digitalocean.com/community/tutorials/how-to-contribute-to-open-source-getting-started-with-git"
fi

if binExists "curl"; then
    binDetails "$_"
    if [ "$_verboseOutput" == true ]; then
        _jsonGet="curl -f -L "
        _jsonDownload="curl -L -O"
    else
        _jsonGet="curl -f -L -s"
        _jsonDownload="curl -L -s -O"
    fi
    _output debug "We can use curl, no need to check for wget"
else
    _output debug "$_ Not found, .. maybe we can use wget?"
    if binExists "wget"; then
        binDetails "$_"
        if [ "$_verboseOutput" == true ]; then
            _jsonGet="wget -O -"
            _jsonDownload="wget"
        else
            _jsonGet="wget -q -O -"
            _jsonDownload="wget -q"
        fi
        _output debug "We can use wget, great."
    else
        _output oops "$_ also not found, .. we require either curl or wget \\n -> https://www.cyberciti.biz/faq/how-to-install-curl-command-on-a-ubuntu-linux/ \\n -> https://www.cyberciti.biz/faq/how-to-install-wget-togetrid-of-error-bash-wget-command-not-found/"
    fi
fi

# And now we can get some online data about spigot and buildtools

### GET BUILD NUMBERS

###
#
# # What is the latest Minecraft build they're making Spigot for?
# https://hub.spigotmc.org/stash/projects/SPIGOT/repos/builddata/raw/info.json
# debug: JSON minecraftVersion NUM
# You can change _jsonUrls and _jsonKey
#
###
_latest=false
_jsonKey="minecraftVersion"
_jsonData=$($_jsonGet $_jsonMcUrl)
_jsonValue="\"($_jsonKey)\": \"([^\"]*)\""
while read -r l; do
    if [[ $l =~ $_jsonValue ]]; then
        _jsonResult="${BASH_REMATCH[2]}"
    fi
done <<< "$_jsonData"
if [ -z "$_jsonResult" ]; then
    _output oops "Failed to get '$_jsonKey' from '$_jsonMcUrl', quitting script!"
else
    _currentMcBuild="$_jsonResult"
    unset _jsonResult
    _output debug "Found MineCraft version number online: '$_currentMcBuild' "
fi

###
#
# What is the latest Spigot nightly build number?
# https://hub.spigotmc.org/versions/latest.json
# debug: JSON name NUM
#
###
_jsonKey="name"
_jsonData=$($_jsonGet $_jsonSpUrl)
_jsonValue="\"($_jsonKey)\": \"([^\"]*)\""
while read -r l; do
    if [[ $l =~ $_jsonValue ]]; then
        _jsonResult="${BASH_REMATCH[2]}"
    fi
done <<< "$_jsonData"
if [ -z "$_jsonResult" ]; then
    _output debug "Failed to get '$_jsonKey' from '$_jsonSpUrl', trying with --rev latest"
    _jsonSpUrl="$_urlBase/versions/latest.json"
    _jsonData=$($_jsonGet $_jsonSpUrl)
    _jsonValue="\"($_jsonKey)\": \"([^\"]*)\""
    while read -r l; do
        if [[ $l =~ $_jsonValue ]]; then
            _jsonResult="${BASH_REMATCH[2]}"
        fi
    done <<< "$_jsonData"
    if [ -z "$_jsonResult" ]; then
        _output oops "Failed to get '$_jsonKey' from '$_jsonSpUrl', I really tried."
    else
        _currentSpBuild="$_jsonResult"
        _latest=true
        _output debug "Couldn't find what you wanted, but latest Spigot build number online seems to be: '$_currentSpBuild'"
        _output debug "$B *!* NOTICE PLEASE: This is not really '$_minecraftVersion', but actually build: '$_currentSpBuild', please double check what you set for _minecraftVersion."
    fi
    unset _jsonResult
else
    _currentSpBuild="$_jsonResult"
    unset _jsonResult
    _output debug "Found Spigot build number online: '$_currentSpBuild'"
fi

###
#
# What is the latest BuildTools build number?
# https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/buildNumber
# debug: spits out just NUM
#
###

_jsonData=$($_jsonGet $_jsonBtUrl)
if [ -z "$_jsonData" ]; then
    _output oops "Failed to get data from $_jsonBtUrl, quitting script!"
else
    _currentBtBuild="$_jsonData"
    _output debug "Found BuildTools build number online: $_currentBtBuild"
fi

## What do we have?
_output debug "Found the cached data (offline): MC: $_cacheMcBuild, SP: $_cacheSpBuild, BT: $_cacheBtBuild"
_output debug "Found the current data (online): MC: $_currentMcBuild, SP: $_currentSpBuild, BT: $_currentBtBuild"

# And COMPARE that against our cached data (regardless if that's old or new)

# We want builds for 1.20.2, so the cached version and the current version have to both be 1.20.2
# PATCH if [ "$_cacheMcBuild" == "$_currentMcBuild" ]; then
if [ "$_minecraftVersion" == "$_currentMcBuild" ]; then
    # success, 1.20.2 == 1.20.2
    _output debug "Comparing MC : OK; we can continue.."
else
    # failure, current must be newer
    _output "Comparing MC : Failure; Spigot $_currentMcBuild detected, we seem to want Minecraft $_cacheMcBuild builds. We are automatically pausing the script here to make sure you do not accidentally upgrade or downgrade $_currentMcBuild server to 1.12 or 1.19.4 or whatever!"
    read -p "Do you still want to build $_jarSpigot? [y/N]" -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
    sed -i.tmp "1s#.*#${_currentMcBuild}#" "$_cacheFile"
fi

# Spigot is being build against the right Minecraft version, but do we want to build a new Spigot?
# If the cached version is the same as the current version, we are done, exit the script.
# and otherwise there is a newer build out, we should go get it and compile a new jar.
if [ "$_currentSpBuild" -le "$_cacheSpBuild" ]; then
    # success, current Spigot build is less than or equal to our cached version (so it's older, or the same)
    _output oops "Comparing SP : OK; Latest Spigot $_currentSpBuild is not newer, nothing to do. Quitting!"
    # Wait, .. check if cache file state is false, if so .. we quit last time we run it..
    # maybe it's fixed now, we have to assume we want to run the script again.
    # if state is positive, then we're outtah here.
else
    # failure, current must be newer, we should go get it and copmile a new jar
    _output debug "Comparing SP : OK; Newer build found ($_currentSpBuild), we can continue.."
    # Updating our cache file with the newer build number
    sed -i.tmp "2s#.*#${_currentSpBuild}#" "$_cacheFile"
fi

# Ok, we know there's a new build out for Spigot for Minecraft 1.20.2,
# we can make it with buildtools, however, we have to make sure
# we are using the current version of buildtools, one more comparison
if [ "$_currentBtBuild" == "$_cacheBtBuild" ]; then
    # success, current BuildTools build is equal to our cached version (so it's the same)
    _output debug "Comparing BT : OK; No newer build found, we can just do an upgrade.."
    # no need to quit script or download anything, compile Spigot with the buildtools.jar we have
else
    # failure, current must be newer, we should go get it and use that instead.
    _output debug "Comparing BT : OK; Not matching. Build found ($_currentBtBuild), we should get it.."
    # updating cache with newer build number:
    sed -i.tmp "3s#.*#${_currentBtBuild}#" "$_cacheFile"
    # we need to download the newer buildtools before we compile spigot with the new bt jar.

    _output debug "Deleting old $_dirBuildtools directory .."
    rm -rf $_dirBuildtools
    _output debug "Done. Next, downloading $_jarBuildtools .."
    cd "$_dirBase" || _output oops "Could not change to $_dirBase"
    $_jsonDownload $_jarBtUrl || _output oops "Download of $_jarBtUrl failed."
    mkdir $_dirBuildtools
    mv $_jarBuildtools $_dirBuildtools
    _output debug "Upgrade: BuildTools jar downloaded .. ready to go."
fi

# Update: What happened?
# If the script didn't quit here, that means we have a new spigot build for 1.20.2 of minecraft,
# and we know if we can upgrade spigot with the buildtools we have, or if we need to get a new jar.

# do we just update spigot?
# do we get buildtools?

## cache sh ends here
## buildtools sh starts here

cd "$_dirBase" || _output oops "Could not change to '$_dirBase'"

_file="server.properties"
_netfind() { _test=$(lsof -iTCP -sTCP:LISTEN -n -P | grep -i "$1");
    if [ -z "$_test" ]; then
        _output debug "Found '$_file' (good!), and found nothing listening on port '$_port' (good!).\\nAssuming there's no server running, we can make the server jar"
    else
        _output debug "$_test\\nPossible solutions: Stop the server first, or run this script in an empty directory"
        _output oops "Found a server running, halting script, I don't want to replace that jar!"
    fi
}; [[ -f "$_file" ]] && _port=$(grep "^server-port=" $_file | awk -F= '{print $2}') && _netfind $_port || _output debug "Found no '$_file' (good!), we can replace the server jar"

if [ $_latest = true ]; then
    _minecraftVersion="$_currentMcBuild"
    _jarSpigot="spigot-$_minecraftVersion.jar"
    _jarSpigotBackup="spigot-$_minecraftVersion._jar"
fi 

_jarSpigotExisting="$_dirBase/$_jarSpigot"
_jarSpigotBackup="$_dirBase/$_jarSpigotBackup"

# is there an old spigot jar backup?
# TODO only make a backup if there is actually a jar to backup as well.
if [ -f "$_jarSpigotBackup" ]; then
    _output debug "Found an existing jar backed up: '$_jarSpigotBackup', removing it.."
    rm -f "$_jarSpigotBackup" # Clean up; removing backup
else
    _output debug "Found no existing jar backed up: '$_jarSpigotBackup', attempting to make one.."
fi

# is there a current spigot jar file to backup?
if [ -f "$_jarSpigotExisting" ]; then
    _output debug "Found an existing jar '$_jarSpigotExisting', backing it up.."
    mv -f "$_jarSpigotExisting" "$_jarSpigotBackup" || _output oops "Backup move of $_jarSpigotExisting failed. "
else
    _output debug "Found no existing jar '$_jarSpigotExisting', it's okay, we're going to make one."
fi

_output debug "Done. Next, building new $_jarSpigot .. $B(can take a while, leave it running)"
cd "$_dirBuildtools" || _output oops "Could not change to $_dirBuildtools"
[ $_latest = true ] && _rev="--rev latest" || _rev="--rev $_minecraftVersion"
if [ "$_verboseOutput" == true ]; then
    # do not hide JVE output during compile
    $_javaBin $_javaMemory $_javaParams -jar $_jarBuildtools $_rev || _output oops "Failed; Could not build '$_jarBuildtools'. Quitting!"
    # _output debug "pretending to build.."
else
    # do not display JVE output during compile (assuming value false)
    # todo: should else if and failover else
    $_javaBin $_javaMemory $_javaParams -jar $_jarBuildtools $_rev > /dev/null 2>&1 || _output oops "Failed; Could not build '$_jarBuildtools'. Quitting!"
    # _output debug "pretending to build.."
fi

_output debug "Done. Next, isolating $_jarSpigot .."
mv -f "$_jarSpigot" "$_dirBase" || _output oops "Failed; No such file or directory. Quitting!"
cd "$_dirBase" || _output oops "Failed; Could not change to $_dirBase. Quitting!"

ls -lh "$_jarSpigot" || _output oops "Failed; Could not list '$_jarSpigot'. Quitting!"
pwd

# We are done, let's get outtah here
_output okay "That's it, we're done!"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com
