#!/usr/bin/env python3
"""
Join HuggingFace Congressional speeches dataset to BioGuide IDs.

The HF dataset (Eugleo/us-congressional-speeches) has speaker first_name, last_name,
state, chamber, and date — but no BioGuide IDs. This script joins against the
congress-legislators database to assign bioguide_id to each speech.

Disambiguation strategy:
  1. Build lookup: (last_name_lower, state, chamber_type) → list of (bioguide_id, start, end)
  2. For each speech, find candidates matching (last_name, state, chamber)
  3. Filter candidates whose term dates overlap the speech date
  4. If exactly 1 match → assign. If 0 or >1 → try first_name disambiguation.
  5. Remaining ambiguous → mark as unmatched.

Usage:
    python join_bioguide.py
    python join_bioguide.py --dry-run   # stats only, no output
"""

import argparse
import json
import polars as pl
from pathlib import Path
from datetime import datetime
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
HF_CACHE = DATA_DIR / "hf_cache" / "datasets--Eugleo--us-congressional-speeches" / "snapshots"
LEGISLATORS_PATH = DATA_DIR / "legislators-all.json"

# HF dataset uses full state names (often truncated); legislators file uses 2-letter codes
STATE_NAME_TO_CODE = {
    "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR",
    "california": "CA", "colorado": "CO", "connecticut": "CT", "delaware": "DE",
    "florida": "FL", "georgia": "GA", "hawaii": "HI", "idaho": "ID",
    "illinois": "IL", "indiana": "IN", "iowa": "IA", "kansas": "KS",
    "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
    "massachusetts": "MA", "michigan": "MI", "minnesota": "MN", "mississippi": "MS",
    "missouri": "MO", "montana": "MT", "nebraska": "NE", "nevada": "NV",
    "new hampshire": "NH", "new jersey": "NJ", "new mexico": "NM", "new york": "NY",
    "north carolina": "NC", "north dakota": "ND", "ohio": "OH", "oklahoma": "OK",
    "oregon": "OR", "pennsylvania": "PA", "rhode island": "RI",
    "south carolina": "SC", "south dakota": "SD", "tennessee": "TN", "texas": "TX",
    "utah": "UT", "vermont": "VT", "virginia": "VA", "washington": "WA",
    "west virginia": "WV", "wisconsin": "WI", "wyoming": "WY",
    "district of columbia": "DC", "puerto rico": "PR", "guam": "GU",
    "american samoa": "AS", "virgin islands": "VI",
    "northern mariana islands": "MP",
}

# Build prefix lookup for truncated state names (e.g., "Cali" → "CA")
_STATE_PREFIX_LOOKUP = {}
for name, code in STATE_NAME_TO_CODE.items():
    for length in range(4, len(name) + 1):
        prefix = name[:length]
        if prefix not in _STATE_PREFIX_LOOKUP:
            _STATE_PREFIX_LOOKUP[prefix] = code
        else:
            # Ambiguous prefix — remove it (e.g., "new" matches multiple states)
            if _STATE_PREFIX_LOOKUP[prefix] != code:
                _STATE_PREFIX_LOOKUP[prefix] = None


def normalize_state(state_str: str) -> str | None:
    """Convert full state name (or truncated form) to 2-letter code."""
    if not state_str or state_str == "Unknown":
        return None

    s = state_str.strip().lower()

    # Already a 2-letter code?
    if len(s) == 2 and s.upper() in {v for v in STATE_NAME_TO_CODE.values()}:
        return s.upper()

    # Exact match
    if s in STATE_NAME_TO_CODE:
        return STATE_NAME_TO_CODE[s]

    # Prefix match (for truncated names like "Cali", "Arizo", "Flor")
    code = _STATE_PREFIX_LOOKUP.get(s)
    if code:
        return code

    return None


