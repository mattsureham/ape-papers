"""
01_fetch_data.py — Extract patent data from Google BigQuery
apep_0637: Patent Examiner Leniency & Defensive Patenting

Single BigQuery query produces analysis-ready dataset:
- All decided utility applications (2008-2015) with examiner leniency
- USPC-class-level filing counts as competitor activity proxy
- Art-unit × year identifiers for FE

Uses Application Default Credentials (ADC).
Project: scl-librechat
"""

import os
import sys
from google.cloud import bigquery

PROJECT = "scl-librechat"
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

client = bigquery.Client(project=PROJECT)

# ============================================================================
# Step 1: Check table schema to verify available columns
# ============================================================================

def check_schema():
    """Verify what columns are available in the PatEx table."""
    q = """
    SELECT column_name, data_type
    FROM `patents-public-data.uspto_oce_pair.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'application_data'
    ORDER BY ordinal_position
    """
    print("Checking PatEx table schema...")
    try:
        df = client.query(q).to_dataframe()
        print(f"  Found {len(df)} columns:")
        for _, row in df.iterrows():
            print(f"    {row['column_name']}: {row['data_type']}")
        return set(df["column_name"].tolist())
    except Exception as e:
        print(f"  Schema check failed: {e}")
        return set()

# ============================================================================
# Step 2: Main analysis query
# ============================================================================

MAIN_QUERY = """
WITH apps AS (
  SELECT
    application_number,
    EXTRACT(YEAR FROM PARSE_DATE('%Y-%m-%d', filing_date)) AS filing_year,
    EXTRACT(QUARTER FROM PARSE_DATE('%Y-%m-%d', filing_date)) AS filing_quarter,
    disposal_type,
    IF(disposal_type = 'ISS', 1, 0) AS granted,
    examiner_id,
    examiner_art_unit,
    patent_number,
    uspc_class,
    uspc_subclass,
    small_entity_indicator
  FROM `patents-public-data.uspto_oce_pair.application_data`
  WHERE examiner_id IS NOT NULL
    AND filing_date IS NOT NULL
    AND filing_date >= '2001-01-01'
    AND filing_date < '2020-01-01'
    AND disposal_type IN ('ISS', 'ABN')
    AND invention_subject_matter = 'UTL'
),

-- Examiner grant rate by art-unit × year (for LOO leniency)
examiner_stats AS (
  SELECT
    examiner_id,
    examiner_art_unit,
    filing_year,
    COUNT(*) AS exam_n_cases,
    SUM(granted) AS exam_n_granted
  FROM apps
  GROUP BY 1, 2, 3
  HAVING COUNT(*) >= 5  -- minimum cases for reliable leniency
),

-- Art-unit-level filing counts by year (for within-AU variation check)
au_year AS (
  SELECT examiner_art_unit, filing_year, COUNT(*) AS au_filings
  FROM apps
  GROUP BY 1, 2
),

-- USPC-class-level filing counts by year (outcome variable)
uspc_year AS (
  SELECT uspc_class, filing_year, COUNT(*) AS class_filings
  FROM apps
  WHERE uspc_class IS NOT NULL AND uspc_class != ''
  GROUP BY 1, 2
)

SELECT
  a.application_number,
  a.filing_year,
  a.filing_quarter,
  a.granted,
  a.examiner_id,
  a.examiner_art_unit,
  a.uspc_class,
  a.uspc_subclass,
  a.small_entity_indicator,
  a.patent_number,

  -- Examiner stats
  es.exam_n_cases,

  -- Leave-one-out examiner leniency
  SAFE_DIVIDE(
    es.exam_n_granted - a.granted,
    es.exam_n_cases - 1
  ) AS examiner_leniency,

  -- Art-unit filings in filing year (control)
  COALESCE(au0.au_filings, 0) AS au_filings_t0,

  -- USPC class filings in subsequent years (outcome)
  COALESCE(u1.class_filings, 0) AS class_filings_t1,
  COALESCE(u2.class_filings, 0) AS class_filings_t2,
  COALESCE(u3.class_filings, 0) AS class_filings_t3,
  -- Cumulative
  COALESCE(u1.class_filings, 0) + COALESCE(u2.class_filings, 0) AS class_filings_2yr,
  COALESCE(u1.class_filings, 0) + COALESCE(u2.class_filings, 0)
    + COALESCE(u3.class_filings, 0) AS class_filings_3yr

FROM apps a
JOIN examiner_stats es
  ON a.examiner_id = es.examiner_id
  AND a.examiner_art_unit = es.examiner_art_unit
  AND a.filing_year = es.filing_year

-- Art-unit filings in current year
LEFT JOIN au_year au0
  ON a.examiner_art_unit = au0.examiner_art_unit
  AND a.filing_year = au0.filing_year

-- USPC class filings in t+1, t+2, t+3
LEFT JOIN uspc_year u1
  ON a.uspc_class = u1.uspc_class AND a.filing_year + 1 = u1.filing_year
LEFT JOIN uspc_year u2
  ON a.uspc_class = u2.uspc_class AND a.filing_year + 2 = u2.filing_year
LEFT JOIN uspc_year u3
  ON a.uspc_class = u3.uspc_class AND a.filing_year + 3 = u3.filing_year

WHERE a.filing_year >= 2008 AND a.filing_year <= 2015
  AND a.uspc_class IS NOT NULL AND a.uspc_class != ''
"""

