"""
fetch_viirs.py — Download and extract VIIRS annual nightlights for El Salvador municipalities.
Uses NASA LAADS DAAC API with blackmarbler-compatible logic,
then reads HDF5 with h5py and extracts zonal statistics.
"""

import os
import sys
import json
import requests
import tempfile
import numpy as np

# Check dependencies
try:
    import h5py
except ImportError:
    os.system("pip install h5py")
    import h5py

try:
    import geopandas as gpd
except ImportError:
    os.system("pip install geopandas")
    import geopandas as gpd

try:
    from rasterstats import zonal_stats
except ImportError:
    os.system("pip install rasterstats")
    from rasterstats import zonal_stats

try:
    import rasterio
    from rasterio.transform import from_bounds
except ImportError:
    os.system("pip install rasterio")
    import rasterio
    from rasterio.transform import from_bounds

# Load env
# Load env vars from .env file manually
env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '.env')
if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, _, val = line.partition('=')
                os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
NASA_TOKEN = os.getenv('NASA_EARTHDATA_API_KEY', '')

if not NASA_TOKEN:
    print("ERROR: NASA_EARTHDATA_API_KEY not set")
    sys.exit(1)

# El Salvador bounding box (approx)
BBOX = {'west': -90.2, 'east': -87.6, 'south': 13.0, 'north': 14.5}

# VIIRS VNP46A4 tiles covering El Salvador: h08v07 and h09v07
TILES = ['h08v07', 'h09v07']

LAADS_BASE = "https://ladsweb.modaps.eosdis.nasa.gov"

def get_viirs_file_urls(year, product="VNP46A4"):
    """Get download URLs for a given year from LAADS DAAC."""
    # VNP46A4 files are organized by day of year. Annual composites use day 001.
    collection = "5000"
    day = "001"

    url = f"{LAADS_BASE}/api/v2/content/archives/allData/{collection}/{product}/{year}/{day}"
    headers = {"Authorization": f"Bearer {NASA_TOKEN}"}

    resp = requests.get(url, headers=headers, timeout=60)
    if resp.status_code != 200:
        print(f"  Error listing files for {year}: HTTP {resp.status_code}")
        return []

    files = resp.json()
    urls = []
    for f in files:
        name = f.get('name', '')
        for tile in TILES:
            if tile in name and name.endswith('.h5'):
                urls.append(f"{LAADS_BASE}/api/v2/content/archives/allData/{collection}/{product}/{year}/{day}/{name}")
    return urls

def download_h5(url, dest):
    """Download HDF5 file from LAADS."""
    headers = {"Authorization": f"Bearer {NASA_TOKEN}"}
    resp = requests.get(url, headers=headers, stream=True, timeout=300)
    if resp.status_code != 200:
        print(f"  Download failed: HTTP {resp.status_code}")
        return False
    with open(dest, 'wb') as f:
        for chunk in resp.iter_content(chunk_size=1024*1024):
            f.write(chunk)
    return True

def h5_to_geotiff(h5_path, tif_path):
    """
    Extract NTL band from VIIRS HDF5 and save as GeoTIFF.
    VNP46A4 has the data in:
    HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/DNB_BRDF-Corrected_NTL
    """
    with h5py.File(h5_path, 'r') as f:
        # Navigate to the data
        try:
            data = f['HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/DNB_BRDF-Corrected_NTL'][:]
        except KeyError:
            # Try alternative paths
            print(f"  Available datasets: {list(f.keys())}")
            # Walk the tree
            def print_tree(name, obj):
                if isinstance(obj, h5py.Dataset):
                    print(f"    Dataset: {name} shape={obj.shape}")
            f.visititems(print_tree)
            return False

        # Get geolocation info from the grid metadata
        try:
            grid = f['HDFEOS/GRIDS/VIIRS_Grid_DNB_2d']
            # Standard sinusoidal projection tile coordinates
            attrs = dict(grid.attrs)
            upper_left = attrs.get('UpperLeftPointMtrs', None)
            lower_right = attrs.get('LowerRightMtrs', None)
        except Exception:
            upper_left = None
            lower_right = None

    if upper_left is None or lower_right is None:
        print("  Warning: Could not read tile extent from HDF5 metadata")
        return False

    nrows, ncols = data.shape

    # Convert fill values to NaN
    data = data.astype(np.float32)
    data[data >= 65534] = np.nan

    # Create GeoTIFF with sinusoidal projection
    sinu_wkt = 'PROJCS["Sinusoidal",GEOGCS["GCS_undefined",DATUM["D_undefined",SPHEROID["Sphere",6371007.181,0]],PRIMEM["Greenwich",0],UNIT["Degree",0.0174532925199433]],PROJECTION["Sinusoidal"],PARAMETER["central_meridian",0],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["Meter",1]]'

    transform = from_bounds(
        upper_left[0], lower_right[1], lower_right[0], upper_left[1],
        ncols, nrows
    )

    with rasterio.open(tif_path, 'w', driver='GTiff',
                       width=ncols, height=nrows, count=1,
                       dtype='float32', crs=sinu_wkt,
                       transform=transform, nodata=np.nan) as dst:
        dst.write(data, 1)

    return True


