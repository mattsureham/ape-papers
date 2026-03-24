"""Extract QWI data from Azure via DuckDB (Python).
Run this before 01_fetch_data.R — saves CSV files to data/.
"""
import duckdb
import os
import sys

# Load .env
env_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '.env')
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            key, val = line.split('=', 1)
            key = key.replace('export ', '')
            val = val.strip('"').strip("'")
            os.environ[key] = val

conn_str = os.environ.get('AZURE_STORAGE_CONNECTION_STRING', '')
if not conn_str:
    print("ERROR: AZURE_STORAGE_CONNECTION_STRING not set")
    sys.exit(1)

data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
os.makedirs(data_dir, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL azure;")
con.execute("LOAD azure;")
con.execute(f"CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '{conn_str}');")
print("Connected to Azure.")

# 1. Publishing industry (NAICS 513) — all counties, all demographics aggregated
print("Extracting publishing industry (NAICS 513)...")
pub_df = con.execute("""
    SELECT
        geography AS fips,
        year, quarter,
        COALESCE(Emp, 0) AS emp,
        COALESCE(HirN, 0) AS hir_n,
        COALESCE(Sep, 0) AS sep,
        COALESCE(EarnS, 0) AS earn_s
    FROM 'az://derived/qwi/rh/n3/*.parquet'
    WHERE CAST(industry AS VARCHAR) = '513'
      AND sex = 0
      AND agegrp = 'A00'
      AND race = 'A0'
      AND ethnicity = 'A0'
    ORDER BY geography, year, quarter
""").fetchdf()

print(f"  Publishing rows: {len(pub_df):,}")
print(f"  Unique counties: {pub_df['fips'].nunique():,}")
print(f"  Year range: {pub_df['year'].min()}-{pub_df['year'].max()}")

pub_path = os.path.join(data_dir, 'qwi_publishing.csv')
pub_df.to_csv(pub_path, index=False)
print(f"  Saved to {pub_path}")

# 2. Placebo industry (Utilities = NAICS 221) — employment only
print("\nExtracting utilities (NAICS 221) for placebo...")
plac_df = con.execute("""
    SELECT
        geography AS fips,
        year, quarter,
        COALESCE(Emp, 0) AS emp
    FROM 'az://derived/qwi/rh/n3/*.parquet'
    WHERE CAST(industry AS VARCHAR) = '221'
      AND sex = 0
      AND agegrp = 'A00'
      AND race = 'A0'
      AND ethnicity = 'A0'
    ORDER BY geography, year, quarter
""").fetchdf()

print(f"  Placebo rows: {len(plac_df):,}")
plac_path = os.path.join(data_dir, 'qwi_placebo.csv')
plac_df.to_csv(plac_path, index=False)
print(f"  Saved to {plac_path}")

con.close()
print("\nDone.")
