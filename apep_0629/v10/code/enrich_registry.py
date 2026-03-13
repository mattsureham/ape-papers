#!/usr/bin/env python3
"""
Enrich speaker registry with party/state/name metadata from legislators-all.json.

The 620 GovInfo-only speakers have party="Unknown". This script looks up their
BioGuide IDs in the congress-legislators dataset to fill in party, state, and name.

For speakers with multiple terms, we use their most recent term's party/state.

Usage:
    python enrich_registry.py
    python enrich_registry.py --dry-run  # preview changes without saving
"""

import argparse
import json
from collections import Counter
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"


def load_bioguide_index(legislators_path: Path) -> dict:
    """Build BioGuide ID → legislator info index."""
    with open(legislators_path) as f:
        legs = json.load(f)

    index = {}
    for entry in legs:
        bid = entry["id"]["bioguide"]
        name = entry.get("name", {})
        terms = entry.get("terms", [])
        if not terms:
            continue

        # Use most recent term for party/state
        last_term = terms[-1]
        # For name, prefer official_full, fall back to first+last
        full_name = name.get("official_full") or f"{name.get('first', '')} {name.get('last', '')}".strip()

        index[bid] = {
            "name": full_name,
            "first_name": name.get("first", ""),
            "last_name": name.get("last", ""),
            "party": last_term.get("party", "Unknown"),
            "state": last_term.get("state", "Unknown"),
            "chamber": "S" if last_term.get("type") == "sen" else "H",
            "n_terms": len(terms),
        }

    return index


def enrich_registry(registry: list[dict], bio_index: dict, dry_run: bool = False) -> tuple[list[dict], dict]:
    """Enrich Unknown-party speakers using BioGuide index."""
    stats = Counter()

    for entry in registry:
        if entry.get("party") != "Unknown":
            stats["already_known"] += 1
            continue

        bid = entry["bioguide_id"]
        if bid not in bio_index:
            stats["not_in_bioguide"] += 1
            continue

        info = bio_index[bid]
        entry["name"] = info["name"]
        entry["first_name"] = info["first_name"]
        entry["last_name"] = info["last_name"]
        entry["party"] = info["party"]
        entry["state"] = info["state"]
        entry["chamber"] = info["chamber"]
        stats["enriched"] += 1

    # Count remaining unknowns
    still_unknown = sum(1 for e in registry if e.get("party") == "Unknown")
    stats["still_unknown"] = still_unknown

    return registry, dict(stats)


def main():
    parser = argparse.ArgumentParser(description="Enrich speaker registry")
    parser.add_argument("--dry-run", action="store_true", help="Preview without saving")
    args = parser.parse_args()

    registry_path = DATA_DIR / "speaker_registry.json"
    legislators_path = DATA_DIR / "legislators-all.json"

    with open(registry_path) as f:
        registry = json.load(f)

    unknown_before = sum(1 for e in registry if e.get("party") == "Unknown")
    print(f"Registry: {len(registry)} speakers, {unknown_before} with Unknown party")

    bio_index = load_bioguide_index(legislators_path)
    print(f"BioGuide index: {len(bio_index)} legislators")

    registry, stats = enrich_registry(registry, bio_index, dry_run=args.dry_run)

    print(f"\nResults:")
    for k, v in sorted(stats.items()):
        print(f"  {k}: {v}")

    # Party distribution after enrichment
    parties = Counter(e.get("party", "Unknown") for e in registry)
    print(f"\nParty distribution:")
    for party, count in parties.most_common():
        print(f"  {party}: {count}")

    if not args.dry_run:
        with open(registry_path, "w") as f:
            json.dump(registry, f, indent=2)
        print(f"\nSaved enriched registry to {registry_path}")
    else:
        print(f"\n[DRY RUN] Would save to {registry_path}")


if __name__ == "__main__":
    main()
