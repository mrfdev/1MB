#!/bin/bash

# @Filename: 1MB-BuildTools.sh
# @Version: 2.0, build 051
# @Release: August 2nd, 2020
# @Description: Helps us get a Minecraft Spigot 1.16.1 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-BuildTools.sh
# @Syntax: ./1MB-BuildTools.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Configuration variables you can declare 
# to match your personal situation.
#
###

# Which version are we trying to build?
MINECRAFT_VERSION="1.16.1"

_minJavaVersion=11.0
# use 11.0 for java 11 which can be used for Minecraft 1.13.x and up.
# use 1.8 for java 8 which can be used for Minecraft 1.12.x and up.

# Debug mode on or off?
DEBUG=true
# Default: true (that means it spits out progress))

# https://hub.spigotmc.org/jenkins/job/BuildTools/
JAR_BUILDTOOLS="BuildTools.jar"

JAVA_MEMORY=""
#   "" = uses the default
#   "-Xmx2G" = maximum memory allocation pool of memory for JVM.
#   "-Xms1G" = initial memory allocation pool of memory for JVM.
# For Spigot servers we recommend -Xms10G -Xmx10G for 16GB systems.
# More details here: https://stackoverflow.com/questions/14763079/


### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

# What to call the cache-file (default: cache.txt)
CACHEFILE="cachespigot.txt"

# What to call the output jar file
JAR_SPIGOT="spigot-$MINECRAFT_VERSION.jar" 
# 1MB-start.sh defaults to spigot-1.16.1.jar

JAVA_JDK=""
# Leave empty for auto-discovery of java path, if 
# this fails, you could hard code the path, as below
# 08 (if you want to make spigot for 1.12.2 or 1.13.2)
# JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
# 11 (if you want to make spigot for 1.13.2 - 1.16.1)
# JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"

DIR_SCRIPT="" #leave empty for auto discovery
# example: DIR_SCRIPT="/Users/floris/MinecraftServer/_development"

JAVA_VERBOSE=false
# true <--- The output of the JVE will be visible,
# false <-- "> /dev/null 2>&1" <-- it will be hidden.

JAR_PARAMS="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
#   "--compile craftbukkit" If you need to make specifically craftbukkit
#   -Dfile.encoding=UTF-8 (ensure that all UTF-8 chars are being saved properly)
#   -Dapple.awt.UIElement=true (helps on macOS to not show icon in cmd-tab)

URL_BASE="https://hub.spigotmc.org"
JSON_URL_MINECRAFT="$URL_BASE/stash/projects/SPIGOT/repos/builddata/raw/info.json"
JSON_URL_SPIGOT="$URL_BASE/versions/$MINECRAFT_VERSION.json"
JSON_URL_BUILDTOOLS="$URL_BASE/jenkins/job/BuildTools/lastSuccessfulBuild/buildNumber"
JAR_URL_BUILDTOOLS="$URL_BASE/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/$JAR_BUILDTOOLS"


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
    # RDIR="$( dirname "$SH_SOURCE" )"
    DIR_BASE="$( cd -P "$( dirname "$SH_SOURCE" )" && pwd )"
else
    DIR_BASE="$DIR_SCRIPT"
fi
CACHEFILE="$DIR_BASE/$CACHEFILE"

DIR_BUILDTOOLS="$DIR_BASE/BuildTools/"

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
# line 1 : Minecraft version (example: 1.15.2)
# line 2 : Spigot nightly build version (example: 2591)
# line 3 : BuildTools build version (example: 108)
# line 4 : Shell script last-run state (example: true|false)
# line 5 : Shell script state message (example: Build successful)
#
# At any time the cache.txt file can be renamed, 
# or deleted. If it's not found it will create one.
# The 'default' values are for Spigot 1.15.2,
# but you can change this obviously. 
# The other values are 'old' on purpose, so when you
# delete the cache.txt file, it also forces a rebuild,
# of both buildtools and spigot jar files.
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
CACHE_SP_BUILD=$(sed '2q;d' $CACHEFILE) #line2
CACHE_BT_BUILD=$(sed '3q;d' $CACHEFILE) #line3
CACHE_SH_STATE=$(sed '4q;d' $CACHEFILE) #line4
CACHE_SH_STMSG=$(sed '5q;d' $CACHEFILE) #line5

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

function version_gt() { test "$(printf '%s\n' "$@"|sort -V|head -n 1)" != "$1"; }

#prerequisites

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"

if binExists "perl"; then
    binDetails "$_"
else
    _output oops "$_ was not found, .. please install it properly."
fi