# ============================================================================
# Step 3: Examiner-level summary for within-AU variation statistics
# ============================================================================

EXAMINER_VARIATION_QUERY = """
WITH apps AS (
  SELECT
    examiner_id, examiner_art_unit,
    EXTRACT(YEAR FROM PARSE_DATE('%Y-%m-%d', filing_date)) AS filing_year,
    IF(disposal_type = 'ISS', 1, 0) AS granted
  FROM `patents-public-data.uspto_oce_pair.application_data`
  WHERE examiner_id IS NOT NULL
    AND filing_date IS NOT NULL
    AND filing_date >= '2001-01-01' AND filing_date < '2020-01-01'
    AND disposal_type IN ('ISS', 'ABN')
    AND invention_subject_matter = 'UTL'
),
examiner_rates AS (
  SELECT
    examiner_id, examiner_art_unit,
    COUNT(*) AS n_cases,
    AVG(granted) AS grant_rate
  FROM apps
  GROUP BY 1, 2
  HAVING COUNT(*) >= 30
)
SELECT
  examiner_art_unit,
  COUNT(*) AS n_examiners,
  AVG(grant_rate) AS mean_grant_rate,
  STDDEV(grant_rate) AS sd_grant_rate,
  MAX(grant_rate) - MIN(grant_rate) AS range_grant_rate
FROM examiner_rates
GROUP BY 1
HAVING COUNT(*) >= 3
ORDER BY n_examiners DESC
"""


def main():
    output_csv = os.path.join(DATA_DIR, "analysis_dataset.csv")
    output_parquet = os.path.join(DATA_DIR, "analysis_dataset.parquet")

    if os.path.exists(output_csv):
        print(f"Analysis dataset already exists at {output_csv}")
        import pandas as pd
        df = pd.read_csv(output_csv, nrows=5)
        print(f"  Columns: {list(df.columns)}")
        print(f"  Shape: check with wc -l")
        return

    # Check schema first
    cols = check_schema()
    if cols and "uspc_class" not in cols:
        print("WARNING: uspc_class not found in PatEx table!")
        print("Available columns:", sorted(cols))
        # Fall back to art-unit based analysis
        print("Will need alternative technology classification.")

    # Run main query
    print("\nRunning main analysis query...")
    print("  (This may take 1-3 minutes and scan ~4-8 GB)")

    try:
        query_job = client.query(MAIN_QUERY)
        df = query_job.to_dataframe()
    except Exception as e:
        error_msg = str(e)
        if "uspc_class" in error_msg.lower() or "not found" in error_msg.lower():
            print(f"\nColumn error: {e}")
            print("Falling back to art-unit-based query...")
            # Fallback: use art_unit as technology space
            fallback_query = MAIN_QUERY.replace("a.uspc_class", "CAST(a.examiner_art_unit AS STRING)")
            fallback_query = fallback_query.replace("uspc_class", "examiner_art_unit")
            fallback_query = fallback_query.replace("class_filings", "au_class_filings")
            try:
                df = client.query(fallback_query).to_dataframe()
            except Exception as e2:
                print(f"FATAL: Fallback query also failed: {e2}")
                sys.exit(1)
        else:
            print(f"FATAL: Query failed: {e}")
            sys.exit(1)

    print(f"\n  Rows: {len(df):,}")
    print(f"  Columns: {list(df.columns)}")
    print(f"  Granted: {df['granted'].sum():,} ({df['granted'].mean():.1%})")
    print(f"  Unique examiners: {df['examiner_id'].nunique():,}")
    print(f"  Unique art units: {df['examiner_art_unit'].nunique():,}")
    if "uspc_class" in df.columns:
        print(f"  Unique USPC classes: {df['uspc_class'].nunique():,}")
    print(f"  Mean leniency: {df['examiner_leniency'].mean():.3f}")
    print(f"  SD leniency: {df['examiner_leniency'].std():.3f}")
    print(f"  Year range: {df['filing_year'].min()}-{df['filing_year'].max()}")

    # Save
    df.to_csv(output_csv, index=False)
    print(f"\n  Saved to {output_csv} ({os.path.getsize(output_csv) / 1e6:.1f} MB)")

    try:
        df.to_parquet(output_parquet, index=False)
        print(f"  Saved to {output_parquet}")
    except Exception:
        print("  (Parquet save skipped — pyarrow not available)")

    # Run examiner variation query
    print("\nRunning examiner variation query...")
    try:
        df_var = client.query(EXAMINER_VARIATION_QUERY).to_dataframe()
        var_csv = os.path.join(DATA_DIR, "examiner_variation.csv")
        df_var.to_csv(var_csv, index=False)
        print(f"  {len(df_var):,} art units with ≥3 examiners (≥30 cases each)")
        print(f"  Mean within-AU SD: {df_var['sd_grant_rate'].mean():.3f}")
        print(f"  Mean within-AU range: {df_var['range_grant_rate'].mean():.3f}")
    except Exception as e:
        print(f"  Examiner variation query failed: {e}")

    print("\n" + "=" * 60)
    print("DATA EXTRACTION COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
