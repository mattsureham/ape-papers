#!/usr/bin/env python3
"""
01d_fetch_gdelt_batch.py
Batch GDELT GKG fetch for all 12 agencies simultaneously.
Much faster than per-agency queries since we scan the table once.

Outputs:
  data/gdelt_agency_quarter.csv   -- agency × quarter coverage
  data/gdelt_competing_news.csv   -- quarter-level competing news (IV)
"""

import pandas as pd
import sys
from google.cloud import bigquery
from pathlib import Path

script_dir = Path(__file__).parent.parent
data_dir = script_dir / "data"
data_dir.mkdir(exist_ok=True)

client = bigquery.Client(project="scl-librechat")

GDELT_OUTPUT     = data_dir / "gdelt_agency_quarter.csv"
COMPETING_OUTPUT = data_dir / "gdelt_competing_news.csv"

# ============================================================
# BATCH QUERY: All agencies at once
# ============================================================

print("=== BATCH GDELT GKG FETCH ===")
print("Querying all agencies simultaneously (2015-2024)...")

if GDELT_OUTPUT.exists() and COMPETING_OUTPUT.exists():
    print(f"Files already exist. Loading...")
    gdelt_df = pd.read_csv(GDELT_OUTPUT)
    competing_df = pd.read_csv(COMPETING_OUTPUT)
    print(f"GDELT: {len(gdelt_df)} rows | Competing: {len(competing_df)} rows")
