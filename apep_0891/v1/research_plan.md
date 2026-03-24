# Research Plan: The Housing Cliff — SNAP Emergency Allotment Expiration and Eviction Filing Surges

## Research Question

Did the staggered expiration of SNAP Emergency Allotments (EA) across states cause an increase in eviction filings? The EA expiration reduced monthly food benefits by $95–250 per household for 42 million Americans — the largest simultaneous benefit reduction in U.S. safety net history. If this income shock cascaded from food budgets to rent non-payment, it reveals a cross-program spillover that standard cost-benefit analyses of SNAP miss entirely.

## Identification Strategy

**Primary Design:** Callaway-Sant'Anna (2021) staggered difference-in-differences exploiting the fact that 18 states opted out of SNAP EA between April 2021 and January 2023, while 32 states + DC retained EA until Congress terminated the program after February 2023.

**Treatment variation:** State-level opt-out dates (binary: EA ended vs. still active). Treatment cohorts defined by the month each state terminated EA.

**Key identification layers:**
1. **Event study** with 60–100 pre-treatment weeks to document parallel pre-trends
2. **Dose-response:** Interact treatment with tract-level SNAP participation rate (ACS B22003). High-SNAP tracts should show larger effects.
3. **Income placebo:** High-income tracts (top quartile median income) should show no effect.
4. **Callaway-Sant'Anna** handles staggered adoption, avoids forbidden comparisons, and provides group-time ATTs.

**Inference:** Cluster at state level (50 states). Wild cluster bootstrap (fwildclusterboot or boottest) for robustness. Randomization inference permuting state-level opt-out assignment.

## Expected Effects

- **Positive effect on eviction filings** in early opt-out states after EA expiration
- **Larger effects in high-SNAP-participation tracts** (dose-response)
- **No effect in high-income tracts** (placebo)
- **Effect should appear within 1–3 months** (typical eviction filing lag after missed rent)

## Primary Specification

Y_{s,t} = tract-level weekly eviction filing count (or rate per renter-occupied unit)
Treatment = 1[state s opted out of EA by week t]
Method = Callaway-Sant'Anna ATT(g,t) aggregated to overall ATT
Controls = tract and week fixed effects (absorbed by CS estimator)
Clustering = state level

## Data Sources

1. **Eviction Lab Eviction Tracking System (ETS):** Tract-level weekly eviction filing counts, ~41 cities, 25+ states, Dec 2019–present. ODC-BY 1.0 license, freely downloadable.
2. **Census ACS (API):** Tract-level SNAP participation rates (B22003), renter-occupied housing units (B25003), median household income (B19013).
3. **SNAP EA opt-out dates:** USDA FNS records + CBPP documentation of state-by-state EA termination dates.

## Fetch Strategy

1. Download Eviction Lab ETS bulk data (CSV)
2. Fetch ACS tract-level variables via Census API (2019 5-year estimates for pre-treatment characteristics)
3. Construct state-level EA treatment dates from USDA/CBPP records
4. Merge all at tract-week level
