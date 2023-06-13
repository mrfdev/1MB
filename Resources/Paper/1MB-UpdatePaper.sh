#!/bin/bash

# @Filename: 1MB-UpdatePaper.sh
# @Version: 3.1.1, build 023
# @Release: June 13th, 2023
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
_apiURL="https://api.papermc.io/v2/projects"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_debug=true # Set to false to minimize output.

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

# parse command line options
while getopts ":d:h-:" opt; do
  case ${opt} in
    d )
      _saveDir=$OPTARG
      ;;
    h )
      _output oops "Syntax: '$0 (-d /full/path/to/store/jars/in)'" 1>&2
      ;;
    \? )
      _output oops "Syntax: '$0 (-d /full/path/to/store/jars/in)'" 1>&2
      ;;
    : )
      _output oops "Syntax: '$0 (-d /full/path/to/store/jars/in)'" 1>&2
      ;;
  esac
done

# create directory if it doesn't exist
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
    _output debug "$_apiProject is not in the list of projects \\n halting script"
    exit 1
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

_output debug "We found this channel: \\n$channel \\n but we want to make sure it says default"

# we are looking for the default channel, so let us know if it is a valid project
## TODO : maybe in the future we can get a prompt asking if it's not default, if we still want it, in case there's a 1.21 experimental build we still want
if [[ $channel == *"default"* ]]; then
    _output debug "it seems to say default"
else
    _output oops "not sure it says default, halting script"
fi

# next, we want to specifically get the downloads > application > name (paper-1.20.1-18.jar)
appName=$(echo "$responseLatestBuild" | jq -r '.downloads.application.name')
_output debug "appName $appName"

##### download-controller

# lets get the jar finally
## TODO : if we have old jar, check if we have old back update, rm it, then rename latest jar to new backup jar, before storing downloaded jar
_output debug "Downloading new .jar...."
curl -f -L -s -X 'GET' -o "$_saveDir/$_apiProject-$latestVersion.jar" "$_apiURL/$_apiProject/versions/$latestVersion/builds/$latestBuild/downloads/$appName" -H 'accept: application/java-archive'

# check the exit status of the curl command
if [ $? -ne 0 ]; then
  _output oops "Error: Failed to get response from the API"
fi

_output debug "Saved to '$_saveDir/$_apiProject-$latestVersion.jar'"

# We are at the end of the script, we're done.
_output okay "Done."

# TODO
# only download new jar if the latest version matches our cache, and latest build matches our cache
# this also allows us to default to project paper, but lets ppl use .sh <projectname> as paramter
# the script has a few todo items that aren't at the end, review those as well.
# allow changing channel default to something else like experimental