"""
01_fetch_data.py — Fetch drug trafficking cases from DataJud API (TJSP)
apep_1177: The Classification Lottery

Fetches all first-instance drug trafficking criminal prosecutions from
São Paulo state judiciary via CNJ DataJud public Elasticsearch API.

Usage:
    python3 ./code/01_fetch_data.py

Output:
    ./data/raw_cases.parquet
"""

import json
import time
import sys
import os
from pathlib import Path
from datetime import datetime

import requests
import pandas as pd

# Config
API_URL = "https://api-publica.datajud.cnj.jus.br/api_publica_tjsp/_search"
API_KEY = "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="
HEADERS = {
    "Content-Type": "application/json",
    "Authorization": f"APIKey {API_KEY}"
}
OUTPUT_DIR = Path("./data")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
BATCH_SIZE = 500  # Max per ES request
RATE_LIMIT = 2.5  # Seconds between requests
MAX_RETRIES = 3

# Target: assuntos.codigo=3608 (Tráfico de Drogas), grau=G1, classe.codigo=283 (Ação Penal)
QUERY_BODY = {
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
        "dataAjuizamento", "classe", "grau", "movimentos",
        "formato", "tribunal"
    ],
    "sort": [{"dataAjuizamento": "asc"}]
}


def parse_case(hit):
    """Extract structured fields from a DataJud hit."""
    src = hit["_source"]
    case = {
        "case_id": src.get("numeroProcesso", ""),
        "vara_codigo": None,
        "vara_nome": "",
        "filing_date": src.get("dataAjuizamento", ""),
        "assunto_codigo": None,
        "assunto_nome": "",
        "formato": "",
    }

    # Vara
    oj = src.get("orgaoJulgador", {})
    case["vara_codigo"] = oj.get("codigo")
    case["vara_nome"] = oj.get("nome", "")

    # Assuntos (first one)
    assuntos = src.get("assuntos", [])
    if assuntos:
        case["assunto_codigo"] = assuntos[0].get("codigo")
        case["assunto_nome"] = assuntos[0].get("nome", "")

    # Format
    fmt = src.get("formato", {})
    case["formato"] = fmt.get("nome", "") if isinstance(fmt, dict) else ""

    # Parse movements for key outcomes
    movs = src.get("movimentos", [])
    case["n_movements"] = len(movs)
    case["has_sorteio"] = False
    case["has_procedencia"] = False
    case["has_improcedencia"] = False
    case["has_mudanca_classe"] = False
    case["has_transito_julgado"] = False
    case["has_definitivo"] = False
    case["has_prescricao"] = False
    case["has_pretrial_detention"] = False
    case["has_denuncia"] = False
    case["date_distribuicao"] = ""
    case["date_procedencia"] = ""
    case["date_definitivo"] = ""
    case["date_transito"] = ""

    for m in movs:
        cod = m.get("codigo")
        dt = m.get("dataHora", "")

        # Sorteio check (distribution via lottery)
        if cod == 26:  # Distribuição
            case["date_distribuicao"] = dt
            comps = m.get("complementosTabelados", [])
            for c in comps:
                if c.get("nome") == "sorteio":
                    case["has_sorteio"] = True

        # Redistribuição also may have sorteio
        elif cod == 36:
            comps = m.get("complementosTabelados", [])
            for c in comps:
                if c.get("nome") == "sorteio":
                    case["has_sorteio"] = True

        # Outcomes
        elif cod == 219:  # Procedência (conviction)
            case["has_procedencia"] = True
            if not case["date_procedencia"]:
                case["date_procedencia"] = dt
        elif cod == 220:  # Improcedência (acquittal)
            case["has_improcedencia"] = True
        elif cod == 10966:  # Mudança de classe
            case["has_mudanca_classe"] = True
        elif cod == 848:  # Trânsito em julgado
            case["has_transito_julgado"] = True
            if not case["date_transito"]:
                case["date_transito"] = dt
        elif cod == 246:  # Definitivo
            case["has_definitivo"] = True
            if not case["date_definitivo"]:
                case["date_definitivo"] = dt
        elif cod == 11878:  # Prescrição
            case["has_prescricao"] = True
        elif cod == 12140:  # Prisão em flagrante → preventiva
            case["has_pretrial_detention"] = True
        elif cod == 391:  # Denúncia
            case["has_denuncia"] = True

    return case


def fetch_all_cases():
    """Paginate through all cases using search_after."""
    all_cases = []
    search_after = None
    page = 0

    while True:
        query = json.loads(json.dumps(QUERY_BODY))
        if search_after:
            query["search_after"] = search_after

        for attempt in range(MAX_RETRIES):
            try:
                resp = requests.post(API_URL, headers=HEADERS,
                                     json=query, timeout=120)
                resp.raise_for_status()
                data = resp.json()
                break
            except Exception as e:
                print(f"  Attempt {attempt+1} failed: {e}")
                if attempt < MAX_RETRIES - 1:
                    time.sleep(5)
                else:
                    raise

        hits = data["hits"]["hits"]
        if not hits:
            break

        for hit in hits:
            try:
                case = parse_case(hit)
                all_cases.append(case)
            except Exception as e:
                print(f"  Parse error for {hit.get('_id', '?')}: {e}")

        # Update search_after for next page
        search_after = hits[-1]["sort"]
        page += 1

        if page % 10 == 0:
            print(f"  Page {page}: {len(all_cases):,} cases fetched "
                  f"(last filing: {all_cases[-1]['filing_date'][:10]})")

        time.sleep(RATE_LIMIT)

    return all_cases


def main():
    print(f"[{datetime.now().isoformat()}] Starting DataJud fetch for apep_1177")
    print(f"Target: TJSP trafficking cases (assunto 3608, classe 283, G1)")

    cases = fetch_all_cases()
    print(f"\nFetched {len(cases):,} cases total")

    df = pd.DataFrame(cases)

    # Basic validation
    print(f"\nValidation:")
    print(f"  Unique cases: {df['case_id'].nunique():,}")
    print(f"  Unique varas: {df['vara_codigo'].nunique()}")
    print(f"  Cases with sorteio: {df['has_sorteio'].sum():,} "
          f"({100*df['has_sorteio'].mean():.1f}%)")
    print(f"  Cases with Procedência: {df['has_procedencia'].sum():,} "
          f"({100*df['has_procedencia'].mean():.1f}%)")
    print(f"  Cases with Improcedência: {df['has_improcedencia'].sum():,}")
    print(f"  Cases with Mudança de classe: {df['has_mudanca_classe'].sum():,}")
    print(f"  Cases with pretrial detention: {df['has_pretrial_detention'].sum():,}")
    print(f"  Filing date range: {df['filing_date'].min()[:10]} to "
          f"{df['filing_date'].max()[:10]}")

    # Save
    outpath = OUTPUT_DIR / "raw_cases.parquet"
    df.to_parquet(outpath, index=False)
    print(f"\nSaved to {outpath}")
    print(f"[{datetime.now().isoformat()}] Fetch complete")


if __name__ == "__main__":
    main()
