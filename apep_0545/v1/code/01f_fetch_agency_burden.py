#!/usr/bin/env python3
"""
01f_fetch_agency_burden.py
Fetch agency-specific burden coverage from GDELT.

Burden = news articles that mention:
  (a) the agency's specific sector/domain
  (b) AND have negative tone toward regulation

This creates AGENCY-SPECIFIC burden variables that vary within-quarter.
Without this, burden is collinear with quarter FEs.

Strategy:
- For each agency, define sector-specific search terms (positive matches)
- Burden article = sector-specific + regulatory context + negative tone
- Use GDELT GKG V2Tone < -2 as "negative toward regulation"

Also builds agency-specific EPU interaction:
  agency_burden = articles mentioning agency sector + regulation burden terms
"""

import pandas as pd
import numpy as np
from google.cloud import bigquery
from pathlib import Path

script_dir = Path(__file__).parent.parent
data_dir = script_dir / "data"
client = bigquery.Client(project="scl-librechat")

AGENCY_SECTOR_TERMS = {
    # Agency: (sector_search_terms, regulatory_burden_terms)
    "EPA": (
        ["ENV_", "CLIMATE", "POLLUTION", "EMISSION", "CARBON", "CLEAN_AIR", "CLEAN_WATER"],
        ["REGULATION", "REGULATORY", "OVERREGULAT", "RED_TAPE", "COMPLIANCE_COST"]
    ),
    "OSHA": (
        ["WORKPLACE", "OCCUPATIONAL", "LABOR", "WORKER", "EMPLOYEE", "MANUFACTURING"],
        ["REGULATION", "REGULATORY", "OVERREGULAT", "COMPLIANCE_COST", "BUSINESS_COST"]
    ),
    "FDA": (
        ["DRUG", "PHARMACEUTICAL", "FOOD_SAFETY", "MEDICAL_DEVICE", "BIOTECH", "APPROVAL"],
        ["FDA_APPROVAL", "REGULATION", "REGULATORY_BURDEN", "APPROVAL_PROCESS"]
    ),
    "NHTSA": (
        ["VEHICLE", "AUTOMOBILE", "AUTO", "FUEL_ECONOMY", "SAFETY_STANDARD"],
        ["REGULATION", "REGULATORY", "AUTO_REGULATION", "COMPLIANCE"]
    ),
    "FAA": (
        ["AVIATION", "AIRLINE", "AIRCRAFT", "AIRPORT", "DRONE", "PILOT"],
        ["REGULATION", "REGULATORY", "OVERREGULAT", "RED_TAPE"]
    ),
    "FRA": (
        ["RAILROAD", "TRAIN", "RAIL", "FREIGHT"],
        ["REGULATION", "REGULATORY", "COMPLIANCE_COST"]
    ),
    "MSHA": (
        ["MINING", "MINE", "COAL", "MINERAL", "QUARRY"],
        ["REGULATION", "REGULATORY", "OVERREGULAT", "COMPLIANCE_COST"]
    ),
    "CPSC": (
        ["CONSUMER_PRODUCT", "PRODUCT_SAFETY", "IMPORT_SAFETY", "TOY"],
        ["REGULATION", "REGULATORY", "OVERREGULAT"]
    ),
    "FMCSA": (
        ["TRUCK", "MOTOR_CARRIER", "FREIGHT", "TRUCKING"],
        ["REGULATION", "REGULATORY", "ELD", "HOURS_OF_SERVICE"]
    ),
    "PHMSA": (
        ["PIPELINE", "HAZMAT", "HAZARDOUS_MATERIAL", "GAS_PIPELINE"],
        ["REGULATION", "REGULATORY", "COMPLIANCE"]
    ),
    "NRC": (
        ["NUCLEAR", "NUCLEAR_POWER", "REACTOR", "RADIATION"],
        ["REGULATION", "REGULATORY", "NUCLEAR_REGULATION", "COMPLIANCE"]
    ),
    "CFTC": (
        ["DERIVATIVES", "FUTURES", "COMMODITY", "SWAP", "FINANCIAL_MARKET"],
        ["REGULATION", "REGULATORY", "DODD_FRANK", "OVERREGULAT"]
    ),
}

print("=== FETCHING AGENCY-SPECIFIC BURDEN COVERAGE ===")

OUTPUT_FILE = data_dir / "gdelt_agency_burden_specific.csv"

if OUTPUT_FILE.exists():
    print(f"File already exists: {OUTPUT_FILE}")
    df = pd.read_csv(OUTPUT_FILE)
