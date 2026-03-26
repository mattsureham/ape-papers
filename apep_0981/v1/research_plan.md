# Research Plan: apep_0981

## Research Question
Do Good Samaritan overdose immunity laws increase substance use treatment admissions? Specifically, does removing legal barriers to calling 911 during overdoses create a pipeline from emergency encounters to treatment entry?

## Identification Strategy
**Method:** Callaway-Sant'Anna (2021) staggered difference-in-differences

**Treatment:** Binary absorbing indicator for state Good Samaritan Law (GSL) effective date. 47+ states adopted between 2007 (New Mexico) and 2021 (Texas, Wyoming), providing 10+ adoption cohorts. Never-treated states serve as comparison group initially; not-yet-treated states provide additional support.

**Unit of observation:** State × year

**Parallel trends argument:** States adopted GSLs in response to overdose *mortality* crises, not treatment admission trends. Pre-trends in admissions are thus more plausible than for mortality outcomes. Event-study plots directly test this.

## Primary Specification
ATT(g,t) estimated via Callaway-Sant'Anna, aggregated to:
1. Simple weighted ATT
2. Dynamic event-study (leads/lags)

Outcome: log(opioid treatment admissions per 100K population) at state-year level

Clustering: state level (47+ clusters)

## Mechanism Test (Triple-Difference)
The GSL mechanism operates through 911 calls → ER encounters → healthcare referrals to treatment. TEDS-A records referral source (PSOURCE):
- **Healthcare referrals (PSOURCE=3):** Should increase if GSL → more ER encounters → more referrals
- **Criminal justice referrals (PSOURCE=7):** Should NOT increase (or may decrease) — GSL immunity reduces CJ contact
- **Self-referrals (PSOURCE=1):** Ambiguous — could increase through awareness

The DDD compares (healthcare referral admissions vs. CJ referral admissions) × (pre vs. post GSL). This isolates the 911-call mechanism from general opioid crisis trends.

## Expected Effects
- **Main effect:** Positive — GSLs should increase total opioid treatment admissions
- **Healthcare referrals:** Positive (mechanism channel)
- **CJ referrals:** Null or negative (placebo-like)
- **Magnitude:** Moderate — expect 5-15% increase in healthcare-referred admissions

## Robustness
1. Non-opioid admissions (alcohol, marijuana) as within-state placebo
2. Controls for concurrent policies: PDMP mandates, naloxone access laws, Medicaid expansion
3. Heterogeneity by GSL immunity strength (arrest vs. charge vs. prosecution)
4. CDC WONDER overdose mortality as benchmark outcome
5. Bacon decomposition for TWFE diagnostics

## Data Sources
1. **TEDS-A (Treatment Episode Data Set - Admissions):** SAMHSA, 2006-2022, episode-level. Variables: STFIPS, ADMYR, SUB1 (substance), PSOURCE (referral source). Freely downloadable PUF.
2. **PDAPS Good Samaritan Laws:** Temple University, state-level adoption dates 2007-2023.
3. **CDC WONDER:** State-year opioid overdose deaths for mortality benchmark.
4. **Census population estimates:** State-year denominators for per-capita rates.

## Fetch Strategy
1. Download TEDS-A concatenated files from SAMHSA data archive
2. Construct GSL adoption dates from PDAPS (or hand-code from legislative sources if API unavailable)
3. Pull CDC WONDER compressed mortality from API
4. Pull Census population estimates from Census API
