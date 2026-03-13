# Research Plan: apep_0650/v1

## Research Question
Does the well-documented near-zero aggregate employment effect of minimum wages mask offsetting firm-level responses — simultaneous job creation and job destruction — and age-specific displacement? We decompose the aggregate null into firm dynamics and demographic channels using novel QWI data in the Dube-Lester-Reich (2010) border-county-pair design.

## Identification Strategy
**Spatial RDD via contiguous county pairs** at state borders with minimum wage differentials, following Dube, Lester, and Reich (2010 ReStat). Counties sharing a border but in different states face different minimum wages. County-pair fixed effects absorb permanent differences; quarter fixed effects absorb national trends. Within-pair temporal variation in minimum wages (from state-level increases) provides the identifying variation.

Key assumption: In the absence of different minimum wages, labor market outcomes in contiguous border counties would evolve identically. Testable via:
- Pre-trend tests on outcomes before MW changes
- Covariate balance between paired counties
- Placebo borders (county pairs with NO MW differential)

## Expected Effects and Mechanisms
1. **Aggregate employment**: Near-zero (replicating Dube et al.)
2. **Firm dynamics decomposition**: Higher MW → increased job destruction at low-wage firms AND increased job creation at expanding firms (creative destruction). The net is near zero, but the gross flows increase.
3. **Age-specific displacement**: Young workers (14-24) may face reduced hiring on the high-MW side; prime-age workers unaffected.
4. **Earnings**: Higher on the high-MW side, concentrated among young and low-wage workers.
5. **Industry heterogeneity**: Effects concentrated in NAICS 72 (accommodation/food), 44-45 (retail), 81 (other services).

## Primary Specification
```
Y_{cpqt} = α_{cp} + γ_q + β × log(MW_{cq}) + X'δ + ε_{cpqt}
```
Where:
- cp = county pair fixed effects
- q = calendar quarter fixed effects
- MW_{cq} = minimum wage applicable to county c in quarter q
- Y = firm job creation rate, destruction rate, employment, hiring, earnings
- SE clustered at state-border-segment level

## Data Sources
1. **QWI (LEHD)**: Azure `derived/qwi/sa/ns/*.parquet` — county × quarter × NAICS sector × sex × age. Variables: Emp, HirA, HirN, Sep, FrmJbGn, FrmJbLs, EarnS, TurnOvrS.
2. **State minimum wages**: Construct from published MW databases (Vaghul & Zipperer 2021; University of Minnesota AAER database; DOL records).
3. **County adjacency**: Census Bureau county adjacency file — identifies all contiguous county pairs.
4. **Controls**: BLS LAUS county unemployment rates; BEA county-level GDP.

## Analysis Plan
1. Construct border county pairs from Census adjacency file
2. Merge with state minimum wage panel (quarterly)
3. Pull QWI data for border counties from Azure
4. Main analysis: county-pair FE regressions on log(MW) → firm dynamics
5. Heterogeneity: by age group, by industry
6. Robustness: placebo borders, alternative bandwidths, wild cluster bootstrap
7. SDE appendix table

## Method Notes
This is NOT standard staggered DiD. It is a border-pair spatial design with:
- County-pair FE (not state FE)
- Continuous treatment (log MW) not binary
- Temporal variation from state MW changes over time
- Clustering at state-border-segment level (not state)
