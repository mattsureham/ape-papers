# Research Plan: Obsolete by Design

## Research Question

Do dams designed using outdated precipitation estimates (TP-40, 1961) generate excess downstream flood damage as climate shifts increase flood magnitudes beyond their engineered spillway capacity?

## Key Insight

Dam spillway capacity is a physical constant determined at construction by the hydrological standards of that era. When NOAA revises precipitation frequency estimates upward (TP-40 → Atlas 14), the infrastructure doesn't change — creating a measurable "design gap" between what the dam was built to handle and what it now faces. This gap varies geographically because precipitation changes are spatially heterogeneous.

## Identification Strategy

**Reduced-form design:** County-level panel regression of flood outcomes on the design gap ratio, with county and year fixed effects.

**Design gap construction:**
1. For each dam in the NID built before 1980, extract location (lat/lon)
2. Query TP-40 raster at dam location for 100-year 24-hour precipitation depth (what the dam was designed for)
3. Query NOAA Atlas 14 API for the same statistic at the same location (current best estimate)
4. Design gap ratio = Atlas14 / TP40 (values >1 indicate the dam is under-designed)
5. Aggregate to county level: mean design gap across all pre-1980 dams weighted by dam storage capacity

**Key specification:**
```
FloodDamage_ct = β × DesignGap_c × Post2004_t + County_FE + Year_FE + Controls_ct + ε_ct
```

where Post2004 marks when Atlas 14 began documenting the gap (though the physical gap existed earlier). Alternative: use continuous time interaction with design gap.

**Primary specification (cross-sectional):**
```
FloodDamage_ct = β × DesignGap_c + Year_FE + StateRegion_FE + Controls_ct + ε_ct
```

Controls: total precipitation, number of dams, dam age, dam storage capacity, population, impervious surface area.

## Expected Effects

Counties with higher design gap ratios (where precipitation has increased most relative to TP-40 baselines) should experience:
- More FEMA flood disaster declarations per decade
- Higher NFIP claims volume and payouts
- Larger NFIP claims per event (dam failure/overtopping = catastrophic)

## Mechanism

The design gap operates through two channels:
1. **Spillway inadequacy:** When inflow exceeds spillway capacity, water overtops the dam → catastrophic failure risk
2. **False security:** Communities downstream of dams develop in the "shadow" of perceived flood protection that has degraded

## Placebos and Robustness

1. **Counties without pre-1980 dams:** Design gap should have no effect (no infrastructure to be inadequate)
2. **Recently built dams (post-2000):** Designed with modern precipitation data, should show weaker/no design gap effect
3. **Low-hazard dams:** Failures cause minimal downstream damage; effect should be concentrated in high-hazard dams
4. **Non-flood disasters:** Design gap should not predict tornado, earthquake, or wildfire damage

## Data Sources

| Source | What | Access |
|--------|------|--------|
| NID CSV | 92,625 dams with year built, coordinates, storage, hazard class | fhwa.dot.gov bulk download |
| TP-40 GeoTIFF | 1961-era 100-year 24-hour precipitation depths | CMU Figshare |
| NOAA Atlas 14 | Current precipitation frequency estimates by location | API (free) |
| OpenFEMA NFIP Claims | 2.5M+ property-level flood insurance claims | API (free) |
| OpenFEMA Declarations | Disaster declarations by county and type | API (free) |
| FEMA Housing Assistance | Zip-level damage by disaster | API (free) |

## Treatment Exposure Alignment

The treatment variable (pre-1970 dam share) is time-invariant at the state level and measures the fraction of a state's dam stock built before the TP-40 precipitation standard era. The outcome (FEMA flood declarations) is measured at the state-year level. The treatment directly affects downstream communities in the state through the physical channel of spillway capacity constraints. All states with dams are exposed; treatment intensity varies continuously (0.30 to 0.96). The design is cross-sectional with year fixed effects, not a staggered DiD — there is no temporal treatment assignment.

## Risk Assessment

- **Main risk:** Design gap correlates with general precipitation increases that cause flooding independent of dam infrastructure. **Mitigation:** Compare counties with vs without pre-1980 dams; control for actual precipitation; use dam-specific engineering parameters.
- **Data risk:** TP-40 raster resolution may be coarse. **Mitigation:** Confirmed on CMU Figshare; will validate with known values.
- **Sample risk:** Need sufficient high-hazard pre-1980 dams. **Mitigation:** Smoke test shows 6,182 dams with complete data.
