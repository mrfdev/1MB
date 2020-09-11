#!/bin/bash

# @Filename: 1MB-UpdatePaper.sh
# @Version: 1.0, build 009
# @Release: September 11th, 2020
# @Description: Helps us get a Minecraft Paper 1.16.3 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-UpdatePaper.sh
# @Syntax: ./1MB-UpdatePaper.sh
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

MINECRAFT_VERSION="1.16.3"

_minJavaVersion=11.0
# use 11.0 for java 11 which can be used for Minecraft 1.13.x and up.
# use 1.8 for java 8 which can be used for Minecraft 1.12.x and up.

DEBUG=true # Debug mode true means you get some output

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

JAVA_JDK=""
# Leave empty for auto-discovery of java path, if 
# this fails, you could hard code the path, as below
# 08 (if you want to make Paper for 1.12.2 or 1.13.2)
# JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
# 11 (if you want to make Paper for 1.13.2 - 1.16.3)
# JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"

DIR_SCRIPT="" #leave empty for auto discovery

BACKUPFILE="paper-$MINECRAFT_VERSION._jar"
CURRENTFILE="paper-$MINECRAFT_VERSION.jar"

CACHEFILE="cachepaper.txt"

URL_BASE="https://papermc.io/api/v1/paper"
URL_VERSION="$URL_BASE/$MINECRAFT_VERSION"
URL_LATEST="$URL_VERSION/latest"
URL_DOWNLOAD="$URL_LATEST/download"

# STRING="paper-350.jar"
# echo "${STRING//[!0-9]/}"
# echo "${STRING//[^0-9]/}"

# Stop configuring things beyond this point.

# some code to help us

# theme
B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m"

