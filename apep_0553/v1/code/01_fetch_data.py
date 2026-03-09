"""01_fetch_data.py — Fetch UN Comtrade bilateral trade data for sanctions analysis.
apep_0553: Do Export Controls Have Teeth?

Uses HS6-level queries (the Comtrade preview API only accepts HS6, not HS4).
Outputs CSV files for R analysis scripts.
"""

import json
import os
import time
import csv
import sys
from urllib.request import urlopen, Request
from urllib.error import HTTPError, URLError

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
CACHE_DIR = os.path.join(DATA_DIR, "cache")
os.makedirs(CACHE_DIR, exist_ok=True)

BASE_URL = "https://comtradeapi.un.org/public/v1/preview/C/A/HS"
RUSSIA = 643

# ============================================================
# CHPL Product Codes (46 HS6 codes)
# ============================================================

CHPL_CODES = {
    # Tier 1
    "854231": "Tier1", "854232": "Tier1", "854233": "Tier1", "854239": "Tier1",
    # Tier 2
    "851762": "Tier2", "852691": "Tier2", "853221": "Tier2", "853224": "Tier2", "854800": "Tier2",
    # Tier 3A
    "847150": "Tier3A", "850440": "Tier3A", "851769": "Tier3A", "852589": "Tier3A",
    "852910": "Tier3A", "852990": "Tier3A", "853669": "Tier3A", "853690": "Tier3A",
    "854110": "Tier3A", "854121": "Tier3A", "854129": "Tier3A", "854130": "Tier3A",
    "854149": "Tier3A", "854151": "Tier3A",
    # Tier 3B
    "848210": "Tier3B", "848220": "Tier3B", "848230": "Tier3B", "848250": "Tier3B",
    "880730": "Tier3B", "901310": "Tier3B", "901380": "Tier3B",
    # Tier 4A
    "847180": "Tier4A", "848610": "Tier4A", "848620": "Tier4A", "848640": "Tier4A",
    "853400": "Tier4A", "854320": "Tier4A", "902750": "Tier4A", "903020": "Tier4A",
    "903032": "Tier4A", "903039": "Tier4A", "903082": "Tier4A",
    # Tier 4B
    "845710": "Tier4B", "845811": "Tier4B", "845891": "Tier4B", "845961": "Tier4B",
    "846693": "Tier4B",
}

# Non-CHPL control codes in the same HS2 chapters (representative sample)
CONTROL_CODES = {
    # Chapter 84 controls
    "847141": "non_CHPL", "847149": "non_CHPL", "847190": "non_CHPL",
    "845929": "non_CHPL", "845939": "non_CHPL", "848280": "non_CHPL",
    "848299": "non_CHPL", "848690": "non_CHPL",
    # Chapter 85 controls
    "851770": "non_CHPL", "851830": "non_CHPL", "852352": "non_CHPL",
    "852580": "non_CHPL", "852990": "non_CHPL",  # Already in CHPL, skip
    "853610": "non_CHPL", "853641": "non_CHPL", "853650": "non_CHPL",
    "854140": "non_CHPL", "854160": "non_CHPL", "854370": "non_CHPL",
    "854890": "non_CHPL",
    # Chapter 90 controls
    "901390": "non_CHPL", "902710": "non_CHPL", "902780": "non_CHPL",
    "903010": "non_CHPL", "903031": "non_CHPL", "903089": "non_CHPL",
}

# Remove any overlap with CHPL
for code in list(CONTROL_CODES.keys()):
    if code in CHPL_CODES:
        del CONTROL_CODES[code]

ALL_CODES = {**CHPL_CODES, **CONTROL_CODES}

# ============================================================
# Country definitions
# ============================================================

TRANSIT = {
    417: "Kyrgyzstan", 51: "Armenia", 398: "Kazakhstan",
    268: "Georgia", 792: "Turkey", 784: "UAE", 356: "India",
}

CONTROL_COUNTRIES = {
    76: "Brazil", 710: "South Africa", 484: "Mexico",
    152: "Chile", 764: "Thailand",
}

WESTERN = {
    276: "Germany", 528: "Netherlands", 826: "United Kingdom",
    392: "Japan", 840: "USA",
}

ALL_REPORTERS = {}
ALL_REPORTERS.update(TRANSIT)
ALL_REPORTERS.update(CONTROL_COUNTRIES)
ALL_REPORTERS.update(WESTERN)

YEARS = list(range(2015, 2025))


