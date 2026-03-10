#!/usr/bin/env python3
"""
00b_fetch_epc.py — Download EPC data from GOV.UK Find Energy Certificate service
apep_0477 v2: Do Energy Labels Move Markets?

This script downloads domestic EPC certificates by querying the GOV.UK
find-energy-certificate service for postcodes found in the Land Registry data.
The service is publicly accessible without registration.

Strategy:
1. Load unique postcodes from Land Registry parquet
2. Query GOV.UK for certificates at each postcode
3. Parse HTML responses to extract certificate details
4. Save as parquet for downstream R analysis
"""

import os
import re
import time
import json
import logging
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.request import urlopen, Request
from urllib.parse import quote_plus
from urllib.error import HTTPError, URLError
from html.parser import HTMLParser

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
EPC_PARQUET = os.path.join(DATA_DIR, "epc_domestic.parquet")
LR_PARQUET = os.path.join(DATA_DIR, "land_registry_2015_2025.parquet")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
log = logging.getLogger(__name__)


class CertificateListParser(HTMLParser):
    """Parse the search results page to extract certificate URLs."""

    def __init__(self):
        super().__init__()
        self.cert_urls = []
        self.in_link = False

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            attrs_dict = dict(attrs)
            href = attrs_dict.get("href", "")
            if "/energy-certificate/" in href:
                self.cert_urls.append(href)


class CertificateDetailParser(HTMLParser):
    """Parse an individual certificate page to extract key fields."""

    def __init__(self):
        super().__init__()
        self.data = {}
        self._capture_key = None
        self._capture_val = False
        self._in_key = False
        self._in_val = False
        self._current_key = ""
        self._current_val = ""
        self._in_desc = False
        self._desc_text = ""

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        cls = attrs_dict.get("class", "")

        if tag == "dt" and "govuk-summary-list__key" in cls:
            self._in_key = True
            self._current_key = ""
        elif tag == "dd" and "govuk-summary-list__value" in cls:
            self._in_val = True
            self._current_val = ""
        elif tag == "desc" and attrs_dict.get("id", "") == "svg-desc":
            self._in_desc = True
            self._desc_text = ""

    def handle_endtag(self, tag):
        if tag == "dt" and self._in_key:
            self._in_key = False
        elif tag == "dd" and self._in_val:
            self._in_val = False
            key = self._current_key.strip().lower()
            val = self._current_val.strip()
            if key and val:
                self.data[key] = val
        elif tag == "desc" and self._in_desc:
            self._in_desc = False
            # Parse "energy rating is D with a score of 58"
            m = re.search(r"energy rating is (\w) with a score of (\d+)", self._desc_text)
            if m:
                self.data["epc_band"] = m.group(1)
                self.data["epc_score"] = int(m.group(2))

    def handle_data(self, data):
        if self._in_key:
            self._current_key += data
        elif self._in_val:
            self._current_val += data
        elif self._in_desc:
            self._desc_text += data


