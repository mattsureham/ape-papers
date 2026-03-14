# Research Plan: The Presumption Paradox — Does Overriding Local Planning Discretion Increase Housing Supply?

## Research Question

Does the "presumption in favour of sustainable development" — triggered when a Local Authority's Housing Delivery Test (HDT) score falls below 75% — causally increase planning approval rates and housing starts?

## Institutional Background

England's Housing Delivery Test, introduced under the revised National Planning Policy Framework (NPPF) in 2018, measures each Local Planning Authority's (LPA's) housing delivery against its assessed requirement over a rolling three-year period. The HDT score is published annually by DLUHC.

**Consequences by score:**
- **Below 75%:** "Presumption in favour of sustainable development" applies (NPPF paragraph 11d). This reverses the burden of proof: development proposals must be approved unless their adverse impacts "significantly and demonstrably" outweigh the benefits. This is the strongest planning sanction.
- **75–95%:** LPA must produce a 20% buffer in its 5-year housing land supply calculations.
- **95–100%:** LPA must prepare an action plan.
- **Above 100%:** No consequence.

The 75% threshold is the key discontinuity: crossing it triggers a qualitative shift in the planning regime from local discretion to a presumption favouring development.

## Identification Strategy

**Design:** Sharp Regression Discontinuity Design at the 75% HDT threshold, pooled across six annual HDT rounds (2019–2024).

**Running variable:** HDT measurement score (housing delivered / housing required × 100). Published by DLUHC for each LPA annually.

**Treatment:** "Presumption in favour of sustainable development" applies when HDT < 75%.

**Key assumptions:**
1. LPAs cannot precisely manipulate their HDT score near 75%. The score is computed from housing completions data (monitored centrally) divided by a requirement figure set through the standard methodology. Manipulation would require either suppressing reported completions (observable) or inflating the requirement denominator (set by formula).
2. No other policy jumps at exactly 75%. The 95% buffer threshold and action plan threshold create discontinuities at other cutoffs, not at 75%.
3. Conditional on being near the threshold, assignment to presumption is as-good-as-random.

**Validity checks:**
- McCrary density test at 75% threshold
- Covariate balance: pre-treatment LA characteristics (deprivation, urbanity, population, political control)
- Bandwidth sensitivity (50%, 75%, 100%, 150% of CCT-optimal bandwidth)
- Placebo cutoffs at 50%, 85%, 95%
- Donut-hole RDD (dropping observations within 1pp of threshold)

## Expected Effects and Mechanisms

**Primary hypothesis:** LAs subject to the presumption have higher planning approval rates for major residential applications, because the tilted playing field makes it harder to refuse applications that meet basic planning standards.

**Expected magnitude:** 3–8 percentage point increase in approval rates. The presumption is a powerful tool, but LAs may still use procedural mechanisms (delays, conditions, negotiation) to slow development.

**Mechanisms to test:**
1. **Major residential vs. minor/householder applications:** The presumption primarily affects major speculative development. Householder applications (extensions, etc.) should show no discontinuity (placebo).
2. **Speed of determination:** LAs under presumption may still delay decisions even if they ultimately approve.
3. **Appeal success rates:** If the presumption is binding, appeals by developers should be more successful in presumption LAs.

## Primary Specification

$$Y_{it} = \alpha + \tau \cdot D_{it} + f(X_{it} - 75) + D_{it} \cdot f(X_{it} - 75) + \delta_t + \epsilon_{it}$$

Where:
- $Y_{it}$ = planning approval rate for LA $i$ in HDT round $t$
- $D_{it}$ = 1 if HDT score < 75%
- $X_{it}$ = HDT score
- $f(\cdot)$ = local polynomial (linear, following Gelman & Imbens 2019)
- $\delta_t$ = year fixed effects

Estimated using `rdrobust` with CCT-optimal bandwidth and bias-corrected confidence intervals.

## Data Sources and Fetch Strategy

### 1. Housing Delivery Test Scores
**Source:** DLUHC HDT measurement files (ODS format)
**URL:** Available on gov.uk — published annually since 2019 for HDT rounds 2018–2023
**Format:** ODS spreadsheets with LA-level HDT scores, housing delivered, housing required, and consequence assignment
**Fetch:** Download all six annual HDT files, parse ODS in R

### 2. Planning Application Statistics (PS2)
**Source:** DLUHC Planning Statistics — Table PS2 (District level)
**URL:** gov.uk planning statistics page — CSV format
**Content:** Quarterly counts of planning applications received, decided, granted, and refused by LA and application type (major residential, minor residential, householder, commercial)
**Fetch:** Download quarterly PS2 CSVs, construct LA-quarter panel

### 3. LA Characteristics (Covariates)
**Source:** ONS/NOMIS for IMD, population, urban/rural classification
**Additional:** Political control from local election results (manual coding or from LGA)

## Analysis Pipeline

1. `01_fetch_data.R` — Download HDT ODS files and PS2 CSV, validate structure
2. `02_clean_data.R` — Parse HDT scores, merge with PS2 quarterly data, construct panel
3. `03_main_analysis.R` — RDD estimation using rdrobust, McCrary test, covariate balance
4. `04_robustness.R` — Bandwidth sensitivity, placebo cutoffs, donut-hole, polynomial order
5. `05_tables.R` — Generate all tables including SDE appendix

## Risk Assessment

- **Data availability:** HDT files confirmed accessible (smoke test). PS2 confirmed at 67,656 rows.
- **Manipulation:** Low risk. HDT score denominator (housing requirement) is set by standard methodology, not LA discretion. Numerator (completions) is centrally monitored.
- **Power:** With ~60 LAs below 75% per round and ~250 above, the effective sample near the threshold depends on bandwidth. At ±15pp, expect ~100–150 observations per round × 6 rounds = 600–900 total. Should be adequate for detecting a 3–5pp effect.
- **Null result possibility:** If LAs find procedural workarounds (delays, conditions, pre-application gatekeeping), the approval rate may not change despite the presumption. A clean null would still be an important finding — the most powerful planning sanction having no effect would speak directly to the literature on local resistance to housing development (Hilber & Vermeulen 2016).
