"""
Fetch MaStR solar installation data for bunching analysis.
Downloads solar PV data from Germany's Marktstammdatenregister,
filters to relevant fields, and saves as CSV for R analysis.
"""

import os
import sys
import json
import sqlite3
import pandas as pd
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"
DATA_DIR.mkdir(exist_ok=True)

OUTPUT_CSV = DATA_DIR / "solar_installations.csv"

def download_mastr_solar():
    """Download solar data from MaStR bulk download."""
    from open_mastr import Mastr

    print("Initializing MaStR database...")
    db = Mastr()

    print("Downloading solar bulk data (this may take several minutes)...")
    db.download(date="today", data=["solar"])

    return db

def extract_solar_data(db):
    """Extract relevant fields from the MaStR SQLite database."""
    print("Querying solar installations from database...")

    # The open-mastr package stores data in a SQLite database
    # Find the database path
    db_path = db.home_directory / "data" / "bnetza_mastr.db"

    if not db_path.exists():
        # Try alternative paths
        for p in [
            db.home_directory / "bnetza_mastr.db",
            Path.home() / ".open-MaStR" / "data" / "bnetza_mastr.db",
        ]:
            if p.exists():
                db_path = p
                break

    print(f"Database path: {db_path}")

    conn = sqlite3.connect(str(db_path))

    # Check available tables
    tables = pd.read_sql("SELECT name FROM sqlite_master WHERE type='table'", conn)
    print(f"Available tables: {tables['name'].tolist()}")

    # Query solar units - the table is typically 'solar' or 'solar_extended'
    # Key fields: capacity (kW), commissioning date, installation type, state
    query = """
    SELECT
        Nettonennleistung as capacity_kw,
        Inbetriebnahmedatum as commissioning_date,
        Lage as installation_type,
        Bundesland as state,
        Gemeinde as municipality,
        AnzahlSolarModule as n_modules
    FROM solar
    WHERE Nettonennleistung IS NOT NULL
      AND Inbetriebnahmedatum IS NOT NULL
    """

    try:
        df = pd.read_sql(query, conn)
    except Exception as e:
        print(f"Query failed: {e}")
        # Try to find the right column names
        cols = pd.read_sql("PRAGMA table_info(solar)", conn)
        print(f"Solar table columns: {cols['name'].tolist()}")

        # Adapt query based on actual column names
        col_names = cols['name'].tolist()

        # Find capacity column
        cap_col = next((c for c in col_names if 'leistung' in c.lower() or 'capacity' in c.lower() or 'Netto' in c), None)
        date_col = next((c for c in col_names if 'betrieb' in c.lower() or 'datum' in c.lower() or 'date' in c.lower()), None)
        type_col = next((c for c in col_names if 'lage' in c.lower() or 'art' in c.lower() or 'type' in c.lower()), None)
        state_col = next((c for c in col_names if 'bundesland' in c.lower() or 'state' in c.lower()), None)
        module_col = next((c for c in col_names if 'modul' in c.lower() or 'module' in c.lower()), None)

        print(f"Detected columns: cap={cap_col}, date={date_col}, type={type_col}, state={state_col}, module={module_col}")

        select_parts = []
        if cap_col:
            select_parts.append(f'"{cap_col}" as capacity_kw')
        if date_col:
            select_parts.append(f'"{date_col}" as commissioning_date')
        if type_col:
            select_parts.append(f'"{type_col}" as installation_type')
        if state_col:
            select_parts.append(f'"{state_col}" as state')
        if module_col:
            select_parts.append(f'"{module_col}" as n_modules')

        query2 = f"""
        SELECT {', '.join(select_parts)}
        FROM solar
        WHERE "{cap_col}" IS NOT NULL
        """
        df = pd.read_sql(query2, conn)

    conn.close()
    return df

def process_and_save(df):
    """Process data and save filtered CSV for R analysis."""
    print(f"Raw records: {len(df):,}")

    # Parse dates
    df['commissioning_date'] = pd.to_datetime(df['commissioning_date'], errors='coerce')
    df['year'] = df['commissioning_date'].dt.year

    # Filter to reasonable capacity range and years
    df = df[df['capacity_kw'].notna() & (df['capacity_kw'] > 0)]
    df = df[df['year'].notna() & (df['year'] >= 2008) & (df['year'] <= 2024)]

    print(f"After filtering (2008-2024, valid capacity): {len(df):,}")

    # Create period indicators
    df['period'] = pd.cut(
        df['year'],
        bins=[2007, 2013, 2020, 2024],
        labels=['pre_eeg2014', 'eeg2014_2020', 'post_eeg2021']
    )

    # Save full filtered dataset
    df.to_csv(OUTPUT_CSV, index=False)
    print(f"Saved {len(df):,} records to {OUTPUT_CSV}")

    # Print summary stats
    print("\n=== Summary Statistics ===")
    print(f"Total installations: {len(df):,}")
    print(f"\nBy period:")
    print(df['period'].value_counts().sort_index())
    print(f"\nBy installation type:")
    if 'installation_type' in df.columns:
        print(df['installation_type'].value_counts().head(10))
    print(f"\nCapacity distribution (kWp):")
    print(df['capacity_kw'].describe())
    print(f"\nInstallations in 5-15 kWp range: {((df['capacity_kw'] >= 5) & (df['capacity_kw'] <= 15)).sum():,}")

    # Save diagnostics
    diag = {
        "n_total": len(df),
        "n_5_15_kwp": int(((df['capacity_kw'] >= 5) & (df['capacity_kw'] <= 15)).sum()),
        "n_pre_2014": int((df['year'] < 2014).sum()),
        "n_2014_2020": int(((df['year'] >= 2014) & (df['year'] <= 2020)).sum()),
        "n_post_2021": int((df['year'] >= 2021).sum()),
        "years_covered": sorted(df['year'].dropna().unique().astype(int).tolist()),
    }
    with open(DATA_DIR / "fetch_diagnostics.json", "w") as f:
        json.dump(diag, f, indent=2)

    return df

if __name__ == "__main__":
    db = download_mastr_solar()
    df = extract_solar_data(db)
    process_and_save(df)
    print("\nData fetch complete.")
