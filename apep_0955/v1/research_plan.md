# Research Plan: apep_0955

## Research Question

Did the Agricultural Adjustment Act's cotton acreage reduction program (1933-34) causally affect the long-run educational, occupational, and earnings outcomes of Black sharecropper children, and did effects vary by developmental stage at the time of displacement?

## Identification Strategy

**Triple-differences with within-family sibling fixed effects:**

```
Y_ifc = α_f + β(AAA_c × CriticalAge_i) + γX_i + ε_ifc
```

- α_f = household (family) fixed effect: absorbs all time-invariant family confounders (parental ability, wealth, networks)
- AAA_c = county-level cotton acreage reduction intensity (continuous treatment)
- CriticalAge_i = age cohort at AAA implementation (school-age 6-12 vs. labor-age 13-17 vs. young 0-5 in 1933)
- Identifying variation: within the same family, differential effects of county AAA intensity on siblings of different ages

**Key assumption:** Within families, the differential effect of county AAA intensity on children of different ages is not driven by pre-existing age-specific trends. Testable via placebo age cutoffs and pre-period balance.

**Second layer:** Black vs. white children in same county (racial displacement mechanism test).

## Expected Effects

1. **Education (educ_1940, educ_1950):** Negative for school-age children — displacement disrupts schooling at critical investment ages
2. **Migration (mover_30_40, mover_40_50):** Positive — displacement accelerates geographic mobility (Great Migration channel)
3. **Occupation (occscore_1940, occscore_1950):** Ambiguous — displacement disrupts but may push into higher-scoring non-farm jobs
4. **Farm residence (farm_1940, farm_1950):** Negative — displacement pushes children off farms
5. **Income (incwage_1940, incwage_1950):** Ambiguous direction, tests net welfare effect

## Primary Specification

Sibling FE regressions with continuous AAA treatment × age cohort interactions:

```r
feols(outcome ~ aaa_intensity:age_cohort | serial_1930, data = siblings_df, cluster = ~countyicp_1930)
```

Outcomes measured in 1940 (short-run) and 1950 (long-run). Clustering at county level (unit of treatment assignment).

## Data Sources

1. **MLP 1930-1940-1950 panel** (`az://derived/mlp_panel/linked_1930_1940_1950.parquet`): Individual-level linked census data. Filter to Black farm children (age 0-17) in 7 cotton-belt states (AL, AR, GA, LA, MS, SC, TX).

2. **AAA cotton acreage treatment:** County-level cotton production data from USDA NASS Census of Agriculture (1929). Will construct: (county cotton acreage / county total cropland) as pre-existing cotton intensity. Alternatively, Fishback-Kantor-Wallis NBER county-level New Deal spending data for direct AAA payment measures.

3. **Robustness data:** State-level cotton production statistics from USDA Yearbooks (well-documented in agricultural history literature).

## Robustness Checks

1. Placebo age cutoffs (children who should NOT be differentially affected)
2. White children as a placebo group (should show smaller displacement effects)
3. Leave-one-state-out estimates
4. Alternative clustering (state level)
5. Alternative age cohort definitions
6. Pre-existing county characteristics balance tests
