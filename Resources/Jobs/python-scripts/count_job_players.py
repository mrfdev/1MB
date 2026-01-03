#!/usr/bin/env python3
"""
Count how many distinct players have a particular Jobs Reborn job
from a SQLite database named 'jobs.sqlite.db'.

Default job: fisherman (case-insensitive)
Default db path: jobs.sqlite.db in the same folder as this script
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import sys
from typing import Optional, Tuple


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


def resolve_job_name(conn: sqlite3.Connection, job_input: str) -> Optional[str]:
    """
    Try to resolve the user's job input to the canonical job name stored in the DB.
    Priority:
      1) jobNames table (authoritative list)
      2) jobs table distinct values
    Returns canonical name (e.g. 'Fisherman') or None if not found.
    """
    job_lc = job_input.strip().lower()

    if table_exists(conn, "jobNames"):
        row = conn.execute(
            "SELECT name FROM jobNames WHERE LOWER(name)=? LIMIT 1;", (job_lc,)
        ).fetchone()
        if row:
            return row["name"]

    # Fallback: check jobs table itself
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


def list_players(conn: sqlite3.Connection, canonical_job: str, limit: Optional[int]) -> list[Tuple[str, str]]:
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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Count how many distinct players have a particular Jobs Reborn job."
    )
    parser.add_argument(
        "job",
        nargs="?",
        default="fisherman",
        help='Job name to count (default: "fisherman"). Case-insensitive.',
    )
    parser.add_argument(
        "--db",
        default=script_dir_default_db(),
        help='Path to jobs sqlite db (default: "./jobs.sqlite.db" next to this script).',
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Also list matching players (username + uuid).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit number of listed players (use with --list).",
    )

    args = parser.parse_args()

    try:
        conn = connect(args.db)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    try:
        # Sanity check for expected tables
        if not table_exists(conn, "jobs"):
            print("ERROR: Expected table 'jobs' not found in this database.", file=sys.stderr)
            return 3

        canonical = resolve_job_name(conn, args.job)
        if not canonical:
            print(f'Job "{args.job}" not found in this database.')
            # Helpful hint: show a few available jobs
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

        print(f"Database: {os.path.abspath(args.db)}")
        print(f"Job: {canonical}")
        print(f"Players with this job: {count} (of {total} total players with any job) = {pct:.2f}%")

        if args.list:
            players = list_players(conn, canonical, args.limit)
            if not players:
                print("\n(No user table found, or no players to list.)")
            else:
                print(f"\nPlayers ({len(players)} shown):")
                for username, uuid in players:
                    print(f" - {username} ({uuid})")

        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())

