# Research Plan: The Enclave as Insurance and Trap

## Research Question

Do immigrant ethnic enclaves function as economic insurance or amplifiers during macroeconomic crises? Specifically, did co-ethnic residential concentration protect or harm European immigrants' occupational trajectories during the Great Depression?

## Key Contribution

We introduce a new object: the **enclave paradox**. Using 1.3 million European-born males tracked across three decades (1920–1930–1940) via the IPUMS MLP linked panel, we show that the same institution—ethnic residential concentration—provided occupational insurance for some nationalities (Russians, Irish) while amplifying Depression losses for others (Italians, Hungarians). The divergence traces to enclave economic structure: self-employment networks absorb shocks; wage-dependent enclaves in cyclical industries transmit them.

## Identification Strategy

**Design:** Within-nationality, across-county variation in co-ethnic concentration (measured in 1920).

**Estimating equation:**
ΔOcc_{i,1930-1940} = α + β₁(CoEthnicShare_{c,n,1920}) + NationalityFE + StateFE + X_i'δ + ε

Where:
- ΔOcc = change in occupational income score (SEI) between 1930 and 1940
- CoEthnicShare = fraction of county population from same birthplace country in 1920
- Nationality FE absorb average differences across groups
- State FE absorb local economic conditions
- X_i includes 1920 age, literacy, years in US, homeownership

**Pre-period validation:** The same specification on ΔOcc_{1920-1930} (boom period) provides a natural placebo. If enclave effects are crisis-specific, β should be near zero during the boom.

**IV strategy:** 1924 Johnson-Reed quota bite × pre-1920 county nationality shares instruments for 1930 enclave density. Quotas are exogenous to individual characteristics and differentially restricted S/E European immigration.

**Heterogeneity:** Interact enclave effects with nationality-level self-employment rate to test the insurance-vs-trap mechanism.

## Expected Effects and Mechanisms

**Hypothesis 1 (Insurance):** Nationalities with high self-employment rates in enclaves (Russians/Jews, Greeks) should show positive β—denser enclaves protected occupational standing during the Depression through informal credit, customer networks, and employment buffers.

**Hypothesis 2 (Trap):** Nationalities concentrated in wage labor in cyclical industries (Italians in construction, Hungarians in mining) should show negative β—denser enclaves amplified losses through correlated industry exposure and limited occupational diversification.

**Hypothesis 3 (Boom neutrality):** During the 1920s boom, enclave density should have minimal differential effects on occupational mobility, confirming the crisis-specific nature of the mechanism.

## Primary Specification

1. **Main result:** OLS regression of Depression-era occupational change on 1920 enclave density, pooled across all nationalities
2. **Heterogeneity by nationality:** Separate regressions or nationality × enclave interactions revealing insurance vs trap pattern
3. **Mechanism test:** Triple interaction CoEthnicShare × SelfEmploymentRate × Post
4. **Placebo:** Boom-period (1920–1930) specification
5. **IV:** Quota-bite instrument for enclave density

## Data Source and Fetch Strategy

**Primary data:** Azure MLP three-decade linked panel
- Path: `derived/mlp_panel/linked_1920_1930_1940.parquet` (4.9 GB)
- 1,309,322 European-born males aged 25–45 in 1920
- Variables: occ1950, occscore, sei, bpl, statefip, countyicp, farm, ownershp, lit, yrimmig, age, sex

**Data engineering steps:**
1. Query Azure via DuckDB in R (stream, don't download)
2. Filter to European-born males aged 25–45 in 1920
3. Compute county × nationality co-ethnic shares from 1920 full-count census
4. Compute nationality-level self-employment rates from 1920 census
5. Merge and construct panel

**No API calls needed.** All data confirmed on Azure.

## Sample Size Targets
- N individuals: ~1.3M European-born males
- N counties: ~5,000 county-nationality cells
- N nationalities: 18 with N ≥ 5,000
- Pre-periods: 1 decade (1920–1930)
- Post-period: 1 decade (1930–1940)
