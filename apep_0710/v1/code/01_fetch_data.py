#!/usr/bin/env python3
"""
Fetch ProZorro procurement data via public API.

Strategy: Use the feed endpoint to collect tender IDs across date windows,
then fetch full details in parallel batches. Filter to tenders near the
UAH 200,000 threshold (50K-500K range).

Data source: https://public.api.openprocurement.org/api/2.5/
"""

import asyncio
import aiohttp
import json
import csv
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_URL = "https://public.api.openprocurement.org/api/2.5"
DATA_DIR = Path(__file__).parent.parent / "data"

# Target date windows: sample from specific months across the study period
# Pre-war: 2017-2021, Post-war: 2022-2024
DATE_WINDOWS = [
    # Pre-war samples (2 months per year)
    ("2017-03-01", "2017-04-30"),
    ("2017-09-01", "2017-10-31"),
    ("2018-03-01", "2018-04-30"),
    ("2018-09-01", "2018-10-31"),
    ("2019-03-01", "2019-04-30"),
    ("2019-09-01", "2019-10-31"),
    ("2020-03-01", "2020-04-30"),
    ("2020-09-01", "2020-10-31"),
    ("2021-03-01", "2021-04-30"),
    ("2021-09-01", "2021-10-31"),
    # Post-war samples
    ("2022-03-01", "2022-04-30"),
    ("2022-09-01", "2022-10-31"),
    ("2023-03-01", "2023-04-30"),
    ("2023-09-01", "2023-10-31"),
    ("2024-03-01", "2024-04-30"),
    ("2024-09-01", "2024-10-31"),
]

# Value range for threshold analysis (UAH)
MIN_VALUE = 50_000
MAX_VALUE = 500_000

# Concurrency settings
MAX_CONCURRENT = 20
BATCH_SIZE = 100
MAX_FEED_PAGES = 150  # Per date window — approx 15,000 IDs per window

# Frontline oblasts (Ukrainian names as they appear in API)
FRONTLINE_OBLASTS = {
    "Донецька область",
    "Луганська область",
    "Запорізька область",
    "Херсонська область",
    "Харківська область",
    "Миколаївська область",
}

# All 25 oblasts for reference
OBLAST_MAP = {
    "Вінницька область": "Vinnytsia",
    "Волинська область": "Volyn",
    "Дніпропетровська область": "Dnipropetrovsk",
    "Донецька область": "Donetsk",
    "Житомирська область": "Zhytomyr",
    "Закарпатська область": "Zakarpattia",
    "Запорізька область": "Zaporizhzhia",
    "Івано-Франківська область": "Ivano-Frankivsk",
    "Київська область": "Kyiv Oblast",
    "Кіровоградська область": "Kirovohrad",
    "Луганська область": "Luhansk",
    "Львівська область": "Lviv",
    "Миколаївська область": "Mykolaiv",
    "Одеська область": "Odesa",
    "Полтавська область": "Poltava",
    "Рівненська область": "Rivne",
    "Сумська область": "Sumy",
    "Тернопільська область": "Ternopil",
    "Харківська область": "Kharkiv",
    "Херсонська область": "Kherson",
    "Хмельницька область": "Khmelnytskyi",
    "Черкаська область": "Cherkasy",
    "Чернівецька область": "Chernivtsi",
    "Чернігівська область": "Chernihiv",
    "м. Київ": "Kyiv City",
}


async def fetch_feed_page(session, url):
    """Fetch one page of the tender feed."""
    try:
        async with session.get(url, timeout=aiohttp.ClientTimeout(total=30)) as resp:
            if resp.status == 200:
                return await resp.json()
            elif resp.status == 429:
                await asyncio.sleep(5)
                return await fetch_feed_page(session, url)
            else:
                print(f"  Feed error {resp.status}: {url[:80]}", file=sys.stderr)
                return None
    except Exception as e:
        print(f"  Feed exception: {e}", file=sys.stderr)
        return None


async def fetch_tender(session, tender_id, semaphore):
    """Fetch full tender details."""
    url = f"{BASE_URL}/tenders/{tender_id}"
    async with semaphore:
        try:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=30)) as resp:
                if resp.status == 200:
                    return await resp.json()
                elif resp.status == 429:
                    await asyncio.sleep(2)
                    return await fetch_tender(session, tender_id, semaphore)
                elif resp.status == 404:
                    return None
                else:
                    return None
        except Exception:
            return None


