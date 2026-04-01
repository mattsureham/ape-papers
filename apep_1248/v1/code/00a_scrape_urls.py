"""Scrape DANE GEIH download URLs from the microdata catalog pages."""
import requests
import re
import json
import os

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
os.makedirs(DATA_DIR, exist_ok=True)

catalog_ids = {
    "2010": 205, "2011": 182, "2012": 77,
    "2013": 68,  "2014": 328, "2015": 356, "2016": 427
}

months_es = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
]

all_urls = {}

for year, cat_id in catalog_ids.items():
    print(f"Scraping catalog {cat_id} for {year}...")
    url = f"https://microdatos.dane.gov.co/index.php/catalog/{cat_id}/get_microdata"

    try:
        resp = requests.get(url, timeout=60)
        html = resp.text
    except Exception as e:
        print(f"  ERROR: {e}")
        continue

    # Extract mostrarModal calls: mostrarModal('Filename.zip' , 'URL ')
    modals = re.findall(r"mostrarModal\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)", html)

    year_urls = {}
    for filename, download_url in modals:
        filename = filename.strip()
        download_url = download_url.strip()

        # Only want the .zip files (SPSS format), not .txt.zip or .csv.zip
        if filename.endswith('.zip') and '.txt.' not in filename and '.csv.' not in filename:
            # Match to month
            for m_idx, month_name in enumerate(months_es, 1):
                if filename.lower().startswith(month_name.lower()):
                    key = f"{m_idx:02d}"
                    if key not in year_urls:  # Take first match (avoid duplicates)
                        year_urls[key] = {
                            "filename": filename,
                            "url": download_url,
                            "month_name": month_name
                        }
                    break

    all_urls[year] = year_urls
    print(f"  Found {len(year_urls)} monthly SPSS downloads")

# Save URL manifest
manifest_path = os.path.join(DATA_DIR, "geih_download_urls.json")
with open(manifest_path, "w") as f:
    json.dump(all_urls, f, indent=2)

print(f"\nSaved URL manifest: {manifest_path}")
print(f"Total year-months: {sum(len(v) for v in all_urls.values())}")
