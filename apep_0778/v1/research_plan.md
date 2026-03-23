# Research Plan: The SNAP Bridge — Transitional Benefits and the Welfare Cliff

## Research Question
Does automatic SNAP continuation for families leaving TANF reduce the bureaucratic gap in food assistance? When families exit cash welfare, they must typically reapply separately for SNAP — creating a "cliff" in food assistance. 24 states adopted transitional SNAP benefits (2001–2016), providing automatic 5-month SNAP continuation. This paper estimates the causal effect on SNAP participation continuity.

## Identification Strategy
**Staggered DiD (Callaway–Sant'Anna 2021)** exploiting the staggered adoption of transitional SNAP benefits across 24 US states (2001–2016), with 27 never-treated states as controls. Treatment is binary: a state has adopted transitional benefits or has not.

**Key assumption:** Parallel trends in the SNAP-to-TANF participation ratio absent adoption of transitional benefits.

## Exposure Alignment
**Who is treated:** Families leaving TANF who would otherwise need to separately reapply for SNAP. Transitional benefits automatically continue SNAP eligibility for 5 months post-TANF exit, eliminating the reapplication barrier. The treatment operates at the state level.

**Treatment-outcome alignment:** State-month SNAP and TANF participation captures the administrative gap between programs. The SNAP/TANF ratio measures how well food assistance covers the welfare-dependent population.

## Expected Effects and Mechanisms
1. **Bridge effect:** Automatic SNAP continuation prevents families from falling through the bureaucratic gap → SNAP participation rises relative to TANF exits (SNAP/TANF ratio increases)
2. **Retention effect:** Families who maintain SNAP during transition may stay enrolled longer → persistent SNAP participation increase
3. **Expected magnitude:** Moderate positive effect on SNAP/TANF ratio (5–15% increase)

## Primary Specification
$$ATT(g,t) \text{ via Callaway–Sant'Anna (2021)}$$
Where groups $g$ are defined by the year of transitional benefits adoption, outcome is log(SNAP participation) or SNAP/TANF ratio at state-month level. Standard errors clustered at state level.

## Data Sources and Fetch Strategy

### 1. SNAP Policy Database (Treatment assignment)
- Source: USDA ERS SNAP Policy Database
- Variable: `transben` (transitional benefits adoption date by state)
- 24 treated states, 27 never-treated + DC

### 2. FNS SNAP Data Tables (Primary outcome)
- Source: USDA FNS, monthly state-level SNAP participation
- URL: https://www.fns.usda.gov/pd/supplemental-nutrition-assistance-program-snap
- Variables: Persons, households, benefits by state-month
- Coverage: FY2000–FY2026

### 3. ACF TANF Caseload Data (Denominator)
- Source: HHS ACF Office of Family Assistance
- Variables: Families, recipients by state-month
- Coverage: FY2000–FY2023

### 4. Population data (per-capita normalization)
- Source: Census Bureau / FRED API
- State annual population estimates

## Robustness Checks
1. Not-yet-treated control group
2. Placebo on elderly SNAP (age 60+ — unaffected by TANF exits)
3. Alternative outcomes: log SNAP persons, SNAP per capita
4. Excluding early adopters (NY 2001, PA 2002)
5. Anticipation (1-year window)
6. TWFE comparison