def parse_tender(data):
    """Extract relevant fields from a tender response."""
    if not data or "data" not in data:
        return None

    d = data["data"]
    status = d.get("status", "")
    if status not in ("complete", "active", "active.awarded", "active.qualification"):
        return None

    value = d.get("value", {})
    amount = value.get("amount")
    if amount is None:
        return None

    # Filter to our value range
    if amount < MIN_VALUE or amount > MAX_VALUE:
        return None

    # Extract date
    date_str = d.get("date") or d.get("dateCreated") or d.get("dateModified")
    if not date_str:
        return None

    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None

    # Extract region
    pe = d.get("procuringEntity", {})
    addr = pe.get("address", {})
    region_ua = addr.get("region", "")

    # Extract award info
    awards = d.get("awards", [])
    active_awards = [a for a in awards if a.get("status") == "active"]
    award_amount = None
    if active_awards:
        award_amount = active_awards[0].get("value", {}).get("amount")

    # Count bids
    bids = d.get("bids", [])
    valid_bids = [b for b in bids if b.get("status") in ("active", None)]
    n_bids = len(valid_bids)

    # Procurement method
    method_type = d.get("procurementMethodType", "")

    # Price savings
    savings = None
    if amount > 0 and award_amount is not None:
        savings = (amount - award_amount) / amount

    # Classification
    is_above = 1 if amount > 200_000 else 0
    is_competitive = 1 if method_type in ("aboveThresholdUA", "aboveThresholdEU",
                                           "competitiveDialogueUA", "competitiveDialogueEU") else 0
    is_frontline = 1 if region_ua in FRONTLINE_OBLASTS else 0
    is_post = 1 if dt >= datetime(2022, 2, 24, tzinfo=timezone.utc) else 0

    region_en = OBLAST_MAP.get(region_ua, region_ua)

    return {
        "tender_id": d.get("tenderID", d.get("id", "")),
        "date": dt.strftime("%Y-%m-%d"),
        "year": dt.year,
        "month": dt.month,
        "value_uah": round(amount, 2),
        "award_uah": round(award_amount, 2) if award_amount else "",
        "savings_rate": round(savings, 4) if savings is not None else "",
        "n_bids": n_bids,
        "method_type": method_type,
        "is_competitive": is_competitive,
        "region_ua": region_ua,
        "region_en": region_en,
        "is_above": is_above,
        "is_post": is_post,
        "is_frontline": is_frontline,
        "status": status,
    }


async def collect_ids_for_window(session, start_date, end_date):
    """Collect tender IDs from the feed within a date window."""
    start_dt = datetime.fromisoformat(start_date + "T00:00:00+00:00")
    end_dt = datetime.fromisoformat(end_date + "T23:59:59+00:00")

    # Convert to Unix timestamp for offset
    start_ts = start_dt.timestamp()

    # Use the feed with offset based on timestamp
    url = f"{BASE_URL}/tenders?limit={BATCH_SIZE}&offset={start_ts}"

    ids = []
    pages = 0
    while url and pages < MAX_FEED_PAGES:
        result = await fetch_feed_page(session, url)
        if not result or not result.get("data"):
            break

        for item in result["data"]:
            dm = item.get("dateModified", "")
            try:
                item_dt = datetime.fromisoformat(dm.replace("Z", "+00:00"))
            except (ValueError, TypeError):
                continue

            if item_dt > end_dt:
                # Past our window
                return ids
            if item_dt >= start_dt:
                ids.append(item["id"])

        # Next page
        next_page = result.get("next_page", {})
        url = next_page.get("uri")
        pages += 1

        if pages % 20 == 0:
            print(f"    Page {pages}, {len(ids)} IDs so far...", file=sys.stderr)

    return ids


async def process_window(session, semaphore, start_date, end_date, writer, stats):
    """Process one date window: collect IDs, fetch details, write to CSV."""
    print(f"\n  Window {start_date} to {end_date}:", file=sys.stderr)

    # Collect IDs
    ids = await collect_ids_for_window(session, start_date, end_date)
    print(f"    Collected {len(ids)} tender IDs", file=sys.stderr)

    if not ids:
        return

    # Fetch details in batches
    kept = 0
    for i in range(0, len(ids), BATCH_SIZE):
        batch = ids[i:i + BATCH_SIZE]
        tasks = [fetch_tender(session, tid, semaphore) for tid in batch]
        results = await asyncio.gather(*tasks)

        for result in results:
            row = parse_tender(result)
            if row:
                writer.writerow(row)
                kept += 1
                stats["total"] += 1

        if (i // BATCH_SIZE) % 5 == 0:
            print(f"    Fetched {i + len(batch)}/{len(ids)}, kept {kept}", file=sys.stderr)

    print(f"    Window done: kept {kept}/{len(ids)}", file=sys.stderr)


async def main():
    print("=== ProZorro Data Fetch ===", file=sys.stderr)
    print(f"Value range: {MIN_VALUE:,} - {MAX_VALUE:,} UAH", file=sys.stderr)
    print(f"Date windows: {len(DATE_WINDOWS)}", file=sys.stderr)

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    outfile = DATA_DIR / "prozorro_tenders.csv"

    fieldnames = [
        "tender_id", "date", "year", "month", "value_uah", "award_uah",
        "savings_rate", "n_bids", "method_type", "is_competitive",
        "region_ua", "region_en", "is_above", "is_post", "is_frontline", "status",
    ]

    semaphore = asyncio.Semaphore(MAX_CONCURRENT)
    stats = {"total": 0}

    connector = aiohttp.TCPConnector(limit=MAX_CONCURRENT, force_close=True)
    async with aiohttp.ClientSession(connector=connector) as session:
        with open(outfile, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for start_date, end_date in DATE_WINDOWS:
                await process_window(session, semaphore, start_date, end_date, writer, stats)

    print(f"\n=== DONE: {stats['total']} tenders saved to {outfile} ===", file=sys.stderr)
    return stats["total"]


if __name__ == "__main__":
    n = asyncio.run(main())
    if n < 100:
        print(f"FATAL: Only {n} tenders fetched. Data insufficient.", file=sys.stderr)
        sys.exit(1)
    print(f"SUCCESS: {n} tenders", file=sys.stderr)
