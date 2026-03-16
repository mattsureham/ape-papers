# Research Plan: Regulatory Bunching at the MEES Threshold

## Research Question
Do England's Minimum Energy Efficiency Standards (MEES) — which prohibit letting properties rated F or G (EPC score <39) — produce genuine energy efficiency improvements, or primarily strategic bunching through assessor gaming? We use the Kleven (2016) bunching framework applied to 28.9M domestic EPCs with a difference-in-bunching design comparing rental (regulated) vs. sale (unregulated) properties.

## Identification Strategy
**Bunching estimator** at score 39 (E/F boundary). Under the null of no behavioral response, the score distribution should be smooth through 39. Under MEES, we expect excess mass just above 39 (scores 39-44) and a missing mass below (scores 33-38) among rental properties.

**Difference-in-bunching:** Rental properties face MEES; sale properties do not. The sale distribution serves as a within-period placebo. Excess bunching = rental bunching − sale bunching at score 39.

**Temporal variation:**
- Pre-announcement (2008-2015): no MEES effect expected → placebo
- Post-announcement / pre-implementation (2015-2018): anticipatory bunching possible
- Post-implementation (2018-2025): full MEES effect

**Placebo thresholds:** D/E boundary (score 55), C/D boundary (score 69) — no regulatory bite → should show no differential bunching.

## Expected Effects
- **Positive excess mass** at 39-44 among rental properties post-2018
- **Missing mass** at 33-38 among rental properties
- **No differential bunching** at placebo thresholds (55, 69)
- If gaming dominates: bunching concentrated in exact scores 39-40; assessor concentration
- If genuine improvement: bunching spread over 39-50; accompanied by actual retrofit activity

## Primary Specification
Polynomial bunching estimator following Kleven & Waseem (2013):
- Fit polynomial (order 7) to EPC score density excluding bunching region [33, 44]
- Estimate excess mass B = (observed − counterfactual) / counterfactual at bunching region
- Bootstrap standard errors (500 replications)
- Difference-in-bunching: B_rental − B_sale

## Data Sources
1. **GOV.UK EPC Live Tables D1**: LA-level quarterly EPC band counts (2008-2024). ~23,000 rows. Direct ODS download.
2. **GOV.UK EPC Live Tables D4B**: Transaction type (rental/sale) by LA quarterly. Direct ODS download.
3. **EPC Register API** (opendatacommunities.org): Individual-level EPCs with integer CURRENT_ENERGY_EFFICIENCY score, TRANSACTION_TYPE, LODGEMENT_DATE, LOCAL_AUTHORITY. Free registration required.

**Fetch strategy:** Use Live Tables D1 and D4B for aggregate time series. Use EPC Register API for individual-level score distributions needed for bunching estimation.

## Exposure Alignment
MEES directly affects landlords of F/G-rated rental properties. Treatment intensity varies across LAs because rental market composition varies: London boroughs and university towns have rental shares exceeding 50%, while rural districts may be below 20%. The treatment timing is uniform (April 2018 for new tenancies, April 2020 for all). The outcome (F+G share of EPC lodgements) measures the mix of assessed properties, not the underlying housing stock — this distinction is central to the measurement effect we identify. Landlords without current EPCs were forced to obtain them for compliance, expanding the assessed population differentially in high-rental areas.

## Key Risks
1. EPC Register API may have rate limits or registration barriers → fallback: use D1 band-level data for coarser analysis
2. Scores may cluster at round numbers (multiples of 5/10) independent of MEES → control with pre-period distribution
3. Assessor heterogeneity may confound → include assessor FE if data available
