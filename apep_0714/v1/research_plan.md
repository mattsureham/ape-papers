# Research Plan: apep_0714

## Research Question
Does automatic marijuana expungement — beyond legalization per se — raise Black employment and earnings?

States that legalized recreational marijuana without automatic expungement (CO, WA, OR, AK) provide a unique counterfactual: we can compare Black labor market outcomes in states that removed criminal records automatically (CA 2019, IL 2020, NJ/VA/NY 2021) against states that legalized but left prior marijuana conviction records intact.

## Identification Strategy

**Triple Difference (DDD):**
```
Y_{c,r,t} = α + β(Expunge_s × Black_r × Post_t)
              + γ(Legal_s × Black_r × Post_t)
              + δ(Expunge_s × Post_t)
              + θ(Black_r × Post_t)
              + county FE + race-year FE + state-year FE + ε
```

- D1: State has automatic expungement law (vs. legalize-only states)
- D2: Race = Black (vs. White workers)
- D3: Post-treatment period (staggered: CA 2019, IL 2020, NJ/VA/NY 2021)

The β coefficient identifies whether expunge states saw ADDITIONAL Black employment/earnings gains beyond:
1. What legalization alone produced (γ)
2. Differential nationwide trends by race (θ)
3. Post-legalization state-level trends (δ)

**Main estimator:** Callaway-Sant'Anna (2021) staggered DiD for transparency on timing; TWFE for baseline comparison.

## Treatment and Comparison Groups

**Treatment (legalize + automatic expungement):**
- California (AB 1793, signed Sep 2018, records cleared Jan 2019)
- Illinois (Cannabis Regulation and Tax Act, Jun 2019, automatic expunge Jan 2020)
- New Jersey (signed Feb 2021, automatic expunge ongoing)
- Virginia (MRTA effective Jul 2021)
- New York (MRTA signed Mar 2021)

**Comparison (legalize only, no automatic expungement):**
- Colorado (retail Jan 2014, petition-based only through 2022)
- Washington (retail Jul 2014, no automatic expunge through 2022)
- Oregon (retail Oct 2015, petition-based only through 2022)
- Alaska (retail Oct 2016, no automatic expunge through 2022)

**Additional controls:** Never-legalized states (placebo universe for parallel trends verification)

## Expected Effects and Mechanisms

1. **Expungement removes "box-checking" barrier**: Many employers conduct background checks; prior marijuana convictions trigger automatic screening-out. Record sealing removes this filter.
2. **Signaling effect**: Employers can no longer observe a marijuana conviction that previously signaled criminality.
3. **Job search intensity**: Workers with cleared records may expand job search to include employers with background-check requirements.

Expected direction: β > 0 for Black employment; β > 0 for Black earnings.

We do NOT expect effects to be immediate (records take time to be sealed; employer screening adapts with lag). Dynamic DiD estimands (Callaway-Sant'Anna) will trace this.

## Primary Specification

Main table: County × race × quarter panel, 2014-2023.
- DV 1: log(Black employment) / log(White employment) ratio
- DV 2: log(Black earnings) / log(White earnings) ratio
- DV 3: Black employment level (county-quarter)
- DV 4: Black earnings level (county-quarter)

Clustering: State × race (to account for within-state-race serial correlation)

## Data Source and Fetch Strategy

**Primary:** Azure QWI Race Panel
- `az://apepdata/derived/qwi/rh/n3/*.parquet` — 460M rows, all 50 states, county×race×quarter
- Race codes: A2=Black, A1=White
- Variables: Emp (employment), EarnS (avg monthly earnings)
- Filters: industry=00 (all industries), firmage=0, firmsize=0, sex=0, agegrp=A00, education=E0
- Years: 2014-2023 (pre-periods: 2014-2018; post: 2019-2023)

**Fetch script:** Use `scripts/lib/azure_data.R` → `apep_azure_connect()` then DuckDB SQL to pull relevant states.

**Auxiliary data:**
- State marijuana legalization dates: self-constructed from legislative records (CA 2016/retail 2018, IL 2019, etc.)
- BLS unemployment rate: FRED API (state-quarter, for time-varying controls)
- County demographics: ACS 5-year (2014-2023, Census API)

## Key Methodological Concerns

1. **Parallel trends**: Pre-trends from 2014-2018 (pre any legalization in treatment states). Will test formally with CS-DiD and event study.
2. **Anticipation effects**: California's AB 1793 was signed Sep 2018 but implemented Jan 2019 — will be careful with cutoff dates.
3. **Spillovers**: Black workers near state borders may have sorted across states if expungement was anticipated. Robustness: drop border counties.
4. **Composition effects**: If expungement changed who works, employment and earnings could move mechanically. Check with population denominators.
5. **Other concurrent policies**: CA Prop 47 (2014) pre-dates our treatment; IL SAFE-T Act (2021) concurrent. Include placebo tests on industries unaffected by criminal record screening (e.g., agriculture).
