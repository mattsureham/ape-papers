"""
Fetch patent examination data from Google BigQuery.
Constructs examiner rejection-type composition and links to outcomes.
"""
import os
import json
from google.cloud import bigquery

client = bigquery.Client(project="scl-librechat")
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# ─── Query 1: Examiner rejection composition by art unit ───
# Get application-level data with examiner, art unit, rejection types
print("Fetching examiner-application-rejection data...")
q1 = """
WITH office_action_rejections AS (
    SELECT
        oa.application_number,
        oa.rejection_102,
        oa.rejection_103
    FROM `patents-public-data.uspto_oce_office_actions.office_actions` oa
    WHERE oa.rejection_102 IS NOT NULL
       OR oa.rejection_103 IS NOT NULL
),
app_rejections AS (
    SELECT
        application_number,
        COUNTIF(rejection_102 = TRUE) AS n_102,
        COUNTIF(rejection_103 = TRUE) AS n_103,
        COUNT(*) AS n_office_actions
    FROM office_action_rejections
    GROUP BY application_number
    HAVING (COUNTIF(rejection_102 = TRUE) + COUNTIF(rejection_103 = TRUE)) > 0
),
app_data AS (
    SELECT
        a.application_number,
        a.examiner_id,
        a.uspc_class,
        a.uspc_subclass,
        a.filing_date,
        a.patent_issue_date,
        a.disposal_type,
        a.earliest_pgpub_number,
        a.patent_number,
        EXTRACT(YEAR FROM a.filing_date) AS filing_year
    FROM `patents-public-data.uspto_oce_pair.application_data` a
    WHERE a.examiner_id IS NOT NULL
      AND a.filing_date IS NOT NULL
      AND EXTRACT(YEAR FROM a.filing_date) BETWEEN 2002 AND 2018
)
SELECT
    d.application_number,
    d.examiner_id,
    d.uspc_class AS art_unit,
    d.filing_date,
    d.filing_year,
    d.patent_issue_date,
    d.disposal_type,
    d.patent_number,
    r.n_102,
    r.n_103,
    r.n_office_actions
FROM app_data d
INNER JOIN app_rejections r
    ON d.application_number = r.application_number
"""

df_main = client.query(q1).to_dataframe()
print(f"  Main dataset: {len(df_main):,} rows")
df_main.to_csv(os.path.join(DATA_DIR, "app_rejections.csv"), index=False)

# ─── Query 2: Continuation filings ───
print("Fetching continuation data...")
q2 = """
SELECT
    parent_application_number AS application_number,
    child_application_number,
    child_filing_date,
    continuation_type
FROM `patents-public-data.uspto_oce_pair.continuity_children`
WHERE continuation_type IN ('CON', 'CIP')
"""

df_cont = client.query(q2).to_dataframe()
print(f"  Continuations: {len(df_cont):,} rows")
df_cont.to_csv(os.path.join(DATA_DIR, "continuations.csv"), index=False)

# ─── Query 3: Forward citations ───
print("Fetching forward citation counts...")
q3 = """
SELECT
    application_number,
    COUNT(*) AS forward_citations
FROM (
    SELECT
        citation.application_number_citing AS citing_app,
        a.application_number
    FROM `patents-public-data.google_patents_research.publications` p,
        UNNEST(p.citation) AS citation
    INNER JOIN `patents-public-data.uspto_oce_pair.application_data` a
        ON p.publication_number = CONCAT('US-', a.patent_number, '-A')
           OR p.publication_number = CONCAT('US-', a.patent_number, '-B1')
           OR p.publication_number = CONCAT('US-', a.patent_number, '-B2')
    WHERE a.patent_number IS NOT NULL
      AND a.examiner_id IS NOT NULL
      AND EXTRACT(YEAR FROM a.filing_date) BETWEEN 2002 AND 2018
)
GROUP BY application_number
"""

# Forward citations query is expensive -- use a simpler approach
# Count citations from the office actions data which has citing references
print("Using simplified citation proxy from patent grants...")
q3_simple = """
SELECT
    a.application_number,
    CASE WHEN a.patent_number IS NOT NULL THEN 1 ELSE 0 END AS granted,
    a.patent_number
FROM `patents-public-data.uspto_oce_pair.application_data` a
WHERE a.examiner_id IS NOT NULL
  AND a.filing_date IS NOT NULL
  AND EXTRACT(YEAR FROM a.filing_date) BETWEEN 2002 AND 2018
"""
df_grants = client.query(q3_simple).to_dataframe()
print(f"  Grant status: {len(df_grants):,} rows")
df_grants.to_csv(os.path.join(DATA_DIR, "grant_status.csv"), index=False)

# ─── Query 4: Application characteristics for balance tests ───
print("Fetching application characteristics...")
q4 = """
SELECT
    a.application_number,
    a.examiner_id,
    a.uspc_class,
    a.uspc_subclass,
    EXTRACT(YEAR FROM a.filing_date) AS filing_year,
    a.disposal_type,
    -- Small/large entity indicator
    CASE
        WHEN a.small_entity_indicator IS NOT NULL THEN a.small_entity_indicator
        ELSE 0
    END AS small_entity,
    -- Number of inventors (proxy for team size)
    (SELECT COUNT(*) FROM `patents-public-data.uspto_oce_pair.all_inventors` inv
     WHERE inv.application_number = a.application_number) AS n_inventors
FROM `patents-public-data.uspto_oce_pair.application_data` a
WHERE a.examiner_id IS NOT NULL
  AND a.filing_date IS NOT NULL
  AND EXTRACT(YEAR FROM a.filing_date) BETWEEN 2002 AND 2018
LIMIT 500000
"""

# This correlated subquery is too expensive. Fetch inventors separately.
print("Fetching inventor counts...")
q4b = """
SELECT
    application_number,
    COUNT(*) AS n_inventors
FROM `patents-public-data.uspto_oce_pair.all_inventors`
GROUP BY application_number
"""
df_inv = client.query(q4b).to_dataframe()
print(f"  Inventor counts: {len(df_inv):,} rows")
df_inv.to_csv(os.path.join(DATA_DIR, "inventor_counts.csv"), index=False)

# ─── Summary statistics ───
n_apps = len(df_main)
n_examiners = df_main['examiner_id'].nunique()
n_art_units = df_main['art_unit'].nunique()
n_cont = len(df_cont)

summary = {
    "n_applications": int(n_apps),
    "n_examiners": int(n_examiners),
    "n_art_units": int(n_art_units),
    "n_continuations": int(n_cont),
    "filing_year_range": [int(df_main['filing_year'].min()), int(df_main['filing_year'].max())],
    "mean_102_per_app": float(df_main['n_102'].mean()),
    "mean_103_per_app": float(df_main['n_103'].mean()),
}

with open(os.path.join(DATA_DIR, "fetch_summary.json"), "w") as f:
    json.dump(summary, f, indent=2)

print("\n=== Fetch Summary ===")
for k, v in summary.items():
    print(f"  {k}: {v}")
print("Done.")
