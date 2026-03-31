"""Download DATASUS SIH data via pysus, one month at a time.
Filters to waterborne diseases (ICD-10 A00-A09)."""

import os
import pandas as pd
import numpy as np
from pathlib import Path
from pysus.online_data.SIH import download

DATA_DIR = Path(__file__).parent.parent / "data"

# Reduced scope for speed: 3 treated states + 3 control states
STATES = ["AL", "RJ", "RS", "PE", "SP", "SC"]
YEARS = list(range(2016, 2024))

print(f"Downloading SIH-RD: {len(STATES)} states x {len(YEARS)} years x 12 months")
print(f"Total downloads: {len(STATES) * len(YEARS) * 12}")

all_records = []
success_count = 0
fail_count = 0

for state in STATES:
    for year in YEARS:
        year_records = []
        for month in range(1, 13):
            try:
                result = download(states=state, years=year, months=month, groups="RD")

                # Handle both ParquetSet and list returns
                if isinstance(result, list):
                    if len(result) > 0 and hasattr(result[0], 'to_dataframe'):
                        df = result[0].to_dataframe()
                    else:
                        continue
                elif hasattr(result, 'to_dataframe'):
                    df = result.to_dataframe()
                else:
                    continue

                if df is not None and len(df) > 0:
                    # Filter to ICD-10 A00-A09
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
                        year_records.append(records)
                success_count += 1
            except Exception as e:
                fail_count += 1

        # Summarize year
        if year_records:
            combined = pd.concat(year_records, ignore_index=True)
            all_records.append(combined)
            print(f"  {state} {year}: {len(combined):,} waterborne records")
        else:
            print(f"  {state} {year}: no data")

print(f"\nSuccess: {success_count}, Failed: {fail_count}")

if not all_records:
    raise RuntimeError("FATAL: No SIH data downloaded.")

sih = pd.concat(all_records, ignore_index=True)
print(f"Total waterborne records: {len(sih):,}")

# Age conversion
sih["age_years"] = np.where(sih["age_code"] == 4, sih["age"],
                   np.where(sih["age_code"] == 3, sih["age"] / 12,
                   np.where(sih["age_code"] == 2, sih["age"] / 365, np.nan)))

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

# Annual summary
print("\nAnnual summary:")
for yr in sorted(sih["year"].dropna().unique()):
    n = len(sih[sih["year"] == yr])
    m = sih[sih["year"] == yr]["muni_code"].nunique()
    print(f"  {int(yr)}: {n:,} hosp across {m:,} municipalities")

print("\nDone!")
