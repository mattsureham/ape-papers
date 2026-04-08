#!/usr/bin/env python3
"""01_fetch_data.py — Fetch NASS crop yields (Quick Stats API) and GHCN-D weather (BigQuery).
apep_1422: When Bugs Hatch Early
"""

import os, sys, json
import requests
import pandas as pd
from google.cloud import bigquery

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# Load NASS API key from .env
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '.env'))
NASS_KEY = os.environ.get('USDA_NASS_API_KEY', '')
assert NASS_KEY, "FATAL: USDA_NASS_API_KEY not in .env"

# Corn Belt state FIPS
CORN_BELT = {
    '17': 'ILLINOIS', '18': 'INDIANA', '19': 'IOWA', '20': 'KANSAS',
    '21': 'KENTUCKY', '26': 'MICHIGAN', '27': 'MINNESOTA', '29': 'MISSOURI',
    '31': 'NEBRASKA', '38': 'NORTH DAKOTA', '39': 'OHIO', '46': 'SOUTH DAKOTA',
    '55': 'WISCONSIN'
}
# GHCN uses 2-letter state abbreviations
FIPS_TO_ABBR = {
    '17': 'IL', '18': 'IN', '19': 'IA', '20': 'KS', '21': 'KY',
    '26': 'MI', '27': 'MN', '29': 'MO', '31': 'NE', '38': 'ND',
    '39': 'OH', '46': 'SD', '55': 'WI'
}
STATE_ABBRS = list(FIPS_TO_ABBR.values())

# ─── 1. NASS Quick Stats: County Corn Yields ────────────────────────
print("=== Fetching NASS corn yields ===")

nass_url = "https://quickstats.nass.usda.gov/api/api_GET/"
all_nass = []

for fips, state_name in CORN_BELT.items():
    params = {
        'key': NASS_KEY,
        'commodity_desc': 'CORN',
        'statisticcat_desc': 'YIELD',
        'unit_desc': 'BU / ACRE',
        'agg_level_desc': 'COUNTY',
        'state_fips_code': fips,
        'year__GE': '2000',
        'year__LE': '2022',
        'format': 'JSON'
    }
    resp = requests.get(nass_url, params=params, timeout=60)
    if resp.status_code != 200:
        print(f"  {state_name}: HTTP {resp.status_code}")
        continue
    data = resp.json().get('data', [])
    if not data:
        print(f"  {state_name}: no data")
        continue
    df = pd.DataFrame(data)
    df = df[['state_fips_code', 'county_code', 'county_name', 'state_name',
             'year', 'Value']].copy()
    df.columns = ['state_fips', 'county_fips', 'county_name', 'state_name',
                  'year', 'yield_bu_acre']
    # Clean: remove non-numeric values
    df = df[df['yield_bu_acre'].apply(lambda x: str(x).replace('.','').replace(',','').isdigit() or
            str(x).replace('.','',1).isdigit())]
    df['yield_bu_acre'] = pd.to_numeric(df['yield_bu_acre'], errors='coerce')
    df['year'] = pd.to_numeric(df['year'], errors='coerce')
    df = df.dropna(subset=['yield_bu_acre', 'year'])
    all_nass.append(df)
    print(f"  {state_name}: {len(df)} records")

nass_df = pd.concat(all_nass, ignore_index=True)
# Create 5-digit FIPS
nass_df['state_fips'] = nass_df['state_fips'].astype(str).str.zfill(2)
nass_df['county_fips'] = nass_df['county_fips'].astype(str).str.zfill(3)
nass_df['fips'] = nass_df['state_fips'] + nass_df['county_fips']

print(f"\nTotal NASS records: {len(nass_df):,}")
print(f"Counties: {nass_df['fips'].nunique()}")
print(f"Years: {int(nass_df['year'].min())}-{int(nass_df['year'].max())}")
print(f"Mean yield: {nass_df['yield_bu_acre'].mean():.1f} bu/acre")

