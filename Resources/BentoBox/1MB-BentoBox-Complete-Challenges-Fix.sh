#!/usr/bin/env bash

# @Filename: 1MB-BentoBox-Complete-Challenges-Fix.sh
# @Version: 0.4.4, build 018 for BentoBox+Challenges, on Minecraft 1.20.x
# @Release: June 19th, 2023
# @Description: Helps me re-sync completed challenges for a player.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-BentoBox-Complete-Challenges-Fix.sh, and move file to `~/plugins/BentoBox/database/ChallengesPlayerData/`
# @Syntax: ./1MB-BentoBox-Complete-Challenges-Fix.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

## TODO ##
## > take script param for uuid, so we don't have to edit the script (.sh <uuid>)
## > check if the <uuid>.json file is in the same dir as the .sh script.
## > We're using jq, check if jq is installed
## > Make 'mcserver' a config option in case we use a mctest server
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

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

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

# Print out to the screen that we're starting the script now, and that we're getting the data from the <uuid>.json file.
echo "Starting script!"
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
    # clean up island type first..
    # The challenge-id looks like this "BSkyBlock_Challenge",
    #    we need bskyblock to be lowercase, then clean it up to just skyblock, 
    #    and then we pull the challenge in a bit out of the result too.

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
  if tmux has-session -t mcserver 2>/dev/null; then
  
    # Send $line string as keys to tmux, where active session is mcserver, and "press enter". 
    tmux send-keys -t mcserver "$line" Enter
    # We don't want to flood the server, and maybe we want to run this live, 1s is a potential performance issue, 2s works, 3s is safe.
    sleep 3
  else
    # Halt the script, we could not find a server to send commands to.
    echo "The 'mcserver' session was not found."
    exit 1
  fi
done < "$log_file"
#        ^--- use created log file to pull the commands, so we know what we are sending to tmux in a second.

# Report that we're done with sending the queue of commands.
echo "Sending commands: Completed."

# And finally, report that we're really done with the script now. 
echo "Script has finished!"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com