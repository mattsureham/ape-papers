#!/usr/bin/env python3
"""
Phase 0: Download and parse Congressional Record data.

Downloads GovInfo CREC data day-by-day, parses via unitedstates/congressional-record
parser, and extracts turn-structured debates.

Usage:
    # Parse a single day (smoke test)
    python download_and_parse.py --start 2023-03-15 --end 2023-03-15

    # Parse a full year
    python download_and_parse.py --start 2023-01-01 --end 2023-12-31

    # Parse the full corpus (1994-2024) — takes hours due to rate limits
    python download_and_parse.py --start 1994-01-01 --end 2024-12-31

    # Resume from where you left off (skips already-parsed days)
    python download_and_parse.py --start 1994-01-01 --end 2024-12-31 --resume

Output:
    data/raw/         — Raw JSON files from parser (one dir per day)
    data/debates.parquet  — Structured debates with turn-level data
    data/corpus_stats.json — Corpus statistics
"""

import argparse
import json
import glob
import os
import sys
import time
import re
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict

# Add parser to path
PARSER_DIR = Path(__file__).parent.parent.parent / "_parser"
sys.path.insert(0, str(PARSER_DIR))

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
VENV_PYTHON = PARSER_DIR / ".venv" / "bin" / "python"


def parse_single_day(date_str: str, output_dir: Path, max_retries: int = 3) -> bool:
    """Download and parse a single day of Congressional Record.

    Uses the unitedstates/congressional-record parser CLI.
    Returns True if successful, False if no data for that day.
    """
    import subprocess

    year = date_str[:4]
    day_dir = output_dir / year / f"CREC-{date_str}"

    # Check if already parsed
    json_dir = day_dir / "json"
    if json_dir.exists() and list(json_dir.glob("*.json")):
        return True

    for attempt in range(max_retries):
        try:
            result = subprocess.run(
                [str(VENV_PYTHON), "-m", "congressionalrecord.cli",
                 date_str, date_str, "json"],
                capture_output=True, text=True, timeout=120,
                cwd=str(PARSER_DIR)
            )

            # Check for rate limiting
            if "429" in result.stderr or "Retry-After" in result.stderr:
                wait = 30 * (attempt + 1)
                print(f"  Rate limited on {date_str}, waiting {wait}s...")
                time.sleep(wait)
                continue

            # Move output to our data dir
            parser_output = PARSER_DIR / "output" / year / f"CREC-{date_str}"
            if parser_output.exists():
                day_dir.parent.mkdir(parents=True, exist_ok=True)
                if not day_dir.exists():
                    parser_output.rename(day_dir)
                return True
            else:
                # No Congressional Record for this day (weekend, recess, etc.)
                return False

        except subprocess.TimeoutExpired:
            print(f"  Timeout on {date_str}, attempt {attempt + 1}/{max_retries}")
            time.sleep(10)
        except Exception as e:
            print(f"  Error on {date_str}: {e}")
            time.sleep(10)

    return False


def extract_debates_from_day(day_dir: Path) -> list[dict]:
    """Extract structured debates from a day's parsed JSON files.

    Each JSON file is one topic/segment. We extract turn-level data
    and stitch them into debate objects.
    """
    json_dir = day_dir / "json"
    if not json_dir.exists():
        return []

    debates = []

    for json_path in sorted(json_dir.glob("*.json")):
        try:
            with open(json_path) as f:
                data = json.load(f)
        except (json.JSONDecodeError, IOError):
            continue

        header = data.get("header", {})

        # Skip Extensions of Remarks (not spoken on floor)
        if header.get("extension", False):
            continue

        chamber = header.get("chamber", "Unknown")
        if chamber not in ("House", "Senate"):
            continue

        # Extract page number for ordering within the day
        pages = header.get("pages", "")
        page_num = _extract_page_number(pages)

        # Extract date from directory name
        date_str = day_dir.name.replace("CREC-", "")

        # Extract turns
        content = data.get("content", [])
        turns = []

        for item in content:
            turn_num = item.get("turn", -1)
            if turn_num < 0:
                continue

            speaker = item.get("speaker", "Unknown")
            bioguide = item.get("speaker_bioguide", None)
            kind = item.get("kind", "speech")

            # Get text
            text = item.get("speaking", item.get("text", ""))
            if isinstance(text, list):
                text = "\n".join(text)
            text = str(text).strip()

            if not text:
                continue

            # Classify turn type
            is_presiding = _is_presiding_officer(speaker)

            turns.append({
                "turn_num": turn_num,
                "speaker": speaker,
                "speaker_bioguide": bioguide,
                "text": text,
                "is_presiding": is_presiding,
                "kind": kind,
                "word_count": len(text.split()),
            })

        if not turns:
            continue

        # Count substantive turns (non-presiding, >10 words)
        substantive_turns = [t for t in turns
                           if not t["is_presiding"] and t["word_count"] > 10]
        unique_speakers = len(set(t["speaker_bioguide"] for t in substantive_turns
                                  if t["speaker_bioguide"]))

        debate = {
            "debate_id": json_path.stem,
            "date": date_str,
            "chamber": chamber,
            "page_num": page_num,
            "title": str(data.get("title") or data.get("doc_title") or ""),
            "related_bills": data.get("related_bills", []),
            "n_turns": len(turns),
            "n_substantive_turns": len(substantive_turns),
            "n_unique_speakers": unique_speakers,
            "turns": turns,
        }

        debates.append(debate)

    return debates


