# Initial Research Plan — apep_0496

## Research Question

Does the French government's education priority label (REP/REP+) causally affect local housing markets? What mechanisms drive any capitalization — school assignment rigidity, information/stigma signals, or actual resource changes? Does the availability of private school alternatives attenuate these effects?

## Identification Strategy

### Main Design: Boundary RDD

- **Running variable:** Distance from property to the nearest collège catchment boundary where one side is REP/REP+ and the other is non-REP
- **Treatment:** Being on the REP/REP+ side of the boundary
- **Outcome:** Log property transaction price per square meter (DVF)
- **Bandwidth:** Data-driven optimal bandwidth (Calonico, Cattaneo, Titiunik 2014)
- **Kernel:** Triangular (with uniform as robustness)

### DiDisc: Difference-in-Discontinuity

- **Shock:** The 2015 REP reform that redrew the education priority map
- **Switchers:** Collèges that gained or lost REP/REP+ status in 2015
- **Design:** Compare the boundary gap before (2014-2015) vs after (2016-2024) the reform at switcher boundaries, differenced against stable boundaries
- **Placebo:** Non-REP/non-REP boundaries (should show no gap change)

### Mechanism: Private School Outside Option

- **Moderator:** Local private school density (number of private collèges within 5km of boundary)
- **Hypothesis:** Boundary capitalization should be SMALLER where private school density is higher (private schools offer an exit from carte scolaire assignment)
- **Design:** Interact boundary RDD with private school density; triple-diff with reform timing
- **Balance check:** Verify private density uncorrelated with boundary-level observables

## Expected Effects and Mechanisms

1. **Baseline boundary gap:** Properties on the REP side should be ~2-5% cheaper per m², consistent with Fack & Grenet (2010) for Paris
2. **Reform effect (DiDisc):** Schools gaining REP status → boundary gap widens (stigma/label); schools losing REP → gap narrows
3. **Private school attenuation:** Boundary gap should be ~30-50% smaller near dense private school areas
4. **Information vs assignment:** If capitalization is about ASSIGNMENT rigidity (carte scolaire), private school density should fully attenuate it. If it's about INFORMATION (label signals neighborhood quality), private schools shouldn't matter much.

## Primary Specification

```
log(price_m2_it) = α + τ · REP_side_i + f(dist_boundary_i) + τ × f(dist)
                   + β · X_it + γ_boundary + δ_year + ε_it
```

Where:
- `price_m2_it` = transaction price per square meter for property i in year t
- `REP_side_i` = 1 if property is on the REP side of the boundary
- `f(dist_boundary_i)` = local polynomial in distance to boundary (separate slopes each side)
- `X_it` = property controls (rooms, type, surface area)
- `γ_boundary` = boundary fixed effects
- `δ_year` = year fixed effects

## Planned Robustness Checks

1. **McCrary density test** at boundaries (ensure no sorting/bunching)
2. **Covariate balance** at boundary (property characteristics should be smooth)
3. **Donut specifications** (drop transactions within 100m of boundary)
4. **Alternative bandwidths** (0.5×, 1.5×, 2× optimal)
5. **Uniform kernel** (vs triangular)
6. **Higher-order polynomials** (quadratic, cubic)
7. **Placebo boundaries** (non-REP/non-REP boundaries as falsification)
8. **Pre-reform event study** (year-by-year boundary gaps for switchers)
9. **Alternative outcome** (transaction volume, property type composition)
10. **Exclude Île-de-France** (Paris region has unique dynamics)

## Data Sources

| Dataset | Source | Variables | Period |
|---------|--------|-----------|--------|
| DVF géolocalisé | data.gouv.fr | Transaction prices, coordinates, property type, surface | 2014-2024 |
| Carte scolaire collèges | data.gouv.fr | Catchment boundary polygons | Current (+ historical if available) |
| REP/REP+ school lists | data.education.gouv.fr | School names, addresses, REP/REP+ status | Current |
| Brevet results (IVAC) | education.gouv.fr | Pass rates, value-added by collège | 2014-2024 |
| Private school locations | data.education.gouv.fr or Sirene | Coordinates of private collèges | Current |

## Power Assessment

- DVF: ~3-4 million transactions per year × 10 years = ~30-40M total
- Transactions near REP/non-REP boundaries (within 1km): likely ~500K-1M
- With hundreds of boundaries nationally, power should be excellent for main RDD
- DiDisc (switchers only): ~100-200 boundaries, still well-powered
- Triple-diff with private school interaction: most demanding on power, may need wider bandwidth
