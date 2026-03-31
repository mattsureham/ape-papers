"""Aggregate downloaded SIH parquet files to municipality-year CSV.
Reads from pysus cache, filters to waterborne ICD-10 A00-A09."""

import pandas as pd
import numpy as np
from pathlib import Path
import pyarrow.parquet as pq

DATA_DIR = Path(__file__).parent.parent / "data"
PYSUS_DIR = Path.home() / "pysus"

print("Reading downloaded SIH parquet files from pysus cache...")

# Find all parquet files
parquet_files = sorted(PYSUS_DIR.glob("*.parquet"))
print(f"Found {len(parquet_files)} parquet files")

# Read and filter
all_records = []
for pf in parquet_files:
    try:
        df = pd.read_parquet(pf)
        if "DIAG_PRINC" not in df.columns:
            continue

        # Filter to ICD-10 A00-A09 (waterborne diseases)
        mask = df["DIAG_PRINC"].astype(str).str.match(r"^A0[0-9]")
        wb = df.loc[mask]

        if len(wb) > 0:
            records = pd.DataFrame({
                "muni_code": wb["MUNIC_RES"].astype(str).str.zfill(6),
                "year": pd.to_numeric(wb["ANO_CMPT"], errors="coerce").astype("Int64"),
                "diag": wb["DIAG_PRINC"].astype(str),
                "age": pd.to_numeric(wb["IDADE"], errors="coerce"),
                "age_code": pd.to_numeric(wb.get("COD_IDADE", pd.Series(dtype=float)), errors="coerce"),
                "cost": pd.to_numeric(wb["VAL_TOT"], errors="coerce"),
            })
            all_records.append(records)
    except Exception as e:
        pass

if not all_records:
    raise RuntimeError("FATAL: No waterborne records in parquet files.")

sih = pd.concat(all_records, ignore_index=True)
print(f"Total waterborne records: {len(sih):,}")

# Remove duplicates (same file may be downloaded twice)
sih = sih.drop_duplicates()
print(f"After dedup: {len(sih):,}")

# Age conversion
sih["age_years"] = np.where(sih["age_code"] == 4, sih["age"],
                   np.where(sih["age_code"] == 3, sih["age"] / 12,
                   np.where(sih["age_code"] == 2, sih["age"] / 365, np.nan)))

# State code
sih["state_code"] = sih["muni_code"].str[:2]

# Aggregate to municipality-year
sih_agg = (sih.groupby(["muni_code", "year"])
           .agg(n_hosp=("diag", "count"),
                n_under5=("age_years", lambda x: (x < 5).sum()),
                n_under1=("age_years", lambda x: (x < 1).sum()),
                total_cost=("cost", "sum"))
           .reset_index())

sih_agg.to_csv(DATA_DIR / "sih_waterborne.csv", index=False)

print(f"\nSaved: {len(sih_agg):,} municipality-year observations")
print(f"Municipalities: {sih_agg['muni_code'].nunique():,}")

# Coverage by state
print("\nCoverage by state:")
state_coverage = sih.groupby("state_code").agg(
    n_records=("diag", "count"),
    n_munis=("muni_code", "nunique"),
    years=("year", lambda x: f"{int(x.min())}-{int(x.max())}")
).reset_index()
for _, row in state_coverage.iterrows():
    print(f"  {row['state_code']}: {row['n_records']:,} records, {row['n_munis']:,} munis ({row['years']})")

# Annual summary
print("\nAnnual summary:")
annual = sih.groupby("year").agg(n=("diag", "count"), munis=("muni_code", "nunique")).reset_index()
for _, row in annual.iterrows():
    print(f"  {int(row['year'])}: {int(row['n']):,} hosp across {int(row['munis']):,} munis")

print("\nDone!")
