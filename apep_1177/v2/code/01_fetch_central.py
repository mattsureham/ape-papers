"""
01_fetch_central.py — Fetch Central + multi-vara comarca cases for 3 offense types
apep_1177 v2: The Conviction Lottery

Fetches case-level data with full movements for:
  - Drug trafficking (assunto 3608)
  - Robbery (assunto 3419)
  - Theft (assunto 3416)

From São Paulo Central (31 varas) + Campinas (6) + Ribeirão Preto (4).

Output:
    ./data/central_trafficking.parquet
    ./data/central_robbery.parquet
    ./data/central_theft.parquet
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
OUTPUT_DIR.mkdir(exist_ok=True)

# Central vara codes (31 varas)
CENTRAL_VARAS = [
    10522, 10525, 10523, 10521, 10533, 10512, 10527, 10529,
    10517, 10509, 10531, 10515, 10536, 10532, 10508, 10513,
    10524, 10514, 10803, 10537, 10534, 10528, 10526, 10520,
    10535, 10530, 10519, 59222, 10511, 10510, 10518
]

# Other multi-vara comarcas
CAMPINAS_VARAS = [9615, 9464, 10112, 9670, 9671, 13675]
RIBEIRAO_VARAS = [10130, 9736, 16271, 9923]

ALL_VARAS = CENTRAL_VARAS + CAMPINAS_VARAS + RIBEIRAO_VARAS

# Offense types
OFFENSES = {
    "trafficking": {"code": 3608, "name": "Tráfico de Drogas"},
    "robbery": {"code": 3419, "name": "Roubo"},
    "theft": {"code": 3416, "name": "Furto"},
}

BATCH_SIZE = 100
RATE_LIMIT = 4.0  # seconds between requests
YEARS = range(2015, 2024)


def parse_case(hit, offense_type):
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
    has_prescricao = False
    date_proc = ""
    date_def = ""
    date_filing = src.get("dataAjuizamento", "")[:10]

    # Check formato (electronic vs physical)
    formato = src.get("formato", {})
    if isinstance(formato, dict):
        formato_nome = formato.get("nome", "")
    else:
        formato_nome = str(formato) if formato else ""

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
        elif cod == 11878:
            has_prescricao = True

    # Extract comarca from case number (digits 14-17 of the 20-digit number)
    case_id = src.get("numeroProcesso", "")
    comarca_code = case_id[13:17] if len(case_id) >= 17 else ""

    return {
        "case_id": case_id,
        "vara_codigo": oj.get("codigo"),
        "vara_nome": oj.get("nome", ""),
        "comarca_code": comarca_code,
        "filing_date": date_filing,
        "offense_type": offense_type,
        "formato": formato_nome,
        "has_sorteio": has_sorteio,
        "convicted": has_proc,
        "acquitted": has_impro,
        "pretrial_detained": has_pretrial,
        "resolved": has_def,
        "final_judgment": has_trans,
        "prescricao": has_prescricao,
        "n_movements": len(movs),
        "date_convicted": date_proc,
        "date_resolved": date_def,
    }


def fetch_vara_year(vara_code, year, offense_code, offense_type):
    """Fetch all cases for one vara in one year for one offense."""
    cases = []
    search_after = None

    while True:
        query = {
            "size": BATCH_SIZE,
            "query": {
                "bool": {
                    "must": [
                        {"match": {"assuntos.codigo": offense_code}},
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
                if resp.status_code == 429:
                    print(f"      429 rate limit, waiting 30s", flush=True)
                    time.sleep(30)
                    continue
                resp.raise_for_status()
                data = resp.json()
                break
            except requests.exceptions.ReadTimeout:
                print(f"      Timeout, retry {attempt+1}", flush=True)
                time.sleep(10 * (attempt + 1))
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
                cases.append(parse_case(hit, offense_type))
            except Exception:
                pass

        if len(hits) < BATCH_SIZE:
            break

        search_after = hits[-1]["sort"]
        time.sleep(RATE_LIMIT)

    return cases


def fetch_offense(offense_key, offense_info, varas, years):
    """Fetch all cases for one offense type across all varas and years."""
    code = offense_info["code"]
    name = offense_info["name"]
    all_cases = []

    print(f"\n{'='*60}", flush=True)
    print(f"Fetching {name} (code {code})", flush=True)
    print(f"{'='*60}", flush=True)

    for year in years:
        year_count = 0
        for vara in varas:
            cases = fetch_vara_year(vara, year, code, offense_key)
            all_cases.extend(cases)
            year_count += len(cases)
            if cases:
                print(f"  {year} vara {vara}: {len(cases)}", flush=True)

        print(f"  {year} total: {year_count}", flush=True)

        # Save incrementally
        if all_cases:
            pd.DataFrame(all_cases).to_parquet(
                OUTPUT_DIR / f"central_{offense_key}_partial.parquet",
                index=False)

    return all_cases


def main():
    print(f"[{datetime.now().isoformat()}] Starting Central fetch for 3 offenses",
          flush=True)
    print(f"Varas: {len(ALL_VARAS)} ({len(CENTRAL_VARAS)} Central, "
          f"{len(CAMPINAS_VARAS)} Campinas, {len(RIBEIRAO_VARAS)} Ribeirão)",
          flush=True)

    for offense_key, offense_info in OFFENSES.items():
        cases = fetch_offense(offense_key, offense_info, ALL_VARAS, YEARS)

        if cases:
            df = pd.DataFrame(cases)
            outpath = OUTPUT_DIR / f"central_{offense_key}.parquet"
            df.to_parquet(outpath, index=False)

            print(f"\n--- {offense_info['name']} ---", flush=True)
            print(f"  Total cases: {len(df):,}", flush=True)
            print(f"  Unique varas: {df['vara_codigo'].nunique()}", flush=True)
            print(f"  Sorteio: {df['has_sorteio'].sum():,} "
                  f"({100*df['has_sorteio'].mean():.1f}%)", flush=True)
            print(f"  Convicted: {df['convicted'].sum():,} "
                  f"({100*df['convicted'].mean():.1f}%)", flush=True)
            print(f"  Saved to {outpath}", flush=True)
        else:
            print(f"\nWARNING: No cases fetched for {offense_info['name']}",
                  flush=True)

    print(f"\n[{datetime.now().isoformat()}] Fetch complete", flush=True)


if __name__ == "__main__":
    main()
