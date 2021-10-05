#!/bin/bash

# @Filename: 1MB-UpdatePaper.sh
# @Version: 2.0, build 012
# @Release: October 5th, 2021
# @Description: Helps us get a Minecraft Paper 1.17.1 server .jar
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/floris
# @Install: chmod a+x 1MB-UpdatePaper.sh
# @Syntax: ./1MB-UpdatePaper.sh
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# Which version are we trying to specifically get a .jar for?
# I recommend to always restrict it to the version you're using now.
# Examples: 1.16.5, 1.12.2, 1.17.1, 1.13.2
# Note: Leave this empty to always get the latest Minecraft version,
#       meaning if Minecraft 1.18.9 came out, it will get not 1.17.1 but 1.18.9
_minecraftVersion=""

# Paper-1.17.1.jar will be downloaded in the directory the script runs in, 
# even if there's a server.properties file. If you run this outside of the 
# server directory (_targetDir) but you want to automatically move it there,
# then set this to true, and define the full path to the server directory.
_targetMove=false
_targetDir="/Users/floris/MinecraftServer"

# Output some progress? (Set to false might be handy for crontabs)
_debug=true

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###
[ -z "$_minecraftVersion" ] && _minecraftVersion="0"

_backupFile="paper-$_minecraftVersion._jar"
_currentFile="paper-$_minecraftVersion.jar"
_serverPropertiesFile="server.properties"
_cacheFile="cachepaper.txt"
_apiUrl='https://papermc.io/api/v2/projects/paper'

#leave empty for auto discovery
_dirScript=""

### END OF CONFIGURATION
#
# Really stop configuring things
# beyond this point. I mean it.
#
###

# theme
B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m"

# working dir
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
        rm -f "$_cacheFile.tmp" # Clean up; removing temp cachefile.
        exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R" >&2
        cache true "$_prefix $_args"
        rm -f "$_cacheFile.tmp" # Clean up; removing temp cachefile.
        exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        if [ "$_debug" == true ]; then
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
    sed -i.tmp "4s#.*#${1}#" "$_cacheFile"
    sed -i.tmp "5s#.*#${2}#" "$_cacheFile"
    # debug "cachefile: $1, msg: $2."
    # debug 1 "cat $_cacheFile"
}

### CACHE LEGEND / HANDLER
#
# line 1 : Minecraft version (example: 1.17.1)
# line 2 : Paper build version (example: 281)
# line 3 : BuildTools build version (example: 108) (not used)
# line 4 : Shell script last-run state (example: true|false)
# line 5 : Shell script state message (example: Build successful)
#
# At any time the cache file can be renamed, 
# or deleted. If it's not found it will create one.
# The 'default' values are for Paper 1.17.1,
# but you can change this obviously. 
# The other values are 'old' on purpose, so when you
# delete the cache file, it also forces a redownload.
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
_cachePpBuild=$(sed '2q;d' $_cacheFile) #line2
_cacheBtBuild=$(sed '3q;d' $_cacheFile) #line3
_cacheShState=$(sed '4q;d' $_cacheFile) #line4
_cacheShStMsg=$(sed '5q;d' $_cacheFile) #line5

# functions to help find installed programs like curl / wget / etc
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

# prefer curl over wget, if we can't find curl, use wget, if that fails, exit script.
if binExists "curl"; then
    binDetails "$_"
    _jsonGetter="curl -f -L -s"
    _jsonDownload="curl -f -L -s -o"
    _output debug "We can use curl, no need to check for wget"
else
    _output debug "$_ Not found, .. maybe we can use wget?"
    if binExists "wget"; then
        binDetails "$_"
        _jsonGetter="wget -q -O -"
        _jsonDownload="wget -q --content-disposition -O"
        _output debug "We can use wget, great."
    else
        _output oops "$_ also not found, .. we require either curl or wget \\n -> https://www.cyberciti.biz/faq/how-to-install-curl-command-on-a-ubuntu-linux/ \\n -> https://www.cyberciti.biz/faq/how-to-install-wget-togetrid-of-error-bash-wget-command-not-found/"
    fi
fi

# TODO : at some point we want to 'restart' if we once run 1.17.1 but now run 1.16.1, build numbers dont match of course.

# Time to start doing something with the data that we have now.

