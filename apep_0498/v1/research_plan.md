# Initial Research Plan: The Austerity Mortality Gradient

## Research Question

Did England's real-terms cuts to ring-fenced local authority public health grants after 2015 causally increase deaths of despair (drug misuse mortality, alcohol-specific mortality) and preventable mortality? What is the mechanism chain through reduced drug/alcohol treatment capacity?

## Identification Strategy

**Design:** Continuous treatment-intensity difference-in-differences, exploiting LA-level variation in per-capita public health grant changes.

**Treatment variable:** Change in real per-capita public health grant from baseline (2014/15) to each post-year, deflated by GDP deflator. LAs that experienced larger real-terms cuts are "more treated."

**Binarized cohort approach (primary):** Classify LAs into terciles of cumulative real per-capita grant change by 2019/20: (1) large cuts (top tercile), (2) moderate cuts, (3) protected/increased. Apply Callaway-Sant'Anna with group-time ATTs using tercile membership as the cohort indicator.

**Continuous TWFE (secondary):** Standard two-way FE with continuous treatment intensity × post interaction, LA and year fixed effects.

**Unit of analysis:** Upper-tier local authority × year (~150 LAs × 19 years = ~2,850 obs).

**Pre-period:** 2006-2012 (PCT-era health data, before devolution to LAs). 7 pre-treatment years.

**Post-period:** 2013-2024 (LA public health era). Primary specification: 2013-2019 (pre-COVID). Secondary: 2013-2024 (full panel with COVID controls).

## Expected Effects and Mechanisms

**Prior:** LAs that faced larger real-terms grant cuts should show:
- Reduced drug treatment completion rates (first stage / mechanism)
- Higher drug misuse death rates
- Higher alcohol-specific mortality
- Higher under-75 preventable mortality

**Expected direction:** Negative (grant cuts → more deaths). This is not a speculative sign — the UK public health community has documented these associations descriptively (King's Fund, Health Foundation reports), but rigorous causal evidence is missing.

**Mechanism chain:**
1. Grant cut → reduced public health service capacity
2. Reduced capacity → lower drug/alcohol treatment completion rates (testable via NDTMS indicator 90244)
3. Lower treatment completions → more deaths from drug misuse and alcohol

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot (\Delta Grant_{i} \times Post_t) + X_{it}'\delta + \varepsilon_{it}$$

Where:
- $Y_{it}$ = age-standardized mortality rate (drug misuse, alcohol, preventable) for LA $i$ in year $t$
- $\alpha_i$ = LA fixed effects
- $\gamma_t$ = year fixed effects
- $\Delta Grant_i$ = cumulative real per-capita grant change from 2014/15 baseline
- $Post_t$ = indicator for $t \geq 2015$ (first year of significant cuts)
- $X_{it}$ = time-varying controls: population, age structure, deprivation index (IMD), employment rate

For CS-DiD: group-time ATTs using tercile of grant change as cohort, with never-treated (top tercile of grant increases) as comparison.

## Planned Robustness Checks

1. **Pre-COVID subsample (2013-2019):** Primary specification — immune to COVID confounds.
2. **Event-study plots:** Visual pre-trends test for all three mortality outcomes.
3. **HonestDiD/Rambachan-Roth bounds:** Sensitivity to violations of parallel trends.
4. **Leave-one-out by region:** Drop each of 9 English regions in turn.
5. **Placebo outcomes:** (a) Road traffic deaths — not affected by public health budgets; (b) Cancer mortality — long latency, unresponsive to short-term spending.
6. **Dosage check:** Replace binary tercile treatment with continuous grant change — effects should increase monotonically.
7. **Wild cluster bootstrap:** Correct inference for ~150 clusters.
8. **Alternative deflators:** CPI vs GDP deflator for real grant calculation.
9. **Excluding London:** London boroughs have distinctive public health challenges.

## Exposure Alignment (DiD)

- **Who is treated?** Populations in LAs that received larger real-terms public health grant cuts (all working-age and elderly residents).
- **Primary estimand population:** All persons in the LA (mortality rates are population-denominator).
- **Placebo/control populations:** (a) Under-5 mortality (pediatric services funded differently), (b) Road deaths, (c) Cancer deaths.
- **Design:** DiD with continuous treatment intensity. Not classic binary staggered — treatment is a continuous dose (size of cut) applied with increasing intensity over 2015-2019.

## Power Assessment

- **Pre-treatment periods:** 7 (2006-2012)
- **Treated clusters:** ~150 upper-tier LAs (50 per tercile)
- **Post-treatment periods:** 7 pre-COVID (2013-2019), up to 12 full (2013-2024)
- **Outcome variation:** Drug misuse deaths range from ~2 to ~20 per 100k across LAs — substantial cross-sectional variation
- **MDE:** With 150 clusters, 7+7 years, and drug death rates averaging ~5/100k with SD ~3, MDE at 80% power ≈ 0.5-1.0 per 100k (10-20% of mean). This is adequate given the 24% real grant cut.

## Data Sources

| Source | Content | Access | Format |
|--------|---------|--------|--------|
| GOV.UK exposition books | LA-level public health grant allocations, 2013/14-2025/26 | Free download (XLSX/ODS) | Annual per-LA |
| Fingertips API (92432) | Deaths from drug misuse by LA | Free API (CSV) | Annual, age-standardized |
| Fingertips API (91380) | Alcohol-specific mortality by LA | Free API (CSV) | Annual, age-standardized |
| Fingertips API (108) | Under-75 mortality from all causes by LA | Free API (CSV) | Annual, age-standardized |
| Fingertips API (90244) | Drug treatment completions (NDTMS) by LA | Free API (CSV) | Annual |
| ONS mid-year estimates | LA population denominators | Free download | Annual |
| MHCLG IMD | Index of Multiple Deprivation by LA | Free download | Decennial (2010, 2015, 2019) |
