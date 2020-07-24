#!/bin/bash

# @Filename: 1MB-BuildTools.sh
# @Version: 1.9, build 047
# @Release: July 25th, 2020
# @Description: Helps us get a Minecraft Spigot 1.16.1 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-BuildTools.sh
# @Syntax: ./1MB-BuildTools.sh

# @URL: Latest source, info, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Stuff here you COULD change, but ONLY if you really really have to
#
###

# Which version are we building against?
MINECRAFT_VERSION="1.16.1"

JAVA_VERSION="11.0"
#	11.0 = java 11, can be used for Minecraft 1.13.x and up.
#	1.8 = java 8, required for Minecraft 1.12.x and up.
	if [ "$JAVA_VERSION" != "11.0" ]; then
		# 08 (if you want to make spigot for 1.12.2 or 1.13.2)
		JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
	else
		# 11 (if you want to make spigot for 1.13.2, 1.15.2 or 1.16.x)
		JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"
	fi

JAR_BUILDTOOLS="BuildTools.jar"
DIR_SCRIPT="" #leave empty for auto discovery
#	example: DIR_SCRIPT="/Users/floris/MinecraftServer/_development"

JAR_SPIGOT="spigot-$MINECRAFT_VERSION.jar" 
#	1MB-start.sh defaults to spigot-1.16.1.jar

JAR_PARAMS="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
# 	"--compile craftbukkit" If you need to make specifically craftbukkit
#	-Dfile.encoding=UTF-8 (ensure that all UTF-8 chars are being saved properly)
#	-Dapple.awt.UIElement=true (helps on macOS to not show icon in cmd-tab)

JAVA_MEMORY="-Xms10G -Xmx10G"
#	"" = uses the default
#	"-Xmx2G" = maximum memory allocation pool of memory for JVM.
#	"-Xms1G" = initial memory allocation pool of memory for JVM.
# For Spigot servers we recommend -Xms10G -Xmx10G for 16GB systems.
# More details here: https://stackoverflow.com/questions/14763079/

URL_BASE="https://hub.spigotmc.org"
JSON_URL_MINECRAFT="$URL_BASE/stash/projects/SPIGOT/repos/builddata/raw/info.json"
JSON_URL_SPIGOT="$URL_BASE/versions/$MINECRAFT_VERSION.json"
JSON_URL_BUILDTOOLS="$URL_BASE/jenkins/job/BuildTools/lastSuccessfulBuild/buildNumber"
JAR_URL_BUILDTOOLS="$URL_BASE/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/$JAR_BUILDTOOLS"

# What to call the cache-file (default: cache.txt)
CACHEFILE="cache.txt"

# Debug mode on or off?
DEBUG=true
# 	Default: true (that means it spits out progress))

JAVA_VERBOSE=true # (default: false)
#	true <--- The output of the JVE will be visible,
#	false <-- "> /dev/null 2>&1" <-- it will be hidden.

# theme
B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m"



#######################################################
#### !You're done, stop editing beyond this point! ####
#######################################################



### FUNCTIONS
#
# oops = spit out failure and exit script
# 	$1 <- the msg
# okay = spit out success and exit script
# 	$1 <- the msg
# debug = echo out debug information or a command
# 	1=cmd <- $1, $2 else: the msg
# cache = updates cache last-run state and msg
# 	$1 <- true|false, $2 <- msg
#
###

function oops {
	#TODO: merge with our output function (currently debug)
	echo -e "\\n$X $1 $R" >&2

	# Updating cachefile
	cache false "$1"
	rm -f "$CACHEFILE.tmp" # Clean up; removing temp cachefile.
	exit 1
}

function okay {
	#TODO: merge with our output function (currently debug)
	echo -e "\\n$X $1 $R" >&2

	cache true "$1"
	rm -f "$CACHEFILE.tmp" # Clean up; removing temp cachefile.
	exit 1
}

function debug {
	if [ "$DEBUG" == true ]; then
		if [ "$1" != 1 ]; then
			#TODO buildOutput ..
			#TODO and after all conditionals, echo buildOutput
			echo -e "\\n$Y(debug)$C $1$R"
			cache true "$1"
		else
			echo -e "\\n$Y(debug):\\n$C$($2)$R"
		fi
	fi
}

function cache {
	# Write given msg true/false to cachefile
	sed -i.tmp "4s#.*#${1}#" "$CACHEFILE"
	sed -i.tmp "5s#.*#${2}#" "$CACHEFILE"
	# debug "cachefile: $1, msg: $2."
	# debug 1 "cat $CACHEFILE"
}

[ "$EUID" -eq 0 ] && oops "*!* This script should not be run using sudo, or as the root user!"

# Figure out the working directory

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
	RDIR="$( dirname "$SH_SOURCE" )"
	DIR_BASE="$( cd -P "$( dirname "$SH_SOURCE" )" && pwd )"
else
	DIR_BASE="$DIR_SCRIPT"
fi

DIR_BUILDTOOLS="$DIR_BASE/BuildTools/"


