#!/usr/bin/env python3
"""
Fetch patent data from Google BigQuery for examiner leniency IV analysis.
Constructs application-level dataset with examiner leniency and
technology-class filing counts for measuring patent thicket formation.

Data sources:
  - patents-public-data.uspto_oce_pair.application_data (PatEx)
  - patents-public-data.patents.publications_202409 (for assignee/CPC on grants)
"""

import os
import sys
import json

try:
    from google.cloud import bigquery
    import pandas as pd
except ImportError:
    os.system(f"{sys.executable} -m pip install google-cloud-bigquery pandas pyarrow db-dtypes")
    from google.cloud import bigquery
    import pandas as pd

# Setup paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'data')
os.makedirs(DATA_DIR, exist_ok=True)

client = bigquery.Client(project="scl-librechat")

# ============================================================
# QUERY 1: Focal applications with leave-one-out examiner leniency
# ============================================================
print("=" * 60)
print("STEP 1: Focal applications with LOO examiner leniency")
print("=" * 60)

q_focal = """
WITH raw AS (
  SELECT
    application_number,
    examiner_id,
    examiner_art_unit,
    EXTRACT(YEAR FROM CAST(filing_date AS DATE)) as filing_year,
    disposal_type,
    CASE WHEN disposal_type = 'ISS' THEN 1 ELSE 0 END as granted,
    patent_number,
    uspc_class,
    uspc_subclass,
    small_entity_indicator
  FROM `patents-public-data.uspto_oce_pair.application_data`
  WHERE examiner_id IS NOT NULL
    AND filing_date >= '2005-01-01'
    AND filing_date < '2016-01-01'
    AND disposal_type IN ('ISS', 'ABN')
    AND invention_subject_matter = 'UTL'
    AND uspc_class IS NOT NULL
    AND uspc_subclass IS NOT NULL
),
-- Leave-one-out examiner leniency within art-unit x filing-year
examiner_auy AS (
  SELECT
    examiner_id,
    examiner_art_unit,
    filing_year,
    SUM(granted) as exam_grants,
    COUNT(*) as exam_cases
  FROM raw
  GROUP BY 1, 2, 3
  HAVING COUNT(*) >= 10  -- Minimum cases for reliable leniency
)
SELECT
  r.application_number,
  r.examiner_id,
  r.examiner_art_unit,
  r.filing_year,
  r.disposal_type,
  r.granted,
  r.patent_number,
  r.uspc_class,
  r.uspc_subclass,
  r.small_entity_indicator,
  -- LOO leniency = (total grants by examiner minus this case) / (total cases minus 1)
  SAFE_DIVIDE(
    CAST(e.exam_grants AS FLOAT64) - CAST(r.granted AS FLOAT64),
    CAST(e.exam_cases AS FLOAT64) - 1.0
  ) as loo_leniency,
  e.exam_cases as examiner_caseload
FROM raw r
INNER JOIN examiner_auy e
  ON r.examiner_id = e.examiner_id
  AND r.examiner_art_unit = e.examiner_art_unit
  AND r.filing_year = e.filing_year
"""

print("Executing query (may take 30-60s)...")
df_focal = client.query(q_focal).to_dataframe()
print(f"  Rows: {len(df_focal):,}")
print(f"  Examiners: {df_focal['examiner_id'].nunique():,}")
print(f"  Art units: {df_focal['examiner_art_unit'].nunique():,}")
print(f"  USPC classes: {df_focal['uspc_class'].nunique():,}")
print(f"  USPC subclasses: {df_focal['uspc_subclass'].nunique():,}")
print(f"  Grant rate: {df_focal['granted'].mean():.3f}")
print(f"  LOO leniency: mean={df_focal['loo_leniency'].mean():.3f}, "
      f"sd={df_focal['loo_leniency'].std():.3f}, "
      f"min={df_focal['loo_leniency'].min():.3f}, "
      f"max={df_focal['loo_leniency'].max():.3f}")
print(f"  Filing years: {df_focal['filing_year'].min()}-{df_focal['filing_year'].max()}")

focal_path = os.path.join(DATA_DIR, 'focal_applications.csv')
df_focal.to_csv(focal_path, index=False)
print(f"  Saved to {focal_path}")

# ============================================================
# QUERY 2: USPC subclass x year filing counts (for outcome)
# ============================================================
print("\n" + "=" * 60)
print("STEP 2: USPC subclass x year filing counts")
print("=" * 60)

q_filings = """
SELECT
  uspc_class,
  uspc_subclass,
  EXTRACT(YEAR FROM CAST(filing_date AS DATE)) as year,
  COUNT(*) as total_filings,
  SUM(CASE WHEN disposal_type = 'ISS' THEN 1 ELSE 0 END) as total_grants
FROM `patents-public-data.uspto_oce_pair.application_data`
WHERE invention_subject_matter = 'UTL'
  AND filing_date >= '2001-01-01'
  AND filing_date < '2022-01-01'
  AND disposal_type IN ('ISS', 'ABN')
  AND uspc_class IS NOT NULL
  AND uspc_subclass IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
"""

print("Executing query...")
df_filings = client.query(q_filings).to_dataframe()
print(f"  Rows: {len(df_filings):,}")
print(f"  Years: {df_filings['year'].min()}-{df_filings['year'].max()}")
print(f"  USPC subclasses: {df_filings.groupby(['uspc_class','uspc_subclass']).ngroups:,}")

