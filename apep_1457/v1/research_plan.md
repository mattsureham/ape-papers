# Research Plan: Insuring Against Nothing

## Research Question

Does the non-monotone federal crop insurance subsidy schedule — which jumps from 55% at 70% coverage to 67% at 75% coverage, then falls to 48% at 80% — create bunching at the 75% coverage level? If so, what is the implied demand elasticity for crop insurance coverage, and did the 2014 Farm Bill's Supplemental Coverage Option (SCO) — available only at 75%+ — amplify bunching?

## Identification Strategy

**Bunching estimation** (Kleven and Waseem 2013; Chetty et al. 2011). The running variable is the discrete coverage level choice (50%, 55%, 60%, 65%, 70%, 75%, 80%, 85%). The threshold is 75%, where the subsidy rate jumps 12pp from 70% coverage. The counterfactual distribution is estimated by fitting a polynomial to the observed distribution excluding the bunching region (70%-80%), then recovering excess mass at 75%.

**Key estimand:** Excess mass ratio b = B / h₀, where B is the excess number of policies at 75% and h₀ is the counterfactual density at 75%. The structural elasticity of coverage demand with respect to the net premium price is recovered from b and the size of the subsidy notch.

**2014 Farm Bill structural break:** SCO became available only to farmers at 75%+ coverage, creating a second discrete incentive at the same threshold. Comparing pre-2014 vs. post-2014 bunching mass estimates the SCO amplification effect. This is a difference-in-bunching design: the subsidy notch existed throughout, but SCO added a second incentive post-2014.

**Moral hazard channel:** Among farmers at 75% vs. adjacent coverage levels (70%, 80%), compare indemnity-to-premium ratios (loss ratios) conditional on county-crop-year fixed effects. If 75%-bunchers have higher loss ratios, the subsidy notch induces moral hazard. If loss ratios are similar, the bunching reflects pure demand response without behavioral distortion.

## Expected Effects and Mechanisms

1. **Large excess mass at 75%:** The 12pp subsidy jump should produce substantial bunching. Expected b > 2 (i.e., more than double the counterfactual density).
2. **Post-2014 amplification:** SCO eligibility at 75%+ should increase bunching further. Expected 20-50% increase in excess mass.
3. **Demand elasticity:** Expected in range of 0.3-0.8 (moderate, consistent with subsidized insurance).
4. **Moral hazard:** Expected weak or null — crop insurance moral hazard is limited by area-based adjustments and yield monitoring.

## Primary Specification

**Bunching estimator:**
- Running variable: Coverage level (discrete: 50, 55, 60, 65, 70, 75, 80, 85%)
- Bunching window: 75% (single mass point due to discrete schedule)
- Counterfactual: Polynomial of order 5-7 fitted to counts at all coverage levels except 75%
- Excess mass: B̂ = N(75%) - ĥ₀(75%), where ĥ₀ is the fitted counterfactual
- Standard errors: Bootstrap (resample policies, re-estimate bunching 500 times)

**Difference-in-bunching (2014 Farm Bill):**
- Pre-period: 2000-2013
- Post-period: 2014-2023
- Estimand: ΔB = B̂_post - B̂_pre (change in excess mass at 75%)

**Moral hazard regression:**
- Y = loss_ratio_{i,c,k,t} (indemnity/premium for policy i, county c, crop k, year t)
- Treatment: 1[coverage = 75%]
- Controls: County × crop × year FEs
- Comparison: 70% and 80% coverage farmers in the same county-crop-year

## Data Source and Fetch Strategy

**FCIC Summary of Business (sobcov) files:**
- Source: pubfs-rma.fpac.usda.gov (free, no authentication)
- Coverage: 2000-2023, ~8.5M records/year, ~170M total
- Key variables: COVERAGE_LEVEL, PREMIUM_AMOUNT, SUBSIDY_AMOUNT, INDEMNITY_AMOUNT, COUNTY_CODE, CROP_CODE, INSURANCE_PLAN_CODE
- Download: Annual ZIP files, each ~50-100MB
- Focus crops: Corn (0041), Soybeans (0081), Wheat (0011), Cotton (0021) — ~80% of policies

**Fetch strategy:**
1. Download sobcov files for 2000-2023 (24 annual files)
2. Filter to major crops (corn, soybeans, wheat, cotton)
3. Construct coverage level distribution by year
4. Compute subsidy rate, premium, indemnity, loss ratio by coverage level
5. Save as analysis-ready panel

## Robustness Checks

1. **Donut hole:** Exclude 75% and re-estimate counterfactual — should predict substantial mass at 75%
2. **By crop:** Separate bunching estimates for corn, soybeans, wheat, cotton
3. **By region:** Corn Belt vs. Plains vs. Southeast
4. **Placebo at 65% and 70%:** No subsidy notch at these levels → should find no excess mass
5. **Time series:** Annual bunching estimates 2000-2023 showing structural break at 2014
6. **Alternative polynomial orders:** Orders 3-9 for counterfactual