if binExists "java"; then
    binDetails "$_"
    if version_gt "$_cmdversion" "$_minJavaVersion"; then
        _output debug "Installed $_cmd version $_cmdversion is newer than $_minJavaVersion (this is great)!"
        if [ -z "$JAVA_JDK" ]; then
            # if java_jdk is empty, we want to auto discover, lets try
            _output debug "JAVA_JDK is empty, trying to auto discover java path"
            if [ -z "$_cmdpath" ]; then
                # if cmdpath is empty, we are in trouble, quit script
                _output oops "Path to java bin was found empty, maybe set JAVA_JDK"
            else
                # else cmdpath is not empty, we could use that path, set it
                _output debug "Path to java auto discovered: $_cmdpath"
                JAVA_JDK="$_cmdpath"
            fi
        else
            # else java_jdk is not empty, we want to use this instead of cmdpath, set it
            _output debug "Path to java was set in JAVA_JDK, using this instead of auto discovery."
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
    JSON_GET="curl -f -L -s"
    JSON_GET_DL="curl -L -s -O"
    _output debug "We can use curl, no need to check for wget"
else
    _output debug "$_ Not found, .. maybe we can use wget?"
    if binExists "wget"; then
        binDetails "$_"
        JSON_GET="wget -q -O -"
        JSON_GET_DL="wget"
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
# You can change JSON_URL and JSON_KEY
#
###

JSON_KEY="minecraftVersion"

JSON_DATA=$($JSON_GET $JSON_URL_MINECRAFT)
JSON_VALUE="\"($JSON_KEY)\": \"([^\"]*)\""
while read -r l; do
    if [[ $l =~ $JSON_VALUE ]]; then
        JSON_RESULT="${BASH_REMATCH[2]}"
    fi
done <<< "$JSON_DATA"

if [ -z "$JSON_RESULT" ]; then
    _output oops "Failed to get $JSON_KEY from $JSON_URL_MINECRAFT, quitting script!"
else
    CURRENT_MC_BUILD="$JSON_RESULT"
    unset JSON_RESULT
    _output debug "Found MineCraft version number online: $CURRENT_MC_BUILD"
fi

###
#
# What is the latest Spigot nightly build number?
# https://hub.spigotmc.org/versions/latest.json
# debug: JSON name NUM
#
###

JSON_KEY="name"

JSON_DATA=$($JSON_GET $JSON_URL_SPIGOT)
JSON_VALUE="\"($JSON_KEY)\": \"([^\"]*)\""
while read -r l; do
    if [[ $l =~ $JSON_VALUE ]]; then
        JSON_RESULT="${BASH_REMATCH[2]}"
    fi
done <<< "$JSON_DATA"

if [ -z "$JSON_RESULT" ]; then
    _output oops "Failed to get $JSON_KEY from $JSON_URL_SPIGOT, quitting script!"
else
    CURRENT_SP_BUILD="$JSON_RESULT"
    unset JSON_RESULT
    _output debug "Found Spigot build number online: $CURRENT_SP_BUILD"
fi

###
#
# What is the latest BuildTools build number?
# https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/buildNumber
# debug: spits out just NUM
#
###

JSON_DATA=$($JSON_GET $JSON_URL_BUILDTOOLS)

if [ -z "$JSON_DATA" ]; then
    _output oops "Failed to get data from $JSON_URL_BUILDTOOLS, quitting script!"
else
    CURRENT_BT_BUILD="$JSON_DATA"
    _output debug "Found BuildTools build number online: $CURRENT_BT_BUILD"
fi

## What do we have?
_output debug "Found the cached data (offline): MC: $CACHE_MC_BUILD, SP: $CACHE_SP_BUILD, BT: $CACHE_BT_BUILD"
_output debug "Found the current data (online): MC: $CURRENT_MC_BUILD, SP: $CURRENT_SP_BUILD, BT: $CURRENT_BT_BUILD"

# And COMPARE that against our cached data (regardless if that's old or new)

# We want builds for 1.16.1, so the cached version and the current version have to both be 1.16.1
# PATCH if [ "$CACHE_MC_BUILD" == "$CURRENT_MC_BUILD" ]; then
if [ "$CURRENT_MC_BUILD" == "$CURRENT_MC_BUILD" ]; then
    # success, 1.16.1 == 1.16.1
    _output debug "Comparing MC : OK; we can continue.."
else
    # failure, current must be newer
    _output oops "Comparing MC : Failure; Spigot $CURRENT_MC_BUILD detected, we only want Minecraft $CACHE_MC_BUILD builds. Quitting!"
    # May we desire to auto update regardless of number, we might want to update the cache
    # since we don't commenting this out:
    # sed -ie "1s/.*/$CURRENT_MC_BUILD/" $CACHEFILE
fi

