# Research Plan: The Hydrological Ridgeline

## Research Question

Does CWA Section 303(d) impaired-waters listing cause facilities to reduce pollutant discharges? We exploit the fact that watershed divides — topographic ridgelines determined by bedrock geology — create sharp discontinuities in regulatory stringency when one HUC-12 watershed is listed as impaired and the adjacent one is not.

## Identification Strategy

**Boundary DiD.** Facilities near HUC-12 watershed boundaries experience quasi-random assignment to impaired vs. non-impaired regulatory regimes. The physical ridgeline determines which watershed a facility's discharge enters, which in turn determines whether the facility faces TMDL wasteload allocations.

- **Spatial component:** Distance to HUC-12 boundary as running variable; restrict sample to facilities within 5km of a boundary where one side is impaired and the other is not.
- **Temporal component:** Staggered biennial 303(d) listing cycles create cohort-level treatment timing variation (states submit lists every 2 years).
- **Treatment:** HUC-12 listed as impaired under CWA 303(d).
- **Estimator:** Callaway-Sant'Anna for staggered adoption with never-treated comparison group.

## Expected Effects

Listing should tighten permit limits and increase enforcement attention, reducing facility discharges. But if the CWA listing mechanism is toothless (as critics argue — 50%+ of waterways still impaired), we may find a precise null. Either result is informative.

## Primary Specification

ATT by cohort-time, where cohort = biennial listing cycle when HUC-12 first listed, outcome = facility-level discharge quantity (DMR reported values) or compliance rate. Cluster SEs at HUC-8 level (regulatory unit).

## Data Sources

1. **EPA ECHO API** — Facility locations (lat/lon, HUC codes), NPDES permits, Discharge Monitoring Reports (DMR), compliance history
2. **EPA ATTAINS API** — 303(d) impairment listings by HUC-12, listing cycle dates, pollutant-specific impairment
3. **USGS WBD** — Watershed boundary geometry for distance calculations

## Scope for V1

Focus on a specific, high-stakes pollutant: **Total Nitrogen** or **Total Phosphorus** (nutrients are the #1 cause of impairment nationally). Use major NPDES permits (>1 MGD) for consistent DMR reporting. National sample, 2006-2022.
