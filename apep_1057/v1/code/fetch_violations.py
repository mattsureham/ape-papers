#!/usr/bin/env python3
"""Fetch all health-based violations from EPA SDWIS."""

import json
import csv
import os
import time
from urllib.request import urlopen, Request

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)
OUTPUT = os.path.join(DATA_DIR, "violations_raw.csv")

if os.path.exists(OUTPUT):
    print(f"Already exists: {OUTPUT}")
    exit(0)

BASE = "https://data.epa.gov/efservice/VIOLATION/IS_HEALTH_BASED_IND/Y"
BATCH = 10000
MAX = 400000

all_rows = []
offset = 0

while offset < MAX:
    url = f"{BASE}/rows/{offset}:{offset + BATCH - 1}/JSON"
    print(f"Fetching {offset}-{offset + BATCH - 1}...", flush=True)
    try:
        req = Request(url, headers={"Accept": "application/json"})
        with urlopen(req, timeout=180) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if not isinstance(data, list) or len(data) == 0:
                print("  No more data.")
                break
            all_rows.extend(data)
            print(f"  Got {len(data)} rows (total: {len(all_rows)})", flush=True)
            if len(data) < BATCH:
                break
    except Exception as e:
        print(f"  Error: {e}", flush=True)
        time.sleep(5)
        continue
    offset += BATCH
    time.sleep(0.5)

print(f"\nTotal violations: {len(all_rows)}")
if len(all_rows) < 100000:
    raise RuntimeError(f"Expected >100k violations, got {len(all_rows)}")

# Save to CSV
fieldnames = list(all_rows[0].keys())
with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
    writer.writeheader()
    writer.writerows(all_rows)

print(f"Saved {OUTPUT}")