### CACHE LEGEND
#
# line 1 : Minecraft version (example: 1.16.1)
# line 2 : Spigot nightly build version (example: 2591)
# line 3 : BuildTools build version (example: 108)
# line 4 : Shell script last-run state (example: true|false)
# line 5 : Shell script state message (example: Build successful)
#
###

### CACHE HANDLER
#
# At any time the cache.txt file can be renamed, 
# or deleted. If it's not found it will create one.
# The 'default' values are for Spigot 1.16.1,
# but you can change this obviously. 
# The other values are 'old' on purpose, so when you
# delete the cache.txt file, it also forces a rebuild,
# of both buildtools and spigot jar files.
#
###

CACHEFILE="$DIR_BASE/$CACHEFILE"

# TODO flip this around, if we did not ! find one, create it. saving on an else

if [ -f "$CACHEFILE" ]
then
	# success
	# There's an existing cache
	debug "Found an existing CACHEFILE '$CACHEFILE'."
	debug 1 "cat $CACHEFILE"
else
	# failure
	# File was never made, or manually deleted
	# Let's create a new one. 
	# The - in <<- lets us indent (but ignore out) our code 
	# todo: we have a config for mc version, use variable here somehow?
	cat <<- EOF > $CACHEFILE
		$MINECRAFT_VERSION
		0
		0
		true
		Never
	EOF
	debug "Found no existing cache: '$CACHEFILE', created with defaults:"
	debug 1 "cat $CACHEFILE"
fi

# At this point we have an old or a new cache file, adding them to variables
# debug: https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
# debug: sed 'NUMq;d' file // sed "${NUM}q;d" file

CACHE_MC_BUILD=$(sed '1q;d' $CACHEFILE) #line1
CACHE_SP_BUILD=$(sed '2q;d' $CACHEFILE) #line2
CACHE_BT_BUILD=$(sed '3q;d' $CACHEFILE) #line3
CACHE_SH_STATE=$(sed '4q;d' $CACHEFILE) #line4
CACHE_SH_STMSG=$(sed '5q;d' $CACHEFILE) #line5

### REQUIREMENTS
#
# do we have curl, wget, java, git, etc?
#
###

# Do we have curl or wget? (else we're outtah here)
if type "curl" > /dev/null 2>&1
then
	debug "Found 'curl', that is great.."
	JSON_GET="curl -f -L -s"
	JSON_GET_DL="curl -L -s -O"
elif type "wget" > /dev/null 2>&1
then
	debug "Found 'wget', that is good.."
	JSON_GET="wget -q -O -"
	JSON_GET_DL="wget"
else
	oops "Failed; Could not find required 'curl' or alternative 'wget'. Quitting!"
fi

# Do we have git
if type -p "git" > /dev/null 2>&1
then
	debug "Found 'git', that is good.."
else
	oops "Failed; Could not find required 'git'. Quitting!"
fi

# Do we have java, and if so, do we have the right version?
if type -p "java" > /dev/null 2>&1
then
	JAVA_BUILD=$($JAVA_JDK -version 2>&1 | awk -F '"' '/version/ {print $2}')
	# debug "Found java version $JAVA_BUILD"
	if [[ "$JAVA_BUILD" > "$JAVA_VERSION" ]]; then
		debug "Found 'java ($JAVA_BUILD)', and we want $JAVA_VERSION or higher, all is good.."
	else         
		oops "Failed; found 'java', but your version $JAVA_BUILD is lower than the required $JAVA_VERSION. Quitting!"
	fi
else
	oops "Failed; no java found. Quitting!"
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
	oops "Failed to get $JSON_KEY from $JSON_URL_MINECRAFT, quitting script!"
else
	CURRENT_MC_BUILD="$JSON_RESULT"
	unset JSON_RESULT
	debug "Found MineCraft version number online: $CURRENT_MC_BUILD"
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
	oops "Failed to get $JSON_KEY from $JSON_URL_SPIGOT, quitting script!"
else
	CURRENT_SP_BUILD="$JSON_RESULT"
	unset JSON_RESULT
	debug "Found Spigot build number online: $CURRENT_SP_BUILD"
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
	oops "Failed to get data from $JSON_URL_BUILDTOOLS, quitting script!"
else
	CURRENT_BT_BUILD="$JSON_DATA"
	debug "Found BuildTools build number online: $CURRENT_BT_BUILD"
fi

## What do we have?
debug "Found the cached data (offline): MC: $CACHE_MC_BUILD, SP: $CACHE_SP_BUILD, BT: $CACHE_BT_BUILD"
debug "Found the current data (online): MC: $CURRENT_MC_BUILD, SP: $CURRENT_SP_BUILD, BT: $CURRENT_BT_BUILD"

# And COMPARE that against our cached data (regardless if that's old or new)

# We want builds for 1.15.2, so the cached version and the current version have to both be 1.15.2
# PATCH if [ "$CACHE_MC_BUILD" == "$CURRENT_MC_BUILD" ]; then
if [ "$CURRENT_MC_BUILD" == "$CURRENT_MC_BUILD" ]; then
	# success, 1.15.2 == 1.15.2
	debug "Comparing MC : OK; we can continue.."
