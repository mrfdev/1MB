#!/usr/bin/env bash

# @Filename: 1MB-BentoBox-Complete-Challenges-Fix.sh
# @Version: 0.3.0, build 011 for BentoBox+Challenges, on Minecraft 1.20.x
# @Release: June 19th, 2023
# @Description: Helps me re-sync completed challenges for a player.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-BentoBox-Complete-Challenges-Fix.sh, and move file to `~/plugins/BentoBox/database/ChallengesPlayerData/`
# @Syntax: ./1MB-BentoBox-Complete-Challenges-Fix.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

## TODO ##
## > take script param for uuid, so we don't have to edit the script (.sh <uuid>)
## > check if the .log file exists, halt and request to start fresh or append.
## > check if the <uuid>.json file is in the same dir as the .sh script.
## > We're using jq, check if jq is installed
## > functions?
## > theme?
## > dont run as root?
## > prerequisites
## > code to process json file
## > output

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
# Known issue: If we have nothing to do, we end up with a touched file, no content. 
if [ ! -f "$log_file" ]; then
  touch "$log_file"
fi


### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

## logic? ##
## > +DONE Get content of the .json file,
## > -50% Go through each line, finding the unique 'completed challenges'
## > -50% And every time we find one, get the challenge-id, so we can complete it later.
## > +DONE There's also a user-id, but the filename discloses that of course.
## > +DONE Now we know how to make a command, put the result of this into the .log file.
## > +DONE Unique the .log file content, I guess, so we don't run the same command over and over.
## > Now take each line of the .log file and send it over to the tmux session (with a few seconds delay)
## > +DONE And echo to the screen each time we've made progress in the script, so it doesn't look like it's not busy.
## > Note, we can do this without writing to a log file, but I have my reasons why I want a log of which commands we've run for what user. 
## > Note, we might need to clean up the island names, so they're always the same/unique.

echo "Starting script!"
echo "Gathering content of the '$uuid' json file..."

# Before we can do anything, we should probably get the content of the JSON file for the provided UUID
json=$(cat $uuid.json)

echo "Gathering content: Completed."

# Next, figure out a way that works and I understand how to do, to iterate through the json file, find the unique blocks, and use jq to find what I need and put that in a string for later.

# We need a counter to increment in the loop.
counter=0

# And we need the whileloop to go through the data.

echo "Going through the file to find our completed challenges..."

while IFS= read -r data; do
  # we can get the user-id, and the challenge-id (with jq)
  challenge_id=$(echo "$data" | jq -r '.data."challenge-id"')
  user_id=$uuid

  # Check if there is something to do (are these empty?)
  if [ -n "$challenge_id" ] && [ -n "$user_id" ]; then
		# increment the $counter if we found something 
		((counter++))
    # clean up island type first..
    # The challenge-id looks like this "BSkyBlock_Challenge",
    #    we need bskyblock to be lowercase, then clean it up to just skyblock, 
    #    and then we pull the challenge in a bit out of the result too.

    # Cut out the part that discloses what island this challenge is for, (from the left to _)
    # and lowercase it, becuause I see we have both BSkyBlock and bskyblock, we want 'skyblock'
    island=$(echo "$challenge_id" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')

    ## if elseif or case switch here for each of the 5 types that i use.

    # Cut out the part of the result that discloses the challenge id, so we can use it in the command. (from the right to _)
    challenge=$(echo "$challenge_id" | cut -d'_' -f2-)

    # Make some sort of $output string (the console command!)
    _output="ISLAND<admin> challenges complete $user_id CLEAN_challenge-id"

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
  # if
  #   # do magic here, such as send to tmux, if it is running, else report back we cannot find it, and exit the script
  # fi
  # Send $line string as keys to tmux, where active session is mcserver, and "press enter". 
  tmux send-keys -t mcserver "$line" Enter

  # We don't want to flood the server, and maybe we want to run this live, 1s is a potential performance issue, 2s works, 3s is safe.
  sleep 3
done < "$log_file"
#        ^--- use created log file to pull the commands, so we know what we are sending to tmux in a second.
# Report that we're done with sending the queue of commands.

echo "Sending commands: Completed."

# Report that we're really done with the script now. 

echo "Script has finished!"

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com