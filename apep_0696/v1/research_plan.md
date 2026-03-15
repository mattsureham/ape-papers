# Research Plan: The Environmental Costs of Fiscal Windfalls

## Research Question

Does exogenous municipal revenue drive deforestation in Brazil? Using the 17 population thresholds embedded in Brazil's Fundo de Participação dos Municípios (FPM) intergovernmental transfer formula as a multi-cutoff regression discontinuity, this paper estimates the causal effect of fiscal windfalls on satellite-measured deforestation, fire incidence, and land-use change across 5,570 Brazilian municipalities.

## Identification Strategy

**Primary: Multi-Cutoff RDD**

The FPM is Brazil's primary intergovernmental transfer from federal to municipal governments (~25% of municipal revenues, R$100B+ annually). Transfer amounts are determined by a formula based on population brackets with 17 sharp thresholds at:
- 10,189 / 13,584 / 16,980 / 23,772 / 30,564 / 37,356 / 44,148 / 50,940 / 61,128 / 71,316 / 81,504 / 91,692 / 101,880 / 115,464 / 129,048 / 142,632 / 156,216 inhabitants

Each bracket increases the municipality's "coefficient" used to compute its FPM share. Municipalities just above a threshold receive substantially more transfer revenue than municipalities just below (15–50% revenue jumps at lower thresholds). Population is measured in the decennial census and remains fixed between censuses, creating plausibly exogenous cross-sectional variation.

**Identification assumption:** Municipalities cannot precisely manipulate their census population count to fall just above a threshold. Density tests (McCrary) and covariate balance checks (geographic, climatic) validate this.

**Normalized running variable:** Following Brollo et al. (2013), normalize the running variable as (actual population / threshold population) − 1 for each threshold, stacking all 17 cutoffs. This pools variation across cutoffs while allowing heterogeneous effects by threshold height.

**Outcome:** Annual deforestation area (km²/year) from MapBiomas land-use change data (2000–2023), aggregated from 30m satellite imagery. Secondary outcomes: fire counts (INPE PRODES/BDQueimadas), agricultural conversion rates.

**Key mechanism:** Extra revenue → expanded municipal public works (roads, infrastructure) → land value rise in forested periphery → increased clearing by farmers and ranchers.

## Expected Effects and Mechanisms

- FPM windfalls fund rural road construction and frontier infrastructure
- Higher revenue enables corruption-facilitated land titling (Brollo et al. 2013 find FPM increases corruption)
- Deforestation expected to *increase* with transfers, especially in Amazon biome municipalities
- Effect should be larger in high-forest-stock municipalities, near Amazon/Cerrado frontier
- Placebo: Atlantic Forest (already mostly cleared) and southern municipalities should show null effects
- Dynamic RD: more years since threshold crossing → more deforestation

## Primary Specifications

**Cross-sectional RD (main):**
```
Deforestation_{m,t} = α + β·FPM_coefficient_m + f(X_m) + γ_t + ε_{mt}
```
where f(X_m) is a local polynomial in the normalized running variable, estimated within MSE-optimal bandwidth.

**Stacked multi-cutoff:**
```
Deforestation_{m,t} = Σ_k [β_k · D(above cutoff k) · φ(X_{mk})] + FE + ε
```
Pool all 17 cutoffs with separate polynomials; FPM coefficient as endogenous variable, above-threshold indicator as IV (fuzzy RD if some municipalities remain in lower bracket).

**Panel 2SLS:**
```
Deforestation_{m,t} = α + β·FPM_transfer_{mt} + μ_m + γ_t + ε
```
Instrument: discrete jumps at population thresholds × census years.

## Data Sources

1. **MapBiomas:** Annual land cover and land use change (LULC) for all Brazilian municipalities, 1985–2023. Free API via Google Earth Engine OR direct CSV downloads from mapbiomas.org. URL: https://mapbiomas.org/en/statistics
2. **IBGE:** Municipal population from 2000, 2010, 2022 censuses (for running variable). Also municipal GDP, area.
3. **STN (Finbra):** Annual FPM transfers by municipality (SICONFI/Finbra database) — actual transfer received each year.
4. **INPE PRODES:** Annual deforestation alerts, Amazon biome, municipality-level.
5. **IBGE Malha:** Municipality polygons for merging.

## Exposure Alignment Discussion

The FPM transfer system creates differential fiscal capacity across municipalities through sharp population-based thresholds. Treatment intensity (FPM coefficient increment) is a deterministic function of population crossing a threshold, not a choice variable. Municipalities do not apply for FPM transfers; all eligible municipalities receive them automatically based on their census population count. This ensures no selection into treatment: municipalities near the threshold cannot self-select into higher or lower FPM brackets, and the assignment is based on historical census figures that predate the deforestation outcomes.

The main identification threat is if population sorting at thresholds correlates with deforestation trends. Municipalities near thresholds from above and below are similar in observable characteristics (area, biome, pre-period deforestation), and McCrary density tests assess whether manipulation is present. We compare municipalities within MSE-optimal bandwidths around each of the 17 thresholds, where treated (above) and control (below) units face identical policy environments except for the FPM coefficient step.
