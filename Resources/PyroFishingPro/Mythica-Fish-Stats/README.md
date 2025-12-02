## (mythical) fish stats script
Handy little script to get some stats on your players' who caught mythical fish, so you can get an idea of the 1%-ers grinders, top 10 - busy months, monthly averages, etc. 
```
cd /path/to/minecraftserver/logs/

zgrep -ri "has just caught a Mythical" . > fish-mythicals.log

put the .py script in the same dir as the fish-mythicals.log

python3 mythical_stats.py < fish-mythicals.log
```
Can easily be tweaked, improved, customized to your preferences. 

Thought some ppl might appreciate this, enjoy.