# Jobs SQLite Tools (Jobs Reborn / Jobs Plugin)

Two small Python scripts that read the Jobs plugin SQLite database (`jobs.sqlite.db`) and help you answer questions like:

- How many players have job X?
- Who are the top 10 Fisherman / Miner players?
- What’s the leaderboard of jobs by how many players have them?
- Give me the top 10 list for every job

---

## Files

- `count_job_players.py` – Simple job → player count tool
- `jobs_stats.py` – Advanced statistics, leaderboards, and top lists

---

## Requirements

- macOS / Linux
- Python 3 (no external dependencies)

Check Python:

```bash
python3 --version
```

---

## Setup

Place the scripts in the same directory as the database:

```
.
├── jobs.sqlite.db
├── count_job_players.py
└── jobs_stats.py
```

(Optional) Make executable:

```bash
chmod +x count_job_players.py jobs_stats.py
```

---

# count_job_players.py

## Syntax

```bash
python3 count_job_players.py [job] [--db PATH] [--list] [--limit N]
```

### Defaults
- Job defaults to `fisherman`
- Database defaults to `./jobs.sqlite.db`

## Examples

Count fisherman (default):

```bash
python3 count_job_players.py
```

Count miner:

```bash
python3 count_job_players.py miner
```

List all fisherman:

```bash
python3 count_job_players.py fisherman --list
```

Limit output:

```bash
python3 count_job_players.py fisherman --list --limit 25
```

---

# jobs_stats.py

## Syntax

```bash
python3 jobs_stats.py [job] [options]
```

## Default behavior

If no flags are provided, the script counts players for the given job (default: fisherman).

---

## Count players in a job

```bash
python3 jobs_stats.py miner
python3 jobs_stats.py farmer --count
```

---

## List players in a job

```bash
python3 jobs_stats.py fisherman --list
python3 jobs_stats.py fisherman --list --limit 50
```

---

## Job → player-count leaderboard

```bash
python3 jobs_stats.py --leaderboard
python3 jobs_stats.py --leaderboard --leaderboard-limit 15
```

---

## Top players for ONE job

```bash
python3 jobs_stats.py --top fisherman
python3 jobs_stats.py --top miner --top-n 25
python3 jobs_stats.py --top fisherman --metric experience
```

---

## Top players for ALL jobs

```bash
python3 jobs_stats.py --all
python3 jobs_stats.py --all --metric experience
python3 jobs_stats.py --all --top-n 5
```

---

## Custom database path

```bash
python3 jobs_stats.py --leaderboard --db /path/to/jobs.sqlite.db
python3 count_job_players.py miner --db /path/to/jobs.sqlite.db
```

---

## Notes

- Job names are case-insensitive
- Rankings default to `level`, with `experience` as tie-breaker
- If the `users` table is missing, output falls back to `userid`

---

## Intended use

Designed for server owners, admins, and staff to analyze Jobs Reborn data safely offline.
