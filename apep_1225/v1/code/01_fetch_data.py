#!/usr/bin/env python3
"""01_fetch_data.py — Fetch police.uk data from bulk archives.

Downloads monthly ZIP archives one at a time, extracts crime and S&S data,
aggregates to force-month level, then deletes the ZIP to save disk space.
"""

import json
import os
import sys
import time
import csv
import zipfile
import io
from urllib.request import urlopen, Request

sys.stdout.reconfigure(line_buffering=True)

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

MONTHS = []
for y in range(2018, 2021):
    for m in range(1, 13):
        d = f"{y}-{m:02d}"
        if "2018-01" <= d <= "2020-02":
            MONTHS.append(d)

print(f"Processing {len(MONTHS)} months: {MONTHS[0]} to {MONTHS[-1]}")

# Crime categories we care about
CRIME_MAP = {
    "Possession of weapons": "weapons_crime",
    "Violence and sexual offences": "violent_crime",
    "Shoplifting": "shoplifting",
    "Other theft": "other_theft",
    "Bicycle theft": "bicycle_theft",
    "Criminal damage and arson": "criminal_damage",
    "Public order": "public_order",
    "Drugs": "drugs",
}

all_ss = []  # stop-and-search force-month aggregates
all_crime = []  # crime force-month aggregates

for month in MONTHS:
    zip_url = f"https://data.police.uk/data/archive/{month}.zip"
    zip_path = os.path.join(DATA_DIR, f"{month}.zip")

    print(f"\n--- {month} ---")
    print(f"Downloading {zip_url}...")
    start = time.time()

    try:
        req = Request(zip_url, headers={"User-Agent": "APEP-Research/1.0"})
        resp = urlopen(req, timeout=300)
        with open(zip_path, "wb") as f:
            while True:
                chunk = resp.read(1024 * 1024)  # 1MB chunks
                if not chunk:
                    break
                f.write(chunk)
        elapsed = time.time() - start
        size_mb = os.path.getsize(zip_path) / 1e6
        print(f"  Downloaded {size_mb:.0f}MB in {elapsed:.0f}s")
    except Exception as e:
        print(f"  DOWNLOAD FAILED: {e}")
        if os.path.exists(zip_path):
            os.remove(zip_path)
        continue

    # Process ZIP
    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            file_list = zf.namelist()
            ss_files = [f for f in file_list if "stop-and-search" in f.lower() and f.endswith(".csv")]
            crime_files = [f for f in file_list if f.endswith("-street.csv")]

            print(f"  Files: {len(ss_files)} S&S, {len(crime_files)} crime")

            # --- Process stop-and-search ---
            ss_force_counts = {}
            for fname in ss_files:
                # Extract force from filename
                # Pattern: YYYY-MM/{YYYY-MM-}{force-name}-stop-and-search.csv
                basename = fname.split("/")[-1]
                # Remove date prefix and suffix
                force = basename
                force = force.replace(f"{month}-", "", 1)  # Remove date prefix
                force = force.replace("-stop-and-search.csv", "")
                force = force.lower()

                try:
                    with zf.open(fname) as csvfile:
                        reader = csv.DictReader(io.TextIOWrapper(csvfile, encoding="utf-8-sig"))
                        for row in reader:
                            if force not in ss_force_counts:
                                ss_force_counts[force] = {"total": 0, "s60": 0, "weapon": 0, "s60_weapon": 0}
                            ss_force_counts[force]["total"] += 1
                            leg = (row.get("Legislation") or row.get("Type") or "").lower()
                            obj = (row.get("Object of search") or "").lower()
                            is_s60 = "criminal justice" in leg or "section 60" in leg
                            is_wep = any(w in obj for w in ["weapon", "knife", "blade", "point", "offensive"])
                            if is_s60:
                                ss_force_counts[force]["s60"] += 1
                            if is_wep:
                                ss_force_counts[force]["weapon"] += 1
                            if is_s60 and is_wep:
                                ss_force_counts[force]["s60_weapon"] += 1
                except Exception as e:
                    print(f"    Error reading {fname}: {e}")

            for force, counts in ss_force_counts.items():
                all_ss.append({
                    "force": force, "month": month,
                    "total_stops": counts["total"], "s60_stops": counts["s60"],
                    "weapon_stops": counts["weapon"], "s60_weapon_stops": counts["s60_weapon"]
                })

            # --- Process crime data ---
            crime_force_counts = {}
            for fname in crime_files:
                basename = fname.split("/")[-1]
                force = basename.replace(f"{month}-", "", 1).replace("-street.csv", "").lower()

                try:
                    with zf.open(fname) as csvfile:
                        reader = csv.DictReader(io.TextIOWrapper(csvfile, encoding="utf-8-sig"))
                        for row in reader:
                            crime_type = row.get("Crime type", "")
                            if crime_type in CRIME_MAP:
                                if force not in crime_force_counts:
                                    crime_force_counts[force] = {v: 0 for v in CRIME_MAP.values()}
                                crime_force_counts[force][CRIME_MAP[crime_type]] += 1
                except Exception as e:
                    print(f"    Error reading {fname}: {e}")

            for force, counts in crime_force_counts.items():
                row = {"force": force, "month": month}
                row.update(counts)
                all_crime.append(row)

            total_ss = sum(c["total"] for c in ss_force_counts.values())
            total_s60 = sum(c["s60"] for c in ss_force_counts.values())
            n_forces_crime = len(crime_force_counts)
            print(f"  S&S: {len(ss_force_counts)} forces, {total_ss:,} stops ({total_s60} S60)")
            print(f"  Crime: {n_forces_crime} forces")

    except Exception as e:
        print(f"  ZIP PROCESSING FAILED: {e}")

    # Delete ZIP to save disk space
    os.remove(zip_path)
    print(f"  Cleaned up ZIP")