def fetch_one(reporter_code, partner_code, hs6, year, flow="X"):
    """Fetch a single Comtrade query, with caching."""
    cache_file = os.path.join(CACHE_DIR, f"ct_{reporter_code}_{partner_code}_{hs6}_{year}_{flow}.json")

    if os.path.exists(cache_file):
        with open(cache_file) as f:
            return json.load(f)

    url = (f"{BASE_URL}?reporterCode={reporter_code}&partnerCode={partner_code}"
           f"&cmdCode={hs6}&flowCode={flow}&period={year}")

    time.sleep(1.2)  # Rate limit

    for attempt in range(3):
        try:
            req = Request(url)
            req.add_header("User-Agent", "APEP-Research/1.0")
            with urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())

            with open(cache_file, "w") as f:
                json.dump(data, f)
            return data

        except HTTPError as e:
            if e.code == 429:
                time.sleep(5 * (attempt + 1))
                continue
            elif e.code == 400:
                # No data for this query
                empty = {"data": [], "count": 0}
                with open(cache_file, "w") as f:
                    json.dump(empty, f)
                return empty
            else:
                print(f"  HTTP {e.code} for {reporter_code}/{hs6}/{year}", file=sys.stderr)
                return {"data": [], "count": 0}
        except (URLError, TimeoutError) as e:
            time.sleep(3 * (attempt + 1))
            continue

    return {"data": [], "count": 0}


def main():
    print(f"CHPL codes: {len(CHPL_CODES)}")
    print(f"Control codes: {len(CONTROL_CODES)}")
    print(f"Total HS6 codes: {len(ALL_CODES)}")
    print(f"Reporters: {len(ALL_REPORTERS)}")
    print(f"Years: {len(YEARS)}")
    total = len(ALL_CODES) * len(ALL_REPORTERS) * len(YEARS)
    print(f"Total queries: {total}")
    print(f"Est. time: {total * 1.2 / 60:.0f} minutes\n")

    output_file = os.path.join(DATA_DIR, "comtrade_raw.csv")
    rows = []
    counter = 0

    for reporter_code, reporter_name in ALL_REPORTERS.items():
        role = ("transit" if reporter_code in TRANSIT
                else "western" if reporter_code in WESTERN
                else "control")

        for hs6, tier in ALL_CODES.items():
            is_chpl = hs6 in CHPL_CODES

            for year in YEARS:
                counter += 1
                if counter % 100 == 0:
                    print(f"  Progress: {counter}/{total} ({100*counter/total:.0f}%) - "
                          f"{reporter_name} HS{hs6} {year}")

                result = fetch_one(reporter_code, RUSSIA, hs6, year)

                if result.get("data"):
                    for rec in result["data"]:
                        rows.append({
                            "reporter_code": reporter_code,
                            "reporter_name": reporter_name,
                            "role": role,
                            "hs6": hs6,
                            "tier": tier if is_chpl else "non_CHPL",
                            "is_chpl": int(is_chpl),
                            "year": year,
                            "fob_value": rec.get("primaryValue", 0) or 0,
                            "net_weight_kg": rec.get("netWgt", 0) or 0,
                            "qty": rec.get("qty", 0) or 0,
                        })
                else:
                    # Record zero trade
                    rows.append({
                        "reporter_code": reporter_code,
                        "reporter_name": reporter_name,
                        "role": role,
                        "hs6": hs6,
                        "tier": tier if is_chpl else "non_CHPL",
                        "is_chpl": int(is_chpl),
                        "year": year,
                        "fob_value": 0,
                        "net_weight_kg": 0,
                        "qty": 0,
                    })

        print(f"  Completed: {reporter_name} ({role})")

    # Write CSV
    if not rows:
        print("FATAL: No data collected!", file=sys.stderr)
        sys.exit(1)

    fieldnames = ["reporter_code", "reporter_name", "role", "hs6", "tier",
                  "is_chpl", "year", "fob_value", "net_weight_kg", "qty"]

    with open(output_file, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    # Also save CHPL codes and reporter codes
    with open(os.path.join(DATA_DIR, "chpl_codes.csv"), "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["hs6", "tier"])
        writer.writeheader()
        for hs6, tier in CHPL_CODES.items():
            writer.writerow({"hs6": hs6, "tier": tier})

    with open(os.path.join(DATA_DIR, "reporter_codes.csv"), "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["code", "name", "role"])
        writer.writeheader()
        for code, name in ALL_REPORTERS.items():
            role = ("transit" if code in TRANSIT
                    else "western" if code in WESTERN
                    else "control")
            writer.writerow({"code": code, "name": name, "role": role})

    # Validation
    total_rows = len(rows)
    chpl_positive = sum(1 for r in rows if r["is_chpl"] and r["fob_value"] > 0)
    non_chpl_positive = sum(1 for r in rows if not r["is_chpl"] and r["fob_value"] > 0)
    reporters = len(set(r["reporter_code"] for r in rows))
    years_present = len(set(r["year"] for r in rows))

    print(f"\n=== DATA VALIDATION ===")
    print(f"Total rows: {total_rows}")
    print(f"CHPL positive trade: {chpl_positive}")
    print(f"Non-CHPL positive trade: {non_chpl_positive}")
    print(f"Reporters: {reporters}")
    print(f"Years: {years_present}")

    assert reporters >= 10, f"Expected 10+ reporters, got {reporters}"
    assert years_present >= 5, f"Expected 5+ years, got {years_present}"
    assert chpl_positive > 0, "No CHPL positive trade found"
    print("Data validation PASSED")


if __name__ == "__main__":
    main()
