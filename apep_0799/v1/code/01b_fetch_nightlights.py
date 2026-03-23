"""
01b_fetch_nightlights.py — Extract district-level nightlights from already-downloaded
VNP46A4 HDF5 tiles. Uses correct V2 structure: VIIRS_Grid_DNB_2d with lat/lon.

Paper: Darkness by Decree (apep_0799)
"""

import os
import sys
import re
import numpy as np
import geopandas as gpd
import h5py
import rasterio
from rasterio.transform import from_bounds
from rasterio.crs import CRS
from rasterstats import zonal_stats
import pandas as pd
from pathlib import Path

os.chdir(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
print("Working directory:", os.getcwd())

CACHE_DIR = Path("data/viirs_cache")

# ── Load district boundaries ────────────────────────────────────────────
print("\n=== Loading India Districts ===")
districts = gpd.read_file("data/india_districts.gpkg").to_crs(epsg=4326)
print(f"Loaded {len(districts)} districts")


def h5_to_geotiff(h5_path, out_tif):
    """Convert VNP46A4 V2 HDF5 tile to GeoTIFF."""
    with h5py.File(h5_path, 'r') as f:
        # V2 structure: HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/
        try:
            grid = f['HDFEOS']['GRIDS']['VIIRS_Grid_DNB_2d']
        except KeyError:
            # Try V1 structure
            try:
                grid = f['HDFEOS']['GRIDS']['VNP_Grid_DNB']
            except KeyError:
                grids = list(f['HDFEOS']['GRIDS'].keys())
                raise ValueError(f"Unknown grid structure. Available: {grids}")

        data_fields = grid['Data Fields']

        # Use AllAngle_Composite_Snow_Free (best coverage)
        ds_name = 'AllAngle_Composite_Snow_Free'
        if ds_name not in data_fields:
            for candidate in ['NearNadir_Composite_Snow_Free',
                            'AllAngle_Composite_Snow_Covered']:
                if candidate in data_fields:
                    ds_name = candidate
                    break

        data = data_fields[ds_name][:]
        fill_val = float(data_fields[ds_name].attrs.get('_FillValue', [-999.9])[0])

        # Read lat/lon arrays (V2 provides these directly)
        lat = data_fields['lat'][:]
        lon = data_fields['lon'][:]

    # Process data
    data = data.astype(np.float64)
    data[data <= fill_val + 0.1] = np.nan
    data[data < 0] = np.nan

    # Build geographic extent from lat/lon arrays
    lat_min, lat_max = float(np.nanmin(lat)), float(np.nanmax(lat))
    lon_min, lon_max = float(np.nanmin(lon)), float(np.nanmax(lon))

    nrows, ncols = data.shape
    transform = from_bounds(lon_min, lat_min, lon_max, lat_max, ncols, nrows)

    with rasterio.open(
        out_tif, 'w', driver='GTiff',
        height=nrows, width=ncols, count=1, dtype='float64',
        crs=CRS.from_epsg(4326), transform=transform, nodata=np.nan
    ) as dst:
        dst.write(data, 1)

    valid = np.count_nonzero(~np.isnan(data))
    return valid


def extract_year_from_filename(fname):
    """Extract data year from VNP46A4 filename (e.g., VNP46A4.A2013001... → 2013)."""
    m = re.search(r'VNP46A4\.A(\d{4})\d{3}', fname)
    return int(m.group(1)) if m else None


# ── Process all downloaded tiles ────────────────────────────────────────
print("\n=== Processing Downloaded HDF5 Tiles ===")

# Collect all h5 files, group by data year
h5_files_by_year = {}
for year_dir in sorted(CACHE_DIR.iterdir()):
    if not year_dir.is_dir():
        continue
    for h5_file in year_dir.glob("*.h5"):
        data_year = extract_year_from_filename(h5_file.name)
        if data_year is not None:
            h5_files_by_year.setdefault(data_year, []).append(h5_file)

print(f"Found data for years: {sorted(h5_files_by_year.keys())}")
for yr, files in sorted(h5_files_by_year.items()):
    print(f"  {yr}: {len(files)} tiles")

# Only keep V2 files (larger, more recent processing)
# Deduplicate: for each tile position (e.g., h24v06), keep only V2 if both exist
def tile_key(fname):
    m = re.search(r'(h\d{2}v\d{2})', fname)
    return m.group(1) if m else fname

for yr in h5_files_by_year:
    files = h5_files_by_year[yr]
    # Group by tile
    by_tile = {}
    for f in files:
        key = tile_key(f.name)
        by_tile.setdefault(key, []).append(f)
    # Keep largest file per tile (V2 is bigger)
    deduped = []
    for key, tile_files in by_tile.items():
        deduped.append(max(tile_files, key=lambda x: x.stat().st_size))
    h5_files_by_year[yr] = deduped

print("\nAfter dedup:")
for yr, files in sorted(h5_files_by_year.items()):
    print(f"  {yr}: {len(files)} unique tiles")

# ── Convert and extract zonal stats ─────────────────────────────────────
all_results = []

for year in sorted(h5_files_by_year.keys()):
    if year < 2012 or year > 2022:
        continue

    h5_files = h5_files_by_year[year]
    print(f"\n{'='*60}")
    print(f"Year: {year} ({len(h5_files)} tiles)")

    tif_files = []
    for h5_file in h5_files:
        tif_path = h5_file.with_suffix('.tif')
        if tif_path.exists() and tif_path.stat().st_size > 1000:
            tif_files.append(str(tif_path))
            continue
        try:
            valid = h5_to_geotiff(str(h5_file), str(tif_path))
            tif_files.append(str(tif_path))
            print(f"  {h5_file.name}: {valid:,} valid pixels")
        except Exception as e:
            print(f"  ERROR {h5_file.name}: {e}")

    if not tif_files:
        print(f"  WARNING: No valid rasters for {year}")
        continue

    # Zonal statistics
    print(f"  Computing zonal stats for {len(tif_files)} tiles...")
    district_sums = np.zeros(len(districts))
    district_counts = np.zeros(len(districts))

    for tif_path in tif_files:
        try:
            stats = zonal_stats(
                districts, tif_path,
                stats=['mean', 'count'],
                nodata=np.nan,
                all_touched=True
            )
            for i, s in enumerate(stats):
                if s['mean'] is not None and s['count'] is not None and s['count'] > 0:
                    district_sums[i] += s['mean'] * s['count']
                    district_counts[i] += s['count']
        except Exception as e:
            print(f"    Error: {e}")

    district_means = np.where(
        district_counts > 0, district_sums / district_counts, np.nan
    )

    year_df = pd.DataFrame({
        'NAME_1': districts['NAME_1'].values,
        'NAME_2': districts['NAME_2'].values,
        'GID_2': districts['GID_2'].values,
        'year': year,
        'ntl_mean': district_means,
        'ntl_pixel_count': district_counts.astype(int)
    })

    valid_n = year_df['ntl_mean'].notna().sum()
    mean_ntl = year_df['ntl_mean'].mean()
    print(f"  Result: {valid_n}/{len(districts)} districts, mean NTL = {mean_ntl:.3f}")

    all_results.append(year_df)

# ── Save ────────────────────────────────────────────────────────────────
if not all_results:
    print("FATAL: No nightlights data extracted.")
    sys.exit(1)

ntl_panel = pd.concat(all_results, ignore_index=True)
ntl_panel.to_csv("data/ntl_annual.csv", index=False)

print(f"\n=== DONE ===")
print(f"Saved {len(ntl_panel)} district-year observations")
print(f"Years: {sorted(ntl_panel['year'].unique())}")
print(f"Districts with data: {ntl_panel.loc[ntl_panel['ntl_mean'].notna(), 'GID_2'].nunique()}")
print(f"\nSummary by year:")
print(ntl_panel.groupby('year')['ntl_mean'].agg(['count', 'mean', 'std']).round(3))
