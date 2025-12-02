#!/usr/bin/env python3
"""
Fish Tier Statistics Analyzer

Parses Minecraft server logs (PyroFishingPro and 1MB /fish formats) from stdin,
aggregates stats per tier (e.g. Mythical, Platinum), and prints a detailed report.

It also writes the full report to a .log file by default, so it can be archived
or processed by other tools later.
"""

import sys
import re
import argparse
from collections import Counter, defaultdict
from datetime import date, datetime


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Analyze Minecraft fishing log stats (Mythical, Platinum, etc.)."
    )
    parser.add_argument(
        "-t",
        "--tier",
        default="Mythical",
        help=(
            "Fish tier to analyze (e.g. Mythical, Platinum). "
            "Use 'ALL' to include all tiers (default: Mythical)."
        ),
    )
    parser.add_argument(
        "--top",
        type=int,
        default=10,
        help="How many players to show in per-tier leaderboards (default: 10).",
    )
    parser.add_argument(
        "--outfile",
        help=(
            "Write the full report to this .log file. "
            "If not provided, a name like 'fish_stats_<tier>_YYYYMMDD-HHMMSS.log' "
            "will be used."
        ),
        default=None,
    )
    parser.add_argument(
        "--no-file",
        action="store_true",
        help="Do not write a .log export, only print to stdout.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    tier_filter = args.tier
    top_n = args.top

    # --- regex helpers ---
    re_date = re.compile(r"(\d{4}-\d{2}-\d{2})")
    # supports both "1MB /fish »" and "PyroFishing ➤"
    re_player = re.compile(r"(?:/fish »|PyroFishing ➤) (.+?) has just caught")
    # first word after "has just caught a" is the tier (Mythical, Platinum, etc.)
    re_tier = re.compile(r"has just caught a (\w+)\b")

    events = []

    for line in sys.stdin:
        line = line.strip()
        if "has just caught a " not in line:
            continue

        # date from filename/path (the zgrep output prefix)
        m_date = re_date.search(line)
        if not m_date:
            # probably from latest.log without date in path; skip for now
            continue
        try:
            d = date.fromisoformat(m_date.group(1))
        except ValueError:
            # malformed date, skip
            continue

        # player
        m_player = re_player.search(line)
        if not m_player:
            continue
        player = m_player.group(1)

        # tier
        m_tier = re_tier.search(line)
        if not m_tier:
            continue
        tier = m_tier.group(1)

        # apply tier filter (unless ALL)
        if tier_filter.upper() != "ALL" and tier != tier_filter:
            continue

        events.append((d, player, tier, line))

    if not events:
        print(f"No events found for tier filter: {tier_filter}")
        return

    # --- global collections ---
    dates = [d for d, _, _, _ in events]
    players = [p for _, p, _, _ in events]
    tiers = [t for _, _, t, _ in events]

    min_date = min(dates)
    max_date = max(dates)
    total_events = len(events)
    days_span = (max_date - min_date).days + 1

    avg_per_day = total_events / days_span
    months_span = days_span / 30.4375  # avg days per month
    years_span = days_span / 365.25    # avg days per year

    avg_per_month = total_events / months_span
    avg_per_year = total_events / years_span

    per_tier = Counter(tiers)
    per_year = Counter(d.year for d in dates)
    per_month = Counter((d.year, d.month) for d in dates)
    per_player_overall = Counter(players)

    # per-tier per-player
    per_player_per_tier = defaultdict(Counter)
    for d, player, tier, _ in events:
        per_player_per_tier[tier][player] += 1

    # Build output in memory so we can both print and write to file
    out_lines = []

    out_lines.append("=== Fish Stats ===")
    out_lines.append(f"Tier filter         : {tier_filter}")
    out_lines.append(f"First recorded catch: {min_date}")
    out_lines.append(f"Last recorded catch : {max_date}")
    out_lines.append(f"Total catches       : {total_events}")
    out_lines.append(
        f"Span of data        : {days_span} days (~{months_span:.1f} months, ~{years_span:.2f} years)"
    )
    out_lines.append("")
    out_lines.append(f"Average per day     : {avg_per_day:.2f}")
    out_lines.append(f"Average per month   : {avg_per_month:.2f}")
    out_lines.append(f"Average per year    : {avg_per_year:.2f}")
    out_lines.append("")

    # --- per-tier totals (useful when tier_filter = ALL) ---
    out_lines.append("=== Per-tier totals (in this dataset) ===")
    for t, count in per_tier.most_common():
        out_lines.append(f"{t}: {count}")
    out_lines.append("")

    # --- per-year breakdown ---
    out_lines.append("=== Per-year totals ===")
    for year in sorted(per_year):
        out_lines.append(f"{year}: {per_year[year]} catches")
    out_lines.append("")

    # --- per-month breakdown (YYYY-MM) ---
    out_lines.append("=== Per-month totals ===")
    for (y, m), count in sorted(per_month.items()):
        out_lines.append(f"{y}-{m:02d}: {count}")
    out_lines.append("")

    # --- overall leaderboard ---
    out_lines.append("=== Overall player leaderboard (catches) ===")
    for name, count in per_player_overall.most_common():
        out_lines.append(f"{name}: {count}")
    out_lines.append("")

    # --- per-tier per-player leaderboards ---
    out_lines.append("=== Per-tier player leaderboards ===")
    for t in sorted(per_player_per_tier.keys()):
        counter = per_player_per_tier[t]
        out_lines.append(f"\n-- Tier: {t} (top {top_n}) --")
        for name, count in counter.most_common(top_n):
            out_lines.append(f"{name}: {count}")
    out_lines.append("")

    # --- meta analysis summary ---
    out_lines.append("=== Meta analysis summary ===")

    # 1) unique players
    unique_players = len(per_player_overall)
    out_lines.append(f"Unique players in this dataset: {unique_players}")

    # 2) busiest / quietest months
    if per_month:
        month_counts = [
            (f"{y}-{m:02d}", c) for (y, m), c in per_month.items()
        ]
        month_counts_sorted = sorted(month_counts, key=lambda x: x[1], reverse=True)
        busiest = month_counts_sorted[:3]
        quietest = sorted(month_counts, key=lambda x: x[1])[:3]

        out_lines.append("Busiest months (top 3):")
        for ym, c in busiest:
            out_lines.append(f"  {ym}: {c} catches")

        out_lines.append("Quietest months (bottom 3):")
        for ym, c in quietest:
            out_lines.append(f"  {ym}: {c} catches")
    else:
        out_lines.append("No monthly data available for meta analysis.")

    # 3) contribution from top players
    def share_for_top(n: int) -> float:
        top_n_players = per_player_overall.most_common(n)
        if not top_n_players:
            return 0.0
        subtotal = sum(count for _, count in top_n_players)
        return (subtotal / total_events) * 100.0

    for n in (3, 5, 10):
        share = share_for_top(n)
        out_lines.append(
            f"Top {n} players combined account for ~{share:.1f}% of all catches."
        )

    # 4) if ALL tiers, show mythical share specifically
    if tier_filter.upper() == "ALL":
        mythical_count = per_tier.get("Mythical", 0)
        plat_count = per_tier.get("Platinum", 0)
        mythical_share = (mythical_count / total_events * 100.0) if total_events else 0.0
        out_lines.append(
            f"Mythical catches: {mythical_count} "
            f"({mythical_share:.1f}% of all high-tier catches in this dataset)."
        )
        if plat_count:
            out_lines.append(
                f"Platinum catches: {plat_count} ({plat_count/total_events*100.0:.1f}%)."
            )

    # 5) basic year-over-year comparison if multiple years
    if len(per_year) >= 2:
        sorted_years = sorted(per_year.items())
        first_year, first_count = sorted_years[0]
        last_year, last_count = sorted_years[-1]
        if first_count > 0:
            delta = last_count - first_count
            pct = (delta / first_count) * 100.0
            if delta > 0:
                trend = "increased"
            elif delta < 0:
                trend = "decreased"
            else:
                trend = "stayed about the same"
            out_lines.append(
                f"Year-over-year: from {first_year} ({first_count} catches) "
                f"to {last_year} ({last_count} catches) → {trend} by {delta} "
                f"({pct:+.1f}%)."
            )

    out_lines.append("")

    # Join and print
    output = "\n".join(out_lines)
    print(output)

    # Write to .log file unless disabled
    if not args.no_file:
        if args.outfile:
            out_path = args.outfile
        else:
            safe_tier = tier_filter.replace(" ", "_")
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            out_path = f"fish_stats_{safe_tier}_{timestamp}.log"
        try:
            with open(out_path, "w", encoding="utf-8") as f:
                f.write(output + "\n")
            print(f"Report written to: {out_path}", file=sys.stderr)
        except OSError as e:
            print(f"Failed to write report to '{out_path}': {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