def build_legislator_lookup(legislators_path: Path) -> tuple[dict, dict, dict]:
    """Build lookups from legislator data.

    Returns:
        lookup: (last_name_lower, state_code, chamber_type) → candidates
        lookup_no_state: (last_name_lower, chamber_type) → candidates
        bioguide_to_party: bioguide_id → party string

    Each candidate is (bioguide_id, first_name_lower, term_start, term_end).
    """
    with open(legislators_path) as f:
        legislators = json.load(f)

    lookup = defaultdict(list)
    lookup_no_state = defaultdict(list)
    bioguide_to_party = {}

    for leg in legislators:
        bioguide = leg["id"].get("bioguide")
        if not bioguide:
            continue

        last = leg["name"]["last"].lower()
        first = leg["name"]["first"].lower()

        for term in leg["terms"]:
            state = term["state"]  # already 2-letter code
            chamber_type = term["type"]  # 'rep' or 'sen'
            start = datetime.strptime(term["start"], "%Y-%m-%d")
            end = datetime.strptime(term["end"], "%Y-%m-%d")
            party = term.get("party", "Unknown")

            entry = (bioguide, first, start, end)
            lookup[(last, state, chamber_type)].append(entry)
            lookup_no_state[(last, chamber_type)].append(entry)

            bioguide_to_party[bioguide] = party

    return dict(lookup), dict(lookup_no_state), bioguide_to_party


def _disambiguate_by_name(candidates: list, first_name: str) -> str | None:
    """Try to disambiguate multiple candidates using first name."""
    if not first_name or first_name == "Unknown":
        return None
    first_lower = first_name.lower()

    # Exact first name match
    name_match = [c for c in candidates if c[1] == first_lower]
    if len(name_match) == 1:
        return name_match[0][0]

    # Prefix match (e.g., "Bob" vs "Robert")
    if len(first_lower) >= 3:
        prefix_match = [c for c in candidates
                        if c[1].startswith(first_lower[:3]) or first_lower.startswith(c[1][:3])]
        if len(prefix_match) == 1:
            return prefix_match[0][0]

    return None


def match_speech_to_bioguide(
    last_name: str,
    first_name: str,
    state: str,
    chamber: str,
    date: datetime,
    lookup: dict,
    lookup_no_state: dict,
) -> str | None:
    """Match a single speech to a BioGuide ID.

    Returns bioguide_id or None if no match / ambiguous.
    """
    if not last_name or last_name == "Unknown":
        return None

    # Map HF chamber codes to legislator types
    chamber_type = "rep" if chamber == "H" else "sen" if chamber == "S" else None
    if not chamber_type:
        return None

    from datetime import timedelta
    grace = timedelta(days=30)

    # Normalize last name: handle hyphenated (JACKSON-LEE → Jackson Lee),
    # apostrophe variants (DAMATO → D'Amato), prefix variants (HOLLEN → Van Hollen)
    last_lower = last_name.lower()
    # Try original name, then with hyphen→space, then parts
    last_variants = [last_lower]
    if "-" in last_lower:
        last_variants.append(last_lower.replace("-", " "))
        # Try just the last part (e.g., "jackson-lee" → "lee")
        last_variants.append(last_lower.split("-")[-1])

    # Normalize state from full name to 2-letter code
    state_code = normalize_state(state)

    # Try each name variant with state
    if state_code:
        for variant in last_variants:
            key = (variant, state_code, chamber_type)
            candidates = lookup.get(key, [])
            if not candidates:
                continue

            active = [(bid, fn, s, e) for bid, fn, s, e in candidates
                      if s - grace <= date <= e + grace]

            if len(active) == 1:
                return active[0][0]

            if len(active) > 1:
                result = _disambiguate_by_name(active, first_name)
                if result:
                    return result

    # Fallback: match by (last_name, chamber) without state
    for variant in last_variants:
        key_no_state = (variant, chamber_type)
        candidates = lookup_no_state.get(key_no_state, [])

        if not candidates:
            continue

        active = [(bid, fn, s, e) for bid, fn, s, e in candidates
                  if s - grace <= date <= e + grace]

        if len(active) == 1:
            return active[0][0]

        if len(active) > 1:
            result = _disambiguate_by_name(active, first_name)
            if result:
                return result

    return None


