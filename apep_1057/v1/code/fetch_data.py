#!/usr/bin/env python3
"""Fetch EPA SDWIS data via Envirofacts REST API using concurrent requests."""

import json
import os
import csv
import time
from urllib.request import urlopen, Request
from concurrent.futures import ThreadPoolExecutor, as_completed

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

STATES = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL",
    "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME",
    "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH",
    "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI",
    "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI",
    "WY", "PR", "VI", "GU", "AS", "MP"
]

BASE = "https://data.epa.gov/efservice"


def fetch_json(url, retries=3):
    """Fetch JSON from URL with retries."""
    for attempt in range(retries):
        try:
            req = Request(url, headers={"Accept": "application/json"})
            with urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return data if isinstance(data, list) else []
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                print(f"  FAILED after {retries} attempts: {e}")
                return []


def fetch_paginated(table, params, max_rows=500000, batch=10000):
    """Fetch all rows from an EPA table with pagination."""
    all_rows = []
    offset = 0
    while offset < max_rows:
        url = f"{BASE}/{table}/{params}/rows/{offset}:{offset + batch - 1}/JSON"
        chunk = fetch_json(url)
        if not chunk:
            break
        all_rows.extend(chunk)
        if len(chunk) < batch:
            break
        offset += batch
    return all_rows


def fetch_systems_for_state(st):
    """Fetch all CWS for a state."""
    rows = fetch_paginated("WATER_SYSTEM", f"PWS_TYPE_CODE/CWS/STATE_CODE/{st}")
    print(f"  {st}: {len(rows)} systems")
    return st, rows


def fetch_violations_for_state(st):
    """Fetch health-based violations for a state."""
    rows = fetch_paginated("VIOLATION", f"IS_HEALTH_BASED_IND/Y/STATE_CODE/{st}",
                           max_rows=500000)
    print(f"  {st}: {len(rows)} violations")
    return st, rows


def save_to_csv(data, filepath, fieldnames=None):
    """Save list of dicts to CSV."""
    if not data:
        return
    if fieldnames is None:
        fieldnames = list(data[0].keys())
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(data)


def main():
    systems_file = os.path.join(DATA_DIR, "water_systems_raw.csv")
    violations_file = os.path.join(DATA_DIR, "violations_raw.csv")

    # 1. Fetch water systems (5 threads for politeness)
    if not os.path.exists(systems_file):
        print("=== Fetching Water Systems ===")
        all_systems = []
        with ThreadPoolExecutor(max_workers=5) as pool:
            futures = {pool.submit(fetch_systems_for_state, st): st for st in STATES}
            for future in as_completed(futures):
                st, rows = future.result()
                all_systems.extend(rows)

        print(f"\nTotal systems: {len(all_systems)}")
        if len(all_systems) < 50000:
            raise RuntimeError(f"Expected >50k systems, got {len(all_systems)}")
        save_to_csv(all_systems, systems_file)
        print(f"Saved {systems_file}")
    else:
        print(f"Systems file exists: {systems_file}")

    # 2. Fetch violations (5 threads)
    if not os.path.exists(violations_file):
        print("\n=== Fetching Health-Based Violations ===")
        all_violations = []
        with ThreadPoolExecutor(max_workers=5) as pool:
            futures = {pool.submit(fetch_violations_for_state, st): st for st in STATES}
            for future in as_completed(futures):
                st, rows = future.result()
                all_violations.extend(rows)

        print(f"\nTotal violations: {len(all_violations)}")
        if len(all_violations) < 50000:
            raise RuntimeError(f"Expected >50k violations, got {len(all_violations)}")
        save_to_csv(all_violations, violations_file)
        print(f"Saved {violations_file}")
    else:
        print(f"Violations file exists: {violations_file}")

    print("\n=== Done ===")


if __name__ == "__main__":
    main()
