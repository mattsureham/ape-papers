
import sys
from google.cloud import bigquery
import pandas as pd

client = bigquery.Client(project="scl-librechat")

agency_terms = {"VA":["veterans affairs"],"EPA":["environmental protection agency","EPA"],"FDA":["food and drug","FDA"],"FAA":["federal aviation","FAA","aviation safety"],"FEMA":["FEMA","emergency management"],"IRS":["internal revenue","IRS"],"DHS":["homeland security"],"DOD":["department of defense","pentagon"],"HHS":["health and human services"],"DOJ":["department of justice","attorney general"],"DOE":["department of energy"],"USDA":["department of agriculture","USDA"],"DOI":["department of interior"],"DOL":["department of labor","OSHA"],"DOT":["department of transportation"],"ED":["department of education"],"HUD":["housing and urban development","HUD"],"CDC":["disease control","CDC"],"NASA":["NASA"]}

scandal_words = ["scandal", "investigation", "misconduct", "fraud",
                 "negligence", "whistleblower", "resign", "corruption",
                 "cover-up", "abuse", "mismanagement", "accountability",
                 "inspector general", "probe"]

scandal_condition = " OR ".join([
    f"LOWER(V2ExtrasXML) LIKE \"%{w}%\"" for w in scandal_words
])

results = []

for agency_code, terms in agency_terms.items():
    print(f"Querying GDELT for {agency_code}...", file=sys.stderr, flush=True)

    org_conditions = " OR ".join([
        f"LOWER(V2ExtrasXML) LIKE \"%{t.lower()}%\"" for t in terms
    ])

    query = f"""
    SELECT
        FORMAT_DATE("%Y-%m-01", DATE(_PARTITIONTIME)) as month,
        COUNT(*) as total_mentions,
        COUNTIF({scandal_condition}) as scandal_mentions
    FROM `gdelt-bq.gdeltv2.gkg_partitioned`
    WHERE _PARTITIONTIME >= "2015-01-01"
        AND _PARTITIONTIME < "2025-01-01"
        AND ({org_conditions})
    GROUP BY month
    ORDER BY month
    """

    try:
        df = client.query(query).to_dataframe()
        df["agency_code"] = agency_code
        results.append(df)
        print(f"  {agency_code}: {len(df)} months, {int(df.total_mentions.sum())} total, "
              f"{int(df.scandal_mentions.sum())} scandal", file=sys.stderr, flush=True)
    except Exception as e:
        print(f"  ERROR for {agency_code}: {e}", file=sys.stderr, flush=True)

if results:
    combined = pd.concat(results, ignore_index=True)
    combined.to_csv("data/gdelt_media_coverage.csv", index=False)
    print(f"Saved {len(combined)} rows", file=sys.stderr, flush=True)
else:
    print("FATAL: No GDELT data", file=sys.stderr, flush=True)
    sys.exit(1)

# Competing news: Olympics, impeachment, World Cup, royals
print("\nQuerying competing news...", file=sys.stderr, flush=True)

competing_query = """
SELECT
    FORMAT_DATE("%Y-%m-01", DATE(_PARTITIONTIME)) as month,
    COUNT(*) as total_articles,
    COUNTIF(
        LOWER(V2ExtrasXML) LIKE "%olympic%"
        OR LOWER(V2Themes) LIKE "%SPORTS_OLYMPICS%"
    ) as olympics_mentions,
    COUNTIF(
        LOWER(V2ExtrasXML) LIKE "%impeach%"
        OR LOWER(V2Themes) LIKE "%IMPEACH%"
    ) as impeachment_mentions,
    COUNTIF(
        LOWER(V2ExtrasXML) LIKE "%world cup%"
        OR LOWER(V2Themes) LIKE "%WORLD_CUP%"
    ) as worldcup_mentions,
    COUNTIF(
        LOWER(V2ExtrasXML) LIKE "%royal wedding%"
        OR LOWER(V2ExtrasXML) LIKE "%queen elizabeth%"
        OR LOWER(V2ExtrasXML) LIKE "%king charles%"
    ) as royals_mentions
FROM `gdelt-bq.gdeltv2.gkg_partitioned`
WHERE _PARTITIONTIME >= "2015-01-01"
    AND _PARTITIONTIME < "2025-01-01"
GROUP BY month
ORDER BY month
"""

try:
    competing_df = client.query(competing_query).to_dataframe()
    competing_df.to_csv("data/gdelt_competing_news.csv", index=False)
    print(f"Saved competing news: {len(competing_df)} months", file=sys.stderr, flush=True)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr, flush=True)
    sys.exit(1)

print("Done.", file=sys.stderr, flush=True)

