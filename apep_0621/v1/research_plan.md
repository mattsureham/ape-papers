# Research Plan: Carrots for Mothers, Ladders for Children

## Research Question

Did the staggered adoption of mothers' pension laws (1911--1919) --- America's first government welfare program --- improve children's long-run occupational attainment? We estimate the population-level intent-to-treat effect using individual-level linked census panels tracking 9.6 million children from 1920 to 1940.

## Why It Matters

Mothers' pensions were the precursor to AFDC and modern TANF. Whether early childhood exposure to cash transfers produces intergenerational mobility has first-order implications for the design of safety nets. Aizer et al. (2016 AER) studied accepted vs. rejected applicants within counties that had programs --- a LATE for program receipt. Our design captures the population-level ITT of law adoption, including general equilibrium effects (school quality, stigma reduction, peer composition) that applicant-level analysis misses.

## Identification Strategy

**Staggered Difference-in-Differences (Callaway--Sant'Anna)**

- **Treatment:** State-level adoption of mothers' pension law, assigned to children based on state of residence at the 1920 census.
- **Cohorts:** 7+ distinct adoption cohorts (1911, 1913, 1915, 1916, 1917, 1918, 1919).
- **Control group:** Not-yet-treated and never-treated states.
- **Unit of analysis:** Individual children, clustered at the state level.

**Primary design (Long-run, 1920--1940 panel):** Children aged 0--10 in 1920 who grew up entirely under MP regimes. Adult outcomes measured in 1940 at ages 20--30: occupational attainment (SEI, occscore), employment status.

**Secondary design (Short-run, 1910--1920 panel):** Children aged 8--14 in 1910 exposed to MPs adopted 1911--1919. Outcomes in 1920: child labor participation, school attendance.

## Expected Effects and Mechanisms

1. **Direct income channel:** Cash transfers reduce poverty → children stay in school longer → higher adult occupational status.
2. **Reduced child labor:** MPs reduce economic pressure for child labor → human capital accumulation.
3. **Institutional spillovers:** MP adoption signals state commitment to child welfare, may correlate with school investment.

**Predictions:**
- Positive effect on adult SEI/occscore (children in MP states attain higher-status occupations)
- Negative effect on child labor rates (immediate pathway)
- Effects concentrated among boys (who had higher child labor rates) and lower-SEI families
- Larger effects in states with more generous benefit levels

## Primary Specification

State-level staggered DiD using Callaway--Sant'Anna (2021):

```
ATT(g,t) = E[Y_t(g) - Y_t(0) | G = g]
```

Where g indexes adoption cohort and t indexes census year. Aggregate to event-study and overall ATT using `aggte()`.

**Clustering:** State level (39--48 states depending on specification).
**Pre-trends:** Check using 1910 baseline outcomes across adoption cohorts.
**Sensitivity:** HonestDiD bounds for parallel trends violations.
**Robustness:**
- Restrict to 26 non-Southern states (cleaner baseline balance)
- Placebo: children too old to benefit (age 15+ in 1920)
- Heterogeneity by MP generosity (benefit levels varied 7x across states)
- Migration control using `mover` variable

## Data Sources

1. **MLP 1920--1930--1940 panel:** `az://derived/mlp_panel/linked_1920_1930_1940.parquet` (34.7M individuals, 75 columns). Children aged 0--10 in 1920 tracked to adulthood in 1940.
2. **MLP 1910--1920 panel:** `az://derived/mlp_panel/linked_1910_1920.parquet` (43.9M individuals). For short-run child labor/schooling outcomes.
3. **1940 full-count census:** `az://raw/ipums_fullcount/us1940b.parquet` (EDUC, INCWAGE variables for joinable outcomes).
4. **Mothers' pension adoption dates:** From Aizer et al. (2016) and Children's Bureau publications. Hard-coded in R script from idea manifest.

## Data Fetch Strategy

All primary data is pre-loaded on Azure Blob Storage. Access via DuckDB using `scripts/lib/azure_data.R`. No external API calls needed.

**Key variables from MLP 1920--1940:**
- `occ1950_1940`: Occupation codes (harmonized 1950 basis)
- `sei_1940`: Duncan Socioeconomic Index
- `occscore_1940`: Occupational income score
- `school_1930`: School attendance
- `statefip_1920`: State of residence at baseline
- `age_1920`, `sex`, `race`: Individual characteristics

**Sample restrictions:**
- Children aged 0--10 in 1920 (born 1910--1920)
- Successfully linked to 1940
- Drop if moved states between censuses (sensitivity check)

## Risks and Mitigation

| Risk | Severity | Mitigation |
|------|----------|------------|
| Pre-trends across adoption cohorts | High | HonestDiD bounds; restrict to 1911-1915 cohorts with similar baselines |
| Selection into adoption timing | Medium | Control for concurrent reforms (compulsory schooling, child labor laws); state-specific trends |
| Link quality varies by state/SES | Medium | Report link rates; reweight; compare linked vs. unlinked on observables |
| Census decade spacing limits event study | Medium | Use aggregate ATT as primary; event study as supporting evidence |
| Small number of clusters (states) | Low | Wild cluster bootstrap; 39+ states is adequate |
