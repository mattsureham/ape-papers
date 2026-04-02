"""Fetch QWI data from Azure via DuckDB and save as local parquet files."""
import os
import duckdb

# Load .env
env_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '.env')
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            line = line.removeprefix('export ')
            k, v = line.split('=', 1)
            v = v.strip('"').strip("'")
            os.environ[k] = v

conn_str = os.environ['AZURE_STORAGE_CONNECTION_STRING']
data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
os.makedirs(data_dir, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL azure; LOAD azure;")
con.execute(f"CREATE SECRET apep (TYPE azure, CONNECTION_STRING '{conn_str}')")

# 1. Total private-sector employment by county × quarter
print("Fetching QWI total private-sector employment...")
qwi_total = con.execute("""
    SELECT geography, year, quarter,
           SUM(Emp) as private_emp,
           SUM(EarnS) as private_earn,
           SUM(HirA) as private_hires,
           SUM(Sep) as private_sep
    FROM 'az://derived/qwi/sa/ns/*.parquet'
    WHERE agegrp = 'A00' AND sex = '0'
      AND year >= 2010 AND year <= 2022
    GROUP BY geography, year, quarter
""").fetchdf()
print(f"QWI total: {len(qwi_total)} rows, {qwi_total['geography'].nunique()} counties")
qwi_total.to_parquet(os.path.join(data_dir, 'qwi_total.parquet'))

# 2. Sector-level for mechanism decomposition
print("Fetching QWI sector-level employment...")
qwi_sector = con.execute("""
    SELECT geography, year, quarter, industry,
           SUM(Emp) as emp,
           SUM(EarnS) as earn,
           SUM(HirA) as hires,
           SUM(Sep) as sep
    FROM 'az://derived/qwi/sa/ns/*.parquet'
    WHERE agegrp = 'A00' AND sex = '0'
      AND industry IN ('72', '44-45', '31-33', '62')
      AND year >= 2010 AND year <= 2022
    GROUP BY geography, year, quarter, industry
""").fetchdf()
print(f"QWI sector: {len(qwi_sector)} rows")
qwi_sector.to_parquet(os.path.join(data_dir, 'qwi_sector.parquet'))

con.close()
print("QWI data saved to parquet.")
