#!/usr/bin/env python3
"""
01_fetch_data.py — Download and aggregate MOT test results (2017-2023)

Streams each year's ZIP from data.dft.gov.uk, uses system unzip,
aggregates to postcode_area × year × fuel_type level, saves a small CSV.
Processes line-by-line to stay within 8GB RAM.
"""

import csv
import os
import sys
import json
import subprocess
import urllib.request
from collections import defaultdict
from datetime import datetime

# Increase CSV field size limit for large fields in some years
csv.field_size_limit(sys.maxsize)

BASE_URL = "https://data.dft.gov.uk/anonymised-mot-test/test_data"
YEARS = range(2017, 2024)  # 2017-2023
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
TMP_DIR = os.path.join(OUT_DIR, "tmp")

# ULEZ/CAZ treatment mapping: postcode_area -> (treatment_wave, start_date)
TREATMENT_MAP = {}
for pc in ["EC", "WC"]:
    TREATMENT_MAP[pc] = ("phase1_central", "2019-04-08")
for pc in ["E", "N", "NW", "W", "SE", "SW"]:
    TREATMENT_MAP[pc] = ("phase2_inner", "2021-10-25")
TREATMENT_MAP["B"] = ("phase3_birmingham", "2021-06-01")
TREATMENT_MAP["BS"] = ("phase4_bristol", "2022-11-28")
for pc in ["BR", "CR", "DA", "EN", "HA", "IG", "KT", "RM", "SM", "TW", "UB", "WD"]:
    TREATMENT_MAP[pc] = ("phase5_outer", "2023-08-29")


def extract_postcode_area(postcode_str):
    if not postcode_str:
        return None
    pc = postcode_str.strip().upper()
    area = ""
    for ch in pc:
        if ch.isalpha():
            area += ch
        else:
            break
    return area if area else None


def classify_fuel(fuel_str):
    if not fuel_str:
        return "other"
    f = fuel_str.strip().upper()
    if f in ("PE", "PETROL"):
        return "petrol"
    elif f in ("DI", "DIESEL"):
        return "diesel"
    return "other"


def get_vehicle_age(first_use_date_str, test_year):
    if not first_use_date_str:
        return None
    try:
        yr = int(first_use_date_str.strip()[:4])
        age = test_year - yr
        return age if 0 <= age <= 50 else None
    except (ValueError, IndexError):
        return None


def is_euro4_era(first_use_date_str):
    if not first_use_date_str:
        return False
    try:
        yr = int(first_use_date_str.strip()[:4])
        return 2006 <= yr <= 2010
    except (ValueError, IndexError):
        return False


