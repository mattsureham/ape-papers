# Research Plan: apep_0605

## Research Question

Do resource booms from hydraulic fracturing leave US counties better or worse off in the long run? Specifically, is the relationship between the fracking boom (2003–2014) and subsequent bust (2015–2023) asymmetric — do counties lose more during busts than they gained during booms?

## Identification Strategy

**Continuous-treatment staggered DiD** exploiting geological variation in shale play exposure.

- **Treatment**: Binary indicator for county overlying a major shale play (Bakken, Barnett, Marcellus/Utica, Eagle Ford, Permian, Haynesville, Niobrara)
- **Treatment timing**: Staggered by play — first significant production year varies (2003 Barnett, 2006 Bakken, 2008 Marcellus/Haynesville, 2010 Eagle Ford/Permian/Niobrara)
- **Control group**: Counties NOT overlying major shale plays (never-treated)
- **Estimator**: Callaway & Sant'Anna (2021) with never-treated comparison group
- **Clustering**: State level (to account for spatial correlation within states)

### Why credible
Geological endowment was determined millions of years before county formation. Shale play locations are exogenous to modern county economic conditions. The identifying assumption is that shale and non-shale counties would have followed parallel employment trends absent fracking. With 15+ years of pre-period data (2001 to first treatment), this assumption is directly testable.

## Expected Effects and Mechanisms

- **Boom phase**: Positive employment effects driven by mining sector expansion, construction, and local multiplier effects
- **Bust phase**: Employment declines as mining contracts, but potentially asymmetric if:
  1. Workers who relocated leave permanently (population drain)
  2. Local businesses that expanded during boom cannot sustain without mining income
  3. Dutch disease eroded non-mining tradable sectors during boom
  4. Housing/cost-of-living increases persist, squeezing remaining residents

**Key innovation**: Formal asymmetry test comparing cumulative boom gains to cumulative bust losses.

## Primary Specification

```
Y_{ct} = α_c + α_t + Σ_k β_k × 1[K_{ct} = k] + ε_{ct}
```

Where Y_ct is log employment in county c, year t; K_ct is event time relative to first fracking production; α_c and α_t are county and year fixed effects. Estimated via Callaway-Sant'Anna with dynamic effects.

## Data Sources

1. **Employment**: Census QWI via Azure Parquet (derived/qwi/sa/ns/) — county×quarter×industry, 2001–present
2. **Oil prices**: FRED API — WTI crude oil (DCOILWTICO)
3. **Shale county crosswalk**: Hard-coded based on EIA DPR region geographies
4. **County covariates**: BEA API — population, per capita income (CAINC1)

## Design Parameters

- ~100 core shale counties across 7 major plays
- ~3,000 never-treated control counties
- 4 treatment cohorts (2003, 2006, 2008, 2010)
- 15+ pre-treatment years for parallel trends validation
- Primary outcomes: total employment, mining employment, average earnings
