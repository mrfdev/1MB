# changelog.py
# 1MoreBlock.com Discord Bot Script to fetch messages from a internal changelog channel to save results to a JSON database file.
# We are not using discord.py but Disnake to poke the Discord API.
# Build 004, https://github.com/mrfdev/1MB/tree/master/Resources/Discord/ChangelogBot

# Imports

import disnake
from disnake.ext import commands  # cmd ext to create bot commands
import json  # we want to write to json later
import asyncio  # handy later for rate limiting and managing asynchronous tasks

# Constants

OUTPUT_JSON_FILENAME = "changelog-msgs.json"

# Discord related Tokens

TOKEN = 'BOTTOKEN'  # lets not put our secrets here, shh
CHANNEL_ID = 1059074047280939078  # our actual internal changelog channel id, no real secrets there

# init msgs intent
# According to google example bots, this is what I need. 
intents = disnake.Intents.default()
intents.message_content = True  # This Enables the msg content intent access, whatever thing that's now required to have enabled.

# build a bot instance, i like !
bot = commands.Bot(command_prefix="!", intents=intents)

# async botevent

@bot.event
async def on_ready():
	# let us know we did it
	# {bot.user}
	print(f"Okay, {bot.user} reporting in..")

	# init stuff, i assume i need channel id, messages from the channel, and start a loop with last id number since we're batching it up
	channel = something[CHANNEL_ID] # <- figure out synopsis
	messages = [] # <- init array for the fetched msgs
	last_message_id = None # <- Let's start empty, append later after each batch

	# loop here, probably a while loop
	# while true, try this .. except that..
	# dont forgeto to try and batch fetch msgs
	# then break if we got nothing to fetch

	# for loop, to go through each msg (from batch)
	# get the batched msg, append to json array

	# save results to json file, python uses write or open() as file, ill have to google again

	# async sleep() for a while, seconds or tens of seconds?
	await asyncio.sleep(5)

	### temp
    while True:
        try:
					# bunch of stuff
			batch = await (dunno this part yet)
            if not batch:
                break # halt if we find no more msgs to batch

			for message in batch:
				messages.append({
					# key 1
					# key 2
					# key 3
				})

					# open file and append to json
						# json.dump(whatever) # do i need to think about indentation?

					# update last.msg.id=[from batch result]

					# sleep async 5s

		except disnake.errors.HTTPException as e:
			print(f"rate limit hit, pausing and trying again")
					# await asyncio.sleep(try.again.after x seconds)

				# and that's it

# we're done, spit out that we got nothing to do
print("All messages fetched from discord and saved to {OUTPUT_JSON_FILENAME}.")

# since we're done, we can continue to markdown.py when ready, so let's close the bot
await bot.close()  # poof

# Always at the end, start the bot now that we have all the code
bot.run(TOKEN)  # provided token
