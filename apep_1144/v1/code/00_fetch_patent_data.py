"""
Fetch patent application data from BigQuery and construct examiner leniency instrument.
Outputs: data/patent_panel.csv (state × year), data/censoring_check.csv
"""
import pandas as pd
from google.cloud import bigquery
import json
import os

os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.makedirs("data", exist_ok=True)

client = bigquery.Client(project="gen-lang-client-0330172635")

# ─── 1. Fetch resolved applications with examiner and first US inventor ───
print("Fetching patent applications joined to first US inventor...")
q_apps = """
WITH first_us_inv AS (
  SELECT application_number, inventor_region_code AS state,
         ROW_NUMBER() OVER (PARTITION BY application_number ORDER BY CAST(inventor_rank AS INT64)) AS rn
  FROM `patents-public-data.uspto_oce_pair.all_inventors`
  WHERE inventor_country_code = 'US'
    AND inventor_region_code IS NOT NULL
)
SELECT
  a.application_number,
  a.filing_date,
  a.disposal_type,
  a.examiner_id,
  a.examiner_art_unit,
  a.uspc_class,
  a.patent_issue_date,
  a.abandon_date,
  a.small_entity_indicator,
  i.state AS inventor_state
FROM `patents-public-data.uspto_oce_pair.application_data` a
INNER JOIN first_us_inv i
  ON a.application_number = i.application_number AND i.rn = 1
WHERE a.examiner_id IS NOT NULL
  AND a.filing_date IS NOT NULL
  AND SAFE_CAST(SUBSTR(a.filing_date, 1, 4) AS INT64) BETWEEN 2001 AND 2015
"""
df = client.query(q_apps).to_dataframe()
print(f"  Fetched {len(df):,} applications with US first inventor")

# Parse dates
df["filing_year"] = df["filing_date"].str[:4].astype(int)
df["granted"] = (df["disposal_type"] == "ISS").astype(int)
df["resolved"] = df["disposal_type"].isin(["ISS", "ABN"]).astype(int)

# ─── 2. Censoring check ───
print("\nCensoring check by filing year:")
censor = df.groupby("filing_year").agg(
    n_apps=("application_number", "count"),
    n_resolved=("resolved", "sum"),
    n_granted=("granted", "sum"),
).reset_index()
censor["pct_unresolved"] = 100 * (1 - censor["n_resolved"] / censor["n_apps"])
censor["grant_rate"] = censor["n_granted"] / censor["n_resolved"]
print(censor.to_string(index=False))
censor.to_csv("data/censoring_check.csv", index=False)

# Apply censoring rule: drop filing years with >20% unresolved
max_year = censor.loc[censor["pct_unresolved"] <= 20, "filing_year"].max()
print(f"\nCensoring rule: last clean filing year = {max_year}")
df = df[df["filing_year"] <= max_year].copy()
print(f"  After censoring: {len(df):,} applications")

# ─── 3. Construct leave-one-out examiner leniency within art-unit × year ───
print("\nConstructing LOO examiner leniency by art-unit × year...")

# Only use resolved applications for leniency calculation
resolved = df[df["resolved"] == 1].copy()

# For each application, compute examiner's LOO grant rate within art-unit-year
resolved["au_year"] = resolved["examiner_art_unit"] + "_" + resolved["filing_year"].astype(str)

# Group stats for LOO calculation
au_yr_exam = resolved.groupby(["au_year", "examiner_id"]).agg(
    exam_grants=("granted", "sum"),
    exam_n=("resolved", "sum"),
).reset_index()

au_yr_totals = resolved.groupby("au_year").agg(
    au_grants=("granted", "sum"),
    au_n=("resolved", "sum"),
).reset_index()

au_yr_exam = au_yr_exam.merge(au_yr_totals, on="au_year")

# LOO: (art-unit-year total grants - this examiner's grants) / (art-unit-year total apps - this examiner's apps)
au_yr_exam["loo_leniency"] = (
    (au_yr_exam["au_grants"] - au_yr_exam["exam_grants"]) /
    (au_yr_exam["au_n"] - au_yr_exam["exam_n"])
)
# Drop cases where examiner is the only one in art-unit-year
au_yr_exam = au_yr_exam[au_yr_exam["au_n"] > au_yr_exam["exam_n"]].copy()

