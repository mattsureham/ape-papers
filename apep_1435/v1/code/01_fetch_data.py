#!/usr/bin/env python3
"""
Fetch proposed and final rules from Federal Register API, 2015-2022.
Match proposed -> final by RIN, download full text for each pair, write a CSV
that the R analysis pipeline reads in.

Real API only. No simulation. Fail loudly.
"""
import os, sys, json, time, csv, re
import requests
from datetime import datetime
from pathlib import Path

BASE = "https://www.federalregister.gov/api/v1/documents.json"
DOC = "https://www.federalregister.gov/api/v1/documents/{}.json"
OUT = Path(__file__).resolve().parent.parent / "data"
OUT.mkdir(exist_ok=True)

YEARS = list(range(2015, 2023))  # 2015-2022 inclusive
FIELDS = [
    "document_number","publication_date","comments_close_on","significant",
    "agencies","page_length","title","regulation_id_numbers","raw_text_url","type"
]

S = requests.Session()
S.headers.update({"User-Agent":"APEP/apep_1435 research"})

def fetch_index(doc_type, year):
    out = []
    page = 1
    while True:
        params = [
            ("conditions[type][]", doc_type),
            ("conditions[publication_date][gte]", f"{year}-01-01"),
            ("conditions[publication_date][lte]", f"{year}-12-31"),
            ("per_page","1000"),
            ("page", str(page)),
        ]
        for f in FIELDS:
            params.append(("fields[]", f))
        for attempt in range(5):
            try:
                r = S.get(BASE, params=params, timeout=60)
                if r.status_code == 200:
                    break
                time.sleep(2**attempt)
            except requests.RequestException:
                time.sleep(2**attempt)
        else:
            raise RuntimeError(f"Failed FR API {doc_type} {year} page {page}")
        d = r.json()
        results = d.get("results") or []
        out.extend(results)
        if not d.get("next_page_url"):
            break
        page += 1
        if page > 50:
            break
    print(f"  {doc_type} {year}: {len(out)} docs", flush=True)
    return out

def normalize(d, kind):
    rins = d.get("regulation_id_numbers") or []
    if not rins:
        return None
    ag = d.get("agencies") or []
    agency_slug = ag[0].get("slug") if ag else None
    parent = ag[0].get("parent_id") if ag else None
    return {
        "kind": kind,
        "doc": d.get("document_number"),
        "pub": d.get("publication_date"),
        "close": d.get("comments_close_on"),
        "significant": d.get("significant"),
        "rin": rins[0],
        "all_rins": ";".join(rins),
        "pages": d.get("page_length"),
        "agency": agency_slug,
        "agency_parent": parent,
        "raw_text_url": d.get("raw_text_url"),
        "title": (d.get("title") or "").replace("\n"," ")[:300],
    }

def main():
    proposed = []
    final = []
    print("Fetching proposed rules...", flush=True)
    for y in YEARS:
        for d in fetch_index("PRORULE", y):
            n = normalize(d, "P")
            if n: proposed.append(n)
    print("Fetching final rules...", flush=True)
    for y in YEARS:
        for d in fetch_index("RULE", y):
            n = normalize(d, "F")
            if n: final.append(n)

    print(f"\nProposed (with RIN): {len(proposed)}")
    print(f"Final (with RIN): {len(final)}")

    # Build RIN -> list of finals (sorted by date)
    final_by_rin = {}
    for f in final:
        final_by_rin.setdefault(f["rin"], []).append(f)
    for k in final_by_rin:
        final_by_rin[k].sort(key=lambda x: x["pub"])

    # Match each proposed to nearest final after publication, within 36 months
    pairs = []
    for p in proposed:
        if not p["pub"] or not p["close"]:
            continue
        if p["significant"] is None:
            continue
        cands = final_by_rin.get(p["rin"], [])
        pub = datetime.fromisoformat(p["pub"])
        close = datetime.fromisoformat(p["close"])
        if (close - pub).days < 1:
            continue
        match = None
        for f in cands:
            fpub = datetime.fromisoformat(f["pub"])
            if fpub <= close:
                continue
            if (fpub - pub).days > 36*31:
                continue
            match = f
            break
        if not match:
            continue
        pairs.append({**{f"p_{k}":v for k,v in p.items()},
                      **{f"f_{k}":v for k,v in match.items()}})
    print(f"Matched proposed-final pairs: {len(pairs)}")

    # Save metadata
    meta_path = OUT / "pairs_meta.csv"
    keys = sorted({k for r in pairs for k in r.keys()})
    with open(meta_path, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=keys)
        w.writeheader()
        for r in pairs:
            w.writerow(r)
    print(f"Wrote {meta_path}")

    # Download text — cache to data/text/
    text_dir = OUT / "text"
    text_dir.mkdir(exist_ok=True)
    needed = set()
    for r in pairs:
        for u in (r["p_raw_text_url"], r["f_raw_text_url"]):
            if u: needed.add(u)
    print(f"Need {len(needed)} text files")

    fetched = 0
    failed = 0
    for u in sorted(needed):
        name = re.sub(r"[^A-Za-z0-9_.-]","_", u.split("/")[-1])
        path = text_dir / name
        if path.exists() and path.stat().st_size > 100:
            continue
        for attempt in range(3):
            try:
                r = S.get(u, timeout=60)
                if r.status_code == 200 and len(r.text) > 100:
                    path.write_text(r.text)
                    fetched += 1
                    break
                time.sleep(1.5**attempt)
            except requests.RequestException:
                time.sleep(1.5**attempt)
        else:
            failed += 1
            path.write_text("")  # mark as attempted
        if (fetched+failed) % 500 == 0:
            print(f"  fetched={fetched} failed={failed}", flush=True)
    print(f"Done. fetched={fetched} failed={failed}")

if __name__ == "__main__":
    main()
