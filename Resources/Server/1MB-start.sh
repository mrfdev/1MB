#!/bin/bash

# @Filename: 1MB-start.sh
# @Version: 2.0, build 027 for Spigot 1.16.1 (java 11)
# @Release: August 2nd, 2020
# @Description: Helps us start and fork a Minecraft Spigot 1.16.1 server.
# @Contact:	I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-start.sh
# @Syntax: ./1MB-start.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Stuff here you COULD change, but ONLY if you really really have to
#
###

#todo take input for servername $1 to set to _serverName
_serverName="mcserver"
# this name makes it easier to spot in screen -ls
# Keep this lowercase, short, simple, no weird characters

_debug=true
# set to false if you want as little visual output as possible.

#######################################################
#### !You're done, stop editing beyond this point! ####
#######################################################

[ "$EUID" -eq 0 ] && echo -e "\n***!!*** This script should not be run using sudo, or as the root user!\n" && exit 1
Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme
_sibling="1MB-minecraft.sh"

function _output {
	_args="${*:1}"; _prefix="(Debug)"
	[[ "$_debug" == true ]] && echo -e "\\n$Y$_prefix$R$C $_args $R"
}

if [ ! -x "$_sibling" ]; then
 	_output "This '$0' script requires '$_sibling' to work and be executable. Correct the permissions, or download it from https://scripts.1moreblock.com/ "
 	exit 1
fi

_output "Attempting to start your Minecraft '$_serverName' server ... "

if type "screen" >/dev/null 2>&1; then
	_output "Found 'screen', attempting to fork session into background ..."
	screen -dmS $_serverName bash "$_sibling"
	[[ "$_debug" == true ]] && screen -ls
else
	_output "Oops, 'screen' not installed. On Ubuntu, try 'apt install screen' \\nCan't fork session, trying '$_sibling' without ..."
	sleep 4
	bash "$_sibling" || _output "Something is wrong, I could not start your server."
fi

_output "Done."

#EOF (c)2011-2020 Floris Fiedeldij Dop