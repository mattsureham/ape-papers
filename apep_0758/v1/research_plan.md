# Research Plan: Loosening the Gate — SNAP BBCE and Labor Supply

## Research Question
Does relaxing SNAP income eligibility thresholds via Broad-Based Categorical Eligibility (BBCE) increase program enrollment while reducing labor supply at the intensive margin?

## Policy Context
BBCE allows states to raise the SNAP gross income limit from 130% FPL to as high as 200% FPL and eliminate asset tests by linking SNAP eligibility to receipt of any TANF-funded benefit (including informational brochures). 42 states adopted BBCE between 2000 (Delaware) and 2018 (Indiana), with bulk adoption during 2007–2011. This creates a textbook staggered adoption design.

## Identification Strategy
**Callaway-Sant'Anna staggered DiD.** Binary treatment: state adopted BBCE (yes/no). 42 treated states, 8 never-adopters + DC as potential control. Event study for dynamic effects and pre-trend testing.

**Key assumption:** Absent BBCE adoption, SNAP participation and labor supply in adopting states would have followed parallel trends to non-adopting states, conditional on state and year fixed effects.

**Placebo test:** Higher-income households (above 200% FPL) should be unaffected.

## Data Sources
1. **USDA SNAP Policy Database** (ERS): State-month BBCE adoption dates, income thresholds, asset test status. Confirmed: 15,301 rows × 49 columns.
2. **Census ACS 1-year** (via tidycensus): State-level SNAP receipt (B22003), poverty rates, employment.
3. **Census QWI** (via Census API): State-quarter employment and earnings by education level. Focus: low-education workers (no HS diploma, HS only).
4. **FRED** (via fredr): State unemployment rates for controls.

## Expected Effects
- **Enrollment:** Positive — BBCE expands the eligible population and eliminates asset tests.
- **Labor supply (intensive margin):** Ambiguous — higher income thresholds create lower marginal tax rates for some workers (positive) but may reduce work effort for those near new eligibility boundary (negative). The net effect is the key empirical question.

## Primary Specification
Using Callaway-Sant'Anna (2021):
- yname = SNAP participation rate or employment outcome
- tname = year
- idname = state FIPS
- gname = first year of BBCE adoption
- control_group = "nevertreated"

Standard errors clustered at the state level. Event study via aggte(type = "dynamic").

## Estimation Plan
1. Callaway-Sant'Anna ATT for SNAP participation
2. Callaway-Sant'Anna ATT for employment/earnings (QWI low-education)
3. Event study for both to check pre-trends and dynamic effects
4. Heterogeneity by state baseline poverty rate
5. Placebo: high-education workers should show null
