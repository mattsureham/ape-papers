# Research Plan: apep_1085

## Research Question

Does wind energy expansion reduce raptor populations? The US installed 75,727 wind turbines across 701 counties (2000–2023), driven by Production Tax Credits and state Renewable Portfolio Standards. While Katovich (2024 ES&T) found no aggregate bird effect using Christmas Bird Count data, we test for **species-composition effects**: wind turbines may restructure avian communities — reducing collision-vulnerable raptors — without changing total abundance.

## Identification Strategy

**Staggered DiD (Callaway–Sant'Anna 2021).** Treatment: first year a state receives substantial wind capacity (≥100 MW). Continuous dose: log(1 + cumulative MW) by state-year. 36+ treated states with staggered adoption (peak 2005–2015). Control: states that never receive substantial wind capacity.

- **Panel**: 50 US states × 15 years (2009–2023)
- **Treatment timing**: First year state reaches 100 MW cumulative capacity
- **Outcome**: eBird raptor reporting rates from GBIF (Accipitridae), grassland bird rates, total species counts
- **Estimator**: Callaway–Sant'Anna with not-yet-treated controls; event study with leads/lags
- **Clustering**: State level

## Expected Effects

1. **Raptors (Accipitridae)**: Negative effect — collision mortality is species-selective, hitting soaring raptors disproportionately (Smallwood 2013, Loss et al. 2013)
2. **Grassland birds**: Negative effect — habitat displacement from turbine pads and roads
3. **Waterfowl/woodpeckers (placebo)**: Null — not collision-vulnerable, different habitat

## Mechanism Decomposition

- **Direct mortality**: Turbine blades kill ~140,000–500,000 birds/year (Loss et al. 2013). Raptors overrepresented per installed MW.
- **Habitat displacement**: Construction disturbs grassland habitat. Effect should scale with turbine density, not just presence.
- **Dose-response**: States with more MW should show larger effects. Log(MW) captures diminishing marginal impact.

## Data Sources

1. **USGS Wind Turbine Database v8.3** (direct CSV download): 75,727 turbines with FIPS codes, operational year, capacity (kW), hub height, rotor diameter.
2. **GBIF occurrence API** (open, no key): eBird bird observations filtered by taxon and US state. Faceted queries return state-year counts in single API calls.
3. **Target taxa**: Accipitridae (raptors, GBIF key 2480830), Ammodramus savannarum (Grasshopper Sparrow, 2491261), Anatidae (waterfowl, 2498252 — placebo).

## Exposure Alignment

The treatment unit is the state-year. Wind turbines are installed within states, and eBird observations are aggregated to the state-year level. The treatment (cumulative installed MW) directly affects the state's avian environment. The outcome (raptor reporting rate) measures the proportional representation of raptors across all eBird observations within that state-year. The key alignment concern is spatial dilution: turbines are concentrated in specific corridors while eBird observations span the entire state. State fixed effects absorb baseline differences in raptor habitat; year fixed effects absorb nationwide birding trends. The identifying variation comes from within-state changes in wind capacity over time.

## Robustness Checks

1. Placebo species (waterfowl, woodpeckers)
2. Pre-trend event study (≥5 leads)
3. Continuous treatment dose-response (log MW)
4. Drop Texas (dominates wind installations)
5. Alternative treatment threshold (50 MW vs 100 MW vs 200 MW)
6. Wild cluster bootstrap inference
