#!/bin/bash

# @Filename: 1MB-minecraft.sh
# @Version: 1.5, build 024 for Spigot 1.16.1 (java 11)
# @Release: July 24th, 2020
# @Description: Helps us start a Minecraft Spigot 1.16.1 server.
# @Contact:	I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-start.sh
# @Syntax: ./1MB-start.sh

# @Installation:
# Type: chmod a+x 1MB-start.sh    and    chmod a+x 1MB-minecraft.sh
# Type: nano -w 1MB-start.sh      and    nano -w 1MB-minecraft.sh
# And edit the configuration part of both files.

# @Usage:
# To start the Minecraft Spigot Server each time, 
# and NOT fork it into the background, Type:  ./1MB-minecraft.sh

# @URL: Latest source, info, & terms: https://scripts.1moreblock.com/start


### CONFIGURATION
#
# Stuff here you COULD change, but ONLY if you really really have to
# Note please that if you can fork, 1MB-minecraft.sh's values will override
#
###

# Which version are we running?
MINECRAFT_VERSION="1.16.1"

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
# 	--eraseCache (lightning fix)

SCREEN_NAME="spigotlive"
# 	spigot (makes it easier to spot in screen -ls)
#	If you want each server to have a unique identifier,
# 	then this the place to set one for each server.
# 	Examples: dev test beta live surivval creative s01 s02


#######################################################
#### !You're done, stop editing beyond this point! ####
#######################################################


MCJAR="spigot-$MINECRAFT_VERSION.jar"
NOGUI="--nogui" # leave "" if you want the 1.15.2 server-gui

if [ "$JAVA_VERSION" != "11.0" ]; then
	# 08 (if you wish to run spigot 1.12.2 or 1.13.2)
	JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home/bin/java"
else
	# 11 (if you wish to run spigot for 1.13.2, 1.14.2, or 1.15.2)
	JAVA_JDK="/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home/bin/java"
fi

# Below is your java start up line for Spigot, edit accordingly.
JAVACMD="$JAVA_JDK $JAVA_MEMORY $JAR_PARAMS -jar $MCJAR $JAR_UPGRADE $NOGUI"

[ "$EUID" -eq 0 ] && echo -e "\n***!!*** This script should not be run using sudo, or as the root user!\n" && exit 1

$JAVACMD

#EOF (c)2011-2020 Floris Fiedeldij Dop
