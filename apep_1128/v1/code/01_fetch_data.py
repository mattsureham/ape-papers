"""01_fetch_data.py — Download QWI race-by-industry data from Azure Blob Storage."""
import os, io, sys
import pyarrow.parquet as pq
import pandas as pd

AZURE_CS = (
    "DefaultEndpointsProtocol=https;"
    "AccountName=apepdata;"
    "AccountKey=iPVAMNtDZQ5vG1zHfLhyQ94Zir++Di5um6fxvKekEYwpxtDwopwpgcyt7WcX4PcoYAtfqS8f7VUV+AStXMqdiQ==;"
    "EndpointSuffix=core.windows.net"
)

from azure.storage.blob import ContainerClient

cc = ContainerClient.from_connection_string(AZURE_CS, "derived")

# ---- State-level data (ns = NAICS supersector) ----
blobs_ns = [b.name for b in cc.list_blobs(name_starts_with="qwi/rh/ns/")]
print(f"Found {len(blobs_ns)} state files in qwi/rh/ns/")

frames = []
for bname in blobs_ns:
    state_abbr = bname.split("/")[-1].replace(".parquet", "")
    print(f"  Reading {state_abbr}...", end=" ")
    bc = cc.get_blob_client(bname)
    raw = bc.download_blob().readall()
    tbl = pq.read_table(io.BytesIO(raw))
    df = tbl.to_pandas()

    # Filter: state-level, NAICS 51/54/72, race A1/A2, all ethnicity,
    # both sexes, all ages, all firm characteristics, 2016+
    mask = (
        (df["geo_level"] == "S") &
        (df["industry"].isin(["51", "54", "72"])) &
        (df["race"].isin(["A1", "A2"])) &
        (df["ethnicity"] == "A0") &
        (df["sex"] == 0) &
        (df["agegrp"] == "A00") &
        (df["firmage"] == 0) &
        (df["firmsize"] == 0) &
        (df["year"] >= 2016)
    )
    sub = df.loc[mask, [
        "geography", "industry", "race", "year", "quarter",
        "Emp", "EmpEnd", "EmpS", "Sep", "HirA", "HirN", "EarnS",
        "SepS", "HirAS", "HirNS", "EarnHirAS", "EarnHirNS", "EarnSepS",
    ]].copy()
    sub["state_abbr"] = state_abbr.upper()
    sub["state_fips"] = sub["geography"].astype(str).str[:2].astype(int)
    frames.append(sub)
    print(f"{len(sub)} rows")

full = pd.concat(frames, ignore_index=True)
print(f"\nTotal state-level rows: {len(full)}")

# Save
outdir = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(outdir, exist_ok=True)
outpath = os.path.join(outdir, "qwi_state_panel.parquet")
full.to_parquet(outpath, index=False)
print(f"Saved to {outpath}")

# Quick validation
assert len(full) > 0, "FATAL: No data fetched"
assert full["Emp"].notna().sum() > 100, "FATAL: Too few non-null Emp values"
print(f"\nValidation passed: {full['state_abbr'].nunique()} states, "
      f"{full['industry'].nunique()} industries, "
      f"years {full['year'].min()}-{full['year'].max()}")
