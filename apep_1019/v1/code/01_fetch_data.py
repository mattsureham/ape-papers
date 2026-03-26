#!/usr/bin/env python3
"""Fetch MLP panel from Azure, filter to analysis sample, reshape to long format."""
import duckdb
import os
import sys

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# Find .env
for depth in range(1, 8):
    env_path = os.path.join(SCRIPT_DIR, *[".."] * depth, ".env")
    if os.path.exists(env_path):
        break
else:
    sys.exit("ERROR: .env not found")

# Read Azure connection string
conn_str = None
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line.startswith("AZURE_STORAGE_CONNECTION_STRING="):
            conn_str = line.split("=", 1)[1].strip('"').strip("'")
            break
if not conn_str:
    sys.exit("ERROR: AZURE_STORAGE_CONNECTION_STRING not found in .env")

# Connect
con = duckdb.connect()
con.execute("INSTALL azure; LOAD azure;")
con.execute(f"CREATE SECRET az (TYPE azure, CONNECTION_STRING '{conn_str}')")

AZURE_PATH = "az://derived/mlp_panel/linked_1920_1930_1940.parquet"

# Reshape wide -> long for panel analysis
# Use statefip_1920 as treatment-assignment state (ITT)
# Carry baseline characteristics (relate_1920, famsize_1920) forward
query = f"""
WITH filtered AS (
    SELECT *
    FROM '{AZURE_PATH}'
    WHERE sex_1920 = 1
      AND age_1920 BETWEEN 25 AND 50
      AND age_diff_20_30 BETWEEN 8 AND 12
      AND age_diff_30_40 BETWEEN 8 AND 12
)
SELECT histid_1920 AS histid, 1920 AS year,
       statefip_1920 AS statefip_origin,
       age_1920 AS age, race_1920 AS race, nativity_1920 AS nativity,
       marst_1920 AS marst,
       occscore_1920 AS occscore, sei_1920 AS sei,
       farm_1920 AS farm, occ1950_1920 AS occ1950,
       classwkr_1920 AS classwkr, ownershp_1920 AS ownershp,
       perwt_1920 AS perwt,
       relate_1920 AS relate_1920_base,
       famsize_1920 AS famsize_1920_base,
       0 AS mover
FROM filtered

UNION ALL

SELECT histid_1920, 1930,
       statefip_1920,
       age_1930, race_1930, nativity_1930,
       marst_1930,
       occscore_1930, sei_1930,
       farm_1930, occ1950_1930,
       classwkr_1930, ownershp_1930,
       perwt_1920,
       relate_1920,
       famsize_1920,
       mover_20_30
FROM filtered

UNION ALL

SELECT histid_1920, 1940,
       statefip_1920,
       age_1940, race_1940, nativity_1940,
       marst_1940,
       occscore_1940, sei_1940,
       farm_1940, occ1950_1940,
       classwkr_1940, ownershp_1940,
       perwt_1920,
       relate_1920,
       famsize_1920,
       mover_20_40
FROM filtered
"""

output_path = os.path.join(DATA_DIR, "analysis_panel.parquet")
print("Fetching and reshaping MLP data from Azure...")
con.execute(f"COPY ({query}) TO '{output_path}' (FORMAT PARQUET)")

# Validate
n = con.execute(f"SELECT COUNT(*) FROM '{output_path}'").fetchone()[0]
n_persons = con.execute(f"SELECT COUNT(DISTINCT histid) FROM '{output_path}'").fetchone()[0]
n_states = con.execute(f"SELECT COUNT(DISTINCT statefip_origin) FROM '{output_path}'").fetchone()[0]

print(f"Rows: {n:,}")
print(f"Unique persons: {n_persons:,}")
print(f"States: {n_states}")

# Quick summary by year
summary = con.execute(f"""
    SELECT year, COUNT(*) AS n,
           AVG(occscore) AS mean_occscore,
           AVG(sei) AS mean_sei,
           AVG(CAST(farm AS DOUBLE)) AS farm_share
    FROM '{output_path}'
    GROUP BY year ORDER BY year
""").fetchdf()
print("\nSummary by year:")
print(summary.to_string(index=False))

con.close()
print("\nDone.")
