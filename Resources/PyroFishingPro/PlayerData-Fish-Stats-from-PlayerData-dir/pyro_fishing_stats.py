#!/usr/bin/env python3
"""
pyro_fishing_stats.py

Zero-dependency stats script for PyroFishingPro, designed to live inside the
plugins/PyroFishingPro/ folder.

Default behaviour:
- Uses the directory this script is in as base_dir.
- Looks for:
    base_dir/config.yml
    base_dir/PlayerData/*.yml

Optional:
- Resolve UUIDs to usernames using CMI's cmi.sqlite.db via:
    --uuid-resolve-cmi
  with optional:
    --cmi-db PATH

Other options:
- --min-total N   -> only include players with >= N total fish in leaderboards
- --min-custom N  -> only include players with >= N custom fish in leaderboards
- --write-log     -> write output to pyro-playerdata-stats-YYYYmmdd-HHMMSS.log
- --write-md      -> write output to pyro-playerdata-stats-YYYYmmdd-HHMMSS.md
- --player X      -> show detailed stats for one player (UUID or name if CMI
                     resolve is enabled). In this mode, ONLY that player's
                     stats are printed (no global summary/leaderboards).

No PyYAML required; uses simple regex/text parsing tailored to PyroFishingPro.
"""

import argparse
import json
import re
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional, Set

TIERS = ["Bronze", "Silver", "Gold", "Diamond", "Platinum", "Mythical"]
CACHE_FILENAME = "uuid_cache.json"


# ----------------------------------------------------------
# ANSI colors + printer
# ----------------------------------------------------------

