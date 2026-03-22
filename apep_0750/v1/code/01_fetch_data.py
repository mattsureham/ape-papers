"""
01_fetch_data.py — Fetch USPTO patent data from BigQuery
APEP-0750: The Innovation Offshore Effect

Queries patents-public-data for AI (G06N), Computing (G06F), and Telecom (H04L)
patents filed 2015-2024, with assignee country information.
"""

import os
import sys
from google.cloud import bigquery

# --- Setup ---
client = bigquery.Client(project="scl-librechat")
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# --- EU-27 country codes ---
EU27 = (
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
)

# --- Query 1: Country-group × tech × quarter aggregates ---
print("Fetching country-group × tech × quarter aggregates...")

query_agg = """
WITH patent_cpc AS (
  SELECT
    p.publication_number,
    p.filing_date,
    EXTRACT(YEAR FROM p.filing_date) AS filing_year,
    CONCAT(CAST(EXTRACT(YEAR FROM p.filing_date) AS STRING), 'Q',
           CAST(EXTRACT(QUARTER FROM p.filing_date) AS STRING)) AS filing_quarter,
    cpc.code AS cpc_code,
    CASE
      WHEN STARTS_WITH(cpc.code, 'G06N') THEN 'AI'
      WHEN STARTS_WITH(cpc.code, 'G06F') THEN 'Computing'
      WHEN STARTS_WITH(cpc.code, 'H04L') THEN 'Telecom'
      ELSE 'Other'
    END AS tech_class,
    assignee.name AS assignee_name,
    assignee.country_code AS assignee_country
  FROM `patents-public-data.patents.publications` p,
    UNNEST(p.cpc) AS cpc,
    UNNEST(p.assignee_harmonized) AS assignee
  WHERE
    p.country_code = 'US'
    AND p.filing_date >= '2015-01-01'
    AND p.filing_date <= '2024-12-31'
    AND (STARTS_WITH(cpc.code, 'G06N')
         OR STARTS_WITH(cpc.code, 'G06F')
         OR STARTS_WITH(cpc.code, 'H04L'))
    AND assignee.country_code IS NOT NULL
    AND assignee.country_code != ''
),
deduped AS (
  SELECT DISTINCT
    publication_number,
    filing_quarter,
    filing_year,
    tech_class,
    assignee_name,
    assignee_country
  FROM patent_cpc
  WHERE tech_class != 'Other'
),
with_groups AS (
  SELECT
    *,
    CASE
      WHEN assignee_country IN UNNEST(@eu27) THEN 'EU'
      WHEN assignee_country = 'US' THEN 'US'
      WHEN assignee_country = 'JP' THEN 'JP'
      WHEN assignee_country = 'KR' THEN 'KR'
      WHEN assignee_country = 'CN' THEN 'CN'
      WHEN assignee_country = 'GB' THEN 'GB'
      ELSE 'Other'
    END AS country_group
  FROM deduped
)
SELECT
  filing_quarter,
  filing_year,
  country_group,
  tech_class,
  COUNT(DISTINCT publication_number) AS n_patents,
  COUNT(DISTINCT assignee_name) AS n_firms
FROM with_groups
WHERE country_group IN ('EU', 'US', 'JP', 'KR', 'CN', 'GB')
GROUP BY filing_quarter, filing_year, country_group, tech_class
ORDER BY filing_quarter, country_group, tech_class
"""

job_config = bigquery.QueryJobConfig(
    query_parameters=[
        bigquery.ArrayQueryParameter("eu27", "STRING", list(EU27))
    ]
)

df_agg = client.query(query_agg, job_config=job_config).to_dataframe()
print(f"  Aggregate data: {len(df_agg)} rows")
assert len(df_agg) > 100, f"Too few rows ({len(df_agg)}), data fetch may have failed"

out_agg = os.path.join(DATA_DIR, "patent_aggregates.csv")
df_agg.to_csv(out_agg, index=False)
print(f"  Saved to {out_agg}")

# --- Query 2: Firm-level panel (top assignees) ---
print("Fetching firm-level panel...")

