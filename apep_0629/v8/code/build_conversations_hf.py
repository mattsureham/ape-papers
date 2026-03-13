#!/usr/bin/env python3
"""
Reconstruct multi-turn debate conversations from HuggingFace Congressional speeches.

The HF dataset has individual speeches with `number_within_file` ordering and `file`
grouping. This script reconstructs debate boundaries and builds conversation objects.

Debate boundary detection:
  - Same (date, chamber, file) = same session day
  - Within a file, speeches are ordered by number_within_file
  - Debate boundaries detected by: gap in number_within_file > 5, or speaker pattern
    reset (presiding officer re-enters after substantive debate)
  - Each debate = contiguous sequence of turns with ≥2 substantive speakers

Input: data/hf_speeches_with_bioguide.parquet (from join_bioguide.py)
Output: data/hf_conversations.parquet (one row per conversation)

Usage:
    python build_conversations_hf.py
    python build_conversations_hf.py --min-turns 3   # require ≥3 substantive turns
"""

import argparse
import json
import polars as pl
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"

# Presiding officer patterns (same as download_and_parse.py)
PRESIDING_PATTERNS = [
    "the presiding officer",
    "the speaker",
    "the chair",
    "the vice president",
    "the clerk",
    "the chief justice",
    "acting chair",
    "speaker pro tempore",
]


def is_presiding(speaker: str) -> bool:
    """Check if speaker string indicates a presiding officer."""
    if not speaker:
        return False
    s = speaker.lower()
    return any(p in s for p in PRESIDING_PATTERNS)


def detect_debate_boundaries(speeches: list[dict], gap_threshold: int = 5) -> list[list[dict]]:
    """Split a day's speeches into individual debates.

    Uses gaps in number_within_file to detect topic boundaries.
    A gap > gap_threshold between consecutive speeches = new debate.
    """
    if not speeches:
        return []

    # Sort by number_within_file
    speeches = sorted(speeches, key=lambda s: s["number_within_file"])

    debates = []
    current_debate = [speeches[0]]

    for i in range(1, len(speeches)):
        gap = speeches[i]["number_within_file"] - speeches[i-1]["number_within_file"]
        if gap > gap_threshold:
            debates.append(current_debate)
            current_debate = [speeches[i]]
        else:
            current_debate.append(speeches[i])

    if current_debate:
        debates.append(current_debate)

    return debates


def build_conversation(debate_speeches: list[dict], date: str, chamber: str,
                       debate_idx: int) -> dict | None:
    """Build a conversation object from a list of speeches in one debate.

    Returns None if debate doesn't meet quality criteria.
    """
    # Classify turns
    turns = []
    for speech in debate_speeches:
        speaker_str = speech.get("speaker", "")
        presiding = is_presiding(speaker_str)
        bioguide = speech.get("bioguide_id")
        text = (speech.get("text") or "").strip()
        word_count = speech.get("word_count", 0)

        if not text:
            continue

        turns.append({
            "speaker": speaker_str,
            "bioguide_id": bioguide,
            "is_presiding": presiding,
            "text": text,
            "word_count": word_count,
        })

    if not turns:
        return None

    # Count substantive turns (non-presiding, >10 words, with bioguide)
    substantive = [t for t in turns
                   if not t["is_presiding"] and t["word_count"] > 10 and t["bioguide_id"]]
    unique_speakers = set(t["bioguide_id"] for t in substantive)

    # Format as training text
    chamber_upper = "HOUSE" if chamber == "H" else "SENATE"
    lines = [f"<|bos|><|chamber:{chamber_upper}|>"]

    for turn in turns:
        if turn["is_presiding"]:
            lines.append(f"<|presiding|> {turn['text']}")
        elif turn["bioguide_id"]:
            lines.append(f"<|speaker:{turn['bioguide_id']}|> {turn['text']}")
        # Skip turns without bioguide (can't attribute)

    text = "\n".join(lines)

    return {
        "conversation_id": f"{date}_{chamber}_{debate_idx:04d}",
        "date": date,
        "year": int(date[:4]),
        "chamber": chamber,
        "text": text,
        "n_turns": len(turns),
        "n_substantive_turns": len(substantive),
        "n_speakers": len(unique_speakers),
        "speaker_ids": sorted(unique_speakers),
        "word_count": sum(t["word_count"] for t in turns),
    }


