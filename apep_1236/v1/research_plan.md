# Research Plan: The Contamination Freeze — PFAS Soil Standards and Dutch Housing Supply

## Research Question

Did the Netherlands' July 2019 PFAS soil movement freeze — which set contamination thresholds so stringently that virtually all soil became immovable — reduce municipal housing completions, and did the November 2019 partial relaxation restore supply? Does proximity to the Chemours factory (the primary PFAS point source near Dordrecht) predict stronger housing supply effects?

## Identification Strategy

**Primary design: DiD with continuous treatment intensity.**

The July 2019 PFAS freeze was a national regulatory shock, but its bite varied spatially: municipalities closer to the Chemours factory in Dordrecht had higher soil PFAS contamination, making the freeze more binding. I exploit this spatial variation using two approaches:

1. **Binary DiD:** Compare high-PFAS municipalities (Rhine-Maas delta, within ~50 km of Chemours) to low-PFAS municipalities (eastern/northern Netherlands). Treatment: July 2019 freeze. Pre-period: Jan 2015 – Jun 2019 (54 months). Post-period: Jul 2019 – Dec 2023.

2. **Dose-response DiD:** Use inverse distance to Chemours Dordrecht factory as continuous treatment intensity. Municipalities closer to the factory have higher PFAS contamination and should show larger housing supply reductions.

**Two-discontinuity design:** The freeze (July 2019) and partial relaxation (November 2019) create two sharp policy breaks, allowing asymmetry tests — did supply recover fully after relaxation, or did regulatory uncertainty cause persistent damage?

**Why credible:**
- The PFAS threshold was set by RIVM (national environmental agency) for environmental reasons unrelated to local housing markets
- Spatial variation in PFAS contamination is geologically determined (Chemours factory location, river systems)
- 54 months of pre-treatment data for parallel trends testing
- Within-country design eliminates macro confounders

**Threats and responses:**
1. Concurrent nitrogen crisis (PAS ruling, May 2019) — controls for nitrogen-designated areas; triple-diff if needed
2. COVID (March 2020) — event study shows effects emerge July 2019, pre-COVID; restrict sample to pre-COVID as robustness
3. Pre-existing housing trends — event study with Rambachan-Roth sensitivity bounds

## Expected Effects and Mechanisms

**Primary hypothesis:** The PFAS freeze reduced housing completions in high-contamination municipalities relative to low-contamination ones.

**Mechanism:** Construction projects require soil movement (excavation, foundation work). When PFAS standards made virtually all soil immovable, projects in contaminated areas could not proceed. This is a *regulatory supply constraint*, not a demand shock.

**Expected magnitudes:**
- Dordrecht completions dropped ~38% (156 → 97) from 2018 to 2019
- National housing shortage worsened during freeze period
- Partial recovery expected after November 2019 relaxation, but regulatory uncertainty may create a persistent "contamination chill"

## Primary Specification

Y_{mt} = α_m + γ_t + β₁(HighPFAS_m × Freeze_t) + β₂(HighPFAS_m × PostRelax_t) + X_{mt}'δ + ε_{mt}

Where:
- Y_{mt} = housing completions in municipality m, month t
- HighPFAS_m = indicator for municipality in high-contamination zone (or continuous distance measure)
- Freeze_t = indicator for July–November 2019
- PostRelax_t = indicator for December 2019 onward
- X_{mt} = controls (population, municipality area)
- Clustering: municipality level

**Estimator:** `fixest::feols()` with municipality and year-month fixed effects. Event study specification for pre-trends.

## Data Sources

1. **CBS Statline OData API** (table 81955NED): Housing completions by municipality, monthly/annual. 441 municipalities. Confirmed accessible.
2. **CBS municipality boundaries** for geographic distance calculations.
3. **Chemours factory location:** Dordrecht (51.7833°N, 4.6833°E) — the primary PFAS point source.
4. **CBS population data** for controls.

## Fetch Strategy

1. Query CBS OData API for table 81955NED (housing completions, all municipalities, 2015–2023)
2. Compute inverse distance from each municipality centroid to Chemours Dordrecht
3. Classify municipalities into high/low PFAS exposure groups
4. Merge with population controls from CBS

All data is freely available via CBS OData API — no API keys required.
