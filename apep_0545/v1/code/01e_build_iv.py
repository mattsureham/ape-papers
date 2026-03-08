#!/usr/bin/env python3
"""
01e_build_iv.py
Build improved competing-news IV measures.

Three IV strategies:
1. Cross-sector competing news: for each agency, sum incident coverage of ALL OTHER agencies
   (e.g., for EPA, competing news = FAA + MSHA + NHTSA + NRC + ... incidents)
   This is the natural Eisensee-Strömberg instrument applied correctly.

2. Pre-scheduled events IV: quarterly indicator for Olympics, major elections,
   Super Bowl, major non-regulatory news (identified ex ante).
   These events are exogenous to regulatory activity.

3. Total news volume: log total GKG volume as a control, to separate
   incident coverage growth from overall news growth.

Output: data/iv_enhanced.csv (merged with panel_clean.csv in 02b_clean_iv.R)
"""

import pandas as pd
import numpy as np
from pathlib import Path

data_dir = Path(__file__).parent.parent / "data"

# ============================================================
# LOAD EXISTING DATA
# ============================================================

gdelt_df = pd.read_csv(data_dir / "gdelt_agency_quarter.csv")
competing_df = pd.read_csv(data_dir / "gdelt_competing_news.csv")

print("=== BUILDING ENHANCED IV MEASURES ===")

# ============================================================
# IV STRATEGY 1: Cross-sector competing news
# For each agency-quarter, competing news = sum of other agencies' incident coverage
# This is the true Eisensee-Strömberg instrument:
# When aviation has a crash, OSHA gets less news attention (zero-sum attention)
# ============================================================

print("[1/3] Building cross-sector competing news IV...")

# Reshape: agency_id × (year, quarter) → wide
pivot = gdelt_df.pivot_table(
    index=['year', 'quarter'],
    columns='agency_id',
    values='incident_articles',
    aggfunc='sum'
).reset_index()

print(f"Pivot shape: {pivot.shape}")

agencies = [c for c in pivot.columns if c not in ['year', 'quarter']]

# For each agency, cross-sector competing news = sum of all other agencies' incidents
cross_sector_rows = []
for agency in agencies:
    other_agencies = [a for a in agencies if a != agency]
    for _, row in pivot.iterrows():
        cross_competing = sum(row[a] for a in other_agencies if pd.notna(row[a]))
        cross_sector_rows.append({
            'agency_id': agency,
            'year': int(row['year']),
            'quarter': int(row['quarter']),
            'cross_sector_competing': cross_competing,
        })

cross_df = pd.DataFrame(cross_sector_rows)
print(f"Cross-sector IV shape: {cross_df.shape}")

# Descriptive check
print("\nCross-sector competing news by agency (mean):")
print(cross_df.groupby('agency_id')['cross_sector_competing'].mean().sort_values(ascending=False).to_string())

# ============================================================
# IV STRATEGY 2: Pre-scheduled events IV
# These events are known ex ante → exogenous to regulatory calendar
# High values = more news competition → lower agency incident salience
# ============================================================

print("\n[2/3] Building pre-scheduled events IV...")

# Known pre-scheduled events by quarter (1994-2024)
# Source: historical record of Olympic Games, Super Bowl months
# OLYMPICS: Summer/Winter Games; ELECTIONS: US presidential + midterm election quarters
# DATA: manually coded from historical records (pre-scheduled = exogenous)

scheduled_events = []

# Summer Olympics (always July-September = Q3)
for year in [2016, 2020, 2024]:  # years in study period
    scheduled_events.append({'year': year, 'quarter': 3, 'event': 'summer_olympics', 'intensity': 1.0})

# Winter Olympics (always Jan-Feb = Q1)
for year in [2018, 2022]:  # years in study period
    scheduled_events.append({'year': year, 'quarter': 1, 'event': 'winter_olympics', 'intensity': 1.0})

# Presidential elections (November = Q4)
for year in [2016, 2020, 2024]:
    scheduled_events.append({'year': year, 'quarter': 4, 'event': 'presidential_election', 'intensity': 1.5})

# Midterm elections (November = Q4)
for year in [2018, 2022]:
    scheduled_events.append({'year': year, 'quarter': 4, 'event': 'midterm_election', 'intensity': 1.0})

# Super Bowl (always Q1, January or February)
for year in range(2015, 2025):
    scheduled_events.append({'year': year, 'quarter': 1, 'event': 'super_bowl', 'intensity': 0.5})

events_df = pd.DataFrame(scheduled_events)

# Aggregate to quarter level
quarter_events = events_df.groupby(['year', 'quarter']).agg(
    n_scheduled_events = ('event', 'count'),
    event_intensity = ('intensity', 'sum'),
    has_olympics = ('event', lambda x: int(any('olympics' in e for e in x))),
    has_election = ('event', lambda x: int(any('election' in e for e in x))),
).reset_index()

