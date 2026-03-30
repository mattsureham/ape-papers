"""Fetch GFW fishing effort data from BigQuery and save as CSV."""

from google.cloud import bigquery
import pandas as pd
import os

client = bigquery.Client(project="scl-librechat")

# Annual aggregation: flag state × year
print("Querying BigQuery for annual GFW fishing effort...")
annual_query = """
SELECT
  flag AS flag_iso3,
  EXTRACT(YEAR FROM date) AS year,
  COUNT(DISTINCT ssvid) AS n_vessels,
  SUM(fishing_hours) AS fishing_hours,
  SUM(hours) AS total_hours
FROM `global-fishing-watch.gfw_public_data.fishing_effort_byvessel_v2`
WHERE EXTRACT(YEAR FROM date) BETWEEN 2012 AND 2024
  AND flag IS NOT NULL
  AND fishing_hours > 0
GROUP BY flag, EXTRACT(YEAR FROM date)
ORDER BY flag, year
"""

annual_df = client.query(annual_query).to_dataframe()
print(f"Annual data: {len(annual_df)} rows, {annual_df['flag_iso3'].nunique()} flag states, "
      f"years {annual_df['year'].min()}-{annual_df['year'].max()}")

# Quarterly aggregation
print("Querying BigQuery for quarterly GFW fishing effort...")
quarterly_query = """
SELECT
  flag AS flag_iso3,
  EXTRACT(YEAR FROM date) AS year,
  EXTRACT(QUARTER FROM date) AS quarter,
  COUNT(DISTINCT ssvid) AS n_vessels,
  SUM(fishing_hours) AS fishing_hours,
  SUM(hours) AS total_hours
FROM `global-fishing-watch.gfw_public_data.fishing_effort_byvessel_v2`
WHERE EXTRACT(YEAR FROM date) BETWEEN 2012 AND 2024
  AND flag IS NOT NULL
  AND fishing_hours > 0
GROUP BY flag, EXTRACT(YEAR FROM date), EXTRACT(QUARTER FROM date)
ORDER BY flag, year, quarter
"""

quarterly_df = client.query(quarterly_query).to_dataframe()
print(f"Quarterly data: {len(quarterly_df)} rows")

# Save
data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(data_dir, exist_ok=True)

annual_df.to_csv(os.path.join(data_dir, "gfw_annual.csv"), index=False)
quarterly_df.to_csv(os.path.join(data_dir, "gfw_quarterly.csv"), index=False)

print("GFW data saved to data/gfw_annual.csv and data/gfw_quarterly.csv")
