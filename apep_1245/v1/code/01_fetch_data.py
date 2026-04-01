#!/usr/bin/env python3
"""
Fetch Korean stock data from Yahoo Finance for the short-selling ban analysis.
Downloads daily OHLCV for KOSPI 200 constituents + major KOSDAQ stocks.
"""

import yfinance as yf
import pandas as pd
import json
import os
import time
import sys

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# Date range: Jan 2022 (18 months pre-ban) to present
START_DATE = "2022-01-01"
END_DATE = "2026-04-01"

# Ban dates
BAN_START = "2023-11-06"
BAN_END = "2025-03-31"

# Major KOSPI stocks (large-cap, diversified sectors)
# These are the most liquid and well-covered on Yahoo Finance
KOSPI_TICKERS = [
    # Semiconductors / Tech
    "005930.KS",  # Samsung Electronics
    "000660.KS",  # SK Hynix
    "035420.KS",  # NAVER
    "035720.KS",  # Kakao
    "006400.KS",  # Samsung SDI
    "028260.KS",  # Samsung C&T
    "018260.KS",  # Samsung SDS
    "009150.KS",  # Samsung Electro-Mechanics
    "034730.KS",  # SK Inc
    "066570.KS",  # LG Electronics
    "003550.KS",  # LG Corp
    "032830.KS",  # Samsung Life Insurance
    # Auto / Industrial
    "005380.KS",  # Hyundai Motor
    "000270.KS",  # Kia
    "012330.KS",  # Hyundai Mobis
    "051910.KS",  # LG Chem
    "096770.KS",  # SK Innovation
    "010140.KS",  # Samsung Heavy Industries
    "009540.KS",  # Hyundai Heavy Industries
    # Battery / EV
    "373220.KS",  # LG Energy Solution
    "247540.KS",  # Ecopro BM
    "086520.KS",  # Ecopro
    "003670.KS",  # POSCO Future M
    # Finance
    "105560.KS",  # KB Financial Group
    "055550.KS",  # Shinhan Financial
    "086790.KS",  # Hana Financial
    "316140.KS",  # Woori Financial
    "024110.KS",  # Industrial Bank of Korea
    # Telecom / Utilities
    "017670.KS",  # SK Telecom
    "030200.KS",  # KT Corp
    "032640.KS",  # LG Uplus
    "015760.KS",  # Korea Electric Power (KEPCO)
    # Consumer
    "004170.KS",  # Shinsegae
    "004990.KS",  # Lotte Corp
    "021240.KS",  # Woongjin Coway
    "036570.KS",  # NCsoft
    "251270.KS",  # Netmarble
    "263750.KS",  # Pearl Abyss
    # Bio / Pharma
    "207940.KS",  # Samsung Biologics
    "068270.KS",  # Celltrion
    "326030.KS",  # SK Biopharmaceuticals
    # Steel / Materials
    "005490.KS",  # POSCO Holdings
    "010130.KS",  # Korea Zinc
    "011170.KS",  # Lotte Chemical
    # Energy / Refining
    "010950.KS",  # S-Oil
    "078930.KS",  # GS Holdings
    "036460.KS",  # Korea Gas Corp
    # Transport / Logistics
    "180640.KS",  # Hanjin KAL (Korean Air parent)
    "003490.KS",  # Korean Air
    "020560.KS",  # Asiana Airlines
]

# Major KOSDAQ stocks (higher beta, more retail-driven)
KOSDAQ_TICKERS = [
    "091990.KQ",  # Celltrion Healthcare
    "196170.KQ",  # Alteogen
    "145020.KQ",  # Hugel
    "293490.KQ",  # Kakao Games
    "112040.KQ",  # Wemade
    "041510.KQ",  # SM Entertainment
    "352820.KQ",  # HYBE
    "328130.KQ",  # LG Energy Solution Veritas (Lupin)
    "403870.KQ",  # HPSP
    "039030.KQ",  # Iotec International
    "060310.KQ",  # 3S
    "095340.KQ",  # ISC
    "058470.KQ",  # Rikamtech (formerly Riken Keiki)
    "357780.KQ",  # Soulbrain
    "036930.KQ",  # Jusung Engineering
    "086900.KQ",  # MEDY-TOX
    "140860.KQ",  # ParkSystems
    "141080.KQ",  # Rino Industrial
    "298380.KQ",  # ABL Bio
    "215600.KQ",  # Shin Young Securities (Shinyoung)
]

# KOSPI Index for benchmark
BENCHMARK = "^KS11"  # KOSPI Composite Index


def fetch_stock_data(tickers, label):
    """Download daily data for a list of tickers."""
    results = []
    failed = []

    for i, ticker in enumerate(tickers):
        try:
            stock = yf.Ticker(ticker)
            hist = stock.history(start=START_DATE, end=END_DATE)

            if len(hist) < 100:
                print(f"  [{i+1}/{len(tickers)}] {ticker}: Only {len(hist)} obs, skipping")
                failed.append(ticker)
                continue

            hist = hist.reset_index()
            hist["ticker"] = ticker
            hist["exchange"] = label
            results.append(hist)
            print(f"  [{i+1}/{len(tickers)}] {ticker}: {len(hist)} obs")

        except Exception as e:
            print(f"  [{i+1}/{len(tickers)}] {ticker}: FAILED - {e}")
            failed.append(ticker)

        # Rate limiting
        if (i + 1) % 10 == 0:
            time.sleep(1)

    return results, failed


