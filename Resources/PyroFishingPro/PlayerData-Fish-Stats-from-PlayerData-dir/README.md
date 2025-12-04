
# PyroFishingPro PlayerData Stats Script

A zero-dependency Python script to analyze **PyroFishingPro** player data directly inside your Minecraft server’s `plugins/PyroFishingPro/` folder.

This script provides:

- Global stats summary
- Multiple leaderboards (custom fish, mythical rate, value fishers, tournaments, etc.)
- UUID → username resolution using **CMI**’s `cmi.sqlite.db`
- Player-specific deep‑dive stats with `--player`
- Export to `.log` and Discord‑friendly `.md`
- Colored console output for readability
- Zero external dependencies — **no pip needed**

---

## 📦 Installation

Place the file:

```
pyro_fishing_stats.py
```

Inside:

```
/plugins/PyroFishingPro/
```

Ensure the folder contains:

- `config.yml`
- `PlayerData/*.yml`
- (optional) `../CMI/cmi.sqlite.db` for UUID → name resolving

---

## 🧪 Basic Usage

Run from inside the plugin directory:

```bash
cd plugins/PyroFishingPro
python3 pyro_fishing_stats.py
```

### With CMI username resolving

```bash
python3 pyro_fishing_stats.py --uuid-resolve-cmi
```

This will read:

```
../CMI/cmi.sqlite.db
```

or a custom path:

```bash
python3 pyro_fishing_stats.py --uuid-resolve-cmi --cmi-db /path/to/cmi.sqlite.db
```

---

## 🏆 Leaderboards

Change number of entries:

```bash
--top 10
--top 25
--top 100
```

Apply global filters:

```bash
--min-total 10000
--min-custom 2500
```

---

## 🧍 Player‑Only Mode

Skip global stats & show detailed stats for one player:

```bash
python3 pyro_fishing_stats.py --player <uuid>
```

Or (with CMI):

```bash
python3 pyro_fishing_stats.py --uuid-resolve-cmi --player <username>
```

Outputs:

- Total/raw/custom fish  
- Tier breakdown  
- Percentages (mythic %, gut %, deliveries %)  
- Entropy + level  
- Money made & theoretical max  
- Longest fish  
- Tournaments won  
- And more

---

## 📝 Exporting Output

### Log file:

```bash
--write-log
```

Produces:

```
pyro-playerdata-stats-YYYYmmdd-HHMMSS.log
```

### Discord‑friendly Markdown:

```bash
--write-md
```

_No tables, no `---`, only plain structured Markdown._

---

## 🎨 Console Coloring

Key/value pairs are formatted like:

```
Deliveries        : 7411
Fish gutted       : 214002
Custom rate %     : 87.19
```

Leaderboards highlight **playernames only**  
UUIDs remain non‑highlighted to avoid noise.

---

## ⚙️ Full Parameter List

```
--player <uuid|name>
--uuid-resolve-cmi
--cmi-db <path>
--top N
--min-total N
--min-custom N
--include-zero
--write-log
--write-md
--data-dir <path>
--config <path>
```

---

## 🧩 No Dependencies

The script **does not require PyYAML**.  
It uses custom lightweight `.yml` parsers designed for PyroFishingPro’s format.

---

## 📄 License

MIT (recommended for this script)

---

## 🤝 Contributing

PRs welcome!  
Ideas welcome!  
Even more stats, fun rankings, or special event tracking can be added easily.

---

Enjoy digging through your fishing addicts’ secrets 🎣🔥
