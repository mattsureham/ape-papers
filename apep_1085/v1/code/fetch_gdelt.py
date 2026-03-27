
from google.cloud import bigquery
import pandas as pd

client = bigquery.Client(project="scl-librechat")

query = """
SELECT
  PARSE_DATE("%Y%m%d", CAST(SQLDATE AS STRING)) AS event_date,
  Year AS year,
  MonthYear,
  EventCode,
  EventRootCode,
  QuadClass,
  GoldsteinScale,
  NumMentions,
  NumSources,
  NumArticles,
  ActionGeo_Lat AS latitude,
  ActionGeo_Long AS longitude,
  ActionGeo_FeatureName AS location,
  ActionGeo_ADM1Code AS admin1_code,
  ActionGeo_ADM2Code AS admin2_code,
  Actor1Name,
  Actor2Name,
  SOURCEURL
FROM `gdelt-bq.gdeltv2.events`
WHERE ActionGeo_CountryCode = "GH"
  AND Year BETWEEN 2010 AND 2024
  AND EventRootCode IN ("14","15","17","18","19","20")
ORDER BY SQLDATE
"""

print("Running BigQuery query...")
df = client.query(query).to_dataframe()
print(f"Total GDELT events fetched: {len(df)}")

# Map CAMEO root codes to event types
event_type_map = {
    "14": "Protest",
    "15": "Exhibit force posture",
    "17": "Coerce",
    "18": "Assault",
    "19": "Fight",
    "20": "Mass violence"
}

df["event_type"] = df["EventRootCode"].map(event_type_map)

# Classify into broader categories matching our analysis
df["is_protest"] = (df["EventRootCode"] == "14").astype(int)
df["is_violence"] = df["EventRootCode"].isin(["18","19","20"]).astype(int)
df["is_coerce"] = df["EventRootCode"].isin(["15","17"]).astype(int)

print(f"Event type distribution:")
print(df["event_type"].value_counts())

df.to_csv("data/gdelt_ghana.csv", index=False)
print("Saved to data/gdelt_ghana.csv")

