#!/usr/bin/env python3
"""
Fetch patent data from USPTO DS-API for Alice Corp analysis.
Two-phase approach:
  Phase 1: Pre/post aggregates for all art units (fast, ~3 min)
  Phase 2: Quarterly panel via bulk download + local aggregation (~10 min)
"""

import requests
import time
import json
import csv
import os
import sys
from datetime import datetime
from collections import defaultdict

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

BASE_URL = "https://developer.uspto.gov/ds-api"
RATE_LIMIT = 0.15

def flush_print(msg):
    print(msg)
    sys.stdout.flush()

def get_count(endpoint, criteria, retries=4):
    url = f"{BASE_URL}/{endpoint}/records"
    for attempt in range(retries):
        try:
            r = requests.post(url, data={
                "criteria": criteria, "start": "0", "rows": "0"
            }, timeout=60)
            if r.status_code == 200:
                data = r.json()
                if "response" in data:
                    return data["response"]["numFound"]
        except:
            pass
        time.sleep(0.5 * (attempt + 1))
    return -1  # Distinguishable failure

def get_docs(endpoint, criteria, n=2000, retries=3):
    url = f"{BASE_URL}/{endpoint}/records"
    for attempt in range(retries):
        try:
            r = requests.post(url, data={
                "criteria": criteria, "start": "0", "rows": str(n)
            }, timeout=120)
            if r.status_code == 200:
                data = r.json()
                if "response" in data:
                    return data["response"]["docs"]
        except:
            pass
        time.sleep(0.5 * (attempt + 1))
    return []


flush_print("=" * 60)
flush_print("PHASE 1: Pre/post aggregates (fast)")
flush_print(f"Started: {datetime.now().isoformat()}")
flush_print("=" * 60)

# --- Discover art units ---
flush_print("\nDiscovering art units...")
tc36_aus = set()
tc16_aus = set()

for year in [2012, 2014, 2016]:
    docs = get_docs("oa_rejections/v2",
        f'groupArtUnitNumber:[3600 TO 3699] AND submissionDate:[{year}-01-01T00:00:00 TO {year}-12-31T23:59:59]')
    for d in docs:
        au = str(d.get("groupArtUnitNumber", ""))
        if au: tc36_aus.add(au)
    time.sleep(RATE_LIMIT)

    docs = get_docs("oa_rejections/v2",
        f'groupArtUnitNumber:[1600 TO 1699] AND submissionDate:[{year}-01-01T00:00:00 TO {year}-12-31T23:59:59]')
    for d in docs:
        au = str(d.get("groupArtUnitNumber", ""))
        if au: tc16_aus.add(au)
    time.sleep(RATE_LIMIT)

