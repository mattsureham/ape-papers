#!/usr/bin/env python3
"""
Build conversations from GovInfo parsed JSON files (2011-2024).

Reads the raw JSON output from download_and_parse.py, extracts debates,
formats as conversations with special tokens, and outputs a Parquet file
matching the schema of hf_conversations.parquet.

Usage:
    python build_conversations_govinfo.py
    python build_conversations_govinfo.py --year-start 2020 --year-end 2024
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

import polars as pl

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"

# Import helpers from download_and_parse
sys.path.insert(0, str(Path(__file__).parent))
from download_and_parse import (
    extract_debates_from_day,
    format_debate_as_conversation,
)


def process_all_years(year_start: int = 2011, year_end: int = 2024) -> pl.DataFrame:
    """Process GovInfo JSON for specified year range into conversations."""
    all_rows = []
    conv_counter = defaultdict(int)

    for year in range(year_start, year_end + 1):
        year_dir = RAW_DIR / str(year)
        if not year_dir.exists():
            print(f"  {year}: directory not found, skipping")
            continue

        day_dirs = sorted(d for d in year_dir.iterdir()
                         if d.is_dir() and d.name.startswith("CREC-"))

        year_debates = 0
        year_convos = 0
        year_words = 0

        for day_dir in day_dirs:
            debates = extract_debates_from_day(day_dir)
            date_str = day_dir.name.replace("CREC-", "")

            for debate in debates:
                # Filter: need ≥2 substantive turns
                if debate["n_substantive_turns"] < 2:
                    continue

                conv_text = format_debate_as_conversation(debate)

                # Collect speaker BioGuide IDs
                speaker_ids = sorted(set(
                    t["speaker_bioguide"] for t in debate["turns"]
                    if t["speaker_bioguide"] and not t["is_presiding"]
                ))

                if not speaker_ids:
                    continue

                chamber = "H" if debate["chamber"] == "House" else "S"
                conv_key = f"{date_str}_{chamber}"
                conv_id = f"{conv_key}_{conv_counter[conv_key]:04d}"
                conv_counter[conv_key] += 1

                word_count = sum(t["word_count"] for t in debate["turns"])

                all_rows.append({
                    "conversation_id": conv_id,
                    "date": date_str,
                    "year": year,
                    "chamber": chamber,
                    "text": conv_text,
                    "n_turns": debate["n_turns"],
                    "n_substantive_turns": debate["n_substantive_turns"],
                    "n_speakers": len(speaker_ids),
                    "speaker_ids": json.dumps(speaker_ids),
                    "word_count": word_count,
                })

                year_debates += 1
                year_words += word_count

            year_convos = len([r for r in all_rows if r["year"] == year])

        print(f"  {year}: {year_convos} conversations, "
              f"{year_words:,} words from {len(day_dirs)} days")

    df = pl.DataFrame(all_rows)
    return df


def main():
    parser = argparse.ArgumentParser(
        description="Build conversations from GovInfo JSON"
    )
    parser.add_argument("--year-start", type=int, default=2011)
    parser.add_argument("--year-end", type=int, default=2024)
    args = parser.parse_args()

    print(f"Building conversations from GovInfo JSON ({args.year_start}-{args.year_end})...")
    df = process_all_years(args.year_start, args.year_end)

    if len(df) == 0:
        print("ERROR: No conversations extracted!")
        return

    print(f"\nTotal: {len(df):,} conversations, "
          f"{df['word_count'].sum():,} words")
    print(f"Speakers per conversation: "
          f"mean={df['n_speakers'].mean():.1f}, "
          f"median={df['n_speakers'].median():.0f}")
    print(f"Turns per conversation: "
          f"mean={df['n_substantive_turns'].mean():.1f}, "
          f"median={df['n_substantive_turns'].median():.0f}")

    # Save
    out_path = DATA_DIR / "govinfo_conversations.parquet"
    df.write_parquet(out_path)
    print(f"\nSaved to {out_path} ({os.path.getsize(out_path) / 1e9:.1f} GB)")

    # Collect unique speakers for registry update
    all_speakers = set()
    for ids_json in df["speaker_ids"].to_list():
        all_speakers.update(json.loads(ids_json))
    print(f"Unique speakers: {len(all_speakers)}")


if __name__ == "__main__":
    main()