assert len(nass_df) > 1000, "FATAL: Too few NASS records"
nass_df.to_csv(os.path.join(DATA_DIR, "nass_corn_yields.csv"), index=False)
print("Saved nass_corn_yields.csv")

# ─── 2. GHCN-D Daily Temperature from BigQuery ──────────────────────
print("\n=== Fetching GHCN-D daily temperature ===")

BQ_PROJECT = "gen-lang-client-0330172635"
client = bigquery.Client(project=BQ_PROJECT)

ABBR_STR = ", ".join(f"'{a}'" for a in STATE_ABBRS)

# Get stations
print("Fetching station list...")
stations_q = f"""
SELECT id AS station_id, latitude, longitude, name AS station_name, state
FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE state IN ({ABBR_STR})
  AND latitude IS NOT NULL AND longitude IS NOT NULL
"""
stations_df = client.query(stations_q).to_dataframe()
print(f"Stations: {len(stations_df)}")
stations_df.to_csv(os.path.join(DATA_DIR, "stations.csv"), index=False)

# Fetch daily TMAX/TMIN in chunks by decade to avoid timeout
station_ids = stations_df['station_id'].tolist()

# Build station filter as temp table
all_ghcn = []
for decade_start in [2000, 2010, 2020]:
    decade_end = min(decade_start + 9, 2022)
    decade_suffix = str(decade_start)[:3]
    table = f"`bigquery-public-data.ghcn_d.ghcnd_{decade_suffix}*`"

    print(f"Fetching {decade_start}-{decade_end} from {table}...")
    q = f"""
    SELECT
      g.id AS station_id,
      g.date,
      EXTRACT(YEAR FROM g.date) AS year,
      EXTRACT(DAYOFYEAR FROM g.date) AS doy,
      g.element,
      g.value / 10.0 AS value_c
    FROM {table} g
    INNER JOIN `bigquery-public-data.ghcn_d.ghcnd_stations` s
      ON g.id = s.id
    WHERE
      s.state IN ({ABBR_STR})
      AND g.element IN ('TMAX', 'TMIN')
      AND g.qflag IS NULL
      AND EXTRACT(YEAR FROM g.date) BETWEEN {decade_start} AND {decade_end}
    """
    try:
        df = client.query(q).to_dataframe()
        all_ghcn.append(df)
        print(f"  Got {len(df):,} records")
    except Exception as e:
        print(f"  Error: {e}")

ghcn_raw = pd.concat(all_ghcn, ignore_index=True)
print(f"\nTotal GHCN records: {len(ghcn_raw):,}")

# Pivot to get TMAX and TMIN per station-date
ghcn_wide = ghcn_raw.pivot_table(
    index=['station_id', 'date', 'year', 'doy'],
    columns='element',
    values='value_c'
).reset_index()

ghcn_wide = ghcn_wide.dropna(subset=['TMAX', 'TMIN'])
ghcn_wide['tmean_c'] = (ghcn_wide['TMAX'] + ghcn_wide['TMIN']) / 2.0
ghcn_wide['tmean_f'] = ghcn_wide['tmean_c'] * 9/5 + 32
ghcn_wide['tmax_f'] = ghcn_wide['TMAX'] * 9/5 + 32

print(f"Station-days with TMAX+TMIN: {len(ghcn_wide):,}")

# ─── 3. Compute GDD at station-year level ───────────────────────────
print("\n=== Computing GDD variables ===")

# PestGDD: degree-days base 52°F, Jan-Jun (pest emergence intensity)
# HeatStress: degree-days above 84.2°F, Jul-Aug (direct heat damage)
ghcn_wide['pest_dd'] = (ghcn_wide['tmean_f'] - 52.0).clip(lower=0)
ghcn_wide['heat_dd'] = (ghcn_wide['tmax_f'] - 84.2).clip(lower=0)

spring = ghcn_wide[ghcn_wide['doy'] <= 181].groupby(['station_id', 'year']).agg(
    pest_gdd=('pest_dd', 'sum'),
    spring_days=('doy', 'count')
).reset_index()

