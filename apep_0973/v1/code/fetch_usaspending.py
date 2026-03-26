#!/usr/bin/env python3
"""Fetch USAspending procurement data — rate-limit-safe version.

Usage:
  python3 fetch_usaspending.py --mode national --output data/national_totals.csv
  python3 fetch_usaspending.py --mode state --output data/state_totals.csv
  python3 fetch_usaspending.py --mode setaside_national --output data/setaside_national.csv
"""

import urllib.request, json, sys, time, csv, argparse

NAICS_CODES = [
    "42", "44", "45", "51", "52", "53",  # Wave 1 (2014)
    "31", "32", "33",                      # Wave 2 (2016)
    "62",                                  # Wave 3 (2021)
    "61", "81", "71", "72",               # Wave 4 (2022)
    "54", "56", "48", "49", "23",         # Wave 5 (2023)
    "11", "21", "22", "55"                # Never-treated
]

FY_START = 2010
FY_END = 2024

def api_call(url, body_dict, max_retries=5):
    """Make a POST request with retries and exponential backoff."""
    body = json.dumps(body_dict).encode()
    for attempt in range(max_retries):
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json",
                "User-Agent": "APEP-Research/1.0 (academic)"
            })
            resp = urllib.request.urlopen(req, timeout=90)
            return json.loads(resp.read())
        except Exception as e:
            wait = min(2 ** (attempt + 1), 30)
            print(f"  Retry {attempt+1}/{max_retries} after {wait}s: {e}", file=sys.stderr)
            time.sleep(wait)
    return None


def fetch_national(output_file, setaside=False):
    """One API call per NAICS → all fiscal years at once."""
    url = "https://api.usaspending.gov/api/v2/search/spending_over_time/"
    rows = []

    for i, naics in enumerate(NAICS_CODES):
        print(f"  [{i+1}/{len(NAICS_CODES)}] NAICS {naics}...", flush=True)

        filters = {
            "time_period": [{
                "start_date": f"{FY_START-1}-10-01",
                "end_date": f"{FY_END}-09-30"
            }],
            "naics_codes": {"require": [naics]},
            "award_type_codes": ["A", "B", "C", "D"]
        }

        if setaside:
            filters["set_aside_type_codes"] = [
                "SBA", "SBP", "8A", "8AN", "HZC", "SDVOSBC",
                "WOSB", "EDWOSB", "VSA", "VSB", "IEE", "ISBEE"
            ]

        data = api_call(url, {"group": "fiscal_year", "filters": filters})
        if data and "results" in data:
            for r in data["results"]:
                fy = int(r["time_period"]["fiscal_year"])
                if FY_START <= fy <= FY_END:
                    rows.append({
                        "naics_2d": naics,
                        "fiscal_year": fy,
                        "amount": r["aggregated_amount"]
                    })
            print(f"    Got {len([r for r in data['results']])} years")
        else:
            print(f"    FAILED")

        time.sleep(1.5)  # generous delay

    with open(output_file, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["naics_2d", "fiscal_year", "amount"])
        writer.writeheader()
        writer.writerows(rows)
    print(f"  Wrote {len(rows)} rows to {output_file}")


def fetch_state(output_file, setaside=False):
    """One API call per NAICS × fiscal_year → state breakdown."""
    url = "https://api.usaspending.gov/api/v2/search/spending_by_geography/"
    rows = []
    fiscal_years = list(range(FY_START, FY_END + 1))
    total = len(NAICS_CODES) * len(fiscal_years)
    count = 0

    for naics in NAICS_CODES:
        for fy in fiscal_years:
            count += 1
            if count % 10 == 0:
                print(f"  [{count}/{total}] NAICS {naics} FY{fy}...", flush=True)

            filters = {
                "time_period": [{
                    "start_date": f"{fy-1}-10-01",
                    "end_date": f"{fy}-09-30"
                }],
                "naics_codes": {"require": [naics]},
                "award_type_codes": ["A", "B", "C", "D"]
            }

            if setaside:
                filters["set_aside_type_codes"] = [
                    "SBA", "SBP", "8A", "8AN", "HZC", "SDVOSBC",
                    "WOSB", "EDWOSB", "VSA", "VSB", "IEE", "ISBEE"
                ]

            data = api_call(url, {
                "scope": "place_of_performance",
                "geo_layer": "state",
                "filters": filters
            })

            if data and "results" in data:
                for r in data["results"]:
                    rows.append({
                        "state_code": r["shape_code"],
                        "state_name": r["display_name"],
                        "amount": r["aggregated_amount"],
                        "population": r.get("population", 0),
                        "naics_2d": naics,
                        "fiscal_year": fy
                    })

            time.sleep(1.5)  # generous delay to avoid rate limits

    with open(output_file, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "state_code", "state_name", "amount", "population", "naics_2d", "fiscal_year"
        ])
        writer.writeheader()
        writer.writerows(rows)
    print(f"  Wrote {len(rows)} rows to {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["national", "state", "setaside_national", "setaside_state"],
                        required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    if args.mode == "national":
        fetch_national(args.output, setaside=False)
    elif args.mode == "setaside_national":
        fetch_national(args.output, setaside=True)
    elif args.mode == "state":
        fetch_state(args.output, setaside=False)
    elif args.mode == "setaside_state":
        fetch_state(args.output, setaside=True)
