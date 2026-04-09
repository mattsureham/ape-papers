# Research Plan: Stars and Dollars — The Medicare Advantage Quality Bonus Threshold

## Research Question

How do Medicare Advantage plans allocate the ~5% quality bonus payment triggered by the 3.750 star-rating threshold? Do they improve beneficiary benefits, reduce premiums, or retain the windfall as margin?

## Identification Strategy

**Sharp RDD** at the 3.750 continuous summary score threshold. Plans scoring ≥3.750 receive a 4.0-star rating and ~5% quality bonus (~$372/enrollee/year). Plans scoring <3.750 receive 3.5 stars and no bonus. The running variable is CMS's continuous summary score — a composite of dozens of HEDIS, CAHPS, and HOS measures. The multi-measure averaging creates noise that prevents precise manipulation.

**Key validity checks:**
- McCrary density test for bunching at 3.750
- Covariate balance (plan age, parent org size, geographic mix)
- Placebo thresholds at 2.750 and 4.250 (where no bonus discontinuity exists)

## Expected Effects and Mechanisms

**Primary hypothesis:** Plans capture most of the bonus as margin, with modest pass-through to beneficiaries via supplemental benefits (dental/vision) rather than premium reductions. Rationale: MA plans face sticky premiums and limited consumer attention to benefit details.

**Alternative:** Competitive pressure forces full pass-through, especially in markets with many plans.

## Primary Specification

Y_{it} = α + τ · 1(Score_{it} ≥ 3.750) + f(Score_{it} - 3.750) + γ_t + ε_{it}

Where Y is benefit generosity (dental maximum, vision allowance, OTC credit) or premium. Local linear regression with triangular kernel. Bandwidth: IK optimal, with sensitivity to ±0.05, ±0.10, ±0.15.

## Data Sources

All public CMS downloads (no API keys required):

1. **Star Ratings Summary files** (2015-2024) — continuous summary scores + assigned star ratings per contract
2. **PBP (Plan Benefit Package) files** — dental maximum (`pbp_b16a`), vision, OTC, hearing benefits
3. **CPD (Contract/Plan/Demographic) files** — monthly premiums
4. **MA Enrollment files** — enrollment by contract × county

## Fetch Strategy

Download directly from CMS data.cms.gov. Files are CSV/Excel, typically 5-50 MB each. Pool 2015-2024 for ~10 years of cross-sections at the threshold.
