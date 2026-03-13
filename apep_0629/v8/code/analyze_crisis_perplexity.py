#!/usr/bin/env python3
"""
Event study: congressional speech perplexity around FEMA disaster declarations.

Merges daily perplexity with FEMA disaster dates.
Computes mean perplexity in event windows [-30, +30] days.
Generates event study figure.

Inputs:
    results/daily_perplexity.parquet
    data/fema_disasters.parquet

Output:
    figures/fema_event_study.pdf
    results/crisis_event_study.parquet

Usage:
    python analyze_crisis_perplexity.py
    python analyze_crisis_perplexity.py --output-dir output/congressional_lm/v3/figures/
"""

import argparse
from datetime import timedelta
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import polars as pl

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RESULTS_DIR = PROJECT_ROOT / "results"


def load_data():
    """Load daily perplexity and FEMA disasters."""
    ppl_df = pl.read_parquet(RESULTS_DIR / "daily_perplexity.parquet")
    ppl_df = ppl_df.filter(pl.col("chamber") == "ALL").filter(~pl.col("ppl").is_nan())
    print(f"Daily perplexity: {len(ppl_df)} days with valid PPL")

    fema_df = pl.read_parquet(DATA_DIR / "fema_disasters.parquet")
    print(f"FEMA disasters: {len(fema_df)} major declarations")

    return ppl_df, fema_df


def filter_isolated_disasters(fema_df: pl.DataFrame, buffer_days: int = 30) -> pl.DataFrame:
    """Keep only disasters that don't overlap with others within buffer_days."""
    dates = sorted(fema_df["date"].to_list())
    isolated = []
    for i, d in enumerate(dates):
        # Check no other disaster within buffer_days
        too_close = False
        for j, other in enumerate(dates):
            if i == j:
                continue
            if abs((d - other).days) <= buffer_days and other < d:
                too_close = True
                break
        if not too_close:
            isolated.append(d)

    result = fema_df.filter(pl.col("date").is_in(isolated))
    print(f"  Isolated disasters (no prior within {buffer_days}d): {len(result)}")
    return result


def compute_event_study(ppl_df: pl.DataFrame, fema_df: pl.DataFrame,
                         window: int = 30) -> pl.DataFrame:
    """Compute event study: perplexity relative to pre-disaster baseline.

    Vectorized: cross-join disasters × daily PPL, compute relative day, filter to window.
    """
    from datetime import date as date_type

    # Ensure date columns are proper date types
    ppl_dates = ppl_df.select("date").to_series()
    fema_dates = fema_df.select("date").to_series()

    # Build: for each disaster, find all PPL days within [-window, +window]
    results = []
    ppl_dict = {}
    for row in ppl_df.iter_rows(named=True):
        d = row["date"]
        if isinstance(d, str):
            d = date_type.fromisoformat(d)
        ppl_dict[d] = (row["ppl"], row["n_conversations"])

    for row in fema_df.iter_rows(named=True):
        disaster_date = row["date"]
        if isinstance(disaster_date, str):
            disaster_date = date_type.fromisoformat(disaster_date)

        for delta in range(-window, window + 1):
            target_date = disaster_date + timedelta(days=delta)
            if target_date in ppl_dict:
                ppl_val, n_convos = ppl_dict[target_date]
                results.append({
                    "disaster_date": disaster_date,
                    "disaster_number": row["disasterNumber"],
                    "incident_type": row["incidentType"],
                    "relative_day": delta,
                    "date": target_date,
                    "ppl": ppl_val,
                    "n_conversations": n_convos,
                })

    if not results:
        raise ValueError("No event study observations found")

    df = pl.DataFrame(results)
    print(f"  Event study observations: {len(df)} day-disaster pairs")
    print(f"  Covering {df['disaster_number'].n_unique()} disasters")
    return df


def normalize_to_baseline(event_df: pl.DataFrame) -> pl.DataFrame:
    """Normalize each disaster's perplexity relative to its pre-period mean."""
    # Compute pre-period mean for each disaster
    pre_means = (
        event_df.filter(pl.col("relative_day").is_between(-30, -1))
        .group_by("disaster_number")
        .agg(pl.col("ppl").mean().alias("baseline_ppl"))
    )

    # Drop disasters with no pre-period data
    pre_means = pre_means.filter(~pl.col("baseline_ppl").is_nan())

    event_df = event_df.join(pre_means, on="disaster_number", how="inner")
    event_df = event_df.with_columns(
        (pl.col("ppl") - pl.col("baseline_ppl")).alias("ppl_deviation"),
        (pl.col("ppl") / pl.col("baseline_ppl") - 1).alias("ppl_pct_change"),
    )

    print(f"  After normalization: {event_df['disaster_number'].n_unique()} disasters with baselines")
    return event_df


