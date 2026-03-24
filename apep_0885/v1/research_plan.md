# Research Plan: Through the Mountain — The Gotthard Base Tunnel and Regional Economic Integration

## Research Question
Does major transport infrastructure that connects a linguistically and geographically isolated region to the national economic core generate real economic investment? We exploit the December 2016 opening of the Gotthard Base Tunnel — the world's longest railway tunnel (57km) — which cut Zurich–Lugano rail travel time from ~2h40 to <2h, to estimate causal effects on construction activity in Ticino municipalities.

## Identification Strategy
**Difference-in-Differences with continuous treatment intensity.**

- **Treatment**: The Gotthard Base Tunnel opening (December 11, 2016) reduced north–south travel times differentially across municipalities. Ticino municipalities (southern terminus) experienced the largest accessibility gains.
- **Treatment intensity**: We measure treatment as a binary indicator (Ticino canton) and as continuous distance-to-corridor (inverse distance to nearest NEAT station).
- **Control group**: Alpine municipalities in Graubünden, Valais, Uri, and Bern Oberland — similar tourism-dependent alpine economies without NEAT connection improvements.
- **Pre-treatment period**: 1994–2015 (22 years) for construction data.
- **Post-treatment period**: 2017–2023 (7 years).

## Expected Effects and Mechanisms
1. **Construction investment**: Improved connectivity raises land values and attracts residential/commercial development → increased construction expenditure in Ticino.
2. **Composition shift**: New construction tilts toward residential (commuter housing for those working in Zurich but living in Ticino) and commercial (firms accessing larger labor markets).
3. **Heterogeneity by prior isolation**: Municipalities that were most isolated before the tunnel benefit most (nonlinear returns to connectivity).

## Primary Specification
```
Y_{mt} = α_m + γ_t + β × (Ticino_m × Post2016_t) + X_{mt}δ + ε_{mt}
```
where Y is construction expenditure per capita, α_m are municipality FEs, γ_t are year FEs, and Ticino × Post2016 is the DiD interaction. Cluster SEs at canton level.

Event study variant with leads/lags for pre-trend validation.

## Robustness
- Callaway & Sant'Anna (if exploiting staggered Gotthard 2016 + Ceneri 2020)
- Synthetic control for Ticino canton aggregate
- Placebo treatment dates (2010, 2012, 2014)
- Exclude COVID period (2020–2021)
- Italian border municipalities as falsification (affected by other Italy-specific shocks)
- Leave-one-out dropping largest Ticino municipalities

## Data Sources
1. **BFS Construction Statistics**: Municipal construction expenditure by type (residential, commercial, infrastructure), 1994–2023, ~2,197 municipalities. Via BFS PXWeb API.
2. **BFS HESTA Tourism**: Monthly hotel overnight stays by municipality (2013–2026) and canton (2005–2026). Via BFS PXWeb API. Secondary outcome for mechanism.
3. **BFS Population**: Municipal population for per-capita normalization. Via BFS PXWeb API.
4. **SBB Passenger Data**: Station-level passenger frequencies (validation of first stage).

## Fetch Strategy
1. Query BFS PXWeb for construction expenditure by municipality (all years, all types)
2. Query BFS PXWeb for HESTA tourism by canton (2005–2025)
3. Query BFS PXWeb for population by municipality
4. Construct treatment intensity variable using geographic data (Ticino indicator + distance)
5. Merge and construct panel
