# Research Plan: apep_0822

## Research Question

Do conditional cash transfers (CCTs) transform local economies? Specifically: Did Colombia's Familias en Acción (FeA) program, which began disbursing conditional cash transfers in 50 randomly selected rural municipalities in 2002, produce measurably different municipality-level economic development outcomes 16 years later?

## Background

Familias en Acción is Colombia's flagship CCT, launched 2001–2002 in rural municipalities with <100,000 population. Cash transfers were conditional on school attendance (children 7–17) and health check-ups (children 0–6). The original IFS/Econometría/SEI evaluation selected 50 treatment municipalities and matched them to 50 control municipalities using stratified matching on geographic region and infrastructure availability.

The existing literature (Attanasio et al. 2005 Fiscal Studies; 2010 EDCC; Barrientos & Villa 2015) exclusively measures **individual and household** outcomes (school enrollment, nutritional status, consumption). No published study measures whether FeA-treated municipalities developed differently **as local economies** — urbanization, employment composition, poverty reduction, or luminosity growth.

## Identification Strategy

**Matched difference-in-differences** using the original 50T/50C quasi-experimental evaluation design.

- **Treatment:** Municipality received FeA transfers starting 2002
- **Control:** Matched municipality did not receive FeA until later rollout
- **Pre-treatment:** DMSP nightlights 1992–2001 (10 pre-treatment years for parallel trends)
- **Post-treatment:** 2018 DANE Census (CNPV) cross-section + VIIRS nightlights 2012–2022
- **Parallel trends test:** Pre-2002 nightlights trajectories for T vs C municipalities

Key assumptions:
1. Pre-treatment parallel trends in nightlights (testable with 10 pre-periods)
2. Treatment assignment is orthogonal to unobserved determinants of long-run growth (supported by matched design and baseline balance from Attanasio et al.)
3. No differential exposure to conflict, natural disasters, or other programs that correlates with treatment status

## Expected Effects and Mechanisms

If CCTs create local economic multipliers through human capital accumulation and demand effects:
- **Nightlights:** Positive luminosity growth differential in treated municipalities (proxy for economic activity)
- **Poverty:** Lower multidimensional poverty index (MPI) in treated municipalities
- **Education:** Higher educational attainment in treated municipalities (direct program mechanism)
- **Employment:** Shift from agriculture to services/formal employment
- **Urbanization:** Population growth and urban infrastructure

If CCTs only affect direct recipients without spillovers, we expect null place-based effects — also a valuable finding.

## Primary Specification

$$Y_{mt} = \alpha + \beta \cdot \text{Treat}_m \times \text{Post}_t + \gamma_m + \delta_t + \epsilon_{mt}$$

Where $m$ indexes municipalities, $t$ indexes years, $\text{Treat}_m$ is assignment to the original evaluation treatment group.

For nightlights panel: Municipality and year FE with treatment × post interaction.
For 2018 census: Cross-sectional comparison with stratum (region) FE and baseline controls.

## Data Sources and Fetch Strategy

1. **Municipality treatment/control list:** Reconstruct from Attanasio et al. (2010) EDCC published municipality codes and World Bank evaluation documentation. The 100 municipalities span 7 Colombian departments.

2. **DANE 2018 Census (CNPV):** Via `ColOpenData` R package (CRAN). Municipality-level aggregates: education attainment, employment status, housing quality, MPI components, population.

3. **DANE Municipal Panel:** Population counts, NBI (Unsatisfied Basic Needs) from DANE territorial statistics.

4. **Nightlights:** DMSP-OLS (1992–2013) and VIIRS (2012–2022) harmonized annual composites. Municipality-level mean luminosity extracted using Colombian municipality shapefiles from `ColOpenData` or `geodata`.

5. **Conflict data (control):** UCDP/ACLED event counts by municipality to control for differential conflict exposure.

## Robustness

1. Pre-trend test: Event study on nightlights 1992–2001
2. Placebo municipalities: Compare non-evaluation municipalities with similar baseline characteristics
3. Permutation inference: Randomization inference under sharp null
4. Conflict controls: Include armed conflict events as time-varying controls
5. Alternative luminosity measures: Log(lights+1), growth rates, binary electrification
