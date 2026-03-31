# Research Plan: Cross-Border Subsidy Dumping

## Research Question
How does Germany's stepwise tightening of the EEG subsidy clawback threshold affect bilateral electricity exports to neighboring countries during negative-price episodes?

## Policy Setting
Germany's EEG § 51 clawback: if day-ahead electricity prices are negative for N+ consecutive hours, renewable generators (>400 kW) lose their market premium for *all hours* of that episode. Threshold tightened:
- Pre-2021: 6 consecutive hours
- 2021–2023: 4 consecutive hours
- 2024+: 3 consecutive hours

Key mechanism: shorter threshold → clawback applies to more episodes → generators curtail output earlier → less excess electricity exported to neighbors.

## Identification Strategy
**Cross-threshold DiD.** Episode duration determines clawback eligibility. The policy change shifts which episodes trigger clawback:
- **Treatment group (2021 reform):** Episodes of 4–5 negative hours (newly subject to clawback)
- **Control group:** Episodes of 1–3 negative hours (never subject to clawback under either regime)
- **Before:** 2019–2020 (6h regime)
- **After:** 2021–2023 (4h regime)

Second treatment (2024 reform):
- **Treatment:** Episodes of exactly 3 negative hours
- **Control:** Episodes of 1–2 negative hours

**Neighbor heterogeneity:** 11 bilateral pairs, varying in interconnector capacity and own clawback rules.

**Cross-country placebos:** Bilateral pairs not connected to Germany (e.g., FR-ES, DK-NO) should show no effect.

## Exposure Alignment and Treatment Assignment
Treatment exposure is determined by episode duration crossing the clawback threshold. Treatment timing is sharp (January 2021, January 2024) and applies uniformly to all renewable generators >400 kW in the DE-LU bidding zone. The affected population is every renewable generator eligible for the market premium during negative-price episodes. Cross-border flows for all 11 neighbors are simultaneously affected because Germany is the common exporter. No staggered adoption across units — all episodes face the same threshold at the same time. Treatment assignment is determined by a combination of policy regime (time) and episode characteristics (duration), ensuring no self-selection into treatment conditional on episode duration.

## Expected Effects
- Negative effect on German exports during treated episodes (fewer MW exported)
- Larger effects for neighbors with high interconnector capacity (FR, AT, CH)
- No effect on flows during short episodes (below all thresholds)
- Null on non-German bilateral pairs (placebos)

## Primary Specification
Y_{ept} = α + β(Treated_e × Post_t) + γ_p + δ_t + ε_{ept}

Where e = episode, p = bilateral pair, t = time period (regime).
Y = average bilateral flow (MW) during episode.
Treated_e = 1 if episode duration in [new_threshold, old_threshold).
γ_p = bilateral pair FE, δ_t = year-month FE.
Cluster SEs at the month level.

## Data Sources
1. **Fraunhofer ISE Energy-Charts API** (open access, CC BY 4.0)
   - Day-ahead prices: `api.energy-charts.info/price` for DE-LU bidding zone
   - Bilateral flows: `api.energy-charts.info/cbet` for Germany ↔ 11 neighbors
   - Resolution: hourly (prices), 15-min (flows, aggregated to hourly)
   - Period: 2019-01-01 to 2025-03-31

2. **Neighbors:** AT, BE, CH, CZ, DK, FR, LU, NL, NO, PL, SE

## File Structure
- `00_packages.R` — Library loading
- `01_fetch_data.R` — API data acquisition
- `02_clean_data.R` — Episode construction and classification
- `03_main_analysis.R` — DiD estimation
- `04_robustness.R` — Placebo tests, sensitivity
- `05_tables.R` — Table generation (including SDE)
