"""01_fetch_batch.py — Smart batch fetcher with rate limit handling.
Fetches in batches, detects rate limiting, and backs off appropriately.
Resumes from cache — safe to run multiple times.
"""

import json, os, time, csv, sys
from urllib.request import urlopen, Request
from urllib.error import HTTPError, URLError

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
CACHE_DIR = os.path.join(DATA_DIR, "cache")
os.makedirs(CACHE_DIR, exist_ok=True)

BASE_URL = "https://comtradeapi.un.org/public/v1/preview/C/A/HS"
RUSSIA = 643

CHPL = {
    "854231": "Tier1", "854232": "Tier1", "854233": "Tier1", "854239": "Tier1",
    "851762": "Tier2", "852691": "Tier2", "853221": "Tier2", "853224": "Tier2",
    "854800": "Tier2",
    "847150": "Tier3A", "850440": "Tier3A", "854110": "Tier3A",
    "854121": "Tier3A", "854129": "Tier3A",
    "848210": "Tier3B", "848220": "Tier3B",
    "880730": "Tier3B", "901310": "Tier3B", "901380": "Tier3B",
    "847180": "Tier4A", "853400": "Tier4A", "854320": "Tier4A",
    "845710": "Tier4B", "845811": "Tier4B",
}

NON_CHPL = {
    "847141": "non_CHPL", "847149": "non_CHPL", "847190": "non_CHPL",
    "845929": "non_CHPL", "848280": "non_CHPL", "848299": "non_CHPL",
    "851770": "non_CHPL", "851830": "non_CHPL", "852580": "non_CHPL",
    "853610": "non_CHPL", "853641": "non_CHPL", "854140": "non_CHPL",
    "854160": "non_CHPL", "854370": "non_CHPL", "854890": "non_CHPL",
    "901390": "non_CHPL", "902780": "non_CHPL", "903089": "non_CHPL",
}

ALL_CODES = {**CHPL, **NON_CHPL}

# All target countries
COUNTRIES = {
    417: ("Kyrgyzstan", "transit"),
    51: ("Armenia", "transit"),
    398: ("Kazakhstan", "transit"),
    268: ("Georgia", "transit"),
    792: ("Turkey", "transit"),
    784: ("UAE", "transit"),
    76: ("Brazil", "control"),
    710: ("South Africa", "control"),
    484: ("Mexico", "control"),
    276: ("Germany", "western"),
    528: ("Netherlands", "western"),
    392: ("Japan", "western"),
}

YEARS = list(range(2015, 2025))


def fetch_one(rep, hs6, year):
    cache_file = os.path.join(CACHE_DIR, f"ct_{rep}_{RUSSIA}_{hs6}_{year}_X.json")
    if os.path.exists(cache_file):
        return True  # Already cached

    url = (f"{BASE_URL}?reporterCode={rep}&partnerCode={RUSSIA}"
           f"&cmdCode={hs6}&flowCode=X&period={year}")

    for attempt in range(3):
        try:
            time.sleep(1.5)
            req = Request(url, headers={"User-Agent": "APEP/1.0"})
            with urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
            with open(cache_file, "w") as f:
                json.dump(data, f)
            return True
        except HTTPError as e:
            if e.code == 403:
                return "QUOTA"  # Daily/hourly quota hit
            if e.code == 429:
                time.sleep(10 * (attempt + 1))
                continue
            empty = {"data": []}
            with open(cache_file, "w") as f:
                json.dump(empty, f)
            return True
        except Exception:
            time.sleep(5)
            continue
    return False


def count_cached():
    """Count how many of our target queries are already cached."""
    cached = 0
    total = 0
    for rep in COUNTRIES:
        for hs6 in ALL_CODES:
            for year in YEARS:
                total += 1
                cache_file = os.path.join(CACHE_DIR, f"ct_{rep}_{RUSSIA}_{hs6}_{year}_X.json")
                if os.path.exists(cache_file):
                    cached += 1
    return cached, total


