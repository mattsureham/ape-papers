#!/usr/bin/env python3
"""Fetch USAJOBS Historic JOA data via REST API and aggregate to monthly panel.

Real data only. Fails loudly on errors. Aggregates to:
  - department x month (main)
  - department x occ-family x month (composition)
"""
import csv
import json
import sys
import time
import urllib.parse
import ssl
import urllib.request
SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE
from collections import defaultdict
from datetime import date
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

API = "https://data.usajobs.gov/api/historicjoa"
HEADERS = {"User-Agent": "apep-research-apep1437"}
OUT = Path(__file__).resolve().parents[1] / "data"
OUT.mkdir(exist_ok=True)

# Period: Jan 2021 - Mar 2025
MONTHS = []
for y in range(2021, 2026):
    for m in range(1, 13):
        if y == 2025 and m > 3:
            break
        MONTHS.append((y, m))

def month_range(y, m):
    if m == 12:
        end = date(y, 12, 31)
    else:
        end = date(y, m + 1, 1).replace(day=1)
        from datetime import timedelta
        end = end - timedelta(days=1)
    return date(y, m, 1).isoformat(), end.isoformat()

def fetch_url(url):
    req = urllib.request.Request(url, headers=HEADERS)
    for attempt in range(15):
        try:
            with urllib.request.urlopen(req, timeout=90, context=SSL_CTX) as r:
                return json.loads(r.read())
        except Exception as e:
            if attempt == 14:
                raise RuntimeError(f"Failed {url}: {e}")
            time.sleep(min(60, 2 ** attempt))

def fetch_month(y, m):
    cache = OUT / f"_cache_{y}_{m:02d}.json"
    if cache.exists():
        d = json.loads(cache.read_text())
        return (y, m, d["dc"], {tuple(k.split("|")): v for k, v in d["doc"].items()},
                {tuple(k.split("|")): v for k, v in d["dg"].items()}, d["total"])
    start, end = month_range(y, m)
    qs = urllib.parse.urlencode({"StartPositionOpenDate": start, "EndPositionOpenDate": end})
    url = f"{API}?{qs}"
    # dept x month, dept x occfam x month, dept x grade x month
    dept_counts = defaultdict(int)
    dept_occ = defaultdict(int)
    dept_grade = defaultdict(int)
    total = 0
    while True:
        data = fetch_url(url)
        for r in data.get("data", []):
            dept = r.get("hiringDepartmentName") or "UNKNOWN"
            ann = r.get("announcementNumber", "") or ""
            # use jobcategory occupation series
            jcs = r.get("jobCategories") or []
            series = jcs[0].get("series") if jcs else None
            try:
                fam = (series or "")[:2]
            except Exception:
                fam = ""
            grade_min = r.get("minimumGrade") or ""
            try:
                gn = int(grade_min)
                gbin = "GS5_9" if gn <= 9 else ("GS10_12" if gn <= 12 else "GS13plus")
            except Exception:
                gbin = "other"
            openings = r.get("totalOpenings") or "1"
            try:
                ow = int(openings) if str(openings).isdigit() else 1
            except Exception:
                ow = 1
            ow = max(1, min(ow, 100))  # cap absurd values
            dept_counts[dept] += 1
            dept_occ[(dept, fam)] += 1
            dept_grade[(dept, gbin)] += 1
            total += 1
        nxt = data.get("paging", {}).get("next")
        if not nxt:
            break
        url = "https://data.usajobs.gov" + nxt
    print(f"  {y}-{m:02d}: {total} vacancies, {len(dept_counts)} depts", flush=True)
    cache.write_text(json.dumps({
        "dc": dict(dept_counts),
        "doc": {f"{a}|{b}": v for (a, b), v in dept_occ.items()},
        "dg": {f"{a}|{b}": v for (a, b), v in dept_grade.items()},
        "total": total,
    }))
    return (y, m, dict(dept_counts), dict(dept_occ), dict(dept_grade), total)

def main():
    print(f"Fetching {len(MONTHS)} months from USAJOBS Historic JOA API...", flush=True)
    results = []
    with ThreadPoolExecutor(max_workers=3) as ex:
        futs = {ex.submit(fetch_month, y, m): (y, m) for (y, m) in MONTHS}
        for f in as_completed(futs):
            results.append(f.result())
    results.sort(key=lambda r: (r[0], r[1]))

    # Write dept x month
    with open(OUT / "dept_month.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["year", "month", "department", "vacancies"])
        for y, m, dc, _, _, _ in results:
            for dept, n in dc.items():
                w.writerow([y, m, dept, n])

    with open(OUT / "dept_occ_month.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["year", "month", "department", "occ_family", "vacancies"])
        for y, m, _, doc, _, _ in results:
            for (dept, fam), n in doc.items():
                w.writerow([y, m, dept, fam, n])

    with open(OUT / "dept_grade_month.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["year", "month", "department", "grade_bin", "vacancies"])
        for y, m, _, _, dg, _ in results:
            for (dept, gb), n in dg.items():
                w.writerow([y, m, dept, gb, n])

    totals = {(y, m): t for (y, m, _, _, _, t) in results}
    print("\nMonthly totals:")
    for (y, m), t in totals.items():
        print(f"  {y}-{m:02d}: {t}")

    # Validation: must observe sharp Feb/Mar 2025 drop
    pre = sum(t for (y, m), t in totals.items() if (y, m) <= (2024, 12)) / sum(1 for (y, m) in totals if (y, m) <= (2024, 12))
    post_feb = totals.get((2025, 2), 0)
    post_mar = totals.get((2025, 3), 0)
    print(f"\nPre-freeze monthly avg: {pre:.0f}; Feb 2025: {post_feb}; Mar 2025: {post_mar}")
    assert post_mar < pre * 0.7, f"Expected sharp Mar 2025 drop; got {post_mar} vs pre {pre:.0f}"
    print("VALIDATION PASSED")

if __name__ == "__main__":
    main()