def process_all_shards(lookup: dict, lookup_no_state: dict,
                       dry_run: bool = False) -> pl.DataFrame | None:
    """Process all HF Parquet shards, joining BioGuide IDs."""
    snapshot_dir = next(HF_CACHE.iterdir())
    shards = sorted(snapshot_dir.glob("data/train-*.parquet"))
    print(f"Found {len(shards)} shards")

    matched = 0
    unmatched = 0
    skipped = 0  # non-floor or pre-1994
    total = 0
    all_frames = []

    for i, shard_path in enumerate(shards):
        df = pl.read_parquet(shard_path)
        total += len(df)

        # Filter to post-1994 floor speeches
        df_floor = df.filter(
            (pl.col("date") >= pl.datetime(1994, 1, 1)) &
            (pl.col("chamber").is_in(["H", "S"]))
        )
        skipped += len(df) - len(df_floor)

        if len(df_floor) == 0:
            print(f"  Shard {i:2d}: {len(df):>8,} rows, 0 post-1994 floor → skip")
            continue

        # Join BioGuide IDs row by row
        bioguide_ids = []
        for row in df_floor.iter_rows(named=True):
            bid = match_speech_to_bioguide(
                last_name=row["last_name"],
                first_name=row["first_name"],
                state=row["state"],
                chamber=row["chamber"],
                date=row["date"],
                lookup=lookup,
                lookup_no_state=lookup_no_state,
            )
            bioguide_ids.append(bid)
            if bid:
                matched += 1
            else:
                unmatched += 1

        df_out = df_floor.with_columns(
            pl.Series("bioguide_id", bioguide_ids)
        )
        all_frames.append(df_out)

        match_rate = matched / (matched + unmatched) * 100 if (matched + unmatched) > 0 else 0
        print(f"  Shard {i:2d}: {len(df_floor):>8,} floor speeches, "
              f"running match rate: {match_rate:.1f}%")

    print(f"\n--- Join Summary ---")
    print(f"Total rows: {total:,}")
    print(f"Post-1994 floor (H+S): {matched + unmatched:,}")
    print(f"Matched to BioGuide: {matched:,} ({matched/(matched+unmatched)*100:.1f}%)")
    print(f"Unmatched: {unmatched:,}")
    print(f"Skipped (pre-1994 or Extensions): {skipped:,}")

    if dry_run or not all_frames:
        return None

    return pl.concat(all_frames)


def build_speaker_registry(df: pl.DataFrame, bioguide_to_party: dict) -> list[dict]:
    """Build a registry of all unique speakers in the corpus."""
    speakers = (
        df.filter(pl.col("bioguide_id").is_not_null())
        .group_by("bioguide_id")
        .agg([
            pl.col("last_name").first(),
            pl.col("first_name").first(),
            pl.col("state").first(),
            pl.col("chamber").first(),
            pl.len().alias("n_speeches"),
            pl.col("word_count").sum().alias("total_words"),
            pl.col("date").min().alias("first_speech"),
            pl.col("date").max().alias("last_speech"),
        ])
        .sort("n_speeches", descending=True)
    )

    registry = []
    for row in speakers.iter_rows(named=True):
        registry.append({
            "bioguide_id": row["bioguide_id"],
            "last_name": row["last_name"],
            "first_name": row["first_name"],
            "state": row["state"],
            "chamber": row["chamber"],
            "party": bioguide_to_party.get(row["bioguide_id"], "Unknown"),
            "n_speeches": row["n_speeches"],
            "total_words": row["total_words"],
            "first_speech": row["first_speech"].strftime("%Y-%m-%d"),
            "last_speech": row["last_speech"].strftime("%Y-%m-%d"),
        })

    return registry


def main():
    parser = argparse.ArgumentParser(description="Join HF speeches to BioGuide IDs")
    parser.add_argument("--dry-run", action="store_true", help="Stats only, no output")
    args = parser.parse_args()

    print("Loading legislator database...")
    lookup, lookup_no_state, bioguide_to_party = build_legislator_lookup(LEGISLATORS_PATH)
    n_entries = sum(len(v) for v in lookup.values())
    print(f"  {len(lookup)} unique (name, state, chamber) keys, {n_entries} term entries")
    print(f"  {len(lookup_no_state)} unique (name, chamber) keys (fallback)")

    print("\nProcessing HuggingFace shards...")
    df = process_all_shards(lookup, lookup_no_state, dry_run=args.dry_run)

    if args.dry_run:
        return

    if df is None or len(df) == 0:
        print("No data to write!")
        return

    # Save joined dataset
    out_path = DATA_DIR / "hf_speeches_with_bioguide.parquet"
    df.write_parquet(out_path)
    print(f"\nSaved joined dataset: {out_path} ({len(df):,} rows)")

    # Save speaker registry
    registry = build_speaker_registry(df, bioguide_to_party)
    registry_path = DATA_DIR / "speaker_registry.json"
    with open(registry_path, "w") as f:
        json.dump(registry, f, indent=2)
    print(f"Saved speaker registry: {registry_path} ({len(registry)} speakers)")


if __name__ == "__main__":
    main()
