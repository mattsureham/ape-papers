# Research Plan: The Employer Side of Deportation

## Research Question
How do employers adjust hiring, separations, and job creation/destruction in response to immigration enforcement? Specifically, does the staggered activation of Secure Communities (2008-2013) reduce Hispanic hiring flows, increase separations, or destroy jobs — and do these employer-side effects differ from the worker-side impacts documented in prior survey-based studies?

## Identification Strategy
**Triple-difference (DDD):** Hispanic vs Non-Hispanic workers × early-activated vs later-activated counties × before vs after county-specific activation. This absorbs:
- County-time shocks (common to both ethnicities)
- National Hispanic employment trends
- Time-invariant county-ethnicity differences

**Estimator:** Callaway-Sant'Anna (2021) staggered DiD with county activation cohorts. Event study for pre-trend validation.

**Why credible:** Secure Communities activation was rolled out by DHS on an administrative schedule largely driven by ICE capacity and existing infrastructure, not by local labor market conditions. Alsan & Yang (2022 ReStat) and East et al. (2023 JoLE) use this variation with survey data. Our contribution is the administrative employer-reported data.

## Expected Effects and Mechanisms
1. **Hispanic hiring declines** (HirA, HirN) — employers reduce new Hispanic hires due to increased deportation risk for unauthorized workers and chilling effects on legal Hispanic workers
2. **Hispanic separations increase** (Sep) — workers leave/are deported
3. **Job destruction increases** (FrmJbLs) — firms dependent on Hispanic labor shed positions
4. **Earnings effects ambiguous** — negative (chilling effects suppress wages) or positive (scarce labor commands premium)

## Primary Specification
Y_{c,q,e} = α_c + γ_q + δ_e + β(SC_c × Post_{c,q} × Hispanic_e) + X'Γ + ε

where c = county, q = quarter, e = ethnicity (Hispanic/Non-Hispanic)

## Data Sources
- **QWI** (Census LEHD): County × quarter × NAICS sector × race/ethnicity. Employment, hires, separations, firm job creation/destruction, earnings. ~144M rows on Azure (`derived/qwi/rh/ns/*.parquet`).
- **Secure Communities activation dates**: Published in Alsan & Yang (2022), East et al. (2023). County-level activation dates 2008-2013.

## Key Robustness
1. Event study pre-trends (8+ quarters pre-activation)
2. Mechanism-matched placebo: Non-Hispanic workers in same counties
3. Industry heterogeneity: high-immigrant (construction, accommodation) vs low-immigrant (finance, professional services)
4. Wild cluster bootstrap for inference
5. Leave-one-state-out sensitivity
