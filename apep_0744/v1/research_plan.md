# Research Plan: The Speed Penalty — Wales's Default 20mph and Road Safety

## Research Question

Does reducing the default urban speed limit from 30mph to 20mph reduce road traffic collisions? Wales's blanket September 2023 reclassification provides a country-level natural experiment with England as control.

## Identification Strategy

**Design:** Difference-in-Differences (panel DiD) with Local Authority (LA) × quarter panel.

- **Treatment:** 22 Welsh LAs, all treated simultaneously on 17 September 2023
- **Control:** English LAs (focus on border LAs for tightest comparison; all English LAs for power)
- **Pre-period:** 2020Q1–2023Q3 (15 quarters)
- **Post-period:** 2023Q4–2024Q4 (5 quarters)
- **Key advantage:** Single sharp treatment date — no staggering, so standard TWFE is appropriate

**Specification:**
```
Y_{lt} = α_l + γ_t + β × Welsh_l × Post_t + X_{lt}'δ + ε_{lt}
```
- Y = collision count (or log rate per road km)
- α_l = LA fixed effects
- γ_t = quarter fixed effects
- Welsh_l × Post_t = treatment indicator
- Cluster SEs at LA level; wild cluster bootstrap given ~22 treated clusters

**Built-in placebo:** Collisions on >40mph roads (unaffected by the reform). If β on these roads is null, it supports the parallel trends assumption.

**Exposure alignment:** The treatment (default speed limit change from 30→20mph) directly affects drivers on restricted roads in Wales. Exposure is geographically determined: all restricted roads in Welsh LAs are treated; no restricted roads in English LAs are treated. The policy does not affect motorways, dual carriageways, or rural roads with limits above 40mph — these serve as the placebo group. Individual drivers cannot select into or out of treatment (the speed limit applies to the road, not the driver), minimizing selection concerns. Cross-border commuters experience the treatment when driving in Wales regardless of residence, though this affects a small share of total miles driven.

## Expected Effects and Mechanisms

1. **Speed reduction → fewer collisions and lower severity** (physics of impact force)
2. **Possible offsetting:** driver frustration, route diversion to faster roads
3. **Heterogeneity:** pedestrian/cyclist casualties should show larger effects than vehicle-only

## Primary Specification

TWFE with LA and quarter FEs, clustering at LA level. Robustness via:
- Wild cluster bootstrap (fwildclusterboot)
- Placebo outcome (>40mph road collisions)
- Border-county subsample (tightest comparison)
- Event study (quarter-by-quarter pre-trends and dynamic effects)

## Data Source and Fetch Strategy

**Primary:** DfT STATS19 collision data (2020-2024)
- Geocoded collision records with speed limit zone, severity, road type, LA
- Download via `stats19` R package or direct DfT CSV
- ~150,000+ collisions per year across England and Wales

**Construction:**
1. Download all collision records 2020-2024
2. Classify each collision by speed limit zone (20mph, 30mph, >40mph)
3. Aggregate to LA × quarter × speed-limit-category panel
4. Identify Welsh vs English LAs
5. Create treatment indicator (Welsh × post-Sep-2023)
