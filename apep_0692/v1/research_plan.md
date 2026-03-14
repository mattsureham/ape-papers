# Research Plan: Displaced or Absorbed? Geographic Spillovers of E-Verify Mandates on Border-County Labor Markets

## Research Question

Do state-level E-Verify mandates displace Hispanic workers to adjacent untreated counties, or do workers remain in place and shift from formal to informal employment? This question resolves a key ambiguity in the immigration enforcement literature: whether the observed decline in formal Hispanic employment following E-Verify mandates reflects geographic displacement (workers moving across state lines) or formality-informality substitution (workers staying but exiting the formal sector).

## Policy Background

Ten US states mandated E-Verify for some or all employers between 2008 and 2023:
- Arizona (2008), Utah (2010), Mississippi (2011), Louisiana (2011)
- Alabama (2012), Georgia (2012), North Carolina (2013), Tennessee (2017)
- South Carolina (2021), Florida (2023)

E-Verify mandates require employers to verify workers' employment eligibility. Non-compliance exposes employers to penalties, creating strong incentives to avoid hiring unauthorized workers. The key margin of interest is whether enforcement pushes workers across state borders or into off-the-books employment.

## Identification Strategy: Spatial DDD

The design exploits three sources of variation simultaneously:

1. **D1 (Ethnicity):** Hispanic vs Non-Hispanic employment within the same county. Hispanic workers are disproportionately affected by E-Verify; Non-Hispanic workers serve as the within-county control group, absorbing all county-level confounders.

2. **D2 (Geography):** Border counties of untreated states adjacent to E-Verify states vs interior counties of untreated states. If displacement occurs, it should concentrate in border counties where the cost of crossing state lines is minimal.

3. **D3 (Time):** Pre vs post the adjacent state's E-Verify mandate adoption. The staggered timing of adoption across states provides 8+ distinct treatment events.

**Key identifying assumption:** In the absence of the adjacent state's E-Verify mandate, Hispanic employment in border counties would have evolved similarly to Hispanic employment in interior counties (conditional on the Non-Hispanic within-county control).

**Threats and tests:**
- **McCrary density test:** Check for compositional changes in county-level data
- **Pre-trend test:** Event-study coefficients should be flat in pre-period
- **Placebo industries:** Test in industries with low Hispanic concentration (e.g., mining, utilities) where E-Verify effects should be minimal
- **Distance decay:** Effects should attenuate with distance from the border

## Data

**QWI (Quarterly Workforce Indicators)** from Azure: `derived/qwi/rh/ns/{state}.parquet`
- Coverage: ~3,100 counties, all states, quarterly, by race/ethnicity × NAICS sector
- Key variables: Emp (beginning-of-quarter employment), EarnS (average monthly earnings), HirA (all hires), Sep (separations)
- Ethnicity dimension: Hispanic (rh = "A05") vs Non-Hispanic (rh = "A06") [or similar coding]
- Industry dimension: NAICS 2-digit sectors (construction [23], agriculture [11], accommodation/food [72] as high-Hispanic-share industries)

**County adjacency:** Census county adjacency file to identify border counties.

**State E-Verify mandate dates:** Hand-coded from legislative records (10 states, known dates).

## Expected Effects and Mechanisms

**If geographic displacement dominates:**
- Hispanic employment in border counties of untreated states increases after the adjacent state mandates E-Verify
- Effects concentrate in construction (NAICS 23) and accommodation/food (NAICS 72)
- Effects decay with distance from the border

**If informality substitution dominates:**
- No spillover to border counties (null DDD)
- This implies workers stay in the mandating state but exit the QWI universe (i.e., leave formal employment)

**Either result is informative.** Geographic displacement implies state-level enforcement is ineffective without federal coordination. Null spillovers imply workers absorb enforcement costs via informality.

## Primary Specification

```
Y_{c,t,e} = β(Border_c × Hispanic_e × Post_t) + δ(Border_c × Hispanic_e) + γ(Hispanic_e × Post_t) + α_c + θ_t + ε_{c,t,e}
```

Where:
- Y = log employment, log earnings, hires, or separations
- c = county, t = quarter, e = ethnicity (Hispanic/Non-Hispanic)
- Border_c = 1 if county is adjacent to an E-Verify-mandating state
- Post_t = 1 after adjacent state adopts E-Verify
- α_c, θ_t = county and quarter fixed effects

**Clustering:** State level (assignment level of treatment).

**Event study:** Dynamic version with leads and lags (-8 to +12 quarters).

## Robustness
1. Callaway-Sant'Anna for heterogeneity-robust estimates
2. Industry-specific regressions (construction vs placebo industries)
3. Distance-to-border gradient (contiguous vs 2nd-ring vs 3rd-ring counties)
4. Randomization inference (permuting treatment across states)
5. HonestDiD sensitivity analysis for parallel trends violations
