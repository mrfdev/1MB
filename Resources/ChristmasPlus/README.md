# 📦 1MB-ChristmasPlus.sh

A command-line tool for querying Advent calendar progress from the **Christmas+** Minecraft plugin database.

This utility allows staff and server admins to inspect, audit, and export participation data from `database.db`, helping track daily advent claims, generate player lists, and produce full event statistics — including Markdown exports suitable for Discord, GitHub, or documentation.

---

## ✨ Features

✔ Query who claimed **a specific Advent day (1–24)**
✔ Look up **any player by name or UUID**
✔ Show which days a player **claimed / missed**
✔ Check who completed all 24, or nearly did (23/22)
✔ Full **per-day breakdown** for every participant
✔ Export Markdown formatted statistics (`stats > file.md`)
✔ List all unique players sorted by total days claimed
✔ Filter players: `allnames <minDays>`
✔ Optional `--uuid` flag to append player UUIDs anywhere

---

## 📜 Requirements

| Dependency | Needed For                                 |
| ---------- | ------------------------------------------ |
| `sqlite3`  | Reading Minecraft Christmas+ database      |
| `jq`       | Parsing JSON stored in claimedGifts column |

---

## 🔧 Installation

### Release / Download
```bash
# @Version: 2.0.0, build 031
# @Release: December 1st, 2025
```
- You can download it from here: [1MB-ChristmasPlus.sh](/Resources/ChristmasPlus/src/1MB-ChristmasPlus.sh)

### Make executable
```bash
chmod +x 1MB-ChristmasPlus.sh
```

### Place the script beside `database.db` (or define with:)
```bash
export DB_PATH=/path/to/database.db
```

---

## 🚀 Usage

If you run the script, it will spit out the usage page.

### 📘 Syntax / Usage
```bash
./1MB-ChristmasPlus.sh <day 1-24> [--uuid]
./1MB-ChristmasPlus.sh <playername|uuid> [--uuid]
./1MB-ChristmasPlus.sh all [--uuid]
./1MB-ChristmasPlus.sh complete [--uuid]
./1MB-ChristmasPlus.sh allnames [minDays] [--uuid]
./1MB-ChristmasPlus.sh stats > stats.md
```

---

### 🔥 Examples
```bash
./1MB-ChristmasPlus.sh 1                                   # who claimed Day 1
./1MB-ChristmasPlus.sh 5 --uuid                            # who claimed Day 5 + UUID column
./1MB-ChristmasPlus.sh mrfloris                            # breakdown for mrfloris
./1MB-ChristmasPlus.sh mrfloris --uuid                     # breakdown w/ UUID
./1MB-ChristmasPlus.sh 631e3896-da2a-4077-974b-d047859d76bc # lookup by UUID
./1MB-ChristmasPlus.sh 631e3896-da2a-4077-974b-d047859d76bc --uuid # with UUID shown back
./1MB-ChristmasPlus.sh all                                 # full, 23-day, 22-day lists
./1MB-ChristmasPlus.sh complete                            # includes per-day breakdown
./1MB-ChristmasPlus.sh complete --uuid                     # per-day breakdown with UUID
./1MB-ChristmasPlus.sh allnames                            # sorted by total days claimed
./1MB-ChristmasPlus.sh allnames --uuid                     # sorted, but with UUIDs included
./1MB-ChristmasPlus.sh allnames 5                          # only players with ≥5 claimed days
./1MB-ChristmasPlus.sh allnames 5 --uuid                   # only ≥5 claimed + UUIDs appended
./1MB-ChristmasPlus.sh stats > stats.md                    # full Markdown export (Discord/GitHub friendly)
```

---

## 📄 Changelog (v2.0)

> A full merge of the internal staff tool, the original public version, and Momshroom’s contributions — rebuilt, extended, cleaned, and refreshed with ChatGPT assistance for Christmas+ 2025.
> Updated for **Paper 1.21.10+ & latest Christmas+ plugin**.
> Code simplified, output clarified, and statistics improved.
>

---

## 🧑‍💻 Authors & Credits

| Contributor            | Notes                                           |
| ---------------------- | ----------------------------------------------- |
| **mrfloris**           | Project maintainer & core developer             |
| **Momshroom**          | Additional logic & improvements                 |
| **ChatGPT assistance** | Full v2.0 refactor, stats system, Markdown mode |

---

 ## 🌐 Project Links

🔗 Latest source & updates: **[https://scripts.1moreblock.com](https://scripts.1moreblock.com)**
💬 Discord support: **[https://discord.gg/floris](https://discord.gg/floris)**

