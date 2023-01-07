#!/usr/bin/env bash

# @Filename: 1MB-template.sh
# @Version: 1.0.0, build 002
# @Release: January 7th, 2023
# @Description: Helps us clone /template to /server
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/floris
# @Install: chmod a+x 1MB-template.sh
# @Syntax: ./1MB-template.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

# get todays date
now=$(date +"%m_%d_%Y_%H%M%S")

# change to working dir
cd /home/minecraft

# tar/gzip the server/ dir before we archive it, and restore from template/
tar -cpzf /home/minecraft/archive/server-$now.tar.gz -C /home/minecraft server

# remove the old server
rm -rf /home/minecraft/server/

# clone the template to server/
cp -R /home/minecraft/templates/server/ /home/minecraft/server/

# change to server dir, so we can start things
cd /home/minecraft/server/

# we're done
echo "Done. You can start the server with ./1MB-start.sh, it will fork to the background."

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com
