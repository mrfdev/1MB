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

Perfect for server owners, staff teams, and event planners.

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

- Zero external dependencies — just Python 3.
- Easy to tweak for your own formats or events.

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

```
logs/
 ├─ fish-catches.log
 └─ mythical_stats.py
```

---

### 3. Run the script

#### Mythical only (default)

```bash
python3 mythical_stats.py < fish-mythicals.log
# or, with the general file:
python3 mythical_stats.py --tier Mythical < fish-catches.log
```

#### Platinum only

```bash
python3 mythical_stats.py --tier Platinum < fish-catches.log
```

#### All tiers combined, with per-tier leaderboards

```bash
python3 mythical_stats.py --tier ALL < fish-catches.log
```

#### Show more (or fewer) players in per-tier leaderboards

```bash
python3 mythical_stats.py --tier ALL --top 20 < fish-catches.log
```

---

## Community & Support

👉 **Join the 1MB community Discord:**  
https://discord.gg/floris

---

## Contributing

This script is intentionally small and hackable.  
**Contributions are very welcome** — feel free to improve it and open a PR.

---

## License

This script is released under the **MIT License**.
