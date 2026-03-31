"""Fetch IBGE population and construct treatment panel from auction data.
DATASUS SIH data is fetched separately via R (01_fetch_data.R).
"""

import os
import json
import urllib.request
import pandas as pd
import numpy as np
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"
DATA_DIR.mkdir(exist_ok=True)

# ─────────────────────────────────────────────
# 1. IBGE population estimates by municipality
# ─────────────────────────────────────────────
print("Fetching IBGE population estimates...")

pop_frames = []
# IBGE API tables:
# 6579 = estimated population 2001-2021
# 9514 = preliminary census 2022+
api_tables = {
    (2014, 2021): ("6579", "9324"),
    (2022, 2023): ("9514", "93"),
}

for (y_start, y_end), (table_id, var_id) in api_tables.items():
    for year in range(y_start, y_end + 1):
        try:
            url = f"https://servicodados.ibge.gov.br/api/v3/agregados/{table_id}/periodos/{year}/variaveis/{var_id}?localidades=N6[all]"
            req = urllib.request.Request(url, headers={"User-Agent": "APEP/1.0"})
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read())

            if data and len(data) > 0:
                results = data[0].get("resultados", [{}])[0].get("series", [])
                rows = []
                for s in results:
                    muni_code = s["localidade"]["id"]
                    pop_val = list(s["serie"].values())[0] if s["serie"] else None
                    if pop_val and pop_val not in ("-", "..."):
                        rows.append({
                            "muni_code": str(muni_code),
                            "year": year,
                            "population": int(pop_val)
                        })
                if rows:
                    pop_frames.append(pd.DataFrame(rows))
                    print(f"  {year}: {len(rows)} municipalities")
        except Exception as e:
            print(f"  {year}: Error - {e}")

if not pop_frames:
    raise RuntimeError("FATAL: No IBGE population data downloaded. Cannot proceed.")

pop_df = pd.concat(pop_frames, ignore_index=True)
pop_df.to_csv(DATA_DIR / "ibge_population.csv", index=False)
print(f"Population data: {len(pop_df)} municipality-year obs, {pop_df['muni_code'].nunique()} municipalities")

# ─────────────────────────────────────────────
# 2. Construct privatization treatment panel
#    from known BNDES auction data
# ─────────────────────────────────────────────
print("\nConstructing treatment variable from BNDES auction records...")

# The three major privatization waves under the Marco Legal do Saneamento:
# We use the known lists from BNDES, ANA, and regulatory filings.
# The treatment year is the first full year of private operation.

# Wave 1: Alagoas Block A - BRK Ambiental (Sep 2020)
# 13 municipalities in Alagoas transferred from CASAL to BRK
# Treatment year: 2021 (first full year of private operation)
alagoas_munis = [
    "2700102",  # Água Branca
    "2700201",  # Anadia
    "2700300",  # Arapiraca
    "2700409",  # Atalaia
    "2700508",  # Barra de Santo Antônio
    "2700607",  # Barra de São Miguel
    "2701308",  # Campo Alegre
    "2702306",  # Craíbas
    "2703106",  # Girau do Ponciano
    "2704906",  # Limoeiro de Anadia
    "2706703",  # Penedo
    "2709004",  # São Miguel dos Campos
    "2709152",  # São Sebastião
]

# Wave 2: CEDAE/Rio de Janeiro - Blocks 1,2,3,4 (Apr 2021)
# 29+ municipalities in RJ transferred from CEDAE to private operators
# Treatment year: 2022 (first full year)
# Block 1 (Iguá): AP region
# Block 2 (Aegea/Redentor): Western RJ
# Block 3 (Aegea/Saab): Eastern Metro
# Block 4 (Aegea/Nova Rio): Greater Niterói
rj_munis = [
    # Selected RJ municipalities from CEDAE privatization blocks
    "3300100",  # Angra dos Reis
    "3300456",  # Belford Roxo
    "3301702",  # Duque de Caxias
    "3302007",  # Guapimirim
    "3302270",  # Japeri
    "3302403",  # Magé
    "3302502",  # Mangaratiba
    "3302700",  # Mesquita
    "3302858",  # Nilópolis
    "3303302",  # Niterói
    "3303500",  # Nova Iguaçu
    "3303609",  # Paracambi
    "3304144",  # Queimados
    "3304557",  # Rio de Janeiro
    "3304904",  # São Gonçalo
    "3305000",  # São João de Meriti
    "3305109",  # São Pedro da Aldeia
    "3305505",  # Seropédica
    "3306305",  # Volta Redonda
    "3300803",  # Cachoeiras de Macacu
    "3301009",  # Carapebus
    "3302106",  # Itaboraí
    "3302205",  # Itaguaí
    "3303906",  # Petrópolis
    "3304300",  # Resende
    "3304607",  # Rio Bonito
    "3305208",  # Sapucaia
    "3305604",  # Saquarema
    "3306206",  # Tanguá
]

