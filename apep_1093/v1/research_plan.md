# Research Plan: apep_1093

## Research Question

Do salary-range-in-job-posting mandates reduce the Black-White new-hire earnings gap? If so, is the effect driven by leveling (Black wages rising) or compression (White wages falling), and is it concentrated in industries where pre-treatment pay dispersion was largest?

## Policy Setting

Six US states adopted salary-range posting mandates in staggered sequence:
- Colorado: January 1, 2021
- Washington: January 1, 2023
- California: January 1, 2023
- New York: September 17, 2023 (NYC was June 2022, but statewide is Sept 2023)
- Hawaii: January 1, 2024
- Illinois & Minnesota: January 1, 2025

Remaining ~44 states serve as never-treated controls.

## Identification Strategy

**Triple-difference (DDD):** state × post-law × high-pay-dispersion industry.

- **First difference:** Pre vs post salary-range mandate adoption
- **Second difference:** Treated vs never-treated states
- **Third difference:** High-dispersion industries (professional services NAICS 541, finance 522, information 511) vs low-dispersion industries (food services 722, retail 445, accommodation 721)

The third difference isolates the mechanism: transparency should have larger effects where there was more pre-treatment wage-setting discretion. It also absorbs state × time shocks common to all industries.

**Estimator:** Callaway-Sant'Anna (2021) for the main DiD, with a stacked DDD for the triple-difference. Event study dynamics for visual pre-trend validation.

**Threats:**
1. Concurrent labor market policies — control via state × quarter FE in DDD
2. COVID recovery differential — pre-period starts 2018Q1 (pre-COVID has 2 years)
3. Composition changes in who gets hired — test using hiring counts and separation rates

## Outcome Variables

From QWI race/ethnicity × 3-digit NAICS (Azure `derived/qwi/rh/n3/`):
1. **EarnHirAS** — Average monthly earnings of all new hires (primary)
2. **HirA** — Hiring counts (extensive margin)
3. **Sep** — Separations (retention channel)

Main estimand: ln(EarnHirAS_Black) - ln(EarnHirAS_White) = racial new-hire earnings gap

## Expected Effects and Mechanisms

- **Leveling hypothesis:** Mandated salary ranges create an anchor. If pre-law Black offers were below the range midpoint, transparency shifts offers upward → gap narrows, driven by Black earnings rising.
- **Compression hypothesis:** Employers compress all offers toward the posted range minimum → gap narrows mechanically, but White wages also fall.
- **Null hypothesis:** Employers game ranges (wide ranges, different titles), or pre-treatment discrimination was in hiring rather than wages → no effect on the earnings gap.

## Data Source and Fetch Strategy

**Primary:** QWI race/ethnicity (rh) × 3-digit NAICS (n3) from Azure Blob Storage
- Path: `derived/qwi/rh/n3/{state}.parquet`
- Already constructed: 51 state files, ~141M county-quarter-industry-race cells
- Query via DuckDB in R (Arrow/DuckDB for out-of-core processing)
- Period: 2018Q1–2024Q4 (7 years, 28 quarters)

**Treatment coding:** Map state FIPS to adoption quarter using the timeline above. States with no mandate are never-treated.

## Primary Specification

```
ln(EarnHirAS)_{c,i,r,t} = β₁(Treated_s × Post_st × HighDisp_i)
                         + β₂(Treated_s × Post_st)
                         + β₃(Treated_s × HighDisp_i)
                         + β₄(Post_st × HighDisp_i)
                         + α_c + γ_t + δ_i + ε_{c,i,r,t}
```

Where:
- c = county, i = 3-digit NAICS, r = race (Black/White), t = quarter
- Treated_s = 1 if state adopted mandate
- Post_st = 1 if quarter ≥ state adoption quarter
- HighDisp_i = 1 if high-dispersion industry
- Clustered SEs at state level (with wild cluster bootstrap for robustness)

## Robustness

1. Event study (leads/lags) for parallel trends
2. Wild cluster bootstrap (few treated clusters)
3. Placebo: Hispanic-White gap (if transparency is race-neutral, similar effects)
4. Drop Colorado (earliest adopter, potential anticipation)
5. Use never-treated controls only (exclude late adopters)
