# Research Ideas

## Idea 1: Does Regulating Private Landlords Raise Property Values? Selective Licensing and Housing Markets in England
**Policy:** Selective licensing of private rented housing under Part 3 of the Housing Act 2004 (effective April 2006). English local authorities gained discretionary power to designate areas where all private landlords must obtain a licence, imposing minimum management standards, property condition requirements, and fees (~GBP 500-750 per property over 5 years). 100+ LAs have adopted schemes since 2006, with staggered adoption providing clean identifying variation.
**Outcome:** (i) Residential property transaction prices from HM Land Registry Price Paid Data — 24M+ transactions since 1995 at postcode level. (ii) Anti-social behaviour incidents from UK Police API (street-level, monthly, by LSOA). (iii) Transaction volumes as a proxy for market activity.
**Identification:** Staggered difference-in-differences using Callaway & Sant'Anna (2021). 100+ treated LAs (well above 20-unit threshold) with staggered adoption 2006-2024. Pre-treatment parallel trends testable with long pre-periods (Land Registry from 1995). Built-in placebos: commercial property prices (unaffected by residential licensing), non-PRS-dominated neighborhoods. Robustness: Sun & Abraham (2021) interaction-weighted estimator; HonestDiD sensitivity bounds; randomization inference.
**Why it's novel:** Existing evaluations focus only on mental health outcomes in Greater London (Humphry et al. 2022, BMJ Open). Petersen et al. (2026, Environment and Planning B) maps adoption patterns via FOI but does not estimate causal effects. No published paper estimates property value effects nationally using Land Registry data.
**Feasibility check:** Confirmed: Land Registry PPD downloads work (HTTP 200, ~150MB/year). Police API returns 625+ ASB records per query. NOMIS returns LA-level data. 100+ treated LAs provide sufficient variation. 24M+ transactions provide ample power.

## Idea 2: Universal Credit Full Service and the Bottom of the Wage Distribution
**Policy:** Universal Credit Full Service rollout (November 2015 – December 2018), replacing six legacy benefits with a continuous 63p taper, rolled out LA-by-LA based on DWP IT readiness.
**Outcome:** NOMIS ASHE p10, p20, median gross annual pay by LA (369 LAs × 8 years = ~2,952 cells).
**Identification:** Staggered DiD exploiting LA-level timing of Full Service rollout. 340+ treated LAs with variation across 37 months. CS-DiD with clustered SEs at LA level.
**Why it's novel:** UC has been studied for crime, housing, and homelessness — but the wage distribution effect (the most direct test of UC's stated work-incentive design) has not been causally identified.
**Feasibility check:** NOMIS NM_30_1 confirmed active with 1,970 valid observations. DWP publishes rollout schedule. Data is LA-level percentile summaries rather than microdata, limiting precision.

## Idea 3: No-Fault Eviction Abolition and Private Rental Supply: Evidence from Wales
**Policy:** Wales abolished Section 21 no-fault evictions in December 2022 under the Renting Homes (Wales) Act 2016, three years ahead of England.
**Outcome:** Land Registry PPD transaction volumes and prices at LA × month level for Welsh vs English LAs.
**Identification:** DiD comparing 22 Welsh LAs (treated Dec 2022) against 309 English LAs. Border-county subsample for tighter geographic control.
**Why it's novel:** No published academic paper uses this Act as a quasi-experiment. First causal estimate for UK no-fault eviction reform.
**Feasibility check:** Land Registry bulk CSVs confirmed working. Only 22 treated units is below the comfort zone — requires permutation inference and leave-one-out sensitivity.
