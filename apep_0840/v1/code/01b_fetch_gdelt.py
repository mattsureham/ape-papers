"""01b_fetch_gdelt.py — Fetch GDELT competing news via DOC API v2
apep_0840: Competing News IV and Swiss Referendum Turnout

Uses GDELT DOC API timeline mode to get daily article volumes for:
1. Swiss political news (referendum, voting) by language
2. Foreign disaster news by language
"""

import csv
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

# Load vote dates from referendum data
def load_vote_dates():
    """Extract unique vote dates from referendum_raw.csv"""
    dates = set()
    with open(os.path.join(DATA_DIR, "referendum_raw.csv"), "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            dates.add(row["votedate"])
    return sorted(dates)


def query_gdelt_timeline(query, start_date, end_date, mode="timelinevol"):
    """Query GDELT DOC API v2 timeline mode.
    Returns list of (date, value) tuples.
    """
    base_url = "https://api.gdeltproject.org/api/v2/doc/doc"
    params = {
        "query": query,
        "mode": mode,
        "format": "csv",
        "startdatetime": start_date.strftime("%Y%m%d%H%M%S"),
        "enddatetime": end_date.strftime("%Y%m%d%H%M%S"),
        "timelinesmooth": "0",
    }
    url = f"{base_url}?{urllib.parse.urlencode(params)}"

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "APEP-Research/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            text = resp.read().decode("utf-8").strip()
            if not text:
                return []
            rows = []
            for line in text.split("\n"):
                parts = line.strip().split(",")
                if len(parts) >= 2:
                    try:
                        dt = datetime.strptime(parts[0].strip(), "%Y-%m-%dT%H:%M:%SZ")
                        val = float(parts[1].strip())
                        rows.append((dt.strftime("%Y-%m-%d"), val))
                    except (ValueError, IndexError):
                        continue
            return rows
    except Exception as e:
        print(f"  Warning: GDELT query failed: {e}")
        return []


def main():
    vote_dates = load_vote_dates()
    print(f"Processing {len(vote_dates)} vote dates")

    # Define queries for each language × content type
    # Swiss political articles by language
    queries = {
        # Swiss political news
        "swiss_political_fr": '(referendum OR votation OR "initiative populaire" OR "conseil federal") sourcelang:french',
        "swiss_political_de": '(Abstimmung OR Volksinitiative OR Referendum OR Bundesrat) sourcelang:german',
        # Foreign disaster articles (non-Swiss)
        "disaster_fr": '(catastrophe OR seisme OR inondation OR ouragan OR attentat OR tsunami OR eruption) NOT suisse NOT geneve NOT zurich sourcelang:french',
        "disaster_de": '(Katastrophe OR Erdbeben OR Überschwemmung OR Hurrikan OR Anschlag OR Tsunami) NOT Schweiz NOT Zürich NOT Bern sourcelang:german',
        # Total article volume (baseline for shares)
        "total_fr": "sourcelang:french",
        "total_de": "sourcelang:german",
    }

    all_results = []

    for i, vdate_str in enumerate(vote_dates):
        vdate = datetime.strptime(vdate_str, "%Y-%m-%d")
        window_start = vdate - timedelta(days=14)
        window_end = vdate - timedelta(days=1)

        print(f"\n[{i+1}/{len(vote_dates)}] Vote date: {vdate_str} (window: {window_start.strftime('%Y-%m-%d')} to {window_end.strftime('%Y-%m-%d')})")

        for query_name, query_text in queries.items():
            time.sleep(1.5)  # Rate limit: be polite to GDELT API
            rows = query_gdelt_timeline(query_text, window_start, window_end)

            for article_date, volume in rows:
                all_results.append({
                    "vote_date": vdate_str,
                    "article_date": article_date,
                    "query_type": query_name,
                    "volume": volume,
                })

            if rows:
                print(f"  {query_name}: {len(rows)} days, avg volume {sum(v for _,v in rows)/max(len(rows),1):.1f}")
            else:
                print(f"  {query_name}: no data returned")

    # Save results
    outpath = os.path.join(DATA_DIR, "gdelt_daily.csv")
    if all_results:
        with open(outpath, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["vote_date", "article_date", "query_type", "volume"])
            writer.writeheader()
            writer.writerows(all_results)
        print(f"\nSaved {len(all_results)} rows to gdelt_daily.csv")
    else:
        print("\nERROR: No GDELT data retrieved!", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
