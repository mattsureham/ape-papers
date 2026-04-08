"""01b_fetch_fec.py — Fetch FEC small-dollar contributions for protest cities.

Uses concurrent requests to speed up API queries.
"""

import os
import csv
import json
import time
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

# Load .env
env_path = os.path.join(os.path.expanduser("~"), "auto-policy-evals", ".env")
env_vars = {}
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            k, v = line.split('=', 1)
            env_vars[k.strip()] = v.strip().strip('"').strip("'")

FEC_KEY = env_vars.get('FEC_API_KEY', 'DEMO_KEY')
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

# Read protest cities from GDELT data
protests_file = os.path.join(DATA_DIR, "ccc_protests.csv")
city_counts = {}
with open(protests_file) as f:
    reader = csv.DictReader(f)
    for row in reader:
        cs = row['city_state']
        city_counts[cs] = city_counts.get(cs, 0) + 1

# Top 30 cities with 50+ protests
top_cities = sorted([(cs, n) for cs, n in city_counts.items() if n >= 50],
                    key=lambda x: -x[1])[:30]

print(f"Top {len(top_cities)} cities selected")


def fetch_fec_city_period(city_state, period):
    """Fetch up to 500 contributions for a city-period."""
    city = city_state.split(',')[0].strip().upper()
    state = city_state.split(',')[1].strip()

    results = []
    last_index = None
    last_date = None

    for page in range(5):  # max 5 pages × 100 = 500
        params = {
            'api_key': FEC_KEY,
            'contributor_city': city,
            'contributor_state': state,
            'two_year_transaction_period': str(period),
            'max_amount': '200',
            'min_amount': '1',
            'per_page': '100',
        }
        if last_index:
            params['last_index'] = last_index
            params['last_contribution_receipt_date'] = last_date

        url = 'https://api.open.fec.gov/v1/schedules/schedule_a/?' + urllib.parse.urlencode(params)

        try:
            resp = urllib.request.urlopen(url, timeout=30)
            data = json.loads(resp.read())
        except Exception as e:
            break

        if not data.get('results'):
            break

        for r in data['results']:
            results.append({
                'contributor_city': r.get('contributor_city', ''),
                'contributor_state': r.get('contributor_state', ''),
                'contribution_receipt_date': r.get('contribution_receipt_date', ''),
                'contribution_receipt_amount': r.get('contribution_receipt_amount', 0),
                'committee_name': r.get('committee_name', ''),
                'contributor_name': r.get('contributor_name', ''),
            })

        indexes = data.get('pagination', {}).get('last_indexes', {})
        last_index = indexes.get('last_index')
        last_date = indexes.get('last_contribution_receipt_date')
        if not last_index:
            break

        time.sleep(0.3)

    return results


def main():
    periods = [2020, 2022]
    tasks = [(cs, p) for cs, _ in top_cities for p in periods]
    total = len(tasks)
    print(f"Total queries: {total}")

    all_results = []
    completed = 0

    # Use 3 parallel workers (FEC rate limit)
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = {executor.submit(fetch_fec_city_period, cs, p): (cs, p)
                   for cs, p in tasks}

        for future in as_completed(futures):
            completed += 1
            cs, p = futures[future]
            result = future.result()
            all_results.extend(result)
            if completed % 10 == 0:
                print(f"  {completed}/{total}: {len(all_results):,} contributions", flush=True)

    print(f"\nTotal contributions: {len(all_results):,}")

    # Write CSV
    outpath = os.path.join(DATA_DIR, "fec_contributions.csv")
    with open(outpath, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'contributor_city', 'contributor_state', 'contribution_receipt_date',
            'contribution_receipt_amount', 'committee_name', 'contributor_name'
        ])
        writer.writeheader()
        writer.writerows(all_results)

    print(f"Saved to {outpath}")


if __name__ == "__main__":
    main()
