# Research Plan: The Corporate Farm Brake

## Research Question

Do anti-corporate farming laws actually restrain agricultural consolidation, or are they purely symbolic? Nebraska's Initiative 300 (1982) prohibited non-family corporations from acquiring farmland. The Eighth Circuit struck it down in December 2006 (Jones v. Gale); SCOTUS declined certiorari in April 2007. Neighboring Iowa, Kansas, South Dakota, and Missouri maintained their restrictions. This judicial deregulation creates a clean spatial discontinuity at Nebraska's borders — the first quasi-experiment on anti-corporate farming laws.

## Identification Strategy

**Spatial RDD + Event Study at Nebraska borders.**

- **Running variable:** Distance from county centroid to the nearest Nebraska state border (positive = Nebraska side, negative = neighbor side).
- **Treatment:** Nebraska counties, post-2007 (corporate farming now permitted).
- **Control:** Border counties in Iowa, Kansas, South Dakota, Missouri (corporate restrictions maintained).
- **Key assumption:** Counties on opposite sides of the border had similar agricultural trajectories before the 2007 ruling. Testable with pre-treatment Census data (2002, 2007).
- **Why exogenous:** The Eighth Circuit ruled on dormant Commerce Clause grounds — a constitutional challenge filed by outsiders, not driven by local agricultural conditions.

## Expected Effects and Mechanisms

If anti-corporate farming laws are binding constraints on consolidation:
1. **Farm consolidation:** Post-2007, Nebraska border counties should show larger average farm size, fewer small farms, and more large farms relative to neighbor border counties.
2. **Agricultural employment:** QWI should show changes in agricultural employment composition — potentially fewer establishments but similar or higher payroll per worker (corporate efficiency).
3. **Land values:** Deregulation may raise farmland values (corporate buyers with deeper capital).

The "corporate farm brake" hypothesis: these laws act as a friction on the natural consolidation process in agriculture. Removing the brake accelerates consolidation on the deregulated side of the border.

## Primary Specification

Y_{ct} = α + β₁(Nebraska_c × Post2007_t) + f(distance_c) + γ_c + δ_t + X_{ct}Γ + ε_{ct}

- Y: farm count, average farm size, share of farms >1000 acres, QWI employment
- f(distance): polynomial or local linear in distance to border
- γ_c: county fixed effects
- δ_t: year fixed effects
- X_{ct}: NOAA weather controls, crop prices
- Cluster SEs at state-border-segment level

## Data Sources

1. **NASS Census of Agriculture** (USDA QuickStats API): County-level farm counts by size class, average farm size, land in farms. Years: 2002, 2007, 2012, 2017, 2022. Key: https://quickstats.nass.usda.gov/api
2. **QWI** (Census Bureau): County-level agricultural employment (NAICS 111 Crop, 112 Animal). Quarterly, 1999-2025. Already on Azure.
3. **County centroids:** Census TIGER/Line for computing distance to state borders.
4. **NASS farmland values** (optional): Land values per acre by county.

## Fetch Strategy

1. NASS API with Census API key for farm size distribution data
2. QWI from Azure for agricultural employment
3. Compute border distances from TIGER county centroids and state boundaries
4. NOAA weather data for controls (optional)

## Exposure Alignment

**Who is actually treated?** All Nebraska counties are treated by the judicial invalidation of Initiative 300, which removed the prohibition on non-family corporate farming statewide. The treatment is binary and uniform: after December 2006, corporate entities could legally acquire farmland in Nebraska but not in neighboring states that maintained their restrictions.

**Exposure timing:** The ruling was issued December 2006; SCOTUS declined certiorari April 2007. The first Census of Agriculture conducted entirely after the ruling is 2012 (data for calendar year 2012). The 2007 Census reflects the last pre-treatment year. QWI annual data treats 2007 onward as post-treatment.

**Spillover concerns:** Corporate entities could theoretically substitute between Nebraska and neighboring states, creating negative spillovers on control counties. The null result cannot be driven by such spillovers inflating the treatment effect.

## Robustness

1. Pre-treatment parallel trends (2002 vs 2007 Census)
2. Placebo borders within Nebraska (east vs west, not at state border)
3. Bandwidth sensitivity (50km, 100km, 150km from border)
4. Excluding counties with major urban areas
5. Different polynomial orders for distance function
