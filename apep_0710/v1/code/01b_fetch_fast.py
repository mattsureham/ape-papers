#!/usr/bin/env python3
"""
Fast ProZorro data fetch — smaller windows, fewer IDs per window.
Prioritizes getting BOTH pre-war and post-war data.
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

# Fewer, targeted windows — 1 month per year, pre+post
DATE_WINDOWS = [
    # Pre-war (3 windows = ~9K tenders)
    ("2018-06-01", "2018-06-30"),
    ("2019-06-01", "2019-06-30"),
    ("2020-06-01", "2020-06-30"),
    ("2021-06-01", "2021-06-30"),
    # Post-war (4 windows = ~12K tenders)
    ("2022-06-01", "2022-06-30"),
    ("2022-11-01", "2022-11-30"),
    ("2023-06-01", "2023-06-30"),
    ("2024-06-01", "2024-06-30"),
]

MIN_VALUE = 50_000
MAX_VALUE = 500_000
MAX_CONCURRENT = 25
BATCH_SIZE = 100
MAX_FEED_PAGES = 80  # ~8000 IDs per window

FRONTLINE_OBLASTS = {
    "Донецька область", "Луганська область", "Запорізька область",
    "Херсонська область", "Харківська область", "Миколаївська область",
}

OBLAST_MAP = {
    "Вінницька область": "Vinnytsia", "Волинська область": "Volyn",
    "Дніпропетровська область": "Dnipropetrovsk", "Донецька область": "Donetsk",
    "Житомирська область": "Zhytomyr", "Закарпатська область": "Zakarpattia",
    "Запорізька область": "Zaporizhzhia", "Івано-Франківська область": "Ivano-Frankivsk",
    "Київська область": "Kyiv Oblast", "Кіровоградська область": "Kirovohrad",
    "Луганська область": "Luhansk", "Львівська область": "Lviv",
    "Миколаївська область": "Mykolaiv", "Одеська область": "Odesa",
    "Полтавська область": "Poltava", "Рівненська область": "Rivne",
    "Сумська область": "Sumy", "Тернопільська область": "Ternopil",
    "Харківська область": "Kharkiv", "Херсонська область": "Kherson",
    "Хмельницька область": "Khmelnytskyi", "Черкаська область": "Cherkasy",
    "Чернівецька область": "Chernivtsi", "Чернігівська область": "Chernihiv",
    "м. Київ": "Kyiv City",
}


async def fetch_json(session, url, semaphore=None):
    """Fetch JSON with rate limit handling."""
    if semaphore:
        async with semaphore:
            return await _fetch(session, url)
    return await _fetch(session, url)


async def _fetch(session, url):
    for attempt in range(3):
        try:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=30)) as resp:
                if resp.status == 200:
                    return await resp.json()
                elif resp.status == 429:
                    await asyncio.sleep(3 * (attempt + 1))
                else:
                    return None
        except Exception:
            await asyncio.sleep(1)
    return None


def parse_tender(data):
    if not data or "data" not in data:
        return None
    d = data["data"]
    status = d.get("status", "")
    if status not in ("complete", "active", "active.awarded", "active.qualification"):
        return None
    value = d.get("value", {})
    amount = value.get("amount")
    if amount is None or amount < MIN_VALUE or amount > MAX_VALUE:
        return None

    date_str = d.get("date") or d.get("dateCreated") or d.get("dateModified")
    if not date_str:
        return None
    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None

    pe = d.get("procuringEntity", {})
    addr = pe.get("address", {})
    region_ua = addr.get("region", "")

    awards = d.get("awards", [])
    active_awards = [a for a in awards if a.get("status") == "active"]
    award_amount = active_awards[0].get("value", {}).get("amount") if active_awards else None

    bids = d.get("bids", [])
    valid_bids = [b for b in bids if b.get("status") in ("active", None)]
    n_bids = len(valid_bids)

    method_type = d.get("procurementMethodType", "")
    savings = (amount - award_amount) / amount if amount > 0 and award_amount is not None else None

    is_above = 1 if amount > 200_000 else 0
    is_competitive = 1 if method_type in ("aboveThresholdUA", "aboveThresholdEU",
                                           "competitiveDialogueUA", "competitiveDialogueEU") else 0
    is_frontline = 1 if region_ua in FRONTLINE_OBLASTS else 0
    is_post = 1 if dt >= datetime(2022, 2, 24, tzinfo=timezone.utc) else 0

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
        "region_en": OBLAST_MAP.get(region_ua, region_ua),
        "is_above": is_above,
        "is_post": is_post,
        "is_frontline": is_frontline,
        "status": status,
    }


async def main():
    print("=== Fast ProZorro Fetch ===", file=sys.stderr)

    # First, preserve existing data from the first fetch
    outfile = DATA_DIR / "prozorro_tenders.csv"
    existing_ids = set()
    existing_rows = []

    if outfile.exists():
        with open(outfile, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                existing_ids.add(row["tender_id"])
                existing_rows.append(row)
        print(f"  Existing data: {len(existing_rows)} tenders", file=sys.stderr)

    fieldnames = [
        "tender_id", "date", "year", "month", "value_uah", "award_uah",
        "savings_rate", "n_bids", "method_type", "is_competitive",
        "region_ua", "region_en", "is_above", "is_post", "is_frontline", "status",
    ]

    semaphore = asyncio.Semaphore(MAX_CONCURRENT)
    new_count = 0

    connector = aiohttp.TCPConnector(limit=MAX_CONCURRENT, force_close=True)
    async with aiohttp.ClientSession(connector=connector) as session:
        with open(outfile, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            # Write existing rows
            for row in existing_rows:
                writer.writerow(row)

            # Fetch new windows
            for start_date, end_date in DATE_WINDOWS:
                print(f"\n  Window {start_date} to {end_date}:", file=sys.stderr)

                start_dt = datetime.fromisoformat(start_date + "T00:00:00+00:00")
                end_dt = datetime.fromisoformat(end_date + "T23:59:59+00:00")
                start_ts = start_dt.timestamp()

                url = f"{BASE_URL}/tenders?limit={BATCH_SIZE}&offset={start_ts}"
                ids = []
                pages = 0

                while url and pages < MAX_FEED_PAGES:
                    result = await fetch_json(session, url)
                    if not result or not result.get("data"):
                        break
                    for item in result["data"]:
                        dm = item.get("dateModified", "")
                        try:
                            item_dt = datetime.fromisoformat(dm.replace("Z", "+00:00"))
                        except (ValueError, TypeError):
                            continue
                        if item_dt > end_dt:
                            url = None
                            break
                        if item_dt >= start_dt and item["id"] not in existing_ids:
                            ids.append(item["id"])
                    if url:
                        next_page = result.get("next_page", {})
                        url = next_page.get("uri")
                    pages += 1

                print(f"    {len(ids)} new IDs (skipped {pages} pages)", file=sys.stderr)

                # Fetch details
                kept = 0
                for i in range(0, len(ids), BATCH_SIZE):
                    batch = ids[i:i + BATCH_SIZE]
                    tasks = [fetch_json(session, f"{BASE_URL}/tenders/{tid}", semaphore) for tid in batch]
                    results = await asyncio.gather(*tasks)
                    for result in results:
                        row = parse_tender(result)
                        if row and row["tender_id"] not in existing_ids:
                            writer.writerow(row)
                            existing_ids.add(row["tender_id"])
                            kept += 1
                            new_count += 1

                    if (i // BATCH_SIZE) % 3 == 0:
                        print(f"    Fetched {min(i + len(batch), len(ids))}/{len(ids)}, kept {kept}", file=sys.stderr)

                print(f"    Window done: +{kept}", file=sys.stderr)

    total = len(existing_rows) + new_count
    print(f"\n=== DONE: {total} total tenders ({new_count} new) ===", file=sys.stderr)
    return total


if __name__ == "__main__":
    n = asyncio.run(main())
    if n < 500:
        print(f"FATAL: Only {n} tenders. Insufficient.", file=sys.stderr)
        sys.exit(1)
    print(f"SUCCESS: {n} tenders", file=sys.stderr)
