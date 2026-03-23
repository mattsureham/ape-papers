"""01b_fetch_disasters.py — Fetch natural disaster data from USGS + ReliefWeb
apep_0840: Competing News IV and Swiss Referendum Turnout

Uses USGS Earthquake API (free, no auth) to construct the competing-news
instrument. For each Swiss vote date, counts significant foreign earthquakes
in pre-vote windows, weighted by proximity to French/German media markets.
"""

import csv
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

# Centroids of key media-market regions (approximate)
# French media covers: France, Francophone Africa, Maghreb, Middle East (Levant)
# German media covers: Germany, Austria, Turkey (Gastarbeiter connection), Central/Eastern Europe
FRENCH_MEDIA_CENTROIDS = [
    (46.6, 2.2),     # France
    (14.5, -14.5),   # West Africa (Francophone)
    (34.0, 9.0),     # Tunisia/Maghreb
    (33.8, 35.8),    # Lebanon/Levant
    (4.0, 22.0),     # Central Africa (Francophone)
]

GERMAN_MEDIA_CENTROIDS = [
    (51.2, 10.4),    # Germany
    (47.5, 14.5),    # Austria
    (39.9, 32.9),    # Turkey
    (52.2, 21.0),    # Poland/Central Europe
    (44.0, 21.0),    # Balkans
]

def haversine_km(lat1, lon1, lat2, lon2):
    """Great-circle distance in km."""
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def media_salience(lat, lon, centroids):
    """Inverse-distance-weighted salience to a set of media centroids.
    Returns a score: higher = more salient in that media market."""
    if lat is None or lon is None:
        return 0.0
    min_dist = min(haversine_km(lat, lon, clat, clon) for clat, clon in centroids)
    # Inverse distance with floor to avoid division by zero
    return 1000.0 / max(min_dist, 100.0)

def load_vote_dates():
    dates = set()
    with open(os.path.join(DATA_DIR, "referendum_raw.csv"), "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            dates.add(row["votedate"])
    return sorted(dates)

def fetch_usgs_earthquakes(start_date, end_date, min_magnitude=5.0):
    """Query USGS FDSNWS for earthquakes in date range."""
    base_url = "https://earthquake.usgs.gov/fdsnws/event/1/query"
    params = {
        "format": "geojson",
        "starttime": start_date.strftime("%Y-%m-%d"),
        "endtime": end_date.strftime("%Y-%m-%d"),
        "minmagnitude": str(min_magnitude),
        "orderby": "magnitude",
    }
    url = f"{base_url}?{urllib.parse.urlencode(params)}"

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "APEP-Research/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            features = data.get("features", [])
            earthquakes = []
            for f in features:
                props = f.get("properties", {})
                coords = f.get("geometry", {}).get("coordinates", [None, None, None])
                earthquakes.append({
                    "time": props.get("time"),
                    "magnitude": props.get("mag"),
                    "place": props.get("place", ""),
                    "longitude": coords[0],
                    "latitude": coords[1],
                    "depth_km": coords[2],
                    "tsunami": props.get("tsunami", 0),
                })
            return earthquakes
    except Exception as e:
        print(f"  Warning: USGS query failed: {e}")
        return []

def main():
    vote_dates = load_vote_dates()
    print(f"Processing {len(vote_dates)} vote dates")

    all_results = []
    earthquake_details = []

    for i, vdate_str in enumerate(vote_dates):
        vdate = datetime.strptime(vdate_str, "%Y-%m-%d")

        # Fetch earthquakes for multiple windows
        for window_days, label in [(7, "7day"), (14, "14day")]:
            window_start = vdate - timedelta(days=window_days)
            window_end = vdate - timedelta(days=1)

            quakes = fetch_usgs_earthquakes(window_start, window_end, min_magnitude=5.0)
            time.sleep(0.5)  # Be polite to USGS

            # Also get very large earthquakes (M6.5+) for stronger instrument
            large_quakes = [q for q in quakes if q["magnitude"] and q["magnitude"] >= 6.5]

            # Compute salience scores for French and German media
            fr_salience_total = sum(
                media_salience(q["latitude"], q["longitude"], FRENCH_MEDIA_CENTROIDS)
                * (q["magnitude"] or 5.0)  # weight by magnitude
                for q in quakes
            )
            de_salience_total = sum(
                media_salience(q["latitude"], q["longitude"], GERMAN_MEDIA_CENTROIDS)
                * (q["magnitude"] or 5.0)
                for q in quakes
            )
            fr_salience_large = sum(
                media_salience(q["latitude"], q["longitude"], FRENCH_MEDIA_CENTROIDS)
                * (q["magnitude"] or 6.5)
                for q in large_quakes
            )
            de_salience_large = sum(
                media_salience(q["latitude"], q["longitude"], GERMAN_MEDIA_CENTROIDS)
                * (q["magnitude"] or 6.5)
                for q in large_quakes
            )

            for lang, salience, salience_large in [
                ("fr", fr_salience_total, fr_salience_large),
                ("de", de_salience_total, de_salience_large),
            ]:
                all_results.append({
                    "vote_date": vdate_str,
                    "source_lang": lang,
                    "window": label,
                    "n_earthquakes": len(quakes),
                    "n_large_earthquakes": len(large_quakes),
                    "max_magnitude": max((q["magnitude"] for q in quakes), default=0),
                    "salience_score": round(salience, 4),
                    "salience_large": round(salience_large, 4),
                    "total_magnitude": round(sum(q["magnitude"] or 0 for q in quakes), 2),
                })

            # Save earthquake details for first window
            if label == "7day":
                for q in quakes:
                    earthquake_details.append({
                        "vote_date": vdate_str,
                        "eq_time": q["time"],
                        "magnitude": q["magnitude"],
                        "place": q["place"],
                        "latitude": q["latitude"],
                        "longitude": q["longitude"],
                        "fr_salience": round(media_salience(q["latitude"], q["longitude"], FRENCH_MEDIA_CENTROIDS) * (q["magnitude"] or 5.0), 4),
                        "de_salience": round(media_salience(q["latitude"], q["longitude"], GERMAN_MEDIA_CENTROIDS) * (q["magnitude"] or 5.0), 4),
                    })

        n_7d = len([q for q in quakes])  # from last iteration
        print(f"[{i+1}/{len(vote_dates)}] {vdate_str}: {len(quakes)} earthquakes (M5.0+), "
              f"fr_sal={all_results[-2]['salience_score']:.1f}, de_sal={all_results[-1]['salience_score']:.1f}")

    # Save results
    outpath = os.path.join(DATA_DIR, "disaster_instrument.csv")
    with open(outpath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(all_results[0].keys()))
        writer.writeheader()
        writer.writerows(all_results)
    print(f"\nSaved {len(all_results)} rows to disaster_instrument.csv")

    # Save earthquake details
    detail_path = os.path.join(DATA_DIR, "earthquake_details.csv")
    with open(detail_path, "w", newline="") as f:
        if earthquake_details:
            writer = csv.DictWriter(f, fieldnames=list(earthquake_details[0].keys()))
            writer.writeheader()
            writer.writerows(earthquake_details)
    print(f"Saved {len(earthquake_details)} earthquake details to earthquake_details.csv")


if __name__ == "__main__":
    main()
