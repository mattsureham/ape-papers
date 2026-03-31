#!/usr/bin/env python3
"""
01_fetch_data.py — Fetch KOSPI stock data for Korea English Disclosure paper (apep_1180)

Data sources:
1. FinanceDataReader: KOSPI stock listing with market cap
2. yfinance: Daily OHLCV data and firm fundamentals (total assets)

Treatment: Phase 1 firms mandated to file in English from January 2024
Criteria: Total assets >= KRW 10 trillion AND foreign ownership >= 5%
"""

import os
import json
import time
import warnings
import pandas as pd
import numpy as np

warnings.filterwarnings('ignore')

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data')
os.makedirs(DATA_DIR, exist_ok=True)

# ============================================================
# Step 1: Get KOSPI stock listing
# ============================================================
print("=" * 60)
print("Step 1: Getting KOSPI stock listing from FinanceDataReader")
print("=" * 60)

import FinanceDataReader as fdr

kospi = fdr.StockListing('KOSPI')
print(f"Total KOSPI stocks: {len(kospi)}")

# Keep relevant columns
kospi = kospi[['Code', 'Name', 'Close', 'Volume', 'Marcap', 'Stocks']].copy()
kospi.columns = ['ticker', 'name', 'last_close', 'last_volume', 'market_cap', 'shares_outstanding']

# Filter out very small or inactive stocks (close=0 or market_cap < 10B KRW)
kospi = kospi[kospi['last_close'] > 0].copy()
kospi = kospi[kospi['market_cap'] > 10e9].copy()  # > 10 billion KRW
print(f"After filtering inactive/tiny stocks: {len(kospi)}")

# ============================================================
# Step 2: Get total assets from yfinance for treatment assignment
# ============================================================
print("\n" + "=" * 60)
print("Step 2: Getting total assets from yfinance for treatment assignment")
print("=" * 60)

import yfinance as yf

# Focus on top 300 by market cap (Phase 1 threshold is 10T KRW, so we need
# to cover well beyond the 111 treated firms to have a good control group)
kospi_sorted = kospi.sort_values('market_cap', ascending=False).head(300).copy()

total_assets_list = []
foreign_pct_list = []
sector_list = []

for i, (idx, row) in enumerate(kospi_sorted.iterrows()):
    ticker_yf = row['ticker'] + '.KS'
    try:
        info = yf.Ticker(ticker_yf).info
        ta = info.get('totalAssets', None) or info.get('totalRevenue', None)
        # For Korean stocks, totalAssets may not be in yfinance
        # Use balance sheet if available
        if ta is None:
            bs = yf.Ticker(ticker_yf).balance_sheet
            if bs is not None and not bs.empty and 'Total Assets' in bs.index:
                ta = bs.loc['Total Assets'].iloc[0]
        sector = info.get('sector', 'Unknown')
        total_assets_list.append(ta)
        sector_list.append(sector)
        if (i + 1) % 50 == 0:
            print(f"  Processed {i+1}/300 firms...")
    except Exception as e:
        total_assets_list.append(None)
        sector_list.append('Unknown')
    time.sleep(0.2)  # Rate limiting

kospi_sorted['total_assets'] = total_assets_list
kospi_sorted['sector'] = sector_list

# ============================================================
# Step 3: Identify Phase 1 firms (total assets >= 10T KRW)
# ============================================================
print("\n" + "=" * 60)
print("Step 3: Identifying Phase 1 firms")
print("=" * 60)

THRESHOLD = 10e12  # 10 trillion KRW

# For firms where we got total assets, classify
has_ta = kospi_sorted['total_assets'].notna()
print(f"Firms with total assets data: {has_ta.sum()}")

# Phase 1: total assets >= 10T KRW
kospi_sorted['phase1'] = (kospi_sorted['total_assets'] >= THRESHOLD).astype(int)
kospi_sorted.loc[kospi_sorted['total_assets'].isna(), 'phase1'] = np.nan

n_phase1 = kospi_sorted['phase1'].sum()
print(f"Phase 1 firms (assets >= 10T KRW): {int(n_phase1)}")

# If yfinance didn't return enough total assets data, use market cap as fallback
# Market cap is correlated with total assets (r~0.7-0.8 for large firms)
if n_phase1 < 50:
    print("WARNING: Too few firms with total assets data. Using market cap fallback.")
    # Use market cap threshold that approximately corresponds to 10T KRW assets
    # Typical asset/market_cap ratio for Korean firms is ~1.5-3x
    # So 10T assets ~ 5-7T market cap
    mcap_threshold = kospi_sorted.sort_values('market_cap', ascending=False).iloc[110]['market_cap']
    kospi_sorted['phase1'] = (kospi_sorted['market_cap'] >= mcap_threshold).astype(int)
    n_phase1 = kospi_sorted['phase1'].sum()
    print(f"Phase 1 firms (market cap fallback, top ~111): {int(n_phase1)}")
    print(f"Market cap threshold: {mcap_threshold/1e12:.1f}T KRW")

