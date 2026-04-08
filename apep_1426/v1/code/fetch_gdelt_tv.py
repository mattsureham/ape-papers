#!/usr/bin/env python3
"""Fetch GDELT TV API data for apep_1426: TV News + OSHA Safety Deterrence.

Outputs:
  - data/gdelt_tv_safety.csv: Daily safety coverage by station
  - data/gdelt_tv_total.csv: Daily total volume by station (for competing-news)
  - data/gdelt_tv_megaevents.csv: Daily mega-event coverage (Olympics, Super Bowl, etc.)
"""

import json
import os
import sys
import time
import urllib.request
import csv
from datetime import datetime, timedelta

DATA_DIR = "data"
os.makedirs(DATA_DIR, exist_ok=True)

STATIONS = [
    "CNN", "FOXNEWS", "MSNBC",
    "BBCNEWS", "CNBC", "FBC",  # Fox Business
]

# Safety keywords for TV caption search
SAFETY_QUERIES = [
    "OSHA",
    '"workplace safety"',
    '"worker killed"',
    '"plant explosion"',
    '"mine collapse"',
    '"chemical spill"',
    '"factory fire"',
    '"industrial accident"',
    '"safety violation"',
    '"construction accident"',
]

# Mega-event queries for competing-news instrument
MEGA_EVENT_QUERIES = [
    "Olympics",
    '"Super Bowl"',
    "impeachment",
    '"World Cup"',
]


def fetch_gdelt_tv(query, station, start_dt, end_dt, max_retries=3):
    """Fetch daily timeline from GDELT TV API."""
    url = (
        f"https://api.gdeltproject.org/api/v2/tv/tv?"
        f"query={urllib.request.quote(query)}+station:{station}"
        f"&mode=timelinevol&format=json&datanorm=perc"
        f"&timelinesmooth=0&datacomb=sep&last24=no"
        f"&STARTDATETIME={start_dt}&ENDDATETIME={end_dt}"
    )

    for attempt in range(max_retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 APEP Research"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read().decode("utf-8")
                if len(raw) < 50:
                    print(f"  Warning: short response for {station}/{query[:20]}: {raw}", file=sys.stderr)
                    return []
                data = json.loads(raw)
                timeline = data.get("timeline", [])
                if timeline:
                    return timeline[0].get("data", [])
                return []
        except Exception as e:
            wait = 5 * (attempt + 1)
            print(f"  Retry {attempt+1}/{max_retries} for {station}/{query[:20]}: {e}", file=sys.stderr)
            time.sleep(wait)

    return []


def fetch_all_stations(queries, stations, start_dt, end_dt, label):
    """Fetch data for multiple queries across stations, merge into daily series."""
    all_rows = []

    for station in stations:
        for query in queries:
            print(f"  Fetching {label}: station={station}, query={query[:30]}...", file=sys.stderr)
            series = fetch_gdelt_tv(query, station, start_dt, end_dt)

            for point in series:
                date_str = point.get("date", "")[:8]  # YYYYMMDD
                value = point.get("value", 0)
                if value > 0:
                    all_rows.append({
                        "date": date_str,
                        "station": station,
                        "query": query,
                        "value": value,
                    })

            time.sleep(2)  # Rate limit

    return all_rows


def main():
    # Fetch in yearly chunks to avoid API limits
    # GDELT TV data starts ~2009 but is more complete from 2015+
    years = [(f"{yr}0101000000", f"{yr+1}0101000000") for yr in range(2015, 2024)]

    # 1. Safety coverage
    safety_file = os.path.join(DATA_DIR, "gdelt_tv_safety.csv")
    if not os.path.exists(safety_file):
        print("=== Fetching safety coverage ===", file=sys.stderr)
        all_safety = []
        for start_dt, end_dt in years:
            yr = start_dt[:4]
            print(f"  Year {yr}...", file=sys.stderr)
            rows = fetch_all_stations(SAFETY_QUERIES, STATIONS, start_dt, end_dt, "safety")
            all_safety.extend(rows)

        with open(safety_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["date", "station", "query", "value"])
            writer.writeheader()
            writer.writerows(all_safety)
        print(f"Safety coverage: {len(all_safety)} rows saved.", file=sys.stderr)
    else:
        print(f"Safety coverage file exists, skipping.", file=sys.stderr)

    # 2. Mega-event coverage (competing-news instrument)
    mega_file = os.path.join(DATA_DIR, "gdelt_tv_megaevents.csv")
    if not os.path.exists(mega_file):
        print("\n=== Fetching mega-event coverage ===", file=sys.stderr)
        all_mega = []
        for start_dt, end_dt in years:
            yr = start_dt[:4]
            print(f"  Year {yr}...", file=sys.stderr)
            rows = fetch_all_stations(MEGA_EVENT_QUERIES, STATIONS, start_dt, end_dt, "mega-events")
            all_mega.extend(rows)

        with open(mega_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["date", "station", "query", "value"])
            writer.writeheader()
            writer.writerows(all_mega)
        print(f"Mega-event coverage: {len(all_mega)} rows saved.", file=sys.stderr)
    else:
        print(f"Mega-event file exists, skipping.", file=sys.stderr)

    # 3. BLS SOII state-level injury data
    bls_file = os.path.join(DATA_DIR, "bls_soii_state.txt")
    if not os.path.exists(bls_file):
        print("\n=== Fetching BLS SOII data ===", file=sys.stderr)
        # State-level data from the 'is' series
        url = "https://download.bls.gov/pub/time.series/is/is.data.1.AllData"
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        }
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = resp.read()
                with open(bls_file, "wb") as f:
                    f.write(data)
                print(f"BLS SOII data: {len(data)} bytes saved.", file=sys.stderr)
        except Exception as e:
            print(f"BLS SOII download failed: {e}", file=sys.stderr)
            # Try alternative: CFOI (Census of Fatal Occupational Injuries)
            cfoi_url = "https://download.bls.gov/pub/time.series/fw/fw.data.0.Current"
            try:
                req = urllib.request.Request(cfoi_url, headers=headers)
                with urllib.request.urlopen(req, timeout=120) as resp:
                    data = resp.read()
                    cfoi_file = os.path.join(DATA_DIR, "bls_cfoi.txt")
                    with open(cfoi_file, "wb") as f:
                        f.write(data)
                    print(f"BLS CFOI data: {len(data)} bytes saved.", file=sys.stderr)
            except Exception as e2:
                print(f"BLS CFOI also failed: {e2}", file=sys.stderr)

    # Also fetch series definitions
    for suffix in ["is.series", "is.area", "is.industry"]:
        sf = os.path.join(DATA_DIR, suffix.replace(".", "_") + ".txt")
        if not os.path.exists(sf):
            url = f"https://download.bls.gov/pub/time.series/is/{suffix}"
            try:
                headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=30) as resp:
                    with open(sf, "wb") as f:
                        f.write(resp.read())
                    print(f"  {suffix}: saved.", file=sys.stderr)
            except Exception as e:
                print(f"  {suffix}: {e}", file=sys.stderr)

    print("\n=== Data fetch complete ===", file=sys.stderr)


if __name__ == "__main__":
    main()
