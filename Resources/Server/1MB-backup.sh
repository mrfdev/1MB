#!/usr/bin/env bash

# @Filename: 1MB-backup.sh
# @Version: 0.0.1, build 002 for Minecraft 1.21.1 (Java 22.0.2, 64bit)
# @Release: August 26th, 2024
# @Description: Helps us make a compressed tarball of a Minecraft 1.21.1 server. 
# @Description: Note: Does not use rsync, this is meant for small servers only.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod a+x 1MB-backup.sh
# @Syntax: ./1MB-backup.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

dir="MinecraftServer"
backup_dir="_backups"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

backup_file="${backup_dir}/${dir}-$(date +%d-%m-%Y).tar.gz"

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# Check if the desired directories exist, if not, exit script and report back.

# Note, this is the directory from within the server(s) run, it SHOULD exist, we will not create it if it doesn't: properly configure the path if it fails
if [ ! -d "$dir" ]; then
    echo "Error: Directory $dir does not exist."
    exit 1
fi

# However, if the backup dir does not exist, we can create it. Sometimes we purge the whole dir after moving it off-site.
if [ ! -d "$backup_dir" ]; then
    echo "Warning: $backup_dir directory does not seem to exist. Creating it now..."
    mkdir -p "$backup_dir"
fi


#EOF Copyright (c) 2011-2024 - Floris Fiedeldij Dop - https://scripts.1moreblock.com