"""
01_fetch_data.py — Fetch QWI data from Azure for H-1B dynamics analysis
Uses Python DuckDB (R DuckDB Azure extension has curl compatibility issues)
"""

import duckdb
import os

# Load .env
env_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '.env')
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            key, val = line.split('=', 1)
            key = key.replace('export ', '').strip()
            val = val.strip().strip('"').strip("'")
            os.environ[key] = val

con = duckdb.connect()
con.execute("INSTALL azure; LOAD azure;")
cs = os.environ["AZURE_STORAGE_CONNECTION_STRING"]
con.execute(f"CREATE SECRET apep (TYPE azure, CONNECTION_STRING '{cs}');")

print("Connected to Azure. Fetching QWI data...")

# Fetch QWI sex×age × NAICS sector data for all states
# Focus: NAICS 54, 51, 00, plus control industries
# Age groups: A04 (25-34), A05 (35-44), A06 (45-54)
query = """
SELECT
    geography AS fips_county,
    year,
    quarter,
    industry,
    agegrp,
    Emp,
    HirA,
    HirN,
    Sep,
    EarnS
FROM 'az://derived/qwi/sa/ns/*.parquet'
WHERE sex = 0
  AND agegrp IN ('A04', 'A05', 'A06')
  AND industry IN ('00', '51', '54', '42', '44-45', '52', '56', '62', '72', '31-33', '23', '48-49', '92', '21')
  AND year BETWEEN 2001 AND 2012
  AND Emp IS NOT NULL
  AND Emp > 0
"""

df = con.execute(query).fetchdf()
print(f"Fetched {len(df):,} rows from QWI.")
assert len(df) > 100_000, f"QWI data must have >100K rows, got {len(df)}"

# Validate
print(f"Counties: {df['fips_county'].nunique()}")
print(f"Year range: {df['year'].min()}-{df['year'].max()}")
print(f"Industries: {sorted(df['industry'].unique())}")
print(f"Age groups: {sorted(df['agegrp'].unique())}")

# Save as CSV for R to read
out_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'qwi_raw.csv')
df.to_csv(out_path, index=False)
print(f"Saved to {out_path}")

con.close()
print("Done.")