def main():
    cached, total = count_cached()
    needed = total - cached
    print(f"Total queries needed: {total}")
    print(f"Already cached: {cached}")
    print(f"Remaining: {needed}")
    print(f"Estimated time: ~{needed * 1.5 / 60:.0f} min (without rate limits)\n")
    sys.stdout.flush()

    fetched = 0
    quota_hits = 0

    for rep_code, (rep_name, role) in COUNTRIES.items():
        country_needed = 0
        country_cached = 0
        for hs6 in ALL_CODES:
            for year in YEARS:
                cache_file = os.path.join(CACHE_DIR, f"ct_{rep_code}_{RUSSIA}_{hs6}_{year}_X.json")
                if os.path.exists(cache_file):
                    country_cached += 1
                else:
                    country_needed += 1

        if country_needed == 0:
            print(f"  {rep_name}: fully cached ({country_cached} files)")
            sys.stdout.flush()
            continue

        print(f"  {rep_name}: {country_cached} cached, {country_needed} to fetch")
        sys.stdout.flush()

        for hs6 in ALL_CODES:
            for year in YEARS:
                cache_file = os.path.join(CACHE_DIR, f"ct_{rep_code}_{RUSSIA}_{hs6}_{year}_X.json")
                if os.path.exists(cache_file):
                    continue

                result = fetch_one(rep_code, hs6, year)
                if result == "QUOTA":
                    quota_hits += 1
                    print(f"\n  QUOTA HIT after {fetched} new fetches. Waiting 5 min...")
                    sys.stdout.flush()
                    time.sleep(300)  # Wait 5 minutes
                    # Retry
                    result = fetch_one(rep_code, hs6, year)
                    if result == "QUOTA":
                        print(f"  Still rate limited. Stopping.")
                        print(f"  Re-run this script later to continue.")
                        sys.stdout.flush()
                        break
                elif result:
                    fetched += 1
                    if fetched % 50 == 0:
                        print(f"    Fetched {fetched} new queries...")
                        sys.stdout.flush()
            else:
                continue
            break  # Break out of hs6 loop if quota hit
        else:
            print(f"  Done: {rep_name}")
            sys.stdout.flush()
            continue
        break  # Break out of country loop if quota hit

    # Build CSV from all cached data
    print(f"\nBuilding CSV from cache...")
    sys.stdout.flush()
    build_csv()


def build_csv():
    rows = []
    countries_found = set()

    for rep_code, (rep_name, role) in COUNTRIES.items():
        for hs6, tier in ALL_CODES.items():
            is_chpl = hs6 in CHPL
            for year in YEARS:
                cache_file = os.path.join(CACHE_DIR,
                    f"ct_{rep_code}_{RUSSIA}_{hs6}_{year}_X.json")

                if not os.path.exists(cache_file):
                    continue

                countries_found.add(rep_code)
                fob_value = 0
                net_weight_kg = 0
                qty = 0

                try:
                    with open(cache_file) as f:
                        data = json.load(f)
                    if data.get("data"):
                        for rec in data["data"]:
                            fob_value += rec.get("primaryValue", 0) or 0
                            net_weight_kg += rec.get("netWgt", 0) or 0
                            qty += rec.get("qty", 0) or 0
                except (json.JSONDecodeError, KeyError):
                    pass

                rows.append({
                    "reporter_code": rep_code,
                    "reporter_name": rep_name,
                    "role": role,
                    "hs6": hs6,
                    "tier": tier if is_chpl else "non_CHPL",
                    "is_chpl": int(is_chpl),
                    "year": year,
                    "fob_value": fob_value,
                    "net_weight_kg": net_weight_kg,
                    "qty": qty,
                })

    # Write CSV
    out = os.path.join(DATA_DIR, "comtrade_raw.csv")
    fields = ["reporter_code", "reporter_name", "role", "hs6", "tier",
              "is_chpl", "year", "fob_value", "net_weight_kg", "qty"]
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

    # Save metadata
    with open(os.path.join(DATA_DIR, "chpl_codes.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["hs6", "tier"])
        w.writeheader()
        for hs6, tier in CHPL.items():
            w.writerow({"hs6": hs6, "tier": tier})

    with open(os.path.join(DATA_DIR, "reporter_codes.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["code", "name", "role"])
        w.writeheader()
        for code, (name, role) in COUNTRIES.items():
            if code in countries_found:
                w.writerow({"code": code, "name": name, "role": role})

    pos = sum(1 for r in rows if r["fob_value"] > 0)
    chpl_pos = sum(1 for r in rows if r["is_chpl"] and r["fob_value"] > 0)
    reporters = len(countries_found)
    print(f"\nTotal rows: {len(rows)}")
    print(f"Countries: {reporters} {sorted(countries_found)}")
    print(f"Positive trade: {pos} ({100*pos/len(rows):.1f}%)")
    print(f"CHPL positive: {chpl_pos}")
    print("DATA BUILD COMPLETE")


if __name__ == "__main__":
    main()
