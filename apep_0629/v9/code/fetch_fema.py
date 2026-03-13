#!/usr/bin/env python3
"""
Fetch FEMA disaster declarations (2015-2024) from OpenFEMA API.

No API key required. Filters to major disaster declarations (type DR).

Output: data/fema_disasters.parquet

Usage:
    python fetch_fema.py
"""

from pathlib import Path

import polars as pl
import requests

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"

FEMA_URL = "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries"


def fetch_disasters(start_year: int = 2015, end_year: int = 2024) -> pl.DataFrame:
    """Fetch major disaster declarations from OpenFEMA API (with pagination)."""
    all_records = []
    skip = 0
    page_size = 1000

    print(f"Fetching FEMA disasters {start_year}-{end_year}...")
    while True:
        params = {
            "$filter": (
                f"fyDeclared ge {start_year} and fyDeclared le {end_year + 1} "
                f"and declarationType eq 'DR'"
            ),
            "$select": (
                "disasterNumber,declarationDate,state,fipsStateCode,"
                "incidentType,declarationTitle,fyDeclared"
            ),
            "$orderby": "declarationDate asc",
            "$top": page_size,
            "$skip": skip,
        }

        resp = requests.get(FEMA_URL, params=params, timeout=60)
        resp.raise_for_status()
        data = resp.json()

        records = data.get("DisasterDeclarationsSummaries", [])
        if not records:
            break
        all_records.extend(records)
        print(f"  Page {skip // page_size + 1}: {len(records)} records (total: {len(all_records)})")
        skip += page_size

    records = all_records
    print(f"  Got {len(records)} total records")

    df = pl.DataFrame(records)

    # Parse date and deduplicate by disaster number (multiple counties per disaster)
    df = (
        df.with_columns(
            pl.col("declarationDate").str.slice(0, 10).str.to_date().alias("date"),
        )
        .group_by("disasterNumber")
        .agg(
            pl.col("date").first(),
            pl.col("state").first(),
            pl.col("fipsStateCode").first(),
            pl.col("incidentType").first(),
            pl.col("declarationTitle").first(),
        )
        .sort("date")
    )

    # Filter to actual date range (fyDeclared is fiscal year, not calendar)
    df = df.filter(
        (pl.col("date").dt.year() >= start_year)
        & (pl.col("date").dt.year() <= end_year)
    )

    print(f"  {len(df)} unique major disasters after dedup")
    print(f"  Date range: {df['date'].min()} to {df['date'].max()}")
    print(f"  Top incident types:")
    for row in df.group_by("incidentType").len().sort("len", descending=True).head(10).iter_rows():
        print(f"    {row[0]}: {row[1]}")

    return df


def main():
    df = fetch_disasters()
    out_path = DATA_DIR / "fema_disasters.parquet"
    df.write_parquet(out_path)
    print(f"\nSaved {len(df)} disasters to {out_path}")


if __name__ == "__main__":
    main()