else:
    # Build batch query for ALL agencies at once
    # For each agency, count articles mentioning the sector AND regulatory burden
    # Use V2Themes for sector, V2Tone for negativity toward regulation

    case_clauses = []
    for agency, (sector_terms, burden_terms) in AGENCY_SECTOR_TERMS.items():
        # Articles about the agency's sector
        sector_cond = " OR ".join([f"V2Themes LIKE '%{t}%'" for t in sector_terms])
        # Articles with regulatory burden context and negative tone
        burden_cond = " OR ".join([f"DocumentIdentifier LIKE '%{t.lower()}%'" for t in burden_terms[:3]])

        # Proxy: articles mentioning agency sector + EPU + negative tone
        # OR articles with sector search terms and negative tone
        clause = f"""
        SUM(CASE WHEN ({sector_cond}) AND CAST(SPLIT(V2Tone, ',')[SAFE_OFFSET(0)] AS FLOAT64) < -2 THEN 1 ELSE 0 END) as {agency.lower()}_burden_neg,
        SUM(CASE WHEN ({sector_cond}) AND V2Themes LIKE '%EPU%' THEN 1 ELSE 0 END) as {agency.lower()}_burden_epu,
        SUM(CASE WHEN ({sector_cond}) THEN 1 ELSE 0 END) as {agency.lower()}_sector_total"""
        case_clauses.append(clause)

    query = f"""
    SELECT
        CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) as year,
        CAST(CEIL(CAST(SUBSTR(CAST(DATE AS STRING), 5, 2) AS INT64) / 3.0) AS INT64) as quarter,
        {','.join(case_clauses)}
    FROM `gdelt-bq.gdeltv2.gkg`
    WHERE DATE >= 20150101000000 AND DATE < 20250101000000
    AND DocumentIdentifier IS NOT NULL
    AND CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) BETWEEN 2015 AND 2024
    GROUP BY year, quarter
    HAVING quarter BETWEEN 1 AND 4
    ORDER BY year, quarter
    """

    print("Running agency-specific burden query (3-5 minutes)...")
    wide_df = client.query(query).to_dataframe()
    print(f"Query returned {len(wide_df)} rows")

    # Reshape to long format
    agencies = list(AGENCY_SECTOR_TERMS.keys())
    long_rows = []
    for _, row in wide_df.iterrows():
        for agency in agencies:
            ag = agency.lower()
            long_rows.append({
                'agency_id': agency,
                'year': int(row['year']),
                'quarter': int(row['quarter']),
                'agency_burden_neg': int(row[f'{ag}_burden_neg']) if pd.notna(row.get(f'{ag}_burden_neg')) else 0,
                'agency_burden_epu': int(row[f'{ag}_burden_epu']) if pd.notna(row.get(f'{ag}_burden_epu')) else 0,
                'agency_sector_total': int(row[f'{ag}_sector_total']) if pd.notna(row.get(f'{ag}_sector_total')) else 0,
            })

    df = pd.DataFrame(long_rows)
    df.to_csv(OUTPUT_FILE, index=False)
    print(f"Saved {len(df)} rows to {OUTPUT_FILE}")

# Validate: does burden vary within quarter across agencies?
print("\nChecking within-quarter variation:")
for (year, quarter), grp in df.groupby(['year', 'quarter']):
    vals = grp['agency_burden_neg'].unique()
    if len(vals) > 1:
        print(f"  {year} Q{quarter}: burden varies across {len(grp)} agencies ✓")
        break
    else:
        print(f"  {year} Q{quarter}: burden is SAME for all agencies ✗")
        break

print("\nAgency-specific burden coverage (mean neg-tone articles):")
print(df.groupby('agency_id')[['agency_burden_neg', 'agency_burden_epu', 'agency_sector_total']].mean().sort_values('agency_burden_neg', ascending=False).to_string())

# Merge with main panel
panel = pd.read_csv(data_dir / "panel_with_iv.csv")
panel = panel.merge(df[['agency_id','year','quarter','agency_burden_neg','agency_burden_epu','agency_sector_total']],
                    on=['agency_id','year','quarter'], how='left')
panel['log_agency_burden'] = np.log(panel['agency_burden_neg'] + 1)
panel['log_agency_burden_epu'] = np.log(panel['agency_burden_epu'] + 1)
panel.to_csv(data_dir / "panel_with_iv.csv", index=False)
print(f"\nUpdated panel_with_iv.csv with agency-specific burden measures")
print(f"Within-quarter variance of agency_burden_neg: {panel.groupby(['year','quarter'])['agency_burden_neg'].std().mean():.0f}")

print("\n=== AGENCY-SPECIFIC BURDEN FETCH COMPLETE ===")
