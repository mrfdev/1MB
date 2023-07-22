#!/bin/bash

# @Filename: 1MB-UpdatePaper.sh
# @Version: 3.2.1, build 026
# @Release: July 22nd, 2023
# @Description: Helps us get a Minecraft Paper 1.20.1 server .jar
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-UpdatePaper.sh
# @Syntax: ./1MB-UpdatePaper.sh (-h) (-d /full/path/to/server)
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# Save the Paper .jar to a default directory
# Default is "." for saving it to current
# Example 1 "./server"
# Example 2 "/full/path/to/server" 
# Startup param -d will override this
_saveDir="."

##### projects-controller query

# Hard set the projects-controller to check for, we're going for paper
# There's currently no support for other projects.
_apiProject="paper"
_apiChannel="default"
_apiURL="https://api.papermc.io/v2/projects"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_debug=true # Set to false to minimize output.
_cacheFile="cachePaper.json" # Name of the temporary cache file (expected to be json format)

Y="\e[33m"; C="\e[36m"; PB="\e[38;5;153m"; B="\e[1m" R="\e[0m" # theme

### END OF CONFIGURATION
#
# Really stop configuring things
# beyond this point. I mean it.
#
###

# Function that we use to handle the output to the screen
function _output {
    case "$1" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        printf "\n%b" "$B$Y$_prefix$X $_args $R\n" >&2; exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        printf "\n%b" "$B$Y$_prefix$PB $_args $R\n" >&2; exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        [[ "$_debug" == true ]] && printf "%b\n" "$Y$_prefix$C $_args $R" >&2
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        printf "%b\n" "$Y$_prefix$PB $_args $R"
    ;;
    esac
}

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!" # You should only use this script as a regular user

# parse command line options:
# Process -d and/or -c params, or use default values
while getopts ":d:c:h-:" opt; do
  case ${opt} in
    d )
      _saveDir=$OPTARG
      ;;
    c )
      case "$OPTARG" in
        default|experimental)
          _apiChannel=$OPTARG
          ;;
        *)
          _output oops "Invalid value for -c. Allowed values are 'default' or 'experimental'."
          ;;
      esac
      ;;
    h )
      _output oops "Syntax: '$0 -d /full/path/to/store/jars/in -c [default|experimental]'"
      ;;
    \? )
      _output oops "Syntax: '$0 -d /full/path/to/store/jars/in -c [default|experimental]'"
      ;;
    : )
      _output oops "Syntax: '$0 -d /full/path/to/store/jars/in -c [default|experimental]'"
      ;;
  esac
done

# And then create directory if it doesn't exist
if [ ! -d "$_saveDir" ]; then
  mkdir -p "$_saveDir"
fi

# check if jq is installed, if not forcefully halt the script
(command -v jq >/dev/null) && _output "Found 'jq', which is great ..." || _output oops "Oops, 'jq' seems to not be installed. This is required. Try installing either. \\n -> macOS: brew install jq, Ubuntu: apt install jq \\n"
(command -v curl >/dev/null) && _output "Found 'curl', which is great ..." || _output oops "Oops, 'curl' seems to not be installed. This is required. Try installing either. \\n -> macOS: brew install curl, Ubuntu: apt install curl \\n"

# CURL params explained
# -f : This option tells curl to fail silently if the HTTP status code returned by the server is >= 400. This means that if the request returns a status code indicating an error (such as 404 Not Found), curl will simply return an error code and not print any output.
# -L : This option tells curl to follow any redirects that the server sends in the response. If the server returns a redirect status code (such as 301 Moved Permanently) and the Location header, curl will automatically make a new request to the URL specified in the Location header.
# -s : This option tells curl to run in "silent" mode, which means that it will not print any progress information or error messages to the console.
# -X 'GET' : This option tells curl to use the GET method for the request. This is the default method, so you could also leave this option out.
# -H 'accept: application/json' : This option sets the value of the Accept header in the request to "application/json". This tells the server that the client is expecting a JSON response.

# lets get the json response from the papermc api
response=$(curl -f -L -s -X 'GET' "$_apiURL" -H 'accept: application/json')

