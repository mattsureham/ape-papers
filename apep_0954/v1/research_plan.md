# Research Plan: The Port Shock — Beirut Explosion and Spatial Food Price Transmission

## Research Question
Did the August 4, 2020 Beirut port explosion — which destroyed Lebanon's only grain silos and disrupted 70% of the country's import capacity — create differential food price effects across Lebanese markets based on their proximity to the alternative Tripoli port? Can we decompose the effect into a pure port-infrastructure channel by comparing imported vs. locally-produced commodities?

## Identification Strategy
**Spatial Difference-in-Differences with Triple-Difference**

The Beirut explosion is a sharp, exogenous supply-chain shock. The key variation:
- **Spatial:** Markets differ in distance to Beirut (destroyed) vs. Tripoli (alternative) port. Beirut-proximate markets lost their primary supply chain; Tripoli-proximate markets had built-in substitution.
- **Commodity:** Imported goods (rice, lentils, vegetable oil, sugar) flow through ports. Locally-produced goods (eggs, vegetables) do not. The triple-diff exploits this imported-vs-local distinction.

**Primary specification (DiD):**
```
log(P_mct) = α_mc + γ_ct + β × (BeirutProximity_m × Post_t) + ε_mct
```
Where BeirutProximity_m = distance to Tripoli / (distance to Beirut + distance to Tripoli), continuous ∈ [0,1].

**Triple-difference:**
```
log(P_mct) = α_mc + γ_ct + δ_mt + β × (BeirutProximity_m × Imported_c × Post_t) + controls + ε_mct
```

## Expected Effects
- Beirut-proximate markets should see larger price increases for imported goods
- Tripoli-proximate markets should partially buffer the shock through port substitution
- Locally-produced goods should show no spatial differential (symmetric shock across all markets)
- The "port dependency premium" = β estimates the price penalty from single-port concentration

## Primary Specification
- Unit: market × commodity × month
- Treatment: BeirutProximity (continuous) × Post (Aug 2020+)
- Outcome: log food prices in Lebanese Pounds (LBP)
- Fixed effects: market×commodity, commodity×month (or market×month for triple-diff)
- Clustering: market level
- Pre-period: Jan 2019 – Jul 2020 (19 months)
- Post-period: Aug 2020 – Dec 2021 (17 months, before hyperinflation makes prices meaningless)

## Robustness
1. **Event study:** Monthly β_t coefficients from Jan 2019 through Dec 2021
2. **Placebo commodity test:** Locally-produced goods (eggs, vegetables) should show null spatial differential
3. **Distance bins:** 0-20km, 20-40km, 40-60km from Beirut
4. **Exclude Beirut markets:** In case direct destruction rather than supply-chain disruption drives results
5. **Alternative post-window:** Restrict to Aug-Dec 2020 (before broader economic collapse accelerates)

## Data Sources
1. **WFP VAM Food Prices (primary):** HDX dataset `wfp-food-prices-for-lebanon`. 27,172 rows, 27 markets, 33 commodities, Aug 2012 – Feb 2026. Free CSV download.
2. **Market geocoding:** WFP markets have governorate/location names; geocode via Google/OSM to compute distances to Beirut port (33.9°N, 35.52°E) and Tripoli port (34.45°N, 35.83°E).
3. **Commodity classification:** Classify 33 commodities as imported vs. locally-produced using FAO Lebanon food balance sheets.

## Risks and Mitigations
- **Hyperinflation confound:** Lebanon experienced extreme currency collapse (LBP lost 90%+ value). Mitigation: use within-month commodity×market variation (triple-diff absorbs common macro shocks via commodity×month FE).
- **COVID confound:** COVID lockdowns reduced food supply chains nationally. Mitigation: COVID is symmetric across markets (all of Lebanon locked down); spatial variation comes from port destruction, not COVID.
- **Small N (27 markets):** The unit of analysis is market×commodity×month, giving ~267 pairs × 36 months ≈ 9,600+ observations. Wild cluster bootstrap at market level for inference.
- **Currency denomination:** Prices in LBP; massive inflation. Use log prices + time FE to absorb level effects.
