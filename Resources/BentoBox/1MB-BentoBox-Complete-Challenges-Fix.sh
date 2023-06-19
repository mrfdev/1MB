#!/usr/bin/env bash

# @Filename: 1MB-BentoBox-Complete-Challenges-Fix.sh
# @Version: 0.1.1, build 008 for BentoBox+Challenges, on Minecraft 1.20.x
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

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

## logic? ##
## > +DONE Get content of the .json file,
## > Go through each line, finding the unique 'completed challenges'
## > And every time we find one, get the challenge-id, so we can complete it later.
## > There's also a user-id, but the filename discloses that of course.
## > Now we know how to make a command, put the result of this into the .log file.
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
  if
    # do magic here
		# increment the $counter if we found something 
		((counter++))
  fi
  # now we can use that magic as a result
done

# Report back and exit the script, if we found nothing, and therefore have nothing to do

## if conditional here, something like if $counter equals 0, echo & exit

# If we can continue, report back that we're done checking, and that we're on our way to the next step.

echo "Going through the file: Completed."

echo "Next, we are going (to sort) through our results and remove duplicates..."

# Use `sort` on the newly created .log file, to remove any duplicates.
sort -u -o "$log_file" "$log_file"

echo "Removing duplicates: Completed."

# Now that we have a .log file with data, we can iterate through the file, one line at a time, with a delay, sending it to the running Minecraft server

echo "Next, iterating through .log file, sending the commands to the Minecraft server..."

while IFS= read -r line; do
  if
    # do magic here, such as send to tmux, if it is running, else report back we cannot find it, and exit the script
  fi
  # now we can use that magic as a result?? <- prob not
done

# Report that we're done with sending the queue of commands.

echo "Sending commands: Completed."

# Report that we're really done with the script now. 

echo "Script has finished!"

# functions?
# theme?
# dont run as root?
# prerequisites
# code to process json file
# output

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com