class Ansi:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    CYAN = "\033[36m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    MAGENTA = "\033[35m"
    WHITE = "\033[37m"


class MultiSinkPrinter:
    """
    Helper that:
    - prints to console (with optional ANSI colors)
    - keeps a plain-text copy of all lines for log/markdown export
    """
    def __init__(self, use_color: bool = True):
        self.use_color = use_color
        self.lines_plain: List[str] = []

    def line(self, text: str = "", color: Optional[str] = None, bold: bool = False) -> None:
        self.lines_plain.append(text)

        if not self.use_color or (color is None and not bold):
            print(text)
            return

        prefix = ""
        if bold:
            prefix += Ansi.BOLD
        if color:
            prefix += color
        suffix = Ansi.RESET
        print(f"{prefix}{text}{suffix}")

    def key_value(self, label: str, value: str) -> None:
        """
        Print "label : value" with value highlighted, but store plain text.
        """
        line_plain = f"{label:<18}: {value}"
        self.lines_plain.append(line_plain)

        if not self.use_color:
            print(line_plain)
            return

        label_part = f"{label:<18}"
        sep = ": "
        val_part = str(value)
        print(f"{label_part}{sep}{Ansi.BOLD}{Ansi.WHITE}{val_part}{Ansi.RESET}")

    def leaderboard_entry(self, index: int, disp: str, detail: str) -> None:
        """
        Print a leaderboard line with ONLY the username highlighted,
        leaving the UUID normal.
        """
        plain = f"{index:>2}. {disp}  {detail}"
        self.lines_plain.append(plain)

        if not self.use_color:
            print(plain)
            return

        prefix = f"{index:>2}. "

        # Split "name (uuid)" so only name is highlighted
        if "(" in disp and disp.endswith(")"):
            name_part, uuid_part = disp.split("(", 1)
            uuid_part = "(" + uuid_part  # add '(' back
        else:
            name_part = disp
            uuid_part = ""

        print(
            f"{prefix}"
            f"{Ansi.BOLD}{Ansi.WHITE}{name_part.strip()}{Ansi.RESET} "
            f"{uuid_part}  {detail}"
        )


# ----------------------------------------------------------
# Tiny YAML-ish parsers (tailored to PyroFishingPro layout)
# ----------------------------------------------------------

def parse_stats_block(text: str) -> Dict[str, Any]:
    m = re.search(r'^Stats:\s*$', text, re.MULTILINE)
    if not m:
        return {}

    stats: Dict[str, Any] = {}
    lines = text[m.end():].splitlines()

    for line in lines:
        if not line.strip():
            if stats:
                break
            else:
                continue

        indent = len(line) - len(line.lstrip(' '))
        if indent < 2:
            if stats:
                break
            else:
                continue
        if indent != 2:
            continue

        stripped = line.strip()
        if ':' not in stripped:
            continue

        key, val = stripped.split(':', 1)
        key = key.strip()
        val = val.strip()

        if ' #' in val:
            val = val.split(' #', 1)[0].strip()

        if re.fullmatch(r'-?\d+', val):
            v: Any = int(val)
        elif re.fullmatch(r'-?\d+\.\d*', val):
            v = float(val)
        else:
            v = val.strip('"').strip("'")

        stats[key] = v

    return stats


def parse_skills_block(text: str) -> Dict[str, Any]:
    entropy: int = 0
    level: int = 0

    in_skills = False
    in_passives = False
    in_skilltree = False
    in_main = False

    for line in text.splitlines():
        stripped = line.lstrip()
        if not stripped or stripped.startswith('#'):
            continue

        indent = len(line) - len(stripped)

        if stripped.startswith("Skills:"):
            in_skills = True
            in_passives = in_skilltree = in_main = False
            continue

        if not in_skills:
            continue

        if indent == 0 and not stripped.startswith("Skills:"):
            in_skills = in_passives = in_skilltree = in_main = False
            continue

        if stripped.startswith("Passives:"):
            in_passives = True
            in_skilltree = in_main = False
            continue

        if stripped.startswith("SkillTree:"):
            in_skilltree = True
            in_passives = False
            in_main = False
            continue

        if in_skilltree and stripped.startswith("Main:"):
            in_main = True
            continue

        if in_passives and stripped.startswith("Entropy:"):
            _, val = stripped.split(":", 1)
            val = val.strip()
            if re.fullmatch(r'-?\d+', val):
                entropy = int(val)
            elif re.fullmatch(r'-?\d+\.\d*', val):
                entropy = int(float(val))

        if in_main and stripped.startswith("Level:"):
            _, val = stripped.split(":", 1)
            val = val.strip()
            if re.fullmatch(r'-?\d+', val):
                level = int(val)

    return {"Entropy": entropy, "Level": level}


def load_prices_from_config(config_path: Path) -> Dict[str, float]:
    if not config_path.is_file():
        return {}

    text = config_path.read_text(encoding="utf-8")
    keys = [
        "RawFishMoney",
        "BronzeMoney",
        "SilverMoney",
        "GoldMoney",
        "DiamondMoney",
        "PlatinumMoney",
        "MythicalMoney",
    ]
    prices: Dict[str, float] = {}
    for k in keys:
        m = re.search(
            rf'^\s*{re.escape(k)}\s*:\s*([-+]?\d+(?:\.\d+)?)',
            text,
            re.MULTILINE,
        )
        if m:
            prices[k] = float(m.group(1))
    return prices


# ----------------------------------------------------------
# UUID <-> username resolution via CMI + cache
# ----------------------------------------------------------

def load_uuid_cache(cache_path: Path) -> Dict[str, str]:
    if not cache_path.is_file():
        return {}
    try:
        data = json.loads(cache_path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return {str(k): str(v) for k, v in data.items()}
    except Exception:
        pass
    return {}


def save_uuid_cache(cache_path: Path, mapping: Dict[str, str]) -> None:
    try:
        cache_path.write_text(json.dumps(mapping, indent=2), encoding="utf-8")
    except Exception:
        pass


def resolve_uuids_via_cmi(
    uuids: Set[str],
    cmi_db_path: Path,
    cache_path: Path,
    out: MultiSinkPrinter,
) -> Dict[str, str]:
    cache = load_uuid_cache(cache_path)

    missing = [u for u in uuids if u not in cache]
    if not missing:
        return cache

    if not cmi_db_path.is_file():
        out.line(f"[WARN] CMI DB not found at {cmi_db_path}, skipping UUID resolution.", color=Ansi.YELLOW)
        return cache

    out.line(f"[INFO] Resolving {len(missing)} UUIDs via CMI DB: {cmi_db_path}", color=Ansi.CYAN)

    try:
        conn = sqlite3.connect(str(cmi_db_path))
        cur = conn.cursor()

        for u in missing:
            try:
                cur.execute(
                    "SELECT userName FROM users WHERE player_uuid = ? LIMIT 1",
                    (u,),
                )
                row = cur.fetchone()
                if row and row[0]:
                    cache[u] = str(row[0])
                else:
                    cache[u] = u
            except Exception as e:
                out.line(f"[WARN] Failed to resolve UUID {u} via CMI: {e}", color=Ansi.YELLOW)
                cache[u] = u

        conn.close()
    except Exception as e:
        out.line(f"[WARN] Could not open CMI DB at {cmi_db_path}: {e}", color=Ansi.YELLOW)
        return cache

    save_uuid_cache(cache_path, cache)
    return cache


# ----------------------------------------------------------
# Player summarising & aggregation
# ----------------------------------------------------------

def summarize_player(path: Path, prices: Dict[str, float]) -> Optional[Dict[str, Any]]:
    text = path.read_text(encoding="utf-8")

    stats = parse_stats_block(text)
    if not stats:
        return None

    skills = parse_skills_block(text)

    total = float(stats.get("TotalFishCaught", 0) or 0)
    custom_counts = {
        tier: int(stats.get(f"{tier}FishCaught", 0) or 0)
        for tier in TIERS
    }
    custom_total = sum(custom_counts.values())
    raw_fish = max(0, int(total - custom_total))

    money_made = float(stats.get("MoneyMade", 0.0) or 0.0)
    deliveries = int(stats.get("DeliveriesMade", 0) or 0)
    gutted = int(stats.get("FishGutted", 0) or 0)
    crabs = int(stats.get("CrabsKilled", 0) or 0)
    augments = int(stats.get("AugmentsCrafted", 0) or 0)
    longest_fish = float(stats.get("LongestFish", 0.0) or 0.0)
    tournaments = int(stats.get("TournamentsWon", 0) or 0)

    entropy = int(skills.get("Entropy", 0) or 0)
    level = int(skills.get("Level", 0) or 0)

    # Derived ratios (percentages where it makes sense)
    custom_ratio = (custom_total / total * 100.0) if total > 0 else 0.0
    high_tier = custom_counts["Diamond"] + custom_counts["Platinum"] + custom_counts["Mythical"]
    high_tier_ratio = (high_tier / custom_total * 100.0) if custom_total > 0 else 0.0
    mythic_rate = (custom_counts["Mythical"] / custom_total * 100.0) if custom_total > 0 else 0.0
    money_per_custom = (money_made / custom_total) if custom_total > 0 else 0.0
    entropy_per_custom = (entropy / custom_total) if custom_total > 0 else 0.0
    gut_ratio = (gutted / custom_total * 100.0) if custom_total > 0 else 0.0
    deliveries_per_custom = (deliveries / custom_total * 100.0) if custom_total > 0 else 0.0

    baseline_money: Optional[float] = None
    sellout_ratio: Optional[float] = None
    if prices:
        raw_price = float(prices.get("RawFishMoney", 0.0) or 0.0)
        base = raw_fish * raw_price
        for tier in TIERS:
            base += custom_counts[tier] * float(prices.get(f"{tier}Money", 0.0) or 0.0)
        baseline_money = float(base)
        if baseline_money > 0:
            sellout_ratio = money_made / baseline_money

    return {
        "uuid": path.stem,
        "name": None,
        "total_fish": int(total),
        "custom_fish": custom_total,
        "raw_fish": raw_fish,
        "tiers": custom_counts,
        "money_made": money_made,
        "baseline_money": baseline_money,
        "sellout_ratio": sellout_ratio,
        "deliveries": deliveries,
        "deliveries_per_custom": deliveries_per_custom,
        "gutted": gutted,
        "gut_ratio": gut_ratio,
        "crabs_killed": crabs,
        "augments_crafted": augments,
        "longest_fish": longest_fish,
        "tournaments_won": tournaments,
        "entropy": entropy,
        "entropy_per_custom": entropy_per_custom,
        "level": level,
        "custom_ratio": custom_ratio,
        "high_tier": high_tier,
        "high_tier_ratio": high_tier_ratio,
        "mythic_rate": mythic_rate,
        "money_per_custom": money_per_custom,
    }


def aggregate_totals(players: List[Dict[str, Any]]) -> Dict[str, Any]:
    agg: Dict[str, Any] = {
        "players": len(players),
        "total_fish": 0,
        "custom_fish": 0,
        "raw_fish": 0,
        "tiers": {tier: 0 for tier in TIERS},
        "money_made": 0.0,
        "deliveries": 0,
        "gutted": 0,
        "crabs_killed": 0,
    }
    for p in players:
        agg["total_fish"] += p.get("total_fish", 0)
        agg["custom_fish"] += p.get("custom_fish", 0)
        agg["raw_fish"] += p.get("raw_fish", 0)
        agg["money_made"] += p.get("money_made", 0.0)
        agg["deliveries"] += p.get("deliveries", 0)
        agg["gutted"] += p.get("gutted", 0)
        agg["crabs_killed"] += p.get("crabs_killed", 0)

        tiers = p.get("tiers", {})
        for tier in TIERS:
            agg["tiers"][tier] += tiers.get(tier, 0)

    return agg


def fmt_num(val: Optional[float], digits: int = 2) -> str:
    if val is None:
        return "-"
    if isinstance(val, int):
        return str(val)
    return f"{val:.{digits}f}"


def player_display_name(p: Dict[str, Any]) -> str:
    name = p.get("name")
    uuid = p.get("uuid", "")
    if name and name != uuid:
        return f"{name} ({uuid})"
    return uuid


def print_leaderboard(
    players: List[Dict[str, Any]],
    key: str,
    title: str,
    top_n: int,
    out: MultiSinkPrinter,
    reverse: bool = True,
    min_custom_for_lb: int = 0,
    global_min_total: int = 0,
    global_min_custom: int = 0,
) -> None:
    filtered = [p for p in players if p.get(key) is not None]

    if global_min_total:
        filtered = [p for p in filtered if p.get("total_fish", 0) >= global_min_total]
    if global_min_custom:
        filtered = [p for p in filtered if p.get("custom_fish", 0) >= global_min_custom]

    if min_custom_for_lb:
        filtered = [p for p in filtered if p.get("custom_fish", 0) >= min_custom_for_lb]

    filtered.sort(key=lambda p: p.get(key, 0), reverse=reverse)
    if not filtered:
        return

    out.line()
    out.line(f"=== {title} (top {min(top_n, len(filtered))}) ===", color=Ansi.MAGENTA, bold=True)
    for i, p in enumerate(filtered[:top_n], start=1):
        val = p.get(key)
        val_str = fmt_num(val)
        disp = player_display_name(p)
        detail = f"{key}={val_str} (total={p.get('total_fish')}, custom={p.get('custom_fish')})"
        out.leaderboard_entry(i, disp, detail)


# ----------------------------------------------------------
# Detailed single-player view
# ----------------------------------------------------------

def find_player(players: List[Dict[str, Any]], query: str) -> Optional[Dict[str, Any]]:
    q = query.strip().lower()
    for p in players:
        if p.get("uuid", "").lower() == q:
            return p
    for p in players:
        name = p.get("name")
        if name and name.lower() == q:
            return p
    return None


def print_player_details(p: Dict[str, Any], out: MultiSinkPrinter) -> None:
    out.line("PyroFishingPro Player Stats", color=Ansi.CYAN, bold=True)
    out.line("=================================", color=Ansi.CYAN)
    out.line(player_display_name(p), bold=True)
    out.line()

    out.key_value("Total fish", str(p["total_fish"]))
    out.key_value("Custom fish", str(p["custom_fish"]))
    out.key_value("Raw fish", str(p["raw_fish"]))

    out.line("Custom fish by tier:")
    tiers = p.get("tiers", {})
    for tier in TIERS:
        out.key_value(f"  {tier}", str(tiers.get(tier, 0)))

    out.key_value("Custom % of total", fmt_num(p["custom_ratio"]))
    out.key_value("High-tier %", fmt_num(p["high_tier_ratio"]))
    out.key_value("Mythic rate %", fmt_num(p["mythic_rate"]))

    out.key_value("Money made", fmt_num(p["money_made"]))
    if p.get("baseline_money") is not None:
        out.key_value("Theoretical max", fmt_num(p["baseline_money"]))
        out.key_value("Sellout ratio", fmt_num(p["sellout_ratio"]))
    out.key_value("Money/custom", fmt_num(p["money_per_custom"]))

    out.key_value("Entropy", str(p["entropy"]))
    out.key_value("Entropy/custom", fmt_num(p["entropy_per_custom"]))
    out.key_value("Level", str(p["level"]))

    out.key_value("Deliveries", str(p["deliveries"]))
    out.key_value("Deliveries %", fmt_num(p["deliveries_per_custom"]))
    out.key_value("Gutted", str(p["gutted"]))
    out.key_value("Gutted %", fmt_num(p["gut_ratio"]))
    out.key_value("Crabs killed", str(p["crabs_killed"]))
    out.key_value("Augments", str(p["augments_crafted"]))
    out.key_value("Longest fish", fmt_num(p["longest_fish"]))
    out.key_value("Tournaments won", str(p["tournaments_won"]))


# ----------------------------------------------------------
# Main CLI
# ----------------------------------------------------------

def main() -> None:
    script_dir = Path(__file__).resolve().parent

    parser = argparse.ArgumentParser(
        description="Analyze PyroFishingPro PlayerData (zero deps, plugin-folder-friendly)."
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=None,
        help="Path to PlayerData folder (default: <script_dir>/PlayerData)",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Path to PyroFishingPro config.yml (default: <script_dir>/config.yml)",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=5,
        help="How many entries to show per leaderboard (default: 5)",
    )
    parser.add_argument(
        "--include-zero",
        action="store_true",
        help="Include players with 0 fish caught.",
    )
    parser.add_argument(
        "--uuid-resolve-cmi",
        action="store_true",
        help="Resolve UUIDs to usernames using CMI's cmi.sqlite.db.",
    )
    parser.add_argument(
        "--cmi-db",
        type=Path,
        default=None,
        help="Path to CMI cmi.sqlite.db "
             "(default: <script_dir>/../CMI/cmi.sqlite.db when --uuid-resolve-cmi is used)",
    )
    parser.add_argument(
        "--min-total",
        type=int,
        default=0,
        help="Minimum total fish required to appear in leaderboards.",
    )
    parser.add_argument(
        "--min-custom",
        type=int,
        default=0,
        help="Minimum custom fish required to appear in leaderboards.",
    )
    parser.add_argument(
        "--write-log",
        action="store_true",
        help="Write output to pyro-playerdata-stats-YYYYmmdd-HHMMSS.log in script directory.",
    )
    parser.add_argument(
        "--write-md",
        action="store_true",
        help="Write output to pyro-playerdata-stats-YYYYmmdd-HHMMSS.md in script directory.",
    )
    parser.add_argument(
        "--player",
        type=str,
        help="Show detailed stats for a specific player (UUID or name; name requires --uuid-resolve-cmi). "
             "In this mode, global stats/leaderboards are not printed.",
    )

    args = parser.parse_args()
    out = MultiSinkPrinter(use_color=True)

    data_dir = args.data_dir or (script_dir / "PlayerData")
    config_path = args.config or (script_dir / "config.yml")

    prices = load_prices_from_config(config_path)

    if not data_dir.is_dir():
        raise SystemExit(f"Data directory not found: {data_dir}")

    player_files = sorted(
        p for p in data_dir.iterdir()
        if p.suffix == ".yml" and p.name != "config.yml"
    )

    players: List[Dict[str, Any]] = []
    for path in player_files:
        summary = summarize_player(path, prices)
        if not summary:
            continue
        if summary["total_fish"] <= 0 and not args.include_zero:
            continue
        players.append(summary)

    if not players:
        raise SystemExit("No player stats found. Check PlayerData or use --include-zero.")

    # Optional UUID -> username resolution via CMI
    if args.uuid_resolve_cmi:
        default_cmi_db = script_dir.parent / "CMI" / "cmi.sqlite.db"
        cmi_db_path = args.cmi_db or default_cmi_db
        cache_path = script_dir / CACHE_FILENAME

        uuids = {p["uuid"] for p in players}
        mapping = resolve_uuids_via_cmi(uuids, cmi_db_path, cache_path, out)

        for p in players:
            u = p["uuid"]
            p["name"] = mapping.get(u, u)

    # --- PLAYER-ONLY MODE ---
    if args.player:
        target = find_player(players, args.player)
        if target:
            print_player_details(target, out)
        else:
            out.line(f"No player found matching '{args.player}'.", color=Ansi.YELLOW)

        # Write log/markdown if requested, then exit
        if args.write_log or args.write_md:
            ts = datetime.now().strftime("%Y%m%d-%H%M%S")
            text = "\n".join(out.lines_plain) + "\n"
            if args.write_log:
                log_path = script_dir / f"pyro-playerdata-stats-{ts}.log"
                log_path.write_text(text, encoding="utf-8")
                out.line(f"\nSaved log to: {log_path}", color=Ansi.GREEN)
            if args.write_md:
                md_path = script_dir / f"pyro-playerdata-stats-{ts}.md"
                md_path.write_text(text, encoding="utf-8")
                out.line(f"Saved markdown to: {md_path}", color=Ansi.GREEN)
        return

    # --- GLOBAL SUMMARY + LEADERBOARDS MODE ---
    agg = aggregate_totals(players)

    out.line("PyroFishingPro Stats Summary", color=Ansi.CYAN, bold=True)
    out.line("============================")
    out.key_value("Base directory", str(script_dir))
    out.key_value("Config used", str(config_path))
    out.key_value("PlayerData used", str(data_dir))
    if args.uuid_resolve_cmi:
        out.key_value("UUID cache", str(script_dir / CACHE_FILENAME))
    out.key_value("Global min-total", str(args.min_total))
    out.key_value("Global min-custom", str(args.min_custom))
    out.line()
    out.key_value("Players with data", str(agg["players"]))
    out.key_value("Total fish caught", str(agg["total_fish"]))
    out.key_value("Custom fish", str(agg["custom_fish"]))
    out.key_value("Raw fish", str(agg["raw_fish"]))
    out.line("Custom fish by tier:")
    for tier in TIERS:
        out.key_value(f"  {tier}", str(agg["tiers"][tier]))
    out.key_value("Total money made", fmt_num(agg["money_made"]))
    out.key_value("Deliveries made", str(agg["deliveries"]))
    out.key_value("Crabs killed", str(agg["crabs_killed"]))
    out.key_value("Fish gutted", str(agg["gutted"]))

    top_n = args.top
    g_min_total = args.min_total
    g_min_custom = args.min_custom

    print_leaderboard(
        players, "total_fish", "Grinders – total fish caught",
        top_n=top_n, out=out,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "custom_fish", "Custom-fish addicts – total custom fish",
        top_n=top_n, out=out,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "mythic_rate",
        "Mythical luck – % of custom fish that are Mythical",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "high_tier_ratio",
        "High-roller fishers – % of custom fish that are Diamond+Platinum+Mythical",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "money_made", "Rich fishers – total money earned",
        top_n=top_n, out=out,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "money_per_custom",
        "Value fishers – money per custom fish",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "sellout_ratio",
        "Sell-out score – sold vs theoretical max (ratio)",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "entropy_per_custom",
        "Entropy farmers – entropy per custom fish",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "gut_ratio",
        "Butchers – % of custom fish gutted",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "deliveries_per_custom",
        "Delivery enjoyers – % of custom fish converted to deliveries",
        top_n=top_n, out=out,
        min_custom_for_lb=500,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "tournaments_won",
        "Tournament champions – total wins",
        top_n=top_n, out=out,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )
    print_leaderboard(
        players, "longest_fish",
        "Tall-tale fishers – longest fish",
        top_n=top_n, out=out,
        global_min_total=g_min_total, global_min_custom=g_min_custom,
    )

    # Optional log / markdown export
    if args.write_log or args.write_md:
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        text = "\n".join(out.lines_plain) + "\n"
        if args.write_log:
            log_path = script_dir / f"pyro-playerdata-stats-{ts}.log"
            log_path.write_text(text, encoding="utf-8")
            out.line(f"\nSaved log to: {log_path}", color=Ansi.GREEN)
        if args.write_md:
            md_path = script_dir / f"pyro-playerdata-stats-{ts}.md"
            md_path.write_text(text, encoding="utf-8")
            out.line(f"Saved markdown to: {md_path}", color=Ansi.GREEN)


if __name__ == "__main__":
    main()
