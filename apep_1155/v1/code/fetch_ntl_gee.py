"""
fetch_ntl_gee.py — Extract VIIRS annual nightlights for El Salvador municipalities
Uses Google Earth Engine to bypass HDF5/BlackMarbleR issues
"""
import ee
import json
import csv
import os

# Initialize GEE
ee.Initialize(project="scl-librechat")

# Load VIIRS annual composites (v2.2)
viirs = ee.ImageCollection("NOAA/VIIRS/DNB/ANNUAL_V22")

# Load El Salvador admin boundaries (GADM level 2 = municipalities)
# Use FAO GAUL level 2 as alternative
gaul = ee.FeatureCollection("FAO/GAUL/2015/level2")
el_salvador = gaul.filter(ee.Filter.eq("ADM0_NAME", "El Salvador"))

print(f"El Salvador municipalities in GAUL: {el_salvador.size().getInfo()}")

# Years to extract
years = list(range(2014, 2025))  # 2014-2024

results = []

for year in years:
    print(f"Processing year {year}...")

    # Filter to the specific year
    img = viirs.filter(ee.Filter.calendarRange(year, year, 'year')).first()

    if img is None:
        print(f"  No data for {year}")
        continue

    # Select the average radiance band
    avg_rad = img.select('average')

    # Reduce regions: compute mean radiance per municipality
    stats = avg_rad.reduceRegions(
        collection=el_salvador,
        reducer=ee.Reducer.mean().combine(
            ee.Reducer.stdDev(), sharedInputs=True
        ),
        scale=500  # VIIRS resolution ~500m
    )

    # Get results
    features = stats.getInfo()['features']

    for feat in features:
        props = feat['properties']
        results.append({
            'year': year,
            'adm1_name': props.get('ADM1_NAME', ''),
            'adm2_name': props.get('ADM2_NAME', ''),
            'adm2_code': props.get('ADM2_CODE', ''),
            'ntl_mean': props.get('mean', None),
            'ntl_sd': props.get('stdDev', None)
        })

    print(f"  Extracted {len(features)} municipalities")

# Save results as CSV
output_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'ntl_gee.csv')
with open(output_path, 'w', newline='') as f:
    if results:
        writer = csv.DictWriter(f, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)

print(f"\nSaved {len(results)} rows to {output_path}")
print(f"Years covered: {min(r['year'] for r in results)} to {max(r['year'] for r in results)}")
print(f"Municipalities per year: {len(results) // len(years)}")
