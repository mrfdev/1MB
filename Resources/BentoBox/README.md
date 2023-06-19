# Complete Challenges for UUID

> A little 'fix' shell script to help me parse some data from the `<uuid>.json` file of a player, after we've wiped the database in-game and re-imported the default library. We recently had some issues and had to hot-fix something, and since I don't know Java this was my quickest solution.

## BentoBox Add-on: Challenges Completer

- This is made for BentoBox 1.24.0, for Minecraft 1.20.1.
- Using any gametype addon, with the add-on: Challenges, version 1.2.0.
- I've made this for a personal edge-case situation, don't use this if you don't know what you're doing of course.

## Installation

- Get the `1MB-BentoBox-Complete-Challenges-Fix.sh` file, and put it in the directory `/plugins/BentoBox/database/ChallengesPlayerData`.
- `chmod a+x 1MB-BentoBox-Complete-Challenges-Fix.sh`
- Make sure your server is running in tmux, with a session name, the default is `mcserver`
- Edit the .sh script with the player's Minecraft UUID.
- And run the .sh script with `./1MB-BentoBox-Complete-Challenges-Fix.sh`

## What does it do?

Upon running it, it will go through the player file and find instances of completed challenges, then store those in a .log file, removing any duplicates. When that's done. It will go through the file line by line, with a 3 second delay. Feeding the lines as a bentobox console command to the `mcserver` tmux session, completing the challenges if they don't already have them.
Bug Report / Suggestions

- Feel free to open a ticket, if I can fix it, I will try to, if I can update the script I will try to. And then publish any releases.
- You're free to clone, make changes, and offer it back with a pull request on Github here, so I can review it and potentially merge it in.

## Author

- Floris, discord.gg/floris

## Version

Version 0.1.0, (prototyping/concept), build 006.
