"""
01b_smoke_corrected.py — Corrected smoke test fetch
apep_1177 v2: The Conviction Lottery

Fix: only count cases that have reached disposition (has code 219, 220, 246, or 848).
For robbery (4000+ cases per vara), we need to fetch enough to get resolved cases.
Strategy: fetch cases filed 2015-2019 (enough time to resolve).

Output:
    ./data/smoke_robbery_corrected.parquet
    ./data/smoke_theft_corrected.parquet
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

OFFENSES = {
    "robbery": 3419,
    "theft": 3416,
}

BATCH_SIZE = 100
RATE_LIMIT = 3.0
# Restrict to older cases more likely to be resolved
YEAR_RANGE = (2015, 2020)  # filed 2015-2019


def parse_case(hit, offense_type):
    """Parse case checking all disposition codes."""
    src = hit["_source"]
    oj = src.get("orgaoJulgador", {})
    movs = src.get("movimentos", [])

    has_sorteio = False
    has_proc = False       # 219 = Procedência (convicted)
    has_proc_part = False  # 221 = Procedência em Parte
    has_impro = False      # 220 = Improcedência (acquitted)
    has_pretrial = False
    has_def = False        # 246 = Definitivo
    has_trans = False      # 848 = Trânsito em julgado
    has_prescricao = False  # 11878
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
        elif cod == 221:
            has_proc_part = True
        elif cod == 220:
            has_impro = True
        elif cod == 12140:
            has_pretrial = True
        elif cod == 246:
            has_def = True
        elif cod == 848:
            has_trans = True
        elif cod == 11878:
            has_prescricao = True

    # A case is "resolved" if it has any disposition code
    resolved = has_proc or has_proc_part or has_impro or has_def or has_trans or has_prescricao
    # "Convicted" includes full and partial conviction
    convicted = has_proc or has_proc_part

    return {
        "case_id": src.get("numeroProcesso", ""),
        "vara_codigo": oj.get("codigo"),
        "vara_nome": oj.get("nome", ""),
        "filing_date": date_filing,
        "offense_type": offense_type,
        "formato": formato_nome,
        "has_sorteio": has_sorteio,
        "convicted": convicted,
        "convicted_full": has_proc,
        "convicted_partial": has_proc_part,
        "acquitted": has_impro,
        "pretrial_detained": has_pretrial,
        "resolved": resolved,
        "has_definitivo": has_def,
        "has_transito": has_trans,
        "prescricao": has_prescricao,
        "n_movements": len(movs),
    }


def fetch_vara_year(vara_code, year, offense_code, offense_type):
    """Fetch all cases for one vara-year-offense."""
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
                        {"range": {"dataAjuizamento": {
                            "gte": f"{year}-01-01",
                            "lt": f"{year+1}-01-01"
                        }}}
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
                                     json=query, timeout=120)
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
    print(f"[{datetime.now().isoformat()}] Corrected smoke test starting", flush=True)
    print(f"Year range: {YEAR_RANGE[0]}-{YEAR_RANGE[1]-1}", flush=True)

    for off_name, off_code in OFFENSES.items():
        all_cases = []
        print(f"\n{'='*50}", flush=True)
        print(f"Fetching {off_name} (code {off_code})", flush=True)
        print(f"{'='*50}", flush=True)

        for vara_idx, vara in enumerate(CENTRAL_VARAS):
            vara_cases = []
            for year in range(YEAR_RANGE[0], YEAR_RANGE[1]):
                cases = fetch_vara_year(vara, year, off_code, off_name)
                vara_cases.extend(cases)

            all_cases.extend(vara_cases)

            if vara_cases:
                n = len(vara_cases)
                resolved = sum(1 for c in vara_cases if c["resolved"])
                convicted = sum(1 for c in vara_cases if c["convicted"])
                conv_rate = convicted / resolved if resolved > 0 else 0
                print(f"  [{vara_idx+1}/31] Vara {vara}: "
                      f"{n} total, {resolved} resolved, "
                      f"conv={convicted} ({100*conv_rate:.1f}% of resolved)",
                      flush=True)
            else:
                print(f"  [{vara_idx+1}/31] Vara {vara}: 0 cases", flush=True)

            # Save incrementally
            if all_cases and vara_idx % 5 == 4:
                pd.DataFrame(all_cases).to_parquet(
                    OUTPUT_DIR / f"smoke_{off_name}_corrected_partial.parquet",
                    index=False)

        if all_cases:
            df = pd.DataFrame(all_cases)
            outpath = OUTPUT_DIR / f"smoke_{off_name}_corrected.parquet"
            df.to_parquet(outpath, index=False)

            resolved_df = df[df["resolved"]]
            print(f"\n  Total: {len(df):,} cases", flush=True)
            print(f"  Resolved: {len(resolved_df):,} "
                  f"({100*len(resolved_df)/len(df):.1f}%)", flush=True)
            print(f"  Convicted (of resolved): {resolved_df['convicted'].sum():,} "
                  f"({100*resolved_df['convicted'].mean():.1f}%)", flush=True)

    # Summary comparison
    print(f"\n{'='*50}", flush=True)
    print("SMOKE TEST COMPARISON (resolved cases only)", flush=True)
    print(f"{'='*50}", flush=True)

    # Also load trafficking
    traff_path = OUTPUT_DIR / "smoke_trafficking.parquet"
    if traff_path.exists():
        traff_df = pd.read_parquet(traff_path)
        # Filter to same year range
        traff_df = traff_df[traff_df["filing_date"].str[:4].astype(int).between(
            YEAR_RANGE[0], YEAR_RANGE[1]-1)]

        print(f"\nTrafficking (filed {YEAR_RANGE[0]}-{YEAR_RANGE[1]-1}):")
        vara_rates = traff_df.groupby("vara_codigo")["convicted"].mean()
        vara_rates = vara_rates[traff_df.groupby("vara_codigo").size() >= 20]
        print(f"  Varas with ≥20 cases: {len(vara_rates)}")
        print(f"  Mean conv rate: {vara_rates.mean():.3f}")
        print(f"  SD: {vara_rates.std():.3f}")
        p10 = vara_rates.quantile(0.10)
        p90 = vara_rates.quantile(0.90)
        print(f"  P10: {p10:.3f}, P90: {p90:.3f}, spread: {p90-p10:.3f}")

    for off_name in OFFENSES:
        path = OUTPUT_DIR / f"smoke_{off_name}_corrected.parquet"
        if path.exists():
            df = pd.read_parquet(path)
            resolved = df[df["resolved"]]

            if len(resolved) > 0:
                print(f"\n{off_name} (resolved only):")
                vara_rates = resolved.groupby("vara_codigo")["convicted"].mean()
                vara_n = resolved.groupby("vara_codigo").size()
                vara_rates = vara_rates[vara_n >= 20]

                print(f"  Varas with ≥20 resolved: {len(vara_rates)}")
                if len(vara_rates) > 2:
                    print(f"  Mean conv rate: {vara_rates.mean():.3f}")
                    print(f"  SD: {vara_rates.std():.3f}")
                    p10 = vara_rates.quantile(0.10)
                    p90 = vara_rates.quantile(0.90)
                    print(f"  P10: {p10:.3f}, P90: {p90:.3f}, spread: {p90-p10:.3f}")

    print(f"\n[{datetime.now().isoformat()}] Done", flush=True)


if __name__ == "__main__":
    main()
