# 1MB-Doors.sh  
**Version:** 2.0.1 (Build 012)  
**Release:** November 2, 2025  
**Author:** [Floris Fiedeldij Dop](https://scripts.1moreblock.com)  
**Assisted by:** ChatGPT (OpenAI)  

---

## 📘 Overview
`1MB-Doors.sh` is a Bash utility for querying Trick-or-Treat (or similar event) databases used on the **1MoreBlock.com** Minecraft server.  
It lets you quickly check which players have found all interactable doors, which are missing some, and exactly *which* doors they still need — all per world.

The script was built to work with the `totdatabase.db` SQLite database from the Halloween event but supports any event world through the `--world` parameter.

---

## ⚙️ Features
- Works on **macOS** and **Ubuntu/Linux**  
- **Colorized output** for easy reading in iTerm2, Terminal, or SSH  
- **Per-player reports**: show which doors a player is missing  
- **List reports**: show all players who found *N* doors (0 → Total)  
- **World scoping** via `--world <name>` (default = `halloween`)  
- Automatic totals and count summaries  
- Safe, read-only SQL queries using the `sqlite3` CLI  

---

### Screenshot

<img width="779" height="981" alt="1MB-Doors screenshot" src="https://github.com/user-attachments/assets/4226d660-167a-405f-b38e-ea291394da4d" />

---

## 🧩 Requirements
- Bash 5 or later  
- `sqlite3` installed and accessible in `$PATH`

Check:
```bash
sqlite3 --version
```

If missing:
```bash
# macOS (Homebrew)
brew install sqlite
# Ubuntu / Debian
sudo apt install sqlite3
```

---

## 🪄 Installation
1. Download or clone this repository.
2. Make the script executable:
   ```bash
   chmod +x 1MB-Doors.sh
   ```
3. (Optional) Place it in your plugin or scripts folder, for example:
   ```bash
   mv 1MB-Doors.sh ~/plugins/TrickOrTreatV2/
   ```

---

## 🎮 Usage

### 🔹 Per-Player Report
Show which doors a specific player has not yet found (default world = `halloween`):

```bash
./1MB-Doors.sh LayKam
```

Specify a custom database or world:

```bash
./1MB-Doors.sh LayKam ./totdatabase.db --world halloween
./1MB-Doors.sh LayKam ./totdatabase.db --world easter
```

Example output:
```
Missing doors for player 'LayKam' (DB: ./totdatabase.db, world: halloween)
-----------------------------------------------
door_id 30  ->  /tppos 1555 73 762 halloween
door_id 60  ->  /tppos 1477 71 689 halloween

Player has 58 of 60 doors (2 missing) in 'halloween'.
```

---

### 🔹 List Mode
List players who found a specific number of doors:

| Command | Meaning |
|----------|----------|
| `-list:60` | All players who found every door |
| `-list:59` | Players missing exactly one door |
| `-list:0` → `-list:58` | Players with that many doors found (shows what they’re missing) |

Examples:
```bash
./1MB-Doors.sh -list:60 --world halloween
./1MB-Doors.sh -list:59 ./totdatabase.db
./1MB-Doors.sh -list:42 --world easter
```

---

### 📊 Example Outputs

> **Note:** GitHub tables don’t support fenced code blocks inside cells.  
> The table below links to the full sample outputs shown right after it.

| Command | Sample Output |
|--------|----------------|
| `./1MB-Doors.sh -list:60 --world halloween` | See **Sample A** below |
| `./1MB-Doors.sh -list:0 --world halloween`  | See **Sample B** below |

**Sample A – `-list:60`**
```
Players with ALL doors (DB: ./totdatabase.db, world: halloween)
-----------------------------------------------
• LayKam
• FreddyTF2
• DaishaunsBot

Total players with all doors: 3.
```

**Sample B – `-list:0`**
```
Players with 0 doors (missing exactly 60) (DB: ./totdatabase.db, world: halloween)
-----------------------------------------------
NewPlayer123
  missing door_id 1  ->  /tppos 1533 77 678 halloween
  missing door_id 2  ->  /tppos 1541 73 697 halloween
  ...
  missing door_id 60 ->  /tppos 1477 71 689 halloween

Total players at 0/60: 1.
```

---

## 🌍 World Filtering
Use `--world <name>` to restrict checks to a specific world.  
This affects **everything**: totals, counts, and door listings.

If you omit `--world`, it defaults to:
```
--world halloween
```

---

## 📄 Notes
- Case-insensitive matching for both player names and world names.  
- Works with databases created by the [Halloween Trick or Treat](https://www.spigotmc.org/resources/halloween-trick-or-treating.48699/) plugin.  
- Safe to run — read-only access to SQLite.  
- Script auto-detects terminal color support; set `NO_COLOR=1` to disable colors.

---

## 💡 Example Use Cases
- During an event, identify players who are one door away from completion.  
- Reward players who found all doors.  
- Debug database issues if a door or world didn’t register properly.  
- Generate quick summaries for Discord or admin announcements.

---

## 🧾 Credits
Created by **Floris Fiedeldij Dop** for the **1MoreBlock.com** community.  
Development, cleanup, and documentation assisted by **ChatGPT (OpenAI)**.  

📍 **Source & support:** [https://scripts.1moreblock.com](https://scripts.1moreblock.com)

---

## ⚖️ License
© 1977 – 2025 Floris Fiedeldij Dop.  
This script is provided for community and educational use.  
Redistribution or modification is permitted with attribution.
