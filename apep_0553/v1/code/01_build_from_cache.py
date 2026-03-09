"""01_build_from_cache.py — Build comtrade_raw.csv from cached API responses.
Uses whatever data is available in the cache directory.
"""

import json, os, csv, sys

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
CACHE_DIR = os.path.join(DATA_DIR, "cache")
RUSSIA = 643

# CHPL codes (24 key codes)
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


def main():
    rows = []
    found = 0
    missing = 0
    countries_found = set()

    for rep_code, (rep_name, role) in COUNTRIES.items():
        for hs6, tier in ALL_CODES.items():
            is_chpl = hs6 in CHPL
            for year in YEARS:
                cache_file = os.path.join(CACHE_DIR,
                    f"ct_{rep_code}_{RUSSIA}_{hs6}_{year}_X.json")

                fob_value = 0
                net_weight_kg = 0
                qty = 0

                if os.path.exists(cache_file):
                    found += 1
                    countries_found.add(rep_code)
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
                else:
                    missing += 1
                    # Skip countries with no cached data at all
                    continue

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

    # Summary
    print(f"Cache files found: {found}")
    print(f"Cache files missing: {missing}")
    print(f"Countries with data: {sorted(countries_found)}")
    print(f"Total rows: {len(rows)}")

    if not rows:
        print("FATAL: No cached data found!", file=sys.stderr)
        sys.exit(1)

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
    reporters = len(set(r["reporter_code"] for r in rows))
    print(f"\nPositive trade: {pos} ({100*pos/len(rows):.1f}%)")
    print(f"CHPL positive: {chpl_pos}")
    print(f"Reporters: {reporters}")
    print("BUILD FROM CACHE COMPLETE")


if __name__ == "__main__":
    main()
