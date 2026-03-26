"""Download QWI race×ethnicity data from Azure for analysis."""
import os
import sys
import pyarrow.parquet as pq
from azure.storage.blob import BlobServiceClient
from io import BytesIO
import pyarrow as pa

# Parse connection string directly from .env
conn_str = ""
with open("../../../../.env") as f:
    for line in f:
        line = line.strip()
        if line.startswith("AZURE_STORAGE_CONNECTION_STRING="):
            conn_str = line.split("=", 1)[1]
            break

assert conn_str and len(conn_str) > 50, f"No valid Azure connection string found (len={len(conn_str)})"
print(f"Connection string loaded ({len(conn_str)} chars)")

client = BlobServiceClient.from_connection_string(conn_str)
container = client.get_container_client("derived")

# All US state abbreviations (lowercase) for QWI
states = [
    "ak", "al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
    "ga", "hi", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
    "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
    "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa", "ri",
    "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi", "wv", "wy"
]

# Industries we need
target_industries = {"72", "44-45", "62", "54"}

os.makedirs("../data", exist_ok=True)

print(f"Downloading QWI rh/ns data for {len(states)} states...")
all_tables = []
for st in states:
    blob_name = f"qwi/rh/ns/{st}.parquet"
    blob_client = container.get_blob_client(blob_name)

    try:
        data = blob_client.download_blob().readall()
        buf = BytesIO(data)
        table = pq.read_table(buf)

        # Filter to target industries in-memory
        df = table.to_pandas()
        df_filtered = df[df["industry"].isin(target_industries)]

        if len(df_filtered) > 0:
            all_tables.append(pa.Table.from_pandas(df_filtered))
            print(f"  {st}: {len(df_filtered):,} rows (from {len(df):,})")
        else:
            print(f"  {st}: no matching industries")
    except Exception as e:
        print(f"  {st}: ERROR - {e}")

if not all_tables:
    print("FATAL: No data downloaded")
    sys.exit(1)

# Combine and save
combined = pa.concat_tables(all_tables, promote_options="default")
output_path = "../data/qwi_rh_ns_raw.parquet"
pq.write_table(combined, output_path)

print(f"\nSaved: {output_path}")
print(f"Total rows: {len(combined):,}")
print(f"Columns: {combined.column_names}")
print("Data fetch complete.")
