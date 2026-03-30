"""
apep_1120 - Romanian 2014 EU-2 Restriction Lifting
01_fetch_data.py - Fetch data from INSSE TEMPO API

INSSE TEMPO API:
- Metadata: GET http://statistici.insse.ro:8077/tempo-ins/matrix/{MATRIX_ID}
- Data: POST http://statistici.insse.ro:8077/tempo-ins/matrix/{MATRIX_ID}/data
  Body: {"language":"ro","enclosedHeader":false,"matrixName":"...","dimensions":[...]}

Each dimension needs nomItemIds for the options we want.
"""

import requests
import json
import csv
import os
import time
import sys

BASE_URL = "http://statistici.insse.ro:8077/tempo-ins/matrix"
DATA_DIR = "data"
os.makedirs(DATA_DIR, exist_ok=True)

def get_matrix_metadata(matrix_id):
    """Get metadata including dimension structure."""
    r = requests.get(f"{BASE_URL}/{matrix_id}", timeout=60)
    r.raise_for_status()
    return r.json()

def fetch_data(matrix_id, dimensions_selection):
    """Fetch actual data from the matrix."""
    url = f"{BASE_URL}/{matrix_id}/data"
    payload = {
        "language": "ro",
        "enclosedHeader": False,
        "matrixName": matrix_id,
        "dimensions": dimensions_selection
    }
    r = requests.post(url, json=payload, timeout=120)
    r.raise_for_status()
    return r.json()

def get_all_county_ids(dims):
    """Extract county nomItemIds (skip macro/region aggregates)."""
    geo_dim = dims[2]  # Geography is typically dimension 3
    counties = []
    regions_macros = {"TOTAL", "MACROREGIUNEA", "Regiunea", "Municipiul"}
    for opt in geo_dim["options"]:
        label = opt["label"]
        # Keep only counties (not totals, macroregions, or regions)
        if not any(label.startswith(prefix) or label == prefix for prefix in regions_macros):
            if "MACROREGIUNEA" not in label and "Regiunea" not in label:
                counties.append(opt)
    return counties

def extract_years(dims):
    """Extract year dimension options."""
    year_dim = dims[3]  # Years typically dimension 4
    return year_dim["options"]

def parse_data_response(response, dim_labels):
    """Parse the nested INSSE data response into flat records."""
    records = []
    if isinstance(response, dict) and "data" in response:
        data = response["data"]
    elif isinstance(response, list):
        data = response
    else:
        data = response

    # The response is a nested list structure
    # Try to parse it based on the actual format
    if isinstance(data, dict):
        for key, values in data.items():
            if isinstance(values, dict):
                for key2, val in values.items():
                    records.append({"key1": key, "key2": key2, "value": val})
            else:
                records.append({"key": key, "value": values})
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict):
                records.append(item)
    return records


# ============================================================
# 1. FOM106E: County wages by CAEN sector
# ============================================================
print("=" * 60)
print("1. Fetching FOM106E (county wages by sector)")
print("=" * 60)

meta = get_matrix_metadata("FOM106E")
dims = meta["dimensionsMap"]

print(f"  Dimensions: {len(dims)}")
for i, dim in enumerate(dims):
    print(f"  Dim {i}: {len(dim['options'])} options — first: {dim['options'][0]['label']}")

# Select all options for each dimension (TOTAL sectors, both sexes, all counties, all years)
# Dim 0: CAEN sectors (68 options)
# Dim 1: Sex (3 options: Total, Male, Female)
# Dim 2: Geography (55 options: counties + regions)
# Dim 3: Years (17 options)
# Dim 4: Indicator (1 option)

# For county-level analysis, we want:
# - CAEN: TOTAL + section-level (A through S)
# - Sex: TOTAL only (for main analysis)
# - Geography: all 42 counties (skip aggregates)
# - Years: all available
# - Indicator: the single option

counties = get_all_county_ids(dims)
years = extract_years(dims)
print(f"  Counties: {len(counties)}")
print(f"  Years: {len(years)} ({years[0]['label']} to {years[-1]['label']})")