# check the exit status of the curl command
if [ $? -ne 0 ]; then
  _output oops "Error: Failed to get response from the API"
fi

# and get the raw values of the key projects
projects=$(echo "$response" | jq -r '.projects[]')
_output debug "We found these projects: \\n$projects \\n but we want just _apiProject"

# we are looking for paper, so let us know if it is a valid project
if [[ $projects == *"$_apiProject"* ]]; then
    _output debug "$_apiProject is in the list of projects | we can continue"
else
    _output oops "$_apiProject is not in the list of projects \\n halting script"
fi

##### project-controller query (paper)

# lets get the json response from the papermc api for project _apiProject
responseProject=$(curl -f -L -s -X 'GET' "$_apiURL/$_apiProject" -H 'accept: application/json')

# check the exit status of the curl command
if [ $? -ne 0 ]; then
  _output oops "Error: Failed to get response from the API"
fi

# and get the raw values of the key versions
versions=$(echo "$responseProject" | jq -r '.versions[]')
_output debug "found versions: \\n$versions \\n but we want the latest version, which seems to be:"

# and get the last value of the key versions
latestVersion=$(echo "$responseProject" | jq -r '.versions[-1]')
_output debug "latest version: $latestVersion"


##### version-controller query (1.20.1)

# lets get the json response from the papermc api for project $latestVersion
responseBuilds=$(curl -f -L -s -X 'GET' "$_apiURL/$_apiProject/versions/$latestVersion" -H 'accept: application/json')

# check the exit status of the curl command
if [ $? -ne 0 ]; then
  _output oops "Error: Failed to get response from the API"
fi

# and get the raw values of the key builds
builds=$(echo "$responseBuilds" | jq -r '.builds[]')
_output debug "found builds: \\n$builds \\n but we want the latest builds, which seems to be:"

# and get the last value of the key builds
latestBuild=$(echo "$responseBuilds" | jq -r '.builds[-1]')
_output debug "latest build number: $latestBuild"


##### version-builds-controller

#skipping, maybe use this to filter only channel default entries?

##### version-build-controller

# lets get the json response from the papermc api for the $latestVersion's $latestBuild
responseLatestBuild=$(curl -f -L -s -X 'GET' "$_apiURL/$_apiProject/versions/$latestVersion/builds/$latestBuild" -H 'accept: application/json')

# check the exit status of the curl command
if [ $? -ne 0 ]; then
  _output oops "Error: Failed to get response from the API"
fi

# and get the raw values of the key channel
channel=$(echo "$responseLatestBuild" | jq -r '.channel')

_output debug "We found this channel: \\n$channel \\n but we want to make sure it says default (or _apiChannel)"

# we are looking for the default channel, so let us know if it is a valid project
if [[ $channel == *"$_apiChannel"* ]]; then
    _output debug "it seems to say '$_apiChannel', that's great."
else
    _output oops "It does not seem to say '$_apiChannel' for found channel $channel, halting script"
fi

# next, we want to specifically get the downloads > application > name (paper-1.20.1-18.jar)
appName=$(echo "$responseLatestBuild" | jq -r '.downloads.application.name')
_output debug "appName $appName"

##### download-controller

# Now that we know what is online, lets write it to a cache file if it doesn't exist already, this way we can compare values and only download if there's a newer version for the same build. And otherwise gracefully halt the script.

