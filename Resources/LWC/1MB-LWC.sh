#!/usr/bin/env bash

# @Filename: 1MB-LWC.sh
# @Version: 1.2.1, build 009
# @Release: June 7th, 2023
# @Description: Shell script for Modern LWC 2.2.8 for Minecraft 1.20, help convert SQLite player names to UUID using MSA API
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-LWC.sh
# @Syntax: ./1MB-LWC.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# which file you want to use to store the playernames in that we found/changed
LOG="result.log"

# The .sqlite3 db filename that we are going to write to
LWC="lwc-updated.db"

# delay in seconds between query to mojang (and db update) to avoid rate limit
DELAY=10

# default trim UUID for when an invalid uuid gets returned by mojang when we query it with a name
UUID="00000000000000000000000000000000"

# lets use the new MSA API
_apiUrl="https://api.minecraftservices.com/minecraft/profile/lookup/name/"

# lets not write to the actual db
# DEBUGGGGGG (comment this out unless you want to do the same thing over and over again)
if [ -f $LWC ];then rm -f $LWC;fi
cp lwc.db $LWC

# END CONFIG (this is where you stop editing this file)

echo " ---- 1MB-lwc.sh script starting.. "

# LOG file; let's start fresh
if [ -f $LOG ];then rm -f $LOG;fi

# use sqlite3 to query the lwc sqlite database, 
# from which we select all the owner entries, (unique only, we don't need duplicates)
# from specifally the table lwc_protections, 
# but only if the owner entry is equal of less than 16 characters (so we do not get uuid entries)
# and output our results to a .log file we can use afterwards.
sqlite3 $LWC "SELECT DISTINCT owner FROM lwc_protections WHERE LENGTH(owner)<=16;" | while read owner
do
	mojang="$(curl -s -H "Accept: application/json" ${_apiUrl}${owner})"
	set -f

	# ARRAY; starting fresh, then populating it
	mojangarray=()
	mojangarray=(${mojang//,/ })

	# ARRAY; cleaning up	
	if [[ ${mojangarray[*]} = *"id"* ]]; then
		cleanup="${mojangarray[*]}"
		cleanup="${cleanup//\"}"
		cleanup="${cleanup//\}}"
		cleanup="${cleanup//\{}"
		cleanup="${cleanup// name :*}"
		cleanup="${cleanup// id \: }"
		lwc_name=("$cleanup")
		uuid_match="matched"
	else
   		# We run into an issue, let's set it to our default trim uuid
		lwc_name=("$UUID")
		uuid_match="nomatch"
	fi

	# result of cleaning up json data from curl query
	lwc_uuid="${lwc_name[@]}"
	lwc_uuid=${lwc_uuid:0:8}-${lwc_uuid:8:4}-${lwc_uuid:12:4}-${lwc_uuid:16:4}-${lwc_uuid:20:12}

	# DATABASE; Update LWC's table from outdated playername to current full UUID
	sqlite3 $LWC "UPDATE lwc_protections SET owner = REPLACE(owner,'$owner','$lwc_uuid');"

	echo "Found UUID ($uuid_match): $lwc_uuid for player: $owner" >> $LOG
	echo "Found UUID ($uuid_match): $lwc_uuid for player: $owner"

	# lets show visually that we are waiting
	echo ".. Waiting ${DELAY}s before querying Mojang for next UUID .."
	sleep $DELAY
done

echo " ---- 1MB-lwc.sh script ended. ($LWC updated, log file: $LOG)"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com