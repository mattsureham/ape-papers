# Research Plan: Breaking the Gauge Barrier

## Research Question

Does the elimination of gauge breaks—transshipment points where goods must be unloaded and reloaded between incompatible rail gauges—cause measurable local economic development? India's Project Unigauge (1992–present) converted 25,000+ km of meter gauge to broad gauge in staggered waves, creating district-level connectivity shocks that reduce a specific transport friction while holding the rail network fixed.

## Identification Strategy

**Staggered difference-in-differences** at the district level.

- **Treatment:** A district's meter-gauge rail segment is converted to broad gauge, eliminating the transshipment requirement and enabling through-running of freight and passenger trains.
- **Treatment timing:** Staggered 1992–2020, driven by Indian Railways' zone-level priority classification and engineering constraints (terrain, bridge capacity, electrification sequencing).
- **Control group:** Districts with (a) not-yet-converted meter-gauge lines and (b) always-broad-gauge districts (never treated).
- **Estimator:** Callaway & Sant'Anna (2021) for heterogeneous treatment effects across cohorts. Sun & Abraham (2021) as robustness.

**Key identifying assumption:** Conditional on district and year fixed effects, the timing of gauge conversion within a zone is orthogonal to district-level economic trends. Indian Railways' conversion priority was determined by engineering feasibility (terrain, bridge age, traffic density on the *national* network) rather than local economic conditions.

## Expected Effects and Mechanisms

1. **Primary:** Gauge conversion reduces transport costs by eliminating transshipment delays (estimated 12–24 hours per break) and cargo damage, lowering effective freight rates.
2. **Nightlights response:** Positive—increased commercial activity, manufacturing, and urban agglomeration around converted corridors.
3. **Mechanism:** Cost reduction channel (not new market access—the rail line already existed). Analogous to containerization's elimination of break-bulk handling.
4. **Heterogeneity:** Stronger effects in districts with (a) higher baseline trade dependence, (b) manufacturing vs. agricultural specialization, (c) proximity to gauge break (transshipment) points.

## Primary Specification

```
Y_{dt} = α_d + γ_t + β × GaugeConverted_{dt} + ε_{dt}
```

Where:
- Y_{dt} = log(nightlight luminosity + 1) for district d in year t
- α_d = district fixed effects
- γ_t = year fixed effects
- GaugeConverted_{dt} = 1 if district d's meter-gauge segment was converted by year t
- Clustering: state level (28 states)

## Data Sources

1. **Outcome:** SHRUG nightlights (DMSP 1992–2013) at district level — `data/india_shrug/dmsp_pc11dist.tab` (on disk)
2. **Treatment:** Constructed from:
   - datameet/railways GeoJSON (8,990 stations with coordinates) — GitHub CC0
   - Indian Railways gauge conversion completion records (zone-level annual route-km by gauge type from Railway Board Annual Statistical Statements)
   - Spatial join: assign stations to Census 2011 districts via SHRUG crosswalk
3. **Controls:** SHRUG Census 2001/2011 district characteristics (population, literacy, urbanization)
4. **Economic Census:** SHRUG EC 2005 and 2013 for firm-level outcomes (pre/post cross-sections)

## Key Risks

1. **Gauge conversion timing granularity:** Zone-level completion data may not resolve to individual district-year. Mitigation: use the spatial footprint of meter-gauge lines + zone-level conversion progress to construct probabilistic treatment.
2. **Endogenous timing:** If Indian Railways prioritized conversion in economically promising districts. Mitigation: control for pre-treatment characteristics; event-study design to verify parallel pre-trends.
3. **Concurrent programs:** PMGSY roads, Golden Quadrilateral highway upgrades. Mitigation: control for PMGSY treatment status; geographic specificity (rail corridors, not general road access).
