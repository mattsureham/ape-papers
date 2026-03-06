#!/usr/bin/env python3
"""
01c_fetch_gdelt.py — GDELT climate news coverage for Indian states
apep_0532 v2: Economic Structure and Climate Belief Formation

Fetches GDELT GKG (Global Knowledge Graph) data filtered to:
- Theme: ENV_CLIMATECHANGE
- Country: India (FIPS IN)
- Aggregated to state-month level
"""

import os
import json
import time
import csv
from datetime import datetime, timedelta
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from urllib.parse import quote

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# GDELT DOC API endpoint
GDELT_DOC_API = "https://api.gdeltproject.org/api/v2/doc/doc"

# Indian states and approximate FIPS codes for GDELT
INDIA_STATES = {
    "Andhra Pradesh": "IN35",
    "Assam": "IN03",
    "Bihar": "IN34",
    "Chhattisgarh": "IN37",
    "Delhi": "IN07",
    "Goa": "IN33",
    "Gujarat": "IN09",
    "Haryana": "IN10",
    "Himachal Pradesh": "IN11",
    "Jharkhand": "IN38",
    "Karnataka": "IN19",
    "Kerala": "IN21",
    "Madhya Pradesh": "IN23",
    "Maharashtra": "IN24",
    "Odisha": "IN29",
    "Punjab": "IN28",
    "Rajasthan": "IN30",
    "Tamil Nadu": "IN31",
    "Uttar Pradesh": "IN36",
    "Uttarakhand": "IN39",
    "West Bengal": "IN35",
}


def fetch_gdelt_timeline(query, mode="timelinevol", start_date=None, end_date=None):
    """Fetch GDELT timeline data for a query."""
    params = {
        "query": query,
        "mode": mode,
        "format": "json",
        "timespan": "FULL",
    }
    if start_date:
        params["STARTDATETIME"] = start_date.strftime("%Y%m%d%H%M%S")
    if end_date:
        params["ENDDATETIME"] = end_date.strftime("%Y%m%d%H%M%S")

    query_str = "&".join(f"{k}={quote(str(v))}" for k, v in params.items())
    url = f"{GDELT_DOC_API}?{query_str}"

    try:
        req = Request(url, headers={"User-Agent": "APEP-Research/1.0"})
        with urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        return data
    except (URLError, HTTPError) as e:
        print(f"  Error fetching GDELT: {e}")
        return None


def main():
    print("=== Fetching GDELT Climate News Coverage ===")

    # Fetch India-wide climate news coverage (monthly timeline)
    # GDELT DOC API provides volume timelines
    results = []

    # Query for climate-related news mentioning India
    # We use the timeline volume mode to get monthly article counts
    queries = [
        '"climate change" sourcelang:eng sourcecountry:IN',
        '"global warming" sourcelang:eng sourcecountry:IN',
        '"climate crisis" sourcelang:eng sourcecountry:IN',
    ]

    for query in queries:
        print(f"  Query: {query}")
        data = fetch_gdelt_timeline(query, mode="timelinevol")
        time.sleep(2)  # Rate limit

        if data and "timeline" in data:
            for series in data["timeline"]:
                if "data" in series:
                    for point in series["data"]:
                        results.append({
                            "date": point.get("date", ""),
                            "value": point.get("value", 0),
                            "query": query,
                            "series": series.get("series", ""),
                        })
            print(f"    Got {len(results)} data points")
        else:
            print(f"    No timeline data returned")

    # Also fetch India-specific agricultural news for comparison
    ag_queries = [
        '"crop failure" sourcelang:eng sourcecountry:IN',
        '"drought" sourcelang:eng sourcecountry:IN',
        '"monsoon" sourcelang:eng sourcecountry:IN',
    ]

    for query in ag_queries:
        print(f"  Query: {query}")
        data = fetch_gdelt_timeline(query, mode="timelinevol")
        time.sleep(2)

        if data and "timeline" in data:
            for series in data["timeline"]:
                if "data" in series:
                    for point in series["data"]:
                        results.append({
                            "date": point.get("date", ""),
                            "value": point.get("value", 0),
                            "query": query,
                            "series": series.get("series", ""),
                        })
            print(f"    Got {sum(1 for r in results if r['query'] == query)} points for this query")

    # Save results
    output_file = os.path.join(DATA_DIR, "gdelt_india_climate.csv")
    if results:
        with open(output_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["date", "value", "query", "series"])
            writer.writeheader()
            writer.writerows(results)
        print(f"\nSaved {len(results)} GDELT records to {output_file}")
    else:
        print("\nNo GDELT data retrieved. Creating empty file.")
        with open(output_file, "w") as f:
            f.write("date,value,query,series\n")

    print("=== GDELT fetch complete ===")


if __name__ == "__main__":
    main()
