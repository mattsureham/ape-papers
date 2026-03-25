# Research Plan: apep_0940

## Research Question
Does official government designation of public housing estates as "parallel societies" cause net out-migration of immigrant-origin residents in Denmark? And does this displacement precede or follow physical demolition interventions?

## Policy Background
Since 2010, Denmark's Ministry of Housing publishes an annual list of "vulnerable residential areas" (udsatte boligområder). The 2018 Ghetto Package (Act No. 1000) introduced a stricter "parallel society" (parallelsamfund) category with mandatory interventions: estates on the list for 5+ consecutive years face forced demolition/conversion to reduce public family housing below 40%. The list was renamed from "ghettolisten" to "parallelsamfundslisten" in 2021. Criteria include: ≥1,000 residents in social housing, >50% non-Western immigrant/descendant share, plus ≥2 of 4 socioeconomic indicators.

## Identification Strategy
**Staggered DiD** at the municipality level:
- **Treatment**: Municipality contains at least one estate designated as "parallel society" (or "ghetto" pre-2021) in year t
- **Unit**: Municipality × year (98 municipalities, 2010-2024)
- **Treated**: ~20-30 municipalities with designated estates at some point
- **Control**: ~68-78 municipalities without designated estates
- **Fixed effects**: Municipality FE + year FE
- **Estimator**: Callaway-Sant'Anna (2021) for staggered adoption with heterogeneous treatment effects
- **Pre-trends**: 5-8 pre-periods from 2010 baseline

## Expected Effects
1. **Displacement**: Designated municipalities see net out-migration of immigrant-origin residents (FOLK1C population changes)
2. **Composition shift**: Share of non-Western immigrants declines in designated municipalities
3. **Mechanism**: Displacement begins after designation (stigma channel) and accelerates after 5-year demolition trigger

## Primary Specification
Y_{mt} = α_m + γ_t + β × Designated_{mt} + ε_{mt}
- Y: immigrant-origin population share, employment rate, residential mobility
- Designated: binary, = 1 if municipality m has ≥1 designated estate in year t
- Cluster SEs at municipality level

## Data Sources
1. **DST StatBank API** (confirmed live):
   - FOLK1C: Population by municipality × ancestry × quarter (2008Q1-present)
   - RAS200: Employment by ancestry × municipality × year
   - FLYT47: Residential mobility flows
   - IND07: Gross income by region × ancestry × year

2. **Designation list**: Manually coded from government publications (Transport, Building and Housing Authority annual lists, December 1 each year). Cross-referenced with parliamentary documents, Wikipedia "Ghettolisten" article, and news coverage.

## Key Risks
- Municipality-level aggregation is coarser than ideal; designated estates may be small relative to total municipality population
- Designation is endogenous to local conditions (mitigated by DiD + event study)
- Number of treated municipalities (~20-30) adequate but not large
