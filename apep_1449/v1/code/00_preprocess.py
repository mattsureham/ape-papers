"""Pre-process GFW fleet daily zips: extract squid_jigger rows only."""
import zipfile
import csv
import io
import os
import glob

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')

def extract_squid_jigger(zip_path, out_path):
    """Read all CSVs in a zip, filter geartype=='squid_jigger', write single CSV."""
    rows = []
    with zipfile.ZipFile(zip_path, 'r') as zf:
        csv_names = [n for n in zf.namelist() if n.endswith('.csv')]
        print(f"  Processing {len(csv_names)} files from {os.path.basename(zip_path)}")
        for i, name in enumerate(csv_names):
            with zf.open(name) as f:
                reader = csv.DictReader(io.TextIOWrapper(f, 'utf-8'))
                for row in reader:
                    if row.get('geartype') == 'squid_jigger':
                        rows.append(row)
            if (i + 1) % 50 == 0:
                print(f"    {i+1}/{len(csv_names)} files, {len(rows)} squid rows so far")

    if rows:
        with open(out_path, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=rows[0].keys())
            writer.writeheader()
            writer.writerows(rows)
    print(f"  Wrote {len(rows)} squid_jigger rows to {os.path.basename(out_path)}")
    return len(rows)

# Also extract trawler rows for falsification
def extract_gear(zip_path, out_path, gear_types):
    """Extract rows matching any of gear_types."""
    rows = []
    with zipfile.ZipFile(zip_path, 'r') as zf:
        csv_names = [n for n in zf.namelist() if n.endswith('.csv')]
        for name in csv_names:
            with zf.open(name) as f:
                reader = csv.DictReader(io.TextIOWrapper(f, 'utf-8'))
                for row in reader:
                    if row.get('geartype') in gear_types:
                        rows.append(row)
    if rows:
        with open(out_path, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=rows[0].keys())
            writer.writeheader()
            writer.writerows(rows)
    print(f"  Wrote {len(rows)} {gear_types} rows to {os.path.basename(out_path)}")
    return len(rows)

if __name__ == '__main__':
    zips = sorted(glob.glob(os.path.join(DATA_DIR, 'fleet-daily-*.zip')))
    for zp in zips:
        year = zp.split('-')[-1].replace('.zip', '')
        print(f"\nYear {year}:")
        # Squid jiggers (main analysis)
        extract_squid_jigger(zp, os.path.join(DATA_DIR, f'squid_jigger_{year}.csv'))
        # Trawlers (falsification)
        extract_gear(zp, os.path.join(DATA_DIR, f'trawlers_{year}.csv'),
                    {'trawlers', 'trawler'})