# --- Write output files ---
print("\n=== WRITING OUTPUT FILES ===")

# Stop-and-search
ss_path = os.path.join(DATA_DIR, "ss_force_month.csv")
with open(ss_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["force", "month", "total_stops", "s60_stops",
                                           "weapon_stops", "s60_weapon_stops"])
    writer.writeheader()
    for r in sorted(all_ss, key=lambda x: (x["force"], x["month"])):
        writer.writerow(r)
print(f"S&S: {len(all_ss)} force-months -> {ss_path}")

# Crime
crime_cols = ["force", "month", "weapons_crime", "violent_crime", "shoplifting",
              "other_theft", "bicycle_theft", "criminal_damage", "public_order", "drugs"]
crime_path = os.path.join(DATA_DIR, "crime_force_month.csv")
with open(crime_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=crime_cols, extrasaction="ignore")
    writer.writeheader()
    for r in sorted(all_crime, key=lambda x: (x["force"], x["month"])):
        # Fill missing with 0
        for c in crime_cols[2:]:
            r.setdefault(c, 0)
        writer.writerow(r)
print(f"Crime: {len(all_crime)} force-months -> {crime_path}")

# --- Static data (population + contiguity) ---
force_pop = {
    "avon-and-somerset": 1720000, "bedfordshire": 685000, "cambridgeshire": 872000,
    "cheshire": 1063000, "city-of-london": 9000, "cleveland": 570000,
    "cumbria": 499000, "derbyshire": 1058000, "devon-and-cornwall": 1790000,
    "dorset": 776000, "durham": 637000, "dyfed-powys": 522000,
    "essex": 1860000, "gloucestershire": 640000, "greater-manchester": 2840000,
    "gwent": 598000, "hampshire": 2010000, "hertfordshire": 1195000,
    "humberside": 935000, "kent": 1870000, "lancashire": 1510000,
    "leicestershire": 1100000, "lincolnshire": 770000, "merseyside": 1440000,
    "metropolitan": 9000000, "norfolk": 910000, "north-wales": 700000,
    "north-yorkshire": 830000, "northamptonshire": 757000, "northumbria": 1470000,
    "nottinghamshire": 1160000, "south-wales": 1340000, "south-yorkshire": 1400000,
    "staffordshire": 1140000, "suffolk": 765000, "surrey": 1200000,
    "sussex": 1710000, "thames-valley": 2420000, "warwickshire": 580000,
    "west-mercia": 1300000, "west-midlands": 2930000, "west-yorkshire": 2340000,
    "wiltshire": 730000
}

pop_path = os.path.join(DATA_DIR, "force_population.csv")
with open(pop_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["force", "population"])
    writer.writeheader()
    for force, pop in sorted(force_pop.items()):
        writer.writerow({"force": force, "population": pop})

