# Research Plan: The Compensation Paradox — Quiet Zones and Railroad Crossing Safety

## Research Question

When communities silence train horns by establishing quiet zones, do crossing accidents rise (because the auditory warning disappears) or fall (because quiet zone designation requires compensating safety infrastructure)? This tests the fundamental question of whether mandated physical safety investments can offset the removal of a behavioral warning signal.

## Identification Strategy

**Staggered difference-in-differences at the crossing level.** Treatment: quiet zone establishment (exact date from FRA `whistledate` field). Controls: never-treated crossings. Modern estimators: Callaway-Sant'Anna (2021) for heterogeneity-robust ATT.

**Key strengths:**
- 5,041 treated crossings with exact establishment dates (2005-2015)
- ~430,000 never-treated control crossings
- 20 years of pre-treatment accident data (1986-2005) for event study validation
- Crossing-level panel eliminates all time-invariant crossing confounders

**Primary threat:** Selection into quiet zones is not random — wealthier or more politically connected communities may adopt earlier. Address via:
1. Pre-trend validation (20 years of pre-data)
2. Matching on observable crossing characteristics (traffic, speed, tracks, urbanicity, existing safety devices)
3. Within-state variation (state fixed effects)
4. Leave-one-out robustness (dropping largest adopting states: TX, WI, IL)

## Expected Effects and Mechanisms

**Theoretical ambiguity:** Two offsetting forces:
1. **Warning removal effect** (+accidents): Horns alert drivers/pedestrians at crossings
2. **Compensation effect** (-accidents): Quiet zone designation requires supplementary safety measures (four-quadrant gates, raised medians, channelization devices)

**Prior:** The compensation effect likely dominates — FRA requires safety equivalence before granting quiet zone status. Expect null or small negative effect on accidents. This is a valuable finding either way: if null, it validates the FRA's compensating-safety framework; if positive, it reveals a hidden cost of noise abatement policy.

## Primary Specification

```
Accident_ct = α_i + γ_t + β × QuietZone_it + X_it'δ + ε_it
```

Where:
- `i` = crossing, `t` = year
- `QuietZone_it` = 1 if crossing is in a quiet zone in year t
- `α_i` = crossing fixed effects
- `γ_t` = year fixed effects
- `X_it` = time-varying controls (traffic volume, train counts)
- Clustering: corridor/county level

**Estimator:** Callaway-Sant'Anna (2021) for group-time ATTs, aggregated to event-time for event study plot.

## Data Sources and Fetch Strategy

1. **FRA Highway-Rail Crossing Inventory** (Form 71): 438,521 crossings with quiet zone status, establishment dates, geographic coordinates, and 147 fields of crossing characteristics. API: `https://data.transportation.gov/resource/hbg3-nmfg.json` (Socrata)

2. **FRA Accident/Incident Data** (Form 57): 250,290 crossing-level accident records (1986-2025). API: `https://data.transportation.gov/resource/85tf-25kj.json` (Socrata)

**Fetch strategy:**
- Paginate through Socrata API (50K record limit per request)
- Merge accident data to crossing inventory via crossing ID
- Construct annual crossing-level panel: count accidents per crossing-year
- Most crossing-years will have zero accidents (rare events)

## Robustness Checks

1. Poisson/negative binomial for count outcomes
2. Binary outcome: any accident in year t (logit/LPM)
3. Leave-one-out dropping largest adopting states
4. Matched sample (coarsened exact matching on traffic, speed, urbanicity)
5. Placebo: pre-2005 event study for never-eventually-treated
6. Heterogeneity by pre-existing safety infrastructure (gates vs. crossbucks)
