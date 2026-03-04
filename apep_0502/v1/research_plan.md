# Initial Research Plan: Clean Air, Dirty Power?

## Research Question

Does NAAQS nonattainment designation accelerate the clean energy transition by creating asymmetric regulatory costs between fossil and renewable power generation?

## Identification Strategy

**Multi-cutoff sharp RDD** using county-level PM2.5 design values relative to the National Ambient Air Quality Standard.

- **Running variable:** County PM2.5 annual mean concentration (design value: 3-year average)
- **Cutoffs:** 15 μg/m³ (1997 NAAQS), 12 μg/m³ (2012 revision), and additional analysis at the 2006 24-hr PM2.5 revision (35 μg/m³ from 65 μg/m³)
- **Treatment:** Nonattainment designation → New Source Review requirements (LAER + offsets + alternative site analysis for new/modified fossil fuel sources)
- **Control:** Attainment designation → Prevention of Significant Deterioration (PSD) with less stringent BACT requirements
- **Key asymmetry:** Renewable generators emit zero criteria pollutants → exempt from NSR regardless of attainment status

## Expected Effects and Mechanisms

1. **Fossil capacity deterrence:** Nonattainment counties should see fewer new fossil fuel plant constructions and capacity additions (higher NSR costs)
2. **Renewable substitution:** If energy demand is inelastic, reduced fossil investment should be offset by increased renewable capacity
3. **Accelerated retirement:** Existing fossil plants in nonattainment areas may face higher costs for modifications, accelerating retirement
4. **Spatial displacement:** Some fossil investment may relocate to neighboring attainment counties rather than converting to renewables

## Primary Specification

$$Y_{c,t} = \alpha + \beta \cdot \mathbb{1}[DV_{c,t} > NAAQS] + f(DV_{c,t}) + \gamma_s + \delta_t + \epsilon_{c,t}$$

Where:
- $Y_{c,t}$: County-level energy infrastructure outcome (new fossil capacity, renewable share, retirements)
- $DV_{c,t}$: County design value (3-year average PM2.5)
- $NAAQS$: Standard threshold (12 μg/m³ for primary analysis)
- $f(\cdot)$: Local polynomial in design value (linear, separate slopes each side)
- $\gamma_s$: State fixed effects
- $\delta_t$: Year fixed effects

## Exposure Alignment

- **Treated:** Counties designated nonattainment (DV > NAAQS threshold)
- **Control:** Counties in attainment (DV ≤ NAAQS threshold)
- **Placebo population:** Renewable energy projects (should show NO discontinuity since they are exempt from NSR)
- **Design:** Sharp RDD with multi-cutoff stacking across PM2.5 standard revisions

## Power Assessment

- **Counties near 12 μg/m³ cutoff:** ~81 (±2 μg/m³ bandwidth)
- **Counties near 9 μg/m³ cutoff:** ~394 (±2 μg/m³ bandwidth)
- **Power plants in the US:** ~10,000+ with county locations
- **Post-treatment periods:** 14+ years for 2012 revision, 27+ years for 1997 standard
- **MDE assessment:** To be computed after data assembly. Key concern: investment outcomes are lumpy. Mitigation: use cumulative/stock measures and renewable share rather than annual flows.

## Planned Robustness Checks

1. **McCrary density test** at the NAAQS threshold
2. **Bandwidth sensitivity** (MSE-optimal, CER, 50-150% of optimal)
3. **Polynomial order** (local linear vs quadratic)
4. **Donut RDD** excluding counties within 0.5 μg/m³ of cutoff
5. **Covariate balance** (population, income, manufacturing share) at the threshold
6. **Placebo cutoffs** at values away from the true NAAQS standard
7. **Placebo outcome** (renewable capacity should show no discontinuity)
8. **Spatial displacement analysis** (neighboring county effects)
9. **Market-area aggregation** (commuting zone, balancing authority)
10. **Multi-cutoff stacking** (PM2.5 1997/2006/2012 revisions as separate cutoffs)

## Data Sources

| Data | Source | Years | Unit |
|------|--------|-------|------|
| PM2.5 design values | EPA AQS annual summary | 1999-2023 | Monitor/County |
| Nonattainment designations | EPA Green Book | 1997-2024 | County |
| Generator inventory | EIA Form 860 | 2001-2024 | Plant/Generator |
| Generation & fuel | EIA Form 923 | 2001-2024 | Plant |
| County demographics | Census ACS | 2005-2023 | County |
| Electricity prices | EIA-861 | 2001-2024 | Utility/State |
