"""01_fetch_data_fast.py — Focused Comtrade fetch for core analysis.
Queries only essential CHPL codes and key countries to keep runtime <30 min.
"""

import json, os, time, csv, sys
from urllib.request import urlopen, Request
from urllib.error import HTTPError, URLError

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
CACHE_DIR = os.path.join(DATA_DIR, "cache")
os.makedirs(CACHE_DIR, exist_ok=True)

BASE_URL = "https://comtradeapi.un.org/public/v1/preview/C/A/HS"
RUSSIA = 643

# Core CHPL codes (Tier 1-2 + key Tier 3)
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

# Non-CHPL controls in same HS2 chapters
NON_CHPL = {
    "847141": "non_CHPL", "847149": "non_CHPL", "847190": "non_CHPL",
    "845929": "non_CHPL", "848280": "non_CHPL", "848299": "non_CHPL",
    "851770": "non_CHPL", "851830": "non_CHPL", "852580": "non_CHPL",
    "853610": "non_CHPL", "853641": "non_CHPL", "854140": "non_CHPL",
    "854160": "non_CHPL", "854370": "non_CHPL", "854890": "non_CHPL",
    "901390": "non_CHPL", "902780": "non_CHPL", "903089": "non_CHPL",
}

ALL_CODES = {**CHPL, **NON_CHPL}

# Key countries only
TRANSIT = {417: "Kyrgyzstan", 51: "Armenia", 398: "Kazakhstan",
           268: "Georgia", 792: "Turkey", 784: "UAE"}
CONTROL = {76: "Brazil", 710: "South Africa", 484: "Mexico"}
WESTERN = {276: "Germany", 528: "Netherlands", 392: "Japan"}

ALL_REPORTERS = {**TRANSIT, **CONTROL, **WESTERN}
YEARS = list(range(2015, 2025))


def fetch_one(rep, hs6, year):
    cache_file = os.path.join(CACHE_DIR, f"ct_{rep}_{RUSSIA}_{hs6}_{year}_X.json")
    if os.path.exists(cache_file):
        with open(cache_file) as f:
            return json.load(f)

    url = (f"{BASE_URL}?reporterCode={rep}&partnerCode={RUSSIA}"
           f"&cmdCode={hs6}&flowCode=X&period={year}")
    time.sleep(1.1)

    for attempt in range(3):
        try:
            req = Request(url, headers={"User-Agent": "APEP/1.0"})
            with urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
            with open(cache_file, "w") as f:
                json.dump(data, f)
            return data
        except HTTPError as e:
            if e.code == 429:
                time.sleep(5 * (attempt + 1)); continue
            empty = {"data": []}
            with open(cache_file, "w") as f:
                json.dump(empty, f)
            return empty
        except Exception:
            time.sleep(3); continue
    return {"data": []}


def main():
    total = len(ALL_CODES) * len(ALL_REPORTERS) * len(YEARS)
    cached = len([f for f in os.listdir(CACHE_DIR) if f.endswith(".json")])
    print(f"Codes: {len(ALL_CODES)} ({len(CHPL)} CHPL + {len(NON_CHPL)} control)")
    print(f"Countries: {len(ALL_REPORTERS)}")
    print(f"Queries: {total} (cached: {cached})")
    print(f"Est. time: ~{max(0, (total - cached)) * 1.1 / 60:.0f} min\n")

    rows = []
    counter = 0

    for rep_code, rep_name in ALL_REPORTERS.items():
        role = ("transit" if rep_code in TRANSIT
                else "western" if rep_code in WESTERN else "control")

        for hs6, tier in ALL_CODES.items():
            is_chpl = hs6 in CHPL
            for year in YEARS:
                counter += 1
                if counter % 200 == 0:
                    print(f"  {counter}/{total} ({100*counter/total:.0f}%) {rep_name}")

                result = fetch_one(rep_code, hs6, year)

                if result.get("data"):
                    for rec in result["data"]:
                        rows.append({
                            "reporter_code": rep_code, "reporter_name": rep_name,
                            "role": role, "hs6": hs6, "tier": tier if is_chpl else "non_CHPL",
                            "is_chpl": int(is_chpl), "year": year,
                            "fob_value": rec.get("primaryValue", 0) or 0,
                            "net_weight_kg": rec.get("netWgt", 0) or 0,
                            "qty": rec.get("qty", 0) or 0,
                        })
                else:
                    rows.append({
                        "reporter_code": rep_code, "reporter_name": rep_name,
                        "role": role, "hs6": hs6, "tier": tier if is_chpl else "non_CHPL",
                        "is_chpl": int(is_chpl), "year": year,
                        "fob_value": 0, "net_weight_kg": 0, "qty": 0,
                    })

        print(f"  Done: {rep_name} ({role})")

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
        for code, name in ALL_REPORTERS.items():
            role = ("transit" if code in TRANSIT
                    else "western" if code in WESTERN else "control")
            w.writerow({"code": code, "name": name, "role": role})

    pos = sum(1 for r in rows if r["fob_value"] > 0)
    chpl_pos = sum(1 for r in rows if r["is_chpl"] and r["fob_value"] > 0)
    print(f"\nTotal rows: {len(rows)}")
    print(f"Positive trade: {pos} ({100*pos/len(rows):.1f}%)")
    print(f"CHPL positive: {chpl_pos}")
    print(f"Reporters: {len(set(r['reporter_code'] for r in rows))}")

    assert len(set(r["reporter_code"] for r in rows)) >= 10
    assert chpl_pos > 0
    print("VALIDATION PASSED")


if __name__ == "__main__":
    main()
