#!/usr/bin/env python3
import sys
import re
from collections import Counter, defaultdict
from datetime import date

# regex helpers
RE_DATE = re.compile(r'(\d{4}-\d{2}-\d{2})')
# supports both "1MB /fish »" and "PyroFishing ➤"
RE_PLAYER = re.compile(r'(?:/fish »|PyroFishing ➤) (.+?) has just caught')

events = []

for line in sys.stdin:
    line = line.strip()
    if "Mythical" not in line:
        continue

    # date from filename
    m_date = RE_DATE.search(line)
    if not m_date:
        # probably from latest.log – skip or hard-code if you want
        continue
    d = date.fromisoformat(m_date.group(1))

    # player name
    m_player = RE_PLAYER.search(line)
    if not m_player:
        continue
    player = m_player.group(1)

    # store event
    events.append((d, player, line))

if not events:
    print("No events found.")
    sys.exit(0)

# --- global stats ---
dates = [d for d, _, _ in events]
players = [p for _, p, _ in events]

min_date = min(dates)
max_date = max(dates)
total_events = len(events)
days_span = (max_date - min_date).days + 1

avg_per_day = total_events / days_span
# use actual span to derive months/years instead of hard-coding
months_span = days_span / 30.4375    # average days per month
years_span = days_span / 365.25      # average days per year

avg_per_month = total_events / months_span
avg_per_year = total_events / years_span

print("=== Mythical Fish Stats ===")
print(f"First recorded catch: {min_date}")
print(f"Last recorded catch : {max_date}")
print(f"Total mythicals     : {total_events}")
print(f"Span of data        : {days_span} days (~{months_span:.1f} months, ~{years_span:.2f} years)")
print()
print(f"Average per day     : {avg_per_day:.2f}")
print(f"Average per month   : {avg_per_month:.2f}")
print(f"Average per year    : {avg_per_year:.2f}")
print()

# --- per-year breakdown ---
per_year = Counter(d.year for d in dates)
print("=== Per-year totals ===")
for year in sorted(per_year):
    print(f"{year}: {per_year[year]} mythicals")
print()

# --- per-month breakdown (YYYY-MM) ---
per_month = Counter((d.year, d.month) for d in dates)
print("=== Per-month totals ===")
for (y, m), count in sorted(per_month.items()):
    print(f"{y}-{m:02d}: {count}")
print()

# --- leaderboard ---
per_player = Counter(players)

print("=== Player leaderboard (mythicals caught) ===")
for name, count in per_player.most_common():
    print(f"{name}: {count}")

