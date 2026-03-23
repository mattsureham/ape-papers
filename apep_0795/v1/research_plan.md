# Research Plan: Insured Escape — Social Security Exclusion and Black Occupational Sorting

## Research Question

Did the 1935 Social Security Act's exclusion of agricultural and domestic workers — occupations employing 60% of Black workers but only 27% of white workers — cause differential occupational sorting by race? Specifically, did Black workers in excluded occupations switch to covered occupations at higher rates than comparable white workers, and did this "insured escape" channel contribute to the Great Migration's occupational transformation?

## Identification Strategy

**Triple-difference design** using linked individual census data:

1. **First difference (occupation type):** Workers in excluded occupations (agricultural, domestic) vs. covered occupations (manufacturing, commerce, etc.)
2. **Second difference (race):** Black vs. White workers
3. **Third difference (time period):** 1930→1940 transition (post-SSA) vs. 1920→1930 transition (pre-SSA placebo)

The key identifying variation: Black workers in excluded occupations had the strongest incentive to switch to covered occupations after 1935, relative to (a) white workers in the same excluded occupations, (b) Black workers already in covered occupations, and (c) the pre-SSA baseline switching rate.

**Estimating equation:**
$$\text{Switch}_{i,t} = \beta_0 + \beta_1 (\text{Black}_i \times \text{Excluded}_i \times \text{Post}_t) + \beta_2 (\text{Black}_i \times \text{Excluded}_i) + \beta_3 (\text{Black}_i \times \text{Post}_t) + \beta_4 (\text{Excluded}_i \times \text{Post}_t) + X_i'\gamma + \epsilon_{i,t}$$

Where $\text{Switch}_{i,t}$ = 1 if individual $i$ moved from an excluded to a covered occupation during decade transition $t$.

## Expected Effects and Mechanisms

**Primary hypothesis:** $\beta_1 > 0$ — Black workers in excluded occupations switched to covered occupations at higher rates after SSA passage, compared to white workers in excluded occupations.

**Mechanisms:**
1. **Forward-looking insurance motive:** The 10-year pension promise created incentives for younger workers (under 55 in 1935) to switch to covered occupations to accumulate credits.
2. **Information channel:** Black community organizations (NAACP, Urban League) publicized SSA exclusions, raising awareness of the coverage gap.
3. **Pull factor for Great Migration:** Covered occupations were concentrated in urban areas and Northern states, reinforcing migration incentives.

**Heterogeneity predictions:**
- Stronger effects for younger workers (longer pension horizon)
- Stronger effects for domestic vs. agricultural workers (domestic work more easily substitutable; proximity to urban covered-sector jobs)
- Stronger effects in states with more covered-sector employment nearby

## Primary Specification

Individual-level linear probability model with the triple interaction as the coefficient of interest. Controls: age, sex, state of residence fixed effects, county-level economic conditions. Standard errors clustered at the state level.

## Data Source and Fetch Strategy

**Primary data:** MLP Linked Panel from Azure
- Path: `az://derived/mlp_panel/linked_1920_1930_1940.parquet`
- 34.7M linked individuals across three censuses
- Variables: race, occupation, state, county, age, sex

**Data construction:**
1. Load MLP panel via DuckDB/Arrow from Azure
2. Classify occupations as "excluded" (agricultural, domestic) vs. "covered" using 1930 Census occupation codes
3. Construct individual-level switching indicator: 1 if occupation category changed from excluded to covered
4. Create two decade-transition observations per individual: 1920→1930 (pre-SSA) and 1930→1940 (post-SSA)
5. Restrict sample to working-age individuals (15-64 in each census year)

**Supplementary:** County-level characteristics from NHGIS for economic controls.

## Key Robustness Checks

1. **Pre-trend test:** 1920→1930 switching rates should be parallel by race within occupation category
2. **Placebo occupation test:** Workers in already-covered occupations should show no differential race × time switching
3. **Age heterogeneity:** Stronger effects for younger workers (longer pension horizon)
4. **Geographic heterogeneity:** Effects by state-level covered-sector employment share
5. **Alternative occupation classification:** Sensitivity to boundary between excluded and covered occupations
