"""01_fetch_data.py — Download, extract, and merge DANE GEIH microdata (2011-2016).

Handles Latin-1 encoding issues in zip filenames by using Python's zipfile module.
Extracts Ocupados (employment) and Características generales (demographics) modules,
merges them on person identifiers, and saves as CSV for R consumption.
Handles both .sav (SPSS) and .txt (tab-delimited) file formats across years.
"""
import os
import io
import json
import tempfile
import requests
import zipfile
import pandas as pd
import pyreadstat
import sys

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
RAW_DIR = os.path.join(DATA_DIR, "raw_geih")
os.makedirs(RAW_DIR, exist_ok=True)

# Load URL manifest
with open(os.path.join(DATA_DIR, "geih_download_urls.json")) as f:
    manifest = json.load(f)

MERGE_KEYS = ["DIRECTORIO", "SECUENCIA_P", "ORDEN"]

# Key variables to keep
OCUPADOS_VARS = MERGE_KEYS + [
    "AREA", "DPTO", "CLASE",
    "P6430", "P6440", "P6450", "P6460", "P6426",
    "P6870", "P6500", "P6510", "P6800",
    "P6424S1", "P6424S2", "P6424S3",
    "P6630S1", "P6630S2", "P6630S3",
    "P6920", "P6090",
    "RAMA4D", "RAMA2D",
]

CARACT_VARS = MERGE_KEYS + [
    "P6040", "P6020", "P6210", "P6210S1",
]

WEIGHT_PATTERNS = ["FEX_C18", "FEX_C11", "FEX_C05", "FEXC_C18", "FEX"]


def find_file_in_zip(z, keyword1, keyword2=None, exclude_keyword=None):
    """Find a file in zip matching keywords, handling encoding issues."""
    results = []
    for name in z.namelist():
        if name.endswith('/'):  # skip directories
            continue
        name_lower = name.lower()
        name_ascii = name_lower.encode('latin-1', errors='ignore').decode('ascii', errors='ignore')

        if exclude_keyword:
            if exclude_keyword.lower() in name_lower or exclude_keyword.lower() in name_ascii:
                continue

        k1_match = keyword1.lower() in name_lower or keyword1.lower() in name_ascii
        if keyword2:
            k2_match = keyword2.lower() in name_lower or keyword2.lower() in name_ascii
            if k1_match and k2_match:
                results.append(name)
        elif k1_match:
            results.append(name)
    return results[0] if results else None


def read_file_from_zip(z, filename):
    """Read a data file from zip — handles both .sav and .txt formats."""
    data = z.read(filename)

    if filename.lower().endswith('.sav'):
        # Write to temp file for pyreadstat
        with tempfile.NamedTemporaryFile(suffix='.sav', delete=False) as tmp:
            tmp.write(data)
            tmp_path = tmp.name
        try:
            df, meta = pyreadstat.read_sav(tmp_path)
        finally:
            os.unlink(tmp_path)
    else:
        # Tab-delimited text
        content = data.decode('latin-1')
        df = pd.read_csv(io.StringIO(content), sep='\t', low_memory=False)

    df.columns = [c.upper().strip() for c in df.columns]
    return df


