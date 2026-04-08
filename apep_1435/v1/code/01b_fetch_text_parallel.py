#!/usr/bin/env python3
"""Parallel text downloader. Reads pairs_meta.csv, fetches missing files into data/text/."""
import csv, re, sys, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests

OUT = Path(__file__).resolve().parent.parent / "data"
TXT = OUT / "text"; TXT.mkdir(exist_ok=True)

def fname(url):
    return re.sub(r"[^A-Za-z0-9_.-]","_", url.split("/")[-1])

def needs(url):
    if not url: return False
    p = TXT / fname(url)
    return not (p.exists() and p.stat().st_size > 100)

def fetch_one(url):
    p = TXT / fname(url)
    s = requests.Session()
    s.headers.update({"User-Agent":"APEP/apep_1435"})
    for attempt in range(3):
        try:
            r = s.get(url, timeout=45)
            if r.status_code == 200 and len(r.text) > 100:
                p.write_text(r.text)
                return True
        except requests.RequestException:
            pass
        time.sleep(1.0+attempt)
    p.write_text("")
    return False

def main():
    rows = list(csv.DictReader(open(OUT/"pairs_meta.csv")))
    urls = set()
    for r in rows:
        for u in (r["p_raw_text_url"], r["f_raw_text_url"]):
            if u and needs(u): urls.add(u)
    print(f"Need {len(urls)} files", flush=True)
    ok = bad = 0
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=24) as ex:
        futs = {ex.submit(fetch_one,u):u for u in urls}
        for i,f in enumerate(as_completed(futs),1):
            if f.result(): ok += 1
            else: bad += 1
            if i % 250 == 0:
                el = time.time()-t0
                print(f"  {i}/{len(urls)}  ok={ok} bad={bad}  {i/el:.1f}/s", flush=True)
    print(f"DONE ok={ok} bad={bad} in {time.time()-t0:.0f}s", flush=True)

if __name__ == "__main__":
    main()
