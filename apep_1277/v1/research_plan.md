# Research Plan: Minimum Wages and the Racial Hiring Gap

## Research Question

Do state minimum wage increases narrow or widen racial gaps in hiring? Specifically, how do Black and Hispanic new-hire rates (accessions) respond to minimum wage increases relative to white workers, in counties where the minimum wage binds most tightly?

## Mechanism

The *compositional hiring squeeze*: minimum wage hikes compress the wage distribution, reducing employers' ability to price-discriminate across worker characteristics. If discrimination operates through wage differentials (Becker 1957), compression should narrow racial hiring gaps. But if employers use non-price screening more intensely when wage flexibility is removed (Autor 2003), minorities may face *harder* barriers to entry. The sign of the racial accession response is theoretically ambiguous — and that's exactly why we need administrative data to settle it.

## Identification Strategy

**Two-layer staggered DiD:**

1. **Outer layer (state × quarter):** Staggered state minimum wage increases, 2010–2023. ~40 distinct adoption events. Estimated using Callaway-Sant'Anna (2021) with not-yet-treated as the comparison group.

2. **Inner layer (county-level bite):** Continuous treatment intensity via the Kaitz index = (state MW / county-industry median wage from BLS OES). High-bite counties experience larger effective shocks.

**Primary specification (DDD):**

$$\Delta \text{Acc}_{c,r,t} = \alpha_c + \gamma_t + \beta_1 (\text{Bite}_c \times \text{Post}_t) + \beta_2 (\text{Minority}_r \times \text{Bite}_c \times \text{Post}_t) + X_{c,t}\delta + \varepsilon_{c,r,t}$$

where $\beta_2$ captures the differential effect of MW bite on minority vs. white accessions.

**Border discontinuity robustness:** Restrict to contiguous county pairs straddling state borders where one state raised MW (Dube, Lester, Reich 2010). Eliminates regional confounds.

## Expected Effects

- **Main effect ($\beta_1$):** Small negative or null effect on overall accessions (consistent with Cengiz et al. 2019 QJE).
- **Racial interaction ($\beta_2$):** Theoretically ambiguous. If compression reduces discrimination → positive (minorities gain). If employers screen harder → negative (minorities lose).
- **Heterogeneity:** Effects should concentrate in low-wage industries (retail, food service, accommodation) where MW binds.

## Primary Specification

- **Unit:** County × race × quarter
- **Outcome:** Log accessions (new hires), log separations, log end-of-quarter employment, log beginning-quarter earnings
- **Treatment:** State MW increase × county Kaitz index
- **Fixed effects:** County, quarter, county-specific linear trends (robustness)
- **Clustering:** State level (treatment assignment level)
- **Estimator:** Callaway-Sant'Anna for staggered adoption; TWFE DDD for the race interaction
- **Inference:** Wild cluster bootstrap (state-level, ~50 clusters)

## Robustness Checks

1. Border-county pairs (Dube et al. 2010 design)
2. Event study with 8+ pre-periods and 8+ post-periods
3. Placebo: high-wage industries (finance, professional services) where MW doesn't bind
4. Leave-one-out state analysis
5. Alternative MW measures (effective MW including city-level ordinances)
6. HonestDiD sensitivity analysis for parallel trends violations

## Data Sources

1. **QWI Race-Ethnicity Panel** (`az://apepdata/derived/qwi/rh/ns/*.parquet`): County × quarter × industry × race, 2001–2023. ~280M observations. Accessions, separations, employment, earnings by race.

2. **State Minimum Wage History:** University of Washington Minimum Wage Study database + manual verification. State × quarter panel of effective MW rates, 2001–2023.

3. **BLS OES County-Level Median Wages:** For Kaitz index construction. Annual, by county × industry.

4. **Border County Crosswalk:** USDA ERS border county adjacency file for contiguous cross-state pairs.

## Key Risk

The QWI race-ethnicity panel has significant cell suppression in small counties/industries to protect confidentiality. Need to verify that enough county × race × quarter cells survive suppression for adequate power, especially for Black and Hispanic workers in rural counties. Mitigation: aggregate to broader industry groups (all-industry totals) or larger geographies if needed.
