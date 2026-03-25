"""Extract district-level nightlights from VIIRS HDF5 tiles for Zambia.

Downloads all years (2012-2023) of VNP46A4 annual composites,
extracts AllAngle_Composite_Snow_Free for each tile covering Zambia,
creates GeoTIFFs, then aggregates to GADM Level 2 district means.

Output: ../data/district_nightlights.csv
"""
import os
import sys
import csv
import json
import glob
import h5py
import numpy as np

# Optional: rasterio for GeoTIFF, geopandas for spatial join
try:
    import rasterio
    from rasterio.transform import from_bounds
    from rasterio.merge import merge
    from rasterio.mask import mask as rio_mask
    HAS_RASTERIO = True
except ImportError:
    HAS_RASTERIO = False

try:
    import geopandas as gpd
    from shapely.geometry import box
    HAS_GEOPANDAS = True
except ImportError:
    HAS_GEOPANDAS = False

# Set up earthaccess
import earthaccess

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
RAW_DIR = os.path.join(DATA_DIR, "viirs_raw")
os.makedirs(RAW_DIR, exist_ok=True)

# Zambia bounding box (lon_min, lat_min, lon_max, lat_max)
ZMB_BBOX = (22, -18, 34, -8)
YEARS = range(2012, 2024)

DATASET_PATH = "HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/AllAngle_Composite_Snow_Free"
FILL_VALUE = 65535.0


def authenticate():
    """Authenticate with NASA Earthdata."""
    token = os.environ.get("NASA_EARTHDATA_API_KEY", "")
    os.environ["EARTHDATA_TOKEN"] = token
    auth = earthaccess.login(strategy="environment")
    if not auth.authenticated:
        raise RuntimeError("NASA Earthdata authentication failed")
    return auth


def download_year(year):
    """Download VNP46A4 tiles for a given year covering Zambia."""
    # VNP46A4 is annual — one file per tile per year
    # The API date range is for the compositing period
    results = earthaccess.search_data(
        short_name="VNP46A4",
        temporal=(f"{year}-01-01", f"{max(year, year+1)}-12-31"),
        bounding_box=ZMB_BBOX,
        count=20
    )

    # Filter to correct year from filenames
    year_results = []
    for r in results:
        urls = r.data_links()
        for url in urls:
            fname = os.path.basename(url)
            # VNP46A4.A{YYYY}001... — extract year from filename
            if f"A{year}" in fname:
                year_results.append(r)
                break

    if not year_results:
        print(f"  WARNING: No tiles found for {year}")
        return []

    print(f"  Downloading {len(year_results)} tiles for {year}...")
    downloaded = earthaccess.download(year_results, RAW_DIR)
    return [str(f) for f in downloaded]


def extract_tile_data(h5_path):
    """Extract nightlight data and coordinates from an HDF5 tile."""
    with h5py.File(h5_path, "r") as f:
        data = f[DATASET_PATH][:]
        lat = f["HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/lat"][:]
        lon = f["HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/lon"][:]

    # Replace fill values with NaN
    data = data.astype(np.float64)
    data[data >= FILL_VALUE] = np.nan
    data[data < 0] = np.nan

    return data, lat, lon


def tile_to_geotiff(h5_path, out_path):
    """Convert an HDF5 tile to GeoTIFF."""
    data, lat, lon = extract_tile_data(h5_path)

    # Create transform from lat/lon arrays
    lat_min, lat_max = lat.min(), lat.max()
    lon_min, lon_max = lon.min(), lon.max()

    # Data is stored north-up (lat decreasing), so flip if needed
    if lat[0] > lat[-1]:
        # Already north-up
        pass
    else:
        data = np.flipud(data)

    transform = from_bounds(lon_min, lat_min, lon_max, lat_max, data.shape[1], data.shape[0])

    with rasterio.open(
        out_path, "w",
        driver="GTiff",
        height=data.shape[0],
        width=data.shape[1],
        count=1,
        dtype="float64",
        crs="EPSG:4326",
        transform=transform,
        nodata=np.nan
    ) as dst:
        dst.write(data, 1)

    return out_path


def aggregate_to_districts_simple(h5_files, zmb_districts_path):
    """Aggregate nightlight values to district means using a grid-based approach.

    This is the fallback when geopandas/rasterio aren't fully available.
    Uses numpy binning against GADM district boundaries.
    """
    # Load district boundaries from the RDS file saved by R
    # We'll use a CSV of district centroids + bounding boxes instead
    pass


def aggregate_to_districts(tif_files, zmb_geojson_path):
    """Aggregate nightlight GeoTIFFs to district means using rasterio."""
    import fiona

    districts = []
    with fiona.open(zmb_geojson_path) as src:
        for feat in src:
            districts.append({
                "name_1": feat["properties"].get("NAME_1", ""),
                "name_2": feat["properties"].get("NAME_2", ""),
                "geometry": feat["geometry"]
            })

    results = []
    for tif in tif_files:
        with rasterio.open(tif) as src:
            for dist in districts:
                from shapely.geometry import shape
                geom = shape(dist["geometry"])
                try:
                    out_image, _ = rio_mask(src, [geom], crop=True, nodata=np.nan)
                    valid = out_image[~np.isnan(out_image)]
                    if len(valid) > 0:
                        results.append({
                            "province": dist["name_1"],
                            "district": dist["name_2"],
                            "ntl_mean": float(valid.mean()),
                            "ntl_sum": float(valid.sum()),
                            "ntl_median": float(np.median(valid)),
                            "n_pixels": int(len(valid)),
                            "tif_file": os.path.basename(tif)
                        })
                except Exception as e:
                    print(f"    Warning: {dist['name_2']}: {e}")

    return results


