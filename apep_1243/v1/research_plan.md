# Research Plan: Merging the Village? Municipal Consolidation and Residential Sorting in Switzerland

## Research question

Do Swiss municipal mergers change where people choose to live? I study whether voluntary municipal consolidation affects residential sorting, with a focus on foreign residents, using a harmonized municipality-year panel.

## Why this question

The Swiss merger literature has already documented democratic costs. What remains open is whether consolidation changes the residential attractiveness of local jurisdictions by altering tax competition, service provision, or local identity. If mergers reduce small-jurisdiction differentiation, population composition should adjust through migration rather than only through politics.

## Policy and treatment

- Policy: voluntary municipal mergers (`Gemeindefusionen`) in Switzerland.
- Timing: staggered merger effective dates from the BFS AGVCH/SMMT mutations API.
- Unit of treatment: successor municipality on current boundaries.
- Treated units: municipalities that absorb or are created through a merger during the sample.
- Controls: municipalities that never merge during the sample window.

## Outcomes

Primary outcomes:

- Foreign population share.
- Log foreign population.
- Foreign net migration rate.

Secondary outcomes:

- Swiss net migration rate.
- Total population growth.
- Naturalizations per 1,000 foreign residents.

## Identification strategy

Main design:

- Harmonize all historical communes to successor boundaries using the BFS merger crosswalk.
- Estimate staggered DiD models with municipality and year fixed effects.
- Prefer Sun-Abraham event-study estimates over naive TWFE for dynamic effects.

Primary estimand:

- Average post-merger change in foreign residential sorting outcomes for merged municipalities relative to never-merged municipalities.

Key threat:

- Municipal mergers are voluntary and likely selected on slow-moving local decline or restructuring.

Planned responses:

- Plot long event studies to inspect pre-trends.
- Report both TWFE and Sun-Abraham estimates and calibrate claims to the stronger design.
- Include canton-by-year fixed effects in robustness checks.
- Compare foreign and Swiss migration margins directly to distinguish general demographic drift from foreign-specific sorting.

## Data and fetch strategy

1. BFS AGVCH mutations API:
   - merger dates and dissolved-to-successor crosswalk.
2. BFS commune snapshot API:
   - current municipality metadata and canton mapping.
3. BFS PXWeb demographic balance table `px-x-0102020000_201`:
   - annual municipal counts for population, immigration, emigration, net migration, and naturalizations by citizenship category, 1981-2024.

Fetch approach:

- Query demographic balance year by year to avoid oversized PXWeb requests.
- Pull citizenship categories `total`, `Swiss`, and `foreign`, sex total only.
- Pull demographic components needed for stocks and flows: population on 1 January, immigration, emigration, net migration, acquisition of Swiss citizenship, and population on 31 December.
- Save raw data to `data/` and construct a harmonized current-boundary panel in `02_clean_data.R`.

## Primary specification

For outcome `Y_it`:

`Y_it = beta * PostMerger_it + alpha_i + gamma_t + epsilon_it`

where `alpha_i` are municipality fixed effects and `gamma_t` are year fixed effects.

Dynamic specification:

`Y_it = sum_k beta_k 1[event_time = k] + alpha_i + gamma_t + epsilon_it`

implemented via `fixest::sunab(first_merger_year, year)`.

## Expected effects and mechanisms

- If mergers weaken local identity or reduce tax/service differentiation, foreign in-migration should fall and foreign out-migration should rise relative to controls.
- If mergers improve service delivery and administrative capacity, the opposite could occur.
- A null would still be informative: mergers may matter politically without materially changing residential location choices.

## Method notes

- Standard errors clustered at the municipality level.
- Because treatment is voluntary, any strong pre-trends will trigger a claim downgrade from causal effect to bounded post-merger association with event-study discipline.
- No simulated or filled-in data under any failure mode; if API coverage is insufficient, the idea will be retired or failed rather than patched.
