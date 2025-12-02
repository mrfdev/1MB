#!/usr/bin/env python3
import sys
import re
import argparse
from collections import Counter, defaultdict
from datetime import date

# --- CLI arguments ---
parser = argparse.ArgumentParser(
    description="Analyze Minecraft fishing log stats (Mythical, Platinum, etc.)."
)
parser.add_argument(
    "-t", "--tier",
    default="Mythical",
    help=(
        "Fish tier to analyze (e.g. Mythical, Platinum). "
        "Use 'ALL' to include all tiers."
    ),
)
parser.add_argument(
    "--top",
    type=int,
    default=10,
    help="How many players to show in per-tier leaderboards (default: 10).",
)
args = parser.parse_args()
tier_filter = args.tier
top_n = args.top

# --- regex helpers ---
RE_DATE = re.compile(r'(\d{4}-\d{2}-\d{2})')
# supports both "1MB /fish »" and "PyroFishing ➤"
RE_PLAYER = re.compile(r'(?:/fish »|PyroFishing ➤) (.+?) has just caught')
# first word after "has just caught a" is the tier (Mythical, Platinum, etc.)
RE_TIER = re.compile(r'has just caught a (\w+)\b')

events = []

for line in sys.stdin:
    line = line.strip()
    if "has just caught a " not in line:
        continue

    # date from filename/path
    m_date = RE_DATE.search(line)
    if not m_date:
        # probably from latest.log without date in path; skip for now
        continue
    d = date.fromisoformat(m_date.group(1))

    # player
    m_player = RE_PLAYER.search(line)
    if not m_player:
        continue
    player = m_player.group(1)

    # tier
    m_tier = RE_TIER.search(line)
    if not m_tier:
        continue
    tier = m_tier.group(1)

    # apply tier filter (unless ALL)
    if tier_filter.upper() != "ALL" and tier != tier_filter:
        continue

    events.append((d, player, tier, line))

if not events:
    print(f"No events found for tier filter: {tier_filter}")
    sys.exit(0)

# --- global collections ---
dates = [d for d, _, _, _ in events]
players = [p for _, p, _, _ in events]
tiers = [t for _, _, t, _ in events]

min_date = min(dates)
max_date = max(dates)
total_events = len(events)
days_span = (max_date - min_date).days + 1

avg_per_day = total_events / days_span
months_span = days_span / 30.4375    # avg days per month
years_span = days_span / 365.25      # avg days per year

avg_per_month = total_events / months_span
avg_per_year = total_events / years_span

print("=== Fish Stats ===")
print(f"Tier filter         : {tier_filter}")
print(f"First recorded catch: {min_date}")
print(f"Last recorded catch : {max_date}")
print(f"Total catches       : {total_events}")
print(f"Span of data        : {days_span} days (~{months_span:.1f} months, ~{years_span:.2f} years)")
print()
print(f"Average per day     : {avg_per_day:.2f}")
print(f"Average per month   : {avg_per_month:.2f}")
print(f"Average per year    : {avg_per_year:.2f}")
print()

# --- per-tier totals (useful when tier_filter = ALL) ---
per_tier = Counter(tiers)
print("=== Per-tier totals (in this dataset) ===")
for t, count in per_tier.most_common():
    print(f"{t}: {count}")
print()

# --- per-year breakdown ---
per_year = Counter(d.year for d in dates)
print("=== Per-year totals ===")
for year in sorted(per_year):
    print(f"{year}: {per_year[year]} catches")
print()

# --- per-month breakdown (YYYY-MM) ---
per_month = Counter((d.year, d.month) for d in dates)
print("=== Per-month totals ===")
for (y, m), count in sorted(per_month.items()):
    print(f"{y}-{m:02d}: {count}")
print()

# --- overall leaderboard ---
per_player_overall = Counter(players)

print("=== Overall player leaderboard (catches) ===")
for name, count in per_player_overall.most_common():
    print(f"{name}: {count}")
print()

# --- per-tier per-player leaderboards ---
per_player_per_tier: dict[str, Counter] = defaultdict(Counter)
for _, player, tier, _ in events:
    per_player_per_tier[tier][player] += 1

print("=== Per-tier player leaderboards ===")
for t in sorted(per_player_per_tier.keys()):
    counter = per_player_per_tier[t]
    print(f"\n-- Tier: {t} (top {top_n}) --")
    for name, count in counter.most_common(top_n):
        print(f"{name}: {count}")
