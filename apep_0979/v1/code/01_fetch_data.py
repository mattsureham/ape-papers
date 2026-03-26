"""01_fetch_data.py — Fetch QWI Race-Hispanic data directly from Census LEHD."""
import os
import sys
import pandas as pd
import urllib.request
import gzip
import io

data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
os.makedirs(data_dir, exist_ok=True)

# State abbreviations (lowercase) and FIPS codes
state_info = {
    'al': '01', 'ak': '02', 'az': '04', 'ar': '05', 'ca': '06',
    'co': '08', 'ct': '09', 'dc': '11', 'de': '10', 'fl': '12',
    'ga': '13', 'hi': '15', 'id': '16', 'il': '17', 'in': '18',
    'ia': '19', 'ks': '20', 'ky': '21', 'la': '22', 'ma': '25',
    'md': '24', 'me': '23', 'mi': '26', 'mn': '27', 'mo': '29',
    'ms': '28', 'mt': '30', 'nc': '37', 'nd': '38', 'ne': '31',
    'nh': '33', 'nj': '34', 'nm': '35', 'nv': '32', 'ny': '36',
    'oh': '39', 'ok': '40', 'or': '41', 'pa': '42', 'ri': '44',
    'sc': '45', 'sd': '46', 'tn': '47', 'tx': '48', 'ut': '49',
    'va': '51', 'vt': '50', 'wa': '53', 'wi': '55', 'wv': '54',
    'wy': '56'
}

# QWI LEHD public URL pattern for Race-Hispanic x NAICS sector (state-level, firm characteristics)
# Format: qwi_{st}_rh_f_gs_ns_op_u.csv.gz
# gs = geography state-level, ns = NAICS sector, op = ownercode private
base_url = "https://lehd.ces.census.gov/data/qwi/latest_release/{st}/qwi_{st}_rh_f_gs_ns_op_u.csv.gz"

frames = []
failed = []

for i, (st, fips) in enumerate(sorted(state_info.items())):
    url = base_url.format(st=st)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'APEP-Research/1.0'})
        response = urllib.request.urlopen(req, timeout=60)
        compressed = response.read()
        decompressed = gzip.decompress(compressed)
        df_st = pd.read_csv(io.BytesIO(decompressed), low_memory=False)

        # Filter to relevant data
        df_st['industry'] = df_st['industry'].astype(str)
        df_st['race'] = df_st['race'].astype(str)
        df_st['sex'] = df_st['sex'].astype(str)
        df_st['ethnicity'] = df_st['ethnicity'].astype(str)
        df_st['year'] = pd.to_numeric(df_st['year'], errors='coerce')

        mask = (
            (df_st['race'].isin(['A2', 'A1'])) &
            (df_st['sex'] == '0') &
            (df_st['ethnicity'] == 'A0') &
            (df_st['year'] >= 2015) & (df_st['year'] <= 2022) &
            (df_st['industry'].isin(['62', '31-33', '44-45']))
        )
        df_filtered = df_st[mask].copy()
        df_filtered['state_fips'] = fips

        if len(df_filtered) > 0:
            frames.append(df_filtered)

        if (i + 1) % 10 == 0:
            print(f"  Downloaded {i+1}/{len(state_info)} states... ({len(df_filtered)} rows from {st})")

    except Exception as e:
        failed.append(st)
        print(f"  Failed {st}: {type(e).__name__}: {e}")
        continue

print(f"\nDone. {len(frames)} states downloaded, {len(failed)} failed.")
if failed:
    print(f"Failed states: {failed}")

df = pd.concat(frames, ignore_index=True)

# Keep relevant columns
cols_keep = [c for c in ['geography', 'state_fips', 'industry', 'sex', 'race', 'ethnicity',
             'year', 'quarter', 'Emp', 'EmpEnd', 'EmpS', 'HirA', 'Sep',
             'EarnS', 'EarnBeg', 'EarnHirAS'] if c in df.columns]
df = df[cols_keep]

# Split
df_main = df[df['industry'].isin(['62', '31-33'])].copy()
df_retail = df[df['industry'].isin(['62', '44-45'])].copy()

print(f"\nMain data (HC + Mfg): {len(df_main):,} rows, {df_main['state_fips'].nunique()} states")
print(f"Retail data (HC + Ret): {len(df_retail):,} rows")
print(f"Industries: {df_main['industry'].unique().tolist()}")
print(f"Races: {df_main['race'].unique().tolist()}")

# Quick earnings check — EarnS is already average monthly earnings per stable worker
for race in ['A1', 'A2']:
    for ind in ['62', '31-33']:
        subset = df_main[(df_main['race'] == race) & (df_main['industry'] == ind)]
        label_r = 'White' if race == 'A1' else 'Black'
        label_i = 'Healthcare' if ind == '62' else 'Manufacturing'
        earns = subset['EarnS'].dropna()
        print(f"  {label_r} {label_i}: mean_monthly_earn=${earns.mean():,.0f}, n={len(subset)}")

df_main.to_csv(os.path.join(data_dir, 'qwi_main.csv'), index=False)
df_retail.to_csv(os.path.join(data_dir, 'qwi_retail.csv'), index=False)
print(f"\nSaved data/qwi_main.csv ({len(df_main):,} rows)")
print(f"Saved data/qwi_retail.csv ({len(df_retail):,} rows)")
