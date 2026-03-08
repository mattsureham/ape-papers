#!/usr/bin/env python3
"""
01b_fetch_gdelt.py
Fetch GDELT GKG data for regulatory ratchet paper (apep_0545)

Outputs:
  data/gdelt_agency_quarter.csv   -- agency × quarter safety incident + burden coverage
  data/gdelt_competing_news.csv   -- quarter-level competing news volume (IV)

Uses BigQuery GDELT GKG table (2015-2024), project: scl-librechat
"""

import os
import sys
import json
import pandas as pd
from google.cloud import bigquery
from pathlib import Path

# Navigate to output directory
script_dir = Path(__file__).parent.parent
data_dir = script_dir / "data"
data_dir.mkdir(exist_ok=True)

client = bigquery.Client(project="scl-librechat")

print("=== GDELT GKG DATA FETCH ===")
print(f"Output directory: {data_dir}")

# ============================================================
# AGENCY → GDELT THEME MAPPING
# ============================================================
# Based on confirmed GDELT GKG V2Themes vocabulary (as confirmed in smoke test)
# Safety incident themes: presence in GKG article = article covers a safety incident
# Burden themes: EPU regulatory discussion with negative tone

AGENCY_THEMES = {
    "EPA": {
        "sector": "environment",
        "incident_themes": [
            "ENV_DISASTER", "ENV_POLLUTION", "ENV_CHEMICALS",
            "CRISISLEX_C09_HAZMAT", "MANMADE_DISASTER", "CONTAMINATION"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ECON_REGULATION", "ENVIRONMENT"]
    },
    "OSHA": {
        "sector": "occupational_safety",
        "incident_themes": [
            "MANMADE_DISASTER", "CRISISLEX_C07_SAFETY",
            "WORKPLACE_SAFETY", "INDUSTRIAL_ACCIDENT", "WORKER_DEATH"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "LABOR_RIGHTS"]
    },
    "FDA": {
        "sector": "food_drug",
        "incident_themes": [
            "FOOD_CONTAMINATION", "DRUG_RECALL", "MEDICAL_EMERGENCY",
            "CRISISLEX_C04_DISEASE", "FOODSAFETY"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ECON_HEALTHCARE"]
    },
    "NHTSA": {
        "sector": "auto_safety",
        "incident_themes": [
            "VEHICLE_ACCIDENT", "AUTO_RECALL", "TRANSPORT_INCIDENT",
            "CRISISLEX_C09_HAZMAT", "TRAFFIC_ACCIDENT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ECON_REGULATION"]
    },
    "FAA": {
        "sector": "aviation",
        "incident_themes": [
            "AVIATION_INCIDENT", "PLANE_CRASH", "AIR_ACCIDENT",
            "CRISISLEX_C09_HAZMAT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "AVIATION"]
    },
    "FRA": {
        "sector": "railroad",
        "incident_themes": [
            "RAIL_ACCIDENT", "TRAIN_CRASH", "TRANSPORT_INCIDENT",
            "CRISISLEX_C09_HAZMAT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION"]
    },
    "MSHA": {
        "sector": "mining",
        "incident_themes": [
            "MINE_ACCIDENT", "MINING_DISASTER", "CRISISLEX_C07_SAFETY",
            "MANMADE_DISASTER"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ENV_MINING"]
    },
    "CPSC": {
        "sector": "consumer_products",
        "incident_themes": [
            "PRODUCT_RECALL", "CONSUMER_SAFETY", "CRISISLEX_C07_SAFETY",
            "PRODUCT_DEFECT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION"]
    },
    "FMCSA": {
        "sector": "trucking",
        "incident_themes": [
            "TRANSPORT_INCIDENT", "TRUCK_ACCIDENT", "VEHICLE_ACCIDENT",
            "CRISISLEX_C09_HAZMAT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION"]
    },
    "PHMSA": {
        "sector": "pipeline",
        "incident_themes": [
            "PIPELINE_LEAK", "PIPELINE_ACCIDENT", "ENV_DISASTER",
            "ENV_POLLUTION", "CRISISLEX_C09_HAZMAT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ENV_ENERGY"]
    },
    "NRC": {
        "sector": "nuclear",
        "incident_themes": [
            "NUCLEAR_ACCIDENT", "NUCLEAR_INCIDENT", "RADIATION",
            "NUCLEAR", "CRISISLEX_C09_HAZMAT"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ENV_ENERGY"]
    },
    "CFTC": {
        "sector": "financial_derivatives",
        "incident_themes": [
            "FINANCIAL_FRAUD", "MARKET_MANIPULATION", "PONZI",
            "CRISISLEX_C08_FINANCE"
        ],
        "burden_themes": ["EPU_CATS_REGULATION", "ECON_FINANCIAL_REGULATION"]
    }
}

# ============================================================
# BUILD GDELT GKG QUERY FOR AGENCY COVERAGE
# ============================================================
# Strategy: for each agency, count GKG articles with relevant themes
# per quarter. Use V2Themes field (semicolon-separated THEME,offset pairs).
# We match on theme strings appearing in V2Themes.

def build_theme_condition(themes, field="V2Themes"):
    """Build SQL LIKE condition for theme matching."""
    conditions = [f"{field} LIKE '%{theme}%'" for theme in themes]
    return "(" + " OR ".join(conditions) + ")"

# Build agency-quarter query
# We query one large batch: all GKG rows 2015-2024 with any relevant theme,
# then aggregate by year+quarter+theme_category

print("\n[1/3] Fetching GDELT GKG agency coverage data...")

gdelt_output_file = data_dir / "gdelt_agency_quarter.csv"
competing_output_file = data_dir / "gdelt_competing_news.csv"

if not gdelt_output_file.exists():
    all_agency_rows = []

    for agency_id, info in AGENCY_THEMES.items():
        print(f"  Fetching GKG for {agency_id}...")

        incident_cond = build_theme_condition(info["incident_themes"])
        burden_cond = build_theme_condition(info["burden_themes"])

        query = f"""
        WITH all_docs AS (
            SELECT
                CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) as year,
                CAST(CEIL(CAST(SUBSTR(CAST(DATE AS STRING), 5, 2) AS INT64) / 3.0) AS INT64) as quarter,
                CASE WHEN {incident_cond} THEN 1 ELSE 0 END as is_incident,
                CASE WHEN {burden_cond} THEN 1 ELSE 0 END as is_burden,
                CAST(SPLIT(V2Tone, ',')[SAFE_OFFSET(0)] AS FLOAT64) as tone_score,
                1 as article
            FROM `gdelt-bq.gdeltv2.gkg`
            WHERE DATE >= 20150101000000 AND DATE < 20250101000000
            AND DocumentIdentifier IS NOT NULL
        )
        SELECT
            year,
            quarter,
            SUM(article) as total_articles,
            SUM(is_incident) as incident_articles,
            SUM(is_burden) as burden_articles,
            SUM(CASE WHEN is_burden = 1 AND tone_score < -2 THEN 1 ELSE 0 END) as burden_neg_tone_articles,
            AVG(tone_score) as avg_tone
        FROM all_docs
        WHERE year >= 2015 AND year <= 2024
        AND quarter BETWEEN 1 AND 4
        GROUP BY year, quarter
        ORDER BY year, quarter
        """

        try:
            result = client.query(query).to_dataframe()
            result['agency_id'] = agency_id
            result['sector'] = info['sector']
            all_agency_rows.append(result)
            print(f"    {agency_id}: {len(result)} quarters, incident_articles range: {result['incident_articles'].min():.0f}-{result['incident_articles'].max():.0f}")
        except Exception as e:
            print(f"    ERROR for {agency_id}: {e}", file=sys.stderr)
            raise RuntimeError(f"FATAL: GDELT query failed for {agency_id}: {e}\nCannot produce paper without real GDELT data.")

    if not all_agency_rows:
        raise RuntimeError("FATAL: No GDELT data retrieved for any agency.")

    gdelt_df = pd.concat(all_agency_rows, ignore_index=True)
    gdelt_df.to_csv(gdelt_output_file, index=False)
    print(f"  Saved {len(gdelt_df)} rows to {gdelt_output_file}")

else:
    print(f"  Loading existing GDELT agency data from {gdelt_output_file}")
    gdelt_df = pd.read_csv(gdelt_output_file)

# ============================================================
# BUILD COMPETING-NEWS IV
# ============================================================
# Competing news = quarterly total GKG volume OUTSIDE the regulatory/safety domain
# Instrument: high competing news → media space crowded → lower agency incident salience
# We use: total GKG articles - agency-relevant articles in each quarter

print("\n[2/3] Building competing-news instrument...")

if not competing_output_file.exists():
    # Total quarterly GKG volume (all articles)
    query_total = """
    SELECT
        CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) as year,
        CAST(CEIL(CAST(SUBSTR(CAST(DATE AS STRING), 5, 2) AS INT64) / 3.0) AS INT64) as quarter,
        COUNT(*) as total_gkg_volume,
        -- Major competing events: elections, natural disasters, sports
        SUM(CASE WHEN V2Themes LIKE '%ELECTIONS%' OR V2Themes LIKE '%ELECTION%' THEN 1 ELSE 0 END) as election_coverage,
        SUM(CASE WHEN V2Themes LIKE '%NATURAL_DISASTER%' OR V2Themes LIKE '%HURRICANE%'
                      OR V2Themes LIKE '%EARTHQUAKE%' OR V2Themes LIKE '%FLOOD%' THEN 1 ELSE 0 END) as disaster_coverage,
        SUM(CASE WHEN V2Themes LIKE '%SPORT%' OR V2Themes LIKE '%OLYMPICS%'
                      OR V2Themes LIKE '%SUPERBOWL%' THEN 1 ELSE 0 END) as sports_coverage,
        -- International/geopolitical news (crowding out domestic regulatory attention)
        SUM(CASE WHEN V2Themes LIKE '%WAR%' OR V2Themes LIKE '%CONFLICT%'
                      OR V2Themes LIKE '%ARMEDCONFLICT%' THEN 1 ELSE 0 END) as conflict_coverage,
        -- "Big story" news (celebrity, crime, major cultural events)
        SUM(CASE WHEN V2Themes LIKE '%CRIME%' OR V2Themes LIKE '%TERROR%'
                      OR V2Themes LIKE '%MASS_SHOOTING%' THEN 1 ELSE 0 END) as crime_terror_coverage
    FROM `gdelt-bq.gdeltv2.gkg`
    WHERE DATE >= 20150101000000 AND DATE < 20250101000000
    AND CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) BETWEEN 2015 AND 2024
    GROUP BY year, quarter
    HAVING quarter BETWEEN 1 AND 4
    ORDER BY year, quarter
    """

    print("  Querying total GKG volume...")
    try:
        competing_df = client.query(query_total).to_dataframe()
        print(f"  Total GKG volume: {len(competing_df)} quarters")
        print(f"  Volume range: {competing_df['total_gkg_volume'].min():,.0f} - {competing_df['total_gkg_volume'].max():,.0f}")

        # Create composite competing news instrument
        # Components: natural disasters, elections, sports (exogenous to regulatory calendar)
        # These are the "news competitors" for regulatory incident coverage
        competing_df['competing_news_vol'] = (
            competing_df['disaster_coverage'] +
            competing_df['election_coverage'] +
            competing_df['sports_coverage'] +
            competing_df['conflict_coverage']
        )
        # Normalize by total GKG volume (fraction of news space occupied by competitors)
        competing_df['competing_news_share'] = (
            competing_df['competing_news_vol'] / competing_df['total_gkg_volume']
        )

        competing_df.to_csv(competing_output_file, index=False)
        print(f"  Saved competing news IV to {competing_output_file}")

    except Exception as e:
        raise RuntimeError(f"FATAL: Competing news query failed: {e}")

else:
    print(f"  Loading existing competing news data from {competing_output_file}")
    competing_df = pd.read_csv(competing_output_file)

# ============================================================
# VALIDATE
# ============================================================

print("\n[3/3] Validating data...")

assert gdelt_df['agency_id'].nunique() >= 12, f"Expected 12 agencies, got {gdelt_df['agency_id'].nunique()}"
assert len(gdelt_df) >= 12 * 38, f"Expected 456+ rows, got {len(gdelt_df)}"
assert 'incident_articles' in gdelt_df.columns, "Missing incident_articles column"
assert 'competing_news_vol' in competing_df.columns, "Missing competing_news_vol column"
assert len(competing_df) >= 38, f"Expected 40+ quarters, got {len(competing_df)}"

print(f"✓ GDELT agency data: {len(gdelt_df)} rows, {gdelt_df['agency_id'].nunique()} agencies")
print(f"✓ Competing news IV: {len(competing_df)} quarters")
print(f"  IV range: {competing_df['competing_news_vol'].min():,.0f} - {competing_df['competing_news_vol'].max():,.0f}")

# Summary statistics
print("\nIncident coverage by agency (total articles 2015-2024):")
agency_summary = gdelt_df.groupby('agency_id')['incident_articles'].sum().sort_values(ascending=False)
print(agency_summary.to_string())

print("\nCompeting news IV by quarter:")
print(competing_df[['year', 'quarter', 'total_gkg_volume', 'competing_news_vol', 'competing_news_share']].to_string())

print("\n=== GDELT FETCH COMPLETE ===")