# Lets find out if we should auto discover the latest version,
# or if we are going to find the latest build for a particular version.
if [ -z "$_minecraftVersion" ] || [ "$_minecraftVersion" = "0" ]
then
    _apiMcVersion=$($_jsonGetter "$_apiUrl")
    _apiMcVersion=${_apiMcVersion%\"*}
    _apiMcVersion=${_apiMcVersion##*\"}

    # Update our cache file with the found version number
    sed -i.tmp "1s#.*#${_apiMcVersion}#" "$_cacheFile"
else
    _apiMcVersion=$_minecraftVersion
fi

_apiPaperBuild=$($_jsonGetter "$_apiUrl/versions/$_apiMcVersion")
_apiPaperBuild=${_apiPaperBuild%]*}
_apiPaperBuild=${_apiPaperBuild##*[,[]}

_output debug "Latest Paper _apiPaperBuild found for $_apiMcVersion:  $_apiPaperBuild"

_apiPaperFile=$($_jsonGetter "$_apiUrl/versions/$_apiMcVersion/builds/$_apiPaperBuild")
_apiPaperFile=${_apiPaperFile##*\"name\":\"}
_apiPaperFile=${_apiPaperFile%%\"*}
_apiFinalFile="paper-$_apiMcVersion.jar"

_output debug "Found the current build (offline): $_cachePpBuild"
_output debug "Found the current build (online): $_apiPaperBuild"

# if our cached number is less than our found online number, it's time to backup and upgrade.
if [ "$_cachePpBuild" -lt "$_apiPaperBuild" ]; then
    _output debug "Cache $_cachePpBuild is less than online $_apiPaperBuild (We can continue..)"
    # We need to update _currentFile
    _backupFile="paper-$_apiMcVersion._jar"
    _currentFile="$_apiFinalFile"
    # Update our cache file with the newer build number
    sed -i.tmp "2s#.*#${_apiPaperBuild}#" "$_cacheFile"
else
    _output oops "What we found online is not newer than what we already have, nothing to do.\\n If you really want to get a new .jar you can remove $_cacheFile and run this script again."
fi

_backupFile="$_dirBase/$_backupFile"
_currentFile="$_dirBase/$_currentFile"

cd "$_dirBase" || _output oops "Could not change to $_dirBase"

# TODO: we probably want to check if we store in _targetDir or not.

# should we actually get the new file, what if there's a server running?
# _serverPropertiesFile="server.properties"
_netfind() { _serverPropertiesTest=$(lsof -iTCP -sTCP:LISTEN -n -P | grep -i "$1");
    if [ -z "$_serverPropertiesTest" ]; then
        _output debug "Found '$_serverPropertiesFile' (good!), and found nothing listening on port '$_serverPropertiesPort' (good!).\\nAssuming there's no server running, we can make the server jar"
    else
        _output debug "$_serverPropertiesTest\\nPossible solutions: Stop the server first, or run this script in an empty directory"
        _output oops "Found a server running, halting script, I don't want to replace that jar!"
    fi
}; [[ -f "$_serverPropertiesFile" ]] && _serverPropertiesPort=$(grep "^server-port=" $_serverPropertiesFile | awk -F= '{print $2}') && _netfind "$_serverPropertiesPort" || _output debug "Found no '$_serverPropertiesFile' (good!), we can replace the server jar"

# is there an old paper jar backup?
if [ -f "$_backupFile" ]; then
    _output debug "Found an existing jar backed up: '$_backupFile', removing it.."
    rm -f "$_backupFile" # Clean up; removing backup
else
    _output debug "Found no existing jar backed up: '$_backupFile', attempting to make one.."
fi

# is there a current paper jar file to backup?
if [ -f "$_currentFile" ]; then
    _output debug "Found an existing jar '$_currentFile', backing it up.."
    mv -f "$_currentFile" "$_backupFile" || _output oops "Backup move of $_currentFile failed. "
else
    _output debug "Found no existing jar '$_currentFile', guess we can download one.."
fi

_output debug "Starting download.. (this could take a short bit)"

$_jsonDownload "$_apiFinalFile" "$_apiUrl/versions/$_apiMcVersion/builds/$_apiPaperBuild/downloads/$_apiPaperFile"

_output debug "Done. Next, trying to isolate $_apiFinalFile .."

if [ -f "$_serverPropertiesFile" ]; then
    _output debug "It looks like we are in the same dir as server.properties, we do not have to move the jar to a target directory."
else
    if [ "$_targetMove" = true ] ; then
        _output debug "We are not in the same dir as server.properties, and _targetMove is true, so lets move the $_apiFinalFile to $_targetDir now.."
        mv -f "$_apiFinalFile" "$_targetDir" || _output oops "Was unable to move $_apiFinalFile to $_targetDir"
    else
        _output debug "We are not in the same dir as server.properties, but _targetMove is false, so we are not going to move anything around."
    fi
fi

if [ "$_targetMove" = true ] ; then
    cd "$_targetDir" || _output oops "Could not change to target dir $_targetDir"
fi
ls -lh "$_apiFinalFile"
pwd
cd "$_dirBase" || _output oops "Could not change back to working dir $_dirBase"

# We are done, let's get outtah here
_output okay "That's it, we're really done!"

#EOF Copyright (c) 2011-2021 - Floris Fiedeldij Dop - https://scripts.1moreblock.com