filings_path = os.path.join(DATA_DIR, 'uspc_subclass_filings.csv')
df_filings.to_csv(filings_path, index=False)
print(f"  Saved to {filings_path}")

# ============================================================
# QUERY 3: Assignee data for granted patents (mechanism test)
# ============================================================
print("\n" + "=" * 60)
print("STEP 3: Assignee + CPC for granted patents")
print("=" * 60)

q_assignee = """
SELECT
  a.application_number,
  a.patent_number,
  a.uspc_class,
  a.uspc_subclass,
  EXTRACT(YEAR FROM CAST(a.filing_date AS DATE)) as filing_year,
  p.assignee_harmonized[SAFE_OFFSET(0)].name as assignee_name,
  p.cpc[SAFE_OFFSET(0)].code as cpc4_code
FROM `patents-public-data.uspto_oce_pair.application_data` a
JOIN `patents-public-data.patents.publications_202409` p
  ON CONCAT('US-', a.patent_number, '-B2') = p.publication_number
WHERE a.disposal_type = 'ISS'
  AND a.filing_date >= '2005-01-01'
  AND a.filing_date < '2016-01-01'
  AND a.invention_subject_matter = 'UTL'
  AND a.patent_number IS NOT NULL
  AND a.examiner_id IS NOT NULL
  AND p.country_code = 'US'
"""

print("Executing query (larger join, may take 1-2 min)...")
df_assignee = client.query(q_assignee).to_dataframe()
print(f"  Rows: {len(df_assignee):,}")
print(f"  Unique assignees: {df_assignee['assignee_name'].nunique():,}")
n_with_cpc = df_assignee['cpc4_code'].notna().sum()
print(f"  With CPC codes: {n_with_cpc:,} ({n_with_cpc/len(df_assignee)*100:.1f}%)")

assignee_path = os.path.join(DATA_DIR, 'grant_assignees.csv')
df_assignee.to_csv(assignee_path, index=False)
print(f"  Saved to {assignee_path}")

# ============================================================
# QUERY 4: CPC-4 group x year x assignee filing counts
# (for competitor-specific analysis using granted patents)
# ============================================================
print("\n" + "=" * 60)
print("STEP 4: CPC-4 x year filing counts by assignee")
print("=" * 60)

# Get unique CPC-4 prefixes from the assignee data
if len(df_assignee) > 0 and df_assignee['cpc4_code'].notna().any():
    # Extract CPC-4 prefix (first 4 chars of CPC code, e.g., G06F from G06F17/30)
    df_assignee['cpc4'] = df_assignee['cpc4_code'].str[:4]
    top_cpc4 = df_assignee['cpc4'].value_counts().head(50).index.tolist()
    cpc4_str = "','".join(top_cpc4)

    q_cpc_filings = f"""
    SELECT
      SUBSTR(cpc.code, 1, 4) as cpc4,
      EXTRACT(YEAR FROM CAST(filing_date AS DATE)) as year,
      assignee_harmonized[SAFE_OFFSET(0)].name as assignee_name,
      COUNT(*) as n_filings
    FROM `patents-public-data.patents.publications_202409`,
      UNNEST(cpc) as cpc
    WHERE country_code = 'US'
      AND SUBSTR(cpc.code, 1, 4) IN ('{cpc4_str}')
      AND filing_date >= '2001-01-01'
      AND filing_date < '2022-01-01'
      AND grant_date IS NOT NULL
      AND assignee_harmonized[SAFE_OFFSET(0)].name IS NOT NULL
    GROUP BY 1, 2, 3
    HAVING COUNT(*) >= 1
    """

    print(f"Fetching filing counts for top {len(top_cpc4)} CPC-4 groups...")
    df_cpc_filings = client.query(q_cpc_filings).to_dataframe()
    print(f"  Rows: {len(df_cpc_filings):,}")

    cpc_path = os.path.join(DATA_DIR, 'cpc4_assignee_filings.csv')
    df_cpc_filings.to_csv(cpc_path, index=False)
    print(f"  Saved to {cpc_path}")
else:
    print("  Skipping (no CPC data available)")

# ============================================================
# Summary and validation
# ============================================================
print("\n" + "=" * 60)
print("DATA CONSTRUCTION COMPLETE")
print("=" * 60)

summary = {
    "n_focal_applications": len(df_focal),
    "n_examiners": int(df_focal['examiner_id'].nunique()),
    "n_art_units": int(df_focal['examiner_art_unit'].nunique()),
    "n_uspc_classes": int(df_focal['uspc_class'].nunique()),
    "n_uspc_subclasses": int(df_focal['uspc_subclass'].nunique()),
    "grant_rate": float(df_focal['granted'].mean()),
    "loo_leniency_mean": float(df_focal['loo_leniency'].mean()),
    "loo_leniency_sd": float(df_focal['loo_leniency'].std()),
    "filing_year_min": int(df_focal['filing_year'].min()),
    "filing_year_max": int(df_focal['filing_year'].max()),
    "n_grants_with_assignee": len(df_assignee),
    "n_unique_assignees": int(df_assignee['assignee_name'].nunique()) if len(df_assignee) > 0 else 0
}

summary_path = os.path.join(DATA_DIR, 'fetch_summary.json')
with open(summary_path, 'w') as f:
    json.dump(summary, f, indent=2)
print(f"\nSummary saved to {summary_path}")
print(json.dumps(summary, indent=2))
