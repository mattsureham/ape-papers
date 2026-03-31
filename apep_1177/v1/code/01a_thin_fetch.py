"""
01a_thin_fetch.py — Fast thin fetch of drug trafficking cases (no movimentos)
apep_1177: The Conviction Lottery

Pass 1: Get case ID, vara, filing date, assuntos for ALL trafficking cases.
This identifies multi-vara assignment pools and defines the sample.

Output:
    ./data/thin_cases.csv
"""

import json
import time
import sys
from pathlib import Path
from datetime import datetime

import requests
import pandas as pd

API_URL = "https://api-publica.datajud.cnj.jus.br/api_publica_tjsp/_search"
API_KEY = "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="
HEADERS = {
    "Content-Type": "application/json",
    "Authorization": f"APIKey {API_KEY}"
}
OUTPUT_DIR = Path("./data")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
BATCH_SIZE = 1000  # Larger batches since no movimentos
RATE_LIMIT = 1.5   # Faster since payloads are small


def fetch_thin():
    """Fetch case metadata without movimentos."""
    all_cases = []
    search_after = None
    page = 0

    query_template = {
        "size": BATCH_SIZE,
        "query": {
            "bool": {
                "must": [
                    {"match": {"assuntos.codigo": 3608}},
                    {"match": {"grau": "G1"}},
                    {"match": {"classe.codigo": 283}}
                ]
            }
        },
        "_source": [
            "numeroProcesso", "orgaoJulgador", "assuntos",
            "dataAjuizamento", "formato"
        ],
        "sort": [{"_doc": "asc"}]  # Fastest sort for streaming
    }

    while True:
        query = json.loads(json.dumps(query_template))
        if search_after:
            query["search_after"] = search_after

        for attempt in range(3):
            try:
                resp = requests.post(API_URL, headers=HEADERS,
                                     json=query, timeout=120)
                resp.raise_for_status()
                data = resp.json()
                break
            except Exception as e:
                print(f"  Attempt {attempt+1} failed: {e}", flush=True)
                if attempt < 2:
                    time.sleep(5)
                else:
                    raise

        hits = data["hits"]["hits"]
        if not hits:
            break

        for hit in hits:
            src = hit["_source"]
            oj = src.get("orgaoJulgador", {})
            assuntos = src.get("assuntos", [])
            fmt = src.get("formato", {})

            # Extract comarca from vara name (pattern: "XX CRIMINAL DE CIDADE")
            vara_name = oj.get("nome", "")

            all_cases.append({
                "case_id": src.get("numeroProcesso", ""),
                "vara_codigo": oj.get("codigo"),
                "vara_nome": vara_name,
                "filing_date": src.get("dataAjuizamento", "")[:10],
                "assunto_codigo": assuntos[0].get("codigo") if assuntos else None,
                "formato": fmt.get("nome", "") if isinstance(fmt, dict) else "",
            })

        search_after = hits[-1]["sort"]
        page += 1

        if page % 5 == 0:
            print(f"  Page {page}: {len(all_cases):,} cases", flush=True)

        time.sleep(RATE_LIMIT)

    return all_cases


def main():
    print(f"[{datetime.now().isoformat()}] Thin fetch starting", flush=True)

    cases = fetch_thin()
    print(f"\nFetched {len(cases):,} cases", flush=True)

    df = pd.DataFrame(cases)

    # Identify multi-vara comarcas
    # Extract comarca from case number: digits 14-17 (0-indexed) = comarca code
    # Brazilian case numbers: NNNNNNN-DD.AAAA.J.TT.OOOO
    # Positions 14-17 in the unformatted number = origin (comarca)
    df["comarca_code"] = df["case_id"].str[13:17]

    # Count varas per comarca
    vara_counts = df.groupby("comarca_code")["vara_codigo"].nunique().reset_index()
    vara_counts.columns = ["comarca_code", "n_varas"]
    multi_vara = vara_counts[vara_counts["n_varas"] >= 2]

    print(f"\n--- Sample Structure ---")
    print(f"Total cases: {len(df):,}")
    print(f"Unique varas: {df['vara_codigo'].nunique()}")
    print(f"Unique comarcas: {df['comarca_code'].nunique()}")
    print(f"Multi-vara comarcas (≥2): {len(multi_vara)}")
    print(f"Cases in multi-vara comarcas: "
          f"{df[df['comarca_code'].isin(multi_vara['comarca_code'])].shape[0]:,}")
    print(f"Filing date range: {df['filing_date'].min()} to {df['filing_date'].max()}")

    # Top comarcas by case volume
    top = df.groupby(["comarca_code"]).agg(
        n_cases=("case_id", "count"),
        n_varas=("vara_codigo", "nunique")
    ).sort_values("n_cases", ascending=False).head(20)
    print(f"\nTop 20 comarcas:")
    print(top.to_string())

    # Save
    outpath = OUTPUT_DIR / "thin_cases.csv"
    df.to_csv(outpath, index=False)
    print(f"\nSaved to {outpath}")
    print(f"[{datetime.now().isoformat()}] Thin fetch complete", flush=True)


if __name__ == "__main__":
    main()