summer = ghcn_wide[(ghcn_wide['doy'] >= 182) & (ghcn_wide['doy'] <= 243)].groupby(
    ['station_id', 'year']).agg(
    heat_stress=('heat_dd', 'sum'),
    summer_days=('doy', 'count')
).reset_index()

# Annual mean temp
annual = ghcn_wide.groupby(['station_id', 'year']).agg(
    tmean_annual=('tmean_c', 'mean'),
    n_days=('doy', 'count')
).reset_index()

station_year = spring.merge(summer, on=['station_id', 'year'], how='inner')
station_year = station_year.merge(annual, on=['station_id', 'year'], how='inner')

# Quality filter
station_year = station_year[
    (station_year['n_days'] >= 300) &
    (station_year['spring_days'] >= 150) &
    (station_year['summer_days'] >= 50)
]

# Merge station locations
station_year = station_year.merge(
    stations_df[['station_id', 'latitude', 'longitude', 'state']],
    on='station_id', how='left'
)

print(f"Station-year observations: {len(station_year):,}")
print(f"Stations: {station_year['station_id'].nunique()}")
print(f"Mean PestGDD: {station_year['pest_gdd'].mean():.1f}")
print(f"SD PestGDD: {station_year['pest_gdd'].std():.1f}")
print(f"Mean HeatStress: {station_year['heat_stress'].mean():.1f}")
print(f"SD HeatStress: {station_year['heat_stress'].std():.1f}")
print(f"Corr(PestGDD, HeatStress): {station_year['pest_gdd'].corr(station_year['heat_stress']):.3f}")

station_year.to_csv(os.path.join(DATA_DIR, "station_year_gdd.csv"), index=False)
print("Saved station_year_gdd.csv")

# ─── 4. RMA Cause-of-Loss (direct HTTP) ─────────────────────────────
print("\n=== Fetching RMA Cause-of-Loss ===")
import urllib.request, zipfile, io

rma_dfs = []
for yr in range(2001, 2023):
    url = f"https://www.rma.usda.gov/-/media/RMA/Cause-Of-Loss/Summary-of-Business/colsom_{yr}.ashx"
    try:
        resp = urllib.request.urlopen(url, timeout=30)
        content = resp.read()
        if content[:2] == b'PK':  # ZIP file
            with zipfile.ZipFile(io.BytesIO(content)) as z:
                for fname in z.namelist():
                    with z.open(fname) as f:
                        try:
                            df = pd.read_csv(f, sep='|', low_memory=False, encoding='latin-1')
                            # Normalize column names
                            df.columns = [c.strip().lower().replace(' ', '_') for c in df.columns]
                            if 'commodity_name' in df.columns:
                                corn = df[df['commodity_name'].str.upper().str.contains('CORN', na=False)]
                                if len(corn) > 0:
                                    cols = ['state_code', 'county_code', 'damage_cause_description', 'indemnity_amount']
                                    cols = [c for c in cols if c in corn.columns]
                                    if len(cols) >= 3:
                                        subset = corn[cols].copy()
                                        subset['year'] = yr
                                        rma_dfs.append(subset)
                                        n_insect = corn['damage_cause_description'].str.upper().str.contains('INSECT', na=False).sum()
                                        print(f"  {yr}: {len(corn)} corn, {n_insect} insect")
                        except:
                            pass
        else:
            print(f"  {yr}: not a ZIP")
    except Exception as e:
        print(f"  {yr}: {str(e)[:50]}")

if rma_dfs:
    rma_all = pd.concat(rma_dfs, ignore_index=True)
    rma_all.to_csv(os.path.join(DATA_DIR, "rma_corn_losses.csv"), index=False)
    print(f"\nRMA records: {len(rma_all):,}")
else:
    print("WARNING: No RMA data (mechanism test unavailable, non-fatal)")

print("\n=== Data fetch complete ===")
