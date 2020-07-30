#!/bin/bash

# Description: spits out if proc is running on port or not.

# config
_file="server.properties"

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
