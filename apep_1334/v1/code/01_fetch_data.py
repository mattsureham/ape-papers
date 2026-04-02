##############################################################################
# 01_fetch_data.py — Fetch patent + assignment data from BigQuery
# Efficient version: do joins in BigQuery, download aggregated result
##############################################################################

import pandas as pd
from google.cloud import bigquery
import os, sys

os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))) or ".")
os.makedirs("data", exist_ok=True)

PROJECT = "gen-lang-client-0330172635"
client = bigquery.Client(project=PROJECT)

print(f"Working directory: {os.getcwd()}")

# -----------------------------------------------------------------------
# Single BigQuery query: join applications to assignment outcomes
# Do the heavy lifting server-side, download the final table
# -----------------------------------------------------------------------
print("=== Running combined query (apps + assignment outcomes) ===")

query = """
WITH apps AS (
  SELECT
    application_number,
    filing_date,
    disposal_type,
    examiner_id,
    examiner_art_unit,
    uspc_class,
    patent_number,
    small_entity_indicator,
    CAST(SUBSTR(filing_date, 1, 4) AS INT64) AS filing_year
  FROM `patents-public-data.uspto_oce_pair.application_data`
  WHERE disposal_type IN ('ISS', 'ABN')
    AND examiner_id IS NOT NULL
    AND examiner_art_unit IS NOT NULL
    AND filing_date IS NOT NULL
    AND CAST(SUBSTR(filing_date, 1, 4) AS INT64) BETWEEN 2000 AND 2016
),

-- Assignment outcomes collapsed to application level
assign_agg AS (
  SELECT
    d.appno_doc_num AS application_number,
    -- Any non-employer assignment (market transfer)
    MAX(CASE WHEN c.employer_assign != '1'
             AND (LOWER(c.convey_ty) LIKE '%assign%'
                  OR LOWER(a.convey_text) LIKE '%assign%')
             AND NOT (LOWER(c.convey_ty) LIKE '%secur%'
                      OR LOWER(a.convey_text) LIKE '%secur%')
         THEN 1 ELSE 0 END) AS market_transfer,
    -- Any security interest
    MAX(CASE WHEN LOWER(c.convey_ty) LIKE '%secur%'
                  OR LOWER(a.convey_text) LIKE '%secur%'
                  OR LOWER(a.convey_text) LIKE '%lien%'
                  OR LOWER(a.convey_text) LIKE '%mortgage%'
         THEN 1 ELSE 0 END) AS has_security,
    -- Any merger
    MAX(CASE WHEN LOWER(c.convey_ty) LIKE '%merger%'
                  OR LOWER(c.convey_ty) LIKE '%merge%'
                  OR LOWER(a.convey_text) LIKE '%merger%'
         THEN 1 ELSE 0 END) AS has_merger,
    -- Any employer assignment
    MAX(CASE WHEN c.employer_assign = '1' THEN 1 ELSE 0 END) AS has_employer_assign,
    COUNT(*) AS n_conveyances
  FROM `patents-public-data.uspto_oce_assignment.assignment` a
  INNER JOIN `patents-public-data.uspto_oce_assignment.assignment_conveyance` c
    ON a.rf_id = c.rf_id
  INNER JOIN `patents-public-data.uspto_oce_assignment.documentid` d
    ON a.rf_id = d.rf_id
  WHERE d.appno_doc_num IS NOT NULL
    AND d.appno_doc_num != ''
  GROUP BY d.appno_doc_num
)

SELECT
  a.*,
  COALESCE(aa.market_transfer, 0) AS market_transfer,
  COALESCE(aa.has_security, 0) AS has_security,
  COALESCE(aa.has_merger, 0) AS has_merger,
  COALESCE(aa.has_employer_assign, 0) AS has_employer_assign,
  COALESCE(aa.n_conveyances, 0) AS n_conveyances
FROM apps a
LEFT JOIN assign_agg aa
  ON a.application_number = aa.application_number
"""

print("Executing query (this processes ~15GB server-side)...")
job = client.query(query)

# Stream results to save memory
print("Downloading results...")
df = job.to_dataframe()

print(f"\n=== Results ===")
print(f"  Applications: {len(df):,}")
print(f"  Granted: {(df['disposal_type'] == 'ISS').sum():,} ({(df['disposal_type'] == 'ISS').mean():.3f})")
print(f"  Abandoned: {(df['disposal_type'] == 'ABN').sum():,}")
print(f"  Examiners: {df['examiner_id'].nunique():,}")
print(f"  Art units: {df['examiner_art_unit'].nunique():,}")
print(f"  Market transfer: {df['market_transfer'].mean():.3f}")
print(f"    Granted: {df.loc[df['disposal_type']=='ISS', 'market_transfer'].mean():.3f}")
print(f"    Abandoned: {df.loc[df['disposal_type']=='ABN', 'market_transfer'].mean():.3f}")
print(f"  Security interest: {df['has_security'].mean():.3f}")
print(f"    Granted: {df.loc[df['disposal_type']=='ISS', 'has_security'].mean():.3f}")
print(f"    Abandoned: {df.loc[df['disposal_type']=='ABN', 'has_security'].mean():.3f}")
print(f"  Small entity: {(df['small_entity_indicator'] == '1').mean():.3f}")

assert len(df) > 1_000_000, f"Expected millions, got {len(df)}"

# Save as parquet
df.to_parquet("data/patent_market_data.parquet", index=False)
print(f"\nSaved data/patent_market_data.parquet ({len(df):,} rows)")
print("=== Data fetch complete ===")
