# Research Plan: The Racial Anatomy of Food Desert Formation

## Research Question

Does the shift from supermarkets to convenience stores in the SNAP retail network disproportionately destroy Black food retail employment? The SNAP retailer composition shifted dramatically: convenience store share rose from 37.6% to 44.8% while supermarket share fell from 27.1% to 15.8% (2005–2024). This paper tests whether this restructuring creates a dual-sided market failure: communities lose both food access AND the jobs that food retailers provided — with effects concentrated among Black workers.

## Identification Strategy

**Event-study DiD with Race Triple-Difference.** Treatment: county experiences supermarket-class SNAP retailer exit(s). Unit: county × quarter × race. The race DDD compares within-county, within-quarter changes in Black vs White food retail employment after supermarket exit events.

**Specification:**
```
Y_{c,t,r} = α_c + γ_t + δ_r + β₁ Post_{c,t} + β₂ (Post_{c,t} × Black_r) + ε_{c,t,r}
```

The coefficient β₂ captures the *differential* effect on Black workers. State-level and county-level economic shocks affect both races equally → β₂ is identified.

**Why this works:** Black workers in food retail face 55% higher separation rates than White workers even pre-treatment. If supermarket exits disproportionately displace Black workers (who occupy lower-wage, lower-seniority positions within these stores), β₂ should be negative for employment and positive for separations.

## Expected Effects

1. Supermarket exit → decline in total NAICS 445 employment (county level)
2. Black employment falls more than White (differential displacement)
3. Black separations rise more than White (differential churning)
4. Effects concentrated in counties with higher pre-period Black employment share

## Data Sources

1. **QWI NAICS 445** (Census LEHD): County × quarter × race employment, hires, separations, earnings. On Azure at `derived/qwi/rh/n3/*.parquet`. ~3,190 counties, 2001–2025.

2. **SNAP Retailer Historical Database** (USDA FNS): 703K retailers with authorization/deauthorization dates, store type, county. Already downloaded for apep_0753.

## Robustness

1. Event-study pre-trends by race
2. Placebo: non-food retail employment (NAICS 44-45 excluding 445)
3. Heterogeneity by county Black population share
4. Alternative treatment definitions (net loss threshold, continuous intensity)
5. Clustering at county level (3,000+ clusters)
