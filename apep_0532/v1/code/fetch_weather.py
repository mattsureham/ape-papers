#!/usr/bin/env python3
"""
Fetch daily weather data from NASA POWER API for Indian state capitals.
POWER temporal coverage: T2M from 1981, PRECTOTCORR from 1981.
Max 30-year range per request.
"""
import json
import csv
import time
import urllib.request
import os

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

STATES = [
    ("Andhra Pradesh", 15.83, 78.05),
    ("Assam", 26.14, 91.74),
    ("Bihar", 25.60, 85.12),
    ("Chhattisgarh", 21.25, 81.63),
    ("Delhi", 28.61, 77.23),
    ("Goa", 15.50, 73.83),
    ("Gujarat", 23.02, 72.57),
    ("Haryana", 29.06, 76.09),
    ("Himachal Pradesh", 31.10, 77.17),
    ("Jharkhand", 23.35, 85.33),
    ("Karnataka", 15.32, 75.71),
    ("Kerala", 10.85, 76.27),
    ("Madhya Pradesh", 23.26, 77.41),
    ("Maharashtra", 19.08, 72.88),
    ("Odisha", 20.94, 84.80),
    ("Punjab", 31.63, 74.87),
    ("Rajasthan", 26.92, 75.79),
    ("Tamil Nadu", 11.13, 78.66),
    ("Telangana", 17.39, 78.49),
    ("Uttar Pradesh", 26.85, 80.91),
    ("Uttarakhand", 30.07, 79.49),
    ("West Bengal", 22.57, 88.36),
]


def fetch_power(lat, lon, start, end, retries=3):
    url = (
        f"https://power.larc.nasa.gov/api/temporal/daily/point?"
        f"parameters=T2M,T2M_MAX,PRECTOTCORR"
        f"&community=AG"
        f"&longitude={lon:.4f}&latitude={lat:.4f}"
        f"&start={start}&end={end}"
        f"&format=JSON"
    )
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url)
            req.add_header("User-Agent", "APEP-Research/1.0")
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode())
                return data.get("properties", {}).get("parameter", None)
        except Exception as e:
            print(f"    Attempt {attempt+1} failed: {e}", flush=True)
            time.sleep(10 * (attempt + 1))
    return None


def main():
    outfile = os.path.join(DATA_DIR, "india_weather_daily.csv")
    rows = []

    # Three periods within POWER's 1981+ temporal range:
    # 1. Normals baseline: 1981-2000
    # 2. Analysis period 1: 2001-2020
    # 3. Analysis period 2: 2021-2023
    periods = [
        ("19810101", "20001231"),
        ("20010101", "20201231"),
        ("20210101", "20231231"),
    ]

    for state, lat, lon in STATES:
        print(f"  {state}...", end=" ", flush=True)
        state_count = 0

        for start, end in periods:
            time.sleep(3)
            params = fetch_power(lat, lon, start, end)
            if params:
                t2m = params.get("T2M", {})
                t2m_max = params.get("T2M_MAX", {})
                prec = params.get("PRECTOTCORR", {})

                for date_str in sorted(t2m.keys()):
                    tavg = t2m.get(date_str)
                    tmax = t2m_max.get(date_str)
                    precip = prec.get(date_str)
                    if tavg is not None and tavg > -900:
                        rows.append({
                            "state": state,
                            "date": f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}",
                            "tavg": round(tavg, 2),
                            "tmax": round(tmax, 2) if tmax and tmax > -900 else "",
                            "precip": round(precip, 2) if precip and precip > -900 else "",
                        })
                        state_count += 1
            else:
                print(f"[FAILED {start[:4]}-{end[:4]}]", end=" ", flush=True)

        print(f"{state_count} days", flush=True)

    with open(outfile, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["state", "date", "tavg", "tmax", "precip"])
        writer.writeheader()
        writer.writerows(rows)

    n_states = len(set(r["state"] for r in rows))
    print(f"\nSaved {len(rows)} rows to {outfile}")
    print(f"States covered: {n_states}")

    if n_states < 15:
        print("WARNING: Fewer than 15 states — check API errors above")
        return 1
    return 0


if __name__ == "__main__":
    exit(main())
