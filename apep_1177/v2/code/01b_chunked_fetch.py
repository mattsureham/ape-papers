"""
01b_chunked_fetch.py — Year-chunked fetch of drug trafficking cases
apep_1177: The Conviction Lottery

Fetches by year to avoid API timeouts on large result sets.
Pass 1 (thin): case metadata + key movement flags (no full movement list).

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
BATCH_SIZE = 200  # Smaller batches to avoid timeouts
RATE_LIMIT = 3.0  # Conservative rate limit


def fetch_year(year):
    """Fetch all trafficking cases for a given filing year."""
    cases = []
    search_after = None
    page = 0

    query_template = {
        "size": BATCH_SIZE,
        "query": {
            "bool": {
                "must": [
                    {"match": {"assuntos.codigo": 3608}},
                    {"match": {"grau": "G1"}},
                    {"match": {"classe.codigo": 283}},
                    {"range": {
                        "dataAjuizamento": {
                            "gte": f"{year}-01-01",
                            "lt": f"{year+1}-01-01"
                        }
                    }}
                ]
            }
        },
        "_source": [
            "numeroProcesso", "orgaoJulgador", "assuntos",
            "dataAjuizamento", "movimentos"
        ],
        "sort": [{"dataAjuizamento": "asc"}, {"_doc": "asc"}]
    }

    while True:
        query = json.loads(json.dumps(query_template))
        if search_after:
            query["search_after"] = search_after

        for attempt in range(5):
            try:
                resp = requests.post(API_URL, headers=HEADERS,
                                     json=query, timeout=180)
                if resp.status_code == 504:
                    print(f"    504 timeout, retry {attempt+1}", flush=True)
                    time.sleep(10 * (attempt + 1))
                    continue
                resp.raise_for_status()
                data = resp.json()
                break
            except requests.exceptions.Timeout:
                print(f"    Timeout, retry {attempt+1}", flush=True)
                time.sleep(10 * (attempt + 1))
            except Exception as e:
                print(f"    Error: {e}, retry {attempt+1}", flush=True)
                time.sleep(5)
        else:
            print(f"    FAILED after 5 attempts, skipping batch", flush=True)
            break

        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            break

        for hit in hits:
            src = hit["_source"]
            oj = src.get("orgaoJulgador", {})
            assuntos = src.get("assuntos", [])
            movs = src.get("movimentos", [])

            # Parse key movement flags
            has_sorteio = False
            has_procedencia = False
            has_improcedencia = False
            has_pretrial = False
            has_definitivo = False
            has_transito = False
            date_procedencia = ""
            date_definitivo = ""

            for m in movs:
                cod = m.get("codigo")
                if cod == 26 or cod == 36:
                    comps = m.get("complementosTabelados", [])
                    for c in comps:
                        if c.get("nome") == "sorteio":
                            has_sorteio = True
                elif cod == 219:
                    has_procedencia = True
                    if not date_procedencia:
                        date_procedencia = m.get("dataHora", "")[:10]
                elif cod == 220:
                    has_improcedencia = True
                elif cod == 12140:
                    has_pretrial = True
                elif cod == 246:
                    has_definitivo = True
                    if not date_definitivo:
                        date_definitivo = m.get("dataHora", "")[:10]
                elif cod == 848:
                    has_transito = True

            cases.append({
                "case_id": src.get("numeroProcesso", ""),
                "vara_codigo": oj.get("codigo"),
                "vara_nome": oj.get("nome", ""),
                "filing_date": src.get("dataAjuizamento", "")[:10],
                "assunto_codigo": assuntos[0].get("codigo") if assuntos else None,
                "has_sorteio": has_sorteio,
                "has_procedencia": has_procedencia,
                "has_improcedencia": has_improcedencia,
                "has_pretrial_detention": has_pretrial,
                "has_definitivo": has_definitivo,
                "has_transito_julgado": has_transito,
                "n_movements": len(movs),
                "date_procedencia": date_procedencia,
                "date_definitivo": date_definitivo,
            })

        search_after = hits[-1]["sort"]
        page += 1

        if page % 10 == 0:
            print(f"    {year}: page {page}, {len(cases)} cases", flush=True)

        time.sleep(RATE_LIMIT)

    return cases


def main():
    print(f"[{datetime.now().isoformat()}] Chunked fetch starting", flush=True)

    all_cases = []
    for year in range(2015, 2024):
        print(f"\n  Fetching {year}...", flush=True)
        year_cases = fetch_year(year)
        print(f"  {year}: {len(year_cases)} cases fetched", flush=True)
        all_cases.extend(year_cases)

        # Save incrementally
        df = pd.DataFrame(all_cases)
        df.to_csv(OUTPUT_DIR / "thin_cases_partial.csv", index=False)

    df = pd.DataFrame(all_cases)

    # Extract comarca from case number
    df["comarca_code"] = df["case_id"].str[13:17]

    print(f"\n--- Final Results ---", flush=True)
    print(f"Total cases: {len(df):,}", flush=True)
    print(f"Unique varas: {df['vara_codigo'].nunique()}", flush=True)
    print(f"Unique comarcas: {df['comarca_code'].nunique()}", flush=True)
    print(f"Cases with sorteio: {df['has_sorteio'].sum():,} "
          f"({100*df['has_sorteio'].mean():.1f}%)", flush=True)
    print(f"Convicted (Procedência): {df['has_procedencia'].sum():,} "
          f"({100*df['has_procedencia'].mean():.1f}%)", flush=True)
    print(f"Pretrial detention: {df['has_pretrial_detention'].sum():,}", flush=True)

    # Multi-vara comarcas
    vara_per_comarca = df.groupby("comarca_code")["vara_codigo"].nunique()
    multi = vara_per_comarca[vara_per_comarca >= 2]
    in_multi = df[df["comarca_code"].isin(multi.index)]
    print(f"\nMulti-vara comarcas: {len(multi)}", flush=True)
    print(f"Cases in multi-vara comarcas: {len(in_multi):,}", flush=True)

    # Save final
    df.to_csv(OUTPUT_DIR / "thin_cases.csv", index=False)

    # Also save as parquet for R
    df.to_parquet(OUTPUT_DIR / "raw_cases.parquet", index=False)

    print(f"\n[{datetime.now().isoformat()}] Fetch complete", flush=True)


if __name__ == "__main__":
    main()
