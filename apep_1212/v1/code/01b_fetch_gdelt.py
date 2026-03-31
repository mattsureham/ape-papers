"""01b_fetch_gdelt.py — Construct anti-Asian media sentiment panel from GDELT GKG via BigQuery.

Produces state × quarter panel of anti-Asian article counts and tone measures.
"""

import os
import sys
import json
from google.cloud import bigquery

# State FIPS to abbreviation mapping for location parsing
STATE_FIPS = {
    "01": "AL", "02": "AK", "04": "AZ", "05": "AR", "06": "CA",
    "08": "CO", "09": "CT", "10": "DE", "11": "DC", "12": "FL",
    "13": "GA", "15": "HI", "16": "ID", "17": "IL", "18": "IN",
    "19": "IA", "20": "KS", "21": "KY", "22": "LA", "23": "ME",
    "24": "MD", "25": "MA", "26": "MI", "27": "MN", "28": "MS",
    "29": "MO", "30": "MT", "31": "NE", "32": "NV", "33": "NH",
    "34": "NJ", "35": "NM", "36": "NY", "37": "NC", "38": "ND",
    "39": "OH", "40": "OK", "41": "OR", "42": "PA", "44": "RI",
    "45": "SC", "46": "SD", "47": "TN", "48": "TX", "49": "UT",
    "50": "VT", "51": "VA", "53": "WA", "54": "WV", "55": "WI",
    "56": "WY"
}

# Reverse: state abbreviation to FIPS
ABBREV_TO_FIPS = {v: k for k, v in STATE_FIPS.items()}

def main():
    client = bigquery.Client(project="scl-librechat")

    # ── Query 1: Anti-Asian media coverage by state and quarter ──
    # GKG Locations format: type#name#countrycode#adm1code#lat#lon#featureid;...
    # adm1code for US states: "USXX" where XX is state abbreviation
    # We extract US state from the Locations field using regex
    print("Querying GDELT GKG for anti-Asian sentiment (2016-2024)...")

    anti_asian_query = """
    WITH articles AS (
      SELECT
        DATE,
        V2Themes,
        V2Tone,
        Locations,
        CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) AS year,
        CAST(CEIL(CAST(SUBSTR(CAST(DATE AS STRING), 5, 2) AS INT64) / 3.0) AS INT64) AS quarter
      FROM `gdelt-bq.gdeltv2.gkg_partitioned`
      WHERE _PARTITIONTIME BETWEEN '2016-01-01' AND '2024-12-31'
        AND (
          V2Themes LIKE '%DISCRIMINATION%'
          OR V2Themes LIKE '%HATE_CRIME%'
          OR V2Themes LIKE '%XENOPHOBIA%'
          OR V2Themes LIKE '%RACIAL_DISCRIMINATION%'
        )
        AND (
          V2Themes LIKE '%ASIA%'
          OR V2Themes LIKE '%CHINA%'
          OR V2Themes LIKE '%CHINESE%'
          OR V2Themes LIKE '%AAPI%'
        )
        AND Locations LIKE '%#US%'
    ),
    -- Extract all US state codes from Locations field
    state_extracted AS (
      SELECT
        year,
        quarter,
        REGEXP_EXTRACT(loc, r'#US([A-Z]{2})#') AS state_abbrev,
        CAST(SPLIT(V2Tone, ',')[SAFE_OFFSET(0)] AS FLOAT64) AS tone
      FROM articles,
      UNNEST(SPLIT(Locations, ';')) AS loc
      WHERE loc LIKE '%#US%'
    )
    SELECT
      state_abbrev,
      year,
      quarter,
      COUNT(*) AS anti_asian_articles,
      SUM(CASE WHEN tone < -2 THEN 1 ELSE 0 END) AS negative_articles,
      AVG(tone) AS avg_tone,
      STDDEV(tone) AS sd_tone
    FROM state_extracted
    WHERE state_abbrev IS NOT NULL
      AND LENGTH(state_abbrev) = 2
    GROUP BY state_abbrev, year, quarter
    ORDER BY state_abbrev, year, quarter
    """

    df_anti_asian = client.query(anti_asian_query).to_dataframe()
    print(f"  Anti-Asian articles: {len(df_anti_asian)} state-quarter obs")
    print(f"  States covered: {df_anti_asian['state_abbrev'].nunique()}")
    print(f"  Year range: {df_anti_asian['year'].min()}-{df_anti_asian['year'].max()}")

    # ── Query 2: Total GKG volume by state-quarter (for normalization) ──
    print("Querying total GKG volume for normalization...")

    volume_query = """
    WITH all_articles AS (
      SELECT
        CAST(SUBSTR(CAST(DATE AS STRING), 1, 4) AS INT64) AS year,
        CAST(CEIL(CAST(SUBSTR(CAST(DATE AS STRING), 5, 2) AS INT64) / 3.0) AS INT64) AS quarter,
        Locations
      FROM `gdelt-bq.gdeltv2.gkg_partitioned`
      WHERE _PARTITIONTIME BETWEEN '2016-01-01' AND '2024-12-31'
        AND Locations LIKE '%#US%'
    ),
    state_vol AS (
      SELECT
        year,
        quarter,
        REGEXP_EXTRACT(loc, r'#US([A-Z]{2})#') AS state_abbrev,
        1 AS article_count
      FROM all_articles,
      UNNEST(SPLIT(Locations, ';')) AS loc
      WHERE loc LIKE '%#US%'
    )
    SELECT
      state_abbrev,
      year,
      quarter,
      COUNT(*) AS total_articles
    FROM state_vol
    WHERE state_abbrev IS NOT NULL
      AND LENGTH(state_abbrev) = 2
    GROUP BY state_abbrev, year, quarter
    ORDER BY state_abbrev, year, quarter
    """

    df_volume = client.query(volume_query).to_dataframe()
    print(f"  Total volume: {len(df_volume)} state-quarter obs")

    # ── Merge and compute rate ──
    df = df_anti_asian.merge(df_volume, on=["state_abbrev", "year", "quarter"], how="left")
    df["anti_asian_rate"] = df["anti_asian_articles"] / df["total_articles"] * 10000  # per 10k articles

    # Map state abbreviations to FIPS codes
    df["state_fips"] = df["state_abbrev"].map(ABBREV_TO_FIPS)
    df = df.dropna(subset=["state_fips"])

    # Save
    outpath = os.path.join(os.path.dirname(__file__), "..", "data", "gdelt_anti_asian.csv")
    df.to_csv(outpath, index=False)
    print(f"\nSaved to {outpath}")
    print(f"Final panel: {len(df)} state-quarter observations")
    print(f"Anti-Asian rate summary:\n{df['anti_asian_rate'].describe()}")

    # Print some key state-quarter values for validation
    print("\n── Key validation points ──")
    for st, yr, qtr in [("GA", 2021, 1), ("CA", 2021, 1), ("NY", 2020, 2), ("TX", 2019, 4)]:
        row = df[(df["state_abbrev"] == st) & (df["year"] == yr) & (df["quarter"] == qtr)]
        if len(row) > 0:
            r = row.iloc[0]
            print(f"  {st} {yr}Q{qtr}: {r['anti_asian_articles']:.0f} articles, "
                  f"rate={r['anti_asian_rate']:.2f}/10k, tone={r['avg_tone']:.2f}")
        else:
            print(f"  {st} {yr}Q{qtr}: no data")

if __name__ == "__main__":
    main()