# Spigot is being build against the right Minecraft version, but do we want to build a new Spigot?
# If the cached version is the same as the current version, we are done, exit the script.
# and otherwise there is a newer build out, we should go get it and compile a new jar.
if [ "$CURRENT_SP_BUILD" -le "$CACHE_SP_BUILD" ]; then
    # success, current Spigot build is less than or equal to our cached version (so it's older, or the same)
    _output oops "Comparing SP : OK; Latest Spigot $CURRENT_SP_BUILD is not newer, nothing to do. Quitting!"
    # Wait, .. check if cache file state is false, if so .. we quit last time we run it.. 
    # maybe it's fixed now, we have to assume we want to run the script again.
    # if state is positive, then we're outtah here.
else
    # failure, current must be newer, we should go get it and copmile a new jar
    _output debug "Comparing SP : OK; Newer build found ($CURRENT_SP_BUILD), we can continue.."
    # Updating our cache file with the newer build number
    sed -i.tmp "2s#.*#${CURRENT_SP_BUILD}#" "$CACHEFILE"
fi

# Ok, we know there's a new build out for Spigot for Minecraft 1.16.1,
# we can make it with buildtools, however, we have to make sure
# we are using the current version of buildtools, one more comparison
if [ "$CURRENT_BT_BUILD" == "$CACHE_BT_BUILD" ]; then
    # success, current BuildTools build is equal to our cached version (so it's the same)
    _output debug "Comparing BT : OK; No newer build found, we can just do an upgrade.." 
    # no need to quit script or download anything, compile Spigot with the buildtools.jar we have
else
    # failure, current must be newer, we should go get it and use that instead.
    _output debug "Comparing BT : OK; Not matching. Build found ($CURRENT_BT_BUILD), we should get it.."
    # updating cache with newer build number:
    sed -i.tmp "3s#.*#${CURRENT_BT_BUILD}#" "$CACHEFILE"
    # we need to download the newer buildtools before we compile spigot with the new bt jar.

    _output debug "Deleting old $DIR_BUILDTOOLS directory .."
    rm -rf $DIR_BUILDTOOLS
    _output debug "Done. Next, downloading $JAR_BUILDTOOLS .."
    cd "$DIR_BASE" || _output oops "Could not change to $DIR_BASE"
    $JSON_GET_DL $JAR_URL_BUILDTOOLS || _output oops "Download of $JAR_URL_BUILDTOOLS failed."
    mkdir $DIR_BUILDTOOLS
    mv $JAR_BUILDTOOLS $DIR_BUILDTOOLS
    #TODO make this: cp -f spigot-*.jar "${SERVER_DIR}"
    _output debug "Upgrade: BuildTools jar downloaded .. ready to go."
fi

# Update: What happened?
# If the script didn't quit here, that means we have a new spigot build for 1.16.1 of minecraft,
# and we know if we can upgrade spigot with the buildtools we have, or if we need to get a new jar.

# do we just update spigot?
# do we get buildtools?

## cache sh ends here
## buildtools sh starts here

_output debug "Done. Next, building new $JAR_SPIGOT .. $B(can take a while, leave it running)"
cd "$DIR_BUILDTOOLS" || _output oops "Could not change to $DIR_BUILDTOOLS"
if [ "$JAVA_VERBOSE" == true ]; then
    # do not hide JVE output during compile
    $JAVA_JDK $JAVA_MEMORY $JAR_PARAMS -jar $JAR_BUILDTOOLS --rev $MINECRAFT_VERSION || _output oops "Failed; Could not build '$JAR_BUILDTOOLS'. Quitting!"
    # _output debug "pretending to build.."
else
    # do not display JVE output during compile (assuming value false)
    # todo: should else if and failover else
    $JAVA_JDK $JAVA_MEMORY $JAR_PARAMS -jar $JAR_BUILDTOOLS --rev $MINECRAFT_VERSION > /dev/null 2>&1 || _output oops "Failed; Could not build '$JAR_BUILDTOOLS'. Quitting!"
    # _output debug "pretending to build.."
fi

_output debug "Done. Next, isolating $JAR_SPIGOT .."
mv -f "$JAR_SPIGOT" "$DIR_BASE" || _output oops "Failed; No such file or directory. Quitting!"
cd "$DIR_BASE" || _output oops "Failed; Could not change to $DIR_BASE. Quitting!"

ls -lh "$JAR_SPIGOT" || _output oops "Failed; Could not list '$JAR_SPIGOT'. Quitting!"
pwd

# We are done, let's get outtah here
_output okay "That's it, we're done!"

#EOF Copyright (c) 2011-2020 - Floris Fiedeldij Dop - https://scripts.1moreblock.com