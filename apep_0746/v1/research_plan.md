# Research Plan: Does Priority Education Stigmatize Neighborhoods?

## Research Question

Does France's REP/REP+ priority education designation increase or decrease housing prices at school catchment boundaries? If the "priority education" label carries neighborhood stigma, we should observe a negative price discontinuity at REP/REP+ boundaries — even though these schools receive substantial additional resources (class sizes capped at 12, teacher salary bonuses of EUR 1,700-5,000/year).

## Identification Strategy

**Spatial RDD** following Black (1999, AER), adapted to French institutional setting.

- **Running variable:** Signed geodesic distance from each DVF property transaction to the nearest REP/non-REP college catchment boundary segment.
- **Treatment:** Property falls within a REP or REP+ college catchment area (carte scolaire).
- **Assignment:** Sharp — residential address determines college assignment. Fuzzy element from ~10% derogation rate makes this a fuzzy RDD where sector assignment instruments for actual attendance.
- **Bandwidth:** Primary 300m; robustness at 200m, 500m, 1000m.
- **Clustering:** At boundary-segment level (to account for spatial correlation along each border).

## Expected Effects and Mechanisms

**Competing channels:**
1. **Resource effect (+):** REP+ schools have class sizes of 12 (vs. ~25), better-paid teachers, more support staff. Families value school quality.
2. **Stigma effect (-):** "Priority education" label signals neighborhood disadvantage. Sorting of higher-SES families away from REP zones.
3. **Peer composition (-):** REP zones serve disadvantaged populations by design. Families may avoid peer effects regardless of school resources.

**Prior:** We expect net capitalization to be **negative** (stigma dominates), consistent with place-based designation literature. The magnitude reveals the relative strength of resources vs. stigma.

## Primary Specification

$$\log(P_i) = \alpha + \tau \cdot \text{REP}_i + f(\text{dist}_i) + \mathbf{X}_i'\beta + \gamma_t + \delta_b + \varepsilon_i$$

Where:
- $P_i$ = transaction price
- $\text{REP}_i$ = 1 if property is in REP/REP+ catchment
- $f(\text{dist}_i)$ = local linear polynomial in signed distance (separate slopes each side)
- $\mathbf{X}_i$ = property controls (type, rooms, surface area from DVF)
- $\gamma_t$ = year-quarter fixed effects
- $\delta_b$ = boundary-segment fixed effects (comparing properties along the same boundary)
- Clustered SEs at boundary-segment level

**Heterogeneity:** REP vs. REP+ (dose-response); urban vs. periurban; pre-2017 vs. post-2017 (class size reduction).

## Data Sources

1. **DVF (Demandes de Valeurs Foncières):** Universe of property transactions in France with GPS coordinates. Available as geolocalized CSV on data.gouv.fr (494 MB). Contains: price, date, property type, surface, rooms, lat/lon.

2. **College sector GeoJSON:** School catchment area polygons for all French colleges. 299 MB on data.gouv.fr. Each polygon maps to a specific college.

3. **REP/REP+ list:** Official list of 731 REP and 362 REP+ colleges on data.education.gouv.fr.

4. **IVAL indicators (secondary):** College-level performance indicators (brevet pass rates, value-added) for mechanism analysis.

## Fetch Strategy

1. Download DVF geolocalized CSV from data.gouv.fr
2. Download college sector GeoJSON from data.gouv.fr
3. Download REP/REP+ college list
4. In R: read DVF with data.table, read GeoJSON with sf, spatial join to assign each transaction to a college sector
5. Compute signed distance from each transaction to nearest REP/non-REP boundary
6. Restrict to transactions within bandwidth of a boundary

## Robustness and Placebo Tests

1. **Bandwidth sensitivity:** 200m, 300m, 500m, 1000m
2. **Polynomial order:** Linear, quadratic
3. **Donut hole:** Exclude transactions within 50m of boundary
4. **McCrary density test:** Check for sorting at the boundary
5. **Covariate balance:** Property characteristics (type, surface, rooms) should be smooth at the boundary
6. **Placebo boundaries:** Use non-REP college sector boundaries where both sides are non-REP
7. **Temporal placebo:** Pre-2015 transactions (before current REP map was drawn)
8. **REP vs. REP+ dose-response:** If stigma drives the effect, both should show similar discounts; if resources matter, REP+ discount should be smaller
