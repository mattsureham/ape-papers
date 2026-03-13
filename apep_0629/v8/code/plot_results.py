#!/usr/bin/env python3
"""
Publication-quality figures for Congressional LM Paper 1.

Figures:
  1. Speaker identifiability time series (main result)
  2. Perplexity over time (House vs Senate)
  3. Neural vs classical methods comparison
  4. Party confusion dynamics

Usage:
    python plot_results.py
    python plot_results.py --no-show  # save only, don't display
"""

import argparse
from pathlib import Path

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import polars as pl

PROJECT_ROOT = Path(__file__).parent.parent.parent
RESULTS_DIR = PROJECT_ROOT / "results"
FIGURES_DIR = RESULTS_DIR / "figures"

# Publication style
matplotlib.rcParams.update({
    'font.family': 'serif',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 13,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.dpi': 150,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
})

# Color palette
COLORS = {
    'democrat': '#2166ac',
    'republican': '#b2182b',
    'neural': '#1b9e77',
    'svm': '#d95f02',
    'logistic': '#7570b3',
    'random': '#999999',
    'house': '#e66101',
    'senate': '#5e3c99',
    'party': '#2166ac',
    'individual': '#1b9e77',
    'within_party': '#d95f02',
}


def figure1_speaker_identifiability(speaker_df: pl.DataFrame):
    """Main result: Speaker identification accuracy over time."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    years = speaker_df['year'].to_list()

    # Left panel: Party-level accuracy
    party_acc = speaker_df['party_accuracy'].to_list()
    ax1.plot(years, party_acc, 'o-', color=COLORS['party'], linewidth=2,
             markersize=5, label='Model (party)')
    ax1.axhline(0.5, color=COLORS['random'], linestyle='--', alpha=0.7,
                label='Random baseline (50%)')
    ax1.set_xlabel('Year')
    ax1.set_ylabel('Party Classification Accuracy')
    ax1.set_title('A. Party Identification')
    ax1.legend(loc='lower right')
    ax1.set_ylim(0.4, 1.0)
    ax1.grid(True, alpha=0.3)

    # Right panel: Individual-level accuracy
    top1 = speaker_df['top1_accuracy'].to_list()
    top5 = speaker_df['top5_accuracy'].to_list()
    top10 = speaker_df['top10_accuracy'].to_list()
    random_baseline = speaker_df['random_individual_baseline'].to_list()

    ax2.plot(years, top1, 'o-', color=COLORS['individual'], linewidth=2,
             markersize=5, label='Top-1')
    ax2.plot(years, top5, 's--', color=COLORS['within_party'], linewidth=1.5,
             markersize=4, label='Top-5')
    ax2.plot(years, top10, '^:', color=COLORS['svm'], linewidth=1.5,
             markersize=4, label='Top-10')
    ax2.plot(years, random_baseline, color=COLORS['random'], linestyle='--',
             alpha=0.7, label='Random (1/N)')

    ax2.set_xlabel('Year')
    ax2.set_ylabel('Individual Speaker Accuracy')
    ax2.set_title('B. Individual Identification')
    ax2.legend(loc='upper right')
    ax2.set_yscale('log')
    ax2.grid(True, alpha=0.3)

    fig.suptitle('Speaker Identifiability in Congressional Debate, 1994–2024',
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()

    path = FIGURES_DIR / "fig1_speaker_identifiability.pdf"
    fig.savefig(path)
    fig.savefig(path.with_suffix('.png'))
    print(f"Saved {path}")
    return fig


def figure2_perplexity(ppl_df: pl.DataFrame):
    """Perplexity over time by chamber."""
    fig, ax = plt.subplots(figsize=(8, 5))

    # Overall
    all_df = ppl_df.filter(pl.col('chamber') == 'ALL').sort('year')
    ax.plot(all_df['year'].to_list(), all_df['ppl'].to_list(),
            'o-', color='black', linewidth=2, markersize=5, label='All')

    # House
    house_df = ppl_df.filter(pl.col('chamber') == 'H').sort('year')
    if len(house_df) > 0:
        ax.plot(house_df['year'].to_list(), house_df['ppl'].to_list(),
                's--', color=COLORS['house'], linewidth=1.5, markersize=4,
                label='House')

    # Senate
    senate_df = ppl_df.filter(pl.col('chamber') == 'S').sort('year')
    if len(senate_df) > 0:
        ax.plot(senate_df['year'].to_list(), senate_df['ppl'].to_list(),
                '^--', color=COLORS['senate'], linewidth=1.5, markersize=4,
                label='Senate')

    ax.set_xlabel('Year')
    ax.set_ylabel('Perplexity')
    ax.set_title('Language Predictability in Congressional Debate')
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    path = FIGURES_DIR / "fig2_perplexity_timeseries.pdf"
    fig.savefig(path)
    fig.savefig(path.with_suffix('.png'))
    print(f"Saved {path}")
    return fig


def figure3_neural_vs_classical(speaker_df: pl.DataFrame, baseline_df: pl.DataFrame):
    """Compare neural model vs SVM/logistic baselines."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    # Party-level comparison
    years = speaker_df['year'].to_list()
    neural_party = speaker_df['party_accuracy'].to_list()
    ax1.plot(years, neural_party, 'o-', color=COLORS['neural'], linewidth=2,
             markersize=5, label='GPT (neural)')

    # SVM party baseline
    svm_party = baseline_df.filter(pl.col('method') == 'svm_party').sort('year')
    if len(svm_party) > 0:
        ax1.plot(svm_party['year'].to_list(), svm_party['accuracy'].to_list(),
                's--', color=COLORS['svm'], linewidth=1.5, markersize=4,
                label='TF-IDF + SVM')

    # Logistic party baseline
    lr_party = baseline_df.filter(pl.col('method') == 'logistic_party').sort('year')
    if len(lr_party) > 0:
        ax1.plot(lr_party['year'].to_list(), lr_party['accuracy'].to_list(),
                '^--', color=COLORS['logistic'], linewidth=1.5, markersize=4,
                label='TF-IDF + Logistic')

    # Majority baseline
    maj = baseline_df.filter(pl.col('method') == 'majority_party').sort('year')
    if len(maj) > 0:
        ax1.plot(maj['year'].to_list(), maj['accuracy'].to_list(),
                color=COLORS['random'], linestyle='--', alpha=0.7,
                label='Majority class')

    ax1.set_xlabel('Year')
    ax1.set_ylabel('Party Classification Accuracy')
    ax1.set_title('A. Party Classification')
    ax1.legend(loc='lower right')
    ax1.set_ylim(0.4, 1.0)
    ax1.grid(True, alpha=0.3)

    # Individual-level comparison
    neural_ind = speaker_df['top1_accuracy'].to_list()
    ax2.plot(years, neural_ind, 'o-', color=COLORS['neural'], linewidth=2,
             markersize=5, label='GPT (neural)')

    # SVM individual baseline
    svm_ind = baseline_df.filter(pl.col('method') == 'svm_individual').sort('year')
    if len(svm_ind) > 0:
        ax2.plot(svm_ind['year'].to_list(), svm_ind['accuracy'].to_list(),
                's--', color=COLORS['svm'], linewidth=1.5, markersize=4,
                label='TF-IDF + SVM')

    # Prior-turn baseline
    prior = baseline_df.filter(pl.col('method') == 'prior_turn').sort('year')
    if len(prior) > 0:
        ax2.plot(prior['year'].to_list(), prior['accuracy'].to_list(),
                'D--', color='#e7298a', linewidth=1.5, markersize=4,
                label='Prior turn')

    # Random baseline
    random_ind = baseline_df.filter(pl.col('method') == 'random_individual').sort('year')
    if len(random_ind) > 0:
        ax2.plot(random_ind['year'].to_list(), random_ind['accuracy'].to_list(),
                color=COLORS['random'], linestyle='--', alpha=0.7,
                label='Random (1/N)')

    ax2.set_xlabel('Year')
    ax2.set_ylabel('Individual Speaker Accuracy')
    ax2.set_title('B. Individual Identification')
    ax2.legend(loc='upper right')
    ax2.grid(True, alpha=0.3)

    fig.suptitle('Neural vs. Classical Speaker Identification',
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()

    path = FIGURES_DIR / "fig3_neural_vs_classical.pdf"
    fig.savefig(path)
    fig.savefig(path.with_suffix('.png'))
    print(f"Saved {path}")
    return fig


def figure4_party_confusion(speaker_df: pl.DataFrame):
    """Party-level prediction dynamics over time."""
    fig, ax = plt.subplots(figsize=(8, 5))

    years = speaker_df['year'].to_list()
    party_acc = speaker_df['party_accuracy'].to_list()
    within_party = speaker_df['within_party_accuracy'].to_list()

    # Party accuracy = how well model separates D from R
    ax.plot(years, party_acc, 'o-', color=COLORS['party'], linewidth=2,
            markersize=5, label='Cross-party accuracy\n(correct party?)')

    # Within-party accuracy = how well model distinguishes individuals within party
    ax.plot(years, within_party, 's-', color=COLORS['within_party'], linewidth=2,
            markersize=5, label='Within-party accuracy\n(correct individual given party?)')

    # Shaded region = party identity is strong but individual identity is weak
    ax.fill_between(years, within_party, party_acc,
                    alpha=0.15, color=COLORS['party'],
                    label='Party uniformity gap')

    ax.set_xlabel('Year')
    ax.set_ylabel('Accuracy')
    ax.set_title('Party vs. Individual Identity in Congressional Speech')
    ax.legend(loc='center right')
    ax.set_ylim(0, 1.0)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    path = FIGURES_DIR / "fig4_party_confusion.pdf"
    fig.savefig(path)
    fig.savefig(path.with_suffix('.png'))
    print(f"Saved {path}")
    return fig


def main():
    parser = argparse.ArgumentParser(description="Generate publication figures")
    parser.add_argument("--no-show", action="store_true",
                        help="Don't display figures (save only)")
    args = parser.parse_args()

    FIGURES_DIR.mkdir(parents=True, exist_ok=True)

    # Load results
    speaker_path = RESULTS_DIR / "speaker_id_accuracy.parquet"
    ppl_path = RESULTS_DIR / "perplexity_timeseries.parquet"
    baseline_path = RESULTS_DIR / "baseline_accuracy.parquet"

    figures_made = []

    if speaker_path.exists():
        speaker_df = pl.read_parquet(speaker_path)
        print(f"Speaker ID results: {len(speaker_df)} years")
        figures_made.append(figure1_speaker_identifiability(speaker_df))
        figures_made.append(figure4_party_confusion(speaker_df))

        if baseline_path.exists():
            baseline_df = pl.read_parquet(baseline_path)
            print(f"Baseline results: {len(baseline_df)} rows")
            figures_made.append(figure3_neural_vs_classical(speaker_df, baseline_df))
    else:
        print(f"WARNING: {speaker_path} not found. Skipping Figures 1, 3, 4.")

    if ppl_path.exists():
        ppl_df = pl.read_parquet(ppl_path)
        print(f"Perplexity results: {len(ppl_df)} rows")
        figures_made.append(figure2_perplexity(ppl_df))
    else:
        print(f"WARNING: {ppl_path} not found. Skipping Figure 2.")

    if not figures_made:
        print("\nNo results found. Run evaluation scripts first.")
        return

    print(f"\n{len(figures_made)} figures generated in {FIGURES_DIR}/")

    if not args.no_show:
        plt.show()


if __name__ == "__main__":
    main()
