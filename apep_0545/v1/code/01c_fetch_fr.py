#!/usr/bin/env python3
"""
01c_fetch_fr.py
Fetch Federal Register data for all 12 agencies, 2015-2024
Output: data/fr_agency_quarter.csv
"""

import json
import time
import ssl
import urllib.request
import urllib.parse
import pandas as pd
from pathlib import Path

script_dir = Path(__file__).parent.parent
data_dir = script_dir / "data"
data_dir.mkdir(exist_ok=True)

FR_OUTPUT = data_dir / "fr_agency_quarter.csv"

# Create SSL context that works on macOS
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

AGENCIES = [
    {"id": "EPA",   "slug": "environmental-protection-agency",                  "sector": "environment"},
    {"id": "OSHA",  "slug": "occupational-safety-and-health-administration",    "sector": "occupational_safety"},
    {"id": "FDA",   "slug": "food-and-drug-administration",                     "sector": "food_drug"},
    {"id": "NHTSA", "slug": "national-highway-traffic-safety-administration",   "sector": "auto_safety"},
    {"id": "FAA",   "slug": "federal-aviation-administration",                  "sector": "aviation"},
    {"id": "FRA",   "slug": "federal-railroad-administration",                  "sector": "railroad"},
    {"id": "MSHA",  "slug": "mine-safety-and-health-administration",            "sector": "mining"},
    {"id": "CPSC",  "slug": "consumer-product-safety-commission",               "sector": "consumer_products"},
    {"id": "FMCSA", "slug": "federal-motor-carrier-safety-administration",      "sector": "trucking"},
    {"id": "PHMSA", "slug": "pipeline-and-hazardous-materials-safety-administration", "sector": "pipeline"},
    {"id": "NRC",   "slug": "nuclear-regulatory-commission",                    "sector": "nuclear"},
    {"id": "CFTC",  "slug": "commodity-futures-trading-commission",             "sector": "financial_derivatives"},
]

YEARS = list(range(2015, 2025))
QUARTERS = [1, 2, 3, 4]

QUARTER_MONTHS = {
    1: ("01", "03", "31"),
    2: ("04", "06", "30"),
    3: ("07", "09", "30"),
    4: ("10", "12", "31"),
}


def fetch_fr_data(agency_slug, year, quarter, retries=3):
    """Fetch Federal Register rules for one agency-year-quarter."""
    start_m, end_m, end_d = QUARTER_MONTHS[quarter]
    start_date = f"{year}-{start_m}-01"
    end_date   = f"{year}-{end_m}-{end_d}"

    params = {
        "fields[]": ["document_number", "publication_date", "type", "significant", "action"],
        "per_page": "1000",
        "conditions[agencies][]": agency_slug,
        "conditions[publication_date][gte]": start_date,
        "conditions[publication_date][lte]": end_date,
        "conditions[type][]": ["RULE", "PRORULE"],
    }

    # Build URL manually for array params
    base_url = "https://www.federalregister.gov/api/v1/documents.json"
    param_parts = []
    for k, v in params.items():
        if isinstance(v, list):
            for item in v:
                param_parts.append(f"{urllib.parse.quote(k)}={urllib.parse.quote(str(item))}")
        else:
            param_parts.append(f"{urllib.parse.quote(k)}={urllib.parse.quote(str(v))}")
    url = base_url + "?" + "&".join(param_parts)

    for attempt in range(retries):
        try:
            time.sleep(0.4)
            req = urllib.request.Request(url, headers={"User-Agent": "APEP-Research/1.0"})
            with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
                data = json.loads(resp.read())

            results = data.get("results", [])
            total   = data.get("count", 0)

            n_final    = sum(1 for r in results if r.get("type") == "RULE")
            n_proposed = sum(1 for r in results if r.get("type") == "PRORULE")
            n_sig      = sum(1 for r in results if r.get("significant") is True)

            return {
                "agency_id":       agency_slug,
                "year":            year,
                "quarter":         quarter,
                "n_total":         len(results),
                "n_final_rule":    n_final,
                "n_proposed_rule": n_proposed,
                "n_significant":   n_sig,
                "api_total_count": total,
            }
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                raise RuntimeError(
                    f"FATAL: Federal Register API failed after {retries} attempts "
                    f"for {agency_slug} {year} Q{quarter}: {e}"
                )


if __name__ == "__main__":
    if FR_OUTPUT.exists():
        print(f"Federal Register data already exists: {FR_OUTPUT}")
        df = pd.read_csv(FR_OUTPUT)
        print(f"  {len(df)} rows, {df['agency_id'].nunique()} agencies")
    else:
        print("Fetching Federal Register data...")
        rows = []
        total = len(AGENCIES) * len(YEARS) * 4
        n = 0

        for agency in AGENCIES:
            for year in YEARS:
                for quarter in QUARTERS:
                    n += 1
                    if n % 20 == 0:
                        print(f"  Progress: {n}/{total} ({agency['id']}, {year} Q{quarter})")
                    try:
                        row = fetch_fr_data(agency["slug"], year, quarter)
                        row["agency_id"] = agency["id"]  # Use short ID
                        row["sector"] = agency["sector"]
                        rows.append(row)
                    except RuntimeError as e:
                        print(f"ERROR: {e}")
                        raise

        df = pd.DataFrame(rows)
        df.to_csv(FR_OUTPUT, index=False)
        print(f"\nSaved {len(df)} rows to {FR_OUTPUT}")

    # Validate
    assert df['agency_id'].nunique() >= 12, f"Expected 12 agencies, got {df['agency_id'].nunique()}"
    print("\nRules per agency (significant, sum 2015-2024):")
    print(df.groupby('agency_id')[['n_significant', 'n_final_rule', 'n_proposed_rule']].sum().to_string())
    print("\n=== FEDERAL REGISTER FETCH COMPLETE ===")
