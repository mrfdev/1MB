#!/usr/bin/env bash

# @Filename: 1MB-MCF.sh
# @Version: 1.1.1, build 009
# @Release: June 7th, 2023
# @Description: Little shell script to process all the 1.20 .jars at once using MaliciousCodeFinder 1.1 and it puts the output in a MCF.log file.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: see below
# @Syntax: ./1MB-MCF.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

##### Installation and stuff
#
# chmod a+x 1MB-MCF.sh first, set things up, run it, read .log
# Get MCF.jar from the above link, and 1MB-MCF.sh from github, 
# and put them in a new empty directory.
# Either create a plugins/ directory with all your .jar files
# or configure the /full/path/to/them/*.jar so it can find it
#
###

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# Where are those Spigot jar files?
jarfiles="./plugins/*.jar"

# MCF.jar startup parameters
params="-ecompact"
# "" for default (gives the most details), 
# "-compact" for compact (shows only the most important stuff) (recommended)
# "-ecompact" for extended-compact (shows only important stuff, with details)

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

# Theme
B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m"

# Just a simple date/time stamp
stamp=$(date "+%Y.%m.%d-%H.%M.%S")

### END OF CONFIGURATION
#
# Really stop configuring things
# beyond this point. I mean it.
#
###

# Output function
function msg {
	echo -e "\\n$X $1 $R" >&2
}

# And write that to the file (overwrite if exist)
echo -e "\\n MCF.log created with: java -jar MCF.jar $params -i \"jars\"" > MCF.log
echo -e "\\n $jarfiles files checked on: $stamp" >> MCF.log
msg "Starting"

# Loop through all the jar files..
for filename in $jarfiles
do
	# Visual output that we're doing something.
	msg "Checking: $filename..."

	# Append to .log file which .jar file we're checking.
	echo -e "\\nChecking: $filename\\n" >> MCF.log

	# Check the .jar file, and append results to the .log file
	java -jar MCF.jar $params -i "$filename" >> MCF.log

	# And take note that we're done with that file.
	echo -e "\\nDone checking... \\n\\n">> MCF.log
done

# And tell the user running this script we are done with everything.
msg "Finished checking all the $jarfiles files. $B Results are in MCF.log."

#EOF Copyright (c) 2011-2023 - Floris Fiedeldij Dop - https://scripts.1moreblock.com