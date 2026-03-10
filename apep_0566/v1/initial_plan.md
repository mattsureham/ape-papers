# Initial Research Plan: apep_0566

## Research Question

Does removing police departments' financial incentive for drug enforcement — through civil asset forfeiture reform — increase drug overdose mortality? Forfeiture allows police to seize property and keep proceeds, creating a direct revenue motive for drug enforcement. Since 2014, 29 states have substantially reformed these laws. If forfeiture revenue motivates drug policing, reform should weaken enforcement, potentially increasing drug availability and overdose deaths. If police pursue drug enforcement regardless of financial incentives, reform has no effect on mortality — resolving the central public safety concern of the reform movement.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD.** Treatment is the year a state enacts substantial forfeiture reform (conviction requirement, burden-of-proof increase, or full abolition). States with only transparency/reporting requirements are coded as controls. 29 treated states, ~20 never-treated controls, reform timing 2014-2021.

**Why this is credible:** Reform timing reflects state-specific legislative dynamics (political composition, high-profile cases, advocacy campaigns) rather than trends in drug overdose mortality. Event-study pre-trends will test this assumption.

**Built-in placebo:** Non-drug mortality (heart disease, cancer, motor vehicle) should NOT respond to forfeiture reform. This cleanly isolates the drug-enforcement channel.

## Data Sources

1. **CDC NCHS Drug Poisoning Mortality by State** (Socrata API: jx6g-fdh6). State × year drug overdose death rates, 1999-2021. Deaths, population, age-adjusted rates. No suppression at state level.
2. **Census ACS** (via tidycensus). State-level controls: median income, poverty rate, unemployment, demographics.
3. **Forfeiture reform dates.** Compiled from Institute for Justice Civil Forfeiture Reform tracker and state legislative records. 29 states with substantial reform, 2014-2021.

## Expected Effects and Mechanisms

**If forfeiture revenue drives drug enforcement effort:**
- Drug overdose deaths increase post-reform (police reduce drug enforcement → drug availability rises)
- Effects concentrate in states with higher pre-reform forfeiture revenue reliance
- Effects are larger for full abolition than for burden-of-proof increases (dose-response)

**If police maintain drug enforcement regardless of financial incentives:**
- Null effect on drug overdose deaths (main contribution: reform is safe)
- Null across all heterogeneity cuts
- The null is publishable because it settles a live policy debate

## Primary Specification

ATT(g,t) estimated via Callaway-Sant'Anna (2021):
- Y_{st} = age-adjusted drug overdose death rate per 100K
- G = reform year for treated states
- Control group: not-yet-treated and never-treated states
- Covariates: pre-treatment state characteristics (income, poverty, demographics)
- Clustering: state level (50 clusters)
- Aggregation: simple ATT, dynamic event study, cohort-specific ATTs

## Exposure Alignment

- **Who is treated:** State residents (mortality is geographically attributed to state of residence)
- **Treatment assignment:** State level (legislative reform)
- **Outcome measurement:** State level (CDC mortality)
- **Alignment:** Perfect — treatment and outcome at same level

## Power Assessment

- Pre-treatment periods: 15+ years (1999-2013) for earliest reformers
- Treated clusters: 29 states
- Post-treatment periods: 2-7 years depending on cohort
- Total observations: ~50 states × 23 years ≈ 1,150 state-years
- Outcome variation: Drug overdose rates range from ~5 to ~55 per 100K with SD ≈ 10
- MDE: With 29 treated states, 20 controls, 50 clusters, MDE ≈ 1.5-2.5 per 100K (15-25% of SD)

## Planned Robustness Checks

1. Bacon decomposition (diagnose TWFE bias)
2. HonestDiD / Rambachan-Roth sensitivity bounds
3. Randomization inference (permute treatment assignment)
4. Leave-one-out (drop each state)
5. Wild cluster bootstrap (few clusters)
6. Placebo outcome: non-drug mortality
7. Alternative treatment definitions (include reporting-only reforms)
8. Dose-response: abolition vs. conviction requirement vs. burden of proof
9. Heterogeneity by pre-reform state characteristics
10. Sun-Abraham (SUNAB) as alternative estimator
