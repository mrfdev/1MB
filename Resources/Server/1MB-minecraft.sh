#!/bin/bash

# @Filename: 1MB-minecraft.sh
# @Version: 2.0, build 026 for Spigot 1.16.1 (java 11)
# @Release: August 1st, 2020
# @Description: Helps us start a Minecraft Spigot 1.16.1 server.
# @Contact:	I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-minecraft.sh
# @Syntax: ./1MB-minecraft.sh
# @URL: Latest source, info, & support: https://scripts.1moreblock.com/


### CONFIGURATION
#
# Stuff here you COULD change, but ONLY if you really really have to
#
###

# Which version are we running?
MINECRAFT_VERSION="1.16.1"

# Override auto engine jar detection; only use this if you have issues
_engine=""
# "" assumes auto detection for <engine>-1.16.1.jar 
# "spigot" assumes to look for spigot-1.16.1.jar
# "paper" assumes to look for paper-1.16.1.jar

JAVA_VERSION="11.0"
#	11.0 = java 11, can be used for Minecraft 1.13.x and up.
#	1.8 = java 8, required for Minecraft 1.12.x and up.

JAVA_MEMORY="-Xms10G -Xmx10G"
#	"" = uses the default
#	"-Xmx2G" = maximum memory allocation pool of memory for JVM.
#	"-Xms1G" = initial memory allocation pool of memory for JVM.
# For Spigot servers we recommend -Xms10G -Xmx10G for 16GB systems.
# More details here: https://stackoverflow.com/questions/14763079/

JAR_PARAMS="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true"
# 	-Dhttps.protocols=TLSv1 (temp fix for discordsrv)
#	-Dcom.mojang.eula.agree=true (Mojang EULA agreement)
#	-Dfile.encoding=UTF-8 (ensure that all UTF-8 chars are being saved properly)
#	-Dapple.awt.UIElement=true (helps on macOS to not show icon in cmd-tab)

JAR_UPGRADE=""
# 	!! Use only if you know you need this !!
#	Leave empty! (for every day running)
# 	--forceUpgrade (one time convert chunks to new engine)
# 	--eraseCache (removing caches, lightning fix)

#######################################################
#### !You're done, stop editing beyond this point! ####
#######################################################

[ "$EUID" -eq 0 ] && echo -e "\n***!!*** This script should not be run using sudo, or as the root user!\n" && exit 1
Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

function _output {
	_args="${*:1}"
	_prefix="(Debug)"
	[[ "$_debug" == true ]] && echo -e "\\n$Y$_prefix$R$C $_args $R"
}

# before we continue, let's figure out if we have spigot or paper
if [ -n "$_engine" ];
then
	# It's not empty, let's use what they have and try to find that jar.
	_enginejar="$_engine-$MINECRAFT_VERSION.jar"
	if [[ -f "$_enginejar" ]]; then
		# we found it, set it and continue the script. todo: we can simplify this logic
		MCJAR="$_enginejar"
	else
		# we did not find it, time to complain and bail out.
		_output "Oops, we did not find $_enginejar, please check your configuration."
		exit 1
	fi
else
	# it's empty - let's figure out if there's a spigot or paper jar
	_enginejar="paper-$MINECRAFT_VERSION.jar"
	if [[ -f "$_enginejar" ]]; then
		# we found paper, set it and continue the script. 
		MCJAR="$_enginejar"
	else
		# we did not find paper, but maybe there's a spigot jar
		_enginejar="spigot-$MINECRAFT_VERSION.jar"
		if [[ -f "$_enginejar" ]]; then
			# found spigot, set it and continue the script.
			MCJAR="$_enginejar"
		else
			# we did not find paper, and now also not spigot, time to bail out.
			_output "Oops, we did not find a paper or $_enginejar, please read a manual."
			exit 1
		fi
	fi
fi

NOGUI="--nogui" # leave "" if you want the 1.16.1 server-gui

if [ "$JAVA_VERSION" != "11.0" ]; then
	# 08 (if you wish to run spigot 1.12.2 or 1.13.2)
	JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
else
	# 11 (if you wish to run spigot for 1.13.2 - 1.16.1)
	JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"
fi

# Below is your java start up line for Spigot, edit accordingly.
JAVACMD="$JAVA_JDK $JAVA_MEMORY $JAR_PARAMS -jar $MCJAR $JAR_UPGRADE $NOGUI"

$JAVACMD

#EOF (c)2011-2020 Floris Fiedeldij Dop