def fetch_certificates_for_postcode(postcode, base_url="https://find-energy-certificate.service.gov.uk"):
    """Fetch all domestic EPC certificates for a given postcode."""
    url = f"{base_url}/find-a-certificate/search-by-postcode?postcode={quote_plus(postcode)}"

    try:
        req = Request(url, headers={"User-Agent": "APEP-Research/1.0"})
        with urlopen(req, timeout=15) as resp:
            html = resp.read().decode("utf-8", errors="replace")
    except (HTTPError, URLError, TimeoutError):
        return []

    # Parse search results to get certificate URLs
    parser = CertificateListParser()
    parser.feed(html)

    if not parser.cert_urls:
        return []

    certificates = []
    for cert_path in parser.cert_urls[:20]:  # Cap at 20 per postcode
        cert_url = f"{base_url}{cert_path}"
        try:
            req2 = Request(cert_url, headers={"User-Agent": "APEP-Research/1.0"})
            with urlopen(req2, timeout=15) as resp2:
                cert_html = resp2.read().decode("utf-8", errors="replace")

            detail_parser = CertificateDetailParser()
            detail_parser.feed(cert_html)
            d = detail_parser.data

            if "epc_score" in d:
                cert_id = cert_path.split("/")[-1]
                certificates.append({
                    "LMK_KEY": cert_id,
                    "POSTCODE": postcode,
                    "CURRENT_ENERGY_EFFICIENCY": d.get("epc_score"),
                    "CURRENT_ENERGY_RATING": d.get("epc_band", ""),
                    "PROPERTY_TYPE": d.get("property type", ""),
                    "TOTAL_FLOOR_AREA": d.get("total floor area", ""),
                    "TENURE": d.get("tenure", ""),
                    "INSPECTION_DATE": "",
                    "LODGEMENT_DATE": d.get("date of assessment", ""),
                    "ADDRESS1": d.get("address", "").split(",")[0] if "address" in d else "",
                    "ADDRESS2": d.get("address", "").split(",")[1].strip() if "address" in d and "," in d.get("address", "") else "",
                })

            time.sleep(0.1)  # Polite delay between certificate fetches
        except Exception:
            continue

    return certificates


def main():
    if os.path.exists(EPC_PARQUET):
        log.info(f"EPC parquet already exists at {EPC_PARQUET}")
        df = pd.read_parquet(EPC_PARQUET)
        log.info(f"EPC data: {len(df):,} certificates")
        return

    log.info("Loading Land Registry postcodes...")
    lr = pd.read_parquet(LR_PARQUET, columns=["postcode"])
    postcodes = lr["postcode"].dropna().str.strip().str.upper().unique()
    log.info(f"Unique postcodes in LR data: {len(postcodes):,}")

    # Sample postcodes to make this feasible (target ~100K certs)
    # Average ~15-20 addresses per postcode, ~3-5 certs per address
    # So ~5000 postcodes should give us ~75K-100K certificates
    import numpy as np
    np.random.seed(42)
    if len(postcodes) > 8000:
        postcodes = np.random.choice(postcodes, size=8000, replace=False)
        log.info(f"Sampled {len(postcodes):,} postcodes for download")

    all_certs = []
    n_done = 0
    n_total = len(postcodes)

    # Use ThreadPoolExecutor for parallel downloads
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {
            executor.submit(fetch_certificates_for_postcode, pc): pc
            for pc in postcodes
        }

        for future in as_completed(futures):
            pc = futures[future]
            n_done += 1
            try:
                certs = future.result()
                all_certs.extend(certs)
            except Exception as e:
                pass

            if n_done % 200 == 0:
                log.info(f"  Progress: {n_done}/{n_total} postcodes, {len(all_certs):,} certificates")

            # Polite rate limiting
            time.sleep(0.05)

    log.info(f"Downloaded {len(all_certs):,} certificates from {n_done} postcodes")

    if len(all_certs) == 0:
        raise RuntimeError("No EPC certificates downloaded. Check network connectivity.")

    df = pd.DataFrame(all_certs)

    # Type conversions
    df["CURRENT_ENERGY_EFFICIENCY"] = pd.to_numeric(df["CURRENT_ENERGY_EFFICIENCY"], errors="coerce")

    # Parse floor area
    df["TOTAL_FLOOR_AREA"] = df["TOTAL_FLOOR_AREA"].str.extract(r"([\d.]+)").astype(float)

    # Parse dates
    for col in ["INSPECTION_DATE", "LODGEMENT_DATE"]:
        df[col] = pd.to_datetime(df[col], errors="coerce", format="mixed")

    # Clean postcode
    df["postcode"] = df["POSTCODE"].str.strip().str.upper()

    log.info(f"Final EPC dataset: {len(df):,} certificates")
    log.info(f"EPC score range: {df['CURRENT_ENERGY_EFFICIENCY'].min()}-{df['CURRENT_ENERGY_EFFICIENCY'].max()}")

    df.to_parquet(EPC_PARQUET, index=False)
    log.info(f"Saved: {EPC_PARQUET}")


if __name__ == "__main__":
    main()
