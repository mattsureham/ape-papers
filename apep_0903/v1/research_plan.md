# Research Plan: Second-Home Construction Ban and Housing Reallocation in Swiss Tourist Municipalities

## Research Question

Did Switzerland's Second Home Initiative — which banned new second-home construction in municipalities exceeding a 20% second-home share — achieve its stated objective of converting housing stock toward permanent residential use? Or did the quantity restriction merely freeze existing composition while distorting construction activity?

## Policy Background

- **Initiative**: Volksinitiative "Schluss mit uferlosem Bau von Zweitwohnungen!" (Art. 75b Federal Constitution)
- **Vote**: March 11, 2012 (50.6% Yes)
- **Implementation**: Federal Act on Second Homes (ZWG, SR 702) in force January 1, 2016
- **Mechanism**: Municipalities with >20% second-home share cannot authorize new second-home construction
- **Scale**: ~340 municipalities above threshold (mostly Alpine tourist communities), ~1,791 below
- **Relaxation**: Partial relaxation entered force October 1, 2024

## Identification Strategy

**Sharp RDD at the 20% second-home threshold.**

- **Running variable**: Municipality second-home share (measured to 2 decimal places by federal housing inventory)
- **Treatment**: Ban on new second-home construction (municipalities above 20%)
- **Control**: No ban (municipalities below 20%)
- **Outcome**: Primary home share (ZWG_3110), secondary home share (ZWG_3120), empty dwelling rate

The institutional threshold is federal and administratively determined — municipalities cannot manipulate their classification. The running variable is measured precisely by the Federal Statistical Office.

**Design**: Panel RDD across 16 semi-annual waves (2017–2025). Estimate:

Y_it = α + β · D(SecondHomeShare_i > 0.20) + f(SecondHomeShare_i) + δ_t + ε_it

where D() is the treatment indicator, f() is a flexible polynomial in the running variable, and δ_t are wave fixed effects.

**Bandwidth**: MSE-optimal (Calonico, Cattaneo, Titiunik 2014). Approximately 78 municipalities in the 18–22% window.

## Expected Effects and Mechanisms

1. **Composition effect** (β < 0 for secondary share): If the ban works, municipalities above 20% should show declining secondary home shares as stock gradually converts through renovation restrictions and resale.
2. **Construction displacement**: New construction may shift to municipalities just below 20% ("bunching below threshold").
3. **Permanent population**: If housing converts, permanent population should grow in treated municipalities.
4. **Empty dwelling rate**: Could rise (owners hold second homes vacant rather than convert) or fall (supply constraint increases occupancy).

## Primary Specification

```r
# Sharp RDD using rdrobust
rdrobust(Y = primary_home_share, X = second_home_share_running_var, c = 0.20)
```

Robustness:
- Bandwidth sensitivity (0.5×, 0.75×, 1.25×, 1.5× MSE-optimal)
- Polynomial order (local linear, local quadratic)
- McCrary density test (rddensity) for manipulation
- Placebo cutoffs at 15% and 25%
- Donut RDD (exclude ±1pp around threshold)
- Panel wave heterogeneity (early vs. late waves)

## Data Sources

1. **ZWG Housing Inventory**: geo.admin.ch STAC API — 2,131 municipalities, 16 semi-annual waves (2017–2025), fields ZWG_3110 (primary %), ZWG_3120 (secondary %)
2. **Official municipality classification**: Federal classification of above/below 20% (from ARE or BFS)
3. **Municipality characteristics**: BFS PXWeb API — population, area, elevation, language region
4. **Empty dwelling rates**: Cantonal portals or BFS (annual, municipality level)
5. **Hotel overnight stays**: BFS tourism statistics (for mechanism — does housing conversion affect tourism?)

## Treatment Exposure Alignment

The treatment is binary: municipalities above the 20% threshold face a ban on new second-home construction authorization. Treatment assignment is determined by the Federal Office for Spatial Development based on the housing inventory. The running variable (initial second-home share in 2017) is measured after the policy's enactment (2012 vote, 2016 implementation). However, second-home shares reflect accumulated housing stock that changes slowly, and the McCrary test shows no manipulation. The RDD identifies the local average treatment effect (LATE) at the threshold — municipalities far above 20% may experience different dynamics. The ban targets new construction permits only; existing second homes face no reclassification requirements.

## Key Risks

1. **Running variable endogeneity**: Municipalities might strategically reclassify dwellings. Mitigate with McCrary test and institutional knowledge (classification is federal).
2. **Limited bandwidth**: 78 municipalities in 18–22% is functional but tight. Report multiple bandwidths.
3. **Post-treatment running variable**: ZWG data starts 2017 (post-policy). Must use the ORIGINAL threshold classification (pre-2016), not current shares. Need to obtain the initial classification list.
4. **Composition of municipalities near threshold**: Alpine tourist vs. urban fringe municipalities may differ. Control for elevation, language, canton FE.

## Fetch Strategy

1. Query geo.admin.ch STAC API for ZWG data (GeoJSON/CSV format)
2. Query BFS PXWeb for municipality characteristics
3. Obtain official ARE/BFS classification list for above/below 20%
4. Merge on BFS Gemeindenummer (municipal ID)