# Get section-level CAEN codes (A, B, C, ... S)
caen_sections = [opt for opt in dims[0]["options"]
                 if len(opt["label"]) <= 3 or opt["label"].startswith(("A ", "B ", "C ", "D ",
                 "E ", "F ", "G ", "H ", "I ", "J ", "K ", "L ", "M ", "N ", "O ", "P ",
                 "Q ", "R ", "S ", "T ", "U ", "TOTAL"))]
print(f"  CAEN sections: {len(caen_sections)}")

# Build dimension selection
dim_selection = [
    {"dimensionId": 0, "nomItemIds": [opt["nomItemId"] for opt in caen_sections]},
    {"dimensionId": 1, "nomItemIds": [dims[1]["options"][0]["nomItemId"]]},  # TOTAL sex
    {"dimensionId": 2, "nomItemIds": [c["nomItemId"] for c in counties]},
    {"dimensionId": 3, "nomItemIds": [y["nomItemId"] for y in years]},
    {"dimensionId": 4, "nomItemIds": [dims[4]["options"][0]["nomItemId"]]}
]

print("  Requesting data...")
try:
    data = fetch_data("FOM106E", dim_selection)
    print(f"  Response type: {type(data).__name__}")

    # Save raw response
    with open(os.path.join(DATA_DIR, "wages_raw.json"), "w") as f:
        json.dump(data, f, ensure_ascii=False)
    print(f"  Saved wages_raw.json ({os.path.getsize(os.path.join(DATA_DIR, 'wages_raw.json'))} bytes)")

    # Parse into flat CSV
    if isinstance(data, dict) and "data" in data:
        rows = data["data"]
    elif isinstance(data, list):
        rows = data
    else:
        rows = [data]

    # Write CSV
    if rows and isinstance(rows[0], dict):
        with open(os.path.join(DATA_DIR, "wages.csv"), "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=rows[0].keys())
            writer.writeheader()
            writer.writerows(rows)
        print(f"  Saved wages.csv ({len(rows)} rows)")
    else:
        print(f"  Data format needs custom parsing. Type: {type(rows)}")
        # Try to flatten the nested structure
        if isinstance(rows, list) and rows:
            print(f"  First element type: {type(rows[0])}")
            print(f"  Sample: {str(rows[0])[:500]}")

except Exception as e:
    print(f"  ERROR: {e}")

time.sleep(1)

# ============================================================
# 2. POP309D: Emigration by destination country
# ============================================================
print("\n" + "=" * 60)
print("2. Fetching POP309D (emigration by destination)")
print("=" * 60)

meta_emig = get_matrix_metadata("POP309D")
dims_emig = meta_emig["dimensionsMap"]

print(f"  Dimensions: {len(dims_emig)}")
for i, dim in enumerate(dims_emig):
    print(f"  Dim {i}: {len(dim['options'])} options — first: {dim['options'][0]['label']}")
    if len(dim["options"]) <= 20:
        for opt in dim["options"]:
            print(f"    {opt['nomItemId']}: {opt['label']}")

# Save metadata for reference
with open(os.path.join(DATA_DIR, "pop309d_metadata.json"), "w") as f:
    json.dump(meta_emig, f, ensure_ascii=False, indent=2)

# Fetch all data
counties_emig = get_all_county_ids(dims_emig)
years_emig = [dim for dim in dims_emig if any("199" in opt.get("label", "") or "200" in opt.get("label", "") or "201" in opt.get("label", "") for opt in dim.get("options", []))]

# Try with all options
all_ids = []
for i, dim in enumerate(dims_emig):
    all_ids.append({
        "dimensionId": i,
        "nomItemIds": [opt["nomItemId"] for opt in dim["options"]]
    })

print("  Requesting data...")
try:
    data_emig = fetch_data("POP309D", all_ids)
    with open(os.path.join(DATA_DIR, "emigration_dest_raw.json"), "w") as f:
        json.dump(data_emig, f, ensure_ascii=False)
    print(f"  Saved emigration_dest_raw.json ({os.path.getsize(os.path.join(DATA_DIR, 'emigration_dest_raw.json'))} bytes)")

    if isinstance(data_emig, dict) and "data" in data_emig:
        rows = data_emig["data"]
        if rows and isinstance(rows[0], dict):
            with open(os.path.join(DATA_DIR, "emigration_dest.csv"), "w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=rows[0].keys())
                writer.writeheader()
                writer.writerows(rows)
            print(f"  Saved emigration_dest.csv ({len(rows)} rows)")
    elif isinstance(data_emig, list):
        print(f"  Got list with {len(data_emig)} items")

except Exception as e:
    print(f"  ERROR: {e}")

time.sleep(1)

# ============================================================
# 3. POP309A: Total emigration by county
# ============================================================
print("\n" + "=" * 60)
print("3. Fetching POP309A (total emigration by county)")
print("=" * 60)

meta_emig_total = get_matrix_metadata("POP309A")
dims_et = meta_emig_total["dimensionsMap"]

print(f"  Dimensions: {len(dims_et)}")
for i, dim in enumerate(dims_et):
    print(f"  Dim {i}: {len(dim['options'])} options — first: {dim['options'][0]['label']}")

all_ids_et = [{"dimensionId": i, "nomItemIds": [opt["nomItemId"] for opt in dim["options"]]} for i, dim in enumerate(dims_et)]

try:
    data_et = fetch_data("POP309A", all_ids_et)
    with open(os.path.join(DATA_DIR, "emigration_total_raw.json"), "w") as f:
        json.dump(data_et, f, ensure_ascii=False)
    print(f"  Saved emigration_total_raw.json ({os.path.getsize(os.path.join(DATA_DIR, 'emigration_total_raw.json'))} bytes)")
except Exception as e:
    print(f"  ERROR: {e}")

time.sleep(1)

# ============================================================
# 4. FOM105G: County employment
# ============================================================
print("\n" + "=" * 60)
print("4. Fetching FOM105G (county employment)")
print("=" * 60)

meta_emp = get_matrix_metadata("FOM105G")
dims_emp = meta_emp["dimensionsMap"]

print(f"  Dimensions: {len(dims_emp)}")
for i, dim in enumerate(dims_emp):
    print(f"  Dim {i}: {len(dim['options'])} options — first: {dim['options'][0]['label']}")

all_ids_emp = [{"dimensionId": i, "nomItemIds": [opt["nomItemId"] for opt in dim["options"]]} for i, dim in enumerate(dims_emp)]

try:
    data_emp = fetch_data("FOM105G", all_ids_emp)
    with open(os.path.join(DATA_DIR, "employment_raw.json"), "w") as f:
        json.dump(data_emp, f, ensure_ascii=False)
    print(f"  Saved employment_raw.json ({os.path.getsize(os.path.join(DATA_DIR, 'employment_raw.json'))} bytes)")
except Exception as e:
    print(f"  ERROR: {e}")

# ============================================================
# 5. Eurostat: Romania->Germany immigration
# ============================================================
print("\n" + "=" * 60)
print("5. Fetching Eurostat migr_imm1ctz (RO→DE)")
print("=" * 60)

eurostat_url = (
    "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/"
    "migr_imm1ctz/A.NR.RO.DE?format=JSON&lang=en"
)
try:
    r = requests.get(eurostat_url, timeout=60)
    if r.status_code == 200:
        with open(os.path.join(DATA_DIR, "eurostat_ro_de.json"), "w") as f:
            json.dump(r.json(), f)
        print(f"  Saved eurostat_ro_de.json")
    else:
        print(f"  HTTP {r.status_code}")
except Exception as e:
    print(f"  ERROR: {e}")

# ============================================================
# Summary
# ============================================================
print("\n" + "=" * 60)
print("DATA FETCH SUMMARY")
print("=" * 60)
for f in sorted(os.listdir(DATA_DIR)):
    if f.endswith((".json", ".csv")):
        size = os.path.getsize(os.path.join(DATA_DIR, f))
        print(f"  {f}: {size:,} bytes")
