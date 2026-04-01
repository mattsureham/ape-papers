#!/usr/bin/env python3
"""Phase 2b: Quarterly panel via count queries (faster than bulk download)."""
import requests, time, csv, os, sys, json
from collections import defaultdict

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
BASE_URL = "https://developer.uspto.gov/ds-api"

def flush_print(msg):
    print(msg); sys.stdout.flush()

def get_count(criteria, retries=4):
    url = f"{BASE_URL}/oa_rejections/v2/records"
    for attempt in range(retries):
        try:
            r = requests.post(url, data={"criteria": criteria, "start": "0", "rows": "0"}, timeout=60)
            if r.status_code == 200:
                d = r.json()
                if "response" in d: return d["response"]["numFound"]
        except: pass
        time.sleep(0.3 * (attempt + 1))
    return 0

# Load art units from Phase 1
import csv as csv_mod
shock_data = list(csv_mod.DictReader(open(os.path.join(DATA_DIR, "art_unit_shock.csv"))))
all_aus = [(r["art_unit"], r["tc"]) for r in shock_data]
flush_print(f"Loaded {len(all_aus)} art units from Phase 1")

quarters = []
for y in range(2012, 2017):
    for q in range(1, 5):
        ms = (q-1)*3 + 1; me = q*3
        end = f"{y}-12-31T23:59:59" if me==12 else f"{y}-{me+1:02d}-01T00:00:00"
        quarters.append({"label": f"{y}Q{q}", "year": y, "qtr": q,
                         "start": f"{y}-{ms:02d}-01T00:00:00", "end": end})

total_q = len(all_aus) * len(quarters) * 2
done = 0
rows = []

for au, tc in all_aus:
    for qi in quarters:
        ql = qi["label"]
        dr = f'submissionDate:[{qi["start"]} TO {qi["end"]}]'
        base = f'groupArtUnitNumber:{au} AND {dr}'

        total = get_count(base)
        time.sleep(0.15)
        s101 = get_count(base + " AND hasRej101:1") if total > 0 else 0
        time.sleep(0.15)
        s103 = get_count(base + " AND hasRej103:1") if total > 0 else 0
        time.sleep(0.15)

        done += 2
        rows.append({
            "art_unit": au, "tc": tc, "quarter": ql,
            "year": qi["year"], "qtr": qi["qtr"],
            "total_actions": total,
            "s101_actions": s101, "s103_actions": s103,
            "s101_rate": round(s101/total, 4) if total > 0 else "",
            "s103_rate": round(s103/total, 4) if total > 0 else ""
        })

    done_pct = (all_aus.index((au, tc)) + 1) / len(all_aus) * 100
    flush_print(f"  [{done_pct:.0f}%] {au} ({tc}) done")

out_file = os.path.join(DATA_DIR, "art_unit_quarterly_rejections.csv")
with open(out_file, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)
flush_print(f"\nSaved: {out_file} ({len(rows)} rows)")

# Also fetch application outcomes
flush_print("\nFetching application outcomes...")
PRE = "2010-01-01T00:00:00 TO 2014-06-30T23:59:59"
POST = "2014-07-01T00:00:00 TO 2016-12-31T23:59:59"
app_rows = []
tc36_aus = [r["art_unit"] for r in shock_data if r["tc"] == "TC3600"]

for au in tc36_aus:
    for pname, pr in [("pre", PRE), ("post", POST)]:
        base = f'groupArtUnitNumber:{au} AND filingDate:[{pr}]'
        total = get_count(base.replace("oa_rejections", "oa_actions").replace("/v2", "/v1"),
                         ) # This won't work - need separate function
        # Use oa_actions endpoint
        url = f"{BASE_URL}/oa_actions/v1/records"
        try:
            r = requests.post(url, data={"criteria": f'groupArtUnitNumber:{au} AND filingDate:[{pr}]',
                                          "start": "0", "rows": "0"}, timeout=60)
            total = r.json()["response"]["numFound"] if r.status_code == 200 and "response" in r.json() else 0
        except:
            total = 0
        time.sleep(0.15)

        granted = 0
        if total > 0:
            try:
                r2 = requests.post(url, data={
                    "criteria": f'groupArtUnitNumber:{au} AND filingDate:[{pr}] AND patentNumber:[* TO *] AND NOT patentNumber:"null"',
                    "start": "0", "rows": "0"}, timeout=60)
                granted = r2.json()["response"]["numFound"] if r2.status_code == 200 and "response" in r2.json() else 0
            except:
                granted = 0
        time.sleep(0.15)

        app_rows.append({
            "art_unit": au, "tc": "TC3600", "period": pname,
            "total_actions": total, "granted_actions": granted,
            "grant_rate": round(granted/total, 4) if total > 0 else ""
        })

app_file = os.path.join(DATA_DIR, "application_outcomes.csv")
with open(app_file, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=app_rows[0].keys())
    writer.writeheader()
    writer.writerows(app_rows)
flush_print(f"Saved: {app_file} ({len(app_rows)} rows)")

# Update diagnostics
diag = {
    "n_treated": len(tc36_aus),
    "n_pre": 10,
    "n_obs": len(rows),
    "n_applications": sum(r["total_actions"] for r in app_rows)
}
with open(os.path.join(DATA_DIR, "diagnostics.json"), "w") as f:
    json.dump(diag, f, indent=2)
flush_print("Done!")