query_firm = """
WITH patent_cpc AS (
  SELECT
    p.publication_number,
    p.filing_date,
    CONCAT(CAST(EXTRACT(YEAR FROM p.filing_date) AS STRING), 'Q',
           CAST(EXTRACT(QUARTER FROM p.filing_date) AS STRING)) AS filing_quarter,
    EXTRACT(YEAR FROM p.filing_date) AS filing_year,
    CASE
      WHEN STARTS_WITH(cpc.code, 'G06N') THEN 'AI'
      WHEN STARTS_WITH(cpc.code, 'G06F') THEN 'Computing'
      WHEN STARTS_WITH(cpc.code, 'H04L') THEN 'Telecom'
      ELSE 'Other'
    END AS tech_class,
    assignee.name AS assignee_name,
    assignee.country_code AS assignee_country
  FROM `patents-public-data.patents.publications` p,
    UNNEST(p.cpc) AS cpc,
    UNNEST(p.assignee_harmonized) AS assignee
  WHERE
    p.country_code = 'US'
    AND p.filing_date >= '2015-01-01'
    AND p.filing_date <= '2024-12-31'
    AND (STARTS_WITH(cpc.code, 'G06N')
         OR STARTS_WITH(cpc.code, 'G06F')
         OR STARTS_WITH(cpc.code, 'H04L'))
    AND assignee.country_code IS NOT NULL
    AND assignee.country_code != ''
),
deduped AS (
  SELECT DISTINCT
    publication_number,
    filing_quarter,
    filing_year,
    tech_class,
    assignee_name,
    assignee_country
  FROM patent_cpc
  WHERE tech_class != 'Other'
),
with_groups AS (
  SELECT
    *,
    CASE
      WHEN assignee_country IN UNNEST(@eu27) THEN 'EU'
      WHEN assignee_country = 'US' THEN 'US'
      WHEN assignee_country = 'JP' THEN 'JP'
      WHEN assignee_country = 'KR' THEN 'KR'
      ELSE 'Other'
    END AS country_group
  FROM deduped
),
firm_counts AS (
  SELECT
    assignee_name,
    assignee_country,
    country_group,
    filing_quarter,
    filing_year,
    tech_class,
    COUNT(DISTINCT publication_number) AS n_patents
  FROM with_groups
  WHERE country_group IN ('EU', 'US', 'JP', 'KR')
  GROUP BY assignee_name, assignee_country, country_group, filing_quarter, filing_year, tech_class
),
-- Keep firms with at least 5 total patents across all years
active_firms AS (
  SELECT assignee_name
  FROM firm_counts
  GROUP BY assignee_name
  HAVING SUM(n_patents) >= 5
)
SELECT fc.*
FROM firm_counts fc
INNER JOIN active_firms af ON fc.assignee_name = af.assignee_name
ORDER BY assignee_name, filing_quarter, tech_class
"""

df_firm = client.query(query_firm, job_config=job_config).to_dataframe()
print(f"  Firm-level data: {len(df_firm)} rows, {df_firm['assignee_name'].nunique()} unique firms")
assert len(df_firm) > 500, f"Too few firm rows ({len(df_firm)}), data fetch may have failed"

out_firm = os.path.join(DATA_DIR, "patent_firm_panel.csv")
df_firm.to_csv(out_firm, index=False)
print(f"  Saved to {out_firm}")

# --- Summary statistics ---
print("\n=== Summary Statistics ===")
print("\nAggregate by country_group × tech_class (2021):")
mask = df_agg["filing_year"] == 2021
print(df_agg[mask].groupby(["country_group", "tech_class"])[["n_patents", "n_firms"]].sum().to_string())

print("\nEU AI patents by year:")
eu_ai = df_agg[(df_agg["country_group"] == "EU") & (df_agg["tech_class"] == "AI")]
print(eu_ai.groupby("filing_year")["n_patents"].sum().to_string())

print("\nUS AI patents by year:")
us_ai = df_agg[(df_agg["country_group"] == "US") & (df_agg["tech_class"] == "AI")]
print(us_ai.groupby("filing_year")["n_patents"].sum().to_string())

print("\nDone! Data ready for R analysis.")