def extract_municipality_means(tif_paths, municipalities_gdf, year):
    """Extract mean nightlight per municipality from GeoTIFF(s)."""
    from rasterio.merge import merge
    from rasterio.warp import calculate_default_transform, reproject, Resampling

    # Merge tiles and reproject to EPSG:4326
    src_files = [rasterio.open(p) for p in tif_paths]

    if len(src_files) > 1:
        mosaic, out_transform = merge(src_files)
        out_crs = src_files[0].crs
        out_meta = src_files[0].meta.copy()
        out_meta.update({
            'height': mosaic.shape[1],
            'width': mosaic.shape[2],
            'transform': out_transform
        })
        for s in src_files:
            s.close()
    else:
        mosaic = src_files[0].read()
        out_transform = src_files[0].transform
        out_crs = src_files[0].crs
        out_meta = src_files[0].meta.copy()
        src_files[0].close()

    # Reproject to EPSG:4326
    dst_crs = 'EPSG:4326'
    transform_4326, width_4326, height_4326 = calculate_default_transform(
        out_crs, dst_crs,
        mosaic.shape[2], mosaic.shape[1],
        left=out_transform.c, bottom=out_transform.f + out_transform.e * mosaic.shape[1],
        right=out_transform.c + out_transform.a * mosaic.shape[2], top=out_transform.f
    )

    reprojected = np.empty((1, height_4326, width_4326), dtype=np.float32)
    reproject(
        source=mosaic,
        destination=reprojected,
        src_transform=out_transform,
        src_crs=out_crs,
        dst_transform=transform_4326,
        dst_crs=dst_crs,
        resampling=Resampling.bilinear,
        src_nodata=np.nan,
        dst_nodata=np.nan
    )

    # Write reprojected to temp file
    tmp_tif = os.path.join(tempfile.gettempdir(), f"viirs_{year}_4326.tif")
    with rasterio.open(tmp_tif, 'w', driver='GTiff',
                       width=width_4326, height=height_4326, count=1,
                       dtype='float32', crs=dst_crs,
                       transform=transform_4326, nodata=np.nan) as dst:
        dst.write(reprojected)

    # Zonal statistics
    stats = zonal_stats(municipalities_gdf, tmp_tif,
                        stats=['mean', 'median', 'count'],
                        nodata=np.nan)

    os.remove(tmp_tif)

    results = []
    for i, row in municipalities_gdf.iterrows():
        results.append({
            'NAME_1': row.get('NAME_1', ''),
            'NAME_2': row.get('NAME_2', ''),
            'GID_2': row.get('GID_2', ''),
            'year': year,
            'ntl_mean': stats[i]['mean'] if stats[i]['mean'] is not None else np.nan,
            'ntl_median': stats[i]['median'] if stats[i]['median'] is not None else np.nan,
            'ntl_pixels': stats[i]['count']
        })

    return results


def main():
    output_path = os.path.join(DATA_DIR, 'viirs_annual.csv')

    if os.path.exists(output_path):
        print(f"VIIRS data already exists at {output_path}")
        return

    # Load municipalities
    gadm_path = os.path.join(DATA_DIR, 'gadm_slv_adm2.gpkg')
    if not os.path.exists(gadm_path):
        print(f"ERROR: GADM file not found at {gadm_path}")
        sys.exit(1)

    muni = gpd.read_file(gadm_path)
    print(f"Loaded {len(muni)} municipalities")

    all_results = []
    tmpdir = tempfile.mkdtemp(prefix="viirs_")

    for year in range(2012, 2024):
        print(f"\n=== Processing {year} ===")

        # Get file URLs
        urls = get_viirs_file_urls(year)
        if not urls:
            print(f"  No files found for {year}")
            continue

        print(f"  Found {len(urls)} tiles")

        tif_paths = []
        for url in urls:
            fname = url.split('/')[-1]
            h5_path = os.path.join(tmpdir, fname)
            tif_path = h5_path.replace('.h5', '.tif')

            # Download
            if not os.path.exists(h5_path):
                print(f"  Downloading {fname}...")
                if not download_h5(url, h5_path):
                    continue

            # Convert to GeoTIFF
            if not os.path.exists(tif_path):
                print(f"  Converting to GeoTIFF...")
                if not h5_to_geotiff(h5_path, tif_path):
                    continue

            tif_paths.append(tif_path)

        if not tif_paths:
            print(f"  No valid tiles for {year}")
            continue

        # Extract zonal statistics
        print(f"  Extracting zonal statistics...")
        results = extract_municipality_means(tif_paths, muni, year)
        all_results.extend(results)
        print(f"  Done: {len(results)} municipalities")

    # Save results
    import pandas as pd
    df = pd.DataFrame(all_results)
    df.to_csv(output_path, index=False)
    print(f"\nSaved {len(df)} rows to {output_path}")
    print(f"Years: {sorted(df['year'].unique())}")
    print(f"Mean NTL range: {df['ntl_mean'].min():.2f} - {df['ntl_mean'].max():.2f}")


if __name__ == '__main__':
    main()
