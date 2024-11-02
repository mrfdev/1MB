# markdown.py
# 1MoreBlock.com Discord Script to convert messages stored with changelog.py (json format) to markdown so we can use it on discord and xenforo forums.
# We are not using discord.py but Disnake to poke the Discord API.
# Build 001, https://github.com/mrfdev/1MB/tree/master/Resources/Discord/ChangelogBot

# Imports

import json  # Import json mod to read the file

# Constants

OUTPUT_MD_FILENAME = "changelog-msgs.md"
OUTPUT_JSON_FILENAME = "changelog-msgs.json"

# Okay, we're ready to read the json data we've stored

with open(OUTPUT_JSON_FILENAME, "r") as file: # open it!
    messages = json.load(file)  # read it!

# We have the data, time to convert.

with open(OUTPUT_MD_FILENAME, "w") as md_file:
	# no idea about format yet
	# md_file.write("content\n")
	# this will be {message['key']}
	# key will be author, content, timestamp

	# for msg in msgs loop probably, so we can go and append to changelog-msgs.md
	md_file.write(f"just testing")

# And we're done. We're not a bot, no need for tokens and i dunno what here. 
# Just print out we're donesies
print("Converted {OUTPUT_JSON_FILENAME} file to {OUTPUT_MD_FILENAME}") #bye