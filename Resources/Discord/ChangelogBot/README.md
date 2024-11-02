# discord.gg/floris ChangelogBot

## Info

Yeah, well, so, .. the situation is that I have my internal changelogs on Discord, and I rather have them in a changelog.md file so I can re-post them structured in our public #changelog channel, as well as our omgboards.com forum. I know literally nothing about Discord bots, so let's try to learn something. Don't use this, as it's probably going to not work .. sigh, yeh. Let's goooo and stuff.

## Concept

Write a changelog.py script that I can run, which I set-up, invite to my server, give access to the internal changelog channel and that grabs the data and puts it in a changelog.json file, and have another script convert that json to markdown, I guess.

## Thinking here..

I probably have to `pip install discord.py` and add a bot to the discord dev portal thing (as a new application) oh and I remember that since a while ago we now have to tick the checkbox for msg content intent or intentions, or something. Sort out the bot token, generate oauth thing, build the grabber and store as json.

The python script will have to import the correct stuff, im sure there's a google page for that. Set the token and channel id, sort out that message content stuff, then async fetch some msgs from the channel (async right?) and save the results to the json file.

and the py script has to end with client.run(TOKEN) or nothing will even happen, i know that much.

To run it, then python changelog.py

### Node alternative?

I almost forgot, i remember `npm install discord.js` is needed, does that even work on mac? But I am more familiar with javascript than with python, so if i get stuck i can probably try this as plan b. 

Set some constants, initiate client, and the same concept. But it's javascript, it will be more code with more errors.. but i have experience using js, so should be okay to debug at least.

## Converting to Markdown

Why not go to json directly? Well, let me tell you !! Let's gather stuff into a database, then convert content we want to markdown. This way I can be even more selective. 

And if it's a database, I can also load it in a spreadsheet, parse the data to filter out certain things .. etc.

The markdown.py script needs import json btw, dont forget.. 

open the json file, read content, parse it.. export.

## Worries

Discord rate limits, eh i might want to batch request and add a sleep() or something. Another thing to look into, and just like with website design, can i gracefully pause when error msgs happen? 429 web service response, sleep .. repeat ??? i need to learn this too. 

- Reminder: probably dont put oauth or at least don't put the bot token on github. 

## Handy stuff
```
brew install python
```
on macOS python's installed, `python3 --version` will show 3.12.x or whatever, otherwise brew it!
Also, on macOS when you brew it, it might be pip3, not pip. I always forget.. `python3.12 -m pip install --upgrade pip` might also be needed. 

Try macOS stuff..
```
# create virtual environment to run as user on macOS
python3 -m venv changelog-env
# start it
source changelog-env/bin/activate
# do the magic
pip install disnake
# probably a little update pending usually
python3.12 -m pip install --upgrade pip
# macos has missing audio crap
pip install audioop-lts
# set the token if you havent yet
# run the script
python changelog.py
# and we're done
deactivate

```
## TODO

- fix not so graceful closing of changelog.py (but it works!)

## More info

Version 0.1.2, build 009, November 2nd, 2024
Author: Floris Fiedeldij Dop
Contributions: Learning, so probably friends and gpt, lol
