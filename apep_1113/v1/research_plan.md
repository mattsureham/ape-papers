# Research Plan: The Admissions Illusion — SFFA v. Harvard and the Racial Composition of College Enrollment

## Research Question

Did the Supreme Court's June 2023 ban on race-conscious admissions (SFFA v. Harvard) change the racial composition of college enrollment, and does the effect vary with institutional selectivity?

## Why It Matters

SFFA v. Harvard is the most consequential US higher education policy change in decades. Proponents of affirmative action predicted catastrophic declines in minority enrollment at selective institutions. Early smoke tests from IPEDS suggest the aggregate effects may be surprisingly muted — Black enrollment shares at highly selective schools barely changed (5.58% → 5.93% from 2020 to 2024). This raises a fundamental question: was race-conscious admissions less consequential than assumed, or did schools rapidly adopt race-neutral alternatives?

## Identification Strategy

**Continuous treatment intensity DiD.** Not all institutions used race-conscious admissions equally. Treatment intensity is proxied by pre-SFFA selectivity: highly selective schools (admit rate <25%) were most likely to practice race-conscious admissions; open-access schools (admit rate >70%) had no reason to. This continuous measure avoids arbitrary binning and exploits the full institutional spectrum.

**Formal specification:**

Y_{it} = α_i + γ_t + β(Intensity_i × Post_t) + X_{it}δ + ε_{it}

Where:
- Y_{it} = URM enrollment share (Black, Hispanic) at institution i in year t
- Intensity_i = 1 − (pre-SFFA average admit rate, 2019-2022)
- Post_t = 1{t ≥ Fall 2024} (first full post-SFFA cohort)
- X_{it} = time-varying controls (total enrollment, public/private, state-year FE)
- α_i = institution FE, γ_t = year FE

**Triple-difference (DDD):** Selectivity tier × Post-SFFA × URM vs. non-URM share — ensures effects are driven by changes in racial composition, not overall enrollment shifts.

**Cascade test:** If selective schools lose URM students, do the next selectivity tier gain them? Estimate the model separately by selectivity quartile to test for "cascade" effects down the selectivity ladder.

## Placebos

1. **Prior-ban states:** California (1996), Washington (1998), Michigan (2006), etc. already banned race-conscious admissions. Institutions in these states should show zero additional SFFA effect — they were "already treated."
2. **HBCUs:** Historically Black Colleges and Universities do not practice race-conscious admissions favoring URMs. Null effect expected.
3. **Pre-trend test:** Event study with leads/lags using 2019-2022 as pre-period. All pre-treatment coefficients should be zero.

## Expected Effects and Mechanisms

**If race-conscious admissions was binding:** Large negative effect on URM share at selective schools (SDE < -0.15), with cascade to less-selective tiers.

**If schools adapted via race-neutral alternatives:** Muted or null effect. Schools substituted socioeconomic criteria, test-optional policies, or targeted recruitment to maintain diversity without explicit race consideration.

**If both:** Heterogeneity across institution types — private elites may adapt faster (endowments, recruitment budgets) than public flagships.

## Primary Specification

Callaway-Sant'Anna or Sun-Abraham event study is not directly applicable here (treatment is simultaneous nationally). Instead, use:
1. **TWFE with continuous intensity** — appropriate because treatment timing is common (SFFA affects all institutions at once)
2. **Interaction-weighted estimator** — interact selectivity deciles with post indicator
3. **Cluster at state level** — policy enforcement and admissions practices cluster by state

## Data Source and Fetch Strategy

**IPEDS on Azure DuckDB** (confirmed in idea manifest: `raw/ipeds/ipeds.duckdb`):
- `effy`: 12-month enrollment by race/ethnicity, 2011-2024
- `v_admission_rates`: admit rate by institution-year
- `hd`: institution characteristics (state, HBCU indicator, sector)
- `c_a`: Completions by race (for cascade/field-of-study tests)

All data confirmed present through 2024 (first full post-SFFA cohort).

**Prior-ban state classification:** Manual coding from legislation — CA (1996), WA (1998), FL (1999), MI (2006), NE (2008), AZ (2010), NH (2012), OK (2012), ID (2020).

## Sample

~6,000 institutions × 6 years (2019-2024). Restrict to Title IV degree-granting institutions. Drop institutions with <100 total enrollment (unstable shares).
