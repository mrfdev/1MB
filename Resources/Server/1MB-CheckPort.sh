#!/bin/bash

# @Filename: 1MB-CheckPort.sh
# @Version: 1.1, build 006
# @Release: September 16th, 2021
# @Description: Spits out if proc is running on port or not.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @Install: chmod a+x 1MB-CheckPort.sh
# @Syntax: ./1MB-CheckPort.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_file="server.properties"
# We will check if the current directory for example has a Paper 1.17.1 server.properties file

if [[ -f "$_file" ]]; then
	#todo result might be empty, might need to check against that.
	_port=$(grep "^server-port=" $_file | awk -F= '{print $2}')
else
	_port="25565"
	echo -e "Could not grep port from $_file, defaulting to $_port"
fi
_proc="java"


# function
_netfind() {
	if [ $# -eq 0 ]; then
		lsof -iTCP -sTCP:LISTEN -n -P || echo -e Nope, found nothing listening
	elif [ $# -eq 1 ]; then
		lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color "$1" || echo -e Nope, found nothing listening
	else
		echo -e "Usage: _netfind [proc|port]"
	fi
}

# use what we have, and output
if [[ -f "$_file" ]]; then
	echo -e "Found $_file, lets find the running proc on $_port:"
	_netfind $_port
else
	echo -e "Did not find $_file, checking for all $_proc instead:"
	_netfind $_proc
fi

#EOF Copyright (c) 2011-2021 - Floris Fiedeldij Dop - https://scripts.1moreblock.com