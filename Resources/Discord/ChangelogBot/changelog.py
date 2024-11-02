# changelog.py
# 1MoreBlock.com Discord Bot Script to fetch messages from a internal changelog channel to save results to a JSON database file.
# We are not using discord.py but Disnake to poke the Discord API.
# Build 001, https://github.com/mrfdev/1MB/tree/master/Resources/Discord/ChangelogBot

# Imports

import disnake
from disnake.ext import commands  # cmd ext to create bot commands
import json  # we want to write to json later
import asyncio  # handy later for rate limiting and managing asynchronous tasks

# Tokens

#discordtoken
#channelid

# init msgs intent

# build a bot instance

#codetobuildbotinstance

# async botevent

@bot.event
async def on_ready():
	# let us know we did it
	# init stuff

	# loop here, probably a while loop
	# while true, try this .. 
	# dont forgeto to try and batch fetch msgs
	# then break if we got nothing to fetch

	# for loop, to go through each msg (from batch)
	# get the batched msg, append to json array

	# save results to json file, python uses write or open() as file, ill have to google again

	# async sleep() for a while, seconds or tens of seconds?

# we're done, spit out that we got nothing to do
print("All messages fetched and saved.")

# since we're done, we can continue to markdown.py when ready, so let's close the bot
await bot.close()  # poof

# Always at the end, start the bot now that we have all the code
bot.run(TOKEN)  # provided token