else
	# failure, current must be newer
	oops "Comparing MC : Failure; Spigot $CURRENT_MC_BUILD detected, we only want Minecraft $CACHE_MC_BUILD builds. Quitting!"
	# May we desire to auto update regardless of number, we might want to update the cache
	# since we don't commenting this out:
	# sed -ie "1s/.*/$CURRENT_MC_BUILD/" $CACHEFILE
fi

# Spigot is being build against the right Minecraft version, but do we want to build a new Spigot?
# If the cached version is the same as the current version, we are done, exit the script.
# and otherwise there is a newer build out, we should go get it and compile a new jar.
if [ "$CURRENT_SP_BUILD" -le "$CACHE_SP_BUILD" ]; then
	# success, current Spigot build is less than or equal to our cached version (so it's older, or the same)
	oops "Comparing SP : OK; Latest Spigot $CURRENT_SP_BUILD is not newer, nothing to do. Quitting!"
	# Wait, .. check if cache file state is false, if so .. we quit last time we run it.. 
	# maybe it's fixed now, we have to assume we want to run the script again.
	# if state is positive, then we're outtah here.
else
	# failure, current must be newer, we should go get it and copmile a new jar
	debug "Comparing SP : OK; Newer build found ($CURRENT_SP_BUILD), we can continue.."
	# Updating our cache file with the newer build number
	sed -i.tmp "2s#.*#${CURRENT_SP_BUILD}#" "$CACHEFILE"
fi

# Ok, we know there's a new build out for Spigot for Minecraft 1.16.1,
# we can make it with buildtools, however, we have to make sure
# we are using the current version of buildtools, one more comparison
if [ "$CURRENT_BT_BUILD" == "$CACHE_BT_BUILD" ]; then
	# success, current BuildTools build is equal to our cached version (so it's the same)
	debug "Comparing BT : OK; No newer build found, we can just do an upgrade.." 
	# no need to quit script or download anything, compile Spigot with the buildtools.jar we have
else
	# failure, current must be newer, we should go get it and use that instead.
	debug "Comparing BT : OK; Not matching. Build found ($CURRENT_BT_BUILD), we should get it.."
	# updating cache with newer build number:
	sed -i.tmp "3s#.*#${CURRENT_BT_BUILD}#" "$CACHEFILE"
	# we need to download the newer buildtools before we compile spigot with the new bt jar.

	debug "Deleting old $DIR_BUILDTOOLS directory .."
	rm -rf $DIR_BUILDTOOLS
	debug "Done. Next, downloading $JAR_BUILDTOOLS .."
	cd "$DIR_BASE" || oops "Could not change to $DIR_BASE"
	$JSON_GET_DL $JAR_URL_BUILDTOOLS || oops "Download of $JAR_URL_BUILDTOOLS failed."
	mkdir $DIR_BUILDTOOLS
	mv $JAR_BUILDTOOLS $DIR_BUILDTOOLS
	#TODO make this: cp -f spigot-*.jar "${SERVER_DIR}"
	debug "Upgrade: BuildTools jar downloaded .. ready to go."

fi

# Update: What happened?
# If the script didn't quit here, that means we have a new spigot build for 1.16.1 of minecraft,
# and we know if we can upgrade spigot with the buildtools we have, or if we need to get a new jar.

# do we just update spigot?
# do we get buildtools?

## cache sh ends here
## buildtools sh starts here

debug "Done. Next, building new '$JAR_SPIGOT' .. (can take a while, leave it running)"
cd "$DIR_BUILDTOOLS" || oops "Could not change to $DIR_BUILDTOOLS"
if [ "$JAVA_VERBOSE" == true ]; then
	# do not hide JVE output during compile
	#debug "hello building "
	$JAVA_JDK $JAVA_MEMORY $JAR_PARAMS -jar $JAR_BUILDTOOLS --rev $MINECRAFT_VERSION || oops "Failed; Could not build '$JAR_BUILDTOOLS'. Quitting!"
else
	# do not display JVE output during compile (assuming value false)
	# todo: should else if and failover else
	$JAVA_JDK $JAVA_MEMORY $JAR_PARAMS -jar $JAR_BUILDTOOLS --rev $MINECRAFT_VERSION > /dev/null 2>&1 || oops "Failed; Could not build '$JAR_BUILDTOOLS'. Quitting!"
	#debug "hello building "
fi

debug "Done. Next, isolating '$JAR_SPIGOT' .."
mv $JAR_SPIGOT $DIR_BASE || oops "Failed; No such file or directory. Quitting!"
cd "$DIR_BASE" || oops "Failed; Could not change to $DIR_BASE. Quitting!"

ls -lh "$JAR_SPIGOT" || oops "Failed; Could not list '$JAR_SPIGOT'. Quitting!"
pwd

# We are done, let's get outtah here
okay "That's it, we're done!"

#EOF Copyright (c) 2011-2020 - Floris Fiedeldij Dop - https://scripts.1moreblock.com


## TODO ##################
# move 'failed' and 'quitting' into oops function
# debug and oops and output # should be one functions, .. different means. 
#### END OF TODO
