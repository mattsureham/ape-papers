# Research Plan: Running Out of Shoulder — Smart Motorway Conversions and Road Safety

## Research Question

Do smart motorway conversions (removing the hard shoulder to create additional running lanes) increase road casualties? England converted ~30 motorway sections between 2006 and 2023, providing staggered treatment timing for a causal DiD design.

## Identification Strategy

**Staggered difference-in-differences** at the motorway-section × quarter level.

- **Treatment:** Quarter in which a specific motorway section opens as a smart motorway (All Lane Running or Dynamic Hard Shoulder Running)
- **Control group:** Conventional motorway sections that were never converted to smart configuration during the study period
- **Estimator:** Callaway-Sant'Anna (2021) for heterogeneity-robust group-time ATTs, with Sun-Abraham as robustness
- **Clustering:** At the motorway-section level (unit of treatment assignment)
- **Pre-periods:** 5+ years for most sections; longest pre-period is 2000-2014

## Expected Effects and Mechanisms

**Direction:** Ambiguous ex ante — this is what makes the question interesting.

- **Safety reduction channel:** Removing hard shoulder eliminates refuge for breakdowns → vehicles stranded in live lanes → higher collision risk, especially rear-end collisions at high speed
- **Safety improvement channel:** More lanes reduce congestion → fewer speed-differential collisions; variable speed limits + CCTV monitoring → smoother flow
- **Net effect:** Unknown — the government claimed smart motorways were safer; media campaigns and coroner reports suggested they were deadly. No causal evidence exists.

## Primary Specification

Y_{it} = α_i + δ_t + β × Smart_{it} + ε_{it}

Where:
- i = motorway section (~60 total: ~30 treated, ~30 control)
- t = quarter (2000Q1 to 2023Q4)
- Y = collision count per billion vehicle-miles (rate) or raw collision count
- Smart_{it} = 1 if section i has been converted to smart motorway by quarter t

## Data Sources

1. **STATS19** (DfT Road Casualty Statistics): Geocoded collision records, 1979-2024, with severity, road number, coordinates. R package `stats19` for download.

2. **Smart motorway section list:** National Highways publications documenting which sections were converted and when. ~30 sections with conversion dates from government reports and parliamentary publications.

3. **Traffic flow data:** DfT Road Traffic Statistics (TRA series) for vehicle-miles by road, enabling rate-based outcomes.

## Mechanism Tests

1. **Severity decomposition:** Fatal vs. serious vs. slight casualties
2. **Collision type:** Rear-end (most likely mechanism) vs. other types
3. **Time of day:** Peak vs. off-peak (congestion channel)
4. **Section type:** All Lane Running (no hard shoulder ever) vs. Dynamic Hard Shoulder (shoulder opens during peak) — ALR should show larger effects

## Robustness

- HonestDiD/Rambachan-Roth sensitivity for parallel trends violations
- Donut-hole excluding conversion year (construction disruption)
- Wild cluster bootstrap (30 sections = small cluster count)
- Placebo: A-roads near smart motorway sections (should not be affected)
