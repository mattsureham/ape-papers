"""
01_smoke_test_fetch.py — Targeted fetch for smoke test comparison
apep_1177 v2: The Conviction Lottery

For each Central vara, fetches up to 500 cases each for robbery and theft
to estimate vara-level conviction rates for the comparison test.
Uses the existing V1 trafficking data.

Output:
    ./data/smoke_robbery.parquet
    ./data/smoke_theft.parquet
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

CENTRAL_VARAS = [
    10522, 10525, 10523, 10521, 10533, 10512, 10527, 10529,
    10517, 10509, 10531, 10515, 10536, 10532, 10508, 10513,
    10524, 10514, 10803, 10537, 10534, 10528, 10526, 10520,
    10535, 10530, 10519, 59222, 10511, 10510, 10518
]

# For smoke test, also fetch trafficking to have consistent data
OFFENSES = {
    "trafficking": 3608,
    "robbery": 3419,
    "theft": 3416,
}

MAX_CASES_PER_VARA = 500  # Enough for precise conviction rate estimates
BATCH_SIZE = 100
RATE_LIMIT = 3.0


def parse_case(hit, offense_type):
    """Parse case with conviction flag."""
    src = hit["_source"]
    oj = src.get("orgaoJulgador", {})
    movs = src.get("movimentos", [])

    has_sorteio = False
    has_proc = False
    has_impro = False
    has_pretrial = False
    date_filing = src.get("dataAjuizamento", "")[:10]

    formato = src.get("formato", {})
    formato_nome = formato.get("nome", "") if isinstance(formato, dict) else str(formato or "")

    for m in movs:
        cod = m.get("codigo")
        if cod in (26, 36):
            comps = m.get("complementosTabelados", [])
            for c in comps:
                if c.get("nome") == "sorteio":
                    has_sorteio = True
        elif cod == 219:
            has_proc = True
        elif cod == 220:
            has_impro = True
        elif cod == 12140:
            has_pretrial = True

    return {
        "case_id": src.get("numeroProcesso", ""),
        "vara_codigo": oj.get("codigo"),
        "vara_nome": oj.get("nome", ""),
        "filing_date": date_filing,
        "offense_type": offense_type,
        "formato": formato_nome,
        "has_sorteio": has_sorteio,
        "convicted": has_proc,
        "acquitted": has_impro,
        "pretrial_detained": has_pretrial,
        "n_movements": len(movs),
    }


def fetch_vara_cases(vara_code, offense_code, offense_type, max_cases):
    """Fetch up to max_cases for one vara, one offense."""
    cases = []
    search_after = None

    while len(cases) < max_cases:
        query = {
            "size": min(BATCH_SIZE, max_cases - len(cases)),
            "query": {
                "bool": {
                    "must": [
                        {"match": {"assuntos.codigo": offense_code}},
                        {"match": {"grau": "G1"}},
                        {"match": {"classe.codigo": 283}},
                        {"match": {"orgaoJulgador.codigo": vara_code}}
                    ]
                }
            },
            "sort": [{"dataAjuizamento": "asc"}]
        }
        if search_after:
            query["search_after"] = search_after

        for attempt in range(3):
            try:
                resp = requests.post(API_URL, headers=HEADERS,
                                     json=query, timeout=60)
                if resp.status_code in (504, 429):
                    time.sleep(15)
                    continue
                resp.raise_for_status()
                data = resp.json()
                break
            except Exception:
                time.sleep(10)
        else:
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


def main():
    print(f"[{datetime.now().isoformat()}] Smoke test fetch starting", flush=True)

    for off_name, off_code in OFFENSES.items():
        all_cases = []
        print(f"\n{'='*50}", flush=True)
        print(f"Fetching {off_name} (code {off_code})", flush=True)
        print(f"{'='*50}", flush=True)

        for i, vara in enumerate(CENTRAL_VARAS):
            cases = fetch_vara_cases(vara, off_code, off_name, MAX_CASES_PER_VARA)
            all_cases.extend(cases)

            if cases:
                conv = sum(1 for c in cases if c["convicted"])
                rate = conv / len(cases)
                print(f"  [{i+1}/{len(CENTRAL_VARAS)}] Vara {vara}: "
                      f"{len(cases)} cases, "
                      f"conv={conv} ({100*rate:.1f}%)", flush=True)
            else:
                print(f"  [{i+1}/{len(CENTRAL_VARAS)}] Vara {vara}: 0 cases", flush=True)

        if all_cases:
            df = pd.DataFrame(all_cases)
            outpath = OUTPUT_DIR / f"smoke_{off_name}.parquet"
            df.to_parquet(outpath, index=False)

            print(f"\n  Total: {len(df):,} cases, "
                  f"convicted: {df['convicted'].sum():,} "
                  f"({100*df['convicted'].mean():.1f}%)", flush=True)
            print(f"  Saved to {outpath}", flush=True)

    # Summary comparison
    print(f"\n{'='*50}", flush=True)
    print("SMOKE TEST COMPARISON", flush=True)
    print(f"{'='*50}", flush=True)

    import statistics
    for off_name in OFFENSES:
        path = OUTPUT_DIR / f"smoke_{off_name}.parquet"
        if path.exists():
            df = pd.read_parquet(path)
            vara_rates = df.groupby("vara_codigo")["convicted"].mean()
            vara_rates = vara_rates[df.groupby("vara_codigo").size() >= 20]

            print(f"\n{off_name} ({len(vara_rates)} varas with ≥20 cases):")
            print(f"  Mean conv rate: {vara_rates.mean():.3f}")
            print(f"  SD conv rate:   {vara_rates.std():.3f}")
            p10 = vara_rates.quantile(0.10)
            p90 = vara_rates.quantile(0.90)
            print(f"  P10: {p10:.3f}, P90: {p90:.3f}")
            print(f"  P90-P10 spread: {p90-p10:.3f}")

    print(f"\n[{datetime.now().isoformat()}] Done", flush=True)


if __name__ == "__main__":
    main()
