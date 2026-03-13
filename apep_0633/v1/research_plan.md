# Research Plan: High Hopes, Fungible Dollars

## Research Question

Does earmarked marijuana tax revenue actually increase total education spending, or do state legislatures offset earmarked dollars by reducing general-fund appropriations to schools?

## Motivation

Twenty-four U.S. states have legalized recreational marijuana since 2012, collectively generating over $25 billion in tax revenue. Many states explicitly earmark marijuana revenue for education—Colorado directs the first $40 million to school construction, Oregon sends 40% to the Common School Fund, and Nevada allocates license-fee revenue to education. Yet fiscal fungibility theory (Hines & Thaler 1995) predicts that earmarking is largely meaningless: legislatures treat earmarked revenue as substituting for general-fund dollars. Evans & Zhang (2007) found lottery earmarking delivers only 50–70 cents per dollar to education. No causal study tests whether marijuana earmarking follows the same pattern.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD.** Treatment is defined as the first fiscal year in which a state collected recreational marijuana tax revenue (proxied by the year recreational sales began). Twenty-four states adopted between 2014 and 2023; twenty-six states plus DC never legalized recreational marijuana, serving as never-treated controls.

**Treatment timing (first legal recreational sales, defining treatment year):**
- 2014: CO, WA
- 2015: OR
- 2016: AK
- 2017: NV
- 2018: CA, MA
- 2019: MI
- 2020: IL, ME
- 2021: AZ
- 2022: MT, NJ, NM, VT
- 2023: CT, MD, MO, NY, RI
- 2024+: DE, MN, OH, VA (minimal/no data)

**Estimand:** ATT(g,t) for each cohort g at time t, aggregated via CS-DiD into an overall ATT and dynamic event-study coefficients.

## Expected Effects and Mechanisms

1. **Total education spending per pupil:** Small positive or null. If fungibility is complete, earmarked marijuana dollars 1:1 crowd out general-fund education appropriations, producing zero net effect.
2. **State education revenue per pupil:** Positive (mechanical—marijuana revenue flows to state coffers).
3. **Local education revenue per pupil:** Null or slightly negative (if states reduce aid, localities may increase property taxes to compensate, but adjustment is slow).
4. **Federal education revenue per pupil:** Null (placebo—federal grants are determined independently).

**Fungibility rate:** The key object. Defined as the ratio of total education spending increase to marijuana revenue earmarked for education. A rate of 1.0 = no fungibility (every earmarked dollar adds to spending). A rate of 0.0 = full fungibility (earmarking is meaningless). Evans & Zhang benchmark for lotteries: 0.50–0.70.

## Primary Specification

Y_{s,t} = CS-DiD ATT estimate
- Unit: state s
- Time: fiscal year t (2008–2022)
- Treatment: first year of recreational marijuana sales
- Outcome: total education expenditure per pupil (Census Annual Survey of School System Finances)
- Inference: clustered at the state level

## Data Sources

1. **Census Annual Survey of School System Finances (ASSF):** State-level annual data on total revenue, expenditure, and enrollment. Available as XLS files from census.gov for fiscal years 2008–2022. Variables: TOTALREV, TSTREV, TLOCREV, TFEDREV, TOTALEXP, TCURELSC, ENROLL.

2. **Marijuana legalization dates:** Compiled from NORML, MPP, Tax Foundation. Treatment year = calendar year of first legal recreational sales.

3. **Earmarking classification:** Compiled from state statutes and Tax Foundation reports. Binary: state earmarks any marijuana revenue for K-12 education (yes/no).

4. **State marijuana tax revenue:** Tax Foundation annual reports, MJBizDaily, state revenue department publications. Used for fungibility rate calculation.

## Falsification Tests

1. **Federal revenue per pupil:** Should show null effect (federal grants are independent of state marijuana policy).
2. **Non-earmarking states:** States that legalized but do NOT earmark for education (CA, WA, AK) should show null or smaller effects on education spending.
3. **Pre-trend test:** CS-DiD event-study coefficients for pre-treatment periods should be insignificantly different from zero.
4. **Placebo outcome:** Capital outlay or non-instruction expenditure as alternative dependent variable.

## Analysis Steps

1. Download Census ASSF state-level tables for 2008–2022
2. Construct state-year panel with per-pupil outcomes
3. Merge treatment timing and earmarking classification
4. Estimate CS-DiD with `did` package in R
5. Plot event-study coefficients
6. Decompose by revenue source (state, local, federal)
7. Heterogeneity by earmarking status
8. Compute fungibility rate for earmarking states
9. Robustness: Sun-Abraham, TWFE comparison, exclude early/late adopters