contiguity = {
    "metropolitan": ["city-of-london", "essex", "hertfordshire", "surrey", "sussex", "kent", "thames-valley", "bedfordshire"],
    "west-midlands": ["staffordshire", "warwickshire", "west-mercia"],
    "greater-manchester": ["lancashire", "cheshire", "derbyshire", "west-yorkshire"],
    "merseyside": ["lancashire", "cheshire"],
    "south-yorkshire": ["west-yorkshire", "north-yorkshire", "humberside", "derbyshire", "nottinghamshire"],
    "south-wales": ["gwent", "dyfed-powys"],
    "west-yorkshire": ["greater-manchester", "lancashire", "north-yorkshire", "south-yorkshire"],
    "avon-and-somerset": ["gloucestershire", "wiltshire", "dorset", "devon-and-cornwall"],
    "bedfordshire": ["hertfordshire", "cambridgeshire", "northamptonshire", "thames-valley", "metropolitan"],
    "cambridgeshire": ["bedfordshire", "hertfordshire", "essex", "suffolk", "norfolk", "lincolnshire", "northamptonshire"],
    "cheshire": ["greater-manchester", "merseyside", "north-wales", "staffordshire", "derbyshire"],
    "cleveland": ["durham", "north-yorkshire"],
    "cumbria": ["lancashire", "north-yorkshire", "northumbria", "durham"],
    "derbyshire": ["greater-manchester", "south-yorkshire", "nottinghamshire", "leicestershire", "staffordshire", "cheshire", "west-mercia"],
    "devon-and-cornwall": ["avon-and-somerset", "dorset"],
    "dorset": ["devon-and-cornwall", "avon-and-somerset", "wiltshire", "hampshire"],
    "durham": ["northumbria", "cumbria", "cleveland", "north-yorkshire"],
    "dyfed-powys": ["south-wales", "gwent", "north-wales", "west-mercia"],
    "essex": ["metropolitan", "hertfordshire", "cambridgeshire", "suffolk", "kent"],
    "gloucestershire": ["avon-and-somerset", "wiltshire", "thames-valley", "west-mercia", "warwickshire"],
    "gwent": ["south-wales", "dyfed-powys", "west-mercia"],
    "hampshire": ["dorset", "wiltshire", "thames-valley", "surrey", "sussex"],
    "hertfordshire": ["metropolitan", "bedfordshire", "cambridgeshire", "essex", "thames-valley"],
    "humberside": ["south-yorkshire", "north-yorkshire", "lincolnshire"],
    "kent": ["metropolitan", "essex", "surrey", "sussex"],
    "lancashire": ["greater-manchester", "merseyside", "west-yorkshire", "north-yorkshire", "cumbria"],
    "leicestershire": ["derbyshire", "nottinghamshire", "lincolnshire", "northamptonshire", "warwickshire", "west-mercia", "staffordshire"],
    "lincolnshire": ["humberside", "south-yorkshire", "nottinghamshire", "leicestershire", "northamptonshire", "cambridgeshire", "norfolk"],
    "norfolk": ["cambridgeshire", "suffolk", "lincolnshire"],
    "north-wales": ["cheshire", "dyfed-powys", "west-mercia"],
    "north-yorkshire": ["west-yorkshire", "south-yorkshire", "humberside", "cleveland", "durham", "cumbria", "lancashire"],
    "northamptonshire": ["bedfordshire", "cambridgeshire", "leicestershire", "warwickshire", "thames-valley", "west-mercia", "lincolnshire"],
    "northumbria": ["durham", "cumbria"],
    "nottinghamshire": ["south-yorkshire", "derbyshire", "leicestershire", "lincolnshire"],
    "staffordshire": ["cheshire", "derbyshire", "leicestershire", "west-mercia", "west-midlands", "warwickshire"],
    "suffolk": ["norfolk", "cambridgeshire", "essex"],
    "surrey": ["metropolitan", "hampshire", "kent", "sussex", "thames-valley"],
    "sussex": ["metropolitan", "kent", "surrey", "hampshire"],
    "thames-valley": ["metropolitan", "hertfordshire", "bedfordshire", "northamptonshire", "warwickshire", "gloucestershire", "wiltshire", "hampshire", "surrey"],
    "warwickshire": ["west-midlands", "staffordshire", "leicestershire", "northamptonshire", "thames-valley", "gloucestershire", "west-mercia"],
    "west-mercia": ["west-midlands", "staffordshire", "warwickshire", "gloucestershire", "dyfed-powys", "gwent", "north-wales", "cheshire", "derbyshire", "leicestershire", "northamptonshire"],
    "wiltshire": ["avon-and-somerset", "dorset", "hampshire", "thames-valley", "gloucestershire"],
    "city-of-london": ["metropolitan"]
}

cont_path = os.path.join(DATA_DIR, "contiguity.json")
with open(cont_path, "w") as f:
    json.dump(contiguity, f, indent=2)

print(f"\nPopulation: {len(force_pop)} forces")
print(f"Contiguity: {len(contiguity)} forces")
print("\n=== ALL DATA FETCHED ===")
total_ss = sum(r["total_stops"] for r in all_ss)
total_s60 = sum(r["s60_stops"] for r in all_ss)
print(f"Total S&S records processed: {total_ss:,}")
print(f"Total S60 records: {total_s60:,}")
print(f"Total crime force-months: {len(all_crime)}")