def plot_event_study(event_df: pl.DataFrame, output_path: Path, window: int = 30):
    """Generate event study figure."""
    # Average across disasters for each relative day
    daily_avg = (
        event_df.group_by("relative_day")
        .agg(
            pl.col("ppl_deviation").mean().alias("mean_deviation"),
            pl.col("ppl_deviation").std().alias("std_deviation"),
            pl.col("ppl_deviation").len().alias("n_disasters"),
        )
        .sort("relative_day")
    )

    days = daily_avg["relative_day"].to_numpy()
    means = daily_avg["mean_deviation"].to_numpy()
    stds = daily_avg["std_deviation"].to_numpy()
    ns = daily_avg["n_disasters"].to_numpy()
    ses = stds / np.sqrt(ns)

    # 7-day rolling average (manual, avoids scipy dependency)
    kernel = 7
    smoothed = np.convolve(means, np.ones(kernel) / kernel, mode="same")
    # Fix edges: use narrower windows at boundaries
    for i in range(kernel // 2):
        smoothed[i] = np.mean(means[:i + kernel // 2 + 1])
        smoothed[-(i + 1)] = np.mean(means[-(i + kernel // 2 + 1):])

    fig, ax = plt.subplots(figsize=(8, 5))

    # Raw daily averages (light)
    ax.scatter(days, means, color="#999999", s=8, alpha=0.5, zorder=2, label="Daily mean")

    # Smoothed line
    ax.plot(days, smoothed, color="#2166AC", linewidth=2, zorder=3, label="7-day moving average")

    # CI band on smoothed
    smoothed_se = np.convolve(ses, np.ones(kernel) / kernel, mode="same")
    ax.fill_between(days, smoothed - 1.96 * smoothed_se, smoothed + 1.96 * smoothed_se,
                     color="#2166AC", alpha=0.15, zorder=1)

    # Reference line at 0
    ax.axhline(y=0, color="black", linewidth=0.5, linestyle="-")

    # Disaster declaration marker
    ax.axvline(x=0, color="#B2182B", linewidth=1.5, linestyle="--", alpha=0.7,
               label="Disaster declaration")

    # Shading for event window
    ax.axvspan(0, 7, color="#B2182B", alpha=0.05)

    ax.set_xlabel("Days relative to disaster declaration", fontsize=11)
    ax.set_ylabel("Perplexity deviation from pre-period mean", fontsize=11)
    ax.set_xlim(-window, window)
    ax.legend(frameon=False, fontsize=9)

    # Add N annotation
    mean_n = int(np.mean(ns))
    ax.text(0.02, 0.98, f"N = {event_df['disaster_number'].n_unique()} disasters",
            transform=ax.transAxes, fontsize=9, va="top", color="#666666")

    plt.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", dpi=300)
    plt.close()
    print(f"  Saved figure to {output_path}")


def summarize_windows(event_df: pl.DataFrame):
    """Print summary statistics by window."""
    windows = {
        "Pre (-30 to -1)": (-30, -1),
        "Event (0 to +7)": (0, 7),
        "Post (+8 to +30)": (8, 30),
    }

    print("\n=== EVENT STUDY SUMMARY ===")
    print(f"{'Window':<20} {'Mean PPL dev':>12} {'SE':>8} {'N days':>8}")

    for name, (lo, hi) in windows.items():
        w = event_df.filter(pl.col("relative_day").is_between(lo, hi))
        # Average across disasters first, then across days
        by_disaster = (
            w.group_by("disaster_number")
            .agg(pl.col("ppl_deviation").mean())
        )
        mean_dev = by_disaster["ppl_deviation"].mean()
        std_dev = by_disaster["ppl_deviation"].std()
        n = len(by_disaster)
        se = std_dev / (n ** 0.5) if n > 0 else float("nan")
        print(f"{name:<20} {mean_dev:>12.3f} {se:>8.3f} {n:>8}")


def main():
    parser = argparse.ArgumentParser(description="FEMA crisis event study")
    parser.add_argument("--output-dir", default=str(PROJECT_ROOT / "figures"),
                        help="Directory for output figure")
    parser.add_argument("--window", type=int, default=30,
                        help="Days before/after disaster declaration")
    parser.add_argument("--isolate", action="store_true",
                        help="Only use disasters with no prior disaster within window days")
    args = parser.parse_args()

    ppl_df, fema_df = load_data()

    if args.isolate:
        fema_df = filter_isolated_disasters(fema_df, buffer_days=args.window)

    event_df = compute_event_study(ppl_df, fema_df, window=args.window)
    event_df = normalize_to_baseline(event_df)

    # Save detailed results
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    event_df.write_parquet(RESULTS_DIR / "crisis_event_study.parquet")
    print(f"  Saved event study data to {RESULTS_DIR / 'crisis_event_study.parquet'}")

    # Plot
    output_path = Path(args.output_dir) / "fema_event_study.pdf"
    plot_event_study(event_df, output_path, window=args.window)

    # Summary
    summarize_windows(event_df)


if __name__ == "__main__":
    main()
