# Initial Research Plan: The Thin Blue Line at the Border

## Research Question

Do police austerity cuts cause crime? This paper exploits the sharp discontinuity in policing regimes at Police Force Area (PFA) boundaries in England and Wales, where differential budget cuts created growing divergences in officer density across adjacent forces. The boundary discontinuity design identifies the causal effect of policing intensity on crime while controlling for all unobservables that vary smoothly across space.

## Identification Strategy

**Boundary Discontinuity Design (BDD)** at PFA boundaries.

- **Running variable:** Signed distance from each LSOA's population-weighted centroid to the nearest PFA boundary. Positive = high-cut force side; negative = low-cut force side.
- **Treatment:** Being on the side of the boundary where the police force experienced larger austerity-driven officer reductions (2010-2019).
- **Identifying assumption:** Unobserved determinants of crime are continuous through the PFA boundary. Only the policing regime changes discontinuously.
- **Multi-boundary pooling:** Stack all boundary segments across 43 forces. Include boundary-pair × year fixed effects.

## Expected Effects and Mechanisms

1. **Direct policing effect:** Crime increases on the heavily-cut side of the boundary (reduced deterrence, slower response, lower clearance rates)
2. **Crime composition:** Visible street crime (ASB, violence) responds most; online/domestic crime less affected
3. **Spatial displacement:** Criminals may migrate toward the understaffed side, creating a "pull" effect
4. **Property price capitalization:** Safety differentials at the boundary should capitalize into house prices (Rosen 1974)

## Exposure Alignment (BDD-specific)

- **Who is treated?** LSOAs on the side of PFA boundaries where the force experienced larger officer reductions
- **Primary estimand:** Local average treatment effect at the boundary — the crime impact of differential policing intensity for neighborhoods at the margin
- **Placebo population:** LSOAs far from any PFA boundary (should show no boundary effect); crime types unrelated to local policing (online fraud, cybercrime)
- **Design:** Cross-sectional BDD pooled across multiple boundary pairs, with pre/post variation exploiting the timing of austerity cuts

## Power Assessment

- **LSOAs:** ~33,000 in England and Wales
- **PFA boundaries:** 43 forces create ~80+ boundary segments
- **LSOAs within 5km of boundaries:** Estimated ~5,000-8,000 (sufficient for bandwidth-optimal RDD)
- **Time periods:** December 2010 - January 2026 (181 months)
- **Pre-treatment period:** Dec 2010 - Mar 2012 (before deepest cuts)
- **Post-treatment period:** Apr 2012 - Jan 2026 (progressive cuts, then 2019 uplift)
- **Power:** With thousands of LSOAs near boundaries and 15+ years of monthly data, power is not a concern. Even small effects (~2-5% change in crime rates) should be detectable.

## Primary Specification

```
Crime_{i,t} = α + β₁ · HighCutSide_{i} + f(distance_{i}) + γ_{b(i),t} + X_{i}β₂ + ε_{i,t}
```

Where:
- `Crime_{i,t}` = log crime count in LSOA i, month t
- `HighCutSide_{i}` = indicator for being on the heavily-cut side of boundary
- `f(distance_{i})` = polynomial in signed distance to boundary (separate slopes each side)
- `γ_{b(i),t}` = boundary-pair × year fixed effects
- `X_{i}` = LSOA-level covariates (population, density, deprivation)

Bandwidth: MSE-optimal (Calonico, Cattaneo, Titiunik 2014). Kernel: triangular.

## Planned Robustness Checks

1. **Pre-period balance:** Show crime rates smooth through boundaries pre-2012
2. **Covariate balance:** IMD rank, population density, housing type smooth at boundary
3. **McCrary density test:** No bunching of LSOAs at boundary (manipulation check)
4. **Bandwidth sensitivity:** Report results for 0.5×, 1×, 1.5×, 2× optimal bandwidth
5. **Donut RDD:** Drop LSOAs closest to boundary (within 500m) to check sensitivity
6. **Polynomial order:** Linear, quadratic, cubic
7. **Placebo outcomes:** Online fraud, cybercrime (shouldn't show boundary effect)
8. **Placebo cutoffs:** Test for discontinuities at non-boundary points
9. **COVID robustness:** Show results excluding 2020-2021
10. **Boundary segment heterogeneity:** Test for urban vs rural, high-cut vs moderate-cut
11. **Event study:** Plot the boundary discontinuity year by year to show it grows with cuts

## Data Sources

| Data | Source | Granularity | Period |
|------|--------|-------------|--------|
| Crime counts | Police API bulk download (data.police.uk) | LSOA × month | Dec 2010 - Jan 2026 |
| PFA boundaries | ONS Open Geography Portal | Shapefile/GeoJSON | Dec 2023 |
| LSOA centroids | ONS population-weighted centroids | Point geometry | 2021 |
| Police officers | Home Office workforce statistics | Force × year | 2010-2025 |
| Property prices | HM Land Registry PPD | Transaction × postcode | 1995-2026 |
| Demographics | ONS Census/NOMIS | LSOA | 2011, 2021 |
| Firm data | Companies House bulk | Firm × postcode | 2010-2026 |

## COVID Handling

The 2020-2021 period saw dramatic crime changes (lockdowns reduced street crime, domestic crime rose). Strategy:
1. Include year fixed effects that absorb aggregate crime trends
2. Present main results both with and without 2020-2021
3. The boundary design partially addresses this: COVID affected both sides of the boundary similarly, so the CROSS-BOUNDARY discontinuity should be unaffected
4. If results are driven by COVID period, flag this prominently

## Paper Structure (Target: 28-30 pages)

1. Introduction (3 pages) — Hook with austerity debate, contribution, preview results
2. Institutional Background (3 pages) — UK policing structure, austerity timeline, force-level variation
3. Data and Measurement (4 pages) — Sources, construction, descriptive statistics
4. Empirical Strategy (4 pages) — BDD design, assumptions, identification threats
5. Results (6 pages) — Main effects, crime decomposition, displacement
6. Property Price Capitalization (3 pages) — Land Registry boundary analysis
7. Robustness (3 pages) — Balance tests, placebos, bandwidth sensitivity
8. Conclusion (2 pages) — Welfare implications, policy counterfactual
+ Appendix (5-8 pages) — Additional figures, tables, data documentation