# Okay, let's check if the _cacheFile exists already
if [ -f "$_cacheFile" ]; then
    # Get the current value for key 'version' from _cacheFile (using jq)
    # currentVersion=$(jq -r '.version' $_cacheFile) (integer error, using below tostring to fix)
    currentVersion=$(jq -r '.version | tostring' "$_cacheFile")

    # Get the current value for key 'build' from _cacheFile (using jq)
    currentBuild=$(jq -r '.build' $_cacheFile)

    # And before we check the build, we have to make sure we're still on the same version. 
    # Compare the current version from _cacheFile against the latestVersion we just found:
    if [ "$currentVersion" = "$latestVersion" ]; then
        # Example: We made a 1.20.1 server jar before, we want to only continue if what we found is 1.20.1 as well.
        _output debug "The 'version' value in $_cacheFile is the same as the found value ($latestVersion). (that is what we want)"
    elif [ "$currentVersion" \< "$latestVersion" ]; then
        # Note: Just in case a future version is released, we don't want to accidentally break the server with an unexpected upgrade.
        # To upgrade anyway, remove the cache .json file and run this script again.
        _output oops "The 'version' value in $_cacheFile is older than the found value ($latestVersion). (to avoid auto upgrades to newer versions, halting script ~ if you do want to upgrade, delete $_cacheFile and run this script again)"
    else
        # We have an unexpected value, halt gracefully and manually review the situation.
        _output oops "The 'version' value in $_cacheFile is newer than the found value ($latestVersion). (this is weird, did not expect this, halting script - maybe manually check what the latest Minecraft version is."
    fi

    # And now we can check the build, lets compare the current build from _cacheFile against the latestBuild we just found:
    if [ "$currentBuild" -eq "$latestBuild" ]; then
        # If we already have downloaded a build number, we don't have to do it again. Gracefully halt script.
        _output oops "The 'build' value in $_cacheFile ($currentBuild) is the same as the found value ($latestBuild). (we have no reason to upgrade, halting script - if you desire to re-download anyway, then delete $_cacheFile)"
    elif [ "$currentBuild" -lt "$latestBuild" ]; then
        # Example: 1 in cache is older than 2 just found, so we want to upgrade.
        _output debug "The 'build' value in $_cacheFile ($currentBuild) is older than the found value ($latestBuild). (we want to upgrade, continue)"
        # Update the new 'build' value in the cache file file
        jq --arg latestBuild "$latestBuild" '.build = $latestBuild' cachePaper.json > temp.json && mv temp.json cachePaper.json
        _output debug "cache file '$_cacheFile' key 'build' ($currentBuild) updated to '$latestBuild'."
    else
        # We have an unexpected value, halt gracefully and manually review the situation.
        _output oops "The 'build' value in $_cacheFile ($currentBuild) is newer than the found value ($latestBuild). (this is weird, did not expect this, halting script - maybe manually check what the latest releases are."
    fi

else
    # If the JSON cache file has not been found, we can create it for the first time.
json_content=$(cat << EOF
{
  "project": "$_apiProject",
  "version": "$latestVersion",
  "build": "$latestBuild",
  "channel": "$channel"
}
EOF
)
    echo "$json_content" > $_cacheFile
    _output debug "The '$_cacheFile' file has been created successfully!"
fi

# Before we finally get the latest jar, we have to remove the oldest backup, and then backup the current jar. Just in case.

# Do we have a backup we have to delete?
if [ -e "_$_apiProject-$latestVersion.jar" ]; then
    # Yep, we found it, we can delete it
    rm "_$_apiProject-$latestVersion.jar"
    _output debug "Found the oldest backup file '_$_apiProject-$latestVersion.jar', and deleted it."
else
    # Nope, we did not find it, nothing to delete
    _output debug "The file '_$_apiProject-$latestVersion.jar' was not found, nothing to delete."
fi

# Do we have a current version we should backup?
if [ -e "$_apiProject-$latestVersion.jar" ]; then
    # Yep, we found it, we can rename it to back it up
    mv "$_apiProject-$latestVersion.jar" "_$_apiProject-$latestVersion.jar"
    _output debug "The file '$_apiProject-$latestVersion.jar' was found, and has been renamed to '_$_apiProject-$latestVersion.jar'"
else
    # Nope, we did not find it, nothing to backup
    _output debug "The file '$_apiProject-$latestVersion.jar' was not found, nothing to backup."
fi

# Okay, now lets get the jar finally
_output debug "Downloading new .jar...."
curl -f -L -s -X 'GET' -o "$_saveDir/$_apiProject-$latestVersion.jar" "$_apiURL/$_apiProject/versions/$latestVersion/builds/$latestBuild/downloads/$appName" -H 'accept: application/java-archive'

# check the exit status of the curl command
if [ $? -ne 0 ]; then
  _output oops "Error: Failed to get response from the API"
fi

_output debug "Saved to '$_saveDir/$_apiProject-$latestVersion.jar'"

# We are at the end of the script, we're done.
_output okay "Done."

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com