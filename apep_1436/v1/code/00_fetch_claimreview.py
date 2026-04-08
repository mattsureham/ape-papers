#!/usr/bin/env python3
"""Fetch ClaimReview fact-checks via Google Fact Check Tools API."""
import os, json, time, sys, pathlib
import requests

# Load FACTCHECK_API_KEY from .env (repo root)
REPO = pathlib.Path(__file__).resolve().parents[4]
API_KEY = None
for line in (REPO / ".env").read_text().splitlines():
    if line.startswith("FACTCHECK_API_KEY="):
        API_KEY = line.split("=", 1)[1].strip().strip('"').strip("'")
        break
if not API_KEY:
    sys.exit("FACTCHECK_API_KEY not set")

OUT = pathlib.Path(__file__).resolve().parents[1] / "data" / "claimreview"
OUT.mkdir(parents=True, exist_ok=True)

QUERIES = [
    "immigration","election","vaccine","climate","biden","trump","covid",
    "abortion","gun","ukraine","israel","inflation","crime","economy",
    "healthcare","fraud","ballot","masks","school","china","russia",
    "fbi","irs","fentanyl","border","tax","medicare","medicaid",
    "socialism","nato","iran","hamas","hunter","pelosi","desantis",
    "obama","clinton","harris","voting","mail","stolen","rigged",
    "january","capitol","insurrection","blm","antifa","police",
    "transgender","crt","woke","unemployment","stimulus","debt",
    "oil","energy","recession","jobs","wages","roe","abortion rights",
    "wildfire","hurricane","drought","flood","supreme court","tariff",
    "sanctions","taliban","syria","venezuela","cuba","mexico","fentanyl crisis",
    "gaza","west bank","hostage","antisemitism","islamophobia","protest",
    "riot","looting","shooting","mass shooting","assault weapon","ar-15",
    "second amendment","first amendment","free speech","censorship","twitter",
    "facebook","tiktok","youtube","musk","zuckerberg",
    "fauci","cdc","who","pfizer","moderna","booster","variant","omicron",
    "delta","lockdown","mandate","quarantine","ivermectin","hydroxychloroquine",
    "epstein","maxwell","weinstein",
    "migrant","asylum","caravan","wall","ice","daca","dreamer",
    "afghanistan","iraq","kabul","putin","zelensky","kyiv","crimea",
    "inflation rate","gas price","grocery","rent","housing","mortgage",
    "fed","interest rate","jerome powell","recession fears",
    "student loan","forgiveness","free college","tuition","defund police",
    "qanon","deep state","great replacement","white supremacy","neo-nazi"
]

def fetch(query, page_token=None):
    params = {
        "query": query,
        "languageCode": "en",
        "pageSize": 10,
        "maxAgeDays": 2555,
        "key": API_KEY,
    }
    if page_token:
        params["pageToken"] = page_token
    for attempt in range(4):
        try:
            r = requests.get(
                "https://factchecktools.googleapis.com/v1alpha1/claims:search",
                params=params, timeout=45,
            )
            if r.status_code == 429:
                time.sleep(5 * (attempt + 1))
                continue
            r.raise_for_status()
            return r.json()
        except Exception as e:
            if attempt == 3:
                raise
            time.sleep(2 * (attempt + 1))
    return {}

total = 0
for q in QUERIES:
    qf = OUT / (q.replace(" ", "_") + ".jsonl")
    if qf.exists() and qf.stat().st_size > 0:
        n = sum(1 for _ in qf.open())
        total += n
        print(f"[skip] {q}: {n}")
        continue
    got, token, pages = 0, None, 0
    with qf.open("w") as f:
        while pages < 80:
            try:
                data = fetch(q, token)
            except Exception as e:
                print(f"[err] {q} page {pages}: {e}")
                break
            claims = data.get("claims", [])
            for c in claims:
                c["_query_topic"] = q
                f.write(json.dumps(c) + "\n")
                got += 1
            token = data.get("nextPageToken")
            pages += 1
            if not token or not claims:
                break
            time.sleep(0.08)
    total += got
    print(f"[ok] {q}: {got} ({pages}p)", flush=True)
    time.sleep(0.15)

print(f"TOTAL: {total}")
