# Research Plan: Post-Dobbs Healthcare Labor Reallocation

## Research Question
Did state abortion bans following the Dobbs decision (June 2022) cause measurable reallocation of reproductive healthcare employment from ban states to neighboring "receiving" states?

## Identification Strategy
**Staggered Difference-in-Differences (Callaway-Sant'Anna 2021)**

Treatment: State abortion ban effective date, driven by pre-enacted trigger laws activated by Dobbs (June 24, 2022). Thirteen states had trigger laws; additional states enacted bans in subsequent months (June–December 2022).

Key identification advantage: Trigger laws were enacted years before Dobbs, so the timing of treatment activation is exogenous — determined by the Supreme Court, not by state-level conditions in 2022.

**Two-sided analysis:**
1. **Ban states** (supply shock): Expected decline in reproductive healthcare employment
2. **Receiving states** (demand shock): Expected increase, especially in border non-ban states absorbing cross-state demand (IL, CO, KS, NM, NC, VA)

**Placebo industries:** NAICS 6213 (dental/optometry offices) — no reproductive health mechanism.

## Expected Effects and Mechanisms
- Ban states: Reduction in family planning (62141) employment as clinics close or reduce operations
- Receiving states: Increase in family planning employment as demand concentrates geographically
- The net reallocation is the key finding — does the system lose capacity, or just relocate it?
- Mechanism: Cross-state patient travel → clinic expansion → hiring in receiving states

## Primary Specification
```
Y_{s,t} = α_s + γ_t + β·BAN_{s,t} + X_{s,t}Γ + ε_{s,t}
```
Where Y is log employment in family planning (NAICS 62141), BAN is indicator for abortion ban in effect, with state and quarter fixed effects. CS-DiD for heterogeneity-robust ATT.

Second specification for receiving states:
```
Y_{s,t} = α_s + γ_t + δ·RECEIVING_{s,t} + X_{s,t}Γ + ε_{s,t}
```

## Data Sources
1. **Census QWI API** (`api.census.gov/data/timeseries/qwi/sa`): State × quarter × NAICS employment, earnings. Variables: Emp, EmpS, EarnS. NAICS: 62141, 6211, 6214, 6219, 6213 (placebo). Period: 2015Q1–2024Q2.
2. **Treatment dates**: State trigger law activation dates from Guttmacher Institute tracking.
3. **Controls**: ACS state-level demographics (optional).

## Sample Size Expectations
- 50 states + DC × ~38 quarters × 5 NAICS codes ≈ 9,690 state-quarter-NAICS observations
- Ban states: 14 (trigger + early adopters)
- Receiving states: ~8 (border non-ban)
- Pre-treatment: 29 quarters (2015Q1–2022Q1)
- Post-treatment: 9 quarters (2022Q3–2024Q2)
