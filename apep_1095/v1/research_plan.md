# Research Plan: The Compliance Illusion — Operator-Led Seismic Response Plans and Induced Earthquake Persistence in the Texas Permian Basin

## Research Question

Do operator-led seismic mitigation plans (Texas SRA designations, 2021-2022) reduce induced seismicity as effectively as government-mandated volume caps (Oklahoma OCC directives)? We test whether the Texas "self-regulatory" approach — where operators propose their own injection volume reduction schedules — achieves meaningful seismicity reduction or merely creates a **compliance illusion** where reported reductions coexist with persistent earthquake activity.

## Identification Strategy

### Primary: Well-Level Dose-Response DiD

The 3-SRA structure limits a simple treated/control DiD. Instead, we exploit **well-level variation in mandated injection volume reductions** (25-88% across hundreds of wells within SRAs) for a dose-response design:

- **Unit:** Grid cell (10km × 10km) × month
- **Treatment intensity:** Distance-weighted injection volume change from SRA-affected wells
- **Outcome:** Count of M2.0+ earthquakes per grid-cell-month (USGS ComCat)
- **Controls:** Grid-cell FE, month FE, baseline seismicity trends
- **Specification:** Poisson/negative binomial with grid-cell and time FE

### Secondary: Spatial Ring Analysis

For displacement effects (do earthquakes migrate outside SRA boundaries?):
- Rings at 0-20km, 20-50km, 50-100km from SRA boundaries
- Tests whether seismicity reduced within SRAs but increased in buffer zones

### Tertiary: Cross-State Comparison (Descriptive)

Texas SRA response vs. Oklahoma OCC mandatory directives. This is necessarily descriptive (different geology, timing, regulatory regimes) but calibrates the magnitude: Oklahoma achieved -97% reduction; Texas achieved -36%.

## Expected Effects and Mechanisms

**Hypothesis:** Operator-led plans achieve smaller seismicity reductions than mandated caps because:
1. **Moral hazard:** Operators set own reduction targets, may choose minimum compliance
2. **Displacement:** Operators redirect injection to wells outside SRA boundaries
3. **Delay:** Self-regulatory timelines are slower than government mandates
4. **Heterogeneity:** Large operators comply more (reputational costs); small operators less

**Expected magnitude:** Moderate negative SDE (injection volume reductions do reduce some seismicity) but well below the counterfactual of mandatory regulation.

## Primary Specification

```
E[Y_it] = exp(α_i + γ_t + β × ΔInjectionVolume_it + X'_it δ)
```

Where:
- Y_it = earthquake count in grid-cell i, month t
- α_i = grid-cell fixed effects
- γ_t = month fixed effects
- ΔInjectionVolume_it = change in distance-weighted injection volume from SRA-affected wells
- X_it = controls (cumulative injection, well count, depth)

Inference: Cluster at SRA-region level; supplement with randomization inference (permuting SRA designation timing) given few clusters.

## Data Sources

1. **USGS ComCat API:** All M2.0+ earthquakes in Permian Basin region (lat 30-33°N, lon 101-105°W), 2017-2024. ~3,000+ events.
2. **Texas RRC Injection Well Data:** Public H-10 filings. Monthly injection volumes by well, location, depth, operator. Available via RRC data query.
3. **Oklahoma OCC Data:** For cross-state comparison. Arbuckle zone injection volumes and earthquake counts.
4. **SRA Boundary Shapefiles:** From RRC orders/documents. Three SRAs with precise geographic boundaries.

## Exposure Alignment

The treatment operates at the SRA geographic level: grid cells within designated SRA boundaries are treated after the enforcement date. The outcome (earthquake counts) is measured at the same grid-cell × month level. Exposure alignment is direct — the policy targets injection wells within SRA boundaries, and earthquakes are spatially proximate to those wells. Potential misalignment: earthquakes can be triggered by injection at distances of 10-20km, so grid cells near SRA boundaries may be partially affected. We address this with ring-zone displacement analysis testing whether seismicity migrates across SRA boundaries.

## Risks and Mitigation

| Risk | Mitigation |
|------|-----------|
| Only 3 SRAs (few clusters) | Well-level dose-response as primary; RI for inference |
| Geological confounds | Grid-cell FE absorb time-invariant geology; month FE absorb common shocks |
| Delayed seismic response | Lag structure (1-6 month lags of injection volume changes) |
| Data availability | USGS API confirmed (smoke test: 774 events in 2022); RRC data public |
