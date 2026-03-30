"""
Fetch patent application + office action data from BigQuery REST API.
Uses GOOGLE_API_KEY for public dataset access (no ADC needed).
"""
import os
import json
import time
import requests
import pandas as pd
# Load .env manually
env_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '.env')
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

API_KEY = os.environ['GOOGLE_API_KEY']
PROJECT = 'scl-librechat'
BASE = f'https://bigquery.googleapis.com/bigquery/v2/projects/{PROJECT}'


def run_query(sql, max_results=100000):
    """Run a BigQuery SQL query using REST API with API key."""
    url = f'{BASE}/queries?key={API_KEY}'
    body = {
        'query': sql,
        'useLegacySql': False,
        'maxResults': max_results,
    }
    r = requests.post(url, json=body)
    r.raise_for_status()
    result = r.json()

    # Check for errors
    if 'errors' in result.get('status', {}):
        raise RuntimeError(f"BigQuery error: {result['status']['errors']}")

    job_id = result.get('jobReference', {}).get('jobId')
    job_complete = result.get('jobComplete', False)

    # Poll until job completes
    while not job_complete:
        time.sleep(2)
        poll_url = f'{BASE}/queries/{job_id}?key={API_KEY}&maxResults={max_results}'
        r = requests.get(poll_url)
        r.raise_for_status()
        result = r.json()
        job_complete = result.get('jobComplete', False)

    # Collect all rows (handle pagination)
    rows = result.get('rows', [])
    schema = result.get('schema', {}).get('fields', [])
    total = int(result.get('totalRows', len(rows)))
    page_token = result.get('pageToken')

    while page_token and len(rows) < total:
        url = f'{BASE}/queries/{job_id}?key={API_KEY}&maxResults={max_results}&pageToken={page_token}'
        r = requests.get(url)
        r.raise_for_status()
        result = r.json()
        rows.extend(result.get('rows', []))
        page_token = result.get('pageToken')
        print(f"  ... fetched {len(rows):,} / {total:,} rows")

    # Convert to dataframe
    col_names = [f['name'] for f in schema]
    data = [[cell.get('v') for cell in row.get('f', [])] for row in rows]
    df = pd.DataFrame(data, columns=col_names)
    return df


# ------------------------------------------------------------------
# 1. Application data + OA counts in a single query (efficient)
# ------------------------------------------------------------------
print("Fetching application data with OA counts...")
query = """
SELECT
    a.application_number,
    EXTRACT(YEAR FROM a.filing_date) AS filing_year,
    a.disposal_type,
    a.examiner_id,
    CAST(a.examiner_art_unit AS STRING) AS art_unit,
    a.uspc_class,
    CASE WHEN a.small_entity_indicator = 1 THEN 1 ELSE 0 END AS small_entity,
    COALESCE(oa.n_oa, 0) AS n_office_actions
FROM `patents-public-data.uspto_oce_pair.application_data` a
LEFT JOIN (
    SELECT application_number, COUNT(*) AS n_oa
    FROM `patents-public-data.uspto_oce_office_actions.office_actions`
    GROUP BY application_number
) oa ON a.application_number = oa.application_number
WHERE a.disposal_type IN ('ISS', 'ABN')
    AND a.filing_date >= '2002-01-01'
    AND a.filing_date < '2015-01-01'
    AND a.examiner_id IS NOT NULL
    AND a.examiner_art_unit IS NOT NULL
"""

df = run_query(query)
print(f"  Raw applications: {len(df):,}")

# Type conversion
for col in ['filing_year', 'small_entity', 'n_office_actions']:
    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)

df['abandoned'] = (df['disposal_type'] == 'ABN').astype(int)
df['au_year'] = df['art_unit'] + '_' + df['filing_year'].astype(str)

print(f"  Small entities: {df['small_entity'].sum():,} ({100*df['small_entity'].mean():.1f}%)")
print(f"  Abandoned: {df['abandoned'].sum():,} ({100*df['abandoned'].mean():.1f}%)")
print(f"  Mean OAs: {df['n_office_actions'].mean():.2f}")

# ------------------------------------------------------------------
# 2. Construct examiner LOO OA average within art-unit x year
# ------------------------------------------------------------------
print("Constructing leave-one-out examiner OA averages...")

examiner_stats = df.groupby(['examiner_id', 'au_year']).agg(
    ex_n=('n_office_actions', 'count'),
    ex_oa_sum=('n_office_actions', 'sum')
).reset_index()

au_year_stats = df.groupby('au_year').agg(
    auy_n=('n_office_actions', 'count'),
    auy_oa_sum=('n_office_actions', 'sum')
).reset_index()

examiner_stats = examiner_stats.merge(au_year_stats, on='au_year')
examiner_stats['loo_oa_avg'] = (
    (examiner_stats['auy_oa_sum'] - examiner_stats['ex_oa_sum']) /
    (examiner_stats['auy_n'] - examiner_stats['ex_n'])
)
# Drop singletons
examiner_stats = examiner_stats[examiner_stats['auy_n'] > examiner_stats['ex_n']]

df = df.merge(
    examiner_stats[['examiner_id', 'au_year', 'loo_oa_avg']],
    on=['examiner_id', 'au_year'],
    how='inner'
)

# Filter: keep cells with ≥2 examiners
au_ex_counts = df.groupby('au_year')['examiner_id'].nunique().reset_index()
au_ex_counts.columns = ['au_year', 'n_examiners']
df = df.merge(au_ex_counts, on='au_year')
df = df[df['n_examiners'] >= 2]

print(f"  Final dataset: {len(df):,} rows")
print(f"  Unique examiners: {df['examiner_id'].nunique():,}")
print(f"  Unique art-unit x year cells: {df['au_year'].nunique():,}")

# ------------------------------------------------------------------
# 3. Summary
# ------------------------------------------------------------------
print("\n--- Summary Statistics ---")
print(f"N: {len(df):,}")
print(f"Small entities: {df['small_entity'].sum():,} ({100*df['small_entity'].mean():.1f}%)")
print(f"Abandoned: {df['abandoned'].sum():,} ({100*df['abandoned'].mean():.1f}%)")
print(f"Mean OAs: {df['n_office_actions'].mean():.2f}")
print(f"LOO OA avg: mean={df['loo_oa_avg'].mean():.3f}, sd={df['loo_oa_avg'].std():.3f}")

for se in [0, 1]:
    sub = df[df['small_entity'] == se]
    label = "Small" if se == 1 else "Large"
    print(f"\n{label} entities (n={len(sub):,}):")
    print(f"  Abandoned: {100*sub['abandoned'].mean():.1f}%")
    print(f"  Mean OAs: {sub['n_office_actions'].mean():.2f}")

# ------------------------------------------------------------------
# 4. Export
# ------------------------------------------------------------------
out_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
cols = ['application_number', 'filing_year', 'abandoned', 'small_entity',
        'n_office_actions', 'examiner_id', 'art_unit', 'au_year',
        'uspc_class', 'loo_oa_avg', 'n_examiners']
df[cols].to_csv(os.path.join(out_dir, 'patent_data.csv.gz'), index=False, compression='gzip')
print(f"\nExported {len(df):,} rows to data/patent_data.csv.gz")