def compute_pre_ban_characteristics(df):
    """Compute pre-ban firm characteristics for cross-sectional analysis."""
    pre_ban = df[df["Date"] < BAN_START].copy()

    chars = []
    for ticker, gdf in pre_ban.groupby("ticker"):
        if len(gdf) < 60:
            continue

        # Last 60 trading days before ban
        recent = gdf.tail(60)

        # Market cap proxy (close * volume as liquidity proxy)
        avg_close = recent["Close"].mean()
        avg_volume = recent["Volume"].mean()
        avg_turnover = (recent["Close"] * recent["Volume"]).mean()

        # Volatility (annualized daily return std)
        returns = recent["Close"].pct_change().dropna()
        daily_vol = returns.std()
        annual_vol = daily_vol * (252 ** 0.5)

        # Average daily return
        avg_ret = returns.mean()

        # Price level
        last_close = recent["Close"].iloc[-1]

        # Amihud illiquidity (|return| / volume)
        amihud = (returns.abs() / recent["Volume"].iloc[1:].values).mean()

        # Turnover ratio (volume / avg volume)
        turnover_vol = recent["Volume"].std() / recent["Volume"].mean() if recent["Volume"].mean() > 0 else 0

        chars.append({
            "ticker": ticker,
            "exchange": gdf["exchange"].iloc[0],
            "pre_ban_close": last_close,
            "pre_ban_avg_close": avg_close,
            "pre_ban_avg_volume": avg_volume,
            "pre_ban_avg_turnover": avg_turnover,
            "pre_ban_volatility": annual_vol,
            "pre_ban_daily_vol": daily_vol,
            "pre_ban_avg_return": avg_ret,
            "pre_ban_amihud": amihud,
            "pre_ban_turnover_volatility": turnover_vol,
            "n_pre_ban_obs": len(gdf),
        })

    return pd.DataFrame(chars)


def main():
    print("=" * 60)
    print("FETCHING KOREAN STOCK DATA")
    print(f"Period: {START_DATE} to {END_DATE}")
    print(f"Ban period: {BAN_START} to {BAN_END}")
    print("=" * 60)

    # Fetch benchmark
    print("\n--- Benchmark (KOSPI Index) ---")
    bench = yf.Ticker(BENCHMARK)
    bench_hist = bench.history(start=START_DATE, end=END_DATE).reset_index()
    bench_hist["ticker"] = BENCHMARK
    bench_hist["exchange"] = "INDEX"
    print(f"  KOSPI Index: {len(bench_hist)} obs")

    # Fetch KOSPI stocks
    print(f"\n--- KOSPI Stocks ({len(KOSPI_TICKERS)} tickers) ---")
    kospi_data, kospi_failed = fetch_stock_data(KOSPI_TICKERS, "KOSPI")

    # Fetch KOSDAQ stocks
    print(f"\n--- KOSDAQ Stocks ({len(KOSDAQ_TICKERS)} tickers) ---")
    kosdaq_data, kosdaq_failed = fetch_stock_data(KOSDAQ_TICKERS, "KOSDAQ")

    # Combine all stock data
    all_data = kospi_data + kosdaq_data
    if not all_data:
        print("\nFATAL: No stock data retrieved!")
        sys.exit(1)

    df = pd.concat(all_data, ignore_index=True)
    print(f"\n--- Combined Data ---")
    print(f"Total observations: {len(df):,}")
    print(f"Unique stocks: {df['ticker'].nunique()}")
    print(f"Date range: {df['Date'].min()} to {df['Date'].max()}")
    print(f"KOSPI stocks: {len(kospi_data)}, failed: {len(kospi_failed)}")
    print(f"KOSDAQ stocks: {len(kosdaq_data)}, failed: {len(kosdaq_failed)}")

    # Save stock data
    df.to_csv(os.path.join(DATA_DIR, "korean_stocks_daily.csv"), index=False)
    bench_hist.to_csv(os.path.join(DATA_DIR, "kospi_index_daily.csv"), index=False)

    # Compute pre-ban characteristics
    print("\n--- Computing Pre-Ban Characteristics ---")
    chars = compute_pre_ban_characteristics(df)
    chars.to_csv(os.path.join(DATA_DIR, "pre_ban_characteristics.csv"), index=False)
    print(f"Characteristics computed for {len(chars)} stocks")
    print(f"Avg pre-ban volatility: {chars['pre_ban_volatility'].mean():.3f}")
    print(f"Avg pre-ban Amihud: {chars['pre_ban_amihud'].mean():.6f}")

    # Summary stats
    summary = {
        "n_stocks": int(df["ticker"].nunique()),
        "n_kospi": len(kospi_data),
        "n_kosdaq": len(kosdaq_data),
        "n_obs": int(len(df)),
        "date_min": str(df["Date"].min()),
        "date_max": str(df["Date"].max()),
        "kospi_failed": kospi_failed,
        "kosdaq_failed": kosdaq_failed,
        "ban_start": BAN_START,
        "ban_end": BAN_END,
    }

    with open(os.path.join(DATA_DIR, "fetch_summary.json"), "w") as f:
        json.dump(summary, f, indent=2, default=str)

    print("\n--- Files Written ---")
    for fname in ["korean_stocks_daily.csv", "kospi_index_daily.csv",
                   "pre_ban_characteristics.csv", "fetch_summary.json"]:
        fpath = os.path.join(DATA_DIR, fname)
        if os.path.exists(fpath):
            size_mb = os.path.getsize(fpath) / 1024 / 1024
            print(f"  {fname}: {size_mb:.1f} MB")

    print("\nDone!")


if __name__ == "__main__":
    main()
