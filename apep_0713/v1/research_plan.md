# Research Plan: apep_0713 — Municipal Broadband Preemption and Digital Entrepreneurship

## Research Question

Do state laws restricting municipal broadband networks reduce broadband adoption and entrepreneurship? Using a staggered CS-DiD with 17-22 treated states that enacted preemption laws (1997-2020) and ~5 states that subsequently repealed them (2019-2023), this paper estimates the causal effect of prohibiting public broadband competition on: (1) household broadband penetration and (2) new firm formation, particularly in digital-intensive sectors.

## Policy Context

Municipal broadband preemption laws prohibit or severely restrict local governments from building publicly-owned broadband networks. These laws were typically passed under incumbent ISP lobbying. As of 2020, 22 states had enacted some form of restriction.

**Key enacted dates (confirmed):**
- Texas: 1997 (Utilities Code §54.201)
- Missouri: 1997/2005
- North Carolina: 2011 (HB 129 — Wilson case)
- And ~17 others

**Key repeals:**
- Arkansas: 2021 (SB 74)
- Colorado: 2023 (SB 23-183) — municipalities can now opt-in
- Washington: partial repeal
- Wisconsin: partial (2022)
- Minnesota: 2023

## Expected Effects and Mechanisms

1. **Competition channel**: Municipal broadband threatens incumbent ISPs, who lobby for preemption → fewer providers → lower penetration
2. **Entrepreneurship spillover**: Low broadband penetration reduces digital firm formation and remote-work business creation
3. **Reverse on repeal**: States that repealed should see broadband penetration increase relative to other preempted states

Primary prediction: preemption reduces broadband penetration by ~3-7pp and reduces firm births in NAICS 51 (Information) and 54 (Professional Services) by 5-10%.

## Identification Strategy

**Staggered CS-DiD (Callaway-Sant'Anna)**
- Treatment: state-year of preemption law enactment
- Control: never-preempted states
- Period: 2010-2023 for broadband; 1997-2023 for firm births (BDS back to 1978)
- Unit: state × year
- Pre-trend test: parallel trends for ~5-10 pre-law years

**Repeal design (secondary):**
- Treatment: states that repealed preemption
- Control: remaining preempted states
- Cleaner "reversal" identification

**Mechanism tests:**
1. Broadband channel: ACS B28002 (broadband penetration) — does preemption reduce this?
2. Competition channel: county-level FCC provider counts
3. Entrepreneurship: BDS firm births in information-intensive sectors

## Primary Specification

For broadband outcome:
```
Broadband_{st} = α + Σ_g β_g · 1(G=g) · D_{gst} + γ_s + δ_t + ε_{st}
```
where g = adoption cohort, D_{gst} = post-treatment indicator for cohort g in state s at time t.

Reported as ATT from Callaway-Sant'Anna (2021) pooled across cohorts.

**Outcome variables:**
1. Broadband subscription rate = B28002_004E / B28002_001E (from Census ACS 1-year, 2015-2023)
2. Firm births per 1000 existing firms (Census BDS, statewide, 1997-2023)
3. NAICS 51 firm births (QWI, 2003-2023)

## Data Sources

1. **Census ACS Table B28002** — Internet subscriptions by type, state-level, 2015-2023
   - Variables: total households (B28002_001E), any internet (B28002_002E), broadband (B28002_004E)
   - API confirmed: HTTP 200, all 52 states returning data

2. **Census BDS** — Business Dynamics Statistics, firm births/deaths, state × year, 1978-2023
   - Variables: FIRM, ESTAB, EMP, JOB_CREATION_BIRTHS
   - API confirmed: HTTP 200, 51 states returning data

3. **Census QWI** — Quarterly Workforce Indicators, employment/hires by state × sector
   - NAICS 51 (Information), 54 (Professional Services) sector variation
   - Used for mechanism test: digital-intensive vs. non-digital sector comparison

4. **State preemption law dates** — compiled from:
   - National Conference of State Legislatures (NCSL) broadband legislation tracker
   - Specific citation: Baller Herbst (2020 white paper), BroadbandNow preemption tracker
   - Broadband Now municipal broadband map (confirmed public data)

## Preemption Law Coding

| State | Year Enacted | Year Repealed | Source |
|-------|-------------|---------------|--------|
| Texas | 1997 | — | Utilities Code §54.201 |
| Missouri | 1997 | — | §392.410 |
| Arkansas | 2011 | 2021 | SB 1 / SB 74 (2021) |
| North Carolina | 2011 | — | Session Law 2011-84 |
| Colorado | 2005 | 2023 | SB 05-152 / SB 23-183 |
| Wisconsin | 1999 | 2022 | §66.0422 (partial) |
| Minnesota | 2001 | 2023 | §237.19 |
| ...plus ~15 others to be confirmed | | | |

## Sample Restrictions

- Primary DiD: states × years 2010-2023 (or ACS coverage 2015-2023 for broadband)
- BDS available 1978-2023 for firm births (longer pre-period for robustness)
- Never-preempted states as clean controls (confirmed ~28-33 states)
- Exclude DC and territories from main analysis; include as robustness

## Diagnostics to Track

- n_treated = number of distinct treatment cohort × state cells
- n_pre = minimum pre-treatment years per cohort
- n_obs = total state × year observations in DiD

## Exposure Alignment

**Who is actually affected by treatment and what is the correct comparison?**

The treatment is a state-level law (preemption), affecting all residents and firms in the state. The outcome (firm birth rate) is measured at the state-year level, matching the treatment unit exactly. There is no within-state heterogeneity in treatment assignment — either the law applies to the whole state or it does not.

**Temporal alignment:** Preemption laws take effect in the year of enactment. The causal effect we estimate is the average effect of having the law in force (preempted = 1) versus not (preempted = 0) in a given state-year. This is a stock-treatment effect: states remain treated until repeal. States that never enacted preemption form the pure control group. The identifying variation in the CS-DiD comes from 9 states that enacted preemption between 2005 and 2017, which contribute at least 1 pre-treatment observation in the 2004-2023 BDS panel.

**Non-compliance / partial compliance:** Preemption laws vary in stringency (outright prohibition vs. referendum requirements). We code all laws as binary (enacted vs. not), which introduces measurement error but attenuates toward zero — i.e., the true effect for the strictest laws may be larger than our ATT. This is a known limitation acknowledged in the paper.

**Exposure window:** The BDS measures firm births in a given calendar year; the preemption indicator captures whether the law was in effect on December 31 of that year. For states that enacted laws mid-year (uncommon), this creates a minor temporal misalignment that is unlikely to affect estimates materially.

Commit this plan before data fetch.