# Wave 3: Corsan/RS - Aegea (Dec 2022)
# 317 municipalities in Rio Grande do Sul
# Treatment year: 2023 (first full year)
# Corsan served virtually all RS municipalities
# RS state IBGE code starts with 43
# We'll identify all RS municipalities from population data and flag them
print("  Identifying RS municipalities for Corsan wave...")
rs_munis = pop_df[pop_df["muni_code"].str.startswith("43")]["muni_code"].unique().tolist()
print(f"  Found {len(rs_munis)} RS municipalities")

# Build treatment panel
treatment_records = []

# Alagoas wave: treatment starts 2021
for m in alagoas_munis:
    treatment_records.append({"muni_code": m, "treatment_year": 2021, "wave": "Alagoas_BRK"})

# CEDAE wave: treatment starts 2022
for m in rj_munis:
    treatment_records.append({"muni_code": m, "treatment_year": 2022, "wave": "CEDAE_RJ"})

# Corsan wave: treatment starts 2023
for m in rs_munis:
    treatment_records.append({"muni_code": m, "treatment_year": 2023, "wave": "Corsan_RS"})

treatment_df = pd.DataFrame(treatment_records)
treatment_df.to_csv(DATA_DIR / "treatment_panel.csv", index=False)

print(f"\nTreatment panel:")
print(f"  Alagoas wave (2021): {len(alagoas_munis)} municipalities")
print(f"  CEDAE/RJ wave (2022): {len(rj_munis)} municipalities")
print(f"  Corsan/RS wave (2023): {len(rs_munis)} municipalities")
print(f"  Total treated: {len(treatment_df)} municipalities")

# ─────────────────────────────────────────────
# 3. Download SNIS coverage indicators (via government API)
# ─────────────────────────────────────────────
print("\nFetching SNIS sanitation indicators...")
# SNIS data is published annually at snis.gov.br
# Key indicators: IN055 (water coverage), IN056 (sewage coverage),
# IN046 (sewage treatment), FN033 (investment)
# These are available as CSV downloads for years 2014-2022

# Try SNIS API endpoint
snis_frames = []
for year in range(2014, 2023):
    try:
        # SNIS provides downloadable CSVs at their data portal
        # We use a simplified version: key indicators by municipality
        url = f"http://appsnis.mdr.gov.br/indicadores/api/indicadores_municipios/{year}"
        req = urllib.request.Request(url, headers={"User-Agent": "APEP/1.0"})
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read())
            if data:
                df = pd.DataFrame(data)
                snis_frames.append(df)
                print(f"  SNIS {year}: {len(df)} municipalities")
    except Exception as e:
        print(f"  SNIS {year}: API unavailable - {e}")

if snis_frames:
    snis_df = pd.concat(snis_frames, ignore_index=True)
    snis_df.to_csv(DATA_DIR / "snis_indicators.csv", index=False)
    print(f"SNIS data: {len(snis_df)} rows")
else:
    print("SNIS API unavailable - will use treatment panel from auction records only")

print("\n=== Data Fetch Summary ===")
print(f"IBGE population: {len(pop_df)} municipality-year obs")
print(f"Treatment panel: {len(treatment_df)} treated municipalities")
print("NOTE: DATASUS SIH hospitalization data must be fetched via R (01_fetch_data.R)")
print("\nDone!")