def _extract_page_number(pages_str: str) -> int:
    """Extract numeric page number from CREC page string (e.g., 'H1430' → 1430)."""
    match = re.search(r'[HSE](\d+)', str(pages_str))
    return int(match.group(1)) if match else 0


def _is_presiding_officer(speaker: str) -> bool:
    """Check if speaker is a presiding officer (institutional, not individual)."""
    presiding_patterns = [
        "The PRESIDING OFFICER",
        "The SPEAKER",
        "The CHAIR",
        "The VICE PRESIDENT",
        "The CLERK",
        "The CHIEF JUSTICE",
        "ACTING CHAIR",
        "SPEAKER pro tempore",
    ]
    speaker_upper = speaker.upper() if speaker else ""
    return any(p.upper() in speaker_upper for p in presiding_patterns)


def format_debate_as_conversation(debate: dict) -> str:
    """Format a debate as a multi-turn conversation string.

    Output format:
        <|bos|><|chamber:HOUSE|>
        <|speaker:P000197|> Mr. Speaker, I rise in opposition...
        <|presiding|> The gentlelady's time has expired.
        <|speaker:J000289|> I thank the gentlelady...
    """
    chamber = debate["chamber"].upper()
    lines = [f"<|bos|><|chamber:{chamber}|>"]

    for turn in debate["turns"]:
        if turn["is_presiding"]:
            lines.append(f"<|presiding|> {turn['text']}")
        elif turn["speaker_bioguide"]:
            lines.append(f"<|speaker:{turn['speaker_bioguide']}|> {turn['text']}")
        else:
            # Speaker without BioGuide ID — skip or use name
            # For now, skip (these are often procedural)
            continue

    return "\n".join(lines)


