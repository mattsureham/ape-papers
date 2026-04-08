"""01b_fetch_extra_years.py — apep_1425
Fetch 2012-2013 cases to add more pre-reform years.
Appends to existing TRT CSV files.
"""

import json
import csv
import os
import time
import urllib.request

API_KEY = "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="
BASE_URL = "https://api-publica.datajud.cnj.jus.br"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, "..", "data")
TRTS = ["trt2", "trt4", "trt15"]
MAX_PER_YEAR = 1_000
PAGE_SIZE = 1_000
EXTRA_YEARS = [2012, 2013]

CSV_FIELDS = [
    "case_id", "filing_date", "classe", "subject_codes", "subject_names",
    "vara_code", "vara_name", "muni_ibge",
    "verdict_code", "verdict_name", "verdict_date",
    "has_settlement", "settlement_date", "trt"
]


def fetch_page(trt, date_gte, date_lte, search_after=None):
    url = f"{BASE_URL}/api_publica_{trt}/_search"
    query = {
        "size": PAGE_SIZE,
        "query": {
            "bool": {
                "must": [
                    {"match": {"grau": "G1"}},
                    {"match": {"movimentos.complementosTabelados.nome": "sorteio"}},
                    {"range": {"dataAjuizamento": {"gte": date_gte, "lte": date_lte}}}
                ]
            }
        },
        "_source": [
            "numeroProcesso", "grau", "orgaoJulgador", "dataAjuizamento",
            "classe", "assuntos", "movimentos"
        ],
        "sort": [{"dataAjuizamento": "asc"}, {"numeroProcesso.keyword": "asc"}]
    }
    if search_after is not None:
        query["search_after"] = search_after
    body = json.dumps(query).encode("utf-8")
    req = urllib.request.Request(
        url, data=body,
        headers={"Authorization": f"ApiKey {API_KEY}", "Content-Type": "application/json"},
        method="POST"
    )
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                return json.loads(resp.read())
        except Exception as e:
            print(f"      Attempt {attempt+1} failed: {e}")
            time.sleep(10 * (attempt + 1))
    return None


def extract_case(hit, trt):
    src = hit["_source"]
    movs = src.get("movimentos", [])
    verdict_code = verdict_name = verdict_date = None
    has_settlement = False
    settlement_date = None
    for m in movs:
        code = m.get("codigo")
        if code in (219, 220, 221):
            verdict_code = code
            verdict_name = m.get("nome", "")
            verdict_date = m.get("dataHora", "")
        if code == 385:
            has_settlement = True
            settlement_date = m.get("dataHora", "")
    oj = src.get("orgaoJulgador", {})
    assuntos = src.get("assuntos", [])
    return {
        "case_id": src.get("numeroProcesso", ""),
        "filing_date": src.get("dataAjuizamento", ""),
        "classe": src.get("classe", {}).get("nome", ""),
        "subject_codes": ";".join([str(a.get("codigo", "")) for a in assuntos if isinstance(a, dict)]),
        "subject_names": ";".join([a.get("nome", "") for a in assuntos if isinstance(a, dict)]),
        "vara_code": str(oj.get("codigo", "")),
        "vara_name": oj.get("nome", ""),
        "muni_ibge": oj.get("codigoMunicipioIBGE", ""),
        "verdict_code": verdict_code or "",
        "verdict_name": verdict_name or "",
        "verdict_date": verdict_date or "",
        "has_settlement": has_settlement,
        "settlement_date": settlement_date or "",
        "trt": trt
    }


def main():
    for trt in TRTS:
        outfile = os.path.join(DATA_DIR, f"{trt}_cases.csv")
        print(f"\n=== Appending to {trt.upper()} ===")

        with open(outfile, "a", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)

            for year in EXTRA_YEARS:
                date_gte = f"{year}0101000000"
                date_lte = f"{year}1231235959"
                search_after = None
                year_total = 0

                while year_total < MAX_PER_YEAR:
                    result = fetch_page(trt, date_gte, date_lte, search_after)
                    if result is None:
                        break
                    if "error" in result:
                        break
                    hits = result["hits"]["hits"]
                    if not hits:
                        break
                    for hit in hits:
                        writer.writerow(extract_case(hit, trt))
                    year_total += len(hits)
                    search_after = hits[-1]["sort"]
                    time.sleep(0.1)

                print(f"    {year}: {year_total} cases")

    # Rebuild combined file
    combined = os.path.join(DATA_DIR, "all_cases.csv")
    total_rows = 0
    with open(combined, "w", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for trt in TRTS:
            with open(os.path.join(DATA_DIR, f"{trt}_cases.csv")) as inp:
                for row in csv.DictReader(inp):
                    writer.writerow(row)
                    total_rows += 1
    print(f"\nCombined: {total_rows} cases -> {combined}")


if __name__ == "__main__":
    main()
