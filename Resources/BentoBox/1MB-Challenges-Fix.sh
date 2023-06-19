#!/usr/bin/env bash

# @Filename: 1MB-Challenges-Fix
# @Version: 0.4.8, build 022 for BentoBox+Challenges, on Minecraft 1.20.x
# @Release: June 19th, 2023
# @Description: Helps me re-sync completed challenges for a player.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-Challenges-Fix, and move file to `~/plugins/BentoBox/database/ChallengesPlayerData/`
# @Syntax: ./1MB-Challenges-Fix
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

## TODO ##
## > We're using jq, check if jq is installed
## > Maybe make the script halt way sooner if we can't even find the active server. 
## > functions?
## > theme?
## > dont run as root?
## > prerequisites

## Notes ##
## > The console command synopsis is: /<gametype>admin challenges complete <uuid> <challenge-id>
## > For example: `oneblockadmin challenges complete 631e3896-da2a-4077-974b-d047859d76bc pumpkinfarm` (tested in console, works)

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# Set the Minecraft UUID of the player you're processing here. 
# The directory this script runs in must have that <uuid>.json file.
uuid="631e3896-da2a-4077-974b-d047859d76bc"

# tmux "session" name, by default this is mcserver in my 1MB-start.sh script
tmuxSession="mcserver"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

# Print out to the screen that we're starting the script now, and that we're getting the data from the <uuid>.json file.
echo "Starting script!"

# The .sh can be run with UUID as argument.
# Lets check if it's provided, if not, we will use the default.
if [[ $# -eq 1 ]]; then
    uuid="$1"
else
    uuid="$uuid"
fi

# We need to make sure the UUID .json file that we want to use actually exists, otherwise halt the script.

# Lets first figure out the working directory
script_dir=$(dirname "$(realpath "$0")")

# And then use that to check if the .json file is inside the same dir as this .sh script.
if [ -e "$script_dir/$uuid.json" ]; then
    echo "Great, I found '$uuid.json' in this same directory."
else
    # failed to find it, graceful exit of the script.
    echo "Error, '$uuid.json' does not exist, double check that you're using a Minecraft UUID (and that the $uuid.json file exists)."
    exit 1
fi

# Now that we've checked for a uuid, checked for the .json file, let's check the .log file next.

# We have the UUID, we can use that to create our unique .log file for the output (handy for potential debugging)
log_file="$uuid.log"

# Does the log file even exist? If not, create it.
# But if the file exists, halt the script, so we don't accidentally overwrite it.

# Check if the file exists
if [ -f "$log_file" ]; then
  # The file seems to exist, ask what to do next
  echo "The file '$log_file' already exists!"
  read -p "Press enter to exit, or type fresh to remove the file [fresh/enter]: " option
  # based on the input, unless it's fresh, we're exiting the script.
  if [ "$option" == "fresh" ]; then
    # Remove the file, and creating a new one
    rm "$log_file"
    sleep 1
    echo "File removed, and starting fresh..."
    touch "$log_file"
  else
    # We probably do not wish to remove it, graceful exit.
    echo "We are keeping it, and exiting the script."
    exit 1
  fi
else
  # If we cannot find the .log file, we can go ahead and create it.
  touch "$log_file"
  echo "Created a new file '$log_file'."
fi

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# Print out to the screen that we're getting the data from the <uuid>.json file.
echo "Gathering content of the '$uuid' json file..."

# Before we can do anything, we should probably get the content of the JSON file for the provided UUID
json=$(cat $uuid.json)

# And now let them know we're done with that.
echo "Gathering content: Completed."

# Next, figure out a way that works and I understand how to do, to iterate through the json file, find the unique blocks, and use jq to find what I need and put that in a string for later.

# We need a counter to increment in the loop.
counter=0

# And we need the whileloop to go through the data.
echo "Going through the file to find our completed challenges..."

while IFS= read -r data; do
  # we can get the challenge-id (with jq)
  challenge_id=$(echo "$data" | jq -r '.data."challenge-id"')

  # Check if there is something to do (are these empty?)
  if [ -n "$challenge_id" ] && [ -n "$uuid" ]; then
		# increment the $counter if we found something 
		((counter++))

    # The challenge-id looks like this "BSkyBlock_Challenge",
    # Cut out the part that discloses what island this challenge is for, (from the left to _)
    # and lowercase it, becuause I see we have both BSkyBlock and bskyblock, we want 'skyblock'
    island=$(echo "$challenge_id" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')

    # Note: AOneBlock becomes aoneblock, and then we set island to oneblock, so we end up with /oneblockadmin

    # Update the island (now that we have a lowercase version)
    case $island in
      "aoneblock")
        island="oneblockadmin"
        ;;
      "bskyblock")
        island="skyblockadmin"
        ;;
      "acidisland")
        island="acidadmin"
        ;;
      "skygrid")
        island="skygridadmin"
        ;;
      "caveblock")
        island="caveadmin"
        ;;
    esac

    # Cut out the part of the result that discloses the challenge id, so we can use it in the command. (from the right to _)
    challenge=$(echo "$challenge_id" | cut -d'_' -f2-)

    # Make some sort of $output string (the console command!)
    _output="$island challenges complete $uuid $challenge"

    # Now that we have some new results in the form of some strings, let's append it to the .log file

    echo "$_output" >> "$log_file"

  fi
done < <(echo "$json" | jq -c '.history[] | select(.type == "COMPLETE")')
#        ^--- use js to pull from the history parent block, only the instances that have a value of COMPLETE for the key called type

# Report back and exit the script, if we found nothing, and therefore have nothing to do
if [ "$counter" -eq 0 ]; then
  echo "No instances found. We can end the script now."
  exit 1
fi

# If we can continue, report back that we're done checking, and that we're on our way to the next step.
echo "Going through the file: Completed."
echo "Next, we are going (to sort) through our results and remove duplicates..."

# Use `sort` on the newly created .log file, to remove any duplicates.
sort -u -o "$log_file" "$log_file"

echo "Removing duplicates: Completed."

# Now that we have a .log file with data, we can iterate through the file, one line at a time, with a delay, sending it to the running Minecraft server

echo "Next, iterating through .log file, sending the commands to the Minecraft server..."

while IFS= read -r line; do

  # Is there actually a forked Minecraft server running under tmux with session name 'mcserver'? (otherwise halt script)
  if tmux has-session -t $tmuxSession 2>/dev/null; then
  
    # Send $line string as keys to tmux, where active session is mcserver, and "press enter". 
    tmux send-keys -t $tmuxSession "$line" Enter
    # We don't want to flood the server, and maybe we want to run this live, 1s is a potential performance issue, 2s works, 3s is safe.
    sleep 3
  else
    # Halt the script, we could not find a server to send commands to.
    echo "The '$tmuxSession' session was not found."
    exit 1
  fi
done < "$log_file"
#        ^--- use created log file to pull the commands, so we know what we are sending to tmux in a second.

# Report that we're done with sending the queue of commands.
echo "Sending commands: Completed."

# And finally, report that we're really done with the script now. 
echo "Script has finished!"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com