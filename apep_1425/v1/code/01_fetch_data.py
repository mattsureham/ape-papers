"""01_fetch_data.py — apep_1425
Fetch labor court case data from DataJud API.
Focus: TRT2, TRT4, TRT15 (three largest with geographic diversity).
Strategy: Fetch by YEAR to ensure temporal coverage across 2014-2023.
Output: CSV files per TRT + combined all_cases.csv
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
MAX_PER_YEAR = 1_000  # 1K per year × 10 years × 3 TRTs = ~30K total
PAGE_SIZE = 1_000
YEARS = list(range(2012, 2024))  # 2012-2023 (need ≥5 pre-reform years)

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
        "sort": [
            {"dataAjuizamento": "asc"},
            {"numeroProcesso.keyword": "asc"}
        ]
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
    subject_codes_list = [str(a.get("codigo", "")) for a in assuntos if isinstance(a, dict)]
    subject_names_list = [a.get("nome", "") for a in assuntos if isinstance(a, dict)]

    return {
        "case_id": src.get("numeroProcesso", ""),
        "filing_date": src.get("dataAjuizamento", ""),
        "classe": src.get("classe", {}).get("nome", ""),
        "subject_codes": ";".join(subject_codes_list),
        "subject_names": ";".join(subject_names_list),
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


def fetch_trt(trt):
    outfile = os.path.join(DATA_DIR, f"{trt}_cases.csv")
    if os.path.exists(outfile):
        with open(outfile) as f:
            n = sum(1 for _ in f) - 1
        print(f"  {trt.upper()}: already fetched ({n} rows), skipping.")
        return outfile

    print(f"\n=== Fetching {trt.upper()} ===")
    grand_total = 0

    with open(outfile, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
        writer.writeheader()

        for year in YEARS:
            date_gte = f"{year}0101000000"
            date_lte = f"{year}1231235959"
            search_after = None
            year_total = 0

            while year_total < MAX_PER_YEAR:
                result = fetch_page(trt, date_gte, date_lte, search_after)
                if result is None:
                    break
                if "error" in result:
                    print(f"    {year}: API error")
                    break
                hits = result["hits"]["hits"]
                if not hits:
                    break
                for hit in hits:
                    writer.writerow(extract_case(hit, trt))
                year_total += len(hits)
                search_after = hits[-1]["sort"]
                time.sleep(0.1)

            grand_total += year_total
            print(f"    {year}: {year_total} cases")

    print(f"  {trt.upper()} total: {grand_total} cases -> {outfile}")
    return outfile


def main():
    os.makedirs(DATA_DIR, exist_ok=True)
    files = [fetch_trt(trt) for trt in TRTS]

    combined = os.path.join(DATA_DIR, "all_cases.csv")
    print(f"\n=== Combining {len(files)} TRT files ===")
    total_rows = 0
    with open(combined, "w", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for f in files:
            with open(f) as inp:
                for row in csv.DictReader(inp):
                    writer.writerow(row)
                    total_rows += 1
    print(f"Combined: {total_rows} cases -> {combined}")
    print("=== Data fetch complete ===")


if __name__ == "__main__":
    main()
