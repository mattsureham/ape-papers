# Research Plan: The Skill Gradient of Steel Protection

## Research Question

Do Section 232 steel/aluminum tariffs (March 2018) impose downstream employment costs that fall disproportionately on higher-educated workers in manufacturing? The political economy claim is that tariffs protect "working class" jobs — this paper tests whether the downstream burden is actually regressive within manufacturing's education distribution.

## Identification Strategy

**Triple-Difference (DDD):**

Y_{cet} = α_{ce} + α_{et} + α_{ct} + β₁(Exposure_c × Post_t) + β₂(Exposure_c × Post_t × HighEdu_e) + ε_{cet}

Where:
- c = county, e = education group (E1-E4), t = quarter
- α_{ce} = county × education FE (absorb level differences)
- α_{et} = education × time FE (absorb national education trends)
- α_{ct} = county × time FE (absorb ALL non-education-specific county shocks)
- Exposure_c = county's pre-period share of manufacturing employment in downstream steel-using industries (NAICS 332, 333, 336)
- Post_t = 1 if t ≥ 2018Q2
- HighEdu_e = indicator or continuous education measure

The key identifying assumption: conditional on county-time FE and education-time FE, the *relative* change in employment across education groups within a county varies only because of differential downstream exposure. County-time FE absorb local demand shocks, trade shocks, and all county-specific confounders — identification is purely from within-county, between-education variation by exposure intensity.

## Expected Effects and Mechanisms

1. **Main effect (β₁):** Negative — downstream exposure reduces overall employment in affected counties post-tariff
2. **Skill gradient (β₂):** Key estimand — if positive, higher-education workers are disproportionately affected. Smoke test suggests BA+ workers face a 3.0pp gap vs HS workers' 1.8pp gap
3. **Mechanisms:** (a) Higher-education workers in management/engineering roles may face layoffs as orders decline; (b) Production workers (low-education) are retained at reduced hours; (c) Higher-education workers have more outside options and exit faster

## Primary Specification

Callaway-Sant'Anna is not needed here (single treatment date: March 2018). Standard OLS with three-way FE is the primary estimator.

**Event study:** Estimate β₁ and β₂ quarter-by-quarter for 2015Q1-2019Q4 to verify no pre-trends and trace dynamic effects.

**Inference:** Cluster standard errors at the state level (~50 clusters). Robust to county clustering as sensitivity.

## Data Source and Fetch Strategy

1. **QWI education panel:** `az://derived/qwi/se/n3/*.parquet` — county × 3-digit NAICS × education × quarter. Variables: Emp, HirA, Sep, EarnBeg, FrmJbGn, FrmJbLs.
2. **Downstream exposure construction:** From QWI 2016Q1 data — county share of manufacturing employment in NAICS 332 (fabricated metals), 333 (machinery), 336 (transportation equipment) vs total manufacturing.
3. **Steel price data:** FRED API — PPI for steel (WPU1017) to verify tariff pass-through timing.

All data accessible via Azure (QWI) and FRED API (steel prices). No additional API keys needed.

## Analysis Plan

1. Construct county-level downstream exposure from 2016Q1 QWI manufacturing composition
2. Build balanced panel: county × education × quarter, 2015Q1-2019Q4
3. Main DDD regression with county×edu, edu×time, county×time FE
4. Event study with quarter-specific coefficients
5. Heterogeneity by education group (E1 vs E2 vs E3 vs E4)
6. Robustness: alternative exposure measures, dropping 2019Q4, state-level clustering
7. Mechanism: decompose into hires vs separations vs earnings