def compute_corpus_stats(all_debates: list[dict]) -> dict:
    """Compute summary statistics for the corpus."""
    stats = {
        "n_debates": len(all_debates),
        "n_days": len(set(d["date"] for d in all_debates)),
        "date_range": {
            "first": min(d["date"] for d in all_debates) if all_debates else None,
            "last": max(d["date"] for d in all_debates) if all_debates else None,
        },
        "by_chamber": defaultdict(int),
        "total_turns": 0,
        "total_substantive_turns": 0,
        "total_words": 0,
        "unique_speakers": set(),
        "turns_per_debate": [],
        "by_year": defaultdict(lambda: {"debates": 0, "turns": 0, "speakers": set()}),
    }

    for d in all_debates:
        stats["by_chamber"][d["chamber"]] += 1
        stats["total_turns"] += d["n_turns"]
        stats["total_substantive_turns"] += d["n_substantive_turns"]
        stats["turns_per_debate"].append(d["n_substantive_turns"])

        year = d["date"][:4]
        stats["by_year"][year]["debates"] += 1
        stats["by_year"][year]["turns"] += d["n_substantive_turns"]

        for t in d["turns"]:
            stats["total_words"] += t["word_count"]
            if t["speaker_bioguide"] and not t["is_presiding"]:
                stats["unique_speakers"].add(t["speaker_bioguide"])
                stats["by_year"][year]["speakers"].add(t["speaker_bioguide"])

    # Convert sets to counts for JSON serialization
    stats["n_unique_speakers"] = len(stats["unique_speakers"])
    del stats["unique_speakers"]

    for year in stats["by_year"]:
        stats["by_year"][year]["n_speakers"] = len(stats["by_year"][year]["speakers"])
        del stats["by_year"][year]["speakers"]

    stats["by_chamber"] = dict(stats["by_chamber"])
    stats["by_year"] = dict(stats["by_year"])

    # Summary stats on turns per debate
    tpd = stats["turns_per_debate"]
    if tpd:
        tpd.sort()
        stats["turns_per_debate_summary"] = {
            "mean": sum(tpd) / len(tpd),
            "median": tpd[len(tpd) // 2],
            "p25": tpd[len(tpd) // 4],
            "p75": tpd[3 * len(tpd) // 4],
            "max": tpd[-1],
        }
    del stats["turns_per_debate"]

    return stats


def daterange(start: str, end: str):
    """Generate dates between start and end (inclusive), skipping weekends."""
    start_dt = datetime.strptime(start, "%Y-%m-%d")
    end_dt = datetime.strptime(end, "%Y-%m-%d")

    current = start_dt
    while current <= end_dt:
        # Skip weekends (Congress rarely in session)
        if current.weekday() < 5:  # Mon-Fri
            yield current.strftime("%Y-%m-%d")
        current += timedelta(days=1)


def main():
    parser = argparse.ArgumentParser(description="Download and parse Congressional Record")
    parser.add_argument("--start", required=True, help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end", required=True, help="End date (YYYY-MM-DD)")
    parser.add_argument("--resume", action="store_true", help="Skip already-parsed days")
    parser.add_argument("--stats-only", action="store_true", help="Just compute stats on existing data")
    parser.add_argument("--format-only", action="store_true", help="Just format existing data for training")
    args = parser.parse_args()

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    if not args.stats_only and not args.format_only:
        # Phase 0.1-0.2: Download and parse
        dates = list(daterange(args.start, args.end))
        print(f"Processing {len(dates)} weekdays from {args.start} to {args.end}")

        parsed = 0
        skipped = 0
        failed = 0

        for i, date_str in enumerate(dates):
            if args.resume:
                year = date_str[:4]
                day_dir = RAW_DIR / year / f"CREC-{date_str}"
                if (day_dir / "json").exists():
                    skipped += 1
                    continue

            success = parse_single_day(date_str, RAW_DIR)
            if success:
                parsed += 1
            else:
                failed += 1

            if (i + 1) % 50 == 0:
                print(f"  Progress: {i+1}/{len(dates)} days "
                      f"(parsed={parsed}, skipped={skipped}, no_data={failed})")

            # Be polite to GovInfo API
            time.sleep(1)

        print(f"\nDownload complete: {parsed} parsed, {skipped} skipped, {failed} no data")

    # Phase 0.3: Extract debates from all parsed days
    print("\nExtracting debates from parsed JSON files...")
    all_debates = []

    for year_dir in sorted(RAW_DIR.iterdir()):
        if not year_dir.is_dir():
            continue
        for day_dir in sorted(year_dir.iterdir()):
            if not day_dir.is_dir() or not day_dir.name.startswith("CREC-"):
                continue
            debates = extract_debates_from_day(day_dir)
            all_debates.extend(debates)

    print(f"Extracted {len(all_debates)} debates from {len(set(d['date'] for d in all_debates))} days")

    # Phase 0.4: Compute corpus statistics
    stats = compute_corpus_stats(all_debates)
    stats_path = DATA_DIR / "corpus_stats.json"
    with open(stats_path, "w") as f:
        json.dump(stats, f, indent=2)
    print(f"\nCorpus statistics saved to {stats_path}")
    print(f"  Debates: {stats['n_debates']}")
    print(f"  Total turns: {stats['total_turns']}")
    print(f"  Substantive turns: {stats['total_substantive_turns']}")
    print(f"  Total words: {stats['total_words']:,}")
    print(f"  Unique speakers: {stats['n_unique_speakers']}")
    print(f"  By chamber: {stats['by_chamber']}")
    if stats.get("turns_per_debate_summary"):
        s = stats["turns_per_debate_summary"]
        print(f"  Turns/debate: mean={s['mean']:.1f}, median={s['median']}, "
              f"p75={s['p75']}, max={s['max']}")

    # Phase 0.5: Format for training
    if not args.stats_only:
        print("\nFormatting debates as conversations...")
        conversations_dir = DATA_DIR / "conversations"
        conversations_dir.mkdir(parents=True, exist_ok=True)

        # Group by year and write conversation files
        by_year = defaultdict(list)
        for debate in all_debates:
            year = debate["date"][:4]
            by_year[year].append(debate)

        total_convos = 0
        for year, debates in sorted(by_year.items()):
            # Filter to multi-turn debates (≥2 substantive turns)
            multi_turn = [d for d in debates if d["n_substantive_turns"] >= 2]

            conversations = []
            for debate in multi_turn:
                conv_text = format_debate_as_conversation(debate)
                conversations.append({
                    "debate_id": debate["debate_id"],
                    "date": debate["date"],
                    "chamber": debate["chamber"],
                    "title": debate["title"],
                    "n_turns": debate["n_substantive_turns"],
                    "n_speakers": debate["n_unique_speakers"],
                    "text": conv_text,
                    "word_count": sum(t["word_count"] for t in debate["turns"]),
                })

            # Write as JSONL (one conversation per line)
            out_path = conversations_dir / f"conversations_{year}.jsonl"
            with open(out_path, "w") as f:
                for conv in conversations:
                    f.write(json.dumps(conv) + "\n")

            total_convos += len(conversations)
            print(f"  {year}: {len(conversations)} multi-turn conversations "
                  f"(from {len(debates)} total debates)")

        print(f"\nTotal multi-turn conversations: {total_convos}")
        print(f"Saved to {conversations_dir}/")

    # Print year-by-year summary
    print("\n--- Year-by-Year Summary ---")
    print(f"{'Year':>6} {'Debates':>8} {'Turns':>8} {'Speakers':>10}")
    for year in sorted(stats.get("by_year", {}).keys()):
        y = stats["by_year"][year]
        print(f"{year:>6} {y['debates']:>8} {y['turns']:>8} {y['n_speakers']:>10}")


if __name__ == "__main__":
    main()
