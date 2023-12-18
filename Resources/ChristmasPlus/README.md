# Missed Days Shell Script
Get a quick overview of claimed/unclaimed days for a name or uuid

## Note
If this is of any use to some server owner then feel free to use this. You can clone/pr suggestions.
I've made this mainly for myself, and have tested it against my database.db file, on my macOS 14.2 instance.
This requires `jq` but this should work on Ubuntu 16+ as well. 

## Release
<https://github.com/mrfdev/1MB/tree/master/Resources/ChristmasPlus>
```bash
# @Version: 0.3.1, build 022
# @Release: December 18th, 2023
```
- You can download it from here: [1MB-ChristmasPlus.sh](/Resources/ChristmasPlus/1MB-ChristmasPlus.sh)

## Output examples
With username as param
```
% ./1MB-ChristmasPlus.sh KoolKidSimp

KoolKidSimp:
Gifts claimed (true): '1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12' '13' '14' '15' '16' '17'
Gifts unclaimed (false): '18' '19' '20' '21' '22' '23' '24'
```

With uuid as param
```
% ./1MB-ChristmasPlus.sh 812c10b0-7bbf-49e5-ac53-3f0521eb504b

812c10b0-7bbf-49e5-ac53-3f0521eb504b:
Gifts claimed (true): '1' '2' '4' '10' '15' '16'
Gifts unclaimed (false): '3' '5' '6' '7' '8' '9' '11' '12' '13' '14' '17' '18' '19' '20' '21' '22' '23' '24'
```

With no param, but using a set value within the .sh file (a default username)
```
% ./1MB-ChristmasPlus.sh

FumbleHead:
Gifts claimed (true): '1' '2'
Gifts unclaimed (false): '3' '4' '5' '6' '7' '8' '9' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21' '22' '23' '24'
```

## Configuration options
You can edit the .sh file to point it to a different database file, set a different default uuid or user name, and you toggle logging to a file on/off, and you can define the filename.
```
# SQLite3 ChristmasPlus 2.32.2 database.db file is expected,
# if you have renamed it, change that here obviously.
# you can also set a full path like /full/path/to/database.db
_databaseFile="./database.db"

# If no param is provided, we fall back to a default username
# can be uuid
_user="FumbleHead"

# output to a log file?
_log=true
_logFile="christmasplus-results.log"
```

## Why?
- Well, on my server I give a voucher for when they've missed a day. So this allows them to give m the voucher, mention the day they say they've missed. I can quickly check and take their voucher, and give them the reward. 
- Another reason is, that those who have collected all 24 days, can get a bonus advent box on day 25. This allows me to check if they have.
- It's easier to read, and you don't need to clone the .db file, or download it, and open it in a sqlite3 viewer and stare at this for a bit to figure out what you're staring at:
```json
{"1":true,"2":true,"3":false,"4":true,"5":false,"6":false,"7":false,"8":false,"9":false,"10":true,"11":false,"12":false,"13":false,"14":false,"15":true,"16":true,"17":false,"18":false,"19":false,"20":false,"21":false,"22":false,"23":false,"24":false}
```

### What's missing?
- The ability to update a day if they give me a voucher and I give them the reward manually. This is a passive script, no database values are being changed.
- I didn't include the tmux send-keys part, because my setup is probably 90% different than other servers, so I don't inlclude the parameter for the kit to pay out, or the tmux forked session to send it to. This way the script works for you still. and doesn't error because it didn't find 'my' server.
- I couldn't figure out how to use jq or read -a to list all the keys smaller than today, to split the unclaimed list in 'missed days' before 'today', and 'unclaimed' days after today. Feel free to clone/pr a solution that works on macOS/Ubuntu