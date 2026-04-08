#!/usr/bin/env python3
"""Fetch real data from datos.gov.co Socrata APIs.

Datasets:
  jgra-rz2t  Cuentas Claras 2019 (campaign donor records)
  h236-q58p  Elected governors and mayors 2019
  jbjy-vk9h  SECOP II - Contratos Electronicos
  kgxf-xxbe  ICFES Saber 11 (student test records)

Output: Parquet files in ../data/
"""
import sys, time, json
from pathlib import Path
import pandas as pd
import requests

DATA = Path(__file__).resolve().parent.parent / "data"
DATA.mkdir(parents=True, exist_ok=True)

BASE = "https://www.datos.gov.co/resource"
PAGE = 50000

def fetch_all(dataset_id, where=None, select=None, order=":id"):
    rows = []
    offset = 0
    while True:
        params = {"$limit": PAGE, "$offset": offset, "$order": order}
        if where: params["$where"] = where
        if select: params["$select"] = select
        url = f"{BASE}/{dataset_id}.json"
        for attempt in range(4):
            try:
                r = requests.get(url, params=params, timeout=180)
                r.raise_for_status()
                break
            except Exception as e:
                if attempt == 3: raise
                print(f"  retry {attempt+1}: {e}", file=sys.stderr)
                time.sleep(2 + attempt*3)
        chunk = r.json()
        if not chunk:
            break
        rows.extend(chunk)
        print(f"  {dataset_id}: fetched {len(rows):,}", file=sys.stderr)
        if len(chunk) < PAGE:
            break
        offset += PAGE
    return pd.DataFrame(rows)

def main():
    skip_existing = True
    # 1. Cuentas Claras donors (2019 mayoral race) - aporte ingresos
    print("[1/4] Cuentas Claras 2019 (Alcaldia)...", file=sys.stderr)
    cc = pd.read_parquet(DATA / "cuentas_claras_2019.parquet")
    print(f"  cached {len(cc):,}", file=sys.stderr)

    # 2. Elected mayors 2019
    print("[2/4] Elected mayors 2019...", file=sys.stderr)
    mayors = fetch_all("h236-q58p", where="a_o='2019' AND corporacion='ALCALDIA'")
    mayors.to_parquet(DATA / "mayors_2019.parquet", index=False)
    print(f"  -> {len(mayors):,} elected mayors", file=sys.stderr)

    # 3. SECOP II
    print("[3/4] SECOP II 2020-2022 (cached)...", file=sys.stderr)
    secop = pd.read_parquet(DATA / "secop_2020_2022.parquet")
    print(f"  cached {len(secop):,}", file=sys.stderr)

    # 4. ICFES Saber 11 2013-2022 - aggregate at API to municipio-year mean
    print("[4/4] ICFES Saber 11 2013-2022 (aggregated by mun-year)...", file=sys.stderr)
    select = ("estu_cod_reside_mcpio AS muni,periodo,"
              "avg(punt_global::number) AS mean_global,"
              "avg(punt_matematicas::number) AS mean_math,"
              "avg(punt_lectura_critica::number) AS mean_lectura,"
              "count(*) AS n_students")
    where = ("periodo >= '20131' AND periodo <= '20224' "
             "AND punt_global IS NOT NULL "
             "AND estu_cod_reside_mcpio IS NOT NULL")
    group = "estu_cod_reside_mcpio,periodo"
    # paginate aggregation
    rows = []
    offset = 0
    while True:
        params = {"$select": select, "$where": where, "$group": group,
                  "$order": "estu_cod_reside_mcpio,periodo",
                  "$limit": PAGE, "$offset": offset}
        r = requests.get(f"{BASE}/kgxf-xxbe.json", params=params, timeout=300)
        r.raise_for_status()
        chunk = r.json()
        if not chunk: break
        rows.extend(chunk)
        print(f"  icfes: {len(rows):,} muni-period rows", file=sys.stderr)
        if len(chunk) < PAGE: break
        offset += PAGE
    icfes = pd.DataFrame(rows)
    icfes.to_parquet(DATA / "icfes_muni_period.parquet", index=False)
    print(f"  -> {len(icfes):,} muni-period observations", file=sys.stderr)

    summary = {
        "cuentas_claras_n": len(cc),
        "mayors_n": len(mayors),
        "secop_n": len(secop),
        "icfes_muni_period_n": len(icfes),
    }
    with open(DATA / "fetch_summary.json", "w") as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    main()
