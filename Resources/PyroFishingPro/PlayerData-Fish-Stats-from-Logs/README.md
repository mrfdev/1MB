# Fish Tier Statistics Analyzer 🐟✨

A lightweight Python tool that parses your Minecraft server logs and generates **detailed statistics** about fish tiers such as **Mythical**, **Platinum**, and more.

It supports data from:

### 🎣 PyroFishingPro

A powerful fishing plugin for Minecraft:

➡️ https://www.spigotmc.org/resources/60729/

### 🎣 1MB’s `/fish` system

Modern in-game fishing used on **1MoreBlock.com**, with log lines like:

- `1MB /fish » Player has just caught a Mythical ...`
- `1PyroFishing ➤ Player has just caught a Mythical ...`
- `1MB /fish » Player has just caught a Platinum ...`
- `1PyroFishing ➤ Player has just caught a Platinum ...`

This script works with either format and gives you a complete overview of player activity, grinding patterns, and fishing intensity across months or years.

---

## What This Script Helps You With

✔️ Identify **top grinders** and 1%-ers per tier  
✔️ Generate **leaderboards** for each tier (Mythical, Platinum, etc.)  
✔️ Discover **busy months** and natural “fishing seasons”  
✔️ Compute **average catches per day, month, year**  
✔️ Compare activity across different tiers  
✔️ Understand community engagement and event loops  
✔️ Get an automatic **meta-analysis summary** (top player share, busiest/quietest months, etc.)  
✔️ Save the full report to a **`.log` file** for archiving or further processing

---

## Features

- Reads both **`.log`** and **`.log.gz`**
- Detects both formats:
  - `PyroFishing ➤ Player has just caught a ...`
  - `1MB /fish » Player has just caught a ...`
- Extracts:
  - Player names  
  - Fish tier (e.g. Mythical, Platinum, etc.)  
  - Dates (by filename, e.g. `2025-11-28-1.log.gz`)  

- Calculates:
  - Total catches for the selected tier(s)
  - First/last catch date
  - Time span
  - Average per day / month / year
  - Per-year totals
  - Per-month totals
  - Overall player leaderboard
  - **Per-tier player leaderboards** (e.g. Top Platinum anglers)
  - **Meta-analysis summary**, including:
    - Unique player count
    - Busiest and quietest months
    - Share of catches from the top 3 / 5 / 10 players
    - Mythical share of all high-tier catches (when `--tier ALL`)
    - Basic year-over-year comparison

- Zero external dependencies — just Python 3.
- Easy to tweak for your own formats or events.
- Automatically writes the full report to a **`.log` file** (unless disabled).

---

## How to Use

### 1. Export catch events from your logs

From your server's `logs/` directory, if you want **all tiers** in one file:

```bash
zgrep -ri "has just caught a " . > fish-catches.log
```

If you *only* care about mythicals (old behaviour):

```bash
zgrep -ri "has just caught a Mythical" . > fish-mythicals.log
```

---

### 2. Place the script

Example structure:

```text
logs/
 ├─ fish-catches.log
 └─ mythical_stats.py
```

The script reads from **stdin** so you can redirect any prepared log file into it.

---

### 3. Run the script

#### Mythical only (default behaviour)

```bash
python3 mythical_stats.py < fish-mythicals.log
# or, with the general file:
python3 mythical_stats.py --tier Mythical < fish-catches.log
```

#### Platinum only

```bash
python3 mythical_stats.py --tier Platinum < fish-catches.log
```

#### All tiers combined, with per-tier leaderboards and meta analysis

```bash
python3 mythical_stats.py --tier ALL < fish-catches.log
```

#### Show more (or fewer) players in per-tier leaderboards

```bash
python3 mythical_stats.py --tier ALL --top 20 < fish-catches.log
```

---

### 4. Output & `.log` Export

By default the script:

1. Prints a full report to **stdout** (terminal), including:
   - Overall stats
   - Per-tier totals
   - Per-year and per-month totals
   - Overall player leaderboard
   - Per-tier player leaderboards
   - Meta-analysis summary

2. Writes the **same report** to a `.log` file in the current directory, e.g.:

   ```text
   fish_stats_ALL_20251202-153045.log
   ```

   The filename includes the chosen tier filter and a timestamp.

You can change or disable this behaviour:

- Custom output file name:

  ```bash
  python3 mythical_stats.py --tier ALL --outfile my-fishing-report.log < fish-catches.log
  ```

- Disable file writing and only print to terminal:

  ```bash
  python3 mythical_stats.py --tier ALL --no-file < fish-catches.log
  ```

---

## Community & Support

Want to share ideas, ask questions, or show off ridiculous fishing grinds?

👉 **Join the 1MB community Discord:**  
https://discord.gg/floris

---

## Contributing

This script is intentionally small and hackable.  
**Contributions are very welcome** — feel free to improve it and open a PR.

Ideas for PRs:

- Better meta-analysis (e.g. per-player trend detection)
- Colored / nicely formatted terminal output
- Separate leaderboards per year or month
- Helper scripts (bash/zsh) to automate the zgrep + Python run
- More flexible parsing for custom log formats
- Tests for different plugin log styles

If your addition helps other server owners, I’m happy to merge it.

---

## License

This script is released under the **MIT License**.

You are free to:

- Use it on your server(s)
- Modify it for your own needs
- Include it in larger projects
- Submit PRs to share improvements with others

Enjoy, and happy fishing 🐟