# Merge back to get each application's LOO examiner leniency
resolved = resolved.merge(
    au_yr_exam[["au_year", "examiner_id", "loo_leniency"]],
    on=["au_year", "examiner_id"],
    how="inner"
)
print(f"  Applications with LOO leniency: {len(resolved):,}")

# ─── 4. Compute art-unit-year shifts (average LOO leniency) ───
shifts = resolved.groupby(["examiner_art_unit", "filing_year"]).agg(
    shift=("loo_leniency", "mean"),
    n_apps=("application_number", "count"),
).reset_index()
print(f"  Art-unit × year shifts: {len(shifts):,}")

# ─── 5. Compute state × art-unit shares (fixed 2001-2003 window) ───
print("\nComputing fixed state × art-unit shares (2001-2003)...")
share_df = df[df["filing_year"].between(2001, 2003)].copy()
state_au = share_df.groupby(["inventor_state", "examiner_art_unit"]).size().reset_index(name="n")
state_totals = share_df.groupby("inventor_state").size().reset_index(name="state_total")
state_au = state_au.merge(state_totals, on="inventor_state")
state_au["share"] = state_au["n"] / state_au["state_total"]
print(f"  State × art-unit share cells: {len(state_au):,}")
print(f"  States: {state_au['inventor_state'].nunique()}")

# ─── 6. Construct Bartik instrument: sum_a(share_sa × shift_at) ───
print("\nConstructing Bartik instrument...")
# Cross state shares with art-unit-year shifts
bartik_inputs = state_au[["inventor_state", "examiner_art_unit", "share"]].merge(
    shifts[["examiner_art_unit", "filing_year", "shift"]],
    on="examiner_art_unit"
)
bartik_inputs["weighted_shift"] = bartik_inputs["share"] * bartik_inputs["shift"]
bartik = bartik_inputs.groupby(["inventor_state", "filing_year"]).agg(
    bartik=("weighted_shift", "sum"),
).reset_index()
print(f"  Bartik cells (state × year): {len(bartik):,}")

# ─── 7. Compute state × year grant counts ───
print("\nComputing state × year grants...")
grants = resolved.groupby(["inventor_state", "filing_year"]).agg(
    total_grants=("granted", "sum"),
    total_apps=("application_number", "count"),
).reset_index()

# ─── 8. Merge into final panel ───
panel = bartik.merge(grants, on=["inventor_state", "filing_year"], how="left")
panel = panel.rename(columns={"inventor_state": "state", "filing_year": "year"})

# Filter to estimating sample (post-share window)
panel = panel[panel["year"] >= 2004].copy()
panel = panel.sort_values(["state", "year"])

print(f"\nFinal patent panel: {len(panel)} state-year obs")
print(f"  States: {panel['state'].nunique()}")
print(f"  Years: {panel['year'].min()}-{panel['year'].max()}")
print(f"  Bartik SD: {panel['bartik'].std():.4f}")
print(f"  Grants range: {panel['total_grants'].min()}-{panel['total_grants'].max()}")

panel.to_csv("data/patent_panel.csv", index=False)
print("\nSaved data/patent_panel.csv")

# ─── 9. Save diagnostics ───
diag = {
    "n_states": int(panel["state"].nunique()),
    "n_years": int(panel["year"].nunique()),
    "n_obs": len(panel),
    "year_range": [int(panel["year"].min()), int(panel["year"].max())],
    "bartik_sd": float(panel["bartik"].std()),
    "bartik_mean": float(panel["bartik"].mean()),
    "max_clean_filing_year": int(max_year),
    "total_resolved_apps": int(len(resolved)),
    "n_art_units_in_shares": int(state_au["examiner_art_unit"].nunique()),
}
with open("data/patent_diagnostics.json", "w") as f:
    json.dump(diag, f, indent=2)
print("Saved data/patent_diagnostics.json")
