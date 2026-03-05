# Initial Research Plan: Salary History Bans and the Gender Earnings Gap

## Research Question

Do state salary history ban laws reduce the gender earnings gap, and does the effect operate primarily through the hiring wage-setting channel?

## Identification Strategy

**Triple-Difference (DDD) Design:**
1. Cross-state variation: 20 jurisdictions with private-employer salary history bans vs. 31 never-treated states
2. Time variation: pre-ban vs. post-ban quarters (2010Q2-2024Q3)
3. Within-state mechanism: new hire earnings (EarnHirNS) vs. continuing worker earnings (EarnS)

**Primary Estimator:** Callaway-Sant'Anna (2021) group-time ATT
- Control group: not-yet-treated and never-treated states
- Aggregation: dynamic event-study, simple ATT, group-level ATT
- Pre-trend test: joint significance of pre-treatment coefficients

**Treatment Timing (private-sector bans):**

| State | Effective Date | Treatment Quarter |
|-------|---------------|-------------------|
| Oregon | Oct 6, 2017 | 2017-Q4 |
| Delaware | Dec 14, 2017 | 2017-Q4 |
| DC | Nov 17, 2017 | 2017-Q4 |
| California | Jan 1, 2018 | 2018-Q1 |
| Massachusetts | Jul 1, 2018 | 2018-Q3 |
| Vermont | Jul 1, 2018 | 2018-Q3 |
| Connecticut | Jan 1, 2019 | 2019-Q1 |
| Hawaii | Jan 1, 2019 | 2019-Q1 |
| Illinois | Sep 29, 2019 | 2019-Q4 |
| Maine | Sep 17, 2019 | 2019-Q4 |
| Washington | Jul 28, 2019 | 2019-Q3 |
| Alabama | Sep 1, 2019 | 2019-Q3 |
| New Jersey | Oct 31, 2019 | 2019-Q4 |
| New York | Jan 6, 2020 | 2020-Q1 |
| Virginia | Jul 1, 2020 | 2020-Q3 |
| Maryland | Oct 1, 2020 | 2020-Q4 |
| Colorado | Jan 1, 2021 | 2021-Q1 |
| Nevada | Oct 1, 2021 | 2021-Q4 |
| Rhode Island | Jan 1, 2023 | 2023-Q1 |
| Minnesota | Jan 1, 2024 | 2024-Q1 |

## Expected Effects and Mechanisms

**Primary hypothesis:** Salary history bans reduce the gender earnings gap among NEW HIRES by removing an anchor that perpetuates historical pay discrimination. Expected effect: 1-5% reduction in the new-hire gender earnings gap.

**Mechanism channel:** When employers cannot ask about salary history, they cannot anchor offers to prior (discriminatorily low) wages. This should compress the gender gap at the hiring stage.

**Null channel (placebo):** CONTINUING workers' wages are set by internal pay structures, not salary negotiation. The ban should have no/smaller effects on the continuing-worker gender gap.

**Heterogeneity prediction:**
- Larger effects in male-dominated industries (construction, finance, mining) where gender gaps are wider
- Larger effects in high-wage industries (professional services, information, finance) where negotiation plays a bigger role
- Potentially SMALLER effects in low-wage industries (retail, food service) where wages are closer to minimums and negotiation matters less

## Primary Specification

**Outcome:** log(Female EarnHirNS / Male EarnHirNS) — log gender earnings ratio for new hires

**Regression (state-quarter level):**
Y_{st} = alpha + beta_1 * Ban_{st} + gamma * X_{st} + delta_s + theta_t + epsilon_{st}

Where:
- Y_{st} = log(female new hire earnings / male new hire earnings) in state s, quarter t
- Ban_{st} = 1 if state s has effective salary history ban in quarter t
- X_{st} = state-quarter controls (unemployment rate, industry mix)
- delta_s = state fixed effects
- theta_t = quarter fixed effects

**DDD version:** Run separately for new hires (EarnHirNS) and continuing workers (EarnS), then test equality of coefficients.

**CS-DiD version:** Using `did` R package with group-time ATT structure.

## Planned Robustness Checks

1. **Event study:** Dynamic treatment effects for 12 quarters pre/post
2. **Male placebo:** Run DiD on male-only outcomes (should be ~zero)
3. **Continuing worker placebo:** DiD on continuing worker gender gap (should be smaller)
4. **Composition test:** DDD on hire COUNTS and demographic shares
5. **Pay-equity law controls:** Include pay transparency indicators
6. **Bacon decomposition:** Assess contribution of different 2x2 DiDs
7. **Randomization inference:** Permute treatment across states (500 iterations)
8. **Industry-level event studies:** Parallel trends by 2-digit NAICS
9. **Exclude bundled states:** Drop CO, CA, WA (had simultaneous pay transparency laws)
10. **Sensitivity analysis:** Rambachan-Roth (2023) honest DiD bounds

## Data

**Primary:** Census QWI via API
- Variables: EarnS, EarnHirNS, HirN, HirNs, Sep, Emp (by state x quarter x sex)
- Time: 2010Q2 - 2024Q3
- Dimensions: state (51) x quarter (58) x sex (2) x industry (19)

**Power Assessment:**
- 20 treated jurisdictions (states + DC)
- 31 never-treated control states
- 58 quarters (2010Q2-2024Q3)
- 7+ years pre-treatment for early adopters (2017Q4)
- Universe data: extremely tight standard errors expected
- MDE: With N=51 states, T=58 quarters, and universe data, the MDE should be well below 1% of the earnings gap

## Actual Results

**Key finding: NULL RESULT.** Salary history bans produced no detectable effect on the aggregate gender earnings gap.

| Specification | Coefficient | SE | p-value |
|--------------|------------|-----|---------|
| TWFE: New Hire Ratio | -0.008 | 0.008 | 0.35 |
| TWFE: Continuing Ratio | -0.006 | 0.006 | ~0.35 |
| TWFE: All Workers | -0.005 | 0.007 | ~0.50 |
| DDD: Post × NewHire | 0.006 | 0.010 | 0.55 |
| CS-DiD: New Hire ATT | 0.012 | — | — |
| CS-DiD: Continuing ATT | 0.003 | — | — |
| RI p-value | 0.45 | — | — |
| Pre-trend F-test | F=0.25 | — | p=0.99 |
| Female hire share | -0.002 | 0.002 | 0.38 |

- All estimates are precisely estimated zeros
- Pre-trends are flat across all specifications
- Industry-level effects are scattered around zero with no systematic pattern
- Results robust to Sun-Abraham, excluding bundled states, randomization inference

## Code Structure

- `00_packages.R` — Load libraries
- `01_fetch_data.R` — QWI API pulls for all states, quarters, sex, industries
- `02_clean_data.R` — Construct treatment indicators, merge, create outcomes
- `03_main_analysis.R` — CS-DiD, TWFE, DDD regressions
- `04_robustness.R` — Placebos, RI, composition tests, sensitivity
- `05_figures.R` — Event studies, mechanism plots, heterogeneity
- `06_tables.R` — Main results, robustness, heterogeneity tables
