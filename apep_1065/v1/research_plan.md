# Research Plan: The Frozen Labor Market — E-Verify Mandates and Hispanic Hiring Flow Dynamics

## Research Question

Do state mandatory E-Verify laws reduce Hispanic labor market *fluidity* in construction — compressing both hiring and separation flows — rather than simply reducing employment levels? If so, E-Verify traps existing workers in place rather than expelling them, creating monopsony-like conditions where job-to-job transitions (the primary channel for wage growth) disappear.

## Identification Strategy

**Triple-difference (DDD) with Callaway-Sant'Anna staggered DiD.**

- **Diff 1 (within-county):** Hispanic (ethnicity code A2) vs non-Hispanic (A1) workers
- **Diff 2 (across states):** E-Verify mandate states vs non-mandate states
- **Diff 3 (time):** Pre-mandate vs post-mandate periods

The within-county ethnicity comparison absorbs ALL local demand shocks (housing booms, oil prices, immigration enforcement intensity), making this design unusually clean for a labor market paper.

**Treatment states and timing:**
- Wave 1 (2008): Arizona, Mississippi
- Wave 2 (2009): South Carolina
- Wave 3 (2012): Alabama, Georgia, Louisiana, Tennessee
- Wave 4 (2013): North Carolina

**Sample restriction:** Counties with Hispanic construction employment > 50 (to avoid noise from tiny cells). ~185 treated counties, ~890 control counties.

## Expected Effects and Mechanisms

**Core hypothesis:** E-Verify *freezes* the labor market rather than clearing it.

| Outcome | Expected direction | Mechanism |
|---------|-------------------|-----------|
| New hires (HirN) | Negative | Employers avoid hiring to avoid verification costs/risks |
| Separations (Sep) | Negative | Workers avoid quitting because re-employment requires verification |
| Recalls (HirR) | Unchanged/positive | Existing employer-employee relationships unaffected |
| Stable employment (EmpS) | Positive | Workers stay put → higher measured stability |
| Employment (Emp) | Ambiguous/small | Offsetting: fewer hires AND fewer separations |
| New hire earnings (EarnHirNS) | Negative | Compressed hiring pool → lower new-hire wage premium |

**The key decomposition:** If E-Verify reduces employment *levels* only, it's a standard deterrence story. If it reduces *flows* on both margins (hiring AND separations), it's a labor market freeze — a qualitatively different phenomenon with distinct welfare implications (monopsony power, reduced wage growth from job-to-job transitions).

## Primary Specification

$$Y_{c,i,e,t} = \alpha + \beta_1 (\text{EVerify}_{s,t} \times \text{Hispanic}_e \times \text{Construction}_i) + \gamma_{c,t} + \delta_{i,e,t} + \epsilon_{c,i,e,t}$$

where:
- $Y$ = hire rate, separation rate, or stability ratio
- $c$ = county, $i$ = industry (construction vs non-construction), $e$ = ethnicity, $t$ = quarter
- $\gamma_{c,t}$ = county × quarter FEs (absorb ALL local demand)
- $\delta_{i,e,t}$ = industry × ethnicity × quarter FEs (absorb national trends)
- Cluster SEs at the state level

**Operationally:** Use `fixest::feols()` with high-dimensional fixed effects. For the staggered component, run Callaway-Sant'Anna with the ethnicity dimension aggregated.

## Data Source and Fetch Strategy

**Primary:** QWI race/ethnicity × 3-digit NAICS from Azure Blob Storage
- Path: `derived/qwi/rh/n3/*.parquet`
- Variables: HirN, HirR, Sep, Emp, EmpS, EarnHirNS
- Filter: Construction (NAICS 236, 237, 238) + comparison industries
- Demographics: Hispanic (ethnicity = 2) vs Non-Hispanic (ethnicity = 1)
- Period: 2004Q1–2016Q4 (covers all 4 treatment waves with ample pre/post)

**Comparison industries (for triple-diff):**
- Construction: NAICS 236 (building), 237 (heavy/civil), 238 (specialty trades)
- Placebo sectors: NAICS 541 (professional services), 621 (ambulatory health) — low undocumented worker share

**Data pipeline:**
1. Query Azure QWI for all states, construction + placebo NAICS, race/ethnicity
2. Construct county-quarter-industry-ethnicity panel
3. Compute flow rates: hire_rate = HirN/Emp, sep_rate = Sep/Emp, stability = EmpS/Emp
4. Merge E-Verify treatment dates
5. Restrict to counties with Hispanic construction Emp > 50 pre-treatment

## Robustness Checks

1. **Event study:** Dynamic DDD event study to test pre-trends
2. **Placebo industry:** Professional services (NAICS 541) should show no effect
3. **Placebo ethnicity:** Non-Hispanic flows should be unaffected within treated states
4. **Leave-one-state-out:** Ensure results not driven by any single state (especially Arizona)
5. **Alternative thresholds:** Vary the Hispanic employment minimum (25, 75, 100)
6. **Wild cluster bootstrap:** For inference with 8 treated states + 42 control states
