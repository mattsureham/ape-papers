# Research Plan: Closing the Golden Door

## Research Question

Did the 1924 Johnson-Reed Immigration Act cause native-born American workers to upgrade their occupations? The Act slashed Southern and Eastern European immigration by 87% through origin-country quotas based on the 1890 census. Counties with larger pre-existing concentrations of restricted-origin immigrants experienced sharper labor supply contractions. We trace 10.7 million individual native-born workers across the 1920–1930 linked census panel to measure occupational mobility responses.

## Identification Strategy

**Continuous-treatment DiD with Bartik-style exposure.** Treatment intensity = share of 1920 county population born in quota-restricted countries (Italy, Russia, Poland, Austria-Hungary, Greece, Romania, etc.). The quotas were set based on 1890 census proportions — a political compromise reflecting 19th-century settlement, not 1920 economic conditions.

Primary specification:
```
ΔOccScore_i = β × QuotaExposure_c + X'δ + State_FE + ε_ic
```

Where ΔOccScore_i is the change in occupational income score for individual i between 1920 and 1930, QuotaExposure_c is the county-level share of restricted-origin foreign-born in 1920, X includes 1920 age, literacy, urban/rural status, and initial occupation fixed effects. Standard errors clustered at county level.

## Key Identifying Assumptions

1. **No differential pre-trends**: County-level occupational upgrading rates were not systematically different by quota exposure before 1924. Tested via 1910-1920 placebo.
2. **Exogeneity of quota exposure**: Settlement patterns from 1890 determined county exposure. The quotas themselves were national legislation.
3. **No contemporaneous shocks**: Other 1920s trends (electrification, auto industry growth) did not systematically correlate with immigrant settlement patterns.

## Expected Effects and Mechanisms

Theory is ambiguous:
- **Complementarity**: If immigrants filled specific niches (unskilled factory, mining), natives could specialize upward into supervisory/skilled roles → positive ΔOccScore
- **Substitution**: If immigrants competed directly, restriction removes competition → positive ΔOccScore
- **General equilibrium**: Restriction may reduce local economic dynamism → negative or null ΔOccScore

We decompose:
1. Farm-to-nonfarm transitions (structural transformation channel)
2. Unskilled-to-skilled within nonfarm (upgrading channel)
3. Geographic mobility (sorting channel)

## Data Sources

All from Azure Blob Storage (IPUMS MLP linked panels):
- `derived/mlp_panel/linked_1920_1930.parquet` — 53.6M linked individuals
- `derived/mlp_panel/linked_1910_1920.parquet` — 43.9M individuals (placebo)
- Full-count 1920 census for constructing county-level exposure

## Primary Specification

Table structure:
1. **Summary statistics** — native workers by county exposure quartile
2. **Main results** — individual-level ΔOccScore on county exposure
3. **Heterogeneity** — by initial skill, age, urban/rural, race
4. **Placebo** — 1910-1920 (same specification, should show null)
5. **Robustness** — leave-one-origin-out, alternative exposure, AKM SEs

## Feasibility Assessment

- 10.7M native-born workers across 3,066 counties (massive power)
- County exposure ranges 0-25% (strong treatment variation)
- Built-in placebo period (1910-1920)
- Data confirmed on Azure with all needed variables