def main():
    parser = argparse.ArgumentParser(description="Build conversations from HF speeches")
    parser.add_argument("--min-turns", type=int, default=2,
                        help="Minimum substantive turns per conversation (default: 2)")
    parser.add_argument("--gap-threshold", type=int, default=5,
                        help="number_within_file gap to split debates (default: 5)")
    args = parser.parse_args()

    input_path = DATA_DIR / "hf_speeches_with_bioguide.parquet"
    if not input_path.exists():
        print(f"ERROR: {input_path} not found. Run join_bioguide.py first.")
        return

    print(f"Loading {input_path}...")
    df = pl.read_parquet(input_path)
    print(f"  {len(df):,} speeches loaded")

    # Group by (date, chamber) to process day-by-day
    groups = df.group_by(["date", "chamber"]).agg(pl.all()).sort("date")
    print(f"  {len(groups):,} (date, chamber) groups")

    conversations = []
    total_debates = 0

    for row in groups.iter_rows(named=True):
        date_dt = row["date"]
        date_str = date_dt.strftime("%Y-%m-%d")
        chamber = row["chamber"]

        # Reconstruct speeches list for this group
        n = len(row["speech_id"])
        speeches = []
        for i in range(n):
            speeches.append({
                "speech_id": row["speech_id"][i],
                "text": row["text"][i],
                "number_within_file": row["number_within_file"][i],
                "speaker": row["speaker"][i],
                "bioguide_id": row["bioguide_id"][i],
                "word_count": row["word_count"][i],
            })

        # Detect debate boundaries
        debates = detect_debate_boundaries(speeches, gap_threshold=args.gap_threshold)
        total_debates += len(debates)

        # Build conversations
        for idx, debate_speeches in enumerate(debates):
            conv = build_conversation(debate_speeches, date_str, chamber, idx)
            if conv and conv["n_substantive_turns"] >= args.min_turns:
                conversations.append(conv)

    print(f"\n--- Conversation Building Summary ---")
    print(f"Total debates detected: {total_debates:,}")
    print(f"Conversations with ≥{args.min_turns} substantive turns: {len(conversations):,}")

    if not conversations:
        print("No conversations found!")
        return

    # Convert to DataFrame (drop speaker_ids list for Parquet compatibility)
    for conv in conversations:
        conv["speaker_ids"] = json.dumps(conv["speaker_ids"])

    df_out = pl.DataFrame(conversations)

    # Year distribution
    year_stats = (
        df_out.group_by("year")
        .agg([
            pl.len().alias("n_conversations"),
            pl.col("n_speakers").mean().alias("avg_speakers"),
            pl.col("n_substantive_turns").mean().alias("avg_turns"),
            pl.col("word_count").sum().alias("total_words"),
        ])
        .sort("year")
    )

    print(f"\n{'Year':>6} {'Convos':>8} {'AvgSpk':>8} {'AvgTrn':>8} {'Words':>12}")
    for row in year_stats.iter_rows(named=True):
        print(f"{row['year']:>6} {row['n_conversations']:>8,} "
              f"{row['avg_speakers']:>8.1f} {row['avg_turns']:>8.1f} "
              f"{row['total_words']:>12,}")

    # Summary
    total_words = df_out["word_count"].sum()
    unique_speakers = set()
    for s in df_out["speaker_ids"].to_list():
        unique_speakers.update(json.loads(s))

    print(f"\nTotal conversations: {len(df_out):,}")
    print(f"Total words: {total_words:,}")
    print(f"Unique speakers: {len(unique_speakers):,}")
    print(f"Estimated BPE tokens (~1.3x words): {int(total_words * 1.3):,}")

    # Save
    out_path = DATA_DIR / "hf_conversations.parquet"
    df_out.write_parquet(out_path)
    print(f"\nSaved: {out_path}")


if __name__ == "__main__":
    main()