else:
    # Single pass through GKG to compute all agency-specific coverage counts
    # Each agency has CASE WHEN ... THEN 1 clauses for their themes
    batch_query = """
    WITH gkg_base AS (
        SELECT
            CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) as year,
            CAST(CEIL(CAST(SUBSTR(CAST(DATE AS STRING), 5, 2) AS INT64) / 3.0) AS INT64) as quarter,
            V2Themes,
            V2Tone,
            1 as article_count
        FROM `gdelt-bq.gdeltv2.gkg`
        WHERE DATE >= 20150101000000 AND DATE < 20250101000000
        AND DocumentIdentifier IS NOT NULL
    )
    SELECT
        year,
        quarter,
        -- Total volume
        SUM(article_count) as total_articles,

        -- EPA: environmental incidents vs. regulatory burden
        SUM(CASE WHEN V2Themes LIKE '%ENV_DISASTER%' OR V2Themes LIKE '%ENV_POLLUTION%'
                      OR V2Themes LIKE '%MANMADE_DISASTER%' OR V2Themes LIKE '%CONTAMINATION%'
                      OR V2Themes LIKE '%CHEMICAL_SPILL%' THEN 1 ELSE 0 END) as epa_incident,

        -- OSHA: occupational safety incidents
        SUM(CASE WHEN V2Themes LIKE '%MANMADE_DISASTER%' OR V2Themes LIKE '%INDUSTRIAL%'
                      OR V2Themes LIKE '%WORKPLACE%' OR V2Themes LIKE '%EXPLOSION%'
                      OR V2Themes LIKE '%FIRE%' AND V2Themes LIKE '%FACTORY%' THEN 1 ELSE 0 END) as osha_incident,

        -- FDA: food and drug safety incidents
        SUM(CASE WHEN V2Themes LIKE '%FOOD%' AND (V2Themes LIKE '%SAFETY%' OR V2Themes LIKE '%RECALL%' OR V2Themes LIKE '%CONTAMIN%')
                      OR V2Themes LIKE '%DRUG%' AND V2Themes LIKE '%RECALL%'
                      OR V2Themes LIKE '%OUTBREAK%' THEN 1 ELSE 0 END) as fda_incident,

        -- NHTSA: auto safety incidents
        SUM(CASE WHEN V2Themes LIKE '%AUTO_RECALL%' OR V2Themes LIKE '%VEHICLE_RECALL%'
                      OR (V2Themes LIKE '%CRASH%' AND V2Themes LIKE '%AUTO%')
                      OR V2Themes LIKE '%TRAFFIC_ACCIDENT%' THEN 1 ELSE 0 END) as nhtsa_incident,

        -- FAA: aviation incidents
        SUM(CASE WHEN V2Themes LIKE '%AVIATION%' AND (V2Themes LIKE '%INCIDENT%' OR V2Themes LIKE '%ACCIDENT%' OR V2Themes LIKE '%CRASH%')
                      OR V2Themes LIKE '%PLANE_CRASH%' OR V2Themes LIKE '%AIR_CRASH%' THEN 1 ELSE 0 END) as faa_incident,

        -- FRA: railroad incidents
        SUM(CASE WHEN V2Themes LIKE '%TRAIN%' AND (V2Themes LIKE '%CRASH%' OR V2Themes LIKE '%DERAIL%' OR V2Themes LIKE '%ACCIDENT%')
                      OR V2Themes LIKE '%RAILROAD%' AND V2Themes LIKE '%ACCIDENT%' THEN 1 ELSE 0 END) as fra_incident,

        -- MSHA: mining incidents
        SUM(CASE WHEN V2Themes LIKE '%MINE%' AND (V2Themes LIKE '%ACCIDENT%' OR V2Themes LIKE '%DISASTER%' OR V2Themes LIKE '%COLLAPSE%')
                      OR V2Themes LIKE '%MINING%' AND V2Themes LIKE '%DISASTER%' THEN 1 ELSE 0 END) as msha_incident,

        -- CPSC: consumer product safety incidents
        SUM(CASE WHEN V2Themes LIKE '%RECALL%' AND (V2Themes LIKE '%CONSUMER%' OR V2Themes LIKE '%PRODUCT%')
                      OR V2Themes LIKE '%TOY%' AND V2Themes LIKE '%SAFETY%' THEN 1 ELSE 0 END) as cpsc_incident,

        -- FMCSA: truck safety incidents
        SUM(CASE WHEN V2Themes LIKE '%TRUCK%' AND (V2Themes LIKE '%CRASH%' OR V2Themes LIKE '%ACCIDENT%')
                      OR V2Themes LIKE '%HAZMAT%' AND V2Themes LIKE '%TRUCK%' THEN 1 ELSE 0 END) as fmcsa_incident,

        -- PHMSA: pipeline incidents
        SUM(CASE WHEN V2Themes LIKE '%PIPELINE%' AND (V2Themes LIKE '%EXPLOSION%' OR V2Themes LIKE '%LEAK%' OR V2Themes LIKE '%ACCIDENT%')
                      OR V2Themes LIKE '%GAS_PIPELINE%' AND V2Themes LIKE '%LEAK%' THEN 1 ELSE 0 END) as phmsa_incident,

        -- NRC: nuclear incidents
        SUM(CASE WHEN V2Themes LIKE '%NUCLEAR%' AND (V2Themes LIKE '%ACCIDENT%' OR V2Themes LIKE '%INCIDENT%' OR V2Themes LIKE '%LEAK%')
                      OR V2Themes LIKE '%RADIATION%' AND V2Themes LIKE '%EMERGENCY%' THEN 1 ELSE 0 END) as nrc_incident,

        -- CFTC: financial market incidents
        SUM(CASE WHEN V2Themes LIKE '%FINANCIAL_FRAUD%' OR V2Themes LIKE '%MARKET_MANIPULATION%'
                      OR V2Themes LIKE '%PONZI%' OR V2Themes LIKE '%FLASH_CRASH%' THEN 1 ELSE 0 END) as cftc_incident,

        -- BURDEN: regulatory burden coverage (any agency, by negative tone)
        SUM(CASE WHEN V2Themes LIKE '%EPU%' THEN 1 ELSE 0 END) as any_epu,
        SUM(CASE WHEN V2Themes LIKE '%EPU%' AND CAST(SPLIT(V2Tone, ',')[SAFE_OFFSET(0)] AS FLOAT64) < -2
                 THEN 1 ELSE 0 END) as epu_negative_tone,

        -- COMPETING NEWS INSTRUMENT components
        SUM(CASE WHEN V2Themes LIKE '%ELECTION%' OR V2Themes LIKE '%ELECTIONS%' THEN 1 ELSE 0 END) as election_coverage,
        SUM(CASE WHEN V2Themes LIKE '%NATURAL_DISASTER%' OR V2Themes LIKE '%HURRICANE%'
                      OR V2Themes LIKE '%EARTHQUAKE%' OR V2Themes LIKE '%FLOOD%'
                      OR V2Themes LIKE '%TORNADO%' OR V2Themes LIKE '%WILDFIRE%' THEN 1 ELSE 0 END) as natural_disaster_coverage,
        SUM(CASE WHEN V2Themes LIKE '%OLYMPIC%' OR V2Themes LIKE '%SPORT%' THEN 1 ELSE 0 END) as sports_coverage,
        SUM(CASE WHEN V2Themes LIKE '%ARMEDCONFLICT%' OR V2Themes LIKE '%WAR%'
                      OR V2Themes LIKE '%TERROR%' THEN 1 ELSE 0 END) as conflict_coverage

    FROM gkg_base
    WHERE year BETWEEN 2015 AND 2024
    AND quarter BETWEEN 1 AND 4
    GROUP BY year, quarter
    ORDER BY year, quarter
    """

    print("Running batch BigQuery query (this may take 3-5 minutes)...")
    try:
        wide_df = client.query(batch_query).to_dataframe()
        print(f"Batch query complete: {len(wide_df)} rows")
        print(wide_df[['year', 'quarter', 'total_articles', 'epa_incident', 'faa_incident']].head(10).to_string())
    except Exception as e:
        raise RuntimeError(f"FATAL: Batch GDELT query failed: {e}")

    # ============================================================
    # RESHAPE: Wide → Long (one row per agency-quarter)
    # ============================================================

    AGENCY_INCIDENT_COLS = {
        'EPA': 'epa_incident',
        'OSHA': 'osha_incident',
        'FDA': 'fda_incident',
        'NHTSA': 'nhtsa_incident',
        'FAA': 'faa_incident',
        'FRA': 'fra_incident',
        'MSHA': 'msha_incident',
        'CPSC': 'cpsc_incident',
        'FMCSA': 'fmcsa_incident',
        'PHMSA': 'phmsa_incident',
        'NRC': 'nrc_incident',
        'CFTC': 'cftc_incident',
    }

    AGENCY_SECTORS = {
        'EPA': 'environment', 'OSHA': 'occupational_safety', 'FDA': 'food_drug',
        'NHTSA': 'auto_safety', 'FAA': 'aviation', 'FRA': 'railroad',
        'MSHA': 'mining', 'CPSC': 'consumer_products', 'FMCSA': 'trucking',
        'PHMSA': 'pipeline', 'NRC': 'nuclear', 'CFTC': 'financial_derivatives'
    }

    long_rows = []
    for agency_id, incident_col in AGENCY_INCIDENT_COLS.items():
        for _, row in wide_df.iterrows():
            long_rows.append({
                'agency_id': agency_id,
                'sector': AGENCY_SECTORS[agency_id],
                'year': int(row['year']),
                'quarter': int(row['quarter']),
                'total_articles': int(row['total_articles']),
                'incident_articles': int(row[incident_col]) if pd.notna(row[incident_col]) else 0,
                'burden_articles': int(row['any_epu']) if pd.notna(row['any_epu']) else 0,
                'burden_neg_tone_articles': int(row['epu_negative_tone']) if pd.notna(row['epu_negative_tone']) else 0,
            })

    gdelt_df = pd.DataFrame(long_rows)

    # Build competing news IV (quarter-level, not agency-level)
    competing_df = wide_df[['year', 'quarter', 'total_articles',
                              'election_coverage', 'natural_disaster_coverage',
                              'sports_coverage', 'conflict_coverage']].copy()

    competing_df['competing_news_vol'] = (
        competing_df['election_coverage'] +
        competing_df['natural_disaster_coverage'] +
        competing_df['sports_coverage'] +
        competing_df['conflict_coverage']
    )
    competing_df['competing_news_share'] = (
        competing_df['competing_news_vol'] / competing_df['total_articles']
    )

    # Save
    gdelt_df.to_csv(GDELT_OUTPUT, index=False)
    competing_df.to_csv(COMPETING_OUTPUT, index=False)
    print(f"\nSaved GDELT agency data: {len(gdelt_df)} rows → {GDELT_OUTPUT}")
    print(f"Saved competing news IV: {len(competing_df)} rows → {COMPETING_OUTPUT}")

