# Research Plan: Taxing the Green Transition

## Research Question

Does the announcement of a resource rent tax on renewable energy chill investment and production in the taxed sector? Norway's December 2022 surprise announcement of a 40% effective resource rent tax on onshore wind power provides a sharp natural experiment.

## Identification Strategy

**Primary: Sector Difference-in-Differences (Wind vs. Hydropower)**

- **Treatment group:** Onshore wind power (new 40% resource rent tax announced December 2022, enacted January 2024 at 25%)
- **Control group:** Hydropower (existing 47% resource rent tax since 1997, unchanged)
- **Panel:** County × sector × month, 2018–2024
- **Treatment date:** December 16, 2022 (announcement)
- **Key assumption:** Wind and hydropower production follow parallel trends absent the tax shock. Both face the same national electricity market, weather correlations, and demand conditions. The 2022 Russia-Ukraine energy price shock affects both sectors equally → absorbed by time fixed effects.

**Robustness:**
- Event study with leads/lags to test pre-trends
- Callaway-Sant'Anna not needed (single sharp treatment date, not staggered)
- Wild cluster bootstrap for inference with ~15 county clusters
- Placebo: petroleum sector investment (should NOT be affected by wind tax)
- External validation: Sweden/Denmark wind production as placebo countries (no comparable tax shock)

## Expected Effects and Mechanisms

1. **Production stall:** Wind GWh growth should flatten or decline post-announcement (confirmed: +25.7% in 2022, −5.7% in 2023)
2. **Investment freeze:** New project starts should drop sharply post-announcement
3. **Mechanism — regulatory uncertainty:** The gap between announcement (Dec 2022) and final enactment (Jan 2024) creates a 12-month uncertainty window; even the revised 25% rate was unknown until mid-2023
4. **Asymmetric response:** Effect should be concentrated in new/planned projects, not existing operational farms

## Primary Specification

$$Y_{cst} = \alpha + \beta \cdot \text{Wind}_s \times \text{Post}_t + \gamma_{cs} + \delta_t + \varepsilon_{cst}$$

Where:
- $Y_{cst}$: electricity production (GWh) in county $c$, sector $s$ (wind/hydro), month $t$
- $\text{Wind}_s$: indicator for wind sector
- $\text{Post}_t$: indicator for months after December 2022
- $\gamma_{cs}$: county × sector fixed effects
- $\delta_t$: month fixed effects
- Clustering: county level (~15 clusters → wild cluster bootstrap)

## Data Sources

| Source | Table | Content | Format |
|--------|-------|---------|--------|
| SSB (Statistics Norway) | 08308 | Annual electricity by type/county (GWh), 2006–2024 | JSON-stat API |
| SSB | 14091 | Monthly electricity by type (MWh), 1993–2026 | JSON-stat API |
| SSB | 04170 | Petroleum investment (NOK million) | JSON-stat API |
| Eurostat | nrg_cb_pem | Monthly electricity by type, EU/EEA | REST API |

## Fetch Strategy

1. SSB PxWeb API: POST requests with JSON query bodies to `https://data.ssb.no/api/v0/en/table/{TABLE_ID}`
2. Eurostat: REST API for Sweden/Denmark wind production comparison
3. All data publicly available, no credentials needed

## Exposure Alignment

The treatment (wind resource rent tax announcement) directly affects all onshore wind power producers in Norway. The unit of observation (sector × month at the national level) exactly matches the treatment assignment: the entire wind sector is treated simultaneously on December 16, 2022. Hydropower (the control) is unaffected because its existing 47% resource rent tax was unchanged. There is no partial compliance or staggered rollout — this is a sharp, single-date treatment affecting one sector. The outcome (electricity production in GWh) measures the generation activity of the affected population at the same geographic and temporal granularity as the treatment.

## Key Risks

1. **Small cluster count:** ~15 Norwegian counties with wind production → wild cluster bootstrap essential
2. **Energy price confound:** 2022 energy crisis affects all sectors → time FE absorbs, hydro control isolates wind-specific shock
3. **Weather variation:** Wind production is weather-dependent → monthly wind/hydro ratio helps control
4. **Capacity vs. production:** Production changes could reflect wind conditions, not investment → supplement with capacity data if available
