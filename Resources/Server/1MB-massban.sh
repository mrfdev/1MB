#!/bin/bash

# chmod +x 1MB-massban.sh
# populate banlist.txt with usernames to ban
# note, it does not check if a user is already banned
# purpose of script: helper to get rid of botnets
# should be able to use minecraft:ban, essentialsx ban, cmi ban -s, etc
# note please that i use cmi ban, and line 28 has -s included to tell cmi to silence output, so we don't bother ingame players

# Configurable variables
TMUX_SESSION="mcserver"
CMD_BASE="cmi ban"
REASON="Stolen accounts not welcome - buy minecraft to play"
DELAY=4

# Check if banlist.txt exists
if [ ! -f banlist.txt ]; then
    printf "banlist.txt not found!\n"
    exit 1
fi

while IFS= read -r username || [[ -n "$username" ]]; do
    # Skip empty lines and comments
    [[ -z "$username" ]] && continue
    [[ "$username" =~ ^# ]] && continue

    # Build and send the command
    cmd="$CMD_BASE $username $REASON -s"
    printf "Sending: %s\n" "$cmd"
    tmux send-keys -t "$TMUX_SESSION" "$cmd" C-m
    sleep "$DELAY"
done < banlist.txt

printf "All commands sent!\n"
