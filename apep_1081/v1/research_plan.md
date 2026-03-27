# Research Plan: Paving Over Pollution

## Research Question
Do coal-tar-based pavement sealant bans reduce polycyclic aromatic hydrocarbon (PAH) contamination in urban waterways? Using the staggered adoption of bans across 40+ US jurisdictions (2006–2025), we estimate the causal effect on measured PAH concentrations in stream water and bed sediment.

## Identification Strategy
**Staggered Difference-in-Differences.** Treatment: jurisdiction adopts a coal-tar sealant ban. Outcome: PAH concentrations (fluoranthene, pyrene, benzo[a]pyrene) measured at USGS/EPA monitoring stations via the Water Quality Portal. Control group: stations in jurisdictions that have not yet banned coal-tar sealants (not-yet-treated).

**Estimator:** Callaway and Sant'Anna (2021) group-time ATT, with never-treated and not-yet-treated as control groups. Event study specification for dynamic effects.

**Key controls:** Precipitation, season, streamflow (where available), station fixed effects, year fixed effects.

**Placebo tests:**
1. Non-sealant contaminants (heavy metals: lead, zinc, copper; pesticides: atrazine) should NOT respond to sealant bans
2. Rural/non-urban stations within treated jurisdictions should show weaker effects (sealants are applied to parking lots, driveways — urban surfaces)
3. Pre-treatment event study leads should be zero

## Expected Effects and Mechanisms
Coal-tar sealants contain 50,000–100,000 mg/kg PAHs. When applied to parking lots and driveways, PAHs leach into stormwater runoff and enter nearby waterways. Banning the product removes the renewal source. We expect:
- **Negative effect** on PAH concentrations (ban → less contamination)
- **Gradual decline** rather than immediate drop (existing sealant degrades over 2-5 years)
- **Stronger effects** in urban areas with high impervious surface coverage
- **No effect** on non-sealant contaminants (metals, pesticides)

The USGS Austin case study found a 58% decline in PAH concentrations after the 2006 ban, but used simple before-after comparison. We provide the first multi-jurisdiction causal estimate.

## Primary Specification
$$Y_{ist} = \alpha_i + \gamma_t + \sum_k \beta_k \cdot \mathbb{1}[t - G_i = k] + X_{ist}'\delta + \varepsilon_{ist}$$

Where $Y_{ist}$ is log PAH concentration at station $i$ in jurisdiction $s$ at time $t$, $G_i$ is the year of sealant ban adoption, $\alpha_i$ are station FE, $\gamma_t$ are year FE, and $X_{ist}$ are controls.

Clustering: at the jurisdiction level (40+ clusters).

## Exposure Alignment
Treatment (coal-tar sealant ban) is assigned at the state/district level. The directly affected units are urban monitoring stations in watersheds with significant impervious surface coverage (parking lots, driveways). Rural stations within treated jurisdictions are not directly exposed to the sealant mechanism because coal-tar sealants are primarily applied to commercial/residential paved surfaces in urban areas. This creates treatment dilution: the state-level assignment includes unexposed stations. The outcome (fluoranthene concentration) is measured at the monitoring station level, which is the correct geographic unit for detecting waterway contamination changes. The key exposure alignment concern is that not all stations within treated states are equally exposed to the sealant pathway.

## Data Sources
1. **Water Quality Portal** (waterqualitydata.us): PAH measurements from USGS/EPA monitoring stations. Characteristic names: Fluoranthene, Pyrene, Benzo(a)pyrene, PAH total. ~30,000+ records across all states.
2. **Ban adoption dates:** Legislative research — Austin TX (2006), Washington DC (~2009), Suffolk County NY (2011), Washington State (2011), Minnesota (2014), New York State (2022-2023), Maryland (2023), Maine (2024), Virginia (2024-2025), Cook County IL (2024).
3. **Station metadata:** WQP provides lat/lon, HUC codes, monitoring organization.
4. **Controls:** NOAA precipitation data (optional enhancement).

## Fetch Strategy
1. Query WQP API for all fluoranthene measurements in US states, 2000-2025
2. Query WQP for pyrene and benzo(a)pyrene as secondary outcomes
3. Query WQP for placebo contaminants (lead, zinc, atrazine)
4. Merge with ban adoption dates
5. Calculate distance from each station to nearest banned jurisdiction boundary