def main():
    print("=== VIIRS Nightlight Extraction for Zambia ===\n")

    # Authenticate
    print("Authenticating with NASA Earthdata...")
    authenticate()

    # Download all years
    all_files = {}
    for year in YEARS:
        existing = glob.glob(os.path.join(RAW_DIR, f"VNP46A4.A{year}*.h5"))
        if existing:
            print(f"  {year}: Using {len(existing)} existing files")
            all_files[year] = existing
        else:
            files = download_year(year)
            all_files[year] = files

    if not HAS_RASTERIO:
        print("\nrasterio not available, using direct HDF5 extraction...")
        # Direct extraction approach without GeoTIFF conversion
        aggregate_direct(all_files)
        return

    # Convert to GeoTIFF and aggregate
    print("\nConverting HDF5 to GeoTIFF and aggregating...")

    # Check for GADM GeoJSON (exported from R)
    geojson_path = os.path.join(DATA_DIR, "zmb_districts.geojson")
    if not os.path.exists(geojson_path):
        print("  Need to export GADM as GeoJSON from R first.")
        print("  Run: Rscript -e 'library(sf); d <- readRDS(\"data/zmb_districts.rds\"); st_write(d, \"data/zmb_districts.geojson\")'")
        # Do direct extraction instead
        aggregate_direct(all_files)
        return

    all_district_data = []
    for year, files in sorted(all_files.items()):
        print(f"\n  Processing {year} ({len(files)} tiles)...")

        # Convert each tile to GeoTIFF
        tif_files = []
        for h5f in files:
            tif_path = h5f.replace(".h5", ".tif")
            if not os.path.exists(tif_path):
                tile_to_geotiff(h5f, tif_path)
            tif_files.append(tif_path)

        # Aggregate to districts
        year_data = aggregate_to_districts(tif_files, geojson_path)
        for row in year_data:
            row["year"] = year
        all_district_data.extend(year_data)
        print(f"    {len(year_data)} district-tile observations")

    # Save as CSV
    out_path = os.path.join(DATA_DIR, "district_nightlights.csv")
    if all_district_data:
        keys = all_district_data[0].keys()
        with open(out_path, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(all_district_data)
        print(f"\nSaved {len(all_district_data)} rows to {out_path}")
    else:
        print("ERROR: No data extracted!")
        sys.exit(1)


def aggregate_direct(all_files):
    """Direct extraction without GeoTIFF — aggregate using lat/lon grid binning."""
    print("\n  Using direct HDF5 extraction with lat/lon binning...")

    # Load district info from R's saved RDS (we need boundaries)
    # Instead, use a simple approach: extract all pixel values with coords,
    # then do the spatial join in R using sf

    all_rows = []
    for year, files in sorted(all_files.items()):
        print(f"  {year}: processing {len(files)} tiles...")
        year_values = []

        for h5f in files:
            data, lat, lon = extract_tile_data(h5f)

            # Create meshgrid for coordinates
            lon_grid, lat_grid = np.meshgrid(lon, lat)

            # Clip to Zambia bounding box
            mask = (
                (lon_grid >= ZMB_BBOX[0]) & (lon_grid <= ZMB_BBOX[2]) &
                (lat_grid >= ZMB_BBOX[1]) & (lat_grid <= ZMB_BBOX[3]) &
                ~np.isnan(data) & (data >= 0)
            )

            n_valid = mask.sum()
            if n_valid > 0:
                year_values.append({
                    "lons": lon_grid[mask],
                    "lats": lat_grid[mask],
                    "values": data[mask]
                })
                print(f"    {os.path.basename(h5f)}: {n_valid} valid pixels in Zambia bbox")

        if year_values:
            # Combine all tiles for this year
            all_lons = np.concatenate([v["lons"] for v in year_values])
            all_lats = np.concatenate([v["lats"] for v in year_values])
            all_vals = np.concatenate([v["values"] for v in year_values])

            # Sample every 4th pixel to keep manageable (still ~100k pixels)
            step = max(1, len(all_lons) // 200000)
            idx = np.arange(0, len(all_lons), step)

            for i in idx:
                all_rows.append({
                    "year": year,
                    "lon": float(all_lons[i]),
                    "lat": float(all_lats[i]),
                    "ntl": float(all_vals[i])
                })

    # Save pixel-level data as CSV for R to do spatial join
    out_path = os.path.join(DATA_DIR, "viirs_pixels.csv")
    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["year", "lon", "lat", "ntl"])
        writer.writeheader()
        writer.writerows(all_rows)

    print(f"\n  Saved {len(all_rows)} pixel observations to {out_path}")
    print("  Run R spatial join to aggregate to districts.")


if __name__ == "__main__":
    main()
