#!/usr/bin/env python3
"""
Jobs Reborn SQLite stats/leaderboards.

Features:
- Count distinct players for a given job (default job: fisherman)
- Leaderboard: job -> player-count (all jobs)
- Top N players for a job by level (default) or experience
- --all: top N players for ALL jobs

Expected tables (common Jobs Reborn schema):
- jobs(userid, job, level, experience, jobid, ...)
- users(id, username, player_uuid, ...)
- jobNames(name, ...)  (optional)
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import sys
from typing import Optional, List, Tuple


def script_dir_default_db() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "jobs.sqlite.db")


def connect(db_path: str) -> sqlite3.Connection:
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database not found: {db_path}")
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def table_exists(conn: sqlite3.Connection, name: str) -> bool:
    cur = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1;", (name,)
    )
    return cur.fetchone() is not None


def get_table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    rows = conn.execute(f"PRAGMA table_info({table});").fetchall()
    return {r["name"] for r in rows}


def resolve_job_name(conn: sqlite3.Connection, job_input: str) -> Optional[str]:
    """
    Resolve user's job input to the canonical job name stored in the DB.
    """
    job_lc = job_input.strip().lower()

    if table_exists(conn, "jobNames"):
        row = conn.execute(
            "SELECT name FROM jobNames WHERE LOWER(name)=? LIMIT 1;", (job_lc,)
        ).fetchone()
        if row:
            return row["name"]

    if table_exists(conn, "jobs"):
        row = conn.execute(
            "SELECT job FROM jobs WHERE LOWER(job)=? LIMIT 1;", (job_lc,)
        ).fetchone()
        if row:
            return row["job"]

    return None


def count_players_with_job(conn: sqlite3.Connection, canonical_job: str) -> int:
    row = conn.execute(
        "SELECT COUNT(DISTINCT userid) AS c FROM jobs WHERE LOWER(job)=LOWER(?);",
        (canonical_job,),
    ).fetchone()
    return int(row["c"] if row and row["c"] is not None else 0)


def total_players_with_any_job(conn: sqlite3.Connection) -> int:
    row = conn.execute("SELECT COUNT(DISTINCT userid) AS c FROM jobs;").fetchone()
    return int(row["c"] if row and row["c"] is not None else 0)


def job_playercount_leaderboard(conn: sqlite3.Connection) -> List[Tuple[str, int]]:
    """
    Returns list of (job, player_count) for all jobs.
    """
    rows = conn.execute(
        """
        SELECT job, COUNT(DISTINCT userid) AS player_count
        FROM jobs
        GROUP BY job
        ORDER BY player_count DESC, LOWER(job) ASC;
        """
    ).fetchall()
    return [(r["job"], int(r["player_count"])) for r in rows]


def list_all_jobs(conn: sqlite3.Connection) -> List[str]:
    """
    Returns all job names present in the DB.
    Prefer jobNames table if present, otherwise distinct jobs from jobs table.
    """
    if table_exists(conn, "jobNames"):
        rows = conn.execute("SELECT name FROM jobNames ORDER BY LOWER(name) ASC;").fetchall()
        if rows:
            return [r["name"] for r in rows]

    rows = conn.execute("SELECT DISTINCT job FROM jobs ORDER BY LOWER(job) ASC;").fetchall()
    return [r["job"] for r in rows]


def list_players_for_job(conn: sqlite3.Connection, canonical_job: str, limit: Optional[int]) -> list[Tuple[str, str]]:
    """
    Returns list of (username, uuid) for players having the job.
    """
    if not table_exists(conn, "users"):
        return []

    sql = """
        SELECT u.username, u.player_uuid
        FROM jobs j
        JOIN users u ON u.id = j.userid
        WHERE LOWER(j.job) = LOWER(?)
        ORDER BY LOWER(u.username) ASC
    """
    params = [canonical_job]
    if limit is not None:
        sql += " LIMIT ?"
        params.append(limit)

    rows = conn.execute(sql, tuple(params)).fetchall()
    return [(r["username"], r["player_uuid"]) for r in rows]


def top_players_for_job(
    conn: sqlite3.Connection,
    canonical_job: str,
    top_n: int,
    metric: str,
) -> list[dict]:
    """
    Returns rows for top players in a job.

    metric:
      - "level" => ORDER BY level DESC, experience DESC
      - "experience" => ORDER BY experience DESC, level DESC

    Tries to join users table for username/uuid; if users missing, returns userid only.
    """
    jobs_cols = get_table_columns(conn, "jobs")
    if "level" not in jobs_cols or "experience" not in jobs_cols:
        raise RuntimeError("Table 'jobs' is missing expected columns 'level' and/or 'experience'.")

    has_users = table_exists(conn, "users")
    order_clause = (
        "j.level DESC, j.experience DESC"
        if metric == "level"
        else "j.experience DESC, j.level DESC"
    )

    if has_users:
        sql = f"""
            SELECT
                u.username AS username,
                u.player_uuid AS uuid,
                j.userid AS userid,
                j.level AS level,
                j.experience AS experience
            FROM jobs j
            JOIN users u ON u.id = j.userid
            WHERE LOWER(j.job) = LOWER(?)
            ORDER BY {order_clause}
            LIMIT ?;
        """
    else:
        sql = f"""
            SELECT
                j.userid AS userid,
                j.level AS level,
                j.experience AS experience
            FROM jobs j
            WHERE LOWER(j.job) = LOWER(?)
            ORDER BY {order_clause}
            LIMIT ?;
        """

    rows = conn.execute(sql, (canonical_job, top_n)).fetchall()
    return [dict(r) for r in rows]


def print_leaderboard(rows: List[Tuple[str, int]], total_players_any_job: int, limit: Optional[int] = None) -> None:
    if limit is not None:
        rows = rows[:limit]

    width_job = max([len("Job")] + [len(job) for job, _ in rows]) if rows else len("Job")
    width_cnt = max([len("Players")] + [len(str(c)) for _, c in rows]) if rows else len("Players")

    print("\nJob → player-count leaderboard")
    print(f"{'Job'.ljust(width_job)}  {'Players'.rjust(width_cnt)}  % of players-with-any-job")
    print(f"{'-'*width_job}  {'-'*width_cnt}  {'-'*24}")

    for job, c in rows:
        pct = (c / total_players_any_job * 100.0) if total_players_any_job else 0.0
        print(f"{job.ljust(width_job)}  {str(c).rjust(width_cnt)}  {pct:>7.2f}%")

    print()


def print_top_block(job: str, rows: list[dict], metric: str) -> None:
    print(f"\nTop {len(rows)} for job {job} by {metric}:")
    if not rows:
        print(" (No rows found.)")
        return

    has_username = "username" in rows[0]
    for i, r in enumerate(rows, start=1):
        level = r.get("level", 0)
        exp = r.get("experience", 0)
        if has_username:
            print(f"{i:>2}. {r['username']} ({r['uuid']})  level={level}  exp={exp}")
        else:
            print(f"{i:>2}. userid={r['userid']}  level={level}  exp={exp}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Jobs Reborn SQLite stats/leaderboards.")
    parser.add_argument(
        "job",
        nargs="?",
        default="fisherman",
        help='Job name for single-job count (default: "fisherman"). Case-insensitive.',
    )
    parser.add_argument(
        "--db",
        default=script_dir_default_db(),
        help='Path to jobs sqlite db (default: "./jobs.sqlite.db" next to this script).',
    )

    parser.add_argument(
        "--count",
        action="store_true",
        help="Show count for the specified job (same as default behavior if no other mode selected).",
    )

    parser.add_argument(
        "--leaderboard",
        action="store_true",
        help="Show full leaderboard of job → player-count (all jobs).",
    )
    parser.add_argument(
        "--leaderboard-limit",
        type=int,
        default=None,
        help="Limit how many jobs to show in the leaderboard.",
    )

    parser.add_argument(
        "--list",
        action="store_true",
        help="List players (username + uuid) that have the specified job.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit number of players listed (use with --list).",
    )

    parser.add_argument(
        "--top",
        metavar="JOB",
        default=None,
        help="Show top players for a job (e.g. --top fisherman).",
    )
    parser.add_argument(
        "--top-n",
        type=int,
        default=10,
        help="How many players to show for --top and --all (default: 10).",
    )
    parser.add_argument(
        "--metric",
        choices=["level", "experience"],
        default="level",
        help="Ranking metric for --top/--all: level (default) or experience.",
    )

    parser.add_argument(
        "--all",
        action="store_true",
        help="Show top N players for ALL jobs found in the database (uses --top-n and --metric).",
    )

    args = parser.parse_args()

    try:
        conn = connect(args.db)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    try:
        if not table_exists(conn, "jobs"):
            print("ERROR: Expected table 'jobs' not found in this database.", file=sys.stderr)
            return 3

        # Decide modes
        any_mode = args.leaderboard or args.list or args.top or args.all or args.count
        if not any_mode:
            # default behavior: count for positional job
            args.count = True

        print(f"Database: {os.path.abspath(args.db)}")

        # Leaderboard
        if args.leaderboard:
            total = total_players_with_any_job(conn)
            lb = job_playercount_leaderboard(conn)
            print_leaderboard(lb, total, args.leaderboard_limit)

        # Count for job (positional)
        if args.count:
            canonical = resolve_job_name(conn, args.job)
            if not canonical:
                print(f'\nJob "{args.job}" not found in this database.')
                if table_exists(conn, "jobNames"):
                    sample = conn.execute("SELECT name FROM jobNames ORDER BY name ASC LIMIT 20;").fetchall()
                    if sample:
                        print("Some available jobs:")
                        for r in sample:
                            print(f" - {r['name']}")
                return 1

            count = count_players_with_job(conn, canonical)
            total = total_players_with_any_job(conn)
            pct = (count / total * 100.0) if total else 0.0

            print(f"\nJob: {canonical}")
            print(f"Players with this job: {count} (of {total} players with any job) = {pct:.2f}%")

        # List players
        if args.list:
            canonical = resolve_job_name(conn, args.job)
            if not canonical:
                print(f'\nJob "{args.job}" not found in this database (cannot list).')
                return 1

            players = list_players_for_job(conn, canonical, args.limit)
            if not players:
                print("\n(No users table found, or no players to list.)")
            else:
                print(f"\nPlayers with job {canonical} ({len(players)} shown):")
                for username, uuid in players:
                    print(f" - {username} ({uuid})")

        # Top N for one job
        if args.top:
            canonical_top = resolve_job_name(conn, args.top)
            if not canonical_top:
                print(f'\nJob "{args.top}" not found in this database (cannot show top).')
                return 1

            rows = top_players_for_job(conn, canonical_top, args.top_n, args.metric)
            print_top_block(canonical_top, rows, args.metric)

        # Top N for ALL jobs
        if args.all:
            jobs = list_all_jobs(conn)
            if not jobs:
                print("\n(No jobs found.)")
                return 0

            print(f"\nTop {args.top_n} for ALL jobs by {args.metric}:")
            for job in jobs:
                rows = top_players_for_job(conn, job, args.top_n, args.metric)
                # Print block even if empty (so you know the job existed)
                print_top_block(job, rows, args.metric)

        return 0

    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