def process_year(year):
    """Download, extract, and stream-aggregate one year of MOT data."""
    url = f"{BASE_URL}/dft_test_result_{year}.zip"
    zip_path = os.path.join(TMP_DIR, f"dft_test_result_{year}.zip")
    os.makedirs(TMP_DIR, exist_ok=True)

    print(f"\n[{year}] Downloading from {url}...")
    sys.stdout.flush()

    try:
        urllib.request.urlretrieve(url, zip_path)
    except Exception as e:
        print(f"[{year}] DOWNLOAD FAILED: {e}")
        return None

    file_size_mb = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"[{year}] Downloaded: {file_size_mb:.0f} MB")
    sys.stdout.flush()

    # Extract using system unzip
    extract_dir = os.path.join(TMP_DIR, f"extract_{year}")
    os.makedirs(extract_dir, exist_ok=True)

    print(f"[{year}] Extracting...")
    sys.stdout.flush()
    result = subprocess.run(
        ["unzip", "-o", "-q", zip_path, "-d", extract_dir],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        # Try 7z as fallback
        print(f"[{year}] unzip failed ({result.stderr.strip()}), trying 7z...")
        result = subprocess.run(
            ["7z", "x", "-y", f"-o{extract_dir}", zip_path],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"[{year}] EXTRACTION FAILED: {result.stderr}")
            return None

    # Remove ZIP to free disk space
    os.remove(zip_path)
    print(f"[{year}] ZIP removed, processing CSV...")
    sys.stdout.flush()

    # Find the CSV file(s)
    csv_files = []
    for root, dirs, files in os.walk(extract_dir):
        for f in files:
            if f.endswith('.csv'):
                csv_files.append(os.path.join(root, f))

    if not csv_files:
        print(f"[{year}] No CSV found after extraction!")
        return None

    # Aggregate counters
    agg = defaultdict(lambda: {
        "n_tests": 0, "n_fail": 0, "n_pass": 0, "n_prs": 0,
        "total_mileage": 0, "n_mileage": 0,
        "total_age": 0, "n_age": 0,
        "euro4_tests": 0, "euro4_fail": 0,
    })

    row_count = 0
    header = None

    for csv_path in csv_files:
        csv_size_mb = os.path.getsize(csv_path) / (1024 * 1024)
        print(f"[{year}] Reading {os.path.basename(csv_path)} ({csv_size_mb:.0f} MB)")
        sys.stdout.flush()

        with open(csv_path, 'r', encoding='utf-8', errors='replace') as f:
            # Auto-detect delimiter from first line
            first_line = f.readline()
            if '|' in first_line and first_line.count('|') > first_line.count(','):
                delimiter = '|'
            else:
                delimiter = ','
            f.seek(0)

            reader = csv.reader(f, delimiter=delimiter)
            header = next(reader)
            # Normalize header
            header = [h.strip().lower() for h in header]

            # Find column indices
            col_map = {h: i for i, h in enumerate(header)}

            # Print header for debugging (first year only)
            if year == 2017 and row_count == 0:
                print(f"[{year}] Columns: {header}")

            for fields in reader:
                row_count += 1
                if row_count % 5_000_000 == 0:
                    print(f"[{year}]   ...{row_count:,} rows")
                    sys.stdout.flush()

                try:
                    # Postcode area
                    pc_area = None
                    if 'postcode_area' in col_map:
                        pc_area = extract_postcode_area(fields[col_map['postcode_area']])
                    if not pc_area and 'postcode' in col_map:
                        pc_area = extract_postcode_area(fields[col_map['postcode']])
                    if not pc_area:
                        continue

                    # Fuel type
                    fuel = classify_fuel(fields[col_map['fuel_type']] if 'fuel_type' in col_map else '')

                    # Test result
                    result_str = fields[col_map.get('test_result', -1)].strip().upper() if 'test_result' in col_map else ''

                    key = (pc_area, fuel)
                    d = agg[key]
                    d["n_tests"] += 1

                    if result_str == "F":
                        d["n_fail"] += 1
                    elif result_str == "P":
                        d["n_pass"] += 1
                    elif result_str == "PRS":
                        d["n_prs"] += 1

                    # Mileage
                    if 'test_mileage' in col_map:
                        try:
                            mil = int(fields[col_map['test_mileage']])
                            if 0 < mil < 500000:
                                d["total_mileage"] += mil
                                d["n_mileage"] += 1
                        except (ValueError, TypeError):
                            pass

                    # Vehicle age
                    fud = fields[col_map['first_use_date']] if 'first_use_date' in col_map else ''
                    age = get_vehicle_age(fud, year)
                    if age is not None:
                        d["total_age"] += age
                        d["n_age"] += 1

                    # Euro 4 era subgroup
                    if is_euro4_era(fud):
                        d["euro4_tests"] += 1
                        if result_str == "F":
                            d["euro4_fail"] += 1
                except (IndexError, KeyError):
                    continue

        # Remove CSV after processing to free disk
        os.remove(csv_path)
        print(f"[{year}] CSV removed")

    # Clean up extract directory
    subprocess.run(["rm", "-rf", extract_dir], capture_output=True)

    print(f"[{year}] Total rows: {row_count:,}, Unique keys: {len(agg)}")
    return {"year": year, "agg": dict(agg), "total_rows": row_count}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    all_rows = []
    total_microdata_rows = 0

    for year in YEARS:
        result = process_year(year)
        if result is None:
            print(f"\n*** FATAL: Could not process year {year}. ***")
            sys.exit(1)

        total_microdata_rows += result["total_rows"]

        for (pc_area, fuel), d in result["agg"].items():
            treated_info = TREATMENT_MAP.get(pc_area, ("never", ""))
            all_rows.append({
                "year": year,
                "postcode_area": pc_area,
                "fuel_type": fuel,
                "n_tests": d["n_tests"],
                "n_fail": d["n_fail"],
                "n_pass": d["n_pass"],
                "n_prs": d["n_prs"],
                "fail_rate": round(d["n_fail"] / d["n_tests"], 6) if d["n_tests"] > 0 else None,
                "avg_mileage": round(d["total_mileage"] / d["n_mileage"], 1) if d["n_mileage"] > 0 else None,
                "avg_age": round(d["total_age"] / d["n_age"], 2) if d["n_age"] > 0 else None,
                "euro4_tests": d["euro4_tests"],
                "euro4_fail": d["euro4_fail"],
                "euro4_fail_rate": round(d["euro4_fail"] / d["euro4_tests"], 6) if d["euro4_tests"] > 0 else None,
                "treatment_wave": treated_info[0],
                "treatment_date": treated_info[1],
            })

    # Write aggregated panel
    out_path = os.path.join(OUT_DIR, "mot_panel.csv")
    fieldnames = [
        "year", "postcode_area", "fuel_type",
        "n_tests", "n_fail", "n_pass", "n_prs", "fail_rate",
        "avg_mileage", "avg_age",
        "euro4_tests", "euro4_fail", "euro4_fail_rate",
        "treatment_wave", "treatment_date",
    ]

    with open(out_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_rows)

    print(f"\n{'='*60}")
    print(f"Panel written: {out_path}")
    print(f"Total microdata rows processed: {total_microdata_rows:,}")
    print(f"Panel rows: {len(all_rows):,}")
    print(f"Unique postcode areas: {len(set(r['postcode_area'] for r in all_rows))}")
    print(f"Years: {min(r['year'] for r in all_rows)}-{max(r['year'] for r in all_rows)}")

    # Write diagnostics
    diag = {
        "total_microdata_rows": total_microdata_rows,
        "panel_rows": len(all_rows),
        "years": list(YEARS),
        "n_postcode_areas": len(set(r['postcode_area'] for r in all_rows)),
        "n_treated_areas": len(set(
            r['postcode_area'] for r in all_rows if r['treatment_wave'] != 'never'
        )),
        "n_never_treated": len(set(
            r['postcode_area'] for r in all_rows if r['treatment_wave'] == 'never'
        )),
    }
    diag_path = os.path.join(OUT_DIR, "fetch_diagnostics.json")
    with open(diag_path, 'w') as f:
        json.dump(diag, f, indent=2)
    print(f"Diagnostics: {json.dumps(diag, indent=2)}")

    # Clean up tmp
    subprocess.run(["rm", "-rf", TMP_DIR], capture_output=True)


if __name__ == "__main__":
    main()
