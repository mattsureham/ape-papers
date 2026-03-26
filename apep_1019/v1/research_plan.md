# Research Plan: The Caregiving Tax

## Research Question
Did state old-age pension laws (1923–1935) improve occupational outcomes for working-age men by relieving them of informal eldercare obligations?

## Identification Strategy
**Staggered DiD with Sun-Abraham estimator** exploiting the phased adoption of state old-age pension laws across 28 states between 1923 and 1935.

- **Treatment groups:** (1) Early adopters (1923–1929, ~10 states) observed as treated in 1930 census; (2) Late adopters (1930–1935, ~18 states) observed as treated only in 1940 census.
- **Control group:** ~18 never-treated states (mostly Southern) that did not adopt old-age pensions before the Social Security Act of 1935.
- **Time periods:** 1920 (universal pre-treatment), 1930 (post for early adopters), 1940 (post for all but contaminated by SSA).
- **Comparison group:** Never-treated states serve as the primary control. Not-yet-treated (late adopters before 1930) provide a secondary comparison.

## Expected Effects and Mechanisms
1. **Occupational upgrading:** Pensions reduce the need for children to stay in low-paying family occupations (especially farming). We expect positive effects on occscore/SEI.
2. **Farm exit:** Pensions allow sons to leave the family farm. We expect a decline in farm residence.
3. **Geographic mobility:** Freed from co-residence obligations, men can move to better labor markets.
4. **Mechanism test:** Effects should be larger for men with co-resident elderly parents in 1920 and for men from smaller families (fewer siblings to share the burden).

## Primary Specification
```
occscore_{i,s,t} = α_i + γ_t + β × Treated_{s,t} + ε_{i,s,t}
```
- Individual FE (α_i) absorb time-invariant person characteristics
- Year FE (γ_t) absorb common shocks
- Treated_{s,t} = 1 if state s has adopted a pension law by census year t
- SEs clustered at state level (N_clusters ≈ 46)
- Sun-Abraham estimator via fixest::sunab() to handle staggered adoption

## Exposure Alignment
The treatment targets elderly residents (65+), but the outcome population is working-age men (25-50 in 1920). The channel runs through intergenerational transfers: pensions provide income to elderly parents, reducing children's informal caregiving obligations. The treatment is assigned based on the man's 1920 state of residence (ITT), not his parents' pension receipt. This measures the reduced-form population-level effect of living in a state with pension availability, which includes both direct beneficiaries' children and general equilibrium effects. The early-adopter window (1920-1930) provides the cleanest exposure since these states had pension laws for at least one year and the federal Social Security Act had not yet introduced universal coverage.

## Data Source and Fetch Strategy
- **Primary:** Azure MLP panel (`az://derived/mlp_panel/linked_1920_1930_1940.parquet`, 34.7M rows)
- **Sample:** Men aged 25-50 in 1920, linked across three censuses
- **Variables:** histid, year, statefip, occ1950, occscore, sei, farm, ownershp
- **Access:** DuckDB Azure extension (query in place, filter on read)
- **Treatment coding:** State FIPS → pension adoption year from historical records
