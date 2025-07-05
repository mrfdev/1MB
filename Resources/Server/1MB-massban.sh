#!/bin/bash

# chmod +x 1MB-massban.sh
# populate banlist.txt with usernames to ban
# note, it does not check if a user is already banned
# purpose of script: helper to get rid of botnets
# should be able to use minecraft:ban, essentialsx ban, cmi ban -s, etc

# Configurable variables
TMUX_SESSION="mcserver"
CMD_BASE="cmi ban"
REASON="Stolen accounts not welcome - buy minecraft to play"
DELAY=4
SILENT="-s"    # Set to "-s" if you use cmi to silence output, or "" for non-silent
VERBOSE=1      # Set to 1 for verbose output, 0 for quiet

# Check if tmux session exists
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    printf "Error: tmux session '%s' not found!\n" "$TMUX_SESSION"
    exit 2
fi

# Check for input file
if [ ! -f banlist.txt ]; then
    printf "Error: banlist.txt not found!\n"
    exit 1
fi

count=0
[ "$VERBOSE" -eq 1 ] && printf "Starting ban process...\nUsing tmux session: %s\nReason: %s\nDelay: %ds\nSilent: %s\n\n" "$TMUX_SESSION" "$REASON" "$DELAY" "$SILENT"

while IFS= read -r username || [[ -n "$username" ]]; do
    # Skip empty lines and comments
    [[ -z "$username" ]] && continue
    [[ "$username" =~ ^# ]] && continue

    cmd="$CMD_BASE $username $REASON $SILENT"
    [ "$VERBOSE" -eq 1 ] && printf "Sending: %s\n" "$cmd"
    tmux send-keys -t "$TMUX_SESSION" "$cmd" C-m
    sleep "$DELAY"
    ((count++))
done < banlist.txt

[ "$VERBOSE" -eq 1 ] && printf "\nAll commands sent! Total usernames processed: %d\n" "$count"
