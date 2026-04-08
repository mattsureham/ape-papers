#!/usr/bin/env python3
"""Fast GDELT TV API fetch — individual queries, 3 stations."""

import json
import os
import sys
import time
import urllib.request
import csv

DATA_DIR = "data"
os.makedirs(DATA_DIR, exist_ok=True)

STATIONS = ["CNN", "FOXNEWS", "MSNBC"]

# Queries that actually return data (tested individually)
SAFETY_QUERIES = ["OSHA", '"workplace safety"', '"safety violation"',
                  '"industrial accident"', '"factory fire"']
MEGA_QUERIES = ["Olympics", '"Super Bowl"', "impeachment", '"World Cup"']


def fetch_tv(query_str, station, start, end, retries=3):
    url = (
        f"https://api.gdeltproject.org/api/v2/tv/tv?"
        f"query={urllib.request.quote(query_str)}+station:{station}"
        f"&mode=timelinevol&format=json&datanorm=perc"
        f"&timelinesmooth=0&datacomb=sep&last24=no"
        f"&STARTDATETIME={start}&ENDDATETIME={end}"
    )
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 APEP"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read().decode("utf-8")
                if len(raw) < 60:
                    return []
                data = json.loads(raw)
                tl = data.get("timeline", [])
                return tl[0].get("data", []) if tl else []
        except Exception as e:
            print(f"  retry {attempt+1}: {station}/{query_str[:20]}: {e}", file=sys.stderr)
            time.sleep(3 * (attempt + 1))
    return []


def main():
    years = [(f"{yr}0101000000", f"{yr+1}0101000000", str(yr)) for yr in range(2015, 2024)]

    # Safety coverage
    safety_file = os.path.join(DATA_DIR, "gdelt_tv_safety.csv")
    print("=== Fetching safety coverage ===", file=sys.stderr)
    with open(safety_file, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "station", "query", "value"])
        total = 0
        for start, end, yr in years:
            for station in STATIONS:
                for q in SAFETY_QUERIES:
                    print(f"  {yr}/{station}/{q[:20]}...", file=sys.stderr, end="")
                    series = fetch_tv(q, station, start, end)
                    n = 0
                    for pt in series:
                        if pt.get("value", 0) > 0:
                            w.writerow([pt["date"][:8], station, q, pt["value"]])
                            n += 1
                    total += n
                    print(f" {n} hits", file=sys.stderr)
                    time.sleep(1)
    print(f"Safety: {total} total observations", file=sys.stderr)

    # Mega-event coverage
    mega_file = os.path.join(DATA_DIR, "gdelt_tv_megaevents.csv")
    print("\n=== Fetching mega-event coverage ===", file=sys.stderr)
    with open(mega_file, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "station", "query", "value"])
        total = 0
        for start, end, yr in years:
            for station in STATIONS:
                for q in MEGA_QUERIES:
                    print(f"  {yr}/{station}/{q[:20]}...", file=sys.stderr, end="")
                    series = fetch_tv(q, station, start, end)
                    n = 0
                    for pt in series:
                        if pt.get("value", 0) > 0:
                            w.writerow([pt["date"][:8], station, q, pt["value"]])
                            n += 1
                    total += n
                    print(f" {n} hits", file=sys.stderr)
                    time.sleep(1)
    print(f"Mega-events: {total} total observations", file=sys.stderr)

    print("\n=== Done ===", file=sys.stderr)


if __name__ == "__main__":
    main()
