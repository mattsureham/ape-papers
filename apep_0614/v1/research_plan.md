# Research Plan: Drawing the Line on Environmental Justice

## Research Question
Does the CEJST disadvantaged community designation — which determines eligibility for Justice40-directed federal investment — causally increase local investment in designated census tracts? Specifically, does crossing the algorithmic designation threshold lead to more EV charger installations and greater mortgage credit access?

## Identification Strategy
**Index-based sharp RDD** at the CEJST income threshold.

CEJST designates a tract as "disadvantaged" if it:
1. Exceeds the 90th percentile in at least one of 8 environmental/climate burden categories, AND
2. Exceeds the 65th percentile for low income (or other socioeconomic indicators)

**Design:** Among tracts that satisfy the environmental burden condition (1), the income percentile determines designation. The running variable is the income percentile score, with the cutoff at the 65th percentile. This creates a sharp RDD where tracts just above the income threshold are designated and tracts just below are not.

**Why it's credible:**
- Thresholds are based on pre-existing 2015-2019 ACS data (no manipulation possible)
- Designation is fully algorithmic (zero bureaucratic discretion)
- Tract boundaries are fixed Census geographies
- The tool was released November 2022 — no anticipation by local actors

## Expected Effects
- **EV chargers:** Designated tracts should receive more Justice40-directed infrastructure investment. Expect a positive discontinuity in new charger installations post-designation.
- **Mortgages:** If investment improves neighborhood quality, HMDA origination rates should increase. Alternatively, if designation signals distress, lenders may pull back (negative effect).
- **Mechanism:** The key channel is whether the algorithmic designation actually directs federal dollars. The 518 covered programs span energy, transportation, housing, and environmental remediation.

## Primary Specification
Local linear regression using rdrobust:
Y_i = α + τD_i + β₁(X_i - c) + β₂D_i(X_i - c) + ε_i

Where:
- Y_i = outcome (new EV chargers, mortgage origination rate)
- D_i = 1[designated as disadvantaged]
- X_i = income percentile score
- c = 65th percentile cutoff

## Data Sources
1. **CEJST:** ArcGIS Feature Service or direct CSV download (~73,000 tracts with scores)
2. **NREL AFDC:** EV charging station locations with open_date (85,755 stations)
3. **HMDA:** CFPB tract-level mortgage data (2021-2024)
4. **ACS:** Census tract demographics for covariates and balance tests

## Robustness Checks
- McCrary density test at the income cutoff
- Covariate balance (demographics, housing values)
- Bandwidth sensitivity (multiple bandwidths around MSE-optimal)
- Placebo cutoffs at non-binding income percentiles
- Donut RDD excluding observations closest to cutoff
- Alternative outcomes (mortgage denials, loan amounts)

## Feasibility Assessment
- Sample: ~27,000 designated tracts, ~15,000-20,000 in the RDD bandwidth
- Treatment window: Nov 2022 – Jan 2025 (26 months)
- Data: All sources publicly available via API (confirmed in smoke test)
- Risk: Short treatment window may yield small/null effects. A well-powered null is still informative.
