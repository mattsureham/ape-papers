#!/usr/bin/env python3
"""Pull GDELT GKG topic-day tone and disaster/sports competing-news counts via BigQuery."""
import pathlib
from google.cloud import bigquery

OUT = pathlib.Path(__file__).resolve().parents[1] / "data"
OUT.mkdir(parents=True, exist_ok=True)

client = bigquery.Client(project="scl-librechat")

# Topics: keyword list matched against Themes + DocumentIdentifier for robustness.
TOPICS = {
    "immigration": "('IMMIGRATION','MIGRATION','BORDER_SECURITY','ILLEGAL_IMMIGRATION')",
    "elections":   "('ELECTION','ELECTION_FRAUD','DEMOCRACY','VOTING','POLITICAL_PARTY')",
    "healthcare":  "('HEALTH_','HEALTHCARE','AFFORDABLE_CARE_ACT','OBAMACARE','MEDICARE')",
    "economy":     "('ECON_','ECONOMY','INFLATION','UNEMPLOYMENT','RECESSION')",
    "crime":       "('CRIME','KILL','MURDER','SHOOTING','ARREST')",
    "climate":     "('ENV_CLIMATE','CLIMATE_CHANGE','GLOBAL_WARMING','GREEN_ENERGY')",
    "covid":       "('TAX_DISEASE_CORONAVIRUS','HEALTH_PANDEMIC','PANDEMIC')",
}

def pull_topic(name, theme_tuple):
    print(f"[gdelt] {name}")
    sql = f"""
    SELECT
      DATE(_PARTITIONTIME) AS day,
      '{name}' AS topic,
      COUNT(*) AS n_articles,
      AVG(SAFE_CAST(SPLIT(V2Tone, ',')[OFFSET(0)] AS FLOAT64)) AS avg_tone,
      STDDEV(SAFE_CAST(SPLIT(V2Tone, ',')[OFFSET(0)] AS FLOAT64)) AS sd_tone
    FROM `gdelt-bq.gdeltv2.gkg_partitioned`
    WHERE _PARTITIONTIME BETWEEN TIMESTAMP('2017-01-01') AND TIMESTAMP('2024-12-31')
      AND (
        REGEXP_CONTAINS(UPPER(V2Themes), r'{"|".join(t.strip("'") for t in theme_tuple.strip("()").split(","))}')
      )
    GROUP BY day
    ORDER BY day
    """
    df = client.query(sql).to_dataframe()
    path = OUT / f"gdelt_topic_{name}.parquet"
    df.to_parquet(path, index=False)
    print(f"  rows={len(df)} -> {path.name}")

for name, themes in TOPICS.items():
    try:
        pull_topic(name, themes)
    except Exception as e:
        print(f"  ERROR {name}: {e}")

# Total competing-news denominator (daily article count)
print("[gdelt] total_daily")
sql_total = """
SELECT
  DATE(_PARTITIONTIME) AS day,
  COUNT(*) AS total_articles
FROM `gdelt-bq.gdeltv2.gkg_partitioned`
WHERE _PARTITIONTIME BETWEEN TIMESTAMP('2017-01-01') AND TIMESTAMP('2024-12-31')
GROUP BY day
ORDER BY day
"""
dft = client.query(sql_total).to_dataframe()
dft.to_parquet(OUT / "gdelt_total_daily.parquet", index=False)
print(f"  rows={len(dft)}")

# Disasters + sports counts for Eisensee-Stromberg IV
print("[gdelt] disasters_sports")
sql_iv = """
SELECT
  PARSE_DATE('%Y%m%d', CAST(SQLDATE AS STRING)) AS day,
  COUNTIF(EventRootCode = '07' OR EventRootCode = '08') AS coop_events,
  COUNTIF(EventRootCode IN ('14','15','18','19','20')) AS conflict_events,
  COUNTIF(EventCode IN ('0233','0243','0333')) AS sports_events,
  COUNTIF(EventCode LIKE '023%' OR EventCode LIKE '024%') AS disaster_related,
  SUM(NumArticles) AS total_articles_events
FROM `gdelt-bq.gdeltv2.events_partitioned`
WHERE _PARTITIONTIME BETWEEN TIMESTAMP('2017-01-01') AND TIMESTAMP('2024-12-31')
GROUP BY day
ORDER BY day
"""
dfi = client.query(sql_iv).to_dataframe()
dfi.to_parquet(OUT / "gdelt_iv_daily.parquet", index=False)
print(f"  rows={len(dfi)}")
print("done")
