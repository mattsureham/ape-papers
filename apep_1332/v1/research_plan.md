# Research Plan: Does Cleaning the List Clean the Water?

## Research Question

Do Total Maximum Daily Load (TMDL) establishments under Section 303(d) of the Clean Water Act actually improve physical water quality in impaired U.S. waterbody segments?

## Motivation

TMDLs are the cornerstone regulatory tool of the Clean Water Act — over 80,000 have been established, costing billions in implementation. Yet there is no rigorous causal evidence on whether they improve the physical water quality parameters they target. Keiser & Shapiro (2019, QJE) studied CWA effects through housing prices and willingness-to-pay; environmental science literature provides descriptive before/after comparisons for individual waterbodies. This paper fills the gap: modern staggered DiD on direct physical water quality measurements.

## Identification Strategy

**Design:** Staggered difference-in-differences using Callaway & Sant'Anna (2021).

**Treatment:** TMDL establishment (EPA approval date) for a specific waterbody segment and pollutant parameter. Sourced from EPA ATTAINS database via rATTAINS R package.

**Unit of observation:** Monitoring station × quarter.

**Outcome:** Dissolved oxygen (mg/L), fecal coliform (CFU/100mL), total phosphorus (mg/L) from EPA Water Quality Portal.

**Control group:** Not-yet-treated stations in segments that eventually receive a TMDL for the same pollutant but at a later date.

**Exogeneity argument:** Conditional on being listed as impaired, TMDL timing is driven by:
1. Consent-decree deadlines (judicial schedules, not water quality trends)
2. Biennial 303(d) listing cycles (administrative timing)
3. State agency capacity variation (orthogonal to local water conditions)

**Key placebo:** Pollutants NOT covered by the segment's TMDL measured at the same station. If TMDLs work through targeted loading reductions, non-targeted pollutants should show null effects.

## Expected Effects

- Dissolved oxygen: positive (increase toward standards, typically 5+ mg/L)
- Fecal coliform: negative (decrease toward standards)
- Total phosphorus: negative (decrease)
- Effects likely emerge 2-5 years post-TMDL (implementation lag)
- Placebo pollutants: null

## Primary Specification

```
Y_{it} = α_i + γ_t + ATT(g,t) + ε_{it}
```

Where ATT(g,t) is the group-time average treatment effect from CS (2021), with groups defined by TMDL approval year-quarter. Clustering at the HUC-8 watershed level.

## Data Sources

1. **ATTAINS** (Assessment, TMDL Tracking and Implementation System): TMDL approval dates, pollutant parameters, waterbody segment IDs. Via rATTAINS R package (CRAN).

2. **Water Quality Portal** (WQP): Physical monitoring data from >240,000 stations. Dissolved oxygen, fecal coliform, total phosphorus. Via dataRetrieval R package (CRAN).

3. **Matching:** Stations matched to TMDL segments via HUC-8 codes and geographic coordinates.

## Fetch Strategy

1. Download ATTAINS TMDL actions for all states with >200 TMDLs
2. Query WQP for DO, fecal coliform, phosphorus readings at stations in those HUC-8 watersheds
3. Focus on 3-5 states with dense monitoring networks and consent-decree timing: CA, OH, VA, FL, PA
4. Time window: 2000-2023

## Robustness

1. Event-study plots (dynamic treatment effects)
2. Pollutant placebo (non-targeted pollutants at same stations)
3. Dose-response (TMDLs with larger required reductions → larger effects)
4. Alternative clustering (station, HUC-12, state)
5. Bacon decomposition to assess TWFE bias
6. Pre-trend tests

## Risk Assessment

- **Main risk:** Implementation lag — TMDLs set limits but don't directly enforce. Effects may take years to materialize.
- **Mitigation:** Extended post-treatment window; dose-response by implementation effort.
- **Data risk:** WQP monitoring density varies by state.
- **Mitigation:** Focus on states with dense networks; weight by monitoring frequency.
