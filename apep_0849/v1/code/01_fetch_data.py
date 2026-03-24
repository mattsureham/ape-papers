"""
Fetch USPTO patent data from PatentsView bulk downloads.
Joins assignee → location → application → patent → USPC/CPC.
Filters for Taiwan (TW), Israel (IL), South Korea (KR).
Saves cleaned CSV for R analysis.
"""

import os
import csv
import io
import zipfile
import urllib.request
import json
from collections import defaultdict
from datetime import datetime

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')
os.makedirs(DATA_DIR, exist_ok=True)

BASE_URL = "https://s3.amazonaws.com/data.patentsview.org/download"
COUNTRIES = {"TW", "IL", "KR"}


def download_file(filename):
    local_path = os.path.join(DATA_DIR, filename)
    if os.path.exists(local_path):
        print(f"  Cached: {filename}")
        return local_path
    url = f"{BASE_URL}/{filename}"
    print(f"  Downloading {filename}...")
    urllib.request.urlretrieve(url, local_path)
    return local_path


def read_tsv_from_zip(zip_path):
    with zipfile.ZipFile(zip_path, 'r') as zf:
        tsv_name = [n for n in zf.namelist() if n.endswith('.tsv')][0]
        print(f"  Reading {tsv_name}...")
        with zf.open(tsv_name) as f:
            reader = csv.DictReader(io.TextIOWrapper(f, encoding='utf-8'), delimiter='\t')
            for row in reader:
                yield row


def main():
    # Step 1: location_id → country
    print("Step 1: Location → country mapping")
    loc_zip = download_file("g_location_disambiguated.tsv.zip")
    loc_to_country = {}
    for row in read_tsv_from_zip(loc_zip):
        if row.get('disambig_country', '') in COUNTRIES:
            loc_to_country[row['location_id']] = row['disambig_country']
    print(f"  {len(loc_to_country)} locations")

    # Step 2: patent_id → country (from assignee + location)
    print("\nStep 2: Patent → country")
    assignee_zip = download_file("g_assignee_disambiguated.tsv.zip")
    patent_countries = defaultdict(set)
    for row in read_tsv_from_zip(assignee_zip):
        loc_id = row.get('location_id', '')
        if loc_id in loc_to_country:
            patent_countries[row['patent_id']].add(loc_to_country[loc_id])
    target_patents = set(patent_countries.keys())
    print(f"  {len(target_patents)} patents")

    # Step 3: patent_id → filing_date (from application table)
    print("\nStep 3: Filing dates")
    app_zip = download_file("g_application.tsv.zip")
    patent_filing = {}
    for row in read_tsv_from_zip(app_zip):
        pid = row.get('patent_id', '')
        if pid in target_patents:
            patent_filing[pid] = row.get('filing_date', '')
    print(f"  Filing dates for {len(patent_filing)} patents")

    # Step 4: patent_id → grant_date, type, claims
    print("\nStep 4: Grant metadata")
    patent_zip = download_file("g_patent.tsv.zip")
    patent_meta = {}
    for row in read_tsv_from_zip(patent_zip):
        pid = row.get('patent_id', '')
        if pid in target_patents:
            patent_meta[pid] = {
                'grant_date': row.get('patent_date', ''),
                'patent_type': row.get('patent_type', ''),
                'num_claims': row.get('num_claims', ''),
            }
    print(f"  Metadata for {len(patent_meta)} patents")

    # Step 5: USPC classes
    print("\nStep 5: USPC classes")
    uspc_zip = download_file("g_uspc_at_issue.tsv.zip")
    patent_uspc = {}
    for row in read_tsv_from_zip(uspc_zip):
        pid = row.get('patent_id', '')
        if pid in target_patents and pid not in patent_uspc:
            patent_uspc[pid] = row.get('uspc_mainclass_id', '')
    print(f"  USPC for {len(patent_uspc)} patents")

    # Step 6: CPC classes (backup)
    print("\nStep 6: CPC classes")
    cpc_zip = download_file("g_cpc_at_issue.tsv.zip")
    patent_cpc = {}
    for row in read_tsv_from_zip(cpc_zip):
        pid = row.get('patent_id', '')
        if pid in target_patents and pid not in patent_cpc:
            patent_cpc[pid] = {
                'section': row.get('cpc_section', ''),
                'group': row.get('cpc_group', ''),
            }
    print(f"  CPC for {len(patent_cpc)} patents")

    # Step 7: Also get citation counts (forward citations)
    print("\nStep 7: Forward citation counts")
    cite_zip = download_file("g_us_patent_citation.tsv.zip")
    citation_counts = defaultdict(int)
    for row in read_tsv_from_zip(cite_zip):
        cited = row.get('citation_patent_id', '')
        if cited in target_patents:
            citation_counts[cited] += 1
    print(f"  Citations for {len(citation_counts)} patents")

    # Step 8: Build final dataset
    print("\nStep 8: Build final dataset")
    output_path = os.path.join(DATA_DIR, 'patents_tw_il_kr.csv')
    rows_written = 0
    year_country = defaultdict(lambda: defaultdict(int))

    with open(output_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            'patent_id', 'filing_date', 'grant_date', 'patent_type',
            'num_claims', 'assignee_country', 'uspc_mainclass',
            'cpc_section', 'cpc_group', 'forward_citations'
        ])

        for pid in target_patents:
            if pid not in patent_meta:
                continue
            filing = patent_filing.get(pid, '')
            meta = patent_meta[pid]
            uspc = patent_uspc.get(pid, '')
            cpc = patent_cpc.get(pid, {'section': '', 'group': ''})
            cites = citation_counts.get(pid, 0)

            for country in sorted(patent_countries[pid]):
                writer.writerow([
                    pid, filing, meta['grant_date'], meta['patent_type'],
                    meta['num_claims'], country, uspc,
                    cpc['section'], cpc['group'], cites
                ])
                rows_written += 1
                yr = filing[:4] if filing else ''
                if yr:
                    year_country[yr][country] += 1

    print(f"  Wrote {rows_written} rows")

    # Summary
    print("\n" + "=" * 60)
    country_totals = defaultdict(int)
    for pid, cs in patent_countries.items():
        if pid in patent_meta:
            for c in cs:
                country_totals[c] += 1
    for c in sorted(country_totals):
        print(f"  {c}: {country_totals[c]:,} patents")

    print(f"\n  {'Year':<6} {'TW':>8} {'IL':>8} {'KR':>8}")
    for year in range(2003, 2016):
        yr = str(year)
        tw = year_country.get(yr, {}).get('TW', 0)
        il = year_country.get(yr, {}).get('IL', 0)
        kr = year_country.get(yr, {}).get('KR', 0)
        print(f"  {yr:<6} {tw:>8,} {il:>8,} {kr:>8,}")

    diag = {
        'total_rows': rows_written,
        'tw_patents': country_totals.get('TW', 0),
        'il_patents': country_totals.get('IL', 0),
        'kr_patents': country_totals.get('KR', 0),
        'patents_with_uspc': len(patent_uspc),
        'patents_with_cpc': len(patent_cpc),
        'patents_with_citations': len(citation_counts),
        'fetch_date': datetime.now().isoformat(),
        'source': 'PatentsView bulk download'
    }
    with open(os.path.join(DATA_DIR, 'fetch_diagnostics.json'), 'w') as f:
        json.dump(diag, f, indent=2)
    print(f"\n  Done!")


if __name__ == '__main__':
    main()
