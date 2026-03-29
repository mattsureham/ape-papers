# Research Plan: The Enforcement Tax

## Research Question

Does immigration enforcement reallocate Hispanic workers across industries rather than reducing their employment? Specifically, does the staggered activation of Secure Communities (2008–2013) shift Hispanic employment from enforcement-visible sectors (construction, manufacturing) toward enforcement-opaque sectors (food services, healthcare, social assistance)?

## Named Mechanism: "The Enforcement Tax"

If enforcement primarily redirects workers from high-wage visible sectors ($2,600/month construction) to low-wage invisible sectors ($1,300/month food services), it functions as an implicit tax on Hispanic workers' earnings — regardless of immigration status. This tax is borne through sectoral wage differentials, not through employment loss.

## Identification Strategy

**Staggered difference-in-differences** exploiting county-by-county Secure Communities activation from March 2008 to January 2013. ICE activated the program based on operational capacity (IT infrastructure, jail capacity), not local labor market conditions — activation was rolled out from the largest jails to smaller ones.

### Estimator

Callaway-Sant'Anna (2021) via the `did` R package, with county as the unit, quarter as the time period, and SC activation quarter as the treatment date. Not-yet-treated counties serve as controls.

### Main Specification

For each county $c$ in quarter $t$:

$$Y_{ct} = \text{Hispanic share in enforcement-visible industries}$$

where enforcement-visible = construction (NAICS 236, 238) and manufacturing (NAICS 311–339), and enforcement-opaque = food services (722), social assistance (624), healthcare (621).

### Triple-Difference

Hispanic vs. non-Hispanic workers × enforcement-visible vs. enforcement-opaque industries × pre/post SC activation. Non-Hispanic workers in the same county-industries should show no reallocation effect.

## Expected Effects

1. **Negative:** Hispanic employment share in construction/manufacturing falls after SC activation
2. **Positive:** Hispanic employment share in food services/healthcare rises after SC activation
3. **Zero (placebo):** Non-Hispanic employment shares unaffected
4. **Negative:** Hispanic earnings fall (compositional shift from high-wage to low-wage sectors)

## Data

**QWI (Quarterly Workforce Indicators)** from Census Bureau's LEHD program:
- Azure path: `az://derived/qwi/rh/n3/{state}.parquet`
- Dimensions: county × quarter × ethnicity (A2=Hispanic, A1=non-Hispanic) × NAICS-3
- Variables: Emp (employment), HirA (hires), Sep (separations), EarnS (earnings)
- Coverage: 51 states, ~1,267 counties with Hispanic data, quarterly 1990–2025

**SC Activation Dates:** Publicly documented ICE FOIA data. Will fetch from published research datasets.

## Primary Specification Details

- **Unit:** County (FIPS)
- **Time:** Calendar quarter (2005Q1–2015Q4)
- **Treatment:** Quarter of SC activation
- **Outcomes:** (1) Hispanic visible-sector employment share, (2) Hispanic opaque-sector employment share, (3) Hispanic average earnings
- **Clustering:** State level (SC activation was coordinated at state level in many cases)
- **Controls:** County and quarter fixed effects (absorbed by C-S estimator)

## Robustness

1. Event study with 8+ pre-treatment quarters
2. Non-Hispanic placebo
3. Bacon decomposition to check TWFE bias
4. HonestDiD sensitivity analysis
5. Alternative industry classifications (broader/narrower definitions of "visible")
6. Drop counties activated during Great Recession trough (2008Q4–2009Q2)

## Key Risk

Great Recession coincides with early SC rollout. Construction employment fell everywhere during 2008–2010. Mitigation: (a) triple-diff with non-Hispanic workers controls for aggregate industry shocks; (b) event study should show no differential trend before SC activation within the Hispanic subsample; (c) restrict to later activation cohorts (2010–2013) as robustness.
