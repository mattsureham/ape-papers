# Initial Research Plan — apep_0499

## Research Question

Does targeted public investment in declining French city centers cause property market revitalization, or does it merely capitalized into existing owners' wealth? We evaluate France's Action Cœur de Ville (ACV) program — a €5 billion place-based policy targeting 222 medium-sized cities announced in March 2018 — using universe property transaction data.

## Identification Strategy

**Triple-Difference (DDD):**

$$Y_{icpt} = \alpha + \beta_1 (ACV_c \times Post_t \times Center_p) + \beta_2 (ACV_c \times Post_t) + \beta_3 (ACV_c \times Center_p) + \beta_4 (Post_t \times Center_p) + \gamma_c + \delta_t + \mu_p + \varepsilon_{icpt}$$

Where:
- $i$ = transaction, $c$ = commune, $p$ = center/periphery, $t$ = year
- $ACV_c$ = 1 if commune is an ACV beneficiary
- $Post_t$ = 1 if year ≥ 2018
- $Center_p$ = 1 if property is in city center (within commune centroid radius)
- $\gamma_c$, $\delta_t$, $\mu_p$ = commune, year, and center FE

**The DDD coefficient $\beta_1$** captures the differential price effect in ACV city centers relative to ACV peripheries, controlling for the general ACV effect ($\beta_2$) and any nationwide center/periphery trends ($\beta_4$).

**Why DDD:** During COVID-19 (2020-2022), medium-sized cities became more attractive (remote work, lower density). This confounds the standard DD. The DDD solves this by using within-commune variation: COVID migration should affect all properties in a city similarly, but ACV investment specifically targeted city centers.

**Exposure Alignment:**
- Treated: properties in city centers of ACV communes
- Primary estimand: ACV center properties post-2018 vs. ACV periphery properties
- Control: non-ACV comparable communes (matched on pre-treatment characteristics)
- Design: DDD (triple-diff)

**Power Assessment:**
- Pre-treatment periods: 4 (2014-2017)
- Treated clusters: 244 communes
- Post-treatment periods: 7 (2018-2024, with partial 2025)
- Expected transactions: ~5,000-15,000 per ACV city over full period
- MDE: With 244 clusters and 4 pre-periods, well-powered for effects > 2-3% of mean price

## Expected Effects and Mechanisms

1. **First stage:** ACV investment increases commercial renovation and new firm openings in city centers (testable via Sirene)
2. **Residential capitalization:** City-center housing prices rise in ACV cities relative to periphery and non-ACV cities
3. **Volume effect:** Transaction volumes increase as market activity picks up
4. **Mechanism decomposition:**
   - Commercial property prices (direct investment effect)
   - Residential prices near commercial areas (amenity spillover)
   - New vs. old construction (renovation vs. new supply)
5. **Distributional effects:** Price effects by property size and type (apartments vs. houses)

## Primary Specification

- **Dependent variable:** log(price per m²) for residential transactions
- **Unit:** Transaction-level, with commune × year clustering
- **Fixed effects:** Commune FE, Year FE, Property type FE
- **Controls:** Property characteristics (area, rooms, type), commune-level covariates
- **Sample:** All DVF transactions 2014-2025 in ACV communes and matched control communes
- **Estimator:** OLS with clustered SEs at commune level; CS-DiD as robustness

## Planned Robustness Checks

1. **Parallel trends:** Event study with annual coefficients (base: 2017)
2. **Placebo dates:** Fake treatment at 2015, 2016
3. **Placebo populations:** Owner-occupied only; agricultural properties; large metro areas
4. **HonestDiD/Rambachan-Roth** sensitivity to pre-trend violations
5. **Alternative control groups:** Different matching criteria; all non-ACV medium-sized cities
6. **Donut specifications:** Exclude properties near center/periphery boundary
7. **Distance gradient:** Multiple rings (0-500m, 500m-1km, 1-2km, >2km from center)
8. **Staggered CS-DiD:** Using convention signing dates instead of announcement
9. **Wild cluster bootstrap:** For inference with clustered data
10. **Leave-one-region-out:** Drop each region to check sensitivity
11. **Property type heterogeneity:** Apartments vs. houses; small vs. large

## Data Sources

| Source | Content | Access |
|--------|---------|--------|
| DVF (data.gouv.fr) | Universe property transactions 2014-2025 | Bulk CSV download (518MB) |
| ACV city list (data.gouv.fr) | 244 beneficiary communes with INSEE codes | CSV download (verified) |
| Sirene (INSEE) | Universe of firm events | API + bulk (credentials configured) |
| INSEE BDM/SDMX | Commune-level controls (population, income) | REST API (no key needed) |
| IGN AdminExpress | Commune boundary shapefiles | Free download |