# Fill zeros for quarters without scheduled events
all_quarters = pd.DataFrame(
    [(y, q) for y in range(2015, 2025) for q in range(1, 5)],
    columns=['year', 'quarter']
)
quarter_events = all_quarters.merge(quarter_events, on=['year','quarter'], how='left').fillna(0)

print("Scheduled events by quarter:")
print(quarter_events[quarter_events['n_scheduled_events'] > 0].to_string())

# ============================================================
# IV STRATEGY 3: Continuous news competition from natural disasters
# Natural disasters are exogenous to regulatory policy,
# but drive massive news consumption → crowd out regulatory incident coverage
# ============================================================

print("\n[3/3] Natural disaster IV from GDELT...")

# We already have natural_disaster_coverage in competing_df
# Normalize by total volume to get disaster news SHARE
competing_df['nat_disaster_share'] = competing_df['natural_disaster_coverage'] / competing_df['total_articles']
competing_df['election_share'] = competing_df['election_coverage'] / competing_df['total_articles']
competing_df['sports_share'] = competing_df['sports_coverage'] / competing_df['total_articles']
competing_df['conflict_share'] = competing_df['conflict_coverage'] / competing_df['total_articles']

# COMPOSITE IV: natural disasters + scheduled elections (leave out sports/conflict as potentially endogenous)
competing_df['exogenous_competition'] = (
    competing_df['natural_disaster_coverage'] +
    competing_df['election_coverage']
) / competing_df['total_articles']

# ============================================================
# MERGE ALL IV MEASURES
# ============================================================

# Merge cross-sector into panel
panel = pd.read_csv(data_dir / "panel_clean.csv")

panel = panel.merge(cross_df, on=['agency_id', 'year', 'quarter'], how='left')
panel = panel.merge(quarter_events[['year', 'quarter', 'n_scheduled_events', 'event_intensity',
                                     'has_olympics', 'has_election']],
                    on=['year', 'quarter'], how='left')
panel = panel.merge(competing_df[['year', 'quarter', 'nat_disaster_share', 'election_share',
                                    'exogenous_competition']],
                    on=['year', 'quarter'], how='left')

# Log-transform cross-sector competing news
panel['log_cross_sector'] = np.log(panel['cross_sector_competing'] + 1)
panel['log_exog_comp'] = np.log(panel['exogenous_competition'] * 1e6 + 1)

# Check first-stage correlations
print("\n--- FIRST-STAGE DIAGNOSTICS ---")
print("Correlation between IV and treatment (incident_articles):")
print(f"  Cross-sector competing: {panel['cross_sector_competing'].corr(panel['incident_articles']):.4f}")
print(f"  Natural disaster share: {panel['nat_disaster_share'].corr(panel['incident_articles']):.4f}")
print(f"  Election share: {panel['election_share'].corr(panel['incident_articles']):.4f}")
print(f"  Has olympics: {panel['has_olympics'].corr(panel['incident_articles']):.4f}")
print(f"  Has election: {panel['has_election'].corr(panel['incident_articles']):.4f}")
print(f"  Event intensity: {panel['event_intensity'].corr(panel['incident_articles']):.4f}")

# Within-agency correlation (what matters for FE estimation)
print("\nWithin-agency correlation (demeaned):")
for iv_name in ['cross_sector_competing', 'nat_disaster_share', 'election_share', 'event_intensity']:
    panel_dm = panel.copy()
    panel_dm[iv_name] = panel_dm.groupby('agency_id')[iv_name].transform(lambda x: x - x.mean())
    panel_dm['incident_articles_dm'] = panel_dm.groupby('agency_id')['incident_articles'].transform(lambda x: x - x.mean())
    corr = panel_dm[iv_name].corr(panel_dm['incident_articles_dm'])
    print(f"  {iv_name}: {corr:.4f}")

# Also check: within-year correlation (quarter FE)
print("\nWithin-year, within-agency residual correlations:")
panel_wfe = panel.copy()
for col in ['cross_sector_competing', 'nat_disaster_share', 'incident_articles']:
    panel_wfe[f'{col}_dm'] = (panel_wfe.groupby(['agency_id', 'year'])[col]
                                .transform(lambda x: x - x.mean()))
print(f"  Cross-sector vs incident (agency+year FE): "
      f"{panel_wfe['cross_sector_competing_dm'].corr(panel_wfe['incident_articles_dm']):.4f}")

# Save enhanced panel
panel.to_csv(data_dir / "panel_with_iv.csv", index=False)
print(f"\nSaved enhanced panel: {len(panel)} rows → {data_dir / 'panel_with_iv.csv'}")
print("\n=== IV CONSTRUCTION COMPLETE ===")
