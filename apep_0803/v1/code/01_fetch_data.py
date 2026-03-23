"""01_fetch_data.py — Extract QWI data from Azure for apep_0803.

Uses Python DuckDB (which works with Azure) to query and save data locally.
R DuckDB has a bug with Azure az:// URLs, so we extract here.
"""

import duckdb
import os
import sys

# Load .env
env_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", ".env")
conn_str = ""
with open(env_path) as f:
    for line in f:
        if line.startswith("AZURE_STORAGE_CONNECTION_STRING="):
            conn_str = line.strip().split("=", 1)[1]
            break

if not conn_str:
    print("FATAL: No Azure connection string found")
    sys.exit(1)

data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(data_dir, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL azure; LOAD azure;")
con.execute(f"CREATE SECRET az (TYPE azure, CONNECTION_STRING '{conn_str}')")

print("=== DATA ACQUISITION START ===")

# ─────────────────────────────────────────────────────────
# 1. QWI Race-Ethnicity Healthcare Panel (NAICS 62)
# ─────────────────────────────────────────────────────────
print("\n--- 1. QWI Race-Ethnicity Healthcare Panel ---")

# List state files
states = [
    "al", "ak", "az", "ar", "ca", "co", "ct", "dc", "de", "fl",
    "ga", "hi", "id", "il", "in", "ia", "ks", "ky", "la", "me",
    "md", "ma", "mi", "mn", "ms", "mo", "mt", "ne", "nv", "nh",
    "nj", "nm", "ny", "nc", "nd", "oh", "ok", "or", "pa", "ri",
    "sc", "sd", "tn", "tx", "ut", "vt", "va", "wa", "wv", "wi", "wy"
]

# Query all states for NAICS 62 (Healthcare), county-level, aggregate to state×quarter×race
# Use glob to read all files at once
print("  Querying all states for NAICS 62...")

qwi_hc = con.execute("""
    SELECT
        geography AS fips,
        year,
        quarter,
        race,
        ethnicity,
        industry,
        Emp AS emp,
        EmpEnd AS emp_end,
        HirA AS hires_all,
        HirN AS hires_new,
        Sep AS separations,
        EarnHirAS AS avg_earnings_new_hires,
        EarnBeg AS avg_earnings_beginning
    FROM 'az://derived/qwi/rh/ns/*.parquet'
    WHERE geo_level = 'C'
      AND industry = '62'
      AND year BETWEEN 2001 AND 2023
      AND ownercode = 'A05'
      AND agegrp = 'A00'
      AND sex = '0'
      AND education = 'E0'
""").fetchdf()

print(f"  Healthcare rows: {len(qwi_hc):,}")
print(f"  Years: {sorted(qwi_hc['year'].unique())}")
print(f"  Race codes: {sorted(qwi_hc['race'].unique())}")
print(f"  Counties: {qwi_hc['fips'].nunique()}")

out_path = os.path.join(data_dir, "qwi_healthcare_race.csv")
qwi_hc.to_csv(out_path, index=False)
print(f"  Saved to {out_path} ({os.path.getsize(out_path)/1e6:.1f} MB)")

# ─────────────────────────────────────────────────────────
# 2. QWI Retail Placebo (NAICS 44-45)
# ─────────────────────────────────────────────────────────
print("\n--- 2. QWI Retail Placebo Panel ---")

qwi_retail = con.execute("""
    SELECT
        geography AS fips,
        year,
        quarter,
        race,
        ethnicity,
        industry,
        Emp AS emp,
        EmpEnd AS emp_end,
        HirA AS hires_all,
        Sep AS separations,
        EarnHirAS AS avg_earnings_new_hires
    FROM 'az://derived/qwi/rh/ns/*.parquet'
    WHERE geo_level = 'C'
      AND industry = '44-45'
      AND year BETWEEN 2001 AND 2023
      AND ownercode = 'A05'
      AND agegrp = 'A00'
      AND sex = '0'
      AND education = 'E0'
""").fetchdf()

print(f"  Retail rows: {len(qwi_retail):,}")
out_path = os.path.join(data_dir, "qwi_retail_race.csv")
qwi_retail.to_csv(out_path, index=False)
print(f"  Saved to {out_path}")

# ─────────────────────────────────────────────────────────
# 3. QWI Total (all industries, NAICS 00) for normalization
# ─────────────────────────────────────────────────────────
print("\n--- 3. QWI Total Employment Panel ---")

qwi_total = con.execute("""
    SELECT
        geography AS fips,
        year,
        quarter,
        race,
        ethnicity,
        SUM(Emp) AS emp_total,
        SUM(EmpEnd) AS emp_end_total
    FROM 'az://derived/qwi/rh/ns/*.parquet'
    WHERE geo_level = 'C'
      AND year BETWEEN 2001 AND 2023
      AND ownercode = 'A05'
      AND agegrp = 'A00'
      AND sex = '0'
      AND education = 'E0'
    GROUP BY geography, year, quarter, race, ethnicity
""").fetchdf()

print(f"  Total rows: {len(qwi_total):,}")
out_path = os.path.join(data_dir, "qwi_total_race.csv")
qwi_total.to_csv(out_path, index=False)
print(f"  Saved to {out_path}")

con.close()

print("\n=== DATA ACQUISITION COMPLETE ===")
