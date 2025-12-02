# (Mythical) Fish Statistics Analyzer 🐟✨

A lightweight Python tool that parses your Minecraft server logs and generates **detailed statistics** about *Mythical Fish* caught by players.

But I am sure you can easily customize it for other types, and maybe I will slowly start supporting those too, and generate some additional stats. 

It supports data from:

### 🎣 **PyroFishingPro**

A powerful fishing plugin for Minecraft:
➡️ [https://www.spigotmc.org/resources/60729/](https://www.spigotmc.org/resources/60729/)

It uses the Minecraft's `/logs/` folder, it doesn't use the plugins' `/PlayerData/` folder from PFP (yet), since it has no date-values we can draw conclusions from.

### 🎣 **1MB’s `/fish` system**

Modern in-game mythical fishing used on **1MoreBlock.com**.

This script works with either system’s log format and gives you a complete overview of player activity, grinding patterns, and fishing intensity across months or even years.

---

## What This Script Helps You With

✔️ Identify **top grinders** and 1%-ers
✔️ Generate a **leaderboard** of mythical catches
✔️ Discover **busy months** and natural fishing seasons
✔️ Compute **average mythicals per day, month, year**
✔️ See growth or drop-offs in fishing activity
✔️ Understand community engagement and event loops

Perfect for server owners, staff teams, and event planners.

---

## Features

* Reads both **`.log`** and **`.log.gz`**

* Detects **PyroFishingPro** (`PyroFishing ➤`) and **1MB /fish** (`/fish »`)

* Extracts:

  * Player names
  * Mythical catch timestamps
  * Monthly and yearly totals

* Calculates:

  * Total mythicals
  * First/last catch
  * Average per day / month / year
  * Per-year totals
  * Per-month totals
  * Full leaderboard (sorted)

* Zero dependencies — runs on Python 3.

* Easy to modify for custom servers and events.

---

## Example Output (Real Server Data)

```
First recorded catch: 2024-01-01
Last recorded catch : 2025-12-01
Total mythicals     : 481
Span of data        : 701 days (~23.0 months, ~1.92 years)

Average per day     : 0.69
Average per month   : 20.89
Average per year    : 250.62
```

### Per-Year Totals

```
2024: 287 mythicals
2025: 194 mythicals
```

### Per-Month Highlights

```
2024-06: 54 mythicals
2025-10: 45 mythicals
2024-05: 38 mythicals
2024-01: 35
2024-02: 35
```

### Top Anglers (Leaderboard)

```
mikefelixxg: 60
AiboPals: 59
Nebih: 41
AtariMaster: 36
JahLion: 28
FreddyTF2: 26
BeardedAdventur: 23
JaCkperByte: 17
kgrim1: 16
1MoreEgg: 15
```

---

## How to Use

### 1. Export mythical catch events

From your server's `/logs/` directory:

```bash
zgrep -ri "has just caught a Mythical" . > fish-mythicals.log
```

### 2. Place the script

```
logs/
 ├─ fish-mythicals.log
 └─ mythical_stats.py
```

### 3. Run it:

```bash
python3 mythical_stats.py < fish-mythicals.log
```

The script outputs full stats immediately.

---

## Community & Support

If you want to discuss improvements, contribute ideas, or hang out with other creators: Open an issue here on Github.

But if you want to follow me, play on my server, etc:
👉 **Join the 1MB community Discord:** [https://discord.gg/floris](https://discord.gg/floris)

---

## Contributing

Pull requests are **warmly welcomed** ❤️
Feel free to:

* Add features
* Improve output formatting
* Add CSV/JSON exporters
* Patch regexes
* Integrate with Discord bots
* Write unit tests

If your addition helps others, let’s ship it.

---

## License

Released under the **MIT License** — free to use, modify, and integrate.

You're encouraged to fork it, improve it, and submit PRs so others can benefit too.

