# Research Plan: Subsidy Caps and Developer Capture

## Research Question

Do developers capture housing subsidies by pricing at government-imposed ceilings? When France reclassified 865 communes into higher PTZ (Prêt à Taux Zéro) zones in July 2024 — shifting price caps by €22,500 to €75,000 — did the bunching mass at price caps migrate from old to new thresholds? This "difference-in-bunching" reveals whether developers adjust prices to extract the maximum subsidy, and how rapidly.

## Policy Background

France's PTZ imposes zone-specific price ceilings on eligible new-build purchases. Five zones (Abis, A, B1, B2, C) combined with 4 household-size brackets create 20 distinct price caps. The Arrêté of 5 July 2024 reclassified 865 communes:
- 485 communes: B2 → B1 (cap Δ = +€37,500, from €165K to €202.5K for 1-person household)
- 190 communes: C → B1 (cap Δ = +€52,500)
- 129 communes: B1 → A (cap Δ = +€22,500)
- 42 communes: A → Abis (cap Δ varies)

## Identification Strategy

**Multi-cutoff bunching with difference-in-bunching from reclassification.**

1. **Cross-sectional bunching:** Estimate excess mass at each of the 20 PTZ price caps in the universe of new-build transactions, using the standard polynomial counterfactual method (Chetty et al. 2011, Kleven 2016).

2. **Difference-in-bunching (core identification):** In reclassified communes, bunching should *migrate* from the old cap to the new cap after July 2024. Non-reclassified communes serve as controls. This within-commune, across-time test eliminates confounders that affect the level of bunching.

3. **Dose-response:** The reclassification magnitudes vary (€22.5K to €75K), enabling estimation of how bunching mass responds to the size of the cap shift.

## Placebos

- **Second-hand properties:** No PTZ eligibility → no bunching expected at PTZ caps.
- **Pre-reform distributions:** Bunching at new caps should be absent before July 2024.
- **Non-reclassified communes:** No migration of bunching mass.

## Expected Effects

- **Excess mass at PTZ caps:** Significant bunching in new-build transactions, absent in second-hand.
- **Migration:** After reclassification, bunching at old cap disappears, appears at new cap.
- **Dose-response:** Larger cap shifts → larger bunching migration (if developers are responsive).
- **Mechanism:** Developer capture — prices adjust to extract maximum subsidy for buyers.

## Primary Specification

Bunching estimation following Kleven (2016):
- Unit: transaction price (€)
- Running variable: distance from nearest PTZ cap (€, normalized)
- Bin width: €2,500
- Counterfactual: 7th-degree polynomial fitted to distribution excluding bunching region
- Excess mass: b = (B_actual - B_counterfactual) / B_counterfactual
- Standard errors: bootstrap (500 replications)

Difference-in-bunching:
- DiD on excess mass: reclassified vs non-reclassified communes × pre/post July 2024
- Regression: bin_count ~ distance_poly + post × reclassified + commune_FE + month_FE

## Data Sources

1. **DVF (Demandes de Valeurs Foncières):** Universe of property transactions in metropolitan France. Downloaded from data.gouv.fr. Years: 2020-2024. ~17.5M transactions total. Variables: price, commune code, date, property type (apartment/house), surface area, number of rooms.

2. **Zone ABC classification:** CSV mapping 34,875 communes to housing-tension zones (Abis, A, B1, B2, C). From Ministry of Housing.

3. **Reclassification lists:** 865 communes reclassified by Arrêté of 5 July 2024. Downloadable from Légifrance.

## Data Fetch Strategy

- DVF: HTTP bulk download from data.gouv.fr (yearly files, CSV/gzip)
- Zone ABC: Direct CSV download
- Reclassification: Manual encoding from Arrêté text (865 communes with old→new zone mapping)
- All fetching done in R (`01_fetch_data.R`) for reproducibility

## Hardware Considerations

DVF is ~500MB/year compressed. With 5 years, total ~2.5GB raw. Will use Arrow/DuckDB for out-of-core processing and filter to relevant price ranges early. Focus on new-build transactions near PTZ caps to keep memory manageable.
