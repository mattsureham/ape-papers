"""01a_fetch_gdelt_protests.py — Download GDELT US protest events with GPS coordinates.

GDELT Events 1.0: daily CSV exports.
EventBaseCode 14* = Protest events (CAMEO coding).
Filter: US only, ActionGeo_Type >= 3 (city-level or finer).

Strategy: Download ALL daily files (2018-2023) but process efficiently.
Each zip is ~3-5MB; we extract only protest events in US.
"""

import os
import csv
import io
import zipfile
import urllib.request
import time
import sys
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def fetch_day(date_str):
    """Download and filter one day's GDELT events for US protests."""
    url = f"http://data.gdeltproject.org/events/{date_str}.export.CSV.zip"
    try:
        resp = urllib.request.urlopen(url, timeout=30)
        data = resp.read()
    except Exception:
        return []

    protests = []
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            for name in zf.namelist():
                with zf.open(name) as f:
                    reader = csv.reader(io.TextIOWrapper(f, encoding='utf-8', errors='replace'),
                                       delimiter='\t')
                    for row in reader:
                        if len(row) < 58:
                            continue
                        if (row[27].startswith('14') and
                            row[44] == 'US' and
                            row[42] in ('3', '4', '5')):
                            try:
                                lat = float(row[46])
                                lon = float(row[47])
                            except (ValueError, IndexError):
                                continue
                            protests.append((
                                row[0],   # event_id
                                row[1],   # event_date YYYYMMDD
                                row[26],  # event_code
                                row[27],  # event_base_code
                                row[30],  # goldstein
                                row[31],  # num_mentions
                                row[32],  # num_sources
                                row[33],  # num_articles
                                row[34],  # avg_tone
                                row[43],  # location
                                row[45],  # admin1
                                lat, lon
                            ))
    except Exception:
        return []
    return protests


def main():
    start = datetime(2018, 1, 1)
    end = datetime(2023, 12, 31)

    # Generate all dates
    dates = []
    current = start
    while current <= end:
        dates.append(current.strftime("%Y%m%d"))
        current += timedelta(days=1)

    print(f"Fetching {len(dates)} daily GDELT files...", flush=True)

    all_protests = []
    completed = 0

    # Use thread pool for parallel downloads (4 concurrent)
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(fetch_day, d): d for d in dates}
        for future in as_completed(futures):
            completed += 1
            result = future.result()
            all_protests.extend(result)
            if completed % 100 == 0:
                print(f"  {completed}/{len(dates)} days, {len(all_protests):,} protests", flush=True)

    print(f"\nTotal US protest events: {len(all_protests):,}")

    # Write CSV
    outpath = os.path.join(OUTPUT_DIR, "gdelt_protests.csv")
    with open(outpath, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            'event_id', 'event_date', 'event_code', 'event_base_code',
            'goldstein', 'num_mentions', 'num_sources', 'num_articles',
            'avg_tone', 'location', 'admin1', 'lat', 'lon'
        ])
        writer.writerows(all_protests)

    print(f"Saved to {outpath}")


if __name__ == "__main__":
    main()
