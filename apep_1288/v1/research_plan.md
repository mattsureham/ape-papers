# Research Plan: The Paper Restriction — Child Labor Law Relaxations and Teen Employment

## Research Question

Do state-level relaxations of child labor laws (2022–2023) actually increase teen employment? Six US states loosened restrictions on youth work hours and permits, enabling a test of whether these regulations are binding constraints or symbolic legislation.

## Policy Variation

**Cohort 1 (Q3 2022):**
- New Jersey (A4222): expanded weekly hours 40→50 for ages 16–17
- New Hampshire (SB 345): raised weekly cap 30→35

**Cohort 2 (Q3 2023):**
- Arkansas (HB 1410): eliminated work permits for under-16
- Iowa (SF 542): extended permissible evening hours
- Florida (HB 49): parental permission to exceed standard limits
- Indiana (SB 146): removed hour restrictions for ages 16–18

## Identification Strategy

**Triple-difference (DDD):**
1. State: 6 treated vs 44 never-treated control states
2. Time: pre vs post law change (14–18 pre-treatment quarters from 2019Q1)
3. Age: teen workers (QWI age group A01: 14–18) vs prime-age adults (A03: 25–34)

**Estimator:** Callaway & Sant'Anna (2021) staggered DiD with two cohorts. The adult age group serves as a within-state control, absorbing state-level economic shocks contemporaneous with the law changes. Industry heterogeneity (food services 18.7% teen share vs finance 0.3%) provides mechanism tests.

**Key threats and mitigation:**
- COVID recovery differentials → long pre-period (2019Q1), adult workers as within-state control
- Seasonal teen employment → quarter fixed effects, same-quarter comparisons
- Contemporaneous policy changes → event-study dynamics showing no pre-trends
- Small N treated → wild cluster bootstrap, randomization inference

## Expected Effects and Mechanisms

If laws are binding: positive employment effects concentrated in high-teen industries (food service, retail), driven by hours expansion (intensive margin) or new entry (extensive margin).

If laws are symbolic: null effects — either enforcement was already weak, or employer demand (not regulation) constrains teen hiring.

## Primary Specification

Y_{s,t,a} = α + β(Treated_s × Post_t × Teen_a) + state×age FE + time×age FE + state×time FE + ε_{s,t,a}

Clustering: state level (50 clusters). Wild cluster bootstrap for robustness.

## Data Source and Fetch Strategy

**Primary:** QWI Statewide panel from Census API
- Geography: 50 states + DC
- Time: 2019Q1–2025Q2 (26 quarters)
- Age groups: A01 (14–18), A02 (19–21), A03 (25–34), A04 (35–44)
- Industries: 20 NAICS 2-digit sectors
- Outcomes: Emp (beginning-of-quarter employment), EmpS (stable employment), HirA (hires), Sep (separations), EarnS (avg monthly earnings)

**Fetch:** Census QWI API with state-level calls, looping by state and industry (multi-industry requests fail with HTTP 204 per MEMORY.md).