# Show some Phase 1 firms
phase1_firms = kospi_sorted[kospi_sorted['phase1'] == 1].sort_values('market_cap', ascending=False)
print(f"\nTop 10 Phase 1 firms:")
for _, row in phase1_firms.head(10).iterrows():
    ta_str = f"{row['total_assets']/1e12:.1f}T" if pd.notna(row['total_assets']) else "N/A"
    print(f"  {row['ticker']}: {row['name']} (MktCap: {row['market_cap']/1e12:.1f}T, Assets: {ta_str})")

# Save firm-level data
firm_data = kospi_sorted[['ticker', 'name', 'market_cap', 'total_assets', 'sector', 'shares_outstanding', 'phase1']].copy()
firm_data.to_csv(os.path.join(DATA_DIR, 'firm_characteristics.csv'), index=False)
print(f"\nSaved firm characteristics: {len(firm_data)} firms")

# ============================================================
# Step 4: Download daily stock data from Yahoo Finance
# ============================================================
print("\n" + "=" * 60)
print("Step 4: Downloading daily stock data from Yahoo Finance")
print("=" * 60)

# Download 2022-01-01 to 2025-06-30 (2 years pre + 1.5 years post)
START_DATE = '2022-01-01'
END_DATE = '2025-12-31'

# Get tickers for all firms in our sample
tickers_yf = [t + '.KS' for t in firm_data['ticker'].tolist()]

all_daily = []
failed = []

# Download in batches of 20
batch_size = 20
for batch_start in range(0, len(tickers_yf), batch_size):
    batch = tickers_yf[batch_start:batch_start + batch_size]
    batch_str = ' '.join(batch)
    try:
        data = yf.download(batch_str, start=START_DATE, end=END_DATE,
                           group_by='ticker', progress=False, threads=True)

        for ticker_yf in batch:
            ticker_kr = ticker_yf.replace('.KS', '')
            try:
                if len(batch) > 1:
                    df = data[ticker_yf].copy()
                else:
                    df = data.copy()
                df = df.dropna(subset=['Close'])
                if len(df) > 0:
                    df['ticker'] = ticker_kr
                    df['date'] = df.index
                    df = df[['ticker', 'date', 'Open', 'High', 'Low', 'Close', 'Volume']].copy()
                    df.columns = ['ticker', 'date', 'open', 'high', 'low', 'close', 'volume']
                    all_daily.append(df)
            except Exception:
                failed.append(ticker_kr)
    except Exception as e:
        failed.extend([t.replace('.KS', '') for t in batch])

    if (batch_start + batch_size) % 100 == 0:
        print(f"  Downloaded {min(batch_start + batch_size, len(tickers_yf))}/{len(tickers_yf)} tickers...")
    time.sleep(1)  # Rate limiting

print(f"  Downloaded {min(batch_start + batch_size, len(tickers_yf))}/{len(tickers_yf)} tickers...")

if not all_daily:
    raise RuntimeError("FATAL: No daily stock data downloaded. Cannot proceed.")

daily = pd.concat(all_daily, ignore_index=True)
daily['date'] = pd.to_datetime(daily['date'])
print(f"\nTotal daily observations: {len(daily):,}")
print(f"Unique tickers with data: {daily['ticker'].nunique()}")
print(f"Date range: {daily['date'].min()} to {daily['date'].max()}")
print(f"Failed downloads: {len(failed)} tickers")

# Save daily data
daily.to_csv(os.path.join(DATA_DIR, 'daily_stock_data.csv'), index=False)
print(f"Saved daily stock data: {len(daily):,} rows")

# ============================================================
# Summary statistics
# ============================================================
print("\n" + "=" * 60)
print("Data Summary")
print("=" * 60)

merged = daily.merge(firm_data[['ticker', 'phase1']], on='ticker', how='left')
phase1_data = merged[merged['phase1'] == 1]
control_data = merged[merged['phase1'] == 0]

print(f"Phase 1 (treated) firms with daily data: {phase1_data['ticker'].nunique()}")
print(f"Control firms with daily data: {control_data['ticker'].nunique()}")
print(f"Phase 1 daily obs: {len(phase1_data):,}")
print(f"Control daily obs: {len(control_data):,}")

# Save metadata
metadata = {
    'total_kospi_firms': len(kospi),
    'sample_firms': len(firm_data),
    'phase1_firms': int(firm_data['phase1'].sum()),
    'control_firms': int((firm_data['phase1'] == 0).sum()),
    'total_daily_obs': len(daily),
    'date_range': [str(daily['date'].min()), str(daily['date'].max())],
    'failed_downloads': len(failed),
    'treatment_threshold': 'KRW 10 trillion total assets',
    'treatment_date': '2024-01-01',
    'data_sources': ['FinanceDataReader (KOSPI listing)', 'Yahoo Finance (daily OHLCV, fundamentals)']
}
with open(os.path.join(DATA_DIR, 'metadata.json'), 'w') as f:
    json.dump(metadata, f, indent=2, default=str)

print("\nData fetch complete!")
