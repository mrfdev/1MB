#!/bin/bash

##### https://scripts.1moreblock.com/mcf
# version 1.1 build 004, by mrfloris
# release: July 25th, 2020
#
# Little shell script to process all the .jars at once
# and it puts the output in a MCF.log file.
#
# Want to double check on just one file?
# Then use the MCF.jar without this script.
# 

##### Made for: MCF.jar, by HoverCatz
# Tested with MaliciousCodeFinder 1.1:
# https://www.spigotmc.org/resources/MCF.56001/
#

##### Installation:
# Get MCF.jar from the above link, and 1MB-MCF.sh from github, 
# and put them in a new empty directory.
# Either create a plugins/ directory with all your .jar files
# or configure the /full/path/to/them/*.jar so it can find it
#

##### Usage:
# chmod a+x 1MB-MCF.sh
# ./1MB-MCF.sh
# When it's done you have a MCF.log file with the results.
#

##### Configuration:
# In case you need to configure something:
#

# Where are those Spigot jar files?
jarfiles="./plugins/*.jar"

# MCF.jar startup parameters
params="-ecompact"
# "" for default (gives the most details), 
# "-compact" for compact (shows only the most important stuff) (recommended)
# "-ecompact" for extended-compact (shows only important stuff, with details)

##### Script:
# No editing needed beyond this point really
#

# Theme
B="\\033[1m"; Y="\\033[33m"; C="\\033[36m"; X="\\033[91m"; R="\\033[0m"

# Just a simple date/time stamp
stamp=$(date "+%Y.%m.%d-%H.%M.%S")

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

#EOF
