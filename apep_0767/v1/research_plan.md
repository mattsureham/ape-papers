# Research Plan: The Reporting Tax on Job Switching

## Research Question

Does reducing SNAP administrative reporting burdens increase labor market fluidity among low-wage workers? Under pre-reform "change reporting," SNAP households had to report every income change within 10 days — creating an implicit tax on job switching since any earnings fluctuation triggered paperwork and risked benefit loss. The 2002 Farm Bill authorized "simplified reporting," requiring reports only when gross income exceeded 130% FPL. States adopted this reform at staggered dates between 2001 and 2013, providing quasi-experimental variation.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD.** Treatment: state-level adoption of SNAP simplified reporting. Treatment timing drawn from the USDA ERS SNAP Policy Database (`reportsimple` variable). 45+ treated states with adoption dates spanning 2001-2013. Never-treated or very-late-treated states serve as controls.

**Key identifying assumption:** Parallel trends in labor market fluidity outcomes between early- and late-adopting states, conditional on state and time fixed effects.

**Validation:**
1. Event-study pre-trend tests (4-8 pre-quarters)
2. Built-in placebo: high-education workers (Bachelor's+) who are unlikely SNAP recipients should show no effect
3. Dose-response: interact treatment with state SNAP participation rates (higher caseload → larger effect)

## Expected Effects and Mechanisms

**Primary hypothesis:** Simplified reporting reduces the implicit cost of income volatility, encouraging job-to-job transitions among low-wage workers. Expected:
- Increase in turnover rates and hires for low-education workers
- Smaller or null effect on separations (switching, not exiting)
- Null effect on high-education workers (placebo)

**Mechanism:** Change reporting acts as an implicit tax on earnings volatility. Workers who switch jobs experience earnings disruptions (gap between jobs, first partial paycheck) that trigger reporting obligations and possible benefit suspension. Simplified reporting removes this friction.

**Alternative hypotheses:**
- Income effect: higher effective benefits reduce labor supply (decrease in fluidity)
- If simplified reporting only affects participation, not behavior, effect may be null

## Primary Specification

Y_{st} = α_s + δ_t + β · (SimplifiedReporting_s × Post_st) + X_{st}γ + ε_{st}

Where Y is QWI turnover rate, hires rate, or separations rate for low-education workers at state-quarter level. Callaway-Sant'Anna estimator accounts for staggered timing.

**Clustering:** State level (51 clusters).
**Inference:** Wild cluster bootstrap as robustness check.

## Data Sources

1. **SNAP Policy Database** (USDA ERS): `reportsimple` variable with state × year-month adoption dates. Downloadable from USDA website.

2. **QWI (Quarterly Workforce Indicators)** via Census API:
   - Geography: State level (all 51)
   - Time: 2000Q1-2019Q4 (pre-COVID)
   - Education breakdowns: E1 (<HS), E2 (HS/GED), E3 (Some college), E4 (Bachelor's+)
   - Outcomes: TurnOvrS (turnover rate), HirA (hires), Sep (separations), EarnS (earnings)
   - Industry: All private sector (agglvl=71)

3. **SNAP participation data**: USDA SNAP annual state-level participation counts (for dose-response).

## Analysis Plan

1. Construct state-quarter panel from QWI (2000-2019)
2. Merge SNAP simplified reporting adoption dates
3. Estimate Callaway-Sant'Anna DiD with group-time ATTs
4. Event-study plot showing pre-trends and dynamic effects
5. Placebo test on high-education workers
6. Dose-response with SNAP caseload intensity
7. Robustness: alternative control groups, wild bootstrap, earnings outcomes