tc36_aus = sorted(tc36_aus)
tc16_aus = sorted(tc16_aus)
tc16_sample = tc16_aus[::max(1, len(tc16_aus)//12)][:12]

flush_print(f"  TC3600: {len(tc36_aus)} art units")
flush_print(f"  TC1600: {len(tc16_sample)} art units (sampled)")

# --- Pre/post counts for all art units ---
flush_print("\nFetching pre/post §101 rates...")

PRE = "2012-01-01T00:00:00 TO 2014-06-30T23:59:59"
POST = "2014-07-01T00:00:00 TO 2016-12-31T23:59:59"

shock_rows = []
all_aus = [(au, "TC3600") for au in tc36_aus] + [(au, "TC1600") for au in tc16_sample]
n_done = 0

for au, tc in all_aus:
    pre_total = get_count("oa_rejections/v2",
        f'groupArtUnitNumber:{au} AND submissionDate:[{PRE}]')
    time.sleep(RATE_LIMIT)

    pre_s101 = get_count("oa_rejections/v2",
        f'groupArtUnitNumber:{au} AND submissionDate:[{PRE}] AND hasRej101:1')
    time.sleep(RATE_LIMIT)

    post_total = get_count("oa_rejections/v2",
        f'groupArtUnitNumber:{au} AND submissionDate:[{POST}]')
    time.sleep(RATE_LIMIT)

    post_s101 = get_count("oa_rejections/v2",
        f'groupArtUnitNumber:{au} AND submissionDate:[{POST}] AND hasRej101:1')
    time.sleep(RATE_LIMIT)

    # Also get §103 for placebo
    pre_s103 = get_count("oa_rejections/v2",
        f'groupArtUnitNumber:{au} AND submissionDate:[{PRE}] AND hasRej103:1')
    time.sleep(RATE_LIMIT)

    post_s103 = get_count("oa_rejections/v2",
        f'groupArtUnitNumber:{au} AND submissionDate:[{POST}] AND hasRej103:1')
    time.sleep(RATE_LIMIT)

    pre_rate = pre_s101 / pre_total if pre_total > 0 else None
    post_rate = post_s101 / post_total if post_total > 0 else None
    shock = (post_rate - pre_rate) if pre_rate is not None and post_rate is not None else None

    shock_rows.append({
        "art_unit": au, "tc": tc,
        "pre_total": pre_total, "pre_s101": pre_s101, "pre_s103": pre_s103,
        "post_total": post_total, "post_s101": post_s101, "post_s103": post_s103,
        "pre_s101_rate": round(pre_rate, 4) if pre_rate is not None else "",
        "post_s101_rate": round(post_rate, 4) if post_rate is not None else "",
        "alice_shock": round(shock, 4) if shock is not None else "",
        "pre_s103_rate": round(pre_s103/pre_total, 4) if pre_total > 0 else "",
        "post_s103_rate": round(post_s103/post_total, 4) if post_total > 0 else ""
    })

    n_done += 1
    if n_done % 5 == 0:
        flush_print(f"  [{n_done}/{len(all_aus)}] {au} ({tc}): shock={shock:.3f}" if shock else f"  [{n_done}/{len(all_aus)}] {au} ({tc}): no data")

# Save shock data
shock_file = os.path.join(DATA_DIR, "art_unit_shock.csv")
with open(shock_file, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=shock_rows[0].keys())
    writer.writeheader()
    writer.writerows(shock_rows)
flush_print(f"\nSaved: {shock_file} ({len(shock_rows)} rows)")

# Summary
tc36_shocks = [r for r in shock_rows if r["tc"] == "TC3600" and r["alice_shock"] != ""]
shocks = [float(r["alice_shock"]) for r in tc36_shocks]
flush_print(f"\nTC3600 Alice shock distribution (n={len(shocks)}):")
flush_print(f"  Mean: {sum(shocks)/len(shocks)*100:+.1f}pp")
flush_print(f"  Min:  {min(shocks)*100:+.1f}pp")
flush_print(f"  Max:  {max(shocks)*100:+.1f}pp")
high = [s for s in shocks if s > 0.20]
low = [s for s in shocks if s < 0.05]
flush_print(f"  High-shock (>20pp): {len(high)}")
flush_print(f"  Low-shock  (<5pp):  {len(low)}")

# ============================================================
flush_print("\n" + "=" * 60)
flush_print("PHASE 2: Quarterly panel (bulk download + aggregate)")
flush_print("=" * 60)

# Download records per quarter, aggregate by art unit
quarters = []
for y in range(2012, 2017):
    for q in range(1, 5):
        ms = (q-1)*3 + 1
        me = q*3
        end_str = f"{y}-12-31T23:59:59" if me == 12 else f"{y}-{me+1:02d}-01T00:00:00"
        quarters.append({"label": f"{y}Q{q}", "year": y, "qtr": q,
                         "start": f"{y}-{ms:02d}-01T00:00:00", "end": end_str})

# For TC3600: download all records per quarter
panel_agg = defaultdict(lambda: defaultdict(lambda: {"total": 0, "s101": 0, "s103": 0}))

for qi, qinfo in enumerate(quarters):
    ql = qinfo["label"]
    criteria = f'groupArtUnitNumber:[3600 TO 3699] AND submissionDate:[{qinfo["start"]} TO {qinfo["end"]}]'

    total_q = get_count("oa_rejections/v2", criteria)
    if total_q <= 0:
        flush_print(f"  {ql}: 0 records (or error)")
        continue

    flush_print(f"  {ql}: {total_q:,} records — downloading...")

    # Paginate through all records
    start = 0
    page_size = 2000
    fetched = 0
    while start < total_q:
        url = f"{BASE_URL}/oa_rejections/v2/records"
        try:
            r = requests.post(url, data={
                "criteria": criteria, "start": str(start), "rows": str(page_size)
            }, timeout=120)
            if r.status_code == 200:
                data = r.json()
                if "response" in data:
                    docs = data["response"]["docs"]
                    if not docs:
                        break
                    for doc in docs:
                        au = str(doc.get("groupArtUnitNumber", ""))
                        if not au: continue
                        panel_agg[au][ql]["total"] += 1
                        if doc.get("hasRej101") in (1, "1", True):
                            panel_agg[au][ql]["s101"] += 1
                        if doc.get("hasRej103") in (1, "1", True):
                            panel_agg[au][ql]["s103"] += 1
                    fetched += len(docs)
                else:
                    time.sleep(1)
                    continue
            else:
                time.sleep(1)
                continue
        except Exception as e:
            flush_print(f"    Error at start={start}: {e}")
            time.sleep(2)
            continue
        start += page_size
        time.sleep(RATE_LIMIT)

    flush_print(f"    downloaded {fetched:,}/{total_q:,}")

# For TC1600: just pre/post counts (already have from phase 1)
# Add TC1600 quarterly using count queries for the 12 sampled art units
flush_print("\nTC1600 quarterly counts (sampled)...")
for au in tc16_sample:
    for qinfo in quarters:
        ql = qinfo["label"]
        base = f'groupArtUnitNumber:{au} AND submissionDate:[{qinfo["start"]} TO {qinfo["end"]}]'
        total = get_count("oa_rejections/v2", base)
        s101 = get_count("oa_rejections/v2", base + " AND hasRej101:1") if total > 0 else 0
        s103 = get_count("oa_rejections/v2", base + " AND hasRej103:1") if total > 0 else 0
        panel_agg[au][ql]["total"] = total if total >= 0 else 0
        panel_agg[au][ql]["s101"] = s101 if s101 >= 0 else 0
        panel_agg[au][ql]["s103"] = s103 if s103 >= 0 else 0
        time.sleep(RATE_LIMIT)
    if tc16_sample.index(au) % 3 == 0:
        flush_print(f"  {au}: done")

# Save quarterly panel
panel_rows = []
for au in sorted(panel_agg.keys()):
    tc = "TC3600" if au.startswith("36") else "TC1600"
    for qinfo in quarters:
        ql = qinfo["label"]
        d = panel_agg[au][ql]
        t = d["total"]
        panel_rows.append({
            "art_unit": au, "tc": tc,
            "quarter": ql, "year": qinfo["year"], "qtr": qinfo["qtr"],
            "total_actions": t,
            "s101_actions": d["s101"],
            "s103_actions": d["s103"],
            "s101_rate": round(d["s101"]/t, 4) if t > 0 else "",
            "s103_rate": round(d["s103"]/t, 4) if t > 0 else ""
        })

panel_file = os.path.join(DATA_DIR, "art_unit_quarterly_rejections.csv")
with open(panel_file, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=panel_rows[0].keys())
    writer.writeheader()
    writer.writerows(panel_rows)
flush_print(f"\nSaved: {panel_file} ({len(panel_rows)} rows)")

# ============================================================
flush_print("\n" + "=" * 60)
flush_print("PHASE 3: Application outcomes")
flush_print("=" * 60)

# Get grant counts per art unit, pre/post
app_rows = []
for au in tc36_aus:
    for pname, prange in [("pre", PRE), ("post", POST)]:
        base = f'groupArtUnitNumber:{au} AND filingDate:[{prange}]'
        total = get_count("oa_actions/v1", base)
        time.sleep(RATE_LIMIT)
        # Granted = has patent number
        granted = get_count("oa_actions/v1", base + ' AND patentNumber:[* TO *] AND NOT patentNumber:"null"') if total > 0 else 0
        time.sleep(RATE_LIMIT)

        app_rows.append({
            "art_unit": au, "tc": "TC3600", "period": pname,
            "total_actions": total if total >= 0 else 0,
            "granted_actions": granted if granted >= 0 else 0,
            "grant_rate": round(granted/total, 4) if total > 0 and granted >= 0 else ""
        })

app_file = os.path.join(DATA_DIR, "application_outcomes.csv")
with open(app_file, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=app_rows[0].keys())
    writer.writeheader()
    writer.writerows(app_rows)
flush_print(f"Saved: {app_file} ({len(app_rows)} rows)")

# ============================================================
# Save diagnostics
# ============================================================
diag = {
    "n_treated": len(tc36_aus),
    "n_control": len(tc16_sample),
    "n_pre": 10,
    "n_obs": len(panel_rows),
    "n_applications": sum(r["total_actions"] for r in app_rows if r["total_actions"]),
    "high_shock_aus": len(high),
    "low_shock_aus": len(low)
}
with open(os.path.join(DATA_DIR, "diagnostics.json"), "w") as f:
    json.dump(diag, f, indent=2)

flush_print(f"\nFinished: {datetime.now().isoformat()}")
