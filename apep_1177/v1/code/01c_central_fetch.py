"""
01c_central_fetch.py — Fetch São Paulo Central drug trafficking cases
apep_1177: The Conviction Lottery

Fetches only cases from the 31 criminal varas in Central comarca.
Uses small batches and conservative rate limiting.

Output:
    ./data/central_cases.parquet
"""

import json
import time
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

# Central vara codes
CENTRAL_VARAS = [
    10522, 10525, 10523, 10521, 10533, 10512, 10527, 10529,
    10517, 10509, 10531, 10515, 10536, 10532, 10508, 10513,
    10524, 10514, 10803, 10537, 10534, 10528, 10526, 10520,
    10535, 10530, 10519, 59222, 10511, 10510, 10518
]

# Also fetch top multi-vara comarcas outside Central
OTHER_MULTI_VARA_CODES = {
    # Campinas (6 varas)
    9615: "CAMPINAS", 9464: "CAMPINAS",
    10112: "CAMPINAS", 9670: "CAMPINAS",
    9671: "CAMPINAS", 13675: "CAMPINAS",
    # Ribeirão Preto (4 varas)
    10130: "RIBEIRAO PRETO", 9736: "RIBEIRAO PRETO",
    16271: "RIBEIRAO PRETO", 9923: "RIBEIRAO PRETO",
}

ALL_VARAS = CENTRAL_VARAS + list(OTHER_MULTI_VARA_CODES.keys())
BATCH_SIZE = 100
RATE_LIMIT = 4.0


def parse_case(hit):
    """Parse a case with movement flags."""
    src = hit["_source"]
    oj = src.get("orgaoJulgador", {})
    movs = src.get("movimentos", [])

    has_sorteio = False
    has_proc = False
    has_impro = False
    has_pretrial = False
    has_def = False
    has_trans = False
    date_proc = ""
    date_def = ""

    for m in movs:
        cod = m.get("codigo")
        if cod in (26, 36):
            comps = m.get("complementosTabelados", [])
            for c in comps:
                if c.get("nome") == "sorteio":
                    has_sorteio = True
        elif cod == 219:
            has_proc = True
            if not date_proc:
                date_proc = m.get("dataHora", "")[:10]
        elif cod == 220:
            has_impro = True
        elif cod == 12140:
            has_pretrial = True
        elif cod == 246:
            has_def = True
            if not date_def:
                date_def = m.get("dataHora", "")[:10]
        elif cod == 848:
            has_trans = True

    return {
        "case_id": src.get("numeroProcesso", ""),
        "vara_codigo": oj.get("codigo"),
        "vara_nome": oj.get("nome", ""),
        "filing_date": src.get("dataAjuizamento", "")[:10],
        "has_sorteio": has_sorteio,
        "convicted": has_proc,
        "acquitted": has_impro,
        "pretrial_detained": has_pretrial,
        "resolved": has_def,
        "final_judgment": has_trans,
        "n_movements": len(movs),
        "date_convicted": date_proc,
        "date_resolved": date_def,
    }


def fetch_vara_year(vara_code, year):
    """Fetch all cases for one vara in one year."""
    cases = []
    search_after = None

    while True:
        query = {
            "size": BATCH_SIZE,
            "query": {
                "bool": {
                    "must": [
                        {"match": {"assuntos.codigo": 3608}},
                        {"match": {"grau": "G1"}},
                        {"match": {"classe.codigo": 283}},
                        {"match": {"orgaoJulgador.codigo": vara_code}},
                        {"range": {
                            "dataAjuizamento": {
                                "gte": f"{year}-01-01",
                                "lt": f"{year+1}-01-01"
                            }
                        }}
                    ]
                }
            },
            "sort": [{"dataAjuizamento": "asc"}]
        }
        if search_after:
            query["search_after"] = search_after

        for attempt in range(5):
            try:
                resp = requests.post(API_URL, headers=HEADERS,
                                     json=query, timeout=180)
                if resp.status_code == 504:
                    print(f"      504, retry {attempt+1}", flush=True)
                    time.sleep(15 * (attempt + 1))
                    continue
                resp.raise_for_status()
                data = resp.json()
                break
            except Exception as e:
                print(f"      Error: {e}, retry {attempt+1}", flush=True)
                time.sleep(10)
        else:
            print(f"      FAILED after 5 attempts", flush=True)
            break

        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            break

        for hit in hits:
            try:
                cases.append(parse_case(hit))
            except Exception:
                pass

        if len(hits) < BATCH_SIZE:
            break

        search_after = hits[-1]["sort"]
        time.sleep(RATE_LIMIT)

    return cases


def main():
    print(f"[{datetime.now().isoformat()}] Central + multi-vara fetch starting",
          flush=True)

    all_cases = []

    for year in range(2015, 2024):
        print(f"\n  Year {year}:", flush=True)
        year_cases = 0

        for vara in ALL_VARAS:
            cases = fetch_vara_year(vara, year)
            all_cases.extend(cases)
            year_cases += len(cases)
            if cases:
                print(f"    Vara {vara}: {len(cases)} cases", flush=True)

        print(f"  {year} total: {year_cases} cases", flush=True)

        # Save incrementally
        pd.DataFrame(all_cases).to_parquet(
            OUTPUT_DIR / "central_cases_partial.parquet", index=False)

    df = pd.DataFrame(all_cases)

    print(f"\n--- Final Results ---", flush=True)
    print(f"Total cases: {len(df):,}", flush=True)
    print(f"Unique varas: {df['vara_codigo'].nunique()}", flush=True)
    print(f"Cases with sorteio: {df['has_sorteio'].sum():,} "
          f"({100*df['has_sorteio'].mean():.1f}%)", flush=True)
    print(f"Convicted: {df['convicted'].sum():,} "
          f"({100*df['convicted'].mean():.1f}%)", flush=True)
    print(f"Pretrial detained: {df['pretrial_detained'].sum():,} "
          f"({100*df['pretrial_detained'].mean():.1f}%)", flush=True)

    # Save final
    df.to_parquet(OUTPUT_DIR / "central_cases.parquet", index=False)
    df.to_csv(OUTPUT_DIR / "central_cases.csv", index=False)

    print(f"\n[{datetime.now().isoformat()}] Fetch complete", flush=True)


if __name__ == "__main__":
    main()
