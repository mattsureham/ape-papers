"""Fetch patent examiner data from BigQuery and save as CSV."""
import sys
from google.cloud import bigquery
import os

client = bigquery.Client(project="scl-librechat")

# --- 1. Examiner grant rates by art unit and year ---
print("Querying examiner application data...")
examiner_query = """
SELECT
  examiner_id,
  SUBSTR(CAST(examiner_art_unit AS STRING), 1, 4) AS art_unit_4,
  EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', CAST(filing_date AS STRING))) AS filing_year,
  uspc_class,
  disposal_type,
  CASE WHEN disposal_type = 'ISS' THEN 1 ELSE 0 END AS granted
FROM `patents-public-data.uspto_oce_pair.application_data`
WHERE examiner_id IS NOT NULL
  AND filing_date IS NOT NULL
  AND disposal_type IN ('ISS', 'ABN')
  AND EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', CAST(filing_date AS STRING))) BETWEEN 2001 AND 2015
"""

df_exam = client.query(examiner_query).to_dataframe()
print(f"  Fetched {len(df_exam):,} application records")
assert len(df_exam) > 100_000, f"Too few records: {len(df_exam)}"

df_exam.to_csv("../data/patent_examiner_raw.csv.gz", index=False, compression="gzip")
print("  Saved patent_examiner_raw.csv.gz")

# --- 2. Inventor state locations ---
print("Querying inventor state locations...")
inventor_query = """
SELECT
  a.uspc_class,
  EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', CAST(a.filing_date AS STRING))) AS filing_year,
  i.state AS inventor_state,
  COUNT(*) AS n_inventors,
  SUM(CASE WHEN a.disposal_type = 'ISS' THEN 1 ELSE 0 END) AS n_granted
FROM `patents-public-data.uspto_oce_pair.application_data` a
JOIN `patents-public-data.uspto_oce_pair.all_inventors` i
  ON a.application_number = i.application_number
WHERE a.filing_date IS NOT NULL
  AND a.disposal_type IN ('ISS', 'ABN')
  AND i.state IS NOT NULL
  AND LENGTH(i.state) = 2
  AND EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', CAST(a.filing_date AS STRING))) BETWEEN 2001 AND 2015
GROUP BY a.uspc_class, filing_year, i.state
"""

df_inv = client.query(inventor_query).to_dataframe()
print(f"  Fetched {len(df_inv):,} inventor-state-class-year cells")
assert len(df_inv) > 10_000, f"Too few cells: {len(df_inv)}"

df_inv.to_csv("../data/inventor_state_class.csv.gz", index=False, compression="gzip")
print("  Saved inventor_state_class.csv.gz")

print(f"\nDone. Examiner records: {len(df_exam):,}, Inventor cells: {len(df_inv):,}")
