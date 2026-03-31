"""Fetch state-level EU trade exposure from Census Foreign Trade API."""
import json
import os
import time
import csv
import urllib.request

# Load Census API key
env_path = os.path.join(os.path.dirname(__file__), "../../../../.env")
census_key = ""
with open(env_path) as f:
    for line in f:
        if line.startswith("CENSUS_API_KEY="):
            census_key = line.strip().split("=", 1)[1].strip('"').strip("'")
            break

key_param = f"&key={census_key}" if census_key else ""

BASE = "https://api.census.gov/data/timeseries/intltrade/exports/statehs"

# State abbreviation to FIPS mapping
STATE_FIPS = {
    'AL': 1, 'AK': 2, 'AZ': 4, 'AR': 5, 'CA': 6, 'CO': 8, 'CT': 9,
    'DE': 10, 'DC': 11, 'FL': 12, 'GA': 13, 'HI': 15, 'ID': 16, 'IL': 17,
    'IN': 18, 'IA': 19, 'KS': 20, 'KY': 21, 'LA': 22, 'ME': 23, 'MD': 24,
    'MA': 25, 'MI': 26, 'MN': 27, 'MS': 28, 'MO': 29, 'MT': 30, 'NE': 31,
    'NV': 32, 'NH': 33, 'NJ': 34, 'NM': 35, 'NY': 36, 'NC': 37, 'ND': 38,
    'OH': 39, 'OK': 40, 'OR': 41, 'PA': 42, 'RI': 44, 'SC': 45, 'SD': 46,
    'TN': 47, 'TX': 48, 'UT': 49, 'VT': 50, 'VA': 51, 'WA': 53, 'WV': 54,
    'WI': 55, 'WY': 56
}

# EU-28 country codes (Census trade data)
EU_COUNTRIES = {
    '4190': 'Germany', '4279': 'France', '4210': 'Netherlands',
    '4120': 'Italy', '4280': 'United Kingdom',
    '4220': 'Belgium', '4050': 'Austria', '4250': 'Spain',
    '4090': 'Denmark', '4170': 'Ireland',
    '4230': 'Poland', '4260': 'Sweden', '4080': 'Czech Republic',
    '4100': 'Finland', '4240': 'Romania'
}


def fetch_state_exports(cty_code):
    """Fetch state exports for a given country code."""
    url = f"{BASE}?get=CTY_NAME,ALL_VAL_YR,STATE&time=2016-04&CTY_CODE={cty_code}{key_param}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            if len(data) < 2:
                return {}
            results = {}
            for row in data[1:]:
                state_abbr = row[2]
                val = int(row[1]) if row[1] and row[1] != '0' else 0
                if state_abbr in STATE_FIPS:
                    results[state_abbr] = val
            return results
    except Exception as e:
        print(f"  Error fetching {cty_code}: {e}")
        return {}


# Fetch total exports by state
print("Fetching total state exports...")
total = fetch_state_exports("-")
print(f"  Got {len(total)} states")

# Fetch EU country exports
print("Fetching EU country exports...")
eu_exports = {}
for code, name in EU_COUNTRIES.items():
    print(f"  {name} ({code})...", end=" ")
    state_vals = fetch_state_exports(code)
    for st, val in state_vals.items():
        eu_exports[st] = eu_exports.get(st, 0) + val
    print(f"{len(state_vals)} states")
    time.sleep(0.5)

# Compute EU share
print("\nComputing EU trade shares...")
output_path = os.path.join(os.path.dirname(__file__), "../data/trade_exposure.csv")
with open(output_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['state_fips', 'state_abbr', 'total_exports', 'eu_exports', 'eu_share'])
    for st in sorted(total.keys()):
        fips = STATE_FIPS.get(st)
        if fips is None:
            continue
        tot = total[st]
        eu = eu_exports.get(st, 0)
        share = eu / tot if tot > 0 else 0
        writer.writerow([fips, st, tot, eu, f"{share:.6f}"])
        if share > 0.3:
            print(f"  High EU share: {st} = {share:.3f}")

print(f"\nSaved to {output_path}")
print(f"Mean EU share: {sum(eu_exports.get(s, 0) for s in total) / sum(total.values()):.4f}")