# ============================================================
# VALIDATION
# ============================================================

print("\n--- VALIDATION ---")
assert gdelt_df['agency_id'].nunique() >= 12, f"Expected 12 agencies, got {gdelt_df['agency_id'].nunique()}"
assert len(gdelt_df) >= 12 * 38, f"Expected 456+ rows, got {len(gdelt_df)}"
assert competing_df['competing_news_vol'].min() > 0, "Competing news should be > 0"
assert len(competing_df) >= 38, f"Expected 40 quarters, got {len(competing_df)}"

print(f"✓ GDELT agency data: {len(gdelt_df)} rows, {gdelt_df['agency_id'].nunique()} agencies")
print(f"✓ Competing news: {len(competing_df)} quarters, vol range: "
      f"{competing_df['competing_news_vol'].min():,.0f} - {competing_df['competing_news_vol'].max():,.0f}")

print("\nIncident coverage by agency (sum 2015-2024):")
agency_sum = gdelt_df.groupby('agency_id')['incident_articles'].sum().sort_values(ascending=False)
print(agency_sum.to_string())

print("\nCompeting news IV sample:")
print(competing_df[['year', 'quarter', 'total_articles', 'natural_disaster_coverage',
                       'election_coverage', 'competing_news_vol', 'competing_news_share']].head(10).to_string())

print("\n=== GDELT BATCH FETCH COMPLETE ===")
