# Research Plan: apep_0640

## Research Question
Do mandatory E-Verify laws for private employers reduce Hispanic employment in high-immigrant industries, and does this reflect formal-sector displacement or genuine labor market exit?

## Idea
idea_0143 — Verify or Vanish? The Labor Market Effects of Mandatory E-Verify on Hispanic Employment Dynamics

## Policy
Ten US states mandated E-Verify for most/all private employers with staggered adoption:
- Arizona (2008), Utah (2010), Mississippi (2011), Louisiana (2011), Alabama (2012), Georgia (2012), North Carolina (2013), Tennessee (2017), South Carolina (2021), Florida (2023)

E-Verify is a federal web-based system that allows employers to check work authorization. Mandating it forces employers to verify all new hires — creating a sharp barrier for unauthorized workers who previously relied on employer discretion.

## Identification Strategy
**Triple-difference (DDD):** Compare Hispanic vs Non-Hispanic employment outcomes, in treated vs never-treated states, before vs after E-Verify mandates.

Y_{c,q,e} = α_c + γ_q + δ_e + β(Treat_s × Post_sq × Hispanic_e) + controls + ε

- Unit: county × quarter × ethnicity
- Treatment: state-level E-Verify mandate activation date
- The DDD absorbs: (1) state-level shocks affecting all workers (via Treat × Post), (2) national trends in Hispanic employment (via Hispanic × Post), (3) time-invariant county-ethnicity differences (via county × ethnicity FE)

**Primary estimator:** Callaway-Sant'Anna staggered DiD on the Hispanic-specific outcome (Hispanic Emp in treated vs untreated states), with non-Hispanic employment as placebo/control outcome.

**Robustness:**
- Sun-Abraham interaction-weighted
- Stacked DiD (clean 2-year windows)
- Exclude Arizona (most studied state)
- Control for concurrent 287(g) and Secure Communities activation at county level

## Expected Effects
1. Hispanic employment should decline in E-Verify states relative to controls (primary)
2. Non-Hispanic employment should show null or small positive effect (DDD validation)
3. Effects should be larger in high-immigrant industries (construction, accommodation/food, agriculture)
4. Hiring (HirA) should decline more sharply than separations (Sep) — consistent with verification barrier on new hires specifically
5. Earnings (EarnS) may rise if lowest-paid unauthorized workers exit the formal sector

## Primary Specification
Using CS-DiD on county-quarter panel:
- Outcome: log(Hispanic Employment) by county × quarter
- Treatment group: counties in 10 E-Verify mandate states
- Control: counties in ~40 never-treated states
- Event study: 12 quarters pre, 12 quarters post
- Clustering: state level (10 treated clusters → wild cluster bootstrap)

## Data Source
Census QWI race/ethnicity (rh) endpoint, already in Azure Blob Storage:
- Path: `derived/qwi/rh/ns/*.parquet`
- Variables: Emp, EarnS, HirA, Sep, FrmJbGn, FrmJbLs
- Coverage: county × quarter × NAICS sector × ethnicity (Hispanic/Non-Hispanic)
- ~150M+ rows, 2001-present

## Mechanism Tests
1. Industry heterogeneity: high-immigrant (NAICS 72, 23, 11, 56) vs low-immigrant industries
2. Hiring vs separations decomposition: new hire barrier vs stock adjustment
3. Earnings composition: if low-wage workers exit, avg earnings rise mechanically
4. Firm dynamics: job creation/destruction rates by ethnicity
5. Dose-response: states with broader mandates (all employers) vs narrower (25+ employees)

## Key Risks
1. Few treated clusters (10 states) → use wild cluster bootstrap and RI
2. Concurrent immigration enforcement (287g, Secure Communities) → control or exclude
3. Arizona (2008) overlaps with Great Recession → stack with/without AZ
4. QWI suppression in small cells → aggregate to state level as robustness