def process_month(year, month_idx, url_info):
    """Download, extract, merge Ocupados + Características for one month."""
    csv_path = os.path.join(RAW_DIR, f"merged_{year}_{month_idx:02d}.csv")

    if os.path.exists(csv_path):
        print(f"  [cached] {year}/{month_idx:02d}")
        return csv_path

    url = url_info["url"]
    month_name = url_info["month_name"]

    print(f"  Downloading {year} {month_name}...", end="", flush=True)

    resp = requests.get(url, timeout=300)
    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code} for {year}/{month_idx:02d}")

    print(f" {len(resp.content)/1e6:.1f}MB...", end="", flush=True)

    z = zipfile.ZipFile(io.BytesIO(resp.content))

    # Find Area Ocupados (preferred), exclude Desocupados
    occ_file = find_file_in_zip(z, "rea", "ocupados", exclude_keyword="desocupados")
    if not occ_file:
        occ_file = find_file_in_zip(z, "cabecera", "ocupados", exclude_keyword="desocupados")
    if not occ_file:
        occ_file = find_file_in_zip(z, "ocupados", exclude_keyword="desocupados")
    if not occ_file:
        raise RuntimeError(f"No Ocupados file in {year}/{month_idx:02d}")

    # Find Area Características
    car_file = find_file_in_zip(z, "rea", "caracter")
    if not car_file:
        car_file = find_file_in_zip(z, "cabecera", "caracter")
    if not car_file:
        car_file = find_file_in_zip(z, "caracter")

    # Read Ocupados
    df_occ = read_file_from_zip(z, occ_file)
    print(f" occ={len(df_occ)}r", end="", flush=True)

    # Keep only needed columns (plus any weight variable)
    occ_available = [c for c in OCUPADOS_VARS if c in df_occ.columns]
    weight_col = None
    for wp in WEIGHT_PATTERNS:
        matches = [c for c in df_occ.columns if wp in c.upper()]
        if matches:
            weight_col = matches[0]
            break
    if weight_col and weight_col not in occ_available:
        occ_available.append(weight_col)
    df_occ = df_occ[occ_available]

    # Read and merge Características if available
    if car_file:
        df_car = read_file_from_zip(z, car_file)
        print(f" car={len(df_car)}r", end="", flush=True)
        car_available = [c for c in CARACT_VARS if c in df_car.columns]
        df_car = df_car[car_available]

        merge_keys_available = [k for k in MERGE_KEYS if k in df_occ.columns and k in df_car.columns]
        if merge_keys_available:
            df = df_occ.merge(df_car, on=merge_keys_available, how="left")
        else:
            print(" NO MERGE KEYS!", end="")
            df = df_occ
    else:
        print(" no car file", end="")
        df = df_occ

    # Add time identifiers
    df["YEAR"] = int(year)
    df["MONTH"] = int(month_idx)

    # Rename weight column for consistency
    if weight_col and weight_col != "FEX_C18":
        df = df.rename(columns={weight_col: "FEX_C18"})

    df.to_csv(csv_path, index=False)
    print(f" -> {len(df)} rows saved")

    return csv_path


# ---- Main loop ----
all_files = []
failures = []

# Only process 2011-2016 (drop 2010 for geographic consistency)
for year in sorted(manifest.keys()):
    if int(year) < 2011:
        print(f"\n=== Skipping {year} (geographic inconsistency) ===")
        continue

    print(f"\n=== GEIH {year} ===")
    months = manifest[year]
    for mk in sorted(months.keys()):
        m_idx = int(mk)
        try:
            csv_path = process_month(year, m_idx, months[mk])
            all_files.append(csv_path)
        except Exception as e:
            print(f"  FATAL ERROR: {e}")
            failures.append(f"{year}/{m_idx:02d}")

if failures:
    print(f"\nFATAL: Failed to process: {', '.join(failures)}")
    sys.exit(1)

# ---- Combine all months ----
print(f"\nCombining {len(all_files)} monthly files...")
dfs = []
for f in all_files:
    df = pd.read_csv(f, low_memory=False)
    dfs.append(df)

combined = pd.concat(dfs, ignore_index=True)
print(f"Total observations: {len(combined):,}")
print(f"Years: {sorted(combined['YEAR'].unique())}")
print(f"Columns: {list(combined.columns)}")

# Check key variables
for v in ["P6500", "P6870", "P6424S1", "P6920", "P6040", "P6020", "P6210"]:
    if v in combined.columns:
        non_na = combined[v].notna().sum()
        print(f"  {v}: {non_na:,} non-NA ({100*non_na/len(combined):.1f}%)")
    else:
        print(f"  {v}: NOT FOUND")

# Save combined CSV for R
combined_path = os.path.join(DATA_DIR, "geih_combined_2011_2016.csv")
combined.to_csv(combined_path, index=False)
print(f"\nSaved: {combined_path} ({os.path.getsize(combined_path)/1e6:.1f} MB)")

# Validate
if len(combined) < 50000:
    print("FATAL: Combined dataset too small. Something went wrong.")
    sys.exit(1)

print("\n=== Data fetch complete ===")
