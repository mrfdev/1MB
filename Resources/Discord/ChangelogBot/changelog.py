# changelog.py
# 1MoreBlock.com Discord Bot Script to fetch messages from an internal changelog channel to save results to a JSON database file.
# We are not using discord.py but Disnake to poke the Discord API.
# Build 008, https://github.com/mrfdev/1MB/tree/master/Resources/Discord/ChangelogBot

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

# Init messages intent
# According to Google example bots, this is what I need.
intents = disnake.Intents.default()
intents.message_content = True  # This enables the message content intent access, whatever thing that's now required to have enabled.

# Build a bot instance, I like !
bot = commands.Bot(command_prefix="!", intents=intents)

# Async bot event
@bot.event
async def on_ready():
    # Let us know we did it
    print(f"Okay, {bot.user} reporting in..")

    # Init stuff, I assume I need channel id, messages from the channel, and start a loop with last id number since we're batching it up
    channel = bot.get_channel(CHANNEL_ID)  # Get the specified channel by ID
    messages = []  # Init array for the fetched msgs
    last_message = None  # Start with no last message

    # While loop to start array and batch-fetch some msgs, parse them in for loop and store in json file, sleep between batches
    while True:
        try:
            # Init batch fetching
            if last_message:
                batch = await channel.history(after=last_message, limit=100).flatten()  # Fetch messages after the last message
            else:
                batch = await channel.history(limit=100).flatten()  # Fetch the initial batch of messages

            if not batch:
                break  # Halt if we find no more msgs to batch

            # Figure out msg elements 
            for message in batch:
                messages.append({
                    "content": message.content,  # Content of msg fetched
                    "author": message.author.name,  # Author of content
                    "timestamp": message.created_at.isoformat()  # Timestamp of fetched content
                })

            # Open file and write to json
            with open(OUTPUT_JSON_FILENAME, "w") as file:
                json.dump(messages, file, indent=2)

            # Update last_message to be the last message object fetched
            last_message = batch[-1]  # Keep the last message object

            # Sleep some seconds between batches
            await asyncio.sleep(5)

        # Something must be wrong, probably exception error, catch it, deal with it
        except disnake.errors.HTTPException as e:
            print("Rate limit hit, pausing and trying again...")
            await asyncio.sleep(e.retry_after / 1000.0 if hasattr(e, 'retry_after') else 10)

    # We're done, spit out that we got nothing to do
    print(f"All messages fetched from discord and saved to {OUTPUT_JSON_FILENAME}.")
    await bot.close()  # Close the bot when done

# Always at the end, start the bot now that we have all the code
bot.run(TOKEN)  # Provided token
