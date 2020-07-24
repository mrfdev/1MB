#!/bin/bash

# @Filename: 1MB-Points.sh
# @Version: 1.0, build 004
# @Release: September 15th, 2018
# @Description: Figures out UUID with most points from PyroWelcomes 2.2.0 (1.12.2)
# @Contact: I am @floris on Twitter and mrfloris in MineCraft
# @Install: chmod a+x 1MB-Points.sh
# @Syntax: ./1MB-Points.sh

# CONFIG
EXT=yml
LOG=points.log
if [ -f $LOG ];then rm -f $LOG;fi

# CODE
for i in *; do
    if [ "${i}" != "${i%.${EXT}}" ];then
        sed -n 's/WelcomePoints//p' $i | while read expression ; do 
            key=$(cut -d: -f1 <<< "$expression")
            value=$(cut -d: -f2 <<< "$expression")
            api=$(echo "$i" | cut -f 1 -d '.')
            echo "$value $api" >> $LOG
        done
    fi
done
sort  -k1,1 -r -n -t $'\t' -o $LOG $LOG

#OUTPUT

# the one player with the most points is:
# pure points
top_points=$(head -n 1 $LOG | cut -d ' ' -f2 $1)
# pure uuid
top_player=$(head -n 1 $LOG | cut -d ' ' -f3 $1)
# uuid without hyphen (used by api call)
top_player_api=${top_player//-}
# api call to figure out player name
string="$(curl -s -H "Accept: application/json" https://api.mojang.com/user/profiles/$top_player_api/names)"

set -f
array=(${string//,/ })

# the result of our cleanup
newlist=()
for i in "${!array[@]}"
do
    if [[ ${array[i]} = *"name"* ]]; then
        cleanup="${array[i]}"
        cleanup="${cleanup//\"}"
        cleanup="${cleanup//\}}"
        cleanup="${cleanup//\{}"
        cleanup="${cleanup//\[}"
        cleanup="${cleanup//\]}"
        cleanup="${cleanup//name\:}"
        top_player_name+=("$cleanup")
    fi
done

top_player_names="${top_player_name[@]}"

# output our findings
echo "Top points: $top_points, by player: $top_player_names"
echo "More information: /cmi info $top_player (API: $top_player_api)"
echo "https://api.mojang.com/user/profiles/$top_player_api/names"

#EOF