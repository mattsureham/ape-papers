"""
Fetch patent continuation twin study data from BigQuery.
Source: patents-public-data.uspto_oce_pair

Date fields are YYYY-MM-DD strings. small_entity_indicator is 0/1.
"""
import os
import json
from google.cloud import bigquery

client = bigquery.Client(project="gen-lang-client-0330172635")
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
os.makedirs(DATA_DIR, exist_ok=True)

# ─── Query 1: Build twin pairs ─────────────────────────────────────────
print("Building continuation twin pairs...")
q_twins = """
WITH child_apps AS (
  SELECT
    cp.application_number AS child_app,
    cp.parent_application_number AS parent_app,
    cp.continuation_type,
    a.filing_date AS child_filing_date,
    a.examiner_id AS child_examiner_id,
    a.examiner_art_unit AS child_art_unit,
    a.disposal_type AS child_disposal,
    a.patent_number AS child_patent_number,
    a.abandon_date AS child_abandon_date,
    a.patent_issue_date AS child_issue_date,
    a.small_entity_indicator AS child_small_entity,
    a.uspc_class AS child_uspc_class,
    CAST(SUBSTR(a.filing_date, 1, 4) AS INT64) AS child_filing_year
  FROM `patents-public-data.uspto_oce_pair.continuity_parents` cp
  JOIN `patents-public-data.uspto_oce_pair.application_data` a
    ON cp.application_number = a.application_number
  WHERE cp.continuation_type IN ('CON', 'DIV')
    AND a.filing_date >= '1998-01-01'
    AND a.filing_date <= '2020-12-31'
    AND a.disposal_type IN ('ISS', 'ABN')
    AND a.examiner_id IS NOT NULL
    AND a.examiner_art_unit IS NOT NULL
),
parent_info AS (
  SELECT
    a.application_number AS parent_app,
    a.examiner_id AS parent_examiner_id,
    a.examiner_art_unit AS parent_art_unit,
    a.disposal_type AS parent_disposal,
    a.patent_number AS parent_patent_number,
    a.small_entity_indicator AS parent_small_entity,
    a.uspc_class AS parent_uspc_class,
    a.filing_date AS parent_filing_date
  FROM `patents-public-data.uspto_oce_pair.application_data` a
  WHERE a.disposal_type IN ('ISS', 'ABN')
    AND a.examiner_id IS NOT NULL
    AND a.examiner_art_unit IS NOT NULL
)
SELECT
  c.*,
  p.parent_examiner_id,
  p.parent_art_unit,
  p.parent_disposal,
  p.parent_patent_number,
  p.parent_small_entity,
  p.parent_uspc_class,
  p.parent_filing_date,
  CASE WHEN c.child_examiner_id != p.parent_examiner_id THEN 1 ELSE 0 END AS diff_examiner,
  CASE WHEN c.child_art_unit = p.parent_art_unit THEN 1 ELSE 0 END AS same_art_unit,
  CASE WHEN c.child_disposal != p.parent_disposal THEN 1 ELSE 0 END AS discordant
FROM child_apps c
JOIN parent_info p
  ON c.parent_app = p.parent_app
"""
df_twins = client.query(q_twins).to_dataframe()
print(f"  Total twin pairs: {len(df_twins):,}")
print(f"  Different examiner: {df_twins['diff_examiner'].sum():,}")
print(f"  Same art unit: {df_twins['same_art_unit'].sum():,}")
diff_same = ((df_twins['diff_examiner']==1) & (df_twins['same_art_unit']==1))
same_same = ((df_twins['diff_examiner']==0) & (df_twins['same_art_unit']==1))
print(f"  Diff examiner + same AU: {diff_same.sum():,}")
print(f"  Same examiner + same AU: {same_same.sum():,}")
if diff_same.sum() > 0:
    print(f"  Discordance (diff exam, same AU): {df_twins.loc[diff_same, 'discordant'].mean():.3f}")
if same_same.sum() > 0:
    print(f"  Discordance (same exam, same AU): {df_twins.loc[same_same, 'discordant'].mean():.3f}")
df_twins.to_csv(os.path.join(DATA_DIR, "twin_pairs.csv"), index=False)

# ─── Query 2: Examiner grant rates for leniency measure ────────────────
print("\nComputing examiner-level grant rates...")
q_leniency = """
SELECT
  examiner_id,
  examiner_art_unit,
  CAST(SUBSTR(filing_date, 1, 4) AS INT64) AS filing_year,
  COUNT(*) AS n_apps,
  COUNTIF(disposal_type = 'ISS') AS n_granted,
  COUNTIF(disposal_type = 'ABN') AS n_abandoned,
  COUNTIF(small_entity_indicator = '1') AS n_small
FROM `patents-public-data.uspto_oce_pair.application_data`
WHERE filing_date >= '1995-01-01'
  AND filing_date <= '2020-12-31'
  AND disposal_type IN ('ISS', 'ABN')
  AND examiner_id IS NOT NULL
  AND examiner_art_unit IS NOT NULL
GROUP BY examiner_id, examiner_art_unit, CAST(SUBSTR(filing_date, 1, 4) AS INT64)
"""
df_leniency = client.query(q_leniency).to_dataframe()
print(f"  Examiner-AU-year cells: {len(df_leniency):,}")
df_leniency.to_csv(os.path.join(DATA_DIR, "examiner_grant_rates.csv"), index=False)

# ─── Query 3: Office actions for twin children ─────────────────────────
print("\nFetching office actions...")
q_oa = """
SELECT
  oa.application_number,
  oa.action_type,
  oa.action_subtype,
  oa.mail_date,
  oa.rejection_101,
  oa.rejection_102,
  oa.rejection_103,
  oa.rejection_112,
  oa.objection
FROM `patents-public-data.uspto_oce_office_actions.office_actions` oa
WHERE oa.application_number IN (
  SELECT cp.application_number
  FROM `patents-public-data.uspto_oce_pair.continuity_parents` cp
  WHERE cp.continuation_type IN ('CON', 'DIV')
)
"""
df_oa = client.query(q_oa).to_dataframe()
print(f"  Office actions: {len(df_oa):,}")
df_oa.to_csv(os.path.join(DATA_DIR, "office_actions.csv"), index=False)

# ─── Summary ────────────────────────────────────────────────────────────
summary = {
    "total_twin_pairs": int(len(df_twins)),
    "diff_examiner_same_au": int(diff_same.sum()),
    "same_examiner_same_au": int(same_same.sum()),
    "discordance_diff_exam": float(df_twins.loc[diff_same, 'discordant'].mean()) if diff_same.sum() > 0 else None,
    "discordance_same_exam": float(df_twins.loc[same_same, 'discordant'].mean()) if same_same.sum() > 0 else None,
    "examiner_cells": int(len(df_leniency)),
    "office_actions": int(len(df_oa)),
    "data_source": "Google BigQuery patents-public-data.uspto_oce_pair",
    "query_date": "2026-03-29"
}
with open(os.path.join(DATA_DIR, "fetch_summary.json"), "w") as f:
    json.dump(summary, f, indent=2)

print("\n=== FETCH COMPLETE ===")
print(json.dumps(summary, indent=2))
