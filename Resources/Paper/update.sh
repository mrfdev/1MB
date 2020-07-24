#!/bin/bash
# chmod a+x update.sh
# ./update.sh
# Update Papermc.io's jar, build 002, for Minecraft 1.15.2, by Floris


#### NOT FINISHED : DO NOT USE


#### config stuff

DIR_SCRIPT="" #leave empty for auto discovery

BACKUPFILE="paperclip._jar"
CURRENTFILE="paperclip.jar"
DOWNLOADFILE="https://papermc.io/api/v1/paper/1.16.1/latest/download"

DEBUG=true # Debug mode true means you get some output



# STRING="paper-350.jar"
# echo "${STRING//[!0-9]/}"
# echo "${STRING//[^0-9]/}"

# exit 0




#### the rest ####
# that means you stop editing beyond this point

[ "$EUID" -eq 0 ] && oops "*!* This script should not be run using sudo, or as the root user!"

Y="\\033[33m"; X="\\033[91m"; R="\\033[0m" #themelol

function debug {
	if [ "$DEBUG" == true ]; then
		echo -e "\\n$Y(debug): $X $1 $R" >&2
	fi
}

# Figure out the working directory (or force is)
if [ -z "$DIR_SCRIPT" ]; then
	SH_SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SH_SOURCE" ]; do
		SH_TARGET="$(readlink "$SH_SOURCE")"
		if [[ $SH_TARGET == /* ]]; then
			SH_SOURCE="$SH_TARGET"
		else
			#DIR_BASE="$( dirname "$SH_SOURCE" )"
			SH_SOURCE="$DIR_BASE/$SH_TARGET"
		fi
	done
	RDIR="$( dirname "$SH_SOURCE" )"
	DIR_BASE="$( cd -P "$( dirname "$SH_SOURCE" )" && pwd )"
else
	DIR_BASE="$DIR_SCRIPT"
fi

# is curl or wget available?
if type "curl" > /dev/null 2>&1
then
	debug "Found 'curl', that is great.."
	JSON_GET="curl -f -L -s"
	GETTER="curl -L -s -O"
elif type "wget" > /dev/null 2>&1
then
	debug "Found 'wget', that is good.."
	JSON_GET="wget -q -O -"
	GETTER="wget"
else
	debug "Failed; Could not find required 'curl' or alternative 'wget'. Quitting!"
	exit 0
fi

# What is the latest paperclip build number?
# https://papermc.io/ci/job/Paper-1.15/lastSuccessfulBuild/buildNumber
# debug: spits out just NUM

JSON_DATA=$($JSON_GET "https://papermc.io/ci/job/Paper-1.15/lastSuccessfulBuild/buildNumber")

if [ -z "$JSON_DATA" ]; then
	debug "Failed to get data from $JSON_URL_BUILDTOOLS, quitting script!"
	exit 0
else
	CURRENT_PAPERCLIP_BUILD="$JSON_DATA"
	debug "Found Paperclip build number online: $CURRENT_PAPERCLIP_BUILD"
fi

## What do we have?
debug "Found the cached data (offline): CURRENT_PAPERCLIP_BUILD: $CURRENT_PAPERCLIP_BUILD"
debug "Found the current data (online): CURRENT_PAPERCLIP_BUILD: $CURRENT_PAPERCLIP_BUILD"








BACKUPFILE="$DIR_BASE/$BACKUPFILE"
CURRENTFILE="$DIR_BASE/$CURRENTFILE"

# is there an old paperclip backup?
if [ -f "$BACKUPFILE" ]
then
	debug "Found an existing BACKUPFILE '$BACKUPFILE', removing it."
	rm -f "$BACKUPFILE" # Clean up; removing backup
else
	debug "Found no existing BACKUPFILE: '$BACKUPFILE', attempting to make a backup."
fi

# is there a current paperflip file to backup?
if [ -f "$CURRENTFILE" ]
then
	debug "Found an existing CURRENTFILE '$CURRENTFILE', backing it up."
	mv -f "$CURRENTFILE" "$BACKUPFILE"
else
	debug "Found no existing CURRENTFILE '$CURRENTFILE', guess we can go dl it now."
fi

cd "$DIR_BASE" || debug "Could not change to $DIR_BASE"
$GETTER $DOWNLOADFILE || debug "Download of $DOWNLOADFILE failed."


### TODO : use new download method, old one is deprecated and will be discontinued
# curl --remote-name --remote-header-name --write-out "Got: %{filename_effective}" --silent https://papermc.io/api/v1/paper/1.15.2/latest/download