if [ -z "$DIR_SCRIPT" ]; then
    SH_SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SH_SOURCE" ]; do
        SH_TARGET="$(readlink "$SH_SOURCE")"
        if [[ $SH_TARGET == /* ]]; then
            SH_SOURCE="$SH_TARGET"
        else
            DIR_BASE="$( dirname "$SH_SOURCE" )"
            SH_SOURCE="$DIR_BASE/$SH_TARGET"
        fi
    done
    DIR_BASE="$( cd -P "$( dirname "$SH_SOURCE" )" && pwd )"
else
    DIR_BASE="$DIR_SCRIPT"
fi

CACHEFILE="$DIR_BASE/$CACHEFILE"

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
        cache false "$_prefix $_args" # Updating cachefile
        rm -f "$CACHEFILE.tmp" # Clean up; removing temp cachefile.
        exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R" >&2
        cache true "$_prefix $_args"
        rm -f "$CACHEFILE.tmp" # Clean up; removing temp cachefile.
        exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        if [ "$DEBUG" == true ]; then
            if [ "$2" != 1 ]; then
                echo -e "\\n$Y$_prefix$C $_args $R"
                cache true "$_prefix $_args"
            else
                echo -e "\\n------------------\\n$C$($3)$R\\n------------------"
            fi
        fi
    ;;
    *)
        _args="${*:1}"; _prefix="(Unknown)";
        echo "$_prefix $_args"
    ;;
    esac
}

function cache {
    # Write given msg true/false to cachefile
    sed -i.tmp "4s#.*#${1}#" "$CACHEFILE"
    sed -i.tmp "5s#.*#${2}#" "$CACHEFILE"
    # debug "cachefile: $1, msg: $2."
    # debug 1 "cat $CACHEFILE"
}

### CACHE LEGEND / HANDLER
#
# line 1 : Minecraft version (example: 1.16.3)
# line 2 : Paper build version (example: 128)
# line 3 : BuildTools build version (example: 108) (not used)
# line 4 : Shell script last-run state (example: true|false)
# line 5 : Shell script state message (example: Build successful)
#
# At any time the cache file can be renamed, 
# or deleted. If it's not found it will create one.
# The 'default' values are for Paper 1.16.3,
# but you can change this obviously. 
# The other values are 'old' on purpose, so when you
# delete the cache file, it also forces a redownload.
#
###

if [ -f "$CACHEFILE" ]; then
    # success
    # There's an existing cache
    _output debug "Found an existing CACHEFILE '$CACHEFILE'."
    _output debug 1 "cat $CACHEFILE"
else
    # failure
    # File was never made, or manually deleted. Let's create a new one. 
cat <<- EOF > $CACHEFILE
$MINECRAFT_VERSION
0
0
true
Never
EOF
    _output debug "Found no existing cache: '$CACHEFILE', created with defaults:"
    _output debug 1 "cat $CACHEFILE"
fi

# At this point we have an old or a new cache file, adding them to variables
# debug: https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
# debug: sed 'NUMq;d' file // sed "${NUM}q;d" file

CACHE_MC_BUILD=$(sed '1q;d' $CACHEFILE) #line1
CACHE_PP_BUILD=$(sed '2q;d' $CACHEFILE) #line2
CACHE_BT_BUILD=$(sed '3q;d' $CACHEFILE) #line3
CACHE_SH_STATE=$(sed '4q;d' $CACHEFILE) #line4
CACHE_SH_STMSG=$(sed '5q;d' $CACHEFILE) #line5


function binExists() { type "$1" >/dev/null 2>&1; }

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

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

#prequisites

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"

if binExists "curl"; then
    binDetails "$_"
    _jsonGetter="curl -f -L -s"
    _GETTER="curl --remote-name --remote-header-name --silent"
    _output debug "We can use curl, no need to check for wget"
else
    _output debug "$_ Not found, .. maybe we can use wget?"
    if binExists "wget"; then
        binDetails "$_"
        _jsonGetter="wget -q -O -"
        _GETTER="wget -q --content-disposition"
        _output debug "We can use wget, great."
    else
        _output oops "$_ also not found, .. we require either curl or wget \\n -> https://www.cyberciti.biz/faq/how-to-install-curl-command-on-a-ubuntu-linux/ \\n -> https://www.cyberciti.biz/faq/how-to-install-wget-togetrid-of-error-bash-wget-command-not-found/"
    fi
fi

###
#
# What is the latest Paper build number?
# https://papermc.io/api/v1/paper/1.16.3/latest
# {"project":"paper","version":"1.16.3","build":"128"}
#
###

JSON_KEY="build"

JSON_DATA=$($_jsonGetter $URL_LATEST)
JSON_VALUE="\"($JSON_KEY)\":\"([^\"]*)\""
while read -r l; do
    if [[ $l =~ $JSON_VALUE ]]; then
        JSON_RESULT="${BASH_REMATCH[2]}"
    fi
done <<< "$JSON_DATA"

if [ -z "$JSON_RESULT" ]; then
    _output oops "Failed to get $JSON_KEY from $JSON_URL_PAPER, quitting script!"
else
    CURRENT_PAPER_BUILD="$JSON_RESULT"
    unset JSON_RESULT
fi
# ## What do we have?
# TODO: Check against version 1.16.3 so we dont accidentally make a 1.17.2 in the future thinking it's 1.16.3

_output debug "Found the current build (offline): $CACHE_PP_BUILD"
_output debug "Found the current build (online): $CURRENT_PAPER_BUILD"

# if our cached number is less than our found online number, it's time to backup and upgrade.
if [ "$CACHE_PP_BUILD" -lt "$CURRENT_PAPER_BUILD" ]; then
    _output debug "Cache $CACHE_PP_BUILD is less than online $CURRENT_PAPER_BUILD (We can continue..)"
    # Updating our cache file with the newer build number
    sed -i.tmp "2s#.*#${CURRENT_PAPER_BUILD}#" "$CACHEFILE"
else
    _output oops "What we found online is not newer than what we already have, nothing to do."
fi

BACKUPFILE="$DIR_BASE/$BACKUPFILE"
CURRENTFILE="$DIR_BASE/$CURRENTFILE"

cd "$DIR_BASE" || _output oops "Could not change to $DIR_BASE"

# is there an old paper jar backup?
if [ -f "$BACKUPFILE" ]; then
	_output debug "Found an existing jar backed up: '$BACKUPFILE', removing it.."
	rm -f "$BACKUPFILE" # Clean up; removing backup
else
	_output debug "Found no existing jar backed up: '$BACKUPFILE', attempting to make one.."
fi

# is there a current paper jar file to backup?
if [ -f "$CURRENTFILE" ]; then
	_output debug "Found an existing jar '$CURRENTFILE', backing it up.."
	mv -f "$CURRENTFILE" "$BACKUPFILE" || _output oops "Backup move of $CURRENTFILE failed. "
else
	_output debug "Found no existing jar '$CURRENTFILE', guess we can download one.."
fi

_output debug "Starting download.. (this could take a short bit)"
$_GETTER $URL_DOWNLOAD || _output oops "Download of $DOWNLOADFILE failed."

# we should now have paper-NUMBER.jar, 
# we know with CURRENT_PAPER_BUILD what the build number is, 
# let's rename it to paper-1.16.3.jar
_downloadedJar="paper-$CURRENT_PAPER_BUILD.jar"

if [ -f "$_downloadedJar" ]; then
    _output debug "Done. Next, isolating $_downloadedJar .."
    mv -f "$_downloadedJar" "$CURRENTFILE" || _output oops "Was unable to rename $_downloadedJar to $CURRENTFILE"
    _output debug "Renamed $_downloadedJar to $CURRENTFILE, printing list:"
    ls -lh "$CURRENTFILE"
    pwd
else
    _output oops "Could not find downloaded jar $_downloadedJar"
fi

# We are done, let's get outtah here
_output okay "That's it, we're done!"

#EOF Copyright (c) 2011-2020 - Floris Fiedeldij Dop - https://scripts.1moreblock.com